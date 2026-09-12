//! Corporate actions — why a sealed position can be correct and unreadable at the same time.
//!
//! A quarterly report states holdings **as of the reporting date**. Mora seals at quarter end and
//! opens 45 days later. If a split lands in between, the number that opens is stated in units that no longer
//! exist, and a reader at `T` cannot tell whether "173,000" means today's units or September's.
//!
//! This is not hypothetical. `fixtures/corporate-actions.json` is the live xStocks schedule as read
//! on 2026-09-12: eight unit-changing events, including a 1→10 on `PPLTx` and a 2→1 reverse on
//! `HONx` that shares its date with a spin-off.
//!
//! The fix is not to re-seal — the commitment is the whole point and must not move. It is to
//! restate at read time. Restatement is a **deterministic function of public data**, so the holder
//! gains nothing by staying quiet about a split: anyone can recompute it, and everyone gets the
//! same answer.

use serde::{Deserialize, Serialize};

/// One unit-changing action, as xStocks publishes it.
#[derive(Clone, Debug, Serialize, Deserialize, PartialEq)]
pub struct CorporateAction {
    pub symbol: String,
    #[serde(default)]
    pub isin: Option<String>,
    #[serde(rename = "caType")]
    pub ca_type: String,
    #[serde(rename = "effectiveTimeUtc")]
    pub effective_utc: String,
    /// Units before. String in the API, because some actions are fractional — and absent
    /// entirely for actions that change *what* is held rather than how much (a spin-off).
    #[serde(rename = "fromUnits")]
    pub from_units: Option<String>,
    #[serde(rename = "toUnits")]
    pub to_units: Option<String>,
}

#[derive(Deserialize)]
struct Fixture {
    nodes: Vec<CorporateAction>,
}

/// The schedule shipped with this crate. Refresh with `scripts/refresh-actions.sh`.
pub fn scheduled() -> Vec<CorporateAction> {
    let raw = include_str!("../fixtures/corporate-actions.json");
    serde_json::from_str::<Fixture>(raw).expect("bundled fixture parses").nodes
}

impl CorporateAction {
    /// Seconds since the epoch, from `YYYY-MM-DDTHH:MM:SS(.sss)Z`. No dependency: the format is
    /// fixed-width and UTC, so parsing it is arithmetic rather than calendaring.
    pub fn effective_ts(&self) -> Option<i64> {
        let b = self.effective_utc.as_bytes();
        if b.len() < 19 || b[4] != b'-' || b[7] != b'-' || b[10] != b'T' {
            return None;
        }
        let num = |s: &str| s.parse::<i64>().ok();
        let (y, m, d) = (num(&self.effective_utc[0..4])?, num(&self.effective_utc[5..7])?, num(&self.effective_utc[8..10])?);
        let (hh, mm, ss) = (num(&self.effective_utc[11..13])?, num(&self.effective_utc[14..16])?, num(&self.effective_utc[17..19])?);
        Some(days_from_civil(y, m, d) * 86_400 + hh * 3_600 + mm * 60 + ss)
    }

    /// The unit ratio as an exact fraction, e.g. a 1→6 forward split is `(6, 1)`.
    ///
    /// `None` when the action has no whole-number unit ratio — a spin-off (no ratio at all), or a
    /// stock dividend like `1 → 1.012`. Those are *unresolved*, not *absent*: see [`Restated`].
    pub fn ratio(&self) -> Option<(u64, u64)> {
        let to = self.to_units.as_ref()?.parse::<f64>().ok()?;
        let from = self.from_units.as_ref()?.parse::<f64>().ok()?;
        if from <= 0.0 || to <= 0.0 {
            return None;
        }
        // Splits in the live schedule are whole-number ratios. Anything else is refused rather
        // than silently rounded — a restatement that quietly loses shares is worse than none.
        let (tn, fd) = (to.round(), from.round());
        if (to - tn).abs() > 1e-9 || (from - fd).abs() > 1e-9 {
            return None;
        }
        Some((tn as u64, fd as u64))
    }

    /// Does this action fall in `(as_of, at]` — i.e. after the position was fixed and no later
    /// than the moment it is being read?
    pub fn applies_between(&self, as_of: i64, at: i64) -> bool {
        matches!(self.effective_ts(), Some(t) if t > as_of && t <= at)
    }
}

/// A position restated from the units it was recorded in into the units in force now.
#[derive(Clone, Debug, PartialEq)]
pub struct Restated {
    /// What the sealed obligation says. Never changes — it is what the commitment binds.
    pub as_of_units: u64,
    /// The same holding, expressed in units current at the read time. Only meaningful when
    /// [`Restated::unresolved`] is empty.
    pub current_units: u64,
    /// The actions that account for the difference, in order.
    pub applied: Vec<CorporateAction>,
    /// Actions in the window that this **cannot** express as a unit ratio — a spin-off, a
    /// fractional stock dividend.
    ///
    /// These exist so that "nothing happened" and "something happened that I cannot compute" are
    /// different answers. Collapsing them is the dangerous direction: a reader told the number is
    /// current, when an unmodelled action moved it, is worse off than one told it cannot be
    /// restated.
    pub unresolved: Vec<CorporateAction>,
}

impl Restated {
    /// True only when the window is genuinely empty — no applied action **and** nothing
    /// unresolved. A reader may quote `as_of_units` as current exactly when this holds.
    pub fn unchanged(&self) -> bool {
        self.applied.is_empty() && self.unresolved.is_empty()
    }

    /// True when every action in the window was expressible as a ratio, so `current_units` means
    /// something.
    pub fn fully_resolved(&self) -> bool {
        self.unresolved.is_empty()
    }
}

/// Restate `shares` of `symbol`, recorded at `as_of`, into the units in force at `at`.
///
/// Never returns `None` for an action it merely cannot model: those land in
/// [`Restated::unresolved`], because silently reporting "unchanged" when a spin-off moved the
/// holding is the failure worth engineering against. `None` is reserved for arithmetic that cannot
/// be completed at all.
pub fn restate(
    shares: u64,
    symbol: &str,
    actions: &[CorporateAction],
    as_of: i64,
    at: i64,
) -> Option<Restated> {
    let mut relevant: Vec<CorporateAction> = actions
        .iter()
        .filter(|a| a.symbol == symbol && a.applies_between(as_of, at))
        .cloned()
        .collect();
    relevant.sort_by_key(|a| a.effective_ts().unwrap_or(i64::MAX));

    let (mut applied, mut unresolved) = (Vec::new(), Vec::new());
    let mut units = shares as u128;
    for a in relevant {
        match a.ratio() {
            Some((num, den)) => {
                units = units.checked_mul(num as u128)? / den as u128;
                applied.push(a);
            }
            None => unresolved.push(a),
        }
    }
    Some(Restated {
        as_of_units: shares,
        current_units: u64::try_from(units).ok()?,
        applied,
        unresolved,
    })
}

/// Days from 1970-01-01 to y-m-d (proleptic Gregorian). Howard Hinnant's civil_from_days, inverted.
fn days_from_civil(y: i64, m: i64, d: i64) -> i64 {
    let y = if m <= 2 { y - 1 } else { y };
    let era = if y >= 0 { y } else { y - 399 } / 400;
    let yoe = y - era * 400;
    let mp = (m + 9) % 12;
    let doy = (153 * mp + 2) / 5 + d - 1;
    let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
    era * 146_097 + doe - 719_468
}

#[cfg(test)]
mod tests {
    use super::*;

    fn ts(iso: &str) -> i64 {
        CorporateAction {
            symbol: String::new(),
            isin: None,
            ca_type: String::new(),
            effective_utc: iso.into(),
            from_units: Some("1".into()),
            to_units: Some("1".into()),
        }
        .effective_ts()
        .unwrap()
    }

    #[test]
    fn the_bundled_schedule_is_real_and_carries_what_it_cannot_model() {
        let a = scheduled();
        assert_eq!(a.len(), 11, "the fixture is the live schedule, every type but cash dividends");
        assert!(a.iter().any(|x| x.symbol == "PPLTx" && x.ratio() == Some((10, 1))));
        // The two kinds this cannot express as a ratio are present rather than filtered out —
        // being absent from the fixture is the one state restate() could not warn about.
        assert!(a.iter().any(|x| x.ca_type == "SpinOff" && x.ratio().is_none()));
        assert!(a.iter().any(|x| x.ca_type == "StockDividend" && x.ratio().is_none()));
    }

    /// **The case that used to be silently wrong.** HONx has a reverse split and a spin-off on the
    /// same date. Applying the split and reporting nothing else would hand a reader a number that
    /// looks current and is not.
    #[test]
    fn an_action_that_cannot_be_modelled_is_reported_not_ignored() {
        let r = restate(
            1_000,
            "HONx",
            &scheduled(),
            ts("2026-06-01T00:00:00.000Z"),
            ts("2026-07-01T00:00:00.000Z"),
        )
        .unwrap();
        assert_eq!(r.applied.len(), 1, "the 2->1 reverse split is applied");
        assert_eq!(r.current_units, 500);
        assert_eq!(r.unresolved.len(), 1, "the spin-off is carried, not dropped");
        assert_eq!(r.unresolved[0].ca_type, "SpinOff");
        assert!(!r.fully_resolved(), "500 must not be quoted as if it were the whole story");
        assert!(!r.unchanged(), "'unchanged' would be a lie here");
    }

    /// A stock dividend of 1 -> 1.012 is not a whole-number ratio. It is reported, not rounded.
    #[test]
    fn a_fractional_action_is_unresolved_rather_than_rounded() {
        let r = restate(
            1_000,
            "SCCOx",
            &scheduled(),
            ts("2026-08-01T00:00:00.000Z"),
            ts("2026-08-31T00:00:00.000Z"),
        )
        .unwrap();
        assert!(r.applied.is_empty());
        assert!(!r.unresolved.is_empty(), "the stock dividends are carried");
        assert!(!r.fully_resolved());
        assert_eq!(r.current_units, 1_000, "nothing was applied, so nothing moved");
    }

    #[test]
    fn dates_parse_against_known_epochs() {
        assert_eq!(ts("2026-09-30T00:00:00.000Z"), 1_790_726_400);
        assert_eq!(ts("2026-11-14T00:00:00.000Z"), 1_794_614_400);
        assert_eq!(ts("1970-01-01T00:00:00.000Z"), 0);
    }

    /// A holding recorded before a 1→2 forward split reads double afterwards. The sealed number
    /// does not move — that is what the commitment binds — but the restated one does.
    #[test]
    fn a_forward_split_in_the_window_restates_the_position() {
        let r = restate(
            173_000,
            "APHx",
            &scheduled(),
            ts("2026-08-31T00:00:00.000Z"),
            ts("2026-10-15T00:00:00.000Z"),
        )
        .unwrap();
        assert_eq!(r.as_of_units, 173_000, "the sealed number never moves");
        assert_eq!(r.current_units, 346_000);
        assert_eq!(r.applied.len(), 1);
        assert_eq!(r.applied[0].ca_type, "ForwardSplit");
    }

    /// A window containing only the reverse split: half the units, and nothing unresolved.
    #[test]
    fn a_reverse_split_halves_the_units() {
        let all = scheduled();
        let splits: Vec<_> = all.into_iter().filter(|a| a.ca_type == "ReverseSplit").collect();
        let r = restate(1_000, "HONx", &splits, ts("2026-06-01T00:00:00.000Z"), ts("2026-07-01T00:00:00.000Z")).unwrap();
        assert_eq!(r.current_units, 500);
        assert!(r.fully_resolved());
    }

    /// An action before the reporting date is already in the sealed number; an action after the
    /// read is not yet in force. Only `(as_of, at]` counts.
    #[test]
    fn only_actions_inside_the_window_apply() {
        let after = restate(100, "APHx", &scheduled(), ts("2026-09-04T00:00:00.000Z"), ts("2026-12-01T00:00:00.000Z")).unwrap();
        assert!(after.unchanged(), "the split was already reflected at as_of");
        let before = restate(100, "APHx", &scheduled(), ts("2026-01-01T00:00:00.000Z"), ts("2026-09-02T00:00:00.000Z")).unwrap();
        assert!(before.unchanged(), "the split had not happened yet at read time");
    }

    /// NVDAx has no unit-changing action scheduled, so the demo's number is unambiguous — and the
    /// test says so rather than the README.
    #[test]
    fn nvdax_needs_no_restatement_over_the_demo_window() {
        let r = restate(173_000, "NVDAx", &scheduled(), ts("2026-09-30T00:00:00.000Z"), ts("2026-11-14T00:00:00.000Z")).unwrap();
        assert!(r.unchanged());
        assert_eq!(r.current_units, r.as_of_units);
    }
}

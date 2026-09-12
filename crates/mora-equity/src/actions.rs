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
    /// Units before. String in the API, because some actions are fractional.
    #[serde(rename = "fromUnits")]
    pub from_units: String,
    #[serde(rename = "toUnits")]
    pub to_units: String,
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
    pub fn ratio(&self) -> Option<(u64, u64)> {
        let to = self.to_units.parse::<f64>().ok()?;
        let from = self.from_units.parse::<f64>().ok()?;
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
    /// The same holding, expressed in units current at the read time.
    pub current_units: u64,
    /// The actions that account for the difference, in order.
    pub applied: Vec<CorporateAction>,
}

impl Restated {
    pub fn unchanged(&self) -> bool {
        self.applied.is_empty()
    }
}

/// Restate `shares` of `symbol`, recorded at `as_of`, into the units in force at `at`.
///
/// Returns `None` if an action in the window has a ratio this refuses to apply — better to say
/// "this cannot be restated" than to publish a number that quietly lost shares.
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

    let mut units = shares as u128;
    for a in &relevant {
        let (num, den) = a.ratio()?;
        units = units.checked_mul(num as u128)? / den as u128;
    }
    Some(Restated {
        as_of_units: shares,
        current_units: u64::try_from(units).ok()?,
        applied: relevant,
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
            from_units: "1".into(),
            to_units: "1".into(),
        }
        .effective_ts()
        .unwrap()
    }

    #[test]
    fn the_bundled_schedule_is_real_and_parses() {
        let a = scheduled();
        assert_eq!(a.len(), 8, "the fixture is the live schedule read 2026-09-12");
        assert!(a.iter().all(|x| x.effective_ts().is_some()), "every date parses");
        assert!(a.iter().any(|x| x.symbol == "HONx" && x.ca_type == "ReverseSplit"));
        assert!(a.iter().any(|x| x.symbol == "PPLTx" && x.ratio() == Some((10, 1))));
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

    /// HONx went 2→1. Half the units, same holding.
    #[test]
    fn a_reverse_split_halves_the_units() {
        let r = restate(
            1_000,
            "HONx",
            &scheduled(),
            ts("2026-06-01T00:00:00.000Z"),
            ts("2026-07-01T00:00:00.000Z"),
        )
        .unwrap();
        assert_eq!(r.current_units, 500);
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

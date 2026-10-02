#!/usr/bin/env python3
"""The observer, against a fake chain. No devnet needed.

    python3 scripts/test_observe.py

scripts/observe-run.py is the only thing that re-reads a review run from outside it. A check that
has never been seen to fail is a display, so every rule it enforces is broken here once, on purpose,
against canned RPC answers shaped like the real ones (taken from the 2026-09-30 devnet run).
"""
import importlib.util, json, pathlib, unittest

spec = importlib.util.spec_from_file_location(
    "observe", pathlib.Path(__file__).with_name("observe-run.py"))
obs = importlib.util.module_from_spec(spec); spec.loader.exec_module(obs)
T22 = obs.TOKEN_2022


def tx(err=None, sigs=2, progs=(T22, T22), keys=("A1", "A2"), inner=()):
    return {"meta": {"err": err, "innerInstructions": [{"instructions": [{"programId": p} for p in inner]}]
                     if inner else []},
            "transaction": {"signatures": ["s"] * sigs,
            "message": {"instructions": [{"programId": p} for p in progs],
                        "accountKeys": [{"pubkey": k} for k in keys]}}}


def acct(amount="0", approved=True, ct=True):
    ex = [{"extension": "confidentialTransferAccount", "state": {"approved": approved}}] if ct else []
    return {"tokenAmount": {"amount": amount, "uiAmountString": amount}, "extensions": ex}


def mint(auto=False, auditor=None):
    return {"extensions": [{"extension": "confidentialTransferMint",
                            "state": {"autoApproveNewAccounts": auto, "auditorElgamalPubkey": auditor}}]}


GOOD_TX = {
    "REF": tx({"InstructionError": [0, {"Custom": 24}]}),
    "SELF": tx({"InstructionError": [0, "MissingRequiredSignature"]}, sigs=1, progs=(T22,), keys=("A1",)),
    "APPR": tx(sigs=1, progs=(T22,), keys=("A1",)),
    "SET1": tx(), "SET2": tx(),
}
GOOD_ACC = {"MX": mint(), "MY": mint(), "A1": acct(), "A2": acct()}
GOOD_EV = [
    {"ev": "run", "mode": "normal"},
    {"ev": "mint", "asset": "X", "mint": "MX"},
    {"ev": "mint", "asset": "Y", "mint": "MY"},
    {"ev": "refused", "source": "on_chain", "what": "allocation", "sig": "REF"},
    {"ev": "refused", "source": "on_chain", "what": "self_approval", "sig": "SELF"},
    {"ev": "approval", "approved": "true", "account": "A1", "sig": "APPR"},
    {"ev": "refused", "source": "rpc_preflight", "what": "half_signed"},
    {"ev": "settled", "act": "1", "sig": "SET1"},
    {"ev": "public", "act": "1", "accounts": "A1,A2"},
    {"ev": "settled", "act": "2", "sig": "SET2"},
    {"ev": "public", "act": "2", "accounts": "A1,A2"},
    {"ev": "done", "mode": "normal"},
]


def run(events, txs=None, accs=None):
    txs = dict(GOOD_TX, **(txs or {})); accs = dict(GOOD_ACC, **(accs or {}))
    obs.tx = lambda url, sig: txs.get(sig)
    obs.account = lambda url, key: accs.get(key)
    return obs.observe("fake", events)[2]


def swap(i, **kw):
    ev = [dict(e) for e in GOOD_EV]; ev[i].update(kw); return ev


class Observe(unittest.TestCase):
    def test_a_good_run_passes(self):
        self.assertEqual(run(GOOD_EV), [])

    def test_the_refusals_must_be_the_cited_errors(self):
        self.assertTrue(run(GOOD_EV, txs={"REF": GOOD_TX["SELF"]}))
        self.assertTrue(run(GOOD_EV, txs={"SELF": GOOD_TX["REF"]}))
        self.assertTrue(run(GOOD_EV, txs={"REF": None}), "a refusal that is not on chain passed")

    def test_a_settlement_must_succeed_with_two_signatures_and_only_token_2022(self):
        self.assertTrue(run(GOOD_EV, txs={"SET1": tx({"InstructionError": [0, {"Custom": 24}]})}))
        self.assertTrue(run(GOOD_EV, txs={"SET1": tx(sigs=1)}))
        self.assertTrue(run(GOOD_EV, txs={"SET2": tx(progs=(T22, "SomeOtherProgram1111111111111111111111111"))}))
        # ... and nothing else by CPI either
        self.assertTrue(run(GOOD_EV, txs={"SET1": tx(inner=("SomeOtherProgram1111111111111111111111111",))}))

    def test_each_signature_is_bound_to_the_accounts_it_is_claimed_for(self):
        # a real, successful, two-signature Token-2022 transaction -- about some other accounts
        self.assertTrue(run(GOOD_EV, txs={"SET1": tx(keys=("Z1", "Z2"))}))
        self.assertTrue(run(GOOD_EV, txs={"REF": tx({"InstructionError": [0, {"Custom": 24}]}, keys=("Z1",))}))
        self.assertTrue(run(GOOD_EV, txs={"APPR": tx(sigs=1, progs=(T22,), keys=("Z1",))}))
        self.assertTrue(run(GOOD_EV, txs={"SELF": tx({"InstructionError": [0, "MissingRequiredSignature"]},
                                                     sigs=1, progs=(T22,), keys=("Z1",))}))

    def test_the_observer_sees_zero_and_an_approved_confidential_account(self):
        self.assertTrue(run(GOOD_EV, accs={"A2": acct(amount="5000")}))
        self.assertTrue(run(GOOD_EV, accs={"A2": acct(approved=False)}))
        self.assertTrue(run(GOOD_EV, accs={"A2": acct(ct=False)}))

    def test_the_mint_is_gated_with_no_auditor(self):
        self.assertTrue(run(GOOD_EV, accs={"MX": mint(auto=True)}))
        self.assertTrue(run(GOOD_EV, accs={"MX": mint(auditor="key")}))

    def test_the_approval_must_have_succeeded(self):
        self.assertTrue(run(GOOD_EV, txs={"APPR": tx({"InstructionError": [0, "MissingRequiredSignature"]})}))

    def test_a_run_missing_a_step_fails(self):
        for drop in ("allocation", "self_approval"):
            self.assertTrue(run([e for e in GOOD_EV if e.get("what") != drop]), drop)
        self.assertTrue(run([e for e in GOOD_EV if e["ev"] != "settled"]))
        self.assertTrue(run([e for e in GOOD_EV if e["ev"] != "public"]))
        self.assertTrue(run([e for e in GOOD_EV if e["ev"] != "done"]))
        self.assertTrue(run([e for e in GOOD_EV if e.get("act") != "2"]), "act 2 missing passed")
        self.assertTrue(run([e for e in GOOD_EV if e["ev"] != "approval"]))
        self.assertTrue(run([e for e in GOOD_EV if e.get("source") != "rpc_preflight"]))
        self.assertTrue(run([e for e in GOOD_EV if e.get("mint") != "MY"]))

    def test_an_unknown_refusal_kind_is_not_waved_through(self):
        self.assertTrue(run(swap(3, what="something_else")))

    def test_the_short_control_must_refuse_and_settle_nothing(self):
        short = [{"ev": "run", "mode": "short"}, {"ev": "mint", "asset": "X", "mint": "MX"},
                 {"ev": "refused", "source": "pre_sign_check", "agreed": "20000"}, {"ev": "done"}]
        self.assertEqual(run(short), [])
        self.assertTrue(run(short[:2] + short[3:]), "a short run with no refusal passed")
        self.assertTrue(run(short[:3] + [{"ev": "settled", "act": "1", "sig": "SET1"}] + short[3:]))


if __name__ == "__main__":
    unittest.main(verbosity=1)

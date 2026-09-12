# STATUS — Mora / Stocklana 2026

| | |
|---|---|
| イベント | Stocklana（hackathons.solana.com）。**提出締切 2026-09-18 16:00 ET = 09-19 05:00 JST** |
| 賞金 | $100,000（Solana Foundation） |
| 審査 | 10-02 まで。判定は一問 — *could this be a real app that people will actually use?* |
| **EVENT_START** | **このリポジトリの initial commit**。Mora は全て会期内の新規作業 |
| 再利用の申告 | `aperture-core`（Apache-2.0, psyto）/ `@fabrknt/veil-core`・`@fabrknt/veil-orders`（MIT, npm）を **open-source component として明示申告**する。Stocklana の eligibility は *original work. Open-source components are fine if you say so.* |
| 中心主張 | **オンチェーンのトークン化株は、保有の開示に遅延が無い。Mora はその遅延を機構として復元する。** |

## 並走している他大会（混ぜない）

- **ETHOnline** — Reckn、提出済み。判定窓 9/14 01:00 → 9/17 01:00 JST（R2 ライブ 9/15 01:00、Finale 9/17 01:00）
- **Crypto World's Fair** — Reckn、9/14 20:00 JST → 10/12

Mora は Solana 単独。Reckn とコードも物語も共有しない。

## 未決（founder の手が要る）

1. **`psyto/aperture` は PRIVATE。** 判事が `cargo build` を通すには公開が要る。選択肢＝(a) aperture を公開する (b) 必要部分を Mora に vendor する (c) 非公開のまま動画とバイナリで出す。**(a) は `project_gtm_public_strategy` の「商用engine非公開」に触る**ので founder 判断。**着手は不要 — 提出パッケージング時まで律速にならない。**

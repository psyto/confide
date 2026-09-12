# STATUS — Confide / Stocklana 2026

| | |
|---|---|
| イベント | Stocklana（hackathons.solana.com）。**提出締切 2026-09-18 16:00 ET = 09-19 05:00 JST** |
| 賞金 | $100,000（Solana Foundation） |
| 審査 | 10-02 まで。判定は一問 — *could this be a real app that people will actually use?* |
| **EVENT_START** | **このリポジトリの initial commit**。Confide は全て会期内の新規作業 |
| 再利用の申告 | `aperture-core`（Apache-2.0, psyto）/ `@fabrknt/veil-core`・`@fabrknt/veil-orders`（MIT, npm）を **open-source component として明示申告**する。Stocklana の eligibility は *original work. Open-source components are fine if you say so.* |
| 中心主張 | **オンチェーンのトークン化株は、保有の開示に遅延が無い。Confide はその遅延を機構として復元する。** |

## 並走している他大会（混ぜない）

- **ETHOnline** — Reckn、提出済み。判定窓 9/14 01:00 → 9/17 01:00 JST（R2 ライブ 9/15 01:00、Finale 9/17 01:00）
- **Crypto World's Fair** — Reckn、9/14 20:00 JST → 10/12

Confide は Solana 単独。Reckn とコードも物語も共有しない。

## 決着済み

1. ~~`psyto/aperture` が PRIVATE で単独ビルド不能~~ → **2026-09-12 に解決。** 全履歴を監査して
   day-job / 顧客 / 秘密情報のヒット 0 件を確認した上で **`psyto/aperture` を PUBLIC 化**（Apache-2.0、
   `v0.5.1`）。Confide は path 依存をやめ、aperture 自身の README が指定する arm's-length の
   `{ git = "...", tag = "v0.5.1" }` で消費している。**Confide は単独でビルドできる。**

## 未決（founder の手が要る）

1. **Confide 自体をいつ公開するか。** 提出には GitHub / live demo / video のいずれか1つ以上のリンクが
   要る。まだ local only。

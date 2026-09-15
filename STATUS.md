# STATUS — Confide

Confide は **2つの大会に出る**。窓も、判定の対象も、名乗り方も違うので、混ぜない。

| | Stocklana | Crypto World's Fair |
|---|---|---|
| 主催 | hackathons.solana.com | Colosseum |
| 締切 | **2026-09-18 16:00 ET = 09-19 05:00 JST** | **2026-10-12 23:59 PT** |
| 開始 | — | **2026-09-14 06:00 PT**（= 13:00 UTC / 22:00 JST、Official Rules §5） |
| 賞金 | $100,000（Solana Foundation） | Solana トラック $100,000（10件 × $10,000）／全体 $840,000 + seed $2.5M |
| 審査 | 10-02 まで。判定は一問 — *could this be a real app that people will actually use?* | 7基準（web）と6基準（Official Rules §8）の**2系統**。勝者発表 12-05 |
| **窓の扱い** | **EVENT_START = このリポジトリの initial commit**。Confide は全て会期内の新規作業 | **窓内のみが判定対象**。基準線は `cwf-2026-baseline` = `765b8bc`。判定されるのは `cwf-2026-baseline..HEAD` **だけ** |

**この2行は同じことを言っていない。** Stocklana には「Confide は全部この大会のために書いた」と言える。
CWF には言えない — 48 commit が窓の外側にある。**片方の言い方をもう片方のフォームに書くと嘘になる。**
根拠と手順は [`docs/WORK-WINDOW.md`](docs/WORK-WINDOW.md)、規約は同ディレクトリにハッシュ付きで pin してある。

## 再利用の申告（両大会共通、フォームの欄に書く）

実際に依存しているものだけ。README の *Built on* と DESIGN §5 の表が正で、ここはその写し。

| Component | Origin | License | 扱い |
|---|---|---|---|
| `aperture-core` | `psyto/aperture`、**事前作業** | Apache-2.0 | `{ git = "…", tag = "v0.5.1" }` で arm's-length 参照 |
| `aperture-receipts` | `psyto/aperture`、**事前作業** | Apache-2.0 | content-blind な on-chain receipt（native Solana program） |
| Confide 本体 | **このリポジトリ** | Apache-2.0 | embargo 機構（I1–I3）、k-of-n 共有、equity 層、demo |

- Stocklana の eligibility: *original work. Open-source components are fine if you say so.*
- CWF: *"Builders may use pre-existing code, but teams must disclose all relevant past development
  work in the submission form."* — **repo に書いてあることは開示にならない。フォームに書いて初めて開示。**

## 1人1プロダクト

> *"Only one product submission is allowed per team—and therefore one per individual—during each
> hackathon."* — Official Rules §7 も同旨（`Entrant may only be a Member of one (1) Team.
> A Team may only submit one (1) Project Submission at a time.`）

*during each hackathon* なので**大会ごと**。Confide を Stocklana と CWF の両方に出すのは規約上塞がれて
いない（排他条項は Official Rules に無い）。ただし **CWF に出せるのは Confide か Reckn のどちらか一方**。

## 並走している他大会（混ぜない）

- **ETHOnline** — Reckn、提出済み。**Round 2 に非選出**（2026-09-14）。ただし partner prize の資格は
  残っており、finale は 09-17 01:00 JST
- **ETHGlobal Tokyo 2026-09-25 → 09-27** — Reckn の live lane、Uniswap Foundation Continuity track
- **Crypto World's Fair** — **Confide**。Reckn は 2026-09-14 の founder ruling で**撤回**
  （`psyto/reckn` の `docs/cwf-2026/RETRACTED-2026-09-14.md`）。二つのレーンを 75:25 で評価した判断で、
  理由は Reckn 側の market / traction が薄く、**先に読まれる4基準で不利**だったこと

Confide は Solana 単独。Reckn とコードも物語も共有しない。

## 決着済み

1. ~~`psyto/aperture` が PRIVATE で単独ビルド不能~~ → **2026-09-12 に解決。** 全履歴を監査して
   day-job / 顧客 / 秘密情報のヒット 0 件を確認した上で **`psyto/aperture` を PUBLIC 化**（Apache-2.0、
   `v0.5.1`）。Confide は path 依存をやめ、arm's-length の `{ git = "...", tag = "v0.5.1" }` で消費して
   いる。**Confide は単独でビルドできる。**
2. ~~Confide 自体をいつ公開するか~~ → **解決済み。** `github.com/psyto/confide` は **PUBLIC**、
   `psyto.github.io/confide/` は 200、動画 `youtu.be/KQsRwP8HTs0` も 200。提出に必要なリンクは3種類とも
   生きている（確認 2026-09-15）。CWF の Official Rules §8(e) は **Open-source 自体が審査基準**なので、
   これは要件であると同時に加点でもある。

## CWF 作業の再開地点（2026-09-15 に中断、Stocklana 提出を優先）

窓内の作業は `git log cwf-2026-baseline..HEAD`。seizure は設計 → 証明 → プログラム → ローカル実行まで
進み、**end-to-end の手前で止まっている**。止めているのは暗号でも設計でもなく輸送手段ひとつ。

| | |
|---|---|
| 動く | 3本の証明がライブ ZK プログラムに受理される（`./scripts/seizure-proofs.sh`）。context state account 3つを作成・検証・読み返し確認済み。プログラムは SBF ビルド + ローカルデプロイ済み |
| 止まっている | **U128 range proof が 1,237 バイトで、レガシー tx 上限 1,232 を5バイト超える**（authority を loan PDA にした場合）。オリジネーションが3本中2本までしか進めない |
| 次の一手 | [`docs/SEIZURE.md`](docs/SEIZURE.md) §8-3。**address lookup table を推奨** — record account 方式と違い、新しい信頼点も新しい口座所有権も持ち込まず、必要な32バイトちょうど浮く |
| 注意 | デプロイは `cargo build-sbf --arch v3`。既定ターゲットはランタイムに蹴られる。`declare_id!` は仮の `SeiZure111…` のままで、実デプロイ ID と違う |

Stocklana 起点の commit もこの窓の内側に入るが、**規約上の問題はない** — CWF が判定するのは
「窓内に完成した作業」であって動機ではなく、どちらも同じプロダクトの作業。

## 未決（founder の手でしか動かない）

1. **traction がゼロ。** 7基準のうち market size / viability / traction / founder + market fit の4つが
   非エンジニアリングで、**先に読まれる**。うち traction は**何を書いても埋まらない** — 外部の誰かが
   実際に使った事実しか埋められない。**これは Reckn を CWF から撤回させた行そのもので、Confide も
   現状ゼロ。** リードタイムが不可逆なので、窓の序盤に founder が投げないと 10-12 に間に合わない。
   最有力は README が既に名指ししている相手 — **発行体（Backed / Kraken）は障害ではなく顧客**、
   および xStocks を担保に取っている **Jupiter Lend**。agent は誰にも接触しない。
2. **CWF のプロジェクト登録**（`colosseum.com`、10-12 23:59 PT まで）と**フォームの過去作業欄への開示**。
   記入元は [`docs/WORK-WINDOW.md`](docs/WORK-WINDOW.md) と上の再利用表。
3. **9/14 公開のトラック / スポンサー / 審査員 / フォーム項目を読む。** Tempo トラックは条件未公開
   （"Session details coming soon"、9/16 workshop）。Solana トラックだけが $100,000 / 10件 と判明。
4. **README / DESIGN の "written in-window" を CWF 向けにどうするか。** 両方の表が Confide を
   *written in-window* と書いている。これは **Stocklana の窓**では真だが、**CWF の窓では偽**
   （48 commit が 09-14 06:00 PT より前）。**同じ public repo を両方の審査員が読む。**
   CWF の審査員には二重の意味で不利 — 誤読されれば虚偽申告に見え、正しく読まれても
   「窓内の成果」がどれか分からない。`docs/WORK-WINDOW.md` への導線を README に置くのが最小の手当て。
5. **CWF 提出動画は2本** — 2〜3分のプレゼンと3分以内のデモ。**既存の 2分動画とは別物**で、提出時に作る。

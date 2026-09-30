# STATUS — Confide

Confide は **2つの大会に出る**。窓も、判定の対象も、名乗り方も違うので、混ぜない。

| | Stocklana | Crypto World's Fair |
|---|---|---|
| 主催 | hackathons.solana.com | Colosseum |
| 締切 | ~~2026-09-18 16:00 ET~~ → **訂正 2026-09-19: 2026-09-25 16:00 ET**（= 09-26 05:00 JST）。**1週間ずれていた。** 09-15 に提出済みだが **"Edits are allowed until submissions close"** なので**まだ差し替えられる** | **2026-10-12 23:59 PT** |
| 開始 | — | **2026-09-14 06:00 PT**（= 13:00 UTC / 22:00 JST、Official Rules §5） |
| 賞金 | $100,000（Solana Foundation） | Solana トラック $100,000（10件 × $10,000）／全体 $840,000 + seed $2.5M |
| 審査 | 10-02 まで。判定は一問 — *could this be a real app that people will actually use?* | 7基準（web）と6基準（Official Rules §8）の**2系統**。両方とも [`docs/cwf-2026/CRITERIA.md`](docs/cwf-2026/CRITERIA.md) に出典つきで pin。**ここに書き写さない** — 一度腐った。勝者発表 12-05 |
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
   `psyto.github.io/confide/` は 200、動画も 200。提出に必要なリンクは3種類とも
   生きている（確認 2026-09-15）。CWF の Official Rules §8(e) は **Open-source 自体が審査基準**なので、
   これは要件であると同時に加点でもある。

## Stocklana は提出済み（2026-09-15）— **2026-09-21 に全欄を差し替え済み**

**2026-09-21、founder が `full.md`（4,969字）と `short.txt`（160字）の両方をフォームに貼り直し、
YouTube の title / description / 英語字幕 / 日本語字幕も更新。** 09-15 以降の 20 回ぶんの変更、
469,477 口座、$24.0m、SEC の日付と 0.25% 上限が、これで全部フォームに入っている。

**フォームはこのリポジトリが唯一読み返せない成果物。** だから代わりに
`./scripts/pasted.sh` が、貼った時点のファイルの sha256 を `_submission/pasted.json` に残す。
以後 `docs-consistency.sh` が **「貼ってからファイルが動いたか」** を毎回判定する
（わざと壊して確認済み: 1字追加・記録の消失・ファイルの消失）。
**フォームを見ているのではなく、こちら側から同じ問いを聞いている。**

**締切前にもう一度やること（09-25 16:00 ET まで編集可）。** 数字は動く —
capacity は1日で $1.17m、口座数は3日で 730 動いた。**09-25 の朝に**
`usage-scan.sh` → `kamino-reserves.sh` → `capacity.sh` → 差分があれば貼り直し →
`./scripts/pasted.sh stocklana-full stocklana-short`。
**審査は 09-25 から 10-02 で、その間フォームは凍る。**


**2026-09-19 に確定。** この行は1週間ずれていた。founder がフォームのページを読んで判明した:

| | |
|---|---|
| 締切 | **Friday 25 September, 4:00pm ET**（= 09-26 05:00 JST）。ページのカウントダウンは 7 days |
| 判定 | **through 2 October**、勝者はサイトで発表 |
| **編集** | ***"Edits are allowed until submissions close"*** — **提出文を差し替えられる** |
| 規模 | **登録 743、提出済み 131**（2026-09-20 にページから再読。09-19 は 690 / 121 だった — 一日で提出が10件増えている） |
| 判定の一問 | *could this be a real app that people will actually use?* — 判事が見るのは **real user and problem / working end-to-end demo / a reason it belongs on Solana / quality of execution** |
| リンク要件 | *"at least one link: GitHub, live demo, or video"* — 3種類とも生きている |
| **動画の尺** | **制限なし。** ページ全文を読んで確認（2026-09-20）。**「2〜3分」は CWF の数字**で、Stocklana のものとして確認されたことは一度も無かった。`Confide_Stocklana_20260920.mp4` は 2:22 で、そのまま出せる |
| **「何を作るか」の一覧** | ページが列挙している最初の項目が ***"Trading: 24/7 venues, order books, **stock-to-stablecoin swaps**"*** — **この大会が募集している題目そのもの**。提出文はこの語を使うべき。続く *"Credit and yield: borrowing against stocks"* が担保側、*"Infrastructure: ... corporate actions ..."* が `confide-equity` |
| 両大会への提出 | ページ自身が *"Taking it further after Stocklana? Colosseum's World's Fair is the next stop"* と書いている。**主催者が明示的に勧めている** |

**なぜ間違えたか記録しておく。** `2026-09-18 16:00 ET` は出典なしで書かれていた。実際は 09-25 で、
**丸1週間の余裕を「過ぎた」と扱っていた。** 出典の無い日付は、出典の無い判定基準
（[`docs/cwf-2026/CRITERIA.md`](docs/cwf-2026/CRITERIA.md)）と同じ失敗。**大会の事実は出典つきで書く。**

**09-15 以降に 96 commit 入っている。** 提出文に反映したのは2つ:

- **挟み撃ち** — `autoApproveNewAccounts` は Kamino が要求する設定であり、同時に発行体を経路に置く
  設定。**1,992 / 1,992 が門の側**で、銘柄を変えても逃げられない
- **escrow の2つ目の出口** — 差し押さえだけでなく**保有者に戻る道**が devnet で通った
  （loan `9yfKfFD5…` が `released`）。返済ではなく attested release であることも明記

文字数は 5,000 ちょうど。`docs-consistency.sh` が上限を検査している。

3リンクとも生存を確認して出した。`healthcheck.sh` は8項目 all clear、`cargo test` 29。
**判定は 10-02 まで続き、devnet はその間にリセットされうる。** 週次で `./scripts/healthcheck.sh` を
回すこと。復旧手順は [`docs/DURABILITY.md`](docs/DURABILITY.md)。**mainnet の核心発見はリセットされない。**

**バウンティは5枠。全部見送る。** 記録しておく（**09-19 に PreStocks と Tessera を追加検討**。
それまでこの節は Meteora と Clawpump の2つしか検討しておらず、「3枠とも」と書いていたのは
**検討していないものを検討済みとして数えていた**）:

- **PreStocks**（$10,000、3名）— *lending/collateral* を明記していて領域は最も近い。**それでも見送る。**
  資格条件が *"projects that integrate any non-PreStocks pre-IPO tokens will be ineligible"* で、
  Confide は Backed `SPCXx` と Backpack `SPCX.US`（どちらも pre-IPO）を扱っている。**外して資格を
  取るのは Clawpump と同じ理由で拒否。** さらに要項は *"drive value for PreStocks"* を求めており、
  こちらの最も興味深い結果は**彼らの mint 上で機能が実行できない**こと。**スポンサーに自社製品の
  報告書を資金提供させに行く**形になる。→ [`docs/cwf-2026/PRE-IPO.md`](docs/cwf-2026/PRE-IPO.md)
- **Tessera**（$6,000）— **技術的に当たらない。** T-SpaceX / T-OpenAI / T-Kalshi は Token-2022 だが
  **秘匿転送の拡張が無い**。空にする枠も無く、Confide が言えることが一行も無い（mainnet で確認）
- **Pyth**（非現金、Pyth Pro 3ヶ月）— price feed は 27-DAYS が理由つきで拒否済み。非現金の賞のために
  記録済みの判断を覆さない

- **Meteora DBC** — 領域が違うだけでなく**技術的に噛み合わない**。AMM / ボンディングカーブのプールは
  スワップ出力を計算するため**取引額を平文で読む必要がある**ので、Token-2022 の秘匿残高はカーブに
  乗せた瞬間に解かれる。これは Confide が MEV 軸を捨てて「約定後の保有」に張り替えたのと同じ線で、
  **避けた領域であって手が届かない領域ではない**。
- **Clawpump** — 要件が *"Launch your token with a stock-paired liquidity pool"*。Confide は
  **自前 mint を作らないことを提出文に明示的な設計判断として書いている**（ラップは借り手が担保に
  取る物ではなく、裏付けを持てばこの層が消そうとしている信頼点に自分がなる）。賞のために発行すると
  自分の書いた判断を撤回することになり、判事が両方読めばその矛盾の方が目立つ。

**出した時点で real user and problem は空白。** 誰にも見せず、発行体にも聞いていない。Codex の
判定は「一次選考を通さない」で、根拠は需要の不在。**判定期間中でも遅くない一手 = Backed / Backpack
への一問**（「auditor 鍵を null のままにしているのは、埋める設定が無いからか」）。

## CWF 作業の再開地点（2026-09-15 に中断、Stocklana 提出を優先）

窓内の作業は `git log cwf-2026-baseline..HEAD`。seizure は設計 → 証明 → プログラム → ローカル実行まで
進み、**end-to-end の手前で止まっている**。止めているのは暗号でも設計でもなく輸送手段ひとつ。

| | |
|---|---|
| 動く | 3本の証明がライブ ZK プログラムに受理される（`./scripts/seizure-proofs.sh`）。context state account 3つを作成・検証・読み返し確認済み。プログラムは SBF ビルド + ローカルデプロイ済み |
| **完了** | **seizure は end-to-end で通った** — `./scripts/seizure-e2e.sh`。借り手の 173,000 が、争えないデフォルトで貸し手に移る。両側とも秘匿のまま、借り手は handover 後に一度も署名しない。前提4つは全部潰れた |
| **devnet でも通った** | プログラム `Gn3rzw8U…`、escrow `HfdcgCmf…`（loan PDA 所有、残高 0）、貸し手 `Kzv6RiLo…`（173,000 保有）、loan 口座 `26QJWCRw…` が `seized=1`。**クリックで確認できる** |
| **戻り道も通った（2026-09-19）** | escrow は一方通行の扉だった — 入ったら出口は差し押さえだけ。`MODE=release ./scripts/seizure-e2e.sh` で **173,000 が保有者に戻った**。loan `9yfKfFD5…` は `released=1` / `seized=0`、740バイト。貸し手は**借り手が武装した宛先以外へ送れず**、借り手に再署名もさせられない。**返済ではなく attested release** — principal はこのプログラムを通らない |
| **普通の保有者にも届いた（2026-09-19）** | ATA は `ImmutableOwner` を持つので**永久に handover できない** — ウォレットが作るのは ATA なので、これが多数派だった。順序を逆にして解決: **貸し手**が escrow を開き、承認を受け、**空のまま** loan PDA に渡す。保有者は `spl-token transfer --confidential`（普通の CLI、このリポジトリのものは何も使わない）で送るだけ。着金先は pending 残高で、所有者がプログラムなので誰も確定できない — そのための命令 `apply_pending`（5番）を追加した。devnet 実走: escrow `5vrhLBsy…`、loan `7aveKFCE…`(741バイト)、`lender-check.sh` 全項目通過。**代償は floor が証明ではなく貸し手の申告になること**（mode B / `FLOOR_ATTESTED`）— 自分の帳簿には十分だが、**第三者には何も証明しない**ので lender-check はそう表示する |
| **交換が1トランザクションで通った（2026-09-20）** | ローンは第三者（escrow）が要るので、発行体の門と ImmutableOwner の両方に当たっていた。**交換なら第三者が要らない** — 両脚が1トランザクションに入るので、Solana の原子性がそのまま escrow の代わりになる。結果、**プログラム不要・発行体の追加承認不要・ATA のまま可**。devnet 実走: 4口座すべて ATA（`immutableOwner: true`）で公開残高は全部 0 のまま、tx `2RksP5AM…` は**署名2・命令2・29,417 CU・1,006バイト**。秘匿ゆえの危険（相手が約束より少なく送る）は、**受取側が署名前に検証済み context から自分で金額を復号する**ことで解消（`swap-check`）。詳細は [docs/cwf-2026/THE-SWAP.md](docs/cwf-2026/THE-SWAP.md) |
| **DvP（株↔現金）が1トランザクションで通った（2026-09-20）** | 株↔株は稀で、**株↔現金は全てのブロック取引**。`MODE=dvp ./scripts/swap-e2e.sh` で、**50,000株と $8,750,000（＄175/株）が同一トランザクションで交換された** — tx `4gzku3FW…`、署名2・命令2・29,849 CU・1,006バイト。4口座すべて ATA で**公開残高は全部 0**、数量も価格も外からは見えない。現金 mint は mainnet の PYUSD を写した（6桁・門あり・**監査鍵は空**・永久デリゲート・凍結権限）。**残る差分は PYUSD の 0bps `transferFeeConfig` ひとつ** — 手数料設定のある mint は 0bps でも平文の `Transfer` を拒否する（監査鍵の有無ではないことを、変数を1つずつ変えた実走で切り分け済み）。必要なのは `TransferWithFee`（証明5本 + U256 range proof を record 口座経由で提出）で、経路の問題であって暗号の問題ではない。[docs/cwf-2026/THE-SWAP.md](docs/cwf-2026/THE-SWAP.md) |
| **PYUSD の設定を完全に写した DvP が通った（2026-09-20）** | 前項で唯一残っていた差分＝0bps `transferFeeConfig` を解消。現金脚を `TransferWithFee`（証明**5本**）に切り替え、**U256 range proof を `spl-record` 口座に分割書き込みして「口座から読む」検証形式で提出**した。tx `5ZrJPGRL…` は**1トランザクションに `confidentialTransfer` と `confidentialTransferWithFee` が同居**し、59,804 CU・1,074バイト。**規則の違う2資産を1トランザクションで合成できる**ことの実証。走らせて初めて出た事実3つ: ①ブロックハッシュは14本の寿命に足りない（13本目が `BlockhashNotFound`）→ 証明をキャッシュして再署名する方式に ②U256 検証は既定20万CUに収まらない → `SetComputeUnitLimit` が要る ③`go` の出力を `/dev/null` に捨てていて失敗理由が消えていた。決済経路の差分はこれで**ゼロ** |
| **門を通った人はまだ誰もいない（2026-09-20）** | 設定ではなく**口座**を数える測定がどこにも無かったので `./scripts/usage-scan.sh` を書いた。保有者のいる5銘柄（Backed の Apple / NVIDIA、PreStocks の SpaceX / Anthropic）で **469,477 口座を走査し、秘匿転送に設定されたものは 0 件**。最初の走査で「400バイト超」が7件出たが、全部 `pausableAccount` と `transferHookAccount` で大きいだけだった（サイズは示唆、拡張リストが判定）。**先行者はおらず、出遅れてもいない。** web/usage.json に出力し、docs-consistency.sh に検査を追加（わざと壊して落ちることを確認済み） |
| **古い証拠は無傷** | レコードは 415 → 740 バイトに**追記**で伸ばした。`may_settle` は `LOAN_LEN_V1` で長さを見るので、**公開動画が映している loan `26QJWCRw…`（415バイト）は再デプロイ後も読める**。定数だけ伸ばしていたら、テストは全部通ったまま証拠が静かに腐っていた |
| 資金の誤解 | 「0.62 SOL で不可能」は**誤り**だった。`solana balance` は `solana config` の鍵を読み、それが別プロジェクト（liquet）のものだった。本物の `~/.config/solana/id.json` は最初から 134 SOL。実費は既定 0.936 / `--max-len` 0.489 SOL |
| 実際の障害 | 公開 RPC が 92KB のアップロードをレート制限すること。専用エンドポイントで解決 |
| 次の一手 | 提出動画2本（2〜3分プレゼン / 3分以内デモ）と traction |
| 注意 | デプロイは `cargo build-sbf --arch v3`。既定ターゲットはランタイムに蹴られる。~~`declare_id!` は仮の `SeiZure111…` のまま~~ → **2026-09-19 に訂正**: `lib.rs:99` は実デプロイ ID `Gn3rzw8U…` を宣言済み（`7f8e57a` の再デプロイで一致した）。この行が腐っていた |

Stocklana 起点の commit もこの窓の内側に入るが、**規約上の問題はない** — CWF が判定するのは
「窓内に完成した作業」であって動機ではなく、どちらも同じプロダクトの作業。

## CWF の27日計画

[`docs/27-DAYS.md`](docs/27-DAYS.md)。要点だけ:

**賭け** — 名指しのリスク責任者から、**数字入りの書面の条件付き判断**を1通取る。
「条件が揃えば LLTV N% / キャップ C まで取る」。公の表明は求めない（リスク責任者にとって
ガバナンス上の負債になるため、85〜95% で取れないと値付けされた）。

**制約1（founder）** — **買い手が自分の単位で benefit を読め、エンジニアを呼ばずに試せること。**
prívacy ではなく LLTV・キャップ・不良債権。1コマンドで、生のチェーンデータから埋まる。

**制約2** — **積み増しであって書き換えではない。** Stocklana の審査は 10-02 まで続き、その提出物は
この repo にリンクしている。既存の主張は消さない。

**変わる見解が1つ** — 提出文の「発行体は顧客であって障害ではない」。**発行体は適格性の門番で
あって買い手ではない**、が現在の読み。これは静かな書き換えではなく**日付つきの見解変更**として
扱い、check-in の素材にする。

**引き返し不能点 09-29。**

## CWF の weekly check-in

**1分の動画を毎週。** 提出動画2本（2〜3分プレゼン / 3分以内デモ）とは別物で、審査員は**軌跡**を見る。
初回は **2026-09-18 に開く**。

設問は3つ:

| | |
|---|---|
| 01 | **What changed?** — 作ったもの、直したもの |
| 02 | **What did you learn?** — *a test, conversation, or decision* |
| 03 | **What is next?** — 向かっている先を名指しする |

**02 が traction の締切を作っている。** 「conversation」が選択肢に入っている以上、9/18 より前に
Kamino の市場所有者へ ask を投げれば、初回に報告できる会話が存在する。投げなければテストか
決定で埋めることになり、成立はするが、**2回目以降に語れる内容が痩せる**。ask は返信待ちの時間が
要るので、遅らせるほど不利になる。

### 初回（9/18）の素材 — 全部そろっている

- **What changed** — seizure が設計からプログラムへ、devnet で end to end。`Gn3rzw8U…`、loan は
  `seized` のまま。テスト 21 → 69
- **What did you learn** — committee の最初のテストが落ちた。**コミットメントではなく、開いた先が
  落ちた**。鍵なしデモは 173,000 を封印して 0 を公開していた。*このプロジェクトが防ぐと言っている
  失敗が、それを防ぐ機構のデモの中にあった* — 画面に出せて（`0` → `173,000`）、価値提案そのものを
  実演する
- **What is next** — 発行体との会話。機能を入れ、ゲートを閉め、鍵の枠を空けたのは彼らで、
  live mint には彼ら抜きでは届かない

### 見込み日程

9/18 / 9/25 / 10/2 / 10/9 の4回。**毎週何を語るかを意識して作業を並べる**ためのもので、
逆に言えば「今週語ることが無い」週を作らない。

## 受賞確率の再推定（Codex、2026-09-22）

**現金賞・公式受賞を1つでも得る確率。** 採択後の投資面談は含まない。**推定であって測定ではない** —
この repo の他の数字と違い、導出も再現もできない。日付と出典を付けて置く。

| 大会 / プロジェクト | 受賞 | 上位賞・Finalist |
|---|---:|---:|
| **Stocklana / Confide** | **31%**（24–39%） | 10%（7–14%） |
| CWF / Confide | 4.8%（3.5–6.5%） | Grand **0.4%**（0.2–0.7%） |
| ETHGlobal Tokyo / Reckn | 11%（6–16%） | Top 10 **5%**（3–8%） |

CWF は前回 2.8% → **4.8%** に上方修正。理由は *Confide が概念ではなくなった* こと — 二署名・一取引・
双方の金額非公開の DvP が devnet で再現でき、公開残高はゼロのまま。**上限を決めているのは
CWF 用の narrated presentation と demo video が未完成なこと。** 内訳は Solana track $10k が 3.2%、
全チェーン共通の Grand / 次点20枠が約2%（重複受賞しうるので加算しない）。登録は約5,000 builders。

**優先順位（Codex）:**

1. **Stocklana — これ以上広げない。** 既存の DvP 証拠を短く鋭く。効くのは機能追加の量ではなく、
   **冒頭15秒で「誰が何を、なぜ今までできなかったか」を理解させること。**
2. **CWF** — Confidential Issuance / Redemption を作るなら CWF 動画の主役にする。完成すれば 6–8% 圏。
3. **Tokyo / Reckn** — 新構想を足さず 013 を本番 Sepolia の資金移動まで通し、4分を demo-first に。

**トップ受賞が 10% に留まる理由は「発行体の承認が必要」という入口が未解決だから** —
[`docs/cwf-2026/ISSUANCE.md`](docs/cwf-2026/ISSUANCE.md) と 0h の「やること」表の *the gate* に同じ。

## 未決（founder の手でしか動かない）

0q. **動画を「初見の審査員」向けに組み直した（2026-09-23）。ヒーローが2回出ていた件も含む。**

   founder の指摘2つ: *ヒーローが何回も出てくる*、*作っている側に自明でも初見には分かりづらい*。
   **両方とも当たっていた。**

   **① `Confide` が2度出ていた。** 転回の場面に `hero` を流用したため — `hero` は必ず
   `<h1>Confide</h1>` を出す。45秒後にタイトルカードが再び現れ、**映画が再起動して見えた。**
   文だけを描く `statement` 種別を追加。

   **② 冷めた目で見ると、最初の35秒、何を見ているのか分からなかった。** 規制の説明から始まり、
   `tape`・`block trade` という金融の隠語が続き、**製品は 1:21、一番強い絵は 1:52**。
   一方 **語彙をまったく要らない画が2つ**あり、両方とも後半にあった。

   | | 新しい順 | 何を分からせるか |
   |---|---|---|
   | 1 | 口座が `0` と言い、173,000株持っている | **これができる** — 語彙ゼロ、16秒 |
   | 2 | 全1,992が同じことをでき、46万口座で2つ試し承認ゼロ | **なのに誰も持っていない**。「それは Token-2022 の機能では」を直ちに潰す |
   | 3 | **Confide** | 名前と、素直な定義 |
   | 4 | DvP の図 | **名前の後**（09-22 の指摘を壊さない） |
   | 5 | 門が閉じている理由 | 診断 |
   | 6 | SEC | **なぜ今か**。「これ」が何か分かった後なら効く |
   | 7-10 | 転回／実演／構造／正直さ | |

   **製品が 0:29 で伝わる**（旧 1:21）。**174秒。**

   **SEC を冒頭から外した理由も書いておく:** 最強の外部事実だが、**画面の中ではなく世界の話**で、
   語彙の要求が最も高く、そして**命令は米国 NMS stock、測った 1,992 は米国外発行**。
   21秒の中では隣の市場の話に聞こえる。

   **組み直しの最中に見つけた不具合:** 場面の `line` が、ナレーションを配る `.map` と**名前衝突**していて、
   画面に出す文が毎回ナレーション全文で上書きされていた。**編集しても画面が変わらない**症状で、
   実物のフレームを見るまで気づけなかった。`say` に改名。

   | やること | |
   |---|---|
   | **音声を作って再収録** | founder の手。台本・尺・無音マスター・10クリップは確定 |
   | **09-25 13:00 PDT** | Stocklana の凍結 |

0p. **動画を Confidential Issuance で組み直した（2026-09-23）。提出文と同じ順になった。**

   founder の指摘: *動画がほぼ DvP のままで、発行は1画面でさりげなく触れているだけ。*
   そのとおりだった。**動画と `full.md` が別の話を冒頭でしていた** — 本文は
   「門が閉じている → 通れる唯一の取引が発行 → 開いた後は二次の DvP」なのに、動画は
   9場面が DvP で発行は7場面目に1つ。審査員が動画を見てから本文を読むと冒頭が食い違う。

   | | 旧 | 新 |
   |---|---|---|
   | 2 hero | *"a stock-to-stablecoin swap"* — **仕組みの名前で、最初の用途ではない** | **Issuance first** — 門が通す唯一の取引 — **then every trade after it**, on the same two instructions |
   | 3 | （5場面目にあった）門の走査 | **nobody can open the door** — 答えを出す前に問題を置く |
   | 4 | so I counted | 同（"Not one" → **two configured, none approved**） |
   | **5** | — | **so the first trade is an issuance**（**この turn が無かった**） |
   | 6 | — | the gate, both ways（拒否 → 決済） |
   | 7 | 4場面目にあった | this account（**間合いは不変**。配分の結果として、ここの方が効く） |
   | 8 | 3場面目の DvP | **and every trade after it** — *発行は second product ではなく、発行体を当事者にした同じもの* |

   **171秒**（2〜3分枠内）。無音マスターはレンダリング済み、10クリップに分割ずみ。

   **組み直しの最中に、名前による束縛が2回捕まえた** — 場面3の名前違いと、配列の余分なカンマで
   入った空要素。**添字で対応させていたら、どちらも黙って違う映像に声が乗っていた。**

   | やること | |
   |---|---|
   | **音声を作って再収録** | founder の手。台本・尺・無音マスターは確定 |
   | **差し替えて投稿** | `healthcheck.sh` が新旧を見る |
   | **09-25 13:00 PDT** | Stocklana の凍結 |

0o. **⚠ 公開中の Stocklana 動画が、いま偽のことを声に出して言っている。再収録が要る。**

   場面6のナレーションは **"Not one."** — 承認ずみが一つも無い、ではなく**設定ずみが一つも無い**の意。
   **切った 2026-09-22 07:14 UTC 時点では正しく、1時間13分後の 08:26 の走査で 2 になった。**

   数字が動いたのではなく**所見が反転している。** しかも提出文は審査員に `usage-scan.sh` を
   走らせるよう誘っていて、走らせると **`2 configured`** と出る。

   | 場面 | |
   |---|---|
   | **6 — so I counted** | *"Two have configured one. None is approved."* に訂正。**事実の修正であって拡張ではない** |
   | **7 — the gate, both ways** | **ステーブルコインの breadth 場面と入れ替え。** 同じ配分が署名前に `Custom(24)` で拒否され、1命令の後に決済する2取引を、`swap-status.sh` がチェーンから読み直した画面で見せる |
   | 9 | 場面3と重複する「4ファイル2台」を落として尺を戻した |

   **178秒**（2〜3分枠内）。無音マスターはレンダリング済み。`07-the-gate.mp4` まで分割ずみ。

   breadth 場面を外したのは `full.md` から `Pools, ever` を外したのと同じ理由 —
   **秒あたりで一番弱く、冒頭が既に言っている。** 門は9場面にわたって説明されていたのに、
   **止まるところを一度も見せていなかった。**

   | やること | |
   |---|---|
   | **音声を作って再収録** | founder の手。台本と尺は確定、`node video/record-presentation.js` は済み |
   | **差し替えて投稿** | 同じ動画を更新するか新規か。`healthcheck.sh` が新旧を見る |
   | **09-25 13:00 PDT** | Stocklana の凍結。**動画が間に合わなければ、説明文に日付つきで「動画は 09-22 07:14 時点を語る」と書くのが次善** |

0n. **Confidential Issuance が動いた（2026-09-23）。門がエラー番号になった。**

   Codex の5条件どおり、5日の打ち切り線に対し**1日**で。[`scripts/issue-e2e.sh`](scripts/issue-e2e.sh)、
   記録は [`docs/cwf-2026/ISSUANCE-RUNS.md`](docs/cwf-2026/ISSUANCE-RUNS.md)。

   | | |
   |---|---|
   | 投資家が口座を開く | configured、**未承認** |
   | 配分を署名前に読む | 20,000株を検証済み context から復号 |
   | **配分を送る** | **チェーン上で拒否** — `Custom(24)` *Account not approved for confidential transfers* |
   | 発行体が署名 | 1命令 |
   | **同じ配分を再送** | **決済** — `Transfer` + `TransferWithFee`、2署名、59,804 CU |
   | 公開残高 | **4口座すべて 0** |

   拒否 `5fqZLgbj3Sijft68iT9U3N8MNEitte4aLrPU6VdcQVytxAb389ZJSJMfHs68tLNYDwaUqSuA11agG7sXmP2HEV5G`
   決済 `29coq95v2k4G2PBdcf42EtraqppMC4nk7QFsgHvMc9gbeCNPjPTYnM6kpza3EkeoeLuugUuPjaW32HefgNWCgxCf`

   **拒否は preflight を切って送っている。** preflight 有効だと RPC 上のシミュレーションで終わり、
   **再現はできても引用できない。** 手数料1回ぶんで、ログつきでチェーンに載る。

   **auditor は終始 EMPTY**（1,992 と同じ設定）。迂回ではなく、この流れが今日動く理由そのもの —
   **一次発行では発行体が送り手なので、送った額を読むのに鍵が要らない。空の slot が止めるのは流通市場。**

   **守り:** 投資家の口座が先に承認されていたら拒否は起きず、**何も実演していないのに同じ見た目**になる。
   だから**着地したエラーを読み**、通ってしまったら exit 1 で「門が持たなかったことが発見であって、
   この script ではない」と言う。承認を先に入れて確認ずみ。
   `refresh-swaps.sh` は拒否が **`Custom(24)` で失敗し続けている**ことを毎回確かめる。

   **やっていないこと:** 発行体は鍵をこちらが持つ devnet。新規の暗号は無い。scoped disclosure は
   解いていない。**redemption は作っていない**（Codex の助言）。

0m. **診断を書き直した（2026-09-22）— 「Token-2022 をもっと使うべき」はデータと合わない。**

   founder の問い: *トークン化株式は Solana で流行っているが Confidential Transfer は使われていない。
   Solana が先駆者であり続けるには Token-2022 をもっと有効活用すべきではないか。*

   **観察は正しく、診断は逆。** 発行体は Token-2022 を使っていないのではない。
   **1,992銘柄すべてで、control 系の拡張を4つ全部使っている** — `permanentDelegate`（誰の残高でも
   動かせる）・`pausableConfig`（全停止）・`transferHook`（全転送で自分のコードが走る）・
   `defaultAccountState`（新規口座は制限つき）。**気づいていない人の設定ではない。**

   拒んでいるのは1つだけで、しかも**その4つと同じ理由で拒んでいる**。全転送にフックを挟み全残高に
   delegate を持つ発行体の設定は、丸ごと「見る・届く」ためのもの。auditor 空の confidential transfer は
   その逆を渡す。

   **Token-2022 の開示モデルは1つしかない** — 全員の全部を永久に読む1本の鍵。入れれば全保有者が
   1者に永久に読まれ、空にすれば誰も何も証明できない。**規制された株式の発行体に正しい設定値は無い。**
   だから無関係な3発行体が同じ設定に辿り着いている。

   **これが仕事の性質を変える:**

   > 「Solana は Token-2022 をもっと使うべき」は**説得の仕事**。
   > 「この拡張には発行体が受け入れられる開示モードが無い」は**建築の仕事**。

   後者は誰の同意にも依存しない。[`docs/cwf-2026/WHY-THE-SLOT-IS-EMPTY.md`](docs/cwf-2026/WHY-THE-SLOT-IS-EMPTY.md)

   **⚠ この repo が測っていないこと: 「Solana が先駆者である」。** 走査は Solana だけ。
   他チェーンとの比較は一度もしていない。**提出物でこの前提に寄りかからないこと** — 今週2件、
   根拠より先に出た主張で成果物を失っている。

   表は [`scripts/slot-roles.sh`](scripts/slot-roles.sh) が `web/slots.json` から生成し、
   `docs-consistency.sh` が照合する。**未知の拡張が現れたら黙って落とさず名指しで止まる**
   （発行体が設定を変えた日に気づくため）。

0l. **⚠⚠ 見出しが変わった。誰かが扉を押した（2026-09-22 08:26 の再測定）。**

   founder が「念のため最新で貼り直したい」と言って測り直したら、**見出しの主張が偽になっていた。**

   | | 前 | いま |
   |---|---|---|
   | 口座 | 465,520 | **469,477** |
   | confidential | **0** | **設定 2 / 承認 0** |
   | Kamino | $23.2m / $84.0m | **$24.0m / $86.2m** |

   **2つとも NVDAx、両方 `approved: false`。**

   | 口座 | |
   |---|---|
   | `5jkuoj8UcgRCVgJo2TGXxDRDxL4DAioCbmhkTugaAxW2` | 09-19 に設定 |
   | `8P31wJSdNfNyVYCSG4dLUJknJi6EWZyYjCVFDhPJKNEu` | **09-21 23:01 UTC**、`IncorrectProgramId` で2回失敗した後 |

   2つ目は **09-21 22:18 の走査（0と出た）より後**。投稿は 09-21 00:37 UTC —
   **順序であって因果ではない。文書はそう書かない。**

   **主張は弱くならず、強くなった。** *"zero are confidential"* → **"two have configured one,
   zero are approved"**。昨日 @KirProzorov が言ったことが測定として現れた形で、
   **門が実在する、こちらが作ったのではない証拠**になった。Backed は署名していない。

   **検査の作り替え:**
   - `usage-scan.sh` が **設定と承認を別に数える**。拡張だけ数えていたら、finding が確認された朝に
     「見出しが壊れた」と報告していた
   - `cwf-form.sh` の守りは「設定が0でない」で落ちる形だった → **フォームが両方の数を述べているか**を見て、
     **いずれかが approved になった日に大きく落ちる**（3通り破壊確認）
   - **新規**: 「設定ずみが0」を現在形で言えない検査。日付つき記録は名指しで除外

   **自分の誤り2件:**
   - 文面更新を「検査が名指しした面」ではなく `docs/**` 全体に広げ、**日付つき記録まで書き換えた** —
     この訂正を記録したレビュー文書自身が偽の文になった。戻した。**検査の方が正しかった**
   - 一括更新が**口座数だけ新しくして「zero」を残した**面が4つ（両方の YouTube 説明文、POST、STORY）。
     **古い主張が新しい数字の隣にあると、検証済みに見える。** 一番危険な形

   全7欄 **11:54 に貼り直しずみ**。`docs-consistency` 緑42・赤0、`healthcheck` all clear。

0k. **提出面は全部 current（2026-09-22 08:17）。両方の検査が赤ゼロ。**

   | 欄 | 貼付 | |
   |---|---|---|
   | `stocklana-full` / `stocklana-short` | 09-22 08:17 | **SEC 先行の新しい背骨が入った** |
   | `cwf-form` | 09-22 08:17 | Brief description・Why now（Kir の修正）・Access instructions（300字） |
   | `cwf-checkin1` | 09-22 08:10 | *"no issuer will approve"* の修正ずみ |
   | `youtube-description` | 09-22 08:00 | 新カット `C86U3R0IgiU` 向け |
   | `cwf-graphic` / `x-post` | 09-21 | 変更なし |

   `docs-consistency.sh` **緑41・赤0**、`healthcheck.sh` **all clear**。

   **⚠ それでも 09-25 の朝にもう一度貼り直すこと。** `full.md` と `short.txt` は
   **469,477 / 1,992 / $24.0m / $86.2m** を引用していて、**チェーンは毎日動く**。
   09-20 に 329,536 が 469,477 になって納品済みの動画が古くなったのは、まさにこれ。
   順序は `0g` にある — **再測定 → 貼り直し → `./scripts/pasted.sh`**、13:00 PDT の凍結まで。

   **残っている founder 作業は check-in 2 の収録だけ**（窓 09-25 08:00 → 09-28 08:00 PDT）。
   台本は [`video/CHECKIN-2.md`](video/CHECKIN-2.md)、58秒。**3日ぶん足りないので 09-25 に読み直す。**

0j. **⚠ リポジトリの外から初めて訂正が来た（2026-09-22）。正しかった。**

   X の投稿に **@KirProzorov** から:

   > "No issuer will approve one" is a bit early if you haven't asked any issuers yet.

   **測ったのは「誰も通っていない」であって「扉が施錠されている」ではない。**
   `autoApproveNewAccounts` が 1,992/1,992 で false、469,477口座で 0 — ここまでが測定。
   「発行体は承認しない」は**根拠の無い主張**で、**誰にも聞いていない。**
   [`docs/reviews/2026-09-22-external-no-issuer-will-approve.md`](docs/reviews/2026-09-22-external-no-issuer-will-approve.md)

   **一番痛いのは、正しい言い方が既に書いてあったこと** — `full.md` は投稿前から
   *"on `NVDAx` it is a conversation nobody has had"* と書いていた。それでも他の4面が過大主張していた。

   | 面 | 状態 |
   |---|---|
   | `_submission/cwf-form.md` | **修正ずみ**（970/1000）。**貼り直しが要る** |
   | `_submission/youtube-checkin1.md` | **修正ずみ**。動画の説明文は編集できる。**貼り直しが要る** |
   | `docs/cwf-2026/x-post.txt` | **凍結。** 投稿した内容の記録で、書き換えたら訂正した事実が消える |
   | `video/CHECKIN-1.md` と収録 | **変更不可。** check-in 1 の窓は 09-21 08:00 PDT に閉じた |

   **4面のうち2面は永久に直せない。** 提出した動画と投稿済みのスレッドに、測定かどうか確かめる前に
   入ってしまった。`docs-consistency.sh` が *"no issuer will approve"* とその変種を全提出面で
   止めるようにした（わざと壊して確認ずみ）。

   **主張そのものは無傷** — 「no incumbent」は「誰もやっていない」に乗っていて「誰もできない」には
   乗っていない。ただし**発行体に聞くことが、やる価値のある行動に変わった**（*what is not built* の
   1番目に既にある）。

0i. **`Confide_Stocklana_20260922.mp4` を founder が収録（2026-09-22）。投稿がまだ。**

   **2:28**、1920x1080、AAC、字幕トラックつき。無音マスター 177.1秒に対し 148.6秒 —
   声が速く、クリップを声に合わせ直したため。**納品物が正**。

   **納品物で測ったこと**（台本ではなく実物）:

   | | |
   |---|---|
   | 全10場面の台詞 | **音声で確認**。字幕は当てにしない |
   | 最強の10秒 | 絵は 55.0秒まで `public balance 0`、55.8秒には `173000 units`。声の間は 53.8秒に0.57秒。**出荷した 09-20 のカット（0.62秒）と同じ構造** |
   | 台詞の抜け | 最長の無音は **98.5秒の1.44秒**（「Nobody chose this」と「You cannot do this on one」の間）。09-20 は1秒超がゼロだったので、そこだけ違う。**判断は founder** |

   **⚠ ASR が16秒ぶん字幕を落としていた。** 83.4〜99.8秒に1つもキューが無い — 場面7まるごと。
   **音はある**（その窓は mean -24.1 dB、直前の場面が -23.1 dB。絵はステーブルコインの表）。
   `fix-captions.sh` は「タイミングは触らず語だけ直す」約束なので、穴埋めは別の段にした —
   [`scripts/caption-gap.py`](scripts/caption-gap.py)。**隙間が6秒超／その音が無音でない／台本の場面が
   ちょうど1つ欠けている、の3つを確認してからでないと書かない**（3つともわざと壊して確認ずみ）。
   結果が [`video/captions-20260922.srt`](video/captions-20260922.srt)、68キュー、全10場面。

   語の補正は5件。**うち2件は既にあった規則が外していた** — `confidential transfer switched` は
   小文字専用で今回は文頭、`and everyone` は行末固定で今回は行中。**規則は、ファイルを読み直すまで
   修正ではない。** 新規は *bite for bite* → **byte for byte**（その場面が説明する検査の主張そのもの）と
   *let's* → *lets*。

   | やること | |
   |---|---|
   ~~**投稿**~~ → **完了。`https://youtu.be/du0Twt_c9wQ`（2026-09-23、再構成カット）。
   `C86U3R0IgiU` は 09-22 の版。**
   `gilIzns5joM` は **404 を返す**ので、旧版は削除ずみ。「1つの問いに1つの答え」は
   `healthcheck.sh` が毎回測る。全面（`README.md`・`web/index.html`・`docs/DURABILITY.md`・
   `video/README.md`・`healthcheck.sh`）を新 ID に差し替えた。

   | 残り | |
   |---|---|
   | ~~**字幕を上げる**~~ | **完了。** アップロード版の英語トラックが `du0Twt_c9wQ` で生きている（`healthcheck.sh` が毎回 `captionTracks` を読む）。**自動生成トラックは消せない** — 2026-09-24 に founder が削除したが、次の読み取りで `a.en` が戻っていた。YouTube 側の挙動で、動画所有者に拒否権が無い。だから検査は「消えていること」ではなく **「人が上げたトラックが存在すること」** を要求する |
   | ~~**説明文とチャプターを貼る**~~ | **完了**（2026-09-24、`pasted.json` に記録）。タイトルも同日 *private block trades* に変更、oembed から読み返して `_submission/youtube.md` を合わせた |

0h. **⚠ 提出物の背骨を入れ替えた（2026-09-22、founder の判断）。動画の再収録が残っている。**

   founder の指摘: *「ナラティブが変わっているので、小手先の更新ではなく構成を含め全体を見直すべき。
   アピールすべきところをアピールできていない」* — そのとおりだった。**一番強い外部事実が
   3節目の1文**に埋まり、**他人に見つけられた自分の欠陥は一行も書いていなかった。**

   **新しい背骨: SEC 先行。** *Block trades have always settled away from the tape. The SEC has now
   built the tape for tokenized equity. Nobody has built the block.* — これは
   [`docs/SEC-EXEMPTION.md`](docs/SEC-EXEMPTION.md) に前からあって、**どの提出物にも入っていなかった。**

   | 成果物 | 状態 |
   |---|---|
   | [`_submission/full.md`](_submission/full.md) | 全面改稿。4,994/5,000字。SEC → 誰も作っていない理由 → 動く証拠 → **間違えた主張** → 作っていないもの |
   | [`_submission/short.txt`](_submission/short.txt) | 157字×2、新しい背骨 |
   | [`video/CWF-PRESENTATION.md`](video/CWF-PRESENTATION.md) | 10場面を書き直し、173秒。**場面4の間合い（"holds nothing" → 173,000）は一字も変えていない** |
   | `video/presentation.mp4` | 無音ラフカットは再レンダリング済み、175.1秒 |

   **founder が実物を見て、私の入れた視覚的欠陥を3つ指摘（同日）。全部直した。**
   ① 法令の文章を**コンソール面（13.5px 等幅・折り返しなし）**に流し込んでいて、右端で単語の途中から
   切れていた → `order` 種別を追加、30px で折り返す引用カード。
   ② **DvP の図を落としていた** — 判断ではなく構成変更の巻き添え。**戻した。**
   一言の説明もなしに製品を伝える唯一の絵で、Codex の「冒頭15秒」とも一致する。
   ③ 冒頭が**30秒間、法令の文字列だけで何も動かなかった** → SEC を2場面から1場面に圧縮。

   ④ **「トークン化株式とステーブルコインの confidential DvP だ」が伝わらない** と founder が指摘。
   これも私が消していた — 旧カットの場面1は *"Confide settles tokenized stock against a stablecoin
   in a single transaction, and neither side publishes what moved"* という**平易な一文**で、構成変更で
   落としたまま置き換えていなかった。冒頭50秒で何であるかを言うのは **"block"**（金融の隠語）と
   `cash` と書かれた図だけ。**stablecoin も confidential も一度も言っていなかった。**

   **founder が本文を書いた。これを正とする:**

   > Confidential delivery-versus-payment for tokenized stocks on Solana: a stock-to-stablecoin swap
   > in one transaction, with neither side publishing what moved. Confide builds the proofs the chain
   > will not assemble for you and lets each side check the other before signing, with nobody in the
   > middle.

   1文目=156字が `short.txt` にそのまま収まる。`full.md` は見出し直下に全文、hero は
   副題と lede に分けた（ナレーションは空白を、画面はそれを埋めるものを言う）。

   ⑤ **2文目（Confide 自身が何をするか）を動画が言うのが場面9＝約2分の地点だった** と founder が
   指摘。冒頭2分、視聴者は**結果は知っていて製品を知らない**。**場面3（DvP の図）に移した** —
   *"So here is one. Confide builds the proofs the chain will not assemble for you, and lets each
   side check the other before signing — with nobody in the middle."* **0:35 で語られる。**
   場面9は重複をやめ、*why it is hard*（証明が1取引に収まらない／手数料 mint では5つ／1つは
   record 口座経由／4ファイル2台）に専念。場面8の *"It has to be two parties"* も
   場面3の *"with nobody in the middle"* と同じことなので落とした。

   ⑥ **その一文を音声だけで出していた** と founder が指摘。**音を切っている審査員が取り逃がす。**
   画面にも出した（`.cap.say`、21px）。**この台本の規則「ナレーションは画面を読み上げない」を
   意図的に破る唯一の箇所**で、理由をファイルに書いてある — 177秒で1回だけ。

   ⑦ **冒頭の SEC が普通の人には難しい** と founder が指摘。条件の羅列は正確だが物語ではなく、
   TSV が何か知らない人には掴むところが無い。**founder の提案した形に変えた** — *猶予を与えた、
   ただし落とし穴があった*。「五年の猶予。それから条件を読む。対象は AMM 経由の取引だけ —
   そこでは自分の取引が全部公開される。サイズ。方向。十分以内。」**数字（0.25%・十分）は
   画面のカードが持ち、声は turn だけを運ぶ。** `full.md` の冒頭も同じ形に揃えた。

   **ただし最初は音声しか変えていなかった** — founder が「SEC の入りが変わっていないように見える」と
   指摘。**そのとおりで、カードは条件の引用のままだった。音を切ると turn が見えない**（「五年の猶予」が
   画面に一言も無い）。カードを **猶予 → 落とし穴 → 数字** に組み直した。`reveal` が順に出すので、
   時間の上でも turn が起きる。カードの言い換えが増えたぶん、**「五年」と「AMM 限定」も
   レンダリング時に一次情報へ照合**する（わざと壊して落ちることを確認ずみ）。

   ⑧ **場面2で `Confide` と一度も言っていなかった** と founder が指摘。画面で一番大きい文字が
   `Confide` なのに、声は tape と block の話をしている。**音だけで聞いている人は、名前が出た瞬間に
   それを受け取れない**（次に名前が出るのは14秒後の場面3）。空白への答えとして2語足した —
   *"Nobody has built the block. **Confide has.**"* 尺は場面9の重複表現を詰めて 177秒に戻した。

   **さらに founder が順序の誤りを指摘（同日）。** DvP の図を hero の前に置いていた。**好みではなく
   論理の誤り** — 場面で *"Nobody has built the block"* と言う直前に、**block が settle する図を
   見せていた**。見た直後に「誰も作っていない」と言われる。加えて製品名 `Confide` が自分の図より
   後に出ていた。**規則 → 空白（hero）→ その答え（DvP）**に直した。図の見出しは
   *"So here is one."* で、前の場面の一文への返答になっている。
   | [`video/DELIVERED-20260920.md`](video/DELIVERED-20260920.md) | **新規。公開中の動画が何を喋っているかの凍結記録** — 台本だけ先に進んだので、これが無いと記録が消えていた |

   **09-20 の並べ替え（製品先行）を反転させたので、反論も文書に残してある** — `CRITERIA.md` は
   **「No weights. No stated reading order.」**で、§8 は Functionality 始まり、web の7項目は
   Founder + Market Fit と Insight 始まり。**どちらの順も同じ2つのリストから正当化できる。**
   決めたのは基準ではなく、9/17 に起きたこと。

   | やること | |
   |---|---|
   | **動画の再収録** | 音声生成は founder の手。台本は出来ていて尺も出ている。`CHECKIN_DOC` は不要、`node video/record-presentation.js` は済み |
   | **Stocklana に貼り直す** | `full.md` と `short.txt`。**09-25 13:00 PDT で凍結**。貼ったら `./scripts/pasted.sh stocklana-full` と `stocklana-short` |
   | **再収録後** | `DELIVERED-20260920.md` を実際に納品した台本で置き換える（凍結記録なので、合わせて書き換えない） |

0g. **CWF check-in 2 — 台本はある、収録がまだ。窓は 09-25 08:00 PDT に開き 09-28 08:00 PDT に閉じる。**

   [`video/CHECKIN-2.md`](video/CHECKIN-2.md) を 2026-09-22 に書き、09-27 に書き直した。58秒・125語・3シーン。
   **窓が開く前に書いたのは check-in 1 と逆** — 09-22 時点で終わっている作業から書いたので、
   **09-25 に読み直すこと。** 間に何か着地したら場面1に入り、今そこにあるものが退く。

   骨は「前回の『次は何か』に答えが出ている」こと。check-in 1 は
   *making the swap runnable by a stranger* で終わった。場面1がそれを引用して答える。
   場面2は**自分の仕事の欠陥を他人が見つけた話** — safety step と呼んでいた段が、
   見てもいないものに署名していた（[`docs/reviews/2026-09-22-two-party-swap.md`](docs/reviews/2026-09-22-two-party-swap.md)）。
   場面3は**一番弱い数字で終わる** — 約46万口座のうち1株以上を持つのは6千未満。

   | やること | |
   |---|---|
   | **09-25 に台本を読み直す** | 3日ぶん足りない。着地したものがあれば場面1へ |
   | **収録して投稿** | 音声生成は founder の手。`CHECKIN_DOC=video/CHECKIN-2.md` を渡す（既定は CHECKIN-1 のまま） |
   | **同じ朝に Stocklana の貼り直しが 13:00 PDT** | 差は5時間。**再測定 → 貼り直し → `./scripts/pasted.sh stocklana-full`** が先 |

0f. **⚠ 保有分布を測った。今のピッチに不利な事実が出た（2026-09-21）** —
   [`docs/cwf-2026/WHERE-THE-POSITIONS-ARE.md`](docs/cwf-2026/WHERE-THE-POSITIONS-ARE.md)

   **口座数は塵** — ただし**最重要銘柄を除く**。354,150 口座のうち **1株以上は 4,117 件（1.163%）**、
   100株以上は **201 件**。NVDAx の中央値は 1株の **0.0046**（約80セント）。

   **⚠ SPCX.US だけ別。** Backpack Securities が Wormhole の **Sunrise** 経由で 2026-06-12
   （SpaceX の Nasdaq IPO 当日）に上場したもの。**応答が大きすぎて走査できていない**が、読めた範囲で:
   **上位20で供給の 48.3%**（NVDAx は上位1で 52%）、**上位6のうち2件が約1,100株を持つ通常ウォレット**、
   流動性は Meteora と Raydium に分散。**門は同じく閉**（`autoApproveNewAccounts: false`、auditor null）。

   **つまり発見はむしろ強くなる:**
   **「Solana で最も取引されているトークン化株式には実在の保有者がいて、誰一人として秘匿で持てない」**

   **⚠ 自分のバグを1つ:** 最初の測定は全銘柄 8 decimals と決め打ちしていた。**6銘柄中4つが違う**
   （ANTHROPIC/SPACEX は 9、AMC.US/SPCX.US は 6）。中央値3件が 10〜100倍ずれていた。
   `holders-scan.sh` は銘柄ごとに読むようにした。

   - **「ポジションを公開したくない保有者」がオンチェーンにほぼ存在しない。** 実際の保有は
     取引所／カストディアンの帳簿にあり、**チェーンからは既に見えない**
   - **469,477 を「市場規模」として提示してはいけない。** 発見（機能は出荷され未使用）は無傷で、
     4銘柄目・3発行体目で**確認が増えた**
   - **代わりに、測定と整合する強い枠組みが出た:** **「今日は自己保管か秘匿か、どちらかしか選べない。
     全員が秘匿を選んだ。塵はその残りかす」** ——**因果は未証明**と明記のこと
   - **発行の仮説は大幅に強化。** NVDAx の 52%、AAPLx の 75% が**発行体の1アドレス**。
     残りは**プール**で、プールは秘匿にできない。**実サイズの相手方は発行体しかいない**

   **これは基準線であって判決ではない（founder の訂正、2026-09-21）。** ここに書かれた構造は
   **今日のもの**で、トークン化株式は1年ほどの歴史しかなく、米国市場は9月17日に開いたばかり。
   だから散文ではなく**スクリプト**にした — `./scripts/holders-scan.sh`、`web/holders.json`。

   **追う列は `>= 1 share`。** 今日は **354,189 口座のうち 5,196 件（1.467%）**、100株以上は **277 件**。
   **仮説が反証可能になる**のが要点 — 第三の選択肢が欠けているものなら、この列は伸びる。
   伸びなければ仮説が誤りで、**そう言う数字をこのリポジトリが記録している**。

   **提出文への反映は founder 判断。** Stocklana は 09-25 まで編集可。

0e. **Confidential Issuance & Redemption の評価（2026-09-21）** —
   [`docs/cwf-2026/ISSUANCE.md`](docs/cwf-2026/ISSUANCE.md)。結論だけ:

   - **最大の長所は再配置ではなく構造適合。** マッチング（未構築かつ意図的に作らない）が
     **発行では存在しない** — 発行体が定義上の相手方。そして門（1,992/1,992 が閉）は
     **発行体の通常業務そのもの**。`testbed-join.sh:80` で**既に動いている**
   - **決め手になる反論:** 一次発行では両者が互いも金額も知っている。主張が
     「どちらも公開しない」から**「公開チェーンが配分を見られない」に縮む**。
     守れる形は1つ — **「同じ案件の他の投資家と、市場」**。配分サイズは板そのもの
   - **⚠ 検証前の仮説:** 「償還は矢印を反転するだけ」は**偽かもしれない**。
     償還が burn なら **mint の supply は公開**で、連続する2状態の差から償還額が復元できる。
     **README の「プールが秘匿にできない」論証と同型。** 動画に入れる前に測ること
   - ~~**残高を読めない保有者に按分で配当は払えない**~~ → **2026-09-21、偽と判明。**
     Backed は `scaledUiAmountConfig` の**乗数**で配当を払う。全残高を比例で倍率調整するだけで、
     **誰も個別残高を読まない**（NVDAx は今 1.00092、次の乗数が予約済み）。**秘匿残高も同じようにリベースする**
   - **生き残る主張は議決権で、そちらの方が狭くて強い。** **投票に乗数は無い** —
     持分比例の集計は持分を知る必要がある。
   - ~~**Backpack のトークンは議決権を伴う**~~ → **2026-09-22 に精密化。オンチェーンのままでは投票できない。**
     株主名簿はブローカー。**償還して entitlement に戻してから**、伝統的なプロキシで行使する。
     **秘匿と議決権は衝突しない — 投票は最初からチェーン上に無い。**
   - **2日で2回、「規制が開示を強制する」に手を伸ばして2回とも構造に回避された**（配当→乗数、議決権→オフチェーン）。
     **同じ方向への3回目は4つ目の誤りになる。**
   - **両方が崩れて残ったものが、どちらより強く、規制を必要としない:**

     > **Backpack の双方向ドアは最大の長所であり、いまの設定では最大の開示漏れ。**
     > **この6銘柄の設定では** burn が公開 supply を同額だけ動かす。

     **⚠ Codex レビュー（2026-09-22）で3点訂正**
     [`docs/reviews/2026-09-22-tokenized-equity-structure.md`](docs/reviews/2026-09-22-tokenized-equity-structure.md):
     ① `scaledUiAmountConfig` は**残高をリベースしない**。`amount_to_ui_amount(u64) -> String` の
     **表示変換**で、暗号文も `base.amount` も触らない（実ファイルで確認済み）。
     ② supply 差分は**無条件ではない** — treasury 移管なら supply は動かない、batching は純額しか出さない、
     再発行、そして **`ConfidentialMintBurn` 拡張は supply 自体が暗号文**。
     ③ Gemini の記述の**固有名詞（InCore Bank / Apex Clearing / UCC Article 8 / Chainlink PoR）は
     再構成の疑いが強い。一次資料なしに提出文へ入れない。**

     **実測: 6銘柄とも `ConfidentialMintBurn` を持たない。** だから今日は burn が公開される。
     **設定の事実であって、プロトコルの事実ではない。**

     **そしてドアは、重要なことすべてで必須:** 投票するには償還。ブローカー移管も償還。
     プールではなく NAV で出るのも償還。プールを動かさずにサイズで入るのも mint。
     **どれもその数字を公開する。**
   - **これが提案そのもの。** 秘匿発行・償還は決済 primitive への後付けではなく、
     **名前のある発行体が既に出来高付きで運用しているドアの、秘匿版**
   - **他チェーンは無し。** Token-2022 と ZK ElGamal Proof Program は他に無く、移植は
     プロジェクトの作り直し。§8(e) は**構成の深さ**を問うている

   **今週の3つ:** ① 償還のリーク測定 ② `swap-offer` / `swap-accept` ③ 発行の語り口を実物に当てる

0d. ~~**CWF Week 1 video**~~ → **完了。提出済み（2026-09-20 19:17 PDT、締切の12時間43分前）。**

   **https://youtu.be/mbE8HMwG0S4** · `Confide_CWF_Check-in-1_20260921.mp4` · 0:55

   実ページで照合済み: oembed 200、タイトル完全一致、説明文 1,602字が**一文字単位で一致**、
   英語・日本語とも**アップロード版**（自動生成は founder が削除）。`healthcheck.sh` が
   両リンクを毎回見る。`_submission/pasted.json` が貼った時点の本文の sha256 を保持し、
   以後ファイルが動いたら `docs-consistency.sh` が落ちる。

   **提出済み。** 受領 **2026-09-20 19:17 PDT**、締切（09-21 08:00 PDT）の **12時間43分前**。
   *"Your team, judges, and Colosseum can view this video."* 提出者 psyto。

   **日程は 2026-09-21 にダッシュボードから読んだ。** *"Submissions open during the last three
   days of each week"*、各 08:00 PDT:

   | week | opens | **締切** | 締切 JST |
   |---|---|---|---|
   | 2 | 09-25 | **09-28 08:00 PDT** | 09-29 00:00 |
   | 3 | 10-02 | **10-05 08:00 PDT** | 10-06 00:00 |
   | 4 | 10-09 | **10-12 08:00 PDT** | 10-13 00:00 |

   **旧 `CHECKIN-1.md` の日付は誤りではなく、誤ったラベルだった** — あれは*開く日*で、締切として
   書かれていた。**2つの誤りのうち危険な方**で、末尾に3日の余裕があるように読める。

   **日程の衝突が2つある。**

   | | |
   |---|---|
   | **09-25** | check-in 2 が **08:00 PDT に開く**／**Stocklana の編集締切が 13:00 PDT**（= 16:00 ET）。**差は5時間。** 同じ朝に、最終再測定と貼り直しと、check-in 2 の収録が重なる |
   | **10-12** | check-in 4 の締切 **08:00 PDT**／**CWF 本提出 23:59 PT**。**同日、差は16時間。** check-in 4 が先に閉じる |

0c. **CWF フォーム — 全欄の貼付文を用意した。残りは founder の入力（2026-09-21）。**

   **登録時の Brief description が腐ったまま Public 欄に座っていた** — *"All 1,869 tokenized
   stocks … two issuers"*。**1,869 は第三の発行体が現れる前の数**で、Stocklana の short
   description で腐ったのと同じ数字（[`_submission/short-alternatives.txt`](_submission/short-alternatives.txt)
   に警告として記録済み）。しかも開示側の製品を売っていて、スワップが一行も無かった。

   [`_submission/cwf-form.md`](_submission/cwf-form.md) が11欄ぶんの貼付文。
   `./scripts/cwf-form.sh` がフォーム自身の上限で数え、**チェーンが報告しない4桁・6桁を拒否**し、
   **欄数そのものを 11 に固定**する（フェンスが壊れて1欄が数えられなくなる形を捕まえるため）。
   `docs-consistency.sh` に配線済み。**最初に書いたとき10欄中4欄が超過していた。**

   | 決定済み | |
   |---|---|
   | Location | **Japan** |
   | Telegram | **設定済み。値はこのリポジトリに書かない** — フォームで Public 表記が無い欄であり、**このリポジトリは公開**なので、書けばフォームより広く晒す |
   | Accelerator | **出す**（2026-09-21 founder 判断） |

   | 残り | |
   |---|---|
   | **Accelerator の追加欄** | 開くと出てくる欄はまだ見ていない。**貼れば同じ扱いにする** — 書いて、数えて、古い数字を拒否する |
   | **過去開発作業の開示欄を探す** | 規約は「**提出フォームに**」開示せよと要求。`Anything else`（500字）に圧縮して入れたが、**「Media and code」か「Team」タブに専用欄がある可能性**。あれば [`docs/cwf-2026/FORM.md`](docs/cwf-2026/FORM.md) §2 の全文（約1,900字）が入る |

0b. ~~**CWF check-in 1 — 収録と日付の出典が残っている**~~ → **両方完了。** 収録・公開・提出済み、日程は
   ダッシュボードから出典を取った（下表）。

   **既存の収録 `video/Confide_CWF_Checkin1_20260916.mp4` は使えない。** 09-16 の週を報告していて、
   数字が4つ古い（「eighteen hundred」銘柄 → **1,992**、`$21.1m / $81.6m` → **$23.2m / $84.0m**）。
   それ以上に**報告している週が違う** — スワップも 469,477 の走査も SEC も、全部この後の出来事。

   [`video/CHECKIN-1.md`](video/CHECKIN-1.md) を書き直した。58秒・125語・3シーン。
   **動く数字は正確な値で喋らせていない** — 口座数は "more than three hundred thousand"、
   ドル額は入れていない。Stocklana のナレーションが4日で古くなった件の規則を、初めて適用した台本。

   | やること | |
   |---|---|
   | **日付の出典を取る** | **Official Rules には check-in の条項が1つも無い。** 判定基準7項目にも §8 6項目にも無い（[`docs/cwf-2026/CRITERIA.md`](docs/cwf-2026/CRITERIA.md)）。**プラットフォーム側の依頼**であって規約上の義務ではない。旧版が書いていた 09-18 / 09-25 / 10-02 / 10-09 は**出典なし**。Colosseum のページで founder が読むこと ——**出典の無い日付**は Stocklana の締切を1週間間違えたのと同じ形 |
   | **収録して投稿** | 音声生成は founder の手。3シーンぶん |

0a. ~~**YouTube の英語字幕が自動生成のまま**~~ → **2026-09-21 に founder が
   `video/captions-20260920.srt` を英語トラックとしてアップロード、解消。**
   ライブの申告が `en kind=asr`「英語 (自動生成)」から `en kind=—`「英語」に変わり、ASR トラックは
   消えた。`scripts/healthcheck.sh` が毎回判定する。
   **ただし検査の天井:** YouTube の timedtext がトラック本文をこの取得に返さないので、**中身が
   補正済みのものかは検証していない。** 人が何かを上げたことは言えるが、正しいものを上げたとは
   言えない。`fix-captions.sh` の14件が効いているかは、founder が動画上で目視するしかない。

0. **納品済みの動画が、言えない数字を1つ喋っている（2026-09-20、founder の判断）。**
   ナレーションは「**Three hundred and twenty-nine thousand accounts**」と言う。09-17 の測定では
   正しかった。**09-20 の再測定で 469,477 になった** — 3日で 730 動き、丸めた「千」の桁が変わった。
   0.4% のずれだが、**この提出物の売りが「全部再計算できる」ことなので、審査員が実際に
   `./scripts/usage-scan.sh` を回すのが想定読者**であり、そこだけ合わない。
   文書・ページ・提出文・YouTube 説明文は**すべて 469,477 に更新済み**。動画と台本と字幕は
   **意図的に触っていない** — 日付のついた記録であり、音声生成は founder の手にしかない。

   | 選択肢 | 中身 |
   |---|---|
   | **そのまま出す（推奨）** | 動画は `Confide_Stocklana_20260920.mp4` と日付入り。ページ側が新しい数字と `usage-scan.sh` を出しているので、回した審査員は「測り直された」と読む。費用ゼロ |
   | scene 6 だけ録り直す | founder が音声を作り直し、再レンダリング。**数字はまた動く**ので、次の測定でまた同じ判断になる |

   **次に録るときの規則:** 動く数字を「三十二万九千」と正確に喋らない。
   **「more than three hundred thousand」**なら両方向のドリフトを何ヶ月も生き延びる。
   この一文が、この項目をもう一度作らせないための全部。

1. **traction がゼロ。** ~~7基準のうち4つが非エンジニアリングで、先に読まれる~~ →
   **2026-09-19 に訂正。** 両方の基準表を出典つきで読んだ結果、**traction は7つの最後**で、
   **Official Rules §8 には traction の項目が無い**（[`docs/cwf-2026/CRITERIA.md`](docs/cwf-2026/CRITERIA.md)）。
   4つのうち engineering より上に載っているのは **Founder + Market Fit だけ**。
   どちらの表にも重みも読む順も書いていないので、「先に読まれる」は**どちら向きにも事実ではなかった**。
   それでも traction は**何を書いても埋まらない** — 外部の誰かが実際に使った事実しか埋められない。
   **個別接触は 2026-09-18 の founder 裁定で無し**、公開投稿のみ。**これは Reckn を CWF から撤回させた行そのもので、Confide も
   現状ゼロ。** リードタイムが不可逆なので、窓の序盤に founder が投げないと 10-12 に間に合わない。
   **2026-09-16 に相手が変わった。** 発行体は**適格性の門**であって最初の買い手ではない —
   発行して売ることが収益の事業に、開示モデルを採る理由が無い。**最初の買い手は貸し手側**で、
   根拠は論証ではなくチェーンにある: Kamino は秘匿転送を allow-list に載せたうえで**不活性**を
   要求しており（`constraints.rs:187` `:194` `:201` `:131`）、**通常の預入経路が預入者自身の口座に
   それを適用する**（`lending_checks.rs:186`）。入れない担保は借入も清算もされない。
   そして Kamino は**既に 19本の reserve** で tokenized stock に貸していて、13本が種以上の残高
   — available ≈89,192、borrowed ≈230 — LTV 30〜73%。
   **SpaceX も `SPCX.US` が LTV 40% / 上限15,000 で稼働中**。全部公開ポジション。
   → [`docs/KAMINO.md`](docs/KAMINO.md)、[`docs/packets/SPCX.US.md`](docs/packets/SPCX.US.md)

   **接触先は Kamino の市場所有者 / vault curator。** 最初の依頼は LLTV ではなく、
   **packet と互換性判定を20分で論破してもらうこと** — 保管と清算の経路が未証明の資産に
   値付けを求めれば、断られるのが正しい。agent は誰にも接触しない。
2. **CWF のフォーム。** 登録は開始済み — https://colosseum.com/arena/projects/confide は
   **公開ページ**（ログイン不要で誰でも見られる）。カテゴリー **RWA**、説明、team は入力済み。
   登録に要求されたのはこの3項目だけで、**リンクと過去作業欄はまだフォームに現れていない**。
   抜けではなく、提出時に出てくる欄。出たときに使うもの:
   - リンク3本、いずれも生存確認済み（2026-09-15、全て HTTP 200）:
     `https://github.com/psyto/confide` / `https://psyto.github.io/confide/` /
     `https://youtu.be/du0Twt_c9wQ`。**動画は `du0Twt_c9wQ` が現行**（2026-09-23 投稿）で、
     `C86U3R0IgiU`（09-22）・`p1aQuEnzhQk`・`KQsRwP8HTs0`・`ZuhLvH5MFgE` は旧版。
     **2026-09-21、founder が旧3本を削除。3本とも 404 を返す。**
     以前ここには「旧 URL も 200 を返すので、貼り間違えても壊れて見えない」と書いてあった。**逆になった**
     ——貼り間違えると見えて壊れる。ただし**これを散文で持たない**: `scripts/healthcheck.sh` が
     `video/README.md` に載る全 ID の消滅と現行の生存を毎回測る（現行を旧側に置く壊し方は除外規則に
     吸われるので、`VIDEO` を別 ID にして生存検出そのものを落とすこと）。ここに ID を書き写すたびに
     腐る（09-15 に一度腐った）。
   - 過去作業の開示欄（規約要件）。記入元は [`docs/WORK-WINDOW.md`](docs/WORK-WINDOW.md) と
     上の再利用表。**repo に書いてあることは開示にならない。**
3. **9/14 公開のトラック / スポンサー / 審査員 / フォーム項目を読む。** Tempo トラックは条件未公開
   （"Session details coming soon"、9/16 workshop）。Solana トラックだけが $100,000 / 10件 と判明。
4. ~~**README / DESIGN の "written in-window"**~~ → **解決済み。** README:574 と DESIGN.md:210 が
   「どちらの窓か」を明示し、`docs/WORK-WINDOW.md` へ導線を張っている。CWF フォームの
   *repo context* 欄にも同じ開示を入れた（[`_submission/cwf-form.md`](_submission/cwf-form.md)）。
   以下は当時の記述。**両方の表が Confide を**
   *written in-window* と書いている。これは **Stocklana の窓**では真だが、**CWF の窓では偽**
   （48 commit が 09-14 06:00 PT より前）。**同じ public repo を両方の審査員が読む。**
   CWF の審査員には二重の意味で不利 — 誤読されれば虚偽申告に見え、正しく読まれても
   「窓内の成果」がどれか分からない。`docs/WORK-WINDOW.md` への導線を README に置くのが最小の手当て。
5. **CWF 提出動画は2本** — 2〜3分のプレゼンと3分以内のデモ。**既存の 2分動画とは別物**で、提出時に作る。

## 2026-09-29 — Codex 2件、そして founder に返す3つ

レビュー全文は `docs/reviews/2026-09-29-{one-product,fmf-video-edits}-r1.md`、依頼文は
`docs/reviews/payloads/` に同名で置いてある。

**確定したこと。** **Confide は1製品** — *confidential Token-2022 settlement*（DvP）が wedge で、
scheduled disclosure は**未完のプロトタイプ**。これは推測ではなくコードの側の事実で、
`crates/confide-embargo/src/lib.rs:39-59` が**自分で I2 を撤回している**
（*"a correction to an earlier version of this comment, which claimed I2 was unconditional. It is not."*）。
`n−k+1` が withhold すれば止まり、時計は `confide-agent <share> <sealed> <now>` の引数で、
`TimeLockPuzzle` は未実装。**「保有者が拒否しても開示は起きる」を提出物の主役に据えてはいけない。**

**⚠ `DESIGN.md` を §1 から読むと必ず誤読する。** 冒頭9行に 09-20 のピボット告知があり、
README が先頭に置くものと、この文書が設計している層の関係がそこに書いてある。読み飛ばすと
「2製品に割れている」という誤診に着地する（実際にした）。

### founder しか動かせない3つ

1. **`docs-consistency.sh` が1件赤。** `_submission/cwf-form.md`（09-22 11:54 に貼って以降）と
   `_submission/youtube-paste.txt`（09-24 06:41 以降）が動いている。**貼り直し → `./scripts/pasted.sh <field>`。**
2. **動画の残り2シーン。** `./scripts/spoken-check.sh video/Confide_Stocklana_20260923.mp4` は
   **10 中 8 が現行台本を 95.7–100% で読んでいる**が、**読めたシーンが1つでも落ちれば非ゼロ終了**する。
   残るのは scene 3（88.6%、"confide" が transcript に無い／ただし ASR は *Confide* を **confined** と聞く
   = `scripts/lib/spoken.py:11-14`、一方 `:16-19` は「際立った語の不在はそれでも意味がある」と書く）と
   scene 5（**57.3–78.2s** を transcriber が落とし、音声は -21.4 dB で在る）。**どちらも耳が要る。**
   経緯は `video/CWF-PRESENTATION.md` の冒頭に測定つきで書いた。
3. **再利用表の Confide 行に `confide-ct`（swap）が入っていない。** ピボット前に書かれた表で、
   **README・STATUS・DESIGN の3箇所に同じものがある**。フォームに貼る開示面なので、
   3枚同時に直すかどうかは founder の判断。事実の方は README の表の直下に測定として書いた
   （`aperture-core` は開示側5 crate・20 use sites、`confide-ct` は依存ゼロ）。

## 2026-09-29 — check-in 2 を逃した。意図の主張を全面から落とした

**0h. check-in 2 は提出されなかった。** 窓は **2026-09-28 08:00 PDT に閉じた**。
`video/checkin-2.mp4` は在る（無音、ffprobe で 59.2 秒、コミット済み）。**起きなかったのは音声生成と投稿だけ。**
台本 `video/CHECKIN-2.md` は 58 秒・125 語。**中身は失われていない** —
場面2（母集団の訂正）も場面3（口座が1つ閉じられた）もまだ公には言われていないので、
**week 3 の素材として生きている。窓は 10-02 に開き、10-05 08:00 PDT に閉じる。** 数字は再測定が前提。

*週次 check-in を落とした扱いが CWF でどうなるかは、このリポジトリからは分からない。推測で書かない。*

**0i. レコーダーは check-in 2 を録れる状態ではなかった。** `CHECKIN_DOC` は台本にだけ効いていて、
出力は `checkin-1.mp4` 固定、manifest も `segments-checkin/` 固定だった。
**そのまま走らせると week 1 の提出済みカットを上書きし、`checkin-2.mp4` は生まれない。**
両方とも `CHECKIN_DOC` の番号から導くようにした。`checkin.html` は未変更なので week 1 は再現する。
最初の書き出しは 60.2 秒で上限超過、**レコーダー自身の報告は 59.2 秒**だった。検査が ffprobe を読むので落ちた。

**0j. 意図の主張を9箇所から落とした。** `README.md` / `docs/ONCHAIN.md` / `THE-PINCER.md` /
`WHY-THE-SLOT-IS-EMPTY.md` / `FOUNDER-MARKET-FIT.md`（2件）/ `WHAT-THE-WEEK-CHANGED.md` /
`video/CWF-PRESENTATION.md` / `web/index.html` / `_submission/cwf-form.md`。
*arriving independently* / *declining exactly one thing* / *every issuer picked null* /
*configured deliberately* の類。**理由は1箇所にだけ書いた** —
[`docs/cwf-2026/THE-PINCER.md`](docs/cwf-2026/THE-PINCER.md) の「And the uniformity is not evidence
of a decision」。`InitializeMintData` が `Pod, Zeroable` を derive するので、
**観測された構成は構造体のゼロ値そのもの**。測定は一切触っていない。**pincer は意図に依存しない。**

**0k. 09-27 の広域スキャンは、まだ証拠ではない。** Jupiter の verified list 経由で
**CT を持つ 1,669 mint すべてが autoApprove=false・auditor 空**、うち **768 が `web/mints.json` に無い**
（うち 450 は **Ondo = 第4の発行体**。残りは既知2社の未計上分で、内訳と mint authority は
[`docs/reviews/2026-09-27-the-direction.md`](docs/reviews/2026-09-27-the-direction.md) に測定として置いた
— この数字を STATUS に写すと、per-issuer の mint 数と読めて検査が正しく落ちる）。
**パーサもスナップショットも実行出力もコミットされていないので、提出にも check-in にも使えない**
（Codex の判定、`docs/reviews/2026-09-27-the-direction.md`）。
**`scripts/slot-scan.sh:3` の *"every tokenized-equity mint on Solana. Not a sample."* は今日時点で偽**
— あの一覧は3発行体の製品カタログ由来。**狭めるか、母集団を作り直すか**が未決。
program 全体の `getProgramAccounts` は Alchemy・publicnode・api.mainnet-beta のいずれでも通らない
（offset 165 は索引外）。言い切るには gPA を返すエンドポイントが要る。

**0l. `web/usage.json` は2日で2回動いた。** 490,673 → 507,908 → **518,744**、
configured は **3 → 2**（口座が1つ**閉じられた**。`8P31wJSdNfNy…` は消滅）、approved は 0 のまま。
**派生数字に触る前に `generated_utc` を読むこと。** 1回動くたびに散文10面と README の転記ブロックが腐る。
GitHub の About は 09-28 に適用済み（518,744 / 2 / none approved）。

**0m. CWF の必須動画2本がまだ無い。** デモ ≤3分（*"the live product, not a slide deck"*）と
**ピッチ ≤2分・founder が画面に出るもの**。後者は基準5 *Founder Communication* が読む唯一の面で、
**このリポジトリの何をもってしても代替できない**。10-12 まで13日。**提出の最大の穴はここ。**

**0n. `docs/cwf-2026/CLAUDE-CODE-BRIEF.md` が未追跡のまま。** founder が 09-27 朝に書いたもの。
今日の結論（Codex の「1製品」判定、母集団の訂正、意図の推論の除去）で内容が変わっているので、
**書き直してコミットするか、消すか**が未決。

## 2026-09-30 — 母集団の主張を31ファイルで狭めた。Codex は15日前に同じことを言っていた

レビュー全文は [`docs/reviews/2026-09-30-the-population.md`](docs/reviews/2026-09-30-the-population.md)、
依頼文は `docs/reviews/payloads/` に同名。語法と理由は
[`docs/cwf-2026/THE-POPULATION.md`](docs/cwf-2026/THE-POPULATION.md) の1箇所だけに置いた。

**0o. 「every tokenized-equity mint on Solana」は 38 ファイル・45 箇所にあった。**
STATUS 0k は `scripts/slot-scan.sh:3` の**1行**として記録していた。**31 直し、7 は意図して残した。**

**最初に数えたときは 24 だった。** 正規表現が `every|all` で始まる形しか知らず、
**公開サイト・README の見出し・scan 自身が print する行・14 個の packet を生成するスクリプト**を
通り過ぎていた。**数え方が、数えようとしている盲点をそのまま持っていた。** 4つとも Codex の指摘。

**0p. これは新しい誤りではない。Codex が 2026-09-15 に指摘している。**
`docs/reviews/2026-09-15-codex-docs-quality.md:31` —
*"`slot-scan.sh` checks every mint in `web/mints.json`; it does not discover the universe."*
そのとき入った修正は **`docs/ONCHAIN.md` と `README.md` の注釈2つだけ**。しかもどちらも
「これは Solana の全数調査ではない」と書いたまま、**その3行上にある反対のことを言う見出しの下に
置かれた。** 見出しと注釈を突き合わせる検査は無かった。**偽の見出しの下の但し書きは訂正ではない。**
主張は自分の撤回より15日長く生き延びた。

**0q. 語法は2つだけ。** コード・ヘッダ・生成物は **`every mint in web/mints.json`**、
散文は **`from three issuers' catalogues`**（動詞を置かない —— *publish* / *list* は現在形で、
9月のスナップショットは今日のカタログの状態を主張できない）。
**最初の修正は偽の1文を「真の3通り」に置き換えていて、Codex はそれを「同じ drift の始まり」と
判定した。** 3通り目を落とす検査を入れた（下記）。
***Not a sample* は限定形でだけ残す** —— *"every entry in `web/mints.json`, not a sample of that
file."* 単独では「部分集合ではない」と読めてしまい、実際には部分集合。裸の語は消した。

**0r. 日付は「retrieved」ではなく「committed 2026-09-19」。** `web/mints.json` に取得時刻が
無かったので、git のコミット日を取得時刻のように書いていた。**`refresh-mints.sh` が
`web/mints-source.json`（`generated_utc`・3つの API URL・書いたバイト列の sha256）を
出すようにした**ので、次の refresh から日付は自分を名乗る。発行体ごとの件数は写さない（導出できる）。

**0s. `refresh-mints.sh` は検算の前に書いていた。** 8本の assert が `json.dump` の**後ろ**に
あったので、**片方の API が空ページを返したら web/mints.json を先に上書きして、後から文句を言う**
—— このスクリプトがまさに防ぐために書かれた失敗で、`STATUS.md` を0バイトにしたのと同じ形。
**検算 → 組み立て → 最後に書く**に直した。

**0t. カタログは既に動いている。1,992 → 2,193（+201）。** `DRY=1 ./scripts/refresh-mints.sh` で
確認（Backed 828→1,025、Backpack 1,156→1,160、PreStocks 8）。**refresh していない。**
`slot-scan.sh` は新しい 201 mint を一度も読んでいないので、**refresh だけすると
「限定された真の数字」を「広い未測定の数字」に取り替える** —— 今日直したのと同じ誤り。
再測定は founder の private RPC が要る（公開エンドポイントはこの量で 429）。
**DRY モードを足したのは、この問いを聞くのに測定を上書きする必要があったから。**

**0u. 検査 `THE POPULATION`。** 3つの形を見る: ①`every|all|the whole … on Solana`
②**`<数> tokenized stocks on Solana` —— 数も量化子**（行の前方の日付が量化子の代わりをしないよう、
数は名詞の隣に固定）③`whole asset class`（packet 生成器の言い方で、母集団を名乗っていなかった）。
加えて**3通り目の言い換え**（`catalogues publish` / `issuers list` / `issuers publish`）も落とす。
走査対象は `git ls-files --cached --others --exclude-standard` —— **追跡と未追跡の両方**。
`.srt` も読む。`docs/reviews/` は読まない。
**引用は主張ではない** —— 二重引用符・`&ldquo;…&rdquo;`・鍵括弧・**markdown の code span**
（いずれも300字上限、対を左から非貪欲に消すので、無関係な2つの span に挟まれた本物の主張は残る）。
訂正文は訂正対象を印字できなければならず、**この節自身が検査のパターンを code span で引用している。**
**ただし `.json` では引用を外さない** —— そこでは `"` は構文で、外すと `manifest.json` の
**公開済みナレーションが丸ごと見えなくなる**。言い換えの検査にも同じ規則を当てた
（禁じるために名前を挙げるのは、使うことではない）。
allowlist は**パスではなく理由**を持ち、**項目が主張を持たなくなったらそれも落ちる**。

**わざと8通り壊して確認した**: ①live な散文に書き戻す ②JSON の文字列値に書く
③凍結ファイルから消す ④未追跡の新規ファイル ⑤3通り目の言い換え
⑥**無関係な2つの code span に挟まれた主張**（引用扱いされず落ちる）
⑦**引用付きは落ちてはいけない**（落ちない）⑧**code span 付きも落ちてはいけない**（落ちない）。

**この検査は自分で4つの穴に落ちた。** ①自分の**説明コメント**に当たった ②`.srt` を拡張子で
読み飛ばし、**納品済み字幕トラック**が主張を持ったまま見えていなかった ③引用外しを JSON にも
適用して、**公開済みナレーションの manifest を見逃した** ④引用に code span を数えておらず、
**この STATUS の説明文自身**を主張として報告した。
**②③は「数え直す」までは出てこなかった。「見えない」と「無い」は別。**
入れた瞬間に `docs/ONCHAIN.md:8` の言い換えを1件捕まえた。

**0v. 凍結している7面は直さない。** `_submission/full.md`（Stocklana、09-25 に窓が閉じた）、
`_submission/short-alternatives.txt`（却下稿を逐語で保持）、`docs/cwf-2026/x-post.txt`（投稿済み）、
`video/CWF-PRESENTATION.md` 場面2・`video/captions-20260923.srt`・
`video/segments-presentation/{LINES.md,manifest.json}`（**収録・公開済みのナレーションと字幕**）。

**動画は見る審査員全員に偽の1文を言い続ける。** Codex の答えは「consistency check を赤にして
再収録を強制するのではなく、**審査員が着地する場所から訂正に届くようにする**」。
**README の先頭の動画リンクの直下**と **`web/index.html` の動画の直下**に訂正を置いた。
YouTube の説明文（編集可）も直した。**動画下の訂正コメントの固定と再収録は founder の手。**

**`scripts/x-post.sh:3` は凍結ファイルへの上書きを指示していた。** *`./scripts/x-post.sh >
docs/cwf-2026/x-post.txt`* —— **走らせれば「何が投稿されたか」の唯一の記録が消える。**
使い方の行を書き換え、テンプレート側だけ直した（次の投稿は正しく、投稿済みの記録は残る）。

**0w. GitHub の About が赤になった（新規、founder の手）。** 生成器を直した
—— *"All 1,992 such mints"* は Solana の全数調査と読めていた。今は
*"1,992 mints from three issuers' catalogues"*、口座側も *"of 518,744 accounts scanned"*。
**325字（上限 335、余白 10）** —— 限定語のために2箇所を縮めた。
**`./scripts/github-about.sh --apply` が要る。これは repo の外にある唯一の面。**

**founder の手は3つ。** ①`cwf-form.md` と `youtube-paste.txt` の貼り直し（**両方とも今日の
修正が入っている**）→ `./scripts/pasted.sh <field>` ②`./scripts/github-about.sh --apply`
③動画下の訂正コメント（再収録は CWF の2本と一緒に）。

**0x. `kamino-verdict.sh` は数日間、走れない状態だった。** `$TMPDIR` の klend クローンを
`[ ! -d "$SRC/.git" ]` で判定していたが、macOS は `$TMPDIR` を古さで掃除する ——
09-30 時点で `.git/` には**空の `hooks/` と `info/` だけ**が残っており、
**ディレクトリは在るのでテストは通り、続く git が全部 `not a git repository` で死んでいた**
（exit 128）。**ディレクトリの存在ではなく、git に読めるかを聞く**ように直した
（`git rev-parse --git-dir`、失敗したら消して clone し直す）。
**派生物ではなく実物を見る、の同じ型。** 直した上で走らせた結果は**12項目すべて緑**、
pin した6行は動いておらず、判定は `REQUIRES INTEGRATION` のまま。

**0y. `docs/cwf-2026/CLAUDE-CODE-BRIEF.md` は未追跡のまま（0n の続き）。** 加えて
**§5 の "Known verification baseline — 2026-09-27" が今日の時点で古い**: 3件挙げている
うち `video/CHECKIN-2.md` の録画は在り、`github-about.sh` の `dim: unbound variable` も
出ない。**残っているのは貼り直しだけ。** 書き直すか消すかは founder の判断で、未決のまま。

`cargo test` 25、`docs-consistency.sh` の赤は上の2件だけ。`wire-check.sh` 緑、
`kamino-verdict.sh` 緑、`python3 video/pace.py` 3本とも一致。

## 2026-09-30（2）— 署名前の「検査」は検査ではなかった

**founder の判断: 貼り直し等は最後にやり直すことになるので、実装計画と実装を先に。** 正しい。
その上で、読んでみて優先順位が変わった。

**0z. `issue-e2e.sh` は brief §2 の 1→7 を既に1本で通している。** 想定していた穴は無かった:
発行体の方針＝手動承認、保有者が口座を設定、**承認前は on-chain で拒否**（`Custom(24)`、
署名つきで引用可能）、発行体が承認、秘匿で割当、投資家が署名前に自分宛の額を復号、公開残高は 0。
**本当の穴は検証ステップの方だった。**

**0aa. `swap-check` は復号した額を「表示」していただけで、何も比較していなかった。**
合意額を引数で取らず、`swap_look` の呼び出し元4本（`issue-e2e` / `swap-e2e` / `swap-settle` /
`swap-sign`）は全部そのまま署名に進む。画面には数字と *"If that is not the amount you agreed,
do not sign"* という文が並ぶだけ。**秘匿スワップの唯一の危険に対する答えが「人間が数字を読む」だった。**
深夜の1人の慎重な運用者には実在の答えだが、ソフトウェアの性質ではない。

**直した。** 第3引数で合意額を受け、**比較は終了コード**。呼び出し元は全部 `set -e` なので、
合意と違う額を運ぶ脚はスクリプトを未署名で止める。

**0ab. そして期待値の出所が、比較に意味があるかを決めていた。** 単位は offer JSON の中を
往復する。**少なく送りたい相手は、脚と記載単位を同じファイルで一緒に下げられる** —— その
ファイルを食わせた検査は通り、しかも検証のように見える。**Codex が 2026-09-22 に見つけたのと同じ形**
（「ファイルに書かれた context を復号して、別の blob に署名していた」）。

so: offer に **id** を付け、**両当事者が合意した時点で自分のマシンに terms を pin する**
（`swap-offer.sh` と `swap-accept.sh` が `terms-<id>.json` を書く、証明が存在する前に）。
step 3 / 4 は pin と比べ、**渡されたファイルが条件を書き換えていれば大声で拒否**する。
pin が無い場合は**「この数字は相手の申告で、あなたの記録ではない」と赤で言う**（黙って落とさない）。

**0ac. 検査を2つ足した。RPC が無くても落ちる方に作った。**

| | |
|---|---|
| `cargo test -p confide-ct --bin swap-check` | **10件。** 合成した proof context に対して、1単位不足・過払い・別人宛・proof type 違い・切り詰め。`compare` を外すと**3件落ちる** |
| `./scripts/swap-pin-check.sh` | **14件、チェーン不要。** 条件書き換え・別 mint・単位の注入・pin 未使用。5通りわざと壊して全部落ちることを確認 |

**この自作検査も自分の穴に落ちた。** ①`swap_look` の到達をシェル変数で記録していたが、
`$(...)` は子プロセスなので**親では常に空 —— 拒否テスト2件が空振りで通っていた**。ファイルに変えた。
②`swap_mint_decimals` のスタブを 8 にしていたので、**pin 経由かチェーン経由かが区別できなかった**。
99 にして区別可能にし、実際に壊して落ちることを確認した。

**0ad. `SHORT=` を足した —— 2つ目の負の対照。** `SHORT=2000 ./scripts/issue-e2e.sh` は
発行体の脚を合意 20,000 株に対し 2,000 株で組む。**他は何も変えない。** 投資家の検査が署名前に拒否し、
スクリプトは「証明 context はチェーン上にあり誰にも読めない、**transfer は存在しない**」と
正確に言って終わる。**通ってしまったら非ゼロで落ちる**（「それは発見であって、このスクリプトではない」）。

**0ae. `THE-SWAP.md` は「両方向の拒否は checked」と書いていた。検査は1つも無かった。**
`swap_check.rs` に対するテストはゼロ。**入っていない検査を入れたと報告する**の型。今は10件あり、
その2方向はそのうちの2件。日付つきの訂正として `THE-SWAP.md` に書いた。

**0af. テストを足したら `_submission/full.md` が赤になった。** 検査が**凍結した提出文に
「今日のテスト数と一致すること」を要求していた**ため。編集窓は 09-25 に閉じており、
**この赤は「もうテストを書かない」以外では絶対に消えない。**
`healthcheck.sh:239` が既に *"A red that no action can clear is a red that teaches everyone to skip"*
と書いている。**過少申告は許し（投稿済み x-post と同じ裁定）、過大申告は落とす**に変えた。
3通り壊して確認: 過大・片側だけ過大・数字の消失。README は 60 → **70** に更新。

**0ag. `kamino-verdict.sh` の修正（0x）と合わせて、赤は変わらず2件** ——
貼り直しと `github-about.sh --apply`。どちらも founder の手で、**提出直前にやり直すもの。**

**まだ無いもの（次）。** brief §3 P0 の負の対照のうち **承認権限が違う鍵**と**2つ目の署名が無い**、
それと claim ledger。**RPC が無いのでこのセッションでは devnet 実走ができていない** ——
`swap-check` の比較と pin の拒否は合成データとチェーン不要の検査で証明したが、
**`SHORT=` の実走は未確認**。founder の endpoint が要る。

## 2026-09-30（3）— Codex が2つの bypass を見つけた。出すな、が判定

レビュー全文 [`docs/reviews/2026-09-30-the-check-that-was-a-display.md`](docs/reviews/2026-09-30-the-check-that-was-a-display.md)。
**判定: bilateral の pinning はまだ出すな。** 全部実ファイルで確認して採った。

**0ah. bypass 1 —— id を消せば「未 pin」経路に落とせた。** id は**返ってきたファイルから**読んでいた。
相手は `id` を消し、`offerer.want.units` を下げ、その額の context を渡せばよい。
**pin が無ければ赤い警告を出して、そのファイルの数字と比べて通していた。**
警告は、これが取り除こうとしていた制御そのもの（「数字に気づけ」）。
→ **未 pin は拒否**。`CONFIDE_UNPINNED=1` だけが通り道で、**名前がある**ので選択が記録に残る。

**0ai. bypass 2 —— 出す側の脚を pin していなかった。これが重い。** pin は `want` だけだった。
`swap-settle.sh` は `offerer.give.units` を**返ってきた accept.json から取って自分の脚を組む**。
**受け取り側の検査は通ったまま、acceptor が 100 → 1,000 に書き換えれば offerer は10倍を渡す。**
**着金を検査するのは取引の半分でしかない。** これは私の変更が作った穴ではなく、元からあって、
pin が `want` だけだったので塞がらなかった。
→ pin は**canonical な取引全体**（id・offerer・両脚の mint / account / units / decimals）。
step 3 は**全フィールドを照合してから、渡す額を pin から読む**。

**0aj. 転送が空白区切りで、検証が無かった。** 3本が各々 `python3` で JSON を読んで `read -r` に
渡していた。**値に空白が1つ入ると以降のフィールドが1つずつずれる** —— mint が units の変数に入り、
エラーは出ず、offerer はその枠に入った何かから脚を組む。
→ `scripts/lib/swapjson.py` 1本に統合し、**印字する前に名前ごとに検証**する
（address は base58、units は u64 内の非負整数、id は16桁hex、ElGamal は base64、
**規則の無い leaf 名は通さず落とす**）。3つのコピーも消えた。

**0ak. `$W` が offer ごとに分かれていなかった。** `accept-ctx.json` / `their-ctx.json` /
`settle-ctx.json` / `half.b64` / `unsigned.b64` が固定名で、`$W` は cluster ごとに共有。
**2件同時、または再開すると互いを上書きし、上書きされたものが次のステップで署名される。**
→ `swap_session <id>` で offer ごとのディレクトリ。`swap-abandon.sh` は offer id も取る。
（`swap_session` は最初「解決しただけで mkdir する」ものを書いてしまい、
**探すと空のセッションができた**。`create` を明示する形に直した。）

**0al. 私が今日入れた破壊的なバグ。** `kamino-verdict.sh` の修理（0x）で
**`rm -rf "$SRC"` を書き、`$SRC` は `KLEND_DIR` が設定されていればそれ** ——
`KLEND_DIR=/some/work/tree ./scripts/kamino-verdict.sh` でそのツリーが消える。
**キャッシュの修理が、他人が選んだパスに触れられてはいけない。**
自分のキャッシュ（既定パス）だけ消し、override は exit 2 で拒否。**実際に消えないことを確認した。**

**0am. 偽だった言い方を3つ直した。**
①`issue-e2e.sh` の *"the identical transaction settled"* —— **fresh blockhash で組み直すのでバイト列は別物**。
「同じ割当（同じ context・口座・金額、承認が1つ増えただけ）」に。
②SHORT モードが承認**前**に *"the gate is open"* と言っていた。この対照は金額だけの話なので、門の物語を借りてはいけない。
③README:156 が**2引数の呼び出し（比較しない形）を教えていた** —— 生きた安全面。第3引数付きに。
④「呼び出し元4本が結果を無視していた」は不正確。**非ゼロは尊重していた。非ゼロが無かった。**
4箇所の文言を直した。

**0an. Codex が正しいと認めた判断1つ。** 0af の凍結提出文の検査（過少申告は許し過大は落とす）は
*"sound; it is not self-serving weakening"*。`full.md` の sha256 は `pasted.json` と一致しており、
別の検査がそれを見ている。

**検査は21件（`swap-pin-check.sh`、チェーン不要）＋ Rust 10件。**
新しい保証を**全部わざと壊して落ちることを確認**した: 未 pin 通過・片脚だけ照合・口座を見ない・
非原子的な pin 書き込み・offer file の id 不一致・検証器の迂回・フィールドずれ・refusal 無視。

**残っている Codex の指摘（未着手）。** ①Rust の合成 fixture は**自分が読むオフセットを自分で書いている**
—— SDK が組んだ proof context の fixture が要る（回帰被覆としては弱い） ②devnet 実走は
**release / demo のゲート**にすべき ③`chmod 700` のエラー抑制。
**RPC が無いので実走は依然できていない。**

## 2026-09-30（4）— 公開 devnet で実走。429 ではなく slot skew で止まった

**0ao. `issue-e2e.sh` を公開 devnet（`api.devnet.solana.com`）で走らせた。exit 1。**
落ちた場所は **Address Lookup Table の作成**:

```
Error: Create failed: RPC response error -32002: Transaction simulation failed:
  Program log: 505745647 is not a recent slot
  Program log: Error: InvalidInstructionData
```

`scripts/lib/swap.sh:286` の `solana address-lookup-table create` が導出する slot を、
**提出先のノードが「recent でない」と判定している。** 公開エンドポイントは複数ノードに
負荷分散されるので、slot の見え方が食い違う。**429 ではない** —— CLAUDE.md が警告している
レート制限より前に、別の理由で止まる。**専用エンドポイント（単一ノード）で解ける類。**

**通ったところ（今日の変更が触った範囲で、実際にチェーンで確認できたこと）:**
mint 2つを `autoApproveNewAccounts: false`・auditor EMPTY で作成、
`configure` / `approve` / `deposit` / `apply` が3口座ぶん、
**投資家の株口座を未承認で開くところ**（`NOT approved — the issuer has not signed for this one`）、
発行体の脚の **6 transactions・3 contexts**。

**通らなかったところ —— そしてこれが肝心。** 署名前の検査（`swap_look` に合意額を渡す形）に
**到達していない。** 投資家の脚を組む途中で落ちたので、**今日足した比較も `SHORT=` の拒否も、
チェーン上では一度も動いていない。** 合成データとチェーン抜きの検査21件では通っている。
**「devnet で動く」とはまだ言えない。**

devnet に残ったもの: throwaway の mint 2つ・口座数個・context 3つ（rent は
`./scripts/swap-abandon.sh` で回収可）・ALT 1つ。資金は 65.16 → ほぼ変わらず。

**次の一手は endpoint ひとつ。** `~/.zshrc` に `export CONFIDE_RPC=...` を置けば、
agent 側は `RPC="$CONFIDE_RPC"` と書くだけで済み、**URL は会話にも repo のファイルにも現れない**
（`SEPOLIA_RPC` で profile の変数がシェルに届くことを確認済み）。
CLAUDE.md の「環境変数としてのみ」をそのまま満たす。

## 2026-09-30（5）— 専用エンドポイントで実走。比較はチェーン上で動いた

**0ap. `issue-e2e.sh` が通った（exit 0）。** founder の endpoint を環境変数として受け取り、
**repo のファイルには書いていない**（`docs-consistency.sh` の THE PRIVATE ENDPOINT が検査している）。
公開エンドポイントを止めていた ALT の slot skew は出ない。

**今日足した比較が、実際にチェーン上で動いた:**

```
  ✓ it will move 2000000000000 base units to you
      decrypted from the verified context, by you, without anyone's cooperation
  ✓ and 2000000000000 is what you agreed
      compared here, not left to your eye
```

門の拒否も引用できる署名つきで残った —— `Custom(24)` /
`5cYPobHEEpECCX9QhsPfquyW4cvhP6NmGD2Vd9jayyF7dU55ivYJDe6aLGYXCqcAE4aQXWmfQs24fZMQdYEdkVUT`。
（**最初にここへ書いた署名は先頭2文字が余っていた** —— ログから抜くときに ANSI エスケープの
`2m` を base58 として拾っていた。**チェーンに聞いて確かめたら見つからなかった**ので直した。
導出した値を検算しない、の型。）承認後、同じ割当が settle。**公開残高は4口座すべて 0**、
発行体の在庫 480,000 / 投資家の株 20,000 / 現金 3,500,000 が秘匿のまま動いた。
証明は発行体 6 tx・3 contexts、投資家 **14 tx・5 contexts**（現金脚は手数料付きなので5本）。

**0aq. `SHORT=2000` が devnet で拒否した（exit 0）。一度も走っていなかった負の対照。**

```
  ✗ you agreed 2000000000000 and this leg moves 200000000000 — short by 1800000000000.
      DO NOT SIGN. Nothing has happened yet: no signature of yours exists ...
  REFUSED BEFORE SIGNING. No transaction was built, so none was signed and none was sent.
```

**これで「秘匿スワップの唯一の危険」に対する答えが、人間の目ではなく終了コードになったことが
チェーン上で確認できた。** 09-30（2）と（4）で「未確認」と書いた部分はこれで埋まった ——
**ただし bilateral（offer/accept/settle/sign）の terms pin は依然として devnet 未実走。**
`issue-e2e.sh` は bilateral の経路を通らない。

**0ar. `healthcheck.sh` は1件赤。** **devnet はリセットされていない** —— pin した program・
loan・秘匿口座・mirrored mint・anchored disclosure・ZK 証明2本・testbed、全部生きている。
mainnet の NVDAx も不変。赤は **公開サイトが今日の `web/index.html` ではない**こと
（母集団の訂正と動画の訂正注記を入れたため）。`./scripts/publish-site.sh --push` が要る。
**サイトは提出リンクの1つで、repo が撤回した主張をまだ掲げていた。**

**0as. 公開した（founder の判断）。** `index.html` / `kamino.html` / `slots.json` / `usage.json` の4件。
**`usage.json` は今日の変更ではない** —— サイトが 09-28 の計測より古いものを配信していたので、
公開で口座数が committed 値に前進した。**`healthcheck.sh` はこれで exit 0、all clear。**

**確認のとき自分の curl に騙されかけた。** publish 直後に
`https://psyto.github.io/confide/` を引いたら**撤回した文がまだ 1 件あり、訂正文が 0 件**だった。
healthcheck は同時刻に緑。**CDN の古いキャッシュを見ていたのは私の方**で、
healthcheck は `$PAGE/index.html` の sha を `web/index.html` と比べている。
キャッシュを外して引き直し、**live の sha がローカルと一致・訂正文あり・撤回した文 0 件**を確認した。
**派生物（キャッシュされた応答）ではなく実物（sha）を見る、の同じ型。**

## 2026-09-30（6）— デモ動画の台本を書いた。存在していなかった

**0at. `video/DEMO.md`（7場面・158 秒・348 語）。** CWF の必須2本のうちデモ側の台本が
**一つも存在していなかった** —— `video/` にあったのは CHECKIN-1 / CHECKIN-2 /
CWF-PRESENTATION / DELIVERED / voiceover だけ。他は全部 `pace.py` が尺を検算しているのに、
**デモは台本が無いので検算する対象も無かった。**

**構成は brief §2 の 1→7 をそのまま追う。** 門が閉じた mint → 保有者が口座を開く →
**on-chain の拒否（署名つき）** → 発行体が「その口座だけ」を承認 → 同じ割当が settle →
**署名前の検査と `SHORT=` の拒否** → ブラウザで公開残高が4口座すべて 0。
**今日の実走出力に合わせて書いた** —— 画面に何が出るかを見てから書けたので、
`*Shows:*` 欄は実際の行を引いている。

**署名はハードコードしていない**（毎回変わる）。数字は `issue-e2e.sh` の既定値から導出できるもの
だけ（20,000 株・$3,500,000・$175/株・treasury 480,000・現金 1,500,000）。

**165 秒を狙って書いた。上限 179 ではない。** `pace.py` の値は 137 wpm の予測で、
**check-in 2 は 58 秒の台本が 60.2 秒で書き出された（約4%長い、0i）**。検査は ffprobe を読むので、
紙の上で収まる台本が納品で落ちる。158 秒なら4%増でも 164 秒で、3分に対して余白がある。
この理由を `DEMO.md` の中に書いた。

**0au. `pace.py` が台本を名前で探していたので、書いた台本が検査対象外だった。**
`DOCS` は `["video/CWF-PRESENTATION.md"] + glob("video/CHECKIN-*.md")` —— **`DEMO.md` は
どちらにも一致しないので、尺表を持っているのに何にも検査されていなかった。**
`pace.py` 自身のコメントが「手で維持する一覧がこのリポジトリの全ドリフトの形」と書いている、その形。
**中身で探す**ように変えた（尺表を持つ `video/*.md` が台本の定義）。
わざと2通り壊して確認: ①ナレーションに1語足すと表が不一致 ②**旧パターンのどちらにも一致しない
名前の台本**（`PITCH-TEST.md`）を置くと拾われる。

**次に足りないもの。** 台本が要求する負の対照のうち、**「2つ目の署名が無い」は語りだけ**で
（`swap-sign.sh` が *"cannot execute"* と書くが、1署名の取引を送って拒否されるところを誰も見せていない
—— brief 自身の *"Never rely on a narrated claim"* に当たる）、**「承認権限が違う鍵」は存在しない**。
**ただしどちらも今の台本には入っていない** ので、デモ収録の前提ではない。
残るのは**一本の語りへの突き合わせ**（README / STORY.md / 提出文 / ナレーション）と claim ledger、
そして収録そのもの（デモは画面、ピッチは founder）。

## 2026-09-30（7）— 負の対照を2つ足した。Codex が「表示だけ」を2箇所見つけた

レビュー全文 [`docs/reviews/2026-09-30-two-more-refusals.md`](docs/reviews/2026-09-30-two-more-refusals.md)、
依頼文 `docs/reviews/payloads/2026-09-30-two-more-refusals.md`。指摘は6件で、全部実ファイルで確認して採った。

**0av. 承認権限の無い鍵（brief §3 P0）。** `issue-e2e.sh` の既定の実行で、Custom(24) の拒否の後・
発行体の承認の前に、**投資家が自分の口座へ `ApproveAccount` を送る。** preflight を切って着地させ、
着地したエラーを読み返す。期待値は `MissingRequiredSignature`
（spl-token-2022 8.0.1 `process_approve_account`、Codex が現行 main でも同じと確認）。
その後、口座の `approved` を**チェーンから読み**、false でなければ落ちる。

**0aw. 2つ目の署名が無い（brief §3 P0、09-30（6）で「語りだけ」と書いたもの）。** 承認後、
`swap-tx build`（公開鍵だけで組む経路）→ 発行体だけが `sign` → 送る。**RPC の preflight で拒否される。**
**ブロックに入らないので、チェーン上に引用できる署名は無い** —— スクリプトはそう言う。
そして**同じ `half.b64` に投資家の署名を足して送り、それが settle する。** 組み直さないので、
拒否された取引と通った取引の差は署名1つだけ（Codex の指摘 2 —— 最初の版は成功側を別経路で組み直していた）。

**Codex が見つけた「表示だけ」2箇所。** ①「1 of 2 signatures」を `grep ... || true` で**印字していただけ**
—— 0 of 2 や 1 of 3 でも RPC の別の拒否で通りえた。**「発行体が署名、1 of 2」を必須に**した。
②**公開残高 0 を印字していただけで判定していなかった。** brief の7番目（observer には何も見えない）が
表示だった。4口座とも 0 でなければ落ちる。**0aa と同じ型が、自分が書いた直後のコードに2つ残っていた。**

**0ax. RPC の拒否の形は、このリポジトリでは未観測。** 最初は `-32003` か、`Signature` を含む任意のエラーを
受けていた。Codex によると現行 Agave は `-32002` + `data.err == "SignatureFailure"`（`-32003` は旧形）で、
**`*Signature*` は緩すぎる**（その語を含む別の拒否を通す）。**2つの厳密な形だけを受ける**ようにした。
どちらが返るかは実走で分かる。

その他: 別鍵承認のコメントを「発行体の署名が欠けている」から正確な言い方に直した
（署名は有効で、名乗った鍵が承認権限でない）。「REFUSED by the network」→「REFUSED in RPC preflight」。
割当の成功時に**署名と compute units を印字**する（brief §3 P0 の「reviewer に必要なもの」）。
着地確認のコードを `landed()` に1本化し、Custom(24) と別鍵承認が共有する。

**わざと壊して確認した（スタブで、落ちた理由まで表示して）。** 別鍵承認6通り・Custom(24) 5通り・
半署名8通り・公開残高2通り・完成側2通り。**最初のハーネスは変数未定義と SIGPIPE で「want 1」を
理由違いで満たしていた** —— 終了コードだけ見て緑と読みかけた。理由を出して取り直した。

**devnet 未実走。** このセッションには endpoint が無い。**次の一手は `RPC=… ./scripts/issue-e2e.sh`**
で、見るべきものは3つ: 別鍵承認の着地エラーが `MissingRequiredSignature` か、半署名の拒否が
どちらの形で返るか、4口座の公開残高が 0 で判定を通るか。

## 2026-09-30（8）— 「なぜ空か」を語る面を全部外した。3巡目で止めた理由も書く

レビュー全文 [`docs/reviews/2026-09-30-the-motive-r1.md`](docs/reviews/2026-09-30-the-motive-r1.md)・
[`-r2.md`](docs/reviews/2026-09-30-the-motive-r2.md)、依頼文は `docs/reviews/payloads/` の同名2本。

**0ay. 発端は私の回答だった。** founder に「発行体は見る・届くための設定を全部入れている。
だから額が見えない状態を受け入れにくいのではないか」と答え、根拠に `WHY-THE-SLOT-IS-EMPTY.md:40-59` を挙げた。
**09-27 に撤回した意図の読みそのもの**で、そのファイルの本文に残っていた。09-29 の `e64abe5` は
「9面から外した」と書いたが、検査を足していなかった。**派生物（コミットメッセージ）を見て実物を確かめない**の型。

**0az. 残っていた面（全部実ファイルで確認して直した）。** 公開サイト `web/index.html`（*"because the only key…"*）、
README（3箇所）、YouTube 説明文、ONCHAIN §8 と :189、DESIGN（2箇所）、STORY（2箇所、うち
*"Every regulated Token-2022 issuer arrives here"* は4発行体からの全称）、COMPOSITION、WHAT-THE-WEEK-CHANGED、
FOUNDER-MARKET-FIT（2箇所）、POST（未投稿の下書き、3箇所）、CWF フォーム（2箇所）、
`slot-scan.sh` の**実行時出力**、Rust の doc comment 2本、`refresh-mints.sh`、`onchain-check.sh`、`demo.html`（3箇所）、
packets の生成器と README。**置き換えの規則は一つ: 測定は残し、動機は外す。「空は既定値でもある」**。理由は THE-PINCER の1箇所だけ。

**0ba. 反対向きも同じ誤り。** 「誰も選んでいない」「substrate が強いた」も**測れていない** —— 既定値は
誰も決めなかったことの証明にならない（Codex r2 も同意）。CWF フォームの *"a constraint nobody chose"* は
実は Kamino の `constraints.rs:187`、**誰かが書いた規則**を指していた。

**0bb. 「セカンダリーを塞ぐ」を撤回（ISSUANCE-RUNS、issue-e2e.sh）。** 技術的には投資家間スワップは通る
（`swap-e2e.sh`）。発行体が額を見られない状態を受け入れるかは**誰にも聞いていない** —— brief §3 P1 の問い。

**0bc. 監査人鍵の範囲も、書き直した文では正確にした。** 「everything, for everyone, forever を復号」→
「**設定中に行われた秘匿移転の額**を復号できる」。brief §1 の通り残高全体ではない。
**リポジトリ全体の掃除はしていない** —— `video/demo.html` 等に *"everyone's everything, forever"* が残る。次の項目。

**0bd. 検査 THE MOTIVE（`docs-consistency.sh`）。** 1版目は言い回しの一覧で、**Codex が同じ日に11件を素通りさせた**。
2版目は**形**で判定する（CAUSE / INDEPENDENCE / INTENT / SECONDARY、文単位＋隣接2文）。
Codex r2 がさらに「削除すれば素通り」「Kamino / not ours を含む文は丸ごと免除」の2穴を示し、塞いだ:
凍結11ファイルは sha256 で固定・削除も落ちる、撤回文の削除も落ちる、例外は発行体を名指す文には効かない。
**固定テストを検査の中に埋め込んだ** —— 今日実在した文を中心に MUST_FLAG と MUST_PASS（件数は検査を読めば分かるので書かない —— 最初に書いた数は2つとも違っていた）。
規則を1つずつ外す13通り・削除2通り・公開サイトを戻す・新ファイルに書く、**全部落ちるのを確認した**。
（固定テスト自体が私の規則の弱さを3回捕まえた —— 「it」主語、`**` の後の文境界、表と JS の塊で遠い語を組にする誤検出。）

**0be. 3巡目のレビューをかけずに止めた。理由。** Codex r2 は *"the pattern is purposeful"* のような**作文した言い換え**で
検査を抜けてみせた。正規表現は言い換えに必ず負ける。**この検査は意味の証明ではなく、読んで直したものが戻らないための守り**
と検査自身のコメントに書いた。次に読むのは人（と Codex）で、検査ではない。

**founder の手で:**
1. **貼り直し2件が増えた** —— CWF フォーム（未提出、元から赤）と **YouTube 説明文（公開中、今回赤になった）**。
2. **公開サイトの再公開** —— `web/index.html` が変わったので `healthcheck.sh` は live との不一致で赤になる。
   `./scripts/publish-site.sh --push`。公開中のサイトは撤回した文を掲げている。
3. **CWF プレゼン動画の一節の録り直しを勧める**（Codex r1/r2 とも）。*"No setting shows one balance to one regulator —
   so every issuer left it empty."* 判事が聞く。録り直さないなら、少なくとも訂正を添える。

**次の項目（今回やっていない、別の種類）:** ①監査人鍵の範囲の言い過ぎを全面から ②公開サイトの
*"Three have asked"* と `usage.json` の 2 の不一致 ③日付なしの 469,477（ISSUANCE-RUNS:11）
④6銘柄の口座スキャンを 1,992 全体に広げている箇所（`issue-e2e.sh:8`、`testbed-join.sh:6`）。

## 2026-09-30（9）— 語りの順番とデモの見せ方を founder と合意した

**founder の決定（2026-09-30）:** ①語りの順番は「測定した問題 → なぜ開いていないか（分かることと分からないこと）
→ Confide とは何か → 動くところ → 境界」②デモは**発行体→投資家の割当から入る** ③**Web アプリで見せる**
（Web のみ、モバイルは見送り、証明と鍵は手元のサーバー）④**第2幕を入れる** —— brief §2 の手順6
（承認された保有者2人の株⇄現金の決済）。④は Codex が「brief と設計が食い違っている」と指摘して founder に聞いた。

**0bf. `STORY.md` を書き直した。** Codex のレビュー（`docs/reviews/2026-09-30-story-and-app.md`）が
**証拠の範囲の誤り2件**を見つけ、実ファイルで確認して直した: ①518,744 は**6銘柄（発行体ごとに2つ）の標本**で
（`usage-scan.sh:4`）、「Nobody is using it」「門は誰にも開けられたことがない」は全体への拡大だった ②「秘匿口座には発行体の署名が要る」は
誤り —— **設定は保有者が自由にでき、使えるようにするのが承認**。ほかに「with it empty, no holder can show anything」
の言い過ぎ、devnet 実走の範囲、手で書いたテスト数（104、README は 114）を直した。「発行体が最初の買い手」は
**作業仮説**として書いた。

**0bg. `issue-e2e.sh` に第2幕。** 投資家が割当の 5,000 株を第2の保有者に $875,000 で売る。**二者間の4手順
（offer / accept / settle / sign）を、当事者ごとの別フォルダで**呼ぶ —— 1台で2台のマシンの代わり。
`ACT2=0` で第1幕だけ。**devnet 未実走**（二者間の合意固定の経路は一度もチェーンで動いていない）。

**0bh. `docs/cwf-2026/DEMO-APP.md`（設計、未実装）。** 規則は「**第2の証明・取引・方針エンジンを作らない**」。
拒否は**スクリプトが検査の後に出した型つきのイベント**からだけ表示し、終了コードや時間切れから推測しない。
3つの画面は**1人の発表者のための可視化で、分離された役割ではない**と明記する（鍵は全部サーバー、イベントは全部1つのブラウザに届く）。
ローカルサーバーの要件（CSRF・Host 検証・許可リストだけの読み取りプロキシ・RPC を画面に出さない）は Codex の列挙を採った。

**次:** アプリの実装、そして **devnet 実走1回**（第1幕の新しい2手順と第2幕。endpoint が要る）。

## 2026-09-30（10）— デモアプリを実装した。Codex が2巡で5つの欠陥を見つけた

`app/server.py`（Python 標準ライブラリのみ）、`app/static/`（3列＋第2幕の画面）、`app/test_app.py`。
起動は `RPC="$CONFIDE_RPC" python3 app/server.py` → `http://127.0.0.1:8787/`。設計は `DEMO-APP.md`、
レビューは `docs/reviews/2026-09-30-demo-app-impl-r1.md` と `-r2.md`。**devnet 未実走。**

**仕組み。** アプリは `issue-e2e.sh` を動かすだけ。スクリプトは手順の前で `pause`（FIFO で1行待つ）、
検査を通った後で `ev`（型つきの1行）を書く。サーバーはその行を検査して画面に流すだけで、
**拒否も決済も自分では判定しない**。どちらのフックも環境変数が無ければ何もしない。

**0bi. 私が SHORT 対照に入れていた欠陥（09-30（2）から）。** `swap-check` は額の不一致も読み取りの失敗も
**全部 exit 1** だったので、SHORT の経路は**証明 context が見つからなくても「署名前に拒否した」と言って exit 0**
していた。→ 不一致だけ **exit 3**。SHORT は 3 のときだけ拒否を報告し、それ以外は「検査が完了しなかった、
額の拒否ではない」で落ちる。（Codex r1。端末版にも効く修正。）

**0bj. Codex が見つけた残り。** ①第2幕の買い手の「検査済み」が**決済の後**に出ていた → 二者間スクリプトの中、署名の前に移した
②数えていない「1 of 2 / 2 of 2」を書いていた → 消した ③端末実行でも復号額のコピー（`check.out`）を書いていた → アプリの時だけ
④再接続で「待っている手順」が巻き戻り、同じ手順を2回進められた → イベントはランごとに1本だけ読む
⑤**ランが終わっても鍵を含む作業フォルダが残っていた**（設計書は「終了時に削除」と書いていた）→ 終了時に削除、
メモリには検査済みイベントだけ ⑥`bound=yes` がスキーマに無く捨てられていた。ほかに `tee` 失敗を無視・置き換え時の競合・書き込みで詰まる接続。

**0bk. 私が自分で見つけたもの。** 復号額は `ESC[1m` の直後にあり、最初の抜き出し方は**エスケープの「1」を拾う**ところだった。
`read-balance` の2行目は**公開残高をチェーンから読まず「0」と固定で印字している**（`read_balance.rs:36`）—— 表示だけの主張で、
今回の公開残高の判定（`issue-e2e.sh` がチェーンから読む）には関係しないが、**直すべき項目**。

**検査。** `app/test_app.py` 14件（チェーン不要）。`swap-pin-check.sh` は `look` ラッパーの呼び出し元も読むようにした。
わざと壊して14通り確認（イベントを検査の前に移す・CSRF を外す・RPC を流す・任意の手順を進める・許可リストを開ける・未知のキーを通す・
SHORT で何でも拒否扱い・第2幕の検査を署名後に・手順を再武装・許可リストを1つに・終了時に消さない・`bound` を捨てる・`tee` 失敗を無視）
—— 全部落ちた。**1つだけ落ちない**: 置き換え直後に古いランの ID を読む競合の守り（外しても、許可リストで先に 404 になる）。
守りは残し、競合そのものはテストで再現できていない。

**画面を実際に描画した**（ブラウザ）—— ただし**偽のイベント**で。偽のスクリプトはスクラッチに置き、**repo には入れていない**
（録画に使われないように）。

**次:** ①**devnet 実走**（アプリ経由と端末の両方。第1幕の新しい2手順、第2幕、SHORT）—— endpoint が要る
②`read-balance` の固定「0」 ③全体スタブによる「イベントの有無で同じ取引か」の検査（設計書で未実装と明記）。

## 2026-09-30（11）— `read-balance` はチェーンを読まずに「公開残高 0」と言っていた

**0bl.** `read-balance` は暗号文を受け取って復号するだけのツールで、チェーンに触れない。それなのに2行目で
`public balance 0 <- what the chain shows anyone` と**固定で印字していた**。→ 呼び出し元が読んだ公開残高を
第5引数で受けたときだけ表示し、無ければ「読んでいない」と言う。単体テスト2件、固定の 0 に戻すと落ちる。
3行目の位置は変えていないので、3行目だけを使う呼び出し元（`issue-e2e.sh`・`swap-e2e.sh`・`seizure-e2e.sh`・
`testbed-join.sh`）は影響なし。

**0bm. `scripts/read-balance.sh` は decimals を渡していなかった** —— 既定の 8 になり、6桁の現金口座は桁を誤って
表示されていた（ツール自身のコメントに同じ誤りが一度あったと書いてある）。同じ1回の読み取りから公開残高と decimals を取って渡す。

README のテスト数 70 → 72（`docs-consistency.sh` が捕まえた）。devnet 実走は endpoint 待ち。

## 2026-09-30（12）— devnet で最後まで通った。端末でも、アプリ経由でも

**0bn. 端末の `issue-e2e.sh`（第1幕＋第2幕）が exit 0。** チェーンに聞いて確かめた署名:

| | 署名 | チェーン上の結果 |
|---|---|---|
| 承認前の割当 | `3kNSFF8DRXACgfPb6gY9Knrv8aiV7vMYGZthS8Yzdt8KUVq3eh1CR8pE6iXYUGJt9ueXrVYuWq6DNFExCbVPh1qA` | slot 505837686、`Custom(24)` |
| 投資家の自己承認 | `CFb4KDcnaXJA1LLA5VG5VLrQdEKD1XdH92pNpDNoa4VKD48CSULnY32dDMreD2WiVBvviwDpFVAJTC2dfgDrN4Q` | slot 505837706、`MissingRequiredSignature` |
| 割当の決済 | `5qqJ7e5ASBcSh2yf5S5N3rotTvkG9QagfLscugdM4C95MsH8JnBfg6JGJ8stFXBQNyraZrffaJJjyMGMExgET8M2` | slot 505837749、成功、60,463 CU、署名2 |

片側署名は RPC preflight で `-32002` / `SignatureFailure`（Codex が言った現行形）。公開残高は第1幕・第2幕とも4口座すべて 0。
**第2幕の二者間の合意固定がチェーン上で初めて動いた** —— 投資家が受け取る現金 875,000 を pin と照合、買い手が株 5,000 を照合し
取引の同一性も確認、1取引で決済。確定後: 投資家 株 15,000・現金 2,375,000、買い手 株 5,000・現金 125,000。
**`SHORT=2000` も exit 0 で拒否** —— 新しい exit 3 の経路をチェーン上で通った。

**0bo. アプリ経由も完走（`process completed`）。** 18手順を順に進め、イベントの順序は設計どおり、409 は0回、ラン終了時に
作業フォルダ（鍵）は消え、ログにも記録にも URL は無い。決済は 20,000 株 ⇄ $3,500,000・60,463 CU で端末と同じ数字。
実データでの画面をブラウザで確認した。

**そこに至るまでに2回止まった —— 両方とも私の側か基盤の側の問題で、両方直した。**
①**片側署名の判定が、正しい拒否を「別の理由」と判定した。** `chain.sh` の `send` がエラー本文を **300文字で切る**ので、
長い `-32002` の JSON が読めなかった。チェーン無しのテストは短いエラー文を使っていたので捕まらなかった。
→ この手順だけ `rpc` で全文を読む。実際の応答（300字超）を固定テストに入れ、`send` に戻すと落ちることを確認。
②**ALT 作成で `… is not a recent slot`** —— 09-30（4）の公開 endpoint と同じ症状が**専用 endpoint でも**出た。
シミュレーションでの失敗なので何も作られない → そのエラーだけ最大4回まで間を空けて再試行、他のエラーは従来どおり止まる。
ほかにネットワークの一時切断（`spl-token mint` の確認中、OS error 54）が1回。送信済みの可能性があるので自動再送はしない。

**0bp. `spl-token` はエラーのとき RPC の URL をそのまま出力する。** 端末実行のログには endpoint が残りうる ——
**手で走らせたログはコミットしない。** アプリは生ログを画面に出さず、ラン終了時に消す。私のスクラッチのログの1件は伏せ字にした。
新しい ALT の再試行は、エラーを表示するとき URL を伏せる。

画面の小さな直し: 終了時に手順の一覧が「完了」にならなかった。

## 2026-09-30（13）— デモ動画を Chromium で録った。devnet の実走そのもの

**0bq. `video/demo-app.mp4`（2:56、1920×1080）。** `video/record-app.js` が puppeteer で Chromium を動かし、
アプリのボタンを押しながら**devnet 上の実走を録った** —— 第1幕・第2幕・SHORT の対照、全部通って終わった
（`normal: done`、`short: done — the short leg was refused`）。生の録画は約10分（実時間 593 秒、録画 580 秒）。

**編集は1種類だけで、画面に出す。** `video/cut-app.js` はボタンを押してから次のボタンが出るまで ——
devnet が証明を検証し取引を確定している間 —— の**中ほどだけを速く流し**、その間は右上に
「▶▶ fast-forward ×N · waiting on devnet · real time m:ss」の帯を出す。押した瞬間と結果が出た瞬間は等速。
削除・並べ替え・差し替えはしない。**早送りした19区間と各実時間は `video/demo-app.manifest.json` に全部ある**
（最長は証明の構築 71.6 秒）。読み取りのための間（結果を見せる時間）には手を付けていない。

**録画の時計が実時間とずれる**（フレーム落ちで録画の方が約2%短い）ので、記録した時刻を録画の長さに線形に合わせた。
帯が正しい区間に乗っていることはフレームを取り出して確認した。録画・編集とも、2つのランが正しく終わった記録が
無ければ拒否する（試験で、失敗した試し録りに「devnet run」と書いた manifest を出しかけたため）。

**3分に収めるために詰めた**のは、早送り区間の長さ（1.1 秒）と前後の等速部分（0.4 秒）だけ。
**帯が約1秒しか出ない区間がある** —— 読めるかは人の目で確かめてほしい。足りなければ、録り直して読み取りの間を短くし、
帯を長く出す方が正しい。

**ナレーションはまだ無い**（音声は founder の作業）。`video/DEMO.md` の台本は端末版のデモ用に書いたもので、
アプリの画面と第2幕に合わせて**書き直しが要る**。生の録画（`video/.demo-render/`）はコミットしない。
画面の小さな直し: 手順を押した後の状態表示を「working on devnet: …」に。

## 2026-09-30（14）— 2つ目の画面（決済オペレーション）と、その動画

**founder の決定:** 今の画面を残したまま、新しい画面を作る。→ `/` は元の画面（役割ごとの列）、`/ops` は
**決済オペレーション画面**: 発行体の承認キュー、幕ごとの DvP 決済チケット（段階が順に並ぶ: 承認前に送って拒否 →
発行体が承認 → 片側署名で拒否 → 両方の署名で決済）、公開台帳、各保有者が自分の鍵で読んだ残高（「1人の発表者が
全部の鍵を持っているから並べている」と明記）、証拠つきのブロッター。**同じイベント・同じ検査・同じ規則**で、何も判定しない。
Bloomberg 風にはしなかった —— 板・気配値・チャートを連想させる見た目は、Confide が持たないものを約束するため。
価格の欄は「現金 ÷ 株数、取引の外で合意」と明記した計算値だけ。

**`video/demo-ops.mp4`（2:55）** —— 新しい画面で devnet を実走して録った（通常の実行と SHORT、両方とも通って終わった）。
早送りした21区間は `video/demo-ops.manifest.json`。`video/demo-app.mp4`（元の画面）はそのまま残している。
1回目の録画は下4割が空いて文字が小さかったので、文字を大きくし画面の高さいっぱいに広げて**録り直した**。
スクリプトの最初のイベントに合意の株数・現金を載せた（決済前からチケットに両脚が出る）。

**まだのもの:** ナレーション（founder）と、`video/DEMO.md` の台本をどちらかの画面の動画に合わせて書き直すこと。
新しい画面そのものは Codex のレビューをまだ受けていない。

## 2026-09-30（15）— 画面で「Confide がやったこと」を名指しする。拒否は Token-2022 と Solana のもの

**founder の依頼:** Confide が使われているところをアピールしたい。→ `/ops` の各段階とブロッターの各行に
**担当の札**（CONFIDE / TOKEN-2022 / SOLANA）を付け、発行体の列に「CONFIDE IN THIS RUN」を置いた ——
「ルールを執行するのは Token-2022 と Solana、その周りの仕事をするのが Confide」。起きたことだけが ✓ になる。

**線の引き方（STORY §1 の通り、取引の中で動くのは Confide ではない）:** 証明を作る（検証はチェーン）・署名前の検査・
条件の固定・取引の同一性の照合・株と現金を1取引に組む ＝ **CONFIDE**。承認前の送付の拒否・承認・自己承認の拒否 ＝
**TOKEN-2022**。片側署名の拒否 ＝ **SOLANA**。決済 ＝ **CONFIDE + TOKEN-2022**。
**拒否を Confide の手柄にしない** —— それはチェーンの基本機能で、名乗れば言い過ぎになる。
「PROOFS VERIFIED · CONFIDE」は検証まで Confide がしたと読めたので「PROOFS BUILT · CHAIN-VERIFIED」に直した。

**`video/demo-ops.mp4` を差し替えた（2:56）** —— この画面で devnet を実走して録り直した（通常・SHORT とも通って終わった）。
早送りした20区間は `video/demo-ops.manifest.json`。

## 2026-09-30（16）— デモの台本を `demo-ops.mp4` に合わせて書き直した

`video/DEMO.md` —— 8場面・339語・予測 165 秒（`pace.py` が生成、動画は 175.7 秒）。場面ごとに動画の時刻
（0:00–0:23 …）を書き、画面と**同じ線引き**で語る: 拒否は Token-2022 と Solana、作る・確かめる・固定する・組むは Confide。
締めは「ルールを執行するのは Token-2022 と Solana、その周りの仕事をするのが Confide。devnet で、実在の発行体はまだ使っていない」。
端末版の台本（第2幕なし）はこれで置き換えた。**「第2幕は devnet で未実走」の但し書きは消した** —— 09-30（12）で走った。
予測で窮屈なのは場面2（12 / 12.5 秒）と場面5（8 / 8.2 秒）。音声は founder の作業。

## 2026-09-30（17）— ナレーションを Codex のレビューで直し、担当表示も2箇所直して録り直した

レビュー `docs/reviews/2026-09-30-demo-narration.md`。全部実ファイルで確認して採った。
**ナレーション:** 片側署名は「Solana が拒否」ではなく**RPC の preflight で拒否、ブロックに入っていない**。
公開の範囲を言い切る（mint・口座・取引は公開、公開残高 0、額は暗号化）。「its key cannot read」→ **mint 全体の監査人鍵が
無いので、承認しても額を読む立場にならない**（1台で全部の鍵を持つデモで紛らわしかった）。「Confide decrypts」→
**投資家の Confide クライアントが投資家宛ての額を復号**（Confide が鍵を預かるように聞こえた）。条件は**取引の外で合意**、
**取引の場でもマッチングでもない**、そして**早送りしていることを冒頭で声でも言う**（帯が1秒ほどの区間がある）。
**画面:** 公開残高の読み戻しを TOKEN-2022 としていた → **SOLANA RPC**（RPC の読み取り）。決済の札から Solana の
アトミック性が抜けていた → **CONFIDE + TOKEN-2022 + SOLANA**。

**`video/demo-ops.mp4` を録り直した（2:55）。** 1回目は第1幕の途中で**ヘッドレス Chromium のページが閉じて**止まった
（スクリプト側ではない。原因不明、2回目は完走）。止まったランはサーバーを SIGTERM で止めて片付けた。
その際、**SIGTERM の後片付けを入れる前の試し録りの一時フォルダ**が1つ残っていたのを見つけて消した（空の作業フォルダ、鍵なし）。

**場面の時刻を導出にした。** `cut-app.js` が各操作の編集版での秒を manifest に書き、`video/demo-times.py` が台本の
「*Shows:* m:ss–m:ss」を書き換える。`docs-consistency.sh` の THE DEMO SCRIPT'S TIMES がずれを落とす（わざと1秒ずらして落ちるのを確認）。
**台本本文に手で書いていた動画の長さ（175.7 秒）は、録り直しで早速 175.2 秒にずれていた** —— 数字をやめて manifest を指す形に。
台本は 331 語・予測 162 秒、各場面が自分の区間に収まる。

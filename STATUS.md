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
384,181 口座、$23.2m、SEC の日付と 0.25% 上限が、これで全部フォームに入っている。

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
| **門を通った人はまだ誰もいない（2026-09-20）** | 設定ではなく**口座**を数える測定がどこにも無かったので `./scripts/usage-scan.sh` を書いた。保有者のいる5銘柄（Backed の Apple / NVIDIA、PreStocks の SpaceX / Anthropic）で **384,181 口座を走査し、秘匿転送に設定されたものは 0 件**。最初の走査で「400バイト超」が7件出たが、全部 `pausableAccount` と `transferHookAccount` で大きいだけだった（サイズは示唆、拡張リストが判定）。**先行者はおらず、出遅れてもいない。** web/usage.json に出力し、docs-consistency.sh に検査を追加（わざと壊して落ちることを確認済み） |
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

## 未決（founder の手でしか動かない）

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
   - **384,181 を「市場規模」として提示してはいけない。** 発見（機能は出荷され未使用）は無傷で、
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
   それ以上に**報告している週が違う** — スワップも 384,181 の走査も SEC も、全部この後の出来事。

   [`video/CHECKIN-1.md`](video/CHECKIN-1.md) を書き直した。64秒・138語・3シーン。
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
   正しかった。**09-20 の再測定で 384,181 になった** — 3日で 730 動き、丸めた「千」の桁が変わった。
   0.4% のずれだが、**この提出物の売りが「全部再計算できる」ことなので、審査員が実際に
   `./scripts/usage-scan.sh` を回すのが想定読者**であり、そこだけ合わない。
   文書・ページ・提出文・YouTube 説明文は**すべて 384,181 に更新済み**。動画と台本と字幕は
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
     `https://youtu.be/gilIzns5joM`。**動画は `gilIzns5joM` が現行**で、`p1aQuEnzhQk`・`KQsRwP8HTs0`・
     `ZuhLvH5MFgE` は旧版。**2026-09-21、founder が旧3本を削除。3本とも 404 を返す。**
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

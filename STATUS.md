# STATUS — Confide

Confide は **2つの大会に出る**。窓も、判定の対象も、名乗り方も違うので、混ぜない。

| | Stocklana | Crypto World's Fair |
|---|---|---|
| 主催 | hackathons.solana.com | Colosseum |
| 締切 | ~~2026-09-18 16:00 ET~~ **提出済み 2026-09-15** | **2026-10-12 23:59 PT** |
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
   `psyto.github.io/confide/` は 200、動画 `youtu.be/p1aQuEnzhQk` も 200。提出に必要なリンクは3種類とも
   生きている（確認 2026-09-15）。CWF の Official Rules §8(e) は **Open-source 自体が審査基準**なので、
   これは要件であると同時に加点でもある。

## Stocklana は提出済み（2026-09-15）

3リンクとも生存を確認して出した。`healthcheck.sh` は8項目 all clear、`cargo test` 29。
**判定は 10-02 まで続き、devnet はその間にリセットされうる。** 週次で `./scripts/healthcheck.sh` を
回すこと。復旧手順は [`docs/DURABILITY.md`](docs/DURABILITY.md)。**mainnet の核心発見はリセットされない。**

**バウンティトラックは3枠とも使わなかった。** 記録しておく:

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
     `https://youtu.be/p1aQuEnzhQk`。**動画は `p1aQuEnzhQk` が現行**（`94fccfd`）で、
     `KQsRwP8HTs0` と `ZuhLvH5MFgE` は旧版。**旧 URL も 200 を返すので、貼り間違えても壊れて見えない**
     ——現行の判定は `scripts/healthcheck.sh` の `VIDEO` を正とすること。ここに ID を書き写すたびに
     腐る（09-15 に一度腐った）。
   - 過去作業の開示欄（規約要件）。記入元は [`docs/WORK-WINDOW.md`](docs/WORK-WINDOW.md) と
     上の再利用表。**repo に書いてあることは開示にならない。**
3. **9/14 公開のトラック / スポンサー / 審査員 / フォーム項目を読む。** Tempo トラックは条件未公開
   （"Session details coming soon"、9/16 workshop）。Solana トラックだけが $100,000 / 10件 と判明。
4. **README / DESIGN の "written in-window" を CWF 向けにどうするか。** 両方の表が Confide を
   *written in-window* と書いている。これは **Stocklana の窓**では真だが、**CWF の窓では偽**
   （48 commit が 09-14 06:00 PT より前）。**同じ public repo を両方の審査員が読む。**
   CWF の審査員には二重の意味で不利 — 誤読されれば虚偽申告に見え、正しく読まれても
   「窓内の成果」がどれか分からない。`docs/WORK-WINDOW.md` への導線を README に置くのが最小の手当て。
5. **CWF 提出動画は2本** — 2〜3分のプレゼンと3分以内のデモ。**既存の 2分動画とは別物**で、提出時に作る。

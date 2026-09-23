# CLAUDE.md — Confide

## 起動時にやること

1. **`STATUS.md`** を読む。2大会の窓・提出状況・founder しか動かせない未決事項がここにある。
2. **`docs/27-DAYS.md`** を読む。CWF に向けた計画で、**賭けの中身と拒否リスト**が書いてある。
3. 何かを主張する前に **`bash scripts/docs-consistency.sh`** を通す。落ちていたら先にそれを直す。

devnet を触るなら `RPC=<private endpoint> ./scripts/healthcheck.sh`。**公開 devnet RPC は 429 を返す**ので、
founder の Alchemy エンドポイントを**環境変数としてのみ**使う。**repo のファイルに書かない。**

## このリポジトリが繰り返している誤り

**すべて実際に起きたもの。** 同じ形で再発する。

- **派生物を見て、実物を確かめない。** 字幕を見て「ナレーションが間違い」、`replace()` の戻り値を見て
  「5件直った」（実際は3件）、`solana balance` を見て「資金不足」（別プロジェクトの鍵を読んでいた）。
  **derived artifact ではなく、実物を読む。**
- **入っていない検査を「入れた」と報告する。** 2026-09-16、floor の context 口座が ZK プログラム所有で
  あることを要求したと報告し、コードに無かった。**主張の前に grep する。**
- **手で保守する数字。** テスト数、動画の尺、提出文の文字数、manifest。全部一度ずれた。
  **導出できる数字は導出し、`docs-consistency.sh` に検査させる。**
- **落ちるところを見ていない検査を書く。** 一度、自分が捕まえるはずのバグを自分が持っている
  consistency check を出荷した。**新しい検査は、わざと壊して落ちることを確認する。**
- **書き込み用に開いてから、中身を計算する。** 2026-09-23、`io.open(p,"w").write(f(...))` の
  `f` が例外を投げ、**`STATUS.md` 738行が0バイトになってコミットされた。** `open(...,"w")` は
  その瞬間に切り詰める。**読む → 組み立てる → 検算する → 最後に開いて書く。**
- **コピーを作る。** 2箇所に同じ規則を置くと必ずずれる（klend の規則、YouTube の説明文、
  動画の尺表）。**1箇所に置いて、他は生成する。**

## 検査

| | |
|---|---|
| `scripts/docs-consistency.sh` | ファイルについての主張。数え直す |
| `scripts/healthcheck.sh` | チェーンについての主張。**判定中に devnet はリセットされる** |
| `scripts/wire-check.sh` | クライアントとプログラムの口座数。テストは配線を通らない |
| `scripts/kamino-verdict.sh` | klend の pin した行がまだその内容か |
| `python3 video/pace.py` | 動画の尺表が台本の語数と合っているか |
| `scripts/spoken-check.sh <納品mp4>` | **声が今の台本を読んでいるか。** 音声は repo の外で作られて戻ってくるので、ここだけが2つを突き合わせる |

## Codex

`codex` は PATH に無い。実体は `/Applications/ChatGPT.app/Contents/Resources/codex`。

```
/Applications/ChatGPT.app/Contents/Resources/codex exec \
  -C /Users/hiroyusai/src/confide -s read-only -o <別パス.md> "$(cat payload.md)" < /dev/null
```

- **依頼文は `docs/reviews/payloads/` に保存し、結果と一緒にコミットする。** 要約で送らない。
  **不利な材料を外していないことの証跡。**
- `-o` は Codex 自身が書くパスに向けない。
- **Codex も間違える。** 2026-09-16、clone できない環境で行番号を URL から推定し、4つとも外した。
  **指摘は実ファイルで検証してから採る。**

## founder しか動かせないもの

接触（誰にも連絡しない）、フォームの記入、動画の音声生成と投稿、GitHub の認証切り替え。

## 自分が書いたものを自分でレビューしない

戦略・計画・実装のレビューは Codex に投げる。今日までに **4回**、自分では見つけられなかった
誤りを見つけている。

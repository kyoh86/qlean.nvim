# qlean.nvimプラグイン設計

## プラグインの目的

- `:q`/`:quit`実行時、keep対象のウィンドウが1つだけなら作業対象外のウィンドウを掃除する
- modifiedバッファがあっても掃除は行い、`:q`の成否はNeovim本体に任せる
- Neovim本体の
  - 失敗時のエラーメッセージ（E37等）を一切上書きしない

このプラグインは「終了を賢くする」のではなく、

> 最後のkeepウィンドウを閉じるときだけ、作業対象外のウィンドウを片付ける

ことに専念する。

## 基本設計

### keep判定（唯一の分類軸）

各バッファは、`keep(buf) -> boolean`によって判定される。

- `keep == true`

  - quit時点でkeep対象と見なす
  - 自動closeの対象にしない
- `keep == false`

  - keep対象外/UI付随と見なす
  - quit前にcloseしてよい

「編集対象かどうか」ではなく、

> quit時に残しておくべきかどうか

という観点に責務を集約する。

#### なぜkeepなのか

- terminal/acwrite/promptなど
  - 編集ではないが
  - 残っていたらkeep対象とみなしたいものが多い

## 安全性ポリシー

### modifiedバッファの扱い

- modifiedバッファがあってもUI掃除は行う
- `:q`の成否はNeovim本体の挙動に委ねる

## ruleモジュール設計

### 方針

- `keep`は単一のpredicate関数として設定する
- 複雑な条件はpredicateの合成で表現する
- DSLや多段ルールエンジンは作らない

### Predicateの仕様

```lua
Predicate = function(bufnr: integer, ctx: Context): boolean
```

- `true`を返したバッファはkeep
- `false`はnon-keep

### 合成子（combinators）

```lua
rule.all(p1, p2, ...)
rule.any(p1, p2, ...)
rule.not(p)
```

- 設定側では常に単一predicateを渡す
- 暗黙ANDは行わない

#### なぜ合成子方式か

- 設定の見通しが良い
- ユーザーがLuaに慣れていれば直感的
- 実装が小さく、安全

### 典型predicateビルダー

```lua
rule.buftype(x)
rule.filetype(x)
rule.bufname(pattern)
rule.buflisted(bool)
rule.bufhidden(x)
rule.modified(bool)
rule.modifiable(bool)
rule.bvar(key, value?)
```

#### 方針

- 8割のケースはこれで足りる
- 足りなければユーザーがpredicateを自作する

### ユーザー定義predicate

```lua
local my_keep = function(bufnr, ctx)
  return ctx.bo.buftype == "" and ctx.name:match("/work/") ~= nil
end
```

#### なぜ許可するか

- bufnrが渡れば、NeovimAPIでほぼ全情報が取得できる
- プラグイン側で全ユースケースを吸収しようとしない

## Context（ctx）設計

### 方針

- QuitPre1回につきctxをキャッシュする
- predicate内ではctxのみを見る

### ctxの内容

```lua
ctx = {
  bo = {
    buftype,
    filetype,
    buflisted,
    bufhidden,
    modifiable,
    readonly,
  },
  name = bufname,
  modified = boolean,
}
```

#### なぜキャッシュするか

- QuitPre中に同じbufを何度も判定するため
- predicate実装を簡潔にするため

## QuitPre処理フロー

1. QuitPre発火
2. ctxキャッシュ生成
3. close対象抽出

   - keepウィンドウが1つだけの場合のみ掃除する
   - 現在ウィンドウ以外
   - `keep == false`のバッファを表示しているウィンドウ
4. `:close`を個別実行（`!`は使わない）
5. quit本体へ制御を戻す

## close戦略

- `only`は使用しない
- 個別`close`のみ

#### 理由

- `only`は画面構成を不可逆に変えやすい
- quit失敗時のUXを壊しやすい

## 設定例

### 通常ファイル＋terminalをkeep

```lua
local rule = require("qlean.rule")

require("qlean").setup({
  keep = rule.any(
    rule.buftype(""),
    rule.buftype("terminal")
  ),
})
```

### gitcommitもkeep

```lua
keep = rule.any(
  rule.buftype(""),
  rule.filetype({ "gitcommit", "gitrebase" })
)
```

### neo-tree等は自動close

```lua
keep = rule.all(
  rule.buftype(""),
  rule.not(rule.bufname("^neo%-tree://"))
)
```

## エラーハンドリング

- keepのpredicate実行は必ず`pcall`
- エラー時は`true`扱い（安全側）
- `debug = true`のときのみ通知

## 非目的

- `:q!`/`:qa!`相当の強制終了は行わない
- modifiedバッファの保存・破棄を自動化しない
- win属性（float等）ベースの掃除は行わない

## 設計まとめ

- 判定軸はkeep（keep対象かどうか）のみ
- ruleはpredicate+combinatorの最小構成
- Vim/Neovim本体の失敗UXを最優先で尊重する

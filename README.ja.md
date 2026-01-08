# qlean.nvim

`qlean`は、`:q`/`:quit`実行時にユーザーの作業対象ではないバッファを表示するウィンドウだけを自動でclose
するNeovim用プラグインです。

> 作業中のものが残っているときは、何もしません。

## 何をしてくれるか

- `:q`したとき（keep対象のウィンドウが1つだけの場合）
  - ファイルツリー/help/quickfixなどの補助UIだけが残る問題を解消します
  - 対象外バッファを表示しているウィンドウをcloseします
- modifiedなユーザーの作業対象バッファがある場合は、一切何もしません
  - Neovim本体のエラー表示・挙動に任せます

`qlean`は「終了を強制する」プラグインではありません。

## インストール

### lazy.nvim

```lua
{
  "kyoh86/qlean.nvim",
}
```

（他のプラグインマネージャでも同様に配置してください）

## 基本的な使い方

特に操作は増えません。
`qlean`は`QuitPre`にフックして動作します。

## 設定

### 最小設定（おすすめ）

```lua
local rule = require("qlean.rule")

require("qlean").setup({
  keep = rule.buftype(""),
})
```

- 通常ファイル（`buftype == ''`）をユーザーの作業対象として扱います
- それ以外（help/quickfix/tree等）を表示しているウィンドウはquit前にcloseされます

## keepとは

`keep`は「quit時に残しておきたいバッファかどうか」を判定する関数です。

- `keep(buf) == true`

  - ユーザーの作業対象と見なされ、自動closeされません
- `keep(buf) == false`

  - ユーザーの作業対象外として、そのバッファを表示しているウィンドウがclose対象になります

## 代表的な設定例

### terminalもユーザーの作業対象として扱う

```lua
keep = rule.any(
  rule.buftype(""),
  rule.buftype("terminal")
)
```

### gitcommit/gitrebaseをユーザーの作業対象に含める

```lua
keep = rule.any(
  rule.buftype(""),
  rule.filetype({ "gitcommit", "gitrebase" })
)
```

### ファイルツリー（neo-treeなど）を確実にcloseする

```lua
keep = rule.all(
  rule.buftype(""),
  rule.not(rule.bufname("^neo%-tree://"))
)
```

### 自分で判定関数を書く

```lua
keep = function(bufnr, ctx)
  -- ctx には buftype / filetype / name などが含まれます
  return ctx.bo.buftype == "" and ctx.name:match("/work/") ~= nil
end
```

## ruleモジュール

`qlean.rule`は、`keep`用の判定関数を作るためのユーティリティです。

### 合成

```lua
rule.all(p1, p2, ...)
rule.any(p1, p2, ...)
rule.not(p)
```

### 判定ビルダー

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

`x`は`string`または`string[]`を指定できます。

## オプション

### modifiedバッファがある場合の挙動

```lua
skip_if_modified_keep = true  -- default
```

- `true`（デフォルト）
  - `keep`に該当するバッファが一つでもmodifiedの場合、qleanは何もしません
- `false`
  - 作業対象外のバッファに対してcloseは行われますが、`:q`が失敗することがあります

## 注意点

- `:q!`/`:qa!`には関与しません
- バッファの保存・破棄は自動化しません

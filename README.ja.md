# qlean.nvim

`qlean`は、「最後の作業ウィンドウを閉じるときに補助UIだけが残る」問題を解消する
Neovim用プラグインです。

> keep対象のウィンドウが1つだけのときに動作します。

## 何をしてくれるか

- `:q`時、keep対象のウィンドウが1つだけで現在ウィンドウもkeep対象なら
  - 非keep対象ウィンドウ（help/quickfix/tree等）をまとめてcloseします
- modifiedバッファがある場合でも掃除は行います
  - `:q`の成否はNeovim本体の挙動に任せます

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

特に操作は増えません。 `qlean`は`QuitPre`にフックして動作します。

## 設定

### 最小設定（おすすめ）

何も設定しない場合、`buftype == ''`をkeep対象として扱います。

```lua
local rule = require("qlean.rule")

require("qlean").setup({})
```

- 通常ファイル（`buftype == ''`）をkeep対象として扱います
- それ以外（help/quickfix/tree等）を表示しているウィンドウはquit前にcloseされます

## keepとは

`keep`は「quit時に残しておきたいバッファかどうか」を判定する関数です。

- `keep(ctx) == true`
  - keep対象と見なされ、自動closeされません
- `keep(ctx) == false`
  - keep対象外として、そのバッファを表示しているウィンドウがclose対象になります

## 代表的な設定例

### terminalもkeep対象として扱う

```lua
keep = rule.any(
  rule.buftype(""),
  rule.buftype("terminal")
)
```

### gitcommit/gitrebaseをkeep対象に含める

```lua
keep = rule.any(
  rule.buftype(""),
  rule.filetype({ "gitcommit", "gitrebase" })
)
```

### ファイルツリー（neo-treeなど）をcloseする

```lua
keep = rule.all(
  rule.buftype(""),
  rule.not(rule.bufname("^neo%-tree://"))
)
```

### 自分で判定関数を書く

```lua
keep = function(ctx)
  -- ctx には bufnr / buftype / filetype / bufname などが含まれます
  -- 詳細なctxの中身はlua/qlean/type.luaを参照してください
  return ctx.bo.buftype == "" and ctx.bufname:match("/work/") ~= nil
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

## 注意点

- `:q!`/`:qa!`には関与しません
- バッファの保存・破棄は自動化しません

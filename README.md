# hierarchy-tree-go
Hierarchy ui tree for go

## Description
[nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) displays incoming and outgoing in quickfix, which does not display hierarchical relationships and perform hierarchical expansion operations, so I wrote such a plugin.

## Feature

**Display the call chain of the symbol under the cursor, including incoming and outgoing**
<img src="https://github.com/crusj/hierarchy-tree-go.nvim/blob/main/screenshots/outgoing-1-min.png" width="850">

**Expand or collapse the upper or lower call chain**
<img src="https://github.com/crusj/hierarchy-tree-go.nvim/blob/main/screenshots/outgoing-2-min.png" width="850">

**Ability to switch window position, editor center, or bottom right corner via mapkey**
<img src="https://github.com/crusj/hierarchy-tree-go.nvim/blob/main/screenshots/incoming-1-min.png" width="850">

**Highlight in the current module or others module**

**The icon of the last layer of the call chain will change to ☉**

**Configurable**

## Install

### Requirement

**Neovim >= 0.7**

**[nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)**

**[gopls](https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#gopls)**

### Install

**Packer**

```lua
use {
	'crusj/hierarchy-tree-go.nvim',
	requires= 'neovim/nvim-lspconfig'
}
```

### Start

```lua
require("hierarchy-tree-go").setup()

```

## Default config

```lua
require("hierarchy-tree-go").setup({
	icon = {
		fold = "", -- fold icon
		unfold = "", -- unfold icon
		func = "₣", -- symbol
		last = '☉', -- last level icon
	},
	hl = {
		current_module = "guifg=Green", -- highlight cwd module line
		others_module = "guifg=Black", -- highlight others module line
		cursorline = "guibg=Gray guifg=White" -- hl  window cursorline
	},
	keymap = {
		--global keymap
		incoming = "<space>fi", -- call incoming under cursorword
		outgoing = "<space>fo", -- call outgoing under cursorword
		open = "<space>ho", -- open hierarchy win
		close = "<space>hc", -- close hierarchy win
		-- focus: if hierarchy win is valid but is not current win, set to current win
		-- focus: if hierarchy win is valid and is current win, close
		-- focus  if hierarchy win not existing,open and focus
		focus = "<space>fu",

		-- bufkeymap
		expand = "o", -- expand or collapse hierarchy
		jump = "<CR>", -- jump
		move = "<space><space>" -- switch the hierarchy window position, must be current win
	}
})

```
## Keymap

| Keymap                   | Action                                                                 | Description                                                   | 
| -------------------------|------------------------------------------------------------------------|---------------------------------------------------------------| 
| ```<space>fi```          |  ```:lua require'hierarchy-tree-go'.incoming()```                      | Call incoming under cursorword                                |
| ```<space>fo```          |  ```:lua require'hierarchy-tree-go'.outgoing()```                      | Call outgoing under cursorword                                |
| ```<space>ho```          |  ```:lua require'hierarchy-tree-go'.open()```                          | Open hierarchy window                                         |
| ```<space>hc```          |  ```:lua require'hierarchy-tree-go'.close()```                         | Close hierarchy window                                        |
| ```<space>fu```          |  ```:lua require'hierarchy-tree-go'.focus()```                         | Focus hierarchy window                                        |
| ```o```                  |  ```:lua require'hierarchy-tree-go'.expand()```                        | Expand or collapse hierarchy                                  | 
| ```<CR>```               |  ```:lua require'hierarchy-tree-go'.jump()```                          | Jump                                                          |
| ```<space><space>```     |  ```:lua require'hierarchy-tree-go'.move()```                          | switch the hierarchy window position, should be current win   |


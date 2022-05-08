local json = require("xxx.json")
local t = require('xxx.tree')
local c

local W = {
	bufw = nil,
	buff = nil,

	bufwh = 0,
	bufww = 0,

	bufnrw = nil,

	hl_cursorline_name = "hl_hierarchy_csl",
	hl_current_module = "hl_hierarchy_c_m",
	hl_others_module = "hl_hierarchy_o_m",

	position = "bottom_right"
}

function W.setup()
	c = require("xxx.config").get_data()
	vim.cmd("highlight " .. W.hl_cursorline_name .. " " .. c.hl.cursorline)
	vim.cmd("highlight " .. W.hl_current_module .. " " .. c.hl.current_module)
	vim.cmd("highlight " .. W.hl_others_module .. " " .. c.hl.others_module)
end

function W.create_window()
	if W.bufnrw == nil then
		W.bufnrw = vim.api.nvim_get_current_win()
	end

	if W.buff == nil then
		if W.buff == nil then
			W.buff = vim.api.nvim_create_buf(false, true)
			vim.api.nvim_buf_set_keymap(W.buff, "n", c.keymap.expand, ":lua require'hierarchy-tree-go'.expand()<cr>", { silent = true })
			vim.api.nvim_buf_set_keymap(W.buff, "n", c.keymap.jump, ":lua require'hierarchy-tree-go'.jump()<cr>", { silent = true })
			vim.api.nvim_buf_set_keymap(W.buff, "n", c.keymap.move, ":lua require'hierarchy-tree-go'.move()<cr>", { silent = true })

			vim.api.nvim_buf_set_option(W.buff, "filetype", "hierarchy-tree-go")
			vim.api.nvim_buf_set_name(W.buff, "HIERARCHY-TREE-GO")
		end
	end

	W.close()

	local ew = vim.api.nvim_get_option("columns")
	local eh = vim.api.nvim_get_option("lines")
	local row, col

	if W.position == "bottom_right" then
		W.bufww = math.floor(ew / 2.5)
		W.bufwh = math.floor(eh / 2)
		row = eh - W.bufwh
		col = ew - W.bufww
	else
		W.bufww = math.floor(ew * 0.7)
		W.bufwh = math.floor(eh * 0.8)
		row = math.floor((eh - W.bufwh) / 2)
		col = math.floor((ew - W.bufww) / 2)
	end

	W.bufw = vim.api.nvim_open_win(W.buff, true, {
		relative = "editor",
		width = W.bufww,
		height = W.bufwh,
		row = row,
		col = col,
		border = "double",
	})

	vim.api.nvim_win_set_option(W.bufw, "scl", "no")
	vim.api.nvim_win_set_option(W.bufw, "cursorline", true)
	vim.api.nvim_win_set_option(W.bufw, "wrap", false)
	vim.api.nvim_win_set_buf(W.bufw, W.buff)
	vim.api.nvim_win_set_option(W.bufw, "winhighlight", "CursorLine:" .. W.hl_cursorline_name)

	W.write_line()
end

function W.write_line()
	vim.api.nvim_buf_set_option(W.buff, "modifiable", true)

	local nodes = t.get_lines()
	local fmt_lines = {}
	local cwd = vim.fn.getcwd()
	local hl = {}

	for _, node in ipairs(nodes) do
		local fold_icon = c.icon.fold

		if node.status == "open" then
			fold_icon = c.icon.unfold
			if #node.children == 0 then
				fold_icon = c.icon.last
			end
		end

		local kind_icon = c.icon.func
		if node.kind ~= 12 then
			kind_icon = node.kind
		end

		local filename = string.sub(node.uri, 8)
		if string.sub(filename, 1, #cwd) ~= cwd then -- others modules
			table.insert(hl, W.hl_others_module)
			filename = node.detail
		else
			table.insert(hl, W.hl_current_module)
			filename = string.sub(filename, #cwd + 2)
		end

		local symbol = string.format("%s%s [%s]%s", string.rep("  ", node.level), fold_icon, kind_icon, node.name)
		local line = symbol .. string.rep(" ", math.floor(W.bufww / 2.5) - #symbol) .. filename

		table.insert(fmt_lines, line)
	end

	vim.api.nvim_buf_set_lines(W.buff, 0, -1, false, {})
	vim.api.nvim_buf_set_lines(W.buff, 0, #fmt_lines, false, fmt_lines)

	for index, item in ipairs(hl) do
		vim.api.nvim_buf_add_highlight(W.buff, -1, item, index - 1, 1, -1)
	end

	vim.api.nvim_set_current_win(W.bufw)
	vim.api.nvim_buf_set_option(W.buff, "modifiable", false)
end

function W.jump(node)
	local filename = string.sub(node.uri, 8)
	vim.api.nvim_set_current_win(W.bufnrw)
	vim.cmd("e " .. filename)
	vim.cmd("execute  \"normal! " .. (node.range.start.line + 1) .. "G\"")
	vim.cmd("execute  \"normal! zz\"")
end

function W.focus()
	if W.bufw == nil then -- open
		W.create_window()
		return
	end

	if W.bufw ~= nil and vim.api.nvim_win_is_valid(W.bufw) then
		if vim.api.nvim_get_current_win() ~= W.bufw then -- focus
			vim.api.nvim_set_current_win(W.bufw)
		else
			W.close()
		end
	end
end

function W.close()
	if W.bufw ~= nil and vim.api.nvim_win_is_valid(W.bufw) then
		vim.api.nvim_win_close(W.bufw, true)
	end

	W.bufw = nil
end

function W.open()
	if W.buff ~= nil then
		if W.bufw ~= nil and vim.api.nvim_win_is_valid(W.bufw) then
			return
		end
		W.create_window()
	end
end

function W.move()
	if W.position == "bottom_right" then
		W.position = "center"
	else
		W.position = "bottom_right"
	end
	W.create_window()
end

return W

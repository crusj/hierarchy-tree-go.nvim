local t = require('xxx.tree')
local c = require("xxx.config").get_data()

local W = {
	bufw = nil,
	buff = nil,

	bufwh = 0,
	bufww = 0,

	bufnrw = nil,

	hl_cursorline_name = "hl_hierarchy_csl"
}

function W.setup()
	vim.cmd("highlight " .. W.hl_cursorline_name .. " " .. c.hl_cursorline)
end

function W.create_window()
	if W.bufnrw == nil then
		W.bufnrw = vim.api.nvim_get_current_win()
	end

	if W.buff == nil then
		if W.buff == nil then
			W.buff = vim.api.nvim_create_buf(false, true)
			vim.api.nvim_buf_set_keymap(W.buff, "n", "o", ":lua require'hierarchy-tree-go'.expand()<cr>", { silent = true })
			vim.api.nvim_buf_set_keymap(W.buff, "n", "<CR>", ":lua require'hierarchy-tree-go'.jump()<cr>", { silent = true })
		end
	end

	local ew = vim.api.nvim_get_option("columns")
	local eh = vim.api.nvim_get_option("lines")

	W.bufww = math.floor(ew / 2.5)
	W.bufwh = math.floor(eh / 2)

	if W.bufw == nil or (not vim.api.nvim_win_is_valid(W.bufw)) then
		W.bufw = nil

		W.bufw = vim.api.nvim_open_win(W.buff, true, {
			relative = "editor",
			width = W.bufww,
			height = W.bufwh,
			row = eh - W.bufwh,
			col = ew - W.bufww,
			border = "double",
		})

		vim.api.nvim_win_set_option(W.bufw, "scl", "no")
		vim.api.nvim_win_set_option(W.bufw, "cursorline", true)
		vim.api.nvim_win_set_option(W.bufw, "wrap", false)
		vim.api.nvim_win_set_buf(W.bufw, W.buff)
		vim.api.nvim_win_set_option(W.bufw, "winhighlight", "CursorLine:" .. W.hl_cursorline_name)
	end

	W.write_line()
end

function W.write_line()
	vim.api.nvim_buf_set_option(W.buff, "modifiable", true)
	vim.api.nvim_buf_set_lines(W.buff, 0, -1, false, {})

	local nodes = t.get_lines()
	local fmt_lines = {}
	local cwd = vim.fn.getcwd()

	for _, node in ipairs(nodes) do
		local icon = c.icon.fold

		if node.status == "open" then
			icon = c.icon.unfold
		end

		local filename = string.sub(string.sub(node.uri, 8), #cwd + 2)
		local symbol = string.format("%s%s %s", string.rep("  ", node.level), icon, node.name)
		local line = symbol .. string.rep(" ", math.floor(W.bufww / 3) - #symbol) .. filename

		table.insert(fmt_lines, line)
	end

	vim.api.nvim_buf_set_lines(W.buff, 0, #fmt_lines, false, fmt_lines)
	vim.api.nvim_buf_set_option(W.buff, "modifiable", false)
end

function W.jump(node)
	local filename = string.sub(node.uri, 8)
	vim.api.nvim_set_current_win(W.bufnrw)
	vim.cmd("e " .. filename)
	vim.cmd("execute  \"normal! " .. (node.range.start.line + 1) .. "G;zz\"")
end

function W.foucus()
	if W.bufw ~= nil and vim.api.nvim_win_is_valid(W.bufw) then
		vim.api.nvim_set_current_win(W.bufw)
	end
end

return W

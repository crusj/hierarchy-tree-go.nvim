local H = {
	client = nil
}

local json = require("xxx.json")
local notify = require("notify")
local t = require("xxx.tree")
local w = require("xxx.window")

function H.setup()
	w.setup()
	H.global_keymap()
end

function H.global_keymap()
	vim.keymap.set("n", "<space>fi", "<cmd>lua require\"hierarchy-tree-go\".incoming()<cr>", { silent = true })
	vim.keymap.set("n", "<space>fo", "<cmd>lua require\"hierarchy-tree-go\".focus()<cr>", { silent = true })
end

function H.incoming()
	local params = vim.lsp.util.make_position_params()

	H.get_children(params, function(result)
		local root = t.create_node(vim.fn.expand("<cword>"), 12, params.textDocument.uri, {
			start = {
				line = params.position.line,
				character = params.position.character
			}
		})
		root.status = "open"

		root.children = {}
		for _, item in ipairs(result) do
			local child = t.create_node(item.from.name, item.from.kind, item.from.uri, item.from.range, item.fromRanges)
			table.insert(root.children, child)
		end

		t.set_root(root)
		w.create_window()
	end)
end

function H.get_children(params, callback)
	vim.lsp.buf_request(nil, "textDocument/prepareCallHierarchy", params, function(err, result)
		if err then
			notify.notify("prepare error" .. json.encode(err), "error", {
				title = "Hierarchy prepare"
			})
			return
		end

		local call_hierarchy_item = H.pick_call_hierarchy_item(result)

		H.call_hierarchy({}, "callHierarchy/incomingCalls", "LSP Incoming Calls", "from", call_hierarchy_item, callback)
	end)
end

function H.prepare_obj(uri, postion)
	return {
		textDocument = {
			uri = uri
		},
		position = postion,
	}
end

function H.pick_call_hierarchy_item(call_hierarchy_items)
	if not call_hierarchy_items then
		return
	end
	if #call_hierarchy_items == 1 then
		return call_hierarchy_items[1]
	end
	local items = {}
	for i, item in pairs(call_hierarchy_items) do
		local entry = item.detail or item.name
		table.insert(items, string.format("%d. %s", i, entry))
	end
	local choice = vim.fn.inputlist(items)
	if choice < 1 or choice > #items then
		return
	end

	return choice
end

function H.call_hierarchy(opts, method, title, direction, item, callback)
	vim.lsp.buf_request(opts.bufnr, method, { item = item }, function(err, result)
		if err then
			notify.notify(json.encode(err), "error", {
				title = "Hierarchy incoming"
			})
			return
		end

		callback(result)
	end)
end

function H.attach_gopls()
	if H.client == nil then
		for _, v in pairs(vim.lsp.get_active_clients()) do
			if v.name == "gopls" then
				H.client = v.id
				break
			end
		end

		if H.client == nil then
			notify.notify("no gopls client", "error", {})
			return false
		end

	end

	if not vim.lsp.buf_is_attached(w.buff, H.client) then
		vim.lsp.buf_attach_client(w.buff, H.client)
	end

	return true
end

function H.expand()
	local line = vim.api.nvim_exec("echo line('.')", true)
	local node = t.nodes[tonumber(line)]

	if node.status == "open" then
		if #node.children > 0 then
			node.status = "fold"
			w.create_window()
			vim.cmd("execute  \"normal! " .. line .. "G\"")
		end

		return
	end

	if node.status == "fold" then
		node.status = "open"
		w.create_window()
		vim.cmd("execute  \"normal! " .. line .. "G\"")
		return
	end

	if H.attach_gopls() == false then
		return
	end

	local params = H.prepare_obj(node.uri, {
		line = node.range.start.line,
		character = node.range.start.character
	})

	H.get_children(params, function(result)
		node.status = "open"
		if #result > 0 then -- no incoming
			for _, item in ipairs(result) do
				local child = t.create_node(item.from.name, item.from.kind, item.from.uri, item.from.range, item.fromRanges)
				table.insert(node.children, child)
			end
		end
		w.create_window()
		vim.cmd("execute  \"normal! " .. line .. "G\"")

	end)
end

function H.jump()
	local line = vim.api.nvim_exec("echo line('.')", true)
	local node = t.nodes[tonumber(line)]
	w.jump(node)
end

function H.focus()
	w.foucus()
end

return H

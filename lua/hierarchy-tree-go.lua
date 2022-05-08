local H = {
	client = nil
}

local json = require("xxx.json")

local has_notify, notify = pcall(require, "notify")

if not has_notify then
	notify = vim.notify
else
	notify = notify.notify
end

local t = require("xxx.tree")
local w = require("xxx.window")
local config = require("xxx.config")

local c

function H.setup(user_config)
	config.setup(user_config)
	c = config.get_data()

	w.setup()
	H.global_keymap()
end

function H.global_keymap()
	vim.keymap.set("n", c.keymap.incoming, "<cmd>lua require\"hierarchy-tree-go\".incoming()<cr>", { silent = true })
	vim.keymap.set("n", c.keymap.focus, "<cmd>lua require\"hierarchy-tree-go\".focus()<cr>", { silent = true })
	vim.keymap.set("n", c.keymap.outgoing, "<cmd>lua require\"hierarchy-tree-go\".outgoing()<cr>", { silent = true })
	vim.keymap.set("n", c.keymap.open, "<cmd>lua require\"hierarchy-tree-go\".open()<cr>", { silent = true })
	vim.keymap.set("n", c.keymap.close, "<cmd>lua require\"hierarchy-tree-go\".close()<cr>", { silent = true })
end

function H.incoming()
	if not H.check_filetype() then
		notify("Filetype error", vim.log.levels.ERROR, {
			title = "Call incoming"
		})
		return
	end

	local params = vim.lsp.util.make_position_params()

	H.get_children(params, "incoming", function(result)
		local root = t.create_node(vim.fn.expand("<cword>"), 12, params.textDocument.uri, params.textDocument.uri, {
			start = {
				line = params.position.line,
				character = params.position.character
			}
		})
		root.status = "open"

		root.children = {}
		for _, item in ipairs(result) do
			local child = t.create_node(item.from.name, item.from.kind, item.from.uri, item.from.detail, item.from.range, item.fromRanges)
			table.insert(root.children, child)
		end

		t.set_root(root, "incoming")
		w.create_window()
	end)
end

function H.check_filetype()
	return vim.api.nvim_buf_get_option(0, "filetype") == "go"
end

function H.outgoing()
	if not H.check_filetype() then
		notify("Filetype error", vim.log.levels.ERROR, {
			title = "Call outgoing"
		})
		return
	end

	local params = vim.lsp.util.make_position_params()
	H.get_children(params, "outgoing", function(result)
		local root = t.create_node(vim.fn.expand("<cword>"), 12, params.textDocument.uri, params.textDocument.uri, {
			start = {
				line = params.position.line,
				character = params.position.character
			}
		})
		root.status = "open"

		root.children = {}
		for _, item in ipairs(result) do
			local child = t.create_node(item.to.name, item.to.kind, item.to.uri, item.to.detail, item.to.range, item.fromRanges)
			table.insert(root.children, child)
		end

		t.set_root(root, "outgoing")
		w.create_window()
	end)
end

function H.get_children(params, direction, callback)
	vim.lsp.buf_request(nil, "textDocument/prepareCallHierarchy", params, function(err, result)
		if err then
			notify.notify("Prepare error" .. json.encode(err), vim.log.levels.ERROR, {
				title = "Hierarchy prepare"
			})
			return
		end

		local call_hierarchy_item = H.pick_call_hierarchy_item(result)

		local method = "callHierarchy/incomingCalls"
		local title = "LSP Incoming Calls"

		if direction == "outgoing" then
			method = "callHierarchy/outgoingCalls"
			title = "LSP Outgoing Calls"
		end

		H.call_hierarchy({}, method, title, call_hierarchy_item, callback)
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

function H.call_hierarchy(opts, method, title, item, callback)
	vim.lsp.buf_request(opts.bufnr, method, { item = item }, function(err, result)
		if err then
			notify(json.encode(err), vim.log.levels.ERROR, {
				title = title
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
			notify("no gopls client", vim.log.levels.ERROR, {})
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

	H.get_children(params, t.direction, function(result)
		node.status = "open"
		if result ~= nil and #result > 0 then -- no incoming
			for _, item in ipairs(result) do
				local child
				if t.direction == "outgoing" then
					child = t.create_node(item.to.name, item.to.kind, item.to.uri, item.to.detail, item.to.range, item.fromRanges)
				else
					child = t.create_node(item.from.name, item.from.kind, item.from.uri, item.from.detail, item.from.range, item.fromRanges)
				end

				table.insert(node.children, child)
			end
		end
		w.create_window()
		vim.cmd("execute  \"normal! " .. line .. "G\"")

	end)
end

function H.close()
	w.close()
end

function H.open()
	w.open()
end

function H.jump()
	local line = vim.api.nvim_exec("echo line('.')", true)
	local node = t.nodes[tonumber(line)]
	w.jump(node)
end

function H.focus()
	w.focus()
end

function H.move()
	w.move()
end

return H

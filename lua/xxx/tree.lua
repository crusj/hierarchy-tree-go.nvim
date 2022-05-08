local notify = require("xxx.notify")

local T = {
	root = nil,
	lines = {},
	nodes = {},

	direction = nil
}

function T.set_root(root, direction)
	T.root = root
	T.direction = direction
end

function T.create_node(name, kind, uri, detail, range, from_ranges)
	return {
		name = name,
		kind = kind,
		uri = uri,
		detail = detail,
		status = "close",
		range = range,
		from_ranges = from_ranges,
		children = {}
	}
end

function T.get_lines()
	T.lines = {}
	T.nodes = {}

	if T.root == nil then
		notify('Empty data: Call outgoing or incoming first.', vim.log.levels.ERROR, {
			title = "Call focus error"
		})
		return
	end

	T.front(T.root, 0)
	return T.lines
end

function T.front(node, level)
	node.level = level
	table.insert(T.lines, node)
	table.insert(T.nodes, node)

	if node.status == "fold" then
		return
	end

	if #node.children > 0 then
		table.sort(node.children, function(a, b) return a.name < b.name end)
	end

	for _, child in ipairs(node.children) do
		T.front(child, level + 1)
	end
end

return T

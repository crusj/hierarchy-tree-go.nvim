local T = {
	root = nil,
	lines = {},
	nodes = {}
}

function T.set_root(root)
	T.root = root
end

function T.create_node(name, kind, uri, range, from_ranges)
	return {
		name = name,
		kind = kind,
		uri = uri,
		status = "close",
		range = range,
		from_ranges = from_ranges,
		children = {}
	}
end

function T.get_lines()
	T.lines = {}
	T.nodes = {}

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

	for _, child in ipairs(node.children) do
		T.front(child, level + 1)
	end
end

return T

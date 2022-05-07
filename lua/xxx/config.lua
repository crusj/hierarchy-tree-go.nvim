local C = {
	data = {
		icon = {
			fold = "",
			unfold = "",
		},
		hl_cursorline = "guibg=Gray guifg=White" -- hl bookmarsk window cursorline
	}
}

function C.get_data()
	return C.data
end

return C

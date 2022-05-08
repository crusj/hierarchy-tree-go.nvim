local C = {}

function C.setup(user_config)
	C.data = {
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
	}

	if user_config == nil or type(user_config) ~= "table" then
		return
	end

	for dk, dv in pairs(C.data) do
		if user_config[dk] ~= nil then
			for fk, fv in pairs(dv) do
				if user_config[dk][fk] ~= nil then
					C.data[dk][fk] = user_config[dk][fk]
				end
			end
		end
	end

end

function C.get_data()
	return C.data
end

return C

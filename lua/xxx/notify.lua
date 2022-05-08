local has_notify, notify = pcall(require, "notify")

if not has_notify then
	notify = vim.notify
else
	notify = notify.notify
end

return notify

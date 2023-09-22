-- skidded from vxpe

local void = function() return 0 end
local setidentity = syn and syn.set_thread_identity or set_thread_identity or setidentity or setthreadidentity or void
local getidentity = syn and syn.get_thread_identity or get_thread_identity or getidentity or getthreadidentity or void

local function displayPopup(title, text, callback, buttonName)
	local oldidentity = getidentity()
	setidentity(8)
	local ErrorPrompt = getrenv().require(game:GetService("CoreGui").RobloxGui.Modules.ErrorPrompt)
	local prompt = ErrorPrompt.new("Default")
	prompt._hideErrorCode = true
	local gui = Instance.new("ScreenGui", game:GetService("CoreGui"))
	prompt:setErrorTitle(title or "Meteor")

	prompt:updateButtons({
		Text = buttonName or "OK",
		Callback = function()
            callback and callback()
			prompt:_close() 
		end,
		Primary = true
	}, 'Default')

	prompt:setParent(gui)
	prompt:_open(text)
	setidentity(oldidentity)
end
-- skidded from vxpe

local api = {}

local RunService = game:GetService("RunService")

local void = function() return 0 end
local setidentity = syn and syn.set_thread_identity or set_thread_identity or setidentity or setthreadidentity or void
local getidentity = syn and syn.get_thread_identity or get_thread_identity or getidentity or getthreadidentity or void

function api:UnbindFromRenderStep(name)
    if name then
        return RunService:UnbindFromRenderStep(tostring(name))
    end

    warn("UnbindFromRenderStep name is nil (meteorapi)")
end


function api:BindToRenderStep(name, priority, func, unbind)
    if unbind == nil then unbind = true end

    if not func then
        return warn("BindToRenderStep func is nil (meteorapi)")
    end

    if unbind and name then
        self:UnbindFromRenderStep(name)
    end

    if not name or priority then
        return RunService.RenderStepped:Connect(func)
    end

    return RunService:BindToRenderStep(tostring(name), tonumber(priority), func)
end


function api:DisplayPopup(title, text, callback, buttonName)
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

return api

local MeteorAPI = {}

local getgenv = getgenv or shared or _G
local getrenv = getrenv or {["_G"] = _G or shared}

assert(getgenv, "Cant find getgenv")

local log = {}

log.info = function(...) print("[METEOR] [INFO] -", ...) end
log.warn = function(...) warn("[METEOR] [WARN] -", ...) end
log.error = function(...) warn("[METEOR] [ERROR] -", ...) end

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local void = function() return 0 end
local setidentity = set_thread_identity or setidentity or setthreadidentity or (syn and syn.set_thread_identity) or void
local getidentity = get_thread_identity or getidentity or getthreadidentity or (syn and syn.get_thread_identity) or void


function MeteorAPI:check(x)
    if not x then
        return false
    end

    if typeof(x) == "Instance" then
        if not x.Parent then
            return false
        end
    elseif typeof(x) == "table" then
        if #x == 0 then
            return false
        end
    end

    if x == Vector3.zero then
        return false
    end

    return true
end


function MeteorAPI:GenerateRandomString(len)
    local abc = ("QWERTYUIOPASDFGHJKLZXCVBNMqwertyuiopasdfghjklzxcvbnm"):split("")
    local result = ""

    for i = 1, len do
        result = result .. abc[math.random(1, #abc)]
    end

    return result
end


function MeteorAPI:UnbindFromRenderStep(name)
    return RunService:UnbindFromRenderStep(name)
end


function MeteorAPI:BindToRenderStep(name, priority, func, unbind)
    if not (name and priority) then
        return RunService.RenderStepped:Connect(func)
    end

    if (unbind == nil) then unbind = true end
    if (unbind) then self:UnbindFromRenderStep(name) end

    return RunService:BindToRenderStep(name, priority, func)
end


function MeteorAPI:FireConnections(signal, ...)
    local success, result = pcall(function(args)
        if (firesignal) then
            firesignal(signal, args)
        elseif (getconnections) then
            for _, v in pairs(getconnections(signal)) do
                if v.Fire then
                    v:Fire(args)
                elseif v.Function then
                    v.Function(args)
                else
                    warn("Unable to fire connections")
                    return false
                end
            end
        else
            return false
        end

        if (replicatesignal) then
            replicatesignal(signal, args)
        end

        return true
    end, ...)

    if (not success) then
        log.error("MeteorAPI: Error while trying to fire connections! " .. result)
        return false
    end

    return result
end


function MeteorAPI:DisplayPopup(title, text, callback, buttonName)
    local success, result = pcall(function()
        if (not text) then
            log.warn("MeteorAPI: No text for displayPopup")
            return
        end

        local oldidentity = getidentity()
        setidentity(8)
        local ErrorPrompt = getrenv().require(game:GetService("CoreGui").RobloxGui.Modules.ErrorPrompt)
        local prompt = ErrorPrompt.new("Default")
        prompt._hideErrorCode = true
        local gui = Instance.new("ScreenGui", game:GetService("CoreGui"))
        prompt:setErrorTitle(title or "Meteor")

        prompt:updateButtons({{
            Text = buttonName or "OK",
            Callback = function()
                prompt:_close()
                if (callback) then callback() end
            end,
            Primary = true
        }}, 'Default')

        prompt:setParent(gui)
        prompt:_open(text)
        setidentity(oldidentity)
    end)

    if (not success) then
        log.info("Meteor API: ", title, text)
        if (callback) then callback() end
        return false
    end

    return success
end


function MeteorAPI:getcharacter()
    while (not player.Character) do
        task.wait()
    end

    return player.Character
end


function MeteorAPI:gethuman()
    local humanoid = self:getcharacter():FindFirstChild("Humanoid")

    if (humanoid and humanoid.Health ~= 0) then
        return humanoid
    end

    return self:getcharacter():WaitForChild("Humanoid", 30) or self:gethuman()
end


function MeteorAPI:getroot()
    local character = self:getcharacter()
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local torso = character:FindFirstChild("Torso")

    if (not (rootPart or torso)) then
        task.wait()
        self:GetHumanoid()
    else
        return rootPart or torso
    end

    return self:getroot()
end


function MeteorAPI:WaitForRespawn()
    return self:getroot()
end


function MeteorAPI:getTorso()
    local character = self:getcharacter()
    local primaryPart = self:getroot()

    return character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso") or character:FindFirstChild("LowerTorso") or primaryPart or self:getroot()
end


function MeteorAPI:getpos(x)
    if (not x) then
        return Vector3.zero
    end

    if (typeof(x) == "Vector3") then
        return x
    elseif (typeof(x) == "Instance" and x:IsA("Model")) then
        return x.PrimaryPart.Position
    else
        return x.Position or x
    end
end


function MeteorAPI:IsPartInArea(area, part)
    local partPosition = self:getpos(part)
    local areaPosition = self:getpos(area)
    local areaSize = area.Size

    if (not (partPosition and areaPosition and areaSize)) then
        log.warn("MeteorAPI: Unable to check IsPartInArea")
        return false
    end

    local minX = areaPosition.X - areaSize.X / 2
    local maxX = areaPosition.X + areaSize.X / 2
    local minZ = areaPosition.Z - areaSize.Z / 2
    local maxZ = areaPosition.Z + areaSize.Z / 2

    return partPosition.X >= minX and partPosition.X <= maxX and partPosition.Z >= minZ and partPosition.Z <= maxZ
end


function MeteorAPI:IsPlayerInArea(area)
    return self:IsPartInArea(area, self:getroot())
end


function MeteorAPI:IsTouching(part, anotherPart)
    if (part and anotherPart) then
        for _, touchingPart in ipairs(part:GetTouchingParts()) do
            if (touchingPart == anotherPart) then
                return true
            end
        end
    end

    return false
end


function MeteorAPI:IsPlayerTouchingPart(part, onlyRoot)
    if (onlyRoot) == nil then onlyRoot = false end

    local character = self:getcharacter()
    local root = self:getroot()

    if (root and part) then
        for _, touchingPart in pairs(part:GetTouchingParts()) do
            if (touchingPart == root) then
                return true
            end

            if onlyRoot == false and touchingPart:IsDecendantOf(character) then
                return true
            end
        end
    end

    return false
end


function MeteorAPI:GetDeltaToGoal(goal, rootpos)
    if not goal then
        return Vector3.zero
    end

    if not (rootpos) then rootpos = self:getpos(self:getroot()) end
    local result = rootpos - self:getpos(goal)
    return Vector3.new(result.X, 0, result.Z).Magnitude
end


function MeteorAPI:GetDistanceToGoal(goal, rootpos)
    return self:GetDeltaToGoal(goal, rootpos)
end


function MeteorAPI:GetPartRegion(part)
    local partpos = self:getpos(part)

    return Region3.new(partpos - part.Size / 2, partpos + part.Size / 2)
end


function MeteorAPI:IsObstructed(position, ignore)
    local region = Region3.new(position - Vector3.new(0.5, 0, 0.5), position + Vector3.new(0.5, 0, 0.5))
    local ignoreList = ignore
    local parts = Workspace:FindPartsInRegion3WithIgnoreList(region, ignoreList, 2000)

    for i, v in pairs(parts) do
        if (v.CanCollide) then
            return true
        end
    end

    return false
end


function MeteorAPI:IsPartObstructed(part, ignore)
    if not part then
        return false
    end

    local ignoreList = {part, self:getcharacter()}

    for _, v in ipairs(ignore) do
        if typeof(v) == "Instance" then
            table.insert(ignoreList, v)
        end
    end

    return self:IsObstructed(self:getpos(part), ignoreList)
end


function MeteorAPI:GetRandomPoint(part)
    local min = part.Position - part.Size / 2
    local max = part.Position + part.Size / 2

    local result = Vector3.new(math.random(min.X + 2, max.X), part.Position.Y, math.random(min.Z + 2, max.Z))

    if (self:IsObstructed(result)) then
        task.wait()
        return self:GetRandomPoint(part)
    end

    return result
end


function MeteorAPI:GetDirectionRelativeToCamera(direction)
    return CFrame.new(camera.CFrame.p, camera.CFrame.p + camera.CFrame.lookVector * Vector3.new(1, 0, 1)):VectorToObjectSpace(direction)
end


function MeteorAPI:Jump()
    local humanoid = self:gethuman()

    if (humanoid:GetStateEnabled(Enum.HumanoidStateType.Jumping) and humanoid:GetState() ~= Enum.HumanoidStateType.Jumping) then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end


return MeteorAPI

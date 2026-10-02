local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Stats = game:GetService("Stats")
local camera = workspace.CurrentCamera

local cfg = {
    tpEnabled = false,
    aimbotEnabled = false,
    silentAimEnabled = true,
    aimMode = "Head",
    tpOnRespawn = true,
    grabGuns = true,
    espEnabled = true,
    aimMaxDistance = 500,
    freecamSpeed = 1,
    aimAssistFov = 100,  -- Радиус захвата аимбота в пикселях вокруг прицела
    silentAimFov = 180   -- Радиус телепортации пуль вокруг прицела
}

local binds = {
    ClickTP = Enum.KeyCode.Q,
    ActivateTP = Enum.KeyCode.Q,
    SaveWP = Enum.KeyCode.Y,
    DeleteWP = Enum.KeyCode.T,
    Rejoin = Enum.KeyCode.R,
    Reload = Enum.KeyCode.F8,
    UnlockMouse = Enum.KeyCode.LeftControl,
    FreecamToggle = Enum.KeyCode.X,
    SilentToggle = Enum.KeyCode.N
}

local waypoints = {}
local wpCount = 0
local whitelist = {}
local blacklist = {}
local lastDeathPos = nil
local freecamActive = false
local mouseUnlocked = false
local originalCameraType = camera.CameraType
local freecamRotX = 0
local freecamRotY = 0
local aimbotActiveState = false

local function saveConfig()
    local data = {cfg = cfg, waypoints = waypoints, whitelist = whitelist, blacklist = blacklist, binds = {}}
    for k, v in pairs(binds) do data.binds[k] = v.Name end
    pcall(function() writefile("PL_Premium_Hub_v7.json", HttpService:JSONEncode(data)) end)
end

local function loadConfig()
    pcall(function()
        if isfile and isfile("PL_Premium_Hub_v7.json") then
            local data = HttpService:JSONDecode(readfile("PL_Premium_Hub_v7.json"))
            if data.cfg then cfg = data.cfg end
            if data.waypoints then waypoints = data.waypoints end
            if data.whitelist then whitelist = data.whitelist end
            if data.blacklist then blacklist = data.blacklist end
            if data.binds then
                for k, v in pairs(data.binds) do binds[k] = Enum.KeyCode[v] end
            end
        end
    end)
end
loadConfig()
local function getDynamicDelay()
    local ping = 0.1
    pcall(function()
        ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000
    end)
    return ping + 0.1
end

local function grabWeaponStationary(gunName)
    local workspaceGuns = workspace:FindFirstChild("Prison_Guns") or workspace:FindFirstChild("Guns")
    if workspaceGuns then
        local giver = workspaceGuns:FindFirstChild(gunName)
        if giver and giver:FindFirstChild("ItemGiver") then
            local itemGiver = giver.ItemGiver
            if itemGiver:IsA("RemoteEvent") then
                local dynamicDelay = getDynamicDelay()
                local t = tick()
                while tick() - t < dynamicDelay do
                    itemGiver:FireServer()
                    task.wait(0.02)
                end
            end
        end
    end
end

function safeTeleport(targetPos)
    local character = player.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local maxStep = 20
    local currentPos = hrp.Position
    local direction = (targetPos - currentPos).Unit
    local distance = (targetPos - currentPos).Magnitude
    local steps = math.floor(distance / maxStep)
    for i = 1, steps do
        currentPos = currentPos + (direction * maxStep)
        hrp.CFrame = CFrame.new(currentPos)
        task.wait(0.02)
    end
    hrp.CFrame = CFrame.new(targetPos)
end

player.CharacterRemoving:Connect(function(char)
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then lastDeathPos = hrp.Position end
end)

player.CharacterAdded:Connect(function(char)
    char:WaitForChild("HumanoidRootPart")
    local isCriminal = (player.TeamColor == BrickColor.new("Bright orange"))
    if cfg.grabGuns and isCriminal then
        grabWeaponStationary("Remington 870")
        grabWeaponStationary("M4A1")
    end
    task.wait(0.1)
    if cfg.tpOnRespawn and lastDeathPos then
        safeTeleport(lastDeathPos + Vector3.new(0, 3, 0))
    end
end)
local function isVisible(part, char)
    local parts = camera:GetPartsObscuringTarget({camera.CFrame.Position, part.Position}, {player.Character, char, camera})
    return #parts == 0
end

local function getTargetInFov(fovRadius)
    local closestTarget = nil
    local shortestDistance = fovRadius
    local myHrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not myHrp then return nil end

    for _, p in ipairs(game.Players:GetPlayers()) do
        if p ~= player and p.Character and p.TeamColor ~= player.TeamColor then
            local isTargetValid = false
            if blacklist[p.Name] then
                isTargetValid = true
            elseif not whitelist[p.Name] then
                isTargetValid = true
            end

            if isTargetValid then
                local character = p.Character
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    local targetPart = (cfg.aimMode == "Head") and character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
                    if targetPart then
                        local screenPos, onScreen = camera:WorldToViewportPoint(targetPart.Position)
                        if onScreen then
                            local mousePos = Vector2.new(mouse.X, mouse.Y)
                            local targetPos2D = Vector2.new(screenPos.X, screenPos.Y)
                            local distanceToCrosshair = (targetPos2D - mousePos).Magnitude
                            local distanceToPlayer = (targetPart.Position - myHrp.Position).Magnitude

                            if distanceToCrosshair < shortestDistance and distanceToPlayer < cfg.aimMaxDistance then
                                if isVisible(targetPart, character) then
                                    shortestDistance = distanceToCrosshair
                                    closestTarget = targetPart
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return closestTarget
end

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local args = {...}
    local method = getnamecallmethod()

    if cfg.silentAimEnabled and method == "FireServer" and self.Name == "Input" then
        local target = getTargetInFov(cfg.silentAimFov)
        if target then
            args[1] = target.Position
            return oldNamecall(self, unpack(args))
        end
    end
    return oldNamecall(self, ...)
end)
RunService.RenderStepped:Connect(function()
    local isRmbPressed = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    if cfg.aimbotEnabled and (aimbotActiveState or isRmbPressed) then
        local target = getTargetInFov(cfg.aimAssistFov)
        if target then
            camera.CFrame = CFrame.new(camera.CFrame.Position, target.Position)
            local tool = player.Character and player.Character:FindFirstChildOfClass("Tool")
            if tool and tool:FindFirstChild("Input") then tool.Input:FireServer(mouse.Hit.p) end
        end
    end
    
    if freecamActive then
        camera.CameraType = Enum.CameraType.Scriptable
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.PlatformStand = true end
        end

        local mouseDelta = UserInputService:GetMouseDelta()
        local isCcPressed = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
        
        if isCcPressed or isRmbPressed then
            freecamRotX = freecamRotX - (mouseDelta.X * 0.003)
            if isRmbPressed then
                freecamRotY = math.clamp(freecamRotY - (mouseDelta.Y * 0.003), -math.pi/2.1, math.pi/2.1)
            else
                freecamRotY = 0
            end
        end

        camera.CFrame = CFrame.new(camera.CFrame.Position) * CFrame.Angles(0, freecamRotX, 0) * CFrame.Angles(freecamRotY, 0, 0)

        local moveVector = Vector3.new(0,0,0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVector = moveVector + camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVector = moveVector - camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVector = moveVector - camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVector = moveVector + camera.CFrame.RightVector end
        camera.CFrame = camera.CFrame + (moveVector * cfg.freecamSpeed)
    else
        local char = player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.PlatformStand = false end
        end
    end

    if cfg.espEnabled then
        for _, p in ipairs(game.Players:GetPlayers()) do
            if p ~= player and p.Character then
                local char = p.Character
                if not char:FindFirstChild("PremiumHighlight") then
                    local hl = Instance.new("Highlight", char)
                    hl.Name = "PremiumHighlight"
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    hl.FillColor = (p.TeamColor == BrickColor.new("Bright orange")) and Color3.fromRGB(255, 120, 0) or (p.TeamColor == BrickColor.new("Bright blue") and Color3.fromRGB(50, 120, 255) or Color3.fromRGB(150, 150, 150))
                    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                    hl.FillTransparency = 0.5
                end
            end
        end
    else
        for _, p in ipairs(game.Players:GetPlayers()) do
            if p.Character and p.Character:FindFirstChild("PremiumHighlight") then p.Character.PremiumHighlight:Destroy() end
        end
    end
end)

mouse.Button1Down:Connect(function()
    if cfg.tpEnabled and mouse.Target then
        if UserInputService:IsKeyDown(binds.ClickTP) then
            safeTeleport(mouse.Hit.p + Vector3.new(0, 3, 0))
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, proc)
    if proc then return end
    local alt = UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) or UserInputService:IsKeyDown(Enum.KeyCode.RightAlt)
    if alt then
        if input.KeyCode == binds.Rejoin then
            if #game.Players:GetPlayers() <= 1 then TeleportService:Teleport(game.PlaceId, player) else TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player) end
        elseif input.KeyCode == binds.ActivateTP then cfg.tpEnabled = not cfg.tpEnabled
        elseif input.KeyCode == binds.FreecamToggle then freecamActive = not freecamActive if not freecamActive then camera.CameraType = originalCameraType end
        elseif input.KeyCode == binds.UnlockMouse then mouseUnlocked = not mouseUnlocked UserInputService.MouseBehavior = mouseUnlocked and Enum.MouseBehavior.Default or Enum.MouseBehavior.LockCenter
        elseif input.KeyCode == binds.SilentToggle then cfg.silentAimEnabled = not cfg.silentAimEnabled
        elseif input.KeyCode == binds.Reload then loadstring(game:HttpGet("https://githubusercontent.com"))() end
    end
end)

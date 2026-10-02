-- Prison Life Premium Hub - Monolithic Release
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
    aimMode = "Head",
    tpOnRespawn = false,
    grabGuns = false,
    espEnabled = false,
    guiScalePercent = 100,
    aimMaxDistance = 500,
    freecamSpeed = 1
}

local binds = {
    ClickTP = Enum.KeyCode.Q,
    ActivateTP = Enum.KeyCode.Q,
    SaveWP = Enum.KeyCode.Y,
    DeleteWP = Enum.KeyCode.T,
    Rejoin = Enum.KeyCode.R,
    Ghost = Enum.KeyCode.G,
    Minimize = Enum.KeyCode.M,
    AimToggle = Enum.KeyCode.N,
    Reload = Enum.KeyCode.F8,
    UnlockMouse = Enum.KeyCode.LeftControl,
    FreecamToggle = Enum.KeyCode.X
}

local waypoints = {}
local wpCount = 0
local whitelist = {}
local blacklist = {}
local lastDeathPos = nil
local ghostMode = false
local minimized = false
local aimbotActiveState = false
local freecamActive = false
local mouseUnlocked = false
local originalCameraType = camera.CameraType

local function saveConfig()
    local data = {cfg = cfg, waypoints = waypoints, whitelist = whitelist, blacklist = blacklist, binds = {}}
    for k, v in pairs(binds) do data.binds[k] = v.Name end
    pcall(function() writefile("PL_Premium_Hub_v5.json", HttpService:JSONEncode(data)) end)
end

local function loadConfig()
    pcall(function()
        if isfile and isfile("PL_Premium_Hub_v5.json") then
            local data = HttpService:JSONDecode(readfile("PL_Premium_Hub_v5.json"))
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

player.CharacterRemoving:Connect(function(char)
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then lastDeathPos = hrp.Position end
end)

local function safeTeleport(targetPos)
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

player.CharacterAdded:Connect(function(char)
    char:WaitForChild("HumanoidRootPart")
    local isCriminal = (player.TeamColor == BrickColor.new("Bright orange"))
    if cfg.grabGuns and isCriminal then
        grabWeaponStationary("Remington 870")
        grabWeaponStationary("M4A1")
    end
    task.wait(0.1)
    if cfg.tpOnRespawn and lastDeathPos then
        if cfg.grabGuns and isCriminal then
            local hasRemington = char:FindFirstChild("Remington 870") or player.Backpack:FindFirstChild("Remington 870")
            local hasM4 = char:FindFirstChild("M4A1") or player.Backpack:FindFirstChild("M4A1")
            if hasRemington and hasM4 then safeTeleport(lastDeathPos + Vector3.new(0, 3, 0)) end
        else
            safeTeleport(lastDeathPos + Vector3.new(0, 3, 0))
        end
    end
end)

local function isVisible(part, char)
    local parts = camera:GetPartsObscuringTarget({camera.CFrame.Position, part.Position}, {player.Character, char, camera})
    return #parts == 0
end

local function getBestTarget()
    local closest = nil
    local maxDist = cfg.aimMaxDistance
    local myHrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not myHrp then return nil end
    
    for _, p in ipairs(game.Players:GetPlayers()) do
        if p ~= player and p.Character and p.TeamColor ~= player.TeamColor then
            if not blacklist[p.Name] or whitelist[p.Name] then
                local character = p.Character
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    local targetPart = (cfg.aimMode == "Head") and character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
                    if targetPart then
                        local screenPos, onScreen = camera:WorldToViewportPoint(targetPart.Position)
                        if onScreen then
                            local distance = (targetPart.Position - myHrp.Position).Magnitude
                            if distance < maxDist then
                                closest = targetPart
                                maxDist = distance
                            end
                        end
                    end
                end
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    local isRmbPressed = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    if cfg.aimbotEnabled and (aimbotActiveState or isRmbPressed) then
        local target = getBestTarget()
        if target then
            camera.CFrame = CFrame.new(camera.CFrame.Position, target.Position)
            local tool = player.Character and player.Character:FindFirstChildOfClass("Tool")
            if tool and tool:FindFirstChild("Input") then tool.Input:FireServer(mouse.Hit.p) end
        end
    end
    
    if freecamActive then
        camera.CameraType = Enum.CameraType.Scriptable
        local moveVector = Vector3.new(0,0,0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVector = moveVector + camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVector = moveVector - camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVector = moveVector - camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVector = moveVector + camera.CFrame.RightVector end
        camera.CFrame = camera.CFrame + (moveVector * cfg.freecamSpeed)
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

local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
local MainFrame = Instance.new("Frame", ScreenGui)
local Title = Instance.new("TextLabel", MainFrame)
local TabBar = Instance.new("Frame", MainFrame)
local ContentFrame = Instance.new("Frame", MainFrame)
local UICorner = Instance.new("UICorner", MainFrame)

ScreenGui.Name = "PL_Premium_Hub_UI"
ScreenGui.ResetOnSpawn = false
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.Active = true MainFrame.Draggable = true
UICorner.CornerRadius = UDim.new(0, 6)

local allTextObjects = {}
local function registerText(obj, baseSize)
    allTextObjects[obj] = baseSize
    obj.TextSize = baseSize * (cfg.guiScalePercent / 100)
    obj.Font = Enum.Font.GothamBold
end

local function applySizeAndScale()
    local multiplier = cfg.guiScalePercent / 100
    if minimized then MainFrame.Size = UDim2.new(0, 350 * multiplier, 0, 35) else MainFrame.Size = UDim2.new(0, 350 * multiplier, 0, 300 * multiplier) end
    Title.Size = UDim2.new(1, 0, 0, 35) TabBar.Size = UDim2.new(1, 0, 0, 30) TabBar.Position = UDim2.new(0, 0, 0, 35) ContentFrame.Size = UDim2.new(1, 0, 1, -65) ContentFrame.Position = UDim2.new(0, 0, 0, 65)
    for obj, baseSize in pairs(allTextObjects) do if obj and obj.Parent then obj.TextSize = baseSize * multiplier else allTextObjects[obj] = nil end end
end

Title.Text = "Prison Life Premium Hub" Title.TextColor3 = Color3.fromRGB(255, 255, 255) registerText(Title, 15)
TabBar.BackgroundTransparency = 1 ContentFrame.BackgroundTransparency = 1

local tabs = {}
local function createTab(name, text, pos)
    local btn = Instance.new("TextButton", TabBar)
    btn.Size = UDim2.new(0.2, 0, 1, 0) btn.Position = pos
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40) btn.Text = text btn.TextColor3 = Color3.fromRGB(200, 200, 200) btn.BorderSizePixel = 0 registerText(btn, 13)
    local f = Instance.new("ScrollingFrame", ContentFrame) f.Size = UDim2.new(1, -20, 1, -20) f.Position = UDim2.new(0, 10, 0, 10) f.BackgroundTransparency = 1 f.Visible = false f.ScrollBarThickness = 4 f.CanvasSize = UDim2.new(0, 0, 0, 600)
    local l = Instance.new("UIListLayout", f) l.Padding = UDim.new(0, 5) tabs[name] = {btn = btn, frame = f}
    btn.MouseButton1Click:Connect(function() for _, t in pairs(tabs) do t.frame.Visible = false t.btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40) end f.Visible = true btn.BackgroundColor3 = Color3.fromRGB(55, 55, 55) end)
end

createTab("Main", "Main", UDim2.new(0, 0, 0, 0))
createTab("Waypoints", "WPs", UDim2.new(0.2, 0, 0, 0))
createTab("Keybinds", "Binds", UDim2.new(0.4, 0, 0, 0))
createTab("Lists", "Teams", UDim2.new(0.6, 0, 0, 0))
createTab("Config", "Cfg", UDim2.new(0.8, 0, 0, 0))
tabs.Main.frame.Visible = true

local function createToggle(parent, text, default, callback)
    local btn = Instance.new("TextButton", parent) btn.Size = UDim2.new(1, 0, 0, 30) registerText(btn, 13)
    local function update() btn.Text = text .. ": " .. (default and "ON" or "OFF") btn.BackgroundColor3 = default and Color3.fromRGB(50, 180, 50) or Color3.fromRGB(180, 50, 50) end
    btn.MouseButton1Click:Connect(function() default = not default callback(default) update() saveConfig() end)
    update() Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
end

createToggle(tabs.Main.frame, "Bypass Click TP", cfg.tpEnabled, function(v) cfg.tpEnabled = v end)
createToggle(tabs.Main.frame, "Smart Aimbot", cfg.aimbotEnabled, function(v) cfg.aimbotEnabled = v end)
createToggle(tabs.Main.frame, "See-Through Wall ESP", cfg.espEnabled, function(v) cfg.espEnabled = v end)
createToggle(tabs.Main.frame, "Free Camera Simulation", freecamActive, function(v) freecamActive = v if not v then camera.CameraType = originalCameraType end end)

createToggle(tabs.Config.frame, "Hitbox Mode (ON=Head/OFF=Body)", (cfg.aimMode == "Head"), function(v) cfg.aimMode = v and "Head" or "AllBody" end)
createToggle(tabs.Config.frame, "Auto Grab Guns on Respawn", cfg.grabGuns, function(v) cfg.grabGuns = v end)
createToggle(tabs.Config.frame, "Teleport to Last Pos on Death", cfg.tpOnRespawn, function(v) cfg.tpOnRespawn = v end)

local scaleContainer = Instance.new("Frame", tabs.Config.frame) scaleContainer.Size = UDim2.new(1, 0, 0, 35) scaleContainer.BackgroundTransparency = 1
local scaleLbl = Instance.new("TextLabel", scaleContainer) scaleLbl.Size = UDim2.new(0.6, 0, 1, 0) scaleLbl.Text = "GUI Scale (%):" scaleLbl.TextColor3 = Color3.fromRGB(255,255,255) scaleLbl.BackgroundTransparency = 1 scaleLbl.TextXAlignment = Enum.TextXAlignment.Left registerText(scaleLbl, 13)
local scaleBox = Instance.new("TextBox", scaleContainer) scaleBox.Size = UDim2.new(0.35, 0, 0.8, 0) scaleBox.Position = UDim2.new(0.62, 0, 0.1, 0) scaleBox.BackgroundColor3 = Color3.fromRGB(50,50,50) scaleBox.TextColor3 = Color3.fromRGB(255,255,255) scaleBox.Text = tostring(cfg.guiScalePercent) Instance.new("UICorner", scaleBox) registerText(scaleBox, 13)
scaleBox.FocusLost:Connect(function() local num = tonumber(scaleBox.Text) if num and num >= 50 and num <= 250 then cfg.guiScalePercent = num applySizeAndScale() saveConfig() else scaleBox.Text = tostring(cfg.guiScalePercent) end end)

local wpAddBtn = Instance.new("TextButton", tabs.Waypoints.frame) wpAddBtn.Size = UDim2.new(1, 0, 0, 30) wpAddBtn.BackgroundColor3 = Color3.fromRGB(60,60,180) wpAddBtn.Text = "+ Add New Waypoint" wpAddBtn.TextColor3 = Color3.fromRGB(255,255,255) registerText(wpAddBtn, 13) Instance.new("UICorner", wpAddBtn)

local function updateWPMenu()
    for _, c in ipairs(tabs.Waypoints.frame:GetChildren()) do if c:IsA("TextButton") and c ~= wpAddBtn then c:Destroy() end end
    for _, wp in ipairs(waypoints) do
        local b = Instance.new("TextButton", tabs.Waypoints.frame) b.Size = UDim2.new(1, 0, 0, 30) b.BackgroundColor3 = Color3.fromRGB(50, 50, 50) b.Text = wp.name b.TextColor3 = Color3.fromRGB(255, 255, 255) registerText(b, 13)
        b.MouseButton1Click:Connect(function() safeTeleport(wp.pos) end) Instance.new("UICorner", b)
    end
end
wpAddBtn.MouseButton1Click:Connect(function() local char = player.Character if char and char:FindFirstChild("HumanoidRootPart") then wpCount = wpCount + 1 table.insert(waypoints, {name = "Waypoint " .. wpCount, pos = char.HumanoidRootPart.Position}) updateWPMenu() saveConfig() end end)

local bindButtons = {}
local currentRebinding = nil
local function createBindRow(actionName, displayName)
    local f = Instance.new("Frame", tabs.Keybinds.frame) f.Size = UDim2.new(1, 0, 0, 32) f.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    local lbl = Instance.new("TextLabel", f) lbl.Size = UDim2.new(0.6, 0, 1, 0) lbl.Position = UDim2.new(0, 5, 0, 0) lbl.Text = displayName lbl.TextColor3 = Color3.fromRGB(230, 230, 230) lbl.BackgroundTransparency = 1 lbl.TextXAlignment = Enum.TextXAlignment.Left registerText(lbl, 12)
    local b = Instance.new("TextButton", f) b.Size = UDim2.new(0.35, 0, 0.8, 0) b.Position = UDim2.new(0.62, 0, 0.1, 0) b.BackgroundColor3 = Color3.fromRGB(65, 65, 65) b.Text = binds[actionName].Name b.TextColor3 = Color3.fromRGB(255, 255, 255) registerText(b, 12)
    b.MouseButton1Click:Connect(function() if not currentRebinding then currentRebinding = actionName b.Text = "..." end end)
    Instance.new("UICorner", f) Instance.new("UICorner", b) bindButtons[actionName] = b
end

createBindRow("ClickTP", "Hold Key + Click TP")
createBindRow("ActivateTP", "Alt+Key Toggle Click TP Mode")
createBindRow("FreecamToggle", "Alt+Key Toggle Freecam")
createBindRow("UnlockMouse", "Alt+Key Unlock Cursor")
createBindRow("SaveWP", "Alt + Key: Save Position")
createBindRow("DeleteWP", "Alt + Key: Delete Last Position")
createBindRow("Rejoin", "Alt + Key: Quick Rejoin")
createBindRow("Ghost", "Alt + Key: Ghost Mode Toggle")
createBindRow("Minimize", "Alt + Key: Minimize GUI")
createBindRow("AimToggle", "Alt + Key: Toggle Aimbot")
createBindRow("Reload", "Alt + Key: Reload Script")

local openTeams = {}
local function updateListsMenu()
    for _, c in ipairs(tabs.Lists.frame:GetChildren()) do if c:IsA("Frame") or c:IsA("TextButton") then c:Destroy() end end
    local teams = {["Guards"] = {}, ["Criminals"] = {}, ["Inmates"] = {}, ["Neutral"] = {}}
    for _, p in ipairs(game.Players:GetPlayers()) do
        if p ~= player then
            local tName = "Neutral"
            if p.TeamColor == BrickColor.new("Bright blue") then tName = "Guards"
            elseif p.TeamColor == BrickColor.new("Bright orange") then tName = "Criminals"
            elseif p.TeamColor == BrickColor.new("Bright yellow") or p.TeamColor == BrickColor.new("Medium stone grey") then tName = "Inmates" end
            table.insert(teams[tName], p)
        end
    end
    for tName, players in pairs(teams) do
        local teamBtn = Instance.new("TextButton", tabs.Lists.frame) teamBtn.Size = UDim2.new(1, 0, 0, 25) teamBtn.BackgroundColor3 = Color3.fromRGB(55,55,55) teamBtn.Text = tName .. " (" .. #players .. ")" teamBtn.TextColor3 = Color3.fromRGB(255,255,255) registerText(teamBtn, 13) Instance.new("UICorner", teamBtn)
        teamBtn.MouseButton1Click:Connect(function() openTeams[tName] = not openTeams[tName] updateListsMenu() end)
        if openTeams[tName] then
            for _, p in ipairs(players) do
                local row = Instance.new("Frame", tabs.Lists.frame) row.Size = UDim2.new(1, 0, 0, 35) row.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
                local lbl = Instance.new("TextLabel", row) lbl.Size = UDim2.new(0.5, 0, 1, 0) lbl.Position = UDim2.new(0, 5, 0, 0) lbl.Text = p.Name lbl.TextColor3 = Color3.fromRGB(255, 255, 255) lbl.BackgroundTransparency = 1 lbl.TextXAlignment = Enum.TextXAlignment.Left registerText(lbl, 12)
                local wBtn = Instance.new("TextButton", row) wBtn.Size = UDim2.new(0.2, 0, 0.8, 0) wBtn.Position = UDim2.new(0.55, 0, 0.1, 0) wBtn.Text = "WL" wBtn.BackgroundColor3 = whitelist[p.Name] and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(70, 70, 70) registerText(wBtn, 11)
                wBtn.MouseButton1Click:Connect(function() whitelist[p.Name] = not whitelist[p.Name] blacklist[p.Name] = nil updateListsMenu() saveConfig() end)
                local bBtn = Instance.new("TextButton", row) bBtn.Size = UDim2.new(0.2, 0, 0.8, 0) bBtn.Position = UDim2.new(0.78, 0, 0.1, 0) bBtn.Text = "BL" bBtn.BackgroundColor3 = blacklist[p.Name] and Color3.fromRGB(150, 150, 50) or Color3.fromRGB(70, 70, 70) registerText(bBtn, 11)
                bBtn.MouseButton1Click:Connect(function() blacklist[p.Name] = not blacklist[p.Name] whitelist[p.Name] = nil updateListsMenu() saveConfig() end)
                Instance.new("UICorner", row) Instance.new("UICorner", wBtn) Instance.new("UICorner", bBtn)
            end
        end
    end
end
game.Players.PlayerAdded:Connect(updateListsMenu) game.Players.PlayerRemoving:Connect(updateListsMenu) updateListsMenu() applySizeAndScale() updateWPMenu()

UserInputService.InputBegan:Connect(function(input, proc)
    if currentRebinding then
        if input.UserInputType == Enum.UserInputType.Keyboard then binds[currentRebinding] = input.KeyCode bindButtons[currentRebinding].Text = input.KeyCode.Name currentRebinding = nil saveConfig() end
        return
    end
    if proc then return end
    local alt = UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) or UserInputService:IsKeyDown(Enum.KeyCode.RightAlt)
    if alt then
        if input.KeyCode == binds.Rejoin then
            if #game.Players:GetPlayers() <= 1 then TeleportService:Teleport(game.PlaceId, player) else TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player) end
        elseif input.KeyCode == binds.ActivateTP then cfg.tpEnabled = not cfg.tpEnabled saveConfig()
        elseif input.KeyCode == binds.FreecamToggle then freecamActive = not freecamActive if not freecamActive then camera.CameraType = originalCameraType end
        elseif input.KeyCode == binds.UnlockMouse then mouseUnlocked = not mouseUnlocked UserInputService.MouseBehavior = mouseUnlocked and Enum.MouseBehavior.Default or Enum.MouseBehavior.LockCenter
        elseif input.KeyCode == binds.SaveWP then local char = player.Character if char and char:FindFirstChild("HumanoidRootPart") then wpCount = wpCount + 1 table.insert(waypoints, {name = "Waypoint " .. wpCount, pos = char.HumanoidRootPart.Position}) updateWPMenu() saveConfig() end
        elseif input.KeyCode == binds.DeleteWP then if #waypoints > 0 then table.remove(waypoints, #waypoints) updateWPMenu() saveConfig() end
        elseif input.KeyCode == binds.AimToggle then aimbotActiveState = not aimbotActiveState
        elseif input.KeyCode == binds.Reload then ScreenGui:Destroy() loadstring(game:HttpGet("https://raw.githubusercontent.com/sakuyaidzayoi-cyber/mrs/refs/heads/main/t.lua"))()
        elseif input.KeyCode == binds.Ghost then ghostMode = not ghostMode MainFrame.Visible = not ghostMode
        elseif input.KeyCode == binds.Minimize then
            minimized = not minimized
            if minimized then MainFrame.Size = UDim2.new(0, MainFrame.Size.X.Offset, 0, 35) TabBar.Visible = false ContentFrame.Visible = false else applySizeAndScale() TabBar.Visible = true ContentFrame.Visible = true end
        end
    end
end)

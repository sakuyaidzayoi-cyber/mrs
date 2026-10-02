local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local camera = workspace.CurrentCamera

local cfg = {
    tpEnabled = false,
    aimbotEnabled = false,
    aimMode = "Head", -- "Head" или "AllBody"
    tpOnRespawn = false,
    grabGuns = false,
    espEnabled = false,
    aimMaxDistance = 250
}

local binds = {
    ClickTP = Enum.KeyCode.Q,
    SaveWP = Enum.KeyCode.Y,
    DeleteWP = Enum.KeyCode.T,
    Rejoin = Enum.KeyCode.R,
    Ghost = Enum.KeyCode.G,
    Minimize = Enum.KeyCode.M,
    AimToggle = Enum.KeyCode.N,
    Reload = Enum.KeyCode.F8
}

local waypoints = {}
local wpCount = 0
local whitelist = {}
local blacklist = {}
local lastDeathPos = nil
local ghostMode = false
local minimized = false
local aimbotActiveState = false

local function saveConfig()
    local data = {cfg = cfg, waypoints = waypoints, whitelist = whitelist, blacklist = blacklist}
    pcall(function() writefile("PL_Premium_Hub.json", HttpService:JSONEncode(data)) end)
end

local function loadConfig()
    pcall(function()
        if isfile and isfile("PL_Premium_Hub.json") then
            local data = HttpService:JSONDecode(readfile("PL_Premium_Hub.json"))
            if data.cfg then cfg = data.cfg end
            if data.waypoints then waypoints = data.waypoints end
            if data.whitelist then whitelist = data.whitelist end
            if data.blacklist then blacklist = data.blacklist end
        end
    end)
end
loadConfig()

local function giveWeapon(gunName)
    local workspaceGuns = workspace:FindFirstChild("Prison_Guns") or workspace:FindFirstChild("Guns")
    if workspaceGuns then
        local giver = workspaceGuns:FindFirstChild(gunName)
        if giver and giver:FindFirstChild("ItemGiver") then
            local itemGiver = giver.ItemGiver
            if itemGiver:IsA("RemoteEvent") then
                itemGiver:FireServer()
            elseif itemGiver:IsA("BindableEvent") then
                itemGiver:Fire()
            end
        end
    end
end

local function safeTeleport(targetPos)
    local character = player.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local maxStep = 25
    local currentPos = hrp.Position
    local direction = (targetPos - currentPos).Unit
    local distance = (targetPos - currentPos).Magnitude
    local steps = math.floor(distance / maxStep)
    for i = 1, steps do
        currentPos = currentPos + (direction * maxStep)
        hrp.CFrame = CFrame.new(currentPos)
        task.wait(0.03)
    end
    hrp.CFrame = CFrame.new(targetPos)
end

player.CharacterRemoving:Connect(function(char)
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then lastDeathPos = hrp.Position end
end)

player.CharacterAdded:Connect(function(char)
    char:WaitForChild("HumanoidRootPart")
    task.wait(0.5)
    local isCriminal = (player.TeamColor == BrickColor.new("Bright orange"))
    
    if cfg.grabGuns and isCriminal then
        giveWeapon("Remington 870")
        giveWeapon("M4A1")
        task.wait(0.3)
    end
    
    if cfg.tpOnRespawn and lastDeathPos then
        if cfg.grabGuns and isCriminal then
            local hasRemington = char:FindFirstChild("Remington 870") or player.Backpack:FindFirstChild("Remington 870")
            local hasM4 = char:FindFirstChild("M4A1") or player.Backpack:FindFirstChild("M4A1")
            if hasRemington and hasM4 then
                safeTeleport(lastDeathPos + Vector3.new(0, 3, 0))
            end
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
        if p ~= player and p.Character and p.TeamColor ~= player.TeamColor and p.TeamColor ~= BrickColor.new("Bright orange") then
            if whitelist[p.Name] or blacklist[p.Name] == false then
                local character = p.Character
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    local targetPart = (cfg.aimMode == "Head") and character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
                    if targetPart then
                        local distance = (targetPart.Position - myHrp.Position).Magnitude
                        if distance < maxDist and isVisible(targetPart, character) then
                            maxDist = distance
                            closest = targetPart
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
    
    if cfg.espEnabled then
        for _, p in ipairs(game.Players:GetPlayers()) do
            if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = p.Character.HumanoidRootPart
                if not hrp:FindFirstChild("HubESP") then
                    local bbg = Instance.new("BillboardGui", hrp)
                    bbg.Name = "HubESP"
                    bbg.AlwaysOnTop = true
                    bbg.Size = UDim2.new(4, 0, 5, 0)
                    local frame = Instance.new("Frame", bbg)
                    frame.Size = UDim2.new(1, 0, 1, 0)
                    frame.BackgroundTransparency = 1
                    local inline = Instance.new("SelectionBox", p.Character)
                    inline.Name = "EspBox"
                    inline.Adornee = p.Character
                    inline.Color3 = (p.TeamColor == BrickColor.new("Bright orange")) and Color3.fromRGB(255, 140, 0) or Color3.fromRGB(200, 50, 50)
                end
            end
        end
    else
        for _, p in ipairs(game.Players:GetPlayers()) do
            if p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                if hrp and hrp:FindFirstChild("HubESP") then hrp.HubESP:Destroy() end
                if p.Character:FindFirstChild("EspBox") then p.Character.EspBox:Destroy() end
            end
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
MainFrame.Size = UDim2.new(0, 280, 0, 260)
MainFrame.Position = UDim2.new(0.1, 0, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.Active = true MainFrame.Draggable = true
Title.Size = UDim2.new(1, 0, 0, 35) Title.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
Title.Text = "Prison Life Premium Hub" Title.TextColor3 = Color3.fromRGB(255, 255, 255) Title.Font = Enum.Font.SourceSansBold
TabBar.Size = UDim2.new(1, 0, 0, 30) TabBar.Position = UDim2.new(0, 0, 0, 35) TabBar.BackgroundTransparency = 1
ContentFrame.Size = UDim2.new(1, 0, 1, -65) ContentFrame.Position = UDim2.new(0, 0, 0, 65) ContentFrame.BackgroundTransparency = 1

local tabs = {}
local function createTab(name, text, pos)
    local btn = Instance.new("TextButton", TabBar)
    btn.Size = UDim2.new(0.2, 0, 1, 0) btn.Position = pos
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40) btn.Text = text btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.Font = Enum.Font.SourceSansBold btn.BorderSizePixel = 0
    local f = Instance.new("ScrollingFrame", ContentFrame)
    f.Size = UDim2.new(1, -20, 1, -20) f.Position = UDim2.new(0, 10, 0, 10) f.BackgroundTransparency = 1 f.Visible = false
    f.ScrollBarThickness = 4 f.CanvasSize = UDim2.new(0, 0, 0, 400)
    local l = Instance.new("UIListLayout", f) l.Padding = UDim.new(0, 5)
    tabs[name] = {btn = btn, frame = f}
    btn.MouseButton1Click:Connect(function()
        for _, t in pairs(tabs) do t.frame.Visible = false t.btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40) end
        f.Visible = true btn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
    end)
end

createTab("Main", "Main", UDim2.new(0, 0, 0, 0))
createTab("Waypoints", "WPs", UDim2.new(0.2, 0, 0, 0))
createTab("Keybinds", "Binds", UDim2.new(0.4, 0, 0, 0))
createTab("Lists", "Lists", UDim2.new(0.6, 0, 0, 0))
createTab("Config", "Cfg", UDim2.new(0.8, 0, 0, 0))
tabs.Main.frame.Visible = true

local function createToggle(parent, text, default, callback)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, 0, 0, 30) btn.Font = Enum.Font.SourceSansBold btn.TextSize = 14
    local function update()
        btn.Text = text .. ": " .. (default and "ON" or "OFF")
        btn.BackgroundColor3 = default and Color3.fromRGB(50, 180, 50) or Color3.fromRGB(180, 50, 50)
    end
    btn.MouseButton1Click:Connect(function() default = not default callback(default) update() saveConfig() end)
    update() Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
end

createToggle(tabs.Main.frame, "Bypass Click TP", cfg.tpEnabled, function(v) cfg.tpEnabled = v end)
createToggle(tabs.Main.frame, "Smart Aimbot", cfg.aimbotEnabled, function(v) cfg.aimbotEnabled = v end)
createToggle(tabs.Main.frame, "ESP Master Switch", cfg.espEnabled, function(v) cfg.espEnabled = v end)

createToggle(tabs.Config.frame, "Hitbox Mode (ON=Head/OFF=Body)", (cfg.aimMode == "Head"), function(v) cfg.aimMode = v and "Head" or "AllBody" end)
createToggle(tabs.Config.frame, "Auto Grab Guns on Respawn", cfg.grabGuns, function(v) cfg.grabGuns = v end)
createToggle(tabs.Config.frame, "Teleport to Last Pos on Death", cfg.tpOnRespawn, function(v) cfg.tpOnRespawn = v end)

local function updateWPMenu()
    for _, c in ipairs(tabs.Waypoints.frame:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
    for _, wp in ipairs(waypoints) do
        local b = Instance.new("TextButton", tabs.Waypoints.frame)
        b.Size = UDim2.new(1, 0, 0, 30) b.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        b.Text = wp.name b.TextColor3 = Color3.fromRGB(255, 255, 255) b.Font = Enum.Font.SourceSansBold
        b.MouseButton1Click:Connect(function() safeTeleport(wp.pos) end)
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
    end
end
updateWPMenu()

local function addWaypoint()
    local char = player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        wpCount = wpCount + 1
        table.insert(waypoints, {name = "Waypoint " .. wpCount, pos = char.HumanoidRootPart.Position})
        updateWPMenu() saveConfig()
    end
end

local function deleteLastWaypoint()
    if #waypoints > 0 then table.remove(waypoints, #waypoints) updateWPMenu() saveConfig() end
end

local currentRebinding = nil
local bindButtons = {}
local function createBindRow(actionName, displayName)
    local f = Instance.new("Frame", tabs.Keybinds.frame) f.Size = UDim2.new(1, 0, 0, 32) f.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    local lbl = Instance.new("TextLabel", f) lbl.Size = UDim2.new(0.6, 0, 1, 0) lbl.Position = UDim2.new(0, 5, 0, 0)
    lbl.Text = displayName lbl.TextColor3 = Color3.fromRGB(230, 230, 230) lbl.Font = Enum.Font.SourceSansBold lbl.BackgroundTransparency = 1 lbl.TextXAlignment = Enum.TextXAlignment.Left
    local b = Instance.new("TextButton", f) b.Size = UDim2.new(0.35, 0, 0.8, 0) b.Position = UDim2.new(0.62, 0, 0.1, 0)
    b.BackgroundColor3 = Color3.fromRGB(65, 65, 65) b.Text = binds[actionName].Name b.TextColor3 = Color3.fromRGB(255, 255, 255) b.Font = Enum.Font.SourceSansBold
    b.MouseButton1Click:Connect(function() if not currentRebinding then currentRebinding = actionName b.Text = "..." end end)
    Instance.new("UICorner", f) Instance.new("UICorner", b)
    bindButtons[actionName] = b
end

createBindRow("ClickTP", "Hold Key + Click TP")
createBindRow("SaveWP", "Alt + Key: Save Position")
createBindRow("DeleteWP", "Alt + Key: Delete Last Position")
createBindRow("Rejoin", "Alt + Key: Quick Rejoin")
createBindRow("Ghost", "Alt + Key: Ghost Mode Toggle")
createBindRow("Minimize", "Alt + Key: Minimize GUI")
createBindRow("AimToggle", "Alt + Key: Toggle Aimbot")
createBindRow("Reload", "Alt + Key: Reload Script")

local function updateListsMenu()
    for _, c in ipairs(tabs.Lists.frame:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    for _, p in ipairs(game.Players:GetPlayers()) do
        if p ~= player then
            local row = Instance.new("Frame", tabs.Lists.frame) row.Size = UDim2.new(1, 0, 0, 35) row.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            local lbl = Instance.new("TextLabel", row) lbl.Size = UDim2.new(0.5, 0, 1, 0) lbl.Position = UDim2.new(0, 5, 0, 0)
            lbl.Text = p.Name lbl.TextColor3 = Color3.fromRGB(255, 255, 255) lbl.Font = Enum.Font.SourceSansBold lbl.BackgroundTransparency = 1 lbl.TextXAlignment = Enum.TextXAlignment.Left
            
            local wBtn = Instance.new("TextButton", row) wBtn.Size = UDim2.new(0.2, 0, 0.8, 0) wBtn.Position = UDim2.new(0.55, 0, 0.1, 0)
            wBtn.Text = "WL" wBtn.BackgroundColor3 = whitelist[p.Name] and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(70, 70, 70)
            wBtn.MouseButton1Click:Connect(function() whitelist[p.Name] = not whitelist[p.Name] blacklist[p.Name] = nil updateListsMenu() saveConfig() end)
            
            local bBtn = Instance.new("TextButton", row) bBtn.Size = UDim2.new(0.2, 0, 0.8, 0) bBtn.Position = UDim2.new(0.78, 0, 0.1, 0)
            bBtn.Text = "BL" bBtn.BackgroundColor3 = blacklist[p.Name] and Color3.fromRGB(150, 50, 50) or Color3.fromRGB(70, 70, 70)
            bBtn.MouseButton1Click:Connect(function() blacklist[p.Name] = not blacklist[p.Name] whitelist[p.Name] = nil updateListsMenu() saveConfig() end)
            
            Instance.new("UICorner", row) Instance.new("UICorner", wBtn) Instance.new("UICorner", bBtn)
        end
    end
end
game.Players.PlayerAdded:Connect(updateListsMenu) game.Players.PlayerRemoving:Connect(updateListsMenu) updateListsMenu()

UserInputService.InputBegan:Connect(function(input, proc)
    if currentRebinding then
        if input.UserInputType == Enum.UserInputType.Keyboard then
            binds[currentRebinding] = input.KeyCode
            bindButtons[currentRebinding].Text = input.KeyCode.Name
            currentRebinding = nil saveConfig()
        end
        return
    end
    if proc then return end
    local alt = UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) or UserInputService:IsKeyDown(Enum.KeyCode.RightAlt)
    if alt then
        if input.KeyCode == binds.Rejoin then
            if #game.Players:GetPlayers() <= 1 then TeleportService:Teleport(game.PlaceId, player) else TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player) end
        elseif input.KeyCode == binds.SaveWP then addWaypoint()
        elseif input.KeyCode == binds.DeleteWP then deleteLastWaypoint()
        elseif input.KeyCode == binds.AimToggle then aimbotActiveState = not aimbotActiveState
        elseif input.KeyCode == binds.Reload then ScreenGui:Destroy() loadstring(game:HttpGet("https://githubusercontent.com"))()
        elseif input.KeyCode == binds.Ghost then ghostMode = not ghostMode MainFrame.Visible = not ghostMode
        elseif input.KeyCode == binds.Minimize then
            minimized = not minimized
            if minimized then MainFrame.Size = UDim2.new(0, 280, 0, 35) TabBar.Visible = false ContentFrame.Visible = false else MainFrame.Size = UDim2.new(0, 280, 0, 260) TabBar.Visible = true ContentFrame.Visible = true end
        end
    end
end)

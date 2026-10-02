local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local TabBar = Instance.new("Frame")
local ContentFrame = Instance.new("Frame")
local UICorner = Instance.new("UICorner")
local TitleCorner = Instance.new("UICorner")

local MainTabBtn = Instance.new("TextButton")
local WPTabBtn = Instance.new("TextButton")
local KBTabBtn = Instance.new("TextButton")

local MainContent = Instance.new("Frame")
local ToggleButton = Instance.new("TextButton")
local ButtonCorner1 = Instance.new("UICorner")
local AimbotButton = Instance.new("TextButton")
local ButtonCornerA = Instance.new("UICorner")

local WPContent = Instance.new("Frame")
local WPScroll = Instance.new("ScrollingFrame")
local WPLayout = Instance.new("UIListLayout")

local KBContent = Instance.new("Frame")
local KBScroll = Instance.new("ScrollingFrame")
local KBLayout = Instance.new("UIListLayout")

ScreenGui.Name = "PrisonLifePremiumHub"
ScreenGui.Parent = game.CoreGui
ScreenGui.ResetOnSpawn = false

MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.Position = UDim2.new(0.1, 0, 0.2, 0)
MainFrame.Size = UDim2.new(0, 260, 0, 240)
MainFrame.Active = true
MainFrame.Draggable = true
UICorner.Parent = MainFrame

Title.Name = "Title"
Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
Title.Size = UDim2.new(1, 0, 0, 35)
Title.Font = Enum.Font.SourceSansBold
Title.Text = "Prison Life Premium Hub"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 16
TitleCorner.Parent = Title

TabBar.Name = "TabBar"
TabBar.Parent = MainFrame
TabBar.BackgroundTransparency = 1
TabBar.Position = UDim2.new(0, 0, 0, 35)
TabBar.Size = UDim2.new(1, 0, 0, 30)

MainTabBtn = Instance.new("TextButton")
MainTabBtn.Name = "MainTabBtn"
MainTabBtn.Parent = TabBar
MainTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
MainTabBtn.BorderSizePixel = 0
MainTabBtn.Size = UDim2.new(0.333, 0, 1, 0)
MainTabBtn.Font = Enum.Font.SourceSansBold
MainTabBtn.Text = "Main"
MainTabBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
MainTabBtn.TextSize = 14

WPTabBtn = Instance.new("TextButton")
WPTabBtn.Name = "WPTabBtn"
WPTabBtn.Parent = TabBar
WPTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
WPTabBtn.BorderSizePixel = 0
WPTabBtn.Position = UDim2.new(0.333, 0, 0, 0)
WPTabBtn.Size = UDim2.new(0.333, 0, 1, 0)
WPTabBtn.Font = Enum.Font.SourceSansBold
WPTabBtn.Text = "Waypoints"
WPTabBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
WPTabBtn.TextSize = 14

KBTabBtn = Instance.new("TextButton")
KBTabBtn.Name = "KBTabBtn"
KBTabBtn.Parent = TabBar
KBTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
KBTabBtn.BorderSizePixel = 0
KBTabBtn.Position = UDim2.new(0.666, 0, 0, 0)
KBTabBtn.Size = UDim2.new(0.334, 0, 1, 0)
KBTabBtn.Font = Enum.Font.SourceSansBold
KBTabBtn.Text = "Keybinds"
KBTabBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
KBTabBtn.TextSize = 14

ContentFrame.Name = "ContentFrame"
ContentFrame.Parent = MainFrame
ContentFrame.BackgroundTransparency = 1
ContentFrame.Position = UDim2.new(0, 0, 0, 65)
ContentFrame.Size = UDim2.new(1, 0, 1, -65)

local function setupContentFrame(frame, parent)
    frame.Parent = parent
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.Visible = false
end

setupContentFrame(MainContent, ContentFrame)
setupContentFrame(WPContent, ContentFrame)
setupContentFrame(KBContent, ContentFrame)

MainContent.Visible = true
MainTabBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
MainTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

ToggleButton.Name = "ToggleButton"
ToggleButton.Parent = MainContent
ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
ToggleButton.Position = UDim2.new(0.1, 0, 0.15, 0)
ToggleButton.Size = UDim2.new(0, 208, 0, 35)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.Text = "Bypass TP: OFF"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 16
ButtonCorner1.Parent = ToggleButton

AimbotButton.Name = "AimbotButton"
AimbotButton.Parent = MainContent
AimbotButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
AimbotButton.Position = UDim2.new(0.1, 0, 0.45, 0)
AimbotButton.Size = UDim2.new(0, 208, 0, 35)
AimbotButton.Font = Enum.Font.SourceSansBold
AimbotButton.Text = "Smart Aimbot: OFF"
AimbotButton.TextColor3 = Color3.fromRGB(255, 255, 255)
AimbotButton.TextSize = 16
ButtonCornerA.Parent = AimbotButton

WPScroll.Name = "WPScroll"
WPScroll.Parent = WPContent
WPScroll.BackgroundTransparency = 1
WPScroll.Position = UDim2.new(0, 10, 0, 10)
WPScroll.Size = UDim2.new(1, -20, 1, -20)
WPScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
WPScroll.ScrollBarThickness = 4
WPLayout.Parent = WPScroll
WPLayout.SortOrder = Enum.SortOrder.LayoutOrder
WPLayout.Padding = UDim.new(0, 5)

KBScroll.Name = "KBScroll"
KBScroll.Parent = KBContent
KBScroll.BackgroundTransparency = 1
KBScroll.Position = UDim2.new(0, 10, 0, 10)
KBScroll.Size = UDim2.new(1, -20, 1, -20)
KBScroll.CanvasSize = UDim2.new(0, 0, 0, 220)
KBScroll.ScrollBarThickness = 4
KBLayout.Parent = KBScroll
KBLayout.SortOrder = Enum.SortOrder.LayoutOrder
KBLayout.Padding = UDim.new(0, 5)

local binds = {
    ClickTP = Enum.KeyCode.Q,
    SaveWP = Enum.KeyCode.Y,
    DeleteWP = Enum.KeyCode.T,
    Rejoin = Enum.KeyCode.R,
    Ghost = Enum.KeyCode.G,
    Minimize = Enum.KeyCode.M
}

local currentRebinding = nil

local function createBindRow(actionName, displayName)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 32)
    frame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    frame.Parent = KBScroll
    
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 4)
    c.Parent = frame

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.6, 0, 1, 0)
    lbl.Position = UDim2.new(0, 5, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.SourceSansBold
    lbl.Text = displayName
    lbl.TextColor3 = Color3.fromRGB(230, 230, 230)
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.35, 0, 0.8, 0)
    btn.Position = UDim2.new(0.62, 0, 0.1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(65, 65, 65)
    btn.Font = Enum.Font.SourceSansBold
    btn.Text = binds[actionName].Name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 12
    btn.Parent = frame

    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 4)
    bc.Parent = btn

    btn.MouseButton1Click:Connect(function()
        if currentRebinding then return end
        currentRebinding = actionName
        btn.Text = "..."
        btn.BackgroundColor3 = Color3.fromRGB(100, 80, 40)
    end)

    return btn, actionName
end

local bindButtons = {}
bindButtons["ClickTP"] = createBindRow("ClickTP", "Hold Key + Click TP")
bindButtons["SaveWP"] = createBindRow("SaveWP", "Alt + Key: Save Position")
bindButtons["DeleteWP"] = createBindRow("DeleteWP", "Alt + Key: Delete Last Position")
bindButtons["Rejoin"] = createBindRow("Rejoin", "Alt + Key: Quick Rejoin")
bindButtons["Ghost"] = createBindRow("Ghost", "Alt + Key: Ghost Mode Toggle")
bindButtons["Minimize"] = createBindRow("Minimize", "Alt + Key: Minimize GUI")

local function switchTab(activeBtn, activeContent)
    MainContent.Visible = false
    WPContent.Visible = false
    KBContent.Visible = false
    MainTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    WPTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    KBTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    MainTabBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    WPTabBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    KBTabBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    
    activeContent.Visible = true
    activeBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
    activeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
end

MainTabBtn.MouseButton1Click:Connect(function() switchTab(MainTabBtn, MainContent) end)
WPTabBtn.MouseButton1Click:Connect(function() switchTab(WPTabBtn, WPContent) end)
KBTabBtn.MouseButton1Click:Connect(function() switchTab(KBTabBtn, KBContent) end)

local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local camera = workspace.CurrentCamera

local tpEnabled = false
local aimbotEnabled = false
local ghostMode = false
local minimized = false
local waypoints = {}
local wpCount = 0
local aimMaxDistance = 250

ToggleButton.MouseButton1Click:Connect(function()
    tpEnabled = not tpEnabled
    if tpEnabled then
        ToggleButton.Text = "Bypass TP: ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
    else
        ToggleButton.Text = "Bypass TP: OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    end
end)

AimbotButton.MouseButton1Click:Connect(function()
    aimbotEnabled = not aimbotEnabled
    if aimbotEnabled then
        AimbotButton.Text = "Smart Aimbot: ON"
        AimbotButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
    else
        AimbotButton.Text = "Smart Aimbot: OFF"
        AimbotButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    end
end)

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


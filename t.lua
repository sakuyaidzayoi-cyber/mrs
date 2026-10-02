local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local ToggleButton = Instance.new("TextButton")
local UICorner = Instance.new("UICorner")
local ButtonCorner = Instance.new("UICorner")

ScreenGui.Name = "BypassClickTP"
ScreenGui.Parent = game.CoreGui
ScreenGui.ResetOnSpawn = false

MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.Position = UDim2.new(0.1, 0, 0.2, 0)
MainFrame.Size = UDim2.new(0, 200, 0, 130)
MainFrame.Active = true
MainFrame.Draggable = true
UICorner.Parent = MainFrame

Title.Name = "Title"
Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
Title.Size = UDim2.new(1, 0, 0, 35)
Title.Font = Enum.Font.SourceSansBold
Title.Text = "Prison Life: Anti-Cheat Bypass"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 14
local TitleCorner = Instance.new("UICorner")
TitleCorner.Parent = Title

ToggleButton.Name = "ToggleButton"
ToggleButton.Parent = MainFrame
ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
ToggleButton.Position = UDim2.new(0.1, 0, 0.45, 0)
ToggleButton.Size = UDim2.new(0, 160, 0, 45)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.Text = "Bypass TP: OFF"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 18
ButtonCorner.Parent = ToggleButton

local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local tpEnabled = false

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
        if not tpEnabled then break end
        currentPos = currentPos + (direction * maxStep)
        hrp.CFrame = CFrame.new(currentPos)
        task.wait(0.03)
    end

    if tpEnabled then
        hrp.CFrame = CFrame.new(targetPos)
    end
end

mouse.Button1Down:Connect(function()
    if tpEnabled and mouse.Target then
        local targetPos = mouse.Hit.p + Vector3.new(0, 3, 0)
        safeTeleport(targetPos)
    end
end)

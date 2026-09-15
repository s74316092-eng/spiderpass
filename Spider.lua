local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local MarketplaceService= game:GetService("MarketplaceService")
local RunService        = game:GetService("RunService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

if playerGui:FindFirstChild("Spider") then
    playerGui.Spider:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "Spider"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

local isMobile = UserInputService.TouchEnabled
local PASSWORD = "spidergamepass"

local connections = {}
local function connect(signal, callback)
    local conn = signal:Connect(callback)
    table.insert(connections, conn)
    return conn
end

local function corner(parent, radius)
    local c = Instance.new("UICorner", parent)
    c.CornerRadius = UDim.new(0, radius or 8)
    return c
end

local function stroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke", parent)
    s.Color = color or Color3.fromRGB(180, 0, 0)
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Transparency = transparency or 0.2
    return s
end

local function glowStroke(parent, c1, c2, thickness)
    local s = Instance.new("UIStroke", parent)
    s.Thickness = thickness or 1.2
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Transparency = 0.1
    local g = Instance.new("UIGradient", s)
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, c1),
        ColorSequenceKeypoint.new(1, c2)
    })
    g.Rotation = 45
    return s
end

local function applyGradient(frame, c1, c2, rotation)
    local g = Instance.new("UIGradient", frame)
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, c1),
        ColorSequenceKeypoint.new(1, c2)
    })
    g.Rotation = rotation or 45
    return g
end

local function applyTextGradient(label, c1, c2)
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    local g = Instance.new("UIGradient", label)
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, c1),
        ColorSequenceKeypoint.new(1, c2)
    })
    g.Rotation = 0
    return g
end

local function getTime()
    return os.date("%H:%M:%S")
end

local function hoverEffect(btn, activeBg, inactiveBg, activeStroke, inactiveStroke)
    local scale = Instance.new("UIScale", btn)
    scale.Scale = 1
    local uistroke = btn:FindFirstChildOfClass("UIStroke")
    local function valid()
        return btn.Text == "BUY" or btn.Text == "VERIFY" or btn.Text == "GET KEY"
            or btn.Text == "BUY ALL" or btn.Text == "AUTOMATIC" or btn.Text == "MANUAL"
    end
    btn.MouseEnter:Connect(function()
        if not valid() then return end
        TweenService:Create(scale, TweenInfo.new(0.2), {Scale = 1.04}):Play()
        if typeof(activeBg) == "Color3" then
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = activeBg}):Play()
        end
        if uistroke and activeStroke then
            TweenService:Create(uistroke, TweenInfo.new(0.15), {Color = activeStroke}):Play()
        end
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(scale, TweenInfo.new(0.2), {Scale = 1}):Play()
        if not valid() then return end
        if typeof(inactiveBg) == "Color3" then
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = inactiveBg}):Play()
        end
        if uistroke and inactiveStroke then
            TweenService:Create(uistroke, TweenInfo.new(0.15), {Color = inactiveStroke}):Play()
        end
    end)
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            TweenService:Create(scale, TweenInfo.new(0.08), {Scale = 0.95}):Play()
        end
    end)
    btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            TweenService:Create(scale, TweenInfo.new(0.15), {Scale = 1.04}):Play()
        end
    end)
end

local function bindTextBoxFocus(box, activeBg, inactiveBg, activeStroke, inactiveStroke)
    local s = box:FindFirstChildOfClass("UIStroke")
    box.Focused:Connect(function()
        TweenService:Create(box, TweenInfo.new(0.2), {BackgroundColor3 = activeBg}):Play()
        if s and activeStroke then TweenService:Create(s, TweenInfo.new(0.2), {Color = activeStroke}):Play() end
    end)
    box.FocusLost:Connect(function()
        TweenService:Create(box, TweenInfo.new(0.25), {BackgroundColor3 = inactiveBg}):Play()
        if s and inactiveStroke then TweenService:Create(s, TweenInfo.new(0.25), {Color = inactiveStroke}):Play() end
    end)
end

local function transitionText(label, newText, newColor, duration)
    duration = duration or 0.12
    local t = TweenService:Create(label, TweenInfo.new(duration), {TextTransparency = 1})
    t:Play()
    t.Completed:Connect(function()
        label.Text = newText
        if newColor then label.TextColor3 = newColor end
        TweenService:Create(label, TweenInfo.new(duration), {TextTransparency = 0}):Play()
    end)
end

local function createPulse(parent, color)
    local pulse = Instance.new("Frame", parent)
    pulse.AnchorPoint = Vector2.new(0.5, 0.5)
    pulse.Position = UDim2.new(0.5, 0, 0.5, 0)
    pulse.Size = UDim2.new(1, 0, 1, 0)
    pulse.BackgroundColor3 = color
    pulse.BorderSizePixel = 0
    pulse.ZIndex = parent.ZIndex - 1
    corner(pulse, 999)
    task.spawn(function()
        while pulse and pulse.Parent do
            pulse.Size = UDim2.new(1, 0, 1, 0)
            pulse.BackgroundTransparency = 0.4
            TweenService:Create(pulse, TweenInfo.new(1.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(2.5, 0, 2.5, 0),
                BackgroundTransparency = 1
            }):Play()
            task.wait(1.8)
        end
    end)
    return pulse
end

local suppressCounter = 0
local addLog

local function fireFakeSignal(kind, id)
    suppressCounter = suppressCounter + 1
    pcall(function()
        if kind == "Product" then
            MarketplaceService:SignalPromptProductPurchaseFinished(player.UserId, id, true)
        elseif kind == "Gamepass" then
            MarketplaceService:SignalPromptGamePassPurchaseFinished(player, id, true)
        elseif kind == "Bulk" then
            MarketplaceService:SignalPromptBulkPurchaseFinished(player.UserId, id, true)
        elseif kind == "Purchase" then
            MarketplaceService:SignalPromptPurchaseFinished(player.UserId, id, true)
        end
    end)
    suppressCounter = suppressCounter - 1

    if addLog then
        addLog(kind, id, kind)
    end
end

local keyWindow = Instance.new("Frame")
keyWindow.Name = "KeySystem"
keyWindow.Size = UDim2.new(0, 360, 0, 240)
keyWindow.Position = UDim2.new(0.5, -180, 0.5, -120)
keyWindow.BackgroundColor3 = Color3.fromRGB(16, 0, 0)
keyWindow.BackgroundTransparency = 0.1
keyWindow.BorderSizePixel = 0
keyWindow.ClipsDescendants = true
keyWindow.Parent = screenGui
corner(keyWindow, 14)
glowStroke(keyWindow, Color3.fromRGB(200, 0, 0), Color3.fromRGB(255, 50, 50), 1.5)

local keyTitleText = Instance.new("TextLabel")
keyTitleText.Size = UDim2.new(1, 0, 0, 50)
keyTitleText.Position = UDim2.new(0, 0, 0, 12)
keyTitleText.BackgroundTransparency = 1
keyTitleText.Text = "Spider Authenticator"
keyTitleText.TextSize = 18
keyTitleText.Font = Enum.Font.GothamBold
keyTitleText.Parent = keyWindow
applyTextGradient(keyTitleText, Color3.fromRGB(200, 0, 0), Color3.fromRGB(255, 50, 50))

local keySubText = Instance.new("TextLabel")
keySubText.Size = UDim2.new(1, 0, 0, 20)
keySubText.Position = UDim2.new(0, 0, 0, 55)
keySubText.BackgroundTransparency = 1
keySubText.Text = "Enter the password to access Spider"
keySubText.TextColor3 = Color3.fromRGB(180, 100, 100)
keySubText.TextSize = 11
keySubText.Font = Enum.Font.Gotham
keySubText.Parent = keyWindow

local keyBox = Instance.new("TextBox")
keyBox.Size = UDim2.new(0, 280, 0, 42)
keyBox.Position = UDim2.new(0.5, -140, 0, 90)
keyBox.BackgroundColor3 = Color3.fromRGB(30, 5, 5)
keyBox.Text = ""
keyBox.PlaceholderText = "Enter password..."
keyBox.PlaceholderColor3 = Color3.fromRGB(150, 80, 80)
keyBox.TextColor3 = Color3.fromRGB(255, 200, 200)
keyBox.TextSize = 12
keyBox.Font = Enum.Font.Code
keyBox.BorderSizePixel = 0
keyBox.ClipsDescendants = true
keyBox.Parent = keyWindow
corner(keyBox, 8)
stroke(keyBox, Color3.fromRGB(150, 50, 50), 1)
bindTextBoxFocus(keyBox, Color3.fromRGB(20, 0, 0), Color3.fromRGB(30, 5, 5), Color3.fromRGB(200, 0, 0), Color3.fromRGB(150, 50, 50))

local verifyBtn = Instance.new("TextButton")
verifyBtn.Size = UDim2.new(0, 120, 0, 36)
verifyBtn.Position = UDim2.new(0.5, -130, 0, 155)
verifyBtn.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
verifyBtn.Text = "VERIFY"
verifyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
verifyBtn.TextSize = 13
verifyBtn.Font = Enum.Font.GothamBold
verifyBtn.BorderSizePixel = 0
verifyBtn.Parent = keyWindow
corner(verifyBtn, 8)
stroke(verifyBtn, Color3.fromRGB(220, 50, 50), 1)

local getKeyBtn = Instance.new("TextButton")
getKeyBtn.Size = UDim2.new(0, 120, 0, 36)
getKeyBtn.Position = UDim2.new(0.5, 5, 0, 155)
getKeyBtn.BackgroundColor3 = Color3.fromRGB(30, 5, 5)
getKeyBtn.Text = "GET KEY"
getKeyBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
getKeyBtn.TextSize = 13
getKeyBtn.Font = Enum.Font.GothamBold
getKeyBtn.BorderSizePixel = 0
getKeyBtn.Parent = keyWindow
corner(getKeyBtn, 8)
stroke(getKeyBtn, Color3.fromRGB(150, 50, 50), 1)

local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, 0, 0, 20)
infoLabel.Position = UDim2.new(0, 0, 0, 205)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = "Status: Awaiting password..."
infoLabel.TextColor3 = Color3.fromRGB(180, 100, 100)
infoLabel.TextSize = 10
infoLabel.Font = Enum.Font.Gotham
infoLabel.Parent = keyWindow

hoverEffect(verifyBtn, Color3.fromRGB(220, 20, 20), Color3.fromRGB(180, 0, 0), Color3.fromRGB(255, 80, 80), Color3.fromRGB(220, 50, 50))
hoverEffect(getKeyBtn, Color3.fromRGB(40, 10, 10), Color3.fromRGB(30, 5, 5), Color3.fromRGB(255, 50, 50), Color3.fromRGB(150, 50, 50))

getKeyBtn.MouseButton1Click:Connect(function()
    pcall(function() setclipboard("https://s74316092-eng.github.io/Spiderchave/") end)
    transitionText(infoLabel, "Key link copied to clipboard!", Color3.fromRGB(255, 50, 50))
    task.wait(2)
    if infoLabel.Parent then
        transitionText(infoLabel, "Status: Awaiting password...", Color3.fromRGB(180, 100, 100))
    end
end)

local function checkPassword(txt)
    local c = string.lower(string.gsub(string.gsub(txt, "^%s+", ""), "%s+$", ""))
    return c == PASSWORD
end

local modeWindow = Instance.new("Frame")
modeWindow.Name = "ModeSelect"
modeWindow.Size = UDim2.new(0, 360, 0, 220)
modeWindow.Position = UDim2.new(0.5, -180, 0.5, -110)
modeWindow.BackgroundColor3 = Color3.fromRGB(16, 0, 0)
modeWindow.BackgroundTransparency = 0.1
modeWindow.BorderSizePixel = 0
modeWindow.ClipsDescendants = true
modeWindow.Visible = false
modeWindow.Parent = screenGui
corner(modeWindow, 14)
glowStroke(modeWindow, Color3.fromRGB(200, 0, 0), Color3.fromRGB(255, 50, 50), 1.5)

local modeTitle = Instance.new("TextLabel")
modeTitle.Size = UDim2.new(1, 0, 0, 40)
modeTitle.Position = UDim2.new(0, 0, 0, 16)
modeTitle.BackgroundTransparency = 1
modeTitle.Text = "Select Mode"
modeTitle.TextSize = 20
modeTitle.Font = Enum.Font.GothamBold
modeTitle.Parent = modeWindow
applyTextGradient(modeTitle, Color3.fromRGB(200, 0, 0), Color3.fromRGB(255, 50, 50))

local modeSub = Instance.new("TextLabel")
modeSub.Size = UDim2.new(1, 0, 0, 20)
modeSub.Position = UDim2.new(0, 0, 0, 58)
modeSub.BackgroundTransparency = 1
modeSub.Text = "Choose how Spider should run"
modeSub.TextColor3 = Color3.fromRGB(180, 100, 100)
modeSub.TextSize = 11
modeSub.Font = Enum.Font.Gotham
modeSub.Parent = modeWindow

local autoBtn = Instance.new("TextButton")
autoBtn.Size = UDim2.new(0, 140, 0, 70)
autoBtn.Position = UDim2.new(0.5, -150, 0, 100)
autoBtn.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
autoBtn.Text = "AUTOMATIC"
autoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
autoBtn.TextSize = 14
autoBtn.Font = Enum.Font.GothamBold
autoBtn.BorderSizePixel = 0
autoBtn.Parent = modeWindow
corner(autoBtn, 10)
stroke(autoBtn, Color3.fromRGB(220, 50, 50), 1)
hoverEffect(autoBtn, Color3.fromRGB(220, 20, 20), Color3.fromRGB(180, 0, 0), Color3.fromRGB(255, 80, 80), Color3.fromRGB(220, 50, 50))

local manualBtn = Instance.new("TextButton")
manualBtn.Size = UDim2.new(0, 140, 0, 70)
manualBtn.Position = UDim2.new(0.5, 10, 0, 100)
manualBtn.BackgroundColor3 = Color3.fromRGB(40, 8, 8)
manualBtn.Text = "MANUAL"
manualBtn.TextColor3 = Color3.fromRGB(255, 200, 200)
manualBtn.TextSize = 14
manualBtn.Font = Enum.Font.GothamBold
manualBtn.BorderSizePixel = 0
manualBtn.Parent = modeWindow
corner(manualBtn, 10)
stroke(manualBtn, Color3.fromRGB(150, 50, 50), 1)
hoverEffect(manualBtn, Color3.fromRGB(70, 15, 15), Color3.fromRGB(40, 8, 8), Color3.fromRGB(255, 50, 50), Color3.fromRGB(150, 50, 50))

do
    local dragging, dragStart, startPos
    modeWindow.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = modeWindow.Position
        end
    end)
    connect(UserInputService.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            modeWindow.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

local panelSize = isMobile and UDim2.new(0.65, 0, 0.45, 0) or UDim2.new(0, 480, 0, 380)
local fontSizeScale = isMobile and 0.8 or 1
local buttonHeight = isMobile and 28 or 22
local titleBarHeight = isMobile and 30 or 34
local panelPosition = UDim2.new(0.5, 0, 0.25, 0)

local autoPanel = Instance.new("Frame")
autoPanel.Name = "AutoPanel"
autoPanel.Size = panelSize
autoPanel.Position = panelPosition
autoPanel.AnchorPoint = Vector2.new(0.5, 0)
autoPanel.BackgroundColor3 = Color3.fromRGB(16, 0, 0)
autoPanel.BackgroundTransparency = 0.3
autoPanel.BorderSizePixel = 0
autoPanel.Visible = false
autoPanel.ClipsDescendants = true
autoPanel.Parent = screenGui
corner(autoPanel, 14)
glowStroke(autoPanel, Color3.fromRGB(200, 0, 0), Color3.fromRGB(255, 50, 50), 1.5)

local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, titleBarHeight)
titleBar.BackgroundColor3 = Color3.fromRGB(24, 0, 0)
titleBar.BackgroundTransparency = 0.3
titleBar.BorderSizePixel = 0
titleBar.Parent = autoPanel

local sep = Instance.new("Frame")
sep.Size = UDim2.new(1, 0, 0, 1)
sep.Position = UDim2.new(0, 0, 1, -1)
sep.BorderSizePixel = 0
sep.Parent = titleBar
applyGradient(sep, Color3.fromRGB(200, 0, 0), Color3.fromRGB(255, 50, 50))

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, 0, 1, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "Spider — Auto"
titleText.TextSize = 13 * fontSizeScale
titleText.Font = Enum.Font.GothamBold
titleText.Parent = titleBar
applyTextGradient(titleText, Color3.fromRGB(200, 0, 0), Color3.fromRGB(255, 50, 50))

local function makeIconBtn(parent, txt, xOff, color, strokeColor)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 20, 0, 20)
    b.Position = UDim2.new(1, xOff, 0.5, 0)
    b.AnchorPoint = Vector2.new(1, 0.5)
    b.BackgroundColor3 = color
    b.Text = txt
    b.TextColor3 = strokeColor
    b.TextSize = 10 * fontSizeScale
    b.Font = Enum.Font.GothamBold
    b.BorderSizePixel = 0
    b.ZIndex = 10
    b.Parent = parent
    corner(b, 999)
    stroke(b, strokeColor, 1)
    return b
end

local backFromAuto = makeIconBtn(titleBar, "<", -56, Color3.fromRGB(30, 5, 5), Color3.fromRGB(200, 100, 100))
local minBtn      = makeIconBtn(titleBar, "-", -32, Color3.fromRGB(30, 5, 5), Color3.fromRGB(200, 100, 100))
local closeBtn    = makeIconBtn(titleBar, "X", -6,  Color3.fromRGB(50, 10, 10), Color3.fromRGB(255, 80, 80))

hoverEffect(minBtn, Color3.fromRGB(40, 10, 10), Color3.fromRGB(30, 5, 5), Color3.fromRGB(200, 0, 0), Color3.fromRGB(150, 50, 50))
hoverEffect(closeBtn, Color3.fromRGB(80, 15, 15), Color3.fromRGB(50, 10, 10), Color3.fromRGB(255, 80, 80), Color3.fromRGB(180, 20, 20))
hoverEffect(backFromAuto, Color3.fromRGB(40, 10, 10), Color3.fromRGB(30, 5, 5), Color3.fromRGB(200, 0, 0), Color3.fromRGB(150, 50, 50))

do
    local dragging, dragStart, startPos
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and not isMobile then
            dragging = true
            dragStart = input.Position
            startPos = autoPanel.Position
        end
    end)
    connect(UserInputService.InputChanged, function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local d = input.Position - dragStart
            autoPanel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
end

local contentContainer = Instance.new("Frame")
contentContainer.Name = "Content"
contentContainer.Size = UDim2.new(1, 0, 1, -titleBarHeight)
contentContainer.Position = UDim2.new(0, 0, 0, titleBarHeight)
contentContainer.BackgroundTransparency = 1
contentContainer.ClipsDescendants = true
contentContainer.Parent = autoPanel

local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, 0, 0, 32)
tabBar.BackgroundColor3 = Color3.fromRGB(20, 5, 5)
tabBar.BackgroundTransparency = 0.2
tabBar.BorderSizePixel = 0
tabBar.Parent = contentContainer

local tabLogs = Instance.new("TextButton")
tabLogs.Size = UDim2.new(0, 80, 1, 0)
tabLogs.BackgroundColor3 = Color3.fromRGB(30, 5, 5)
tabLogs.Text = "Logs"
tabLogs.TextColor3 = Color3.fromRGB(255, 200, 200)
tabLogs.TextSize = 12 * fontSizeScale
tabLogs.Font = Enum.Font.GothamBold
tabLogs.BorderSizePixel = 0
tabLogs.Parent = tabBar
corner(tabLogs, 0)

local tabProducts = Instance.new("TextButton")
tabProducts.Size = UDim2.new(0, 80, 1, 0)
tabProducts.Position = UDim2.new(0, 80, 0, 0)
tabProducts.BackgroundColor3 = Color3.fromRGB(20, 5, 5)
tabProducts.Text = "Products"
tabProducts.TextColor3 = Color3.fromRGB(180, 100, 100)
tabProducts.TextSize = 12 * fontSizeScale
tabProducts.Font = Enum.Font.GothamBold
tabProducts.BorderSizePixel = 0
tabProducts.Parent = tabBar
corner(tabProducts, 0)

local logArea = Instance.new("ScrollingFrame")
logArea.Size = UDim2.new(1, -12, 1, -(32 + 6))
logArea.Position = UDim2.new(0, 6, 0, 32 + 6)
logArea.BackgroundTransparency = 1
logArea.BorderSizePixel = 0
logArea.ScrollBarThickness = isMobile and 4 or 3
logArea.ScrollBarImageColor3 = Color3.fromRGB(200, 0, 0)
logArea.CanvasSize = UDim2.new(0, 0, 0, 0)
logArea.AutomaticCanvasSize = Enum.AutomaticSize.Y
logArea.Parent = contentContainer

local listLayout = Instance.new("UIListLayout", logArea)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, isMobile and 6 or 4)

local logPad = Instance.new("UIPadding", logArea)
logPad.PaddingTop = UDim.new(0, 2)
logPad.PaddingBottom = UDim.new(0, 2)
logPad.PaddingLeft = UDim.new(0, 2)
logPad.PaddingRight = UDim.new(0, 2)

local productArea = Instance.new("ScrollingFrame")
productArea.Size = UDim2.new(1, -12, 1, -(32 + 6))
productArea.Position = UDim2.new(0, 6, 0, 32 + 6)
productArea.BackgroundTransparency = 1
productArea.BorderSizePixel = 0
productArea.ScrollBarThickness = isMobile and 4 or 3
productArea.ScrollBarImageColor3 = Color3.fromRGB(200, 0, 0)
productArea.CanvasSize = UDim2.new(0, 0, 0, 0)
productArea.AutomaticCanvasSize = Enum.AutomaticSize.Y
productArea.Visible = false
productArea.Parent = contentContainer

local productListLayout = Instance.new("UIListLayout", productArea)
productListLayout.SortOrder = Enum.SortOrder.LayoutOrder
productListLayout.Padding = UDim.new(0, isMobile and 6 or 4)

local productPad = Instance.new("UIPadding", productArea)
productPad.PaddingTop = UDim.new(0, 2)
productPad.PaddingBottom = UDim.new(0, 2)
productPad.PaddingLeft = UDim.new(0, 2)
productPad.PaddingRight = UDim.new(0, 2)

local buyAllProductsBtn = Instance.new("TextButton")
buyAllProductsBtn.Size = UDim2.new(1, -4, 0, 30)
buyAllProductsBtn.Position = UDim2.new(0, 2, 0, 2)
buyAllProductsBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
buyAllProductsBtn.Text = "Buy All (loading...)"
buyAllProductsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
buyAllProductsBtn.TextSize = 12 * fontSizeScale
buyAllProductsBtn.Font = Enum.Font.GothamBold
buyAllProductsBtn.BorderSizePixel = 0
buyAllProductsBtn.Parent = productArea
corner(buyAllProductsBtn, 6)
stroke(buyAllProductsBtn, Color3.fromRGB(220, 50, 50), 1)

local developerProducts = {}
local function createProductEntry(devProduct)
    local entry = Instance.new("Frame")
    entry.Name = "ProductEntry"
    entry.Size = UDim2.new(1, -2, 0, isMobile and 60 or 52)
    entry.BackgroundColor3 = Color3.fromRGB(22, 5, 5)
    entry.BackgroundTransparency = 0.3
    entry.BorderSizePixel = 0
    entry.ClipsDescendants = true
    entry.Parent = productArea
    corner(entry, 8)
    stroke(entry, Color3.fromRGB(150, 50, 50), 1, 0.3)

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size = UDim2.new(0, 160, 0, 18)
    nameLbl.Position = UDim2.new(0, 8, 0, 4)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = devProduct.Name or "N/A"
    nameLbl.TextColor3 = Color3.fromRGB(255, 200, 200)
    nameLbl.TextSize = 12 * fontSizeScale
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
    nameLbl.Parent = entry

    local idLbl = Instance.new("TextLabel")
    idLbl.Size = UDim2.new(0, 100, 0, 16)
    idLbl.Position = UDim2.new(0, 8, 0, 24)
    idLbl.BackgroundTransparency = 1
    idLbl.Text = "ID: " .. tostring(devProduct.ProductId)
    idLbl.TextColor3 = Color3.fromRGB(180, 100, 100)
    idLbl.TextSize = 10 * fontSizeScale
    idLbl.Font = Enum.Font.GothamMedium
    idLbl.TextXAlignment = Enum.TextXAlignment.Left
    idLbl.Parent = entry

    local priceLbl = Instance.new("TextLabel")
    priceLbl.Size = UDim2.new(0, 100, 0, 16)
    priceLbl.Position = UDim2.new(0, 8, 0, 40)
    priceLbl.BackgroundTransparency = 1
    priceLbl.Text = "Price: " .. tostring(devProduct.PriceInRobux) .. " R$"
    priceLbl.TextColor3 = Color3.fromRGB(180, 100, 100)
    priceLbl.TextSize = 10 * fontSizeScale
    priceLbl.Font = Enum.Font.GothamMedium
    priceLbl.TextXAlignment = Enum.TextXAlignment.Left
    priceLbl.Parent = entry

    local buyBtn = Instance.new("TextButton")
    buyBtn.Size = UDim2.new(0, 100, 0, 28)
    buyBtn.Position = UDim2.new(1, -106, 0.5, -14)
    buyBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
    buyBtn.Text = "BUY"
    buyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    buyBtn.TextSize = 11 * fontSizeScale
    buyBtn.Font = Enum.Font.GothamBold
    buyBtn.BorderSizePixel = 0
    buyBtn.Parent = entry
    corner(buyBtn, 4)
    stroke(buyBtn, Color3.fromRGB(150, 50, 50), 0.8)

    buyBtn.MouseButton1Click:Connect(function()
        local old = buyBtn.Text
        buyBtn.Text = "BUYING..."
        fireFakeSignal("Product", devProduct.ProductId)
        task.wait(1)
        buyBtn.Text = old
    end)
end

local function loadProducts()
    local ok, products = pcall(function()
        return MarketplaceService:GetDeveloperProductsAsync():GetCurrentPage()
    end)
    if ok then
        developerProducts = products or {}
        for _, c in ipairs(productArea:GetChildren()) do
            if c.Name == "ProductEntry" then c:Destroy() end
        end
        for _, p in ipairs(developerProducts) do createProductEntry(p) end
        buyAllProductsBtn.Text = "Buy All (" .. #developerProducts .. ")"
    else
        buyAllProductsBtn.Text = "Error loading products"
    end
end

loadProducts()

buyAllProductsBtn.MouseButton1Click:Connect(function()
    local old = buyAllProductsBtn.Text
    buyAllProductsBtn.Text = "Processing..."
    for _, p in ipairs(developerProducts) do
        fireFakeSignal("Product", p.ProductId)
        task.wait(0.01)
    end
    buyAllProductsBtn.Text = "Done!"
    task.wait(2)
    buyAllProductsBtn.Text = old
end)

local eventCount = 0
local entries = {}
local function makeEmptyLabel()
    local el = Instance.new("TextLabel")
    el.Name = "EmptyState"
    el.Size = UDim2.new(1, 0, 0, 180)
    el.BackgroundTransparency = 1
    el.Text = ""
    el.TextColor3 = Color3.fromRGB(180, 100, 100)
    el.TextSize = 11 * fontSizeScale
    el.Font = Enum.Font.GothamMedium
    el.TextWrapped = true
    el.LayoutOrder = 99999
    el.Parent = logArea
    return el
end

local function setEmpty(show)
    local e = logArea:FindFirstChild("EmptyState")
    if show and not e then makeEmptyLabel()
    elseif not show and e then e:Destroy() end
end

local function makeSmallBtn(parent)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 48, 0, buttonHeight)
    b.BackgroundColor3 = Color3.fromRGB(30, 5, 5)
    b.Text = "BUY"
    b.TextColor3 = Color3.fromRGB(200, 100, 100)
    b.TextSize = 10 * fontSizeScale
    b.Font = Enum.Font.GothamBold
    b.BorderSizePixel = 0
    b.Parent = parent
    corner(b, 6)
    stroke(b, Color3.fromRGB(150, 50, 50), 1)
    return b
end

addLog = function(label, id, signalType)
    setEmpty(false)

    local entry = Instance.new("Frame")
    entry.Name = "EntryLog"
    entry.Size = UDim2.new(1, -2, 0, 0)
    entry.BackgroundColor3 = Color3.fromRGB(22, 5, 5)
    entry.BackgroundTransparency = 1
    entry.BorderSizePixel = 0
    entry.ClipsDescendants = true
    entry.LayoutOrder = -eventCount
    entry.Parent = logArea
    corner(entry, 8)
    local entryStroke = stroke(entry, Color3.fromRGB(150, 50, 50), 1, 1)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 64, 1, 0)
    lbl.Position = UDim2.new(0, 20, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = string.upper(label)
    lbl.TextColor3 = Color3.fromRGB(200, 100, 100)
    lbl.TextTransparency = 1
    lbl.TextSize = 9 * fontSizeScale
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = entry

    local idEl = Instance.new("TextLabel")
    idEl.Size = UDim2.new(0, 110, 1, 0)
    idEl.Position = UDim2.new(0, 88, 0, 0)
    idEl.BackgroundTransparency = 1
    idEl.Text = tostring(id)
    idEl.TextColor3 = Color3.fromRGB(255, 200, 200)
    idEl.TextTransparency = 1
    idEl.TextSize = 11 * fontSizeScale
    idEl.Font = Enum.Font.Code
    idEl.TextXAlignment = Enum.TextXAlignment.Left
    idEl.TextTruncate = Enum.TextTruncate.AtEnd
    idEl.Parent = entry

    local timeEl = Instance.new("TextLabel")
    timeEl.Size = UDim2.new(0, 50, 1, 0)
    timeEl.Position = UDim2.new(0, 202, 0, 0)
    timeEl.BackgroundTransparency = 1
    timeEl.Text = getTime()
    timeEl.TextColor3 = Color3.fromRGB(150, 80, 80)
    timeEl.TextTransparency = 1
    timeEl.TextSize = 9 * fontSizeScale
    timeEl.Font = Enum.Font.GothamMedium
    timeEl.Parent = entry

    local bf = Instance.new("Frame")
    bf.Size = UDim2.new(0, 60, 1, 0)
    bf.Position = UDim2.new(1, -66, 0, 0)
    bf.BackgroundTransparency = 1
    bf.Parent = entry

    local hl = Instance.new("UIListLayout", bf)
    hl.FillDirection = Enum.FillDirection.Horizontal
    hl.HorizontalAlignment = Enum.HorizontalAlignment.Right
    hl.VerticalAlignment = Enum.VerticalAlignment.Center
    hl.Padding = UDim.new(0, 6)

    local buyBtn = makeSmallBtn(bf)

    local targetH = isMobile and 46 or 38
    TweenService:Create(entry, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = UDim2.new(1, -2, 0, targetH)}):Play()
    TweenService:Create(entry, TweenInfo.new(0.3), {BackgroundTransparency = 0.3}):Play()
    TweenService:Create(entryStroke, TweenInfo.new(0.3), {Transparency = 0.2}):Play()
    TweenService:Create(lbl, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
    TweenService:Create(idEl, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
    TweenService:Create(timeEl, TweenInfo.new(0.3), {TextTransparency = 0}):Play()

    buyBtn.MouseButton1Click:Connect(function()
        fireFakeSignal(signalType, id)
        buyBtn.Text = "BOUGHT!"
        buyBtn.TextColor3 = Color3.fromRGB(0, 255, 0)
        task.wait(1.5)
        if buyBtn.Parent then
            buyBtn.Text = "BUY"
            buyBtn.TextColor3 = Color3.fromRGB(200, 100, 100)
        end
    end)

    eventCount = eventCount + 1
    table.insert(entries, entry)
end

connect(MarketplaceService.PromptProductPurchaseFinished, function(_, id)
    if suppressCounter == 0 then addLog("Product", id, "Product") end
end)
connect(MarketplaceService.PromptGamePassPurchaseFinished, function(_, id)
    if suppressCounter == 0 then addLog("Gamepass", id, "Gamepass") end
end)
connect(MarketplaceService.PromptBulkPurchaseFinished, function(_, id)
    if suppressCounter == 0 then addLog("Bulk", id, "Bulk") end
end)
connect(MarketplaceService.PromptPurchaseFinished, function(_, id)
    if suppressCounter == 0 then addLog("Purchase", id, "Purchase") end
end)

setEmpty(true)

local function switchTab(t)
    if t == "logs" then
        tabLogs.BackgroundColor3 = Color3.fromRGB(30, 5, 5)
        tabLogs.TextColor3 = Color3.fromRGB(255, 200, 200)
        tabProducts.BackgroundColor3 = Color3.fromRGB(20, 5, 5)
        tabProducts.TextColor3 = Color3.fromRGB(180, 100, 100)
        logArea.Visible = true
        productArea.Visible = false
    else
        tabProducts.BackgroundColor3 = Color3.fromRGB(30, 5, 5)
        tabProducts.TextColor3 = Color3.fromRGB(255, 200, 200)
        tabLogs.BackgroundColor3 = Color3.fromRGB(20, 5, 5)
        tabLogs.TextColor3 = Color3.fromRGB(180, 100, 100)
        logArea.Visible = false
        productArea.Visible = true
    end
end
tabLogs.MouseButton1Click:Connect(function() switchTab("logs") end)
tabProducts.MouseButton1Click:Connect(function() switchTab("products") end)
switchTab("logs")

local manualPanel = Instance.new("Frame")
manualPanel.Name = "ManualPanel"
manualPanel.AnchorPoint = Vector2.new(0.5, 0.5)
manualPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
manualPanel.Size = UDim2.new(0, 517, 0, 377)
manualPanel.BackgroundColor3 = Color3.fromRGB(16, 0, 0)
manualPanel.BackgroundTransparency = 0.15
manualPanel.BorderSizePixel = 0
manualPanel.Visible = false
manualPanel.ClipsDescendants = true
manualPanel.Parent = screenGui
corner(manualPanel, 8)
glowStroke(manualPanel, Color3.fromRGB(200, 0, 0), Color3.fromRGB(255, 50, 50), 1.5)

local RED_BG_DARK    = Color3.fromRGB(16, 0, 0)
local RED_BG_MID     = Color3.fromRGB(30, 5, 5)
local RED_BG_LIGHT   = Color3.fromRGB(45, 10, 10)
local RED_ACCENT     = Color3.fromRGB(200, 0, 0)
local RED_ACCENT_2   = Color3.fromRGB(255, 50, 50)
local RED_TEXT       = Color3.fromRGB(255, 200, 200)
local RED_TEXT_DIM   = Color3.fromRGB(180, 100, 100)
local RED_INPUT_TXT  = Color3.fromRGB(255, 100, 100)

do
    local Header = Instance.new("TextLabel")
    Header.TextWrapped = true
    Header.TextColor3 = Color3.fromRGB(255, 255, 255)
    Header.Text = "Spider"
    Header.Name = "Header"
    Header.Size = UDim2.new(0, 197, 0, 19)
    Header.Position = UDim2.new(0.025, 0, 0.031, 0)
    Header.BorderSizePixel = 0
    Header.BackgroundTransparency = 1
    Header.TextXAlignment = Enum.TextXAlignment.Left
    Header.TextSize = 14
    Header.Font = Enum.Font.GothamBold
    Header.TextScaled = true
    Header.Parent = manualPanel
    applyTextGradient(Header, RED_ACCENT, RED_ACCENT_2)

    local manualClose = Instance.new("TextButton")
    manualClose.Size = UDim2.new(0, 20, 0, 20)
    manualClose.Position = UDim2.new(1, -6, 0, 6)
    manualClose.AnchorPoint = Vector2.new(1, 0)
    manualClose.BackgroundColor3 = Color3.fromRGB(50, 10, 10)
    manualClose.Text = "X"
    manualClose.TextColor3 = Color3.fromRGB(255, 80, 80)
    manualClose.TextSize = 10
    manualClose.Font = Enum.Font.GothamBold
    manualClose.BorderSizePixel = 0
    manualClose.Parent = manualPanel
    corner(manualClose, 999)
    stroke(manualClose, Color3.fromRGB(180, 20, 20), 1)
    hoverEffect(manualClose, Color3.fromRGB(80, 15, 15), Color3.fromRGB(50, 10, 10), Color3.fromRGB(255, 80, 80), Color3.fromRGB(180, 20, 20))

    local manualBack = Instance.new("TextButton")
    manualBack.Size = UDim2.new(0, 20, 0, 20)
    manualBack.Position = UDim2.new(1, -32, 0, 6)
    manualBack.AnchorPoint = Vector2.new(1, 0)
    manualBack.BackgroundColor3 = Color3.fromRGB(30, 5, 5)
    manualBack.Text = "<"
    manualBack.TextColor3 = Color3.fromRGB(200, 100, 100)
    manualBack.TextSize = 12
    manualBack.Font = Enum.Font.GothamBold
    manualBack.BorderSizePixel = 0
    manualBack.Parent = manualPanel
    corner(manualBack, 999)
    stroke(manualBack, Color3.fromRGB(150, 50, 50), 1)
    hoverEffect(manualBack, Color3.fromRGB(40, 10, 10), Color3.fromRGB(30, 5, 5), Color3.fromRGB(200, 0, 0), Color3.fromRGB(150, 50, 50))

    local dfgsgdsf = Instance.new("Frame")
    dfgsgdsf.AnchorPoint = Vector2.new(0.5, 0.5)
    dfgsgdsf.BackgroundTransparency = 1
    dfgsgdsf.Position = UDim2.new(0.5, 0, 0.143, 0)
    dfgsgdsf.Name = "TabBar"
    dfgsgdsf.Size = UDim2.new(0, 489, 0, 24)
    dfgsgdsf.BorderSizePixel = 0
    dfgsgdsf.Parent = manualPanel

    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.Padding = UDim.new(0.01, 0)
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.FillDirection = Enum.FillDirection.Horizontal
    UIListLayout.Parent = dfgsgdsf

    local function makeTab(name, label)
        local tab = Instance.new("ImageButton")
        tab.Name = name
        tab.ImageTransparency = 1
        tab.Size = UDim2.new(0, 100, 0, 24)
        tab.BorderSizePixel = 0
        tab.BackgroundColor3 = RED_BG_MID
        tab.Parent = dfgsgdsf
        corner(tab, 6)
        stroke(tab, RED_ACCENT, 1, 0.2)

        local lbl = Instance.new("TextLabel")
        lbl.TextWrapped = true
        lbl.TextColor3 = RED_TEXT
        lbl.Text = label
        lbl.Size = UDim2.new(0, 84, 0, 15)
        lbl.AnchorPoint = Vector2.new(0.5, 0.5)
        lbl.BorderSizePixel = 0
        lbl.BackgroundTransparency = 1
        lbl.Position = UDim2.new(0.5, 0, 0.5, 0)
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 14
        lbl.TextScaled = true
        lbl.Parent = tab
        applyGradient(tab, RED_ACCENT, RED_ACCENT_2, -90)
        return tab
    end

    local ScanTab     = makeTab("ScanTab", "Shop")
    local ActionTab   = makeTab("ActionTab", "Activation")

    local function makeFrame(name, scroll)
        local f
        if scroll then
            f = Instance.new("ScrollingFrame")
            f.AutomaticCanvasSize = Enum.AutomaticSize.Y
            f.CanvasSize = UDim2.new(0, 0, 0, 0)
        else
            f = Instance.new("Frame")
        end
        f.Visible = false
        f.Name = name
        f.Size = UDim2.new(0, 489, 0, 286)
        f.AnchorPoint = Vector2.new(0.5, 0.5)
        f.BackgroundTransparency = 1
        f.Position = UDim2.new(0.5, 0, 0.586, 0)
        f.BorderSizePixel = 0
        f.Parent = manualPanel
        local l = Instance.new("UIListLayout", f)
        l.Padding = UDim.new(0.01, 0)
        l.SortOrder = Enum.SortOrder.LayoutOrder
        return f
    end

    local scannerTabFrame  = makeFrame("ScannerFrame", true)
    local actionTabFrame   = makeFrame("ActionFrame", false)
    actionTabFrame.ClipsDescendants = true

    local actLayout = actionTabFrame:FindFirstChildOfClass("UIListLayout")
    if actLayout then actLayout:Destroy() end

    do
        local dragging, dragStart, startPos
        manualPanel.InputBegan:Connect(function(input)
            if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch)
                and UserInputService:GetFocusedTextBox() == nil then
                dragging = true
                dragStart = input.Position
                startPos = manualPanel.Position
            end
        end)
        connect(UserInputService.InputChanged, function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local d = input.Position - dragStart
                manualPanel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end)
        connect(UserInputService.InputEnded, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
    end

    local function createScannerEntry(pName, pid, price)
        local Entry = Instance.new("Frame")
        Entry.BackgroundTransparency = 0.4
        Entry.Name = "ProductEntry"
        Entry.Size = UDim2.new(0, 464, 0, 48)
        Entry.BorderSizePixel = 0
        Entry.BackgroundColor3 = RED_BG_MID
        Entry.Parent = scannerTabFrame
        corner(Entry, 6)
        stroke(Entry, RED_ACCENT, 1, 0.2)
        applyGradient(Entry, RED_ACCENT, RED_ACCENT_2, -90)

        local nameLbl = Instance.new("TextLabel")
        nameLbl.TextWrapped = true
        nameLbl.Name = "ProductName"
        nameLbl.TextColor3 = RED_TEXT
        nameLbl.Text = pName
        nameLbl.Size = UDim2.new(0, 250, 0, 15)
        nameLbl.Position = UDim2.new(0.3, 0, 0.375, 0)
        nameLbl.AnchorPoint = Vector2.new(0.5, 0.5)
        nameLbl.BorderSizePixel = 0
        nameLbl.BackgroundTransparency = 1
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        nameLbl.TextScaled = true
        nameLbl.Font = Enum.Font.Code
        nameLbl.TextSize = 14
        nameLbl.Parent = Entry

        local idLbl = Instance.new("TextLabel")
        idLbl.TextWrapped = true
        idLbl.Name = "ProductID"
        idLbl.TextColor3 = RED_INPUT_TXT
        idLbl.Text = "ID: " .. tostring(pid)
        idLbl.Size = UDim2.new(0, 250, 0, 15)
        idLbl.Position = UDim2.new(0.3, 0, 0.6875, 0)
        idLbl.AnchorPoint = Vector2.new(0.5, 0.5)
        idLbl.BorderSizePixel = 0
        idLbl.BackgroundTransparency = 1
        idLbl.TextXAlignment = Enum.TextXAlignment.Left
        idLbl.TextScaled = true
        idLbl.Font = Enum.Font.Code
        idLbl.TextSize = 14
        idLbl.Parent = Entry

        local CopyID = Instance.new("ImageButton")
        CopyID.ImageTransparency = 1
        CopyID.AnchorPoint = Vector2.new(0.5, 0.5)
        CopyID.Name = "CopyID"
        CopyID.Position = UDim2.new(0.948, 0, 0.5, 0)
        CopyID.Size = UDim2.new(0, 30, 0, 30)
        CopyID.BorderSizePixel = 0
        CopyID.BackgroundColor3 = RED_BG_LIGHT
        CopyID.Parent = Entry
        corner(CopyID, 6)
        stroke(CopyID, RED_ACCENT, 1, 0.2)

        local Ico3 = Instance.new("ImageLabel")
        Ico3.ImageColor3 = RED_TEXT
        Ico3.Name = "Ico"
        Ico3.Size = UDim2.new(0, 26, 0, 26)
        Ico3.AnchorPoint = Vector2.new(0.5, 0.5)
        Ico3.Image = "rbxassetid://16884178261"
        Ico3.BackgroundTransparency = 1
        Ico3.ImageRectSize = Vector2.new(36, 36)
        Ico3.Position = UDim2.new(0.5, 0, 0.5, 0)
        Ico3.BorderSizePixel = 0
        Ico3.Parent = CopyID

        CopyID.MouseButton1Click:Connect(function()
            pcall(function() setclipboard(tostring(pid)) end)
        end)
    end

    local loadingLbl = Instance.new("TextLabel")
    loadingLbl.Name = "ShopLoading"
    loadingLbl.Size = UDim2.new(0, 464, 0, 40)
    loadingLbl.BackgroundTransparency = 1
    loadingLbl.Text = "Loading products..."
    loadingLbl.TextColor3 = RED_TEXT_DIM
    loadingLbl.TextSize = 14
    loadingLbl.Font = Enum.Font.GothamMedium
    loadingLbl.Parent = scannerTabFrame

    local shopLoaded = false
    local function loadShopProducts()
        if shopLoaded then return end
        shopLoaded = true

        for _, c in ipairs(scannerTabFrame:GetChildren()) do
            if c:IsA("Frame") and c.Name == "ProductEntry" then c:Destroy() end
        end

        local ok, pages = pcall(function()
            return MarketplaceService:GetDeveloperProductsAsync()
        end)

        if loadingLbl then loadingLbl:Destroy() end

        if ok and pages then
            local page = pages:GetCurrentPage()
            while true do
                for _, p in ipairs(page) do
                    createScannerEntry(p.Name or "Unknown", p.ProductId or 0, p.PriceInRobux or 0)
                end
                if pages.IsFinished then break end
                local ok2 = pcall(function() pages:AdvanceToNextPageAsync() end)
                if not ok2 then break end
                page = pages:GetCurrentPage()
            end
        else
            local errLbl = Instance.new("TextLabel")
            errLbl.Size = UDim2.new(0, 464, 0, 30)
            errLbl.BackgroundTransparency = 1
            errLbl.Text = "Failed to load products."
            errLbl.TextColor3 = RED_ACCENT_2
            errLbl.TextSize = 14
            errLbl.Font = Enum.Font.GothamMedium
            errLbl.Parent = scannerTabFrame
        end
    end

    ScanTab.MouseButton1Click:Connect(function()
        ScanTab.BackgroundColor3 = RED_BG_LIGHT
        ActionTab.BackgroundColor3 = RED_BG_MID
        scannerTabFrame.Visible = true
        actionTabFrame.Visible = false
        loadShopProducts()
    end)
    ActionTab.MouseButton1Click:Connect(function()
        ScanTab.BackgroundColor3 = RED_BG_MID
        ActionTab.BackgroundColor3 = RED_BG_LIGHT
        scannerTabFrame.Visible = false
        actionTabFrame.Visible = true
    end)
    ActionTab.BackgroundColor3 = RED_BG_LIGHT
    actionTabFrame.Visible = true

    task.spawn(function()
        task.wait(1)
        loadShopProducts()
    end)

    local grferge = Instance.new("Frame")
    grferge.Active = true
    grferge.BackgroundTransparency = 0.4
    grferge.Name = "InputFrame"
    grferge.Size = UDim2.new(0, 464, 0, 27)
    grferge.Position = UDim2.new(0, 0, 0, 0)
    grferge.BorderSizePixel = 0
    grferge.BackgroundColor3 = RED_BG_MID
    grferge.Parent = actionTabFrame
    corner(grferge, 6)
    stroke(grferge, RED_ACCENT, 1, 0.2)
    applyGradient(grferge, RED_ACCENT, RED_ACCENT_2, -90)

    local ProductIDInput = Instance.new("TextBox")
    ProductIDInput.CursorPosition = -1
    ProductIDInput.AnchorPoint = Vector2.new(0.5, 0.5)
    ProductIDInput.PlaceholderText = "Product ID"
    ProductIDInput.TextSize = 14
    ProductIDInput.Size = UDim2.new(0, 420, 0, 15)
    ProductIDInput.TextColor3 = RED_INPUT_TXT
    ProductIDInput.Text = ""
    ProductIDInput.Name = "ProductIDInput"
    ProductIDInput.Position = UDim2.new(0.514, 0, 0.5, 0)
    ProductIDInput.BorderSizePixel = 0
    ProductIDInput.Font = Enum.Font.Code
    ProductIDInput.BackgroundTransparency = 1
    ProductIDInput.TextXAlignment = Enum.TextXAlignment.Left
    ProductIDInput.ClearTextOnFocus = false
    ProductIDInput.TextScaled = true
    ProductIDInput.PlaceholderColor3 = Color3.fromRGB(180, 100, 100)
    ProductIDInput.Parent = grferge

    local Ico = Instance.new("ImageLabel")
    Ico.Name = "Ico"
    Ico.Size = UDim2.new(0, 15, 0, 15)
    Ico.Position = UDim2.new(0.034, 0, 0.5, 0)
    Ico.AnchorPoint = Vector2.new(0.5, 0.5)
    Ico.Image = "rbxassetid://16167590360"
    Ico.BackgroundTransparency = 1
    Ico.ImageColor3 = RED_ACCENT_2
    Ico.ImageRectSize = Vector2.new(16, 16)
    Ico.ImageRectOffset = Vector2.new(253, 492)
    Ico.BorderSizePixel = 0
    Ico.Parent = grferge

    local BUY_BG_A    = Color3.fromRGB(180, 20, 20)
    local BUY_BG_B    = Color3.fromRGB(220, 45, 45)
    local BUY_STROKE  = Color3.fromRGB(255, 80, 80)
    local BUY_TXT     = Color3.fromRGB(255, 255, 255)
    local BUY_SPAM    = Color3.fromRGB(255, 200, 140)
    local BUY_OK      = Color3.fromRGB(120, 230, 120)
    local BUY_ERR     = Color3.fromRGB(255, 140, 140)

    local BuyContainer = Instance.new("Frame")
    BuyContainer.Name = "BuyContainer"
    BuyContainer.Size = UDim2.new(0, 220, 0, 34)
    BuyContainer.Position = UDim2.new(0.5, -110, 0, 75)
    BuyContainer.BackgroundTransparency = 1
    BuyContainer.BorderSizePixel = 0
    BuyContainer.Parent = actionTabFrame

    local BuyBg = Instance.new("Frame")
    BuyBg.Name = "BuyBg"
    BuyBg.Size = UDim2.new(1, 0, 1, 0)
    BuyBg.Position = UDim2.new(0, 0, 0, 0)
    BuyBg.BackgroundColor3 = BUY_BG_A
    BuyBg.BorderSizePixel = 0
    BuyBg.ZIndex = 1
    BuyBg.Parent = BuyContainer
    corner(BuyBg, 6)
    stroke(BuyBg, BUY_STROKE, 1, 0.2)
    applyGradient(BuyBg, BUY_BG_A, BUY_BG_B, -90)

    local BuyBtn = Instance.new("TextButton")
    BuyBtn.Size = UDim2.new(1, 0, 1, 0)
    BuyBtn.Name = "BuyBtn"
    BuyBtn.Position = UDim2.new(0, 0, 0, 0)
    BuyBtn.BackgroundTransparency = 1
    BuyBtn.Text = "BUY"
    BuyBtn.TextColor3 = BUY_TXT
    BuyBtn.TextSize = 16
    BuyBtn.Font = Enum.Font.GothamBold
    BuyBtn.BorderSizePixel = 0
    BuyBtn.ZIndex = 2
    BuyBtn.Parent = BuyContainer

    local holdStart = nil
    local holdThread = nil
    local spamThread = nil
    local isSpamming = false

    local function fireAll(pid)
        fireFakeSignal("Product",  pid)
        fireFakeSignal("Gamepass", pid)
        fireFakeSignal("Bulk",     pid)
        fireFakeSignal("Purchase", pid)
    end

    local function setBuyText(txt, color)
        BuyBtn.Text = txt
        BuyBtn.TextColor3 = color or BUY_TXT
    end

    local function startSpam(pid)
        if isSpamming then return end
        isSpamming = true
        setBuyText("SPAMMING...", BUY_SPAM)
        spamThread = task.spawn(function()
            while isSpamming and BuyBtn.Parent do
                fireAll(pid)
                task.wait(0.1)
            end
        end)
    end

    local function stopSpam()
        isSpamming = false
        if spamThread then task.cancel(spamThread) end
        if BuyBtn.Parent then
            setBuyText("BUY", BUY_TXT)
        end
    end

    BuyBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local pid = tonumber(ProductIDInput.Text)
            if not pid then
                setBuyText("INVALID ID", BUY_ERR)
                task.wait(1)
                if BuyBtn.Parent then
                    setBuyText("BUY", BUY_TXT)
                end
                return
            end

            holdStart = tick()
            holdThread = task.spawn(function()
                while holdStart and (tick() - holdStart) < 3 do
                    task.wait(0.1)
                end
                if holdStart and not isSpamming then
                    startSpam(pid)
                end
            end)
        end
    end)

    BuyBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local held = holdStart and (tick() - holdStart) or 0
            holdStart = nil
            if holdThread then task.cancel(holdThread) end

            if isSpamming then
                stopSpam()
            elseif held < 3 then
                local pid = tonumber(ProductIDInput.Text)
                if pid then
                    fireAll(pid)
                    setBuyText("BOUGHT!", BUY_OK)
                    task.spawn(function()
                        task.wait(1.5)
                        if BuyBtn.Parent and not isSpamming then
                            setBuyText("BUY", BUY_TXT)
                        end
                    end)
                end
            end
        end
    end)

    manualClose.MouseButton1Click:Connect(function()
        manualPanel.Visible = false
        modeWindow.Visible = true
    end)
    manualBack.MouseButton1Click:Connect(function()
        manualPanel.Visible = false
        modeWindow.Visible = true
    end)
end

backFromAuto.MouseButton1Click:Connect(function()
    autoPanel.Visible = false
    modeWindow.Visible = true
end)
closeBtn.MouseButton1Click:Connect(function()
    autoPanel.Visible = false
    modeWindow.Visible = true
end)

do
    local lastNormalSize = panelSize
    local isMinimized = false
    minBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        if isMinimized then
            minBtn.Text = "+"
            contentContainer.Visible = false
            TweenService:Create(autoPanel, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
                Size = UDim2.new(autoPanel.Size.X.Scale, autoPanel.Size.X.Offset, 0, titleBarHeight)
            }):Play()
        else
            minBtn.Text = "-"
            contentContainer.Visible = true
            TweenService:Create(autoPanel, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
                Size = lastNormalSize
            }):Play()
        end
    end)
end

local function unlockScript()
    transitionText(infoLabel, "Access Granted!", Color3.fromRGB(255, 50, 50))
    task.wait(0.6)
    TweenService:Create(keyWindow, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 360, 0, 0),
        Position = UDim2.new(0.5, -180, 0.5, 0)
    }):Play()
    task.wait(0.4)
    keyWindow:Destroy()
    modeWindow.Visible = true
    modeWindow.Size = UDim2.new(0, 0, 0, 0)
    modeWindow.Position = UDim2.new(0.5, 0, 0.5, 0)
    TweenService:Create(modeWindow, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 360, 0, 220),
        Position = UDim2.new(0.5, -180, 0.5, -110)
    }):Play()
end

verifyBtn.MouseButton1Click:Connect(function()
    if checkPassword(keyBox.Text) then
        unlockScript()
    else
        transitionText(infoLabel, "Access Denied! Invalid Password.", Color3.fromRGB(255, 50, 50))
        local oldBg = keyBox.BackgroundColor3
        local sBox = keyBox:FindFirstChildOfClass("UIStroke")
        local oldS = sBox and sBox.Color
        TweenService:Create(keyBox, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 10, 10)}):Play()
        if sBox then TweenService:Create(sBox, TweenInfo.new(0.2), {Color = Color3.fromRGB(255, 50, 50)}):Play() end
        task.wait(1.5)
        if keyBox.Parent then
            TweenService:Create(keyBox, TweenInfo.new(0.3), {BackgroundColor3 = oldBg}):Play()
            if sBox and oldS then TweenService:Create(sBox, TweenInfo.new(0.3), {Color = oldS}):Play() end
            transitionText(infoLabel, "Status: Awaiting password...", Color3.fromRGB(180, 100, 100))
        end
    end
end)

autoBtn.MouseButton1Click:Connect(function()
    modeWindow.Visible = false
    autoPanel.Visible = true
    autoPanel.Size = UDim2.new(0, 0, 0, 0)
    TweenService:Create(autoPanel, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = panelSize
    }):Play()
end)

manualBtn.MouseButton1Click:Connect(function()
    modeWindow.Visible = false
    manualPanel.Visible = true
    manualPanel.Size = UDim2.new(0, 0, 0, 0)
    TweenService:Create(manualPanel, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 517, 0, 377)
    }):Play()
end)

connect(screenGui.AncestryChanged, function(_, parent)
    if not parent then
        for _, c in ipairs(connections) do
            if c.Connected then c:Disconnect() end
        end
        table.clear(connections)
    end
end)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
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

local function createSpring(stiffness, damping, initialValue)
    return {
        Target = initialValue or 0,
        Position = initialValue or 0,
        Velocity = 0,
        Stiffness = stiffness or 150,
        Damping = damping or 12,
        Update = function(self, dt)
            local steps = math.clamp(math.floor(dt / 0.01) + 1, 1, 10)
            local stepDt = dt / steps
            for i = 1, steps do
                local force = (self.Target - self.Position) * self.Stiffness - self.Velocity * self.Damping
                self.Velocity = self.Velocity + force * stepDt
                self.Position = self.Position + self.Velocity * stepDt
            end
            return self.Position
        end
    }
end

local function createUDim2Spring(stiffness, damping, initialValue)
    local sx = createSpring(stiffness, damping, initialValue.X.Offset)
    local sy = createSpring(stiffness, damping, initialValue.Y.Offset)
    return {
        ScaleX = initialValue.X.Scale,
        ScaleY = initialValue.Y.Scale,
        X = sx,
        Y = sy,
        SetTarget = function(self, target)
            self.ScaleX = target.X.Scale
            self.ScaleY = target.Y.Scale
            self.X.Target = target.X.Offset
            self.Y.Target = target.Y.Offset
        end,
        SetPosition = function(self, pos)
            self.ScaleX = pos.X.Scale
            self.ScaleY = pos.Y.Scale
            self.X.Position = pos.X.Offset
            self.Y.Position = pos.Y.Offset
            self.X.Velocity = 0
            self.Y.Velocity = 0
        end,
        Update = function(self, dt)
            return UDim2.new(self.ScaleX, self.X:Update(dt), self.ScaleY, self.Y:Update(dt))
        end
    }
end

local function corner(parent, radius)
    local c = Instance.new("UICorner", parent)
    c.CornerRadius = UDim.new(0, radius or 8)
    return c
end

local function stroke(parent, color, thickness)
    local s = Instance.new("UIStroke", parent)
    s.Color = color or Color3.fromRGB(180, 0, 0)
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Transparency = 0.2
    return s
end

local function glowStroke(parent, color1, color2, thickness)
    local s = Instance.new("UIStroke", parent)
    s.Thickness = thickness or 1.2
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Transparency = 0.1
    
    local grad = Instance.new("UIGradient", s)
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, color1),
        ColorSequenceKeypoint.new(1, color2)
    })
    grad.Rotation = 45
    return s
end

local function applyGradient(frame, color1, color2)
    local grad = Instance.new("UIGradient", frame)
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, color1),
        ColorSequenceKeypoint.new(1, color2)
    })
    grad.Rotation = 45
    return grad
end

local function applyTextGradient(label, color1, color2)
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    local grad = Instance.new("UIGradient", label)
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, color1),
        ColorSequenceKeypoint.new(1, color2)
    })
    grad.Rotation = 0
    return grad
end

local function getTime()
    return os.date("%H:%M:%S")
end

local function hoverEffect(btn, activeBg, inactiveBg, activeStroke, inactiveStroke)
    local scale = Instance.new("UIScale", btn)
    scale.Scale = 1
    
    local uistroke = btn:FindFirstChildOfClass("UIStroke")
    
    local function isStateValid()
        return btn.Text == "BUY" or btn.Text == "VERIFY" or btn.Text == "GET KEY" or btn.Text == "BUY ALL"
    end

    btn.MouseEnter:Connect(function()
        if not isStateValid() then return end
        TweenService:Create(scale, TweenInfo.new(0.2, Enum.EasingStyle.Out), {Scale = 1.04}):Play()
        if typeof(activeBg) == "Color3" then
            TweenService:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundColor3 = activeBg}):Play()
        end
        if uistroke and activeStroke then
            TweenService:Create(uistroke, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {Color = activeStroke}):Play()
        end
    end)

    btn.MouseLeave:Connect(function()
        TweenService:Create(scale, TweenInfo.new(0.2, Enum.EasingStyle.Out), {Scale = 1}):Play()
        if not isStateValid() then return end
        if typeof(inactiveBg) == "Color3" then
            TweenService:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundColor3 = inactiveBg}):Play()
        end
        if uistroke and inactiveStroke then
            TweenService:Create(uistroke, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {Color = inactiveStroke}):Play()
        end
    end)

    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            TweenService:Create(scale, TweenInfo.new(0.08, Enum.EasingStyle.Out), {Scale = 0.95}):Play()
        end
    end)

    btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local targetScale = (btn.AbsoluteSize ~= Vector2.new() and scale.Scale ~= 0.95) and 1.04 or 1
            TweenService:Create(scale, TweenInfo.new(0.15, Enum.EasingStyle.Out), {Scale = targetScale}):Play()
        end
    end)
end

local function bindTextBoxFocus(box, activeBg, inactiveBg, activeStroke, inactiveStroke)
    local uistroke = box:FindFirstChildOfClass("UIStroke")
    box.Focused:Connect(function()
        TweenService:Create(box, TweenInfo.new(0.2), {BackgroundColor3 = activeBg}):Play()
        if uistroke and activeStroke then
            TweenService:Create(uistroke, TweenInfo.new(0.2), {Color = activeStroke}):Play()
        end
    end)
    box.FocusLost:Connect(function()
        TweenService:Create(box, TweenInfo.new(0.25), {BackgroundColor3 = inactiveBg}):Play()
        if uistroke and inactiveStroke then
            TweenService:Create(uistroke, TweenInfo.new(0.25), {Color = inactiveStroke}):Play()
        end
    end)
end

local function transitionText(label, newText, newColor, duration)
    duration = duration or 0.12
    local fadeOut = TweenService:Create(label, TweenInfo.new(duration, Enum.EasingStyle.Quad), {TextTransparency = 1})
    fadeOut:Play()
    fadeOut.Completed:Connect(function()
        label.Text = newText
        if newColor then label.TextColor3 = newColor end
        TweenService:Create(label, TweenInfo.new(duration, Enum.EasingStyle.Quad), {TextTransparency = 0}):Play()
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
        while pulse and pulse.Parent and screenGui and screenGui.Parent do
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

local panelSize
local fontSizeScale = isMobile and 0.8 or 1
local buttonHeight = isMobile and 28 or 22
local titleBarHeight = isMobile and 30 or 34

if isMobile then
    panelSize = UDim2.new(0.65, 0, 0.45, 0)
else
    panelSize = UDim2.new(0, 480, 0, 380)
end

local panelPosition = UDim2.new(0.5, 0, 0.25, 0)

-- MAIN PANEL (RED THEME)
local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = panelSize
panel.Position = panelPosition
panel.AnchorPoint = Vector2.new(0.5, 0)
panel.BackgroundColor3 = Color3.fromRGB(16, 0, 0)
panel.BackgroundTransparency = 0.3
panel.BorderSizePixel = 0
panel.Visible = false
panel.ClipsDescendants = true
panel.Parent = screenGui
corner(panel, 14)
glowStroke(panel, Color3.fromRGB(200, 0, 0), Color3.fromRGB(255, 50, 50), 1.5)

-- KEY SYSTEM AUTHENTICATOR
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

local shakeSpring = createSpring(250, 14, 0)
local keyWindowPos = keyWindow.Position
local panelTargetPos = panelPosition

local keyDragging = false
local keyDragStart, keyStartPos
keyWindow.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        keyDragging = true
        keyDragStart = input.Position
        keyStartPos = keyWindowPos
    end
end)

connect(UserInputService.InputChanged, function(input)
    if keyDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - keyDragStart
        keyWindowPos = UDim2.new(keyStartPos.X.Scale, keyStartPos.X.Offset + delta.X, keyStartPos.Y.Scale, keyStartPos.Y.Offset + delta.Y)
    end
end)

connect(UserInputService.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        keyDragging = false
    end
end)

getKeyBtn.MouseButton1Click:Connect(function()
    pcall(function()
        setclipboard("https://s74316092-eng.github.io/Spiderchave/")
    end)
    transitionText(infoLabel, "Key link copied to clipboard!", Color3.fromRGB(255, 50, 50))
    task.wait(2)
    if infoLabel.Parent then
        transitionText(infoLabel, "Status: Awaiting password...", Color3.fromRGB(180, 100, 100))
    end
end)

local function checkPassword(inputText)
    local cleaned = string.gsub(inputText, "^%s+", "")
    cleaned = string.gsub(cleaned, "%s+$", "")
    cleaned = string.lower(cleaned)
    return cleaned == PASSWORD
end

local function unlockScript()
    transitionText(infoLabel, "Access Granted! Welcome to Spider.", Color3.fromRGB(255, 50, 50))
    
    TweenService:Create(keyBox, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(20, 5, 5)}):Play()
    local strokeB = keyBox:FindFirstChildOfClass("UIStroke")
    if strokeB then TweenService:Create(strokeB, TweenInfo.new(0.3), {Color = Color3.fromRGB(255, 50, 50)}):Play() end
    
    task.wait(0.6)
    
    local fadeOutInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(keyWindow, fadeOutInfo, {Size = UDim2.new(0, 360, 0, 0), Position = UDim2.new(0.5, -180, 0.5, 0)}):Play()
    
    task.wait(0.4)
    keyWindow:Destroy()
    
    panel.Visible = true
    panel.Size = UDim2.new(0, 0, 0, 0)
    panelTargetPos = panelPosition
    
    local popInfo = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    TweenService:Create(panel, popInfo, {Size = panelSize}):Play()
end

verifyBtn.MouseButton1Click:Connect(function()
    if checkPassword(keyBox.Text) then
        unlockScript()
    else
        transitionText(infoLabel, "Access Denied! Invalid Password.", Color3.fromRGB(255, 50, 50))
        
        shakeSpring.Velocity = 1400
        
        local oldBg = keyBox.BackgroundColor3
        local strokeBox = keyBox:FindFirstChildOfClass("UIStroke")
        local oldStroke = strokeBox and strokeBox.Color
        
        TweenService:Create(keyBox, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 10, 10)}):Play()
        if strokeBox then TweenService:Create(strokeBox, TweenInfo.new(0.2), {Color = Color3.fromRGB(255, 50, 50)}):Play() end
        
        task.wait(1.5)
        
        if keyBox.Parent then
            TweenService:Create(keyBox, TweenInfo.new(0.3), {BackgroundColor3 = oldBg}):Play()
            if strokeBox then TweenService:Create(strokeBox, TweenInfo.new(0.3), {Color = oldStroke}):Play() end
            transitionText(infoLabel, "Status: Awaiting password...", Color3.fromRGB(180, 100, 100))
        end
    end
end)

-- ============================================
-- TITLE BAR
-- ============================================
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, titleBarHeight)
titleBar.BackgroundColor3 = Color3.fromRGB(24, 0, 0)
titleBar.BackgroundTransparency = 0.3
titleBar.BorderSizePixel = 0
titleBar.Parent = panel

local separator = Instance.new("Frame")
separator.Size = UDim2.new(1, 0, 0, 1)
separator.Position = UDim2.new(0, 0, 1, -1)
separator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
separator.BorderSizePixel = 0
separator.Parent = titleBar
applyGradient(separator, Color3.fromRGB(200, 0, 0), Color3.fromRGB(255, 50, 50))

-- Drag logic for main panel
local dragging = false
local dragStart, startPos
titleBar.InputBegan:Connect(function(input)
    if not isMobile and (input.UserInputType == Enum.UserInputType.MouseButton1) then
        dragging = true
        dragStart = input.Position
        startPos = panelTargetPos
    end
end)

connect(UserInputService.InputChanged, function(input)
    if not isMobile and dragging and (input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStart
        panelTargetPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

connect(UserInputService.InputEnded, function(input)
    if not isMobile and (input.UserInputType == Enum.UserInputType.MouseButton1) then
        if dragging then
            dragging = false
            panelPosition = panelTargetPos
        end
    end
end)

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, 0, 1, 0)
titleText.Position = UDim2.new(0, 0, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "Spider"
titleText.TextSize = 13 * fontSizeScale
titleText.Font = Enum.Font.GothamBold
titleText.ZIndex = titleBar.ZIndex + 2
titleText.Parent = titleBar
applyTextGradient(titleText, Color3.fromRGB(200, 0, 0), Color3.fromRGB(255, 50, 50))

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 20, 0, 20)
closeBtn.Position = UDim2.new(1, -6, 0.5, 0)
closeBtn.AnchorPoint = Vector2.new(1, 0.5)
closeBtn.BackgroundColor3 = Color3.fromRGB(50, 10, 10)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
closeBtn.TextSize = 10 * fontSizeScale
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
closeBtn.ZIndex = 10
closeBtn.Parent = titleBar
corner(closeBtn, 999)
stroke(closeBtn, Color3.fromRGB(180, 20, 20), 1)

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 20, 0, 20)
minBtn.Position = UDim2.new(1, -32, 0.5, 0)
minBtn.AnchorPoint = Vector2.new(1, 0.5)
minBtn.BackgroundColor3 = Color3.fromRGB(30, 5, 5)
minBtn.Text = "-"
minBtn.TextColor3 = Color3.fromRGB(200, 100, 100)
minBtn.TextSize = 12 * fontSizeScale
minBtn.Font = Enum.Font.GothamBold
minBtn.BorderSizePixel = 0
minBtn.ZIndex = 10
minBtn.Parent = titleBar
corner(minBtn, 999)
stroke(minBtn, Color3.fromRGB(150, 50, 50), 1)

hoverEffect(closeBtn, Color3.fromRGB(80, 15, 15), Color3.fromRGB(50, 10, 10), Color3.fromRGB(255, 80, 80), Color3.fromRGB(180, 20, 20))
hoverEffect(minBtn, Color3.fromRGB(40, 10, 10), Color3.fromRGB(30, 5, 5), Color3.fromRGB(200, 0, 0), Color3.fromRGB(150, 50, 50))

-- Resize handle (desktop only)
local resizeHandle = nil
local resizing = false
local lastNormalSize = panelSize
local isMinimized = false

if not isMobile then
    resizeHandle = Instance.new("Frame")
    resizeHandle.Name = "ResizeHandle"
    resizeHandle.Size = UDim2.new(0, 12, 0, 12)
    resizeHandle.Position = UDim2.new(1, -12, 1, -12)
    resizeHandle.AnchorPoint = Vector2.new(1, 1)
    resizeHandle.BackgroundColor3 = Color3.fromRGB(30, 5, 5)
    resizeHandle.BorderSizePixel = 0
    resizeHandle.Parent = panel
    corner(resizeHandle, 999)
    glowStroke(resizeHandle, Color3.fromRGB(200, 0, 0), Color3.fromRGB(255, 50, 50), 1.5)

    local resizeStartPos, startSize
    resizeHandle.InputBegan:Connect(function(input)
        if not isMinimized and input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing = true
            resizeStartPos = input.Position
            startSize = panel.AbsoluteSize
        end
    end)
    connect(UserInputService.InputChanged, function(input)
        if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - resizeStartPos
            local newWidth = math.clamp(startSize.X + delta.X, 300, 900)
            local newHeight = math.clamp(startSize.Y + delta.Y, 200, 600)
            local newSize = UDim2.new(0, newWidth, 0, newHeight)
            panel.Size = newSize
            if not isMinimized then
                lastNormalSize = newSize
            end
        end
    end)
    connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing = false
        end
    end)
end

-- ============================================
-- CONTENT CONTAINER (TABS + AREAS)
-- ============================================
local contentContainer = Instance.new("Frame")
contentContainer.Name = "ContentContainer"
contentContainer.Size = UDim2.new(1, 0, 1, -(titleBarHeight))
contentContainer.Position = UDim2.new(0, 0, 0, titleBarHeight)
contentContainer.BackgroundTransparency = 1
contentContainer.BorderSizePixel = 0
contentContainer.ClipsDescendants = true
contentContainer.Parent = panel

-- ============================================
-- TAB BAR
-- ============================================
local tabBar = Instance.new("Frame")
tabBar.Name = "TabBar"
tabBar.Size = UDim2.new(1, 0, 0, 32)
tabBar.BackgroundColor3 = Color3.fromRGB(20, 5, 5)
tabBar.BackgroundTransparency = 0.2
tabBar.BorderSizePixel = 0
tabBar.Parent = contentContainer

local tabSeparator = Instance.new("Frame")
tabSeparator.Size = UDim2.new(1, 0, 0, 1)
tabSeparator.Position = UDim2.new(0, 0, 1, 0)
tabSeparator.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
tabSeparator.BorderSizePixel = 0
tabSeparator.BackgroundTransparency = 0.5
tabSeparator.Parent = tabBar

local tabLogs = Instance.new("TextButton")
tabLogs.Name = "TabLogs"
tabLogs.Size = UDim2.new(0, 80, 1, 0)
tabLogs.Position = UDim2.new(0, 0, 0, 0)
tabLogs.BackgroundColor3 = Color3.fromRGB(30, 5, 5)
tabLogs.Text = "Logs"
tabLogs.TextColor3 = Color3.fromRGB(255, 200, 200)
tabLogs.TextSize = 12 * fontSizeScale
tabLogs.Font = Enum.Font.GothamBold
tabLogs.BorderSizePixel = 0
tabLogs.Parent = tabBar
corner(tabLogs, 0)

local tabProducts = Instance.new("TextButton")
tabProducts.Name = "TabProducts"
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

local function tabHover(btn, activeBg)
    btn.MouseEnter:Connect(function()
        if btn.BackgroundColor3 ~= activeBg then
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(40, 10, 10)}):Play()
        end
    end)
    btn.MouseLeave:Connect(function()
        if btn.BackgroundColor3 ~= activeBg then
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(20, 5, 5)}):Play()
        end
    end)
end
tabHover(tabLogs, Color3.fromRGB(30, 5, 5))
tabHover(tabProducts, Color3.fromRGB(30, 5, 5))

-- ============================================
-- LOG AREA
-- ============================================
local logArea = Instance.new("ScrollingFrame")
logArea.Name = "LogArea"
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
listLayout.VerticalAlignment = Enum.VerticalAlignment.Top

local logPad = Instance.new("UIPadding", logArea)
logPad.PaddingTop = UDim.new(0, 2)
logPad.PaddingBottom = UDim.new(0, 2)
logPad.PaddingLeft = UDim.new(0, 2)
logPad.PaddingRight = UDim.new(0, 2)

-- ============================================
-- PRODUCT AREA
-- ============================================
local productArea = Instance.new("ScrollingFrame")
productArea.Name = "ProductArea"
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
productListLayout.VerticalAlignment = Enum.VerticalAlignment.Top

local productPad = Instance.new("UIPadding", productArea)
productPad.PaddingTop = UDim.new(0, 2)
productPad.PaddingBottom = UDim.new(0, 2)
productPad.PaddingLeft = UDim.new(0, 2)
productPad.PaddingRight = UDim.new(0, 2)

-- Buy All button
local buyAllProductsBtn = Instance.new("TextButton")
buyAllProductsBtn.Name = "BuyAllProducts"
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
hoverEffect(buyAllProductsBtn, Color3.fromRGB(180, 70, 70), Color3.fromRGB(150, 50, 50), Color3.fromRGB(255, 80, 80), Color3.fromRGB(220, 50, 50))

-- ============================================
-- LOAD PRODUCTS (WITHOUT COPY ID AND AUTO BUTTONS)
-- ============================================
local developerProducts = {}

local function createProductEntry(developerProduct)
    local entryHeight = isMobile and 60 or 52
    local entry = Instance.new("Frame")
    entry.Name = "ProductEntry"
    entry.Size = UDim2.new(1, -2, 0, entryHeight)
    entry.BackgroundColor3 = Color3.fromRGB(22, 5, 5)
    entry.BackgroundTransparency = 0.3
    entry.BorderSizePixel = 0
    entry.ClipsDescendants = true
    entry.Parent = productArea
    corner(entry, 8)
    local entryStroke = stroke(entry, Color3.fromRGB(150, 50, 50), 1)
    entryStroke.Transparency = 0.3

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size = UDim2.new(0, 160, 0, 18)
    nameLbl.Position = UDim2.new(0, 8, 0, 4)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = developerProduct.Name or "N/A"
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
    idLbl.Text = "ID: " .. tostring(developerProduct.ProductId)
    idLbl.TextColor3 = Color3.fromRGB(180, 100, 100)
    idLbl.TextSize = 10 * fontSizeScale
    idLbl.Font = Enum.Font.GothamMedium
    idLbl.TextXAlignment = Enum.TextXAlignment.Left
    idLbl.Parent = entry

    local priceLbl = Instance.new("TextLabel")
    priceLbl.Size = UDim2.new(0, 100, 0, 16)
    priceLbl.Position = UDim2.new(0, 8, 0, 40)
    priceLbl.BackgroundTransparency = 1
    priceLbl.Text = "Price: " .. tostring(developerProduct.PriceInRobux) .. " R$"
    priceLbl.TextColor3 = Color3.fromRGB(180, 100, 100)
    priceLbl.TextSize = 10 * fontSizeScale
    priceLbl.Font = Enum.Font.GothamMedium
    priceLbl.TextXAlignment = Enum.TextXAlignment.Left
    priceLbl.Parent = entry

    -- Button frame: positioned to the right
    local btnFrame = Instance.new("Frame")
    btnFrame.Size = UDim2.new(0, 100, 1, 0)
    btnFrame.Position = UDim2.new(1, -106, 0, 0)  -- right aligned with margin
    btnFrame.BackgroundTransparency = 1
    btnFrame.Parent = entry

    local function makeBuyButton(text, color, hoverColor)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 28)
        btn.Position = UDim2.new(0, 0, 0.5, -14)
        btn.BackgroundColor3 = color
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextSize = 11 * fontSizeScale
        btn.Font = Enum.Font.GothamBold
        btn.BorderSizePixel = 0
        btn.Parent = btnFrame
        corner(btn, 4)
        stroke(btn, Color3.fromRGB(150, 50, 50), 0.8)
        hoverEffect(btn, hoverColor, color, Color3.fromRGB(255, 80, 80), Color3.fromRGB(150, 50, 50))
        return btn
    end

    -- Buy button only
    local buyBtn = makeBuyButton("BUY", Color3.fromRGB(150, 50, 50), Color3.fromRGB(180, 70, 70))
    buyBtn.MouseButton1Click:Connect(function()
        local oldText = buyBtn.Text
        buyBtn.Text = "BUYING..."
        MarketplaceService:SignalPromptProductPurchaseFinished(player.UserId, developerProduct.ProductId, true)
        task.wait(1)
        buyBtn.Text = oldText
    end)

    return entry
end

local function loadProducts()
    local success, products = pcall(function()
        return MarketplaceService:GetDeveloperProductsAsync():GetCurrentPage()
    end)
    if success then
        developerProducts = products or {}
        for _, child in ipairs(productArea:GetChildren()) do
            if child.Name == "ProductEntry" then
                child:Destroy()
            end
        end
        for _, prod in ipairs(developerProducts) do
            createProductEntry(prod)
        end
        buyAllProductsBtn.Text = "Buy All (" .. #developerProducts .. ")"
    else
        buyAllProductsBtn.Text = "Error loading products"
    end
end

loadProducts()

buyAllProductsBtn.MouseButton1Click:Connect(function()
    local oldText = buyAllProductsBtn.Text
    buyAllProductsBtn.Text = "Processing..."
    for _, prod in ipairs(developerProducts) do
        MarketplaceService:SignalPromptProductPurchaseFinished(player.UserId, prod.ProductId, true)
        task.wait(0.01)
    end
    buyAllProductsBtn.Text = "Done!"
    task.wait(2)
    buyAllProductsBtn.Text = oldText
end)

local function switchTab(tab)
    if tab == "logs" then
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

-- ============================================
-- LOG EVENTS
-- ============================================
local eventCount = 0
local entries = {}
local suppressCounter = 0

local function fireFakeSignal(signalType, id)
    suppressCounter = suppressCounter + 1
    pcall(function()
        if signalType == "Product" then
            MarketplaceService:SignalPromptProductPurchaseFinished(player.UserId, id, true)
        elseif signalType == "Gamepass" then
            MarketplaceService:SignalPromptGamePassPurchaseFinished(player, id, true)
        elseif signalType == "Bulk" then
            MarketplaceService:SignalPromptBulkPurchaseFinished(player.UserId, id, true)
        elseif signalType == "Purchase" then
            MarketplaceService:PromptPurchase(player, id)
        end
    end)
    suppressCounter = suppressCounter - 1
end

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
    if show and not e then
        makeEmptyLabel()
    elseif not show and e then
        e:Destroy()
    end
end

local activeSpamButtons = {}

local function makeButton(text, parent)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 48, 0, buttonHeight)
    btn.BackgroundColor3 = Color3.fromRGB(30, 5, 5)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(200, 100, 100)
    btn.TextSize = 10 * fontSizeScale
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.Parent = parent
    corner(btn, 6)
    stroke(btn, Color3.fromRGB(150, 50, 50), 1)
    
    hoverEffect(btn, 
        Color3.fromRGB(40, 10, 10),
        Color3.fromRGB(30, 5, 5),
        Color3.fromRGB(255, 50, 50),
        Color3.fromRGB(150, 50, 50)
    )
    
    return btn
end

local function addLog(label, id, signalType)
    if suppressCounter > 0 then return end
    setEmpty(false)
    
    local entryHeight = isMobile and 46 or 38
    local entry = Instance.new("Frame")
    entry.Name = "EntryLog"
    entry.Size = UDim2.new(1, -2, 0, 0)
    entry.BackgroundColor3 = Color3.fromRGB(22, 5, 5)
    entry.BackgroundTransparency = 1
    entry.BorderSizePixel = 0
    entry.ClipsDescendants = true
    entry.LayoutOrder = -(eventCount)
    entry.Parent = logArea
    
    corner(entry, 8)
    local entryStroke = stroke(entry, Color3.fromRGB(150, 50, 50), 1)
    entryStroke.Transparency = 1
    
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 6, 0, 6)
    dot.Position = UDim2.new(0, 10, 0.5, -3)
    dot.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    dot.BackgroundTransparency = 1
    dot.BorderSizePixel = 0
    dot.Parent = entry
    corner(dot, 999)

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

    local buttonFrame = Instance.new("Frame")
    buttonFrame.Size = UDim2.new(0, 60, 1, 0)
    buttonFrame.Position = UDim2.new(1, -66, 0, 0)
    buttonFrame.BackgroundTransparency = 1
    buttonFrame.Parent = entry

    local horizontalLayout = Instance.new("UIListLayout")
    horizontalLayout.FillDirection = Enum.FillDirection.Horizontal
    horizontalLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    horizontalLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    horizontalLayout.Padding = UDim.new(0, 6)
    horizontalLayout.Parent = buttonFrame

    local buyBtn = makeButton("BUY", buttonFrame)

    TweenService:Create(entry, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, -2, 0, entryHeight)}):Play()
    
    local function fadeIn(obj, property, targetVal)
        TweenService:Create(obj, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {[property] = targetVal}):Play()
    end
    
    fadeIn(entry, "BackgroundTransparency", 0.3)
    fadeIn(entryStroke, "Transparency", 0.2)
    fadeIn(dot, "BackgroundTransparency", 0)
    fadeIn(lbl, "TextTransparency", 0)
    fadeIn(idEl, "TextTransparency", 0)
    fadeIn(timeEl, "TextTransparency", 0)
    fadeIn(buyBtn, "TextTransparency", 0)
    
    local buyBtnStroke = buyBtn:FindFirstChildOfClass("UIStroke")
    if buyBtnStroke then fadeIn(buyBtnStroke, "Transparency", 0.2) end

    local holdStart = nil
    local holdConnection = nil
    local spamLoop = nil
    local isSpamming = false
    
    local function startSpam()
        if isSpamming then return end
        isSpamming = true
        buyBtn.Text = "SPAM"
        buyBtn.TextColor3 = Color3.fromRGB(255, 150, 50)
        local str = buyBtn:FindFirstChildOfClass("UIStroke")
        if str then str.Color = Color3.fromRGB(255, 150, 50) end
        
        spamLoop = task.spawn(function()
            while isSpamming and buyBtn.Parent do
                fireFakeSignal(signalType, id)
                task.wait(0.1)
            end
        end)
        activeSpamButtons[buyBtn] = {active = true, loop = spamLoop}
    end
    
    local function stopSpam()
        isSpamming = false
        if spamLoop then task.cancel(spamLoop) end
        activeSpamButtons[buyBtn] = nil
        if buyBtn.Parent then
            buyBtn.Text = "BUY"
            buyBtn.TextColor3 = Color3.fromRGB(200, 100, 100)
            local str = buyBtn:FindFirstChildOfClass("UIStroke")
            if str then str.Color = Color3.fromRGB(150, 50, 50) end
        end
    end

    local function onBuyPress()
        if isSpamming then return end
        holdStart = tick()
        holdConnection = task.spawn(function()
            while holdStart and (tick() - holdStart) < 3 do
                task.wait(0.1)
            end
            if holdStart and not isSpamming then
                startSpam()
            end
        end)
    end

    local function onBuyRelease()
        local heldDuration = holdStart and (tick() - holdStart) or 0
        holdStart = nil
        if holdConnection then task.cancel(holdConnection) end
        if isSpamming then
            stopSpam()
        elseif heldDuration < 3 then
            fireFakeSignal(signalType, id)
            buyBtn.Text = "BOUGHT!"
            buyBtn.TextColor3 = Color3.fromRGB(0, 255, 0)
            local str = buyBtn:FindFirstChildOfClass("UIStroke")
            if str then str.Color = Color3.fromRGB(0, 255, 0) end
            
            task.spawn(function()
                task.wait(1.5)
                if buyBtn.Parent and not isSpamming then
                    buyBtn.Text = "BUY"
                    buyBtn.TextColor3 = Color3.fromRGB(200, 100, 100)
                    if str then str.Color = Color3.fromRGB(150, 50, 50) end
                end
            end)
        end
    end

    buyBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            onBuyPress()
        end
    end)
    buyBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            onBuyRelease()
        end
    end)

    entry.AncestryChanged:Connect(function()
        if not entry.Parent then
            if isSpamming then stopSpam() end
            for i, e in ipairs(entries) do
                if e == entry then
                    table.remove(entries, i)
                    break
                end
            end
        end
    end)

    eventCount = eventCount + 1
    table.insert(entries, entry)
end

connect(MarketplaceService.PromptProductPurchaseFinished, function(plr, id, bought)
    if suppressCounter == 0 then addLog("Product", id, "Product") end
end)
connect(MarketplaceService.PromptGamePassPurchaseFinished, function(plr, id, bought)
    if suppressCounter == 0 then addLog("Gamepass", id, "Gamepass") end
end)
connect(MarketplaceService.PromptBulkPurchaseFinished, function(userId, id, bought)
    if suppressCounter == 0 then addLog("Bulk", id, "Bulk") end
end)
connect(MarketplaceService.PromptPurchaseFinished, function(userId, id, bought)
    if suppressCounter == 0 then addLog("Purchase", id, "Purchase") end
end)

connect(screenGui.AncestryChanged, function(_, parent)
    if not parent then
        for _, conn in ipairs(connections) do
            if conn.Connected then
                conn:Disconnect()
            end
        end
        table.clear(connections)
    end
end)

setEmpty(true)

-- ============================================
-- UI VISIBILITY TOGGLE (Close / Reopen)
-- ============================================
local uiVisible = true
local reopenButton = nil
local reopenSpring = createUDim2Spring(18, 12, UDim2.new(0, 0, 0, 0))
local reopenSnapping = false

local function showGui()
    if not screenGui.Enabled then
        screenGui.Enabled = true
        uiVisible = true
        
        if reopenButton then
            reopenButton.Visible = false
        end
        
        panelTargetPos = panelPosition
        panel.Size = UDim2.new(0, 0, 0, 0)
        TweenService:Create(panel, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = panelSize}):Play()
    end
end

local function hideGui()
    if screenGui.Enabled then
        uiVisible = false
        local panelT = TweenService:Create(panel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0)
        })
        panelT:Play()
        panelT.Completed:Connect(function()
            if not uiVisible then
                screenGui.Enabled = false
            end
        end)

        if isMobile then
            if not reopenButton or not reopenButton.Parent then
                reopenButton = Instance.new("TextButton")
                reopenButton.Name = "Spider_Reopen"
                reopenButton.Size = UDim2.new(0, 48, 0, 48)
                reopenButton.AnchorPoint = Vector2.new(0.5, 0.5)
                
                local screenWidth = screenGui.AbsoluteSize.X
                local screenHeight = screenGui.AbsoluteSize.Y
                local startX = screenWidth - 39
                local startY = screenHeight - 39
                
                reopenButton.Position = UDim2.new(0, startX, 0, startY)
                reopenSpring:SetPosition(reopenButton.Position)
                reopenSpring:SetTarget(reopenButton.Position)
                
                reopenButton.BackgroundColor3 = Color3.fromRGB(30, 5, 5)
                reopenButton.BackgroundTransparency = 0.2
                reopenButton.Text = "S"
                reopenButton.TextColor3 = Color3.fromRGB(255, 50, 50)
                reopenButton.TextSize = 20
                reopenButton.Font = Enum.Font.GothamBold
                reopenButton.BorderSizePixel = 0
                reopenButton.ZIndex = 100
                reopenButton.Parent = playerGui
                corner(reopenButton, 24)
                glowStroke(reopenButton, Color3.fromRGB(200, 0, 0), Color3.fromRGB(255, 50, 50), 1.5)
                createPulse(reopenButton, Color3.fromRGB(200, 0, 0))

                hoverEffect(reopenButton, Color3.fromRGB(40, 10, 10), Color3.fromRGB(30, 5, 5), Color3.fromRGB(255, 50, 50), Color3.fromRGB(200, 0, 0))

                local reopenDragging = false
                local reopenDragStart, reopenStartPos                
                reopenButton.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                        reopenDragging = true
                        reopenSnapping = false
                        reopenDragStart = input.Position
                        reopenStartPos = reopenButton.Position
                    end
                end)

                connect(UserInputService.InputChanged, function(input2)
                    if reopenDragging and (input2.UserInputType == Enum.UserInputType.Touch or input2.UserInputType == Enum.UserInputType.MouseMovement) then
                        local delta = input2.Position - reopenDragStart
                        reopenButton.Position = UDim2.new(reopenStartPos.X.Scale, reopenStartPos.X.Offset + delta.X, reopenStartPos.Y.Scale, reopenStartPos.Y.Offset + delta.Y)
                    end
                end)

                connect(UserInputService.InputEnded, function(input2)
                    if input2.UserInputType == Enum.UserInputType.Touch or input2.UserInputType == Enum.UserInputType.MouseButton1 then
                        if reopenDragging then
                            reopenDragging = false
                            reopenSnapping = true
                            
                            local sw = screenGui.AbsoluteSize.X
                            local sh = screenGui.AbsoluteSize.Y
                            local curX = reopenButton.Position.X.Offset
                            local targetX
                            
                            if curX < sw / 2 then
                                targetX = 39
                            else
                                targetX = sw - 39
                            end
                            
                            local targetY = math.clamp(reopenButton.Position.Y.Offset, 39, sh - 39)
                            reopenSpring:SetPosition(reopenButton.Position)
                            reopenSpring:SetTarget(UDim2.new(0, targetX, 0, targetY))
                        end
                    end
                end)

                reopenButton.MouseButton1Click:Connect(showGui)
            else
                reopenButton.Visible = true
            end
        end
    end
end

closeBtn.MouseButton1Click:Connect(hideGui)

minBtn.MouseButton1Click:Connect(function()
    if resizing then return end
    isMinimized = not isMinimized
    local targetSize
    if isMinimized then
        minBtn.Text = "+"
        targetSize = UDim2.new(panel.Size.X.Scale, panel.Size.X.Offset, 0, titleBarHeight)
        contentContainer.Visible = false
        if resizeHandle then resizeHandle.Visible = false end
    else
        minBtn.Text = "-"
        targetSize = lastNormalSize
        contentContainer.Visible = true
        if resizeHandle then resizeHandle.Visible = true end
    end
    TweenService:Create(panel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = targetSize}):Play()
end)

if not isMobile then
    connect(UserInputService.InputBegan, function(input)
        if input.KeyCode == Enum.KeyCode.RightShift then
            if uiVisible then hideGui() else showGui() end
        end
    end)
end

connect(RunService.RenderStepped, function(dt)
    dt = math.min(dt, 0.1)
    
    if keyWindow and keyWindow.Parent then
        local shakeOffset = shakeSpring:Update(dt)
        keyWindow.Position = keyWindowPos + UDim2.new(0, shakeOffset, 0, 0)
    end
    
    if panel and panel.Visible then
        panel.Position = panelTargetPos
    end
    
    if reopenButton and reopenButton.Parent and reopenButton.Visible and reopenSnapping then
        reopenButton.Position = reopenSpring:Update(dt)
        if math.abs(reopenSpring.X.Velocity) < 1 and math.abs(reopenSpring.X.Position - reopenSpring.X.Target) < 1 then
            reopenSnapping = false
            reopenButton.Position = UDim2.new(reopenSpring.ScaleX, reopenSpring.X.Target, reopenSpring.ScaleY, reopenSpring.Y.Target)
        end
    end
end)
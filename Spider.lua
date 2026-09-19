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

-- ============================================
-- THEME SYSTEM
-- ============================================
local Theme = {
    bgDark      = Color3.fromRGB(16, 0, 0),
    bgMid       = Color3.fromRGB(30, 5, 5),
    bgLight     = Color3.fromRGB(45, 10, 10),
    accent      = Color3.fromRGB(200, 0, 0),
    accent2     = Color3.fromRGB(255, 50, 50),
    text        = Color3.fromRGB(255, 200, 200),
    textDim     = Color3.fromRGB(180, 100, 100),
    inputText   = Color3.fromRGB(255, 100, 100),
}

local ThemeTargets = {
    frames    = {},
    strokes   = {},
    texts     = {},
    gradients = {},
    images    = {},
}

local function regFrame(obj, key)
    table.insert(ThemeTargets.frames, {obj = obj, key = key})
end
local function regStroke(obj, key)
    table.insert(ThemeTargets.strokes, {obj = obj, key = key})
end
local function regText(obj, key)
    table.insert(ThemeTargets.texts, {obj = obj, key = key})
end
local function regGradient(obj, key1, key2)
    table.insert(ThemeTargets.gradients, {obj = obj, key1 = key1, key2 = key2})
end
local function regImage(obj, key)
    table.insert(ThemeTargets.images, {obj = obj, key = key})
end

local HoverRegistry = {}

local function applyTheme()
    for _, t in ipairs(ThemeTargets.frames) do
        pcall(function() t.obj.BackgroundColor3 = Theme[t.key] end)
    end
    for _, t in ipairs(ThemeTargets.strokes) do
        pcall(function() t.obj.Color = Theme[t.key] end)
    end
    for _, t in ipairs(ThemeTargets.texts) do
        pcall(function() t.obj.TextColor3 = Theme[t.key] end)
    end
    for _, t in ipairs(ThemeTargets.gradients) do
        pcall(function()
            t.obj.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Theme[t.key1]),
                ColorSequenceKeypoint.new(1, Theme[t.key2])
            })
        end)
    end
    for _, t in ipairs(ThemeTargets.images) do
        pcall(function() t.obj.ImageColor3 = Theme[t.key] end)
    end

    for _, h in ipairs(HoverRegistry) do
        if h.btn and h.btn.Parent then
            if h.bgKey then
                h.btn.BackgroundColor3 = Theme[h.bgKey]
            end
            if h.txtKey then
                h.btn.TextColor3 = Theme[h.txtKey]
            end
            if h.stroke and h.strokeKey then
                h.stroke.Color = Theme[h.strokeKey]
            end
        end
    end
end

-- ============================================
-- HOVER EFFECT
-- ============================================
local function hoverEffect(btn, bgKey, bgHoverKey, strokeKey, strokeHoverKey, txtKey)
    local scale = Instance.new("UIScale", btn)
    scale.Scale = 1
    local uistroke = btn:FindFirstChildOfClass("UIStroke")

    local reg = {
        btn = btn,
        bgKey = bgKey,
        stroke = uistroke,
        strokeKey = strokeKey,
        txtKey = txtKey,
    }
    table.insert(HoverRegistry, reg)

    btn.MouseEnter:Connect(function()
        TweenService:Create(scale, TweenInfo.new(0.2), {Scale = 1.04}):Play()
        if bgHoverKey and Theme[bgHoverKey] then
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Theme[bgHoverKey]}):Play()
        end
        if uistroke and strokeHoverKey and Theme[strokeHoverKey] then
            TweenService:Create(uistroke, TweenInfo.new(0.15), {Color = Theme[strokeHoverKey]}):Play()
        end
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(scale, TweenInfo.new(0.2), {Scale = 1}):Play()
        if bgKey and Theme[bgKey] then
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Theme[bgKey]}):Play()
        end
        if uistroke and strokeKey and Theme[strokeKey] then
            TweenService:Create(uistroke, TweenInfo.new(0.15), {Color = Theme[strokeKey]}):Play()
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
    if addLog then addLog(kind, id, kind) end
end

-- ============================================
-- NOME DINÂMICO
-- ============================================
local ScriptName = "Spider"

local NameTargets = {}

local function regName(obj, suffix)
    table.insert(NameTargets, {obj = obj, suffix = suffix or ""})
end

local function applyScriptName()
    for _, t in ipairs(NameTargets) do
        pcall(function()
            t.obj.Text = ScriptName .. t.suffix
        end)
    end
    pcall(function() screenGui.Name = ScriptName end)
end

-- ============================================
-- MODE SELECT
-- ============================================
local modeWindow = Instance.new("Frame")
modeWindow.Name = "ModeSelect"
modeWindow.Size = UDim2.new(0, 360, 0, 290)
modeWindow.Position = UDim2.new(0.5, -180, 0.5, -145)
modeWindow.BackgroundColor3 = Theme.bgDark
modeWindow.BackgroundTransparency = 0.1
modeWindow.BorderSizePixel = 0
modeWindow.ClipsDescendants = true
modeWindow.Parent = screenGui
corner(modeWindow, 14)
local modeStroke = glowStroke(modeWindow, Theme.accent, Theme.accent2, 1.5)
regFrame(modeWindow, "bgDark")
regGradient(modeStroke:FindFirstChildOfClass("UIGradient"), "accent", "accent2")

local modeTitle = Instance.new("TextLabel")
modeTitle.Size = UDim2.new(1, 0, 0, 40)
modeTitle.Position = UDim2.new(0, 0, 0, 16)
modeTitle.BackgroundTransparency = 1
modeTitle.Text = "Select Mode"
modeTitle.TextSize = 20
modeTitle.Font = Enum.Font.GothamBold
modeTitle.Parent = modeWindow
local modeTitleGrad = applyTextGradient(modeTitle, Theme.accent, Theme.accent2)
regGradient(modeTitleGrad, "accent", "accent2")

local modeSub = Instance.new("TextLabel")
modeSub.Size = UDim2.new(1, 0, 0, 20)
modeSub.Position = UDim2.new(0, 0, 0, 58)
modeSub.BackgroundTransparency = 1
modeSub.Text = "Choose how to run"
modeSub.TextColor3 = Theme.textDim
modeSub.TextSize = 11
modeSub.Font = Enum.Font.Gotham
modeSub.Parent = modeWindow
regText(modeSub, "textDim")

local autoBtn = Instance.new("TextButton")
autoBtn.Size = UDim2.new(0, 140, 0, 70)
autoBtn.Position = UDim2.new(0.5, -150, 0, 100)
autoBtn.BackgroundColor3 = Theme.accent
autoBtn.Text = "AUTOMATIC"
autoBtn.TextColor3 = Theme.text
autoBtn.TextSize = 14
autoBtn.Font = Enum.Font.GothamBold
autoBtn.BorderSizePixel = 0
autoBtn.Parent = modeWindow
corner(autoBtn, 10)
local autoStroke = stroke(autoBtn, Theme.accent2, 1)
regFrame(autoBtn, "accent")
regText(autoBtn, "text")
regStroke(autoStroke, "accent2")
hoverEffect(autoBtn, "accent", "accent2", "accent2", "accent", "text")

local manualBtn = Instance.new("TextButton")
manualBtn.Size = UDim2.new(0, 140, 0, 70)
manualBtn.Position = UDim2.new(0.5, 10, 0, 100)
manualBtn.BackgroundColor3 = Theme.bgMid
manualBtn.Text = "MANUAL"
manualBtn.TextColor3 = Theme.text
manualBtn.TextSize = 14
manualBtn.Font = Enum.Font.GothamBold
manualBtn.BorderSizePixel = 0
manualBtn.Parent = modeWindow
corner(manualBtn, 10)
local manualStroke = stroke(manualBtn, Theme.accent, 1)
regFrame(manualBtn, "bgMid")
regText(manualBtn, "text")
regStroke(manualStroke, "accent")
hoverEffect(manualBtn, "bgMid", "bgLight", "accent", "accent2", "text")

local colorBtn = Instance.new("TextButton")
colorBtn.Size = UDim2.new(0, 300, 0, 40)
colorBtn.Position = UDim2.new(0.5, -150, 0, 185)
colorBtn.BackgroundColor3 = Theme.bgLight
colorBtn.Text = "EDIT COLORS"
colorBtn.TextColor3 = Theme.text
colorBtn.TextSize = 13
colorBtn.Font = Enum.Font.GothamBold
colorBtn.BorderSizePixel = 0
colorBtn.Parent = modeWindow
corner(colorBtn, 10)
local colorBtnStroke = stroke(colorBtn, Theme.accent, 1)
regFrame(colorBtn, "bgLight")
regText(colorBtn, "text")
regStroke(colorBtnStroke, "accent")
hoverEffect(colorBtn, "bgLight", "accent", "accent", "accent2", "text")

do
    local dragging, dragStart, startPos
    modeWindow.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if input.Target == autoBtn or input.Target == manualBtn or input.Target == colorBtn then return end
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

-- ============================================
-- AUTO PANEL
-- ============================================
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
autoPanel.BackgroundColor3 = Theme.bgDark
autoPanel.BackgroundTransparency = 0.3
autoPanel.BorderSizePixel = 0
autoPanel.Visible = false
autoPanel.ClipsDescendants = true
autoPanel.Parent = screenGui
corner(autoPanel, 14)
local autoPanelStroke = glowStroke(autoPanel, Theme.accent, Theme.accent2, 1.5)
regFrame(autoPanel, "bgDark")
regGradient(autoPanelStroke:FindFirstChildOfClass("UIGradient"), "accent", "accent2")

local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, titleBarHeight)
titleBar.BackgroundColor3 = Theme.bgDark
titleBar.BackgroundTransparency = 0.3
titleBar.BorderSizePixel = 0
titleBar.Parent = autoPanel
regFrame(titleBar, "bgDark")

local sep = Instance.new("Frame")
sep.Size = UDim2.new(1, 0, 0, 1)
sep.Position = UDim2.new(0, 0, 1, -1)
sep.BorderSizePixel = 0
sep.Parent = titleBar
local sepGrad = applyGradient(sep, Theme.accent, Theme.accent2)
regGradient(sepGrad, "accent", "accent2")

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, 0, 1, 0)
titleText.BackgroundTransparency = 1
titleText.Text = ScriptName .. " — Auto"
titleText.TextSize = 13 * fontSizeScale
titleText.Font = Enum.Font.GothamBold
titleText.Parent = titleBar
local titleTextGrad = applyTextGradient(titleText, Theme.accent, Theme.accent2)
regGradient(titleTextGrad, "accent", "accent2")
regName(titleText, " — Auto")

local function makeIconBtn(parent, txt, xOff, bgKey, txtKey, strokeKey)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 20, 0, 20)
    b.Position = UDim2.new(1, xOff, 0.5, 0)
    b.AnchorPoint = Vector2.new(1, 0.5)
    b.BackgroundColor3 = Theme[bgKey]
    b.Text = txt
    b.TextColor3 = Theme[txtKey]
    b.TextSize = 10 * fontSizeScale
    b.Font = Enum.Font.GothamBold
    b.BorderSizePixel = 0
    b.ZIndex = 10
    b.Parent = parent
    corner(b, 999)
    local s = stroke(b, Theme[strokeKey], 1)
    regFrame(b, bgKey)
    regText(b, txtKey)
    regStroke(s, strokeKey)
    return b
end

local backFromAuto = makeIconBtn(titleBar, "<", -56, "bgMid", "textDim", "textDim")
local minBtn      = makeIconBtn(titleBar, "-", -32, "bgMid", "textDim", "textDim")
local closeBtn    = makeIconBtn(titleBar, "X", -6,  "bgLight", "accent2", "accent2")

hoverEffect(minBtn, "bgMid", "bgLight", "textDim", "accent", "textDim")
hoverEffect(closeBtn, "bgLight", "accent", "accent2", "accent2", "accent2")
hoverEffect(backFromAuto, "bgMid", "bgLight", "textDim", "accent", "textDim")

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
tabBar.BackgroundColor3 = Theme.bgMid
tabBar.BackgroundTransparency = 0.2
tabBar.BorderSizePixel = 0
tabBar.Parent = contentContainer
regFrame(tabBar, "bgMid")

local tabLogs = Instance.new("TextButton")
tabLogs.Size = UDim2.new(0, 80, 1, 0)
tabLogs.BackgroundColor3 = Theme.bgMid
tabLogs.Text = "Logs"
tabLogs.TextColor3 = Theme.text
tabLogs.TextSize = 12 * fontSizeScale
tabLogs.Font = Enum.Font.GothamBold
tabLogs.BorderSizePixel = 0
tabLogs.Parent = tabBar
corner(tabLogs, 0)
regFrame(tabLogs, "bgMid")
regText(tabLogs, "text")

local tabProducts = Instance.new("TextButton")
tabProducts.Size = UDim2.new(0, 80, 1, 0)
tabProducts.Position = UDim2.new(0, 80, 0, 0)
tabProducts.BackgroundColor3 = Theme.bgMid
tabProducts.Text = "Products"
tabProducts.TextColor3 = Theme.textDim
tabProducts.TextSize = 12 * fontSizeScale
tabProducts.Font = Enum.Font.GothamBold
tabProducts.BorderSizePixel = 0
tabProducts.Parent = tabBar
corner(tabProducts, 0)
regFrame(tabProducts, "bgMid")
regText(tabProducts, "textDim")

-- ============================================
-- CONTAINER DA ABA LOGS + BOTÃO WIPE (canto superior direito)
-- ============================================
local logsContainer = Instance.new("Frame")
logsContainer.Name = "LogsContainer"
logsContainer.Size = UDim2.new(1, -12, 1, -(32 + 6))
logsContainer.Position = UDim2.new(0, 6, 0, 32 + 6)
logsContainer.BackgroundTransparency = 1
logsContainer.BorderSizePixel = 0
logsContainer.Parent = contentContainer

-- Botão WIPE fixo no canto superior direito
local wipeLogsBtn = Instance.new("TextButton")
wipeLogsBtn.Name = "WipeBtn"
wipeLogsBtn.Size = UDim2.new(0, 70, 0, 24)
wipeLogsBtn.Position = UDim2.new(1, -70, 0, 0)
wipeLogsBtn.BackgroundColor3 = Theme.bgMid
wipeLogsBtn.Text = "WIPE"
wipeLogsBtn.TextColor3 = Theme.accent2
wipeLogsBtn.TextSize = 11 * fontSizeScale
wipeLogsBtn.Font = Enum.Font.GothamBold
wipeLogsBtn.BorderSizePixel = 0
wipeLogsBtn.ZIndex = 5
wipeLogsBtn.Parent = logsContainer
corner(wipeLogsBtn, 6)
local wipeLogsStroke = stroke(wipeLogsBtn, Theme.accent, 1, 0.3)
regFrame(wipeLogsBtn, "bgMid")
regText(wipeLogsBtn, "accent2")
regStroke(wipeLogsStroke, "accent")
hoverEffect(wipeLogsBtn, "bgMid", "bgLight", "accent", "accent2", "accent2")

-- Área de logs (fica abaixo do botão)
local logArea = Instance.new("ScrollingFrame")
logArea.Size = UDim2.new(1, 0, 1, -28)
logArea.Position = UDim2.new(0, 0, 0, 28)
logArea.BackgroundTransparency = 1
logArea.BorderSizePixel = 0
logArea.ScrollBarThickness = isMobile and 4 or 3
logArea.ScrollBarImageColor3 = Theme.accent
logArea.CanvasSize = UDim2.new(0, 0, 0, 0)
logArea.AutomaticCanvasSize = Enum.AutomaticSize.Y
logArea.Parent = logsContainer
regFrame(logArea, "accent")

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
productArea.ScrollBarImageColor3 = Theme.accent
productArea.CanvasSize = UDim2.new(0, 0, 0, 0)
productArea.AutomaticCanvasSize = Enum.AutomaticSize.Y
productArea.Visible = false
productArea.Parent = contentContainer
regFrame(productArea, "accent")

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
buyAllProductsBtn.BackgroundColor3 = Theme.accent
buyAllProductsBtn.Text = "Buy All (loading...)"
buyAllProductsBtn.TextColor3 = Theme.text
buyAllProductsBtn.TextSize = 12 * fontSizeScale
buyAllProductsBtn.Font = Enum.Font.GothamBold
buyAllProductsBtn.BorderSizePixel = 0
buyAllProductsBtn.Parent = productArea
corner(buyAllProductsBtn, 6)
local buyAllStroke = stroke(buyAllProductsBtn, Theme.accent2, 1)
regFrame(buyAllProductsBtn, "accent")
regText(buyAllProductsBtn, "text")
regStroke(buyAllStroke, "accent2")
hoverEffect(buyAllProductsBtn, "accent", "accent2", "accent2", "accent", "text")

local developerProducts = {}
local function createProductEntry(devProduct)
    local entry = Instance.new("Frame")
    entry.Name = "ProductEntry"
    entry.Size = UDim2.new(1, -2, 0, isMobile and 60 or 52)
    entry.BackgroundColor3 = Theme.bgMid
    entry.BackgroundTransparency = 0.3
    entry.BorderSizePixel = 0
    entry.ClipsDescendants = true
    entry.Parent = productArea
    corner(entry, 8)
    local entryStroke = stroke(entry, Theme.accent, 1, 0.3)
    regFrame(entry, "bgMid")
    regStroke(entryStroke, "accent")

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size = UDim2.new(0, 160, 0, 18)
    nameLbl.Position = UDim2.new(0, 8, 0, 4)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = devProduct.Name or "N/A"
    nameLbl.TextColor3 = Theme.text
    nameLbl.TextSize = 12 * fontSizeScale
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
    nameLbl.Parent = entry
    regText(nameLbl, "text")

    local idLbl = Instance.new("TextLabel")
    idLbl.Size = UDim2.new(0, 100, 0, 16)
    idLbl.Position = UDim2.new(0, 8, 0, 24)
    idLbl.BackgroundTransparency = 1
    idLbl.Text = "ID: " .. tostring(devProduct.ProductId)
    idLbl.TextColor3 = Theme.textDim
    idLbl.TextSize = 10 * fontSizeScale
    idLbl.Font = Enum.Font.GothamMedium
    idLbl.TextXAlignment = Enum.TextXAlignment.Left
    idLbl.Parent = entry
    regText(idLbl, "textDim")

    local priceLbl = Instance.new("TextLabel")
    priceLbl.Size = UDim2.new(0, 100, 0, 16)
    priceLbl.Position = UDim2.new(0, 8, 0, 40)
    priceLbl.BackgroundTransparency = 1
    priceLbl.Text = "Price: " .. tostring(devProduct.PriceInRobux) .. " R$"
    priceLbl.TextColor3 = Theme.textDim
    priceLbl.TextSize = 10 * fontSizeScale
    priceLbl.Font = Enum.Font.GothamMedium
    priceLbl.TextXAlignment = Enum.TextXAlignment.Left
    priceLbl.Parent = entry
    regText(priceLbl, "textDim")

    local buyBtn = Instance.new("TextButton")
    buyBtn.Size = UDim2.new(0, 100, 0, 28)
    buyBtn.Position = UDim2.new(1, -106, 0.5, -14)
    buyBtn.BackgroundColor3 = Theme.accent
    buyBtn.Text = "BUY"
    buyBtn.TextColor3 = Theme.text
    buyBtn.TextSize = 11 * fontSizeScale
    buyBtn.Font = Enum.Font.GothamBold
    buyBtn.BorderSizePixel = 0
    buyBtn.Parent = entry
    corner(buyBtn, 4)
    local buyStroke = stroke(buyBtn, Theme.accent, 0.8)
    regFrame(buyBtn, "accent")
    regText(buyBtn, "text")
    regStroke(buyStroke, "accent")
    hoverEffect(buyBtn, "accent", "accent2", "accent", "accent2", "text")

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
    el.TextColor3 = Theme.textDim
    el.TextSize = 11 * fontSizeScale
    el.Font = Enum.Font.GothamMedium
    el.TextWrapped = true
    el.LayoutOrder = 99999
    el.Parent = logArea
    regText(el, "textDim")
    return el
end

local function setEmpty(show)
    local e = logArea:FindFirstChild("EmptyState")
    if show and not e then makeEmptyLabel()
    elseif not show and e then e:Destroy() end
end

-- ============================================
-- FUNÇÃO LIMPAR LOGS
-- ============================================
local function clearAllLogs()
    for _, c in ipairs(logArea:GetChildren()) do
        if c.Name == "EntryLog" then
            c:Destroy()
        end
    end
    entries = {}
    eventCount = 0
    setEmpty(true)
end

local function makeSmallBtn(parent)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 48, 0, buttonHeight)
    b.BackgroundColor3 = Theme.bgMid
    b.Text = "BUY"
    b.TextColor3 = Theme.textDim
    b.TextSize = 10 * fontSizeScale
    b.Font = Enum.Font.GothamBold
    b.BorderSizePixel = 0
    b.Parent = parent
    corner(b, 6)
    local s = stroke(b, Theme.accent, 1)
    regFrame(b, "bgMid")
    regText(b, "textDim")
    regStroke(s, "accent")
    hoverEffect(b, "bgMid", "bgLight", "accent", "accent2", "textDim")
    return b
end

addLog = function(label, id, signalType)
    setEmpty(false)

    local entry = Instance.new("Frame")
    entry.Name = "EntryLog"
    entry.Size = UDim2.new(1, -2, 0, 0)
    entry.BackgroundColor3 = Theme.bgMid
    entry.BackgroundTransparency = 1
    entry.BorderSizePixel = 0
    entry.ClipsDescendants = true
    entry.LayoutOrder = -eventCount
    entry.Parent = logArea
    corner(entry, 8)
    local entryStroke = stroke(entry, Theme.accent, 1, 1)
    regFrame(entry, "bgMid")
    regStroke(entryStroke, "accent")

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 64, 1, 0)
    lbl.Position = UDim2.new(0, 20, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = string.upper(label)
    lbl.TextColor3 = Theme.textDim
    lbl.TextTransparency = 1
    lbl.TextSize = 9 * fontSizeScale
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = entry
    regText(lbl, "textDim")

    local idEl = Instance.new("TextLabel")
    idEl.Size = UDim2.new(0, 110, 1, 0)
    idEl.Position = UDim2.new(0, 88, 0, 0)
    idEl.BackgroundTransparency = 1
    idEl.Text = tostring(id)
    idEl.TextColor3 = Theme.text
    idEl.TextTransparency = 1
    idEl.TextSize = 11 * fontSizeScale
    idEl.Font = Enum.Font.Code
    idEl.TextXAlignment = Enum.TextXAlignment.Left
    idEl.TextTruncate = Enum.TextTruncate.AtEnd
    idEl.Parent = entry
    regText(idEl, "text")

    local timeEl = Instance.new("TextLabel")
    timeEl.Size = UDim2.new(0, 50, 1, 0)
    timeEl.Position = UDim2.new(0, 202, 0, 0)
    timeEl.BackgroundTransparency = 1
    timeEl.Text = getTime()
    timeEl.TextColor3 = Theme.textDim
    timeEl.TextTransparency = 1
    timeEl.TextSize = 9 * fontSizeScale
    timeEl.Font = Enum.Font.GothamMedium
    timeEl.Parent = entry
    regText(timeEl, "textDim")

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
            buyBtn.TextColor3 = Theme.textDim
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

-- ============================================
-- CONEXÃO DO BOTÃO WIPE
-- ============================================
wipeLogsBtn.MouseButton1Click:Connect(function()
    clearAllLogs()
    wipeLogsBtn.Text = "WIPED!"
    task.wait(0.8)
    if wipeLogsBtn.Parent then
        wipeLogsBtn.Text = "WIPE"
    end
end)

local function switchTab(t)
    if t == "logs" then
        tabLogs.BackgroundColor3 = Theme.bgLight
        tabLogs.TextColor3 = Theme.text
        tabProducts.BackgroundColor3 = Theme.bgMid
        tabProducts.TextColor3 = Theme.textDim
        logsContainer.Visible = true
        productArea.Visible = false
    else
        tabProducts.BackgroundColor3 = Theme.bgLight
        tabProducts.TextColor3 = Theme.text
        tabLogs.BackgroundColor3 = Theme.bgMid
        tabLogs.TextColor3 = Theme.textDim
        logsContainer.Visible = false
        productArea.Visible = true
    end
end
tabLogs.MouseButton1Click:Connect(function() switchTab("logs") end)
tabProducts.MouseButton1Click:Connect(function() switchTab("products") end)
switchTab("logs")

-- ============================================
-- MANUAL PANEL
-- ============================================
local manualPanel = Instance.new("Frame")
manualPanel.Name = "ManualPanel"
manualPanel.AnchorPoint = Vector2.new(0.5, 0.5)
manualPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
manualPanel.Size = UDim2.new(0, 517, 0, 377)
manualPanel.BackgroundColor3 = Theme.bgDark
manualPanel.BackgroundTransparency = 0.15
manualPanel.BorderSizePixel = 0
manualPanel.Visible = false
manualPanel.ClipsDescendants = true
manualPanel.Parent = screenGui
corner(manualPanel, 8)
local manualPanelStroke = glowStroke(manualPanel, Theme.accent, Theme.accent2, 1.5)
regFrame(manualPanel, "bgDark")
regGradient(manualPanelStroke:FindFirstChildOfClass("UIGradient"), "accent", "accent2")

do
    local Header = Instance.new("TextLabel")
    Header.TextWrapped = true
    Header.TextColor3 = Color3.fromRGB(255, 255, 255)
    Header.Text = ScriptName
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
    local headerGrad = applyTextGradient(Header, Theme.accent, Theme.accent2)
    regGradient(headerGrad, "accent", "accent2")
    regName(Header, "")

    local manualClose = Instance.new("TextButton")
    manualClose.Size = UDim2.new(0, 20, 0, 20)
    manualClose.Position = UDim2.new(1, -6, 0, 6)
    manualClose.AnchorPoint = Vector2.new(1, 0)
    manualClose.BackgroundColor3 = Theme.bgLight
    manualClose.Text = "X"
    manualClose.TextColor3 = Theme.accent2
    manualClose.TextSize = 10
    manualClose.Font = Enum.Font.GothamBold
    manualClose.BorderSizePixel = 0
    manualClose.Parent = manualPanel
    corner(manualClose, 999)
    local manualCloseStroke = stroke(manualClose, Theme.accent, 1)
    regFrame(manualClose, "bgLight")
    regText(manualClose, "accent2")
    regStroke(manualCloseStroke, "accent")
    hoverEffect(manualClose, "bgLight", "accent", "accent", "accent2", "accent2")

    local manualBack = Instance.new("TextButton")
    manualBack.Size = UDim2.new(0, 20, 0, 20)
    manualBack.Position = UDim2.new(1, -32, 0, 6)
    manualBack.AnchorPoint = Vector2.new(1, 0)
    manualBack.BackgroundColor3 = Theme.bgMid
    manualBack.Text = "<"
    manualBack.TextColor3 = Theme.textDim
    manualBack.TextSize = 12
    manualBack.Font = Enum.Font.GothamBold
    manualBack.BorderSizePixel = 0
    manualBack.Parent = manualPanel
    corner(manualBack, 999)
    local manualBackStroke = stroke(manualBack, Theme.accent, 1)
    regFrame(manualBack, "bgMid")
    regText(manualBack, "textDim")
    regStroke(manualBackStroke, "accent")
    hoverEffect(manualBack, "bgMid", "bgLight", "accent", "accent2", "textDim")

    local tabBarFrame = Instance.new("Frame")
    tabBarFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    tabBarFrame.BackgroundTransparency = 1
    tabBarFrame.Position = UDim2.new(0.5, 0, 0.143, 0)
    tabBarFrame.Name = "TabBar"
    tabBarFrame.Size = UDim2.new(0, 489, 0, 24)
    tabBarFrame.BorderSizePixel = 0
    tabBarFrame.Parent = manualPanel

    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.Padding = UDim.new(0.01, 0)
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.FillDirection = Enum.FillDirection.Horizontal
    UIListLayout.Parent = tabBarFrame

    local function makeTab(name, label)
        local tab = Instance.new("ImageButton")
        tab.Name = name
        tab.ImageTransparency = 1
        tab.Size = UDim2.new(0, 100, 0, 24)
        tab.BorderSizePixel = 0
        tab.BackgroundColor3 = Theme.bgMid
        tab.Parent = tabBarFrame
        corner(tab, 6)
        local tabStroke = stroke(tab, Theme.accent, 1, 0.2)

        local lbl = Instance.new("TextLabel")
        lbl.TextWrapped = true
        lbl.TextColor3 = Theme.text
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
        local tabGrad = applyGradient(tab, Theme.accent, Theme.accent2, -90)
        regGradient(tabGrad, "accent", "accent2")
        regFrame(tab, "bgMid")
        regText(lbl, "text")
        regStroke(tabStroke, "accent")
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
        Entry.BackgroundColor3 = Theme.bgMid
        Entry.Parent = scannerTabFrame
        corner(Entry, 6)
        local entryStroke = stroke(Entry, Theme.accent, 1, 0.2)
        local entryGrad = applyGradient(Entry, Theme.accent, Theme.accent2, -90)
        regGradient(entryGrad, "accent", "accent2")
        regFrame(Entry, "bgMid")
        regStroke(entryStroke, "accent")

        local nameLbl = Instance.new("TextLabel")
        nameLbl.TextWrapped = true
        nameLbl.Name = "ProductName"
        nameLbl.TextColor3 = Theme.text
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
        regText(nameLbl, "text")

        local idLbl = Instance.new("TextLabel")
        idLbl.TextWrapped = true
        idLbl.Name = "ProductID"
        idLbl.TextColor3 = Theme.inputText
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
        regText(idLbl, "inputText")

        local CopyID = Instance.new("ImageButton")
        CopyID.ImageTransparency = 1
        CopyID.AnchorPoint = Vector2.new(0.5, 0.5)
        CopyID.Name = "CopyID"
        CopyID.Position = UDim2.new(0.948, 0, 0.5, 0)
        CopyID.Size = UDim2.new(0, 30, 0, 30)
        CopyID.BorderSizePixel = 0
        CopyID.BackgroundColor3 = Theme.bgLight
        CopyID.Parent = Entry
        corner(CopyID, 6)
        local copyStroke = stroke(CopyID, Theme.accent, 1, 0.2)
        regFrame(CopyID, "bgLight")
        regStroke(copyStroke, "accent")
        hoverEffect(CopyID, "bgLight", "accent", "accent", "accent2", nil)

        local Ico3 = Instance.new("ImageLabel")
        Ico3.ImageColor3 = Theme.text
        Ico3.Name = "Ico"
        Ico3.Size = UDim2.new(0, 26, 0, 26)
        Ico3.AnchorPoint = Vector2.new(0.5, 0.5)
        Ico3.Image = "rbxassetid://16884178261"
        Ico3.BackgroundTransparency = 1
        Ico3.ImageRectSize = Vector2.new(36, 36)
        Ico3.Position = UDim2.new(0.5, 0, 0.5, 0)
        Ico3.BorderSizePixel = 0
        Ico3.Parent = CopyID
        regImage(Ico3, "text")

        CopyID.MouseButton1Click:Connect(function()
            pcall(function() setclipboard(tostring(pid)) end)
        end)
    end

    local loadingLbl = Instance.new("TextLabel")
    loadingLbl.Name = "ShopLoading"
    loadingLbl.Size = UDim2.new(0, 464, 0, 40)
    loadingLbl.BackgroundTransparency = 1
    loadingLbl.Text = "Loading products..."
    loadingLbl.TextColor3 = Theme.textDim
    loadingLbl.TextSize = 14
    loadingLbl.Font = Enum.Font.GothamMedium
    loadingLbl.Parent = scannerTabFrame
    regText(loadingLbl, "textDim")

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
            errLbl.TextColor3 = Theme.accent2
            errLbl.TextSize = 14
            errLbl.Font = Enum.Font.GothamMedium
            errLbl.Parent = scannerTabFrame
            regText(errLbl, "accent2")
        end
    end

    ScanTab.MouseButton1Click:Connect(function()
        ScanTab.BackgroundColor3 = Theme.bgLight
        ActionTab.BackgroundColor3 = Theme.bgMid
        scannerTabFrame.Visible = true
        actionTabFrame.Visible = false
        loadShopProducts()
    end)
    ActionTab.MouseButton1Click:Connect(function()
        ScanTab.BackgroundColor3 = Theme.bgMid
        ActionTab.BackgroundColor3 = Theme.bgLight
        scannerTabFrame.Visible = false
        actionTabFrame.Visible = true
    end)
    ActionTab.BackgroundColor3 = Theme.bgLight
    actionTabFrame.Visible = true

    task.spawn(function()
        task.wait(1)
        loadShopProducts()
    end)

    local inputFrame = Instance.new("Frame")
    inputFrame.Active = true
    inputFrame.BackgroundTransparency = 0.4
    inputFrame.Name = "InputFrame"
    inputFrame.Size = UDim2.new(0, 464, 0, 27)
    inputFrame.Position = UDim2.new(0, 0, 0, 0)
    inputFrame.BorderSizePixel = 0
    inputFrame.BackgroundColor3 = Theme.bgMid
    inputFrame.Parent = actionTabFrame
    corner(inputFrame, 6)
    local inputStroke = stroke(inputFrame, Theme.accent, 1, 0.2)
    local inputGrad = applyGradient(inputFrame, Theme.accent, Theme.accent2, -90)
    regGradient(inputGrad, "accent", "accent2")
    regFrame(inputFrame, "bgMid")
    regStroke(inputStroke, "accent")

    local ProductIDInput = Instance.new("TextBox")
    ProductIDInput.CursorPosition = -1
    ProductIDInput.AnchorPoint = Vector2.new(0.5, 0.5)
    ProductIDInput.PlaceholderText = "Product ID"
    ProductIDInput.TextSize = 14
    ProductIDInput.Size = UDim2.new(0, 420, 0, 15)
    ProductIDInput.TextColor3 = Theme.inputText
    ProductIDInput.Text = ""
    ProductIDInput.Name = "ProductIDInput"
    ProductIDInput.Position = UDim2.new(0.514, 0, 0.5, 0)
    ProductIDInput.BorderSizePixel = 0
    ProductIDInput.Font = Enum.Font.Code
    ProductIDInput.BackgroundTransparency = 1
    ProductIDInput.TextXAlignment = Enum.TextXAlignment.Left
    ProductIDInput.ClearTextOnFocus = false
    ProductIDInput.TextScaled = true
    ProductIDInput.PlaceholderColor3 = Theme.textDim
    ProductIDInput.Parent = inputFrame
    regText(ProductIDInput, "inputText")

    local Ico = Instance.new("ImageLabel")
    Ico.Name = "Ico"
    Ico.Size = UDim2.new(0, 15, 0, 15)
    Ico.Position = UDim2.new(0.034, 0, 0.5, 0)
    Ico.AnchorPoint = Vector2.new(0.5, 0.5)
    Ico.Image = "rbxassetid://16167590360"
    Ico.BackgroundTransparency = 1
    Ico.ImageColor3 = Theme.accent2
    Ico.ImageRectSize = Vector2.new(16, 16)
    Ico.ImageRectOffset = Vector2.new(253, 492)
    Ico.BorderSizePixel = 0
    Ico.Parent = inputFrame
    regImage(Ico, "accent2")

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
    BuyBg.BackgroundColor3 = Theme.accent
    BuyBg.BorderSizePixel = 0
    BuyBg.ZIndex = 1
    BuyBg.Parent = BuyContainer
    corner(BuyBg, 6)
    local buyBgStroke = stroke(BuyBg, Theme.accent2, 1, 0.2)
    local buyBgGrad = applyGradient(BuyBg, Theme.accent, Theme.accent2, -90)
    regFrame(BuyBg, "accent")
    regStroke(buyBgStroke, "accent2")
    regGradient(buyBgGrad, "accent", "accent2")

    local BuyBtn = Instance.new("TextButton")
    BuyBtn.Size = UDim2.new(1, 0, 1, 0)
    BuyBtn.Name = "BuyBtn"
    BuyBtn.Position = UDim2.new(0, 0, 0, 0)
    BuyBtn.BackgroundTransparency = 1
    BuyBtn.Text = "BUY"
    BuyBtn.TextColor3 = Theme.text
    BuyBtn.TextSize = 16
    BuyBtn.Font = Enum.Font.GothamBold
    BuyBtn.BorderSizePixel = 0
    BuyBtn.ZIndex = 2
    BuyBtn.Parent = BuyContainer
    regText(BuyBtn, "text")

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
        BuyBtn.TextColor3 = color or Theme.text
    end

    local function startSpam(pid)
        if isSpamming then return end
        isSpamming = true
        setBuyText("SPAMMING...", Color3.fromRGB(255, 200, 140))
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
            setBuyText("BUY", Theme.text)
        end
    end

    BuyBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local pid = tonumber(ProductIDInput.Text)
            if not pid then
                setBuyText("INVALID ID", Color3.fromRGB(255, 140, 140))
                task.wait(1)
                if BuyBtn.Parent then setBuyText("BUY", Theme.text) end
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
                    setBuyText("BOUGHT!", Color3.fromRGB(120, 230, 120))
                    task.spawn(function()
                        task.wait(1.5)
                        if BuyBtn.Parent and not isSpamming then
                            setBuyText("BUY", Theme.text)
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

-- ============================================
-- COLOR + NAME EDITOR PANEL
-- ============================================
local colorPanel = Instance.new("Frame")
colorPanel.Name = "ColorPanel"
colorPanel.Size = UDim2.new(0, 420, 0, 550)
colorPanel.Position = UDim2.new(0.5, -210, 0.5, -275)
colorPanel.BackgroundColor3 = Theme.bgDark
colorPanel.BackgroundTransparency = 0.1
colorPanel.BorderSizePixel = 0
colorPanel.ClipsDescendants = true
colorPanel.Visible = false
colorPanel.Parent = screenGui
corner(colorPanel, 14)
local colorPanelStroke = glowStroke(colorPanel, Theme.accent, Theme.accent2, 1.5)
regFrame(colorPanel, "bgDark")
regGradient(colorPanelStroke:FindFirstChildOfClass("UIGradient"), "accent", "accent2")

local colorTitle = Instance.new("TextLabel")
colorTitle.Size = UDim2.new(1, 0, 0, 34)
colorTitle.Position = UDim2.new(0, 0, 0, 6)
colorTitle.BackgroundTransparency = 1
colorTitle.Text = "Color Editor"
colorTitle.TextSize = 16
colorTitle.Font = Enum.Font.GothamBold
colorTitle.Parent = colorPanel
local colorTitleGrad = applyTextGradient(colorTitle, Theme.accent, Theme.accent2)
regGradient(colorTitleGrad, "accent", "accent2")

local colorBack = Instance.new("TextButton")
colorBack.Size = UDim2.new(0, 24, 0, 24)
colorBack.Position = UDim2.new(1, -58, 0, 6)
colorBack.AnchorPoint = Vector2.new(1, 0)
colorBack.BackgroundColor3 = Theme.bgLight
colorBack.Text = "<"
colorBack.TextColor3 = Theme.text
colorBack.TextSize = 12
colorBack.Font = Enum.Font.GothamBold
colorBack.BorderSizePixel = 0
colorBack.Parent = colorPanel
corner(colorBack, 999)
local colorBackStroke = stroke(colorBack, Theme.accent, 1)
regFrame(colorBack, "bgLight")
regText(colorBack, "text")
regStroke(colorBackStroke, "accent")
hoverEffect(colorBack, "bgLight", "accent", "accent", "accent2", "text")

local colorClose = Instance.new("TextButton")
colorClose.Size = UDim2.new(0, 24, 0, 24)
colorClose.Position = UDim2.new(1, -6, 0, 6)
colorClose.AnchorPoint = Vector2.new(1, 0)
colorClose.BackgroundColor3 = Theme.bgLight
colorClose.Text = "X"
colorClose.TextColor3 = Theme.accent2
colorClose.TextSize = 10
colorClose.Font = Enum.Font.GothamBold
colorClose.BorderSizePixel = 0
colorClose.Parent = colorPanel
corner(colorClose, 999)
local colorCloseStroke = stroke(colorClose, Theme.accent, 1)
regFrame(colorClose, "bgLight")
regText(colorClose, "accent2")
regStroke(colorCloseStroke, "accent")
hoverEffect(colorClose, "bgLight", "accent", "accent", "accent2", "accent2")

-- ============================================
-- NOME DO SCRIPT
-- ============================================
local nameSection = Instance.new("Frame")
nameSection.Name = "NameSection"
nameSection.Size = UDim2.new(1, -16, 0, 62)
nameSection.Position = UDim2.new(0, 8, 0, 40)
nameSection.BackgroundColor3 = Theme.bgMid
nameSection.BackgroundTransparency = 0.3
nameSection.BorderSizePixel = 0
nameSection.Parent = colorPanel
corner(nameSection, 8)
local nameSectionStroke = stroke(nameSection, Theme.accent, 1, 0.3)
regFrame(nameSection, "bgMid")
regStroke(nameSectionStroke, "accent")

local nameLblTitle = Instance.new("TextLabel")
nameLblTitle.Size = UDim2.new(0, 200, 0, 16)
nameLblTitle.Position = UDim2.new(0, 8, 0, 4)
nameLblTitle.BackgroundTransparency = 1
nameLblTitle.Text = "Script Name"
nameLblTitle.TextColor3 = Theme.text
nameLblTitle.TextSize = 11
nameLblTitle.Font = Enum.Font.GothamBold
nameLblTitle.TextXAlignment = Enum.TextXAlignment.Left
nameLblTitle.Parent = nameSection
regText(nameLblTitle, "text")

local nameInputFrame = Instance.new("Frame")
nameInputFrame.Size = UDim2.new(1, -16, 0, 30)
nameInputFrame.Position = UDim2.new(0, 8, 0, 24)
nameInputFrame.BackgroundColor3 = Theme.bgLight
nameInputFrame.BorderSizePixel = 0
nameInputFrame.Parent = nameSection
corner(nameInputFrame, 6)
local nameInputStroke = stroke(nameInputFrame, Theme.accent, 1, 0.4)
regFrame(nameInputFrame, "bgLight")
regStroke(nameInputStroke, "accent")

local nameInput = Instance.new("TextBox")
nameInput.Size = UDim2.new(1, -12, 1, 0)
nameInput.Position = UDim2.new(0, 6, 0, 0)
nameInput.BackgroundTransparency = 1
nameInput.Text = ScriptName
nameInput.PlaceholderText = "Enter script name..."
nameInput.PlaceholderColor3 = Theme.textDim
nameInput.TextColor3 = Theme.text
nameInput.TextSize = 13
nameInput.Font = Enum.Font.GothamBold
nameInput.TextXAlignment = Enum.TextXAlignment.Left
nameInput.ClearTextOnFocus = false
nameInput.BorderSizePixel = 0
nameInput.Parent = nameInputFrame
regText(nameInput, "text")

-- ============================================
-- COLOR ENTRIES
-- ============================================
local colorScroll = Instance.new("ScrollingFrame")
colorScroll.Size = UDim2.new(1, -16, 1, -230)
colorScroll.Position = UDim2.new(0, 8, 0, 110)
colorScroll.BackgroundTransparency = 1
colorScroll.BorderSizePixel = 0
colorScroll.ScrollBarThickness = 4
colorScroll.ScrollBarImageColor3 = Theme.accent
colorScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
colorScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
colorScroll.Parent = colorPanel
regFrame(colorScroll, "accent")

local colorList = Instance.new("UIListLayout", colorScroll)
colorList.SortOrder = Enum.SortOrder.LayoutOrder
colorList.Padding = UDim.new(0, 8)

local colorPad = Instance.new("UIPadding", colorScroll)
colorPad.PaddingTop = UDim.new(0, 4)
colorPad.PaddingBottom = UDim.new(0, 4)

local colorEntries = {}

local function rgbToHex(c)
    return string.format("#%02X%02X%02X",
        math.floor(c.R * 255),
        math.floor(c.G * 255),
        math.floor(c.B * 255))
end

local function createColorEntry(label, key)
    local initialColor = Theme[key]

    local entry = Instance.new("Frame")
    entry.Name = "ColorEntry"
    entry.Size = UDim2.new(1, -8, 0, 62)
    entry.BackgroundColor3 = Theme.bgMid
    entry.BackgroundTransparency = 0.3
    entry.BorderSizePixel = 0
    entry.Parent = colorScroll
    corner(entry, 8)
    local entryStroke = stroke(entry, Theme.accent, 1, 0.3)
    regFrame(entry, "bgMid")
    regStroke(entryStroke, "accent")

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size = UDim2.new(0, 120, 0, 16)
    nameLbl.Position = UDim2.new(0, 8, 0, 4)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = label
    nameLbl.TextColor3 = Theme.text
    nameLbl.TextSize = 11
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.Parent = entry
    regText(nameLbl, "text")

    local hexLbl = Instance.new("TextLabel")
    hexLbl.Size = UDim2.new(0, 80, 0, 16)
    hexLbl.Position = UDim2.new(1, -88, 0, 4)
    hexLbl.BackgroundTransparency = 1
    hexLbl.Text = rgbToHex(initialColor)
    hexLbl.TextColor3 = Theme.textDim
    hexLbl.TextSize = 10
    hexLbl.Font = Enum.Font.Code
    hexLbl.TextXAlignment = Enum.TextXAlignment.Right
    hexLbl.Parent = entry
    regText(hexLbl, "textDim")

    local preview = Instance.new("Frame")
    preview.Size = UDim2.new(0, 24, 0, 24)
    preview.Position = UDim2.new(0, 8, 0, 28)
    preview.BackgroundColor3 = initialColor
    preview.BorderSizePixel = 0
    preview.Parent = entry
    corner(preview, 4)
    local previewStroke = stroke(preview, Theme.accent, 1, 0.4)
    regStroke(previewStroke, "accent")

    local values = {initialColor.R, initialColor.G, initialColor.B}

    local function updateColor()
        local c = Color3.new(values[1], values[2], values[3])
        preview.BackgroundColor3 = c
        hexLbl.Text = rgbToHex(c)
    end

    local sliderNames = {"R", "G", "B"}
    local sliderFrames = {}

    for i = 1, 3 do
        local sliderFrame = Instance.new("Frame")
        sliderFrame.Size = UDim2.new(0, 104, 0, 24)
        sliderFrame.Position = UDim2.new(0, 38 + (i-1) * 108, 0, 28)
        sliderFrame.BackgroundColor3 = Theme.bgLight
        sliderFrame.BorderSizePixel = 0
        sliderFrame.Parent = entry
        corner(sliderFrame, 4)
        sliderFrames[i] = sliderFrame
        regFrame(sliderFrame, "bgLight")

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new(values[i], 0, 1, 0)
        fill.BackgroundColor3 = Theme.accent
        fill.BackgroundTransparency = 0.5
        fill.BorderSizePixel = 0
        fill.Parent = sliderFrame
        corner(fill, 4)
        regFrame(fill, "accent")

        local slider = Instance.new("TextButton")
        slider.Size = UDim2.new(1, 0, 1, 0)
        slider.BackgroundTransparency = 1
        slider.Text = sliderNames[i]
        slider.TextColor3 = Theme.text
        slider.TextSize = 10
        slider.Font = Enum.Font.GothamBold
        slider.Parent = sliderFrame
        regText(slider, "text")

        local function updateSlider(input)
            local relX = math.clamp((input.Position.X - sliderFrame.AbsolutePosition.X) / sliderFrame.AbsoluteSize.X, 0, 1)
            values[i] = relX
            fill.Size = UDim2.new(relX, 0, 1, 0)
            updateColor()
        end

        slider.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                updateSlider(input)
                local moveConn, endConn
                moveConn = UserInputService.InputChanged:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
                        updateSlider(inp)
                    end
                end)
                endConn = UserInputService.InputEnded:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                        if moveConn then moveConn:Disconnect() end
                        if endConn then endConn:Disconnect() end
                    end
                end)
            end
        end)
    end

    table.insert(colorEntries, {
        key = key,
        update = function(newColor)
            values[1] = newColor.R
            values[2] = newColor.G
            values[3] = newColor.B
            updateColor()
            for i = 1, 3 do
                local fill = sliderFrames[i]:FindFirstChildOfClass("Frame")
                if fill then fill.Size = UDim2.new(values[i], 0, 1, 0) end
            end
        end,
        getValue = function()
            return Color3.new(values[1], values[2], values[3])
        end
    })
end

createColorEntry("Background Dark", "bgDark")
createColorEntry("Background Mid", "bgMid")
createColorEntry("Background Light", "bgLight")
createColorEntry("Accent", "accent")
createColorEntry("Accent 2", "accent2")
createColorEntry("Text", "text")
createColorEntry("Text Dim", "textDim")
createColorEntry("Input Text", "inputText")

local applyBtn = Instance.new("TextButton")
applyBtn.Size = UDim2.new(0, 180, 0, 34)
applyBtn.Position = UDim2.new(0.5, -190, 1, -46)
applyBtn.BackgroundColor3 = Theme.accent
applyBtn.Text = "APPLY"
applyBtn.TextColor3 = Theme.text
applyBtn.TextSize = 13
applyBtn.Font = Enum.Font.GothamBold
applyBtn.BorderSizePixel = 0
applyBtn.Parent = colorPanel
corner(applyBtn, 8)
local applyStroke = stroke(applyBtn, Theme.accent2, 1)
regFrame(applyBtn, "accent")
regText(applyBtn, "text")
regStroke(applyStroke, "accent2")
hoverEffect(applyBtn, "accent", "accent2", "accent2", "accent", "text")

local resetBtn = Instance.new("TextButton")
resetBtn.Size = UDim2.new(0, 180, 0, 34)
resetBtn.Position = UDim2.new(0.5, 10, 1, -46)
resetBtn.BackgroundColor3 = Theme.bgLight
resetBtn.Text = "RESET"
resetBtn.TextColor3 = Theme.text
resetBtn.TextSize = 13
resetBtn.Font = Enum.Font.GothamBold
resetBtn.BorderSizePixel = 0
resetBtn.Parent = colorPanel
corner(resetBtn, 8)
local resetStroke = stroke(resetBtn, Theme.accent, 1)
regFrame(resetBtn, "bgLight")
regText(resetBtn, "text")
regStroke(resetStroke, "accent")
hoverEffect(resetBtn, "bgLight", "accent", "accent", "accent2", "text")

applyBtn.MouseButton1Click:Connect(function()
    for _, entry in ipairs(colorEntries) do
        Theme[entry.key] = entry.getValue()
    end
    applyTheme()
    local newName = nameInput.Text
    if newName and newName ~= "" then
        ScriptName = newName
        applyScriptName()
    end
    applyBtn.Text = "APPLIED!"
    task.wait(0.8)
    applyBtn.Text = "APPLY"
end)

resetBtn.MouseButton1Click:Connect(function()
    Theme.bgDark    = Color3.fromRGB(16, 0, 0)
    Theme.bgMid     = Color3.fromRGB(30, 5, 5)
    Theme.bgLight   = Color3.fromRGB(45, 10, 10)
    Theme.accent    = Color3.fromRGB(200, 0, 0)
    Theme.accent2   = Color3.fromRGB(255, 50, 50)
    Theme.text      = Color3.fromRGB(255, 200, 200)
    Theme.textDim   = Color3.fromRGB(180, 100, 100)
    Theme.inputText = Color3.fromRGB(255, 100, 100)

    for _, entry in ipairs(colorEntries) do
        entry.update(Theme[entry.key])
    end

    ScriptName = "Spider"
    nameInput.Text = ScriptName
    applyScriptName()
    applyTheme()
    resetBtn.Text = "RESET!"
    task.wait(0.8)
    resetBtn.Text = "RESET"
end)

do
    local dragging, dragStart, startPos
    colorPanel.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if input.Target == colorBack or input.Target == colorClose
                or input.Target == applyBtn or input.Target == resetBtn
                or input.Target == nameInput then return end
            dragging = true
            dragStart = input.Position
            startPos = colorPanel.Position
        end
    end)
    connect(UserInputService.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            colorPanel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- ============================================
-- MENU BUTTONS
-- ============================================
colorBtn.MouseButton1Click:Connect(function()
    modeWindow.Visible = false
    colorPanel.Visible = true
    colorPanel.Size = UDim2.new(0, 0, 0, 0)
    TweenService:Create(colorPanel, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 420, 0, 550)
    }):Play()
end)

colorBack.MouseButton1Click:Connect(function()
    colorPanel.Visible = false
    modeWindow.Visible = true
end)

colorClose.MouseButton1Click:Connect(function()
    colorPanel.Visible = false
    modeWindow.Visible = true
end)

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

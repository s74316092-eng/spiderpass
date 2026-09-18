local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local MarketplaceService
pcall(function() MarketplaceService = game:GetService("MarketplaceService") end)

local player = Players.LocalPlayer
if not player then return end
local playerGui = player:WaitForChild("PlayerGui", 10)
if not playerGui then return end

if playerGui:FindFirstChild("Spider") then
	playerGui.Spider:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "Spider"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
screenGui.Enabled = true
screenGui.DisplayOrder = 999
screenGui.Parent = playerGui

-- ============================================
-- VIEWPORT / MOBILE
-- ============================================
local isMobile = UserInputService.TouchEnabled
local viewport = Vector2.new(1280, 720)
pcall(function()
	if workspace.CurrentCamera then
		viewport = workspace.CurrentCamera.ViewportSize
	end
end)

local function isSmallScreen()
	return viewport.X < 700
end

local connections = {}
local function connect(signal, callback)
	local conn = signal:Connect(callback)
	table.insert(connections, conn)
	return conn
end

-- ============================================
-- UI HELPERS
-- ============================================
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
		ColorSequenceKeypoint.new(1, c2),
	})
	g.Rotation = 45
	return s
end

local function applyGradient(frame, c1, c2, rotation)
	local g = Instance.new("UIGradient", frame)
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, c1),
		ColorSequenceKeypoint.new(1, c2),
	})
	g.Rotation = rotation or 45
	return g
end

local function applyTextGradient(label, c1, c2)
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	local g = Instance.new("UIGradient", label)
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, c1),
		ColorSequenceKeypoint.new(1, c2),
	})
	g.Rotation = 0
	return g
end

local function getTime()
	return os.date("%H:%M:%S")
end

-- ============================================
-- THEME
-- ============================================
local Theme = {
	bgDark = Color3.fromRGB(16, 0, 0),
	bgMid = Color3.fromRGB(30, 5, 5),
	bgLight = Color3.fromRGB(45, 10, 10),
	accent = Color3.fromRGB(200, 0, 0),
	accent2 = Color3.fromRGB(255, 50, 50),
	text = Color3.fromRGB(255, 200, 200),
	textDim = Color3.fromRGB(180, 100, 100),
	inputText = Color3.fromRGB(255, 100, 100),
}

local ThemeTargets = { frames = {}, strokes = {}, texts = {}, gradients = {}, images = {} }
local function regFrame(obj, key) if obj then table.insert(ThemeTargets.frames, { obj = obj, key = key }) end end
local function regStroke(obj, key) if obj then table.insert(ThemeTargets.strokes, { obj = obj, key = key }) end end
local function regText(obj, key) if obj then table.insert(ThemeTargets.texts, { obj = obj, key = key }) end end
local function regGradient(obj, k1, k2) if obj then table.insert(ThemeTargets.gradients, { obj = obj, key1 = k1, key2 = k2 }) end end
local function regImage(obj, key) if obj then table.insert(ThemeTargets.images, { obj = obj, key = key }) end end

local function applyTheme()
	for _, t in ipairs(ThemeTargets.frames) do pcall(function() t.obj.BackgroundColor3 = Theme[t.key] end) end
	for _, t in ipairs(ThemeTargets.strokes) do pcall(function() t.obj.Color = Theme[t.key] end) end
	for _, t in ipairs(ThemeTargets.texts) do pcall(function() t.obj.TextColor3 = Theme[t.key] end) end
	for _, t in ipairs(ThemeTargets.gradients) do
		pcall(function()
			t.obj.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Theme[t.key1]),
				ColorSequenceKeypoint.new(1, Theme[t.key2]),
			})
		end)
	end
	for _, t in ipairs(ThemeTargets.images) do pcall(function() t.obj.ImageColor3 = Theme[t.key] end) end
end

local function hoverEffect(btn)
	local scale = Instance.new("UIScale", btn)
	scale.Scale = 1
	btn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			TweenService:Create(scale, TweenInfo.new(0.08), { Scale = 0.93 }):Play()
		end
	end)
	btn.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			TweenService:Create(scale, TweenInfo.new(0.15), { Scale = 1 }):Play()
		end
	end)
end

-- ============================================
-- FAKE SIGNAL
-- ============================================
local suppressCounter = 0
local addLog

local function fireFakeSignal(kind, id)
	if not MarketplaceService then return end
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
-- SCRIPT NAME
-- ============================================
local ScriptName = "Spider"
local NameTargets = {}
local function regName(obj, suffix) table.insert(NameTargets, { obj = obj, suffix = suffix or "" }) end
local function applyScriptName()
	for _, t in ipairs(NameTargets) do pcall(function() t.obj.Text = ScriptName .. t.suffix end) end
end

-- ============================================
-- PRODUCT NAME CACHE
-- ============================================
local productNameCache = {}
local function registerProductName(id, name)
	if id and name then
		productNameCache[tostring(id)] = name
	end
end
local function getProductName(id)
	return productNameCache[tostring(id)] or ("Produto " .. tostring(id))
end

-- ============================================
-- DRAG
-- ============================================
local function makeDraggable(target, handle, extraIgnore)
	handle = handle or target
	target.Active = true
	if handle ~= target then
		handle.Active = true
	end

	local dragging, dragStart, startPos

	local function isInteractive(obj)
		return obj:IsA("GuiButton") or obj:IsA("TextBox") or obj:IsA("ScrollingFrame")
	end

	local function isIgnored(obj)
		if not obj then return false end
		if extraIgnore then
			for _, o in ipairs(extraIgnore) do
				if obj == o or (obj.IsDescendantOf and obj:IsDescendantOf(o)) then
					return true
				end
			end
		end
		local cur = obj
		local depth = 0
		while cur and cur ~= target and depth < 25 do
			if isInteractive(cur) then
				return true
			end
			cur = cur.Parent
			depth = depth + 1
		end
		return false
	end

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			if isIgnored(input.Target) then return end
			if UserInputService:GetFocusedTextBox() then return end
			dragging = true
			dragStart = input.Position
			startPos = target.Position
		end
	end)

	connect(UserInputService.InputChanged, function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - dragStart
			target.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + d.X,
				startPos.Y.Scale, startPos.Y.Offset + d.Y
			)
		end
	end)

	connect(UserInputService.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
end

-- ============================================
-- DIMENSÕES
-- ============================================
local fs = isMobile and 0.75 or 1
local titleH = isMobile and 28 or 34

local function getPanelSize()
	if isSmallScreen() then return UDim2.new(0, math.min(viewport.X - 20, 320), 0, math.min(viewport.Y - 80, 300))
	elseif isMobile then return UDim2.new(0, math.min(viewport.X - 30, 380), 0, math.min(viewport.Y - 100, 340))
	else return UDim2.new(0, 420, 0, 340) end
end

local function getManualSize()
	if isSmallScreen() then return UDim2.new(0, math.min(viewport.X - 20, 340), 0, math.min(viewport.Y - 80, 320))
	elseif isMobile then return UDim2.new(0, math.min(viewport.X - 30, 400), 0, math.min(viewport.Y - 100, 360))
	else return UDim2.new(0, 450, 0, 340) end
end

local function getModeSize()
	if isSmallScreen() then return UDim2.new(0, 260, 0, 210)
	elseif isMobile then return UDim2.new(0, 280, 0, 220)
	else return UDim2.new(0, 320, 0, 250) end
end

local function getColorPanelSize()
	local w, h
	if isSmallScreen() then
		w = math.min(viewport.X - 20, 300)
		h = math.min(viewport.Y - 40, 380)
	elseif isMobile then
		w = math.min(viewport.X - 30, 330)
		h = math.min(viewport.Y - 60, 430)
	else
		w = 380
		h = 480
	end
	return UDim2.new(0, w, 0, h)
end

-- ============================================
-- MODE SELECT
-- ============================================
local modeSize = getModeSize()

local modeWindow = Instance.new("Frame")
modeWindow.Name = "ModeSelect"
modeWindow.Size = modeSize
modeWindow.Position = UDim2.new(0.5, 0, 0.5, 0)
modeWindow.AnchorPoint = Vector2.new(0.5, 0.5)
modeWindow.BackgroundColor3 = Theme.bgDark
modeWindow.BackgroundTransparency = 0.1
modeWindow.BorderSizePixel = 0
modeWindow.ClipsDescendants = true
modeWindow.Visible = true
modeWindow.Active = true
modeWindow.Parent = screenGui
corner(modeWindow, 10)

local modeStroke = glowStroke(modeWindow, Theme.accent, Theme.accent2, 1.2)
regFrame(modeWindow, "bgDark")
regGradient(modeStroke:FindFirstChildOfClass("UIGradient"), "accent", "accent2")

local modeTitle = Instance.new("TextLabel")
modeTitle.Size = UDim2.new(1, 0, 0, 26)
modeTitle.Position = UDim2.new(0, 0, 0, 10)
modeTitle.BackgroundTransparency = 1
modeTitle.Text = "Select Mode"
modeTitle.TextSize = 15
modeTitle.Font = Enum.Font.GothamBold
modeTitle.Parent = modeWindow
regGradient(applyTextGradient(modeTitle, Theme.accent, Theme.accent2), "accent", "accent2")

local modeSub = Instance.new("TextLabel")
modeSub.Size = UDim2.new(1, 0, 0, 16)
modeSub.Position = UDim2.new(0, 0, 0, 38)
modeSub.BackgroundTransparency = 1
modeSub.Text = "Choose how to run"
modeSub.TextColor3 = Theme.textDim
modeSub.TextSize = 10
modeSub.Font = Enum.Font.Gotham
modeSub.Parent = modeWindow
regText(modeSub, "textDim")

local autoBtn = Instance.new("TextButton")
autoBtn.Size = UDim2.new(0, 100, 0, 50)
autoBtn.Position = UDim2.new(0.5, -110, 0, 65)
autoBtn.BackgroundColor3 = Theme.accent
autoBtn.Text = "AUTOMATIC"
autoBtn.TextColor3 = Theme.text
autoBtn.TextSize = 11
autoBtn.Font = Enum.Font.GothamBold
autoBtn.BorderSizePixel = 0
autoBtn.Parent = modeWindow
corner(autoBtn, 8)
regFrame(autoBtn, "accent")
regText(autoBtn, "text")
regStroke(stroke(autoBtn, Theme.accent2, 1), "accent2")
hoverEffect(autoBtn)

local manualBtn = Instance.new("TextButton")
manualBtn.Size = UDim2.new(0, 100, 0, 50)
manualBtn.Position = UDim2.new(0.5, 10, 0, 65)
manualBtn.BackgroundColor3 = Theme.bgMid
manualBtn.Text = "MANUAL"
manualBtn.TextColor3 = Theme.text
manualBtn.TextSize = 11
manualBtn.Font = Enum.Font.GothamBold
manualBtn.BorderSizePixel = 0
manualBtn.Parent = modeWindow
corner(manualBtn, 8)
regFrame(manualBtn, "bgMid")
regText(manualBtn, "text")
regStroke(stroke(manualBtn, Theme.accent, 1), "accent")
hoverEffect(manualBtn)

local colorBtn = Instance.new("TextButton")
colorBtn.Size = UDim2.new(1, -24, 0, 32)
colorBtn.Position = UDim2.new(0.5, 0, 0, 130)
colorBtn.AnchorPoint = Vector2.new(0.5, 0)
colorBtn.BackgroundColor3 = Theme.bgLight
colorBtn.Text = "EDIT COLORS"
colorBtn.TextColor3 = Theme.text
colorBtn.TextSize = 11
colorBtn.Font = Enum.Font.GothamBold
colorBtn.BorderSizePixel = 0
colorBtn.Parent = modeWindow
corner(colorBtn, 8)
regFrame(colorBtn, "bgLight")
regText(colorBtn, "text")
regStroke(stroke(colorBtn, Theme.accent, 1), "accent")
hoverEffect(colorBtn)

makeDraggable(modeWindow, modeWindow)

-- ============================================
-- AUTO PANEL
-- ============================================
local panelSize = getPanelSize()

local autoPanel = Instance.new("Frame")
autoPanel.Name = "AutoPanel"
autoPanel.Size = panelSize
autoPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
autoPanel.AnchorPoint = Vector2.new(0.5, 0.5)
autoPanel.BackgroundColor3 = Theme.bgDark
autoPanel.BackgroundTransparency = 0.3
autoPanel.BorderSizePixel = 0
autoPanel.Visible = false
autoPanel.ClipsDescendants = true
autoPanel.Parent = screenGui
corner(autoPanel, 10)
local autoPanelStroke = glowStroke(autoPanel, Theme.accent, Theme.accent2, 1.2)
regFrame(autoPanel, "bgDark")
regGradient(autoPanelStroke:FindFirstChildOfClass("UIGradient"), "accent", "accent2")

local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, titleH)
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
regGradient(applyGradient(sep, Theme.accent, Theme.accent2), "accent", "accent2")

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -110, 1, 0)
titleText.Position = UDim2.new(0, 8, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = ScriptName .. " — Auto"
titleText.TextSize = 11
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Font = Enum.Font.GothamBold
titleText.Parent = titleBar
regGradient(applyTextGradient(titleText, Theme.accent, Theme.accent2), "accent", "accent2")
regName(titleText, " — Auto")

local function makeIconBtn(parent, txt, xOff, bgKey, txtKey, strokeKey)
	local b = Instance.new("TextButton")
	local sz = isMobile and 22 or 20
	b.Size = UDim2.new(0, sz, 0, sz)
	b.Position = UDim2.new(1, xOff, 0.5, 0)
	b.AnchorPoint = Vector2.new(1, 0.5)
	b.BackgroundColor3 = Theme[bgKey]
	b.Text = txt
	b.TextColor3 = Theme[txtKey]
	b.TextSize = (isMobile and 11 or 10)
	b.Font = Enum.Font.GothamBold
	b.BorderSizePixel = 0
	b.ZIndex = 10
	b.Parent = parent
	corner(b, 999)
	regFrame(b, bgKey)
	regText(b, txtKey)
	regStroke(stroke(b, Theme[strokeKey], 1), strokeKey)
	return b
end

local iconSpacing = isMobile and 25 or 24
local backFromAuto = makeIconBtn(titleBar, "<", -(iconSpacing * 2), "bgMid", "textDim", "textDim")
local minBtn = makeIconBtn(titleBar, "-", -iconSpacing, "bgMid", "textDim", "textDim")
local closeBtn = makeIconBtn(titleBar, "X", -4, "bgLight", "accent2", "accent2")
hoverEffect(minBtn)
hoverEffect(closeBtn)
hoverEffect(backFromAuto)

makeDraggable(autoPanel, autoPanel)

local contentContainer = Instance.new("Frame")
contentContainer.Name = "Content"
contentContainer.Size = UDim2.new(1, 0, 1, -titleH)
contentContainer.Position = UDim2.new(0, 0, 0, titleH)
contentContainer.BackgroundTransparency = 1
contentContainer.ClipsDescendants = true
contentContainer.Parent = autoPanel

local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, 0, 0, 26)
tabBar.BackgroundColor3 = Theme.bgMid
tabBar.BackgroundTransparency = 0.2
tabBar.BorderSizePixel = 0
tabBar.Parent = contentContainer
regFrame(tabBar, "bgMid")

local tabLogs = Instance.new("TextButton")
tabLogs.Size = UDim2.new(0, 70, 1, 0)
tabLogs.BackgroundColor3 = Theme.bgMid
tabLogs.Text = "Logs"
tabLogs.TextColor3 = Theme.text
tabLogs.TextSize = 11
tabLogs.Font = Enum.Font.GothamBold
tabLogs.BorderSizePixel = 0
tabLogs.Parent = tabBar
corner(tabLogs, 0)
regFrame(tabLogs, "bgMid")
regText(tabLogs, "text")

local tabProducts = Instance.new("TextButton")
tabProducts.Size = UDim2.new(0, 70, 1, 0)
tabProducts.Position = UDim2.new(0, 70, 0, 0)
tabProducts.BackgroundColor3 = Theme.bgMid
tabProducts.Text = "Products"
tabProducts.TextColor3 = Theme.textDim
tabProducts.TextSize = 11
tabProducts.Font = Enum.Font.GothamBold
tabProducts.BorderSizePixel = 0
tabProducts.Parent = tabBar
corner(tabProducts, 0)
regFrame(tabProducts, "bgMid")
regText(tabProducts, "textDim")

local logArea = Instance.new("ScrollingFrame")
logArea.Size = UDim2.new(1, -8, 1, -(26 + 4))
logArea.Position = UDim2.new(0, 4, 0, 26 + 4)
logArea.BackgroundTransparency = 1
logArea.BorderSizePixel = 0
logArea.ScrollBarThickness = isMobile and 4 or 3
logArea.ScrollBarImageColor3 = Theme.accent
logArea.CanvasSize = UDim2.new(0, 0, 0, 0)
logArea.AutomaticCanvasSize = Enum.AutomaticSize.Y
logArea.Parent = contentContainer

local listLayout = Instance.new("UIListLayout", logArea)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 4)
local logPad = Instance.new("UIPadding", logArea)
logPad.PaddingTop = UDim.new(0, 2)
logPad.PaddingBottom = UDim.new(0, 2)
logPad.PaddingLeft = UDim.new(0, 2)
logPad.PaddingRight = UDim.new(0, 2)

local productArea = Instance.new("ScrollingFrame")
productArea.Size = UDim2.new(1, -8, 1, -(26 + 4))
productArea.Position = UDim2.new(0, 4, 0, 26 + 4)
productArea.BackgroundTransparency = 1
productArea.BorderSizePixel = 0
productArea.ScrollBarThickness = isMobile and 4 or 3
productArea.ScrollBarImageColor3 = Theme.accent
productArea.CanvasSize = UDim2.new(0, 0, 0, 0)
productArea.AutomaticCanvasSize = Enum.AutomaticSize.Y
productArea.Visible = false
productArea.Parent = contentContainer

local productListLayout = Instance.new("UIListLayout", productArea)
productListLayout.SortOrder = Enum.SortOrder.LayoutOrder
productListLayout.Padding = UDim.new(0, 4)
local productPad = Instance.new("UIPadding", productArea)
productPad.PaddingTop = UDim.new(0, 2)
productPad.PaddingBottom = UDim.new(0, 2)
productPad.PaddingLeft = UDim.new(0, 2)
productPad.PaddingRight = UDim.new(0, 2)

local buyAllProductsBtn = Instance.new("TextButton")
buyAllProductsBtn.Size = UDim2.new(1, -4, 0, 26)
buyAllProductsBtn.Position = UDim2.new(0, 2, 0, 2)
buyAllProductsBtn.BackgroundColor3 = Theme.accent
buyAllProductsBtn.Text = "Buy All (loading...)"
buyAllProductsBtn.TextColor3 = Theme.text
buyAllProductsBtn.TextSize = 11
buyAllProductsBtn.Font = Enum.Font.GothamBold
buyAllProductsBtn.BorderSizePixel = 0
buyAllProductsBtn.Parent = productArea
corner(buyAllProductsBtn, 5)
regFrame(buyAllProductsBtn, "accent")
regText(buyAllProductsBtn, "text")
regStroke(stroke(buyAllProductsBtn, Theme.accent2, 1), "accent2")
hoverEffect(buyAllProductsBtn)

local developerProducts = {}

local function createProductEntry(devProduct)
	registerProductName(devProduct.ProductId, devProduct.Name)

	local entry = Instance.new("Frame")
	entry.Name = "ProductEntry"
	entry.Size = UDim2.new(1, -2, 0, 48)
	entry.BackgroundColor3 = Theme.bgMid
	entry.BackgroundTransparency = 0.3
	entry.BorderSizePixel = 0
	entry.ClipsDescendants = true
	entry.Parent = productArea
	corner(entry, 6)
	regFrame(entry, "bgMid")
	regStroke(stroke(entry, Theme.accent, 1, 0.3), "accent")

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size = UDim2.new(1, -90, 0, 14)
	nameLbl.Position = UDim2.new(0, 6, 0, 2)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text = devProduct.Name or "N/A"
	nameLbl.TextColor3 = Theme.text
	nameLbl.TextSize = 11
	nameLbl.Font = Enum.Font.GothamBold
	nameLbl.TextXAlignment = Enum.TextXAlignment.Left
	nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
	nameLbl.Parent = entry
	regText(nameLbl, "text")

	local idLbl = Instance.new("TextLabel")
	idLbl.Size = UDim2.new(0, 130, 0, 12)
	idLbl.Position = UDim2.new(0, 6, 0, 16)
	idLbl.BackgroundTransparency = 1
	idLbl.Text = "ID: " .. tostring(devProduct.ProductId)
	idLbl.TextColor3 = Theme.textDim
	idLbl.TextSize = 9
	idLbl.Font = Enum.Font.GothamMedium
	idLbl.TextXAlignment = Enum.TextXAlignment.Left
	idLbl.Parent = entry
	regText(idLbl, "textDim")

	local priceLbl = Instance.new("TextLabel")
	priceLbl.Size = UDim2.new(0, 130, 0, 12)
	priceLbl.Position = UDim2.new(0, 6, 0, 30)
	priceLbl.BackgroundTransparency = 1
	priceLbl.Text = "Price: " .. tostring(devProduct.PriceInRobux) .. " R$"
	priceLbl.TextColor3 = Theme.textDim
	priceLbl.TextSize = 9
	priceLbl.Font = Enum.Font.GothamMedium
	priceLbl.TextXAlignment = Enum.TextXAlignment.Left
	priceLbl.Parent = entry
	regText(priceLbl, "textDim")

	local buyBtn = Instance.new("TextButton")
	buyBtn.Size = UDim2.new(0, 70, 0, 28)
	buyBtn.Position = UDim2.new(1, -76, 0.5, -14)
	buyBtn.BackgroundColor3 = Theme.accent
	buyBtn.Text = "BUY"
	buyBtn.TextColor3 = Theme.text
	buyBtn.TextSize = 10
	buyBtn.Font = Enum.Font.GothamBold
	buyBtn.BorderSizePixel = 0
	buyBtn.Parent = entry
	corner(buyBtn, 4)
	regFrame(buyBtn, "accent")
	regText(buyBtn, "text")
	regStroke(stroke(buyBtn, Theme.accent, 0.8), "accent")
	hoverEffect(buyBtn)

	buyBtn.MouseButton1Click:Connect(function()
		local old = buyBtn.Text
		buyBtn.Text = "..."
		fireFakeSignal("Product", devProduct.ProductId)
		task.wait(0.8)
		buyBtn.Text = old
	end)
end

local function loadProducts()
	if not MarketplaceService then
		buyAllProductsBtn.Text = "Indisponível"
		return
	end
	local ok, products = pcall(function()
		return MarketplaceService:GetDeveloperProductsAsync():GetCurrentPage()
	end)
	if ok then
		developerProducts = products or {}
		for _, c in ipairs(productArea:GetChildren()) do
			if c.Name == "ProductEntry" then c:Destroy() end
		end
		for _, p in ipairs(developerProducts) do
			pcall(function() createProductEntry(p) end)
		end
		buyAllProductsBtn.Text = "Buy All (" .. #developerProducts .. ")"
	else
		buyAllProductsBtn.Text = "Erro"
	end
end
task.spawn(loadProducts)

buyAllProductsBtn.MouseButton1Click:Connect(function()
	local old = buyAllProductsBtn.Text
	buyAllProductsBtn.Text = "..."
	for _, p in ipairs(developerProducts) do
		fireFakeSignal("Product", p.ProductId)
		task.wait(0.01)
	end
	buyAllProductsBtn.Text = "Done!"
	task.wait(1.5)
	buyAllProductsBtn.Text = old
end)

-- ============================================
-- LOG SYSTEM
-- ============================================
local eventCount = 0

local function setEmpty(show)
	local e = logArea:FindFirstChild("EmptyState")
	if show and not e then
		local el = Instance.new("TextLabel")
		el.Name = "EmptyState"
		el.Size = UDim2.new(1, 0, 0, 60)
		el.BackgroundTransparency = 1
		el.Text = "Nenhum evento ainda."
		el.TextColor3 = Theme.textDim
		el.TextSize = 10
		el.Font = Enum.Font.GothamMedium
		el.LayoutOrder = 99999
		el.Parent = logArea
		regText(el, "textDim")
	elseif not show and e then
		e:Destroy()
	end
end

local function makeSmallBuyBtn(parent, id, signalType)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0, 42, 0, 22)
	b.AnchorPoint = Vector2.new(0.5, 0.5)
	b.Position = UDim2.new(0.5, 0, 0.5, 0)
	b.BackgroundColor3 = Theme.accent
	b.Text = "BUY"
	b.TextColor3 = Theme.text
	b.TextSize = 10
	b.Font = Enum.Font.GothamBold
	b.BorderSizePixel = 0
	b.Parent = parent
	corner(b, 4)
	regFrame(b, "accent")
	regText(b, "text")
	regStroke(stroke(b, Theme.accent2, 1), "accent2")
	hoverEffect(b)

	b.MouseButton1Click:Connect(function()
		local old = b.Text
		b.Text = "..."
		fireFakeSignal(signalType, id)
		b.Text = "OK"
		b.TextColor3 = Color3.fromRGB(120, 230, 120)
		task.wait(1)
		if b.Parent then
			b.Text = old
			b.TextColor3 = Theme.text
		end
	end)
	return b
end

addLog = function(label, id, signalType)
	setEmpty(false)

	local productName = getProductName(id)

	local entry = Instance.new("Frame")
	entry.Name = "EntryLog"
	entry.Size = UDim2.new(1, -2, 0, 0)
	entry.BackgroundColor3 = Theme.bgMid
	entry.BackgroundTransparency = 1
	entry.BorderSizePixel = 0
	entry.ClipsDescendants = true
	entry.LayoutOrder = -eventCount
	entry.Parent = logArea
	corner(entry, 6)
	local entryStroke = stroke(entry, Theme.accent, 1, 1)
	regFrame(entry, "bgMid")
	regStroke(entryStroke, "accent")

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0, 60, 0, 12)
	lbl.Position = UDim2.new(0, 8, 0, 3)
	lbl.BackgroundTransparency = 1
	lbl.Text = string.upper(label)
	lbl.TextColor3 = Theme.textDim
	lbl.TextTransparency = 1
	lbl.TextSize = 8
	lbl.Font = Enum.Font.GothamBold
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = entry
	regText(lbl, "textDim")

	local nameEl = Instance.new("TextLabel")
	nameEl.Size = UDim2.new(1, -110, 0, 12)
	nameEl.Position = UDim2.new(0, 8, 0, 16)
	nameEl.BackgroundTransparency = 1
	nameEl.Text = productName
	nameEl.TextColor3 = Theme.text
	nameEl.TextTransparency = 1
	nameEl.TextSize = 10
	nameEl.Font = Enum.Font.GothamBold
	nameEl.TextXAlignment = Enum.TextXAlignment.Left
	nameEl.TextTruncate = Enum.TextTruncate.AtEnd
	nameEl.Parent = entry
	regText(nameEl, "text")

	local infoEl = Instance.new("TextLabel")
	infoEl.Size = UDim2.new(1, -110, 0, 10)
	infoEl.Position = UDim2.new(0, 8, 0, 29)
	infoEl.BackgroundTransparency = 1
	infoEl.Text = "ID: " .. tostring(id) .. "  •  " .. getTime()
	infoEl.TextColor3 = Theme.textDim
	infoEl.TextTransparency = 1
	infoEl.TextSize = 9
	infoEl.Font = Enum.Font.Code
	infoEl.TextXAlignment = Enum.TextXAlignment.Left
	infoEl.Parent = entry
	regText(infoEl, "textDim")

	local btnHolder = Instance.new("Frame")
	btnHolder.Size = UDim2.new(0, 46, 1, 0)
	btnHolder.Position = UDim2.new(1, -48, 0, 0)
	btnHolder.BackgroundTransparency = 1
	btnHolder.Parent = entry

	makeSmallBuyBtn(btnHolder, id, signalType)

	local targetH = 44
	TweenService:Create(entry, TweenInfo.new(0.3), { Size = UDim2.new(1, -2, 0, targetH) }):Play()
	TweenService:Create(entry, TweenInfo.new(0.3), { BackgroundTransparency = 0.3 }):Play()
	TweenService:Create(entryStroke, TweenInfo.new(0.3), { Transparency = 0.2 }):Play()
	TweenService:Create(lbl, TweenInfo.new(0.3), { TextTransparency = 0 }):Play()
	TweenService:Create(nameEl, TweenInfo.new(0.3), { TextTransparency = 0 }):Play()
	TweenService:Create(infoEl, TweenInfo.new(0.3), { TextTransparency = 0 }):Play()

	eventCount = eventCount + 1
end

if MarketplaceService then
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
end

setEmpty(true)

local function switchTab(t)
	if t == "logs" then
		tabLogs.BackgroundColor3 = Theme.bgLight
		tabLogs.TextColor3 = Theme.text
		tabProducts.BackgroundColor3 = Theme.bgMid
		tabProducts.TextColor3 = Theme.textDim
		logArea.Visible = true
		productArea.Visible = false
	else
		tabProducts.BackgroundColor3 = Theme.bgLight
		tabProducts.TextColor3 = Theme.text
		tabLogs.BackgroundColor3 = Theme.bgMid
		tabLogs.TextColor3 = Theme.textDim
		logArea.Visible = false
		productArea.Visible = true
	end
end
tabLogs.MouseButton1Click:Connect(function() switchTab("logs") end)
tabProducts.MouseButton1Click:Connect(function() switchTab("products") end)
switchTab("logs")

-- ============================================
-- MANUAL PANEL
-- ============================================
local manualSize = getManualSize()

local manualPanel = Instance.new("Frame")
manualPanel.Name = "ManualPanel"
manualPanel.AnchorPoint = Vector2.new(0.5, 0.5)
manualPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
manualPanel.Size = manualSize
manualPanel.BackgroundColor3 = Theme.bgDark
manualPanel.BackgroundTransparency = 0.15
manualPanel.BorderSizePixel = 0
manualPanel.Visible = false
manualPanel.ClipsDescendants = true
manualPanel.Parent = screenGui
corner(manualPanel, 8)
local manualPanelStroke = glowStroke(manualPanel, Theme.accent, Theme.accent2, 1.2)
regFrame(manualPanel, "bgDark")
regGradient(manualPanelStroke:FindFirstChildOfClass("UIGradient"), "accent", "accent2")

local Header = Instance.new("TextLabel")
Header.TextColor3 = Color3.fromRGB(255, 255, 255)
Header.Text = ScriptName
Header.Name = "Header"
Header.Size = UDim2.new(0.5, 0, 0, 18)
Header.Position = UDim2.new(0.03, 0, 0.025, 0)
Header.BorderSizePixel = 0
Header.BackgroundTransparency = 1
Header.TextXAlignment = Enum.TextXAlignment.Left
Header.TextSize = 12
Header.Font = Enum.Font.GothamBold
Header.Parent = manualPanel
regGradient(applyTextGradient(Header, Theme.accent, Theme.accent2), "accent", "accent2")
regName(Header, "")

local closeSz = 22

local manualClose = Instance.new("TextButton")
manualClose.Size = UDim2.new(0, closeSz, 0, closeSz)
manualClose.Position = UDim2.new(1, -6, 0, 5)
manualClose.AnchorPoint = Vector2.new(1, 0)
manualClose.BackgroundColor3 = Theme.bgLight
manualClose.Text = "X"
manualClose.TextColor3 = Theme.accent2
manualClose.TextSize = 10
manualClose.Font = Enum.Font.GothamBold
manualClose.BorderSizePixel = 0
manualClose.Parent = manualPanel
corner(manualClose, 999)
regFrame(manualClose, "bgLight")
regText(manualClose, "accent2")
regStroke(stroke(manualClose, Theme.accent, 1), "accent")
hoverEffect(manualClose)

local manualBack = Instance.new("TextButton")
manualBack.Size = UDim2.new(0, closeSz, 0, closeSz)
manualBack.Position = UDim2.new(1, -(closeSz + 6), 0, 5)
manualBack.AnchorPoint = Vector2.new(1, 0)
manualBack.BackgroundColor3 = Theme.bgMid
manualBack.Text = "<"
manualBack.TextColor3 = Theme.textDim
manualBack.TextSize = 11
manualBack.Font = Enum.Font.GothamBold
manualBack.BorderSizePixel = 0
manualBack.Parent = manualPanel
corner(manualBack, 999)
regFrame(manualBack, "bgMid")
regText(manualBack, "textDim")
regStroke(stroke(manualBack, Theme.accent, 1), "accent")
hoverEffect(manualBack)

local tabBarFrame = Instance.new("Frame")
tabBarFrame.AnchorPoint = Vector2.new(0.5, 0)
tabBarFrame.BackgroundTransparency = 1
tabBarFrame.Position = UDim2.new(0.5, 0, 0.11, 0)
tabBarFrame.Name = "TabBar"
tabBarFrame.Size = UDim2.new(1, -16, 0, 24)
tabBarFrame.BorderSizePixel = 0
tabBarFrame.Parent = manualPanel

local tabListLayout = Instance.new("UIListLayout")
tabListLayout.Padding = UDim.new(0.02, 0)
tabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabListLayout.FillDirection = Enum.FillDirection.Horizontal
tabListLayout.Parent = tabBarFrame

local function makeTab(name, label)
	local tab = Instance.new("TextButton")
	tab.Name = name
	tab.AutoButtonColor = false
	tab.Size = UDim2.new(0.48, 0, 1, 0)
	tab.BorderSizePixel = 0
	tab.BackgroundColor3 = Theme.bgMid
	tab.Text = ""
	tab.Parent = tabBarFrame
	corner(tab, 5)
	regStroke(stroke(tab, Theme.accent, 1, 0.2), "accent")
	local lbl = Instance.new("TextLabel")
	lbl.TextColor3 = Theme.text
	lbl.Text = label
	lbl.Size = UDim2.new(0.9, 0, 0.75, 0)
	lbl.AnchorPoint = Vector2.new(0.5, 0.5)
	lbl.BorderSizePixel = 0
	lbl.BackgroundTransparency = 1
	lbl.Position = UDim2.new(0.5, 0, 0.5, 0)
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 11
	lbl.Parent = tab
	regGradient(applyGradient(tab, Theme.accent, Theme.accent2, -90), "accent", "accent2")
	regFrame(tab, "bgMid")
	regText(lbl, "text")
	return tab
end

local ScanTab = makeTab("ScanTab", "Shop")
local ActionTab = makeTab("ActionTab", "Activation")

local function makeFrame(name, scroll)
	local f
	if scroll then
		f = Instance.new("ScrollingFrame")
		f.AutomaticCanvasSize = Enum.AutomaticSize.Y
		f.CanvasSize = UDim2.new(0, 0, 0, 0)
		f.ScrollBarThickness = 4
		f.ScrollBarImageColor3 = Theme.accent
	else
		f = Instance.new("Frame")
	end
	f.Visible = false
	f.Name = name
	f.Size = UDim2.new(1, -16, 1, -70)
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.BackgroundTransparency = 1
	f.Position = UDim2.new(0.5, 0, 0.58, 0)
	f.BorderSizePixel = 0
	f.Parent = manualPanel
	local l = Instance.new("UIListLayout", f)
	l.Padding = UDim.new(0, 6)
	l.SortOrder = Enum.SortOrder.LayoutOrder
	return f
end

local scannerTabFrame = makeFrame("ScannerFrame", true)
local actionTabFrame = makeFrame("ActionFrame", false)
actionTabFrame.ClipsDescendants = true
local actLayout = actionTabFrame:FindFirstChildOfClass("UIListLayout")
if actLayout then actLayout:Destroy() end

makeDraggable(manualPanel, manualPanel)

local function createScannerEntry(pName, pid, price)
	registerProductName(pid, pName)

	local Entry = Instance.new("Frame")
	Entry.BackgroundTransparency = 0.4
	Entry.Name = "ProductEntry"
	Entry.Size = UDim2.new(1, -8, 0, 42)
	Entry.BorderSizePixel = 0
	Entry.BackgroundColor3 = Theme.bgMid
	Entry.Parent = scannerTabFrame
	corner(Entry, 5)
	regStroke(stroke(Entry, Theme.accent, 1, 0.2), "accent")
	regGradient(applyGradient(Entry, Theme.accent, Theme.accent2, -90), "accent", "accent2")
	regFrame(Entry, "bgMid")

	local nameLbl = Instance.new("TextLabel")
	nameLbl.TextColor3 = Theme.text
	nameLbl.Text = pName
	nameLbl.Size = UDim2.new(0.7, 0, 0, 14)
	nameLbl.Position = UDim2.new(0, 8, 0, 3)
	nameLbl.BorderSizePixel = 0
	nameLbl.BackgroundTransparency = 1
	nameLbl.TextXAlignment = Enum.TextXAlignment.Left
	nameLbl.Font = Enum.Font.Code
	nameLbl.TextSize = 11
	nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
	nameLbl.Parent = Entry
	regText(nameLbl, "text")

	local idLbl = Instance.new("TextLabel")
	idLbl.TextColor3 = Theme.inputText
	idLbl.Text = "ID: " .. tostring(pid)
	idLbl.Size = UDim2.new(0.7, 0, 0, 12)
	idLbl.Position = UDim2.new(0, 8, 0, 17)
	idLbl.BorderSizePixel = 0
	idLbl.BackgroundTransparency = 1
	idLbl.TextXAlignment = Enum.TextXAlignment.Left
	idLbl.Font = Enum.Font.Code
	idLbl.TextSize = 10
	idLbl.Parent = Entry
	regText(idLbl, "inputText")

	local priceLbl = Instance.new("TextLabel")
	priceLbl.TextColor3 = Theme.textDim
	priceLbl.Text = tostring(price) .. " R$"
	priceLbl.Size = UDim2.new(0.7, 0, 0, 12)
	priceLbl.Position = UDim2.new(0, 8, 0, 29)
	priceLbl.BorderSizePixel = 0
	priceLbl.BackgroundTransparency = 1
	priceLbl.TextXAlignment = Enum.TextXAlignment.Left
	priceLbl.Font = Enum.Font.Code
	priceLbl.TextSize = 9
	priceLbl.Parent = Entry
	regText(priceLbl, "textDim")

	local CopyID = Instance.new("TextButton")
	CopyID.AutoButtonColor = false
	CopyID.AnchorPoint = Vector2.new(1, 0.5)
	CopyID.Position = UDim2.new(1, -6, 0.5, 0)
	CopyID.Size = UDim2.new(0, 34, 0, 34)
	CopyID.BorderSizePixel = 0
	CopyID.Text = "ID"
	CopyID.TextColor3 = Theme.text
	CopyID.TextSize = 10
	CopyID.Font = Enum.Font.GothamBold
	CopyID.BackgroundColor3 = Theme.bgLight
	CopyID.Parent = Entry
	corner(CopyID, 5)
	regFrame(CopyID, "bgLight")
	regText(CopyID, "text")
	regStroke(stroke(CopyID, Theme.accent, 1, 0.2), "accent")
	hoverEffect(CopyID)

	CopyID.MouseButton1Click:Connect(function()
		pcall(function() setclipboard(tostring(pid)) end)
		local old = CopyID.Text
		CopyID.Text = "OK"
		task.wait(0.8)
		if CopyID.Parent then CopyID.Text = old end
	end)
end

local loadingLbl = Instance.new("TextLabel")
loadingLbl.Name = "ShopLoading"
loadingLbl.Size = UDim2.new(1, -8, 0, 30)
loadingLbl.BackgroundTransparency = 1
loadingLbl.Text = "Loading products..."
loadingLbl.TextColor3 = Theme.textDim
loadingLbl.TextSize = 11
loadingLbl.Font = Enum.Font.GothamMedium
loadingLbl.Parent = scannerTabFrame
regText(loadingLbl, "textDim")

local shopLoaded = false
local function loadShopProducts()
	if shopLoaded then return end
	shopLoaded = true
	if not MarketplaceService then
		if loadingLbl then loadingLbl.Text = "Indisponível" end
		return
	end
	for _, c in ipairs(scannerTabFrame:GetChildren()) do
		if c:IsA("Frame") and c.Name == "ProductEntry" then c:Destroy() end
	end
	local ok, pages = pcall(function()
		return MarketplaceService:GetDeveloperProductsAsync()
	end)
	if loadingLbl then loadingLbl:Destroy() end
	if ok and pages then
		local page = pages:GetCurrentPage()
		local safety = 0
		while true do
			for _, p in ipairs(page) do
				pcall(function() createScannerEntry(p.Name or "Unknown", p.ProductId or 0, p.PriceInRobux or 0) end)
			end
			if pages.IsFinished then break end
			local ok2 = pcall(function() pages:AdvanceToNextPageAsync() end)
			if not ok2 then break end
			page = pages:GetCurrentPage()
			safety = safety + 1
			if safety > 20 then break end
		end
	else
		local errLbl = Instance.new("TextLabel")
		errLbl.Size = UDim2.new(1, -8, 0, 24)
		errLbl.BackgroundTransparency = 1
		errLbl.Text = "Falha ao carregar."
		errLbl.TextColor3 = Theme.accent2
		errLbl.TextSize = 11
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

-- ---------- INPUT ----------
local inputFrame = Instance.new("Frame")
inputFrame.Active = true
inputFrame.BackgroundTransparency = 0.4
inputFrame.Name = "InputFrame"
inputFrame.Size = UDim2.new(0.78, 0, 0, 38)
inputFrame.Position = UDim2.new(0.5, 0, 0.32, 0)
inputFrame.AnchorPoint = Vector2.new(0.5, 0.5)
inputFrame.BorderSizePixel = 0
inputFrame.BackgroundColor3 = Theme.bgMid
inputFrame.Parent = actionTabFrame
corner(inputFrame, 5)
regGradient(applyGradient(inputFrame, Theme.accent, Theme.accent2, -90), "accent", "accent2")
regFrame(inputFrame, "bgMid")
regStroke(stroke(inputFrame, Theme.accent, 1, 0.2), "accent")

local ProductIDInput = Instance.new("TextBox")
ProductIDInput.CursorPosition = -1
ProductIDInput.AnchorPoint = Vector2.new(0.5, 0.5)
ProductIDInput.PlaceholderText = "Product ID"
ProductIDInput.TextSize = 13
ProductIDInput.Size = UDim2.new(0.82, 0, 0.75, 0)
ProductIDInput.TextColor3 = Theme.inputText
ProductIDInput.Text = ""
ProductIDInput.Position = UDim2.new(0.55, 0, 0.5, 0)
ProductIDInput.BorderSizePixel = 0
ProductIDInput.Font = Enum.Font.Code
ProductIDInput.BackgroundTransparency = 1
ProductIDInput.TextXAlignment = Enum.TextXAlignment.Left
ProductIDInput.ClearTextOnFocus = false
ProductIDInput.PlaceholderColor3 = Theme.textDim
ProductIDInput.Parent = inputFrame
regText(ProductIDInput, "inputText")

local Ico = Instance.new("ImageLabel")
Ico.Size = UDim2.new(0, 14, 0, 14)
Ico.Position = UDim2.new(0.07, 0, 0.5, 0)
Ico.AnchorPoint = Vector2.new(0.5, 0.5)
Ico.Image = "rbxassetid://16167590360"
Ico.BackgroundTransparency = 1
Ico.ImageColor3 = Theme.accent2
Ico.ImageRectSize = Vector2.new(16, 16)
Ico.ImageRectOffset = Vector2.new(253, 492)
Ico.BorderSizePixel = 0
Ico.Parent = inputFrame
regImage(Ico, "accent2")

-- ---------- BUY ----------
local BuyContainer = Instance.new("Frame")
BuyContainer.Name = "BuyContainer"
BuyContainer.Size = UDim2.new(0.6, 0, 0, 44)
BuyContainer.Position = UDim2.new(0.5, 0, 0.55, 0)
BuyContainer.AnchorPoint = Vector2.new(0.5, 0.5)
BuyContainer.BackgroundTransparency = 1
BuyContainer.BorderSizePixel = 0
BuyContainer.Parent = actionTabFrame

local BuyBg = Instance.new("Frame")
BuyBg.Name = "BuyBg"
BuyBg.Size = UDim2.new(1, 0, 1, 0)
BuyBg.BackgroundColor3 = Theme.accent
BuyBg.BorderSizePixel = 0
BuyBg.ZIndex = 1
BuyBg.Parent = BuyContainer
corner(BuyBg, 6)
regFrame(BuyBg, "accent")
regStroke(stroke(BuyBg, Theme.accent2, 1, 0.2), "accent2")
regGradient(applyGradient(BuyBg, Theme.accent, Theme.accent2, -90), "accent", "accent2")

local BuyBtn = Instance.new("TextButton")
BuyBtn.Size = UDim2.new(1, 0, 1, 0)
BuyBtn.Name = "BuyBtn"
BuyBtn.BackgroundTransparency = 1
BuyBtn.Text = "BUY"
BuyBtn.TextColor3 = Theme.text
BuyBtn.TextSize = 15
BuyBtn.Font = Enum.Font.GothamBold
BuyBtn.BorderSizePixel = 0
BuyBtn.ZIndex = 2
BuyBtn.Parent = BuyContainer
regText(BuyBtn, "text")

local holdStart, holdThread, spamThread, isSpamming = nil, nil, nil, false

local function fireAll(pid)
	fireFakeSignal("Product", pid)
	fireFakeSignal("Gamepass", pid)
	fireFakeSignal("Bulk", pid)
	fireFakeSignal("Purchase", pid)
end

local function setBuyText(txt, color)
	BuyBtn.Text = txt
	BuyBtn.TextColor3 = color or Theme.text
end

local function startSpam(pid)
	if isSpamming then return end
	isSpamming = true
	setBuyText("SPAM...", Color3.fromRGB(255, 200, 140))
	spamThread = task.spawn(function()
		while isSpamming and BuyBtn.Parent do
			fireAll(pid)
			task.wait(0.1)
		end
	end)
end

local function stopSpam()
	isSpamming = false
	if spamThread then pcall(task.cancel, spamThread) end
	if BuyBtn.Parent then setBuyText("BUY", Theme.text) end
end

BuyBtn.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		local pid = tonumber(ProductIDInput.Text)
		if not pid then
			setBuyText("INVÁLIDO", Color3.fromRGB(255, 140, 140))
			task.wait(1)
			if BuyBtn.Parent then setBuyText("BUY", Theme.text) end
			return
		end
		holdStart = tick()
		holdThread = task.spawn(function()
			while holdStart and (tick() - holdStart) < 2 do task.wait(0.1) end
			if holdStart and not isSpamming then startSpam(pid) end
		end)
	end
end)

BuyBtn.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		local held = holdStart and (tick() - holdStart) or 0
		holdStart = nil
		if holdThread then pcall(task.cancel, holdThread) end
		if isSpamming then
			stopSpam()
		elseif held < 2 then
			local pid = tonumber(ProductIDInput.Text)
			if pid then
				fireAll(pid)
				setBuyText("OK!", Color3.fromRGB(120, 230, 120))
				task.spawn(function()
					task.wait(1.2)
					if BuyBtn.Parent and not isSpamming then setBuyText("BUY", Theme.text) end
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

-- ============================================
-- COLOR PANEL
-- ============================================
local colorPanelSize = getColorPanelSize()
local cpW = colorPanelSize.X.Offset
local cpH = colorPanelSize.Y.Offset

local cpTitleH = 30
local cpNameH = 54
local cpBtnH = 32
local cpBtnPad = 8
local cpScrollTop = cpTitleH + cpNameH + 6
local cpScrollBottom = cpBtnH + cpBtnPad * 2
local cpScrollH = cpH - cpScrollTop - cpScrollBottom

local colorPanel = Instance.new("Frame")
colorPanel.Name = "ColorPanel"
colorPanel.Size = colorPanelSize
colorPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
colorPanel.AnchorPoint = Vector2.new(0.5, 0.5)
colorPanel.BackgroundColor3 = Theme.bgDark
colorPanel.BackgroundTransparency = 0.1
colorPanel.BorderSizePixel = 0
colorPanel.ClipsDescendants = true
colorPanel.Visible = false
colorPanel.Active = true
colorPanel.Parent = screenGui
corner(colorPanel, 10)
local colorPanelStroke = glowStroke(colorPanel, Theme.accent, Theme.accent2, 1.2)
regFrame(colorPanel, "bgDark")
regGradient(colorPanelStroke:FindFirstChildOfClass("UIGradient"), "accent", "accent2")

local colorTitle = Instance.new("TextLabel")
colorTitle.Size = UDim2.new(1, -90, 0, 20)
colorTitle.Position = UDim2.new(0, 10, 0, 6)
colorTitle.BackgroundTransparency = 1
colorTitle.Text = "Color Editor"
colorTitle.TextSize = 13
colorTitle.Font = Enum.Font.GothamBold
colorTitle.TextXAlignment = Enum.TextXAlignment.Left
colorTitle.Parent = colorPanel
regGradient(applyTextGradient(colorTitle, Theme.accent, Theme.accent2), "accent", "accent2")

local cpBtnSz = 22

local colorBack = Instance.new("TextButton")
colorBack.Size = UDim2.new(0, cpBtnSz, 0, cpBtnSz)
colorBack.Position = UDim2.new(1, -(cpBtnSz * 2 + 10), 0, 5)
colorBack.BackgroundColor3 = Theme.bgLight
colorBack.Text = "<"
colorBack.TextColor3 = Theme.text
colorBack.TextSize = 11
colorBack.Font = Enum.Font.GothamBold
colorBack.BorderSizePixel = 0
colorBack.Parent = colorPanel
corner(colorBack, 999)
regFrame(colorBack, "bgLight")
regText(colorBack, "text")
regStroke(stroke(colorBack, Theme.accent, 1), "accent")
hoverEffect(colorBack)

local colorClose = Instance.new("TextButton")
colorClose.Size = UDim2.new(0, cpBtnSz, 0, cpBtnSz)
colorClose.Position = UDim2.new(1, -6, 0, 5)
colorClose.AnchorPoint = Vector2.new(1, 0)
colorClose.BackgroundColor3 = Theme.bgLight
colorClose.Text = "X"
colorClose.TextColor3 = Theme.accent2
colorClose.TextSize = 10
colorClose.Font = Enum.Font.GothamBold
colorClose.BorderSizePixel = 0
colorClose.Parent = colorPanel
corner(colorClose, 999)
regFrame(colorClose, "bgLight")
regText(colorClose, "accent2")
regStroke(stroke(colorClose, Theme.accent, 1), "accent")
hoverEffect(colorClose)

local nameSection = Instance.new("Frame")
nameSection.Name = "NameSection"
nameSection.Size = UDim2.new(1, -12, 0, cpNameH)
nameSection.Position = UDim2.new(0, 6, 0, cpTitleH + 2)
nameSection.BackgroundColor3 = Theme.bgMid
nameSection.BackgroundTransparency = 0.3
nameSection.BorderSizePixel = 0
nameSection.Parent = colorPanel
corner(nameSection, 6)
regFrame(nameSection, "bgMid")
regStroke(stroke(nameSection, Theme.accent, 1, 0.3), "accent")

local nameLblTitle = Instance.new("TextLabel")
nameLblTitle.Size = UDim2.new(1, -12, 0, 12)
nameLblTitle.Position = UDim2.new(0, 8, 0, 4)
nameLblTitle.BackgroundTransparency = 1
nameLblTitle.Text = "Script Name"
nameLblTitle.TextColor3 = Theme.text
nameLblTitle.TextSize = 10
nameLblTitle.Font = Enum.Font.GothamBold
nameLblTitle.TextXAlignment = Enum.TextXAlignment.Left
nameLblTitle.Parent = nameSection
regText(nameLblTitle, "text")

local nameInputFrame = Instance.new("Frame")
nameInputFrame.Size = UDim2.new(1, -12, 0, cpNameH - 24)
nameInputFrame.Position = UDim2.new(0, 6, 0, 20)
nameInputFrame.BackgroundColor3 = Theme.bgLight
nameInputFrame.BorderSizePixel = 0
nameInputFrame.Parent = nameSection
corner(nameInputFrame, 5)
regFrame(nameInputFrame, "bgLight")
regStroke(stroke(nameInputFrame, Theme.accent, 1, 0.4), "accent")

local nameInput = Instance.new("TextBox")
nameInput.Size = UDim2.new(1, -10, 1, 0)
nameInput.Position = UDim2.new(0, 5, 0, 0)
nameInput.BackgroundTransparency = 1
nameInput.Text = ScriptName
nameInput.PlaceholderText = "Enter script name..."
nameInput.PlaceholderColor3 = Theme.textDim
nameInput.TextColor3 = Theme.text
nameInput.TextSize = 12
nameInput.Font = Enum.Font.GothamBold
nameInput.TextXAlignment = Enum.TextXAlignment.Left
nameInput.ClearTextOnFocus = false
nameInput.BorderSizePixel = 0
nameInput.Parent = nameInputFrame
regText(nameInput, "text")

local colorScroll = Instance.new("ScrollingFrame")
colorScroll.Size = UDim2.new(1, -12, 0, cpScrollH)
colorScroll.Position = UDim2.new(0, 6, 0, cpScrollTop)
colorScroll.BackgroundTransparency = 1
colorScroll.BorderSizePixel = 0
colorScroll.ScrollBarThickness = 4
colorScroll.ScrollBarImageColor3 = Theme.accent
colorScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
colorScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
colorScroll.ScrollingDirection = Enum.ScrollingDirection.Y
colorScroll.Parent = colorPanel

local colorList = Instance.new("UIListLayout", colorScroll)
colorList.SortOrder = Enum.SortOrder.LayoutOrder
colorList.Padding = UDim.new(0, 5)
colorList.HorizontalAlignment = Enum.HorizontalAlignment.Center
local colorPad = Instance.new("UIPadding", colorScroll)
colorPad.PaddingTop = UDim.new(0, 3)
colorPad.PaddingBottom = UDim.new(0, 6)
colorPad.PaddingLeft = UDim.new(0, 1)
colorPad.PaddingRight = UDim.new(0, 1)

local colorEntries = {}

local function rgbToHex(c)
	return string.format("#%02X%02X%02X",
		math.floor(c.R * 255), math.floor(c.G * 255), math.floor(c.B * 255))
end

local function createColorEntry(label, key)
	local initialColor = Theme[key]

	local entryH = 92
	local entry = Instance.new("Frame")
	entry.Name = "ColorEntry"
	entry.Size = UDim2.new(1, -4, 0, entryH)
	entry.BackgroundColor3 = Theme.bgMid
	entry.BackgroundTransparency = 0.3
	entry.BorderSizePixel = 0
	entry.Parent = colorScroll
	corner(entry, 6)
	regFrame(entry, "bgMid")
	regStroke(stroke(entry, Theme.accent, 1, 0.3), "accent")

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size = UDim2.new(0, 110, 0, 12)
	nameLbl.Position = UDim2.new(0, 8, 0, 4)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text = label
	nameLbl.TextColor3 = Theme.text
	nameLbl.TextSize = 10
	nameLbl.Font = Enum.Font.GothamBold
	nameLbl.TextXAlignment = Enum.TextXAlignment.Left
	nameLbl.Parent = entry
	regText(nameLbl, "text")

	local hexLbl = Instance.new("TextLabel")
	hexLbl.Size = UDim2.new(0, 70, 0, 12)
	hexLbl.Position = UDim2.new(1, -78, 0, 4)
	hexLbl.BackgroundTransparency = 1
	hexLbl.Text = rgbToHex(initialColor)
	hexLbl.TextColor3 = Theme.textDim
	hexLbl.TextSize = 9
	hexLbl.Font = Enum.Font.Code
	hexLbl.TextXAlignment = Enum.TextXAlignment.Right
	hexLbl.Parent = entry
	regText(hexLbl, "textDim")

	local preview = Instance.new("Frame")
	preview.Size = UDim2.new(0, 24, 0, 24)
	preview.Position = UDim2.new(0, 8, 0, 20)
	preview.BackgroundColor3 = initialColor
	preview.BorderSizePixel = 0
	preview.Parent = entry
	corner(preview, 3)
	regStroke(stroke(preview, Theme.accent, 1, 0.4), "accent")

	local values = { initialColor.R, initialColor.G, initialColor.B }

	local function updateColor()
		local c = Color3.new(values[1], values[2], values[3])
		preview.BackgroundColor3 = c
		hexLbl.Text = rgbToHex(c)
	end

	local sliderNames = { "R", "G", "B" }
	local sliderFrames = {}

	for i = 1, 3 do
		local sliderFrame = Instance.new("Frame")
		sliderFrame.Size = UDim2.new(1, -44, 0, 18)
		sliderFrame.Position = UDim2.new(0, 38, 0, 20 + (i - 1) * 22)
		sliderFrame.BackgroundColor3 = Theme.bgLight
		sliderFrame.BorderSizePixel = 0
		sliderFrame.Parent = entry
		corner(sliderFrame, 3)
		sliderFrames[i] = sliderFrame
		regFrame(sliderFrame, "bgLight")

		local fill = Instance.new("Frame")
		fill.Size = UDim2.new(values[i], 0, 1, 0)
		fill.BackgroundColor3 = Theme.accent
		fill.BackgroundTransparency = 0.5
		fill.BorderSizePixel = 0
		fill.Parent = sliderFrame
		corner(fill, 3)
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
			local sx = sliderFrame.AbsolutePosition.X
			local sw = sliderFrame.AbsoluteSize.X
			if sw <= 0 then return end
			local relX = math.clamp((input.Position.X - sx) / sw, 0, 1)
			values[i] = relX
			fill.Size = UDim2.new(relX, 0, 1, 0)
			updateColor()
		end

		slider.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				updateSlider(input)
				local moveConn, endConn
				moveConn = UserInputService.InputChanged:Connect(function(inp)
					if inp.UserInputType == Enum.UserInputType.MouseMovement
						or inp.UserInputType == Enum.UserInputType.Touch then
						updateSlider(inp)
					end
				end)
				endConn = UserInputService.InputEnded:Connect(function(inp)
					if inp.UserInputType == Enum.UserInputType.MouseButton1
						or inp.UserInputType == Enum.UserInputType.Touch then
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
		end,
	})
end

createColorEntry("Bg Dark", "bgDark")
createColorEntry("Bg Mid", "bgMid")
createColorEntry("Bg Light", "bgLight")
createColorEntry("Accent", "accent")
createColorEntry("Accent 2", "accent2")
createColorEntry("Text", "text")
createColorEntry("Text Dim", "textDim")
createColorEntry("Input Text", "inputText")

local applyBtn = Instance.new("TextButton")
applyBtn.Size = UDim2.new(0.5, -10, 0, cpBtnH)
applyBtn.Position = UDim2.new(0, 6, 1, -(cpBtnH + cpBtnPad))
applyBtn.BackgroundColor3 = Theme.accent
applyBtn.Text = "APPLY"
applyBtn.TextColor3 = Theme.text
applyBtn.TextSize = 12
applyBtn.Font = Enum.Font.GothamBold
applyBtn.BorderSizePixel = 0
applyBtn.Parent = colorPanel
corner(applyBtn, 6)
regFrame(applyBtn, "accent")
regText(applyBtn, "text")
regStroke(stroke(applyBtn, Theme.accent2, 1), "accent2")
hoverEffect(applyBtn)

local resetBtn = Instance.new("TextButton")
resetBtn.Size = UDim2.new(0.5, -10, 0, cpBtnH)
resetBtn.Position = UDim2.new(0.5, 4, 1, -(cpBtnH + cpBtnPad))
resetBtn.BackgroundColor3 = Theme.bgLight
resetBtn.Text = "RESET"
resetBtn.TextColor3 = Theme.text
resetBtn.TextSize = 12
resetBtn.Font = Enum.Font.GothamBold
resetBtn.BorderSizePixel = 0
resetBtn.Parent = colorPanel
corner(resetBtn, 6)
regFrame(resetBtn, "bgLight")
regText(resetBtn, "text")
regStroke(stroke(resetBtn, Theme.accent, 1), "accent")
hoverEffect(resetBtn)

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
	applyBtn.Text = "OK!"
	task.wait(0.8)
	applyBtn.Text = "APPLY"
end)

resetBtn.MouseButton1Click:Connect(function()
	Theme.bgDark = Color3.fromRGB(16, 0, 0)
	Theme.bgMid = Color3.fromRGB(30, 5, 5)
	Theme.bgLight = Color3.fromRGB(45, 10, 10)
	Theme.accent = Color3.fromRGB(200, 0, 0)
	Theme.accent2 = Color3.fromRGB(255, 50, 50)
	Theme.text = Color3.fromRGB(255, 200, 200)
	Theme.textDim = Color3.fromRGB(180, 100, 100)
	Theme.inputText = Color3.fromRGB(255, 100, 100)
	for _, entry in ipairs(colorEntries) do
		entry.update(Theme[entry.key])
	end
	ScriptName = "Spider"
	nameInput.Text = ScriptName
	applyScriptName()
	applyTheme()
	resetBtn.Text = "OK!"
	task.wait(0.8)
	resetBtn.Text = "RESET"
end)

makeDraggable(colorPanel, colorPanel)

-- ============================================
-- BOTÕES DE MENU
-- ============================================
colorBtn.MouseButton1Click:Connect(function()
	modeWindow.Visible = false
	colorPanel.Visible = true
	colorPanel.Size = UDim2.new(0, 0, 0, 0)
	TweenService:Create(colorPanel, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = colorPanelSize,
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

local isMinimized = false
minBtn.MouseButton1Click:Connect(function()
	isMinimized = not isMinimized
	if isMinimized then
		minBtn.Text = "+"
		contentContainer.Visible = false
		TweenService:Create(autoPanel, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
			Size = UDim2.new(autoPanel.Size.X.Scale, autoPanel.Size.X.Offset, 0, titleH),
		}):Play()
	else
		minBtn.Text = "-"
		contentContainer.Visible = true
		TweenService:Create(autoPanel, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
			Size = panelSize,
		}):Play()
	end
end)

autoBtn.MouseButton1Click:Connect(function()
	modeWindow.Visible = false
	autoPanel.Visible = true
	autoPanel.Size = UDim2.new(0, 0, 0, 0)
	TweenService:Create(autoPanel, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = panelSize,
	}):Play()
end)

manualBtn.MouseButton1Click:Connect(function()
	modeWindow.Visible = false
	manualPanel.Visible = true
	manualPanel.Size = UDim2.new(0, 0, 0, 0)
	TweenService:Create(manualPanel, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = manualSize,
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

print("[Spider] Pronto!")
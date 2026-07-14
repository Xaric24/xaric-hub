--[[
    ╔═══════════════════════════════════════════════════════════╗
    ║  🎮 XARIC HUB v1 — Universal Exploit Hub                 ║
    ║  Auto-Detect Game · Lazy Load · Centralized Config        ║
    ╚═══════════════════════════════════════════════════════════╝

    Supported Games:
      • 🌷 Bloom v3      — The Garden Frontier
      • 🌱 Reseeder      — Be A Seed?
      • 🐟 Cobalt v3     — BE A FISH BAIT!
      • ⚔ Warhead v1     — Missiles vs Cities
      • 🔧 Cobalt GUI    — Universal Dev Tools

    Usage: Execute this file. It detects your game and shows
    a launcher. Pick a script or let auto-detect handle it.
]]

-- ═══════════════════════════════════════════
-- CLEANUP (safe re-inject)
-- ═══════════════════════════════════════════
if getgenv and getgenv()._xaricHubCleanup then
    pcall(getgenv()._xaricHubCleanup)
end
pcall(function()
    for _, g in ipairs(game:GetService("CoreGui"):GetDescendants()) do
        if g.Name == "XaricHub" and g:IsA("ScreenGui") then g:Destroy() end
    end
end)
pcall(function()
    for _, g in ipairs(gethui():GetChildren()) do
        if g.Name == "XaricHub" then g:Destroy() end
    end
end)

-- ═══════════════════════════════════════════
-- SERVICES
-- ═══════════════════════════════════════════
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")
local LP = Players.LocalPlayer

-- ═══════════════════════════════════════════
-- SCRIPT REGISTRY
-- ═══════════════════════════════════════════
-- Each entry: { name, icon, file, description, gameKeywords }
-- gameKeywords: substrings matched against the place name for auto-detect
local SCRIPTS = {
    {
        name        = "Bloom v3",
        icon        = "🌷",
        file        = "garden_cheats.lua",
        description = "The Garden Frontier\nAuto-Farm · Grid Plant · Profit Tracker · ESP",
        keywords    = {"garden", "frontier"},
    },
    {
        name        = "Reseeder",
        icon        = "🌱",
        file        = "beaseed_cheats.lua",
        description = "Be A Seed?\nAuto-Collect · Auto-Run · Gamepass Spoof · Speed",
        keywords    = {"seed", "be a seed"},
    },
    {
        name        = "Cobalt v3",
        icon        = "🐟",
        file        = "cobalt_cheats.lua",
        description = "BE A FISH BAIT!\nAuto-Fish · Auto-Train · QTE · Movement",
        keywords    = {"fish", "bait", "delulu"},
    },
    {
        name        = "Warhead v1",
        icon        = "⚔",
        file        = "missiles_cheats.lua",
        description = "Missiles vs Cities\nAuto-Fire · Auto-Farm · Movement · Teleport",
        keywords    = {"missile", "cities", "warhead"},
    },
    {
        name        = "Cobalt GUI",
        icon        = "🔧",
        file        = "cobalt_gui.lua",
        description = "Universal Dev Tools\nExecutor · Console · Explorer · Remote Spy",
        keywords    = {},  -- never auto-detected, always manual
    },
}

-- Base path for scripts (same directory as this hub)
local BASE_PATH = "C:\\Users\\Xaric\\.gemini\\antigravity\\scratch\\exploit-gui\\"

-- ═══════════════════════════════════════════
-- GAME DETECTION
-- ═══════════════════════════════════════════
local function getPlaceName()
    local ok, info = pcall(function()
        return MarketplaceService:GetProductInfo(game.PlaceId)
    end)
    if ok and info and info.Name then
        return info.Name
    end
    return "Unknown Game"
end

local function detectGame()
    local placeName = getPlaceName():lower()
    for i, entry in ipairs(SCRIPTS) do
        for _, kw in ipairs(entry.keywords) do
            if placeName:find(kw:lower()) then
                return i, entry
            end
        end
    end
    return nil, nil
end

-- ═══════════════════════════════════════════
-- THEME
-- ═══════════════════════════════════════════
local Theme = {
    BG         = Color3.fromRGB(12, 12, 18),
    Surface    = Color3.fromRGB(20, 20, 30),
    Card       = Color3.fromRGB(28, 28, 42),
    CardHover  = Color3.fromRGB(38, 38, 55),
    Border     = Color3.fromRGB(50, 50, 70),
    Accent     = Color3.fromRGB(130, 80, 255),
    AccentGlow = Color3.fromRGB(160, 110, 255),
    AccentDim  = Color3.fromRGB(90, 55, 180),
    Green      = Color3.fromRGB(80, 220, 130),
    Red        = Color3.fromRGB(255, 80, 90),
    Yellow     = Color3.fromRGB(255, 200, 60),
    Text       = Color3.fromRGB(230, 230, 240),
    TextMuted  = Color3.fromRGB(140, 140, 165),
    TextDim    = Color3.fromRGB(90, 90, 110),
    Font       = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
    FontBold   = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
    FontLight  = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular),
}

-- ═══════════════════════════════════════════
-- SCREEN GUI
-- ═══════════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "XaricHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true

pcall(function() ScreenGui.Parent = gethui() end)
if not ScreenGui.Parent then
    pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
end
if not ScreenGui.Parent then
    ScreenGui.Parent = LP:WaitForChild("PlayerGui")
end

-- ═══════════════════════════════════════════
-- BACKDROP (dim overlay)
-- ═══════════════════════════════════════════
local Backdrop = Instance.new("Frame")
Backdrop.Name = "Backdrop"
Backdrop.Size = UDim2.new(1, 0, 1, 0)
Backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Backdrop.BackgroundTransparency = 1
Backdrop.BorderSizePixel = 0
Backdrop.ZIndex = 1
Backdrop.Parent = ScreenGui

TweenService:Create(Backdrop, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {
    BackgroundTransparency = 0.5
}):Play()

-- ═══════════════════════════════════════════
-- MAIN FRAME
-- ═══════════════════════════════════════════
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.Size = UDim2.new(0, 520, 0, 0)  -- starts collapsed
MainFrame.BackgroundColor3 = Theme.BG
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.ZIndex = 2
MainFrame.Parent = ScreenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 16)
mainCorner.Parent = MainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Theme.Border
mainStroke.Thickness = 1.5
mainStroke.Transparency = 0.3
mainStroke.Parent = MainFrame

-- Glow shadow
local shadow = Instance.new("ImageLabel")
shadow.Name = "Shadow"
shadow.AnchorPoint = Vector2.new(0.5, 0.5)
shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
shadow.Size = UDim2.new(1, 60, 1, 60)
shadow.BackgroundTransparency = 1
shadow.Image = "rbxassetid://5028857084"
shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
shadow.ImageTransparency = 0.5
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(24, 24, 276, 276)
shadow.ZIndex = 1
shadow.Parent = MainFrame

-- ═══════════════════════════════════════════
-- HEADER
-- ═══════════════════════════════════════════
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 64)
Header.BackgroundColor3 = Theme.Surface
Header.BorderSizePixel = 0
Header.ZIndex = 5
Header.Parent = MainFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 16)
headerCorner.Parent = Header

-- Bottom mask to keep header square at bottom edge
local headerMask = Instance.new("Frame")
headerMask.Size = UDim2.new(1, 0, 0, 16)
headerMask.Position = UDim2.new(0, 0, 1, -16)
headerMask.BackgroundColor3 = Theme.Surface
headerMask.BorderSizePixel = 0
headerMask.ZIndex = 5
headerMask.Parent = Header

-- Accent line at top
local accentLine = Instance.new("Frame")
accentLine.Size = UDim2.new(1, 0, 0, 2)
accentLine.BackgroundColor3 = Theme.Accent
accentLine.BorderSizePixel = 0
accentLine.ZIndex = 6
accentLine.Parent = Header

local accentGradient = Instance.new("UIGradient")
accentGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Theme.AccentDim),
    ColorSequenceKeypoint.new(0.5, Theme.AccentGlow),
    ColorSequenceKeypoint.new(1, Theme.AccentDim),
}
accentGradient.Parent = accentLine

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Position = UDim2.new(0, 20, 0, 0)
titleLabel.Size = UDim2.new(1, -80, 1, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.FontFace = Theme.FontBold
titleLabel.Text = "🎮  XARIC HUB"
titleLabel.TextColor3 = Theme.Text
titleLabel.TextSize = 20
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 6
titleLabel.Parent = Header

-- Subtitle (game name)
local placeName = getPlaceName()
local subtitleLabel = Instance.new("TextLabel")
subtitleLabel.Name = "Subtitle"
subtitleLabel.Position = UDim2.new(0, 20, 0, 32)
subtitleLabel.Size = UDim2.new(1, -80, 0, 20)
subtitleLabel.BackgroundTransparency = 1
subtitleLabel.FontFace = Theme.FontLight
subtitleLabel.Text = placeName .. "  ·  " .. LP.Name
subtitleLabel.TextColor3 = Theme.TextMuted
subtitleLabel.TextSize = 12
subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
subtitleLabel.ZIndex = 6
subtitleLabel.Parent = Header

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "Close"
closeBtn.AnchorPoint = Vector2.new(1, 0)
closeBtn.Position = UDim2.new(1, -12, 0, 12)
closeBtn.Size = UDim2.new(0, 36, 0, 36)
closeBtn.BackgroundColor3 = Theme.Card
closeBtn.Text = "✕"
closeBtn.FontFace = Theme.Font
closeBtn.TextColor3 = Theme.TextMuted
closeBtn.TextSize = 16
closeBtn.BorderSizePixel = 0
closeBtn.ZIndex = 7
closeBtn.Parent = Header

Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

closeBtn.MouseEnter:Connect(function()
    TweenService:Create(closeBtn, TweenInfo.new(0.15), {
        BackgroundColor3 = Theme.Red, TextColor3 = Color3.new(1, 1, 1)
    }):Play()
end)
closeBtn.MouseLeave:Connect(function()
    TweenService:Create(closeBtn, TweenInfo.new(0.15), {
        BackgroundColor3 = Theme.Card, TextColor3 = Theme.TextMuted
    }):Play()
end)

-- ═══════════════════════════════════════════
-- CONTENT AREA (scrolling cards)
-- ═══════════════════════════════════════════
local Content = Instance.new("ScrollingFrame")
Content.Name = "Content"
Content.Position = UDim2.new(0, 0, 0, 64)
Content.Size = UDim2.new(1, 0, 1, -64)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 3
Content.ScrollBarImageColor3 = Theme.Accent
Content.CanvasSize = UDim2.new(0, 0, 0, 0)
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
Content.ZIndex = 3
Content.Parent = MainFrame

local contentLayout = Instance.new("UIListLayout")
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Padding = UDim.new(0, 10)
contentLayout.Parent = Content

local contentPadding = Instance.new("UIPadding")
contentPadding.PaddingTop = UDim.new(0, 14)
contentPadding.PaddingBottom = UDim.new(0, 14)
contentPadding.PaddingLeft = UDim.new(0, 16)
contentPadding.PaddingRight = UDim.new(0, 16)
contentPadding.Parent = Content

-- ═══════════════════════════════════════════
-- CARD BUILDER
-- ═══════════════════════════════════════════
local detectedIdx, detectedEntry = detectGame()
local statusLabel  -- forward declaration

local function createCard(entry, idx)
    local isDetected = (idx == detectedIdx)

    local card = Instance.new("Frame")
    card.Name = "Card_" .. entry.name
    card.Size = UDim2.new(1, 0, 0, 90)
    card.BackgroundColor3 = Theme.Card
    card.BorderSizePixel = 0
    card.LayoutOrder = isDetected and 0 or idx
    card.ZIndex = 3
    card.Parent = Content

    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 12)

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = isDetected and Theme.Accent or Theme.Border
    cardStroke.Thickness = isDetected and 1.5 or 1
    cardStroke.Transparency = isDetected and 0.2 or 0.6
    cardStroke.Parent = card

    -- Detected badge
    if isDetected then
        local badge = Instance.new("Frame")
        badge.Size = UDim2.new(0, 72, 0, 20)
        badge.Position = UDim2.new(1, -82, 0, 8)
        badge.BackgroundColor3 = Theme.Accent
        badge.ZIndex = 5
        badge.Parent = card
        Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 6)

        local badgeText = Instance.new("TextLabel")
        badgeText.Size = UDim2.new(1, 0, 1, 0)
        badgeText.BackgroundTransparency = 1
        badgeText.FontFace = Theme.FontBold
        badgeText.Text = "DETECTED"
        badgeText.TextColor3 = Color3.new(1, 1, 1)
        badgeText.TextSize = 10
        badgeText.ZIndex = 6
        badgeText.Parent = badge
    end

    -- Icon
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Position = UDim2.new(0, 14, 0, 14)
    iconLabel.Size = UDim2.new(0, 48, 0, 48)
    iconLabel.BackgroundColor3 = Theme.Surface
    iconLabel.FontFace = Theme.Font
    iconLabel.Text = entry.icon
    iconLabel.TextSize = 28
    iconLabel.ZIndex = 4
    iconLabel.Parent = card
    Instance.new("UICorner", iconLabel).CornerRadius = UDim.new(0, 10)

    -- Name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Position = UDim2.new(0, 76, 0, 12)
    nameLabel.Size = UDim2.new(1, -170, 0, 22)
    nameLabel.BackgroundTransparency = 1
    nameLabel.FontFace = Theme.FontBold
    nameLabel.Text = entry.name
    nameLabel.TextColor3 = Theme.Text
    nameLabel.TextSize = 16
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.ZIndex = 4
    nameLabel.Parent = card

    -- Description
    local descLabel = Instance.new("TextLabel")
    descLabel.Position = UDim2.new(0, 76, 0, 34)
    descLabel.Size = UDim2.new(1, -170, 0, 44)
    descLabel.BackgroundTransparency = 1
    descLabel.FontFace = Theme.FontLight
    descLabel.Text = entry.description
    descLabel.TextColor3 = Theme.TextMuted
    descLabel.TextSize = 11
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.TextYAlignment = Enum.TextYAlignment.Top
    descLabel.TextWrapped = true
    descLabel.ZIndex = 4
    descLabel.Parent = card

    -- Launch button
    local launchBtn = Instance.new("TextButton")
    launchBtn.AnchorPoint = Vector2.new(1, 0.5)
    launchBtn.Position = UDim2.new(1, -12, 0.5, 0)
    launchBtn.Size = UDim2.new(0, 72, 0, 34)
    launchBtn.BackgroundColor3 = isDetected and Theme.Accent or Theme.Surface
    launchBtn.FontFace = Theme.FontBold
    launchBtn.Text = "LAUNCH"
    launchBtn.TextColor3 = isDetected and Color3.new(1, 1, 1) or Theme.TextMuted
    launchBtn.TextSize = 12
    launchBtn.BorderSizePixel = 0
    launchBtn.ZIndex = 5
    launchBtn.Parent = card

    Instance.new("UICorner", launchBtn).CornerRadius = UDim.new(0, 8)

    -- Hover effects
    card.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            TweenService:Create(card, TweenInfo.new(0.15), {BackgroundColor3 = Theme.CardHover}):Play()
        end
    end)
    card.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            TweenService:Create(card, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Card}):Play()
        end
    end)

    launchBtn.MouseEnter:Connect(function()
        TweenService:Create(launchBtn, TweenInfo.new(0.15), {
            BackgroundColor3 = Theme.AccentGlow,
            TextColor3 = Color3.new(1, 1, 1),
        }):Play()
    end)
    launchBtn.MouseLeave:Connect(function()
        TweenService:Create(launchBtn, TweenInfo.new(0.15), {
            BackgroundColor3 = isDetected and Theme.Accent or Theme.Surface,
            TextColor3 = isDetected and Color3.new(1, 1, 1) or Theme.TextMuted,
        }):Play()
    end)

    -- Launch handler
    launchBtn.MouseButton1Click:Connect(function()
        -- Animate button
        TweenService:Create(launchBtn, TweenInfo.new(0.1), {
            Size = UDim2.new(0, 66, 0, 30)
        }):Play()
        task.wait(0.1)
        TweenService:Create(launchBtn, TweenInfo.new(0.1), {
            Size = UDim2.new(0, 72, 0, 34)
        }):Play()

        launchBtn.Text = "..."
        launchBtn.BackgroundColor3 = Theme.Yellow
        launchBtn.TextColor3 = Theme.BG

        if statusLabel then
            statusLabel.Text = "⏳  Loading " .. entry.name .. "..."
            statusLabel.TextColor3 = Theme.Yellow
        end

        -- Close the hub UI
        task.wait(0.3)
        local closeTween = TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 520, 0, 0)
        })
        TweenService:Create(Backdrop, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
        closeTween:Play()
        closeTween.Completed:Wait()

        ScreenGui:Destroy()

        -- Load the script
        local filePath = BASE_PATH .. entry.file
        local ok, err = pcall(function()
            if executefile then
                executefile(filePath)
            elseif loadfile then
                loadfile(filePath)()
            else
                loadstring(readfile(filePath))()
            end
        end)

        if not ok then
            warn("[XaricHub] Failed to load " .. entry.name .. ": " .. tostring(err))
        end
    end)

    return card
end

-- ═══════════════════════════════════════════
-- STATUS BAR
-- ═══════════════════════════════════════════
local statusFrame = Instance.new("Frame")
statusFrame.Name = "Status"
statusFrame.Size = UDim2.new(1, 0, 0, 30)
statusFrame.BackgroundTransparency = 1
statusFrame.LayoutOrder = 100
statusFrame.ZIndex = 3
statusFrame.Parent = Content

statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 1, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.FontFace = Theme.FontLight
statusLabel.TextSize = 11
statusLabel.TextColor3 = Theme.TextDim
statusLabel.ZIndex = 4
statusLabel.Parent = statusFrame

if detectedEntry then
    statusLabel.Text = "✨  Auto-detected: " .. detectedEntry.name .. "  ·  Press LAUNCH or wait 5s"
    statusLabel.TextColor3 = Theme.Green
else
    statusLabel.Text = "⚠  Game not recognized  ·  Select a script manually"
    statusLabel.TextColor3 = Theme.Yellow
end

-- ═══════════════════════════════════════════
-- BUILD CARDS
-- ═══════════════════════════════════════════
for i, entry in ipairs(SCRIPTS) do
    createCard(entry, i)
end

-- ═══════════════════════════════════════════
-- OPEN ANIMATION
-- ═══════════════════════════════════════════
-- Calculate target height: header + content
local targetHeight = 64 + (#SCRIPTS * 100) + 30 + 28 + 14
targetHeight = math.min(targetHeight, 580)

MainFrame.Size = UDim2.new(0, 520, 0, 0)
local openTween = TweenService:Create(MainFrame, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, 520, 0, targetHeight)
})
openTween:Play()

-- ═══════════════════════════════════════════
-- CLOSE HANDLER
-- ═══════════════════════════════════════════
local function closeHub()
    local closeTween = TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 520, 0, 0)
    })
    TweenService:Create(Backdrop, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
    closeTween:Play()
    closeTween.Completed:Wait()
    ScreenGui:Destroy()
end

closeBtn.MouseButton1Click:Connect(closeHub)
Backdrop.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        closeHub()
    end
end)

-- ═══════════════════════════════════════════
-- AUTO-LAUNCH (5s countdown for detected game)
-- ═══════════════════════════════════════════
if detectedEntry then
    task.spawn(function()
        for i = 5, 1, -1 do
            if not ScreenGui.Parent then return end  -- hub was closed/launched
            statusLabel.Text = "✨  Auto-launching " .. detectedEntry.name .. " in " .. i .. "s  ·  Click another to cancel"
            task.wait(1)
        end
        if not ScreenGui.Parent then return end

        -- Auto-launch
        statusLabel.Text = "🚀  Launching " .. detectedEntry.name .. "..."
        statusLabel.TextColor3 = Theme.Accent
        task.wait(0.3)

        local closeTween = TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 520, 0, 0)
        })
        TweenService:Create(Backdrop, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
        closeTween:Play()
        closeTween.Completed:Wait()
        ScreenGui:Destroy()

        local filePath = BASE_PATH .. detectedEntry.file
        pcall(function()
            if executefile then
                executefile(filePath)
            elseif loadfile then
                loadfile(filePath)()
            else
                loadstring(readfile(filePath))()
            end
        end)
    end)
end

-- ═══════════════════════════════════════════
-- KEYBIND: Toggle hub visibility with ` (backtick)
-- ═══════════════════════════════════════════
getgenv()._xaricHubCleanup = function()
    pcall(function() ScreenGui:Destroy() end)
end

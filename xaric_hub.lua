--[[
    ╔═══════════════════════════════════════════════════════════╗
    ║  🎮 XARIC HUB v2 — Universal Exploit Hub                 ║
    ║  Auto-Detect · Draggable · Animated · Version Check       ║
    ╚═══════════════════════════════════════════════════════════╝

    Supported Games:
      • 🌷 Bloom v3      — The Garden Frontier
      • 🌱 Reseeder      — Be A Seed?
      • 🐟 Cobalt v3     — BE A FISH BAIT!
      • ⚔ Warhead v1     — Missiles vs Cities
      • 🧠 BrainSnatch   — Catch a Brainrot
      • 🌿 GreenThumb v1 — My Greenhouse!
      • ⭐ StarForge v1   — Make a Galaxy ✨
      • 🐺 Coyote v1      — San Diego Border RP
      • ⛏️ CrushForge v1  — Build An Ore Crusher
      • 🦠 Pathogen v1    — Parasite.exe
      • 🪓 Timber v1      — My Wood Farm
      • 🔧 Cobalt GUI    — Universal Dev Tools
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
local Players            = game:GetService("Players")
local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService         = game:GetService("RunService")
local LP = Players.LocalPlayer

local HUB_VERSION = "2.0.1"
local HUB_RELEASE = "v2.0.1"
local autoLaunchCancelled = false

-- ═══════════════════════════════════════════
-- SCRIPT REGISTRY
-- ═══════════════════════════════════════════
local SCRIPTS = {
    {
        name        = "Bloom v3",
        icon        = "🌷",
        file        = "garden_cheats.lua",
        description = "The Garden Frontier",
        features    = {"Auto-Farm", "Grid Plant", "Profit Tracker", "ESP"},
        keywords    = {"garden", "frontier"},
        color       = Color3.fromRGB(100, 200, 120),
    },
    {
        name        = "Reseeder",
        icon        = "🌱",
        file        = "beaseed_cheats.lua",
        description = "Be A Seed?",
        features    = {"Auto-Collect", "Auto-Run", "Gamepass Spoof", "Speed"},
        keywords    = {"seed", "be a seed"},
        color       = Color3.fromRGB(80, 180, 80),
    },
    {
        name        = "Cobalt v3",
        icon        = "🐟",
        file        = "cobalt_cheats.lua",
        description = "BE A FISH BAIT!",
        features    = {"Auto-Fish", "Auto-Train", "QTE", "Movement"},
        keywords    = {"fish", "bait", "delulu"},
        color       = Color3.fromRGB(60, 160, 220),
    },
    {
        name        = "Warhead v1",
        icon        = "⚔",
        file        = "missiles_cheats.lua",
        description = "Missiles vs Cities",
        features    = {"Auto-Fire", "Auto-Farm", "Movement", "Teleport"},
        keywords    = {"missile", "cities", "warhead"},
        color       = Color3.fromRGB(220, 90, 80),
    },
    {
        name        = "BrainSnatch v1",
        icon        = "🧠",
        file        = "brainrot_cheats.lua",
        description = "Catch a Brainrot",
        features    = {"Auto-Battle", "ESP", "Speed", "Teleport"},
        keywords    = {"brainrot", "catch"},
        color       = Color3.fromRGB(180, 100, 255),
    },
    {
        name        = "GreenThumb v1",
        icon        = "🌿",
        file        = "greenhouse_cheats.lua",
        description = "My Greenhouse!",
        features    = {"Auto-Collect", "Auto-Harvest", "Auto-Sell", "ESP"},
        keywords    = {"greenhouse", "my greenhouse"},
        color       = Color3.fromRGB(60, 180, 80),
    },
    {
        name        = "StarForge v1",
        icon        = "⭐",
        file        = "galaxy_cheats.lua",
        description = "Make a Galaxy ✨",
        features    = {"Auto-Collect", "Auto-Sell", "Auto-Crate", "Auto-Fuse"},
        keywords    = {"galaxy", "make a galaxy", "comet", "planet"},
        color       = Color3.fromRGB(255, 215, 80),
    },
    {
        name        = "Coyote v1",
        icon        = "🐺",
        file        = "border_cheats.lua",
        description = "San Diego Border RP",
        features    = {"ESP", "Noclip", "God Mode", "Teleport"},
        keywords    = {"san diego", "border", "roleplay", "coyote"},
        color       = Color3.fromRGB(230, 180, 80),
    },
    {
        name        = "CrushForge v1",
        icon        = "⛏️",
        file        = "orecrusher_cheats.lua",
        description = "Build An Ore Crusher",
        features    = {"Auto-Mine", "Auto-Sell", "Auto-Roll", "Auto-Upgrade"},
        keywords    = {"ore", "crusher", "build an ore", "crushforge", "mine"},
        color       = Color3.fromRGB(255, 165, 0),
    },
    {
        name        = "Pathogen v1",
        icon        = "🦠",
        file        = "parasite_cheats.lua",
        description = "Parasite.exe",
        features    = {"Auto-Grow", "Auto-Attack", "Dummies", "Contracts"},
        keywords    = {"parasite", "parasite.exe", "pathogen"},
        color       = Color3.fromRGB(50, 200, 50),
    },
    {
        name        = "Timber v1",
        icon        = "🪓",
        file        = "woodfarm_cheats.lua",
        description = "My Wood Farm",
        features    = {"Auto-Collect", "Auto-Sell", "Auto-Spin", "Auto-Equip"},
        keywords    = {"wood", "farm", "my wood farm", "timber"},
        color       = Color3.fromRGB(139, 69, 19),
    },
    {
        name        = "Cobalt GUI",
        icon        = "🔧",
        file        = "cobalt_gui.lua",
        description = "Universal Dev Tools",
        features    = {"Executor", "Console", "Explorer", "Remote Spy"},
        keywords    = {},
        color       = Color3.fromRGB(200, 200, 200),
    },
}

-- Keep module loads on the tested release selected by this launcher.
local GITHUB_RAW = "https://raw.githubusercontent.com/Xaric24/xaric-hub/" .. HUB_RELEASE .. "/"

-- ═══════════════════════════════════════════
-- GAME DETECTION
-- ═══════════════════════════════════════════
local placeName = "Unknown Game"
pcall(function()
    local info = MarketplaceService:GetProductInfo(game.PlaceId)
    if info and info.Name then placeName = info.Name end
end)

local function detectGame()
    local lower = placeName:lower()
    for i, entry in ipairs(SCRIPTS) do
        for _, kw in ipairs(entry.keywords) do
            if lower:find(kw:lower()) then
                return i, entry
            end
        end
    end
    return nil, nil
end

-- ═══════════════════════════════════════════
-- THEME
-- ═══════════════════════════════════════════
local T = {
    BG           = Color3.fromRGB(10, 10, 16),
    Surface      = Color3.fromRGB(18, 18, 28),
    Card         = Color3.fromRGB(24, 24, 38),
    CardHover    = Color3.fromRGB(32, 32, 50),
    CardActive   = Color3.fromRGB(40, 36, 65),
    Border       = Color3.fromRGB(45, 45, 65),
    Accent       = Color3.fromRGB(130, 80, 255),
    AccentGlow   = Color3.fromRGB(165, 115, 255),
    AccentDim    = Color3.fromRGB(85, 50, 170),
    AccentSoft   = Color3.fromRGB(50, 35, 90),
    Green        = Color3.fromRGB(70, 210, 120),
    Red          = Color3.fromRGB(240, 70, 80),
    Yellow       = Color3.fromRGB(255, 195, 55),
    Orange       = Color3.fromRGB(250, 140, 50),
    Text         = Color3.fromRGB(235, 235, 245),
    TextSub      = Color3.fromRGB(170, 170, 195),
    TextMuted    = Color3.fromRGB(110, 110, 135),
    TextDim      = Color3.fromRGB(70, 70, 90),
    Font         = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
    FontBold     = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
    FontBlack    = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.ExtraBold),
    FontLight    = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular),
}

local TWEEN_FAST  = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_MED   = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_OPEN  = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local TWEEN_CLOSE = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)

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
-- BACKDROP
-- ═══════════════════════════════════════════
local Backdrop = Instance.new("Frame")
Backdrop.Name = "Backdrop"
Backdrop.Size = UDim2.new(1, 0, 1, 0)
Backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Backdrop.BackgroundTransparency = 1
Backdrop.BorderSizePixel = 0
Backdrop.ZIndex = 1
Backdrop.Parent = ScreenGui

TweenService:Create(Backdrop, TweenInfo.new(0.5), {BackgroundTransparency = 0.55}):Play()

-- ═══════════════════════════════════════════
-- MAIN FRAME
-- ═══════════════════════════════════════════
local FRAME_W, FRAME_H = 540, 0
local TARGET_H = 64 + (#SCRIPTS * 108) + 68 + 28
TARGET_H = math.min(TARGET_H, 620)

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.Size = UDim2.new(0, FRAME_W, 0, 0)
MainFrame.BackgroundColor3 = T.BG
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.ZIndex = 2
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 14)

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = T.Border
mainStroke.Thickness = 1
mainStroke.Transparency = 0.4
mainStroke.Parent = MainFrame

-- Drop shadow
local shadow = Instance.new("ImageLabel")
shadow.Name = "Shadow"
shadow.AnchorPoint = Vector2.new(0.5, 0.5)
shadow.Position = UDim2.new(0.5, 0, 0.5, 4)
shadow.Size = UDim2.new(1, 70, 1, 70)
shadow.BackgroundTransparency = 1
shadow.Image = "rbxassetid://5028857084"
shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
shadow.ImageTransparency = 0.35
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(24, 24, 276, 276)
shadow.ZIndex = 1
shadow.Parent = MainFrame

-- ═══════════════════════════════════════════
-- DRAGGABLE HEADER
-- ═══════════════════════════════════════════
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 64)
Header.BackgroundColor3 = T.Surface
Header.BorderSizePixel = 0
Header.ZIndex = 10
Header.Parent = MainFrame

Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 14)

-- Mask bottom corners
local hMask = Instance.new("Frame")
hMask.Size = UDim2.new(1, 0, 0, 14)
hMask.Position = UDim2.new(0, 0, 1, -14)
hMask.BackgroundColor3 = T.Surface
hMask.BorderSizePixel = 0
hMask.ZIndex = 10
hMask.Parent = Header

-- Accent bar (animated gradient)
local accentBar = Instance.new("Frame")
accentBar.Size = UDim2.new(1, 0, 0, 2)
accentBar.BackgroundColor3 = T.Accent
accentBar.BorderSizePixel = 0
accentBar.ZIndex = 11
accentBar.Parent = Header

local accentGrad = Instance.new("UIGradient")
accentGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, T.AccentDim),
    ColorSequenceKeypoint.new(0.3, T.AccentGlow),
    ColorSequenceKeypoint.new(0.7, T.Accent),
    ColorSequenceKeypoint.new(1, T.AccentDim),
}
accentGrad.Parent = accentBar

-- Animate the gradient offset
task.spawn(function()
    while ScreenGui.Parent do
        TweenService:Create(accentGrad, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Offset = Vector2.new(0.5, 0)
        }):Play()
        task.wait(2)
        TweenService:Create(accentGrad, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Offset = Vector2.new(-0.5, 0)
        }):Play()
        task.wait(2)
    end
end)

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Position = UDim2.new(0, 18, 0, 8)
titleLabel.Size = UDim2.new(0.6, 0, 0, 24)
titleLabel.BackgroundTransparency = 1
titleLabel.FontFace = T.FontBlack
titleLabel.Text = "XARIC HUB"
titleLabel.TextColor3 = T.Text
titleLabel.TextSize = 19
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 11
titleLabel.Parent = Header

-- Version badge
local verBadge = Instance.new("TextLabel")
verBadge.Position = UDim2.new(0, 112, 0, 11)
verBadge.Size = UDim2.new(0, 30, 0, 16)
verBadge.BackgroundColor3 = T.AccentSoft
verBadge.FontFace = T.FontBold
verBadge.Text = "v" .. HUB_VERSION
verBadge.TextColor3 = T.AccentGlow
verBadge.TextSize = 9
verBadge.ZIndex = 11
verBadge.Parent = Header
Instance.new("UICorner", verBadge).CornerRadius = UDim.new(0, 4)

-- Subtitle
local subLabel = Instance.new("TextLabel")
subLabel.Position = UDim2.new(0, 18, 0, 34)
subLabel.Size = UDim2.new(0.7, 0, 0, 18)
subLabel.BackgroundTransparency = 1
subLabel.FontFace = T.FontLight
subLabel.Text = "🎮 " .. placeName .. "  ·  " .. LP.Name
subLabel.TextColor3 = T.TextMuted
subLabel.TextSize = 11
subLabel.TextXAlignment = Enum.TextXAlignment.Left
subLabel.ZIndex = 11
subLabel.Parent = Header

-- Script count pill
local countPill = Instance.new("TextLabel")
countPill.AnchorPoint = Vector2.new(1, 0)
countPill.Position = UDim2.new(1, -56, 0, 12)
countPill.Size = UDim2.new(0, 50, 0, 18)
countPill.BackgroundColor3 = T.Card
countPill.FontFace = T.Font
countPill.Text = #SCRIPTS .. " scripts"
countPill.TextColor3 = T.TextMuted
countPill.TextSize = 9
countPill.ZIndex = 11
countPill.Parent = Header
Instance.new("UICorner", countPill).CornerRadius = UDim.new(0, 5)

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.AnchorPoint = Vector2.new(1, 0)
closeBtn.Position = UDim2.new(1, -12, 0, 12)
closeBtn.Size = UDim2.new(0, 34, 0, 34)
closeBtn.BackgroundColor3 = T.Card
closeBtn.Text = "✕"
closeBtn.FontFace = T.Font
closeBtn.TextColor3 = T.TextMuted
closeBtn.TextSize = 14
closeBtn.BorderSizePixel = 0
closeBtn.ZIndex = 12
closeBtn.Parent = Header
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

closeBtn.MouseEnter:Connect(function()
    TweenService:Create(closeBtn, TWEEN_FAST, {BackgroundColor3 = T.Red, TextColor3 = Color3.new(1,1,1)}):Play()
end)
closeBtn.MouseLeave:Connect(function()
    TweenService:Create(closeBtn, TWEEN_FAST, {BackgroundColor3 = T.Card, TextColor3 = T.TextMuted}):Play()
end)

-- DRAG LOGIC
do
    local dragging, dragStart, frameStart = false, nil, nil
    Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            frameStart = MainFrame.Position
        end
    end)
    Header.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(
                frameStart.X.Scale, frameStart.X.Offset + delta.X,
                frameStart.Y.Scale, frameStart.Y.Offset + delta.Y
            )
        end
    end)
end

-- ═══════════════════════════════════════════
-- CONTENT AREA
-- ═══════════════════════════════════════════
local Content = Instance.new("ScrollingFrame")
Content.Name = "Content"
Content.Position = UDim2.new(0, 0, 0, 64)
Content.Size = UDim2.new(1, 0, 1, -64)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 3
Content.ScrollBarImageColor3 = T.Accent
Content.ScrollBarImageTransparency = 0.4
Content.CanvasSize = UDim2.new(0, 0, 0, 0)
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
Content.ZIndex = 3
Content.Parent = MainFrame

local contentLayout = Instance.new("UIListLayout")
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Padding = UDim.new(0, 8)
contentLayout.Parent = Content

local contentPad = Instance.new("UIPadding")
contentPad.PaddingTop = UDim.new(0, 12)
contentPad.PaddingBottom = UDim.new(0, 16)
contentPad.PaddingLeft = UDim.new(0, 14)
contentPad.PaddingRight = UDim.new(0, 14)
contentPad.Parent = Content

-- ═══════════════════════════════════════════
-- CARD BUILDER
-- ═══════════════════════════════════════════
local detectedIdx, detectedEntry = detectGame()
local statusLabel
local allCards = {}

local function launchScript(entry)
    autoLaunchCancelled = true

    if statusLabel then
        statusLabel.Text = "⏳  Loading " .. entry.name .. "..."
        statusLabel.TextColor3 = T.Yellow
    end

    local url = GITHUB_RAW .. entry.file
    print("[XaricHub] Loading " .. entry.name .. " from: " .. url)
    local ok, loadedOrError = pcall(function()
        local src = game:HttpGet(url)
        if not src or #src == 0 then
            error("HttpGet returned empty response")
        end
        local fn, compileErr = loadstring(src, entry.file)
        if not fn then error("Compile: " .. tostring(compileErr)) end
        return fn
    end)
    if not ok then
        local err = loadedOrError
        warn("[XaricHub] Failed to load " .. entry.name .. ": " .. tostring(err))
        if statusLabel then
            statusLabel.Text = "Load failed. Select a script to retry."
            statusLabel.TextColor3 = T.Red
        end
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "XaricHub Error",
                Text = entry.name .. ": " .. tostring(err):sub(1, 80),
                Duration = 8,
            })
        end)
        return
    end

    if statusLabel then
        statusLabel.Text = "Launching " .. entry.name .. "..."
    end
    local ran, err = pcall(loadedOrError)
    if not ran then
        warn("[XaricHub] Failed to launch " .. entry.name .. ": " .. tostring(err))
        if statusLabel then
            statusLabel.Text = "Launch failed. Select a script to retry."
            statusLabel.TextColor3 = T.Red
        end
        return
    end

    local tw = TweenService:Create(MainFrame, TWEEN_CLOSE, {Size = UDim2.new(0, FRAME_W, 0, 0)})
    TweenService:Create(Backdrop, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
    tw:Play()
    tw.Completed:Wait()
    ScreenGui:Destroy()
    print("[XaricHub] " .. entry.name .. " loaded OK")
end

local function createCard(entry, idx)
    local isDetected = (idx == detectedIdx)
    local accentColor = entry.color or T.Accent

    -- Card container
    local card = Instance.new("Frame")
    card.Name = "Card_" .. entry.name
    card.Size = UDim2.new(1, 0, 0, 100)
    card.BackgroundColor3 = T.Card
    card.BorderSizePixel = 0
    card.LayoutOrder = isDetected and -1 or idx
    card.ZIndex = 3
    card.Parent = Content
    card.ClipsDescendants = true

    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 12)

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = isDetected and accentColor or T.Border
    cardStroke.Thickness = isDetected and 1.5 or 1
    cardStroke.Transparency = isDetected and 0.15 or 0.6
    cardStroke.Parent = card

    -- Left color accent strip
    local strip = Instance.new("Frame")
    strip.Size = UDim2.new(0, 3, 1, -16)
    strip.Position = UDim2.new(0, 0, 0, 8)
    strip.BackgroundColor3 = accentColor
    strip.BorderSizePixel = 0
    strip.ZIndex = 5
    strip.Parent = card
    Instance.new("UICorner", strip).CornerRadius = UDim.new(0, 2)

    -- Subtle gradient background on detected card
    if isDetected then
        local glow = Instance.new("Frame")
        glow.Size = UDim2.new(1, 0, 1, 0)
        glow.BackgroundColor3 = accentColor
        glow.BackgroundTransparency = 0.92
        glow.BorderSizePixel = 0
        glow.ZIndex = 3
        glow.Parent = card
        Instance.new("UICorner", glow).CornerRadius = UDim.new(0, 12)
    end

    -- DETECTED badge
    if isDetected then
        local badge = Instance.new("Frame")
        badge.Size = UDim2.new(0, 78, 0, 20)
        badge.Position = UDim2.new(1, -88, 0, 8)
        badge.BackgroundColor3 = accentColor
        badge.ZIndex = 7
        badge.Parent = card
        Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 6)

        local bStroke = Instance.new("UIStroke")
        bStroke.Color = Color3.new(1,1,1)
        bStroke.Thickness = 1
        bStroke.Transparency = 0.8
        bStroke.Parent = badge

        local bText = Instance.new("TextLabel")
        bText.Size = UDim2.new(1, 0, 1, 0)
        bText.BackgroundTransparency = 1
        bText.FontFace = T.FontBold
        bText.Text = "✦ DETECTED"
        bText.TextColor3 = Color3.new(1, 1, 1)
        bText.TextSize = 9
        bText.ZIndex = 8
        bText.Parent = badge

        -- Pulse animation
        task.spawn(function()
            while badge.Parent and ScreenGui.Parent do
                TweenService:Create(badge, TweenInfo.new(1, Enum.EasingStyle.Sine), {
                    BackgroundTransparency = 0.3
                }):Play()
                task.wait(1)
                TweenService:Create(badge, TweenInfo.new(1, Enum.EasingStyle.Sine), {
                    BackgroundTransparency = 0
                }):Play()
                task.wait(1)
            end
        end)
    end

    -- Icon background
    local iconBg = Instance.new("Frame")
    iconBg.Position = UDim2.new(0, 14, 0, 16)
    iconBg.Size = UDim2.new(0, 52, 0, 52)
    iconBg.BackgroundColor3 = T.Surface
    iconBg.BorderSizePixel = 0
    iconBg.ZIndex = 5
    iconBg.Parent = card
    Instance.new("UICorner", iconBg).CornerRadius = UDim.new(0, 12)

    local iconStroke = Instance.new("UIStroke")
    iconStroke.Color = accentColor
    iconStroke.Thickness = 1
    iconStroke.Transparency = 0.7
    iconStroke.Parent = iconBg

    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(1, 0, 1, 0)
    iconLabel.BackgroundTransparency = 1
    iconLabel.FontFace = T.Font
    iconLabel.Text = entry.icon
    iconLabel.TextSize = 26
    iconLabel.ZIndex = 6
    iconLabel.Parent = iconBg

    -- Name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Position = UDim2.new(0, 78, 0, 12)
    nameLabel.Size = UDim2.new(1, -180, 0, 20)
    nameLabel.BackgroundTransparency = 1
    nameLabel.FontFace = T.FontBold
    nameLabel.Text = entry.name
    nameLabel.TextColor3 = T.Text
    nameLabel.TextSize = 15
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.ZIndex = 5
    nameLabel.Parent = card

    -- Game name (subtitle)
    local descLabel = Instance.new("TextLabel")
    descLabel.Position = UDim2.new(0, 78, 0, 32)
    descLabel.Size = UDim2.new(1, -180, 0, 16)
    descLabel.BackgroundTransparency = 1
    descLabel.FontFace = T.FontLight
    descLabel.Text = entry.description
    descLabel.TextColor3 = T.TextSub
    descLabel.TextSize = 11
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.ZIndex = 5
    descLabel.Parent = card

    -- Feature tags row
    local tagFrame = Instance.new("Frame")
    tagFrame.Position = UDim2.new(0, 78, 0, 54)
    tagFrame.Size = UDim2.new(1, -92, 0, 22)
    tagFrame.BackgroundTransparency = 1
    tagFrame.ZIndex = 5
    tagFrame.Parent = card

    local tagLayout = Instance.new("UIListLayout")
    tagLayout.FillDirection = Enum.FillDirection.Horizontal
    tagLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tagLayout.Padding = UDim.new(0, 5)
    tagLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    tagLayout.Parent = tagFrame

    for fi, feat in ipairs(entry.features or {}) do
        local pill = Instance.new("Frame")
        pill.Size = UDim2.new(0, #feat * 6 + 14, 0, 18)
        pill.BackgroundColor3 = T.Surface
        pill.BorderSizePixel = 0
        pill.LayoutOrder = fi
        pill.ZIndex = 5
        pill.Parent = tagFrame
        Instance.new("UICorner", pill).CornerRadius = UDim.new(0, 5)

        local pLabel = Instance.new("TextLabel")
        pLabel.Size = UDim2.new(1, 0, 1, 0)
        pLabel.BackgroundTransparency = 1
        pLabel.FontFace = T.Font
        pLabel.Text = feat
        pLabel.TextColor3 = T.TextMuted
        pLabel.TextSize = 9
        pLabel.ZIndex = 6
        pLabel.Parent = pill
    end

    -- Launch button
    local launchBtn = Instance.new("TextButton")
    launchBtn.AnchorPoint = Vector2.new(1, 0.5)
    launchBtn.Position = UDim2.new(1, -10, 0.5, -6)
    launchBtn.Size = UDim2.new(0, 70, 0, 32)
    launchBtn.BackgroundColor3 = isDetected and accentColor or T.Surface
    launchBtn.FontFace = T.FontBold
    launchBtn.Text = "LAUNCH"
    launchBtn.TextColor3 = isDetected and Color3.new(1, 1, 1) or T.TextMuted
    launchBtn.TextSize = 11
    launchBtn.BorderSizePixel = 0
    launchBtn.ZIndex = 7
    launchBtn.Parent = card
    Instance.new("UICorner", launchBtn).CornerRadius = UDim.new(0, 8)

    if not isDetected then
        local lStroke = Instance.new("UIStroke")
        lStroke.Color = T.Border
        lStroke.Thickness = 1
        lStroke.Transparency = 0.5
        lStroke.Parent = launchBtn
    end

    -- Hover effects
    card.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            TweenService:Create(card, TWEEN_FAST, {BackgroundColor3 = T.CardHover}):Play()
            TweenService:Create(cardStroke, TWEEN_FAST, {Color = accentColor, Transparency = 0.3}):Play()
        end
    end)
    card.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            TweenService:Create(card, TWEEN_FAST, {BackgroundColor3 = T.Card}):Play()
            TweenService:Create(cardStroke, TWEEN_FAST, {
                Color = isDetected and accentColor or T.Border,
                Transparency = isDetected and 0.15 or 0.6,
            }):Play()
        end
    end)

    launchBtn.MouseEnter:Connect(function()
        TweenService:Create(launchBtn, TWEEN_FAST, {
            BackgroundColor3 = accentColor, TextColor3 = Color3.new(1,1,1)
        }):Play()
    end)
    launchBtn.MouseLeave:Connect(function()
        TweenService:Create(launchBtn, TWEEN_FAST, {
            BackgroundColor3 = isDetected and accentColor or T.Surface,
            TextColor3 = isDetected and Color3.new(1,1,1) or T.TextMuted,
        }):Play()
    end)

    -- Click: cancel auto-launch + launch
    launchBtn.MouseButton1Click:Connect(function()
        autoLaunchCancelled = true

        -- Press animation
        TweenService:Create(launchBtn, TweenInfo.new(0.08), {Size = UDim2.new(0, 64, 0, 28)}):Play()
        task.wait(0.08)
        TweenService:Create(launchBtn, TweenInfo.new(0.08), {Size = UDim2.new(0, 70, 0, 32)}):Play()

        launchBtn.Text = "..."
        launchBtn.BackgroundColor3 = T.Yellow
        launchBtn.TextColor3 = T.BG

        task.spawn(function() launchScript(entry) end)
    end)

    -- Also cancel auto-launch if any card is hovered
    card.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            -- Only cancel if hovering a different card than detected
            if not isDetected then
                autoLaunchCancelled = true
            end
        end
    end)

    table.insert(allCards, card)
    return card
end

-- ═══════════════════════════════════════════
-- STATUS BAR
-- ═══════════════════════════════════════════
local statusFrame = Instance.new("Frame")
statusFrame.Name = "Status"
statusFrame.Size = UDim2.new(1, 0, 0, 48)
statusFrame.BackgroundColor3 = T.Surface
statusFrame.BorderSizePixel = 0
statusFrame.LayoutOrder = -2
statusFrame.ZIndex = 3
statusFrame.Parent = Content
statusFrame.ClipsDescendants = true
Instance.new("UICorner", statusFrame).CornerRadius = UDim.new(0, 10)

statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 1, 0)
statusLabel.Position = UDim2.new(0, 10, 0, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.FontFace = T.Font
statusLabel.TextSize = 11
statusLabel.TextColor3 = T.TextMuted
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.ZIndex = 4
statusLabel.Parent = statusFrame

if detectedEntry then
    statusLabel.Text = "✨  " .. detectedEntry.name .. " detected  ·  Auto-launching in 5s"
    statusLabel.TextColor3 = T.Green

    -- Progress bar inside status
    local progressBg = Instance.new("Frame")
    progressBg.Size = UDim2.new(1, 0, 0, 3)
    progressBg.Position = UDim2.new(0, 0, 1, -3)
    progressBg.BackgroundColor3 = T.Card
    progressBg.BorderSizePixel = 0
    progressBg.ZIndex = 4
    progressBg.Parent = statusFrame

    local progressFill = Instance.new("Frame")
    progressFill.Name = "Fill"
    progressFill.Size = UDim2.new(0, 0, 1, 0)
    progressFill.BackgroundColor3 = detectedEntry.color or T.Accent
    progressFill.BorderSizePixel = 0
    progressFill.ZIndex = 5
    progressFill.Parent = progressBg

    -- Animate progress over 5 seconds
    TweenService:Create(progressFill, TweenInfo.new(5, Enum.EasingStyle.Linear), {
        Size = UDim2.new(1, 0, 1, 0)
    }):Play()
else
    statusLabel.Text = "⚠  Game not recognized  ·  Select a script to launch"
    statusLabel.TextColor3 = T.Yellow
end

-- ═══════════════════════════════════════════
-- BUILD CARDS (staggered entry animation)
-- ═══════════════════════════════════════════
for i, entry in ipairs(SCRIPTS) do
    createCard(entry, i)
end

-- ═══════════════════════════════════════════
-- FOOTER
-- ═══════════════════════════════════════════
local footer = Instance.new("Frame")
footer.Size = UDim2.new(1, 0, 0, 20)
footer.BackgroundTransparency = 1
footer.LayoutOrder = 200
footer.ZIndex = 3
footer.Parent = Content

local footerText = Instance.new("TextLabel")
footerText.Size = UDim2.new(1, 0, 1, 0)
footerText.BackgroundTransparency = 1
footerText.FontFace = T.FontLight
footerText.Text = "Xaric Hub v" .. HUB_VERSION .. "  ·  " .. #SCRIPTS .. " exploits loaded  ·  PlaceId " .. game.PlaceId
footerText.TextColor3 = T.TextDim
footerText.TextSize = 9
footerText.ZIndex = 4
footerText.Parent = footer

-- ═══════════════════════════════════════════
-- OPEN ANIMATION (staggered cards)
-- ═══════════════════════════════════════════
-- First expand the main frame
TweenService:Create(MainFrame, TWEEN_OPEN, {Size = UDim2.new(0, FRAME_W, 0, TARGET_H)}):Play()

-- Then stagger-fade each card
for i, card in ipairs(allCards) do
    card.BackgroundTransparency = 1
    for _, desc in ipairs(card:GetDescendants()) do
        if desc:IsA("GuiObject") then
            pcall(function()
                if desc.BackgroundTransparency < 1 then
                    local orig = desc.BackgroundTransparency
                    desc.BackgroundTransparency = 1
                    task.delay(0.3 + i * 0.06, function()
                        TweenService:Create(desc, TWEEN_MED, {BackgroundTransparency = orig}):Play()
                    end)
                end
            end)
        end
        if desc:IsA("TextLabel") or desc:IsA("TextButton") then
            pcall(function()
                local origTC = desc.TextColor3
                local origTT = desc.TextTransparency
                desc.TextTransparency = 1
                task.delay(0.3 + i * 0.06, function()
                    TweenService:Create(desc, TWEEN_MED, {TextTransparency = origTT}):Play()
                end)
            end)
        end
    end
    task.delay(0.3 + i * 0.06, function()
        TweenService:Create(card, TWEEN_MED, {BackgroundTransparency = 0}):Play()
    end)
end

-- ═══════════════════════════════════════════
-- CLOSE HANDLER
-- ═══════════════════════════════════════════
local function closeHub()
    autoLaunchCancelled = true
    local tw = TweenService:Create(MainFrame, TWEEN_CLOSE, {Size = UDim2.new(0, FRAME_W, 0, 0)})
    TweenService:Create(Backdrop, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
    tw:Play()
    tw.Completed:Wait()
    ScreenGui:Destroy()
end

closeBtn.MouseButton1Click:Connect(closeHub)
Backdrop.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        closeHub()
    end
end)

-- ═══════════════════════════════════════════
-- AUTO-LAUNCH COUNTDOWN
-- ═══════════════════════════════════════════
if detectedEntry then
    task.spawn(function()
        for i = 5, 1, -1 do
            if not ScreenGui.Parent or autoLaunchCancelled then
                if statusLabel and statusLabel.Parent then
                    statusLabel.Text = "✋  Auto-launch cancelled  ·  Select manually"
                    statusLabel.TextColor3 = T.TextMuted
                end
                return
            end
            statusLabel.Text = "✨  Auto-launching " .. detectedEntry.name .. " in " .. i .. "s"
            task.wait(1)
        end
        if not ScreenGui.Parent or autoLaunchCancelled then return end

        statusLabel.Text = "🚀  Launching " .. detectedEntry.name .. "..."
        statusLabel.TextColor3 = T.Accent
        task.wait(0.2)

        launchScript(detectedEntry)
    end)
end

-- ═══════════════════════════════════════════
-- KEYBIND: RightShift to reopen hub
-- ═══════════════════════════════════════════
getgenv()._xaricHubCleanup = function()
    pcall(function() ScreenGui:Destroy() end)
end

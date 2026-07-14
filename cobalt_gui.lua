--[[
    Cobalt v2.0 — In-Game Exploit GUI
    Draggable tabbed interface with:
      • Script Executor (multi-line editor + run)
      • Console Viewer (dev console logs)
      • Game Explorer (descendants tree)
      • Instance Search (selector queries)
      • Remote Spy (init / fetch / block)
      • Data Probe (get-data-by-code)
]]

-- Cleanup previous instance
if game:GetService("CoreGui"):FindFirstChild("CobaltGUI") then
    game:GetService("CoreGui"):FindFirstChild("CobaltGUI"):Destroy()
end

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- ═══════════════════════════════════════════
-- THEME / CONSTANTS
-- ═══════════════════════════════════════════
local Theme = {
    BG           = Color3.fromRGB(16, 16, 22),
    BG2          = Color3.fromRGB(22, 22, 30),
    Surface      = Color3.fromRGB(28, 28, 38),
    Surface2     = Color3.fromRGB(34, 34, 46),
    Border       = Color3.fromRGB(48, 48, 65),
    BorderLight  = Color3.fromRGB(60, 60, 80),
    Text         = Color3.fromRGB(220, 220, 235),
    TextDim      = Color3.fromRGB(140, 140, 165),
    TextMuted    = Color3.fromRGB(90, 90, 115),
    Accent       = Color3.fromRGB(130, 100, 255),
    AccentDim    = Color3.fromRGB(100, 75, 200),
    AccentGlow   = Color3.fromRGB(160, 130, 255),
    Green        = Color3.fromRGB(80, 220, 140),
    Red          = Color3.fromRGB(240, 80, 90),
    Yellow       = Color3.fromRGB(240, 200, 80),
    Orange       = Color3.fromRGB(240, 150, 60),
    Cyan         = Color3.fromRGB(80, 200, 240),
}

local FONT_MONO = Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.Regular)
local FONT_MONO_BOLD = Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.Bold)
local FONT_UI = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
local FONT_UI_BOLD = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
local FONT_UI_LIGHT = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular)

local TWEEN_FAST = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_MED  = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_SLOW = TweenInfo.new(0.4,  Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local WIN_SIZE = UDim2.fromOffset(780, 500)
local SIDEBAR_W = 140
local TOPBAR_H = 38
local MINIMIZE_SIZE = UDim2.fromOffset(200, TOPBAR_H)

-- ═══════════════════════════════════════════
-- UTILITY FUNCTIONS
-- ═══════════════════════════════════════════
local function create(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        inst[k] = v
    end
    for _, child in ipairs(children or {}) do
        child.Parent = inst
    end
    return inst
end

local function addCorner(parent, radius)
    return create("UICorner", {CornerRadius = UDim.new(0, radius or 6), Parent = parent})
end

local function addStroke(parent, color, thickness)
    return create("UIStroke", {Color = color or Theme.Border, Thickness = thickness or 1, Parent = parent})
end

local function addPadding(parent, t, r, b, l)
    return create("UIPadding", {
        PaddingTop = UDim.new(0, t or 6),
        PaddingRight = UDim.new(0, r or 6),
        PaddingBottom = UDim.new(0, b or 6),
        PaddingLeft = UDim.new(0, l or 6),
        Parent = parent
    })
end

local function tween(obj, tweenInfo, props)
    local t = TweenService:Create(obj, tweenInfo, props)
    t:Play()
    return t
end

local function truncate(str, maxLen)
    if #str > maxLen then
        return string.sub(str, 1, maxLen) .. "..."
    end
    return str
end

local function formatTime()
    return os.date("%H:%M:%S")
end

-- ═══════════════════════════════════════════
-- SCREENGU & ROOT
-- ═══════════════════════════════════════════
local screenGui = create("ScreenGui", {
    Name = "CobaltGUI",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 999,
    Parent = CoreGui
})

-- Main window frame
local mainFrame = create("Frame", {
    Name = "MainFrame",
    Size = WIN_SIZE,
    Position = UDim2.new(0.5, -WIN_SIZE.X.Offset/2, 0.5, -WIN_SIZE.Y.Offset/2),
    BackgroundColor3 = Theme.BG,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    Parent = screenGui
})
addCorner(mainFrame, 10)
addStroke(mainFrame, Theme.Border, 1)

-- Drop shadow (fake)
local shadow = create("ImageLabel", {
    Name = "Shadow",
    Size = UDim2.new(1, 30, 1, 30),
    Position = UDim2.new(0, -15, 0, -15),
    BackgroundTransparency = 1,
    Image = "rbxassetid://5554236805",
    ImageColor3 = Color3.fromRGB(0, 0, 0),
    ImageTransparency = 0.5,
    ScaleType = Enum.ScaleType.Slice,
    SliceCenter = Rect.new(23, 23, 277, 277),
    ZIndex = 0,
    Parent = mainFrame
})

-- ═══════════════════════════════════════════
-- TOPBAR
-- ═══════════════════════════════════════════
local topbar = create("Frame", {
    Name = "Topbar",
    Size = UDim2.new(1, 0, 0, TOPBAR_H),
    BackgroundColor3 = Theme.BG2,
    BorderSizePixel = 0,
    ZIndex = 10,
    Parent = mainFrame
})
addCorner(topbar, 10)
-- Mask bottom corners of topbar
create("Frame", {
    Size = UDim2.new(1, 0, 0, 12),
    Position = UDim2.new(0, 0, 1, -12),
    BackgroundColor3 = Theme.BG2,
    BorderSizePixel = 0,
    ZIndex = 10,
    Parent = topbar
})

-- Logo
local logoLabel = create("TextLabel", {
    Size = UDim2.new(0, 120, 1, 0),
    Position = UDim2.new(0, 12, 0, 0),
    BackgroundTransparency = 1,
    Text = "◆ Cobalt",
    FontFace = FONT_UI_BOLD,
    TextSize = 15,
    TextColor3 = Theme.AccentGlow,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 11,
    Parent = topbar
})

-- Version badge
local verBadge = create("TextLabel", {
    Size = UDim2.new(0, 30, 0, 16),
    Position = UDim2.new(0, 90, 0.5, -8),
    BackgroundColor3 = Theme.Accent,
    BackgroundTransparency = 0.85,
    Text = "v2",
    FontFace = FONT_UI,
    TextSize = 10,
    TextColor3 = Theme.AccentGlow,
    TextXAlignment = Enum.TextXAlignment.Center,
    ZIndex = 11,
    Parent = topbar
})
addCorner(verBadge, 4)

-- Game info (center)
local gameInfoLabel = create("TextLabel", {
    Size = UDim2.new(1, -280, 1, 0),
    Position = UDim2.new(0, 130, 0, 0),
    BackgroundTransparency = 1,
    Text = "Connecting...",
    FontFace = FONT_UI_LIGHT,
    TextSize = 11,
    TextColor3 = Theme.TextDim,
    TextXAlignment = Enum.TextXAlignment.Center,
    TextTruncate = Enum.TextTruncate.AtEnd,
    ZIndex = 11,
    Parent = topbar
})

-- Status dot
local statusDot = create("Frame", {
    Size = UDim2.fromOffset(8, 8),
    Position = UDim2.new(0, 122, 0.5, -4),
    BackgroundColor3 = Theme.Green,
    BorderSizePixel = 0,
    ZIndex = 11,
    Parent = topbar
})
addCorner(statusDot, 4)

-- Topbar buttons (right side)
local btnMinimize = create("TextButton", {
    Size = UDim2.fromOffset(30, 22),
    Position = UDim2.new(1, -72, 0.5, -11),
    BackgroundColor3 = Theme.Surface,
    BackgroundTransparency = 0.5,
    Text = "─",
    FontFace = FONT_UI_BOLD,
    TextSize = 14,
    TextColor3 = Theme.TextDim,
    ZIndex = 11,
    Parent = topbar
})
addCorner(btnMinimize, 4)

local btnClose = create("TextButton", {
    Size = UDim2.fromOffset(30, 22),
    Position = UDim2.new(1, -38, 0.5, -11),
    BackgroundColor3 = Theme.Red,
    BackgroundTransparency = 0.7,
    Text = "✕",
    FontFace = FONT_UI_BOLD,
    TextSize = 12,
    TextColor3 = Theme.Red,
    ZIndex = 11,
    Parent = topbar
})
addCorner(btnClose, 4)

-- ═══════════════════════════════════════════
-- DRAGGING
-- ═══════════════════════════════════════════
local dragging, dragStart, startPos
topbar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

-- ═══════════════════════════════════════════
-- MINIMIZE / CLOSE
-- ═══════════════════════════════════════════
local isMinimized = false
local savedSize, savedPos

btnMinimize.MouseButton1Click:Connect(function()
    if isMinimized then
        isMinimized = false
        tween(mainFrame, TWEEN_MED, {Size = savedSize})
        btnMinimize.Text = "─"
    else
        isMinimized = true
        savedSize = mainFrame.Size
        tween(mainFrame, TWEEN_MED, {Size = MINIMIZE_SIZE})
        btnMinimize.Text = "□"
    end
end)

btnClose.MouseButton1Click:Connect(function()
    tween(mainFrame, TWEEN_FAST, {Size = UDim2.fromOffset(0, 0)})
    task.wait(0.2)
    screenGui:Destroy()
end)

-- Button hover effects
for _, btn in ipairs({btnMinimize, btnClose}) do
    btn.MouseEnter:Connect(function()
        tween(btn, TWEEN_FAST, {BackgroundTransparency = 0.2})
    end)
    btn.MouseLeave:Connect(function()
        tween(btn, TWEEN_FAST, {BackgroundTransparency = btn == btnClose and 0.7 or 0.5})
    end)
end

-- ═══════════════════════════════════════════
-- BODY (below topbar)
-- ═══════════════════════════════════════════
local body = create("Frame", {
    Name = "Body",
    Size = UDim2.new(1, 0, 1, -TOPBAR_H),
    Position = UDim2.new(0, 0, 0, TOPBAR_H),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    Parent = mainFrame
})

-- ═══════════════════════════════════════════
-- SIDEBAR
-- ═══════════════════════════════════════════
local sidebar = create("Frame", {
    Name = "Sidebar",
    Size = UDim2.new(0, SIDEBAR_W, 1, 0),
    BackgroundColor3 = Theme.BG2,
    BorderSizePixel = 0,
    Parent = body
})

-- Sidebar border right
create("Frame", {
    Size = UDim2.new(0, 1, 1, 0),
    Position = UDim2.new(1, 0, 0, 0),
    BackgroundColor3 = Theme.Border,
    BorderSizePixel = 0,
    Parent = sidebar
})

local sidebarList = create("Frame", {
    Size = UDim2.new(1, -12, 1, -12),
    Position = UDim2.new(0, 6, 0, 6),
    BackgroundTransparency = 1,
    Parent = sidebar
})
create("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 2),
    Parent = sidebarList
})

-- Tab definitions
local tabs = {
    {id = "executor",  icon = "▶",  label = "Executor",   order = 1},
    {id = "console",   icon = "≡",  label = "Console",    order = 2},
    {id = "explorer",  icon = "📁", label = "Explorer",   order = 3},
    {id = "search",    icon = "🔍", label = "Search",     order = 4},
    {id = "remotespy", icon = "👁", label = "Remote Spy", order = 5},
    {id = "scripts",   icon = "📜", label = "Scripts",    order = 6},
    {id = "dataprobe", icon = "⚡", label = "Data Probe", order = 7},
}

local tabButtons = {}
local panels = {}
-- Start without an active tab.  Panels are created hidden, so setting this to
-- "executor" here makes the first switchTab("executor") return early and
-- leaves the entire content area blank.
local activeTab = nil

local function createSidebarButton(tabDef)
    local btn = create("TextButton", {
        Name = "Tab_" .. tabDef.id,
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 1,
        Text = "",
        LayoutOrder = tabDef.order,
        Parent = sidebarList
    })
    addCorner(btn, 6)

    local icon = create("TextLabel", {
        Size = UDim2.fromOffset(20, 30),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Text = tabDef.icon,
        FontFace = FONT_UI,
        TextSize = 13,
        TextColor3 = Theme.TextDim,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = btn
    })

    local label = create("TextLabel", {
        Size = UDim2.new(1, -36, 1, 0),
        Position = UDim2.new(0, 32, 0, 0),
        BackgroundTransparency = 1,
        Text = tabDef.label,
        FontFace = FONT_UI,
        TextSize = 11,
        TextColor3 = Theme.TextDim,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = btn
    })

    -- Accent bar (left edge indicator)
    local bar = create("Frame", {
        Size = UDim2.new(0, 3, 0, 0),
        Position = UDim2.new(0, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Parent = btn
    })
    addCorner(bar, 2)

    tabButtons[tabDef.id] = {button = btn, icon = icon, label = label, bar = bar}

    btn.MouseEnter:Connect(function()
        if activeTab ~= tabDef.id then
            tween(btn, TWEEN_FAST, {BackgroundTransparency = 0.85})
        end
    end)
    btn.MouseLeave:Connect(function()
        if activeTab ~= tabDef.id then
            tween(btn, TWEEN_FAST, {BackgroundTransparency = 1})
        end
    end)

    return btn
end

-- ═══════════════════════════════════════════
-- CONTENT AREA
-- ═══════════════════════════════════════════
local content = create("Frame", {
    Name = "Content",
    Size = UDim2.new(1, -SIDEBAR_W, 1, 0),
    Position = UDim2.new(0, SIDEBAR_W, 0, 0),
    BackgroundColor3 = Theme.BG,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    Parent = body
})

-- ═══════════════════════════════════════════
-- PANEL FACTORY HELPERS
-- ═══════════════════════════════════════════
local function createPanel(id)
    local panel = create("Frame", {
        Name = "Panel_" .. id,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible = (id == "executor"),
        Parent = content
    })
    panels[id] = panel
    return panel
end

local function createPanelHeader(parent, title)
    local header = create("Frame", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = Theme.Surface,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Parent = parent
    })
    create("TextLabel", {
        Size = UDim2.new(0, 200, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = title,
        FontFace = FONT_UI_BOLD,
        TextSize = 13,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = header
    })
    -- Bottom border
    create("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Theme.Border,
        BorderSizePixel = 0,
        Parent = header
    })
    return header
end

local function createScrollOutput(parent, yOffset)
    local scroll = create("ScrollingFrame", {
        Size = UDim2.new(1, -16, 1, -(yOffset or 44)),
        Position = UDim2.new(0, 8, 0, (yOffset or 44)),
        BackgroundColor3 = Theme.Surface,
        BackgroundTransparency = 0.6,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Theme.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = parent
    })
    addCorner(scroll, 6)
    addPadding(scroll, 6, 8, 6, 8)
    create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
        Parent = scroll
    })
    return scroll
end

local function addOutputLine(scroll, text, color, order)
    local line = create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Text = text,
        FontFace = FONT_MONO,
        TextSize = 11,
        TextColor3 = color or Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        RichText = true,
        LayoutOrder = order or (#scroll:GetChildren()),
        Parent = scroll
    })
    -- Auto scroll to bottom
    task.defer(function()
        scroll.CanvasPosition = Vector2.new(0, scroll.AbsoluteCanvasSize.Y)
    end)
    return line
end

local function clearOutput(scroll)
    for _, child in ipairs(scroll:GetChildren()) do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
    end
end

local function createSmallButton(parent, text, color, size, pos)
    local btn = create("TextButton", {
        Size = size or UDim2.fromOffset(70, 26),
        Position = pos or UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = color or Theme.Accent,
        Text = text,
        FontFace = FONT_UI_BOLD,
        TextSize = 11,
        TextColor3 = Theme.Text,
        Parent = parent
    })
    addCorner(btn, 5)
    btn.MouseEnter:Connect(function() tween(btn, TWEEN_FAST, {BackgroundTransparency = 0.2}) end)
    btn.MouseLeave:Connect(function() tween(btn, TWEEN_FAST, {BackgroundTransparency = 0}) end)
    return btn
end

local function createTextInput(parent, placeholder, size, pos, multiline)
    local box = create("TextBox", {
        Size = size or UDim2.new(1, 0, 0, 26),
        Position = pos or UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Theme.Surface2,
        Text = "",
        PlaceholderText = placeholder or "",
        PlaceholderColor3 = Theme.TextMuted,
        FontFace = FONT_MONO,
        TextSize = 11,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        MultiLine = multiline or false,
        TextWrapped = multiline or false,
        Parent = parent
    })
    addCorner(box, 5)
    addStroke(box, Theme.Border, 1)
    addPadding(box, 4, 8, 4, 8)
    box.Focused:Connect(function()
        box:FindFirstChildWhichIsA("UIStroke").Color = Theme.Accent
    end)
    box.FocusLost:Connect(function()
        box:FindFirstChildWhichIsA("UIStroke").Color = Theme.Border
    end)
    return box
end

-- ═══════════════════════════════════════════
-- PANEL: EXECUTOR
-- ═══════════════════════════════════════════
local execPanel = createPanel("executor")
local execHeader = createPanelHeader(execPanel, "Script Executor")

-- Action buttons row (in header)
local execBtn = createSmallButton(execHeader, "▶ Execute", Theme.Accent,
    UDim2.fromOffset(80, 24), UDim2.new(1, -180, 0.5, -12))
local execClearBtn = createSmallButton(execHeader, "Clear", Theme.Surface2,
    UDim2.fromOffset(50, 24), UDim2.new(1, -95, 0.5, -12))

-- Editor area (top 60%)
local editorFrame = create("Frame", {
    Size = UDim2.new(1, -16, 0.6, -44),
    Position = UDim2.new(0, 8, 0, 42),
    BackgroundColor3 = Theme.Surface,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    Parent = execPanel
})
addCorner(editorFrame, 6)
addStroke(editorFrame, Theme.Border, 1)

-- Language badge
create("TextLabel", {
    Size = UDim2.fromOffset(40, 16),
    Position = UDim2.new(1, -48, 0, 4),
    BackgroundColor3 = Theme.AccentDim,
    BackgroundTransparency = 0.8,
    Text = "Luau",
    FontFace = FONT_UI,
    TextSize = 9,
    TextColor3 = Theme.AccentGlow,
    ZIndex = 5,
    Parent = editorFrame
})
addCorner(editorFrame:FindFirstChild("TextLabel"), 3)

local editorBox = create("TextBox", {
    Size = UDim2.new(1, -8, 1, -4),
    Position = UDim2.new(0, 4, 0, 2),
    BackgroundTransparency = 1,
    Text = '-- Welcome to Cobalt v2\n-- Type your Luau script here\n\nprint("Hello from Cobalt!")',
    PlaceholderText = "-- Enter Luau code...",
    PlaceholderColor3 = Theme.TextMuted,
    FontFace = FONT_MONO,
    TextSize = 12,
    TextColor3 = Theme.Text,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    ClearTextOnFocus = false,
    MultiLine = true,
    TextWrapped = true,
    Parent = editorFrame
})
addPadding(editorBox, 6, 8, 6, 8)

-- Output area (bottom 40%)
local outputLabel = create("TextLabel", {
    Size = UDim2.new(0, 60, 0, 18),
    Position = UDim2.new(0, 12, 0.6, 2),
    BackgroundTransparency = 1,
    Text = "Output",
    FontFace = FONT_UI,
    TextSize = 10,
    TextColor3 = Theme.TextMuted,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = execPanel
})

local execOutput = createScrollOutput(execPanel, nil)
execOutput.Size = UDim2.new(1, -16, 0.4, -8)
execOutput.Position = UDim2.new(0, 8, 0.6, 20)

addOutputLine(execOutput, '<font color="#8c8ca5">Ready — paste or type a script and hit Execute.</font>', Theme.TextMuted, 0)

-- Execute logic
execBtn.MouseButton1Click:Connect(function()
    local code = editorBox.Text
    if code == "" then return end
    addOutputLine(execOutput, '<font color="#50c88c">[' .. formatTime() .. '] Executing...</font>', Theme.Green)
    local ok, err = pcall(function()
        local fn = loadstring(code)
        if fn then
            fn()
        else
            error("Failed to compile script")
        end
    end)
    if ok then
        addOutputLine(execOutput, '<font color="#50c88c">[' .. formatTime() .. '] ✓ Executed successfully</font>', Theme.Green)
    else
        addOutputLine(execOutput, '<font color="#f0505a">[' .. formatTime() .. '] ✗ ' .. tostring(err) .. '</font>', Theme.Red)
    end
end)

execClearBtn.MouseButton1Click:Connect(function()
    editorBox.Text = ""
    clearOutput(execOutput)
    addOutputLine(execOutput, '<font color="#8c8ca5">Cleared.</font>', Theme.TextMuted, 0)
end)

-- ═══════════════════════════════════════════
-- PANEL: CONSOLE
-- ═══════════════════════════════════════════
local consolePanel = createPanel("console")
local consoleHeader = createPanelHeader(consolePanel, "Console Output")

local consoleFetchBtn = createSmallButton(consoleHeader, "⟳ Fetch", Theme.Accent,
    UDim2.fromOffset(70, 24), UDim2.new(1, -85, 0.5, -12))

local consoleOutput = createScrollOutput(consolePanel)
addOutputLine(consoleOutput, '<font color="#8c8ca5">Click Fetch to pull dev console logs.</font>', Theme.TextMuted, 0)

consoleFetchBtn.MouseButton1Click:Connect(function()
    clearOutput(consoleOutput)
    addOutputLine(consoleOutput, '<font color="#50c8f0">Fetching console logs...</font>', Theme.Cyan, 0)
    -- Pull from LogService
    local logService = game:GetService("LogService")
    local history = logService:GetLogHistory()
    clearOutput(consoleOutput)
    if #history == 0 then
        addOutputLine(consoleOutput, '<font color="#8c8ca5">No logs found.</font>', Theme.TextMuted, 0)
        return
    end
    local count = math.min(#history, 50)
    for i = math.max(1, #history - count + 1), #history do
        local entry = history[i]
        local color = "#dcdceb"
        if entry.messageType == Enum.MessageType.MessageWarning then
            color = "#f0c850"
        elseif entry.messageType == Enum.MessageType.MessageError then
            color = "#f0505a"
        elseif entry.messageType == Enum.MessageType.MessageInfo then
            color = "#50c8f0"
        end
        addOutputLine(consoleOutput, '<font color="' .. color .. '">' .. tostring(entry.message) .. '</font>', nil, i)
    end
end)

-- ═══════════════════════════════════════════
-- PANEL: EXPLORER
-- ═══════════════════════════════════════════
local explorePanel = createPanel("explorer")
local exploreHeader = createPanelHeader(explorePanel, "Game Explorer")

local exploreInput = createTextInput(exploreHeader, "Path (e.g. game.Workspace)",
    UDim2.new(0, 220, 0, 24), UDim2.new(1, -390, 0.5, -12))
exploreInput.Text = "game"

local exploreBtn = createSmallButton(exploreHeader, "Explore", Theme.Accent,
    UDim2.fromOffset(65, 24), UDim2.new(1, -160, 0.5, -12))

local exploreDepthInput = createTextInput(exploreHeader, "Depth",
    UDim2.fromOffset(45, 24), UDim2.new(1, -90, 0.5, -12))
exploreDepthInput.Text = "2"

local exploreOutput = createScrollOutput(explorePanel)
addOutputLine(exploreOutput, '<font color="#8c8ca5">Enter a path and click Explore to browse the instance tree.</font>', Theme.TextMuted, 0)

local function resolveInstancePath(path)
    local parts = string.split(path, ".")
    local current = game
    for i = 1, #parts do
        local part = parts[i]
        if part == "game" and i == 1 then
            current = game
        else
            local child = current:FindFirstChild(part)
            if not child then
                return nil, "Could not find: " .. part .. " in " .. current:GetFullName()
            end
            current = child
        end
    end
    return current
end

local function buildTree(instance, depth, maxDepth, order)
    if depth > maxDepth then return order end
    local indent = string.rep("  ", depth)
    local icon = "📄"
    if instance:IsA("Folder") then icon = "📁"
    elseif instance:IsA("Model") then icon = "🔷"
    elseif instance:IsA("Script") or instance:IsA("LocalScript") or instance:IsA("ModuleScript") then icon = "📜"
    elseif instance:IsA("BasePart") then icon = "🟦"
    elseif instance:IsA("ScreenGui") or instance:IsA("Frame") or instance:IsA("TextLabel") then icon = "🖼"
    elseif instance:IsA("RemoteEvent") or instance:IsA("RemoteFunction") then icon = "📡"
    end
    local className = '<font color="#8c8ca5">[' .. instance.ClassName .. ']</font>'
    addOutputLine(exploreOutput, indent .. icon .. " " .. instance.Name .. " " .. className, Theme.Text, order)
    order = order + 1
    local children = instance:GetChildren()
    local cap = math.min(#children, 25)
    for i = 1, cap do
        order = buildTree(children[i], depth + 1, maxDepth, order)
    end
    if #children > cap then
        addOutputLine(exploreOutput, indent .. '  <font color="#8c8ca5">... and ' .. (#children - cap) .. ' more</font>', Theme.TextMuted, order)
        order = order + 1
    end
    return order
end

exploreBtn.MouseButton1Click:Connect(function()
    clearOutput(exploreOutput)
    local path = exploreInput.Text
    local depth = tonumber(exploreDepthInput.Text) or 2
    depth = math.clamp(depth, 1, 5)
    local inst, err = resolveInstancePath(path)
    if not inst then
        addOutputLine(exploreOutput, '<font color="#f0505a">Error: ' .. tostring(err) .. '</font>', Theme.Red, 0)
        return
    end
    addOutputLine(exploreOutput, '<font color="#a08cff">▼ ' .. inst:GetFullName() .. '</font>', Theme.Accent, 0)
    buildTree(inst, 0, depth, 1)
end)

-- ═══════════════════════════════════════════
-- PANEL: SEARCH
-- ═══════════════════════════════════════════
local searchPanel = createPanel("search")
local searchHeader = createPanelHeader(searchPanel, "Instance Search")

local searchInput = createTextInput(searchHeader, "Class, name, or property query",
    UDim2.new(0, 240, 0, 24), UDim2.new(1, -400, 0.5, -12))

local searchRootInput = createTextInput(searchHeader, "Root",
    UDim2.fromOffset(100, 24), UDim2.new(1, -150, 0.5, -12))
searchRootInput.Text = "game"

local searchBtn = createSmallButton(searchHeader, "Search", Theme.Accent,
    UDim2.fromOffset(60, 24), UDim2.new(1, -45, 0.5, -12))

local searchOutput = createScrollOutput(searchPanel)
addOutputLine(searchOutput, '<font color="#8c8ca5">Search for instances by ClassName, Name, or properties.</font>', Theme.TextMuted, 0)

searchBtn.MouseButton1Click:Connect(function()
    clearOutput(searchOutput)
    local query = searchInput.Text
    local rootPath = searchRootInput.Text
    if query == "" then
        addOutputLine(searchOutput, '<font color="#f0c850">Enter a search query.</font>', Theme.Yellow, 0)
        return
    end
    local root, err = resolveInstancePath(rootPath)
    if not root then
        addOutputLine(searchOutput, '<font color="#f0505a">Error: ' .. tostring(err) .. '</font>', Theme.Red, 0)
        return
    end
    addOutputLine(searchOutput, '<font color="#50c8f0">Searching for "' .. query .. '" under ' .. root:GetFullName() .. '...</font>', Theme.Cyan, 0)
    local results = {}
    local function searchRecursive(inst)
        if #results >= 50 then return end
        local nameMatch = string.find(string.lower(inst.Name), string.lower(query))
        local classMatch = string.find(string.lower(inst.ClassName), string.lower(query))
        if nameMatch or classMatch then
            table.insert(results, inst)
        end
        for _, child in ipairs(inst:GetChildren()) do
            searchRecursive(child)
        end
    end
    searchRecursive(root)
    clearOutput(searchOutput)
    if #results == 0 then
        addOutputLine(searchOutput, '<font color="#8c8ca5">No results found.</font>', Theme.TextMuted, 0)
    else
        addOutputLine(searchOutput, '<font color="#50c88c">Found ' .. #results .. ' result(s):</font>', Theme.Green, 0)
        for i, inst in ipairs(results) do
            local className = '<font color="#8c8ca5">[' .. inst.ClassName .. ']</font>'
            addOutputLine(searchOutput, "  " .. inst:GetFullName() .. " " .. className, Theme.Text, i)
        end
    end
end)

-- ═══════════════════════════════════════════
-- PANEL: REMOTE SPY
-- ═══════════════════════════════════════════
local spyPanel = createPanel("remotespy")
local spyHeader = createPanelHeader(spyPanel, "Remote Spy")

local spyInitBtn = createSmallButton(spyHeader, "Init", Theme.Green,
    UDim2.fromOffset(45, 24), UDim2.new(1, -195, 0.5, -12))
local spyFetchBtn = createSmallButton(spyHeader, "Fetch", Theme.Accent,
    UDim2.fromOffset(50, 24), UDim2.new(1, -143, 0.5, -12))
local spyClearBtn = createSmallButton(spyHeader, "Clear", Theme.Surface2,
    UDim2.fromOffset(50, 24), UDim2.new(1, -87, 0.5, -12))

local spyOutput = createScrollOutput(spyPanel)
addOutputLine(spyOutput, '<font color="#8c8ca5">Remote Spy — hooks RemoteEvents and RemoteFunctions.</font>', Theme.TextMuted, 0)
addOutputLine(spyOutput, '<font color="#8c8ca5">Click "Init" to install hooks, then "Fetch" to view captured calls.</font>', Theme.TextMuted, 1)

local spyHooked = false
local spyLogs = {}

spyInitBtn.MouseButton1Click:Connect(function()
    if spyHooked then
        addOutputLine(spyOutput, '<font color="#f0c850">Already hooked.</font>', Theme.Yellow)
        return
    end
    clearOutput(spyOutput)
    addOutputLine(spyOutput, '<font color="#50c88c">Installing remote spy hooks...</font>', Theme.Green, 0)

    local hookOk, hookErr = pcall(function()
        -- Hook __namecall
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if method == "FireServer" or method == "InvokeServer" then
                local args = {...}
                local argStr = ""
                for i, v in ipairs(args) do
                    argStr = argStr .. tostring(v)
                    if i < #args then argStr = argStr .. ", " end
                end
                table.insert(spyLogs, {
                    time = formatTime(),
                    name = tostring(self),
                    path = self:GetFullName(),
                    method = method,
                    args = truncate(argStr, 200),
                    direction = "Outgoing"
                })
                if #spyLogs > 500 then
                    table.remove(spyLogs, 1)
                end
            end
            return oldNamecall(self, ...)
        end))
    end)

    if hookOk then
        spyHooked = true
        addOutputLine(spyOutput, '<font color="#50c88c">✓ Remote spy active. Calls will be logged.</font>', Theme.Green, 1)
    else
        addOutputLine(spyOutput, '<font color="#f0505a">✗ Hook failed: ' .. tostring(hookErr) .. '</font>', Theme.Red, 1)
        addOutputLine(spyOutput, '<font color="#8c8ca5">Note: hookmetamethod may not be available in all executors.</font>', Theme.TextMuted, 2)
    end
end)

spyFetchBtn.MouseButton1Click:Connect(function()
    clearOutput(spyOutput)
    if #spyLogs == 0 then
        addOutputLine(spyOutput, '<font color="#8c8ca5">No remote calls captured yet.</font>', Theme.TextMuted, 0)
        return
    end
    addOutputLine(spyOutput, '<font color="#a08cff">Captured ' .. #spyLogs .. ' remote call(s):</font>', Theme.Accent, 0)
    local start = math.max(1, #spyLogs - 50)
    for i = start, #spyLogs do
        local log = spyLogs[i]
        local dir = log.direction == "Outgoing" and '<font color="#f0963c">OUT</font>' or '<font color="#50c8f0">IN</font>'
        addOutputLine(spyOutput,
            '<font color="#8c8ca5">[' .. log.time .. ']</font> ' .. dir ..
            ' <font color="#dcdceb">' .. log.name .. '</font>' ..
            '.<font color="#f0c850">' .. log.method .. '</font>' ..
            '(<font color="#8c8ca5">' .. log.args .. '</font>)',
            Theme.Text, i)
    end
end)

spyClearBtn.MouseButton1Click:Connect(function()
    spyLogs = {}
    clearOutput(spyOutput)
    addOutputLine(spyOutput, '<font color="#8c8ca5">Logs cleared.</font>', Theme.TextMuted, 0)
end)

-- ═══════════════════════════════════════════
-- PANEL: SCRIPTS (grep)
-- ═══════════════════════════════════════════
local scriptsPanel = createPanel("scripts")
local scriptsHeader = createPanelHeader(scriptsPanel, "Script Grep")

local grepInput = createTextInput(scriptsHeader, "Search scripts...",
    UDim2.new(0, 220, 0, 24), UDim2.new(1, -310, 0.5, -12))

local grepBtn = createSmallButton(scriptsHeader, "Grep", Theme.Accent,
    UDim2.fromOffset(55, 24), UDim2.new(1, -80, 0.5, -12))

local scriptsOutput = createScrollOutput(scriptsPanel)
addOutputLine(scriptsOutput, '<font color="#8c8ca5">Search through all LocalScripts and ModuleScripts for patterns.</font>', Theme.TextMuted, 0)

grepBtn.MouseButton1Click:Connect(function()
    clearOutput(scriptsOutput)
    local query = grepInput.Text
    if query == "" then
        addOutputLine(scriptsOutput, '<font color="#f0c850">Enter a search query.</font>', Theme.Yellow, 0)
        return
    end
    addOutputLine(scriptsOutput, '<font color="#50c8f0">Searching scripts for "' .. query .. '"...</font>', Theme.Cyan, 0)

    local results = {}
    local function grepScript(script)
        if #results >= 30 then return end
        local ok, source = pcall(function()
            if typeof(decompile) == "function" then
                return decompile(script)
            elseif typeof(getscriptbytecode) == "function" then
                return "-- (bytecode available, decompile not supported)"
            end
            return nil
        end)
        if ok and source then
            local lineNum = 0
            for line in source:gmatch("[^\r\n]+") do
                lineNum = lineNum + 1
                if string.find(string.lower(line), string.lower(query)) then
                    table.insert(results, {
                        script = script:GetFullName(),
                        line = lineNum,
                        content = truncate(line, 120)
                    })
                    if #results >= 30 then return end
                end
            end
        end
    end

    for _, script in ipairs(game:GetDescendants()) do
        if script:IsA("LocalScript") or script:IsA("ModuleScript") then
            grepScript(script)
        end
    end

    clearOutput(scriptsOutput)
    if #results == 0 then
        addOutputLine(scriptsOutput, '<font color="#8c8ca5">No matches found. (decompile may not be available)</font>', Theme.TextMuted, 0)
    else
        addOutputLine(scriptsOutput, '<font color="#50c88c">Found ' .. #results .. ' match(es):</font>', Theme.Green, 0)
        for i, r in ipairs(results) do
            addOutputLine(scriptsOutput,
                '<font color="#a08cff">' .. r.script .. ':' .. r.line .. '</font>\n' ..
                '  <font color="#dcdceb">' .. r.content .. '</font>',
                Theme.Text, i)
        end
    end
end)

-- ═══════════════════════════════════════════
-- PANEL: DATA PROBE
-- ═══════════════════════════════════════════
local probePanel = createPanel("dataprobe")
local probeHeader = createPanelHeader(probePanel, "Data Probe")

local probeExecBtn = createSmallButton(probeHeader, "▶ Run", Theme.Accent,
    UDim2.fromOffset(65, 24), UDim2.new(1, -80, 0.5, -12))

-- Editor area for probe
local probeEditorFrame = create("Frame", {
    Size = UDim2.new(1, -16, 0, 100),
    Position = UDim2.new(0, 8, 0, 42),
    BackgroundColor3 = Theme.Surface,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    Parent = probePanel
})
addCorner(probeEditorFrame, 6)
addStroke(probeEditorFrame, Theme.Border, 1)

local probeEditor = create("TextBox", {
    Size = UDim2.new(1, -8, 1, -4),
    Position = UDim2.new(0, 4, 0, 2),
    BackgroundTransparency = 1,
    Text = "-- Return a value to probe it\nreturn game.PlaceId",
    PlaceholderText = "-- Code that returns a value...",
    PlaceholderColor3 = Theme.TextMuted,
    FontFace = FONT_MONO,
    TextSize = 12,
    TextColor3 = Theme.Text,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    ClearTextOnFocus = false,
    MultiLine = true,
    TextWrapped = true,
    Parent = probeEditorFrame
})
addPadding(probeEditor, 6, 8, 6, 8)

local probeOutput = createScrollOutput(probePanel, 150)
addOutputLine(probeOutput, '<font color="#8c8ca5">Write code that returns values. Results will be displayed below.</font>', Theme.TextMuted, 0)

probeExecBtn.MouseButton1Click:Connect(function()
    local code = probeEditor.Text
    if code == "" then return end
    clearOutput(probeOutput)
    addOutputLine(probeOutput, '<font color="#50c8f0">[' .. formatTime() .. '] Running probe...</font>', Theme.Cyan, 0)
    local ok, result = pcall(function()
        local fn = loadstring(code)
        if fn then
            return fn()
        else
            error("Failed to compile")
        end
    end)
    if ok then
        local resultStr = tostring(result)
        if typeof(result) == "table" then
            local parts = {}
            for k, v in pairs(result) do
                table.insert(parts, "  " .. tostring(k) .. " = " .. tostring(v))
            end
            resultStr = "{\n" .. table.concat(parts, "\n") .. "\n}"
        end
        addOutputLine(probeOutput, '<font color="#50c88c">[' .. formatTime() .. '] Result:</font>', Theme.Green, 1)
        addOutputLine(probeOutput, '<font color="#dcdceb">' .. resultStr .. '</font>', Theme.Text, 2)
    else
        addOutputLine(probeOutput, '<font color="#f0505a">[' .. formatTime() .. '] Error: ' .. tostring(result) .. '</font>', Theme.Red, 1)
    end
end)

-- ═══════════════════════════════════════════
-- TAB SWITCHING
-- ═══════════════════════════════════════════
local function switchTab(id)
    if not panels[id] or not tabButtons[id] then return end
    if activeTab == id then return end
    -- Deactivate old
    local old = tabButtons[activeTab]
    if old then
        tween(old.button, TWEEN_FAST, {BackgroundTransparency = 1})
        tween(old.icon, TWEEN_FAST, {TextColor3 = Theme.TextDim})
        tween(old.label, TWEEN_FAST, {TextColor3 = Theme.TextDim})
        tween(old.bar, TWEEN_FAST, {Size = UDim2.new(0, 3, 0, 0)})
    end
    if panels[activeTab] then
        panels[activeTab].Visible = false
    end

    activeTab = id

    -- Activate new
    local new = tabButtons[id]
    if new then
        tween(new.button, TWEEN_FAST, {BackgroundTransparency = 0.85})
        tween(new.icon, TWEEN_FAST, {TextColor3 = Theme.AccentGlow})
        tween(new.label, TWEEN_FAST, {TextColor3 = Theme.Text})
        tween(new.bar, TWEEN_FAST, {Size = UDim2.new(0, 3, 0, 18)})
    end
    if panels[id] then
        panels[id].Visible = true
    end
end

-- Create sidebar buttons and wire them
for _, tabDef in ipairs(tabs) do
    local btn = createSidebarButton(tabDef)
    btn.MouseButton1Click:Connect(function()
        switchTab(tabDef.id)
    end)
end

-- Activate default tab
switchTab("executor")
-- Force visual state for initial tab
local initTab = tabButtons["executor"]
initTab.button.BackgroundTransparency = 0.85
initTab.icon.TextColor3 = Theme.AccentGlow
initTab.label.TextColor3 = Theme.Text
initTab.bar.Size = UDim2.new(0, 3, 0, 18)

-- ═══════════════════════════════════════════
-- POPULATE GAME INFO
-- ═══════════════════════════════════════════
task.spawn(function()
    local placeName = "Unknown"
    local infoOk, info = pcall(function()
        return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
    end)
    if infoOk and type(info) == "table" and type(info.Name) == "string" then
        placeName = info.Name
    end
    local userName = LocalPlayer and LocalPlayer.Name or "Unknown"
    gameInfoLabel.Text = "🎮 " .. truncate(placeName, 35) .. "  •  👤 " .. userName .. "  •  PlaceId: " .. tostring(game.PlaceId)
end)

-- ═══════════════════════════════════════════
-- TOGGLE KEYBIND (RightShift to show/hide)
-- ═══════════════════════════════════════════
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        mainFrame.Visible = not mainFrame.Visible
    end
end)

-- ═══════════════════════════════════════════
-- INTRO ANIMATION
-- ═══════════════════════════════════════════
mainFrame.BackgroundTransparency = 1
mainFrame.Size = UDim2.fromOffset(WIN_SIZE.X.Offset, 0)
task.wait(0.05)
tween(mainFrame, TWEEN_SLOW, {
    Size = WIN_SIZE,
    BackgroundTransparency = 0
})

print("[Cobalt v2] GUI loaded — press RightShift to toggle visibility")

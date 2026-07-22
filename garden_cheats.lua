--[[
    🌷 Bloom v3 — The Garden Frontier Exploit
    Built with Rayfield UI Library
    Full Auto-Farm · Grid Plant · Profit Tracker · ESP+ · Custom Theme
]]

-- ═══════════════════════════════════════════
-- CLEANUP (safe re-inject)
-- ═══════════════════════════════════════════
if getgenv and getgenv()._bloomCleanup then
    pcall(getgenv()._bloomCleanup)
end

-- Services
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local HttpService       = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local CoreGui           = game:GetService("CoreGui")
local UserInputService  = game:GetService("UserInputService")
local LocalPlayer       = Players.LocalPlayer or Players:GetPropertyChangedSignal('LocalPlayer'):Wait() or Players.LocalPlayer

-- Game modules
local Remotes    = ReplicatedStorage:WaitForChild("Remotes")
local DataClient = require(ReplicatedStorage.ClientServices.DataClient)

-- Key Remotes
local PlantSeedRF       = Remotes:WaitForChild("PlantSeed")
local RemovePlantRF     = Remotes:WaitForChild("RemovePlant")
local SellSeedRF        = Remotes:WaitForChild("SellSeed")
local BuySeedRF         = Remotes:WaitForChild("BuySeed")
local DigAllPlantsRE    = Remotes:WaitForChild("DigAllPlants")
local ChangeGardenRF    = Remotes:WaitForChild("ChangeGarden")
local BuyUpgradeRF      = Remotes:WaitForChild("BuyUpgrade")

-- ═══════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════
local function getHRP()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildWhichIsA("Humanoid")
end

local function getPC()
    local ls = LocalPlayer:FindFirstChild("leaderstats")
    return ls and ls:FindFirstChild("Plant Coins") and ls["Plant Coins"].Value or 0
end

local function formatNum(n)
    if n >= 1e9 then return string.format("%.2fB", n / 1e9)
    elseif n >= 1e6 then return string.format("%.2fM", n / 1e6)
    elseif n >= 1e3 then return string.format("%.1fK", n / 1e3)
    else return tostring(n) end
end

local function getPlayerData()
    local ok, data = pcall(function() return DataClient:Get() end)
    return ok and data or nil
end

local function getGardenFolder()
    local gardens = Workspace:FindFirstChild("Gardens")
    if gardens then return gardens:FindFirstChild(tostring(LocalPlayer.UserId)) end
    return nil
end

local function getPlantFolder()
    local root = getGardenFolder()
    return root and root:FindFirstChild("Garden")
end

local function getGardenCenter()
    local root = getGardenFolder()
    if root then
        local model = root:FindFirstChild("GardenModel")
        if model then
            local primary = model:FindFirstChildWhichIsA("BasePart")
            if primary then return primary.Position end
        end
    end
    return nil
end

local function isPlantGrown(plant)
    local growthServer = plant:GetAttribute("GrowthServerTime") or 0
    local growthAccum  = tonumber(plant:GetAttribute("GrowthAccumulatedTime")) or 0
    local growTime     = tonumber(plant:GetAttribute("GrowthGrowTimeSeconds")) or 40
    local speedMult    = tonumber(plant:GetAttribute("GrowSpeedMult")) or 1
    local now = Workspace:GetServerTimeNow()
    local elapsed = now - growthServer
    return (growthAccum + elapsed * speedMult) / growTime >= 1
end

local function getGrowthPercent(plant)
    local growthServer = plant:GetAttribute("GrowthServerTime") or 0
    local growthAccum  = tonumber(plant:GetAttribute("GrowthAccumulatedTime")) or 0
    local growTime     = tonumber(plant:GetAttribute("GrowthGrowTimeSeconds")) or 40
    local speedMult    = tonumber(plant:GetAttribute("GrowSpeedMult")) or 1
    local now = Workspace:GetServerTimeNow()
    local elapsed = now - growthServer
    return math.min(1, (growthAccum + elapsed * speedMult) / growTime)
end

local function gridPositions(center, count, spacing)
    local positions = {}
    local cols = math.ceil(math.sqrt(count))
    local totalW = (cols - 1) * spacing
    for i = 1, count do
        local row = math.floor((i - 1) / cols)
        local col = (i - 1) % cols
        local x = center.X + (col * spacing) - totalW / 2
        local z = center.Z + (row * spacing) - totalW / 2
        table.insert(positions, Vector3.new(x, center.Y, z))
    end
    return positions
end

local function getGardenCapacity()
    local ok, result = pcall(function()
        local data = getPlayerData()
        if not data then return 0 end
        local activeGarden = tostring(data.ActiveGarden or "1")
        local Master = require(ReplicatedStorage:FindFirstChild("Master"))
        -- Per-garden upgrades take priority over global
        local gardenData = data.Gardens and data.Gardens[activeGarden]
        local gardenSizeLevel = (gardenData and gardenData.Upgrades and tonumber(gardenData.Upgrades.GardenSize))
            or (data.Upgrades and data.Upgrades.GardenSize)
            or 1
        local maxPlants = Master.Config.Shop.ShopUpgrades.GardenSize[gardenSizeLevel].Amount
        local folder = getPlantFolder()
        local current = folder and #folder:GetChildren() or 0
        return maxPlants - current
    end)
    return ok and result or 0
end

-- ═══════════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════════
local sessionStartPC = getPC()
local harvestCount   = 0
local plantCount     = 0
local sellCount      = 0

local State = {
    -- Master
    autoFarm      = false,
    -- Individual
    autoHarvest   = false,
    autoPlant     = false,
    autoSell      = false,
    autoBuyShop   = false,
    autoRestock   = false,
    -- Settings
    minRarity     = 1,
    harvestDelay  = 0.3,
    plantDelay    = 0.3,
    gridSpacing   = 4,
    -- Movement
    speedHack     = false,
    noclip        = false,
    infJump       = false,
    antiAfk       = true,
    esp           = false,
    walkSpeed     = 48,
    jumpPower     = 50,
    gravity       = 196.2,
}
if getgenv then getgenv()._bloomState = State end

-- Connection tracking for cleanup
local _connections = {}
local function track(conn)
    table.insert(_connections, conn)
    return conn
end

-- ═══════════════════════════════════════════
-- CUSTOM THEME — Garden Teal
-- ═══════════════════════════════════════════
local GardenTheme = {
    TextColor = Color3.fromRGB(230, 245, 230),

    Background = Color3.fromRGB(15, 22, 18),
    Topbar = Color3.fromRGB(18, 28, 22),
    Shadow = Color3.fromRGB(10, 16, 12),

    NotificationBackground = Color3.fromRGB(18, 28, 22),
    NotificationActionsBackground = Color3.fromRGB(180, 230, 180),

    TabBackground = Color3.fromRGB(30, 50, 38),
    TabStroke = Color3.fromRGB(40, 65, 48),
    TabBackgroundSelected = Color3.fromRGB(60, 180, 120),
    TabTextColor = Color3.fromRGB(180, 210, 185),
    SelectedTabTextColor = Color3.fromRGB(10, 20, 12),

    ElementBackground = Color3.fromRGB(22, 34, 26),
    ElementBackgroundHover = Color3.fromRGB(28, 42, 32),
    SecondaryElementBackground = Color3.fromRGB(18, 28, 22),
    ElementStroke = Color3.fromRGB(35, 55, 40),
    SecondaryElementStroke = Color3.fromRGB(30, 45, 34),

    SliderBackground = Color3.fromRGB(30, 120, 70),
    SliderProgress = Color3.fromRGB(40, 160, 90),
    SliderStroke = Color3.fromRGB(50, 190, 105),

    ToggleBackground = Color3.fromRGB(20, 30, 24),
    ToggleEnabled = Color3.fromRGB(40, 180, 100),
    ToggleDisabled = Color3.fromRGB(60, 75, 65),
    ToggleEnabledStroke = Color3.fromRGB(50, 210, 120),
    ToggleDisabledStroke = Color3.fromRGB(75, 90, 78),
    ToggleEnabledOuterStroke = Color3.fromRGB(35, 55, 40),
    ToggleDisabledOuterStroke = Color3.fromRGB(30, 42, 34),

    DropdownSelected = Color3.fromRGB(28, 42, 32),
    DropdownUnselected = Color3.fromRGB(20, 30, 24),

    InputBackground = Color3.fromRGB(20, 30, 24),
    InputStroke = Color3.fromRGB(40, 60, 45),
    PlaceholderColor = Color3.fromRGB(120, 150, 125),
}

-- ═══════════════════════════════════════════
-- LOAD RAYFIELD
-- ═══════════════════════════════════════════
local function loadRayfield()
    local ok, source = pcall(game.HttpGet, game, 'https://sirius.menu/rayfield')
    assert(ok and type(source) == "string" and #source > 0, "Unable to download Rayfield")
    local chunk, compileError = loadstring(source)
    assert(chunk, "Rayfield compile failed: " .. tostring(compileError))
    return chunk()
end
local Rayfield = loadRayfield()

local Window = Rayfield:CreateWindow({
    Name = "🌷 Bloom v3",
    Icon = "sprout",
    LoadingTitle = "Bloom v3",
    LoadingSubtitle = "by Xaric — Garden Frontier",
    Theme = GardenTheme,
    ToggleUIKeybind = "K",
    DisableRayfieldPrompts = true,
    DisableBuildWarnings = true,
    ConfigurationSaving = {
        Enabled = true,
        FileName = "BloomV3_GardenFrontier"
    },
    KeySystem = false,
})

-- ═══════════════════════════════════════════
-- TAB 1: AUTO-FARM (the main tab)
-- ═══════════════════════════════════════════
local FarmTab = Window:CreateTab("Auto-Farm", "bot")

-- Live Stats: displayed via PlayerGui overlay (CoreGui writes blocked in executor threads)
FarmTab:CreateParagraph({
    Title = "📊 Live Stats",
    Content = "See floating overlay (top-left corner)"
})

-- Create PlayerGui overlay for live stats
local statsGui = Instance.new('ScreenGui')
statsGui.Name = 'BloomStatsOverlay'
statsGui.ResetOnSpawn = false
statsGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
statsGui.Parent = (LocalPlayer or game.Players.LocalPlayer):WaitForChild('PlayerGui')

local statsFrame = Instance.new('Frame', statsGui)
statsFrame.Name = 'StatsPanel'
statsFrame.Size = UDim2.new(0, 320, 0, 120)
statsFrame.Position = UDim2.new(0, 12, 0, 12)
statsFrame.BackgroundColor3 = Color3.fromRGB(18, 24, 20)
statsFrame.BackgroundTransparency = 0.15
statsFrame.BorderSizePixel = 0
local statsCorner = Instance.new('UICorner', statsFrame)
statsCorner.CornerRadius = UDim.new(0, 8)
local statsStroke = Instance.new('UIStroke', statsFrame)
statsStroke.Color = Color3.fromRGB(50, 90, 60)
statsStroke.Thickness = 1.5
statsStroke.Transparency = 0.3

local statsTitle = Instance.new('TextLabel', statsFrame)
statsTitle.Name = 'Title'
statsTitle.Size = UDim2.new(1, -16, 0, 22)
statsTitle.Position = UDim2.new(0, 8, 0, 6)
statsTitle.BackgroundTransparency = 1
statsTitle.Text = '🌷 Bloom v3'
statsTitle.TextColor3 = Color3.fromRGB(120, 210, 140)
statsTitle.TextSize = 14
statsTitle.Font = Enum.Font.GothamBold
statsTitle.TextXAlignment = Enum.TextXAlignment.Left

local statsLabel = Instance.new('TextLabel', statsFrame)
statsLabel.Name = 'Content'
statsLabel.Size = UDim2.new(1, -16, 1, -32)
statsLabel.Position = UDim2.new(0, 8, 0, 28)
statsLabel.BackgroundTransparency = 1
statsLabel.Text = 'Loading stats...'
statsLabel.TextColor3 = Color3.fromRGB(200, 230, 210)
statsLabel.TextSize = 13
statsLabel.Font = Enum.Font.Gotham
statsLabel.TextXAlignment = Enum.TextXAlignment.Left
statsLabel.TextYAlignment = Enum.TextYAlignment.Top
statsLabel.TextWrapped = true

FarmTab:CreateDivider()

FarmTab:CreateSection("Master Control")

FarmTab:CreateToggle({
    Name = "🔥 Full Auto-Farm",
    CurrentValue = false,
    Flag = "AutoFarm",
    Callback = function(Value)
        State.autoFarm = Value
        State.autoHarvest = Value
        State.autoPlant = Value
        State.autoSell = Value
        Rayfield:Notify({
            Title = Value and "Auto-Farm ON" or "Auto-Farm OFF",
            Content = Value and "Harvest + Plant + Sell all running" or "All automation stopped",
            Duration = 3,
            Image = "zap",
        })
    end,
})

FarmTab:CreateDivider()
FarmTab:CreateSection("Individual Toggles")

FarmTab:CreateToggle({
    Name = "Auto-Harvest",
    CurrentValue = false,
    Flag = "AutoHarvest",
    Callback = function(Value)
        State.autoHarvest = Value
    end,
})

FarmTab:CreateToggle({
    Name = "Auto-Plant",
    CurrentValue = false,
    Flag = "AutoPlant",
    Callback = function(Value)
        State.autoPlant = Value
    end,
})

FarmTab:CreateToggle({
    Name = "Auto-Sell Below Rarity",
    CurrentValue = false,
    Flag = "AutoSell",
    Callback = function(Value)
        State.autoSell = Value
    end,
})

FarmTab:CreateToggle({
    Name = "Auto-Buy Shop Seeds",
    CurrentValue = false,
    Flag = "AutoBuyShop",
    Callback = function(Value)
        State.autoBuyShop = Value
    end,
})

FarmTab:CreateToggle({
    Name = "Auto-Restock Shop",
    CurrentValue = false,
    Flag = "AutoRestock",
    Callback = function(Value)
        State.autoRestock = Value
    end,
})

FarmTab:CreateDivider()
FarmTab:CreateSection("Tuning")

FarmTab:CreateSlider({
    Name = "Min Rarity to Keep",
    Range = {1, 5},
    Increment = 1,
    Suffix = "★",
    CurrentValue = 1,
    Flag = "MinRarity",
    Callback = function(Value) State.minRarity = Value end,
})

FarmTab:CreateSlider({
    Name = "Harvest Speed",
    Range = {1, 10},
    Increment = 1,
    Suffix = "",
    CurrentValue = 3,
    Flag = "HarvestDelay",
    Callback = function(Value) State.harvestDelay = Value / 10 end,
})

FarmTab:CreateSlider({
    Name = "Grid Spacing (Plant)",
    Range = {2, 8},
    Increment = 1,
    Suffix = " studs",
    CurrentValue = 4,
    Flag = "GridSpacing",
    Callback = function(Value) State.gridSpacing = Value end,
})

-- ═══════════════════════════════════════════
-- TAB 2: QUICK ACTIONS
-- ═══════════════════════════════════════════
local ActionsTab = Window:CreateTab("Actions", "wand-sparkles")

ActionsTab:CreateSection("Garden")

ActionsTab:CreateButton({
    Name = "⛏ Dig ALL Plants",
    Callback = function()
        pcall(function() DigAllPlantsRE:FireServer() end)
        Rayfield:Notify({Title = "Bloom", Content = "Dug all plants!", Duration = 3, Image = "pickaxe"})
    end,
})

ActionsTab:CreateButton({
    Name = "🌱 Plant ALL Seeds (Grid)",
    Callback = function()
        local data = getPlayerData()
        if not data or not data.Seeds then
            Rayfield:Notify({Title = "Bloom", Content = "No seed data!", Duration = 3, Image = "alert-circle"})
            return
        end
        local activeGarden = data.ActiveGarden or 1
        local center = getGardenCenter() or Vector3.new(0, 3, 0)
        local seedList = {}
        for seedId, seedData in pairs(data.Seeds) do
            if not seedData.Locked then table.insert(seedList, seedId) end
        end
        local positions = gridPositions(center, #seedList, State.gridSpacing)
        local planted = 0
        for i, seedId in ipairs(seedList) do
            local pos = positions[i] or center
            local ok, result = pcall(function()
                return PlantSeedRF:InvokeServer(activeGarden, seedId, pos)
            end)
            if ok and result and result.Status == "Success" then planted = planted + 1 end
            task.wait(0.2)
        end
        Rayfield:Notify({Title = "Bloom", Content = "Grid-planted " .. planted .. " seeds!", Duration = 3, Image = "grid-3x3"})
    end,
})

ActionsTab:CreateButton({
    Name = "🌾 Harvest ALL Grown",
    Callback = function()
        local folder = getPlantFolder()
        if not folder then return end
        local data = getPlayerData()
        local activeGarden = data and data.ActiveGarden or 1
        local count = 0
        for _, plant in ipairs(folder:GetChildren()) do
            if isPlantGrown(plant) then
                pcall(function() RemovePlantRF:InvokeServer(activeGarden, plant.Name, true, 0) end)
                count = count + 1
                task.wait(0.15)
            end
        end
        Rayfield:Notify({Title = "Bloom", Content = "Harvested " .. count .. " plants!", Duration = 3, Image = "leaf"})
    end,
})

ActionsTab:CreateButton({
    Name = "💰 Sell ALL (Below Filter)",
    Callback = function()
        local data = getPlayerData()
        if not data or not data.Seeds then return end
        local activeGarden = data.ActiveGarden or 1
        local sold = 0
        for seedId, seedData in pairs(data.Seeds) do
            if seedData.Rarity and seedData.Rarity < State.minRarity and not seedData.Locked then
                pcall(function() SellSeedRF:InvokeServer(activeGarden, seedId, false) end)
                sold = sold + 1
                task.wait(0.1)
            end
        end
        Rayfield:Notify({Title = "Bloom", Content = "Sold " .. sold .. " seeds!", Duration = 3, Image = "coins"})
    end,
})

ActionsTab:CreateDivider()
ActionsTab:CreateSection("Shop")

ActionsTab:CreateButton({
    Name = "🛒 Buy ALL Shop Seeds",
    Callback = function()
        local data = getPlayerData()
        if not data or not data.ShopSeeds then
            Rayfield:Notify({Title = "Bloom", Content = "No shop data available", Duration = 3, Image = "alert-circle"})
            return
        end
        local activeGarden = data.ActiveGarden or 1
        local bought = 0
        for seedId, seed in pairs(data.ShopSeeds) do
            if type(seed) == "table" and not seed.Locked then
                local id = seed.SeedId or seedId
                pcall(function() BuySeedRF:InvokeServer(activeGarden, id) end)
                bought = bought + 1
            end
        end
        Rayfield:Notify({Title = "Bloom", Content = "Bought " .. bought .. " seeds!", Duration = 3, Image = "shopping-cart"})
    end,
})

ActionsTab:CreateButton({
    Name = "💎 Restock Shop",
    Callback = function()
        pcall(function() Remotes.BuyShopRestockWithPC:InvokeServer() end)
        Rayfield:Notify({Title = "Bloom", Content = "Shop restocked!", Duration = 3, Image = "refresh-cw"})
    end,
})

ActionsTab:CreateDivider()
ActionsTab:CreateSection("Keybinds")

ActionsTab:CreateKeybind({
    Name = "Quick Harvest All",
    CurrentKeybind = "H",
    HoldToInteract = false,
    Flag = "HarvestBind",
    Callback = function()
        local folder = getPlantFolder()
        if not folder then return end
        local data = getPlayerData()
        local activeGarden = data and data.ActiveGarden or 1
        for _, plant in ipairs(folder:GetChildren()) do
            if isPlantGrown(plant) then
                pcall(function() RemovePlantRF:InvokeServer(activeGarden, plant.Name, true, 0) end)
                task.wait(0.1)
            end
        end
    end,
})

ActionsTab:CreateKeybind({
    Name = "Quick Plant All",
    CurrentKeybind = "J",
    HoldToInteract = false,
    Flag = "PlantBind",
    Callback = function()
        local data = getPlayerData()
        if not data or not data.Seeds then return end
        local activeGarden = data.ActiveGarden or 1
        local center = getGardenCenter() or Vector3.new(0, 3, 0)
        local seedList = {}
        for seedId, sd in pairs(data.Seeds) do
            if not sd.Locked then table.insert(seedList, seedId) end
        end
        local positions = gridPositions(center, #seedList, State.gridSpacing)
        for i, seedId in ipairs(seedList) do
            pcall(function() PlantSeedRF:InvokeServer(activeGarden, seedId, positions[i] or center) end)
            task.wait(0.15)
        end
    end,
})

-- ═══════════════════════════════════════════
-- TAB 3: MOVEMENT & PLAYER
-- ═══════════════════════════════════════════
local MoveTab = Window:CreateTab("Player", "user")

MoveTab:CreateSection("Speed & Physics")

MoveTab:CreateToggle({
    Name = "Speed Hack",
    CurrentValue = false,
    Flag = "SpeedHack",
    Callback = function(Value)
        State.speedHack = Value
        if not Value then
            local hum = getHumanoid()
            if hum then hum.WalkSpeed = 48; hum.JumpPower = 50 end
            Workspace.Gravity = 196.2
        end
    end,
})

MoveTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 500},
    Increment = 2,
    Suffix = "",
    CurrentValue = 48,
    Flag = "WalkSpeed",
    Callback = function(Value) State.walkSpeed = Value end,
})

MoveTab:CreateSlider({
    Name = "Jump Power",
    Range = {50, 500},
    Increment = 5,
    Suffix = "",
    CurrentValue = 50,
    Flag = "JumpPower",
    Callback = function(Value) State.jumpPower = Value end,
})

MoveTab:CreateSlider({
    Name = "Gravity",
    Range = {0, 400},
    Increment = 10,
    Suffix = "",
    CurrentValue = 196,
    Flag = "Gravity",
    Callback = function(Value) State.gravity = Value end,
})

MoveTab:CreateDivider()
MoveTab:CreateSection("Toggles")

MoveTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Flag = "Noclip",
    Callback = function(Value) State.noclip = Value end,
})

MoveTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Flag = "InfJump",
    Callback = function(Value) State.infJump = Value end,
})

MoveTab:CreateToggle({
    Name = "Anti-AFK",
    CurrentValue = true,
    Flag = "AntiAfk",
    Callback = function(Value) State.antiAfk = Value end,
})

MoveTab:CreateDivider()
MoveTab:CreateSection("Visuals")

MoveTab:CreateToggle({
    Name = "ESP (Names + Distance)",
    CurrentValue = false,
    Flag = "ESP",
    Callback = function(Value) State.esp = Value end,
})

-- ═══════════════════════════════════════════
-- TAB 4: TELEPORT
-- ═══════════════════════════════════════════
local TPTab = Window:CreateTab("Teleport", "map-pin")

TPTab:CreateSection("Quick Teleport")

TPTab:CreateButton({
    Name = "🏡 My Garden",
    Callback = function()
        local hrp = getHRP()
        local center = getGardenCenter()
        if hrp and center then
            hrp.CFrame = CFrame.new(center + Vector3.new(0, 5, 0))
            Rayfield:Notify({Title = "Bloom", Content = "Teleported to garden!", Duration = 2, Image = "home"})
        end
    end,
})

TPTab:CreateButton({
    Name = "🎲 Random Garden",
    Callback = function()
        local hrp = getHRP()
        if not hrp then return end
        local gardens = Workspace:FindFirstChild("Gardens")
        if not gardens then return end
        local targets = {}
        for _, g in ipairs(gardens:GetChildren()) do
            if g.Name ~= tostring(LocalPlayer.UserId) then table.insert(targets, g) end
        end
        if #targets == 0 then return end
        local pick = targets[math.random(1, #targets)]
        local model = pick:FindFirstChild("GardenModel")
        if model then
            local part = model:FindFirstChildWhichIsA("BasePart")
            if part then
                hrp.CFrame = CFrame.new(part.Position + Vector3.new(0, 5, 0))
                local pName = "Unknown"
                pcall(function()
                    local p = Players:GetPlayerByUserId(tonumber(pick.Name))
                    if p then pName = p.Name end
                end)
                Rayfield:Notify({Title = "Bloom", Content = "TP → " .. pName, Duration = 3, Image = "compass"})
            end
        end
    end,
})

-- Dynamic player garden buttons
do
    local gardens = Workspace:FindFirstChild("Gardens")
    if gardens then
        TPTab:CreateDivider()
        TPTab:CreateSection("Player Gardens")
        for _, g in ipairs(gardens:GetChildren()) do
            if g.Name ~= tostring(LocalPlayer.UserId) then
                local pName = "ID:" .. g.Name
                pcall(function()
                    local p = Players:GetPlayerByUserId(tonumber(g.Name))
                    if p then pName = p.Name end
                end)
                TPTab:CreateButton({
                    Name = "→ " .. pName,
                    Callback = function()
                        local hrp = getHRP()
                        if not hrp then return end
                        local model = g:FindFirstChild("GardenModel")
                        if model then
                            local part = model:FindFirstChildWhichIsA("BasePart")
                            if part then hrp.CFrame = CFrame.new(part.Position + Vector3.new(0, 5, 0)) end
                        end
                    end,
                })
            end
        end
    end
end

-- ═══════════════════════════════════════════
-- TAB 5: INFO
-- ═══════════════════════════════════════════
local InfoTab = Window:CreateTab("Info", "info")

InfoTab:CreateParagraph({
    Title = "📈 Session Tracker",
    Content = "See floating overlay (top-left corner)"
})
InfoTab:CreateDivider()

InfoTab:CreateParagraph({
    Title = "🌷 Bloom v3",
    Content = "Garden Frontier Exploit\nBuilt with Rayfield UI Library\n\nKeybinds:\n  K — Toggle UI\n  H — Quick Harvest\n  J — Quick Plant\n\nby Xaric"
})

InfoTab:CreateButton({
    Name = "🗑 Destroy GUI",
    Callback = function()
        if getgenv()._bloomCleanup then
            getgenv()._bloomCleanup()
        end
    end,
})

-- ═══════════════════════════════════════════
-- BACKGROUND LOOPS
-- ═══════════════════════════════════════════

-- LIVE STATS UPDATER (writes to PlayerGui overlay — CoreGui writes blocked in executor threads)
do
    local lastStatsTick = 0
    track(RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - lastStatsTick < 4 then return end
        lastStatsTick = now

        pcall(function()
            local pc = getPC()
            local folder = getPlantFolder()
            local total = folder and #folder:GetChildren() or 0
            local grown = 0
            local avgGrowth = 0
            if folder then
                for _, plant in ipairs(folder:GetChildren()) do
                    local pct = getGrowthPercent(plant)
                    if pct >= 1 then grown = grown + 1 end
                    avgGrowth = avgGrowth + pct
                end
                if total > 0 then avgGrowth = avgGrowth / total end
            end
            local data = getPlayerData()
            local activeGarden = tostring(data and data.ActiveGarden or "1")

            -- Count plantable seeds from actual inventory
            local seedCount = 0
            if data and data.Gardens and data.Gardens[activeGarden] then
                local inv = data.Gardens[activeGarden].Inventory
                if inv then
                    for _, info in pairs(inv) do
                        local amt = tonumber(info.Amount) or 0
                        if amt > 0 then seedCount = seedCount + amt end
                    end
                end
            end

            -- Garden money and capacity
            local gardenMoney = 0
            local maxSlots = 0
            if data and data.Gardens and data.Gardens[activeGarden] then
                gardenMoney = data.Gardens[activeGarden].Money or 0
                pcall(function()
                    local Master = require(ReplicatedStorage:FindFirstChild("Master"))
                    local gsLevel = tonumber(data.Gardens[activeGarden].Upgrades and data.Gardens[activeGarden].Upgrades.GardenSize) or 1
                    maxSlots = Master.Config.Shop.ShopUpgrades.GardenSize[gsLevel].Amount
                end)
            end
            local profit = pc - sessionStartPC

            statsLabel.Text = string.format(
                "💰 PC: %s  (Garden: %s)\n🌱 Plants: %d/%d  (%d grown, %d%% avg)\n🌾 Seeds: %d available\n📈 Session: +%s PC\n\n⛏ Harvested: %d | 🌱 Planted: %d | 💸 Sold: %d",
                formatNum(pc), formatNum(gardenMoney),
                total, maxSlots, grown, math.floor(avgGrowth * 100),
                seedCount, formatNum(profit),
                harvestCount, plantCount, sellCount
            )
        end)
    end))
end

-- AUTO-HARVEST (Heartbeat, every 2s)
do
    local lastTick = 0
    track(RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - lastTick < 2 then return end
        lastTick = now
        if not State.autoHarvest then return end
        pcall(function()
            local folder = getPlantFolder()
            if not folder then return end
            local data = getPlayerData()
            local activeGarden = data and data.ActiveGarden or 1
            for _, plant in ipairs(folder:GetChildren()) do
                if not State.autoHarvest then break end
                if isPlantGrown(plant) then
                    pcall(function() RemovePlantRF:InvokeServer(activeGarden, plant.Name, true, 0) end)
                    harvestCount = harvestCount + 1
                end
            end
        end)
    end))
end

-- AUTO-PLANT (Heartbeat, every 2s — one seed per cycle)
do
    local lastTick = 0
    track(RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - lastTick < 2 then return end
        lastTick = now
        if not State.autoPlant then return end
        pcall(function()
            local slotsAvailable = getGardenCapacity()
            if slotsAvailable <= 0 then return end

            local data = getPlayerData()
            if not data then return end
            local activeGarden = data.ActiveGarden or "1"

            -- Read from the ACTUAL inventory (Gardens[activeGarden].Inventory)
            local gardenData = data.Gardens and data.Gardens[tostring(activeGarden)]
            local inventory = gardenData and gardenData.Inventory
            if not inventory then return end

            -- Find a seed with Amount > 0, prefer highest rarity
            local bestSeed = nil
            local bestRarity = -1
            for seedId, seedInfo in pairs(inventory) do
                local amount = tonumber(seedInfo.Amount) or 0
                if amount > 0 then
                    -- Get rarity from the Seeds catalog
                    local seedMeta = data.Seeds and data.Seeds[seedId]
                    local rarity = seedMeta and (tonumber(seedMeta.Rarity) or 1) or 1
                    if rarity > bestRarity then
                        bestRarity = rarity
                        bestSeed = seedId
                    end
                end
            end
            if not bestSeed then return end

            -- Pick a plant position (Y MUST be 0 — garden ground level)
            local plantX, plantZ
            local folder = getPlantFolder()
            if folder then
                local children = folder:GetChildren()
                if #children > 0 then
                    local ref = children[math.random(#children)]
                    local part = ref:FindFirstChildWhichIsA("BasePart")
                    if part then
                        local angle = math.random() * math.pi * 2
                        local dist = 2 + math.random() * 3
                        plantX = part.Position.X + math.cos(angle) * dist
                        plantZ = part.Position.Z + math.sin(angle) * dist
                    end
                end
            end
            if not plantX then
                local center = getGardenCenter()
                if center then
                    plantX = center.X + math.random(-10, 10)
                    plantZ = center.Z + math.random(-10, 10)
                else
                    plantX, plantZ = 192, -239
                end
            end
            local plantPos = Vector3.new(plantX, 0, plantZ)

            local ok, result = pcall(function()
                return PlantSeedRF:InvokeServer(activeGarden, bestSeed, plantPos)
            end)
            if ok and result and result.Status == "Success" then
                plantCount = plantCount + 1
            end
        end)
    end))
end

-- AUTO-SELL (Heartbeat, every 6s)
do
    local lastTick = 0
    track(RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - lastTick < 6 then return end
        lastTick = now
        if not State.autoSell then return end
        pcall(function()
            local data = getPlayerData()
            if not data or not data.Seeds then return end
            for seedId, seedData in pairs(data.Seeds) do
                if not State.autoSell then break end
                local rarity = seedData.Rarity or 1
                if rarity < State.minRarity and not seedData.Locked then
                    pcall(function() SellSeedRF:InvokeServer(data.ActiveGarden or 1, seedId, false) end)
                    sellCount = sellCount + 1
                end
            end
        end)
    end))
end

-- AUTO-BUY SHOP (Heartbeat, every 10s)
do
    local lastTick = 0
    track(RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - lastTick < 10 then return end
        lastTick = now
        if not State.autoBuyShop then return end
        pcall(function()
            local data = getPlayerData()
            if not data or not data.ShopSeeds then return end
            local activeGarden = data.ActiveGarden or 1
            for seedId, seed in pairs(data.ShopSeeds) do
                if not State.autoBuyShop then break end
                if type(seed) == "table" and not seed.Locked then
                    local rarity = tonumber(seed.Rarity) or 1
                    local price = tonumber(seed.Price) or 0
                    local id = seed.SeedId or seedId
                    if rarity >= State.minRarity and price <= getPC() then
                        pcall(function() BuySeedRF:InvokeServer(activeGarden, id) end)
                    end
                end
            end
        end)
    end))
end

-- AUTO-RESTOCK (Heartbeat, every 30s)
do
    local lastTick = 0
    track(RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - lastTick < 30 then return end
        lastTick = now
        if not State.autoRestock then return end
        pcall(function() Remotes.BuyShopRestockWithPC:InvokeServer() end)
    end))
end

-- SPEED HACK + GRAVITY (Heartbeat, every 0.2s)
do
    local lastTick = 0
    track(RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - lastTick < 0.2 then return end
        lastTick = now
        if not State.speedHack then return end
        pcall(function()
            local hum = getHumanoid()
            if hum then
                hum.WalkSpeed = State.walkSpeed
                hum.JumpPower = State.jumpPower
            end
            Workspace.Gravity = State.gravity
        end)
    end))
end

-- NOCLIP
track(RunService.Stepped:Connect(function()
    if State.noclip then
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end
end))

-- INFINITE JUMP
track(UserInputService.JumpRequest:Connect(function()
    if State.infJump then
        local hum = getHumanoid()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end))

-- ANTI-AFK (dual approach: VirtualUser + periodic character nudge)
pcall(function()
    local vu = game:GetService("VirtualUser")
    track(LocalPlayer.Idled:Connect(function()
        if State.antiAfk then
            vu:CaptureController()
            vu:ClickButton2(Vector2.new())
        end
    end))
end)
-- Backup: periodic jump nudge every 60s to prevent any AFK detection
do
    local lastAfkTick = 0
    track(RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - lastAfkTick < 60 then return end
        lastAfkTick = now
        if not State.antiAfk then return end
        pcall(function()
            local hum = getHumanoid()
            if hum and hum:GetState() ~= Enum.HumanoidStateType.Jumping then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end))
end

-- ESP (with distance)
task.spawn(function()
    local espFolder = Instance.new("Folder")
    espFolder.Name = "BloomESP"
    espFolder.Parent = CoreGui

    while task.wait(1.5) do
        if State.esp then
            espFolder:ClearAllChildren()
            local myHRP = getHRP()
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local hrp2 = player.Character:FindFirstChild("HumanoidRootPart")
                    if hrp2 then
                        local dist = myHRP and math.floor((myHRP.Position - hrp2.Position).Magnitude) or "?"

                        local bb = Instance.new("BillboardGui")
                        bb.Size = UDim2.fromOffset(160, 40)
                        bb.StudsOffset = Vector3.new(0, 4.5, 0)
                        bb.AlwaysOnTop = true
                        bb.Adornee = hrp2
                        bb.Parent = espFolder

                        local lbl = Instance.new("TextLabel")
                        lbl.Size = UDim2.new(1, 0, 1, 0)
                        lbl.BackgroundTransparency = 0.3
                        lbl.BackgroundColor3 = Color3.fromRGB(10, 20, 15)
                        lbl.TextColor3 = Color3.fromRGB(80, 220, 120)
                        lbl.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Bold)
                        lbl.TextSize = 13
                        lbl.Text = player.Name .. "  [" .. tostring(dist) .. "m]"
                        lbl.Parent = bb
                        Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 6)

                        local stroke = Instance.new("UIStroke")
                        stroke.Color = Color3.fromRGB(40, 180, 100)
                        stroke.Thickness = 1
                        stroke.Parent = lbl
                    end
                end
            end
        else
            espFolder:ClearAllChildren()
        end
    end
end)

-- ═══════════════════════════════════════════
-- CLEANUP FUNCTION (for re-inject)
-- ═══════════════════════════════════════════
if getgenv then
    getgenv()._bloomCleanup = function()
        -- Kill all connections
        for _, conn in ipairs(_connections) do
            pcall(function() conn:Disconnect() end)
        end
        -- Disable all state
        for k, v in pairs(State) do
            if typeof(v) == "boolean" then State[k] = false end
        end
        -- Destroy ESP
        local espF = CoreGui:FindFirstChild("BloomESP")
        if espF then espF:Destroy() end
        -- Destroy stats overlay
        pcall(function()
            local pg = LocalPlayer:FindFirstChild("PlayerGui")
            if pg then
                local overlay = pg:FindFirstChild("BloomStatsOverlay")
                if overlay then overlay:Destroy() end
            end
        end)
        -- Destroy Rayfield
        pcall(function() Rayfield:Destroy() end)
        local hui = gethui()
        if hui then
            for _, child in ipairs(hui:GetChildren()) do
                if child.Name == "Rayfield" then child:Destroy() end
            end
        end
    end
end

-- ═══════════════════════════════════════════
-- STARTUP NOTIFICATION
-- ═══════════════════════════════════════════
local pc = getPC()
local folder = getPlantFolder()
local pCount = folder and #folder:GetChildren() or 0
Rayfield:Notify({
    Title = "🌷 Bloom v3 Loaded",
    Content = string.format("PC: %s | Plants: %d | Press K to toggle", formatNum(pc), pCount),
    Duration = 5,
    Image = "check-circle",
})
print(string.format("[Bloom v3] PC: %s | Plants: %d | Loaded", formatNum(pc), pCount))

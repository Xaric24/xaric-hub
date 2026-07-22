local function loadRayfield()
    local ok, source = pcall(game.HttpGet, game, 'https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/5f83e2300acfd8e39d543eef09c7e55d45eda9a1/source.lua')
    assert(ok and type(source) == "string" and #source > 0, "Unable to download Rayfield")
    local chunk, compileError = loadstring(source)
    assert(chunk, "Rayfield compile failed: " .. tostring(compileError))
    return chunk()
end
local Rayfield = loadRayfield()

local Window = Rayfield:CreateWindow({
    Name = "🪓 Timber v1 | My Wood Farm",
    Icon = 0,
    LoadingTitle = "Timber v1",
    LoadingSubtitle = "by Xaric",
    Theme = "DarkBlue",
    DisableRayfieldPrompts = true,
    DisableBuildWarnings = true,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "TimberV1",
        FileName = "WoodFarmSave"
    }
})

-- Services & Setup
local RS = game:GetService("ReplicatedStorage")
local WS = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local LP = Players.LocalPlayer
local Env = getgenv()

if Env._timberCleanup then pcall(Env._timberCleanup) end
Env._timberSession = (Env._timberSession or 0) + 1
local SessionId = Env._timberSession

local State = {
    autoCollect = false,
    autoSell = false,
    autoSpin = false,
    minSpinTier = 1,
    autoEquip = false,
    autoUpgradeChipper = false,
    autoUpgradeStand = false,
    autoClaimMoney = false,
    autoBuyStump = false,
    stumpTier = 1,
    antiAFK = true,
    tpSpeed = 2 -- Delay between TPs to prevent glitching
}
Env._timberState = State

-- Connections
local connections = {}
local function track(conn) table.insert(connections, conn) return conn end
local function isAlive() return Env._timberSession == SessionId end
local function clean()
    if not isAlive() then return end
    Env._timberSession = Env._timberSession + 1
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    connections = {}
    if Env._timberState == State then Env._timberState = nil end
    pcall(function() Rayfield:Destroy() end)
end
Env._timberCleanup = clean

-- Utility: Find my plot
local function getMyPlot()
    local plots = WS:FindFirstChild("Map") and WS.Map:FindFirstChild("Plots")
    if not plots then return nil end
    for _, plot in ipairs(plots:GetChildren()) do
        if tostring(plot:GetAttribute("OwnerUserId")) == tostring(LP.UserId) then
            return plot
        end
    end
    return nil
end

local function firePrompt(prompt)
    if prompt and prompt:IsA("ProximityPrompt") then
        pcall(fireproximityprompt, prompt, prompt.HoldDuration or 0)
    end
end

local function getMoney()
    local stats = LP:FindFirstChild("leaderstats")
    local money = stats and stats:FindFirstChild("Money")
    return money and tonumber(money.Value) or nil
end

local function getBestAxeTier()
    return tonumber(LP:GetAttribute("TopRarity")) or 0
end

local skippedOffers = {}
local AxeTiers = {"WoodenAxe", "ChippedStoneAxe", "RustyIronAxe", "SteelAxe", "GoldenAxe", "ObsidianAxe", "CrystalAxe", "EmeraldAxe", "RubyAxe", "IcyAxe", "PoisonAxe", "NecromancerAxe", "DragonboneAxe", "ShadowAxe", "FuturisticAxe", "SteampunkAxe", "LavaAxe", "CandyAxe", "CosmicAxe", "GodlyAxe", "SerratedAxe", "RitualAxe", "ElvenAxe", "LichsAxe", "GalaxyAxe"}
local AxeNames = {ShadowAxe="Shadow", DragonboneAxe="Dragonbone", CandyAxe="Candy", SteampunkAxe="Steampunk", RitualAxe="Ritual", ChippedStoneAxe="Stone", IcyAxe="Icy", GodlyAxe="Godly", RustyIronAxe="Iron", NecromancerAxe="Necro", WoodenAxe="Wood", CosmicAxe="Cosmic", ObsidianAxe="Obsidian", SteelAxe="Steel", PoisonAxe="Poison", CrystalAxe="Crystal", ElvenAxe="Elven", SerratedAxe="Serrated", GoldenAxe="Gold", EmeraldAxe="Emerald", LavaAxe="Lava", GalaxyAxe="Galaxy", FuturisticAxe="Futuristic", RubyAxe="Ruby", LichsAxe="Lich's"}

local function getOfferTier(name)
    for tier, axeId in ipairs(AxeTiers) do
        local displayName = AxeNames[axeId]
        if displayName and name:find(displayName, 1, true) then return tier end
    end
    return 0
end

local function findBestUpgradeOffer(stands)
    local currentTier = getBestAxeTier()
    local best
    for _, stand in ipairs(stands:GetChildren()) do
        local anchor = stand:FindFirstChild("SpinAnchor")
        if anchor then
            for _, prompt in ipairs(anchor:GetDescendants()) do
                if prompt:IsA("ProximityPrompt") and prompt.Enabled and tostring(prompt.ActionText):find("Buy") then
                    local name = tostring(prompt.ObjectText)
                    local key = stand.Name .. "|" .. name
                    local tier = getOfferTier(name)
                    if (skippedOffers[key] or 0) <= os.clock()
                        and tier >= State.minSpinTier and tier > currentTier
                        and (not best or tier > best.tier) then
                        best = {prompt = prompt, anchor = anchor, key = key, tier = tier}
                    end
                end
            end
        end
    end
    return best
end

local function getAnchorCFrame(instance)
    if not instance then return nil end
    if instance:IsA("BasePart") then return instance.CFrame end
    if instance:IsA("Model") then return instance:GetPivot() end
    local part = instance:FindFirstChildWhichIsA("BasePart", true)
    return part and part.CFrame or nil
end

local function moveToAnchor(hrp, anchor, height)
    local cf = getAnchorCFrame(anchor)
    if not cf then return false end
    hrp.CFrame = cf + Vector3.new(0, height or 3, 0)
    return true
end

local function clickUpgradeButton(button)
    if not button or not button:IsA("TextButton") or not button.Visible then return false end
    return pcall(function()
        if firesignal then
            firesignal(button.Activated)
        else
            button:Activate()
        end
    end)
end

local function tryUpgradeStand(plot)
    local stand = plot and plot:FindFirstChild("UpgradeStand", true)
    local money = getMoney()
    if not stand or not money then return false end

    -- One purchase per pass keeps spending controlled and lets costs refresh.
    local upgrades = {
        {card = "MutationCard", cost = "MutationChanceCost", maxed = "MutationChanceMaxed"},
        {card = "LuckCard", cost = "LuckCost", maxed = "LuckMaxed"},
        {card = "StandCard", cost = "NextSpinStandCost", maxed = "SpinStandMaxed"},
    }
    for _, upgrade in ipairs(upgrades) do
        local cost = tonumber(stand:GetAttribute(upgrade.cost)) or math.huge
        if not stand:GetAttribute(upgrade.maxed) and money >= cost then
            local card = stand:FindFirstChild(upgrade.card, true)
            if clickUpgradeButton(card and card:FindFirstChild("BuyBtn")) then return true end
        end
    end
    return false
end

-- ═══════════════════════════════════════════
-- MAIN TAB
-- ═══════════════════════════════════════════
local MainTab = Window:CreateTab("🪵 Farming", 0)

MainTab:CreateToggle({
    Name = "Auto-Collect Wood",
    CurrentValue = false,
    Flag = "AutoCollect",
    Callback = function(v) State.autoCollect = v end,
})

MainTab:CreateToggle({
    Name = "Auto-Sell Wood",
    CurrentValue = false,
    Flag = "AutoSell",
    Callback = function(v) State.autoSell = v end,
})

MainTab:CreateToggle({
    Name = "Auto-Spin For Axes",
    CurrentValue = false,
    Flag = "AutoSpin",
    Callback = function(v) State.autoSpin = v end,
})

MainTab:CreateSlider({
    Name = "Min Axe Tier To Buy (1-25)",
    Range = {1, 25},
    Increment = 1,
    Suffix = "Tier",
    CurrentValue = 1,
    Flag = "MinSpinTier",
    Callback = function(Value)
        State.minSpinTier = Value
    end,
})

MainTab:CreateToggle({
    Name = "Auto-Equip Best Axe",
    CurrentValue = false,
    Flag = "AutoEquip",
    Callback = function(v) State.autoEquip = v end,
})

MainTab:CreateToggle({
    Name = "Auto-Upgrade Chipper",
    CurrentValue = false,
    Flag = "AutoUpgradeChipper",
    Callback = function(v) State.autoUpgradeChipper = v end,
})

MainTab:CreateToggle({
    Name = "Auto-Upgrade Rolls, Luck & Mutation",
    CurrentValue = false,
    Flag = "AutoUpgradeStand",
    Callback = function(v) State.autoUpgradeStand = v end,
})

MainTab:CreateToggle({
    Name = "Auto-Claim Money",
    CurrentValue = false,
    Flag = "AutoClaimMoney",
    Callback = function(v) State.autoClaimMoney = v end,
})

-- ═══════════════════════════════════════════
-- STUMPS TAB
-- ═══════════════════════════════════════════
local StumpsTab = Window:CreateTab("🪵 Stumps", 0)

StumpsTab:CreateToggle({
    Name = "Auto-Buy Stumps",
    CurrentValue = false,
    Flag = "AutoBuyStump",
    Callback = function(v) State.autoBuyStump = v end,
})

StumpsTab:CreateDropdown({
    Name = "Stump Tier to Buy",
    Options = {"1", "2", "3", "4", "5", "6", "7", "8"},
    CurrentOption = {"1"},
    Flag = "StumpTier",
    Callback = function(v) State.stumpTier = tonumber(v[1] or v) end,
})

-- ═══════════════════════════════════════════
-- UTILS TAB
-- ═══════════════════════════════════════════
local UtilsTab = Window:CreateTab("⚙️ Utils", 0)

UtilsTab:CreateButton({
    Name = "TP to My Plot",
    Callback = function()
        local plot = getMyPlot()
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if plot and hrp then
            moveToAnchor(hrp, plot:FindFirstChild("SpawnPoint"), 5)
        end
    end,
})

UtilsTab:CreateToggle({
    Name = "Anti-AFK",
    CurrentValue = State.antiAFK,
    Flag = "AntiAFK",
    Callback = function(v) State.antiAFK = v end,
})

UtilsTab:CreateButton({
    Name = "Upgrade Chipper 1x",
    Callback = function()
        pcall(function() RS.ChipperAction:FireServer("upgrade") end)
    end,
})

-- ═══════════════════════════════════════════
-- LOOPS
-- ═══════════════════════════════════════════

-- Auto Collect / Sell Loop (requires TP)
task.spawn(function()
    while task.wait(State.tpSpeed) do
        if not isAlive() then break end
        
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        local plot = getMyPlot()
        
        if hrp and plot then
            -- Collect
            if State.autoCollect then
                local holder = plot:FindFirstChild("WoodHolder", true)
                if holder and moveToAnchor(hrp, holder, 2) then
                    task.wait(0.3)
                    for _, d in ipairs(holder:GetDescendants()) do
                        if d:IsA("ProximityPrompt") then firePrompt(d) end
                    end
                end
            end
            
            -- Wait before next action
            if State.autoCollect and State.autoSell then task.wait(State.tpSpeed / 2) end
            
            -- Sell
            if State.autoSell then
                local seller = plot:FindFirstChild("SellAnchor", true)
                if seller and moveToAnchor(hrp, seller, 2) then
                    task.wait(0.3)
                    for _, d in ipairs(seller:GetDescendants()) do
                        if d:IsA("ProximityPrompt") then firePrompt(d) end
                    end
                end
            end
            
            -- Wait before next action
            if (State.autoCollect or State.autoSell) and (State.autoClaimMoney or State.autoSpin) then task.wait(State.tpSpeed / 2) end
            
            -- Claim Money
            if State.autoClaimMoney then
                local claimMoney = plot:FindFirstChild("ClaimMoney", true)
                if claimMoney then
                    local surface = claimMoney:FindFirstChild("Surface") or claimMoney:FindFirstChild("Part")
                    if surface and moveToAnchor(hrp, surface, 3) then
                        task.wait(0.2)
                        firetouchinterest(hrp, surface, 0)
                        task.wait(0.1)
                        firetouchinterest(hrp, surface, 1)
                    end
                end
            end
            
            -- Wait before next action
            if State.autoClaimMoney and State.autoSpin then task.wait(State.tpSpeed / 2) end
            
            
            -- Spin (requires TP to lever and stand)
            if State.autoSpin then
                -- Scan every rolled offer, then buy only the highest upgrade.
                local bought = false
                local stands = plot:FindFirstChild("Stands", true) or plot:FindFirstChild("Stand", true)
                if stands then
                    local offer = findBestUpgradeOffer(stands)
                    if offer and moveToAnchor(hrp, offer.anchor, 3) then
                        task.wait(0.3)
                        firePrompt(offer.prompt)
                        skippedOffers[offer.key] = os.clock() + 8
                        bought = true
                    end
                end
                
                -- If we didn't buy anything, pull the lever to spin again
                if not bought then
                    local lever = plot:FindFirstChild("LeverAnchor", true)
                    if lever and moveToAnchor(hrp, lever, 3) then
                        task.wait(0.3)
                        for _, d in ipairs(lever:GetDescendants()) do
                            if d:IsA("ProximityPrompt") then firePrompt(d) end
                        end
                    end
                end
            end
        end
    end
end)

-- Background Loops (no TP required)
track(LP.Idled:Connect(function()
    if not isAlive() or not State.antiAFK then return end
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end))

local lastAntiAFK = 0
local lastStumpBuy, lastEquip, lastChipperUpgrade, lastStandUpgrade = 0, 0, 0, 0
track(RunService.Heartbeat:Connect(function()
    if not isAlive() then return end
    local now = os.clock()
    if State.antiAFK and now - lastAntiAFK >= 55 then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
        lastAntiAFK = now
    end
    if State.autoBuyStump and now - lastStumpBuy >= 5 then
        pcall(function() RS.StumpShopBuy:FireServer(State.stumpTier) end)
        lastStumpBuy = now
    end
    if State.autoEquip and now - lastEquip >= 3 then
        pcall(function() RS.EquipBest:FireServer() end)
        lastEquip = now
    end
    if State.autoUpgradeChipper and now - lastChipperUpgrade >= 5 then
        pcall(function() RS.ChipperAction:FireServer("upgrade") end)
        lastChipperUpgrade = now
    end
    if State.autoUpgradeStand and now - lastStandUpgrade >= 5 then
        tryUpgradeStand(getMyPlot())
        lastStandUpgrade = now
    end
end))

Rayfield:LoadConfiguration()

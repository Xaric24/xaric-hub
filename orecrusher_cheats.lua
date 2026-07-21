--[[
    ╔═══════════════════════════════════════════════════════╗
    ║  CrushForge v1 — Build An Ore Crusher Exploit        ║
    ║  Xaric Hub Module                                    ║
    ╚═══════════════════════════════════════════════════════╝
]]

if getgenv()._crushforgeLoaded then return end
getgenv()._crushforgeLoaded = true

-- ═══════════════════════════════════════════
-- SERVICES
-- ═══════════════════════════════════════════
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local UserInputService  = game:GetService("UserInputService")

local LP = Players.LocalPlayer

-- ═══════════════════════════════════════════
-- REMOTE REFS
-- ═══════════════════════════════════════════
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 5)

local Swing             = Remotes and Remotes:FindFirstChild("Swing")
local SellOre           = Remotes and Remotes:FindFirstChild("SellOre")
local SellInventory     = Remotes and Remotes:FindFirstChild("SellInventory")
local Roll              = Remotes and Remotes:FindFirstChild("Roll")
local EquipBest         = Remotes and Remotes:FindFirstChild("EquipBest")
local EquipPickaxe      = Remotes and Remotes:FindFirstChild("EquipPickaxe")
local BuyPickaxe        = Remotes and Remotes:FindFirstChild("BuyPickaxe")
local DoUpgrade         = Remotes and Remotes:FindFirstChild("DoUpgrade")
local DoMaxUpgrade      = Remotes and Remotes:FindFirstChild("DoMaxUpgrade")
local MakeRebirth       = Remotes and Remotes:FindFirstChild("MakeRebirth")
local ClaimDaily        = Remotes and Remotes:FindFirstChild("ClaimDaily")
local ClaimGroupReward  = Remotes and Remotes:FindFirstChild("ClaimGroupReward")
local ClaimSessionReward = Remotes and Remotes:FindFirstChild("ClaimSessionReward")
local AutoRollRequest   = Remotes and Remotes:FindFirstChild("AutoRollRequest")
local BombPlot          = Remotes and Remotes:FindFirstChild("BombPlot")
local RedeemCode        = Remotes and Remotes:FindFirstChild("RedeemCode")

-- ═══════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════
local connections = {}
local function track(conn) table.insert(connections, conn) return conn end

local function getHRP()
    return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    return LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
end

local function getPlot()
    local pv = LP:FindFirstChild("Plot")
    return pv and pv.Value
end

local function getOres()
    local plot = getPlot()
    local folder = plot and plot:FindFirstChild("Ores")
    return folder and folder:GetChildren() or {}
end

local function equipPickaxe()
    local tool = LP.Backpack:FindFirstChildOfClass("Tool")
    if tool then
        local hum = getHumanoid()
        if hum then hum:EquipTool(tool) end
    end
end

-- Ore value lookup ($/Ore from drill billboard data)
local ORE_VALUES = {
    ["Golden Ruby"]       = 900000,
    ["Normal Ruby"]       = 450000,
    ["Golden Amethyst"]   = 48000,
    ["Normal Amethyst"]   = 24000,
    ["Golden Silver"]     = 10800,
    ["Normal Silver"]     = 5400,
    ["Golden Iron"]       = 6600,
    ["Normal Iron"]       = 3300,
    ["Golden Coal"]       = 1800,
    ["Normal Coal"]       = 900,
    ["Golden Sandstone"]  = 1080,
    ["Normal Sandstone"]  = 540,
    ["Golden Stone"]      = 600,
    ["Normal Stone"]      = 300,
}

local function getOreKey(ore)
    local mutation = ore:GetAttribute("Mutation") or "Normal"
    return mutation .. " " .. ore.Name
end

local function getOreValue(key)
    return ORE_VALUES[key] or 0
end

local function getDrillOreKey(drill)
    local billPart = drill:FindFirstChild("BillPart")
    if billPart then
        for _, t in ipairs(billPart:GetDescendants()) do
            if t:IsA("TextLabel") and t.Text:find("Mines:") then
                local oreName = t.Text:gsub("Mines: ", "")
                return oreName
            end
        end
    end
    return "Nothing"
end

local function getDrillPrompt(drill)
    for _, d in ipairs(drill:GetDescendants()) do
        if d:IsA("ProximityPrompt") and d.Name == "PutOre" then
            return d
        end
    end
    return nil
end

-- ═══════════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════════
local State = {
    autoMine        = false,
    mineDelay       = 0.03,
    autoSell        = false,
    autoRoll        = false,
    autoUpgrade     = false,
    autoEquipBest   = false,
    autoRebirth     = false,
    autoDrill       = false,
    autoCollect     = false,
    speedHack       = false,
    speedMult       = 2,
    infiniteJump    = false,
    noclip          = false,
    antiAFK         = true,
    esp             = false,
    fullbright      = false,
}
getgenv()._crushforgeState = State

-- ═══════════════════════════════════════════
-- UI LIBRARY
-- ═══════════════════════════════════════════
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name              = "⛏️ CrushForge v1",
    Icon              = 0,
    LoadingTitle      = "CrushForge v1",
    LoadingSubtitle   = "Build An Ore Crusher",
    Theme             = "DarkBlue",
    DisableRayfieldPrompts = true,
    DisableBuildWarnings   = true,
    ConfigurationSaving = {
        Enabled    = true,
        FolderName = "CrushForge",
        FileName   = "config",
    },
    KeySystem = false,
})

-- ═══════════════════════════════════════════
-- TAB: FARMING
-- ═══════════════════════════════════════════
local FarmTab = Window:CreateTab("⛏️ Farm", 0)

FarmTab:CreateSection("Mining")

FarmTab:CreateToggle({
    Name = "Auto-Mine Ores",
    CurrentValue = false,
    Flag = "AutoMine",
    Callback = function(v) State.autoMine = v end,
})

FarmTab:CreateSlider({
    Name = "Mine Speed (delay in ms)",
    Range = {10, 200},
    Increment = 10,
    Suffix = "ms",
    CurrentValue = 30,
    Flag = "MineDelay",
    Callback = function(v) State.mineDelay = v / 1000 end,
})

FarmTab:CreateToggle({
    Name = "Auto-Equip Best Pickaxe",
    CurrentValue = false,
    Flag = "AutoEquipBest",
    Callback = function(v) State.autoEquipBest = v end,
})

FarmTab:CreateSection("Collecting")

FarmTab:CreateToggle({
    Name = "Auto-Collect Cash",
    CurrentValue = false,
    Flag = "AutoCollect",
    Callback = function(v) State.autoCollect = v end,
})

FarmTab:CreateButton({
    Name = "Collect Cash Now",
    Callback = function()
        task.spawn(function()
            pcall(function()
                local plot = getPlot()
                if not plot then return end
                local button = plot:FindFirstChild("Button")
                if not button then return end
                local zone = button:FindFirstChild("Zone") or button:FindFirstChild("Touch")
                if not zone then return end
                local hrp = getHRP()
                if hrp then
                    hrp.CFrame = zone.CFrame
                    task.wait(0.5)
                end
            end)
        end)
    end,
})

FarmTab:CreateSection("Selling")

FarmTab:CreateToggle({
    Name = "Auto-Sell Ores",
    CurrentValue = false,
    Flag = "AutoSell",
    Callback = function(v) State.autoSell = v end,
})

FarmTab:CreateButton({
    Name = "Sell Ores Now",
    Callback = function()
        pcall(function() SellOre:FireServer() end)
        pcall(function() SellInventory:FireServer() end)
    end,
})

FarmTab:CreateSection("Drill Placement")

FarmTab:CreateToggle({
    Name = "Auto-Place Best Ores on Drills",
    CurrentValue = false,
    Flag = "AutoDrill",
    Callback = function(v) State.autoDrill = v end,
})

FarmTab:CreateButton({
    Name = "Place Best Ores Now",
    Callback = function()
        task.spawn(function()
            pcall(function()
                local plot = getPlot()
                if not plot then return end
                local drillsFolder = plot:FindFirstChild("Drills")
                local oresFolder = plot:FindFirstChild("Ores")
                if not drillsFolder or not oresFolder then return end

                -- Build sorted list of available ores by value (best first)
                local oreList = {}
                for _, ore in ipairs(oresFolder:GetChildren()) do
                    local key = getOreKey(ore)
                    table.insert(oreList, {ore = ore, key = key, value = getOreValue(key)})
                end
                if #oreList == 0 then return end
                table.sort(oreList, function(a, b) return a.value > b.value end)

                -- Build sorted list of drills by current value (worst first)
                local drillList = {}
                for _, drill in ipairs(drillsFolder:GetChildren()) do
                    local prompt = getDrillPrompt(drill)
                    if prompt then
                        local drillOreKey = getDrillOreKey(drill)
                        local drillVal = getOreValue(drillOreKey)
                        table.insert(drillList, {drill = drill, prompt = prompt, key = drillOreKey, value = drillVal})
                    end
                end
                table.sort(drillList, function(a, b) return a.value < b.value end)

                -- Place best ores on worst drills
                local oreIdx = 1
                for _, dEntry in ipairs(drillList) do
                    if oreIdx > #oreList then break end
                    local bestOre = oreList[oreIdx]
                    if bestOre.value > dEntry.value then
                        local hrp = getHRP()
                        if hrp and dEntry.prompt.Parent then
                            hrp.CFrame = dEntry.prompt.Parent.CFrame * CFrame.new(0, 0, 1)
                            task.wait(0.8)
                            fireproximityprompt(dEntry.prompt, dEntry.prompt.HoldDuration)
                            task.wait(1.5)
                        end
                        oreIdx = oreIdx + 1
                    else
                        break
                    end
                end
            end)
        end)
    end,
})

FarmTab:CreateSection("Rolling")

FarmTab:CreateToggle({
    Name = "Auto-Roll Ores",
    CurrentValue = false,
    Flag = "AutoRoll",
    Callback = function(v) State.autoRoll = v end,
})

FarmTab:CreateButton({
    Name = "Roll Once",
    Callback = function()
        pcall(function() Roll:FireServer() end)
    end,
})

FarmTab:CreateButton({
    Name = "Enable Server Auto-Roll",
    Callback = function()
        pcall(function() AutoRollRequest:FireServer() end)
    end,
})

-- ═══════════════════════════════════════════
-- TAB: UPGRADES
-- ═══════════════════════════════════════════
local UpgradeTab = Window:CreateTab("🔧 Upgrades", 0)

UpgradeTab:CreateSection("Auto-Upgrade")

UpgradeTab:CreateToggle({
    Name = "Auto-Upgrade All",
    CurrentValue = false,
    Flag = "AutoUpgrade",
    Callback = function(v) State.autoUpgrade = v end,
})

local UPGRADE_IDS = {
    {display = "Speed",            id = "speed"},
    {display = "Power",            id = "power"},
    {display = "Luck",             id = "luck"},
    {display = "Conveyor",         id = "conveyor"},
    {display = "Roll Speed",       id = "rollSpeed"},
    {display = "New Drill",        id = "drills"},
    {display = "2nd Floor Drill",  id = "drillsSecondFloor"},
    {display = "New Pads",         id = "pads"},
    {display = "2nd Floor",        id = "secondFloor"},
}

for _, upg in ipairs(UPGRADE_IDS) do
    UpgradeTab:CreateButton({
        Name = "Upgrade: " .. upg.display,
        Callback = function()
            pcall(function() DoUpgrade:FireServer(upg.id) end)
        end,
    })
end

UpgradeTab:CreateSection("Max Upgrades")

UpgradeTab:CreateButton({
    Name = "Max All Upgrades",
    Callback = function()
        task.spawn(function()
            for _ = 1, 20 do
                for _, upg in ipairs(UPGRADE_IDS) do
                    pcall(function() DoUpgrade:FireServer(upg.id) end)
                    pcall(function() DoMaxUpgrade:FireServer(upg.id) end)
                end
                task.wait(0.1)
            end
        end)
    end,
})

UpgradeTab:CreateSection("Pickaxe")

UpgradeTab:CreateButton({
    Name = "Buy Best Pickaxe",
    Callback = function()
        pcall(function() BuyPickaxe:FireServer() end)
    end,
})

UpgradeTab:CreateButton({
    Name = "Equip Best Pickaxe",
    Callback = function()
        pcall(function() EquipBest:FireServer() end)
        equipPickaxe()
    end,
})

UpgradeTab:CreateSection("Rebirth")

UpgradeTab:CreateToggle({
    Name = "Auto-Rebirth",
    CurrentValue = false,
    Flag = "AutoRebirth",
    Callback = function(v) State.autoRebirth = v end,
})

UpgradeTab:CreateButton({
    Name = "Rebirth Now",
    Callback = function()
        pcall(function() MakeRebirth:FireServer() end)
    end,
})

-- ═══════════════════════════════════════════
-- TAB: PLAYER
-- ═══════════════════════════════════════════
local PlayerTab = Window:CreateTab("🏃 Player", 0)

PlayerTab:CreateSection("Movement")

PlayerTab:CreateToggle({
    Name = "Speed Hack",
    CurrentValue = false,
    Flag = "SpeedHack",
    Callback = function(v) State.speedHack = v end,
})

PlayerTab:CreateSlider({
    Name = "Walk Speed Multiplier",
    Range = {1, 10},
    Increment = 0.5,
    CurrentValue = 2,
    Flag = "SpeedMult",
    Callback = function(v) State.speedMult = v end,
})

PlayerTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Flag = "InfJump",
    Callback = function(v) State.infiniteJump = v end,
})

PlayerTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Flag = "Noclip",
    Callback = function(v) State.noclip = v end,
})

-- ═══════════════════════════════════════════
-- TAB: VISUALS
-- ═══════════════════════════════════════════
local VisTab = Window:CreateTab("👁️ Visuals", 0)

VisTab:CreateSection("World")

VisTab:CreateToggle({
    Name = "Fullbright",
    CurrentValue = false,
    Flag = "Fullbright",
    Callback = function(v)
        State.fullbright = v
        pcall(function()
            local lighting = game:GetService("Lighting")
            if v then
                lighting.Brightness = 3
                lighting.ClockTime = 12
                lighting.FogEnd = 100000
                lighting.GlobalShadows = false
                for _, eff in ipairs(lighting:GetChildren()) do
                    if eff:IsA("PostEffect") then eff.Enabled = false end
                end
            else
                lighting.Brightness = 1
                lighting.GlobalShadows = true
                for _, eff in ipairs(lighting:GetChildren()) do
                    if eff:IsA("PostEffect") then eff.Enabled = true end
                end
            end
        end)
    end,
})

VisTab:CreateSection("ESP")

VisTab:CreateToggle({
    Name = "Player ESP",
    CurrentValue = false,
    Flag = "ESP",
    Callback = function(v) State.esp = v end,
})

-- ═══════════════════════════════════════════
-- TAB: MISC
-- ═══════════════════════════════════════════
local MiscTab = Window:CreateTab("⚙️ Misc", 0)

MiscTab:CreateSection("Claims")

MiscTab:CreateButton({
    Name = "Claim Daily Reward",
    Callback = function()
        pcall(function() ClaimDaily:FireServer() end)
    end,
})

MiscTab:CreateButton({
    Name = "Claim Group Reward",
    Callback = function()
        pcall(function() ClaimGroupReward:FireServer() end)
    end,
})

MiscTab:CreateButton({
    Name = "Claim Session Reward",
    Callback = function()
        pcall(function() ClaimSessionReward:FireServer() end)
    end,
})

MiscTab:CreateSection("Plot")

MiscTab:CreateButton({
    Name = "Bomb Plot (clear crusher)",
    Callback = function()
        pcall(function() BombPlot:FireServer() end)
    end,
})

MiscTab:CreateSection("Anti-AFK")

MiscTab:CreateToggle({
    Name = "Anti-AFK",
    CurrentValue = true,
    Flag = "AntiAFK",
    Callback = function(v) State.antiAFK = v end,
})

MiscTab:CreateSection("Destruction")

MiscTab:CreateButton({
    Name = "Destroy All Connections (Panic)",
    Callback = function()
        for _, conn in ipairs(connections) do
            pcall(function() conn:Disconnect() end)
        end
        connections = {}
        getgenv()._crushforgeLoaded = nil
        pcall(function() Rayfield:Destroy() end)
    end,
})

-- ═══════════════════════════════════════════
-- BACKGROUND LOOPS
-- ═══════════════════════════════════════════

-- AUTO-MINE
do
    local mining = false
    track(RunService.Heartbeat:Connect(function()
        if not State.autoMine or mining then return end
        mining = true
        task.spawn(function()
            pcall(function()
                -- Make sure pickaxe is equipped
                local tool = LP.Character and LP.Character:FindFirstChildOfClass("Tool")
                if not tool then equipPickaxe() task.wait(0.2) end

                local ores = getOres()
                if #ores == 0 then mining = false return end

                -- TP near the first ore so server accepts swings
                local firstOre = ores[1]
                if firstOre:IsA("BasePart") then
                    local hrp = getHRP()
                    if hrp then
                        local oreCF = firstOre.CFrame
                        hrp.CFrame = oreCF * CFrame.new(0, 2, 3)
                    end
                end

                for _, ore in ipairs(ores) do
                    if not State.autoMine then break end
                    if ore.Parent then
                        Swing:FireServer(ore)
                        task.wait(State.mineDelay)
                    end
                end
            end)
            mining = false
        end)
    end))
end

-- AUTO-SELL
do
    local lastSell = 0
    track(RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - lastSell < 3 then return end
        lastSell = now
        if not State.autoSell then return end
        pcall(function() SellOre:FireServer() end)
        pcall(function() SellInventory:FireServer() end)
    end))
end

-- AUTO-ROLL
do
    local lastRoll = 0
    track(RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - lastRoll < 1 then return end
        lastRoll = now
        if not State.autoRoll then return end
        pcall(function() Roll:FireServer() end)
    end))
end

-- AUTO-UPGRADE
do
    local lastUpgrade = 0
    track(RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - lastUpgrade < 2 then return end
        lastUpgrade = now
        if not State.autoUpgrade then return end
        task.spawn(function()
            for _, upg in ipairs(UPGRADE_IDS) do
                pcall(function() DoUpgrade:FireServer(upg.id) end)
                pcall(function() DoMaxUpgrade:FireServer(upg.id) end)
                task.wait(0.05)
            end
        end)
    end))
end

-- AUTO-COLLECT
do
    local lastCollect = 0
    track(RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - lastCollect < 5 then return end
        lastCollect = now
        if not State.autoCollect then return end
        task.spawn(function()
            pcall(function()
                local plot = getPlot()
                if not plot then return end
                local button = plot:FindFirstChild("Button")
                if not button then return end
                local zone = button:FindFirstChild("Zone") or button:FindFirstChild("Touch")
                if not zone then return end
                local hrp = getHRP()
                if hrp then
                    hrp.CFrame = zone.CFrame
                end
            end)
        end)
    end))
end

-- AUTO-DRILL (smart ore placement)
do
    local lastDrill = 0
    track(RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - lastDrill < 10 then return end
        lastDrill = now
        if not State.autoDrill then return end
        task.spawn(function()
            pcall(function()
                local plot = getPlot()
                if not plot then return end
                local drillsFolder = plot:FindFirstChild("Drills")
                local oresFolder = plot:FindFirstChild("Ores")
                if not drillsFolder or not oresFolder then return end

                -- Build sorted ore list (best first)
                local oreList = {}
                for _, ore in ipairs(oresFolder:GetChildren()) do
                    local key = getOreKey(ore)
                    table.insert(oreList, {ore = ore, key = key, value = getOreValue(key)})
                end
                if #oreList == 0 then return end
                table.sort(oreList, function(a, b) return a.value > b.value end)

                -- Build sorted drill list (worst first)
                local drillList = {}
                for _, drill in ipairs(drillsFolder:GetChildren()) do
                    local prompt = getDrillPrompt(drill)
                    if prompt then
                        local drillOreKey = getDrillOreKey(drill)
                        local drillVal = getOreValue(drillOreKey)
                        table.insert(drillList, {drill = drill, prompt = prompt, key = drillOreKey, value = drillVal})
                    end
                end
                table.sort(drillList, function(a, b) return a.value < b.value end)

                local oreIdx = 1
                for _, dEntry in ipairs(drillList) do
                    if oreIdx > #oreList then break end
                    local bestOre = oreList[oreIdx]
                    if bestOre.value > dEntry.value then
                        local hrp = getHRP()
                        if hrp and dEntry.prompt.Parent then
                            hrp.CFrame = dEntry.prompt.Parent.CFrame * CFrame.new(0, 0, 1)
                            task.wait(0.8)
                            fireproximityprompt(dEntry.prompt, dEntry.prompt.HoldDuration)
                            task.wait(1.5)
                        end
                        oreIdx = oreIdx + 1
                    else
                        break
                    end
                end
            end)
        end)
    end))
end

-- AUTO-EQUIP BEST
do
    local lastEquip = 0
    track(RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - lastEquip < 10 then return end
        lastEquip = now
        if not State.autoEquipBest then return end
        pcall(function() EquipBest:FireServer() end)
        equipPickaxe()
    end))
end

-- AUTO-REBIRTH
do
    local lastRebirth = 0
    track(RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - lastRebirth < 5 then return end
        lastRebirth = now
        if not State.autoRebirth then return end
        pcall(function() MakeRebirth:FireServer() end)
    end))
end

-- SPEED HACK
track(RunService.Heartbeat:Connect(function()
    if not State.speedHack then return end
    pcall(function()
        local hum = getHumanoid()
        if hum then hum.WalkSpeed = 24 * State.speedMult end
    end)
end))

-- INFINITE JUMP
track(UserInputService.JumpRequest:Connect(function()
    if not State.infiniteJump then return end
    pcall(function()
        local hum = getHumanoid()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end)
end))

-- NOCLIP
track(RunService.Stepped:Connect(function()
    if not State.noclip then return end
    pcall(function()
        if LP.Character then
            for _, part in ipairs(LP.Character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end)
end))

-- ANTI-AFK
do
    local lastTick = 0
    track(RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - lastTick < 60 then return end
        lastTick = now
        if not State.antiAFK then return end
        pcall(function()
            local VU = game:GetService("VirtualUser")
            VU:CaptureController()
            VU:ClickButton2(Vector2.new())
        end)
    end))
end

-- PLAYER ESP
do
    local espFolder = Instance.new("Folder")
    espFolder.Name = "CrushForgeESP"
    espFolder.Parent = Workspace.CurrentCamera

    local function createESP(player)
        if player == LP then return end
        local highlight = Instance.new("Highlight")
        highlight.Name = "ESP_" .. player.Name
        highlight.FillColor = Color3.fromRGB(255, 165, 0)
        highlight.FillTransparency = 0.7
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.OutlineTransparency = 0.3
        highlight.Parent = espFolder

        local function attach()
            if player.Character then highlight.Adornee = player.Character end
        end
        attach()
        player.CharacterAdded:Connect(attach)

        local bb = Instance.new("BillboardGui")
        bb.Name = "ESP_BB_" .. player.Name
        bb.Size = UDim2.new(0, 120, 0, 30)
        bb.StudsOffset = Vector3.new(0, 3.5, 0)
        bb.AlwaysOnTop = true
        bb.Parent = espFolder

        local lbl = Instance.new("TextLabel", bb)
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        lbl.TextStrokeTransparency = 0.3
        lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        lbl.TextSize = 12
        lbl.Font = Enum.Font.GothamBold

        track(RunService.Heartbeat:Connect(function()
            highlight.Enabled = State.esp
            bb.Enabled = State.esp
            if State.esp and player.Character then
                local head = player.Character:FindFirstChild("Head")
                bb.Adornee = head
                local hrp = getHRP()
                if hrp and head then
                    local dist = math.floor((hrp.Position - head.Position).Magnitude)
                    lbl.Text = player.Name .. " [" .. dist .. "m]"
                else
                    lbl.Text = player.Name
                end
            end
        end))
    end

    for _, p in ipairs(Players:GetPlayers()) do createESP(p) end
    track(Players.PlayerAdded:Connect(createESP))
    track(Players.PlayerRemoving:Connect(function(player)
        local h = espFolder:FindFirstChild("ESP_" .. player.Name)
        if h then h:Destroy() end
        local b = espFolder:FindFirstChild("ESP_BB_" .. player.Name)
        if b then b:Destroy() end
    end))
end

-- ═══════════════════════════════════════════
-- STATS OVERLAY
-- ═══════════════════════════════════════════
do
    local overlay = Instance.new("ScreenGui")
    overlay.Name = "CrushForgeOverlay"
    overlay.ResetOnSpawn = false
    overlay.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local frame = Instance.new("Frame", overlay)
    frame.Name = "StatsFrame"
    frame.Size = UDim2.new(0, 200, 0, 80)
    frame.Position = UDim2.new(1, -10, 0, 10)
    frame.AnchorPoint = Vector2.new(1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(15, 12, 25)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1, 0, 0, 20)
    title.Position = UDim2.new(0, 0, 0, 2)
    title.BackgroundTransparency = 1
    title.Text = "⛏️ CrushForge"
    title.TextColor3 = Color3.fromRGB(255, 165, 0)
    title.TextSize = 14
    title.Font = Enum.Font.GothamBold

    local info = Instance.new("TextLabel", frame)
    info.Size = UDim2.new(1, -10, 1, -24)
    info.Position = UDim2.new(0, 5, 0, 22)
    info.BackgroundTransparency = 1
    info.TextColor3 = Color3.fromRGB(200, 200, 200)
    info.TextSize = 11
    info.Font = Enum.Font.Gotham
    info.TextXAlignment = Enum.TextXAlignment.Left
    info.TextYAlignment = Enum.TextYAlignment.Top

    pcall(function() overlay.Parent = gethui() end)
    if not overlay.Parent then overlay.Parent = LP.PlayerGui end

    track(RunService.Heartbeat:Connect(function()
        pcall(function()
            local money = LP:FindFirstChild("leaderstats")
            local moneyVal = money and money:FindFirstChild("Money")
            local oreCount = #getOres()
            local vip = LP:GetAttribute("VIP") and "✅" or "❌"
            local luck2x = LP:GetAttribute("2xLuck") and "✅" or "❌"

            info.Text = string.format(
                "💰 %s\n⛏️ Ores: %d\n👑 VIP: %s  🍀 2xLuck: %s",
                moneyVal and tostring(moneyVal.Value) or "?",
                oreCount,
                vip, luck2x
            )
        end)
    end))
end

-- ═══════════════════════════════════════════
-- NOTIFY
-- ═══════════════════════════════════════════
pcall(function()
    Rayfield:Notify({
        Title = "CrushForge v1 Loaded",
        Content = "Build An Ore Crusher exploit ready",
        Duration = 4,
    })
end)

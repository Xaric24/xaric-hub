--[[
    ██████╗ ███████╗ █████╗ ██████╗ ███████╗███████╗██████╗ 
    ██╔══██╗██╔════╝██╔══██╗██╔══██╗██╔════╝██╔════╝██╔══██╗
    ██████╔╝█████╗  ███████║██║  ██║███████╗█████╗  ██████╔╝
    ██╔══██╗██╔══╝  ██╔══██║██║  ██║╚════██║██╔══╝  ██║  ██║
    ██║  ██║███████╗██║  ██║██████╔╝███████║███████╗██║  ██║
    ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚══════╝╚═╝  ╚═╝
    Reseeder v1 — Be A Seed? Exploit Menu
]]

-- ═══════════════════════════════════════════
-- CLEANUP previous instance
-- ═══════════════════════════════════════════
if getgenv()._reseederCleanup then
    pcall(getgenv()._reseederCleanup)
end
for _, child in ipairs(gethui():GetChildren()) do
    if child.Name == "Rayfield" then child:Destroy() end
end
local PG = game.Players.LocalPlayer:FindFirstChild("PlayerGui")
if PG then
    local old = PG:FindFirstChild("ReseederOverlay")
    if old then old:Destroy() end
end

-- ═══════════════════════════════════════════
-- SERVICES
-- ═══════════════════════════════════════════
local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser     = game:GetService("VirtualUser")
local Workspace       = game:GetService("Workspace")
local TweenService    = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LP   = Players.LocalPlayer
local Networker = require(ReplicatedStorage.Packages.Networker)

-- ═══════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════
local connections = {}
local function track(conn)
    table.insert(connections, conn)
    return conn
end

local function getChar()
    return LP.Character or LP.CharacterAdded:Wait()
end

local function getHRP()
    local char = getChar()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local char = getChar()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function formatNum(n)
    n = tonumber(n) or 0
    if n >= 1e12 then return string.format("%.1fT", n / 1e12) end
    if n >= 1e9  then return string.format("%.1fB", n / 1e9) end
    if n >= 1e6  then return string.format("%.1fM", n / 1e6) end
    if n >= 1e3  then return string.format("%.1fK", n / 1e3) end
    return tostring(math.floor(n))
end

local function getCash()
    local ls = LP:FindFirstChild("leaderstats")
    if not ls or not ls:FindFirstChild("Cash") then return 0 end
    local raw = tostring(ls.Cash.Value)
    -- Strip invisible characters (zero-width spaces etc)
    raw = raw:gsub("[^%d%.%a]", "")
    local num, suffix = raw:match("([%d%.]+)(%a*)")
    num = tonumber(num) or 0
    suffix = suffix:upper()
    if suffix == "K" then num = num * 1e3
    elseif suffix == "M" then num = num * 1e6
    elseif suffix == "B" then num = num * 1e9
    elseif suffix == "T" then num = num * 1e12
    end
    return num
end

-- Zone positions lookup
local function getZonePositions()
    local zones = {}
    local zonesFolder = Workspace:FindFirstChild("Zones")
    if zonesFolder then
        for _, z in ipairs(zonesFolder:GetChildren()) do
            local num = tonumber(z.Name)
            if num then
                zones[num] = z.Position
            end
        end
    end
    return zones
end

-- Find the player's base by OwnerId attribute
local function getMyBase()
    local basesFolder = Workspace:FindFirstChild("Bases")
    if not basesFolder then return nil end
    local uid = tostring(LP.UserId)
    for _, base in ipairs(basesFolder:GetChildren()) do
        if tostring(base:GetAttribute("OwnerId")) == uid then
            return base
        end
    end
    return nil
end

-- Get collect parts on player's base only
local function getCollectParts()
    local parts = {}
    local base = getMyBase()
    if not base then return parts end
    for _, desc in ipairs(base:GetDescendants()) do
        if desc.Name == "Collect" and desc:IsA("BasePart") then
            local banked = desc:GetAttribute("Banked") or 0
            table.insert(parts, {part = desc, banked = tonumber(banked) or 0, base = base.Name})
        end
    end
    return parts
end

-- Get plants on player's base only
local function getMyPlants()
    local plants = {}
    local base = getMyBase()
    if not base then return plants end
    for _, desc in ipairs(base:GetDescendants()) do
        if desc.Name == "Planted" and desc:GetAttribute("DisplayPlantName") then
            table.insert(plants, {
                name = desc:GetAttribute("DisplayPlantName"),
                level = desc:GetAttribute("DisplayPlantLevel") or 0,
                cps = desc:GetAttribute("DisplayCashPerSecond") or 0,
                size = desc:GetAttribute("DisplayPlantSize") or "Normal",
                base = base.Name,
                key = desc:GetAttribute("PersistKey"),
            })
        end
    end
    return plants
end

-- ═══════════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════════
local sessionStartCash = getCash()

local State = {
    speedHack    = false,
    speedMult    = 2,
    autoCollect  = false,
    autoRun      = false,
    infiniteJump = false,
    antiAFK      = true,
    noclip       = false,
}
getgenv()._reseederState = State

-- ═══════════════════════════════════════════
-- GAMEPASS SPOOFING (AutoRun + AutoCollect)
-- ═══════════════════════════════════════════
pcall(function()
    local dataClient = require(ReplicatedStorage.Packages.DataService).client
    -- Spoof gamepass flags in local data cache
    dataClient:set({"Gamepasses", "AutoRun"}, true)
    dataClient:set({"Gamepasses", "AutoCollect"}, true)

    -- Re-init AutoRunServiceClient so it picks up the spoofed flag
    local ARSC = require(ReplicatedStorage.Shared.Services.AutoRunService.AutoRunServiceClient)
    ARSC._inited = false
    pcall(function() ARSC.init() end)
    task.wait(0.2)
    pcall(function() ARSC.setEnabled(true) end)

    -- Enable AutoCollect setting
    local settingsNet = Networker.client.new("SettingsService")
    pcall(function() settingsNet:fire("updateSetting", "AutoCollectEnabled", true) end)

    -- Also set it on the local SettingsServiceClient
    pcall(function()
        local SSC = require(ReplicatedStorage.Shared.Services.SettingsService.SettingsServiceClient)
        SSC:updateSetting("AutoCollectEnabled", true)
    end)
end)
-- ═══════════════════════════════════════════
-- UI LIBRARY (Rayfield)
-- ═══════════════════════════════════════════
local function loadRayfield()
    local ok, source = pcall(game.HttpGet, game, "https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/5f83e2300acfd8e39d543eef09c7e55d45eda9a1/source.lua")
    assert(ok and type(source) == "string" and #source > 0, "Unable to download Rayfield")
    local chunk, compileError = loadstring(source)
    assert(chunk, "Rayfield compile failed: " .. tostring(compileError))
    return chunk()
end
local Rayfield = loadRayfield()

local Window = Rayfield:CreateWindow({
    Name             = "🌱 Reseeder v1",
    Icon             = 0,
    LoadingTitle     = "Reseeder v1",
    LoadingSubtitle  = "Be A Seed? Exploit Menu",
    Theme            = "Ocean",
    DisableRayfieldPrompts = true,
    DisableBuildWarnings   = true,
    ConfigurationSaving    = { Enabled = false },
    KeySystem              = false,
})

-- ═══════════════════════════════════════════
-- TAB: PLAYER
-- ═══════════════════════════════════════════
local PlayerTab = Window:CreateTab("🏃 Player", 0)

PlayerTab:CreateSection("Movement")

PlayerTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 500},
    Increment = 1,
    Suffix = "studs/s",
    CurrentValue = 36,
    Callback = function(val)
        pcall(function()
            local hum = getHumanoid()
            if hum then hum.WalkSpeed = val end
        end)
    end,
})

PlayerTab:CreateSlider({
    Name = "Jump Power",
    Range = {50, 500},
    Increment = 5,
    Suffix = "power",
    CurrentValue = 50,
    Callback = function(val)
        pcall(function()
            local hum = getHumanoid()
            if hum then hum.JumpPower = val end
        end)
    end,
})

PlayerTab:CreateToggle({
    Name = "Speed Hack (Run Boost)",
    CurrentValue = false,
    Callback = function(val)
        State.speedHack = val
    end,
})

PlayerTab:CreateSlider({
    Name = "Speed Multiplier",
    Range = {1, 10},
    Increment = 0.5,
    Suffix = "x",
    CurrentValue = 2,
    Callback = function(val)
        State.speedMult = val
    end,
})

PlayerTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Callback = function(val)
        State.infiniteJump = val
    end,
})

PlayerTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Callback = function(val)
        State.noclip = val
    end,
})

PlayerTab:CreateSection("Anti-AFK")

PlayerTab:CreateToggle({
    Name = "Anti-AFK (Auto)",
    CurrentValue = true,
    Callback = function(val)
        State.antiAFK = val
    end,
})

-- ═══════════════════════════════════════════
-- TAB: FARMING
-- ═══════════════════════════════════════════
local FarmTab = Window:CreateTab("🌾 Farming", 0)

FarmTab:CreateSection("Auto-Collect")

FarmTab:CreateToggle({
    Name = "Auto-Collect Cash",
    CurrentValue = false,
    Callback = function(val)
        State.autoCollect = val
    end,
})

FarmTab:CreateSection("Auto-Run")

FarmTab:CreateToggle({
    Name = "Auto-Run (Start Runs)",
    CurrentValue = false,
    Callback = function(val)
        State.autoRun = val
    end,
})

FarmTab:CreateSection("Quick Actions")

FarmTab:CreateButton({
    Name = "Collect All Cash Now",
    Callback = function()
        pcall(function()
            local parts = getCollectParts()
            local hrp = getHRP()
            if not hrp then return end
            local origCFrame = hrp.CFrame
            for _, info in ipairs(parts) do
                if info.banked > 0 then
                    hrp.CFrame = info.part.CFrame
                    task.wait(0.15)
                    firetouchinterest(hrp, info.part, 0)
                    task.wait(0.1)
                    firetouchinterest(hrp, info.part, 1)
                end
            end
            task.wait(0.2)
            hrp.CFrame = origCFrame
        end)
    end,
})

-- ═══════════════════════════════════════════
-- TAB: TELEPORT
-- ═══════════════════════════════════════════
local TeleportTab = Window:CreateTab("🗺️ Teleport", 0)

TeleportTab:CreateSection("NPCs (Farmer Pickup)")

-- Helper: teleport to an NPC model, 3 studs in front
local function tpToNPC(folderName, npcName)
    pcall(function()
        local folder = Workspace:FindFirstChild(folderName)
        if not folder then return end
        local npc = folder:FindFirstChild(npcName) or folder:FindFirstChild("Farmer")
        if not npc then return end
        local hrp = getHRP()
        if not hrp then return end
        local pos
        if npc:IsA("Model") then
            pos = npc:GetPivot().Position
        elseif npc:IsA("BasePart") then
            pos = npc.Position
        end
        if pos then
            hrp.CFrame = CFrame.new(pos + Vector3.new(0, 0, 3))
        end
    end)
end

TeleportTab:CreateButton({
    Name = "🌾 Seed Shop Farmer",
    Callback = function() tpToNPC("Seed Shop", "Seed Shop Farmer") end,
})
TeleportTab:CreateButton({
    Name = "💰 Sell Farmer",
    Callback = function() tpToNPC("Sell", "Sell Farmer") end,
})
TeleportTab:CreateButton({
    Name = "⬆️ Upgrades Farmer",
    Callback = function() tpToNPC("Upgrades", "Farmer") end,
})
TeleportTab:CreateButton({
    Name = "💎 Robux Farmer",
    Callback = function() tpToNPC("Robux", "Robux Farmer") end,
})
pcall(function()
    if Workspace:FindFirstChild("Fruit Fuser") then
        TeleportTab:CreateButton({
            Name = "🍎 Fruit Fuser Farmer",
            Callback = function() tpToNPC("Fruit Fuser", "Fruit Fuser Farmer") end,
        })
    end
end)

TeleportTab:CreateSection("Zones")

-- Get zone list
local zonePositions = getZonePositions()
local sortedZones = {}
for num in pairs(zonePositions) do
    table.insert(sortedZones, num)
end
table.sort(sortedZones)

local zoneNames = {}
for _, num in ipairs(sortedZones) do
    table.insert(zoneNames, "Zone " .. num)
end

if #zoneNames > 0 then
    TeleportTab:CreateDropdown({
        Name = "Teleport to Zone",
        Options = zoneNames,
        CurrentOption = {zoneNames[1]},
        Callback = function(opt)
            pcall(function()
                local num = tonumber(opt[1]:match("%d+"))
                local pos = zonePositions[num]
                if pos then
                    local hrp = getHRP()
                    if hrp then hrp.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0)) end
                end
            end)
        end,
    })
end

TeleportTab:CreateSection("Bases")

-- Find bases
local basesFolder = Workspace:FindFirstChild("Bases")
if basesFolder then
    for _, base in ipairs(basesFolder:GetChildren()) do
        local spawn = base:FindFirstChild("Spawn")
        if spawn then
            TeleportTab:CreateButton({
                Name = "TP to " .. base.Name,
                Callback = function()
                    pcall(function()
                        local hrp = getHRP()
                        if hrp and spawn:IsA("BasePart") then
                            hrp.CFrame = spawn.CFrame + Vector3.new(0, 5, 0)
                        end
                    end)
                end,
            })
        end
    end
end

-- ═══════════════════════════════════════════
-- TAB: INFO
-- ═══════════════════════════════════════════
local InfoTab = Window:CreateTab("📊 Info", 0)

InfoTab:CreateSection("Session Stats")

pcall(function() InfoTab:CreateLabel("See floating overlay (top-left corner)") end)

InfoTab:CreateSection("My Plants")

local plants = getMyPlants()
if #plants > 0 then
    for _, p in ipairs(plants) do
        pcall(function()
            InfoTab:CreateLabel(string.format("%s (Lv%d) - %s/s [%s]", p.name, p.level, formatNum(p.cps), p.size))
        end)
    end
else
    pcall(function() InfoTab:CreateLabel("No plants found on your base.") end)
end

InfoTab:CreateSection("Player Info")

pcall(function() InfoTab:CreateLabel(string.format("Equipped Seed: %s", LP:GetAttribute("EquippedRunSeed") or "None")) end)
pcall(function() InfoTab:CreateLabel(string.format("Run Speed: %s", formatNum(LP:GetAttribute("RunSpeed") or 0))) end)
pcall(function() InfoTab:CreateLabel(string.format("VIP: %s", tostring(LP:GetAttribute("IsVIP") or false))) end)

-- ═══════════════════════════════════════════
-- STATS OVERLAY
-- ═══════════════════════════════════════════
local statsGui = Instance.new("ScreenGui")
statsGui.Name = "ReseederOverlay"
statsGui.ResetOnSpawn = false
statsGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local panel = Instance.new("Frame", statsGui)
panel.Name = "StatsPanel"
panel.Size = UDim2.new(0, 280, 0, 140)
panel.Position = UDim2.new(0, 10, 0, 10)
panel.BackgroundColor3 = Color3.fromRGB(15, 20, 30)
panel.BackgroundTransparency = 0.15
panel.BorderSizePixel = 0

local corner = Instance.new("UICorner", panel)
corner.CornerRadius = UDim.new(0, 10)

local stroke = Instance.new("UIStroke", panel)
stroke.Color = Color3.fromRGB(80, 200, 120)
stroke.Thickness = 1.5
stroke.Transparency = 0.3

local statsLabel = Instance.new("TextLabel", panel)
statsLabel.Name = "Content"
statsLabel.Size = UDim2.new(1, -16, 1, -12)
statsLabel.Position = UDim2.new(0, 8, 0, 6)
statsLabel.BackgroundTransparency = 1
statsLabel.Font = Enum.Font.RobotoMono
statsLabel.TextSize = 13
statsLabel.TextColor3 = Color3.fromRGB(200, 255, 200)
statsLabel.TextXAlignment = Enum.TextXAlignment.Left
statsLabel.TextYAlignment = Enum.TextYAlignment.Top
statsLabel.Text = "Loading..."
statsLabel.RichText = true

pcall(function() statsGui.Parent = LP:FindFirstChild("PlayerGui") end)
if not statsGui.Parent then
    pcall(function() statsGui.Parent = gethui() end)
end

-- Toggle visibility with K
track(UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.K then
        panel.Visible = not panel.Visible
    end
end))

-- ═══════════════════════════════════════════
-- BACKGROUND LOOPS
-- ═══════════════════════════════════════════

-- SPEED HACK (fixed multiplier, no compounding)
do
    local DEFAULT_SPEED = 36
    track(RunService.Heartbeat:Connect(function()
        if not State.speedHack then return end
        pcall(function()
            local hum = getHumanoid()
            if not hum then return end
            -- During runs, game accelerates WalkSpeed. We override it.
            -- Use the game's current speed OR default, whichever is higher
            local runActive = LP:GetAttribute("RunActive")
            if runActive then
                -- During run: set to a flat boosted speed
                local runMax = LP:GetAttribute("RunMaxSpeed") or 100
                hum.WalkSpeed = math.max(runMax, DEFAULT_SPEED) * State.speedMult
            else
                hum.WalkSpeed = DEFAULT_SPEED * State.speedMult
            end
        end)
    end))
end

-- NOCLIP (Stepped)
do
    track(RunService.Stepped:Connect(function()
        if not State.noclip then return end
        pcall(function()
            local char = getChar()
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    end))
end

-- INFINITE JUMP
do
    track(UserInputService.JumpRequest:Connect(function()
        if not State.infiniteJump then return end
        pcall(function()
            local hum = getHumanoid()
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    end))
end

-- AUTO-COLLECT (Heartbeat, every 3s)
do
    local lastTick = 0
    track(RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - lastTick < 3 then return end
        lastTick = now
        if not State.autoCollect then return end
        pcall(function()
            local parts = getCollectParts()
            local hrp = getHRP()
            if not hrp then return end
            local origCFrame = hrp.CFrame
            local moved = false
            for _, info in ipairs(parts) do
                if info.banked > 0 then
                    hrp.CFrame = info.part.CFrame
                    moved = true
                    task.wait(0.1)
                    firetouchinterest(hrp, info.part, 0)
                    task.wait(0.05)
                    firetouchinterest(hrp, info.part, 1)
                end
            end
            if moved then
                task.wait(0.15)
                hrp.CFrame = origCFrame
            end
        end)
    end))
end

-- AUTO-RUN (Heartbeat, every 5s — touch RunHitbox to start runs)
do
    local lastTick = 0
    track(RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - lastTick < 5 then return end
        lastTick = now
        if not State.autoRun then return end
        pcall(function()
            local runActive = LP:GetAttribute("RunActive")
            if runActive then return end
            local runHitbox = Workspace:FindFirstChild("RunHitbox")
            local hrp = getHRP()
            if not runHitbox or not hrp then return end
            local origCFrame = hrp.CFrame
            hrp.CFrame = CFrame.new(runHitbox.Position)
            task.wait(0.3)
            firetouchinterest(hrp, runHitbox, 0)
            task.wait(0.2)
            firetouchinterest(hrp, runHitbox, 1)
            task.wait(0.5)
            -- Only teleport back if run didn't start (stay in lane if it did)
            if not LP:GetAttribute("RunActive") then
                hrp.CFrame = origCFrame
            end
        end)
    end))
end

-- ANTI-AFK (Heartbeat, every 60s + VirtualUser)
do
    local lastTick = 0
    track(RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - lastTick < 60 then return end
        lastTick = now
        if not State.antiAFK then return end
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
            local hum = getHumanoid()
            if hum then hum.Jump = true end
        end)
    end))
end

-- LIVE STATS UPDATER (every 4s)
do
    local lastTick = 0
    track(RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - lastTick < 4 then return end
        lastTick = now
        pcall(function()
            local cash = getCash()
            local profit = cash - sessionStartCash
            local plants = getMyPlants()

            local totalCPS = 0
            for _, p in ipairs(plants) do
                totalCPS = totalCPS + (p.cps or 0)
            end

            local equippedSeed = LP:GetAttribute("EquippedRunSeed") or "None"
            local runActive = LP:GetAttribute("RunActive") or false
            local runSpeed = LP:GetAttribute("RunSpeed") or 0

            -- Count banked cash
            local totalBanked = 0
            local collectParts = getCollectParts()
            for _, info in ipairs(collectParts) do
                totalBanked = totalBanked + info.banked
            end

            statsLabel.Text = string.format(
                "💰 Cash: %s  (+%s session)\n🌱 Plants: %d  (%s/s total)\n📦 Banked: %s\n🏃 Run: %s  |  Speed: %s\n🌾 Seed: %s\n\n⚡ Speed: %s | 🔄 Collect: %s | 🏃 Run: %s",
                formatNum(cash), formatNum(profit),
                #plants, formatNum(totalCPS),
                formatNum(totalBanked),
                runActive and "ACTIVE" or "idle", formatNum(runSpeed),
                equippedSeed,
                State.speedHack and (State.speedMult .. "x") or "OFF",
                State.autoCollect and "ON" or "OFF",
                State.autoRun and "ON" or "OFF"
            )
        end)
    end))
end

-- ═══════════════════════════════════════════
-- CLEANUP FUNCTION
-- ═══════════════════════════════════════════
getgenv()._reseederCleanup = function()
    for _, conn in ipairs(connections) do
        pcall(function() conn:Disconnect() end)
    end
    connections = {}

    pcall(function()
        local pg = LP:FindFirstChild("PlayerGui")
        if pg then
            local overlay = pg:FindFirstChild("ReseederOverlay")
            if overlay then overlay:Destroy() end
        end
    end)

    -- Reset humanoid
    pcall(function()
        local hum = getHumanoid()
        if hum then
            hum.WalkSpeed = 36
            hum.JumpPower = 50
        end
    end)
end

-- ═══════════════════════════════════════════
-- STARTUP
-- ═══════════════════════════════════════════
local pCount = #getMyPlants()
local cash = getCash()

Rayfield:Notify({
    Title = "🌱 Reseeder v1 Loaded",
    Content = string.format("Cash: %s | Plants: %d | Press K to toggle stats", formatNum(cash), pCount),
    Duration = 5,
})

print(string.format("[Reseeder v1] Cash: %s | Plants: %d | Loaded", formatNum(cash), pCount))

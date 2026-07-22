--[[
    ╔════════════════════════════════════════════╗
    ║   🦠 PATHOGEN v1 — Parasite.exe Exploit   ║
    ║        by Xaric Hub                        ║
    ╚════════════════════════════════════════════╝
]]

if getgenv()._pathogenLoaded then return end
getgenv()._pathogenLoaded = true

-- ═══════════════════════════════════════════
-- SERVICES
-- ═══════════════════════════════════════════
local Players           = game:GetService("Players")
local RS                = game:GetService("ReplicatedStorage")
local WS                = game:GetService("Workspace")
local RunService        = game:GetService("RunService")
local Lighting          = game:GetService("Lighting")
local VirtualInputMgr   = game:GetService("VirtualInputManager")
local LP                = Players.LocalPlayer

-- ═══════════════════════════════════════════
-- REMOTES
-- ═══════════════════════════════════════════
local SpawnParasite     = RS:FindFirstChild("SpawnParasite")      -- RemoteFunction
local PurchaseUpgrade   = RS:FindFirstChild("PurchaseUpgrade")    -- RemoteFunction
local TerminateParasite = RS:FindFirstChild("TerminateParasite")  -- RemoteEvent
local TakeSpin          = RS:FindFirstChild("TakeSpin")           -- RemoteEvent
local ClaimWheelPrize   = RS:FindFirstChild("ClaimWheelPrize")    -- RemoteEvent
local ClaimCode         = RS:FindFirstChild("ClaimCode")          -- RemoteEvent
local GetIndex          = RS:FindFirstChild("GetIndex")           -- RemoteFunction
local GetContracts      = RS:FindFirstChild("GetContracts")       -- RemoteFunction
local SubmitContract    = RS:FindFirstChild("SubmitContract")     -- RemoteFunction
local RefreshContract   = RS:FindFirstChild("RefreshContract")    -- RemoteEvent

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

local function getMyLab()
    for _, lab in ipairs(WS.Labs:GetChildren()) do
        local owner = lab:FindFirstChild("Owner")
        if owner and owner.Value == LP then return lab end
    end
    return nil
end

local function getMyParasiteFolder()
    for _, c in ipairs(WS:GetChildren()) do
        if c.Name:find("Parasite") and c:IsA("Folder") then
            for _, part in ipairs(c:GetChildren()) do
                if part:IsA("BasePart") and part:GetAttribute("ParasiteUID") then
                    return c
                end
            end
        end
    end
    return nil
end

local function fireClickDetector(cd)
    if cd and cd:IsA("ClickDetector") then
        fireclickdetector(cd)
    end
end

local function findClickInLab(name)
    local lab = getMyLab()
    if not lab then return nil end
    local control = lab:FindFirstChild("Control")
    if not control then return nil end
    for _, d in ipairs(control:GetDescendants()) do
        if d:IsA("ClickDetector") and d.Parent.Name == name then
            return d
        end
    end
    return nil
end

-- ═══════════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════════
local State = {
    autoGrow        = false,
    autoFastGrow    = false,
    autoAttack      = false,
    attackType      = "Hurt",
    autoSpawn       = false,
    autoUpgrade     = false,
    upgradeType     = "damage",
    speedHack       = false,
    speedMult       = 2,
    infiniteJump    = false,
    noclip          = false,
    antiAFK         = true,
    fullbright      = false,
    autoSpin        = false,
}
getgenv()._pathogenState = State

-- ═══════════════════════════════════════════
-- UI LIBRARY (Rayfield)
-- ═══════════════════════════════════════════
local function loadRayfield()
    local ok, source = pcall(game.HttpGet, game, "https://sirius.menu/rayfield")
    assert(ok and type(source) == "string" and #source > 0, "Unable to download Rayfield")
    local chunk, compileError = loadstring(source)
    assert(chunk, "Rayfield compile failed: " .. tostring(compileError))
    return chunk()
end
local Rayfield = loadRayfield()

local Window = Rayfield:CreateWindow({
    Name            = "🦠 PATHOGEN v1",
    Icon            = 0,
    LoadingEnabled  = false,
    ConfigurationSaving = { Enabled = false },
    KeySystem       = false,
})

-- ═══════════════════════════════════════════
-- LAB TAB
-- ═══════════════════════════════════════════
local LabTab = Window:CreateTab("🧪 Lab", 0)

LabTab:CreateSection("Parasite Growth")

LabTab:CreateToggle({
    Name = "Auto-Grow",
    CurrentValue = false,
    Flag = "AutoGrow",
    Callback = function(v) State.autoGrow = v end,
})

LabTab:CreateToggle({
    Name = "Auto-FastGrow (⚡ Boost)",
    CurrentValue = false,
    Flag = "AutoFastGrow",
    Callback = function(v) State.autoFastGrow = v end,
})

LabTab:CreateButton({
    Name = "Grow Once",
    Callback = function()
        local cd = findClickInLab("Grow")
        if cd then fireClickDetector(cd) end
    end,
})

LabTab:CreateButton({
    Name = "FastGrow Once",
    Callback = function()
        local cd = findClickInLab("FastGrow")
        if cd then fireClickDetector(cd) end
    end,
})

LabTab:CreateSection("Attacks")

local ATTACK_TYPES = {"Hurt", "Shock", "Freeze", "Ignite", "Soak", "AcidBurn", "Radioactive", "Lazer", "Vaporize", "Twist", "Confuse", "Corrupt", "Shockstorm", "ColorSurge", "Heal"}

LabTab:CreateDropdown({
    Name = "Attack Type",
    Options = ATTACK_TYPES,
    CurrentOption = {"Hurt"},
    Flag = "AttackType",
    Callback = function(v) State.attackType = v[1] or v end,
})

LabTab:CreateToggle({
    Name = "Auto-Attack",
    CurrentValue = false,
    Flag = "AutoAttack",
    Callback = function(v) State.autoAttack = v end,
})

LabTab:CreateButton({
    Name = "Fire Attack Once",
    Callback = function()
        local cd = findClickInLab(State.attackType)
        if cd then fireClickDetector(cd) end
    end,
})

LabTab:CreateSection("Dummies")

local DUMMY_TYPES = {"NormalDummy", "MegaDummy", "ToxicDummy", "BullyDummy", "GlitchDummy", "CloneDummy", "FunnyDummy", "MiniDummy", "FreezeDummy", "BouncyDummy", "CrazyDummy", "ZombieDummy", "RainbowDummy", "SlowDummy", "SmartDummy", "SpikyDummy", "RubberDummy", "ExplodingDummy"}

LabTab:CreateDropdown({
    Name = "Spawn Dummy Type",
    Options = DUMMY_TYPES,
    CurrentOption = {"NormalDummy"},
    Flag = "DummyType",
    Callback = function(v)
        local name = v[1] or v
        local cd = findClickInLab(name)
        if cd then fireClickDetector(cd) end
    end,
})

LabTab:CreateSection("Parasite Management")

LabTab:CreateToggle({
    Name = "Auto-Spawn Parasite",
    CurrentValue = false,
    Flag = "AutoSpawn",
    Callback = function(v) State.autoSpawn = v end,
})

LabTab:CreateButton({
    Name = "Spawn Parasite",
    Callback = function()
        pcall(function()
            local cd = findClickInLab("Spawn")
            if cd then fireClickDetector(cd) end
        end)
    end,
})

LabTab:CreateButton({
    Name = "Delete Parasite",
    Callback = function()
        pcall(function()
            local cd = findClickInLab("Delete")
            if cd then fireClickDetector(cd) end
        end)
    end,
})

LabTab:CreateButton({
    Name = "TP to My Lab",
    Callback = function()
        local lab = getMyLab()
        if lab then
            local tp = lab:FindFirstChild("Tp")
            local hrp = getHRP()
            if tp and hrp then
                hrp.CFrame = tp.CFrame + Vector3.new(0, 3, 0)
            end
        end
    end,
})

-- ═══════════════════════════════════════════
-- UPGRADES TAB
-- ═══════════════════════════════════════════
local UpgradeTab = Window:CreateTab("⬆️ Upgrades", 0)

UpgradeTab:CreateSection("Growth Accelerator")

UpgradeTab:CreateToggle({
    Name = "Auto-Purchase Growth Upgrade",
    CurrentValue = false,
    Flag = "AutoUpgrade",
    Callback = function(v) State.autoUpgrade = v end,
})

UpgradeTab:CreateButton({
    Name = "Buy Growth Accelerator",
    Callback = function()
        pcall(function() PurchaseUpgrade:InvokeServer("growth") end)
    end,
})

UpgradeTab:CreateSection("Contracts")

UpgradeTab:CreateButton({
    Name = "View Contracts",
    Callback = function()
        task.spawn(function()
            pcall(function()
                local result = GetContracts:InvokeServer()
                if result then
                    print("[Pathogen] Contracts: Level " .. tostring(result.level) .. " | XP: " .. tostring(result.xp) .. " | RP: " .. tostring(result.researchPoints))
                end
            end)
        end)
    end,
})

UpgradeTab:CreateButton({
    Name = "Submit Contract 1",
    Callback = function()
        pcall(function() SubmitContract:InvokeServer(1) end)
    end,
})

UpgradeTab:CreateButton({
    Name = "Submit Contract 2",
    Callback = function()
        pcall(function() SubmitContract:InvokeServer(2) end)
    end,
})

UpgradeTab:CreateButton({
    Name = "Submit Contract 3",
    Callback = function()
        pcall(function() SubmitContract:InvokeServer(3) end)
    end,
})

-- ═══════════════════════════════════════════
-- PLAYER TAB
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
    Name = "Speed Multiplier",
    Range = {1, 10},
    Increment = 0.5,
    CurrentValue = 2,
    Flag = "SpeedMult",
    Callback = function(v) State.speedMult = v end,
})

PlayerTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Flag = "InfiniteJump",
    Callback = function(v) State.infiniteJump = v end,
})

PlayerTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Flag = "Noclip",
    Callback = function(v) State.noclip = v end,
})

PlayerTab:CreateSection("Teleport")

PlayerTab:CreateButton({
    Name = "TP to Lab",
    Callback = function()
        local lab = getMyLab()
        if lab then
            local tp = lab:FindFirstChild("Tp")
            local hrp = getHRP()
            if tp and hrp then hrp.CFrame = tp.CFrame + Vector3.new(0, 3, 0) end
        end
    end,
})

PlayerTab:CreateButton({
    Name = "TP to Dummy Area",
    Callback = function()
        local lab = getMyLab()
        if lab then
            local dtp = lab:FindFirstChild("DummyTp")
            local hrp = getHRP()
            if dtp and hrp then hrp.CFrame = dtp.CFrame + Vector3.new(0, 3, 0) end
        end
    end,
})

PlayerTab:CreateButton({
    Name = "TP to Boss Spawn",
    Callback = function()
        local bossSpawn = WS:FindFirstChild("BossSpawn")
        local hrp = getHRP()
        if bossSpawn and hrp then hrp.CFrame = bossSpawn.CFrame + Vector3.new(0, 5, 0) end
    end,
})

-- ═══════════════════════════════════════════
-- VISUALS TAB
-- ═══════════════════════════════════════════
local VisualsTab = Window:CreateTab("👁️ Visuals", 0)

VisualsTab:CreateSection("Rendering")

VisualsTab:CreateToggle({
    Name = "Fullbright",
    CurrentValue = false,
    Flag = "Fullbright",
    Callback = function(v)
        State.fullbright = v
        if v then
            Lighting.Brightness = 3
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
        else
            Lighting.Brightness = 1
            Lighting.ClockTime = 14
            Lighting.FogEnd = 10000
            Lighting.GlobalShadows = true
        end
    end,
})

-- ═══════════════════════════════════════════
-- MISC TAB
-- ═══════════════════════════════════════════
local MiscTab = Window:CreateTab("⚙️ Misc", 0)

MiscTab:CreateSection("Rewards")

MiscTab:CreateToggle({
    Name = "Auto-Spin Wheel",
    CurrentValue = false,
    Flag = "AutoSpin",
    Callback = function(v) State.autoSpin = v end,
})

MiscTab:CreateButton({
    Name = "Spin Wheel Once",
    Callback = function()
        pcall(function() TakeSpin:FireServer() end)
        task.wait(0.5)
        pcall(function() ClaimWheelPrize:FireServer() end)
    end,
})

MiscTab:CreateButton({
    Name = "Claim Code: RELEASE",
    Callback = function()
        pcall(function() ClaimCode:FireServer("RELEASE") end)
    end,
})

MiscTab:CreateButton({
    Name = "Claim Code: UPDATE",
    Callback = function()
        pcall(function() ClaimCode:FireServer("UPDATE") end)
    end,
})

MiscTab:CreateSection("Lab Effects")

MiscTab:CreateButton({
    Name = "Rainbow Parasite",
    Callback = function()
        local lab = getMyLab()
        if lab then
            local evt = lab:FindFirstChild("RainbowifyEvent")
            if evt then evt:Fire() end
        end
    end,
})

MiscTab:CreateButton({
    Name = "Crazy Mutation",
    Callback = function()
        local lab = getMyLab()
        if lab then
            local evt = lab:FindFirstChild("SpawnCrazyEvent")
            if evt then evt:Fire() end
        end
    end,
})

MiscTab:CreateButton({
    Name = "Halloween Effect",
    Callback = function()
        local lab = getMyLab()
        if lab then
            local evt = lab:FindFirstChild("SpawnHalloweenEvent")
            if evt then evt:Fire() end
        end
    end,
})

MiscTab:CreateSection("Safety")

MiscTab:CreateToggle({
    Name = "Anti-AFK",
    CurrentValue = true,
    Flag = "AntiAFK",
    Callback = function(v) State.antiAFK = v end,
})

MiscTab:CreateButton({
    Name = "🔴 Panic Kill",
    Callback = function()
        for _, conn in ipairs(connections) do pcall(function() conn:Disconnect() end) end
        connections = {}
        getgenv()._pathogenLoaded = nil
        getgenv()._pathogenState = nil
        pcall(function() Rayfield:Destroy() end)
    end,
})

-- ═══════════════════════════════════════════
-- BACKGROUND LOOPS
-- ═══════════════════════════════════════════

-- AUTO-GROW
do
    local lastGrow = 0
    track(RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - lastGrow < 0.5 then return end
        lastGrow = now
        if not State.autoGrow then return end
        local cd = findClickInLab("Grow")
        if cd then fireClickDetector(cd) end
    end))
end

-- AUTO-FASTGROW
do
    local lastFG = 0
    track(RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - lastFG < 0.5 then return end
        lastFG = now
        if not State.autoFastGrow then return end
        local cd = findClickInLab("FastGrow")
        if cd then fireClickDetector(cd) end
    end))
end

-- AUTO-ATTACK
do
    local lastAtk = 0
    track(RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - lastAtk < 0.3 then return end
        lastAtk = now
        if not State.autoAttack then return end
        local cd = findClickInLab(State.attackType)
        if cd then fireClickDetector(cd) end
    end))
end

-- AUTO-SPAWN
do
    local lastSpawn = 0
    track(RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - lastSpawn < 5 then return end
        lastSpawn = now
        if not State.autoSpawn then return end
        local cd = findClickInLab("Spawn")
        if cd then fireClickDetector(cd) end
    end))
end

-- AUTO-UPGRADE
do
    local lastUpg = 0
    track(RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - lastUpg < 2 then return end
        lastUpg = now
        if not State.autoUpgrade then return end
        pcall(function() PurchaseUpgrade:InvokeServer("growth") end)
    end))
end

-- AUTO-SPIN
do
    local lastSpin = 0
    track(RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - lastSpin < 5 then return end
        lastSpin = now
        if not State.autoSpin then return end
        pcall(function() TakeSpin:FireServer() end)
        task.wait(0.5)
        pcall(function() ClaimWheelPrize:FireServer() end)
    end))
end

-- SPEED HACK
track(RunService.Heartbeat:Connect(function()
    if not State.speedHack then return end
    local hum = getHumanoid()
    if hum then hum.WalkSpeed = 16 * State.speedMult end
end))

-- INFINITE JUMP
track(game:GetService("UserInputService").JumpRequest:Connect(function()
    if not State.infiniteJump then return end
    local hum = getHumanoid()
    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end))

-- NOCLIP
track(RunService.Stepped:Connect(function()
    if not State.noclip then return end
    if LP.Character then
        for _, part in ipairs(LP.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end))

-- ANTI-AFK
track(LP.Idled:Connect(function()
    if State.antiAFK then
        VirtualInputMgr:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
        task.wait(0.1)
        VirtualInputMgr:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
    end
end))

print("[XaricHub] Pathogen v1 loaded OK")

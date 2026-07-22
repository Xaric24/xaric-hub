--[[
    ╔═══════════════════════════════════════════════════════════╗
    ║  🧠 BrainSnatch v1 — Catch a Brainrot Exploit             ║
    ║  Auto-Battle · Auto-Catch · ESP · Speed · Teleport        ║
    ╚═══════════════════════════════════════════════════════════╝
]]

-- ═══════════════════════════════════════════
-- CLEANUP
-- ═══════════════════════════════════════════
if getgenv and getgenv()._brainrotCleanup then
    pcall(getgenv()._brainrotCleanup)
end
pcall(function()
    for _, g in ipairs(gethui():GetChildren()) do
        if g.Name == "Rayfield" then g:Destroy() end
    end
end)
pcall(function()
    local pg = game.Players.LocalPlayer:FindFirstChild("PlayerGui")
    if pg then
        local o = pg:FindFirstChild("BrainSnatchOverlay")
        if o then o:Destroy() end
    end
end)
-- Remove old ESP
pcall(function()
    for _, bb in ipairs(game.Workspace:GetDescendants()) do
        if bb.Name == "BrainSnatchESP" then bb:Destroy() end
    end
end)

-- ═══════════════════════════════════════════
-- SERVICES
-- ═══════════════════════════════════════════
local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local Workspace          = game:GetService("Workspace")
local TweenService       = game:GetService("TweenService")
local LP = Players.LocalPlayer

-- ═══════════════════════════════════════════
-- GAME MODULES (safe require)
-- ═══════════════════════════════════════════
local Core, MyRots, Sprint, Yen, InsideBattle, WorldClient
pcall(function() Core = require(ReplicatedStorage.Brainrot.Core) end)
pcall(function() MyRots = require(ReplicatedStorage.Brainrot.Rot.MyRots) end)
pcall(function() Sprint = require(ReplicatedStorage.Brainrot.Sprint) end)
pcall(function() Yen = require(ReplicatedStorage.Brainrot.Yen) end)
pcall(function() InsideBattle = require(ReplicatedStorage.Brainrot.Battle.InsideActiveBattle) end)
pcall(function() WorldClient = require(ReplicatedStorage.Brainrot.Worlds.Client) end)

-- Battle remotes
local BattleSend  -- RemoteFunction for battle commands
pcall(function() BattleSend = ReplicatedStorage.Brainrot.Battle.Server.Send end)

-- ═══════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════
local connections = {}
local function track(conn) table.insert(connections, conn) return conn end

local function getHRP()
    local char = LP.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local char = LP.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function getWildRotTags()
    local folder = Workspace:FindFirstChild("WildRotTags")
    return folder and folder:GetChildren() or {}
end

local function getRotObjects()
    local folder = Workspace:FindFirstChild("ROT OBJECTS")
    return folder and folder:GetChildren() or {}
end

local function getNearestTag()
    local hrp = getHRP()
    if not hrp then return nil, math.huge end
    local nearest, dist = nil, math.huge
    for _, tag in ipairs(getWildRotTags()) do
        if tag:IsA("BasePart") then
            local d = (tag.Position - hrp.Position).Magnitude
            if d < dist then
                nearest = tag
                dist = d
            end
        end
    end
    return nearest, dist
end

local function getYen()
    if Yen and Yen.Wallet then
        return tonumber(Yen.Wallet.Amount) or 0
    end
    return 0
end

local function isInBattle()
    if InsideBattle then
        return InsideBattle.Enabled == true or InsideBattle.Count > 0
    end
    return false
end

local function getTeamInfo()
    if not MyRots or not MyRots.Team then return {} end
    local team = {}
    for i, rot in ipairs(MyRots.Team) do
        if type(rot) == "table" then
            table.insert(team, {
                slot = i,
                name = rot.DisplayName or rot.Name or "???",
                level = rot.Level or 0,
                hp = rot.Health or 0,
                iv = rot.IV or 0,
                ball = rot.BallName or "?",
            })
        end
    end
    return team
end

-- ═══════════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════════
local State = {
    speedHack     = false,
    speedMult     = 2,
    infiniteJump  = false,
    noclip        = false,
    antiAFK       = true,
    alwaysSprint  = false,
    autoWild      = false,
    autoAttack    = false,
    autoCatch     = false,
    esp           = false,
}
getgenv()._brainrotState = State

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
    Name              = "🧠 BrainSnatch v1",
    Icon              = 0,
    LoadingTitle      = "BrainSnatch v1",
    LoadingSubtitle   = "Catch a Brainrot Exploit",
    Theme             = "DarkBlue",
    DisableRayfieldPrompts = true,
    DisableBuildWarnings   = true,
    ConfigurationSaving = {
        Enabled  = true,
        FolderName = "BrainSnatch",
        FileName   = "config",
    },
    KeySystem = false,
})

-- ═══════════════════════════════════════════
-- TAB: PLAYER
-- ═══════════════════════════════════════════
local PlayerTab = Window:CreateTab("🎮 Player", 0)

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
    Name = "Always Sprint",
    CurrentValue = false,
    Flag = "AlwaysSprint",
    Callback = function(v) State.alwaysSprint = v end,
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

PlayerTab:CreateSection("Utility")

PlayerTab:CreateToggle({
    Name = "Anti-AFK",
    CurrentValue = true,
    Flag = "AntiAFK",
    Callback = function(v) State.antiAFK = v end,
})

-- ═══════════════════════════════════════════
-- TAB: BATTLE
-- ═══════════════════════════════════════════
local BattleTab = Window:CreateTab("⚔️ Battle", 0)

BattleTab:CreateSection("Automation")

BattleTab:CreateToggle({
    Name = "Auto Walk Into Wild Rots",
    CurrentValue = false,
    Flag = "AutoWild",
    Callback = function(v) State.autoWild = v end,
})

BattleTab:CreateToggle({
    Name = "Wild Rot ESP",
    CurrentValue = false,
    Flag = "ESP",
    Callback = function(v) State.esp = v end,
})

BattleTab:CreateSection("Quick Actions")

BattleTab:CreateButton({
    Name = "TP to Nearest Wild Rot",
    Callback = function()
        pcall(function()
            local tag, dist = getNearestTag()
            if tag then
                local hrp = getHRP()
                if hrp then
                    hrp.CFrame = CFrame.new(tag.Position + Vector3.new(0, 3, 0))
                end
            end
        end)
    end,
})

-- ═══════════════════════════════════════════
-- TAB: TELEPORT
-- ═══════════════════════════════════════════
local TeleportTab = Window:CreateTab("🗺️ Teleport", 0)

TeleportTab:CreateSection("Worlds")

TeleportTab:CreateButton({
    Name = "Switch to World 1",
    Callback = function()
        pcall(function()
            ReplicatedStorage.Brainrot.Worlds.Server.SetWorld:FireServer(1)
            if WorldClient then WorldClient.SetWorld(1) end
        end)
    end,
})

TeleportTab:CreateButton({
    Name = "Switch to World 2",
    Callback = function()
        pcall(function()
            ReplicatedStorage.Brainrot.Worlds.Server.SetWorld:FireServer(2)
            if WorldClient then WorldClient.SetWorld(2) end
        end)
    end,
})

TeleportTab:CreateSection("Wild Rots")

TeleportTab:CreateButton({
    Name = "TP to Nearest Wild Rot",
    Callback = function()
        pcall(function()
            local tag = getNearestTag()
            local hrp = getHRP()
            if tag and hrp then
                hrp.CFrame = CFrame.new(tag.Position + Vector3.new(0, 3, 0))
            end
        end)
    end,
})

-- Build zone TP buttons from WildRotTags positions
pcall(function()
    local tags = getWildRotTags()
    -- Group tags roughly by Z-coordinate to identify zones
    local zones = {}
    for _, tag in ipairs(tags) do
        if tag:IsA("BasePart") then
            table.insert(zones, tag.Position)
        end
    end
    if #zones > 0 then
        -- Just add first few unique positions as zone TPs
        for i = 1, math.min(#zones, 5) do
            TeleportTab:CreateButton({
                Name = "TP to Wild Spot " .. i,
                Callback = function()
                    pcall(function()
                        local hrp = getHRP()
                        if hrp then
                            hrp.CFrame = CFrame.new(zones[i] + Vector3.new(0, 3, 0))
                        end
                    end)
                end,
            })
        end
    end
end)

-- ═══════════════════════════════════════════
-- TAB: INFO
-- ═══════════════════════════════════════════
local InfoTab = Window:CreateTab("📊 Info", 0)

InfoTab:CreateSection("Currency")

local yenLabel = InfoTab:CreateLabel("Yen: " .. tostring(getYen()))

InfoTab:CreateSection("Team")

pcall(function()
    local team = getTeamInfo()
    for _, rot in ipairs(team) do
        InfoTab:CreateLabel(
            string.format("[%d] %s  Lv.%d  IV:%.0f%%  HP:%.0f",
                rot.slot, rot.name, rot.level, rot.iv * 100, rot.hp)
        )
    end
    if #team == 0 then
        InfoTab:CreateLabel("No team data loaded")
    end
end)

InfoTab:CreateSection("World")

local worldLabel = InfoTab:CreateLabel("World: " .. (WorldClient and tostring(WorldClient.CurrentWorld) or "?"))
local wildLabel = InfoTab:CreateLabel("Wild Rot Tags: " .. #getWildRotTags())

InfoTab:CreateButton({
    Name = "Refresh Info",
    Callback = function()
        pcall(function()
            yenLabel:Set("Yen: " .. tostring(getYen()))
            worldLabel:Set("World: " .. (WorldClient and tostring(WorldClient.CurrentWorld) or "?"))
            wildLabel:Set("Wild Rot Tags: " .. #getWildRotTags())
        end)
    end,
})

-- ═══════════════════════════════════════════
-- BACKGROUND LOOPS
-- ═══════════════════════════════════════════

-- SPEED HACK (Heartbeat)
do
    local DEFAULT_SPEED = 19.2
    track(RunService.Heartbeat:Connect(function()
        if not State.speedHack then return end
        pcall(function()
            local hum = getHumanoid()
            if hum then
                hum.WalkSpeed = DEFAULT_SPEED * State.speedMult
            end
        end)
    end))
end

-- ALWAYS SPRINT (Heartbeat, every 0.5s)
do
    local lastTick = 0
    track(RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - lastTick < 0.5 then return end
        lastTick = now
        if not State.alwaysSprint then return end
        pcall(function()
            if Sprint then
                Sprint.Sprinting = true
            end
        end)
    end))
end

-- NOCLIP (Stepped)
do
    track(RunService.Stepped:Connect(function()
        if not State.noclip then return end
        pcall(function()
            local char = LP.Character
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

-- ANTI-AFK (every 60s)
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

-- AUTO WALK INTO WILD (every 3s)
do
    local lastTick = 0
    track(RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - lastTick < 3 then return end
        lastTick = now
        if not State.autoWild then return end
        if isInBattle() then return end
        pcall(function()
            local tag, dist = getNearestTag()
            local hrp = getHRP()
            if tag and hrp and dist > 5 then
                hrp.CFrame = CFrame.new(tag.Position + Vector3.new(0, 2, 0))
            end
        end)
    end))
end

-- ESP (Wild Rot Tags — every 2s refresh)
do
    local espParts = {}
    local lastTick = 0

    local function clearESP()
        for _, bb in ipairs(espParts) do
            pcall(function() bb:Destroy() end)
        end
        espParts = {}
    end

    local function refreshESP()
        clearESP()
        if not State.esp then return end

        for _, tag in ipairs(getWildRotTags()) do
            if tag:IsA("BasePart") then
                pcall(function()
                    local bb = Instance.new("BillboardGui")
                    bb.Name = "BrainSnatchESP"
                    bb.Adornee = tag
                    bb.Size = UDim2.new(0, 120, 0, 40)
                    bb.StudsOffset = Vector3.new(0, 4, 0)
                    bb.AlwaysOnTop = true
                    bb.Parent = tag

                    local label = Instance.new("TextLabel")
                    label.Size = UDim2.new(1, 0, 1, 0)
                    label.BackgroundColor3 = Color3.fromRGB(130, 80, 255)
                    label.BackgroundTransparency = 0.3
                    label.TextColor3 = Color3.new(1, 1, 1)
                    label.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
                    label.TextSize = 14
                    label.Text = "🧠 WILD ROT"
                    label.Parent = bb

                    Instance.new("UICorner", label).CornerRadius = UDim.new(0, 6)

                    -- Distance label
                    local hrp = getHRP()
                    if hrp then
                        local dist = math.floor((tag.Position - hrp.Position).Magnitude)
                        label.Text = "🧠 WILD ROT [" .. dist .. "m]"
                    end

                    table.insert(espParts, bb)
                end)
            end
        end
    end

    track(RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - lastTick < 2 then return end
        lastTick = now
        if State.esp then
            refreshESP()
        else
            if #espParts > 0 then clearESP() end
        end
    end))
end

-- ═══════════════════════════════════════════
-- LIVE OVERLAY
-- ═══════════════════════════════════════════
pcall(function()
    local overlay = Instance.new("ScreenGui")
    overlay.Name = "BrainSnatchOverlay"
    overlay.ResetOnSpawn = false
    overlay.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    pcall(function() overlay.Parent = LP:WaitForChild("PlayerGui") end)
    if not overlay.Parent then
        overlay.Parent = game:GetService("CoreGui")
    end

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 220, 0, 100)
    frame.Position = UDim2.new(0, 10, 0.5, -50)
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    frame.BackgroundTransparency = 0.15
    frame.BorderSizePixel = 0
    frame.Parent = overlay

    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(130, 80, 255)
    stroke.Thickness = 1.5
    stroke.Transparency = 0.3
    stroke.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 22)
    title.Position = UDim2.new(0, 0, 0, 2)
    title.BackgroundTransparency = 1
    title.Text = "🧠 BrainSnatch"
    title.TextColor3 = Color3.fromRGB(160, 110, 255)
    title.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
    title.TextSize = 13
    title.Parent = frame

    local statsLabel = Instance.new("TextLabel")
    statsLabel.Size = UDim2.new(1, -16, 1, -26)
    statsLabel.Position = UDim2.new(0, 8, 0, 24)
    statsLabel.BackgroundTransparency = 1
    statsLabel.Text = "Loading..."
    statsLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
    statsLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular)
    statsLabel.TextSize = 11
    statsLabel.TextXAlignment = Enum.TextXAlignment.Left
    statsLabel.TextYAlignment = Enum.TextYAlignment.Top
    statsLabel.TextWrapped = true
    statsLabel.Parent = frame

    -- Update overlay every 1s
    local lastTick = 0
    track(RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - lastTick < 1 then return end
        lastTick = now
        pcall(function()
            local yen = getYen()
            local wildCount = #getWildRotTags()
            local inBattle = isInBattle()
            local world = WorldClient and tostring(WorldClient.CurrentWorld) or "?"

            local team = getTeamInfo()
            local teamStr = ""
            for _, r in ipairs(team) do
                teamStr = teamStr .. r.name:sub(1, 12) .. " Lv" .. r.level .. "  "
            end

            statsLabel.Text = string.format(
                "💰 Yen: %s\n🌍 World %s  |  🧠 Wild: %d\n⚔ Battle: %s\n👥 %s",
                tostring(yen),
                world,
                wildCount,
                inBattle and "ACTIVE" or "idle",
                teamStr ~= "" and teamStr or "No team"
            )
        end)
    end))
end)

-- ═══════════════════════════════════════════
-- CLEANUP FUNCTION
-- ═══════════════════════════════════════════
getgenv()._brainrotCleanup = function()
    for _, conn in ipairs(connections) do
        pcall(function() conn:Disconnect() end)
    end
    connections = {}
    pcall(function()
        for _, g in ipairs(gethui():GetChildren()) do
            if g.Name == "Rayfield" then g:Destroy() end
        end
    end)
    pcall(function()
        local pg = LP:FindFirstChild("PlayerGui")
        if pg then
            local o = pg:FindFirstChild("BrainSnatchOverlay")
            if o then o:Destroy() end
        end
    end)
    pcall(function()
        for _, bb in ipairs(Workspace:GetDescendants()) do
            if bb.Name == "BrainSnatchESP" then bb:Destroy() end
        end
    end)
end

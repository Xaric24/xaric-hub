--[[
    ╔═══════════════════════════════════════════╗
    ║  StarForge v1 — Make a Galaxy ✨ Exploit  ║
    ║  Xaric Hub Module                         ║
    ╚═══════════════════════════════════════════╝
]]

if getgenv()._starforgeLoaded then return end
getgenv()._starforgeLoaded = true

-- ═══════════════════════════════════════════
-- SERVICES
-- ═══════════════════════════════════════════
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")

local LP  = Players.LocalPlayer
local RS  = ReplicatedStorage

-- ═══════════════════════════════════════════
-- REMOTE REFS
-- ═══════════════════════════════════════════
local Remotes = RS:FindFirstChild("Remotes")
local Events  = RS:FindFirstChild("Events")

local OpenCrate         = Remotes and Remotes:FindFirstChild("OpenCrate")
local SellEvent         = Events and Events:FindFirstChild("SellEvent")
local SellPlanet        = Events and Events:FindFirstChild("SellPlanet")
local SellInventory     = Events and Events:FindFirstChild("SellInventoryEvent")
local AutoCollectToggle = Events and Events:FindFirstChild("AutoCollectToggle")
local AutoBuyToggle     = Events and Events:FindFirstChild("AutoBuyToggle")
local EquipComet        = Events and Events:FindFirstChild("EquipComet")
local UnequipComet      = Events and Events:FindFirstChild("UnequipComet")
local TpPlayer          = Events and Events:FindFirstChild("TpPlayer")
local Tp2Player         = Events and Events:FindFirstChild("Tp2Player")
local FuseRequest       = Events and Events:FindFirstChild("FuseRequest")
local PurchaseUpgrade   = Events and Events:FindFirstChild("PurchaseUpgrade")
local PurchaseBase      = Events and Events:FindFirstChild("PurchaseBaseUpgrade")
local GetInventory      = Events and Events:FindFirstChild("GetInventory")
local MergeComet        = Remotes and Remotes:FindFirstChild("MergeComet")

-- ═══════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════
local connections = {}
local function track(conn) table.insert(connections, conn) return conn end

local function getHRP()
    return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
end

local function getMyPlot()
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return nil end
    for _, p in ipairs(plots:GetChildren()) do
        local owner = p:FindFirstChild("Owner")
        if owner and owner:IsA("StringValue") and owner.Value == LP.Name then
            return p
        end
    end
    return nil
end

local function getInventory()
    if GetInventory then
        local ok, data = pcall(function() return GetInventory:InvokeServer() end)
        if ok then return data end
    end
    return nil
end

-- ═══════════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════════
local State = {
    speedHack       = false,
    speedMult       = 2,
    infiniteJump    = false,
    noclip          = false,
    antiAFK         = true,
    autoCollect     = false,
    autoHatch       = false,
    autoOpenCrate   = false,
    crateType       = "Basic",
    autoFuse        = false,
}
getgenv()._starforgeState = State

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
    Name              = "⭐ StarForge v1",
    Icon              = 0,
    LoadingTitle      = "StarForge v1",
    LoadingSubtitle   = "Make a Galaxy! Exploit",
    Theme             = "DarkBlue",
    DisableRayfieldPrompts = true,
    DisableBuildWarnings   = true,
    ConfigurationSaving = {
        Enabled    = true,
        FolderName = "StarForge",
        FileName   = "config",
    },
    KeySystem = false,
})

-- ═══════════════════════════════════════════
-- TAB: PLAYER
-- ═══════════════════════════════════════════
local PlayerTab = Window:CreateTab("🚀 Player", 0)

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

PlayerTab:CreateSection("Utility")

PlayerTab:CreateToggle({
    Name = "Anti-AFK",
    CurrentValue = true,
    Flag = "AntiAFK",
    Callback = function(v) State.antiAFK = v end,
})

-- ═══════════════════════════════════════════
-- TAB: FARMING
-- ═══════════════════════════════════════════
local FarmTab = Window:CreateTab("🌌 Farm", 0)

FarmTab:CreateSection("Collection")

FarmTab:CreateToggle({
    Name = "Auto-Collect Stored Coins",
    CurrentValue = false,
    Flag = "AutoCollect",
    Callback = function(v) State.autoCollect = v end,
})

FarmTab:CreateButton({
    Name = "Collect All Stored Coins Now",
    Callback = function()
        pcall(function() SellInventory:FireServer() end)
    end,
})

FarmTab:CreateSection("Selling")

FarmTab:CreateButton({
    Name = "Sell Planet (by index)",
    Callback = function()
        task.spawn(function()
            pcall(function()
                local inv = getInventory()
                if inv and inv.planets and #inv.planets > 0 then
                    local lowest = inv.planets[1]
                    for _, p in ipairs(inv.planets) do
                        if p.cps < lowest.cps then lowest = p end
                    end
                    SellPlanet:FireServer(lowest.index)
                    pcall(function()
                        Rayfield:Notify({
                            Title = "Sold Planet",
                            Content = lowest.displayName .. " (" .. lowest.cps .. " CPS)",
                            Duration = 3,
                        })
                    end)
                end
            end)
        end)
    end,
})

FarmTab:CreateSection("Hatching")

FarmTab:CreateToggle({
    Name = "Auto-Open Crates",
    CurrentValue = false,
    Flag = "AutoOpenCrate",
    Callback = function(v) State.autoOpenCrate = v end,
})

FarmTab:CreateDropdown({
    Name = "Crate Type",
    Options = {"Basic", "Advanced", "Elite", "Void", "Robux"},
    CurrentOption = {"Basic"},
    Flag = "CrateType",
    Callback = function(v) State.crateType = v[1] or v end,
})

FarmTab:CreateSection("Fusion")

FarmTab:CreateToggle({
    Name = "Auto-Fuse (fuse all duplicates)",
    CurrentValue = false,
    Flag = "AutoFuse",
    Callback = function(v) State.autoFuse = v end,
})

FarmTab:CreateButton({
    Name = "Fuse All Duplicates Now",
    Callback = function()
        task.spawn(function()
            pcall(function()
                local inv = getInventory()
                if not inv or not inv.planets then return end
                local groups = {}
                for _, planet in ipairs(inv.planets) do
                    if planet.canFuse then
                        local key = planet.baseName .. "_" .. planet.tier
                        if not groups[key] then groups[key] = {} end
                        table.insert(groups[key], planet.index)
                    end
                end
                local fused = 0
                for _, indices in pairs(groups) do
                    while #indices >= 3 do
                        pcall(function()
                            FuseRequest:FireServer({indices[1], indices[2], indices[3]})
                            fused = fused + 1
                        end)
                        table.remove(indices, 3)
                        table.remove(indices, 2)
                        table.remove(indices, 1)
                        task.wait(0.3)
                    end
                end
                pcall(function()
                    Rayfield:Notify({
                        Title = "Fusion Complete",
                        Content = "Fused " .. fused .. " sets!",
                        Duration = 4,
                    })
                end)
            end)
        end)
    end,
})

-- ═══════════════════════════════════════════
-- TAB: TELEPORT
-- ═══════════════════════════════════════════
local TPTab = Window:CreateTab("🗺️ Teleport", 0)

TPTab:CreateSection("Locations")

TPTab:CreateButton({
    Name = "Teleport to My Plot",
    Callback = function()
        local plot = getMyPlot()
        if plot then
            local spawn = plot:FindFirstChild("Spawn")
            local hrp = getHRP()
            if spawn and hrp then
                hrp.CFrame = CFrame.new(spawn.Position + Vector3.new(0, 3, 0))
            end
        end
    end,
})

TPTab:CreateButton({
    Name = "Teleport to Spawn Island",
    Callback = function()
        local tp = Workspace:FindFirstChild("TpPart")
        local hrp = getHRP()
        if tp and hrp then
            hrp.CFrame = CFrame.new(tp.Position + Vector3.new(0, 3, 0))
        end
    end,
})

TPTab:CreateButton({
    Name = "Teleport to Area 2",
    Callback = function()
        local tp = Workspace:FindFirstChild("Tp2Part")
        local hrp = getHRP()
        if tp and hrp then
            hrp.CFrame = CFrame.new(tp.Position + Vector3.new(0, 3, 0))
        end
    end,
})

TPTab:CreateButton({
    Name = "Teleport to Area 3",
    Callback = function()
        local tp = Workspace:FindFirstChild("Tp3Part")
        local hrp = getHRP()
        if tp and hrp then
            hrp.CFrame = CFrame.new(tp.Position + Vector3.new(0, 3, 0))
        end
    end,
})

TPTab:CreateButton({
    Name = "Teleport to Black Hole",
    Callback = function()
        local map = Workspace:FindFirstChild("Map")
        local bh = map and map:FindFirstChild("BlackHole")
        local hrp = getHRP()
        if bh and hrp then
            local part = bh:IsA("BasePart") and bh or bh:FindFirstChildWhichIsA("BasePart")
            if part then
                hrp.CFrame = CFrame.new(part.Position + Vector3.new(0, 5, 0))
            end
        end
    end,
})

TPTab:CreateButton({
    Name = "Teleport to Cannon",
    Callback = function()
        local map = Workspace:FindFirstChild("Map")
        local cannon = map and map:FindFirstChild("Cannon")
        local hrp = getHRP()
        if cannon and hrp then
            local part = cannon:FindFirstChildWhichIsA("BasePart")
            if part then
                hrp.CFrame = CFrame.new(part.Position + Vector3.new(0, 5, 0))
            end
        end
    end,
})

-- ═══════════════════════════════════════════
-- TAB: MISC
-- ═══════════════════════════════════════════
local MiscTab = Window:CreateTab("⚙️ Misc", 0)

MiscTab:CreateSection("Stats Overlay")

local overlayEnabled = true
MiscTab:CreateToggle({
    Name = "Show Stats Overlay",
    CurrentValue = true,
    Flag = "StatsOverlay",
    Callback = function(v) overlayEnabled = v end,
})

MiscTab:CreateSection("Destruction")

MiscTab:CreateButton({
    Name = "Destroy All Connections (Panic)",
    Callback = function()
        for _, conn in ipairs(connections) do
            pcall(function() conn:Disconnect() end)
        end
        connections = {}
        getgenv()._starforgeLoaded = nil
        pcall(function() Rayfield:Destroy() end)
    end,
})

-- ═══════════════════════════════════════════
-- BACKGROUND LOOPS
-- ═══════════════════════════════════════════

-- SPEED HACK
track(RunService.Heartbeat:Connect(function()
    if not State.speedHack then return end
    pcall(function()
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 16 * State.speedMult end
    end)
end))

-- INFINITE JUMP
track(game:GetService("UserInputService").JumpRequest:Connect(function()
    if not State.infiniteJump then return end
    pcall(function()
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end)
end))

-- NOCLIP
track(RunService.Stepped:Connect(function()
    if not State.noclip then return end
    pcall(function()
        if LP.Character then
            for _, part in ipairs(LP.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
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

-- AUTO-COLLECT STORED COINS
do
    local lastTick = 0
    track(RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - lastTick < 5 then return end
        lastTick = now
        if not State.autoCollect then return end
        pcall(function()
            SellInventory:FireServer()
        end)
    end))
end

-- AUTO-OPEN CRATES
do
    local lastTick = 0
    track(RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - lastTick < 0.5 then return end
        lastTick = now
        if not State.autoOpenCrate then return end
        pcall(function()
            OpenCrate:FireServer(State.crateType)
        end)
    end))
end

-- AUTO-FUSE
do
    local lastTick = 0
    local fusing = false
    track(RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - lastTick < 10 then return end
        lastTick = now
        if not State.autoFuse or fusing then return end
        fusing = true

        task.spawn(function()
            pcall(function()
                local inv = getInventory()
                if not inv or not inv.planets then fusing = false return end
                local groups = {}
                for _, planet in ipairs(inv.planets) do
                    if planet.canFuse then
                        local key = planet.baseName .. "_" .. planet.tier
                        if not groups[key] then groups[key] = {} end
                        table.insert(groups[key], planet.index)
                    end
                end
                for _, indices in pairs(groups) do
                    while #indices >= 3 do
                        pcall(function()
                            FuseRequest:FireServer({indices[1], indices[2], indices[3]})
                        end)
                        table.remove(indices, 3)
                        table.remove(indices, 2)
                        table.remove(indices, 1)
                        task.wait(0.3)
                    end
                end
            end)
            fusing = false
        end)
    end))
end

-- ═══════════════════════════════════════════
-- STATS OVERLAY
-- ═══════════════════════════════════════════
do
    local overlay = Instance.new("ScreenGui")
    overlay.Name = "StarForgeOverlay"
    overlay.ResetOnSpawn = false
    overlay.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local frame = Instance.new("Frame", overlay)
    frame.Name = "StatsFrame"
    frame.Size = UDim2.new(0, 200, 0, 90)
    frame.Position = UDim2.new(1, -10, 0, 10)
    frame.AnchorPoint = Vector2.new(1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(15, 10, 30)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

    local title = Instance.new("TextLabel", frame)
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 20)
    title.Position = UDim2.new(0, 0, 0, 2)
    title.BackgroundTransparency = 1
    title.Text = "⭐ StarForge"
    title.TextColor3 = Color3.fromRGB(255, 215, 0)
    title.TextSize = 14
    title.Font = Enum.Font.GothamBold

    local info = Instance.new("TextLabel", frame)
    info.Name = "Info"
    info.Size = UDim2.new(1, -10, 1, -24)
    info.Position = UDim2.new(0, 5, 0, 22)
    info.BackgroundTransparency = 1
    info.TextColor3 = Color3.fromRGB(200, 200, 220)
    info.TextSize = 11
    info.Font = Enum.Font.Gotham
    info.TextXAlignment = Enum.TextXAlignment.Left
    info.TextYAlignment = Enum.TextYAlignment.Top

    pcall(function() overlay.Parent = gethui() end)
    if not overlay.Parent then overlay.Parent = LP.PlayerGui end

    track(RunService.Heartbeat:Connect(function()
        frame.Visible = overlayEnabled
        if not overlayEnabled then return end
        pcall(function()
            local coins = LP.leaderstats.Coins.Value
            local cps = LP.leaderstats.CPS.Value
            local lvl = LP.Stats.Lvl.Value

            local lines = {
                "💰 Coins: " .. tostring(coins),
                "⚡ CPS: " .. tostring(cps),
                "📊 Level: " .. tostring(lvl),
            }

            local inv = getInventory()
            if inv and inv.planets then
                lines[#lines + 1] = "🪐 Planets: " .. #inv.planets
            end

            info.Text = table.concat(lines, "\n")
        end)
    end))
end

-- ═══════════════════════════════════════════
-- NOTIFY
-- ═══════════════════════════════════════════
pcall(function()
    Rayfield:Notify({
        Title = "StarForge v1 Loaded",
        Content = "Make a Galaxy! exploit ready",
        Duration = 4,
    })
end)

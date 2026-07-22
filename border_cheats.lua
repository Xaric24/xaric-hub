--[[
    ╔═══════════════════════════════════════════════════════╗
    ║  Coyote v1 — San Diego Border Roleplay Exploit       ║
    ║  Xaric Hub Module                                    ║
    ╚═══════════════════════════════════════════════════════╝
]]

if getgenv()._coyoteLoaded then return end
getgenv()._coyoteLoaded = true

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
-- REMOTE REFS (lazy-find by service folder)
-- ═══════════════════════════════════════════
local function findRemote(serviceName, remoteName)
    for _, d in ipairs(ReplicatedStorage:GetDescendants()) do
        if d.Name == remoteName and d.Parent.Name == serviceName then return d end
    end
    return nil
end

local GateToggle    = findRemote("GateService", "ToggleGate")
local ToggleLocked  = findRemote("VehicleService", "ToggleLocked")
local SetVState     = findRemote("VehicleService", "SetVehicleState")
local UnstuckVeh    = findRemote("VehicleService", "UnstuckVehicle")
local SpawnVehicle  = findRemote("VehicleSpawnerService", "SpawnVehicleFromSpawner")
local PurchaseVeh   = findRemote("VehicleSpawnerService", "PurchaseVehicle")
local GrantEntry    = findRemote("BorderAuthorisationService", "GrantEntry")
local SendToInspec  = findRemote("BorderAuthorisationService", "SendToInspection")
local ShowPassport  = findRemote("Passport", "ShowPassport")
local HidePassport  = findRemote("Passport", "HidePassport")
local ClaimDaily    = findRemote("DailyRewardService", "ClaimDailyReward")
local Transfer      = findRemote("ATMService", "Transfer")
local RadioMsg      = findRemote("ChatService", "SendRadioMessage")
local SetSetting    = findRemote("PlayerSettingsService", "SetSetting")
local PurchaseItem  = findRemote("WorldBuyableItemService", "PurchaseWorldBuyableItem")

-- Robbery / Grinding remotes
local BeginRobTrolley  = findRemote("BankRobbery", "BeginRobTrolley")
local StartRobTrolley  = findRemote("BankRobbery", "StartRobTrolley")
local GrabTrolleyCash  = findRemote("BankRobbery", "GrabTrolleyCash")
local StopRobTrolley   = findRemote("BankRobbery", "StopRobTrolley")
local ReserveCabinet   = findRemote("JewelleryStoreService", "ReserveCabinet")
local BeginCabinet     = findRemote("JewelleryStoreService", "BeginCabinet")
local HitCabinet       = findRemote("JewelleryStoreService", "HitCabinet")
local GrabItem         = findRemote("JewelleryStoreService", "GrabItem")
local FetchBox         = findRemote("BoxJobService", "FetchBox")
local DeliverBox       = findRemote("BoxJobService", "DeliverBox")
local SellSmuggled     = findRemote("SmuggleService", "SellSmuggledGoods")
local LaunderBriefcase = findRemote("SmuggleService", "LaunderBriefcase")
local KickDoor         = findRemote("SmallHouseRobberyService", "KickDoor")
local BeginDoorBreach  = findRemote("SmallHouseRobberyService", "BeginDoorBreach")
local StartDoorBreach  = findRemote("SmallHouseRobberyService", "StartDoorBreach")
local ReserveBreakSafe = findRemote("SmallHouseRobberyService", "ReserveBreakSafe")
local BeginBreakSafe   = findRemote("SmallHouseRobberyService", "BeginBreakSafe")
local PressBreakSafe   = findRemote("SmallHouseRobberyService", "PressBreakSafe")
local GrabSafeCash     = findRemote("SmallHouseRobberyService", "GrabSafeCash")
local StartMission     = findRemote("TruckService", "StartMission")
local SpeakToTrucker   = findRemote("TruckService", "SpeakToTrucker")

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

local function tpTo(pos)
    local hrp = getHRP()
    if hrp then hrp.CFrame = CFrame.new(pos) end
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
    godMode         = false,
    esp             = false,
    fullbright      = false,
    -- Grind
    autoRobBank     = false,
    autoJewellery   = false,
    autoBoxJob      = false,
    autoSellSmuggle = false,
}
getgenv()._coyoteState = State

-- ═══════════════════════════════════════════
-- TELEPORT LOCATIONS
-- ═══════════════════════════════════════════
local TP_LOCATIONS = {
    ["Civilian Spawn"]  = Vector3.new(6893, 15, -35),
    ["Black Market"]    = Vector3.new(6800, 21, -2),
    ["Free Gun"]        = Vector3.new(6834, 17, -27),
    ["El Capo"]         = Vector3.new(7422, 15, 30),
    ["Bank"]            = Vector3.new(-273, 18, -227),
    ["Jewellery Store"] = Vector3.new(-45, 22, 925),
    ["Jail"]            = Vector3.new(-1480, -44, -4505),
    ["Tunnel"]          = Vector3.new(3010, -44, -1203),
    ["Petrol Station"]  = Vector3.new(6892, 57, 209),
    ["Truck Spawn"]     = Vector3.new(7163, 63, 229),
}

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
    Name              = "🐺 Coyote v1",
    Icon              = 0,
    LoadingTitle      = "Coyote v1",
    LoadingSubtitle   = "San Diego Border RP",
    Theme             = "DarkBlue",
    DisableRayfieldPrompts = true,
    DisableBuildWarnings   = true,
    ConfigurationSaving = {
        Enabled    = true,
        FolderName = "Coyote",
        FileName   = "config",
    },
    KeySystem = false,
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

PlayerTab:CreateSection("Combat")

PlayerTab:CreateToggle({
    Name = "God Mode (set MaxHealth huge)",
    CurrentValue = false,
    Flag = "GodMode",
    Callback = function(v) State.godMode = v end,
})

PlayerTab:CreateSection("Utility")

PlayerTab:CreateToggle({
    Name = "Anti-AFK",
    CurrentValue = true,
    Flag = "AntiAFK",
    Callback = function(v) State.antiAFK = v end,
})

-- ═══════════════════════════════════════════
-- TAB: TELEPORT
-- ═══════════════════════════════════════════
local TPTab = Window:CreateTab("🗺️ Teleport", 0)

TPTab:CreateSection("Locations")

-- Build sorted location names
local locationNames = {}
for name, _ in pairs(TP_LOCATIONS) do
    table.insert(locationNames, name)
end
table.sort(locationNames)

TPTab:CreateDropdown({
    Name = "Teleport To Location",
    Options = locationNames,
    CurrentOption = {locationNames[1]},
    Flag = "TPLocation",
    Callback = function(v)
        local name = type(v) == "table" and v[1] or v
        local pos = TP_LOCATIONS[name]
        if pos then tpTo(pos + Vector3.new(0, 3, 0)) end
    end,
})

TPTab:CreateSection("Player Teleport")

TPTab:CreateDropdown({
    Name = "Teleport To Player",
    Options = (function()
        local names = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP then table.insert(names, p.Name) end
        end
        return names
    end)(),
    CurrentOption = {},
    Flag = "TPPlayer",
    Callback = function(v)
        local name = type(v) == "table" and v[1] or v
        local target = Players:FindFirstChild(name)
        if target and target.Character then
            local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
            if tHRP then tpTo(tHRP.Position + Vector3.new(0, 3, 0)) end
        end
    end,
})

-- ═══════════════════════════════════════════
-- TAB: VEHICLE
-- ═══════════════════════════════════════════
local VehTab = Window:CreateTab("🚗 Vehicle", 0)

VehTab:CreateSection("Vehicle Actions")

VehTab:CreateButton({
    Name = "Unstuck Current Vehicle",
    Callback = function()
        pcall(function() UnstuckVeh:FireServer() end)
    end,
})

VehTab:CreateButton({
    Name = "Toggle Vehicle Lock",
    Callback = function()
        pcall(function() ToggleLocked:InvokeServer() end)
    end,
})

VehTab:CreateButton({
    Name = "Infinite Vehicle Fuel (visual)",
    Callback = function()
        task.spawn(function()
            pcall(function()
                local vFolder = Workspace:FindFirstChild("Vehicles")
                if not vFolder then return end
                for _, v in ipairs(vFolder:GetChildren()) do
                    local fuel = v:FindFirstChild("Fuel") or v:FindFirstChild("fuel")
                    if fuel and fuel:IsA("ValueBase") then
                        fuel.Value = 100
                    end
                end
            end)
        end)
    end,
})

-- ═══════════════════════════════════════════
-- TAB: VISUALS
-- ═══════════════════════════════════════════
local VisTab = Window:CreateTab("👁️ Visuals", 0)

VisTab:CreateSection("ESP")

VisTab:CreateToggle({
    Name = "Player ESP",
    CurrentValue = false,
    Flag = "ESP",
    Callback = function(v) State.esp = v end,
})

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

-- ═══════════════════════════════════════════
-- TAB: BORDER
-- ═══════════════════════════════════════════
local BorderTab = Window:CreateTab("🛃 Border", 0)

BorderTab:CreateSection("Gates")

BorderTab:CreateButton({
    Name = "Open All Gates",
    Callback = function()
        task.spawn(function()
            pcall(function()
                local gates = Workspace:FindFirstChild("Gates")
                if not gates then return end
                for _, gate in ipairs(gates:GetChildren()) do
                    pcall(function() GateToggle:InvokeServer(gate, true) end)
                    task.wait(0.1)
                end
            end)
        end)
    end,
})

BorderTab:CreateButton({
    Name = "Show Passport",
    Callback = function()
        pcall(function() ShowPassport:FireServer() end)
    end,
})

BorderTab:CreateButton({
    Name = "Claim Daily Reward",
    Callback = function()
        pcall(function()
            local ok, result = pcall(function() return ClaimDaily:InvokeServer() end)
            pcall(function()
                Rayfield:Notify({
                    Title = "Daily Reward",
                    Content = ok and tostring(result) or "Claimed!",
                    Duration = 3,
                })
            end)
        end)
    end,
})

-- ═══════════════════════════════════════════
-- TAB: GRIND
-- ═══════════════════════════════════════════
local GrindTab = Window:CreateTab("💰 Grind", 0)

GrindTab:CreateSection("Bank Robbery")

GrindTab:CreateToggle({
    Name = "Auto-Rob Bank Trolleys",
    CurrentValue = false,
    Flag = "AutoRobBank",
    Callback = function(v) State.autoRobBank = v end,
})

GrindTab:CreateButton({
    Name = "Teleport to Bank Vault",
    Callback = function()
        tpTo(Vector3.new(-277, 16, -249))
    end,
})

GrindTab:CreateSection("Jewellery Store")

GrindTab:CreateToggle({
    Name = "Auto-Rob Jewellery Cabinets",
    CurrentValue = false,
    Flag = "AutoJewellery",
    Callback = function(v) State.autoJewellery = v end,
})

GrindTab:CreateButton({
    Name = "Teleport to Jewellery Store",
    Callback = function()
        tpTo(Vector3.new(-45, 22, 925))
    end,
})

GrindTab:CreateSection("Box Delivery")

GrindTab:CreateToggle({
    Name = "Auto-Box Delivery (fetch → deliver loop)",
    CurrentValue = false,
    Flag = "AutoBoxJob",
    Callback = function(v) State.autoBoxJob = v end,
})

GrindTab:CreateSection("Smuggling")

GrindTab:CreateToggle({
    Name = "Auto-Sell Smuggled Goods",
    CurrentValue = false,
    Flag = "AutoSellSmuggle",
    Callback = function(v) State.autoSellSmuggle = v end,
})

GrindTab:CreateButton({
    Name = "Sell Smuggled Goods Now",
    Callback = function()
        pcall(function() SellSmuggled:FireServer() end)
    end,
})

GrindTab:CreateButton({
    Name = "Launder Briefcase Now",
    Callback = function()
        pcall(function() LaunderBriefcase:FireServer() end)
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
        getgenv()._coyoteLoaded = nil
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
        local hum = getHumanoid()
        if hum then hum.WalkSpeed = 12 * State.speedMult end
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
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end)
end))

-- GOD MODE
track(RunService.Heartbeat:Connect(function()
    if not State.godMode then return end
    pcall(function()
        local hum = getHumanoid()
        if hum then
            hum.MaxHealth = math.huge
            hum.Health = math.huge
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

-- AUTO-ROB BANK TROLLEYS
do
    local robbing = false
    local lastTick = 0
    track(RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - lastTick < 2 then return end
        lastTick = now
        if not State.autoRobBank or robbing then return end
        robbing = true

        task.spawn(function()
            pcall(function()
                local bank = Workspace:FindFirstChild("Bank")
                if not bank then robbing = false return end

                -- TP to bank if far away
                local hrp = getHRP()
                if hrp and (hrp.Position - Vector3.new(-277, 16, -249)).Magnitude > 50 then
                    tpTo(Vector3.new(-277, 16, -249))
                    task.wait(1)
                end

                for _, trolley in ipairs(bank:GetChildren()) do
                    if not State.autoRobBank then break end
                    if trolley.Name == "Trolley" then
                        pcall(function()
                            local result = BeginRobTrolley:InvokeServer(trolley)
                            task.wait(0.3)
                            StartRobTrolley:InvokeServer(trolley)
                            task.wait(0.5)
                            for i = 1, 10 do
                                if not State.autoRobBank then break end
                                pcall(function() GrabTrolleyCash:InvokeServer(trolley) end)
                                task.wait(0.3)
                            end
                            pcall(function() StopRobTrolley:InvokeServer(trolley) end)
                        end)
                        task.wait(0.5)
                    end
                end
            end)
            robbing = false
        end)
    end))
end

-- AUTO-ROB JEWELLERY CABINETS
do
    local robbing = false
    local lastTick = 0
    track(RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - lastTick < 2 then return end
        lastTick = now
        if not State.autoJewellery or robbing then return end
        robbing = true

        task.spawn(function()
            pcall(function()
                local store = Workspace:FindFirstChild("JewelleryStore")
                if not store then robbing = false return end

                -- TP to jewellery store if far
                local hrp = getHRP()
                if hrp and (hrp.Position - Vector3.new(-45, 22, 925)).Magnitude > 50 then
                    tpTo(Vector3.new(-45, 22, 925))
                    task.wait(1)
                end

                for _, folder in ipairs(store:GetChildren()) do
                    if not State.autoJewellery then break end
                    if folder.Name == "JewelleryCabinet" then
                        pcall(function()
                            ReserveCabinet:InvokeServer(folder)
                            task.wait(0.3)
                            BeginCabinet:InvokeServer(folder)
                            task.wait(0.3)
                            for i = 1, 15 do
                                if not State.autoJewellery then break end
                                local done = pcall(function() HitCabinet:InvokeServer(folder) end)
                                task.wait(0.2)
                            end
                            pcall(function() GrabItem:InvokeServer(folder) end)
                        end)
                        task.wait(0.5)
                    end
                end
            end)
            robbing = false
        end)
    end))
end

-- AUTO-BOX DELIVERY
do
    local delivering = false
    local lastTick = 0
    local FETCH_POS = Vector3.new(-17.5, 18.1, -70.3)
    local DELIVER_POS = Vector3.new(5.8, 16.5, -48.0)

    track(RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - lastTick < 3 then return end
        lastTick = now
        if not State.autoBoxJob or delivering then return end
        delivering = true

        task.spawn(function()
            pcall(function()
                -- TP to fetch
                tpTo(FETCH_POS + Vector3.new(0, 3, 0))
                task.wait(1)
                FetchBox:FireServer()
                task.wait(2)

                -- TP to deliver
                tpTo(DELIVER_POS + Vector3.new(0, 3, 0))
                task.wait(1)
                DeliverBox:FireServer()
                task.wait(1)
            end)
            delivering = false
        end)
    end))
end

-- AUTO-SELL SMUGGLED GOODS
do
    local lastTick = 0
    track(RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - lastTick < 5 then return end
        lastTick = now
        if not State.autoSellSmuggle then return end
        pcall(function() SellSmuggled:FireServer() end)
    end))
end

-- PLAYER ESP
do
    local espFolder = Instance.new("Folder")
    espFolder.Name = "CoyoteESP"
    espFolder.Parent = Workspace.CurrentCamera

    local function createESP(player)
        if player == LP then return end
        local highlight = Instance.new("Highlight")
        highlight.Name = "ESP_" .. player.Name
        highlight.FillColor = Color3.fromRGB(255, 50, 50)
        highlight.FillTransparency = 0.7
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.OutlineTransparency = 0.3
        highlight.Parent = espFolder

        local function attach()
            if player.Character then
                highlight.Adornee = player.Character
            end
        end
        attach()
        player.CharacterAdded:Connect(attach)

        -- Billboard for name + distance
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

        local function updateBB()
            if player.Character then
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
        end
        attach()

        track(RunService.Heartbeat:Connect(function()
            highlight.Enabled = State.esp
            bb.Enabled = State.esp
            if State.esp then updateBB() end
        end))
    end

    for _, p in ipairs(Players:GetPlayers()) do
        createESP(p)
    end
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
    overlay.Name = "CoyoteOverlay"
    overlay.ResetOnSpawn = false
    overlay.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local frame = Instance.new("Frame", overlay)
    frame.Name = "StatsFrame"
    frame.Size = UDim2.new(0, 200, 0, 100)
    frame.Position = UDim2.new(1, -10, 0, 10)
    frame.AnchorPoint = Vector2.new(1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(20, 15, 10)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

    local title = Instance.new("TextLabel", frame)
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 20)
    title.Position = UDim2.new(0, 0, 0, 2)
    title.BackgroundTransparency = 1
    title.Text = "🐺 Coyote"
    title.TextColor3 = Color3.fromRGB(230, 180, 80)
    title.TextSize = 14
    title.Font = Enum.Font.GothamBold

    local info = Instance.new("TextLabel", frame)
    info.Name = "Info"
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
        frame.Visible = overlayEnabled
        if not overlayEnabled then return end
        pcall(function()
            local hum = getHumanoid()
            local money = LP:FindFirstChild("ReplicatedStats")
            local moneyVal = money and money:FindFirstChild("Money")

            local wantedLvl = LP:GetAttribute("WantedLevel") or 0
            local rank = LP:GetAttribute("CurrentRankName") or "Unknown"
            local fromMX = LP:GetAttribute("FromMexico") and "Mexico" or "USA"
            local hp = hum and math.floor(hum.Health) or 0
            local maxHp = hum and math.floor(hum.MaxHealth) or 0

            local lines = {
                "💰 " .. (moneyVal and moneyVal.Value or "?"),
                "🏥 " .. hp .. "/" .. maxHp,
                "⭐ Wanted: " .. tostring(wantedLvl),
                "🎖️ " .. rank,
                "📍 " .. fromMX,
            }
            info.Text = table.concat(lines, "\n")
        end)
    end))
end

-- ═══════════════════════════════════════════
-- NOTIFY
-- ═══════════════════════════════════════════
pcall(function()
    Rayfield:Notify({
        Title = "Coyote v1 Loaded",
        Content = "San Diego Border RP exploit ready",
        Duration = 4,
    })
end)

--[[
    ╔═══════════════════════════════════════════════════════════╗
    ║  🌿 GreenThumb v1 — My Greenhouse! Exploit                ║
    ║  Auto-Collect · Auto-Sell · Greenhouse Harvest · ESP      ║
    ╚═══════════════════════════════════════════════════════════╝
]]

-- ═══════════════════════════════════════════
-- CLEANUP
-- ═══════════════════════════════════════════
if getgenv and getgenv()._greenthumbCleanup then
    pcall(getgenv()._greenthumbCleanup)
end
pcall(function()
    for _, g in ipairs(gethui():GetChildren()) do
        if g.Name == "Rayfield" then g:Destroy() end
    end
end)
pcall(function()
    local pg = game.Players.LocalPlayer:FindFirstChild("PlayerGui")
    if pg then
        local o = pg:FindFirstChild("GreenThumbOverlay")
        if o then o:Destroy() end
    end
end)
pcall(function()
    for _, bb in ipairs(game.Workspace:GetDescendants()) do
        if bb.Name == "GreenThumbESP" then bb:Destroy() end
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
-- GAME DATA (safe require)
-- ═══════════════════════════════════════════
local CropInfo, ProduceInfo, GreenhouseInfo, ItemInfo
pcall(function() CropInfo = require(ReplicatedStorage.CropInfo) end)
pcall(function() ProduceInfo = require(ReplicatedStorage.ProduceInfo) end)
pcall(function() GreenhouseInfo = require(ReplicatedStorage.GreenhouseInfo) end)
pcall(function() ItemInfo = require(ReplicatedStorage.ItemInfo) end)

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

local function getMyGreenhouse()
    local ghFolder = Workspace:FindFirstChild("Greenhouses")
    return ghFolder and ghFolder:FindFirstChild(LP.Name .. " Greenhouse")
end

local function getAllCollectables()
    local results = {}
    -- Area 1
    local area1 = Workspace:FindFirstChild("Area1Collectables")
    if area1 then
        for _, folder in ipairs(area1:GetChildren()) do
            for _, model in ipairs(folder:GetChildren()) do
                -- Find ClickDetector (could be in Hitbox child or direct)
                local cd
                for _, d in ipairs(model:GetDescendants()) do
                    if d:IsA("ClickDetector") then cd = d break end
                end
                if cd then
                    local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
                    table.insert(results, {
                        model = model,
                        name = folder.Name,
                        clickDetector = cd,
                        position = part and part.Position,
                        area = "Area1",
                    })
                end
            end
        end
    end
    -- Area 2
    local area2 = Workspace:FindFirstChild("Area2")
    if area2 then
        local a2c = area2:FindFirstChild("Area2Collectables")
        if a2c then
            for _, folder in ipairs(a2c:GetChildren()) do
                for _, model in ipairs(folder:GetChildren()) do
                    local cd
                    for _, d in ipairs(model:GetDescendants()) do
                        if d:IsA("ClickDetector") then cd = d break end
                    end
                    if cd then
                        local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
                        table.insert(results, {
                            model = model,
                            name = folder.Name,
                            clickDetector = cd,
                            position = part and part.Position,
                            area = "Area2",
                        })
                    end
                end
            end
        end
    end
    return results
end

local function getGreenhouseCrops()
    local myGH = getMyGreenhouse()
    if not myGH then return {} end
    local results = {}
    for _, child in ipairs(myGH:GetChildren()) do
        if child.Name:find("Grown") and child:IsA("Model") then
            local cd
            for _, d in ipairs(child:GetDescendants()) do
                if d:IsA("ClickDetector") then cd = d break end
            end
            local complete = child:GetAttribute("Complete")
            table.insert(results, {
                model = child,
                name = child.Name,
                complete = complete,
                clickDetector = cd,
                number = child:GetAttribute("Number"),
            })
        end
    end
    return results
end

local function getPlanters()
    local myGH = getMyGreenhouse()
    if not myGH then return {} end
    local results = {}
    for _, child in ipairs(myGH:GetChildren()) do
        if child.Name == "Planter" and child:IsA("Model") then
            table.insert(results, {
                model = child,
                number = child:GetAttribute("Number"),
                spawned = child:GetAttribute("Spawned"),
                plantInside = child:GetAttribute("PlantInside"),
                owner = child:GetAttribute("Owner"),
            })
        end
    end
    return results
end

local collectStats = {collected = 0, sold = 0}

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
    autoHarvest     = false,
    autoSell        = false,
    collectESP      = false,
    cropESP         = false,
    tpCollect       = false,
    autoQTE         = false,
}
getgenv()._greenthumbState = State

-- ═══════════════════════════════════════════
-- UI LIBRARY (Rayfield)
-- ═══════════════════════════════════════════
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name              = "🌿 GreenThumb v1",
    Icon              = 0,
    LoadingTitle      = "GreenThumb v1",
    LoadingSubtitle   = "My Greenhouse! Exploit",
    Theme             = "DarkBlue",
    DisableRayfieldPrompts = true,
    DisableBuildWarnings   = true,
    ConfigurationSaving = {
        Enabled    = true,
        FolderName = "GreenThumb",
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
local FarmTab = Window:CreateTab("🌾 Farm", 0)

FarmTab:CreateSection("Wild Collecting")

FarmTab:CreateToggle({
    Name = "Auto-Collect Wild (TP + Collect)",
    CurrentValue = false,
    Flag = "AutoCollect",
    Callback = function(v) State.autoCollect = v end,
})

FarmTab:CreateToggle({
    Name = "TP to Collectables",
    CurrentValue = false,
    Flag = "TPCollect",
    Callback = function(v) State.tpCollect = v end,
})

FarmTab:CreateToggle({
    Name = "Collectable ESP",
    CurrentValue = false,
    Flag = "CollectESP",
    Callback = function(v) State.collectESP = v end,
})

FarmTab:CreateSection("Greenhouse")

FarmTab:CreateToggle({
    Name = "Auto-Harvest Greenhouse Crops",
    CurrentValue = false,
    Flag = "AutoHarvest",
    Callback = function(v) State.autoHarvest = v end,
})

FarmTab:CreateToggle({
    Name = "Crop ESP (Greenhouse)",
    CurrentValue = false,
    Flag = "CropESP",
    Callback = function(v) State.cropESP = v end,
})

FarmTab:CreateSection("Minigames")

FarmTab:CreateToggle({
    Name = "Auto-QTE (Flowers / Bar / Mushrooms)",
    CurrentValue = false,
    Flag = "AutoQTE",
    Callback = function(v) State.autoQTE = v end,
})

FarmTab:CreateSection("Selling")

FarmTab:CreateToggle({
    Name = "Auto-Sell (fires Sell remote)",
    CurrentValue = false,
    Flag = "AutoSell",
    Callback = function(v) State.autoSell = v end,
})

FarmTab:CreateSection("Quick Actions")

FarmTab:CreateButton({
    Name = "Collect All Wild NOW",
    Callback = function()
        task.spawn(function()
            local collectables = getAllCollectables()
            local hrp = getHRP()
            if not hrp then return end
            local origCF = hrp.CFrame
            for _, c in ipairs(collectables) do
                pcall(function()
                    if c.position then
                        hrp.CFrame = CFrame.new(c.position)
                        task.wait(0.1)
                    end
                    fireclickdetector(c.clickDetector)
                    collectStats.collected = collectStats.collected + 1
                end)
                task.wait(0.15)
            end
            hrp.CFrame = origCF
        end)
    end,
})

FarmTab:CreateButton({
    Name = "Harvest All Greenhouse NOW",
    Callback = function()
        task.spawn(function()
            local crops = getGreenhouseCrops()
            for _, crop in ipairs(crops) do
                if crop.clickDetector then
                    pcall(function()
                        fireclickdetector(crop.clickDetector)
                        collectStats.collected = collectStats.collected + 1
                    end)
                    task.wait(0.15)
                end
            end
        end)
    end,
})

FarmTab:CreateButton({
    Name = "Sell All NOW",
    Callback = function()
        pcall(function()
            ReplicatedStorage.Sell:FireServer()
            collectStats.sold = collectStats.sold + 1
        end)
    end,
})

FarmTab:CreateButton({
    Name = "🎁 Redeem All Codes",
    Callback = function()
        task.spawn(function()
            local CODES = {
                "GEMSTRAWBERRY",
                "RELEASE",
                "GREENHOUSE",
                "THANKYOU",
                "1KLIKES",
                "5KLIKES",
                "10KLIKES",
                "25KLIKES",
                "50KLIKES",
                "100KLIKES",
                "SORRY",
                "UPDATE1",
                "UPDATE2",
                "UPDATE3",
                "NEWGREENHOUSE",
                "STARDUST",
                "AREA2",
                "FOREST",
                "FREESTUFF",
                "SEEDS",
                "SUMMER",
                "SPRING",
                "WINTER",
                "AUTUMN",
            }
            local redeemed = 0
            for _, code in ipairs(CODES) do
                pcall(function()
                    ReplicatedStorage.SubmitCode:FireServer(code)
                    redeemed = redeemed + 1
                end)
                task.wait(0.5)
            end
            pcall(function()
                Rayfield:Notify({
                    Title = "Codes Redeemed",
                    Content = "Fired " .. redeemed .. "/" .. #CODES .. " codes!",
                    Duration = 4,
                })
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
    Name = "TP to My Greenhouse",
    Callback = function()
        pcall(function()
            local ghSpawns = Workspace:FindFirstChild("GreenhouseSpawns")
            for _, c in ipairs(ghSpawns:GetChildren()) do
                if c:GetAttribute("Claimed") == LP.Name then
                    local hrp = getHRP()
                    if hrp then hrp.CFrame = CFrame.new(c.Position + Vector3.new(0, 5, 0)) end
                    break
                end
            end
        end)
    end,
})

TPTab:CreateButton({
    Name = "TP to Sell Area",
    Callback = function()
        pcall(function()
            -- Find the sell proximity prompt NPC area
            local ppFolder = Workspace:FindFirstChild("ProximityPrompts")
            if ppFolder then
                for _, c in ipairs(ppFolder:GetChildren()) do
                    if c:IsA("BasePart") then
                        local hrp = getHRP()
                        if hrp then hrp.CFrame = CFrame.new(c.Position + Vector3.new(0, 3, 0)) end
                        break
                    end
                end
            end
        end)
    end,
})

TPTab:CreateButton({
    Name = "TP to Forest",
    Callback = function()
        pcall(function()
            local tps = Workspace:FindFirstChild("Teleports")
            local tp = tps and tps:FindFirstChild("ForestTeleport")
            if tp and tp:IsA("BasePart") then
                local hrp = getHRP()
                if hrp then hrp.CFrame = CFrame.new(tp.Position + Vector3.new(0, 3, 0)) end
            end
        end)
    end,
})

TPTab:CreateButton({
    Name = "TP to Nearest Collectable",
    Callback = function()
        pcall(function()
            local hrp = getHRP()
            if not hrp then return end
            local collectables = getAllCollectables()
            local nearest, dist = nil, math.huge
            for _, c in ipairs(collectables) do
                if c.position then
                    local d = (c.position - hrp.Position).Magnitude
                    if d < dist then nearest = c; dist = d end
                end
            end
            if nearest and nearest.position then
                hrp.CFrame = CFrame.new(nearest.position + Vector3.new(0, 3, 0))
            end
        end)
    end,
})

-- ═══════════════════════════════════════════
-- TAB: INFO
-- ═══════════════════════════════════════════
local InfoTab = Window:CreateTab("📊 Info", 0)

InfoTab:CreateSection("Greenhouse")

local ghLabel = InfoTab:CreateLabel("Loading...")
local planterLabel = InfoTab:CreateLabel("Loading...")
local cropLabel = InfoTab:CreateLabel("Loading...")

InfoTab:CreateSection("Wild Collectables")

local wildLabel = InfoTab:CreateLabel("Loading...")

InfoTab:CreateSection("Stats")

local statsLabel = InfoTab:CreateLabel("Collected: 0  |  Sold: 0")

InfoTab:CreateButton({
    Name = "Refresh Info",
    Callback = function()
        pcall(function()
            local myGH = getMyGreenhouse()
            ghLabel:Set("Greenhouse: " .. (myGH and myGH.Name or "Not found"))

            local planters = getPlanters()
            local planterStr = ""
            for _, p in ipairs(planters) do
                planterStr = planterStr .. string.format("#%s %s  ", tostring(p.number), p.plantInside and "🌱" or "⬜")
            end
            planterLabel:Set("Planters: " .. (planterStr ~= "" and planterStr or "None"))

            local crops = getGreenhouseCrops()
            local readyCount = 0
            for _, c in ipairs(crops) do
                if c.complete then readyCount = readyCount + 1 end
            end
            cropLabel:Set(string.format("Crops: %d total, %d ready 🟢", #crops, readyCount))

            local collectables = getAllCollectables()
            wildLabel:Set("Wild collectables: " .. #collectables)

            statsLabel:Set(string.format("Collected: %d  |  Sold: %d", collectStats.collected, collectStats.sold))
        end)
    end,
})

-- Initial info load
task.spawn(function()
    task.wait(1)
    pcall(function()
        local myGH = getMyGreenhouse()
        ghLabel:Set("Greenhouse: " .. (myGH and myGH.Name or "Not found"))
        local planters = getPlanters()
        planterLabel:Set("Planters: " .. #planters .. " total")
        local crops = getGreenhouseCrops()
        cropLabel:Set("Crops: " .. #crops .. " in greenhouse")
        local collectables = getAllCollectables()
        wildLabel:Set("Wild collectables: " .. #collectables)
    end)
end)

-- ═══════════════════════════════════════════
-- BACKGROUND LOOPS
-- ═══════════════════════════════════════════

-- SPEED HACK
do
    local DEFAULT_SPEED = 20
    track(RunService.Heartbeat:Connect(function()
        if not State.speedHack then return end
        pcall(function()
            local hum = getHumanoid()
            if hum then hum.WalkSpeed = DEFAULT_SPEED * State.speedMult end
        end)
    end))
end

-- NOCLIP
do
    track(RunService.Stepped:Connect(function()
        if not State.noclip then return end
        pcall(function()
            local char = LP.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
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

-- AUTO-COLLECT WILD (TP to each, click, return)
do
    local lastTick = 0
    local collecting = false
    track(RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - lastTick < 2 then return end
        lastTick = now
        if not State.autoCollect or collecting then return end
        collecting = true

        task.spawn(function()
            pcall(function()
                local collectables = getAllCollectables()
                local hrp = getHRP()
                if not hrp or #collectables == 0 then
                    collecting = false
                    return
                end

                local origCF = hrp.CFrame

                for _, c in ipairs(collectables) do
                    if not State.autoCollect then break end
                    pcall(function()
                        if State.tpCollect and c.position then
                            hrp.CFrame = CFrame.new(c.position)
                            task.wait(0.1)
                        end
                        fireclickdetector(c.clickDetector)
                        collectStats.collected = collectStats.collected + 1
                    end)
                    task.wait(0.15)
                end

                if State.tpCollect then
                    hrp.CFrame = origCF
                end
            end)
            collecting = false
        end)
    end))
end

-- AUTO-HARVEST GREENHOUSE
do
    local lastTick = 0
    track(RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - lastTick < 3 then return end
        lastTick = now
        if not State.autoHarvest then return end

        pcall(function()
            local crops = getGreenhouseCrops()
            for _, crop in ipairs(crops) do
                if crop.clickDetector and crop.complete then
                    pcall(function()
                        fireclickdetector(crop.clickDetector)
                        collectStats.collected = collectStats.collected + 1
                    end)
                    task.wait(0.15)
                end
            end
        end)
    end))
end

-- AUTO-SELL
do
    local lastTick = 0
    track(RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - lastTick < 5 then return end
        lastTick = now
        if not State.autoSell then return end
        pcall(function()
            ReplicatedStorage.Sell:FireServer()
            collectStats.sold = collectStats.sold + 1
        end)
    end))
end

-- AUTO-QTE (Wildflower / Mushroom / BarTarget minigames)
do
    local lastTick = 0
    track(RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - lastTick < 0.15 then return end
        lastTick = now
        if not State.autoQTE then return end

        pcall(function()
            local pg = LP.PlayerGui

            -- 1) WildflowerMinigame: click any ImageButton/TextButton that spawns in GameFrame
            local wfMG = pg:FindFirstChild("WildflowerMinigame")
            if wfMG and wfMG.Enabled then
                local gameFrame = wfMG:FindFirstChild("GameFrame")
                if gameFrame then
                    for _, child in ipairs(gameFrame:GetChildren()) do
                        if (child:IsA("ImageButton") or child:IsA("TextButton")) and child.Visible then
                            pcall(function()
                                -- Virtual click via firesignal or direct invoke
                                if firesignal then
                                    firesignal(child.MouseButton1Click)
                                elseif child.MouseButton1Click then
                                    child.MouseButton1Click:Fire()
                                end
                            end)
                        end
                    end
                end
            end

            -- 2) MushroomMinigame: click M1, M2, M3 buttons
            local mushMG = pg:FindFirstChild("MushroomMinigame")
            if mushMG and mushMG.Enabled then
                local gameFrame = mushMG:FindFirstChild("GameFrame")
                if gameFrame then
                    for _, btn in ipairs(gameFrame:GetChildren()) do
                        if (btn:IsA("ImageButton") or btn:IsA("TextButton")) and btn.Visible then
                            pcall(function()
                                if firesignal then
                                    firesignal(btn.MouseButton1Click)
                                elseif btn.MouseButton1Click then
                                    btn.MouseButton1Click:Fire()
                                end
                            end)
                        end
                    end
                end
            end

            -- 3) BarTargetMinigame: click the ClickDetector ImageButton + fire BarAccuracy
            local barMG = pg:FindFirstChild("BarTargetMinigame")
            if barMG and barMG.Enabled then
                local clickBtn = barMG:FindFirstChild("ClickDetector")
                if clickBtn and clickBtn:IsA("ImageButton") and clickBtn.Visible then
                    pcall(function()
                        if firesignal then
                            firesignal(clickBtn.MouseButton1Click)
                        elseif clickBtn.MouseButton1Click then
                            clickBtn.MouseButton1Click:Fire()
                        end
                    end)
                    -- Also fire BarAccuracy with perfect score
                    pcall(function()
                        ReplicatedStorage.BarAccuracy:FireServer(1)
                    end)
                end
            end
        end)
    end))
end

-- COLLECTABLE ESP
do
    local espParts = {}
    local lastTick = 0

    local function clearESP()
        for _, bb in ipairs(espParts) do pcall(function() bb:Destroy() end) end
        espParts = {}
    end

    track(RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - lastTick < 3 then return end
        lastTick = now

        if not State.collectESP then
            if #espParts > 0 then clearESP() end
            return
        end

        clearESP()
        local collectables = getAllCollectables()
        local hrp = getHRP()

        for _, c in ipairs(collectables) do
            pcall(function()
                local part = c.model.PrimaryPart or c.model:FindFirstChildWhichIsA("BasePart")
                if not part then return end

                local bb = Instance.new("BillboardGui")
                bb.Name = "GreenThumbESP"
                bb.Adornee = part
                bb.Size = UDim2.new(0, 110, 0, 36)
                bb.StudsOffset = Vector3.new(0, 3, 0)
                bb.AlwaysOnTop = true
                bb.Parent = part

                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(1, 0, 1, 0)
                label.BackgroundColor3 = Color3.fromRGB(60, 180, 80)
                label.BackgroundTransparency = 0.25
                label.TextColor3 = Color3.new(1, 1, 1)
                label.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
                label.TextSize = 12

                local dist = hrp and math.floor((part.Position - hrp.Position).Magnitude) or 0
                label.Text = "🌿 " .. c.name .. " [" .. dist .. "m]"
                label.Parent = bb
                Instance.new("UICorner", label).CornerRadius = UDim.new(0, 6)

                table.insert(espParts, bb)
            end)
        end
    end))
end

-- CROP ESP
do
    local espParts = {}
    local lastTick = 0

    local function clearESP()
        for _, bb in ipairs(espParts) do pcall(function() bb:Destroy() end) end
        espParts = {}
    end

    track(RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - lastTick < 3 then return end
        lastTick = now

        if not State.cropESP then
            if #espParts > 0 then clearESP() end
            return
        end

        clearESP()
        local crops = getGreenhouseCrops()

        for _, crop in ipairs(crops) do
            pcall(function()
                local part = crop.model.PrimaryPart or crop.model:FindFirstChildWhichIsA("BasePart")
                if not part then return end

                local bb = Instance.new("BillboardGui")
                bb.Name = "GreenThumbESP"
                bb.Adornee = part
                bb.Size = UDim2.new(0, 120, 0, 36)
                bb.StudsOffset = Vector3.new(0, 4, 0)
                bb.AlwaysOnTop = true
                bb.Parent = part

                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(1, 0, 1, 0)
                label.BackgroundColor3 = crop.complete and Color3.fromRGB(60, 200, 100) or Color3.fromRGB(200, 160, 40)
                label.BackgroundTransparency = 0.25
                label.TextColor3 = Color3.new(1, 1, 1)
                label.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
                label.TextSize = 12
                label.Text = (crop.complete and "🟢 " or "🟡 ") .. crop.name:gsub("Grown", "")
                label.Parent = bb
                Instance.new("UICorner", label).CornerRadius = UDim.new(0, 6)

                table.insert(espParts, bb)
            end)
        end
    end))
end

-- ═══════════════════════════════════════════
-- LIVE OVERLAY
-- ═══════════════════════════════════════════
pcall(function()
    local overlay = Instance.new("ScreenGui")
    overlay.Name = "GreenThumbOverlay"
    overlay.ResetOnSpawn = false
    overlay.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    pcall(function() overlay.Parent = LP:WaitForChild("PlayerGui") end)
    if not overlay.Parent then overlay.Parent = game:GetService("CoreGui") end

    local frame = Instance.new("Frame")
    frame.AnchorPoint = Vector2.new(1, 0)
    frame.Size = UDim2.new(0, 210, 0, 90)
    frame.Position = UDim2.new(1, -10, 0, 70)
    frame.BackgroundColor3 = Color3.fromRGB(12, 18, 12)
    frame.BackgroundTransparency = 0.15
    frame.BorderSizePixel = 0
    frame.Parent = overlay

    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(60, 180, 80)
    stroke.Thickness = 1.5
    stroke.Transparency = 0.3
    stroke.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 20)
    title.Position = UDim2.new(0, 0, 0, 2)
    title.BackgroundTransparency = 1
    title.Text = "🌿 GreenThumb"
    title.TextColor3 = Color3.fromRGB(80, 210, 100)
    title.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
    title.TextSize = 12
    title.Parent = frame

    local statsLabel = Instance.new("TextLabel")
    statsLabel.Size = UDim2.new(1, -14, 1, -24)
    statsLabel.Position = UDim2.new(0, 7, 0, 22)
    statsLabel.BackgroundTransparency = 1
    statsLabel.Text = "Loading..."
    statsLabel.TextColor3 = Color3.fromRGB(200, 210, 200)
    statsLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular)
    statsLabel.TextSize = 10
    statsLabel.TextXAlignment = Enum.TextXAlignment.Left
    statsLabel.TextYAlignment = Enum.TextYAlignment.Top
    statsLabel.TextWrapped = true
    statsLabel.Parent = frame

    local lastTick = 0
    track(RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - lastTick < 1.5 then return end
        lastTick = now
        pcall(function()
            local collectables = getAllCollectables()
            local crops = getGreenhouseCrops()
            local readyCount = 0
            for _, c in ipairs(crops) do
                if c.complete then readyCount = readyCount + 1 end
            end
            local zone = LP:GetAttribute("Zone") or "?"

            statsLabel.Text = string.format(
                "📍 %s\n🌿 Wild: %d  |  🌱 Crops: %d/%d ready\n📦 Collected: %d  |  💰 Sold: %d",
                zone,
                #collectables,
                readyCount, #crops,
                collectStats.collected,
                collectStats.sold
            )
        end)
    end))
end)

-- ═══════════════════════════════════════════
-- CLEANUP
-- ═══════════════════════════════════════════
getgenv()._greenthumbCleanup = function()
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
            local o = pg:FindFirstChild("GreenThumbOverlay")
            if o then o:Destroy() end
        end
    end)
    pcall(function()
        for _, bb in ipairs(Workspace:GetDescendants()) do
            if bb.Name == "GreenThumbESP" then bb:Destroy() end
        end
    end)
end

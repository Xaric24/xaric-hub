local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

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
local LP = Players.LocalPlayer

local State = {
    autoCollect = false,
    autoSell = false,
    autoSpin = false,
    autoEquip = false,
    autoUpgradeChipper = false,
    tpSpeed = 2 -- Delay between TPs to prevent glitching
}

-- Connections
local connections = {}
local function track(conn) table.insert(connections, conn) return conn end
local function clean() for _, c in ipairs(connections) do c:Disconnect() end end

getgenv()._timberLoaded = true

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
        task.spawn(function()
            fireproximityprompt(prompt, prompt.HoldDuration or 0)
        end)
    end
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
            local spawnPt = plot:FindFirstChild("SpawnPoint")
            if spawnPt then
                hrp.CFrame = spawnPt.CFrame + Vector3.new(0, 5, 0)
            end
        end
    end,
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
        if not getgenv()._timberLoaded then break end
        
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        local plot = getMyPlot()
        
        if hrp and plot then
            -- Collect
            if State.autoCollect then
                local holder = plot:FindFirstChild("WoodHolder", true)
                if holder then
                    hrp.CFrame = holder.CFrame * CFrame.new(0, 2, 0)
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
                if seller then
                    hrp.CFrame = seller.CFrame * CFrame.new(0, 2, 0)
                    task.wait(0.3)
                    for _, d in ipairs(seller:GetDescendants()) do
                        if d:IsA("ProximityPrompt") then firePrompt(d) end
                    end
                end
            end
        end
    end
end)

-- Background Loops (no TP required)
track(RunService.Heartbeat:Connect(function()
    if math.random() > 0.05 then return end -- throttle
    
    if State.autoSpin then
        pcall(function() RS.SpinFeature:FireServer("spin") end)
    end
    
    if State.autoEquip then
        pcall(function() RS.EquipBest:FireServer() end)
    end
    
    if State.autoUpgradeChipper then
        pcall(function() RS.ChipperAction:FireServer("upgrade") end)
    end
end))

Rayfield:LoadConfiguration()

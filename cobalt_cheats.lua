--[[
    ╔═══════════════════════════════════════════════════════════╗
    ║  Cobalt Cheats v3 — BE A FISH BAIT! [DELULU UPD]        ║
    ║  Fixed: proper Flamework Promise handling, Reflex state  ║
    ║  access, correct function arguments, inventory-aware     ║
    ╚═══════════════════════════════════════════════════════════╝
]]

local Env = (getgenv and getgenv()) or _G
if Env._cobaltCleanup then pcall(Env._cobaltCleanup) end

-- Cleanup (destroy ALL old CobaltCheats GUIs everywhere)
pcall(function()
    for _, desc in ipairs(game:GetService("CoreGui"):GetDescendants()) do
        if desc.Name == "CobaltCheats" and desc:IsA("ScreenGui") then
            desc:Destroy()
        end
    end
end)

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

-- Best GUI container: gethui() (executor-protected) > CoreGui
local GuiParent = (gethui and gethui()) or CoreGui

-- Flamework networking
local networkModule = require(LocalPlayer.PlayerScripts.TS.network)
local events = networkModule.events
local functions = networkModule.functions

-- Flamework DI → Reflex state
local Flamework = require(ReplicatedStorage.rbxts_include.node_modules["@flamework"].core.out).Flamework
local reflexCtrl = Flamework.resolveDependency("client/controllers/reflex-controller@ReflexController")
local producer = reflexCtrl:getClientProducer()

-- Charm (atom/peek/subscribe)
local charm = require(ReplicatedStorage.rbxts_include.node_modules["@rbxts"].charm)
local peek = charm.peek
local subscribe = charm.subscribe

-- Fishing phase atoms
local fishingPhaseAtom = require(LocalPlayer.PlayerScripts.TS["fishing-phase-atom"])
local fishingMovementLockedAtom = fishingPhaseAtom.fishingMovementLockedAtom

-- Training boost atoms (for QTE auto-click)
local trainingBoostAtom = require(LocalPlayer.PlayerScripts.TS["training-boost-atom"])
local trainingBoostFillAtom = trainingBoostAtom.trainingBoostFillAtom
local trainingIsFrenzyAtom = trainingBoostAtom.trainingIsFrenzyAtom
local trainingSkillcheckHitCounterAtom = trainingBoostAtom.trainingSkillcheckHitCounterAtom

local uid = tostring(LocalPlayer.UserId)

-- ═══════════════════════════════════════════
-- HELPER: Safe promise call (fire-and-forget with error suppression)
-- ═══════════════════════════════════════════
local function safeCall(fn, ...)
    local args = {...}
    local ok, promise = pcall(function()
        return fn(unpack(args))
    end)
    if ok and promise and typeof(promise) == "table" and promise.catch then
        promise:catch(function() end) -- suppress unhandled rejection
        return promise
    end
    return nil
end

-- ═══════════════════════════════════════════
-- HELPER: Fire a GUI button's click/tap signal via executor APIs
-- ═══════════════════════════════════════════
local function fireButton(btn)
    -- firesignal is the executor's built-in signal dispatcher
    local fired = false
    if firesignal then
        pcall(function()
            firesignal(btn.Activated)
            fired = true
        end)
        if not fired then
            pcall(function()
                firesignal(btn.MouseButton1Click)
                fired = true
            end)
        end
    end
    -- fireclick is another common executor API
    if not fired and fireclick then
        pcall(function()
            fireclick(btn)
            fired = true
        end)
    end
    -- Last resort: try direct Fire (may fail without Plugin capability)
    if not fired then
        pcall(function()
            btn.Activated:Fire()
        end)
    end
    return fired
end

-- ═══════════════════════════════════════════
-- HELPER: Read player inventory from Reflex
-- ═══════════════════════════════════════════
local function getPlayerData()
    local state = producer:getState()
    return state.playerData
end

local function getInventory()
    local pd = getPlayerData()
    return pd and pd.inventory and pd.inventory[uid]
end

local function getStats()
    local pd = getPlayerData()
    return pd and pd.stats and pd.stats[uid]
end

local function getFishItemIds()
    local inv = getInventory()
    if not inv then return {} end
    local ids = {}
    for id, item in pairs(inv) do
        if item.itemType == "fish" and not item.isEquipped then
            table.insert(ids, id)
        end
    end
    return ids
end

local function getWeightItems()
    local inv = getInventory()
    if not inv then return {} end
    local weights = {}
    for id, item in pairs(inv) do
        if item.itemType == "trainingWeight" then
            table.insert(weights, {id = id, name = item.itemName, equipped = item.isEquipped})
        end
    end
    return weights
end

local function getBestWeight()
    local weights = getWeightItems()
    if #weights == 0 then return nil end
    -- Return the first one found (they're all in inventory)
    local best = weights[1]
    for _, w in ipairs(weights) do
        -- Prefer the one that's already equipped
        if w.equipped then return w end
    end
    return best
end

local function getEquippedItem()
    local inv = getInventory()
    if not inv then return nil end
    for id, item in pairs(inv) do
        if item.isEquipped then
            return {id = id, name = item.itemName, type = item.itemType}
        end
    end
    return nil
end

-- ═══════════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════════
local State = {
    autoFish      = false,
    autoTrain     = false,
    autoSell      = false,
    autoCollect   = false,
    autoClaim     = false,
    speedHack     = false,
    noclip        = false,
    antiAfk       = true,
    
    walkSpeed     = 60,
    jumpPower     = 50,
    trainInterval = 0.1,
}
Env._cobaltState = State
local connections = {}
local function track(connection)
    table.insert(connections, connection)
    return connection
end

local savedHumanoid
local savedCollision = {}

local function restoreNoclip()
    for part, canCollide in pairs(savedCollision) do
        if part and part.Parent then part.CanCollide = canCollide end
    end
    table.clear(savedCollision)
end

-- ═══════════════════════════════════════════
-- THEME
-- ═══════════════════════════════════════════
local T = {
    BG      = Color3.fromRGB(12, 12, 18),
    Panel   = Color3.fromRGB(18, 18, 26),
    Surface = Color3.fromRGB(26, 26, 36),
    Border  = Color3.fromRGB(42, 42, 58),
    Text    = Color3.fromRGB(215, 215, 230),
    Dim     = Color3.fromRGB(120, 120, 150),
    Muted   = Color3.fromRGB(75, 75, 100),
    Accent  = Color3.fromRGB(120, 90, 245),
    AccentH = Color3.fromRGB(150, 120, 255),
    Green   = Color3.fromRGB(70, 210, 130),
    Red     = Color3.fromRGB(235, 70, 80),
    Yellow  = Color3.fromRGB(235, 195, 70),
    Cyan    = Color3.fromRGB(70, 195, 235),
    Orange  = Color3.fromRGB(235, 140, 55),
}
local FNT   = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
local FNT_B = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
local FNT_M = Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.Regular)
local TW    = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TW_S  = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

-- ═══════════════════════════════════════════
-- UI UTILS
-- ═══════════════════════════════════════════
local function create(cls, props, kids)
    local i = Instance.new(cls)
    for k,v in pairs(props or {}) do i[k] = v end
    for _,c in ipairs(kids or {}) do c.Parent = i end
    return i
end
local function corner(p,r) return create("UICorner",{CornerRadius=UDim.new(0,r or 6),Parent=p}) end
local function stroke(p,c) return create("UIStroke",{Color=c or T.Border,Thickness=1,Parent=p}) end
local function pad(p,t,r,b,l) return create("UIPadding",{PaddingTop=UDim.new(0,t or 4),PaddingRight=UDim.new(0,r or 4),PaddingBottom=UDim.new(0,b or 4),PaddingLeft=UDim.new(0,l or 4),Parent=p}) end
local function tw(o,i,p) local t=TweenService:Create(o,i,p); t:Play(); return t end
local function getChar() return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait() end
local function getHRP() local c=getChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum() local c=getChar(); return c and c:FindFirstChildWhichIsA("Humanoid") end

local function applySpeed()
    local humanoid = getHum()
    if not humanoid then return end
    if not savedHumanoid then
        savedHumanoid = {
            humanoid = humanoid,
            walkSpeed = humanoid.WalkSpeed,
            jumpPower = humanoid.JumpPower,
        }
    end
    humanoid.WalkSpeed = State.walkSpeed
    humanoid.JumpPower = State.jumpPower
end

local function restoreSpeed()
    if savedHumanoid and savedHumanoid.humanoid and savedHumanoid.humanoid.Parent then
        savedHumanoid.humanoid.WalkSpeed = savedHumanoid.walkSpeed
        savedHumanoid.humanoid.JumpPower = savedHumanoid.jumpPower
    end
    savedHumanoid = nil
end

local function restoreMovement()
    restoreSpeed()
    restoreNoclip()
end

local function applyNoclip()
    local character = LocalPlayer.Character
    if not character then return end
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            if savedCollision[part] == nil then savedCollision[part] = part.CanCollide end
            part.CanCollide = false
        end
    end
end

-- ═══════════════════════════════════════════
-- GUI SETUP
-- ═══════════════════════════════════════════
local gui = create("ScreenGui", {
    Name="CobaltCheats", ResetOnSpawn=false,
    ZIndexBehavior=Enum.ZIndexBehavior.Sibling, DisplayOrder=1000, Parent=GuiParent
})

local main = create("Frame", {
    Name="Main", Size=UDim2.fromOffset(320, 540),
    Position=UDim2.new(0,20,0.5,-270),
    BackgroundColor3=T.BG, BorderSizePixel=0, ClipsDescendants=true, Parent=gui
})
corner(main, 10); stroke(main)

-- Shadow
create("ImageLabel",{Size=UDim2.new(1,30,1,30),Position=UDim2.new(0,-15,0,-15),BackgroundTransparency=1,Image="rbxassetid://5554236805",ImageColor3=Color3.new(0,0,0),ImageTransparency=0.5,ScaleType=Enum.ScaleType.Slice,SliceCenter=Rect.new(23,23,277,277),ZIndex=0,Parent=main})

-- Topbar
local topbar = create("Frame",{Size=UDim2.new(1,0,0,34),BackgroundColor3=T.Panel,BorderSizePixel=0,ZIndex=10,Parent=main})
corner(topbar, 10)
create("Frame",{Size=UDim2.new(1,0,0,10),Position=UDim2.new(0,0,1,-10),BackgroundColor3=T.Panel,BorderSizePixel=0,ZIndex=10,Parent=topbar})
create("TextLabel",{Size=UDim2.new(0,200,1,0),Position=UDim2.new(0,10,0,0),BackgroundTransparency=1,Text="◆ Cobalt v3",FontFace=FNT_B,TextSize=14,TextColor3=T.AccentH,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=11,Parent=topbar})

-- Status label (shows current action)
local statusLabel = create("TextLabel",{
    Size=UDim2.new(0,150,0,12), Position=UDim2.new(0,100,0.5,-6),
    BackgroundTransparency=1, Text="idle", FontFace=FNT_M, TextSize=9,
    TextColor3=T.Dim, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=11, Parent=topbar
})

-- Close
local btnClose = create("TextButton",{Size=UDim2.fromOffset(26,20),Position=UDim2.new(1,-34,0.5,-10),BackgroundColor3=T.Red,BackgroundTransparency=0.7,Text="✕",FontFace=FNT_B,TextSize=11,TextColor3=T.Red,ZIndex=11,Parent=topbar})
corner(btnClose,4)
btnClose.MouseButton1Click:Connect(function()
    tw(main,TW,{Size=UDim2.fromOffset(0,0)}); task.wait(0.2); Env._cobaltCleanup()
end)

-- Drag
local dragging,dragStart,startPos
topbar.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 then
        dragging=true; dragStart=input.Position; startPos=main.Position
        input.Changed:Connect(function() if input.UserInputState==Enum.UserInputState.End then dragging=false end end)
    end
end)
track(UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType==Enum.UserInputType.MouseMovement then
        local d=input.Position-dragStart
        main.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
    end
end))

-- Scroll area
local scroll = create("ScrollingFrame",{
    Size=UDim2.new(1,-8,1,-42), Position=UDim2.new(0,4,0,38),
    BackgroundTransparency=1, ScrollBarThickness=3, ScrollBarImageColor3=T.Accent,
    CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y,
    BorderSizePixel=0, Parent=main
})
create("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,3),Parent=scroll})
pad(scroll,2,4,4,4)

-- ═══════════════════════════════════════════
-- UI BUILDERS
-- ═══════════════════════════════════════════
local ord = 0
local function section(title)
    ord = ord + 1
    create("TextLabel",{Size=UDim2.new(1,0,0,20),BackgroundTransparency=1,Text="  "..string.upper(title),FontFace=FNT_B,TextSize=9,TextColor3=T.Dim,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=ord*100,Parent=scroll})
    return ord * 100
end

local function toggle(label, key, base, color)
    local o = base + 1
    local f = create("Frame",{Size=UDim2.new(1,0,0,30),BackgroundColor3=T.Surface,BorderSizePixel=0,LayoutOrder=o,Parent=scroll})
    corner(f,6)
    create("TextLabel",{Size=UDim2.new(1,-55,1,0),Position=UDim2.new(0,10,0,0),BackgroundTransparency=1,Text=label,FontFace=FNT,TextSize=11,TextColor3=T.Text,TextXAlignment=Enum.TextXAlignment.Left,Parent=f})
    local bg = create("Frame",{Size=UDim2.fromOffset(36,18),Position=UDim2.new(1,-44,0.5,-9),BackgroundColor3=State[key] and (color or T.Green) or T.Border,BorderSizePixel=0,Parent=f})
    corner(bg,9)
    local dot = create("Frame",{Size=UDim2.fromOffset(14,14),Position=State[key] and UDim2.new(0,20,0.5,-7) or UDim2.new(0,2,0.5,-7),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,Parent=bg})
    corner(dot,7)
    local btn = create("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",Parent=f})
    btn.MouseButton1Click:Connect(function()
        State[key] = not State[key]
        tw(bg,TW,{BackgroundColor3=State[key] and (color or T.Green) or T.Border})
        tw(dot,TW,{Position=State[key] and UDim2.new(0,20,0.5,-7) or UDim2.new(0,2,0.5,-7)})
    end)
    return f, bg, dot
end

local function button(label, cb, base, color)
    local o = base + 1
    local b = create("TextButton",{Size=UDim2.new(1,0,0,28),BackgroundColor3=color or T.Accent,Text=label,FontFace=FNT_B,TextSize=11,TextColor3=T.Text,LayoutOrder=o,Parent=scroll})
    corner(b,6)
    b.MouseEnter:Connect(function() tw(b,TW,{BackgroundTransparency=0.15}) end)
    b.MouseLeave:Connect(function() tw(b,TW,{BackgroundTransparency=0}) end)
    b.MouseButton1Click:Connect(cb)
    return b
end

local function slider(label, key, min, max, base)
    local o = base + 1
    local f = create("Frame",{Size=UDim2.new(1,0,0,42),BackgroundColor3=T.Surface,BorderSizePixel=0,LayoutOrder=o,Parent=scroll})
    corner(f,6)
    create("TextLabel",{Size=UDim2.new(0.5,0,0,18),Position=UDim2.new(0,10,0,2),BackgroundTransparency=1,Text=label,FontFace=FNT,TextSize=10,TextColor3=T.Text,TextXAlignment=Enum.TextXAlignment.Left,Parent=f})
    local vl = create("TextLabel",{Size=UDim2.new(0.4,0,0,18),Position=UDim2.new(0.55,0,0,2),BackgroundTransparency=1,Text=tostring(State[key]),FontFace=FNT_M,TextSize=10,TextColor3=T.AccentH,TextXAlignment=Enum.TextXAlignment.Right,Parent=f})
    local track = create("Frame",{Size=UDim2.new(1,-20,0,5),Position=UDim2.new(0,10,0,28),BackgroundColor3=T.Border,BorderSizePixel=0,Parent=f})
    corner(track,3)
    local fill = create("Frame",{Size=UDim2.new((State[key]-min)/(max-min),0,1,0),BackgroundColor3=T.Accent,BorderSizePixel=0,Parent=track})
    corner(fill,3)
    local knob = create("Frame",{Size=UDim2.fromOffset(10,10),Position=UDim2.new((State[key]-min)/(max-min),-5,0.5,-5),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ZIndex=2,Parent=track})
    corner(knob,5)
    local sb = create("TextButton",{Size=UDim2.new(1,0,0,18),Position=UDim2.new(0,0,0,22),BackgroundTransparency=1,Text="",Parent=f})
    local sliding = false
    sb.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then sliding=true end end)
    sb.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then sliding=false end end)
    UserInputService.InputChanged:Connect(function(i)
        if sliding and i.UserInputType==Enum.UserInputType.MouseMovement then
            local r=math.clamp((i.Position.X-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
            local v=math.floor(min+r*(max-min))
            State[key]=v; vl.Text=tostring(v)
            fill.Size=UDim2.new(r,0,1,0); knob.Position=UDim2.new(r,-5,0.5,-5)
        end
    end)
    return f
end

-- ═══════════════════════════════════════════
-- BUILD PANELS
-- ═══════════════════════════════════════════

-- FARMING
local farmBase = section("Farming")
toggle("Auto-Fish (QTE + Jackpot)", "autoFish", farmBase, T.Green)
toggle("Auto-Train (equip+spam tick)", "autoTrain", farmBase, T.Cyan)
toggle("Auto-Sell All Fish", "autoSell", farmBase, T.Orange)
toggle("Auto-Collect Coins", "autoCollect", farmBase, T.Yellow)
toggle("Auto-Claim Rewards", "autoClaim", farmBase, T.AccentH)

button("⚡ Sell All Fish Now", function()
    local ids = getFishItemIds()
    if #ids == 0 then
        print("[Cobalt] No fish to sell")
        return
    end
    print("[Cobalt] Selling", #ids, "fish...")
    safeCall(functions.sellFishItems, ids):andThen(function(v)
        if v and v ~= false then
            print("[Cobalt] Sold fish for $" .. tostring(v))
        else
            print("[Cobalt] Sell returned false (no fish or error)")
        end
    end):catch(function() end)
end, farmBase, T.Orange)

button("🏋 Equip Best Weight", function()
    local w = getBestWeight()
    if not w then
        print("[Cobalt] No training weights in inventory!")
        return
    end
    print("[Cobalt] Equipping", w.name, "(" .. w.id .. ")")
    safeCall(functions.equipInventoryItem, w.id):andThen(function(v)
        print("[Cobalt] Equip result:", tostring(v))
    end):catch(function() end)
end, farmBase, T.Cyan)

button("🎁 Claim Daily Reward", function()
    safeCall(functions.claimDailyReward):andThen(function(v) print("[Cobalt] Daily:", tostring(v)) end):catch(function() end)
end, farmBase, T.Accent)

button("💰 Claim Offline Earnings", function()
    safeCall(functions.claimOfflineEarnings):andThen(function(v) print("[Cobalt] Offline:", tostring(v)) end):catch(function() end)
end, farmBase, T.Accent)

button("🎡 Spin Playtime Wheel", function()
    safeCall(functions.spinPlaytimeWheel):andThen(function(v)
        if typeof(v) == "table" then
            print("[Cobalt] Wheel: segment=" .. tostring(v.segmentId) .. " fish=" .. tostring(v.fishName) .. " cash=" .. tostring(v.cashAmount))
        else
            print("[Cobalt] Wheel:", tostring(v))
        end
    end):catch(function() end)
end, farmBase, T.Yellow)

button("🔄 Perform Rebirth", function()
    safeCall(functions.performRebirth):andThen(function(v) print("[Cobalt] Rebirth:", tostring(v)) end):catch(function() end)
end, farmBase, T.Red)

button("📊 Print Stats", function()
    local stats = getStats()
    local inv = getInventory()
    local fishCount = 0
    if inv then
        for _, item in pairs(inv) do
            if item.itemType == "fish" then fishCount = fishCount + 1 end
        end
    end
    if stats then
        print("[Cobalt] Money:", stats.money, "| Power:", stats.power, "| Fish:", fishCount, "| Casts:", stats.lifetimeCasts, "| Rerolls:", stats.rerolls)
    end
end, farmBase, T.Surface)

-- MOVEMENT
local moveBase = section("Movement")
toggle("Speed Hack", "speedHack", moveBase, T.Cyan)
slider("Walk Speed", "walkSpeed", 16, 500, moveBase)
slider("Jump Power", "jumpPower", 50, 500, moveBase)
toggle("Noclip", "noclip", moveBase, T.Orange)
toggle("Anti-AFK", "antiAfk", moveBase, T.Green)

-- TELEPORT
local tpBase = section("Teleport")
local zones = {
    {"Zone 1 (Starter)",  Vector3.new(-744, 106, -958)},
    {"Zone 2",            Vector3.new(-533, 106, -750)},
    {"Zone 3",            Vector3.new(-350, 106, -600)},
    {"Zone 4 (Crystal)",  Vector3.new(-150, 106, -450)},
    {"Zone 5",            Vector3.new(50, 106, -300)},
    {"Zone 6 (Lava)",     Vector3.new(250, 106, -150)},
    {"Zone 7 (Clouds)",   Vector3.new(450, 106, 0)},
    {"Barbells (Train)",  Vector3.new(-680, 107, -920)},
}
for _, z in ipairs(zones) do
    button("→ " .. z[1], function()
        local hrp = getHRP()
        if hrp then hrp.CFrame = CFrame.new(z[2]); print("[Cobalt] TP →", z[1]) end
    end, tpBase, T.Surface)
end

-- ═══════════════════════════════════════════
-- CHEAT LOOPS
-- ═══════════════════════════════════════════

-- AUTO-FISH: full cycle (TP → cast → QTE → reel → repeat)
do
    local Workspace = game:GetService("Workspace")
    local fishingZoneCenter = Vector3.new(-798, 106, -810) -- FishingArea center
    -- Helper: find the big FISH ImageButton in PlayerGui
    local function findFishButton()
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if not pg then return nil end
        -- Navigate the known React tree: PlayerGui.1.1.36.1.1.2
        local node = pg
        for _, idx in ipairs({"1", "1", "36", "1", "1", "2"}) do
            node = node and node:FindFirstChild(idx)
        end
        if node and node:IsA("ImageButton") and node.Visible then
            return node
        end
        -- Fallback: scan for large visible ImageButtons near bottom of screen
        for _, desc in ipairs(pg:GetDescendants()) do
            if desc:IsA("ImageButton") and desc.Visible 
               and desc.AbsoluteSize.X > 200 and desc.AbsoluteSize.Y > 60
               and desc.AbsolutePosition.Y > 500 then
                return desc
            end
        end
        return nil
    end

    -- The power meter has its own full-screen TextButton. Firing the cast
    -- event directly skips the React input handler and leaves "Tap to cast!"
    -- stuck on screen, so activate the real control first.
    local function findCastButton()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if not playerGui then return nil end
        for _, desc in ipairs(playerGui:GetDescendants()) do
            if desc:IsA("TextLabel") and desc.Visible
               and string.find(string.lower(desc.Text), "tap to cast", 1, true) then
                local root = desc
                for _ = 1, 4 do
                    root = root.Parent
                    if not root then break end
                end
                if root then
                    for _, child in ipairs(root:GetChildren()) do
                        if child:IsA("GuiButton") and child.Visible then
                            return child
                        end
                    end
                end
            end
        end
        return nil
    end
    
    -- Helper: check if player is in the fishing zone
    local function isInFishingZone()
        local hrp = getHRP()
        if not hrp then return false end
        local fz = Workspace:FindFirstChild("Map") 
            and Workspace.Map:FindFirstChild("FishingArea")
            and Workspace.Map.FishingArea:FindFirstChild("DetectableArea")
        if not fz then return false end
        local rel = hrp.Position - fz.Position
        local half = fz.Size / 2
        return math.abs(rel.X) <= half.X and math.abs(rel.Y) <= half.Y and math.abs(rel.Z) <= half.Z
    end
    
    -- Helper: get current fishing state from Reflex
    local function getFishingPhase()
        local state = producer:getState()
        local uid2 = tostring(LocalPlayer.UserId)
        local fs = state.fishingState and state.fishingState[uid2]
        return fs and fs.fishingState -- "idle", "casting", "nibbling", "reeling", etc
    end
    
    -- Helper: check if we have an active hook
    local function getMyHook()
        local state = producer:getState()
        for hookId, hook in pairs(state.fishingHooks or {}) do
            if hook.casterUserId == LocalPlayer.UserId then
                return hookId, hook
            end
        end
        return nil, nil
    end
    
    -- QTE listeners (always active, fire when autoFish is on)
    events.hookSpawned:connect(function(hookId)
        if gui.Parent and State.autoFish then
            task.delay(0.15, function()
                if gui.Parent and State.autoFish then
                    pcall(function() events.hookQteTapResult:fire(true) end)
                    print("[Cobalt] Auto-tapped hook QTE:", hookId)
                end
            end)
        end
    end)
    
    events.hookQteMutationRolled:connect(function(mutation)
        if gui.Parent and State.autoFish then
            task.delay(0.1, function()
                if gui.Parent and State.autoFish then
                    pcall(function() events.hookQteTapResult:fire(true) end)
                    print("[Cobalt] Auto-tapped mutation QTE:", tostring(mutation))
                end
            end)
        end
    end)
    
    -- Auto-complete reel animation when server starts reel
    events.reelStarted:connect(function(...)
        if gui.Parent and State.autoFish then
            task.delay(0.5, function()
                if gui.Parent and State.autoFish then
                    pcall(function() events.reelAnimComplete:fire() end)
                    print("[Cobalt] Auto-completed reel")
                end
            end)
        end
    end)
    
    -- Main auto-fish loop
    task.spawn(function()
        while gui.Parent do
            if State.autoFish then
                statusLabel.Text = "fishing..."
                
                -- Step 1: Make sure we're in the fishing zone
                if not isInFishingZone() then
                    local hrp = getHRP()
                    if hrp then
                        hrp.CFrame = CFrame.new(fishingZoneCenter)
                        print("[Cobalt] TP to fishing zone")
                        task.wait(1)
                    end
                end
                
                -- Step 2: Check current state
                local phase = getFishingPhase()
                local hookId, hook = getMyHook()
                
                if not hookId and (phase == nil or phase == "idle") then
                    -- No active hook, not casting — click the FISH button
                    local btn = findFishButton()
                    if btn then
                        fireButton(btn)
                        print("[Cobalt] Clicked FISH button")
                        task.wait(0.3)
                        
                        -- Step 3: complete the visible power-meter input.
                        local hrp = getHRP()
                        if hrp then
                            local castControl = findCastButton()
                            local castOk = castControl and fireButton(castControl)
                            local castErr
                            if not castOk then
                                castOk, castErr = pcall(function()
                                    events.castFishingHook:fire({
                                        direction = hrp.CFrame.LookVector,
                                        peakBias = 0.33,
                                        skillCheckStrength = 1.0,
                                        startPosition = hrp.Position,
                                        utilizedPowerFraction = 1.0,
                                    })
                                end)
                            end
                            if castOk then
                                print("[Cobalt] Completed cast power meter")
                                task.wait(2) -- wait for hook to land
                            else
                                warn("[Cobalt] Cast failed:", castErr)
                                task.wait(1)
                            end
                        else
                            print("[Cobalt] Character not ready, retry...")
                            task.wait(1)
                        end
                    else
                        -- No fish button visible — maybe not in area or UI not loaded
                        print("[Cobalt] Fish button not found, retrying...")
                        task.wait(2)
                    end
                elseif phase == "nibbling" then
                    -- Hook is in water, fish nibbling — wait for reel
                    task.wait(0.5)
                else
                    -- Some other phase (casting, reeling, etc) — just wait
                    task.wait(0.5)
                end
            else
                if statusLabel.Text == "fishing..." then statusLabel.Text = "idle" end
                task.wait(0.5)
            end
        end
    end)
    
    -- Rare fish QTE circle auto-clicker
    task.spawn(function()
        while gui.Parent do
            local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
            if State.autoFish and playerGui then
                for _, desc in ipairs(playerGui:GetDescendants()) do
                    if not State.autoFish then break end
                    if desc:IsA("TextButton") and desc.Text == ""
                       and desc.BackgroundTransparency == 1
                       and desc.Visible and desc.Active ~= false then
                        local uiCorner = desc:FindFirstChildWhichIsA("UICorner")
                        if uiCorner and uiCorner.CornerRadius == UDim.new(0.5, 0) then
                            local parent = desc.Parent
                            if parent and parent:IsA("Frame") and parent.BackgroundTransparency == 1 then
                                if desc.ZIndex >= 5 then
                                    if fireButton(desc) then
                                        print("[Cobalt] Auto-clicked rare fish QTE")
                                    end
                                end
                            end
                        end
                    end
                end
                task.wait(0.05)
            else
                task.wait(0.3)
            end
        end
    end)
end

-- AUTO-TRAIN: equip weight → spam trainingTick + auto-click QTE circles
task.spawn(function()
    while gui.Parent do
        if State.autoTrain then
            statusLabel.Text = "training..."
            -- Make sure a weight is equipped
            local equipped = getEquippedItem()
            if not equipped or equipped.type ~= "trainingWeight" then
                local w = getBestWeight()
                if w then
                    safeCall(functions.equipInventoryItem, w.id)
                    task.wait(0.5)
                end
            end
            -- Spam training tick for base power
            safeCall(functions.trainingTick)
            task.wait(State.trainInterval)
        else
            if statusLabel.Text == "training..." then statusLabel.Text = "idle" end
            task.wait(0.5)
        end
    end
end)

-- AUTO-TRAIN QTE: scan for skillcheck circle buttons and auto-click them
task.spawn(function()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    while gui.Parent do
        if State.autoTrain and pg then
            -- Scan all descendants for training QTE buttons
            -- QTE circles are: TextButton, Text="", BackgroundTransparency=1, ZIndex=10,
            -- with a UICorner child (CornerRadius 0.5,0 = circle), inside a frame at ZIndex=3
            local clicked = false
            for _, desc in ipairs(pg:GetDescendants()) do
                if not State.autoTrain then break end
                if desc:IsA("TextButton") and desc.Text == "" 
                   and desc.ZIndex == 10 and desc.BackgroundTransparency == 1 
                   and desc.Visible and desc.Active ~= false then
                    -- Check for circular UICorner (hallmark of QTE target)
                    local uiCorner = desc:FindFirstChildWhichIsA("UICorner")
                    if uiCorner and uiCorner.CornerRadius == UDim.new(0.5, 0) then
                        -- Check parent is a positioned frame (not toolbar/topbar)
                        local parent = desc.Parent
                        if parent and parent:IsA("Frame") 
                           and parent.ZIndex == 3 
                           and parent.BackgroundTransparency == 1 then
                            -- This is a training QTE circle — fire it
                            fireButton(desc)
                            clicked = true
                        end
                    end
                end
            end
            -- Also fire trainingSkillcheckBonus for the server-side power multiplier
            if clicked then
                safeCall(functions.trainingSkillcheckBonus)
            end
            task.wait(0.05) -- scan very fast for responsive QTE clicking
        else
            task.wait(0.3)
        end
    end
end)

-- AUTO-TRAIN FRENZY BOOST: directly fill the boost bar via atom manipulation
task.spawn(function()
    while gui.Parent do
        if State.autoTrain then
            -- Read current boost fill
            local currentFill = peek(trainingBoostFillAtom)
            local isFrenzy = peek(trainingIsFrenzyAtom)
            -- If not in frenzy and boost is building, accelerate it
            if not isFrenzy and currentFill < 1 then
                -- Increment the hit counter (triggers UI feedback)
                trainingSkillcheckHitCounterAtom(function(v) return v + 1 end)
                -- Bump the fill toward 1.0
                local newFill = math.min(currentFill + 0.12, 1.0)
                trainingBoostFillAtom(newFill)
            end
            task.wait(0.15)
        else
            task.wait(0.5)
        end
    end
end)

-- AUTO-SELL: sell all fish periodically
task.spawn(function()
    while gui.Parent do
        if State.autoSell then
            statusLabel.Text = "selling..."
            local ids = getFishItemIds()
            if #ids > 0 then
                safeCall(functions.sellFishItems, ids)
                print("[Cobalt] Auto-sold", #ids, "fish")
            end
            task.wait(8) -- every 8 seconds
        else
            task.wait(1)
        end
    end
end)

-- AUTO-COLLECT COINS: fire collectCoin for nearby coins
task.spawn(function()
    while gui.Parent do
        if State.autoCollect then
            statusLabel.Text = "collecting..."
            -- Collect any coins spawned via the spawnCoin event
            -- They're usually tagged with CollectionService
            local CollectionService = game:GetService("CollectionService")
            for _, tagged in ipairs(CollectionService:GetTagged("Coin") or {}) do
                if not State.autoCollect then break end
                if tagged:IsA("BasePart") then
                    local hrp = getHRP()
                    if hrp then
                        local oldCF = hrp.CFrame
                        hrp.CFrame = tagged.CFrame
                        task.wait(0.05)
                        hrp.CFrame = oldCF
                    end
                end
            end
            -- Also try collectPlotMoney
            safeCall(functions.collectPlotMoney)
            task.wait(3)
        else
            task.wait(1)
        end
    end
end)

-- AUTO-CLAIM: cycle through all claimable rewards
task.spawn(function()
    while gui.Parent do
        if State.autoClaim then
            safeCall(functions.claimDailyReward)
            task.wait(0.5)
            safeCall(functions.claimPlaytimeReward)
            task.wait(0.5)
            safeCall(functions.claimFreeReward)
            task.wait(0.5)
            safeCall(functions.claimOfflineEarnings)
            task.wait(0.5)
            safeCall(functions.spinPlaytimeWheel)
            task.wait(30)
        else
            task.wait(5)
        end
    end
end)

-- SPEED HACK
task.spawn(function()
    while gui.Parent do
        if State.speedHack then
            applySpeed()
        else
            restoreSpeed()
        end
        task.wait(0.3)
    end
    restoreSpeed()
end)

-- NOCLIP
track(RunService.Stepped:Connect(function()
    if State.noclip then
        applyNoclip()
    else
        restoreNoclip()
    end
end))

-- ANTI-AFK
task.spawn(function()
    while gui.Parent do
        if State.antiAfk then
            pcall(function()
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                task.wait(0.1)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
            end)
            task.wait(120) -- every 2 min
        else
            task.wait(5)
        end
    end
end)

-- ═══════════════════════════════════════════
-- TOGGLE (RightControl)
-- ═══════════════════════════════════════════
track(UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        main.Visible = not main.Visible
    end
end))

Env._cobaltCleanup = function()
    for key, value in pairs(State) do
        if typeof(value) == "boolean" then State[key] = false end
    end
    restoreMovement()
    for _, connection in ipairs(connections) do pcall(function() connection:Disconnect() end) end
    table.clear(connections)
    if Env._cobaltState == State then Env._cobaltState = nil end
    pcall(function() gui:Destroy() end)
end

-- ═══════════════════════════════════════════
-- INTRO
-- ═══════════════════════════════════════════
pcall(function()
    main.BackgroundTransparency = 1
    main.Size = UDim2.fromOffset(320, 0)
    task.wait(0.05)
    tw(main, TW_S, {Size = UDim2.fromOffset(320, 540), BackgroundTransparency = 0})
end)

-- Print stats on load
local stats = getStats()
local fishIds = getFishItemIds()
local weights = getWeightItems()
print("[Cobalt v3] Loaded | RightControl to toggle")
print("[Cobalt v3] Money:", stats and stats.money or "?", "| Power:", stats and stats.power or "?")
print("[Cobalt v3] Fish:", #fishIds, "| Weights:", #weights)
print("[Cobalt v3] Equipped:", getEquippedItem() and (getEquippedItem().name .. " [" .. getEquippedItem().type .. "]") or "nothing")

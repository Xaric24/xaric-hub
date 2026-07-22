--[[
    ╔═══════════════════════════════════════════════════════════╗
    ║  ⚔ Warhead v1 — Missiles vs Cities Exploit               ║
    ║  Auto-Farm · Auto-Fire · Movement · Teleport              ║
    ╚═══════════════════════════════════════════════════════════╝
]]

local Env = (getgenv and getgenv()) or _G
if Env._warheadCleanup then pcall(Env._warheadCleanup) end

-- Cleanup (destroy ALL old WarheadCheats GUIs)
pcall(function()
    for _, desc in ipairs(game:GetService("CoreGui"):GetDescendants()) do
        if desc.Name == "WarheadCheats" and desc:IsA("ScreenGui") then desc:Destroy() end
    end
end)

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local LocalPlayer = Players.LocalPlayer
local GuiParent = (gethui and gethui()) or CoreGui

-- Game modules
local configs = require(ReplicatedStorage:WaitForChild("configs"))
local remotes = ReplicatedStorage:WaitForChild("remotes")
local prompt_action = remotes:WaitForChild("prompt_action")
local fire_missile = remotes:WaitForChild("fire_missile")
local claim_task = remotes:WaitForChild("claim_task")
local shop_purchase = remotes:WaitForChild("shop_purchase")

-- ═══════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════
local function getHRP()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildWhichIsA("Humanoid")
end

local function getCash()
    local c = LocalPlayer:FindFirstChild("currency")
    return c and c:FindFirstChild("Cash") and c.Cash.Value or 0
end

local function getGems()
    local c = LocalPlayer:FindFirstChild("currency")
    return c and c:FindFirstChild("Gems") and c.Gems.Value or 0
end

local function isOwnedByMe(inst)
    local owner = inst:GetAttribute("prompt_owner")
    return owner and tostring(owner) == tostring(LocalPlayer.UserId)
end

local function fireButton(btn)
    local fired = false
    if firesignal then
        pcall(function() firesignal(btn.Activated); fired = true end)
        if not fired then pcall(function() firesignal(btn.MouseButton1Click); fired = true end) end
    end
    if not fired then pcall(function() btn.Activated:Fire() end) end
end

-- ═══════════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════════
local State = {
    autoCollect   = false,
    autoUpgrade   = false,
    autoFireSilos = false,
    autoReload    = false,
    autoScramble  = false,
    autoUpgradeSilo = false,
    autoUpgradeAA = false,
    autoMines     = false,
    speedHack     = false,
    noclip        = false,
    antiAfk       = true,
    esp           = false,

    walkSpeed     = 35,
    jumpPower     = 50,
    fireDelay     = 1.5,
}
Env._warheadState = State
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

local function applySpeed()
    local humanoid = getHumanoid()
    if not humanoid then return end
    if not savedHumanoid then
        savedHumanoid = {humanoid = humanoid, walkSpeed = humanoid.WalkSpeed, jumpPower = humanoid.JumpPower}
    end
    humanoid.WalkSpeed = State.walkSpeed
    humanoid.JumpPower = State.jumpPower
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
-- THEME (Military dark green)
-- ═══════════════════════════════════════════
local T = {
    BG      = Color3.fromRGB(10, 14, 10),
    Panel   = Color3.fromRGB(16, 22, 16),
    Surface = Color3.fromRGB(24, 32, 24),
    Border  = Color3.fromRGB(40, 55, 40),
    Accent  = Color3.fromRGB(80, 200, 80),
    Text    = Color3.fromRGB(210, 230, 210),
    Dim     = Color3.fromRGB(100, 130, 100),
    Green   = Color3.fromRGB(60, 180, 60),
    Red     = Color3.fromRGB(200, 60, 60),
    Orange  = Color3.fromRGB(220, 160, 40),
    Cyan    = Color3.fromRGB(60, 180, 200),
    Yellow  = Color3.fromRGB(220, 200, 60),
}

local FNT   = Font.new("rbxassetid://12187365364", Enum.FontWeight.Regular)
local FNT_B = Font.new("rbxassetid://12187365364", Enum.FontWeight.Bold)
local TW    = TweenInfo.new(0.2, Enum.EasingStyle.Quad)
local TW_S  = TweenInfo.new(0.3, Enum.EasingStyle.Back)
local tw    = function(i,t,p) TweenService:Create(i,t,p):Play() end

-- ═══════════════════════════════════════════
-- GUI CREATION
-- ═══════════════════════════════════════════
local function create(class, props)
    local inst = Instance.new(class)
    for k,v in pairs(props) do inst[k] = v end
    return inst
end
local function corner(inst, r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r); c.Parent=inst; return c end
local function pad(inst,t,b,l,r) local p=Instance.new("UIPadding"); p.PaddingTop=UDim.new(0,t); p.PaddingBottom=UDim.new(0,b); p.PaddingLeft=UDim.new(0,l); p.PaddingRight=UDim.new(0,r); p.Parent=inst end

local gui = create("ScreenGui", {
    Name="WarheadCheats", ResetOnSpawn=false,
    ZIndexBehavior=Enum.ZIndexBehavior.Sibling, DisplayOrder=1000, Parent=GuiParent
})

local main = create("Frame", {
    Size=UDim2.fromOffset(340, 560), Position=UDim2.new(0.5,-170,0.5,-280),
    BackgroundColor3=T.BG, BorderSizePixel=0, Parent=gui
})
corner(main,10)
create("UIStroke",{Thickness=1, Color=T.Border, Parent=main})

-- Topbar
local topbar = create("Frame",{Size=UDim2.new(1,0,0,34),BackgroundColor3=T.Panel,BorderSizePixel=0,Parent=main})
corner(topbar,10)
create("TextLabel",{
    Size=UDim2.new(1,-60,1,0), Position=UDim2.fromOffset(10,0),
    BackgroundTransparency=1, Text="  ⚔ Warhead v1", FontFace=FNT_B, TextSize=13,
    TextColor3=T.Accent, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=11, Parent=topbar
})

-- Status label
local statusLabel = create("TextLabel",{
    Size=UDim2.new(0.5,0,0,12), Position=UDim2.new(0.5,0,1,-14),
    BackgroundTransparency=1, Text="idle", FontFace=FNT, TextSize=9,
    TextColor3=T.Dim, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=11, Parent=topbar
})

-- Close
local btnClose = create("TextButton",{Size=UDim2.fromOffset(26,20),Position=UDim2.new(1,-34,0.5,-10),BackgroundColor3=T.Red,BackgroundTransparency=0.7,Text="✕",FontFace=FNT_B,TextSize=11,TextColor3=T.Red,ZIndex=11,Parent=topbar})
corner(btnClose,4)
btnClose.MouseButton1Click:Connect(function()
    tw(main,TW,{Size=UDim2.fromOffset(0,0)}); task.wait(0.2); Env._warheadCleanup()
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
    return f
end

local function button(label, callback, base, color)
    ord = ord + 1
    local b = create("TextButton",{
        Size=UDim2.new(1,0,0,28), BackgroundColor3=color or T.Surface, BorderSizePixel=0,
        Text=label, FontFace=FNT, TextSize=11, TextColor3=T.Text,
        LayoutOrder=base+ord, Parent=scroll
    })
    corner(b,6)
    b.MouseButton1Click:Connect(callback)
    return b
end

local function slider(label, key, mn, mx, base)
    ord = ord + 1
    local f = create("Frame",{Size=UDim2.new(1,0,0,38),BackgroundColor3=T.Surface,BorderSizePixel=0,LayoutOrder=base+ord,Parent=scroll})
    corner(f,6)
    local lbl = create("TextLabel",{Size=UDim2.new(0.5,0,0,16),Position=UDim2.fromOffset(10,2),BackgroundTransparency=1,Text=label,FontFace=FNT,TextSize=10,TextColor3=T.Dim,TextXAlignment=Enum.TextXAlignment.Left,Parent=f})
    local val = create("TextLabel",{Size=UDim2.new(0.4,0,0,16),Position=UDim2.new(0.55,0,0,2),BackgroundTransparency=1,Text=tostring(State[key]),FontFace=FNT_B,TextSize=10,TextColor3=T.Accent,TextXAlignment=Enum.TextXAlignment.Right,Parent=f})
    local track = create("Frame",{Size=UDim2.new(1,-20,0,6),Position=UDim2.new(0,10,1,-12),BackgroundColor3=T.Border,BorderSizePixel=0,Parent=f})
    corner(track,3)
    local fill = create("Frame",{Size=UDim2.new((State[key]-mn)/(mx-mn),0,1,0),BackgroundColor3=T.Accent,BorderSizePixel=0,Parent=track})
    corner(fill,3)
    local sb = create("TextButton",{Size=UDim2.new(1,0,1,10),Position=UDim2.new(0,0,0,-5),BackgroundTransparency=1,Text="",Parent=track})
    sb.MouseButton1Down:Connect(function(x)
        local conn; conn = RunService.RenderStepped:Connect(function()
            if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then conn:Disconnect(); return end
            local rel = math.clamp((UserInputService:GetMouseLocation().X - track.AbsolutePosition.X)/track.AbsoluteSize.X, 0, 1)
            State[key] = math.floor(mn + rel*(mx-mn))
            val.Text = tostring(State[key])
            fill.Size = UDim2.new(rel,0,1,0)
        end)
    end)
end

-- ═══════════════════════════════════════════
-- UI SECTIONS
-- ═══════════════════════════════════════════

-- AUTO-FARMING
local farmBase = section("Auto-Farming")
toggle("Auto-Collect Income", "autoCollect", farmBase, T.Green)
toggle("Auto-Upgrade Buildings", "autoUpgrade", farmBase, T.Cyan)
toggle("Auto-Operate Mines", "autoMines", farmBase, T.Yellow)

button("📋 Claim All Tasks", function()
    pcall(function() claim_task:FireServer() end)
    print("[Warhead] Claimed tasks")
end, farmBase, T.Surface)

button("📅 Claim Calendar", function()
    pcall(function() remotes.calendar_redeem:FireServer() end)
    print("[Warhead] Claimed calendar")
end, farmBase, T.Surface)

button("🎁 Claim Gift", function()
    pcall(function() remotes.gift_redeem:FireServer() end)
    print("[Warhead] Claimed gift")
end, farmBase, T.Surface)

-- COMBAT
local combatBase = section("Combat")
toggle("Auto-Fire Silos", "autoFireSilos", combatBase, T.Red)
toggle("Auto-Reload Silos", "autoReload", combatBase, T.Orange)
toggle("Auto-Scramble Jets", "autoScramble", combatBase, T.Cyan)
toggle("Auto-Upgrade Silos", "autoUpgradeSilo", combatBase, T.Yellow)
toggle("Auto-Upgrade AA", "autoUpgradeAA", combatBase, T.Green)
slider("Fire Delay (sec)", "fireDelay", 0.5, 5, combatBase)

button("🚀 Fire All Silos NOW", function()
    local silos = CollectionService:GetTagged("silo_prompt")
    local fired = 0
    for _, silo in ipairs(silos) do
        if isOwnedByMe(silo) and silo:GetAttribute("shoot_ready") then
            pcall(function() prompt_action:FireServer(silo, "shoot") end)
            fired = fired + 1
            task.wait(0.3)
        end
    end
    print("[Warhead] Fired", fired, "silos")
end, combatBase, T.Red)

button("✈ Scramble All Jets NOW", function()
    local jets = CollectionService:GetTagged("jet_prompt")
    local scrambled = 0
    for _, jet in ipairs(jets) do
        if isOwnedByMe(jet) then
            pcall(function() prompt_action:FireServer(jet, "scramble") end)
            scrambled = scrambled + 1
            task.wait(0.2)
        end
    end
    print("[Warhead] Scrambled", scrambled, "jets")
end, combatBase, T.Cyan)

button("🛡 Buy Naval Defense", function()
    pcall(function() remotes.naval_action:FireServer("buy_defense") end)
    print("[Warhead] Bought naval defense")
end, combatBase, T.Surface)

button("💥 Revenge Barrage", function()
    pcall(function() remotes.revenge_barrage:FireServer() end)
    print("[Warhead] Fired revenge barrage")
end, combatBase, T.Orange)

-- MOVEMENT
local moveBase = section("Movement")
toggle("Speed Hack", "speedHack", moveBase, T.Cyan)
slider("Walk Speed", "walkSpeed", 16, 500, moveBase)
slider("Jump Power", "jumpPower", 50, 500, moveBase)
toggle("Noclip", "noclip", moveBase, T.Orange)
toggle("Anti-AFK", "antiAfk", moveBase, T.Green)
toggle("ESP (Player Names)", "esp", moveBase, T.Yellow)

-- UTILITY
local utilBase = section("Utility")
button("📊 Print Stats", function()
    local silos = #CollectionService:GetTagged("silo_prompt")
    local buildings = #CollectionService:GetTagged("building")
    local aas = #CollectionService:GetTagged("aa_prompt")
    local jets = #CollectionService:GetTagged("jet_prompt")
    print(string.format("[Warhead] Cash: %s | Gems: %d | Buildings: %d | Silos: %d | AA: %d | Jets: %d",
        tostring(getCash()), getGems(), buildings, silos, aas, jets))
end, utilBase, T.Surface)

button("🔄 Upgrade All Affordable", function()
    -- Upgrade all silos
    for _, silo in ipairs(CollectionService:GetTagged("silo_prompt")) do
        if isOwnedByMe(silo) and silo:GetAttribute("up_affordable") then
            pcall(function() prompt_action:FireServer(silo, "upgrade") end)
            task.wait(0.1)
        end
    end
    -- Upgrade all AA
    for _, aa in ipairs(CollectionService:GetTagged("aa_prompt")) do
        if isOwnedByMe(aa) and aa:GetAttribute("up_affordable") then
            pcall(function() prompt_action:FireServer(aa, "upgrade") end)
            task.wait(0.1)
        end
    end
    print("[Warhead] Upgraded all affordable structures")
end, utilBase, T.Accent)

-- TELEPORT
local tpBase = section("Teleport")
button("🏠 TP to My City", function()
    local hrp = getHRP()
    if not hrp then return end
    -- Find own plot center
    local map = game.Workspace:FindFirstChild("map")
    if map and map:FindFirstChild("plots") then
        for _, plot in ipairs(map.plots:GetChildren()) do
            -- Check if this plot has our silos
            for _, desc in ipairs(plot:GetDescendants()) do
                if desc:GetAttribute("prompt_owner") == tostring(LocalPlayer.UserId) then
                    hrp.CFrame = CFrame.new(desc.Position + Vector3.new(0, 5, 0))
                    print("[Warhead] TP to own city")
                    return
                end
            end
        end
    end
    print("[Warhead] Could not find own plot")
end, tpBase, T.Surface)

button("⚓ TP to Naval Docks", function()
    local hrp = getHRP()
    if hrp then
        local dock = game.Workspace:FindFirstChild("NavalDocks")
        if dock then
            local first = dock:FindFirstChildWhichIsA("BasePart", true)
            if first then
                hrp.CFrame = CFrame.new(first.Position + Vector3.new(0, 10, 0))
                print("[Warhead] TP to naval docks")
            end
        end
    end
end, tpBase, T.Surface)

button("🌙 Travel to Moon", function()
    pcall(function() remotes.moon_travel:FireServer() end)
    print("[Warhead] Moon travel requested")
end, tpBase, T.Surface)

-- ═══════════════════════════════════════════
-- CHEAT LOOPS
-- ═══════════════════════════════════════════

-- AUTO-COLLECT INCOME (buildings produce cash over time, collect via prompt_action)
task.spawn(function()
    while gui.Parent do
        if State.autoCollect then
            statusLabel.Text = "collecting..."
            -- Find island prompts (collect income)
            for _, island in ipairs(CollectionService:GetTagged("island_prompt")) do
                if not State.autoCollect then break end
                if isOwnedByMe(island) then
                    pcall(function() prompt_action:FireServer(island, "collect") end)
                    task.wait(0.15)
                end
            end
            task.wait(2)
        else
            task.wait(0.5)
        end
    end
end)

-- AUTO-UPGRADE BUILDINGS
task.spawn(function()
    while gui.Parent do
        if State.autoUpgrade then
            statusLabel.Text = "upgrading..."
            -- Upgrade silos
            for _, silo in ipairs(CollectionService:GetTagged("silo_prompt")) do
                if not State.autoUpgrade then break end
                if isOwnedByMe(silo) and silo:GetAttribute("up_affordable") then
                    pcall(function() prompt_action:FireServer(silo, "upgrade") end)
                    print("[Warhead] Upgraded silo:", silo:GetAttribute("title"))
                    task.wait(0.2)
                end
            end
            -- Upgrade AA
            for _, aa in ipairs(CollectionService:GetTagged("aa_prompt")) do
                if not State.autoUpgrade then break end
                if isOwnedByMe(aa) and aa:GetAttribute("up_affordable") then
                    pcall(function() prompt_action:FireServer(aa, "upgrade") end)
                    print("[Warhead] Upgraded AA:", aa:GetAttribute("title"))
                    task.wait(0.2)
                end
            end
            task.wait(5)
        else
            task.wait(1)
        end
    end
end)

-- AUTO-OPERATE MINES
task.spawn(function()
    while gui.Parent do
        if State.autoMines then
            statusLabel.Text = "mining..."
            for _, desc in ipairs(game.Workspace:GetDescendants()) do
                if not State.autoMines then break end
                if desc:GetAttribute("mine_upgrade") ~= nil and isOwnedByMe(desc) then
                    pcall(function() prompt_action:FireServer(desc, "operate") end)
                    task.wait(0.3)
                end
            end
            task.wait(8)
        else
            task.wait(1)
        end
    end
end)

-- AUTO-FIRE SILOS
task.spawn(function()
    while gui.Parent do
        if State.autoFireSilos then
            statusLabel.Text = "firing silos..."
            for _, silo in ipairs(CollectionService:GetTagged("silo_prompt")) do
                if not State.autoFireSilos then break end
                if isOwnedByMe(silo) and silo:GetAttribute("shoot_ready") then
                    pcall(function() prompt_action:FireServer(silo, "shoot") end)
                    print("[Warhead] Fired silo:", silo:GetAttribute("title"))
                    task.wait(State.fireDelay)
                end
            end
            task.wait(3)
        else
            task.wait(1)
        end
    end
end)

-- AUTO-RELOAD SILOS
task.spawn(function()
    while gui.Parent do
        if State.autoReload then
            for _, silo in ipairs(CollectionService:GetTagged("silo_prompt")) do
                if not State.autoReload then break end
                if isOwnedByMe(silo) and not silo:GetAttribute("shoot_ready") then
                    local remaining = silo:GetAttribute("shoot_remaining") or 0
                    if remaining and remaining == 0 then
                        -- Try gems first, then robux
                        pcall(function() prompt_action:FireServer(silo, "reload_gems") end)
                        print("[Warhead] Reloaded silo:", silo:GetAttribute("title"))
                        task.wait(0.5)
                    end
                end
            end
            task.wait(5)
        else
            task.wait(1)
        end
    end
end)

-- AUTO-SCRAMBLE JETS
task.spawn(function()
    while gui.Parent do
        if State.autoScramble then
            statusLabel.Text = "scrambling jets..."
            for _, jet in ipairs(CollectionService:GetTagged("jet_prompt")) do
                if not State.autoScramble then break end
                if isOwnedByMe(jet) then
                    pcall(function() prompt_action:FireServer(jet, "scramble") end)
                    task.wait(0.3)
                end
            end
            task.wait(10)
        else
            task.wait(1)
        end
    end
end)

-- AUTO-UPGRADE SILOS
task.spawn(function()
    while gui.Parent do
        if State.autoUpgradeSilo then
            for _, silo in ipairs(CollectionService:GetTagged("silo_prompt")) do
                if not State.autoUpgradeSilo then break end
                if isOwnedByMe(silo) and silo:GetAttribute("up_affordable") then
                    pcall(function() prompt_action:FireServer(silo, "upgrade") end)
                    print("[Warhead] Auto-upgraded silo")
                    task.wait(0.2)
                end
            end
            task.wait(10)
        else
            task.wait(1)
        end
    end
end)

-- AUTO-UPGRADE AA
task.spawn(function()
    while gui.Parent do
        if State.autoUpgradeAA then
            for _, aa in ipairs(CollectionService:GetTagged("aa_prompt")) do
                if not State.autoUpgradeAA then break end
                if isOwnedByMe(aa) and aa:GetAttribute("up_affordable") then
                    pcall(function() prompt_action:FireServer(aa, "upgrade") end)
                    print("[Warhead] Auto-upgraded AA")
                    task.wait(0.2)
                end
            end
            task.wait(10)
        else
            task.wait(1)
        end
    end
end)

-- SPEED HACK / NOCLIP / ANTI-AFK
task.spawn(function()
    while gui.Parent do
        if State.speedHack then applySpeed() else restoreSpeed() end
        task.wait(0.2)
    end
    restoreMovement()
end)

-- Noclip
track(RunService.Stepped:Connect(function()
    if State.noclip then
        applyNoclip()
    else
        restoreNoclip()
    end
end))

-- Anti-AFK
local vu = game:GetService("VirtualUser")
if vu then
    track(LocalPlayer.Idled:Connect(function()
        if State.antiAfk then
            vu:CaptureController()
            vu:ClickButton2(Vector2.new())
            print("[Warhead] Anti-AFK triggered")
        end
    end))
end

-- ESP
task.spawn(function()
    local espFolder = Instance.new("Folder")
    espFolder.Name = "WarheadESP"
    espFolder.Parent = CoreGui

    while gui.Parent do
        if State.esp then
            -- Clear old
            espFolder:ClearAllChildren()
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local hrp2 = player.Character:FindFirstChild("HumanoidRootPart")
                    if hrp2 then
                        local bb = Instance.new("BillboardGui")
                        bb.Size = UDim2.fromOffset(120, 30)
                        bb.StudsOffset = Vector3.new(0, 4, 0)
                        bb.AlwaysOnTop = true
                        bb.Adornee = hrp2
                        bb.Parent = espFolder

                        local lbl = Instance.new("TextLabel")
                        lbl.Size = UDim2.new(1,0,1,0)
                        lbl.BackgroundTransparency = 0.5
                        lbl.BackgroundColor3 = Color3.fromRGB(0,0,0)
                        lbl.TextColor3 = T.Red
                        lbl.FontFace = FNT_B
                        lbl.TextSize = 12
                        lbl.Text = player.Name
                        lbl.Parent = bb
                        corner(lbl, 4)
                    end
                end
            end
            task.wait(2)
        else
            espFolder:ClearAllChildren()
            task.wait(1)
        end
    end
    espFolder:Destroy()
end)

-- Idle status updater
task.spawn(function()
    while gui.Parent do
        local active = false
        for _, key in ipairs({"autoCollect","autoUpgrade","autoFireSilos","autoReload","autoScramble","autoMines"}) do
            if State[key] then active = true; break end
        end
        if not active then statusLabel.Text = "idle" end
        task.wait(1)
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

Env._warheadCleanup = function()
    for key, value in pairs(State) do
        if typeof(value) == "boolean" then State[key] = false end
    end
    restoreMovement()
    for _, connection in ipairs(connections) do pcall(function() connection:Disconnect() end) end
    table.clear(connections)
    if Env._warheadState == State then Env._warheadState = nil end
    pcall(function() gui:Destroy() end)
end

-- ═══════════════════════════════════════════
-- INTRO
-- ═══════════════════════════════════════════
pcall(function()
    main.BackgroundTransparency = 1
    main.Size = UDim2.fromOffset(340, 0)
    task.wait(0.05)
    tw(main, TW_S, {Size = UDim2.fromOffset(340, 560), BackgroundTransparency = 0})
end)

-- Print stats on load
local siloCount = #CollectionService:GetTagged("silo_prompt")
local buildingCount = #CollectionService:GetTagged("building")
local aaCount = #CollectionService:GetTagged("aa_prompt")
local jetCount = #CollectionService:GetTagged("jet_prompt")
print(string.format("[Warhead v1] Cash: %s | Gems: %d", tostring(getCash()), getGems()))
print(string.format("[Warhead v1] Silos: %d | AA: %d | Jets: %d | Buildings: %d", siloCount, aaCount, jetCount, buildingCount))
print("[Warhead v1] Loaded | RightControl to toggle")

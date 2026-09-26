local APP = "SDK Demo"

DynamicIslandQueue = DynamicIslandQueue or {}
table.insert(DynamicIslandQueue, { app = APP, title = "SDK demo is loaded", icon = "check", level = "passive" })

local function Island()
    local di = DynamicIsland
    if type(di) == "table" and di.api then return di end
    return nil
end

local function Say(msg)
    Log.Write("[SDK Demo] " .. msg)
end

local function Notify(opts)
    local di = Island()
    if not di then
        Say("Dynamic Island is not loaded")
        return
    end
    opts.app = APP
    local id, err = di.Notify(opts)
    if not id then Say("notify failed: " .. tostring(err)) end
end

local Timer = { act = nil, ends = 0, len = 30 }
local Toggle = false
local Delivery = { act = nil, start = 0, len = 8 }

local function StartTimer()
    local di = Island()
    if not di then return end
    if Timer.act then Timer.act:End() end
    Timer.ends = os.clock() + Timer.len
    Timer.act = di.Activity.Start({
        app = APP,
        icon = "clock",
        tint = "orange",
        title = "Ancients stack",
        subtitle = "Pull the camp when the timer hits zero",
        timer = Timer.len,
        progress = 0,
        staleAfter = 120,
        onTap = function() Say("stack timer tapped") end,
        onEnd = function(reason) Say("stack timer ended by the island: " .. reason) end
    })
end

local function StartDelivery()
    local di = Island()
    if not di then return end
    if Delivery.act then Delivery.act:End() end
    Delivery.start = os.clock()
    Delivery.act = di.Activity.Start({
        app = APP,
        icon = "courier",
        tint = "blue",
        title = "Item delivery",
        subtitle = "Courier is on the way",
        trailing = "0%",
        progress = 0,
        onEnd = function(reason) Say("delivery ended by the island: " .. reason) end
    })
end

local function EndAll()
    if Timer.act then Timer.act:End() end
    if Delivery.act then Delivery.act:End() end
    Timer.act, Delivery.act = nil, nil
end

local tab = Menu.Create("General", "Dynamic Island", "SDK Demo")
local page = tab:Create("Demo")
local gN = page:Create("Notifications", Enum.GroupSide.Left)
local gA = page:Create("Live Activities", Enum.GroupSide.Right)

gN:Button("Send notification", function()
    Notify({
        title = "Stack the ancients in 0:10",
        icon = "stack",
        tint = "green",
        onTap = function() Say("notification tapped") end
    })
end)

gN:Button("Send with actions", function()
    Notify({
        title = "Ancients are ready to stack",
        body = "Pull at 0:53 from the left side so the creeps leave the camp before the minute mark.",
        icon = "stack",
        tint = "green",
        actions = {
            { title = "Remind at 0:50", fn = function() Say("remind pressed") end },
            { title = "Skip", destructive = true, fn = function() Say("skip pressed") end }
        }
    })
end)

gN:Button("Send toggle", function()
    Toggle = not Toggle
    Notify({ title = "Blink Dagger", icon = Toggle and "check" or "close", tint = Toggle and "green" or "red", trailing = Toggle and "On" or "Off", duration = 2.5 })
end)

gN:Button("Send time-sensitive", function()
    Notify({ title = "Roshan respawns in 0:30", icon = "swords", tint = "red", level = "time-sensitive", sound = "chime" })
end)

gN:Button("Send passive", function()
    Notify({ title = "Saved quietly to Notification Center", icon = "moon", tint = "indigo", level = "passive" })
end)

gN:Button("Spam 20 in a row", function()
    local di = Island()
    if not di then return end
    local sent, blocked = 0, 0
    for i = 1, 20 do
        local id = di.Notify({ app = APP, title = "Spam " .. i })
        if id then sent = sent + 1 else blocked = blocked + 1 end
    end
    Say(string.format("spam test: %d sent, %d blocked", sent, blocked))
end)

gA:Button("Play wheel sound", function()
    local di = Island()
    if di then di.PlaySound("wheel_notch", 0.8) end
end)
gA:Button("Start stack timer", StartTimer)
gA:Button("Start delivery", StartDelivery)
gA:Button("End activities", EndAll)

local function Tick()
    local now = os.clock()
    if Timer.act and Timer.act:IsActive() then
        local left = Timer.ends - now
        Timer.act:Update({ progress = 1 - math.max(0, left) / Timer.len })
        if left <= 0 then
            Timer.act:End({ title = "Stacked", trailing = "Done", progress = 1, after = 3 })
            Timer.act = nil
            Notify({ title = "Pull the camp now", icon = "stack", tint = "orange", level = "time-sensitive", sound = "success" })
        end
    end
    if Delivery.act and Delivery.act:IsActive() then
        local p = math.min(1, (now - Delivery.start) / Delivery.len)
        Delivery.act:Update({ progress = p, trailing = string.format("%d%%", math.floor(p * 100)) })
        if p >= 1 then
            Delivery.act:End({ subtitle = "Delivered", after = 2 })
            Delivery.act = nil
            Notify({ title = "Items delivered", icon = "courier", tint = "blue", sound = "success" })
        end
    end
end

return {
    OnFrame = Tick
}

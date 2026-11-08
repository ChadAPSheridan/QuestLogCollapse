-- Run from the repository root with: lua5.1 tests/button.lua
local frames, timers = {}, {}
local now, inCombat = 0, false
local methods = {}
local function frame()
    return setmetatable({ scripts = {}, events = {}, alpha = 1, children = {} }, { __index = methods })
end
function methods:SetScript(event, callback) self.scripts[event] = callback end
function methods:RegisterEvent(event) self.events[event] = true end
function methods:SetSize() end
function methods:SetPoint() end
function methods:SetText(text) self.text = text end
function methods:SetAlpha(alpha) self.alpha = alpha end
function methods:GetAlpha() return self.alpha end
function methods:GetChildren() return unpack(self.children) end
function methods:GetRegions() end
function methods:IsMouseClickEnabled() return self.clicks or false end
function methods:IsMouseMotionEnabled() return self.motion or false end
function methods:IsMouseWheelEnabled() return self.wheel or false end
function methods:SetMouseClickEnabled(enabled) assert(not inCombat); self.clicks = enabled end
function methods:SetMouseMotionEnabled(enabled) assert(not inCombat); self.motion = enabled end
function methods:EnableMouseWheel(enabled) assert(not inCombat); self.wheel = enabled end
function methods:SetCollapsed() error("Button must not call native collapse") end
function methods:MarkDirty() error("Button must not trigger tracker layout") end

local button
local globals = setmetatable({
    SlashCmdList = {},
    UIParent = frame(),
    QuestObjectiveTracker = frame(),
    CampaignQuestObjectiveTracker = frame(),
    ObjectiveTrackerFrame = frame(),
}, { __index = _G })
globals._G = globals
globals.CreateFrame = function(_, name, _, template)
    assert(name == nil)
    local result = frame()
    frames[#frames + 1] = result
    if template == "UIPanelButtonTemplate" then
        assert(not button)
        button = result
    end
    return result
end
globals.GetTime = function() return now end
globals.InCombatLockdown = function() return inCombat end
globals.IsInInstance = function() return false, "none" end
globals.GetCVar = function() return "0" end
globals.print = function() end
globals.C_Timer = {
    After = function(_, callback) timers[#timers + 1] = callback end,
    NewTicker = function() return { Cancel = function() end } end,
}

local settings = { enabled = false }
local profile = { enabled = true }
local ns = {
    InitializeConfigDB = function() end,
    db = {},
    GetCurrentQLCProfile = function() return profile end,
    GetCurrentInstanceSettings = function() return settings end,
}
local chunk = assert(loadfile("QuestLogCollapse.lua"))
setfenv(chunk, globals)
chunk("QuestLogCollapse", ns)

local function event(name, ...)
    for _, item in ipairs(frames) do
        if item.events[name] and item.scripts.OnEvent then
            item.scripts.OnEvent(item, name, ...)
        end
    end
end
local function update()
    for _, item in ipairs(frames) do
        if item.scripts.OnUpdate then item.scripts.OnUpdate(item) end
    end
end
local function click()
    assert(button and button.scripts.OnClick, "Show/hide button not created")
    button.scripts.OnClick(button)
end

local quest, campaign = globals.QuestObjectiveTracker, globals.CampaignQuestObjectiveTracker
local child = frame()
child.clicks, child.motion = true, true
quest.children = { child }

click()
assert(quest:GetAlpha() == 1, "Button acted before the tracker was ready")
event("ADDON_LOADED", "QuestLogCollapse")
event("PLAYER_ENTERING_WORLD")

-- A second click cancels an opacity restoration deferred by map activity.
click()
assert(quest:GetAlpha() == 0 and campaign:GetAlpha() == 0, "Button did not hide all sections")
assert(not child.clicks and not child.motion, "Hidden section still accepts mouse input")
click()
assert(quest:GetAlpha() == 0, "Map-busy restoration was not deferred")
click()
now = 16
update()
assert(quest:GetAlpha() == 0 and campaign:GetAlpha() == 0, "Stale restoration overrode the latest click")
click()
assert(quest:GetAlpha() == 1 and campaign:GetAlpha() == 1, "Button did not restore all sections")
assert(child.clicks and child.motion, "Mouse input was not restored")

-- The latest click wins in combat, independently of profile settings.
inCombat = true
event("PLAYER_REGEN_DISABLED")
click()
assert(quest:GetAlpha() == 1, "Button changed alpha during combat")
click()
click()
profile.enabled = false
inCombat = false
event("PLAYER_REGEN_ENABLED")
assert(quest:GetAlpha() == 0 and campaign:GetAlpha() == 0, "Queued hide-all was not applied")
inCombat = true
click()
inCombat = false
event("PLAYER_REGEN_ENABLED")
assert(quest:GetAlpha() == 1 and campaign:GetAlpha() == 1, "Queued show-all was not applied")

inCombat = true
click()
ns.HandleSlashCommand("expand")
inCombat = false
event("PLAYER_REGEN_ENABLED")
assert(quest:GetAlpha() == 1 and campaign:GetAlpha() == 1, "Slash command did not cancel queued hide-all")

-- Existing combat-induced transparency is recognized by the button.
profile.enabled = true
settings.enabled, settings.collapseQuests = true, true
inCombat = true
event("PLAYER_REGEN_DISABLED")
assert(quest:GetAlpha() == 0 and campaign:GetAlpha() == 1)
click()
inCombat = false
event("PLAYER_REGEN_ENABLED")
assert(quest:GetAlpha() == 1 and campaign:GetAlpha() == 1, "Button failed to show combat-hidden sections")
print("Show/hide button checks passed")

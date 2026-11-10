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
function methods:SetPoint(...) self.point = { ... } end
function methods:GetPoint() return unpack(self.point) end
function methods:ClearAllPoints() self.point = nil end
function methods:SetMovable(enabled) self.movable = enabled end
function methods:SetClampedToScreen(enabled) self.clamped = enabled end
function methods:RegisterForDrag(mouseButton) self.dragButton = mouseButton end
function methods:StartMoving() assert(self.movable); self.moving = true end
function methods:StopMovingOrSizing() self.moving = false end
function methods:SetText(text) self.text = text end
function methods:SetAlpha(alpha) self.alpha = alpha end
function methods:GetAlpha() return self.alpha end
function methods:GetChildren() return unpack(self.children) end
function methods:GetRegions() end
function methods:IsMouseClickEnabled() return self.clicks or false end
function methods:IsMouseMotionEnabled() return self.motion or false end
function methods:IsMouseWheelEnabled() return self.wheel or false end
function methods:CanChangeProtectedState() return not inCombat or not self.protected end
function methods:SetMouseClickEnabled(enabled) assert(self:CanChangeProtectedState()); self.clicks = enabled end
function methods:SetMouseMotionEnabled(enabled) assert(self:CanChangeProtectedState()); self.motion = enabled end
function methods:EnableMouseWheel(enabled) assert(self:CanChangeProtectedState()); self.wheel = enabled end
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
    charDB = { toggleButtonPosition = { point = "CENTER", relativePoint = "CENTER", x = 70, y = 40 } },
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
assert(button.point[1] == "CENTER" and button.point[4] == 70 and button.point[5] == 40, "Saved button position was not restored")
assert(button.dragButton == "RightButton" and button.clamped, "Button drag configuration missing")
button.scripts.OnDragStart(button)
assert(button.moving, "Button did not start moving")
button:SetPoint("TOPLEFT", globals.UIParent, "TOPLEFT", 120, -90)
button.scripts.OnDragStop(button)
assert(not button.moving and ns.charDB.toggleButtonPosition.x == 120 and ns.charDB.toggleButtonPosition.y == -90, "Button position was not saved")
assert(quest:GetAlpha() == 1, "Dragging toggled section visibility")

-- Button visibility changes do not wait for map activity.
click()
assert(quest:GetAlpha() == 0 and campaign:GetAlpha() == 0, "Button did not hide all sections")
assert(not child.clicks and not child.motion, "Hidden section still accepts mouse input")
click()
assert(quest:GetAlpha() == 1 and campaign:GetAlpha() == 1, "Map activity blocked button visibility")
assert(child.clicks and child.motion, "Mouse input was not restored")
click()
now = 16
update()
assert(quest:GetAlpha() == 0 and campaign:GetAlpha() == 0, "Latest hide click did not persist")
click()
assert(quest:GetAlpha() == 1 and campaign:GetAlpha() == 1, "Button did not restore all sections")
assert(child.clicks and child.motion, "Mouse input was not restored")

-- The latest click wins in combat, independently of profile settings.
inCombat = true
event("PLAYER_REGEN_DISABLED")
click()
assert(quest:GetAlpha() == 0 and campaign:GetAlpha() == 0, "Button did not hide sections immediately in combat")
assert(not child.clicks and not child.motion, "Mouse input was not disabled during combat")
click()
assert(quest:GetAlpha() == 1, "Second combat click did not show sections")
click()
profile.enabled = false
inCombat = false
event("PLAYER_REGEN_ENABLED")
assert(quest:GetAlpha() == 0 and campaign:GetAlpha() == 0, "Queued hide-all was not applied")
inCombat = true
click()
assert(quest:GetAlpha() == 1 and campaign:GetAlpha() == 1, "Button did not show sections during combat")
assert(child.clicks and child.motion, "Mouse input was not restored during combat")
inCombat = false
event("PLAYER_REGEN_ENABLED")
assert(quest:GetAlpha() == 1 and campaign:GetAlpha() == 1, "Queued show-all was not applied")
assert(child.clicks and child.motion, "Deferred mouse restoration did not run")

inCombat = true
click()
ns.HandleSlashCommand("expand")
inCombat = false
event("PLAYER_REGEN_ENABLED")
assert(quest:GetAlpha() == 1 and campaign:GetAlpha() == 1, "Slash command did not cancel queued hide-all")

-- Existing combat-induced transparency is recognized by the button.
profile.enabled = true
settings.enabled, settings.collapseQuests = true, true
quest:SetAlpha(0.6)
inCombat = true
event("PLAYER_REGEN_DISABLED")
assert(quest:GetAlpha() == 0 and campaign:GetAlpha() == 1)
click()
assert(quest:GetAlpha() == 1 and campaign:GetAlpha() == 1, "Combat-hidden section was not shown immediately")
click()
assert(quest:GetAlpha() == 0 and campaign:GetAlpha() == 0, "Combat hide did not apply immediately")
inCombat = false
event("PLAYER_REGEN_ENABLED")
assert(quest:GetAlpha() == 0 and campaign:GetAlpha() == 0, "Combat restoration overrode the manual hide")
click()
assert(quest:GetAlpha() == 1 and child.clicks, "Manual hide could not be reversed")

-- A show request supersedes an earlier map-deferred restoration even in combat.
settings.enabled = false
event("ZONE_CHANGED_NEW_AREA")
click()
ns.HandleSlashCommand("expand")
assert(quest:GetAlpha() == 0, "Map-busy restoration was not deferred")
inCombat = true
event("PLAYER_REGEN_DISABLED")
click()
assert(quest:GetAlpha() == 1 and campaign:GetAlpha() == 1, "Pending map restoration blocked showing in combat")
inCombat = false
event("PLAYER_REGEN_ENABLED")
now = 25
update()
assert(quest:GetAlpha() == 1 and child.clicks, "Deferred work undid the in-combat show")

-- A protected child must not prevent changes to unprotected descendants.
local protected = frame()
protected.protected, protected.clicks, protected.motion, protected.wheel = true, true, true, true
protected.children = { child }
quest.children = { protected }
inCombat = true
click()
assert(not child.clicks and not child.motion, "Unprotected descendant was not disabled")
assert(protected.clicks and protected.motion and protected.wheel, "Protected input changed in combat")
inCombat = false
event("PLAYER_REGEN_ENABLED")
assert(not protected.clicks and not protected.motion and not protected.wheel, "Protected input was not disabled after combat")
inCombat = true
click()
assert(child.clicks and child.motion, "Unprotected descendant was not restored")
assert(not protected.clicks and not protected.motion and not protected.wheel, "Protected input was restored in combat")
inCombat = false
event("PLAYER_REGEN_ENABLED")
assert(protected.clicks and protected.motion and protected.wheel, "Protected input was not restored after combat")
print("Show/hide button checks passed")

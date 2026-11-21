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
function methods:SetWidth() end
function methods:SetHeight(height) self.height = height end
function methods:SetFrameStrata() end
function methods:EnableKeyboard() end
function methods:SetPropagateKeyboardInput(enabled) self.propagateKeyboard = enabled end
function methods:SetJustifyH() end
function methods:GetStringHeight() return 12 end
function methods:SetScrollChild(child) self.scrollChild = child end
function methods:SetVerticalScroll(offset) self.scrollOffset = offset end
function methods:SetChecked(checked) self.checked = checked end
function methods:GetChecked() return self.checked end
function methods:SetBackdrop() end
function methods:SetBackdropColor() end
function methods:SetBackdropBorderColor() end
function methods:EnableMouse() end
function methods:SetPoint(...) self.point = { ... } end
function methods:GetPoint() return unpack(self.point) end
function methods:ClearAllPoints() self.point = nil end
function methods:SetMovable(enabled) self.movable = enabled end
function methods:SetClampedToScreen(enabled) self.clamped = enabled end
function methods:RegisterForDrag(mouseButton) self.dragButton = mouseButton end
function methods:StartMoving() assert(self.movable); self.moving = true end
function methods:StopMovingOrSizing() self.moving = false end
function methods:SetText(text) self.text = text end
function methods:SetTexture(texture) self.texture = texture end
function methods:SetColorTexture(...) self.color = { ... } end
function methods:SetRotation(rotation) self.rotation = rotation end
function methods:Show() self.shown = true end
function methods:Hide() self.shown = false end
function methods:CreateTexture()
    local result = frame()
    self.children[#self.children + 1] = result
    return result
end
function methods:SetAlpha(alpha) self.alpha = alpha end
function methods:GetAlpha() return self.alpha end
function methods:GetChildren() return unpack(self.children) end
function methods:GetRegions() end
function methods:CreateFontString()
    local result = frame()
    self.children[#self.children + 1] = result
    return result
end
function methods:IsMouseClickEnabled() return self.clicks or false end
function methods:IsMouseMotionEnabled() return self.motion or false end
function methods:IsMouseWheelEnabled() return self.wheel or false end
function methods:CanChangeProtectedState() return not inCombat or not self.protected end
function methods:SetMouseClickEnabled(enabled) assert(self:CanChangeProtectedState()); self.clicks = enabled end
function methods:SetMouseMotionEnabled(enabled) assert(self:CanChangeProtectedState()); self.motion = enabled end
function methods:EnableMouseWheel(enabled) assert(self:CanChangeProtectedState()); self.wheel = enabled end
function methods:SetCollapsed() error("Button must not call native collapse") end
function methods:MarkDirty() error("Button must not trigger tracker layout") end

local button, dropButton, controls, dialog, accept, cancel
local globals = setmetatable({
    SlashCmdList = {},
    StaticPopupDialogs = {},
    YES = "Yes", NO = "No",
    UIParent = frame(),
    QuestObjectiveTracker = frame(),
    CampaignQuestObjectiveTracker = frame(),
    ObjectiveTrackerFrame = frame(),
}, { __index = _G })
globals._G = globals
globals.CreateFrame = function(_, name, parent, template)
    assert(name == nil)
    local result = frame()
    frames[#frames + 1] = result
    if template == "UIPanelButtonTemplate" then
        if parent == controls then
            if not button then button = result else dropButton = result end
        elseif parent == dialog then
            if not accept then accept = result else cancel = result end
        end
    elseif template == "BackdropTemplate" then
        if not controls then controls = result else dialog = result end
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
local function assertToggleIcon(hidden)
    local icon = button.children[1]
    local expected = hidden
        and "Interface\\Icons\\inv_helm_armor_pirateeyepatch_b_01_black"
        or "Interface\\Icons\\inv_darkmoon_eye"
    assert(icon and icon.texture == expected, "Eye icon does not match tracker visibility")
end

local quest, campaign = globals.QuestObjectiveTracker, globals.CampaignQuestObjectiveTracker
local child = frame()
child.clicks, child.motion = true, true
quest.children = { child }

click()
assert(quest:GetAlpha() == 1, "Button acted before the tracker was ready")
event("ADDON_LOADED", "QuestLogCollapse")
event("PLAYER_ENTERING_WORLD")
assert(controls.point[1] == "CENTER" and controls.point[4] == 70 and controls.point[5] == 40, "Saved button position was not restored")
assert(button.dragButton == "RightButton" and dropButton.dragButton == "RightButton" and controls.clamped, "Frame drag configuration missing")
button.scripts.OnDragStart(button)
assert(controls.moving, "Frame did not start moving")
controls:SetPoint("TOPLEFT", globals.UIParent, "TOPLEFT", 120, -90)
button.scripts.OnDragStop(button)
assert(not controls.moving and ns.charDB.toggleButtonPosition.x == 120 and ns.charDB.toggleButtonPosition.y == -90, "Frame position was not saved")
assert(quest:GetAlpha() == 1, "Dragging toggled section visibility")

-- A config request is independent of queued tracker changes and opens only once.
local configOpens = 0
ns.CreateQuestLogCollapseConfigPanel = function()
    return { Show = function() configOpens = configOpens + 1 end }
end
inCombat = true
ns.HandleSlashCommand("config")
click()
assert(configOpens == 0, "Config opened during combat")
inCombat = false
event("PLAYER_REGEN_ENABLED")
assert(configOpens == 1, "Deferred config did not open alongside queued tracker changes")
assert(quest:GetAlpha() == 0, "Queued tracker change was not applied")
event("PLAYER_REGEN_ENABLED")
assert(configOpens == 1, "Deferred config opened more than once")
click()

-- Button visibility changes do not wait for map activity.
click()
assert(quest:GetAlpha() == 0 and campaign:GetAlpha() == 0, "Button did not hide all sections")
assertToggleIcon(true)
assert(not child.clicks and not child.motion, "Hidden section still accepts mouse input")
click()
assert(quest:GetAlpha() == 1 and campaign:GetAlpha() == 1, "Map activity blocked button visibility")
assertToggleIcon(false)
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

-- Gray quest selection includes collapsed headers, but excludes hidden and non-abandonable quests.
local groups = {
    { isHeader = true, isCollapsed = true, quests = {
        { questID = 1, title = "First quest" }, { questID = 2 }, { questID = 3, isHidden = true },
        { questID = 8 },
    } },
    { isHeader = true, isCollapsed = true, quests = {
        { questID = 4, title = "Fourth quest" }, { questID = 5 }, { questID = 6, title = "Sixth quest" },
    } },
    { isHeader = true, isCollapsed = false, quests = { { questID = 7 } } },
}
local difficulties = { [1] = 0, [2] = 1, [3] = 0, [4] = 0, [5] = 0, [6] = 0, [7] = 1, [8] = 0 }
local onQuest = { [1] = true, [2] = true, [3] = true, [4] = true, [5] = true, [6] = true, [7] = true, [8] = true }
local canAbandon = { [1] = true, [2] = true, [3] = true, [4] = true, [5] = false, [6] = true, [7] = true, [8] = true }
local selected, abandon, dropped = 2, nil, {}
local function entries()
    local result = {}
    for _, group in ipairs(groups) do
        result[#result + 1] = group
        if not group.isCollapsed then
            for _, item in ipairs(group.quests) do result[#result + 1] = item end
        end
    end
    return result
end
globals.C_QuestLog = {
    GetNumQuestLogEntries = function() return #entries() end,
    GetInfo = function(index) return entries()[index] end,
    CanAbandonQuest = function(id) return canAbandon[id] end,
    IsOnQuest = function(id) return onQuest[id] end,
    GetSelectedQuest = function() return selected end,
    SetSelectedQuest = function(id) selected = id end,
    SetAbandonQuest = function() abandon = selected end,
    AbandonQuest = function() dropped[#dropped + 1] = abandon; onQuest[abandon] = false end,
}
globals.C_PlayerInfo = { GetContentDifficultyQuestForPlayer = function(id) return difficulties[id] end }
globals.Enum = { RelativeContentDifficulty = { Trivial = 0 } }
globals.ExpandQuestHeader = function(index) entries()[index].isCollapsed = false end
globals.CollapseQuestHeader = function(index) entries()[index].isCollapsed = true end
dropButton.scripts.OnClick()
assert(dialog and dialog.shown and #dialog.rows == 4, "Wrong gray quest count")
assert(dialog.rows[1].label.text == "First quest" and dialog.rows[2].label.text == "Quest 8"
    and dialog.rows[3].label.text == "Fourth quest" and dialog.rows[4].label.text == "Sixth quest",
    "Quest titles missing or out of order")
for _, row in ipairs(dialog.rows) do assert(row:GetChecked(), "Quest not checked by default") end
assert(groups[1].isCollapsed and groups[2].isCollapsed and not groups[3].isCollapsed, "Quest header states changed")
assert(#dropped == 0, "Quests abandoned without confirmation")
dialog.rows[1]:SetChecked(false)
difficulties[4] = 1
onQuest[8] = false
accept.scripts.OnClick()
assert(not dialog.shown and #dropped == 1 and dropped[1] == 6, "Confirmation ignored selection or eligibility")
assert(selected == 2, "Previous quest selection was not restored")

-- Reopening resets selections and hides stale rows; cancellation does nothing.
dropButton.scripts.OnClick()
assert(dialog.shown and dialog.rows[1].questID == 1 and dialog.rows[1]:GetChecked(), "Reopening did not reset selection")
assert(not dialog.rows[2].shown and not dialog.rows[3].shown and not dialog.rows[4].shown, "Stale rows remain visible")
cancel.scripts.OnClick()
assert(not dialog.shown and #dropped == 1, "Cancellation abandoned quests")
dropButton.scripts.OnClick()
dialog.scripts.OnKeyDown(dialog, "ESCAPE")
assert(not dialog.shown and not dialog.propagateKeyboard and #dropped == 1, "Escape did not cancel")
dropButton.scripts.OnClick()
dialog.scripts.OnKeyDown(dialog, "A")
assert(dialog.shown and dialog.propagateKeyboard, "Other keys were not propagated")
dialog.rows[1]:SetChecked(false)
accept.scripts.OnClick()
assert(#dropped == 1, "An unchecked quest was abandoned")

dropButton.scripts.OnClick()
inCombat = true
accept.scripts.OnClick()
assert(#dropped == 1, "Confirmation abandoned quests in combat")
dropButton.scripts.OnClick()
assert(not dialog.shown, "Drop button opened confirmation in combat")
inCombat = false
canAbandon[1] = false
dropButton.scripts.OnClick()
assert(not dialog.shown, "Empty gray quest list opened confirmation")

-- A long list remains scrollable and its selections are all honored.
for id = 10, 25 do
    groups[3].quests[#groups[3].quests + 1] = { questID = id, title = "Quest " .. id }
    difficulties[id], onQuest[id], canAbandon[id] = 0, true, true
end
dropButton.scripts.OnClick()
assert(dialog.shown and #dialog.rows == 16 and dialog.content.height == 16 * 24, "Long list did not size its scroll content")
dialog.scroll:SetVerticalScroll(100)
dialog.rows[16]:SetChecked(false)
accept.scripts.OnClick()
assert(#dropped == 16 and dropped[16] == 24 and onQuest[25], "Long-list selection was not honored")
dropButton.scripts.OnClick()
assert(dialog.shown and dialog.scroll.scrollOffset == 0 and dialog.rows[1]:GetChecked(), "Reopened list did not reset")
cancel.scripts.OnClick()
print("Show/hide button checks passed")

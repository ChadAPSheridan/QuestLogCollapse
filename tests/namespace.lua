-- Run from the repository root with: lua5.1 tests/namespace.lua
local function run(savedDB, savedCharDB)
    local frames, timers, messages = {}, {}, {}
    local now, inCombat, instanceType = 0, false, "none"
    local enemyNameplates = "0"
    local allowedGlobals = {
        QuestLogCollapseDB = true,
        QuestLogCollapseCharDB = true,
        MyAddonDB = true,
        SLASH_QUESTLOGCOLLAPSE1 = true,
        SLASH_QUESTLOGCOLLAPSE2 = true,
    }
    local globals = {
        QuestLogCollapseDB = savedDB,
        QuestLogCollapseCharDB = savedCharDB,
        SlashCmdList = {},
        StaticPopupDialogs = {},
    }
    for _, name in ipairs({
        "assert", "error", "ipairs", "next", "pairs", "select",
        "tonumber", "tostring", "type", "string", "table", "math",
    }) do
        globals[name] = _G[name]
    end
    local env = setmetatable({}, {
        __index = globals,
        __newindex = function(_, key, value)
            assert(allowedGlobals[key], "Unexpected global write: " .. tostring(key))
            globals[key] = value
        end,
    })
    globals._G = env
    globals.date = os.date

    local methods = {}
    for _, name in ipairs({
        "SetSize", "SetPoint", "SetBackdrop", "SetBackdropColor",
        "SetBackdropBorderColor", "SetTextColor", "SetColorTexture",
        "SetHeight", "SetScrollChild", "Disable", "SetMotionScriptsWhileDisabled",
        "SetMovable", "SetClampedToScreen", "RegisterForDrag",
    }) do
        methods[name] = function() end
    end
    local function widget()
        return setmetatable({ scripts = {}, events = {}, shown = true, children = {}, regions = {} }, { __index = methods })
    end
    function methods:SetScript(event, callback) self.scripts[event] = callback end
    function methods:HookScript(event, callback)
        local previous = self.scripts[event]
        self.scripts[event] = function(...)
            if previous then previous(...) end
            callback(...)
        end
    end
    function methods:RegisterEvent(event) self.events[event] = true end
    function methods:UnregisterEvent(event) self.events[event] = nil end
    function methods:CreateFontString() return widget() end
    function methods:CreateTexture() return widget() end
    function methods:SetText(text) self.text = text end
    function methods:GetText() return self.text end
    function methods:SetChecked(checked) self.checked = checked end
    function methods:GetChecked() return self.checked end
    function methods:GetName() return self.name end
    function methods:IsShown() return self.shown end
    function methods:SetAlpha(alpha) self.alpha = alpha end
    function methods:GetAlpha() return self.alpha or 1 end
    function methods:GetChildren() return unpack(self.children) end
    function methods:GetRegions() return unpack(self.regions) end
    function methods:IsMouseClickEnabled() return self.mouseClick or false end
    function methods:IsMouseMotionEnabled() return self.mouseMotion or false end
    function methods:IsMouseWheelEnabled() return self.mouseWheel or false end
    function methods:CanChangeProtectedState() return not inCombat end
    function methods:SetMouseClickEnabled(enabled) assert(not inCombat); self.mouseClick = enabled end
    function methods:SetMouseMotionEnabled(enabled) assert(not inCombat); self.mouseMotion = enabled end
    function methods:EnableMouseWheel(enabled) assert(not inCombat); self.mouseWheel = enabled end
    function methods:Hide() self.shown = false end
    function methods:Show()
        if self.shown then return end
        self.shown = true
        if self.scripts.OnShow then self.scripts.OnShow(self) end
    end

    globals.CreateFrame = function(_, name)
        assert(name == nil, "Addon frames must be anonymous")
        local frame = widget()
        frame.Text = widget()
        frames[#frames + 1] = frame
        return frame
    end
    globals.UIParent = widget()
    globals.GetTime = function() return now end
    globals.InCombatLockdown = function() return inCombat end
    globals.IsInInstance = function() return instanceType ~= "none", instanceType end
    globals.Enum = { GarrisonType = { Type_6_0_Garrison = 1, Type_7_0_Garrison = 2, Type_8_0_Garrison = 3 } }
    globals.C_Garrison = {
        IsPlayerInGarrison = function() return false end,
        IsAtGarrisonMissionNPC = function() return false end,
    }
    globals.GetCVar = function(name)
        return name == "nameplateShowEnemies" and enemyNameplates or "0"
    end
    globals.SetCVar = function(name, value)
        assert(name == "nameplateShowEnemies")
        enemyNameplates = value
    end
    globals.print = function(message) messages[#messages + 1] = message end
    globals.securecall = function(callback) callback(); return true end
    globals.C_Timer = {
        After = function(_, callback) timers[#timers + 1] = callback end,
        NewTicker = function() return { Cancel = function() end } end,
    }
    globals.UIDropDownMenu_SetWidth = function() end
    globals.UIDropDownMenu_SetSelectedValue = function(frame, value) frame.selected = value end
    globals.UIDropDownMenu_Initialize = function(frame, callback) frame.initialize = callback end
    globals.UIDropDownMenu_CreateInfo = function() return {} end
    globals.UIDropDownMenu_AddButton = function() end
    local categories = {}
    globals.Settings = {
        RegisterCanvasLayoutCategory = function(frame)
            categories[#categories + 1] = frame
            return { ID = #categories }
        end,
        RegisterCanvasLayoutSubcategory = function(_, frame)
            categories[#categories + 1] = frame
            return { ID = #categories }
        end,
        RegisterAddOnCategory = function() end,
        OpenToCategory = function(id) categories[id]:Show() end,
    }
    local trackers = {}
    for _, name in ipairs({
        "QuestObjectiveTracker", "AchievementObjectiveTracker", "BonusObjectiveTracker",
        "ScenarioObjectiveTracker", "CampaignQuestObjectiveTracker", "WorldQuestObjectiveTracker",
        "ProfessionsRecipeTracker", "MonthlyActivitiesObjectiveTracker",
        "UIWidgetObjectiveTracker", "AdventureMapQuestObjectiveTracker",
    }) do
        local tracker = widget()
        tracker.isCollapsed = true
        function tracker:SetCollapsed() error("Native collapse must not be called") end
        function tracker:MarkDirty() error("Tracker layout must not be dirtied") end
        trackers[#trackers + 1] = tracker
        globals[name] = tracker
    end
    globals.ObjectiveTrackerFrame = widget()
    local header, child, text = widget(), widget(), widget()
    header.mouseClick, header.mouseMotion = true, true
    child.mouseClick, child.mouseWheel = true, true
    text.mouseMotion = true
    globals.QuestObjectiveTracker.children = { header, child }
    child.regions = { text }

    local function event(name, ...)
        for _, frame in ipairs(frames) do
            if frame.events[name] and frame.scripts.OnEvent then
                frame.scripts.OnEvent(frame, name, ...)
            end
        end
    end
    local function update()
        local count = #frames
        for i = 1, count do
            local frame = frames[i]
            if frame.scripts.OnUpdate then frame.scripts.OnUpdate(frame) end
        end
    end
    local function runTimers()
        local queued = timers
        timers = {}
        for _, callback in ipairs(queued) do callback() end
    end
    local ns = {}
    for line in io.lines("QuestLogCollapse.toc") do
        if line:match("%.lua$") then
            local chunk = assert(loadfile(line))
            setfenv(chunk, env)
            chunk("QuestLogCollapse", ns)
        end
    end

    assert(globals.QuestLogCollapseDB == savedDB, "DB initialized before ADDON_LOADED")
    event("ADDON_LOADED", "OtherAddon")
    assert(ns.db == nil, "Another addon's load initialized the DB")
    event("ADDON_LOADED", "QuestLogCollapse")
    assert(ns.db == globals.QuestLogCollapseDB)
    assert(ns.charDB == globals.QuestLogCollapseCharDB)
    if savedDB then assert(ns.db == savedDB, "Saved DB identity changed") end
    if savedCharDB then assert(ns.charDB == savedCharDB, "Character DB identity changed") end
    local originalProfile = ns.GetCurrentQLCProfile()
    assert(originalProfile == ns.db.profiles[ns.charDB.currentProfile])

    event("PLAYER_ENTERING_WORLD")
    assert(#categories == 5, "Settings categories not registered")
    assert(globals.SLASH_QUESTLOGCOLLAPSE1 == "/qlc")
    assert(globals.SLASH_QUESTLOGCOLLAPSE2 == "/questlogcollapse")
    assert(globals.SlashCmdList.QUESTLOGCOLLAPSE == ns.HandleSlashCommand)
    assert(globals.StaticPopupDialogs.QUESTLOGCOLLAPSE_NEW_PROFILE == ns.NewProfileDialog)
    for key in pairs(globals.SlashCmdList) do assert(key == "QUESTLOGCOLLAPSE") end
    for key in pairs(globals.StaticPopupDialogs) do assert(key == "QUESTLOGCOLLAPSE_NEW_PROFILE") end
    ns.HandleSlashCommand("config")
    assert(#categories == 5, "Opening settings duplicated registration")

    local enabled = originalProfile.enabled
    ns.HandleSlashCommand("toggle")
    assert(originalProfile.enabled == not enabled)
    ns.HandleSlashCommand("toggle")
    local editBox = widget()
    editBox:SetText("  Namespace Test  ")
    ns.NewProfileDialog.OnAccept({ editBox = editBox })
    assert(ns.charDB.currentProfile == "Namespace Test")
    assert(ns.GetCurrentQLCProfile() == ns.db.profiles["Namespace Test"])
    assert(ns.GetCurrentQLCProfile() ~= originalProfile)
    ns.SwitchProfile("Default")
    assert(ns.GetCurrentQLCProfile() == ns.db.profiles.Default)

    local defaultSettings = ns.GetCurrentQLCProfile().defaultSettings
    assert(ns.GetCurrentInstanceSettings() == defaultSettings, "Open-world context did not use default settings")
    defaultSettings.enabled, defaultSettings.collapseQuests = true, true
    for key in pairs(defaultSettings) do
        if key:match("^collapse") then defaultSettings[key] = true end
    end
    defaultSettings.namePlates.enabled = true
    ns.UpdateNamePlates()
    assert(enemyNameplates == "1", "Default settings did not enable enemy nameplates")
    local dungeonSettings = ns.GetCurrentQLCProfile().dungeons
    dungeonSettings.enabled = false
    instanceType = "party"
    assert(ns.GetCurrentInstanceSettings() == defaultSettings, "Disabled instance settings did not fall back to defaults")
    dungeonSettings.enabled = true
    assert(ns.GetCurrentInstanceSettings() == dungeonSettings, "Enabled instance settings were not selected")
    dungeonSettings.namePlates.enabled = false
    ns.UpdateNamePlates()
    assert(enemyNameplates == "0", "Zone settings did not restore the original nameplate state")
    dungeonSettings.namePlates.enabled = true
    ns.UpdateNamePlates()
    assert(enemyNameplates == "1", "Instance settings did not enable enemy nameplates")
    instanceType = "none"
    defaultSettings.namePlates.enabled = false
    ns.UpdateNamePlates()
    assert(enemyNameplates == "0", "Default settings did not restore the original nameplate state")
    ns.HandleSlashCommand("collapse")
    for _, tracker in ipairs(trackers) do
        assert(tracker:GetAlpha() == 0, "Manual transparency was not applied")
    end
    now = 16
    update()
    update()
    for _, tracker in ipairs(trackers) do
        assert(tracker:GetAlpha() == 0, "Pending transparency was not applied to every section")
        assert(tracker.isCollapsed == true, "Native collapsed state changed")
        assert(tracker:IsShown(), "Transparency must not hide the frame")
    end
    assert(not header.mouseClick and not header.mouseMotion, "Header remains interactive")
    assert(not child.mouseClick and not child.mouseWheel, "Child remains interactive")
    assert(not text.mouseMotion, "Nested region remains interactive")
    local dynamic = widget()
    dynamic.mouseClick, dynamic.mouseMotion = true, true
    child.children = { dynamic }
    update()
    assert(not dynamic.mouseClick and not dynamic.mouseMotion, "New child remains interactive")
    child.children = {}
    update()
    assert(dynamic.mouseClick and dynamic.mouseMotion, "Reparented child was not restored")
    child.children = { dynamic }
    update()
    assert(not dynamic.mouseClick, "Reused child remains interactive")
    dynamic.mouseWheel = true
    update()
    assert(not dynamic.mouseWheel, "Re-enabled mouse input was not suppressed")
    ns.HandleSlashCommand("collapse")
    assert(not header.mouseClick, "Repeated transparency re-enabled input")
    assert(globals.ObjectiveTrackerFrame:GetAlpha() == 1, "Whole tracker was made transparent")
    ns.HandleSlashCommand("expand")
    update()
    for _, tracker in ipairs(trackers) do
        assert(tracker:GetAlpha() == 1, "Section opacity was not restored")
        assert(tracker.isCollapsed == true, "Native collapsed state changed on restoration")
    end
    assert(header.mouseClick and header.mouseMotion, "Header mouse state was not restored")
    assert(child.mouseClick and child.mouseWheel and not child.mouseMotion, "Child mouse state was not restored")
    assert(text.mouseMotion and not text.mouseClick, "Region mouse state was not restored")
    assert(dynamic.mouseClick and dynamic.mouseMotion and dynamic.mouseWheel, "Dynamic child mouse state was not restored")
    defaultSettings.collapseScenarios = false
    ns.HandleSlashCommand("collapse")
    assert(globals.ScenarioObjectiveTracker:GetAlpha() == 1, "Unselected section was changed")
    assert(globals.QuestObjectiveTracker:GetAlpha() == 0, "Selected section was not made transparent")
    inCombat = true
    local combatChild = widget()
    combatChild.mouseClick = true
    child.children = { dynamic, combatChild }
    update()
    assert(combatChild.mouseClick, "Mouse input changed during combat")
    inCombat = false
    update()
    assert(not combatChild.mouseClick, "Combat-created child was not suppressed after combat")
    inCombat = true
    ns.HandleSlashCommand("expand")
    assert(globals.QuestObjectiveTracker:GetAlpha() == 0, "Alpha changed during combat")
    update()
    assert(not header.mouseClick, "Mouse state changed during combat")
    inCombat = false
    event("PLAYER_REGEN_ENABLED")
    update()
    assert(globals.QuestObjectiveTracker:GetAlpha() == 1, "Combat-deferred opacity was not restored")
    assert(combatChild.mouseClick, "Combat-created child mouse state was not restored")

    -- Combat restores only sections it made transparent, including non-default alpha.
    globals.QuestObjectiveTracker:SetAlpha(0.6)
    globals.AchievementObjectiveTracker:SetAlpha(0)
    inCombat = true
    event("PLAYER_REGEN_DISABLED")
    assert(globals.QuestObjectiveTracker:GetAlpha() == 0, "Combat did not apply transparency")
    assert(globals.AchievementObjectiveTracker:GetAlpha() == 0, "Already transparent section changed")
    inCombat = false
    event("PLAYER_REGEN_ENABLED")
    assert(globals.QuestObjectiveTracker:GetAlpha() == 0.6, "Combat did not restore original alpha")
    assert(globals.AchievementObjectiveTracker:GetAlpha() == 0, "Pre-existing transparency was lost")
    assert(header.mouseClick and header.mouseMotion, "Combat did not restore mouse interaction")
    ns.HandleSlashCommand("expand")

    -- A section already hidden by the addon must stay hidden after combat.
    ns.HandleSlashCommand("collapse")
    inCombat = true
    event("PLAYER_REGEN_DISABLED")
    inCombat = false
    event("PLAYER_REGEN_ENABLED")
    assert(globals.QuestObjectiveTracker:GetAlpha() == 0, "Combat restored a previously hidden section")
    assert(not header.mouseClick, "Previously hidden section regained mouse input")
    ns.HandleSlashCommand("expand")

    -- Explicit combat commands take precedence over automatic restoration.
    inCombat = true
    event("PLAYER_REGEN_DISABLED")
    ns.HandleSlashCommand("collapse")
    inCombat = false
    event("PLAYER_REGEN_ENABLED")
    assert(globals.QuestObjectiveTracker:GetAlpha() == 0, "Queued transparency was lost at combat end")
    ns.HandleSlashCommand("expand")

    inCombat = true
    event("PLAYER_REGEN_DISABLED")
    ns.HandleSlashCommand("expand")
    inCombat = false
    event("PLAYER_REGEN_ENABLED")
    assert(globals.QuestObjectiveTracker:GetAlpha() == 1, "Queued restoration was lost at combat end")

    inCombat = true
    event("PLAYER_REGEN_DISABLED")
    ns.GetCurrentQLCProfile().enabled = false
    inCombat = false
    event("PLAYER_REGEN_ENABLED")
    assert(globals.QuestObjectiveTracker:GetAlpha() == 1, "Disabling the addon prevented combat restoration")
    ns.GetCurrentQLCProfile().enabled = true

    instanceType = "party"
    dungeonSettings.enabled, dungeonSettings.collapseCampaigns = true, true
    event("ZONE_CHANGED_NEW_AREA")
    now = 25
    update()
    runTimers()
    assert(globals.CampaignQuestObjectiveTracker:GetAlpha() == 0, "Instance entry did not apply transparency")
    assert(globals.QuestObjectiveTracker:GetAlpha() == 1, "Instance entry changed an unselected section")
    dungeonSettings.collapseQuests = true
    inCombat = true
    event("PLAYER_REGEN_DISABLED")
    assert(globals.QuestObjectiveTracker:GetAlpha() == 0, "Instance combat did not apply transparency")
    inCombat = false
    event("PLAYER_REGEN_ENABLED")
    assert(globals.QuestObjectiveTracker:GetAlpha() == 1, "Instance combat did not restore newly hidden section")
    assert(globals.CampaignQuestObjectiveTracker:GetAlpha() == 0, "Instance combat restored a previously hidden section")
    instanceType = "none"
    event("ZONE_CHANGED_NEW_AREA")
    now = 34
    update()
    runTimers()
    for _, tracker in ipairs(trackers) do
        assert(tracker:GetAlpha() == 1, "Instance exit did not restore section opacity")
    end

    for _, command in ipairs({
        "help", "debug", "status", "diag", "test", "testcombat",
        "filterzone", "clearpending", "unknown",
    }) do
        ns.HandleSlashCommand(command)
    end
end

run()
local profile = {
    enabled = false,
    debug = false,
    combat = { enabled = true, collapseQuests = true },
    dungeons = { collapseCampaigns = false },
}
local db = { profiles = { Default = {}, Existing = profile } }
local charDB = { currentProfile = "Existing" }
run(db, charDB)
assert(db.profiles.Existing == profile)
assert(profile.enabled == false and profile.dungeons.collapseCampaigns == false)
assert(profile.combat == nil, "Legacy combat settings were not migrated")
assert(profile.defaultSettings.enabled == true and profile.defaultSettings.collapseQuests == true)
print("Namespace isolation and addon lifecycle checks passed")

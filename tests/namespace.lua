-- Run from the repository root with: lua5.1 tests/namespace.lua
local function run(savedDB, savedCharDB)
    local frames, timers, messages = {}, {}, {}
    local now, inCombat = 0, false
    local allowedGlobals = {
        QuestLogCollapseDB = true,
        QuestLogCollapseCharDB = true,
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

    local methods = {}
    for _, name in ipairs({
        "SetSize", "SetPoint", "SetBackdrop", "SetBackdropColor",
        "SetBackdropBorderColor", "SetTextColor", "SetColorTexture",
        "SetHeight", "SetScrollChild", "Disable", "SetMotionScriptsWhileDisabled",
    }) do
        methods[name] = function() end
    end
    local function widget()
        return setmetatable({ scripts = {}, events = {}, shown = true }, { __index = methods })
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
    globals.IsInInstance = function() return false, "none" end
    globals.GetCVar = function() return "0" end
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
    globals.QuestObjectiveTracker = widget()
    function globals.QuestObjectiveTracker:SetCollapsed(collapsed) self.collapsed = collapsed end
    globals.ObjectiveTrackerFrame = widget()

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

    -- Deferred work must reach the shared processor after map activity ends.
    local combat = ns.GetCurrentQLCProfile().combat
    combat.enabled, combat.collapseQuests = true, true
    ns.HandleSlashCommand("collapse")
    assert(globals.QuestObjectiveTracker.collapsed == nil)
    now = 16
    update()
    update()
    assert(globals.QuestObjectiveTracker.collapsed == true, "Pending collapse was not processed")
    ns.HandleSlashCommand("expand")
    update()
    assert(globals.QuestObjectiveTracker.collapsed == false)
    inCombat = true
    ns.HandleSlashCommand("expand")
    inCombat = false
    event("PLAYER_REGEN_ENABLED")
    update()
    for _, command in ipairs({
        "help", "debug", "status", "diag", "test", "testcombat",
        "filterzone", "clearpending", "unknown",
    }) do
        ns.HandleSlashCommand(command)
    end
end

run()
local profile = { enabled = false, debug = false, dungeons = { collapseCampaigns = false } }
local db = { profiles = { Default = {}, Existing = profile } }
local charDB = { currentProfile = "Existing" }
run(db, charDB)
assert(db.profiles.Existing == profile)
assert(profile.enabled == false and profile.dungeons.collapseCampaigns == false)
print("Namespace isolation and addon lifecycle checks passed")

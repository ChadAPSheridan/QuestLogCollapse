-- QuestLogCollapse Configuration Panel
-- Author: Gaspode
-- Contributors: Artherion77 (significant ui revamp in 1.4.0)
-- Version: 1.4.0
-- Updated: 2024-06-14


local addonName, ns = ...

-- ============================================================
-- DEFAULTS
-- ============================================================
local defaults = {
    enabled = true,
    debug = false,
    filterQuestsByZone = false,
    filterQuestsByZoneMode = "openworld",  -- "openworld" | "always"
    questInteractionCollapseBehavior = "skip_section", -- "off" | "skip_section" | "untrack_others"
    combat = {
        enabled = false,
        collapseQuests = false, collapseAchievements = false,
        collapseBonusObjectives = false, collapseScenarios = false, collapseCampaigns = false,
        collapseProfessions = false, collapseMonthlyActivities = false,
        collapseUIWidgets = false, collapseAdventureMaps = false, collapseWorldQuests = false,
        namePlates = { enabled = false },
    },
    dungeons = {
        enabled = true,
        collapseQuests = false, collapseAchievements = false,
        collapseBonusObjectives = false, collapseScenarios = false, collapseCampaigns = true,
        collapseProfessions = false, collapseMonthlyActivities = false,
        collapseUIWidgets = false, collapseAdventureMaps = false, collapseWorldQuests = false,
        namePlates = { enabled = false },
    },
    raids = {
        enabled = true,
        collapseQuests = false, collapseAchievements = false,
        collapseBonusObjectives = false, collapseScenarios = false, collapseCampaigns = true,
        collapseProfessions = false, collapseMonthlyActivities = false,
        collapseUIWidgets = false, collapseAdventureMaps = false, collapseWorldQuests = false,
        namePlates = { enabled = false },
    },
    scenarios = {
        enabled = false,
        collapseQuests = false, collapseAchievements = false,
        collapseBonusObjectives = false, collapseScenarios = true, collapseCampaigns = false,
        collapseProfessions = false, collapseMonthlyActivities = false,
        collapseUIWidgets = false, collapseAdventureMaps = false, collapseWorldQuests = false,
        namePlates = { enabled = false },
    },
    battlegrounds = {
        enabled = false,
        collapseQuests = false, collapseAchievements = false,
        collapseBonusObjectives = false, collapseScenarios = false, collapseCampaigns = false,
        collapseProfessions = false, collapseMonthlyActivities = false,
        collapseUIWidgets = false, collapseAdventureMaps = false, collapseWorldQuests = false,
        namePlates = { enabled = false },
    },
    arenas = {
        enabled = false,
        collapseQuests = false, collapseAchievements = false,
        collapseBonusObjectives = false, collapseScenarios = false, collapseCampaigns = false,
        collapseProfessions = false, collapseMonthlyActivities = false,
        collapseUIWidgets = false, collapseAdventureMaps = false, collapseWorldQuests = false,
        namePlates = { enabled = false },
    },
    garrisons = {
        enabled = false,
        collapseQuests = false, collapseAchievements = false,
        collapseBonusObjectives = false, collapseScenarios = false, collapseCampaigns = false,
        collapseProfessions = false, collapseMonthlyActivities = false,
        collapseUIWidgets = false, collapseAdventureMaps = false, collapseWorldQuests = false,
        namePlates = { enabled = false },
    },
    classHalls = {
        enabled = false,
        collapseQuests = false, collapseAchievements = false,
        collapseBonusObjectives = false, collapseScenarios = false, collapseCampaigns = false,
        collapseProfessions = false, collapseMonthlyActivities = false,
        collapseUIWidgets = false, collapseAdventureMaps = false, collapseWorldQuests = false,
        namePlates = { enabled = false },
    },
    questTables = {
        enabled = false,
        collapseQuests = false, collapseAchievements = false,
        collapseBonusObjectives = false, collapseScenarios = false, collapseCampaigns = false,
        collapseProfessions = false, collapseMonthlyActivities = false,
        collapseUIWidgets = false, collapseAdventureMaps = false, collapseWorldQuests = false,
        namePlates = { enabled = false },
    },
    neighbourhood = {
        enabled = false,
        collapseQuests = false, collapseAchievements = false,
        collapseBonusObjectives = false, collapseScenarios = false, collapseCampaigns = false,
        collapseProfessions = false, collapseMonthlyActivities = false,
        collapseUIWidgets = false, collapseAdventureMaps = false, collapseWorldQuests = false,
        namePlates = { enabled = false },
    },
    house = {
        enabled = false,
        collapseQuests = false, collapseAchievements = false,
        collapseBonusObjectives = false, collapseScenarios = false, collapseCampaigns = false,
        collapseProfessions = false, collapseMonthlyActivities = false,
        collapseUIWidgets = false, collapseAdventureMaps = false, collapseWorldQuests = false,
        namePlates = { enabled = false },
    },
}

local function getDefaultProfile()
    local t = {}
    for k, v in pairs(defaults) do
        if type(v) == "table" then
            t[k] = {}
            for k2, v2 in pairs(v) do
                if type(v2) == "table" then
                    t[k][k2] = {}
                    for k3, v3 in pairs(v2) do t[k][k2][k3] = v3 end
                else
                    t[k][k2] = v2
                end
            end
        else
            t[k] = v
        end
    end
    return t
end

local function InitializeConfigDB()
    if not QuestLogCollapseDB then QuestLogCollapseDB = {} end
    if not QuestLogCollapseDB.profiles then
        QuestLogCollapseDB.profiles = { ["Default"] = getDefaultProfile() }
    end
    if not QuestLogCollapseCharDB then QuestLogCollapseCharDB = {} end
    if not QuestLogCollapseCharDB.currentProfile then
        QuestLogCollapseCharDB.currentProfile = "Default"
    end
    if not QuestLogCollapseDB.profiles[QuestLogCollapseCharDB.currentProfile] then
        QuestLogCollapseDB.profiles[QuestLogCollapseCharDB.currentProfile] = getDefaultProfile()
    end
    -- Migrate old flat settings into the profile system
    for k, v in pairs(defaults) do
        if QuestLogCollapseDB[k] ~= nil and (not QuestLogCollapseDB.profiles["Default"][k]) then
            QuestLogCollapseDB.profiles["Default"][k] = QuestLogCollapseDB[k]
            QuestLogCollapseDB[k] = nil
        end
    end
end

local function getProfile()
    if not QuestLogCollapseDB or not QuestLogCollapseDB.profiles
       or not QuestLogCollapseCharDB or not QuestLogCollapseCharDB.currentProfile then
        return getDefaultProfile()
    end
    return QuestLogCollapseDB.profiles[QuestLogCollapseCharDB.currentProfile] or getDefaultProfile()
end

-- ============================================================
-- SHARED UI HELPERS
-- ============================================================
local function Tip(widget, title, ...)
    local lines = { ... }
    widget:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(title, 1, 0.82, 0)
        for _, line in ipairs(lines) do
            GameTooltip:AddLine(line, 1, 1, 1, true)
        end
        GameTooltip:Show()
    end)
    widget:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

-- --------------------------------------------------------
-- TRACKER SECTION DEFINITIONS  (used by all containers)
-- --------------------------------------------------------
-- blacklistName matches the friendly name used in the runtime TAINT_BLACKLIST table
-- (see QuestLogCollapse.lua). When set and present in ns.TAINT_BLACKLIST at panel build,
-- the corresponding checkbox is disabled and visually marked so the user understands
-- the toggle is inert. Saved-vars values are left untouched.
local SECTIONS_ROW1 = {
    { key = "collapseQuests",
      label = "Quests",
      blacklistName = "Quest",
      tip = "Collapse the Quest tracker (QuestObjectiveTracker).\nShows standard quests with objectives in your current area.\n|cffff9900Caution:|r Tracked quests with UIWidget content (e.g. delve coffer-key timers) taint Area POI tooltip widths. Off by default." },
    { key = "collapseAchievements",
      label = "Achievements",
      tip = "Collapse the Achievement tracker.\nShows progress toward tracked achievement criteria." },
    { key = "collapseBonusObjectives",
      label = "Bonus",
      blacklistName = "Bonus objectives",
      tip = "Collapse the Bonus Objective tracker.\nShows area bonus objectives and rare encounters.\n|cffff9900Caution:|r Can cause taint on Area POI tooltips in some builds. Off by default." },
    { key = "collapseCampaigns",
      label = "Campaigns",
      tip = "Collapse the Campaign Quest tracker.\nTracks story campaign and chapter quest chains." },
    { key = "collapseScenarios",
      label = "Scenario",
      tip = "Collapse the Scenario/Dungeon objective tracker.\nShows dungeon and scenario step objectives." },
}
local SECTIONS_ROW2 = {
    { key = "collapseWorldQuests",
      label = "World Quests",
      blacklistName = "World quest",
      tip = "Collapse the World Quest tracker.\nShows world quests on the map.\n|cffff9900Caution:|r May cause world map system taint. Off by default." },
    { key = "collapseProfessions",
      label = "Professions",
      tip = "Collapse the Profession Recipe tracker.\nShows active crafting work orders and profession recipes." },
    { key = "collapseMonthlyActivities",
      label = "Monthly",
      blacklistName = "Monthly activities",
      tip = "Collapse the Monthly Activities tracker.\nShows seasonal event and monthly quest progress bars.\n|cffff9900Caution:|r UIWidget status bars can cause taint. Off by default." },
    { key = "collapseUIWidgets",
      label = "Widgets",
      blacklistName = "UI widgets",
      tip = "Collapse the UI Widget objective tracker.\nShows general widget-based objectives.\n|cffff9900Caution:|r Directly manages widget pool frames — can cause taint. Off by default." },
    { key = "collapseAdventureMaps",
      label = "Adventure",
      blacklistName = "Adventure map",
      tip = "Collapse the Adventure Map Quest tracker.\nShows objectives from the adventure map.\n|cffff9900Caution:|r Can cause world map system taint. Off by default." },
}

-- Returns true when the section's tracker is in the runtime TAINT_BLACKLIST.
local function IsSectionBlacklisted(section)
    return section.blacklistName and ns.TAINT_BLACKLIST and ns.TAINT_BLACKLIST[section.blacklistName] == true
end

local CONTAINER_H    = 107
local CONTAINER_STEP = 112

-- --------------------------------------------------------
-- CONTAINER REFRESH HELPER
-- --------------------------------------------------------
local function RefreshContainer(container, instanceKey, prof)
    if not container then return end
    if not prof then prof = getProfile() end
    if not prof[instanceKey] then
        local src = defaults[instanceKey]
        if src then
            prof[instanceKey] = {}
            for k, v in pairs(src) do
                if type(v) == "table" then
                    prof[instanceKey][k] = {}
                    for k2, v2 in pairs(v) do prof[instanceKey][k][k2] = v2 end
                else
                    prof[instanceKey][k] = v
                end
            end
        end
    end
    local s = prof[instanceKey]
    if not s then return end
    container.enabledCheck:SetChecked(s.enabled)
    container.namePlatesEnabledCheck:SetChecked(s.namePlates and s.namePlates.enabled or false)
    for _, section in ipairs(SECTIONS_ROW1) do
        if container[section.key] then container[section.key]:SetChecked(s[section.key]) end
    end
    for _, section in ipairs(SECTIONS_ROW2) do
        if container[section.key] then container[section.key]:SetChecked(s[section.key]) end
    end
end

-- --------------------------------------------------------
-- CONTAINER BUILDER
-- --------------------------------------------------------
local function BuildContainer(parent, instanceInfo, yTopLeft, isLegacy)
    local container = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    container:SetSize(622, CONTAINER_H)
    container:SetPoint("TOPLEFT", parent, "TOPLEFT", -5, yTopLeft)
    container:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    container:SetBackdropColor(0, 0, 0, isLegacy and 0.12 or 0.2)
    container:SetBackdropBorderColor(0.4, 0.4, 0.4, isLegacy and 0.35 or 0.55)

    -- Instance name label
    local typeLabel = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    typeLabel:SetPoint("TOPLEFT", container, "TOPLEFT", 8, -8)
    typeLabel:SetText(instanceInfo.color .. instanceInfo.name .. "|r")

    -- "Active" (enabled) checkbox
    local typeEnabledCheck = CreateFrame("CheckButton", nil, container, "InterfaceOptionsCheckButtonTemplate")
    typeEnabledCheck:SetPoint("TOPLEFT", container, "TOPLEFT", 148, -4)
    typeEnabledCheck.Text:SetText("Active")
    typeEnabledCheck.key = instanceInfo.key
    Tip(typeEnabledCheck, "Activate for " .. instanceInfo.name,
        instanceInfo.contextTip or ("Apply these settings when you enter " .. instanceInfo.name .. "."),
        "When unchecked, the addon will not collapse or expand any trackers in this context.")
    typeEnabledCheck:SetScript("OnClick", function(self)
        getProfile()[self.key].enabled = self:GetChecked()
    end)

    -- Build a single tracker checkbox row; gates blacklisted entries to inert + grayed.
    local function BuildSectionRow(sections, yOffset)
        for j, section in ipairs(sections) do
            local cb = CreateFrame("CheckButton", nil, container, "InterfaceOptionsCheckButtonTemplate")
            cb:SetPoint("TOPLEFT", container, "TOPLEFT", 5 + (j - 1) * 120, yOffset)
            cb.instanceKey = instanceInfo.key
            cb.sectionKey  = section.key
            local blacklisted = IsSectionBlacklisted(section)
            if blacklisted then
                -- "(blacklisted)" suffix overflows the 120px column into adjacent
                -- entries (see screenshot from 1.4.0-beta4). Use a small orange
                -- asterisk instead and explain it in the tooltip.
                cb.Text:SetText(section.label .. " |cffffaa00*|r")
                cb:Disable()
                cb:SetMotionScriptsWhileDisabled(true)  -- keep OnEnter/OnLeave firing for tooltip
                cb.Text:SetTextColor(0.5, 0.5, 0.5)
                Tip(cb, section.label .. " |cffffaa00*|r (blacklisted)",
                    "|cffffaa00This tracker is in the runtime taint blacklist; the toggle has no effect.|r",
                    "Reason: " .. (section.tip or ""),
                    " ",
                    "The |cffffaa00*|r in the label marks a blacklisted entry. The setting in your saved variables is left untouched, so removing the blacklist entry restores the toggle without losing your previous value.")
            else
                cb.Text:SetText(section.label)
                Tip(cb, section.label, section.tip)
                cb:SetScript("OnClick", function(self)
                    getProfile()[self.instanceKey][self.sectionKey] = self:GetChecked()
                end)
            end
            container[section.key] = cb
        end
    end

    BuildSectionRow(SECTIONS_ROW1, -28)
    BuildSectionRow(SECTIONS_ROW2, -50)

    -- Thin separator before nameplate option
    local npSep = container:CreateTexture(nil, "BACKGROUND")
    npSep:SetPoint("TOPLEFT", container, "TOPLEFT", 5, -75)
    npSep:SetSize(612, 1)
    npSep:SetColorTexture(0.3, 0.3, 0.3, 0.4)

    -- Nameplate toggle
    local namePlatesCheck = CreateFrame("CheckButton", nil, container, "InterfaceOptionsCheckButtonTemplate")
    namePlatesCheck:SetPoint("TOPLEFT", container, "TOPLEFT", 5, -79)
    namePlatesCheck.Text:SetText("Show Enemy Name Plates")
    namePlatesCheck.key = instanceInfo.key
    Tip(namePlatesCheck, "Show Enemy Name Plates",
        "Automatically enable enemy nameplates when entering " .. instanceInfo.name .. ".",
        "Your original nameplate setting is restored when you leave.",
        "Controls the |cffffcc00nameplateShowEnemies|r game CVar.")
    namePlatesCheck:SetScript("OnClick", function(self)
        local prof = getProfile()
        if not prof[self.key].namePlates then prof[self.key].namePlates = {} end
        prof[self.key].namePlates.enabled = self:GetChecked()
    end)

    container.enabledCheck          = typeEnabledCheck
    container.namePlatesEnabledCheck = namePlatesCheck
    return container
end

-- ============================================================
-- INSTANCE TYPE DEFINITIONS
-- ============================================================
local combatType = {
    { key = "combat", name = "Open World Combat", color = "|cffffff00",
      contextTip = "Applied when you enter combat outside of any instance." },
}
local instanceTypes = {
    { key = "dungeons",  name = "Dungeons",  color = "|cff00ff00",
      contextTip = "Applied when you enter a 5-player dungeon (party instance)." },
    { key = "raids",     name = "Raids",     color = "|cffff8000",
      contextTip = "Applied when you enter a raid instance." },
    { key = "scenarios", name = "Scenarios", color = "|cff0080ff",
      contextTip = "Applied when you enter a scenario." },
}
local pvpTypes = {
    { key = "battlegrounds", name = "Battlegrounds", color = "|cffff0080",
      contextTip = "Applied when you enter a PvP battleground." },
    { key = "arenas",        name = "Arenas",        color = "|cff8000ff",
      contextTip = "Applied when you enter a PvP arena." },
}
local housingTypes = {
    { key = "neighbourhood", name = "Neighbourhood", color = "|cff80ff80",
      contextTip = "Applied in The War Within Neighbourhood areas." },
    { key = "house",         name = "Player Housing", color = "|cffff80ff",
      contextTip = "Applied inside your Player House." },
}
local legacyTypes = {
    { key = "garrisons",   name = "Garrisons",   color = "|cffffc000",
      contextTip = "Applied inside a Warlords of Draenor Garrison." },
    { key = "classHalls",  name = "Class Halls", color = "|cffff00ff",
      contextTip = "Applied inside a Legion Class Hall." },
    { key = "questTables", name = "Quest Tables", color = "|cffff8080",
      contextTip = "Applied when at a garrison mission table." },
}

-- ============================================================
-- SUB-PANEL FACTORY  (Instance Settings / PvP / Housing / Legacy)
-- ============================================================
local function BuildContainerPanel(titleText, typeList, isLegacyStyle)
    local subPanel = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    subPanel.OnCommit  = function() end
    subPanel.OnDefault = function() end
    subPanel.OnRefresh = function() end

    local titleLabel = subPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleLabel:SetPoint("TOP", subPanel, "TOP", 0, -20)
    titleLabel:SetText(titleText)

    local scrollFrame = CreateFrame("ScrollFrame", nil, subPanel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT",     subPanel, "TOPLEFT",     0,   -50)
    scrollFrame:SetPoint("BOTTOMRIGHT", subPanel, "BOTTOMRIGHT", -25,   8)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(600, 100)
    scrollFrame:SetScrollChild(scrollChild)

    local containers = {}
    local yOffset = -10
    for _, instanceInfo in ipairs(typeList) do
        containers[instanceInfo.key] = BuildContainer(scrollChild, instanceInfo, yOffset, isLegacyStyle)
        yOffset = yOffset - CONTAINER_STEP
    end
    scrollChild:SetHeight(math.abs(yOffset) + 20)

    subPanel.OnShow = function()
        local prof = getProfile()
        for _, instanceInfo in ipairs(typeList) do
            RefreshContainer(containers[instanceInfo.key], instanceInfo.key, prof)
        end
    end
    subPanel:HookScript("OnShow", subPanel.OnShow)
    -- Also hand the same logic to OnRefresh, the documented Settings-system hook
    -- (in case the canvas-layout dispatch ever skips the OnShow transition).
    subPanel.OnRefresh = subPanel.OnShow

    -- Hide after construction. CreateFrame returns a frame in shown state, so
    -- the first Settings.OpenToCategory call would call frame:Show() as a no-op
    -- and OnShow would never fire — leaving the checkboxes at their default
    -- unticked state until a hide/show round-trip via category switching.
    subPanel:Hide()

    return subPanel
end

-- ============================================================
-- BASIC OPTIONS PANEL  (parent category — global settings + open world combat)
-- ============================================================
local basicPanel  -- forward ref for SwitchProfile below

local function CreateBasicOptionsPanel()
    if basicPanel then return basicPanel end

    -- refreshProfileDD is wired up once RefreshQLCProfileDropdown is defined below
    local refreshProfileDD = nil

    if not StaticPopupDialogs["QUESTLOGCOLLAPSE_NEW_PROFILE"] then
        StaticPopupDialogs["QUESTLOGCOLLAPSE_NEW_PROFILE"] = {
            text = "Enter new profile name:",
            button1 = "Create", button2 = "Cancel",
            hasEditBox = true, maxLetters = 32,
            OnAccept = function(self)
                local editBox = self.editBox or self.EditBox
                local name = editBox and editBox:GetText():gsub("^%s+", ""):gsub("%s+$", "") or ""
                if name == "" then return end
                if QuestLogCollapseDB.profiles[name] then
                    print("|cffff0000QuestLogCollapse|r Profile already exists.")
                    return
                end
                QuestLogCollapseDB.profiles[name] = getDefaultProfile()
                QuestLogCollapseCharDB.currentProfile = name
                if refreshProfileDD then refreshProfileDD() end
                print("|cff00ff00QuestLogCollapse|r Created profile: " .. name)
            end,
            timeout = 0, whileDead = true, exclusive = true,
            hideOnEscape = true, preferredIndex = 3,
        }
    end

    basicPanel = CreateFrame("Frame", "QuestLogCollapseConfigPanel", UIParent, "BackdropTemplate")
    basicPanel.name      = "QuestLogCollapse"
    basicPanel.OnCommit  = function() end
    basicPanel.OnDefault = function() end
    basicPanel.OnRefresh = function() end

    -- --------------------------------------------------------
    -- TITLE
    -- --------------------------------------------------------
    local titleLabel = basicPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleLabel:SetPoint("TOP", basicPanel, "TOP", 0, -20)
    titleLabel:SetText("QuestLogCollapse — Basic Options")

    -- --------------------------------------------------------
    -- DEBUG (pinned outside the scroll frame, always at bottom)
    -- --------------------------------------------------------
    local debugCheck = CreateFrame("CheckButton", nil, basicPanel, "InterfaceOptionsCheckButtonTemplate")
    debugCheck:SetPoint("BOTTOMLEFT", basicPanel, "BOTTOMLEFT", 8, 8)
    debugCheck.Text:SetText("Debug Mode")
    Tip(debugCheck, "Debug Mode",
        "Print verbose log messages to the chat frame.",
        "Useful for diagnosing unexpected behaviour.",
        "Toggle with |cffffcc00/qlc debug|r.")

    -- --------------------------------------------------------
    -- SCROLL FRAME
    -- --------------------------------------------------------
    local scrollFrame = CreateFrame("ScrollFrame", nil, basicPanel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT",     basicPanel, "TOPLEFT",     0,   -50)
    scrollFrame:SetPoint("BOTTOMRIGHT", basicPanel, "BOTTOMRIGHT", -25,  32)  -- leave room for debug

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(600, 320)
    scrollFrame:SetScrollChild(scrollChild)

    -- --------------------------------------------------------
    -- PROFILE ROW
    -- --------------------------------------------------------
    local profileLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    profileLabel:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 5, -10)
    profileLabel:SetText("Profile:")
    Tip(profileLabel, "Profiles",
        "Profiles store independent sets of settings.",
        "Switch profiles to quickly change between configurations (e.g. one for raiding, one for casual questing).")

    local profileDD = CreateFrame("Frame", nil, scrollChild, "UIDropDownMenuTemplate")
    profileDD:SetPoint("LEFT", profileLabel, "RIGHT", 8, 0)
    UIDropDownMenu_SetWidth(profileDD, 150)

    local newProfileBtn = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
    newProfileBtn:SetSize(100, 22)
    newProfileBtn:SetPoint("LEFT", profileDD, "RIGHT", 6, 0)
    newProfileBtn:SetText("New Profile")
    newProfileBtn:SetScript("OnClick", function() StaticPopup_Show("QUESTLOGCOLLAPSE_NEW_PROFILE") end)
    Tip(newProfileBtn, "New Profile",
        "Create a new profile with default settings.",
        "The new profile becomes active immediately.")

    -- --------------------------------------------------------
    -- SEPARATOR + GLOBAL ENABLE
    -- --------------------------------------------------------
    local sep1 = scrollChild:CreateTexture(nil, "BACKGROUND")
    sep1:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 5, -38)
    sep1:SetSize(590, 1)
    sep1:SetColorTexture(0.5, 0.5, 0.5, 0.4)

    local enabledCheck = CreateFrame("CheckButton", nil, scrollChild, "InterfaceOptionsCheckButtonTemplate")
    enabledCheck:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -46)
    enabledCheck.Text:SetText("Enable QuestLogCollapse")
    Tip(enabledCheck, "Enable QuestLogCollapse",
        "Master on/off switch for the entire addon.",
        "When disabled, no trackers are collapsed or expanded and zone filtering does not run.",
        "Toggle with |cffffcc00/qlc toggle|r.")

    -- --------------------------------------------------------
    -- ZONE FILTER SECTION
    -- --------------------------------------------------------
    local zfHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    zfHeader:SetPoint("TOPLEFT", enabledCheck, "BOTTOMLEFT", 4, -8)
    zfHeader:SetText("ZONE QUEST FILTERING")
    zfHeader:SetTextColor(0.6, 0.6, 0.6)

    local filterQuestsByZoneCheck = CreateFrame("CheckButton", nil, scrollChild, "InterfaceOptionsCheckButtonTemplate")
    filterQuestsByZoneCheck:SetPoint("TOPLEFT", zfHeader, "BOTTOMLEFT", -4, -2)
    filterQuestsByZoneCheck.Text:SetText("Filter tracked quests by current zone")
    Tip(filterQuestsByZoneCheck, "Filter Tracked Quests by Zone",
        "Adjusts which quests appear in your tracker based on your current zone.",
        "Quests with objectives or map markers here are tracked; others are untracked.",
        "Triggers automatically after a zone change when you start moving, mount/dismount, cast a spell, or interact with the quest tracker.",
        "Use |cffffcc00/qlc filterzone|r to trigger manually.",
        "|cffff9900Note:|r Your original tracked-quest list is saved and can be restored by disabling this option.")

    -- Mode dropdown (same row, to the right of the checkbox label)
    local filterModeLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    filterModeLabel:SetPoint("LEFT", filterQuestsByZoneCheck.Text, "RIGHT", 18, 0)
    filterModeLabel:SetText("Apply in:")
    filterModeLabel:SetTextColor(0.8, 0.8, 0.8)

    local filterModeDD = CreateFrame("Frame", nil, scrollChild, "UIDropDownMenuTemplate")
    filterModeDD:SetPoint("LEFT", filterModeLabel, "RIGHT", 0, 0)
    UIDropDownMenu_SetWidth(filterModeDD, 175)
    Tip(filterModeDD, "Zone Filter Scope",
        "|cff00ff00Open World Only|r — Filtering skips instances. Quests for your dungeon or raid stay visible naturally.",
        "|cffff9900Always|r — Filtering runs everywhere, including while inside instances.",
        "Default: Open World Only.")

    local function InitFilterModeDD()
        UIDropDownMenu_Initialize(filterModeDD, function()
            local modes = {
                { value = "openworld", text = "Open World Only" },
                { value = "always",    text = "Always (incl. instances)" },
            }
            local currentMode = getProfile().filterQuestsByZoneMode or "openworld"
            for _, mode in ipairs(modes) do
                local info = UIDropDownMenu_CreateInfo()
                info.text    = mode.text
                info.value   = mode.value
                info.checked = (currentMode == mode.value)
                info.func    = function(item)
                    getProfile().filterQuestsByZoneMode = item.value
                    UIDropDownMenu_SetSelectedValue(filterModeDD, item.value)
                end
                UIDropDownMenu_AddButton(info)
            end
        end)
        UIDropDownMenu_SetSelectedValue(filterModeDD, getProfile().filterQuestsByZoneMode or "openworld")
    end
    InitFilterModeDD()

    -- Quest tracker interaction-button handling mode
    local interactionModeLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    interactionModeLabel:SetPoint("TOPLEFT", filterQuestsByZoneCheck, "BOTTOMLEFT", 17, -10)
    interactionModeLabel:SetText("Quest collapse with tracked interaction-button quests:")
    interactionModeLabel:SetTextColor(0.8, 0.8, 0.8)

    local interactionModeDD = CreateFrame("Frame", nil, scrollChild, "UIDropDownMenuTemplate")
    interactionModeDD:SetPoint("TOPLEFT", interactionModeLabel, "BOTTOMLEFT", -15, -2)
    UIDropDownMenu_SetWidth(interactionModeDD, 285)
    Tip(interactionModeDD, "Quest Collapse Interaction Handling",
        "When a watched quest has an interaction button (quest item), choose how quest-section collapse behaves:",
        "|cff00ff00Skip Quest section|r — leave the Quest tracker expanded for this collapse pass.",
        "|cffff9900Untrack other watched quests|r — keep only interaction-button quests watched, then collapse Quest.",
        "|cffff6666Disabled|r — do not apply special handling.")

    local function InitInteractionModeDD()
        UIDropDownMenu_Initialize(interactionModeDD, function()
            local modes = {
                { value = "skip_section",   text = "Skip Quest section (default)" },
                { value = "untrack_others", text = "Untrack other watched quests, then collapse Quest" },
                { value = "off",            text = "Disabled" },
            }
            local currentMode = getProfile().questInteractionCollapseBehavior or "skip_section"
            for _, mode in ipairs(modes) do
                local info = UIDropDownMenu_CreateInfo()
                info.text    = mode.text
                info.value   = mode.value
                info.checked = (currentMode == mode.value)
                info.func    = function(item)
                    getProfile().questInteractionCollapseBehavior = item.value
                    UIDropDownMenu_SetSelectedValue(interactionModeDD, item.value)
                end
                UIDropDownMenu_AddButton(info)
            end
        end)
        UIDropDownMenu_SetSelectedValue(interactionModeDD, getProfile().questInteractionCollapseBehavior or "skip_section")
    end
    InitInteractionModeDD()

    -- --------------------------------------------------------
    -- OPEN WORLD COMBAT SECTION
    -- --------------------------------------------------------
    local sep2 = scrollChild:CreateTexture(nil, "BACKGROUND")
    sep2:SetPoint("TOPLEFT", interactionModeDD, "BOTTOMLEFT", 4, -6)
    sep2:SetSize(590, 1)
    sep2:SetColorTexture(0.5, 0.5, 0.5, 0.4)

    local owcHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    owcHeader:SetPoint("TOPLEFT", sep2, "BOTTOMLEFT", 0, -8)
    owcHeader:SetText("OPEN WORLD COMBAT")
    owcHeader:SetTextColor(0.6, 0.6, 0.6)

    -- yTopLeft computed from the sections above, including interaction handling controls.
    local combatContainer = BuildContainer(scrollChild, combatType[1], -220, false)
    scrollChild:SetHeight(220 + CONTAINER_H + 20)

    -- --------------------------------------------------------
    -- PROFILE DROPDOWN
    -- --------------------------------------------------------
    local function RefreshQLCProfileDropdown()
        if not QuestLogCollapseDB or not QuestLogCollapseDB.profiles or not QuestLogCollapseCharDB then
            return
        end
        local items = {}
        for k in pairs(QuestLogCollapseDB.profiles) do table.insert(items, k) end
        table.sort(items)

        UIDropDownMenu_Initialize(profileDD, function()
            for _, name in ipairs(items) do
                local info = UIDropDownMenu_CreateInfo()
                info.text    = name
                info.checked = (name == QuestLogCollapseCharDB.currentProfile)
                info.func    = function()
                    QuestLogCollapseCharDB.currentProfile = name
                    if basicPanel.OnShow then basicPanel:OnShow() end
                end
                UIDropDownMenu_AddButton(info)
            end
        end)
        UIDropDownMenu_SetSelectedValue(profileDD, QuestLogCollapseCharDB.currentProfile)
    end

    refreshProfileDD = RefreshQLCProfileDropdown  -- wire up the StaticPopup upvalue

    -- --------------------------------------------------------
    -- PANEL OnShow — refresh all widgets from current profile
    -- --------------------------------------------------------
    basicPanel.OnShow = function()
        local prof = getProfile()

        enabledCheck:SetChecked(prof.enabled)
        debugCheck:SetChecked(prof.debug)
        filterQuestsByZoneCheck:SetChecked(prof.filterQuestsByZone or false)
        UIDropDownMenu_SetSelectedValue(filterModeDD, prof.filterQuestsByZoneMode or "openworld")
        UIDropDownMenu_SetSelectedValue(interactionModeDD, prof.questInteractionCollapseBehavior or "skip_section")

        RefreshContainer(combatContainer, "combat", prof)
        RefreshQLCProfileDropdown()
        InitFilterModeDD()
        InitInteractionModeDD()
    end

    basicPanel:HookScript("OnShow", basicPanel.OnShow)
    basicPanel.OnRefresh = basicPanel.OnShow

    -- See BuildContainerPanel — same reason: hide so the first Settings.Show()
    -- actually transitions visibility and fires OnShow.
    basicPanel:Hide()

    -- --------------------------------------------------------
    -- GLOBAL CHECKBOX HANDLERS
    -- --------------------------------------------------------
    enabledCheck:SetScript("OnClick", function(self)
        getProfile().enabled = self:GetChecked()
    end)

    filterQuestsByZoneCheck:SetScript("OnClick", function(self)
        getProfile().filterQuestsByZone = self:GetChecked()
    end)

    debugCheck:SetScript("OnClick", function(self)
        getProfile().debug = self:GetChecked()
    end)

    return basicPanel
end

-- ============================================================
-- EVENTS + REGISTRATION
-- ============================================================
local configEventFrame = CreateFrame("Frame")
configEventFrame:RegisterEvent("ADDON_LOADED")
configEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

local panelRegistered = false
local allPanels       = {}

local function SwitchProfile(profileName)
    QuestLogCollapseCharDB.currentProfile = profileName
    for _, p in ipairs(allPanels) do
        if p.OnShow then p:OnShow() end
    end
end

configEventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "QuestLogCollapse" then
        InitializeConfigDB()
    elseif event == "PLAYER_ENTERING_WORLD" then
        if not panelRegistered then
            -- Create all panels
            local basicOpts    = CreateBasicOptionsPanel()
            local instPanel    = BuildContainerPanel("Instances", instanceTypes, false)
            local pvpPanel     = BuildContainerPanel("PvP",      pvpTypes,     false)
            local housingPanel = BuildContainerPanel("Housing",   housingTypes, false)
            local legacyPanel  = BuildContainerPanel("Legacy",    legacyTypes,  true)

            allPanels = { basicOpts, instPanel, pvpPanel, housingPanel, legacyPanel }

            -- Register parent category (Basic Options)
            local parentCat = Settings.RegisterCanvasLayoutCategory(basicOpts, "QuestLogCollapse")
            Settings.RegisterAddOnCategory(parentCat)
            basicOpts.categoryID = parentCat.ID

            -- Register the four subcategories
            local function RegSub(subPanel, name)
                local subCat = Settings.RegisterCanvasLayoutSubcategory(parentCat, subPanel, name)
                Settings.RegisterAddOnCategory(subCat)
                subPanel.categoryID = subCat.ID
            end
            RegSub(instPanel,    "Instances")
            RegSub(pvpPanel,     "PvP")
            RegSub(housingPanel, "Housing")
            RegSub(legacyPanel,  "Legacy")

            panelRegistered = true
        end
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    end
end)

-- ============================================================
-- NAMESPACE EXPORTS
-- ============================================================
local function GetCurrentInstanceSettings()
    local prof = getProfile()
    if not prof then return nil end

    local instanceType = select(2, IsInInstance())
    if ns.DebugPrint then
        ns.DebugPrint("Current instance type: " .. tostring(instanceType))
    end
    if instanceType == "party" then
        local isInGarrison  = C_Garrison.IsPlayerInGarrison(Enum.GarrisonType.Type_6_0_Garrison)
        local isInClassHall = C_Garrison.IsPlayerInGarrison(Enum.GarrisonType.Type_7_0_Garrison)
        local isAtQuestTable = C_Garrison.IsAtGarrisonMissionNPC() or
                               C_Garrison.IsPlayerInGarrison(Enum.GarrisonType.Type_8_0_Garrison)
        if isInGarrison      then return prof.garrisons
        elseif isInClassHall then return prof.classHalls
        elseif isAtQuestTable then return prof.questTables
        else                      return prof.dungeons
        end
    elseif instanceType == "raid"         then return prof.raids
    elseif instanceType == "scenario"     then return prof.scenarios
    elseif instanceType == "pvp"          then return prof.battlegrounds
    elseif instanceType == "arena"        then return prof.arenas
    elseif instanceType == "neighborhood" then return prof.neighbourhood
    elseif instanceType == "interior"     then return prof.house
    else                                       return prof.combat
    end
end

local function GetCurrentQLCProfile()
    return getProfile()
end

ns.CreateQuestLogCollapseConfigPanel = CreateBasicOptionsPanel
ns.GetCurrentInstanceSettings        = GetCurrentInstanceSettings
ns.GetCurrentQLCProfile              = GetCurrentQLCProfile
ns.SwitchProfile                     = SwitchProfile

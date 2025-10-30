-- QuestLogCollapse Configuration Panel
-- Author: YourName
-- Version: 1.0.0

local QLC = QuestLogCollapseDB or {}

-- Default settings for profiles
local defaults = {
    enabled = true,
    debug = false,
    -- Instance type settings
    dungeons = {
        enabled = true,
        collapseQuests = true,
        collapseAchievements = false,
        collapseBonusObjectives = true,
        collapseScenarios = false,
        collapseCampaigns = true,
        collapseProfessions = false,
        collapseMonthlyActivities = false,
        collapseUIWidgets = false,
        collapseAdventureMaps = false
    },
    raids = {
        enabled = true,
        collapseQuests = true,
        collapseAchievements = false,
        collapseBonusObjectives = true,
        collapseScenarios = false,
        collapseCampaigns = true,
        collapseProfessions = false,
        collapseMonthlyActivities = false,
        collapseUIWidgets = false,
        collapseAdventureMaps = false
    },
    scenarios = {
        enabled = false,
        collapseQuests = false,
        collapseAchievements = false,
        collapseBonusObjectives = false,
        collapseScenarios = true,
        collapseCampaigns = false,
        collapseProfessions = false,
        collapseMonthlyActivities = false,
        collapseUIWidgets = false,
        collapseAdventureMaps = false
    },
    battlegrounds = {
        enabled = false,
        collapseQuests = false,
        collapseAchievements = false,
        collapseBonusObjectives = false,
        collapseScenarios = false,
        collapseCampaigns = false,
        collapseProfessions = false,
        collapseMonthlyActivities = false,
        collapseUIWidgets = false,
        collapseAdventureMaps = false
    },
    arenas = {
        enabled = false,
        collapseQuests = false,
        collapseAchievements = false,
        collapseBonusObjectives = false,
        collapseScenarios = false,
        collapseCampaigns = false,
        collapseProfessions = false,
        collapseMonthlyActivities = false,
        collapseUIWidgets = false,
        collapseAdventureMaps = false
    }
}

local function getDefaultProfile()
    local t = {}
    for k, v in pairs(defaults) do
        if type(v) == "table" then
            t[k] = {}
            for k2, v2 in pairs(v) do
                t[k][k2] = v2
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

    -- Initialize character-specific database
    if not QuestLogCollapseCharDB then
        QuestLogCollapseCharDB = {}
    end

    -- Set default profile if none is set
    if not QuestLogCollapseCharDB.currentProfile then
        QuestLogCollapseCharDB.currentProfile = "Default"
    end

    -- Ensure the current profile exists in the profiles database
    if not QuestLogCollapseDB.profiles[QuestLogCollapseCharDB.currentProfile] then
        QuestLogCollapseDB.profiles[QuestLogCollapseCharDB.currentProfile] = getDefaultProfile()
    end

    -- Migrate old settings to new profile system
    for k, v in pairs(defaults) do
        if QuestLogCollapseDB[k] ~= nil and (not QuestLogCollapseDB.profiles["Default"][k]) then
            QuestLogCollapseDB.profiles["Default"][k] = QuestLogCollapseDB[k]
            QuestLogCollapseDB[k] = nil
        end
    end
end

local function getProfile()
    if not QuestLogCollapseDB or not QuestLogCollapseDB.profiles or not QuestLogCollapseCharDB or not QuestLogCollapseCharDB.currentProfile then
        return getDefaultProfile()
    end
    return QuestLogCollapseDB.profiles[QuestLogCollapseCharDB.currentProfile] or getDefaultProfile()
end

-- Define the new profile popup
if not StaticPopupDialogs["QUESTLOGCOLLAPSE_NEW_PROFILE"] then
    StaticPopupDialogs["QUESTLOGCOLLAPSE_NEW_PROFILE"] = {
        text = "Enter new profile name:",
        button1 = "Create",
        button2 = "Cancel",
        hasEditBox = true,
        maxLetters = 32,
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
            if _G.RefreshQLCProfileDropdown then
                _G.RefreshQLCProfileDropdown()
            end
            print("|cff00ff00QuestLogCollapse|r Created profile: " .. name)
        end,
        timeout = 0,
        whileDead = true,
        exclusive = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
end

local panel

function CreateQuestLogCollapseConfigPanel()
    if panel then return panel end
    
    panel = CreateFrame("Frame", "QuestLogCollapseConfigPanel", UIParent)
    panel.name = "QuestLogCollapse"

    -- Main container
    local mainContainer = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    mainContainer:SetSize(650, 600)
    mainContainer:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
    mainContainer:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    mainContainer:SetBackdropColor(0, 0, 0, 0.3)
    mainContainer:SetBackdropBorderColor(0.6, 0.6, 0.6, 0.8)

    -- Title
    local title = mainContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", mainContainer, "TOP", 0, -20)
    title:SetText("QuestLogCollapse Configuration")

    -- Profile section
    local profileLabel = mainContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    profileLabel:SetPoint("TOPLEFT", mainContainer, "TOPLEFT", 20, -60)
    profileLabel:SetText("Profile:")

    local profileDD = CreateFrame("Frame", nil, mainContainer, "UIDropDownMenuTemplate")
    profileDD:SetPoint("LEFT", profileLabel, "RIGHT", 10, 0)
    UIDropDownMenu_SetWidth(profileDD, 150)

    local newProfileBtn = CreateFrame("Button", nil, mainContainer, "UIPanelButtonTemplate")
    newProfileBtn:SetSize(100, 22)
    newProfileBtn:SetPoint("LEFT", profileDD, "RIGHT", 10, 0)
    newProfileBtn:SetText("New Profile")
    newProfileBtn:SetScript("OnClick", function()
        StaticPopup_Show("QUESTLOGCOLLAPSE_NEW_PROFILE")
    end)

    -- Global settings
    local enabledCheck = CreateFrame("CheckButton", nil, mainContainer, "InterfaceOptionsCheckButtonTemplate")
    enabledCheck:SetPoint("TOPLEFT", profileLabel, "BOTTOMLEFT", 0, -30)
    enabledCheck.Text:SetText("Enable QuestLogCollapse")

    local debugCheck = CreateFrame("CheckButton", nil, mainContainer, "InterfaceOptionsCheckButtonTemplate")
    debugCheck:SetPoint("LEFT", enabledCheck, "RIGHT", 200, 0)
    debugCheck.Text:SetText("Debug Mode")

    -- Instance type containers
    local instanceTypes = {
        { key = "dungeons", name = "Dungeons", color = "|cff00ff00" },
        { key = "raids", name = "Raids", color = "|cffff8000" },
        { key = "scenarios", name = "Scenarios", color = "|cff0080ff" },
        { key = "battlegrounds", name = "Battlegrounds", color = "|cffff0080" },
        { key = "arenas", name = "Arenas", color = "|cff8000ff" }
    }

    local instanceContainers = {}
    local yOffset = -130

    for i, instanceInfo in ipairs(instanceTypes) do
        local container = CreateFrame("Frame", nil, mainContainer, "BackdropTemplate")
        container:SetSize(620, 85)
        container:SetPoint("TOPLEFT", mainContainer, "TOPLEFT", 20, yOffset)
        container:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        container:SetBackdropColor(0, 0, 0, 0.2)
        container:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.6)

        instanceContainers[instanceInfo.key] = container

        -- Instance type label and enable checkbox
        local typeLabel = container:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        typeLabel:SetPoint("TOPLEFT", container, "TOPLEFT", 15, -10)
        typeLabel:SetText(instanceInfo.color .. instanceInfo.name .. "|r")

        local typeEnabledCheck = CreateFrame("CheckButton", nil, container, "InterfaceOptionsCheckButtonTemplate")
        typeEnabledCheck:SetPoint("LEFT", typeLabel, "RIGHT", 20, 0)
        typeEnabledCheck.Text:SetText("Enabled")
        typeEnabledCheck.key = instanceInfo.key

        -- Section checkboxes
        local sections = {
            { key = "collapseQuests", name = "Quests" },
            { key = "collapseAchievements", name = "Achievements" },
            { key = "collapseBonusObjectives", name = "Bonus" },
            { key = "collapseScenarios", name = "Scenarios" },
            { key = "collapseCampaigns", name = "Campaigns" }
        }

        local sections2 = {
            { key = "collapseProfessions", name = "Professions" },
            { key = "collapseMonthlyActivities", name = "Monthly" },
            { key = "collapseUIWidgets", name = "Widgets" },
            { key = "collapseAdventureMaps", name = "Adventure" }
        }

        -- First row of checkboxes
        for j, section in ipairs(sections) do
            local sectionCheck = CreateFrame("CheckButton", nil, container, "InterfaceOptionsCheckButtonTemplate")
            sectionCheck:SetPoint("TOPLEFT", container, "TOPLEFT", 15 + (j-1) * 120, -35)
            sectionCheck.Text:SetText(section.name)
            sectionCheck.instanceKey = instanceInfo.key
            sectionCheck.sectionKey = section.key
            sectionCheck:SetScript("OnClick", function(self)
                local prof = getProfile()
                prof[self.instanceKey][self.sectionKey] = self:GetChecked()
            end)
            container[section.key] = sectionCheck
        end

        -- Second row of checkboxes
        for j, section in ipairs(sections2) do
            local sectionCheck = CreateFrame("CheckButton", nil, container, "InterfaceOptionsCheckButtonTemplate")
            sectionCheck:SetPoint("TOPLEFT", container, "TOPLEFT", 15 + (j-1) * 120, -55)
            sectionCheck.Text:SetText(section.name)
            sectionCheck.instanceKey = instanceInfo.key
            sectionCheck.sectionKey = section.key
            sectionCheck:SetScript("OnClick", function(self)
                local prof = getProfile()
                prof[self.instanceKey][self.sectionKey] = self:GetChecked()
            end)
            container[section.key] = sectionCheck
        end

        container.enabledCheck = typeEnabledCheck
        typeEnabledCheck:SetScript("OnClick", function(self)
            local prof = getProfile()
            prof[self.key].enabled = self:GetChecked()
        end)

        yOffset = yOffset - 90
    end

    -- Profile dropdown refresh function
    function RefreshQLCProfileDropdown()
        if not QuestLogCollapseDB or not QuestLogCollapseDB.profiles or not QuestLogCollapseCharDB then
            return
        end
        local items = {}
        for k in pairs(QuestLogCollapseDB.profiles) do table.insert(items, k) end
        table.sort(items)
        
        UIDropDownMenu_Initialize(profileDD, function(self, level)
            for _, name in ipairs(items) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = name
                info.checked = (name == QuestLogCollapseCharDB.currentProfile)
                info.func = function()
                    QuestLogCollapseCharDB.currentProfile = name
                    if panel.OnShow then panel:OnShow() end
                end
                UIDropDownMenu_AddButton(info)
            end
        end)
        UIDropDownMenu_SetSelectedValue(profileDD, QuestLogCollapseCharDB.currentProfile)
    end
    _G.RefreshQLCProfileDropdown = RefreshQLCProfileDropdown

    -- Update panel on show
    panel.OnShow = function()
        local prof = getProfile()
        
        -- Update global settings
        enabledCheck:SetChecked(prof.enabled)
        debugCheck:SetChecked(prof.debug)
        
        -- Update instance type settings
        for _, instanceInfo in ipairs(instanceTypes) do
            local container = instanceContainers[instanceInfo.key]
            local instanceSettings = prof[instanceInfo.key]
            
            container.enabledCheck:SetChecked(instanceSettings.enabled)
            
            -- Update section checkboxes
            local allSections = {
                "collapseQuests", "collapseAchievements", "collapseBonusObjectives",
                "collapseScenarios", "collapseCampaigns", "collapseProfessions",
                "collapseMonthlyActivities", "collapseUIWidgets", "collapseAdventureMaps"
            }
            
            for _, sectionKey in ipairs(allSections) do
                if container[sectionKey] then
                    container[sectionKey]:SetChecked(instanceSettings[sectionKey])
                end
            end
        end
        
        RefreshQLCProfileDropdown()
    end

    panel:HookScript("OnShow", panel.OnShow)

    -- Global setting handlers
    enabledCheck:SetScript("OnClick", function(self)
        local prof = getProfile()
        prof.enabled = self:GetChecked()
    end)

    debugCheck:SetScript("OnClick", function(self)
        local prof = getProfile()
        prof.debug = self:GetChecked()
    end)

    return panel
end

-- Event frame for initialization
local configEventFrame = CreateFrame("Frame")
configEventFrame:RegisterEvent("ADDON_LOADED")

configEventFrame:SetScript("OnEvent", function(self, event, addonName)
    if event == "ADDON_LOADED" and addonName == "QuestLogCollapse" then
        InitializeConfigDB()
        self:UnregisterEvent("ADDON_LOADED")
    end
end)

-- Update the main addon functions to use profile settings
local function GetCurrentInstanceSettings()
    local prof = getProfile()
    local instanceType = select(2, IsInInstance())
    
    if instanceType == "party" then
        return prof.dungeons
    elseif instanceType == "raid" then
        return prof.raids
    elseif instanceType == "scenario" then
        return prof.scenarios
    elseif instanceType == "pvp" then
        return prof.battlegrounds
    elseif instanceType == "arena" then
        return prof.arenas
    end
    
    return nil
end

-- Override the main addon's functions
if QuestLogCollapseDB then
    -- Update the collapse/expand functions to use instance-specific settings
    local originalCollapseQuestLog = CollapseQuestLog
    local originalExpandQuestLog = ExpandQuestLog
    local originalOnZoneChanged = OnZoneChanged

    function CollapseQuestLog()
        local settings = GetCurrentInstanceSettings()
        if not settings or not settings.enabled then return end
        
        if settings.collapseQuests and QuestObjectiveTracker then
            QuestObjectiveTracker:SetCollapsed(true)
            if QuestLogCollapseCharDB and getProfile().debug then
                print("|cff00ff00[QuestLogCollapse]|r Quest section collapsed")
            end
        end
        
        if settings.collapseAchievements and AchievementObjectiveTracker then
            AchievementObjectiveTracker:SetCollapsed(true)
            if QuestLogCollapseCharDB and getProfile().debug then
                print("|cff00ff00[QuestLogCollapse]|r Achievement section collapsed")
            end
        end
        
        if settings.collapseBonusObjectives and BonusObjectiveTracker then
            BonusObjectiveTracker:SetCollapsed(true)
            if QuestLogCollapseCharDB and getProfile().debug then
                print("|cff00ff00[QuestLogCollapse]|r Bonus objectives section collapsed")
            end
        end
        
        if settings.collapseScenarios and ScenarioObjectiveTracker then
            ScenarioObjectiveTracker:SetCollapsed(true)
            if QuestLogCollapseCharDB and getProfile().debug then
                print("|cff00ff00[QuestLogCollapse]|r Scenario section collapsed")
            end
        end
        
        if settings.collapseCampaigns and CampaignQuestObjectiveTracker then
            CampaignQuestObjectiveTracker:SetCollapsed(true)
            if QuestLogCollapseCharDB and getProfile().debug then
                print("|cff00ff00[QuestLogCollapse]|r Campaign section collapsed")
            end
        end
        
        if settings.collapseProfessions and ProfessionsRecipeTracker then
            ProfessionsRecipeTracker:SetCollapsed(true)
            if QuestLogCollapseCharDB and getProfile().debug then
                print("|cff00ff00[QuestLogCollapse]|r Professions section collapsed")
            end
        end
        
        if settings.collapseMonthlyActivities and MonthlyActivitiesObjectiveTracker then
            MonthlyActivitiesObjectiveTracker:SetCollapsed(true)
            if QuestLogCollapseCharDB and getProfile().debug then
                print("|cff00ff00[QuestLogCollapse]|r Monthly activities section collapsed")
            end
        end
        
        if settings.collapseUIWidgets and UIWidgetObjectiveTracker then
            UIWidgetObjectiveTracker:SetCollapsed(true)
            if QuestLogCollapseCharDB and getProfile().debug then
                print("|cff00ff00[QuestLogCollapse]|r UI widgets section collapsed")
            end
        end
        
        if settings.collapseAdventureMaps and AdventureMapQuestObjectiveTracker then
            AdventureMapQuestObjectiveTracker:SetCollapsed(true)
            if QuestLogCollapseCharDB and getProfile().debug then
                print("|cff00ff00[QuestLogCollapse]|r Adventure map section collapsed")
            end
        end
    end

    function ExpandQuestLog()
        local settings = GetCurrentInstanceSettings()
        if not settings or not settings.enabled then return end
        
        if settings.collapseQuests and QuestObjectiveTracker then
            QuestObjectiveTracker:SetCollapsed(false)
            if QuestLogCollapseCharDB and getProfile().debug then
                print("|cff00ff00[QuestLogCollapse]|r Quest section expanded")
            end
        end
        
        if settings.collapseAchievements and AchievementObjectiveTracker then
            AchievementObjectiveTracker:SetCollapsed(false)
            if QuestLogCollapseCharDB and getProfile().debug then
                print("|cff00ff00[QuestLogCollapse]|r Achievement section expanded")
            end
        end
        
        if settings.collapseBonusObjectives and BonusObjectiveTracker then
            BonusObjectiveTracker:SetCollapsed(false)
            if QuestLogCollapseCharDB and getProfile().debug then
                print("|cff00ff00[QuestLogCollapse]|r Bonus objectives section expanded")
            end
        end
        
        if settings.collapseScenarios and ScenarioObjectiveTracker then
            ScenarioObjectiveTracker:SetCollapsed(false)
            if QuestLogCollapseCharDB and getProfile().debug then
                print("|cff00ff00[QuestLogCollapse]|r Scenario section expanded")
            end
        end
        
        if settings.collapseCampaigns and CampaignQuestObjectiveTracker then
            CampaignQuestObjectiveTracker:SetCollapsed(false)
            if QuestLogCollapseCharDB and getProfile().debug then
                print("|cff00ff00[QuestLogCollapse]|r Campaign section expanded")
            end
        end
        
        if settings.collapseProfessions and ProfessionsRecipeTracker then
            ProfessionsRecipeTracker:SetCollapsed(false)
            if QuestLogCollapseCharDB and getProfile().debug then
                print("|cff00ff00[QuestLogCollapse]|r Professions section expanded")
            end
        end
        
        if settings.collapseMonthlyActivities and MonthlyActivitiesObjectiveTracker then
            MonthlyActivitiesObjectiveTracker:SetCollapsed(false)
            if QuestLogCollapseCharDB and getProfile().debug then
                print("|cff00ff00[QuestLogCollapse]|r Monthly activities section expanded")
            end
        end
        
        if settings.collapseUIWidgets and UIWidgetObjectiveTracker then
            UIWidgetObjectiveTracker:SetCollapsed(false)
            if QuestLogCollapseCharDB and getProfile().debug then
                print("|cff00ff00[QuestLogCollapse]|r UI widgets section expanded")
            end
        end
        
        if settings.collapseAdventureMaps and AdventureMapQuestObjectiveTracker then
            AdventureMapQuestObjectiveTracker:SetCollapsed(false)
            if QuestLogCollapseCharDB and getProfile().debug then
                print("|cff00ff00[QuestLogCollapse]|r Adventure map section expanded")
            end
        end
    end

    function OnZoneChanged()
        local prof = getProfile()
        if not prof.enabled then return end
        
        local settings = GetCurrentInstanceSettings()
        if not settings or not settings.enabled then return end
        
        if IsInDungeon() then
            if QuestLogCollapseCharDB and prof.debug then
                print("|cff00ff00[QuestLogCollapse]|r Entered instance - collapsing configured sections")
            end
            CollapseQuestLog()
        else
            if QuestLogCollapseCharDB and prof.debug then
                print("|cff00ff00[QuestLogCollapse]|r Left instance - expanding configured sections")
            end
            ExpandQuestLog()
        end
    end
end
-- QuestLogCollapse: Automatically collapses quest log when entering dungeons
-- Author: YourName
-- Version: 1.0.0

local QuestLogCollapse = CreateFrame("Frame")
QuestLogCollapse:RegisterEvent("ADDON_LOADED")
QuestLogCollapse:RegisterEvent("ZONE_CHANGED_NEW_AREA")
QuestLogCollapse:RegisterEvent("PLAYER_REGEN_DISABLED")
QuestLogCollapse:RegisterEvent("PLAYER_REGEN_ENABLED")

-- Default settings
local defaults = {
    enabled = true,
    debug = false,
    collapseQuests = true,
    collapseAchievements = false,
    collapseBonusObjectives = true,
    collapseScenarios = false,
    collapseCampaigns = true,
    collapseProfessions = false,
    collapseMonthlyActivities = false,
    collapseUIWidgets = false,
    collapseAdventureMaps = false,
    collapseWorldQuests = false,
    namePlates = { enabled = false }
}

-- Initialize saved variables
QuestLogCollapseDB = QuestLogCollapseDB or {}

local function DebugPrint(message)
    local profile = GetCurrentQLCProfile and GetCurrentQLCProfile() or QuestLogCollapseDB
    if profile and profile.debug then
        print("|cff00ff00[QuestLogCollapse]|r " .. message)
    end
end

local function IsInDungeon()
    local instanceType = select(2, IsInInstance())
    return instanceType == "party" or instanceType == "raid" or instanceType == "scenario" or instanceType == "pvp" or
        instanceType == "arena"
end

local function CollapseQuestLog()
    -- Get instance-specific settings from config system
    local settings = GetCurrentInstanceSettings and GetCurrentInstanceSettings()

    DebugPrint("CollapseQuestLog() called")

    if not settings then
        DebugPrint("No instance settings found")
        return
    end

    if not settings.enabled then
        DebugPrint("Instance type not enabled for collapsing")
        return
    end

    DebugPrint("Instance settings found and enabled, proceeding with collapse")
    local collapsed = 0

    if settings.collapseQuests and QuestObjectiveTracker then
        QuestObjectiveTracker:SetCollapsed(true)
        DebugPrint("Quest section collapsed")
        collapsed = collapsed + 1
    end

    if settings.collapseAchievements and AchievementObjectiveTracker then
        AchievementObjectiveTracker:SetCollapsed(true)
        DebugPrint("Achievement section collapsed")
        collapsed = collapsed + 1
    end

    if settings.collapseBonusObjectives and BonusObjectiveTracker then
        BonusObjectiveTracker:SetCollapsed(true)
        DebugPrint("Bonus objectives section collapsed")
        collapsed = collapsed + 1
    end

    if settings.collapseScenarios and ScenarioObjectiveTracker then
        ScenarioObjectiveTracker:SetCollapsed(true)
        DebugPrint("Scenario section collapsed")
        collapsed = collapsed + 1
    end

    if settings.collapseCampaigns and CampaignQuestObjectiveTracker then
        CampaignQuestObjectiveTracker:SetCollapsed(true)
        DebugPrint("Campaign section collapsed")
        collapsed = collapsed + 1
    end

    if settings.collapseProfessions and ProfessionsRecipeTracker then
        ProfessionsRecipeTracker:SetCollapsed(true)
        DebugPrint("Professions section collapsed")
        collapsed = collapsed + 1
    end

    if settings.collapseMonthlyActivities and MonthlyActivitiesObjectiveTracker then
        MonthlyActivitiesObjectiveTracker:SetCollapsed(true)
        DebugPrint("Monthly activities section collapsed")
        collapsed = collapsed + 1
    end

    if settings.collapseUIWidgets and UIWidgetObjectiveTracker then
        UIWidgetObjectiveTracker:SetCollapsed(true)
        DebugPrint("UI widgets section collapsed")
        collapsed = collapsed + 1
    end

    if settings.collapseAdventureMaps and AdventureMapQuestObjectiveTracker then
        AdventureMapQuestObjectiveTracker:SetCollapsed(true)
        DebugPrint("Adventure map section collapsed")
        collapsed = collapsed + 1
    end

    if settings.collapseWorldQuests and WorldQuestObjectiveTracker then
        WorldQuestObjectiveTracker:SetCollapsed(true)
        DebugPrint("World quest section collapsed")
        collapsed = collapsed + 1
    end

    DebugPrint("Collapsed " .. collapsed .. " sections")
    -- Handle nameplate settings
    if settings.namePlates and settings.namePlates.enabled then
        DebugPrint("Enabling nameplates for instance")
        SetCVar("nameplateShowAll", 1)
    end
end

local function ExpandQuestLog()
    -- When leaving an instance, expand all sections regardless of settings
    -- This ensures we restore the original state

    DebugPrint("ExpandQuestLog() called")
    local expanded = 0

    if QuestObjectiveTracker then
        QuestObjectiveTracker:SetCollapsed(false)
        DebugPrint("Quest section expanded")
        expanded = expanded + 1
    else
        DebugPrint("QuestObjectiveTracker not found")
    end

    if AchievementObjectiveTracker then
        AchievementObjectiveTracker:SetCollapsed(false)
        DebugPrint("Achievement section expanded")
        expanded = expanded + 1
    else
        DebugPrint("AchievementObjectiveTracker not found")
    end

    if BonusObjectiveTracker then
        BonusObjectiveTracker:SetCollapsed(false)
        DebugPrint("Bonus objectives section expanded")
        expanded = expanded + 1
    else
        DebugPrint("BonusObjectiveTracker not found")
    end

    if ScenarioObjectiveTracker then
        ScenarioObjectiveTracker:SetCollapsed(false)
        DebugPrint("Scenario section expanded")
        expanded = expanded + 1
    else
        DebugPrint("ScenarioObjectiveTracker not found")
    end

    if CampaignQuestObjectiveTracker then
        CampaignQuestObjectiveTracker:SetCollapsed(false)
        DebugPrint("Campaign section expanded")
        expanded = expanded + 1
    else
        DebugPrint("CampaignQuestObjectiveTracker not found")
    end

    if ProfessionsRecipeTracker then
        ProfessionsRecipeTracker:SetCollapsed(false)
        DebugPrint("Professions section expanded")
        expanded = expanded + 1
    else
        DebugPrint("ProfessionsRecipeTracker not found")
    end

    if MonthlyActivitiesObjectiveTracker then
        MonthlyActivitiesObjectiveTracker:SetCollapsed(false)
        DebugPrint("Monthly activities section expanded")
        expanded = expanded + 1
    else
        DebugPrint("MonthlyActivitiesObjectiveTracker not found")
    end

    if UIWidgetObjectiveTracker then
        UIWidgetObjectiveTracker:SetCollapsed(false)
        DebugPrint("UI widgets section expanded")
        expanded = expanded + 1
    else
        DebugPrint("UIWidgetObjectiveTracker not found")
    end
    if AdventureMapQuestObjectiveTracker then
        AdventureMapQuestObjectiveTracker:SetCollapsed(false)
        DebugPrint("Adventure map section expanded")
        expanded = expanded + 1
    else
        DebugPrint("AdventureMapQuestObjectiveTracker not found")
    end
    if WorldQuestObjectiveTracker then
        WorldQuestObjectiveTracker:SetCollapsed(false)
        DebugPrint("World quest section expanded")
        expanded = expanded + 1
    else
        DebugPrint("WorldQuestObjectiveTracker not found")
    end

    -- Try alternative method for the entire ObjectiveTrackerFrame
    if ObjectiveTrackerFrame then
        if ObjectiveTrackerFrame.SetCollapsed then
            ObjectiveTrackerFrame:SetCollapsed(false)
            DebugPrint("ObjectiveTrackerFrame expanded")
            expanded = expanded + 1
        end

        -- Also try expanding all modules
        if ObjectiveTrackerFrame.MODULES then
            for i, module in ipairs(ObjectiveTrackerFrame.MODULES) do
                if module and module.SetCollapsed then
                    module:SetCollapsed(false)
                    DebugPrint("Module " .. i .. " expanded")
                    expanded = expanded + 1
                end
            end
        end
    else
        DebugPrint("ObjectiveTrackerFrame not found")
    end

    DebugPrint("Expanded " .. expanded .. " sections/modules")
    -- Restore nameplate settings
    DebugPrint("Disabling nameplates after leaving instance")
    SetCVar("nameplateShowAll", 0)
end

local function OnZoneChanged()
    local profile = GetCurrentQLCProfile and GetCurrentQLCProfile() or QuestLogCollapseDB
    if not profile or not profile.enabled then
        DebugPrint("Addon disabled or no profile found")
        return
    end

    DebugPrint("Zone change detected, checking instance status...")

    -- Add a small delay to ensure accurate instance detection
    C_Timer.After(0.5, function()
        local inInstance, instanceType = IsInInstance()
        DebugPrint("Instance check: inInstance=" .. tostring(inInstance) .. ", type=" .. tostring(instanceType))

        if IsInDungeon() then
            DebugPrint("Entered instance - collapsing configured sections")
            CollapseQuestLog()
        else
            DebugPrint("Left instance - expanding all collapsed sections")
            ExpandQuestLog()
        end
    end)
end

local function OnAddonLoaded(addonName)
    if addonName ~= "QuestLogCollapse" then
        return
    end

    -- Basic initialization - detailed config handled by config file
    for key, value in pairs(defaults) do
        if QuestLogCollapseDB[key] == nil then
            QuestLogCollapseDB[key] = value
        end
    end

    print("|cff00ff00QuestLogCollapse|r v1.0.0 loaded. Type |cffff0000/qlc config|r for options.")

    -- Check initial state
    if IsInDungeon() then
        local profile = GetCurrentQLCProfile and GetCurrentQLCProfile() or QuestLogCollapseDB
        if profile and profile.enabled then
            CollapseQuestLog()
        end
    end
end

local function OnCombatStateChanged(event)
    local profile = GetCurrentQLCProfile and GetCurrentQLCProfile() or QuestLogCollapseDB
    if not profile or not profile.enabled then
        DebugPrint("Addon disabled or no profile found")
        return
    end
    -- make sure we're not in a dungeon to avoid conflicts
    if not IsInDungeon() then
        if event == "PLAYER_REGEN_DISABLED" then
            DebugPrint("Entering combat - checking status for collapse")

            CollapseQuestLog()
        elseif event == "PLAYER_REGEN_ENABLED" then
            DebugPrint("Leaving combat - checking status for expand")
            ExpandQuestLog()
        end
    end
end
-- Event handler
QuestLogCollapse:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        OnAddonLoaded(...)
    elseif event == "ZONE_CHANGED_NEW_AREA" then
        OnZoneChanged()
    elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
        -- Handle combat options
        OnCombatStateChanged(event)
    end
end)

-- Slash command handler
SLASH_QUESTLOGCOLLAPSE1 = "/qlc"
SLASH_QUESTLOGCOLLAPSE2 = "/questlogcollapse"

function SlashCmdList.QUESTLOGCOLLAPSE(msg)
    local args = {}
    for word in msg:gmatch("%S+") do
        table.insert(args, word:lower())
    end

    if #args == 0 or args[1] == "help" then
        print("|cff00ff00QuestLogCollapse Commands:|r")
        print("|cffff0000/qlc toggle|r - Toggle addon on/off")
        print("|cffff0000/qlc debug|r - Toggle debug messages")
        print("|cffff0000/qlc status|r - Show current status")
        print("|cffff0000/qlc collapse|r - Manually collapse configured sections")
        print("|cffff0000/qlc expand|r - Manually expand all collapsed sections")
        print("|cffff0000/qlc test|r - Test objective tracker detection")
        print("|cffff0000/qlc config|r - Open configuration panel")
        print("Available sections: quests, achievements, bonus, scenarios,")
        print("campaigns, professions, monthly, widgets, adventuremaps")
    elseif args[1] == "toggle" then
        local profile = GetCurrentQLCProfile and GetCurrentQLCProfile() or QuestLogCollapseDB
        if profile then
            profile.enabled = not profile.enabled
            print("|cff00ff00QuestLogCollapse|r " .. (profile.enabled and "enabled" or "disabled"))
        end
    elseif args[1] == "debug" then
        local profile = GetCurrentQLCProfile and GetCurrentQLCProfile() or QuestLogCollapseDB
        if profile then
            profile.debug = not profile.debug
            print("|cff00ff00QuestLogCollapse|r debug " .. (profile.debug and "enabled" or "disabled"))
        end
    elseif args[1] == "config" then
        if CreateQuestLogCollapseConfigPanel then
            local configPanel = CreateQuestLogCollapseConfigPanel()
            if Settings and Settings.OpenToCategory then
                -- Try to register and open in the new settings system
                if not configPanel.categoryID then
                    configPanel.categoryID = Settings.RegisterCanvasLayoutCategory(configPanel, "QuestLogCollapse")
                    Settings.RegisterAddOnCategory(configPanel.categoryID)
                end
                Settings.OpenToCategory(configPanel.categoryID)
            elseif InterfaceOptionsFrame_OpenToCategory and configPanel then
                -- Fallback to old interface options
                InterfaceOptions_AddCategory(configPanel)
                InterfaceOptionsFrame_OpenToCategory(configPanel)
                InterfaceOptionsFrame_OpenToCategory(configPanel) -- Called twice for proper display
            else
                -- Direct show if other methods fail
                configPanel:Show()
            end
        else
            print("|cff00ff00QuestLogCollapse|r Configuration panel not available.")
        end
    elseif args[1] == "status" then
        local profile = GetCurrentQLCProfile and GetCurrentQLCProfile() or QuestLogCollapseDB
        print("|cff00ff00QuestLogCollapse Status:|r")
        print("Enabled: " .. ((profile and profile.enabled) and "Yes" or "No"))
        print("Debug: " .. ((profile and profile.debug) and "Yes" or "No"))
        print("In Instance: " .. (IsInDungeon() and "Yes" or "No"))

        local settings = GetCurrentInstanceSettings and GetCurrentInstanceSettings()
        if settings then
            local instanceType = select(2, IsInInstance())
            print("Current Instance Settings (" .. (instanceType or "none") .. "):")
            print("  Instance Type Enabled: " .. (settings.enabled and "Yes" or "No"))
        end

        print("|cff00ff00Current Section States:|r")
        if QuestObjectiveTracker then
            print("Quests: " .. (QuestObjectiveTracker.collapsed and "Collapsed" or "Expanded"))
        end
        if AchievementObjectiveTracker then
            print("Achievements: " .. (AchievementObjectiveTracker.collapsed and "Collapsed" or "Expanded"))
        end
        if BonusObjectiveTracker then
            print("Bonus Objectives: " .. (BonusObjectiveTracker.collapsed and "Collapsed" or "Expanded"))
        end
        if ScenarioObjectiveTracker then
            print("Scenarios: " .. (ScenarioObjectiveTracker.collapsed and "Collapsed" or "Expanded"))
        end
    elseif args[1] == "collapse" then
        CollapseQuestLog()
        print("|cff00ff00QuestLogCollapse|r manually collapsed configured sections")
    elseif args[1] == "expand" then
        ExpandQuestLog()
        print("|cff00ff00QuestLogCollapse|r manually expanded all collapsed sections")
    elseif args[1] == "test" then
        print("|cff00ff00QuestLogCollapse Test Results:|r")
        print("QuestObjectiveTracker: " .. (QuestObjectiveTracker and "Found" or "Not found"))
        print("AchievementObjectiveTracker: " .. (AchievementObjectiveTracker and "Found" or "Not found"))
        print("BonusObjectiveTracker: " .. (BonusObjectiveTracker and "Found" or "Not found"))
        print("ObjectiveTrackerFrame: " .. (ObjectiveTrackerFrame and "Found" or "Not found"))
        if ObjectiveTrackerFrame and ObjectiveTrackerFrame.MODULES then
            print("ObjectiveTrackerFrame.MODULES count: " .. #ObjectiveTrackerFrame.MODULES)
        end
        local inInstance, instanceType = IsInInstance()
        print("In Instance: " .. tostring(inInstance) .. ", Type: " .. tostring(instanceType))
        print("IsInDungeon(): " .. tostring(IsInDungeon()))
        local settings = GetCurrentInstanceSettings and GetCurrentInstanceSettings()
        print("Current Instance Settings: " .. (settings and "Found" or "Not found"))
        if settings then
            print("  Settings enabled: " .. tostring(settings.enabled))
        end
    else
        print("|cff00ff00QuestLogCollapse|r Unknown command. Type |cffff0000/qlc help|r for available commands.")
    end
end

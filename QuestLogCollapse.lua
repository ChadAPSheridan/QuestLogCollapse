-- QuestLogCollapse: Automatically collapses quest log when entering dungeons
-- Author: YourName
-- Version: 1.0.0

local QuestLogCollapse = CreateFrame("Frame")
QuestLogCollapse:RegisterEvent("ADDON_LOADED")
QuestLogCollapse:RegisterEvent("ZONE_CHANGED_NEW_AREA")

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
    collapseAdventureMaps = false
}

-- Initialize saved variables
QuestLogCollapseDB = QuestLogCollapseDB or {}

local function DebugPrint(message)
    if QuestLogCollapseDB.debug then
        print("|cff00ff00[QuestLogCollapse]|r " .. message)
    end
end

local function IsInDungeon()
    local instanceType = select(2, IsInInstance())
    return instanceType == "party" or instanceType == "raid"
end

local function CollapseQuestLog()
    -- Collapse individual sections based on settings
    if QuestLogCollapseDB.collapseQuests and QuestObjectiveTracker then
        QuestObjectiveTracker:SetCollapsed(true)
        DebugPrint("Quest section collapsed")
    end
    
    if QuestLogCollapseDB.collapseAchievements and AchievementObjectiveTracker then
        AchievementObjectiveTracker:SetCollapsed(true)
        DebugPrint("Achievement section collapsed")
    end
    
    if QuestLogCollapseDB.collapseBonusObjectives and BonusObjectiveTracker then
        BonusObjectiveTracker:SetCollapsed(true)
        DebugPrint("Bonus objectives section collapsed")
    end
    
    if QuestLogCollapseDB.collapseScenarios and ScenarioObjectiveTracker then
        ScenarioObjectiveTracker:SetCollapsed(true)
        DebugPrint("Scenario section collapsed")
    end
    
    if QuestLogCollapseDB.collapseCampaigns and CampaignQuestObjectiveTracker then
        CampaignQuestObjectiveTracker:SetCollapsed(true)
        DebugPrint("Campaign section collapsed")
    end
    
    if QuestLogCollapseDB.collapseProfessions and ProfessionsRecipeTracker then
        ProfessionsRecipeTracker:SetCollapsed(true)
        DebugPrint("Professions section collapsed")
    end
    
    if QuestLogCollapseDB.collapseMonthlyActivities and MonthlyActivitiesObjectiveTracker then
        MonthlyActivitiesObjectiveTracker:SetCollapsed(true)
        DebugPrint("Monthly activities section collapsed")
    end
    
    if QuestLogCollapseDB.collapseUIWidgets and UIWidgetObjectiveTracker then
        UIWidgetObjectiveTracker:SetCollapsed(true)
        DebugPrint("UI widgets section collapsed")
    end
    
    if QuestLogCollapseDB.collapseAdventureMaps and AdventureMapQuestObjectiveTracker then
        AdventureMapQuestObjectiveTracker:SetCollapsed(true)
        DebugPrint("Adventure map section collapsed")
    end
end

local function ExpandQuestLog()
    -- Expand individual sections based on settings
    if QuestLogCollapseDB.collapseQuests and QuestObjectiveTracker then
        QuestObjectiveTracker:SetCollapsed(false)
        DebugPrint("Quest section expanded")
    end
    
    if QuestLogCollapseDB.collapseAchievements and AchievementObjectiveTracker then
        AchievementObjectiveTracker:SetCollapsed(false)
        DebugPrint("Achievement section expanded")
    end
    
    if QuestLogCollapseDB.collapseBonusObjectives and BonusObjectiveTracker then
        BonusObjectiveTracker:SetCollapsed(false)
        DebugPrint("Bonus objectives section expanded")
    end
    
    if QuestLogCollapseDB.collapseScenarios and ScenarioObjectiveTracker then
        ScenarioObjectiveTracker:SetCollapsed(false)
        DebugPrint("Scenario section expanded")
    end
    
    if QuestLogCollapseDB.collapseCampaigns and CampaignQuestObjectiveTracker then
        CampaignQuestObjectiveTracker:SetCollapsed(false)
        DebugPrint("Campaign section expanded")
    end
    
    if QuestLogCollapseDB.collapseProfessions and ProfessionsRecipeTracker then
        ProfessionsRecipeTracker:SetCollapsed(false)
        DebugPrint("Professions section expanded")
    end
    
    if QuestLogCollapseDB.collapseMonthlyActivities and MonthlyActivitiesObjectiveTracker then
        MonthlyActivitiesObjectiveTracker:SetCollapsed(false)
        DebugPrint("Monthly activities section expanded")
    end
    
    if QuestLogCollapseDB.collapseUIWidgets and UIWidgetObjectiveTracker then
        UIWidgetObjectiveTracker:SetCollapsed(false)
        DebugPrint("UI widgets section expanded")
    end
    
    if QuestLogCollapseDB.collapseAdventureMaps and AdventureMapQuestObjectiveTracker then
        AdventureMapQuestObjectiveTracker:SetCollapsed(false)
        DebugPrint("Adventure map section expanded")
    end
end

local function OnZoneChanged()
    if not QuestLogCollapseDB.enabled then
        return
    end
    
    if IsInDungeon() then
        DebugPrint("Entered dungeon/raid - collapsing quest log")
        CollapseQuestLog()
    else
        DebugPrint("Left dungeon/raid - expanding quest log")
        ExpandQuestLog()
    end
end

local function OnAddonLoaded(addonName)
    if addonName ~= "QuestLogCollapse" then
        return
    end
    
    -- Initialize settings with defaults
    for key, value in pairs(defaults) do
        if QuestLogCollapseDB[key] == nil then
            QuestLogCollapseDB[key] = value
        end
    end
    
    print("|cff00ff00QuestLogCollapse|r v1.0.0 loaded. Type |cffff0000/qlc|r for options.")
    
    -- Check initial state
    if IsInDungeon() and QuestLogCollapseDB.enabled then
        CollapseQuestLog()
    end
end

-- Event handler
QuestLogCollapse:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        OnAddonLoaded(...)
    elseif event == "ZONE_CHANGED_NEW_AREA" then
        OnZoneChanged()
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
        print("|cffff0000/qlc expand|r - Manually expand configured sections")
        print("|cffff0000/qlc config|r - Show configuration options")
        print("|cffff0000/qlc set <section> <true/false>|r - Configure section")
        print("Available sections: quests, achievements, bonus, scenarios,")
        print("campaigns, professions, monthly, widgets, adventuremaps")
    elseif args[1] == "toggle" then
        QuestLogCollapseDB.enabled = not QuestLogCollapseDB.enabled
        print("|cff00ff00QuestLogCollapse|r " .. (QuestLogCollapseDB.enabled and "enabled" or "disabled"))
    elseif args[1] == "debug" then
        QuestLogCollapseDB.debug = not QuestLogCollapseDB.debug
        print("|cff00ff00QuestLogCollapse|r debug " .. (QuestLogCollapseDB.debug and "enabled" or "disabled"))
    elseif args[1] == "config" then
        print("|cff00ff00QuestLogCollapse Configuration:|r")
        print("Quests: " .. (QuestLogCollapseDB.collapseQuests and "ON" or "OFF"))
        print("Achievements: " .. (QuestLogCollapseDB.collapseAchievements and "ON" or "OFF"))
        print("Bonus Objectives: " .. (QuestLogCollapseDB.collapseBonusObjectives and "ON" or "OFF"))
        print("Scenarios: " .. (QuestLogCollapseDB.collapseScenarios and "ON" or "OFF"))
        print("Campaigns: " .. (QuestLogCollapseDB.collapseCampaigns and "ON" or "OFF"))
        print("Professions: " .. (QuestLogCollapseDB.collapseProfessions and "ON" or "OFF"))
        print("Monthly Activities: " .. (QuestLogCollapseDB.collapseMonthlyActivities and "ON" or "OFF"))
        print("UI Widgets: " .. (QuestLogCollapseDB.collapseUIWidgets and "ON" or "OFF"))
        print("Adventure Maps: " .. (QuestLogCollapseDB.collapseAdventureMaps and "ON" or "OFF"))
    elseif args[1] == "set" and args[2] and args[3] then
        local section = args[2]
        local value = args[3] == "true"
        
        if section == "quests" then
            QuestLogCollapseDB.collapseQuests = value
            print("|cff00ff00QuestLogCollapse|r Quests collapse: " .. (value and "ON" or "OFF"))
        elseif section == "achievements" then
            QuestLogCollapseDB.collapseAchievements = value
            print("|cff00ff00QuestLogCollapse|r Achievements collapse: " .. (value and "ON" or "OFF"))
        elseif section == "bonus" then
            QuestLogCollapseDB.collapseBonusObjectives = value
            print("|cff00ff00QuestLogCollapse|r Bonus objectives collapse: " .. (value and "ON" or "OFF"))
        elseif section == "scenarios" then
            QuestLogCollapseDB.collapseScenarios = value
            print("|cff00ff00QuestLogCollapse|r Scenarios collapse: " .. (value and "ON" or "OFF"))
        elseif section == "campaigns" then
            QuestLogCollapseDB.collapseCampaigns = value
            print("|cff00ff00QuestLogCollapse|r Campaigns collapse: " .. (value and "ON" or "OFF"))
        elseif section == "professions" then
            QuestLogCollapseDB.collapseProfessions = value
            print("|cff00ff00QuestLogCollapse|r Professions collapse: " .. (value and "ON" or "OFF"))
        elseif section == "monthly" then
            QuestLogCollapseDB.collapseMonthlyActivities = value
            print("|cff00ff00QuestLogCollapse|r Monthly activities collapse: " .. (value and "ON" or "OFF"))
        elseif section == "widgets" then
            QuestLogCollapseDB.collapseUIWidgets = value
            print("|cff00ff00QuestLogCollapse|r UI widgets collapse: " .. (value and "ON" or "OFF"))
        elseif section == "adventuremaps" then
            QuestLogCollapseDB.collapseAdventureMaps = value
            print("|cff00ff00QuestLogCollapse|r Adventure maps collapse: " .. (value and "ON" or "OFF"))
        else
            print("|cff00ff00QuestLogCollapse|r Unknown section. Use /qlc help for available sections.")
        end
    elseif args[1] == "status" then
        print("|cff00ff00QuestLogCollapse Status:|r")
        print("Enabled: " .. (QuestLogCollapseDB.enabled and "Yes" or "No"))
        print("Debug: " .. (QuestLogCollapseDB.debug and "Yes" or "No"))
        print("In Dungeon: " .. (IsInDungeon() and "Yes" or "No"))
        
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
        print("|cff00ff00QuestLogCollapse|r manually expanded configured sections")
    else
        print("|cff00ff00QuestLogCollapse|r Unknown command. Type |cffff0000/qlc help|r for available commands.")
    end
end
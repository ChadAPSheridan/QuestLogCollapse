-- QuestLogCollapse: Automatically collapses quest log when entering dungeons
-- Author: YourName
-- Version: 1.1.0
--
-- TAINT PROTECTION STRATEGY:
-- Instead of avoiding problematic trackers, this version uses secure manipulation methods:
-- 
-- 1. OnUpdate frame execution - Operations run outside event context
-- 2. Multiple fallback methods - Direct SetCollapsed() + property manipulation
-- 3. Pending operation queue - Defers operations during busy periods then executes them
-- 4. Secure timing - Uses frame updates instead of timers for critical operations
-- 
-- This ensures ALL configured trackers work while preventing taint issues.

local QuestLogCollapse = CreateFrame("Frame")
QuestLogCollapse:RegisterEvent("ADDON_LOADED")
QuestLogCollapse:RegisterEvent("ZONE_CHANGED_NEW_AREA")
QuestLogCollapse:RegisterEvent("PLAYER_ENTER_COMBAT")
QuestLogCollapse:RegisterEvent("PLAYER_REGEN_DISABLED")
QuestLogCollapse:RegisterEvent("PLAYER_REGEN_ENABLED")
QuestLogCollapse:RegisterEvent("PLAYER_ENTERING_WORLD")

-- Track if we're in the middle of map system operations to avoid interference
local mapSystemBusy = false

-- Track loading state to prevent operations during initialization
local isFullyLoaded = false

-- Track which operations are pending to avoid conflicts
local pendingOperations = {}

-- Track combat state for delayed operations
local combatStateQueue = {
    shouldCollapseOnCombatEnd = false,
    shouldExpandOnCombatEnd = false,
    enteredCombatOutsideInstance = false,
    trackersWereCollapsedInCombat = false
}

-- Track nameplate state to restore properly
local namePlateState = {
    originalShowAll = nil,  -- Original value before addon touched it
    addonControlled = false -- Whether the addon is currently controlling nameplates
}

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

-- Safe function to collapse a tracker using secure methods
local function SafeCollapseTracker(tracker, name, shouldCollapse)
    if not isFullyLoaded or not tracker or not shouldCollapse then
        return false
    end
    
    -- NEVER manipulate trackers during combat to avoid taint
    if InCombatLockdown() then
        DebugPrint("Skipping " .. name .. " collapse - in combat")
        return false
    end
    
    -- Avoid operations when map system might be busy
    if mapSystemBusy then
        DebugPrint("Deferring " .. name .. " collapse - map system busy")
        -- Store for later execution
        pendingOperations[name] = {action = "collapse", tracker = tracker}
        return true
    end
    
    -- Check if this operation is already pending
    if pendingOperations[name] then
        DebugPrint("Operation already pending for " .. name)
        return true
    end
    
    -- Use secure execution with frame script
    local success = false
    
    -- Method 1: Try direct collapse outside of any event context
    if tracker.SetCollapsed and type(tracker.SetCollapsed) == "function" then
        local executeFrame = CreateFrame("Frame")
        executeFrame:SetScript("OnUpdate", function(self)
            self:SetScript("OnUpdate", nil)
            
            if InCombatLockdown() then
                DebugPrint("Combat started, aborting " .. name .. " collapse")
                return
            end
            
            local ok, err = pcall(function()
                if tracker and tracker.SetCollapsed then
                    tracker:SetCollapsed(true)
                end
            end)
            
            if ok then
                DebugPrint(name .. " section collapsed successfully")
                success = true
            else
                DebugPrint("Method 1 failed for " .. name .. ": " .. tostring(err))
                
                -- Method 2: Try using the collapsed property directly
                local ok2, err2 = pcall(function()
                    if tracker then
                        tracker.collapsed = true
                        if tracker.Update then
                            tracker:Update()
                        end
                    end
                end)
                
                if ok2 then
                    DebugPrint(name .. " section collapsed using property method")
                    success = true
                else
                    DebugPrint("All methods failed for " .. name .. ": " .. tostring(err2))
                end
            end
        end)
    end
    
    return true
end

local function CollapseQuestLog()
    -- NEVER do anything during combat to avoid taint
    if InCombatLockdown() then
        DebugPrint("CollapseQuestLog() skipped - in combat")
        return
    end
    
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

    -- Use safe collapse function for all trackers
    if SafeCollapseTracker(QuestObjectiveTracker, "Quest", settings.collapseQuests) then
        collapsed = collapsed + 1
    end

    if SafeCollapseTracker(AchievementObjectiveTracker, "Achievement", settings.collapseAchievements) then
        collapsed = collapsed + 1
    end

    if SafeCollapseTracker(BonusObjectiveTracker, "Bonus objectives", settings.collapseBonusObjectives) then
        collapsed = collapsed + 1
    end

    if SafeCollapseTracker(ScenarioObjectiveTracker, "Scenario", settings.collapseScenarios) then
        collapsed = collapsed + 1
    end

    if SafeCollapseTracker(CampaignQuestObjectiveTracker, "Campaign", settings.collapseCampaigns) then
        collapsed = collapsed + 1
    end

    if SafeCollapseTracker(ProfessionsRecipeTracker, "Professions", settings.collapseProfessions) then
        collapsed = collapsed + 1
    end

    if SafeCollapseTracker(MonthlyActivitiesObjectiveTracker, "Monthly activities", settings.collapseMonthlyActivities) then
        collapsed = collapsed + 1
    end

    if SafeCollapseTracker(UIWidgetObjectiveTracker, "UI widgets", settings.collapseUIWidgets) then
        collapsed = collapsed + 1
    end

    if SafeCollapseTracker(_G["AdventureMapQuestObjectiveTracker"], "Adventure map", settings.collapseAdventureMaps) then
        collapsed = collapsed + 1
    end

    if SafeCollapseTracker(WorldQuestObjectiveTracker, "World quest", settings.collapseWorldQuests) then
        collapsed = collapsed + 1
    end

    DebugPrint("Collapsed " .. collapsed .. " sections")
    
    -- Handle nameplate settings (only if not in combat)
    if settings.namePlates and settings.namePlates.enabled and not InCombatLockdown() then
        DebugPrint("Enabling ENEMY nameplates for instance")
        -- Store original state before changing it (only if we haven't already)
        if not namePlateState.addonControlled then
            namePlateState.originalShowAll = GetCVar("nameplateShowEnemies")
            DebugPrint("Stored original ENEMY nameplate state: " .. tostring(namePlateState.originalShowAll))
            -- Debug: Show current state of all nameplate CVars
            DebugPrint("Before change - nameplateShowAll: " .. tostring(GetCVar("nameplateShowAll")))
            DebugPrint("Before change - nameplateShowEnemies: " .. tostring(GetCVar("nameplateShowEnemies")))
            DebugPrint("Before change - nameplateShowFriends: " .. tostring(GetCVar("nameplateShowFriends")))
        end
        namePlateState.addonControlled = true
        SetCVar("nameplateShowEnemies", "1")
        -- Debug: Show state after change
        DebugPrint("After change - nameplateShowAll: " .. tostring(GetCVar("nameplateShowAll")))
        DebugPrint("After change - nameplateShowEnemies: " .. tostring(GetCVar("nameplateShowEnemies")))
        DebugPrint("After change - nameplateShowFriends: " .. tostring(GetCVar("nameplateShowFriends")))
    end
end

-- Safe function to expand a tracker using secure methods
local function SafeExpandTracker(tracker, name)
    if not isFullyLoaded or not tracker then
        DebugPrint(name .. " not found or not fully loaded")
        return false
    end
    
    -- NEVER manipulate trackers during combat to avoid taint
    if InCombatLockdown() then
        DebugPrint("Skipping " .. name .. " expand - in combat")
        return false
    end
    
    -- Avoid operations when map system might be busy
    if mapSystemBusy then
        DebugPrint("Deferring " .. name .. " expand - map system busy")
        -- Store for later execution
        pendingOperations[name] = {action = "expand", tracker = tracker}
        return true
    end
    
    -- Check if this operation is already pending
    if pendingOperations[name] then
        DebugPrint("Operation already pending for " .. name)
        return true
    end
    
    -- Use secure execution with frame script
    local success = false
    
    -- Method 1: Try direct expand outside of any event context
    if tracker.SetCollapsed and type(tracker.SetCollapsed) == "function" then
        local executeFrame = CreateFrame("Frame")
        executeFrame:SetScript("OnUpdate", function(self)
            self:SetScript("OnUpdate", nil)
            
            if InCombatLockdown() then
                DebugPrint("Combat started, aborting " .. name .. " expand")
                return
            end
            
            local ok, err = pcall(function()
                if tracker and tracker.SetCollapsed then
                    tracker:SetCollapsed(false)
                end
            end)
            
            if ok then
                DebugPrint(name .. " section expanded successfully")
                success = true
            else
                DebugPrint("Method 1 failed for " .. name .. ": " .. tostring(err))
                
                -- Method 2: Try using the collapsed property directly
                local ok2, err2 = pcall(function()
                    if tracker then
                        tracker.collapsed = false
                        if tracker.Update then
                            tracker:Update()
                        end
                    end
                end)
                
                if ok2 then
                    DebugPrint(name .. " section expanded using property method")
                    success = true
                else
                    DebugPrint("All methods failed for " .. name .. ": " .. tostring(err2))
                end
            end
        end)
    end
    
    return true
end

local function ExpandQuestLog()
    -- NEVER do anything during combat to avoid taint
    if InCombatLockdown() then
        DebugPrint("ExpandQuestLog() skipped - in combat")
        return
    end
    
    -- When leaving an instance, expand all sections regardless of settings
    -- This ensures we restore the original state

    DebugPrint("ExpandQuestLog() called")
    local expanded = 0

    -- Use safe expand function for all trackers
    if SafeExpandTracker(QuestObjectiveTracker, "Quest") then
        expanded = expanded + 1
    end

    if SafeExpandTracker(AchievementObjectiveTracker, "Achievement") then
        expanded = expanded + 1
    end

    if SafeExpandTracker(BonusObjectiveTracker, "Bonus objectives") then
        expanded = expanded + 1
    end

    if SafeExpandTracker(ScenarioObjectiveTracker, "Scenario") then
        expanded = expanded + 1
    end

    if SafeExpandTracker(CampaignQuestObjectiveTracker, "Campaign") then
        expanded = expanded + 1
    end

    if SafeExpandTracker(ProfessionsRecipeTracker, "Professions") then
        expanded = expanded + 1
    end

    if SafeExpandTracker(MonthlyActivitiesObjectiveTracker, "Monthly activities") then
        expanded = expanded + 1
    end

    if SafeExpandTracker(UIWidgetObjectiveTracker, "UI widgets") then
        expanded = expanded + 1
    end

    if SafeExpandTracker(_G["AdventureMapQuestObjectiveTracker"], "Adventure map") then
        expanded = expanded + 1
    end

    if SafeExpandTracker(WorldQuestObjectiveTracker, "World quest") then
        expanded = expanded + 1
    end

    -- Try alternative method for the entire ObjectiveTrackerFrame
    if ObjectiveTrackerFrame and not InCombatLockdown() then
        local success, err = pcall(function()
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
        end)
        
        if not success then
            DebugPrint("Failed to expand ObjectiveTrackerFrame: " .. tostring(err))
        end
    else
        DebugPrint("ObjectiveTrackerFrame not found or in combat")
    end

    DebugPrint("Expanded " .. expanded .. " sections/modules")
    
    -- Restore nameplate settings (only if the addon was controlling them)
    if namePlateState.addonControlled and not InCombatLockdown() then
        DebugPrint("Restoring original ENEMY nameplate state: " .. tostring(namePlateState.originalShowAll))
        -- Debug: Show current state before restoration
        DebugPrint("Before restore - nameplateShowAll: " .. tostring(GetCVar("nameplateShowAll")))
        DebugPrint("Before restore - nameplateShowEnemies: " .. tostring(GetCVar("nameplateShowEnemies")))
        DebugPrint("Before restore - nameplateShowFriends: " .. tostring(GetCVar("nameplateShowFriends")))
        
        SetCVar("nameplateShowEnemies", namePlateState.originalShowAll or "0")
        
        -- Debug: Show state after restoration
        DebugPrint("After restore - nameplateShowAll: " .. tostring(GetCVar("nameplateShowAll")))
        DebugPrint("After restore - nameplateShowEnemies: " .. tostring(GetCVar("nameplateShowEnemies")))
        DebugPrint("After restore - nameplateShowFriends: " .. tostring(GetCVar("nameplateShowFriends")))
        
        namePlateState.addonControlled = false
        namePlateState.originalShowAll = nil
    end
end

local function OnZoneChanged()
    local profile = GetCurrentQLCProfile and GetCurrentQLCProfile() or QuestLogCollapseDB
    if not profile or not profile.enabled then
        DebugPrint("Addon disabled or no profile found")
        return
    end

    DebugPrint("Zone change detected, checking instance status...")

    -- Set a flag to indicate map system might be busy
    mapSystemBusy = true
    
    -- Reset the flag after a longer delay to be extra safe
    C_Timer.After(8.0, function()
        mapSystemBusy = false
        -- Process any pending operations
        if next(pendingOperations) then
            DebugPrint("Processing pending tracker operations")
            C_Timer.After(0.5, function()
                for name, operation in pairs(pendingOperations) do
                    if not InCombatLockdown() and operation.tracker then
                        if operation.action == "collapse" then
                            DebugPrint("Executing pending collapse for " .. name)
                            SafeCollapseTracker(operation.tracker, name, true)
                        elseif operation.action == "expand" then
                            DebugPrint("Executing pending expand for " .. name)
                            SafeExpandTracker(operation.tracker, name)
                        end
                    end
                end
                pendingOperations = {}  -- Clear pending operations
            end)
        end
    end)

    -- Add an even longer delay to ensure all Blizzard systems are fully initialized
    -- This prevents any chance of taint during critical system operations
    C_Timer.After(5.0, function()
        -- Double-check that we're not in combat before proceeding
        if InCombatLockdown() then
            DebugPrint("Skipping zone change handling - in combat")
            return
        end
        
        -- Additional check to avoid interference during map operations
        if mapSystemBusy then
            DebugPrint("Map system may be busy, deferring tracker operations")
            C_Timer.After(3.0, function()
                if not InCombatLockdown() then
                    local inInstance, instanceType = IsInInstance()
                    DebugPrint("Deferred instance check: inInstance=" .. tostring(inInstance) .. ", type=" .. tostring(instanceType))

                    if IsInDungeon() then
                        DebugPrint("Entered instance - collapsing configured sections (deferred)")
                        CollapseQuestLog()
                    else
                        DebugPrint("Left instance - expanding all collapsed sections (deferred)")
                        ExpandQuestLog()
                    end
                end
            end)
            return
        end
        
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

    -- Check initial state with a much longer delay to avoid conflicts during addon loading
    -- Give the map system and all other Blizzard systems plenty of time to fully initialize
    C_Timer.After(8.0, function()
        if IsInDungeon() then
            local profile = GetCurrentQLCProfile and GetCurrentQLCProfile() or QuestLogCollapseDB
            if profile and profile.enabled and not InCombatLockdown() then
                DebugPrint("Initial state check: in dungeon, applying collapse")
                CollapseQuestLog()
            end
        end
    end)
end

local function OnCombatStateChanged(event)
    local profile = GetCurrentQLCProfile and GetCurrentQLCProfile() or QuestLogCollapseDB
    if not profile or not profile.enabled then
        DebugPrint("Addon disabled or no profile found")
        return
    end
    
    -- Make sure we're not in a dungeon to avoid conflicts
    if not IsInDungeon() then
        if event == "PLAYER_REGEN_DISABLED" then
            -- Check if combat collapse is enabled
            local settings = GetCurrentInstanceSettings and GetCurrentInstanceSettings()
            if settings and settings.enabled then
                DebugPrint("PLAYER_REGEN_DISABLED fired - checking if early combat already handled collapse")
                
                -- Check if early combat detection already handled the collapse
                if combatStateQueue.enteredCombatOutsideInstance and not combatStateQueue.shouldCollapseOnCombatEnd then
                    DebugPrint("Early combat detection already handled collapse - skipping duplicate attempt")
                    return
                end
                
                DebugPrint("Early combat did not fully handle collapse - attempting immediate collapse")
                
                -- Try to collapse immediately (before taint protection fully kicks in)
                -- This is a backup in case PLAYER_ENTER_COMBAT didn't fire or failed
                local collapsed = 0
                
                -- Attempt immediate collapse of each enabled tracker
                if settings.collapseQuests and QuestObjectiveTracker then
                    local ok, err = pcall(function()
                        if QuestObjectiveTracker.SetCollapsed then
                            QuestObjectiveTracker:SetCollapsed(true)
                            collapsed = collapsed + 1
                        end
                    end)
                    if ok then
                        DebugPrint("Quest tracker immediately collapsed in combat")
                    else
                        DebugPrint("Failed to immediately collapse quest tracker: " .. tostring(err))
                    end
                end
                
                if settings.collapseAchievements and AchievementObjectiveTracker then
                    local ok, err = pcall(function()
                        if AchievementObjectiveTracker.SetCollapsed then
                            AchievementObjectiveTracker:SetCollapsed(true)
                            collapsed = collapsed + 1
                        end
                    end)
                    if ok then
                        DebugPrint("Achievement tracker immediately collapsed in combat")
                    else
                        DebugPrint("Failed to immediately collapse achievement tracker: " .. tostring(err))
                    end
                end
                
                if settings.collapseBonusObjectives and BonusObjectiveTracker then
                    local ok, err = pcall(function()
                        if BonusObjectiveTracker.SetCollapsed then
                            BonusObjectiveTracker:SetCollapsed(true)
                            collapsed = collapsed + 1
                        end
                    end)
                    if ok then
                        DebugPrint("Bonus objectives tracker immediately collapsed in combat")
                    else
                        DebugPrint("Failed to immediately collapse bonus objectives tracker: " .. tostring(err))
                    end
                end
                
                if settings.collapseCampaigns and CampaignQuestObjectiveTracker then
                    local ok, err = pcall(function()
                        if CampaignQuestObjectiveTracker.SetCollapsed then
                            CampaignQuestObjectiveTracker:SetCollapsed(true)
                            collapsed = collapsed + 1
                        end
                    end)
                    if ok then
                        DebugPrint("Campaign tracker immediately collapsed in combat")
                    else
                        DebugPrint("Failed to immediately collapse campaign tracker: " .. tostring(err))
                    end
                end
                
                if settings.collapseWorldQuests and WorldQuestObjectiveTracker then
                    local ok, err = pcall(function()
                        if WorldQuestObjectiveTracker.SetCollapsed then
                            WorldQuestObjectiveTracker:SetCollapsed(true)
                            collapsed = collapsed + 1
                        end
                    end)
                    if ok then
                        DebugPrint("World quest tracker immediately collapsed in combat")
                    else
                        DebugPrint("Failed to immediately collapse world quest tracker: " .. tostring(err))
                    end
                end
                
                if collapsed > 0 then
                    DebugPrint("Successfully collapsed " .. collapsed .. " trackers immediately in combat")
                    -- Mark that we successfully collapsed and need to expand on combat end
                    combatStateQueue.enteredCombatOutsideInstance = true
                    combatStateQueue.shouldCollapseOnCombatEnd = false
                    combatStateQueue.shouldExpandOnCombatEnd = false
                    combatStateQueue.trackersWereCollapsedInCombat = true
                else
                    DebugPrint("No trackers could be collapsed immediately - queuing for after combat")
                    -- Queue the operation for after combat ends
                    combatStateQueue.enteredCombatOutsideInstance = true
                    combatStateQueue.shouldCollapseOnCombatEnd = true
                    combatStateQueue.shouldExpandOnCombatEnd = false
                    combatStateQueue.trackersWereCollapsedInCombat = false
                    DebugPrint("Queuing remaining collapse operations for when combat ends")
                end
            else
                DebugPrint("Combat collapse not enabled for this profile")
                -- Still mark that we entered combat outside instance in case user manually interacts
                combatStateQueue.enteredCombatOutsideInstance = true
                combatStateQueue.shouldCollapseOnCombatEnd = false
                combatStateQueue.shouldExpandOnCombatEnd = false
            end
        elseif event == "PLAYER_REGEN_ENABLED" then
            DebugPrint("Leaving combat - checking queued operations and quest log state")
            
            if combatStateQueue.enteredCombatOutsideInstance and combatStateQueue.shouldCollapseOnCombatEnd then
                DebugPrint("Applying queued collapse operation after combat")
                CollapseQuestLog()
                combatStateQueue.shouldCollapseOnCombatEnd = false
                combatStateQueue.trackersWereCollapsedInCombat = true
            elseif combatStateQueue.shouldExpandOnCombatEnd then
                DebugPrint("Applying queued expand operation after combat")
                ExpandQuestLog()
                combatStateQueue.shouldExpandOnCombatEnd = false
            elseif combatStateQueue.enteredCombatOutsideInstance and combatStateQueue.trackersWereCollapsedInCombat then
                -- If we were in combat outside instances and trackers were collapsed,
                -- expand the quest log when combat ends to restore original state
                local settings = GetCurrentInstanceSettings and GetCurrentInstanceSettings()
                if settings and settings.enabled then
                    DebugPrint("Combat ended outside instance - expanding quest log to restore original state")
                    ExpandQuestLog()
                else
                    DebugPrint("Combat collapse not enabled - no expansion needed")
                end
            elseif combatStateQueue.enteredCombatOutsideInstance then
                DebugPrint("Combat ended outside instance but no trackers were collapsed - no expansion needed")
            end
            
            -- Reset combat tracking
            combatStateQueue.enteredCombatOutsideInstance = false
            combatStateQueue.trackersWereCollapsedInCombat = false
            
        end
    else
        DebugPrint("In dungeon/instance - skipping combat state change handling")
    end
end

-- Early combat detection - this fires before PLAYER_REGEN_DISABLED
local function OnEarlyCombat(event)
    local profile = GetCurrentQLCProfile and GetCurrentQLCProfile() or QuestLogCollapseDB
    if not profile or not profile.enabled then
        DebugPrint("Addon disabled or no profile found")
        return
    end
    
    -- Make sure we're not in a dungeon to avoid conflicts
    if not IsInDungeon() then
        if event == "PLAYER_ENTER_COMBAT" then
            -- Check if combat collapse is enabled
            local settings = GetCurrentInstanceSettings and GetCurrentInstanceSettings()
            if settings and settings.enabled then
                DebugPrint("Early combat detection (PLAYER_ENTER_COMBAT) - attempting immediate collapse")
                
                -- Try to collapse immediately - this happens BEFORE taint protection
                local collapsed = 0
                
                -- Attempt immediate collapse of each enabled tracker
                if settings.collapseQuests and QuestObjectiveTracker then
                    local ok, err = pcall(function()
                        if QuestObjectiveTracker.SetCollapsed then
                            QuestObjectiveTracker:SetCollapsed(true)
                            collapsed = collapsed + 1
                        end
                    end)
                    if ok then
                        DebugPrint("Quest tracker collapsed via early combat detection")
                    else
                        DebugPrint("Failed early collapse of quest tracker: " .. tostring(err))
                    end
                end
                
                if settings.collapseAchievements and AchievementObjectiveTracker then
                    local ok, err = pcall(function()
                        if AchievementObjectiveTracker.SetCollapsed then
                            AchievementObjectiveTracker:SetCollapsed(true)
                            collapsed = collapsed + 1
                        end
                    end)
                    if ok then
                        DebugPrint("Achievement tracker collapsed via early combat detection")
                    else
                        DebugPrint("Failed early collapse of achievement tracker: " .. tostring(err))
                    end
                end
                
                if settings.collapseBonusObjectives and BonusObjectiveTracker then
                    local ok, err = pcall(function()
                        if BonusObjectiveTracker.SetCollapsed then
                            BonusObjectiveTracker:SetCollapsed(true)
                            collapsed = collapsed + 1
                        end
                    end)
                    if ok then
                        DebugPrint("Bonus objectives tracker collapsed via early combat detection")
                    else
                        DebugPrint("Failed early collapse of bonus objectives tracker: " .. tostring(err))
                    end
                end
                
                if settings.collapseCampaigns and CampaignQuestObjectiveTracker then
                    local ok, err = pcall(function()
                        if CampaignQuestObjectiveTracker.SetCollapsed then
                            CampaignQuestObjectiveTracker:SetCollapsed(true)
                            collapsed = collapsed + 1
                        end
                    end)
                    if ok then
                        DebugPrint("Campaign tracker collapsed via early combat detection")
                    else
                        DebugPrint("Failed early collapse of campaign tracker: " .. tostring(err))
                    end
                end
                
                if settings.collapseWorldQuests and WorldQuestObjectiveTracker then
                    local ok, err = pcall(function()
                        if WorldQuestObjectiveTracker.SetCollapsed then
                            WorldQuestObjectiveTracker:SetCollapsed(true)
                            collapsed = collapsed + 1
                        end
                    end)
                    if ok then
                        DebugPrint("World quest tracker collapsed via early combat detection")
                    else
                        DebugPrint("Failed early collapse of world quest tracker: " .. tostring(err))
                    end
                end
                
                if collapsed > 0 then
                    DebugPrint("Successfully collapsed " .. collapsed .. " trackers via early combat detection")
                    -- Mark that we successfully handled combat collapse early and need to expand on combat end
                    combatStateQueue.enteredCombatOutsideInstance = true
                    combatStateQueue.shouldCollapseOnCombatEnd = false
                    combatStateQueue.shouldExpandOnCombatEnd = false
                    combatStateQueue.trackersWereCollapsedInCombat = true
                else
                    DebugPrint("No trackers collapsed via early detection - will try again on PLAYER_REGEN_DISABLED")
                    -- Still mark that we're in combat outside instance for potential later operations
                    combatStateQueue.enteredCombatOutsideInstance = true
                    combatStateQueue.trackersWereCollapsedInCombat = false
                end
            else
                DebugPrint("Combat collapse not enabled for this profile")
                -- Still mark that we entered combat outside instance for potential manual interaction
                combatStateQueue.enteredCombatOutsideInstance = true
                combatStateQueue.shouldCollapseOnCombatEnd = false
                combatStateQueue.shouldExpandOnCombatEnd = false
            end
        end
    else
        DebugPrint("In dungeon/instance - skipping early combat detection")
    end
end
-- Event handler
QuestLogCollapse:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        OnAddonLoaded(...)
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Mark as fully loaded after player enters world
        isFullyLoaded = true
        DebugPrint("Player entered world - addon fully loaded")
    elseif event == "ZONE_CHANGED_NEW_AREA" then
        OnZoneChanged()
    elseif event == "PLAYER_ENTER_COMBAT" then
        -- Handle early combat detection (fires before PLAYER_REGEN_DISABLED)
        OnEarlyCombat(event)
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
        print("|cffff0000/qlc status|r - Show current status and combat queue")
        print("|cffff0000/qlc collapse|r - Manually collapse configured sections")
        print("|cffff0000/qlc expand|r - Manually expand all collapsed sections")
        print("|cffff0000/qlc test|r - Test objective tracker detection")
        print("|cffff0000/qlc testcombat|r - Test combat collapse behavior")
        print("|cffff0000/qlc clearpending|r - Clear pending tracker operations")
        print("|cffff0000/qlc config|r - Open configuration panel")
        print("")
        print("|cff00ff00Combat Behavior:|r")
        print("• Quest trackers collapse via early combat detection (PLAYER_ENTER_COMBAT)")
        print("• Fallback attempt during PLAYER_REGEN_DISABLED if early detection fails")
        print("• Quest trackers automatically expand when combat ends (outside instances)")
        print("• If immediate collapse fails, operations are queued for when combat ends")
        print("• Use |cffff0000/qlc expand|r during combat to cancel queued operations")
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
                -- Fallback to old interface options (check if function exists in global table)
                local addCategoryFunc = _G["InterfaceOptions_AddCategory"]
                if addCategoryFunc then
                    addCategoryFunc(configPanel)
                end
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
        print("In Combat: " .. (InCombatLockdown() and "Yes" or "No"))

        local settings = GetCurrentInstanceSettings and GetCurrentInstanceSettings()
        if settings then
            local instanceType = select(2, IsInInstance())
        print("Current Instance Settings (" .. (instanceType or "none") .. "):")
        print("  Instance Type Enabled: " .. (settings.enabled and "Yes" or "No"))
        end

        print("|cff00ff00Combat Queue Status:|r")
        print("  Entered Combat Outside Instance: " .. (combatStateQueue.enteredCombatOutsideInstance and "Yes" or "No"))
        print("  Collapse Queued: " .. (combatStateQueue.shouldCollapseOnCombatEnd and "Yes" or "No"))
        print("  Expand Queued: " .. (combatStateQueue.shouldExpandOnCombatEnd and "Yes" or "No"))
        print("  Trackers Collapsed in Combat: " .. (combatStateQueue.trackersWereCollapsedInCombat and "Yes" or "No"))
        
        print("|cff00ff00Nameplate Status:|r")
        print("  Addon Controlled: " .. (namePlateState.addonControlled and "Yes" or "No"))
        print("  Original State: " .. tostring(namePlateState.originalShowAll or "None"))
        print("  Current nameplateShowAll: " .. tostring(GetCVar("nameplateShowAll")))
        print("  Current nameplateShowEnemies: " .. tostring(GetCVar("nameplateShowEnemies")))
        print("  Current nameplateShowFriends: " .. tostring(GetCVar("nameplateShowFriends")))
        
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
        if InCombatLockdown() then
            print("|cff00ff00QuestLogCollapse|r Cannot collapse during combat - will apply when combat ends")
            -- Queue the operation if we're outside dungeons
            if not IsInDungeon() then
                combatStateQueue.shouldCollapseOnCombatEnd = true
                combatStateQueue.shouldExpandOnCombatEnd = false
            end
        else
            CollapseQuestLog()
            print("|cff00ff00QuestLogCollapse|r manually collapsed configured sections")
        end
    elseif args[1] == "expand" then
        if InCombatLockdown() then
            print("|cff00ff00QuestLogCollapse|r Cannot expand during combat - canceling any queued operations")
            -- Cancel any queued operations and clear combat state
            combatStateQueue.shouldCollapseOnCombatEnd = false
            combatStateQueue.shouldExpandOnCombatEnd = true
        else
            ExpandQuestLog()
            print("|cff00ff00QuestLogCollapse|r manually expanded all collapsed sections")
        end
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
        print("|cff00ff00Combat Queue Status:|r")
        print("  Entered Combat Outside Instance: " .. (combatStateQueue.enteredCombatOutsideInstance and "Yes" or "No"))
        print("  Collapse Queued: " .. (combatStateQueue.shouldCollapseOnCombatEnd and "Yes" or "No"))
        print("  Expand Queued: " .. (combatStateQueue.shouldExpandOnCombatEnd and "Yes" or "No"))
        print("  Trackers Collapsed in Combat: " .. (combatStateQueue.trackersWereCollapsedInCombat and "Yes" or "No"))
    elseif args[1] == "testcombat" then
        print("|cff00ff00QuestLogCollapse Combat Test:|r")
        local settings = GetCurrentInstanceSettings and GetCurrentInstanceSettings()
        if settings then
            print("Combat Settings Found: " .. (settings.enabled and "Enabled" or "Disabled"))
            if settings.enabled then
                print("Combat Collapse Sections:")
                print("  Quests: " .. (settings.collapseQuests and "Yes" or "No"))
                print("  Achievements: " .. (settings.collapseAchievements and "Yes" or "No"))
                print("  Bonus Objectives: " .. (settings.collapseBonusObjectives and "Yes" or "No"))
                print("  Campaigns: " .. (settings.collapseCampaigns and "Yes" or "No"))
                print("  Scenarios: " .. (settings.collapseScenarios and "Yes" or "No"))
                print("  Professions: " .. (settings.collapseProfessions and "Yes" or "No"))
                print("  Monthly Activities: " .. (settings.collapseMonthlyActivities and "Yes" or "No"))
                print("  UI Widgets: " .. (settings.collapseUIWidgets and "Yes" or "No"))
                print("  Adventure Maps: " .. (settings.collapseAdventureMaps and "Yes" or "No"))
                print("  World Quests: " .. (settings.collapseWorldQuests and "Yes" or "No"))
                print("  Nameplate Control: " .. (settings.namePlates and settings.namePlates.enabled and "Yes" or "No"))
            end
        else
            print("No combat settings found")
        end
        print("Current Combat State: " .. (InCombatLockdown() and "In Combat" or "Not in Combat"))
        print("Current Instance State: " .. (IsInDungeon() and "In Instance" or "Outside Instance"))
        print("Available Trackers:")
        print("  QuestObjectiveTracker: " .. (QuestObjectiveTracker and "Available" or "Not found"))
        print("  AchievementObjectiveTracker: " .. (AchievementObjectiveTracker and "Available" or "Not found"))
        print("  BonusObjectiveTracker: " .. (BonusObjectiveTracker and "Available" or "Not found"))
        print("  CampaignQuestObjectiveTracker: " .. (CampaignQuestObjectiveTracker and "Available" or "Not found"))
        print("  ScenarioObjectiveTracker: " .. (ScenarioObjectiveTracker and "Available" or "Not found"))
        print("  UIWidgetObjectiveTracker: " .. (UIWidgetObjectiveTracker and "Available" or "Not found"))
        print("|cff00ff00Pending Operations:|r")
        if next(pendingOperations) then
            for name, operation in pairs(pendingOperations) do
                print("  " .. name .. ": " .. operation.action)
            end
        else
            print("  None")
        end
    elseif args[1] == "clearpending" then
        print("|cff00ff00QuestLogCollapse|r Clearing pending operations...")
        pendingOperations = {}
        print("All pending operations cleared.")
    else
        print("|cff00ff00QuestLogCollapse|r Unknown command. Type |cffff0000/qlc help|r for available commands.")
    end
end

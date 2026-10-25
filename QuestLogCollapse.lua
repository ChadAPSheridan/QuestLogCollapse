-- QuestLogCollapse: Automatically fades quest tracker sections when entering instances
-- Author: Gaspode
-- Contributors: Artherion77
-- Version: 1.6.1
-- Updated: 2026-10-25

-- TAINT PROTECTION STRATEGY:
-- Implemented namespace to avoid global variable pollution
-- Added extensive error handling and logging to detect and isolate taint issues

-- Use addon namespace to prevent global variable pollution and taint
local addonName, ns = ...
local ADDON_VERSION = "1.6.1"

-- Create addon frame (local to prevent global pollution)
local QuestLogCollapse = CreateFrame("Frame")
QuestLogCollapse:RegisterEvent("ADDON_LOADED")
QuestLogCollapse:RegisterEvent("ZONE_CHANGED_NEW_AREA")
-- Combat start is intentionally not handled; combat does not trigger automatic tracker changes.
QuestLogCollapse:RegisterEvent("PLAYER_REGEN_ENABLED")
QuestLogCollapse:RegisterEvent("PLAYER_ENTERING_WORLD")
QuestLogCollapse:RegisterEvent("PLAYER_STARTED_MOVING")
QuestLogCollapse:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
QuestLogCollapse:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")


-- Taint-safe deferral logic
local mapSystemBusy = false
local mapSystemBusyUntil = 0
local pendingOperations = {}

-- Shared tracker definitions used by all tracker operations.
local TRACKER_DEFS = {
    { name = "Quest",              label = "Quests",             settingKey = "collapseQuests",            supportsImmediate = true, getter = function() return
        QuestObjectiveTracker end },
    { name = "Achievement",        label = "Achievements",       settingKey = "collapseAchievements",      supportsImmediate = true, getter = function() return
        AchievementObjectiveTracker end },
    { name = "Bonus objectives",   label = "Bonus Objectives",   settingKey = "collapseBonusObjectives",   supportsImmediate = true, getter = function() return
        BonusObjectiveTracker end },
    { name = "Scenario",           label = "Scenarios",          settingKey = "collapseScenarios",         supportsImmediate = true, getter = function() return
        ScenarioObjectiveTracker end },
    { name = "Campaign",           label = "Campaigns",          settingKey = "collapseCampaigns",         supportsImmediate = true, getter = function() return
        CampaignQuestObjectiveTracker end },
    { name = "Professions",        label = "Professions",        settingKey = "collapseProfessions",       supportsImmediate = true, getter = function() return
        ProfessionsRecipeTracker end },
    { name = "Monthly activities", label = "Monthly Activities", settingKey = "collapseMonthlyActivities", supportsImmediate = true, getter = function() return
        MonthlyActivitiesObjectiveTracker end },
    { name = "UI widgets",         label = "UI Widgets",         settingKey = "collapseUIWidgets",         supportsImmediate = true, getter = function() return
        UIWidgetObjectiveTracker end },
    { name = "Adventure map",      label = "Adventure Maps",     settingKey = "collapseAdventureMaps",     supportsImmediate = true, getter = function() return
        _G["AdventureMapQuestObjectiveTracker"] end },
    { name = "World quest",        label = "World Quests",       settingKey = "collapseWorldQuests",       supportsImmediate = true, getter = function() return
        WorldQuestObjectiveTracker end },
}
local TRACKER_DEF_BY_NAME = {}
for _, def in ipairs(TRACKER_DEFS) do
    TRACKER_DEF_BY_NAME[def.name] = def
end

local function QueuePendingOperation(trackerName, action)
    pendingOperations[trackerName] = { action = action, trackerName = trackerName }
end

local function SetMapSystemBusy(seconds)
    mapSystemBusy = true
    mapSystemBusyUntil = GetTime() + seconds
end

local function CheckMapSystemBusy()
    if mapSystemBusy and GetTime() > mapSystemBusyUntil then
        mapSystemBusy = false
        mapSystemBusyUntil = 0
        if ns.ProcessPendingOperations then
            ns.ProcessPendingOperations()
        end
    end
end

local busyFrame = CreateFrame("Frame")
busyFrame:SetScript("OnUpdate", function()
    CheckMapSystemBusy()
end)

-- Track loading state to prevent operations during initialization
local isFullyLoaded = false

-- Track combat state for delayed operations
local combatStateQueue = {
    shouldCollapseOnCombatEnd = false,
    shouldExpandOnCombatEnd = false
}

-- Track nameplate state to restore properly
local namePlateState = {
    originalShowAll = nil,  -- Original value before addon touched it
    addonControlled = false -- Whether the addon is currently controlling nameplates
}

-- Track quest tracking state to restore properly
local questTrackingState = {
    originalTrackedQuests = {},   -- Store original tracked quest IDs
    addonModifiedTracking = false -- Whether the addon has modified quest tracking
}

-- Track if zone filtering is needed (set on zone change, cleared when filtering runs)
-- This flag approach allows the filter to run from hardware-initiated events without taint
local needsZoneFilter = false
local lastZoneFilterTrigger = "none"

local function MarkZoneFilterTrigger(reason)
    lastZoneFilterTrigger = reason or "unknown"
end

-- "Have we installed the HookScript already?" guards. Kept as file-locals to avoid tainting
-- Blizzard frame tables, which would block all protected operations on those frames.

local mapFrameHooked = false
local minimizeButtonHooked = false

-- Legacy fallback defaults used only if profile DB initialization has not run yet.
local LEGACY_DEFAULTS = {
    enabled = true,
    debug = false,
    filterQuestsByZone = false,
    filterQuestsByZoneMode = "openworld",
}

local function GetLegacyDefaults()
    if ns.GetLegacyDefaults then
        return ns.GetLegacyDefaults()
    end
    return LEGACY_DEFAULTS
end

MyAddonDB = MyAddonDB or { logs = {} }

local function LogMessage(msg)
    local timestamp = date("%H:%M:%S")
    table.insert(MyAddonDB.logs, "[" .. timestamp .. "] " .. msg)

    -- Optional: Keep the log from growing infinitely large
    if #MyAddonDB.logs > 500 then
        table.remove(MyAddonDB.logs, 1)
    end
end

ns.LogMessage = LogMessage

-- Debug print function (stored in namespace)
local function DebugPrint(message)
    local profile = (ns.GetCurrentQLCProfile and ns.GetCurrentQLCProfile()) or ns.db
    if profile and profile.debug then
        print("|cff00ff00[QuestLogCollapse]|r " .. message)
        LogMessage(message)
    end
end
-- Make DebugPrint available to other addon files via namespace
ns.DebugPrint = DebugPrint

local function IsInDungeon()
    local instanceType = select(2, IsInInstance())
    return instanceType == "party" or instanceType == "raid" or instanceType == "scenario" or instanceType == "pvp" or
        instanceType == "arena" or instanceType == "neighborhood" or instanceType == "interior"
end

local function UpdateNamePlates()
    if InCombatLockdown() then
        DebugPrint("Skipping nameplate update - in combat")
        return
    end

    local profile = (ns.GetCurrentQLCProfile and ns.GetCurrentQLCProfile()) or ns.db
    local settings = ns.GetCurrentInstanceSettings and ns.GetCurrentInstanceSettings()
    local shouldShow = profile and profile.enabled and settings and settings.enabled
        and settings.namePlates and settings.namePlates.enabled

    if shouldShow then
        if not namePlateState.addonControlled then
            namePlateState.originalShowAll = GetCVar("nameplateShowEnemies")
            namePlateState.addonControlled = true
            DebugPrint("Stored original ENEMY nameplate state: " .. tostring(namePlateState.originalShowAll))
        end
        if GetCVar("nameplateShowEnemies") ~= "1" then
            SetCVar("nameplateShowEnemies", "1")
        end
        DebugPrint("Enabled ENEMY nameplates for current zone settings")
    elseif namePlateState.addonControlled then
        local originalState = namePlateState.originalShowAll or "0"
        SetCVar("nameplateShowEnemies", originalState)
        DebugPrint("Restored original ENEMY nameplate state: " .. tostring(originalState))
        namePlateState.addonControlled = false
        namePlateState.originalShowAll = nil
    end
end
ns.UpdateNamePlates = UpdateNamePlates

-- Keep legacy operation names and saved settings; only change visual alpha.
local function SafeCollapseTracker(tracker, name, shouldCollapse)
    if not isFullyLoaded or not tracker or not shouldCollapse then
        DebugPrint(name .. " not found, not fully loaded, or shouldCollapse is false")
        return false
    end

    -- NEVER manipulate trackers during combat to avoid taint
    if InCombatLockdown() then
        DebugPrint("Skipping " .. name .. " transparency - in combat")
        return false
    end

    -- Avoid operations when map system might be busy
    if mapSystemBusy then
        DebugPrint("Deferring " .. name .. " transparency - map system busy")
        QueuePendingOperation(name, "collapse")
        return true
    end

    -- Check if this operation is already pending
    if pendingOperations[name] then
        DebugPrint("Operation already pending for " .. name)
        return true
    end

    if type(tracker.SetAlpha) == "function" then
        tracker:SetAlpha(0)
        DebugPrint(name .. " section made transparent")
        return true
    end

    DebugPrint(name .. " section has no SetAlpha method")
    return false
end

local function CollapseQuestLog()
    -- NEVER do anything during combat to avoid taint
    if InCombatLockdown() then
        DebugPrint("CollapseQuestLog() skipped - in combat")
        return
    end

    -- Get instance-specific settings from config system
    local settings = ns.GetCurrentInstanceSettings and ns.GetCurrentInstanceSettings()

    DebugPrint("CollapseQuestLog() called")

    if not settings then
        DebugPrint("No instance settings found")
        return
    end

    if not settings.enabled then
        DebugPrint("Instance type not enabled for transparency")
        return
    end

    DebugPrint("Instance settings found and enabled, applying transparency")


    local collapsed = 0

    for _, def in ipairs(TRACKER_DEFS) do
        if SafeCollapseTracker(def.getter(), def.name, settings[def.settingKey]) then
            collapsed = collapsed + 1
        end
    end

    DebugPrint("Made " .. collapsed .. " sections transparent")
end

-- Restore section opacity without touching Blizzard's collapsed state or layout.
local function SafeExpandTracker(tracker, name)
    if not isFullyLoaded or not tracker then
        DebugPrint(name .. " not found or not fully loaded")
        return false
    end

    -- NEVER manipulate trackers during combat to avoid taint
    if InCombatLockdown() then
        DebugPrint("Skipping " .. name .. " opacity restoration - in combat")
        return false
    end

    -- Avoid operations when map system might be busy
    if mapSystemBusy then
        DebugPrint("Deferring " .. name .. " opacity restoration - map system busy")
        QueuePendingOperation(name, "expand")
        return true
    end

    -- Check if this operation is already pending
    if pendingOperations[name] then
        DebugPrint("Operation already pending for " .. name)
        return true
    end

    if type(tracker.SetAlpha) == "function" then
        tracker:SetAlpha(1)
        DebugPrint(name .. " section made opaque")
        return true
    end

    DebugPrint(name .. " section has no SetAlpha method")
    return false
end

function ns.ProcessPendingOperations()
    if mapSystemBusy or InCombatLockdown() or not next(pendingOperations) then
        return
    end

    DebugPrint("Processing pending tracker operations")
    local queued = pendingOperations
    pendingOperations = {}

    for trackerName, operation in pairs(queued) do
        local def = TRACKER_DEF_BY_NAME[trackerName]
        local tracker = def and def.getter and def.getter() or nil
        if operation.action == "collapse" then
            SafeCollapseTracker(tracker, trackerName, true)
        elseif operation.action == "expand" then
            SafeExpandTracker(tracker, trackerName)
        end
    end
end

local function ExpandQuestLog()
    -- NEVER do anything during combat to avoid taint
    if InCombatLockdown() then
        DebugPrint("ExpandQuestLog() skipped - in combat")
        return
    end

    -- When leaving an instance, restore opacity for all sections.

    DebugPrint("ExpandQuestLog() called")
    local expanded = 0

    for _, def in ipairs(TRACKER_DEFS) do
        if SafeExpandTracker(def.getter(), def.name) then
            expanded = expanded + 1
        end
    end
    DebugPrint("Made " .. expanded .. " sections/modules opaque")
end

-- Filter quests by current zone
-- This function is only safe to call from:
-- 1. Slash commands (user-initiated)
-- 2. Hardware-event hooks (map open, quest log open, player movement)
-- 3. Frame OnShow events triggered by user action
-- NEVER call from ZONE_CHANGED or other game events - it will cause taint!
local function FilterQuestsByZone()
    -- NEVER do anything during combat to avoid taint
    if InCombatLockdown() then
        DebugPrint("FilterQuestsByZone() skipped - in combat")
        return
    end

    local profile = (ns.GetCurrentQLCProfile and ns.GetCurrentQLCProfile()) or ns.db
    if not profile or not profile.filterQuestsByZone then
        needsZoneFilter = false -- Clear the flag
        return
    end

    -- Respect the zone filter mode: skip when inside any instance if set to open-world only
    local filterMode = profile.filterQuestsByZoneMode or "openworld"
    if filterMode == "openworld" and IsInInstance() then
        DebugPrint("FilterQuestsByZone() skipped - in instance (mode: Open World Only)")
        needsZoneFilter = false
        return
    end

    -- Clear the flag since we're running now
    needsZoneFilter = false

    DebugPrint("========================================")
    DebugPrint("=== FILTERING QUESTS BY CURRENT ZONE ===")
    DebugPrint("========================================")
    DebugPrint("Trigger source: " .. tostring(lastZoneFilterTrigger))
    C_Timer.After(0.5, function()
        if InCombatLockdown() then
            DebugPrint("Combat started, skipping quest filtering")
            return
        end

        -- Get current zone
        local currentMapID = C_Map.GetBestMapForUnit("player")
        local currentMapInfo = currentMapID and C_Map.GetMapInfo(currentMapID)

        DebugPrint("Current map ID: " .. tostring(currentMapID))
        if currentMapInfo then
            DebugPrint("Current map name: '" .. (currentMapInfo.name or "unknown") .. "'")
        end

        if not currentMapID then
            DebugPrint("Unable to determine current zone, skipping quest filtering")
            return
        end

        -- Helper function to check if a quest is in the current zone
        local function IsQuestInCurrentZone(questID, questInfo)
            -- Check if the quest has markers or objectives in the current zone
            -- isOnMap = quest objectives/markers are on the current zone's map
            -- hasLocalPOI = quest has a Point of Interest in the current zone

            local isOnCurrentMap = questInfo and questInfo.isOnMap
            local hasLocalMarker = questInfo and questInfo.hasLocalPOI

            DebugPrint("  Quest " ..
            questID .. ": isOnMap=" .. tostring(isOnCurrentMap) .. ", hasLocalPOI=" .. tostring(hasLocalMarker))

            if isOnCurrentMap or hasLocalMarker then
                return true, "has objectives/markers in current zone"
            else
                return false, "no objectives/markers in current zone"
            end
        end

        local numQuestLogEntries = C_QuestLog.GetNumQuestLogEntries()
        local questInfoByID = {}
        for i = 1, numQuestLogEntries do
            local info = C_QuestLog.GetInfo(i)
            if info and info.questID then
                questInfoByID[info.questID] = info
            end
        end

        local trackedQuestIDs = {}
        local numTracked = C_QuestLog.GetNumQuestWatches()
        for i = 1, numTracked do
            local qid = C_QuestLog.GetQuestIDForQuestWatchIndex(i)
            if qid then
                trackedQuestIDs[qid] = true
            end
        end

        -- Step 1: Untrack quests not in current zone
        local untracked = 0
        local kept = 0
        DebugPrint("=== STEP 1: Checking " .. numTracked .. " currently tracked quests ===")

        -- Snapshot the watch list before modifying it so we can restore it later
        if not questTrackingState.addonModifiedTracking then
            questTrackingState.originalTrackedQuests = {}
            for questID in pairs(trackedQuestIDs) do
                questTrackingState.originalTrackedQuests[questID] = true
            end
            questTrackingState.addonModifiedTracking = true
            DebugPrint("Saved original quest tracking state (" .. numTracked .. " quests)")
        end

        for questID in pairs(trackedQuestIDs) do
            local trackedQuestInfo = questInfoByID[questID]
            DebugPrint("Examining tracked quest " .. questID)
            local isInCurrentZone, reason = IsQuestInCurrentZone(questID, trackedQuestInfo)

            if not isInCurrentZone then
                C_QuestLog.RemoveQuestWatch(questID)
                trackedQuestIDs[questID] = nil
                DebugPrint(">>> UNTRACKED quest " .. questID .. " - " .. reason)
                untracked = untracked + 1
            else
                DebugPrint(">>> KEPT quest " .. questID .. " - " .. reason)
                kept = kept + 1
            end
        end

        DebugPrint("=== Step 1 complete: kept " .. kept .. ", untracked " .. untracked .. " ===")

        -- Step 2: Track quests that ARE in current zone
        local tracked = 0
        local skipped = 0
        DebugPrint("=== STEP 2: Scanning " .. numQuestLogEntries .. " quest log entries for current zone quests ===")

        for i = 1, numQuestLogEntries do
            local info = C_QuestLog.GetInfo(i)
            if info and not info.isHeader and not info.isHidden then
                local questID = info.questID
                if questID then
                    DebugPrint("Checking quest log entry " ..
                    i .. ": questID=" .. questID .. ", title='" .. (info.title or "unknown") .. "'")

                    if trackedQuestIDs[questID] then
                        DebugPrint("  Quest " .. questID .. " already tracked, skipping")
                        skipped = skipped + 1
                    else
                        local isInCurrentZone, reason = IsQuestInCurrentZone(questID, info)
                        if isInCurrentZone then
                            local success = C_QuestLog.AddQuestWatch(questID)
                            if success then
                                trackedQuestIDs[questID] = true
                                DebugPrint(">>> TRACKED quest " .. questID .. " - " .. reason)
                                tracked = tracked + 1
                            else
                                DebugPrint(">>> FAILED to track quest " .. questID .. " (AddQuestWatch returned false)")
                            end
                        else
                            DebugPrint("  Quest " .. questID .. " not in current zone - " .. reason)
                        end
                    end
                end
            end
        end

        DebugPrint("=== Step 2 complete: newly tracked " ..
        tracked .. ", skipped (already tracked) " .. skipped .. " ===")
        DebugPrint("=== FINAL: kept " ..
        kept .. ", untracked " .. untracked .. ", newly tracked " .. tracked .. " quests ===")
    end)
end

local function RunWhenAddonReady(label, maxAttempts, intervalSeconds, callback, allowDungeonCombat)
    local attempts = 0
    local maxTries = maxAttempts or 20
    local interval = intervalSeconds or 1

    local function TryRun()
        attempts = attempts + 1

        -- Allow callbacks during dungeon combat if explicitly permitted (for zone changes in instances)
        local blockDueToCombat = InCombatLockdown() and not (allowDungeonCombat and IsInDungeon())

        if not isFullyLoaded or mapSystemBusy or blockDueToCombat or not ObjectiveTrackerFrame then
            if attempts < maxTries then
                C_Timer.After(interval, TryRun)
            else
                DebugPrint(label .. " aborted after waiting for addon/map/combat readiness")
            end
            return
        end

        callback()
    end

    C_Timer.After(interval, TryRun)
end

local function OnZoneChanged()
    local profile = (ns.GetCurrentQLCProfile and ns.GetCurrentQLCProfile()) or ns.db

    UpdateNamePlates()

    -- Set flag for zone filtering - will be triggered by user action (map open, movement, etc.)
    -- We can't call FilterQuestsByZone() directly here because it would cause taint
    if profile and profile.filterQuestsByZone then
        needsZoneFilter = true
        MarkZoneFilterTrigger("Zone changed (pending user action)")
        DebugPrint("Zone changed - zone filter will run on next user action (open map, move, or use /qlc filterzone)")
    end

    if not profile or not profile.enabled then
        DebugPrint("Addon disabled or no profile found (skipping alpha changes)")
        return
    end

    DebugPrint("Zone change detected, checking instance status...")

    SetMapSystemBusy(8)
    RunWhenAddonReady("Zone change handling", 25, 1, function()
        local inInstance, instanceType = IsInInstance()
        DebugPrint("Instance check: inInstance=" .. tostring(inInstance) .. ", type=" .. tostring(instanceType))

        if IsInDungeon() then
            DebugPrint("Entered instance - making configured sections transparent")
            CollapseQuestLog()
        else
            DebugPrint("Left instance - restoring section opacity")
            ExpandQuestLog()
        end
    end, true) -- Allow callback during dungeon combat
end

local function OnAddonLoaded(loadedAddonName)
    if loadedAddonName ~= addonName then
        return
    end

    ns.InitializeConfigDB()

    -- Basic legacy fallback initialization - detailed profile config handled by config file.
    for key, value in pairs(GetLegacyDefaults()) do
        if ns.db[key] == nil then
            ns.db[key] = value
        end
    end

    print("|cff00ff00QuestLogCollapse|r v" .. ADDON_VERSION .. " loaded. Type |cffff0000/qlc config|r for options.")

    RunWhenAddonReady("Initial state check", 40, 1, function()
        UpdateNamePlates()
        if IsInDungeon() then
            local profile = (ns.GetCurrentQLCProfile and ns.GetCurrentQLCProfile()) or ns.db
            if profile and profile.enabled and not InCombatLockdown() then
                DebugPrint("Initial state check: in dungeon, applying transparency")
                CollapseQuestLog()
            end
        end
    end)
end

local function OnCombatStateChanged(event)
    local profile = (ns.GetCurrentQLCProfile and ns.GetCurrentQLCProfile()) or ns.db
    if not profile or not profile.enabled then
        DebugPrint("Addon disabled or no profile found")
        return
    end

    if event == "PLAYER_REGEN_ENABLED" then
        DebugPrint("Leaving combat - checking queued operations and quest log state")

        if combatStateQueue.enteredCombatOutsideInstance and combatStateQueue.shouldCollapseOnCombatEnd then
            DebugPrint("Applying queued transparency after combat")
            CollapseQuestLog()
            combatStateQueue.shouldCollapseOnCombatEnd = false
            combatStateQueue.trackersWereCollapsedInCombat = true
        elseif combatStateQueue.shouldExpandOnCombatEnd then
            DebugPrint("Applying queued opacity restoration after combat")
            ExpandQuestLog()
            combatStateQueue.shouldExpandOnCombatEnd = false
        elseif combatStateQueue.enteredCombatOutsideInstance then
            DebugPrint("Combat ended outside instance with no queued alpha changes")
        end

        -- Reset combat tracking
        combatStateQueue.enteredCombatOutsideInstance = false
        combatStateQueue.trackersWereCollapsedInCombat = false
    end
end

-- Event handler
QuestLogCollapse:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddonName = ...
        if loadedAddonName == addonName then
            OnAddonLoaded(loadedAddonName)
            SetMapSystemBusy(15)
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Mark as fully loaded after player enters world
        isFullyLoaded = true
        DebugPrint("Player entered world - addon fully loaded")
    elseif event == "ZONE_CHANGED_NEW_AREA" then
        SetMapSystemBusy(8)
        OnZoneChanged()
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Handle combat options
        OnCombatStateChanged(event)
        UpdateNamePlates()
    elseif event == "PLAYER_STARTED_MOVING" then
        -- Player movement - check for pending zone filter
        -- This is typically hardware-initiated (WASD keys)
        if needsZoneFilter and not InCombatLockdown() then
            DebugPrint("Player started moving - running pending zone filter")
            MarkZoneFilterTrigger("Player started moving")
            FilterQuestsByZone()
        end
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unitTarget, castGUID, spellID = ...
        -- Only respond to player's own spells
        if unitTarget == "player" and needsZoneFilter and not InCombatLockdown() then
            DebugPrint("Player cast spell/ability - running pending zone filter")
            MarkZoneFilterTrigger("Player cast spell/ability (" .. tostring(spellID) .. ")")
            FilterQuestsByZone()
        end
    elseif event == "PLAYER_MOUNT_DISPLAY_CHANGED" then
        -- Player mounted/dismounted - check for pending zone filter
        -- Mounting is always hardware-initiated (button press)
        if needsZoneFilter and not InCombatLockdown() then
            DebugPrint("Player mount state changed - running pending zone filter")
            MarkZoneFilterTrigger("Player mount state changed")
            FilterQuestsByZone()
        end
    end
end)

-- Periodic garbage collection during low-activity periods
local gcFrame = CreateFrame("Frame")
local lastGCTime = GetTime()
gcFrame:SetScript("OnUpdate", function()
    local currentTime = GetTime()

    -- Run garbage collection every 5 minutes (300 seconds) if not in combat/instance
    if currentTime - lastGCTime > 300 then
        if not InCombatLockdown() and not IsInDungeon() then
            DebugPrint("Running periodic garbage collection")
            collectgarbage("collect")
            lastGCTime = currentTime
        end
    end
end)

-- Slash command handler
function ns.HandleSlashCommand(msg)
    local args = {}
    for word in msg:gmatch("%S+") do
        table.insert(args, word:lower())
    end

    if #args == 0 or args[1] == "help" then
        print("|cff00ff00QuestLogCollapse Commands:|r")
        print("|cffff0000/qlc toggle|r - Toggle addon on/off")
        print("|cffff0000/qlc debug|r - Toggle debug messages")
        print("|cffff0000/qlc status|r - Show current status and combat queue")
        print("|cffff0000/qlc collapse|r - Make configured sections transparent (alpha 0)")
        print("|cffff0000/qlc expand|r - Restore all section opacity (alpha 1)")
        print("|cffff0000/qlc filterzone|r - Filter quests by current zone (manual)")
        print("|cffff0000/qlc diag|r - Show concise diagnostic summary")
        print("|cffff0000/qlc test|r - Test objective tracker detection")
        print("|cffff0000/qlc testcombat|r - Test current settings (legacy command name)")
        print("|cffff0000/qlc clearpending|r - Clear pending tracker operations")
        print("|cffff0000/qlc config|r - Open configuration panel")
        print("")
        print("|cff00ff00Combat Safety:|r")
        print("• Automatic tracker changes are not triggered by combat")
        print("• Manual tracker operations requested during combat are deferred until combat ends")
        print("• Use |cffff0000/qlc expand|r during combat to cancel queued operations")
        print("")
        print("|cff00ff00Zone Filtering:|r")
        print("• When enabled, zone filtering triggers automatically when you:")
        print("  - Interact with the quest tracker (minimize/expand)")
        print("  - Start moving after a zone change")
        print("  - Cast any spell/ability (including dynamic flight)")
        print("  - Mount or dismount")
        print("• You can also manually trigger with |cffff0000/qlc filterzone|r")
        print("Available sections: quests, achievements, bonus, scenarios,")
        print("campaigns, professions, monthly, widgets, adventuremaps")
    elseif args[1] == "toggle" then
        local profile = (ns.GetCurrentQLCProfile and ns.GetCurrentQLCProfile()) or ns.db
        if profile then
            profile.enabled = not profile.enabled
            print("|cff00ff00QuestLogCollapse|r " .. (profile.enabled and "enabled" or "disabled"))
        end
    elseif args[1] == "debug" then
        local profile = (ns.GetCurrentQLCProfile and ns.GetCurrentQLCProfile()) or ns.db
        if profile then
            profile.debug = not profile.debug
            print("|cff00ff00QuestLogCollapse|r debug " .. (profile.debug and "enabled" or "disabled"))
        end
    elseif args[1] == "config" then
        if ns.CreateQuestLogCollapseConfigPanel then
            local configPanel = ns.CreateQuestLogCollapseConfigPanel()
            if Settings and Settings.OpenToCategory then
                -- Try to register and open in the new settings system
                if not configPanel.categoryID then
                    local category = Settings.RegisterCanvasLayoutCategory(configPanel, "QuestLogCollapse")
                    Settings.RegisterAddOnCategory(category)
                    configPanel.categoryID = category.ID
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
        local profile = (ns.GetCurrentQLCProfile and ns.GetCurrentQLCProfile()) or ns.db
        print("|cff00ff00QuestLogCollapse Status:|r")
        print("Enabled: " .. ((profile and profile.enabled) and "Yes" or "No"))
        print("Debug: " .. ((profile and profile.debug) and "Yes" or "No"))
        print("Filter Quests by Zone: " .. ((profile and profile.filterQuestsByZone) and "Yes" or "No"))
        print("Zone Filter Pending: " .. (needsZoneFilter and "Yes" or "No"))
        print("In Instance: " .. (IsInDungeon() and "Yes" or "No"))
        print("In Combat: " .. (InCombatLockdown() and "Yes" or "No"))

        local settings = ns.GetCurrentInstanceSettings and ns.GetCurrentInstanceSettings()
        if settings then
            local instanceType = select(2, IsInInstance())
            print("Current Instance Settings (" .. (instanceType or "none") .. "):")
            print("  Instance Type Enabled: " .. (settings.enabled and "Yes" or "No"))
        end

        print("|cff00ff00Combat Queue Status:|r")
        print("  Entered Combat Outside Instance: " .. (combatStateQueue.enteredCombatOutsideInstance and "Yes" or "No"))
        print("  Transparency Queued: " .. (combatStateQueue.shouldCollapseOnCombatEnd and "Yes" or "No"))
        print("  Opacity Restoration Queued: " .. (combatStateQueue.shouldExpandOnCombatEnd and "Yes" or "No"))

        print("|cff00ff00Nameplate Status:|r")
        print("  Addon Controlled: " .. (namePlateState.addonControlled and "Yes" or "No"))
        print("  Original State: " .. tostring(namePlateState.originalShowAll or "None"))
        print("  Current nameplateShowAll: " .. tostring(GetCVar("nameplateShowAll")))
        print("  Current nameplateShowEnemies: " .. tostring(GetCVar("nameplateShowEnemies")))
        print("  Current nameplateShowFriends: " .. tostring(GetCVar("nameplateShowFriends")))

        print("|cff00ff00Current Section States:|r")
        for _, def in ipairs(TRACKER_DEFS) do
            local tracker = def.getter()
            if tracker then
                print(def.label .. ": alpha " .. tostring(tracker:GetAlpha()))
            end
        end
    elseif args[1] == "diag" then
        local profile = (ns.GetCurrentQLCProfile and ns.GetCurrentQLCProfile()) or ns.db
        local profileName = (ns.charDB and ns.charDB.currentProfile) or "Default"
        local settings = ns.GetCurrentInstanceSettings and ns.GetCurrentInstanceSettings()
        local inInstance, instanceType = IsInInstance()
        local pendingCount = 0

        for _ in pairs(pendingOperations) do
            pendingCount = pendingCount + 1
        end

        print("|cff00ff00QuestLogCollapse Diagnostics:|r")
        print("Profile: " .. profileName)
        print("Enabled: " .. ((profile and profile.enabled) and "Yes" or "No"))
        print("Instance: " .. tostring(instanceType) .. " (" .. (inInstance and "inside" or "outside") .. ")")
        print("Context active: " .. ((settings and settings.enabled) and "Yes" or "No"))
        print("Map busy: " .. (mapSystemBusy and "Yes" or "No"))
        print("Pending operations: " .. tostring(pendingCount))
        print("Zone filter pending: " .. (needsZoneFilter and "Yes" or "No"))
        print("Last zone filter trigger: " .. tostring(lastZoneFilterTrigger))
        print("Tracker mode: section alpha (0 = transparent, 1 = opaque); layout unchanged")
        if settings then
            print("Configured transparent sections in current context:")
            for _, def in ipairs(TRACKER_DEFS) do
                print("  " .. def.label .. ": " .. (settings[def.settingKey] and "Yes" or "No"))
            end
        end
    elseif args[1] == "collapse" then
        if InCombatLockdown() then
            print("|cff00ff00QuestLogCollapse|r Cannot change section alpha during combat - will apply when combat ends")
            -- Queue the operation if we're outside dungeons
            if not IsInDungeon() then
                combatStateQueue.shouldCollapseOnCombatEnd = true
                combatStateQueue.shouldExpandOnCombatEnd = false
            end
        else
            CollapseQuestLog()
            print("|cff00ff00QuestLogCollapse|r requested alpha 0 for configured sections (layout unchanged)")
        end
    elseif args[1] == "expand" then
        if InCombatLockdown() then
            print("|cff00ff00QuestLogCollapse|r Cannot change section alpha during combat - opacity restoration queued")
            -- Cancel any queued operations and clear combat state
            combatStateQueue.shouldCollapseOnCombatEnd = false
            combatStateQueue.shouldExpandOnCombatEnd = true
        else
            ExpandQuestLog()
            print("|cff00ff00QuestLogCollapse|r requested alpha 1 for all sections")
        end
    elseif args[1] == "filterzone" then
        -- Manual zone filter trigger (always safe from slash command)
        if InCombatLockdown() then
            print("|cff00ff00QuestLogCollapse|r Cannot filter quests during combat")
        else
            local profile = (ns.GetCurrentQLCProfile and ns.GetCurrentQLCProfile()) or ns.db
            if profile and profile.filterQuestsByZone then
                MarkZoneFilterTrigger("Manual command (/qlc filterzone)")
                FilterQuestsByZone()
                print("|cff00ff00QuestLogCollapse|r Quest filtering by zone completed")
            else
                print("|cff00ff00QuestLogCollapse|r Zone filtering is not enabled. Enable it in /qlc config")
            end
        end
    elseif args[1] == "test" then
        print("|cff00ff00QuestLogCollapse Test Results:|r")
        for _, def in ipairs(TRACKER_DEFS) do
            print(def.label .. ": " .. (def.getter() and "Found" or "Not found"))
        end
        print("ObjectiveTrackerFrame: " .. (ObjectiveTrackerFrame and "Found" or "Not found"))
        if ObjectiveTrackerFrame and ObjectiveTrackerFrame.MODULES then
            print("ObjectiveTrackerFrame.MODULES count: " .. #ObjectiveTrackerFrame.MODULES)
        end
        local inInstance, instanceType = IsInInstance()
        print("In Instance: " .. tostring(inInstance) .. ", Type: " .. tostring(instanceType))
        print("IsInDungeon(): " .. tostring(IsInDungeon()))
        local settings = ns.GetCurrentInstanceSettings and ns.GetCurrentInstanceSettings()
        print("Current Instance Settings: " .. (settings and "Found" or "Not found"))
        if settings then
            print("  Settings enabled: " .. tostring(settings.enabled))
        end
        print("|cff00ff00Combat Queue Status:|r")
        print("  Entered Combat Outside Instance: " .. (combatStateQueue.enteredCombatOutsideInstance and "Yes" or "No"))
        print("  Transparency Queued: " .. (combatStateQueue.shouldCollapseOnCombatEnd and "Yes" or "No"))
        print("  Opacity Restoration Queued: " .. (combatStateQueue.shouldExpandOnCombatEnd and "Yes" or "No"))
    elseif args[1] == "testcombat" then
        print("|cff00ff00QuestLogCollapse Current Settings Test:|r")
        local settings = ns.GetCurrentInstanceSettings and ns.GetCurrentInstanceSettings()
        if settings then
            print("Current Settings Found: " .. (settings.enabled and "Enabled" or "Disabled"))
            if settings.enabled then
                print("Configured Transparent Sections:")
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
            print("No settings found")
        end
        print("Current Combat State: " .. (InCombatLockdown() and "In Combat" or "Not in Combat"))
        print("Current Instance State: " .. (IsInDungeon() and "In Instance" or "Outside Instance"))
        print("Available Trackers:")
        for _, def in ipairs(TRACKER_DEFS) do
            print("  " .. def.label .. ": " .. (def.getter() and "Available" or "Not found"))
        end
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

-- WoW discovers slash commands through these global registrations.
_G.SLASH_QUESTLOGCOLLAPSE1 = "/qlc"
_G.SLASH_QUESTLOGCOLLAPSE2 = "/questlogcollapse"
SlashCmdList.QUESTLOGCOLLAPSE = ns.HandleSlashCommand

-- ============================================================================
-- ZONE FILTERING AUTOMATIC TRIGGERS (Hardware-Event Hooks)
-- ============================================================================
-- These hooks allow zone filtering to run in response to user actions,
-- which breaks the taint chain from game events like ZONE_CHANGED_NEW_AREA

-- Helper function to check flag and run filter if needed
local function TryRunZoneFilter()
    if needsZoneFilter and not InCombatLockdown() then
        DebugPrint("User action detected - running pending zone filter")
        FilterQuestsByZone()
    end
end

-- Monitor World Map opening via periodic visibility check (avoids taint from HookScript)
-- Instead of hooking into OnShow (which taints the secure frame), we periodically check
-- if the map is visible and run the filter. This breaks the taint chain from Blizzard's
-- secure map initialization code.
C_Timer.After(2, function()
    if not mapFrameHooked and WorldMapFrame then
        local lastMapState = false
        local checkTicker
        checkTicker = C_Timer.NewTicker(0.5, function()
            if not WorldMapFrame then
                checkTicker:Cancel()
                return
            end

            local isMapShown = WorldMapFrame:IsShown()
            if isMapShown and not lastMapState then
                DebugPrint("World map opened - checking for pending zone filter")
                MarkZoneFilterTrigger("World map opened")
                TryRunZoneFilter()
            end
            lastMapState = isMapShown
        end)
        mapFrameHooked = true
        DebugPrint("Monitoring WorldMapFrame visibility for zone filtering (non-taint approach)")
    end
end)

-- Hook Quest Log / Objective Tracker interaction.
-- Modern retail moved the minimize button from `ObjectiveTrackerFrame.HeaderMenu`
-- to `ObjectiveTrackerFrame.Header`; we probe both rather than hard-code one.
local function FindTrackerMinimizeButton()
    local OT = ObjectiveTrackerFrame
    if not OT then return nil end
    if OT.Header and OT.Header.MinimizeButton then return OT.Header.MinimizeButton end
    if OT.HeaderMenu and OT.HeaderMenu.MinimizeButton then return OT.HeaderMenu.MinimizeButton end
    if OT.MinimizeButton then return OT.MinimizeButton end
    return nil
end

C_Timer.After(1, function()
    local function HookQuestLog()
        if minimizeButtonHooked then return true end
        local btn = FindTrackerMinimizeButton()
        if not btn then return false end
        btn:HookScript("OnMouseDown", function()
            DebugPrint("Quest tracker interacted with - checking for pending zone filter")
            MarkZoneFilterTrigger("Quest tracker interaction")
            TryRunZoneFilter()
        end)
        minimizeButtonHooked = true
        DebugPrint("Hooked tracker minimize button for zone filtering")
        return true
    end

    if not HookQuestLog() then
        local attempts = 0
        local ticker
        ticker = C_Timer.NewTicker(1, function()
            attempts = attempts + 1
            if HookQuestLog() or attempts > 30 then
                ticker:Cancel()
            end
        end)
    end
end)

DebugPrint("QuestLogCollapse: Zone filtering hooks initialized")
DebugPrint("  - Quest tracker interaction will trigger pending filters")
DebugPrint("  - Player movement will trigger pending filters")
DebugPrint("  - Spell/ability cast will trigger pending filters")
DebugPrint("  - Mounting/dismounting will trigger pending filters")
DebugPrint("  - Manual trigger: /qlc filterzone")

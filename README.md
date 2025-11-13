# QuestLogCollapse

A World of Warcraft addon that automatically collapses the quest log when entering dungeons, raids, or combat situations.

**Please Note: This addon does not work with client versions < 10.0**

## Features

- **Automatic Quest Log Management**: Automatically collapses quest log sections when entering instances and expands them when leaving
- **Combat Collapse Support**: Collapses quest trackers during combat outside of instances (with smart queue system)
- **Instance Type Configuration**: Different settings for dungeons, raids, scenarios, battlegrounds, arenas, and combat
- **Individual Section Control**: Fine-grained control over which objective tracker sections to collapse (quests, achievements, bonus objectives, etc.)
- **Character-Specific Profiles**: Settings saved per character with support for multiple profiles
- **GUI Configuration**: Easy-to-use configuration panel accessible via `/qlc config`
- **Combat Queue System**: Smart handling of operations during combat to prevent taint issues
- **Nameplate Integration**: Optional nameplate management for different instance types
- **Debug Mode**: Optional debug messages to track addon behavior
- **Manual Control**: Commands to manually collapse/expand configured sections
- **Error-Safe Operation**: Protected against addon taint with comprehensive error handling
- **Lightweight**: Minimal performance impact with efficient event handling

## Installation

1. Download or clone this repository
2. Copy the `QuestLogCollapse` folder to your World of Warcraft addons directory:
   - **Windows**: `World of Warcraft\_retail_\Interface\AddOns\`
   - **macOS**: `Applications/World of Warcraft/_retail_/Interface/AddOns/`
3. Restart World of Warcraft or reload your UI (`/reload`)
4. The addon will automatically load and display a confirmation message

## Commands

The addon provides several slash commands for basic control:

- `/qlc` or `/questlogcollapse` - Show help menu with combat behavior information
- `/qlc config` - Open the configuration panel (recommended)
- `/qlc toggle` - Enable/disable the addon
- `/qlc debug` - Toggle debug messages on/off
- `/qlc status` - Show current addon status, combat queue, and section states
- `/qlc collapse` - Manually collapse configured sections (queued during combat)
- `/qlc expand` - Manually expand configured sections (cancels combat queue)
- `/qlc test` - Test objective tracker detection and combat queue status
- `/qlc testcombat` - Test combat settings and tracker availability
- `/qlc help` - Show all available commands

### Combat Behavior
- **Early Combat Detection**: Quest trackers collapse via `PLAYER_ENTER_COMBAT` event (fires before taint protection)
- **Fallback Collapse**: If early detection fails, attempts immediate collapse during `PLAYER_REGEN_DISABLED`
- **Automatic Expansion**: Quest trackers automatically expand when combat ends (only if they were collapsed during combat)
- **Queue System**: If immediate collapse fails due to taint protection, operations are queued for when combat ends
- **Smart Overrides**: Use `/qlc expand` during combat to cancel any queued collapse operations
- **Instance Priority**: Combat settings are ignored when in dungeons/instances

## Configuration

The addon features a comprehensive configuration panel accessible via `/qlc config`. The panel allows you to:

### Profile Management
- Create multiple profiles for different characters or situations
- Switch between profiles easily
- Each character can have their own profile settings

### Instance Type Settings
Configure different behaviors for each type of instance:
- **Combat**: Outside instances during combat situations
- **Dungeons**: 5-player group content
- **Raids**: Large group content  
- **Scenarios**: Solo/small group story content
- **Battlegrounds**: PvP battleground content
- **Arenas**: PvP arena content

### Individual Section Control
For each instance type, you can control which objective tracker sections get collapsed:
- **Quests**: Regular quest objectives
- **Achievements**: Achievement progress tracking
- **Bonus Objectives**: World quest and bonus objectives
- **Scenarios**: Scenario-specific objectives
- **Campaigns**: Campaign quest lines
- **World Quests**: World quest objectives
- **Professions**: Profession recipe tracking
- **Monthly Activities**: Monthly event tracking
- **UI Widgets**: Special UI widget objectives
- **Adventure Maps**: Adventure map objectives

### Additional Options
- **Nameplate Control**: Enable/disable enemy nameplates for each instance type
- **Profile Management**: Create, switch, and manage multiple configuration profiles

## How It Works

The addon uses the World of Warcraft API to:

1. **Detect Zone Changes**: Listens to the `ZONE_CHANGED_NEW_AREA` event
2. **Monitor Combat State**: Tracks `PLAYER_REGEN_DISABLED` and `PLAYER_REGEN_ENABLED` events
3. **Check Instance Type**: Uses `IsInInstance()` to determine if you're in a dungeon, raid, scenario, battleground, or arena
4. **Apply Instance-Specific Settings**: Uses different configurations based on the type of instance you're in
5. **Smart Combat Handling**: Queues operations during combat and applies them safely when combat ends
6. **Manage Individual Sections**: Controls specific ObjectiveTracker modules rather than the entire frame
   - `QuestObjectiveTracker` - Regular quests
   - `AchievementObjectiveTracker` - Achievements  
   - `BonusObjectiveTracker` - World quests and bonus objectives
   - `ScenarioObjectiveTracker` - Scenario objectives
   - `CampaignQuestObjectiveTracker` - Campaign quests
   - `WorldQuestObjectiveTracker` - World quest objectives
   - `ProfessionsRecipeTracker` - Profession recipes
   - `MonthlyActivitiesObjectiveTracker` - Monthly activities
   - `UIWidgetObjectiveTracker` - UI widget objectives
   - `AdventureMapQuestObjectiveTracker` - Adventure map objectives

### Combat Queue System
- **Early Detection**: Uses `PLAYER_ENTER_COMBAT` event for earliest possible collapse (before taint protection)
- **Dual-Layer Approach**: Fallback to `PLAYER_REGEN_DISABLED` if early detection fails or is incomplete
- **Smart Expansion**: Tracks which trackers were collapsed during combat and only expands those on combat end
- **State Preservation**: Maintains quest log state when combat collapse is disabled or no trackers were affected
- **Taint Prevention**: If both immediate attempts fail, operations are safely queued to prevent addon taint
- **Operation Queuing**: Queues collapse/expand operations when combat is detected
- **Automatic Application**: Applies queued operations safely when combat ends
- **Manual Overrides**: Allows manual cancellation of queued operations
- **Instance Priority**: Combat operations are ignored when in instances to avoid conflicts

## Technical Details

### File Structure
```
QuestLogCollapse/
├── QuestLogCollapse.toc           # Addon metadata and file loading
├── QuestLogCollapse.lua           # Main addon logic and event handling  
└── QuestLogCollapse_Config.lua    # Configuration panel and profile management
```

### Events Handled
- `ADDON_LOADED` - Initialize settings when addon loads
- `PLAYER_ENTERING_WORLD` - Mark addon as fully loaded and ready
- `ZONE_CHANGED_NEW_AREA` - Detect when player changes zones/instances
- `PLAYER_ENTER_COMBAT` - Early combat detection for immediate collapse (before taint protection)
- `PLAYER_REGEN_DISABLED` - Handle entering combat (fallback immediate collapse or queue operations)
- `PLAYER_REGEN_ENABLED` - Handle leaving combat (apply queued operations)

### Database Structure
- `QuestLogCollapseDB` - Global settings and profiles
- `QuestLogCollapseCharDB` - Character-specific settings (current profile)

## Configuration

Settings are organized into profiles with the following structure:

### Global Settings
- `enabled` (default: true) - Whether the addon is active
- `debug` (default: false) - Whether to show debug messages

### Instance Type Settings (per profile)
Each instance type (combat, dungeons, raids, scenarios, battlegrounds, arenas) has:
- `enabled` - Whether to process this instance type
- Individual section collapse settings for each ObjectiveTracker module
- `namePlates.enabled` - Whether to show enemy nameplates for this instance type

## Compatibility

- **WoW Version**: Compatible with retail World of Warcraft (Interface 110002+)
- **Dependencies**: None - this is a standalone addon
- **Conflicts**: Should not conflict with other quest log or UI addons

## Troubleshooting

### Quest Log Not Collapsing/Expanding
1. Check if the addon is enabled: `/qlc status`
2. Open the configuration panel: `/qlc config`
3. Verify that the current instance type is enabled in your active profile
4. Check that the specific sections you want collapsed are enabled for that instance type
5. Enable debug mode to see what's happening: `/qlc debug`
6. Try manually toggling: `/qlc collapse` or `/qlc expand`

### Combat Operations Not Working
1. Check if combat instance type is enabled: `/qlc config`
2. Verify you're outside of instances (combat settings ignored in dungeons/raids)
3. Check combat queue status: `/qlc status`
4. Enable debug mode to see combat queue operations: `/qlc debug`
5. Try manual commands to test: `/qlc collapse` during combat

### Addon Taint Issues
1. The addon now uses a combat queue system to prevent taint
2. If you see "ADDON_ACTION_BLOCKED" errors, ensure you're using the latest version
3. Operations during combat are queued and applied safely when combat ends
4. Use `/qlc expand` during combat to cancel problematic queued operations

### Addon Not Loading
1. Ensure files are in the correct directory
2. Check that `QuestLogCollapse.toc` has the correct interface version
3. Make sure all files are present and properly named (`QuestLogCollapse.lua`, `QuestLogCollapse_Config.lua`)
4. Try `/reload` to refresh addons

### Configuration Panel Not Opening
1. Make sure both lua files are loaded properly
2. Check for any lua errors using an error display addon
3. Try `/qlc help` to see if basic commands work

### Settings Not Saving
1. Check that you have write permissions in your WoW directory
2. Verify that `SavedVariables` and `SavedVariablesPerCharacter` are working
3. Settings are saved when you log out or `/reload`

### Debug Information
Enable debug mode with `/qlc debug` to see detailed information about:
- Zone changes and dungeon detection
- Combat state changes and queue operations
- Quest log state changes
- Addon initialization
- Error handling and protected function calls

## Contributing

Feel free to submit issues, feature requests, or pull requests to improve this addon.

## License

This project is open source. Feel free to modify and distribute as needed.

## Changelog

### Version 1.3.0
- **Automatic Quest Log Expansion**: Quest trackers now automatically expand when combat ends (only if they were collapsed during combat)
- **Smart State Tracking**: Added tracking to determine which trackers were collapsed during combat for intelligent restoration
- **Enhanced Combat Flow**: Complete combat cycle - collapse on enter, expand on exit (outside instances)
- **Improved State Management**: Better handling of combat state when collapse is disabled or no trackers are affected
- **Enhanced Debug Information**: Added tracker collapse state to status and test commands

### Version 1.2.0
- **Early Combat Detection**: Added `PLAYER_ENTER_COMBAT` event for earliest possible quest tracker collapse
- **Dual-Layer Combat System**: Early detection + fallback system for maximum reliability
- **Improved Success Rate**: Better chance of collapsing trackers before taint protection activates
- **Enhanced Debug Logging**: Better tracking of early vs. fallback combat detection
- **Reduced Taint Risk**: Earlier event handling reduces reliance on protected functions during combat

### Version 1.1.0
- **Enhanced Combat Collapse**: Quest trackers now attempt immediate collapse when entering combat
- **Improved Combat Handling**: Added fallback queuing system when immediate collapse fails due to taint protection
- **New Test Command**: Added `/qlc testcombat` to test combat settings and tracker availability
- **Better User Feedback**: Enhanced debug messages for immediate vs. queued combat operations
- **World Quest Support**: Added world quest tracker support to immediate combat collapse

### Version 1.0.0
- Initial release with comprehensive functionality
- Automatic quest log collapse/expand based on instance entry/exit
- Combat collapse support with smart queue system
- Multiple instance type support (combat, dungeons, raids, scenarios, battlegrounds, arenas)
- Individual objective tracker section control
- Character-specific profile system
- GUI configuration panel with scrollable interface
- Nameplate integration for instance types
- Combat queue system to prevent addon taint
- Protected function error handling
- Comprehensive slash command interface
- Debug mode with detailed logging
- Manual override capabilities
- Settings migration and profile management
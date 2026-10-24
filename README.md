# QuestLogCollapse

A World of Warcraft addon that automatically collapses the quest log when entering configured instances.
Optionally can filter quests to current zone (triggered by user actions to avoid taint).
**Please Note: This addon targets current Retail builds (Interface 120000/120001/120500/120700).**

## Features

- **Automatic Quest Log Management**: Automatically collapses quest log sections when entering instances and expands them when leaving
- **Instance Type Configuration**: Different settings for dungeons, raids, scenarios, battlegrounds, and arenas
- **Default Settings**: Settings used when no instance-specific settings apply; combat itself does not trigger tracker changes
- **Individual Section Control**: Fine-grained control over which objective tracker sections to collapse (quests, achievements, bonus objectives, etc.)
- **Character-Specific Profiles**: Settings saved per character with support for multiple profiles
- **GUI Configuration**: Easy-to-use configuration panel accessible via `/qlc config`
- **Combat Safety**: Manual tracker operations are deferred during combat to prevent taint issues
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

- `/qlc` or `/questlogcollapse` - Show help menu
- `/qlc config` - Open the configuration panel (recommended)
- `/qlc toggle` - Enable/disable the addon
- `/qlc debug` - Toggle debug messages on/off
- `/qlc status` - Show current addon status, combat queue, and section states
- `/qlc collapse` - Manually collapse configured sections (queued during combat)
- `/qlc expand` - Manually expand configured sections (cancels combat queue)
- `/qlc filterzone` - Manually filter quests by current zone (if enabled in settings)
- `/qlc diag` - Show concise diagnostics (profile, context, queue, blacklist, trigger source)
- `/qlc test` - Test objective tracker detection and combat queue status
- `/qlc testcombat` - Test current settings and tracker availability (legacy command name)
- `/qlc help` - Show all available commands

### Combat Safety

- Combat does not trigger automatic tracker changes.
- Manual tracker operations requested during combat are deferred until combat ends to avoid taint.
- Use `/qlc expand` during combat to cancel any queued collapse operation.

## Configuration

The addon features a comprehensive configuration panel accessible via `/qlc config`. The panel allows you to:

### Global Settings

- `Enable QuestLogCollapse` (default: true) - Whether the addon is active
- `Filter Quests by Current Zone` (default: false) - Track/Untrack quests in your current zone when you open the map, move, use an ability, mount/dismount, or use `/qlc filterzone`
- `Debug Mode` (default: false) - Whether to show debug messages

### Profile Management

- Create multiple profiles for different characters or situations
- Switch between profiles easily
- Each character can have their own profile settings

### Instance Type Settings

Configure different behaviors for each type of instance. **Default Settings** are used when no instance-specific settings apply; they do not trigger actions just because combat starts.

- **Default Settings**: Fallback settings outside recognized instance contexts
- **Dungeons**: 5-player group content
- **Raids**: Large group content  
- **Scenarios**: Solo/small group story content
- **Battlegrounds**: PvP battleground content
- **Arenas**: PvP arena content
- **Garrison**: Inside your Garrison
- **Class Hall**: Inside your Legion Class Hall
- **Quest/Map Tables**: When near/using a map/quest/campaign table
- **Neighbourhood**: In your neighbourhood
- **House**: In the interior of your house

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

- **Nameplate Control**: Show enemy nameplates according to each zone type's setting; restore your original setting when the active zone type does not request them
- **Profile Management**: Create, switch, and manage multiple configuration profiles

## How It Works

The addon uses the World of Warcraft API to:

1. **Detect Zone Changes**: Listens to the `ZONE_CHANGED_NEW_AREA` event
2. **Avoid Protected Operations During Combat**: Defers manual tracker changes until combat ends
3. **Check Instance Type**: Uses `IsInInstance()` to determine if you're in a dungeon, raid, scenario, battleground, or arena
4. **Apply Instance-Specific Settings**: Uses different configurations based on the type of instance you're in
5. **Use Default Settings**: Falls back to the default settings when no instance-specific settings apply
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

### Manual Operations During Combat

- Combat does not trigger automatic tracker changes.
- Manual collapse/expand commands issued during combat are queued until combat ends to avoid taint.
- Use `/qlc expand` during combat to cancel a queued collapse.

## Technical Details

### File Structure

```text
QuestLogCollapse/
├── QuestLogCollapse.toc           # Addon metadata and file loading
├── QuestLogCollapse.lua           # Main addon logic and event handling  
└── QuestLogCollapse_Config.lua    # Configuration panel and profile management
```

### Events Handled

- `ADDON_LOADED` - Initialize settings when addon loads
- `PLAYER_ENTERING_WORLD` - Mark addon as fully loaded and ready
- `ZONE_CHANGED_NEW_AREA` - Detect when player changes zones/instances (sets flag for zone filtering)
- `PLAYER_STARTED_MOVING` - Triggers pending zone filter when player moves (hardware-initiated)
- `UNIT_SPELLCAST_SUCCEEDED` - Triggers pending zone filter when player casts spells/abilities (hardware-initiated)
- `PLAYER_MOUNT_DISPLAY_CHANGED` - Triggers pending zone filter when mounting/dismounting (hardware-initiated)
- `PLAYER_REGEN_ENABLED` - Apply manually queued tracker operations after combat

### Zone Filtering Triggers (Taint-Safe)

To avoid taint issues with protected quest tracking functions, zone filtering is triggered by user-initiated actions:

- **Quest Tracker Interaction** - Triggers when you interact with the objective tracker
- **Player Movement** - Triggers when you start moving after a zone change
- **Spell/Ability Use** - Triggers when you cast any spell or ability (including dynamic flight abilities)
- **Mounting/Dismounting** - Triggers when your mount state changes
- **Manual Command** - Use `/qlc filterzone` to trigger anytime

### Database Structure

- `QuestLogCollapseDB` - Global settings and profiles
- `QuestLogCollapseCharDB` - Character-specific settings (current profile)

### Addon Namespace

Both Lua files share WoW's private addon namespace (`local addonName, ns = ...`).
Shared functions and dialog definitions live on `ns`; implementation helpers, frames,
and transient state stay file-local. No addon frames are globally named.

Saved variables are bound at `ADDON_LOADED` as `ns.db` and `ns.charDB`, referencing
the original tables without changing existing profiles or saved-variable names.
Only WoW-required registrations remain global: the two saved variables,
`SLASH_QUESTLOGCOLLAPSE1/2`, the `SlashCmdList.QUESTLOGCOLLAPSE` handler, and
`StaticPopupDialogs.QUESTLOGCOLLAPSE_NEW_PROFILE`. Namespacing prevents accidental
global pollution; it does not make protected Blizzard API calls taint-free.

Run `lua5.1 tests/namespace.lua` from the repository root to check namespace
isolation, saved-variable identity, settings registration, and deferred operations
with a mocked WoW environment.

## Compatibility

- **WoW Version**: Compatible with retail World of Warcraft (Interface 120000, 120001, 120500, 120700)
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

### Default Settings Not Being Used

1. Open `/qlc config` and review the **Default Settings** section.
2. Confirm that Default Settings are active and that the desired sections are enabled.
3. Instance-specific settings take precedence in recognized instances.

### Addon Taint Issues

1. The addon uses a combat queue system to prevent taint from collapse operations
2. Zone filtering uses a hybrid trigger system (user actions) to avoid taint from protected quest tracking functions
3. If you see "ADDON_ACTION_BLOCKED" errors with zone filtering:
   - The filter requires a user action after zone changes (open map, move, or use `/qlc filterzone`)
   - This is by design to comply with WoW's taint protection system
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
- Combat safety and deferred manual operations
- Quest log state changes
- Addon initialization
- Error handling and protected function calls

## CONTRIBUTORS

- **Gaspode** - Original author and maintainer
- **Artherion77** - UI configuration panel revamp and usability improvements

## Contributing

Feel free to submit issues, feature requests, or pull requests to improve this addon.
***Please note: If you submit a PR, please tag me (@ChadAPSheridan) for a review, otherwise I may miss it.

## License

This project is open source. Feel free to modify and distribute as needed.

## Changelog

### Version 1.5.7

- Tightened up namespacing and added more error handling to prevent taint issues
- Added tests for namespace isolation, saved-variable identity, settings registration, and deferred operations with a mocked WoW environment.

### Version 1.5.6

- Reset TAINT_BLACKLIST entry for UI Widgets to default to true to address taint issues that persist.

### Verion 1.5.5

- Added `/qlc diag` command for concise diagnostics (profile, context, queue, blacklist, trigger source)
- Improved debug logging for zone filtering triggers and combat queue operations
- hopefully fixed remaining taint issues with zone filtering and combat queue operations

### Version 1.5.4

- Fixed World Map visibility monitoring for zone filtering (non-taint approach)
- Improved debug logging for zone filtering triggers

### Version 1.5.3

- Minor bug fixes and performance improvements

### Version 1.5.2

- Use securecall for tracker collapse and expand paths instead of direct calls to protected functions.
- This should eliminate any remaining taint issues with tracker collapse/expand operations.

### Version 1.4.1

- Updated compatible version

### Version 1.4.0

- Significant code refactor and optimization for better performance and maintainability
- **Significant UI Revamp**: Updated configuration panel with improved layout and usability (courtesy of Artherion77)
- Updated documentation to reflect new zone filtering system and UI changes
- Updated compatible version

### Version 1.3.2

- Update compatible version

### Version 1.3.1

- **Zone Filtering Taint Fix**: Completely redesigned zone filtering to use hybrid trigger system
  - Zone changes set a flag instead of immediately calling protected functions
  - Filter automatically triggers on user actions (opening map, moving, using abilities, mount/unmount, quest tracker interaction)
  - Added `/qlc filterzone` command for manual triggering
  - Eliminates `ADDON_ACTION_BLOCKED` errors from quest tracking operations
  - Now fully compatible with WoW's taint protection system
- **Enhanced Documentation**: Updated README with clear explanation of zone filtering triggers

### Version 1.3

- **Taint Issues Resolved!!!:** Implemented [namespacing](https://warcraft.wiki.gg/wiki/Using_the_AddOn_namespace) throughout entire addon to resolve secret variable taint issues.
- If this completely resolves taint issues, will remove previous mitigation strategies (disabling collapsing of certain trackers, setting delays etc.) in the next update, but wanted to get this into user's hands asap.

### Version 1.2.7

- **Zone Filtering Added**: You can now enable the option to have quests tracked and untracked based on your current zone.
- **Error Handling Updates**: Added more error handling in a further attempt to catch those pesky taint errors before they escape.
- **Documentation Updates & Fixes**: Configuration is now all listed in one area.

### Verion 1.2.6

- **New Instance Types Supported**: QLC now has configurable support for Garrisons, Class Halls, Quest Tables, Neighbourhoods, and House Interiors!
- **Passive Garbage Collection**: In some rare situations (ie. repeated entering and exiting combat in a non-instance with other, non-contained combat/location tracking addons installed) the state tracking was balooning in memory footprint. Added non-intrusive GC to address.
  
### Version 1.2.3

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

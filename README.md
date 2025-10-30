# QuestLogCollapse

A World of Warcraft addon that automatically collapses the quest log when entering dungeons or raids.

## Features

- **Automatic Quest Log Management**: Automatically collapses quest log sections when entering instances and expands them when leaving
- **Instance Type Configuration**: Different settings for dungeons, raids, scenarios, battlegrounds, and arenas
- **Individual Section Control**: Fine-grained control over which objective tracker sections to collapse (quests, achievements, bonus objectives, etc.)
- **Character-Specific Profiles**: Settings saved per character with support for multiple profiles
- **GUI Configuration**: Easy-to-use configuration panel accessible via `/qlc config`
- **Debug Mode**: Optional debug messages to track addon behavior
- **Manual Control**: Commands to manually collapse/expand configured sections
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
- `/qlc status` - Show current addon status and section states
- `/qlc collapse` - Manually collapse configured sections
- `/qlc expand` - Manually expand configured sections
- `/qlc help` - Show all available commands

## Configuration

The addon features a comprehensive configuration panel accessible via `/qlc config`. The panel allows you to:

### Profile Management
- Create multiple profiles for different characters or situations
- Switch between profiles easily
- Each character can have their own profile settings

### Instance Type Settings
Configure different behaviors for each type of instance:
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
- **Professions**: Profession recipe tracking
- **Monthly Activities**: Monthly event tracking
- **UI Widgets**: Special UI widget objectives
- **Adventure Maps**: Adventure map objectives

## How It Works

The addon uses the World of Warcraft API to:

1. **Detect Zone Changes**: Listens to the `ZONE_CHANGED_NEW_AREA` event
2. **Check Instance Type**: Uses `IsInInstance()` to determine if you're in a dungeon, raid, scenario, battleground, or arena
3. **Apply Instance-Specific Settings**: Uses different configurations based on the type of instance you're in
4. **Manage Individual Sections**: Controls specific ObjectiveTracker modules rather than the entire frame
   - `QuestObjectiveTracker` - Regular quests
   - `AchievementObjectiveTracker` - Achievements  
   - `BonusObjectiveTracker` - World quests and bonus objectives
   - `ScenarioObjectiveTracker` - Scenario objectives
   - `CampaignQuestObjectiveTracker` - Campaign quests
   - `ProfessionsRecipeTracker` - Profession recipes
   - `MonthlyActivitiesObjectiveTracker` - Monthly activities
   - `UIWidgetObjectiveTracker` - UI widget objectives

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
- `ZONE_CHANGED_NEW_AREA` - Detect when player changes zones/instances

### Database Structure
- `QuestLogCollapseDB` - Global settings and profiles
- `QuestLogCollapseCharDB` - Character-specific settings (current profile)

## Configuration

Settings are organized into profiles with the following structure:

### Global Settings
- `enabled` (default: true) - Whether the addon is active
- `debug` (default: false) - Whether to show debug messages

### Instance Type Settings (per profile)
Each instance type (dungeons, raids, scenarios, battlegrounds, arenas) has:
- `enabled` - Whether to process this instance type
- Individual section collapse settings for each ObjectiveTracker module

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
- Quest log state changes
- Addon initialization

## Contributing

Feel free to submit issues, feature requests, or pull requests to improve this addon.

## License

This project is open source. Feel free to modify and distribute as needed.

## Changelog

### Version 1.0.0
- Initial release
- Automatic quest log collapse/expand based on dungeon entry/exit
- Slash commands for configuration and manual control
- Debug mode for troubleshooting
- Saved settings per character
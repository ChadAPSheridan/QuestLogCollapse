# QuestLogCollapse

A World of Warcraft addon that automatically collapses the quest log when entering dungeons or raids.

## Features

- **Automatic Quest Log Management**: Automatically collapses the quest log when entering dungeons/raids and expands it when leaving
- **Configurable**: Enable/disable the addon functionality with simple commands
- **Debug Mode**: Optional debug messages to track addon behavior
- **Manual Control**: Commands to manually collapse/expand the quest log
- **Lightweight**: Minimal performance impact with efficient event handling

## Installation

1. Download or clone this repository
2. Copy the `QuestLogCollapse` folder to your World of Warcraft addons directory:
   - **Windows**: `World of Warcraft\_retail_\Interface\AddOns\`
   - **macOS**: `Applications/World of Warcraft/_retail_/Interface/AddOns/`
3. Restart World of Warcraft or reload your UI (`/reload`)
4. The addon will automatically load and display a confirmation message

## Commands

The addon provides several slash commands for configuration and manual control:

- `/qlc` or `/questlogcollapse` - Show help menu
- `/qlc toggle` - Enable/disable the addon
- `/qlc debug` - Toggle debug messages on/off
- `/qlc status` - Show current addon status and settings
- `/qlc collapse` - Manually collapse the quest log
- `/qlc expand` - Manually expand the quest log
- `/qlc help` - Show all available commands

## How It Works

The addon uses the World of Warcraft API to:

1. **Detect Zone Changes**: Listens to the `ZONE_CHANGED_NEW_AREA` event
2. **Check Instance Type**: Uses `IsInInstance()` to determine if you're in a dungeon or raid
3. **Manage Quest Log**: Uses the `questLogCollapseFilter` CVar to control quest log state
   - `0` = Expanded quest log
   - `1` = Collapsed quest log

## Technical Details

### Files Structure
```
QuestLogCollapse/
├── QuestLogCollapse.toc    # Addon metadata and file loading
└── QuestLogCollapse.lua    # Main addon logic
```

### Events Handled
- `ADDON_LOADED` - Initialize settings when addon loads
- `ZONE_CHANGED_NEW_AREA` - Detect when player changes zones/instances

### CVars Used
- `questLogCollapseFilter` - Controls the quest log collapse state

## Configuration

Settings are automatically saved to your character and include:

- `enabled` (default: true) - Whether the addon is active
- `debug` (default: false) - Whether to show debug messages

## Compatibility

- **WoW Version**: Compatible with retail World of Warcraft (Interface 110002+)
- **Dependencies**: None - this is a standalone addon
- **Conflicts**: Should not conflict with other quest log or UI addons

## Troubleshooting

### Quest Log Not Collapsing/Expanding
1. Check if the addon is enabled: `/qlc status`
2. Enable debug mode to see what's happening: `/qlc debug`
3. Try manually toggling: `/qlc collapse` or `/qlc expand`

### Addon Not Loading
1. Ensure files are in the correct directory
2. Check that `QuestLogCollapse.toc` has the correct interface version
3. Make sure both files are present and properly named
4. Try `/reload` to refresh addons

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
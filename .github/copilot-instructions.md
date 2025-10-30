# QuestLogCollapse - World of Warcraft Addon

This workspace contains a World of Warcraft addon that automatically collapses the quest log when entering dungeons or raids.

## Project Structure

- `QuestLogCollapse.toc` - Addon metadata file defining the addon interface version, name, and files to load
- `QuestLogCollapse.lua` - Main addon logic with event handling and quest log management
- `README.md` - Complete documentation for installation, usage, and troubleshooting

## Development Guidelines

- This is a Lua-based World of Warcraft addon
- Uses WoW API events and CVars for functionality
- Follows standard WoW addon conventions and structure
- No external dependencies required
- Compatible with retail World of Warcraft (Interface 110002+)

## Installation for Users

1. Copy the entire project folder to `World of Warcraft/_retail_/Interface/AddOns/`
2. Restart WoW or use `/reload`
3. Use `/qlc` commands to configure and control the addon

## Key Features

- Automatic quest log collapse/expand based on dungeon entry/exit
- Configurable with slash commands
- Debug mode for troubleshooting
- Character-specific saved settings
- Manual override controls
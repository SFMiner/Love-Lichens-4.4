# Love & Lichens Project Configuration

## Autoload Configuration

In the Godot project settings, add the following scripts as Autoloads:

1. **GameController**
   - Path: `res://scripts/autoload/game_controller.gd`
   - Name: `GameController`
   - Singleton: Enabled

2. **DialogSystem**
   - Path: `res://scripts/autoload/dialog_system.gd`
   - Name: `DialogSystem`
   - Singleton: Enabled

3. **RelationshipSystem**
   - Path: `res://scripts/autoload/relationship_system.gd`
   - Name: `RelationshipSystem`
   - Singleton: Enabled

4. **InventorySystem**
   - Path: `res://scripts/autoload/inventory_system.gd`
   - Name: `InventorySystem`
   - Singleton: Enabled

5. **SaveLoadSystem**
   - Path: `res://scripts/autoload/save_load_system.gd`
   - Name: `SaveLoadSystem`
   - Singleton: Enabled

## Input Map Configuration

Add the following input actions:

1. **interact**
   - Key: E
   - Key: Space
   - Description: Used to interact with NPCs and objects

2. **Movement Keys** - Make sure these are properly configured:
   - ui_up: W, Up Arrow
   - ui_down: S, Down Arrow
   - ui_left: A, Left Arrow
   - ui_right: D, Right Arrow

## Project Settings

1. Set the main scene to `res://scenes/game.tscn`
2. Set the window size to 1280x720
3. Set the application name to "Love & Lichens"

## Physics Layers

1. Layer 1: Player (Collision Layer 1, Collision Mask 2)
2. Layer 2: Interactable (Collision Layer 2, Collision Mask 1)

## Quick Start Guide

1. Open the project in Godot 4.4
2. Configure the autoloads as specified above
3. Set the main scene to `res://scenes/game.tscn`
4. Run the project
5. The game will automatically load the main menu
6. Click "New Game" to start playing

## Script Structure Overview

- **game_controller.gd**: Central coordinator that manages scene loading and game state
- **dialog_system.gd**: Handles character conversations and dialog trees
- **relationship_system.gd**: Tracks player's relationships with NPCs
- **inventory_system.gd**: Manages player's items and inventory
- **save_load_system.gd**: Handles saving and loading game state

## Common Issues and Solutions

- If you see "ERROR: GameController not found" in the console, make sure GameController is properly added as an autoload
- If scenes don't load correctly, check that the paths in game_controller.gd's change_scene function are correct
- If NPCs don't interact, make sure they have the correct CollisionShape2D component added
- If the dialog panel doesn't appear, check that it's properly connected to the dialog system
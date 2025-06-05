# Save/Load System Implementation Plan for Claude Code

## Overview

This plan implements comprehensive save/load functionality for the Love & Lichens game. The current system only saves basic player state - we need to extend it to capture all critical game data including inventory, quests, relationships, time, memory system state, and phone apps.

## Architecture Summary

The save/load system follows a distributed pattern:
- Each major system implements `get_save_data()` and `load_save_data(data)` methods
- `GameState._collect_save_data()` orchestrates data collection from all systems
- `GameState._apply_save_data()` distributes loaded data back to systems
- Final JSON contains nested objects for each system's data

## Implementation Order (Priority-Based)

### Phase 1: Core Gameplay Systems (High Priority)

#### 1. Inventory System (`scripts/autoload/inventory_system.gd`)
**Status:** Missing save/load methods entirely
**Current State:** Has `get_all_items()` but no persistence integration
**Required:**
- Add `get_save_data()` method returning `{inventory: {...}, item_tags: {...}}`
- Add `load_save_data(data)` method restoring inventory state
- Preserve item amounts, custom data, and tag organization

#### 2. Quest System (`scripts/autoload/quest_system.gd`)
**Status:** Has `get_all_quests()` but not integrated with save system
**Current State:** Complete quest data structure exists
**Required:**
- Add `get_save_data()` method (can wrap existing `get_all_quests()`)
- Add `load_save_data(data)` method (can wrap existing `load_quests()`)
- Ensure area exploration data (`area_exploration` dict) is included

#### 3. Relationship System (`scripts/autoload/relationship_system.gd`)
**Status:** No save/load methods, just has relationships dict
**Current State:** Simple dictionary structure with character data
**Required:**
- Add `get_save_data()` method returning relationships dictionary
- Add `load_save_data(data)` method restoring relationships
- Emit `relationship_changed` signals after loading for UI updates

### Phase 2: Enhanced Gameplay Systems (Medium Priority)

#### 4. Memory System (`scripts/autoload/memory_system.gd`)
**Status:** Uses GameState for persistence but has local state
**Current State:** Has `examination_history` and `current_target` variables
**Required:**
- Add `get_save_data()` method for system-specific state
- Add `load_save_data(data)` method (reset `current_target` to null)
- Preserve examination history for look-at interactions

#### 5. Time System (`scripts/autoload/time_system.gd`)
**Status:** Already has `save_data()` and `load_data()` methods
**Current State:** Fully implemented, just needs integration
**Required:**
- No changes to time_system.gd needed
- Add calls in GameState `_collect_save_data()` and `_apply_save_data()`

### Phase 3: UI and Narrative Systems (Lower Priority)

#### 6. Phone Apps System
**Status:** Unknown implementation, likely in `scenes/ui/phone/`
**Discovery Required:** 
- Locate main phone scene script (probably `PhoneScene.gd`)
- Identify individual app scripts (Discord, Email, Journal)
- Determine data structures used for messages, conversations, etc.
**Required:**
- Implement phone scene `get_save_data()` and `load_save_data(data)`
- Individual app save/load methods if apps are separate scripts
- Preserve message history, read status, app states

### Phase 4: GameState Integration (Critical)

#### 7. Enhanced GameState Methods (`scripts/autoload/game_state.gd`)
**Status:** Has basic `_collect_save_data()` and `_apply_save_data()` 
**Current State:** Only handles basic player/scene data
**Required:**
- Replace `_collect_save_data()` to call all systems' `get_save_data()`
- Replace `_apply_save_data()` to call all systems' `load_save_data()`
- Add error handling and debug logging for each system
- Increment save format version to 2

## File Locations and Specific Tasks

### Files to Modify

1. **`scripts/autoload/inventory_system.gd`**
  - Add methods after line ~380 (after `clear_inventory()`)
  - Include inventory items, amounts, item_tags organization

2. **`scripts/autoload/quest_system.gd`**
  - Enhance existing save methods around line ~700
  - Ensure `area_exploration` dict is included in save data
  - Add compatibility wrappers for existing `save_quests()`/`load_quests()`

3. **`scripts/autoload/relationship_system.gd`**
  - Add methods after line ~150 (after relationship management functions)
  - Include all relationship data: levels, affinity, key moments, flags

4. **`scripts/autoload/memory_system.gd`**
  - Add methods after line ~300 (after utility functions)
  - Save examination history, reset current_target on load

5. **`scripts/autoload/game_state.gd`**
  - Replace `_collect_save_data()` around line 400
  - Replace `_apply_save_data()` around line 450
  - Add system-by-system data collection and distribution

6. **Phone App Scripts** (Discovery Required)
  - Locate in `scenes/ui/phone/` directory
  - Implement save/load for message data, app states, notifications

### Data Structure Requirements

The final JSON should have this structure:

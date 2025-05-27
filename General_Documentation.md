# Love & Lichens - General Documentation

## Introduction

This document provides a comprehensive overview of the various systems and components that make up the "Love & Lichens" game. It is intended for developers and contributors to understand the game's architecture and how different parts interact. All file paths and script names are formatted with backticks, e.g., `scripts/autoload/game_controller.gd`.

## Autoload Systems (Singletons)

Autoload systems, also known as Singletons in Godot, provide globally accessible functionality throughout the game. They are primarily located in `scripts/autoload/`.

### Character Data Loader (`scripts/autoload/character_data_loader.gd`)

*   **Purpose:** Responsible for loading character-specific data from JSON files located in `data/characters/`. This includes character names, dialogue file paths, display names, and potentially other metadata like font preferences or portrait paths.
*   **Key Functions:**
    *   `load_character_data(character_id)`: Loads data for a specific character by reading their respective JSON file (e.g., `data/characters/poison.json`).
    *   `get_character_dialogue_file(character_id)`: Returns the dialogue file path (e.g., `res://data/dialogues/erik.dialogue`) for a character.
    *   `get_character_display_name(character_id)`: Returns the name to be shown in UI elements.

### Game Controller (`scripts/autoload/game_controller.gd`)

*   **Purpose:** Acts as a central hub for managing high-level game state, player interactions, and overall game flow. It often orchestrates the initialization of other systems and manages transitions between broad game states (e.g., from field exploration to combat).
*   **Key Functions:**
    *   Manages the main player node instance and its availability.
    *   Handles global event listeners or signals.
    *   Coordinates interactions between disparate game systems when direct dependencies are not desirable.

### GameState (`scripts/autoload/game_state.gd`)

*   **Purpose:** Maintains the overall persistent state of the game world that isn't specific to one system. This can include tracking global flags (e.g., "main_story_arc_completed"), current major game chapter or phase, or world conditions that might affect multiple systems (e.g., weather, time of day effects beyond just visuals).
*   **Key Functions:**
    *   `set_flag(flag_name, value)`: Sets a global boolean flag.
    *   `get_flag(flag_name)`: Retrieves the value of a global flag.
    *   `get_current_chapter()`: Returns the current narrative chapter or game phase.
    *   Often works closely with the `SaveLoadSystem` to ensure these states are persisted.

### Memory System (`scripts/autoload/memory_system.gd`)

*   **Purpose:** Manages game events, player choices, character knowledge, and world state changes that need to be remembered across sessions or to influence future events, dialogue, and quest progression. This system is crucial for creating dynamic narratives and responsive game worlds.
*   **Key Functions:**
    *   `set_memory(memory_id, value)`: Stores a piece of information (boolean, integer, string) associated with a unique ID. For example, `set_memory("poison_met_player", true)`.
    *   `get_memory(memory_id)`: Retrieves a stored piece of information.
    *   `check_memory_condition(condition_string)`: Evaluates if a certain condition based on memories is met (e.g., "poison_met_player == true and player_has_item_X == false").
    *   `increment_memory(memory_id, amount)`: Increases a numerical memory.
*   **Memory Chains:** The system may support "memory chains," where sequences of memories or conditions unlock further narrative branches or game content. See `Test Quest_ Poison's Memory Chain.md` for conceptual examples.
*   **Integration:** Works closely with `scripts/autoload/dialog_memory_extension.gd` to allow dialogue scripts to directly read and write memories.
*   **Data:** Memory states are saved as part of the game save data. Definitions or structures for complex memories might be outlined in `data/memories/` (e.g., `data/memories/poison.json`).

### Quest System (`scripts/autoload/quest_system.gd`)

*   **Purpose:** Manages quests, including their activation, tracking objectives, progression, and completion. Handles distributing rewards and notifying other systems of quest state changes.
*   **Key Functions:**
    *   `start_quest(quest_id)`: Initiates a new quest, loading its data from `data/quests/`.
    *   `update_quest_objective(quest_id, objective_id, status_or_progress)`: Updates the status or progress of a quest objective.
    *   `complete_quest(quest_id)`: Marks a quest as completed and distributes rewards (e.g., items, experience, relationship changes).
    *   `is_quest_active(quest_id)`, `is_quest_completed(quest_id)`: Checks quest states.
*   **Related Files:** Quest definitions are stored in JSON files within `data/quests/` (e.g., `data/quests/intro_quest.json`).
*   **UI:** Interacts with `scenes/ui/quest_panel.tscn` to display quest information.

### Time System (`scripts/autoload/time_system.gd`)

*   **Purpose:** Manages the in-game time, date, day of the week, and potentially day/night cycles or seasonal changes.
*   **Key Functions:**
    *   `advance_time(hours, minutes)`: Moves the in-game time forward. Can trigger events at specific times.
    *   `get_current_time_string()`: Returns the current in-game time as a formatted string.
    *   `get_current_day()`, `get_current_weekday()`: Returns current day/date information.
    *   `is_daytime()`, `is_nighttime()`: Checks current part of the day.
*   **UI:** The `scenes/ui/time_display.tscn` UI element reads data from this system to show the current time to the player. Works with `scenes/ui/sleep_interface.tscn` to allow players to pass large blocks of time.

### Inventory System (`scripts/autoload/inventory_system.gd`)

*   **Purpose:** Manages the player's inventory, including adding, removing, using, and querying items.
*   **Key Functions:**
    *   `add_item(item_id, quantity)`: Adds an item (defined in `data/items/item_templates.json`) to the inventory.
    *   `remove_item(item_id, quantity)`: Removes an item from the inventory.
    *   `has_item(item_id, quantity)`: Checks if the player possesses a specific item and quantity.
    *   `use_item(item_id)`: Triggers the item's effect, often by calling `scripts/autoload/item_effects_system.gd`.
*   **UI:** Interacts with `scenes/ui/inventory_panel.tscn`, which uses `scenes/ui/inventory_item_slot.tscn` and `scenes/ui/inventory_tooltip.tscn` for display.
*   **Data:** Item definitions are loaded from `data/items/item_templates.json`.

### Navigation Manager (`scripts/autoload/navigation_manager.gd`)

*   **Purpose:** Handles player movement between different game locations/scenes and within scenes if pathfinding is used. Manages scene loading/unloading and placing the player at correct entry points.
*   **Key Functions:**
    *   `change_scene(target_scene_path, spawn_point_name)`: Loads a new game location (e.g., `scenes/world/locations/library.tscn`) and positions the player at a designated `scenes/world/locations/spawn_point.tscn` within that scene.
    *   `get_player_current_scene()`: Returns the path of the currently active scene.
*   **Related Scenes:** Uses `scenes/world/locations/spawn_point.tscn` for defining entry positions and `scenes/transitions/` (e.g. `scenes/transitions/campus_to_cemetery.tscn`) for managing visual transitions between scenes.

### Fast Travel System (`scripts/autoload/fast_travel_system.gd`)

*   **Purpose:** Allows the player to quickly travel between previously discovered or unlocked locations on a map or list.
*   **Key Functions:**
    *   `unlock_location(location_id)`: Makes a location available for fast travel.
    *   `get_unlocked_locations()`: Returns a list of available fast travel points.
    *   `travel_to(location_id)`: Initiates travel to a location, likely by calling `NavigationManager.change_scene()` with the appropriate scene path and spawn point associated with the `location_id`.
    *   May check `GameState.gd` or `QuestSystem.gd` for conditions that might temporarily disable fast travel or specific locations.
*   **UI:** Would typically interact with a dedicated fast travel map UI (not explicitly listed but implied).

### Save Load System (`scripts/autoload/save_load_system.gd`)

*   **Purpose:** Manages saving and loading the game state, allowing players to persist and resume their progress. This includes player data, inventory, quest states, memories, game state flags, etc.
*   **Key Functions:**
    *   `save_game(slot_id)`: Collects data from all relevant systems (Inventory, Quests, Memory, Player stats, GameState) and saves it to a specified file/slot.
    *   `load_game(slot_id)`: Loads data from a save file and restores the state of all relevant systems.
    *   `get_save_slots_info()`: Retrieves metadata about existing save files (e.g., timestamp, player location).

### Relationship System (`scripts/autoload/relationship_system.gd`)

*   **Purpose:** Tracks the player's relationships with non-player characters (NPCs). Relationship scores can influence dialogue options, quest availability, NPC behavior, and story outcomes.
*   **Key Functions:**
    *   `get_relationship_score(npc_id)`: Returns the current relationship level (e.g., a numerical value or a category like "Friendly", "Neutral", "Hostile") with an NPC.
    *   `modify_relationship_score(npc_id, amount_to_change)`: Changes the relationship level with an NPC. Can be positive or negative.
    *   `set_relationship_level(npc_id, level_name)`: Sets a specific categorical relationship level.

### Item Effects System (`scripts/autoload/item_effects_system.gd`)

*   **Purpose:** Handles the concrete effects of using items from the inventory. This system is called by `InventorySystem.use_item()`.
*   **Key Functions:**
    *   `apply_effect(item_id, target_character_node_or_id)`: Applies the specific effect of an item (e.g., heal HP, grant temporary buff, inflict status, unlock a door, trigger a memory). This function would contain a large match statement or dictionary lookup based on `item_id`.

### Look At System (`scripts/autoload/look_at_system.gd`)

*   **Purpose:** Manages the behavior of characters turning their heads or bodies to look at points of interest, the player, or other characters. This adds a dynamic visual element to interactions and makes characters feel more alive.
*   **Key Functions:**
    *   `request_look_at(character_node, target_node_or_global_position)`: Makes a character (identified by `character_node`) turn to look at a specific target.
    *   `clear_look_target(character_node)`: Resets the character's gaze to their default orientation.

### Icon System (`scripts/autoload/icon_system.gd`)

*   **Purpose:** Manages the display of various in-world icons, such as interaction prompts ("E to talk"), quest markers ("!"), or status indicators above characters or objects.
*   **Key Functions:**
    *   `show_icon_on_node(target_node, icon_type_or_texture_path)`: Displays a specified icon above a given `Node2D` or `Node3D`.
    *   `hide_icon_on_node(target_node, icon_type_or_texture_path)`: Hides a specific icon on a node.
    *   `update_icon_position(target_node)`: Ensures icons follow their target nodes if they move.
*   **Assets:** Uses icon images from `assets/icons/` (e.g., `assets/icons/target_icon.png`).

### Character Font Manager (`scripts/autoload/character_font_manager.gd`)

*   **Purpose:** Manages loading and assigning custom fonts for different characters' dialogue, adding personality and visual distinction to the text displayed in the `DialogPanel`.
*   **Key Functions:**
    *   `get_font_for_character(character_id)`: Returns the specific Godot `Font` resource for a character, potentially loading it from `assets/fonts/` based on data from `CharacterDataLoader.gd`.
*   **Assets:** Font files are stored in `assets/fonts/` (e.g., `assets/fonts/WigglyCurvesRegular-qZdAx.ttf`).

### Cutscene Manager (`scripts/autoload/cutscene_manager.gd`)

*   **Purpose:** Controls the playback of pre-scripted sequences (cutscenes) that advance the story, showcase important events, or introduce characters/locations.
*   **Key Functions:**
    *   `play_cutscene(cutscene_id_or_scene_path)`: Starts a cutscene. This might involve taking control from the player, moving characters, playing animations, and displaying dialogue.
    *   `is_cutscene_playing()`: Returns true if a cutscene is currently active, which can be used by other systems to pause behavior.
    *   `end_cutscene()`: Terminates the current cutscene and returns control to the player.
*   **Related Scenes:** Uses `scenes/world/cutscene_marker.tscn` which are likely `Area2D` or `Node3D` points in a scene that can trigger a cutscene when the player enters them.

### Dialog Memory Extension (`scripts/autoload/dialog_memory_extension.gd`)

*   **Purpose:** An extension specifically for the Dialogue Manager plugin (likely Nathan Hoad's). It bridges the Dialogue Manager with the `scripts/autoload/memory_system.gd`, allowing dialogue scripts (`.dialogue` files) to directly get, set, or check memories.
*   **Key Functions:** (These are typically exposed to be callable from within dialogue script files)
    *   `get_mem(memory_id)`: Equivalent to `MemorySystem.get_memory(memory_id)`.
    *   `set_mem(memory_id, value)`: Equivalent to `MemorySystem.set_memory(memory_id, value)`.
    *   `check_mem(condition_string)`: Equivalent to `MemorySystem.check_memory_condition(condition_string)`.

## Player System

### Player Node (`scenes/player.tscn`, Script: `scripts/player/player.gd`)

*   **Purpose:** Represents the player character in the game world. This is the central node for player representation.
*   **Key Components (within `scenes/player.tscn`):**
    *   `Sprite2D` or `AnimatedSprite2D` for visual representation.
    *   `CollisionShape2D` for physics interactions and collision detection.
    *   `Camera2D` (often a child node) to control the game view.
    *   `InteractionAgent` node (script: `scripts/world/interaction_agent.gd`) for handling interactions with `scripts/world/interactable.gd` objects.
*   **Script (`scripts/player/player.gd`):**
    *   Handles player input for movement (e.g., WASD, arrow keys) and actions (e.g., interaction, jump).
    *   Manages player animations based on state (idle, walking, running).
    *   Communicates with autoload systems like `InventorySystem.gd`, `QuestSystem.gd`, `MemorySystem.gd`.
    *   Stores player-specific state that isn't combat-related (e.g., current movement speed, interaction target).

### Player Combatant (`scripts/player/player_combatant.gd`)

*   **Purpose:** Manages the player's attributes, abilities, and state specifically within combat scenarios. This script is likely attached to a child node of the main player scene or is part of the main `player.gd`'s logic when combat begins.
*   **Key Features:**
    *   Manages core combat stats: Health Points (HP), Action Points (AP) or Stamina, special attack meters. These are often defined as exported variables or loaded from character configuration data.
    *   Stores a list of available skills, spells, or attacks the player can use, possibly as an array of resource paths or IDs.
    *   Includes functions like `take_damage(amount)`, `heal(amount)`, `use_skill(skill_id)`.
    *   Handles receiving damage from enemies, including calculating reductions from armor or buffs, and applying status effects.
    *   Manages status effects (e.g., poisoned, stunned) applied to the player, potentially through a dedicated status effect manager component.
    *   Communicates player actions to the `scripts/combat/combat_manager.gd` during the player's turn (e.g., `emit_signal("action_chosen", action_data)`).
    *   Handles player defeat conditions (e.g., HP reaches zero, triggering a game over or retreat sequence).
*   **Inheritance:** Likely inherits from a base `scripts/combat/combatant.gd` class.

## NPC System

### NPC Node (`scenes/npc.tscn`, Script: `scripts/world/npc.gd`)

*   **Purpose:** Represents non-player characters in the game world. Each NPC instance in a scene would be based on `scenes/npc.tscn`.
*   **Key Components (within `scenes/npc.tscn`):**
    *   `Sprite2D` or `AnimatedSprite2D` for visual representation.
    *   `CollisionShape2D` for physics.
    *   May include an `InteractionAgent` (`scripts/world/interaction_agent.gd`) if NPCs can interact with objects, or an `Area2D` to detect the player for initiating dialogue.
    *   May use `scripts/world/character_animator.gd` for managing complex animation states based on behavior (idle, walking, talking).
*   **Script (`scripts/world/npc.gd`):**
    *   Controls NPC behavior: idle animations, movement patterns (e.g., patrolling a set path defined by `Path2D`, moving between schedule points at different times via `TimeSystem.gd`).
    *   Manages dialogue interactions: initiates dialogue with the player, often by calling `DialogueManager.start_dialogue()` with their specific dialogue file (obtained from `CharacterDataLoader.gd`).
    *   Can be a target for player interactions (talking, giving items via its `scripts/world/interactable.gd` component).
    *   Stores NPC-specific state: current schedule point, relationship status with player (via `RelationshipSystem.gd`), current mood or alertness that might affect dialogue or behavior.

### NPC Combatant (`scripts/world/npc_combatant.gd`)

*   **Purpose:** Manages NPC attributes, abilities, and AI decision-making in combat scenarios. Attached to NPCs that can participate in combat.
*   **Key Features:**
    *   Manages combat stats: HP, attack power, defense, speed, elemental weaknesses/resistances. These could be exported variables or loaded from a character data file.
    *   Defines NPC attack patterns, available skills, and special abilities.
    *   Includes AI routines for selecting targets (e.g., highest threat, lowest HP) and choosing actions during their turn in combat (e.g., attack, defend, use skill, heal based on current situation). This might involve a state machine or behavior tree.
    *   Handles status effects applied to them.
    *   Communicates chosen actions to the `scripts/combat/combat_manager.gd`.
*   **Inheritance:** Likely inherits from `scripts/combat/combatant.gd`.
*   **Specialized AI:** For more complex enemies, like "Constructs" (as suggested by `scripts/combat/construct_combatant.gd` and `scripts/combat/construct_enemy.gd`), these specialized scripts would either inherit from `scripts/world/npc_combatant.gd` or directly from `scripts/combat/combatant.gd`, implementing unique AI logic, abilities, and potentially different stat blocks.

## Interactable System

This system allows the player to interact with various objects and characters in the game world.

### Interactable Base (`scripts/world/interactable.gd`)

*   **Purpose:** This is a base script attached to any *object or character in the world* that the player can interact with. Examples: doors, items to pick up, signs to read, NPCs to talk to. It defines *what happens* when an interaction occurs.
*   **Key Features:**
    *   Typically an `Area2D` (or `Area3D`) node to define its interaction zone. The `interactable.gd` script would be attached to this Area node or its parent.
    *   Defines a primary `interact(agent)` function (or a similarly named one like `do_interaction`). The `agent` parameter is crucial; it's the node that initiated the interaction (e.g., the player node instance). This allows the interactable to know who is interacting with it.
    *   Specifies the type of interaction (e.g., "talk", "pickup", "examine", "open_door") often via an exported variable string or enum. This can be used by the `InteractionAgent` to display appropriate prompts.
    *   Can emit signals when interacted with (e.g., `signal item_taken(item_id)`), allowing other systems (`QuestSystem.gd`, `MemorySystem.gd`) to react without direct coupling.
    *   May have properties like `interaction_prompt_text` (e.g., "Read Sign") that the `InteractionAgent.gd` can fetch and display.

### Interaction Agent (`scripts/world/interaction_agent.gd`)

*   **Purpose:** This script is a component attached to the *player character* (and potentially other NPCs if they need to interact with objects). It is responsible for *detecting* and *managing* interactions with `scripts/world/interactable.gd` nodes.
*   **Key Features:**
    *   Uses an `Area2D` (or `Area3D`) child node to detect `Interactable` nodes that enter its range (i.e., their collision layers/masks are compatible).
    *   Maintains a list of currently overlapping `Interactable`s.
    *   Often determines the "best" or closest interactable target from this list, possibly based on distance or line of sight. This prevents accidental interaction with objects far away if multiple are in range.
    *   Can display a UI prompt (e.g., "Press E to talk") for the currently targeted interactable. This might involve fetching `interaction_prompt_text` from the `interactable.gd` script and using the `IconSystem.gd` or a dedicated UI label.
    *   When the player presses the interaction button (input handled by `scripts/player/player.gd`), this agent script calls the `interact(self)` method on the currently targeted `interactable.gd` script, passing itself as the `agent`.

## World and Scene Structure

### Location Management

*   **Structure:** The game world is divided into multiple Godot scenes (`.tscn` files), each representing a distinct location (e.g., `scenes/world/locations/campus_quad.tscn`, `scenes/world/locations/dorm_room.tscn`, `scenes/world/locations/library.tscn`).
*   **Scene Contents:** Each location scene typically contains:
    *   `TileMap` nodes or `Sprite2D`s/`Node2D`s for the visual environment.
    *   Instances of `scenes/npc.tscn` for characters present in that location.
    *   Various objects with `scripts/world/interactable.gd` scripts attached.
    *   `scenes/world/locations/spawn_point.tscn` nodes: These are simple `Node2D` (or `Position2D`) instances with a unique name (e.g., "EntryFromLibrary", "DefaultStart") that define where the player appears when entering the scene via `NavigationManager.gd`.
    *   Transition triggers: These are usually `Area2D` nodes with `scripts/world/interactable.gd` or specialized scripts (like `scenes/world/locations/door_transition.tscn` which itself is an interactable scene) that, when interacted with, call `NavigationManager.change_scene()` to move to another location.
*   **Directory:** Main location scenes are stored in `scenes/world/locations/`.

### Scene Transitions

*   **Mechanism:** Primarily handled by the `scripts/autoload/navigation_manager.gd` autoload.
*   **Process:**
    1.  Player interacts with a transition object (e.g., a door that is an instance of `scenes/world/locations/door_transition.tscn` or an object with a generic `scripts/world/interactable.gd` script that calls the manager) or triggers a transition area.
    2.  The transition object/script calls a function in `NavigationManager.gd`, specifying the `target_scene_path` (e.g., `res://scenes/world/locations/cemetery.tscn`) and often a `spawn_point_name` in the target scene.
    3.  `NavigationManager.gd` handles the visual transition (e.g., fade out, loading screen, fade in), loads the new scene, removes the old scene, and places the player character at the specified `scenes/world/locations/spawn_point.tscn` in the new scene.
*   **Transition Scenes:** The `scenes/transitions/` directory (e.g., `scenes/transitions/campus_to_cemetery.tscn`) may contain pre-defined scene transition animations (like `AnimationPlayer` nodes controlling fades or wipes) or specialized scenes used by `NavigationManager.gd` for more complex visual transitions between specific locations.

## UI Systems

User Interface elements are primarily located in `scenes/ui/`.

### Dialog Panel (`scenes/ui/dialog_panel.tscn`, Script: `scripts/ui/dialog_panel.gd`)

*   **Purpose:** Displays character dialogue, including speaker name (fetched via `CharacterDataLoader.gd`), dialogue text, and potentially character portraits.
*   **Integration:** Works closely with the `DialogueManager` plugin (Nathan Hoad's) and the `scripts/autoload/dialog_system.gd` autoload (if it exists as a wrapper). `scripts/autoload/character_font_manager.gd` is used to apply character-specific fonts.
*   **Features:**
    *   Text display area for dialogue lines.
    *   Label for speaker's name.
    *   Container for response options menu (e.g., `addons/dialogue_manager/dialogue_responses_menu.gd` or a custom scene like `addons/dialogue_manager/example_balloon/example_balloon.tscn`).

### Inventory Panel (`scenes/ui/inventory_panel.tscn`, Script: `scripts/ui/inventory_panel.gd`)

*   **Purpose:** Provides a graphical interface for the player to view, manage, and use items from their inventory.
*   **Features:**
    *   Grid or list display of items using instances of `scenes/ui/inventory_item_slot.tscn` (script: `scripts/ui/inventory_item_slot.gd`).
    *   Displays item tooltips with details when an item is hovered/selected, using `scenes/ui/inventory_tooltip.tscn` (script: `scripts/ui/inventory_tooltip.gd`).
    *   Allows player to select items to use (calling `InventorySystem.use_item()`), equip, or drop.
*   **Interaction:** Communicates directly with `scripts/autoload/inventory_system.gd` to get item lists and trigger actions.

### Phone System (`scenes/ui/phone/PhoneScene.tscn`, Script: `scenes/ui/phone/PhoneScene.gd`)

*   **Purpose:** Simulates a smartphone interface, providing access to various mini-applications or game features like messages, contacts, maps, or mini-games.
*   **Apps (examples from `scenes/ui/phone/apps/`):**
    *   `CameraRollApp.tscn` (Script: `scenes/ui/phone/apps/CameraRollApp.gd`): View saved images.
    *   `DiscordApp.tscn` (Script: `scenes/ui/phone/apps/DiscordApp.gd`): In-game chat/social client.
    *   `EmailApp.tscn` (Script: `scenes/ui/phone/apps/EmailApp.gd`): In-game emails.
    *   `GradesApp.tscn` (Script: `scenes/ui/phone/apps/GradesApp.gd`): View academic progress.
    *   `JournalApp.tscn` (Script: `scenes/ui/phone/apps/JournalApp.gd`): Quest log or notes.
    *   `MessagesApp.tscn` (Script: `scenes/ui/phone/apps/MessagesApp.gd`): Character text messaging.
    *   `SnakeApp.tscn` (Script: `scenes/ui/phone/apps/SnakeApp.gd`): Minigame.
    *   `SocialFeedApp.tscn` (Script: `scenes/ui/phone/apps/SocialFeedApp.gd`): In-game social media.
    *   `SporeApp.tscn` (Script: `scenes/ui/phone/apps/SporeApp.gd`): Game-specific app.
*   **Icon Assets:** Uses icons from `assets/icons/phone/` (e.g., `assets/icons/phone/camera_roll_icon.png`).

### Quest Panel (`scenes/ui/quest_panel.tscn`, Script: `scripts/ui/quest_panel.gd`)

*   **Purpose:** Displays active and completed quests, along with their objectives, descriptions, and current progress.
*   **Interaction:** Fetches quest data from `scripts/autoload/quest_system.gd` and displays it. May allow filtering or tracking specific quests.

### Pause Menu (`scenes/ui/pause_menu.tscn`, Script: `scripts/ui/pause_menu.gd`)

*   **Purpose:** Provides access to game options, saving/loading, and quitting the game when the player pauses.
*   **Features:**
    *   "Resume Game" button.
    *   "Settings" (audio, graphics, controls).
    *   "Save Game" / "Load Game" options (interacts with `scripts/autoload/save_load_system.gd`).
    *   "Exit to Main Menu" or "Exit to Desktop" options.

### Notification System (`scenes/ui/notification_system.tscn`, Script: `scripts/ui/notification_system.gd`)

*   **Purpose:** Displays temporary, non-intrusive on-screen messages to the player (e.g., "Item received: Herb", "Quest Started: Find the Lost Cat", "Memory Updated").
*   **Features:**
    *   Configurable display time, position, and animation (e.g., fade in/out).
    *   Can be triggered by various game systems emitting a global signal or calling a function on this autoload.

### Time Display (`scenes/ui/time_display.tscn`, Script: `scripts/ui/time_display.gd`)

*   **Purpose:** A UI element, usually visible on the main game screen, that shows the current in-game time and possibly the day or date.
*   **Functionality:**
    *   Reads data from `scripts/autoload/time_system.gd` at regular intervals or when time changes.
    *   Formats the time and date for display using `Label` nodes.
    *   May include icons or visual cues for day/night cycle (e.g., changing background color, sun/moon icon).

### Sleep Interface (`scenes/ui/sleep_interface.tscn`, Script: `scripts/ui/sleep_interface.gd`)

*   **Purpose:** Provides a UI for the player to pass significant amounts of in-game time, typically by sleeping (e.g., at a bed interactable).
*   **Functionality:**
    *   Allows player to select how long to sleep or to sleep until a specific time (e.g., "Sleep until morning", "Rest for 8 hours").
    *   When activated, it calls `scripts/autoload/time_system.gd` to advance the game time accordingly.
    *   May trigger specific events tied to sleeping (e.g., daily resets for certain game elements, player character healing, triggering dream sequences or cutscenes via `CutsceneManager.gd`).
    *   Could be linked to the `scripts/autoload/save_load_system.gd` to offer saving the game upon sleeping.

## Data Management

Game data is primarily stored in JSON files (`.json`) and Godot resource files (`.tres`, `.res`). Key data directories are under `data/`.

### Character Data (`data/characters/`)

*   **Format:** JSON files, one per character (e.g., `data/characters/poison.json`, `data/characters/dusty.json`).
*   **Contents:**
    *   `id`: Unique character identifier (e.g., "poison").
    *   `display_name`: Name shown in UI (e.g., "Poison").
    *   `dialogue_file`: Path to their dialogue file (e.g., `res://data/dialogues/poison.dialogue`).
    *   `font_path` (optional): Path to a specific font in `assets/fonts/`.
    *   Initial relationship scores or states.
    *   Links to sprite sheets or animation resources if not standardized.

### Dialogue Data (`data/dialogues/`)

*   **Format:** `.dialogue` files (for Nathan Hoad's Dialogue Manager plugin).
*   **Contents:**
    *   Dialogue trees defined with a custom syntax: character lines, player response choices, conditions for branches (often using `scripts/autoload/dialog_memory_extension.gd` to check memories), mutations (e.g., `do set_mem("key", value)`), and signals.

### Item Data (`data/items/item_templates.json`)

*   **Format:** A single JSON file containing a list of all item definitions.
*   **Contents (per item):**
    *   `id`: Unique item identifier (e.g., "herb_red").
    *   `name`: Display name (e.g., "Red Herb").
    *   `description`: Text for tooltips and inventory.
    *   `type`: Category (e.g., "consumable", "key_item", "collectible", "equippable").
    *   `icon_path`: Path to its image in `assets/images/items/` or `assets/icons/`.
    *   `effects`: Description of what `scripts/autoload/item_effects_system.gd` should do (e.g., `{ "heal": 10 }`, `{ "unlock_quest": "herb_quest" }`).
    *   `stackable` (boolean), `max_stack` (integer), `value` (integer for shops).

### Memory Data (`data/memories/`)

*   **Format:** Potentially JSON files (e.g., `data/memories/world_events.json`, `data/memories/poison_plot.json`) or could be implicitly defined by their usage in scripts and dialogue.
*   **Contents:** If files exist, they might define:
    *   Lists of known memory IDs for reference or debugging.
    *   Structures for complex "memory chains" or narrative flags, outlining dependencies or groupings of memories.
    *   Initial states for certain memories at the start of the game.
    *   The primary storage of memory *values* during gameplay is managed by `scripts/autoload/memory_system.gd` and included in save files.

### Quest Data (`data/quests/`)

*   **Format:** JSON files, one per quest (e.g., `data/quests/intro_quest.json`, `data/quests/lichen_collection.json`).
*   **Contents:**
    *   `id`: Unique quest identifier.
    *   `title`: Display name of the quest.
    *   `description`: Detailed explanation shown in the quest log.
    *   `objectives`: A list of tasks, each with an ID, description, and tracking type (e.g., "collect_item", "talk_to_npc", "reach_location", "memory_set").
    *   `prerequisites`: Conditions for the quest to become available (e.g., other completed quests, player level, specific memory state).
    *   `rewards`: Items, experience points, relationship changes, new fast travel locations unlocked, etc.

## Core Gameplay Loops

### Exploration and Interaction

1.  Player navigates the game world (various scenes in `scenes/world/locations/`) using input handled by `scripts/player/player.gd`.
2.  The `scripts/world/interaction_agent.gd` on the player detects nearby `scripts/world/interactable.gd` nodes.
3.  The `InteractionAgent` may display a UI prompt (e.g., "E to Talk") using the `scripts/autoload/icon_system.gd` or a dedicated UI element.
4.  Player presses the interaction key.
5.  The `InteractionAgent` calls the `interact(agent)` method on the targeted `Interactable` script.
6.  The `Interactable`'s `interact()` method executes its specific logic: starting dialogue (via `DialogueManager`), giving an item (via `scripts/autoload/inventory_system.gd`), changing a scene (via `scripts/autoload/navigation_manager.gd`), setting a memory (via `scripts/autoload/memory_system.gd`), etc.

### Dialogue and Story Progression

1.  Interaction with an NPC or object triggers a dialogue (e.g., `DialogueManager.start_dialogue("character_dialogue_file", "start_node_title")`).
2.  The `scenes/ui/dialog_panel.tscn` displays dialogue lines, speaker names (using `CharacterDataLoader.gd` for names and `scripts/autoload/character_font_manager.gd` for fonts).
3.  Player choices (if any) are presented.
4.  Selecting a choice can:
    *   Navigate to different parts of the dialogue tree.
    *   Trigger actions via `scripts/autoload/dialog_memory_extension.gd` (e.g., `do set_mem("player_agreed", true)`), which calls `scripts/autoload/memory_system.gd`.
    *   Emit signals that other systems (like `scripts/autoload/quest_system.gd` or `scripts/autoload/relationship_system.gd`) listen to.
5.  Story progresses as memories are set, quests are updated, and relationships change based on dialogue outcomes.

### Quest Completion

1.  Player receives a quest (e.g., through dialogue, interacting with an object, or automatically via `scripts/autoload/game_state.gd` triggers). `scripts/autoload/quest_system.gd` activates the quest, loading its data from `data/quests/`.
2.  The `scenes/ui/quest_panel.tscn` (or a journal UI) displays quest title, description, and objectives.
3.  Player performs actions in the game world to meet objectives. Examples:
    *   Collecting items: `scripts/autoload/inventory_system.gd` signals `QuestSystem.gd` when relevant items are added.
    *   Talking to NPCs: Dialogue choices or specific dialogue nodes signal `QuestSystem.gd`.
    *   Reaching locations: `scripts/autoload/navigation_manager.gd` or area triggers signal `QuestSystem.gd`.
    *   Specific memories being set: `scripts/autoload/memory_system.gd` signals or `QuestSystem.gd` checks.
4.  `QuestSystem.gd` updates the status of objectives.
5.  When all objectives for a quest are met, `QuestSystem.gd` marks the quest as complete and issues defined rewards (e.g., adding items to inventory, modifying relationship scores, granting new abilities).

### Inventory Management

1.  Player obtains items (world pickups via `Interactable`s, quest rewards from `QuestSystem.gd`, gifts from NPCs via dialogue). `scripts/autoload/inventory_system.gd` adds these items.
2.  Player opens the `scenes/ui/inventory_panel.tscn`.
3.  The panel displays items using `scenes/ui/inventory_item_slot.tscn` and shows details via `scenes/ui/inventory_tooltip.tscn`.
4.  Player can select items to:
    *   Use the item: `InventorySystem.use_item(item_id)` calls `scripts/autoload/item_effects_system.apply_effect(item_id, player_node)`.
    *   Equip the item (if applicable, logic within `InventorySystem.gd` or player script).
    *   Drop the item.
5.  Game logic (e.g., crafting, puzzles, dialogue options) can check for item possession using `InventorySystem.has_item(item_id)`.

### Combat

This describes a potential combat loop based on identified scripts and scenes:
1.  **Initiation:** Combat starts when the player character enters a `combat_trigger.tscn` (an `Area2D` in a location scene that calls the `scripts/combat/combat_manager.gd`) or through a scripted event/dialogue choice.
2.  **Setup:** `scripts/combat/combat_manager.gd` takes over:
    *   It may pause other game systems (like world time via `TimeSystem.gd`) and switch game music via `SoundManager.gd`.
    *   Loads a dedicated combat scene or arranges combatants in the current scene.
    *   Instantiates player combatant (from `scripts/player/player_combatant.gd`) and enemy combatants (e.g., `scripts/world/npc_combatant.gd`, `scripts/combat/construct_combatant.gd`, or `scripts/combat/combatant_enemy.gd`) using data from `CharacterDataLoader.gd` or specific enemy stats/definitions. The `scripts/combat/ConstructSpawner.tscn` (script: `scripts/combat/construct_spawner.gd`) can be used for dynamically spawning enemy waves or specific enemy types.
    *   Initializes the `scenes/ui/combat/combat_ui.tscn` (script: `scripts/combat/combat_ui.gd`) with combatant information, health bars, action menus, etc.
3.  **Turns:**
    *   `CombatManager.gd` determines turn order (e.g., based on speed stats of combatants).
    *   When it's a combatant's turn, their respective script (`player_combatant.gd` or `npc_combatant.gd`/`construct_combatant.gd`) handles action selection.
        *   Player: Waits for input from the `CombatUI` (e.g., choosing "Attack", "Skill" from a list, "Use Item" from inventory).
        *   NPC: Uses its AI routines (defined in its specific script) to select an action (attack, skill, defend) and target.
    *   The chosen action is executed. This involves damage calculation (considering stats like attack, defense, resistances), applying status effects, or using support abilities. Results are reflected in combatant stats and updated on the `CombatUI`.
    *   The base `scripts/combat/combatant.gd` script likely provides core functions for taking damage, checking for defeat (`is_defeated()`), managing health, and applying/removing status effects.
4.  **Resolution:**
    *   `CombatManager.gd` checks for win/loss conditions after each action or turn (e.g., all enemies defeated, player party defeated).
    *   Once combat ends, `CombatManager.gd` distributes rewards (experience points, items via `InventorySystem.gd`), cleans up the combat scene/state (removes defeated enemy nodes), unpauses game systems, and returns control to the `GameController.gd` or normal exploration mode (e.g., via `NavigationManager.gd`).
    *   Player/NPC states may be updated (e.g., HP is saved, resources are consumed).
    *   The `scripts/combat/combat_initializer.gd` might be involved in setting up the initial state for combatants or the combat environment.
    *   The `scenes/ui/combat/opponent_entry.tscn` is likely a UI component used within `CombatUI` to display information for each opponent.

# Scene Transition System for Love & Lichens

This document explains how to use the scene transition system to move between locations while preserving player state.

## Components

1. **location_transition.gd** - Attach to Area2D nodes to create transitions between scenes
2. **spawn_point.gd** - Attach to Marker2D nodes to define player spawn points in scenes
3. **fast_travel_system.gd** - Autoload singleton for managing available locations
4. **GameController.change_location()** - Enhanced scene transition that preserves player state

## How to Add a Scene Transition

### 1. Create a Location Transition

To add a door/portal to another scene:

1. Add an Area2D node to your scene
2. Add the Area2D to the "interactable" group
3. Attach the `location_transition.gd` script to it
4. Set these exported variables:
   - `target_location`: The name of the location (e.g., "cemetery")
   - `target_scene`: Or provide a full scene path instead
   - `spawn_point`: ID of spawn point in target scene (e.g., "entrance")
   - `transition_name`: Display name for the transition
   - `require_interaction`: Whether player needs to press interact (default: true)
   - Optional: `require_item` if a key is needed

Example:
```gdscript
[node name="CemeteryEntrance" type="Area2D" groups=["interactable"]]
script = ExtResource("1_kvd0s")  # location_transition.gd
target_location = "cemetery"
spawn_point = "entrance"
transition_name = "Cemetery Entrance"
```

Alternatively, you can instance the template at `scenes/world/locations/cemetery_entrance_example.tscn`.

### 2. Add Spawn Points

Each scene should have spawn points where players appear when entering:

1. Add a Marker2D node to your scene
2. Add the Marker2D to the "spawn_point" group
3. Attach the `spawn_point.gd` script to it
4. Set these exported variables:
   - `spawn_id`: Name of this spawn point (matching with transition.spawn_point)
   - `spawn_direction`: Direction player will face when spawning here
   - `is_default`: Set to true for the main spawn point

Example:
```gdscript
[node name="EntranceSpawn" type="Marker2D" groups=["spawn_point"]]
script = ExtResource("1_4aqyh")  # spawn_point.gd
spawn_id = "entrance"
spawn_direction = Vector2(0, 1)
is_default = true
```

### 3. Using Fast Travel in Dialogue

To add fast travel options to NPC dialogue, use `fast_travel.dialogue` as a template. Example:

```gdscript
~ start

NPC: Do you need to travel somewhere else?
- Yes, I'd like to go somewhere else.
  set locations = FastTravelSystem.get_available_locations()
  NPC: Where would you like to go?
  - {{ locations[0].name if locations.size() > 0 else "No locations available" }}
	do FastTravelSystem.fast_travel(locations[0].id) if locations.size() > 0
	=> END
  - I'll stay here.
	NPC: As you wish.
	=> END
- No, I'll stay here.
  NPC: Very well.
  => END

=> END
```

## Scene Structure Tips

1. The player node should be in the "player" group
2. Each scene should have at least one spawn point with is_default=true
3. Reciprocal transitions should exist (if you can go A→B, also add B→A)
4. Player state (position, direction) is automatically preserved

## Notes for Current Scenes

The following need to be updated in the Godot editor:

1. **Add the spawn_point.gd script to marker nodes**:
   - In campus_quad.tscn:
	 - CampusQuadSpawn (Marker2D)
	 - CemeteryExitSpawn (Marker2D)
   - In cemetery.tscn:
	 - EntranceSpawn (Marker2D)
   
   You can either add the script manually or instance the spawn_point_sample.tscn.

2. **Fix transition nodes to use location_transition.gd**:
   
   The current scene transitions have incorrect scripts:
   - In campus_quad.tscn, the CemeteryTransition node is using microscope.gd
   - In cemetery.tscn, the CampusExitPoint node is using cemetery.gd
   
   You have two options to fix this:
   
   **Option 1: Replace with pre-made transitions**
   
   Delete the current transition nodes and instance these scenes:
   - In campus_quad.tscn: Instance "scenes/transitions/campus_to_cemetery.tscn"
   - In cemetery.tscn: Instance "scenes/transitions/cemetery_to_campus.tscn"
   
   **Option 2: Change the scripts manually**
   
   - Select each transition node
   - In the Inspector, clear the current script
   - Add the location_transition.gd script
   - Set the required properties (target_location, spawn_point, etc.)

For the Marker2D nodes, you can:
1. Select the node
2. In the Inspector, click the "Script" dropdown
3. Choose "Load" and select scripts/world/spawn_point.gd
4. Configure the spawn_id and is_default properties

For Area2D transition nodes:
1. Select the node
2. In the Inspector, change the Script property to location_transition.gd
3. Configure target_location, spawn_point, etc. properties

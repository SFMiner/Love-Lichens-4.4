Last updates Jun 1. 2025, 13:58

res://
  ├── addons/
  │   ├── dialogue_balloon.gd
  │   ├── dialogue_manager/
  │   │   ├── DialogueManager.cs
  │   │   ├── compiler/
  │   │   ├── components/
  │   │   ├── example_balloon/
  │   │   ├── l10n/
  │   │   ├── utilities/
  │   │   └── views/
  │   ├── sound_manager/
  │   │   ├── SoundManager.cs
  │   │   ├── ambient_sounds.gd
  │   │   ├── music.gd
  │   │   ├── sound_effects.gd
  │   │   └── sound_manager.gd
  │   └── story_web/
  │       ├── graph_connection.gd
  │       ├── graph_node.gd
  │       ├── icons/
  │       ├── story_web_editor.tscn
  │       ├── story_web_plugin.gd
  │       ├── story_web_system.gd
  │       └── story_web_ui.gd
  ├── assets/
  │   ├── character_sprites/
  │   │   ├── Dusty/
  │   │   ├── Erik/
  │   │   ├── Fate/
  │   │   ├── Li/
  │   │   ├── Poison/
  │   │   ├── ProfessorMoss/
  │   │   ├── adam/
  │   │   ├── iris_bookwright/
  │   │   ├── kitty/
  │   │   └── professor_moss/
  │   ├── fonts/
  │   │   ├── bainsley/
  │   │   ├── bored_in_science/
  │   │   ├── cat_cafe/
  │   │   ├── cup_of_sea/
  │   │   ├── earthy/
  │   │   ├── ff-path-spect/
  │   │   ├── jagged_dreams/
  │   │   ├── medieval_sharp_tool/
  │   │   ├── numb_bunny/
  │   │   ├── quango/
  │   │   ├── really_free/
  │   │   ├── rough_dusty_chalk/
  │   │   ├── street_humoresque/
  │   │   └── wiffles/
  │   ├── icons/
  │   │   ├── defeated_icon.png
  │   │   ├── movement_marker.png
  │   │   ├── phone/
  │   │   ├── retreating_icon.png
  │   │   ├── status_icon.png
  │   │   └── target_icon.png
  │   ├── images/
  │   │   ├── items/
  │   │   ├── microscope.png
  │   │   ├── nature/
  │   │   ├── portraits/
  │   │   ├── scenes/
  │   │   └── ui/
  │   ├── sprites/
  │   │   ├── character_animations.res
  │   │   ├── insects/
  │   │   └── various sprite files...
  │   └── tilesets/
  │       ├── 1_Room_Builder_Office/
  │       ├── 2_Modern_Office_Black_Shadow/
  │       ├── 3_Modern_Office_Shadowless/
  │       ├── floors/
  │       ├── nature full/
  │       └── various tileset files...
  ├── contrib/
  │   ├── gdformat-plugin/
  │   └── gut/
  ├── data/
  │   ├── characters/
  │   │   ├── dusty.json
  │   │   ├── erik.json
  │   │   ├── fate.json
  │   │   ├── iris_bookwright.json
  │   │   ├── kitty.json
  │   │   ├── li.json
  │   │   ├── poison.json
  │   │   └── professor_moss.json
  │   ├── dialogues/
  │   │   ├── Poison.dialog
  │   │   ├── cutscene_test.dialogue
  │   │   ├── dorm_room.dialogue
  │   │   ├── dusty.dialogue
  │   │   ├── erik.dialogue
  │   │   ├── fate.dialogue
  │   │   ├── headstones.dialogue
  │   │   ├── iris_bookwright.dialogue
  │   │   ├── kitty.dialogue
  │   │   ├── li.dialogue
  │   │   ├── library_interactables.dialogue
  │   │   ├── poison.dialogue
  │   │   ├── professor_moss.dialogue
  │   │   └── various dialogue files...
  │   ├── generated/
  │   │   └── memory_tag_registry.json
  │   ├── grades/
  │   │   └── year1_sem1_grades.json
  │   ├── items/
  │   │   └── item_templates.json
  │   ├── memories/
  │   │   ├── individual_memories.json
  │   │   └── poison.json
  │   └── quests/
  │       ├── intro_quest.json
  │       └── lichen_collection.json
  ├── scenes/
  │   ├── game.tscn
  │   ├── game_scene_logic.gd
  │   ├── main_menu.tscn
  │   ├── npc.tscn
  │   ├── passage_collision.tscn
  │   ├── pickups/
  │   │   └── pickup_item.tscn
  │   ├── player.tscn
  │   ├── tests/
  │   │   └── TestPhoneScene.tscn
  │   ├── transitions/
  │   │   ├── campus_to_cemetery.tscn
  │   │   ├── campus_to_forest.tscn
  │   │   └── cemetery_to_campus.tscn
  │   ├── ui/
  │   │   ├── combat/
  │   │   │   ├── combat_ui.tscn
  │   │   │   ├── construct_enemy.tscn
  │   │   │   └── opponent_entry.tscn
  │   │   ├── dialog_panel.tscn
  │   │   ├── dialogue_balloon/
  │   │   │   └── dialogue_balloon.tscn
  │   │   ├── inventory_item_slot.tscn
  │   │   ├── inventory_panel.tscn
  │   │   ├── inventory_tooltip.tscn
  │   │   ├── notification_system.tscn
  │   │   ├── pause_menu.tscn
  │   │   ├── phone/
  │   │   │   ├── PhoneScene.gd
  │   │   │   └── PhoneScene.tscn
  │   │   ├── quest_panel.tscn
  │   │   ├── sleep_interface.tscn
  │   │   └── time_display.tscn
  │   └── world/
  │       ├── Butterfly.tscn
  │       ├── bee_area.tscn
  │       ├── cutscene_marker.tscn
  │       ├── insect.tscn
  │       ├── insect_manager.tscn
  │       ├── locations/
  │       │   ├── campus_quad.tscn
  │       │   ├── campus_quad_nographics.tscn
  │       │   ├── cemetery.tscn
  │       │   ├── cemetery_entrance.tscn
  │       │   ├── door_transition.tscn
  │       │   ├── dorm_room.tscn
  │       │   ├── library.tscn
  │       │   ├── old_growth_forest.tscn
  │       │   ├── permaculture_garden.tscn
  │       │   ├── research_lab.tscn
  │       │   └── spawn_point.tscn
  │       └── movement_marker.tscn
  ├── scripts/
  │   ├── autoload/
  │   │   ├── character_data.gd
  │   │   ├── character_data_loader.gd
  │   │   ├── character_font_manager.gd
  │   │   ├── cutscene_manager.gd
  │   │   ├── dialog_memory_extension.gd
  │   │   ├── dialog_system.gd
  │   │   ├── fast_travel_system.gd
  │   │   ├── game_controller.gd
  │   │   ├── game_state.gd
  │   │   ├── icon_system.gd
  │   │   ├── inventory_system.gd
  │   │   ├── item_effects_system.gd
  │   │   ├── look_at_system.gd
  │   │   ├── memory_system.gd
  │   │   ├── navigation_manager.gd
  │   │   ├── quest_debug_commands.gd
  │   │   ├── quest_system.gd
  │   │   ├── relationship_system.gd
  │   │   ├── resources/
  │   │   │   ├── memory_chain.gd
  │   │   │   ├── memory_discovery.gd
  │   │   │   └── memory_trigger.gd
  │   │   ├── save_load_system.gd
  │   │   └── time_system.gd
  │   ├── combat/
  │   │   ├── combat_initializer.gd
  │   │   ├── combat_manager.gd
  │   │   ├── combat_manager_setup.gd
  │   │   ├── combat_ui.gd
  │   │   ├── combatant.gd
  │   │   ├── combatant_enemy.gd
  │   │   ├── construct_combatant.gd
  │   │   ├── construct_enemy.gd
  │   │   └── construct_spawner.gd
  │   ├── pickups/
  │   │   └── pickup_item.gd
  │   ├── player/
  │   │   ├── player.gd
  │   │   └── player_combatant.gd
  │   ├── tools/
  │   │   └── memory_tag_linter.gd
  │   ├── ui/
  │   │   ├── combat/
  │   │   │   └── opponent_entry.gd
  │   │   ├── dialog_panel.gd
  │   │   ├── inventory_item_icons.gd
  │   │   ├── inventory_item_slot.gd
  │   │   ├── inventory_panel.gd
  │   │   ├── inventory_tooltip.gd
  │   │   ├── main_menu.gd
  │   │   ├── movement_marker.gd
  │   │   ├── notification_system.gd
  │   │   ├── pause_menu.gd
  │   │   ├── quest_panel.gd
  │   │   ├── sleep_interface.gd
  │   │   └── time_display.gd
  │   └── world/
  │       ├── Main_bug.gd
  │       ├── campus_quad.gd
  │       ├── cemetery.gd
  │       ├── character_animator.gd
  │       ├── combat_trigger.gd
  │       ├── cutcene_marker.gd
  │       ├── dorm_room.gd
  │       ├── insect.gd
  │       ├── insect_manager.gd
  │       ├── interactable.gd
  │       ├── interaction_agent.gd
  │       ├── lab_cat.gd
  │       ├── library.gd
  │       ├── location_transition.gd
  │       ├── message_board_new.gd
  │       ├── microscope.gd
  │       ├── movement_marker.gd
  │       ├── npc.gd
  │       ├── npc_combatant.gd
  │       ├── old_growth_forest.gd
  │       └── research_lab.gd
  ├── CLAUDE.md
  ├── icon.svg
  ├── project.godot
  └── Various documentation files (README.md, design documents, etc.)

  This schematic represents the current state of the project's directory structure, showing the organization of files and folders without opening the files themselves.

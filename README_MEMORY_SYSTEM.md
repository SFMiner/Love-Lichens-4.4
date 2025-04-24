# Memory Discovery System Documentation

The Memory Discovery System allows players to organically discover personal stories and memories through observation and dialogue. This document explains how to use and expand this system.

## Core Components

1. **Memory Triggers** - Events that unlock memories when specific conditions are met
2. **Memory Chains** - Sequences of related memories that tell a complete story
3. **Observable Features** - Visual elements on characters/objects that players can notice
4. **Tag System** - Persistent tracking of player discoveries and story progression

## Usage

### Adding Observable Features to NPCs

NPCs can have observable features that players can notice:

```gdscript
# In your NPC scene script
func _ready():
    # Add observable features
    add_observable_feature("necklace", "Poison's wearing a small metal vial necklace.")
    add_observable_feature("tattoo", "A small botanical illustration is tattooed on their wrist.")
```

### Creating Memory Data Files

Memory chains are defined in JSON files located in `data/memories/`. Each character can have their own file.

Example JSON structure:
```json
[
  {
    "id": "character_memory_chain",
    "character_id": "CharacterName",
    "relationship_reward": 10,
    "completed_tag": "memory_chain_completed",
    "steps": [
      {
        "id": "notice_feature",
        "trigger_type": 0, // LOOK_AT = 0
        "target_id": "CharacterName_feature",
        "unlock_tag": "feature_seen",
        "description": "Description text shown when discovered",
        "condition_tags": []
      },
      {
        "id": "ask_about_feature",
        "trigger_type": 3, // DIALOGUE_CHOICE = 3
        "target_id": "ask_feature_dialogue_id",
        "unlock_tag": "feature_discussed",
        "description": "Response from character",
        "condition_tags": ["feature_seen"]
      }
    ]
  }
]
```

### Adding Conditional Dialogue

In dialogue files, you can use tag checks to conditionally show dialogue options:

```
~ start
Character: Hello there!

- Normal option
  Character: Normal response
  => END
- [if DialogSystem.can_unlock("feature_seen")] Ask about the thing you noticed
  Character: Oh, you noticed that?
  do DialogSystem.unlock_memory("feature_discussed")
  => END
```

### Trigger Types

The memory system supports various trigger types:

- `LOOK_AT` (0): Triggered when player observes a specific feature
- `ITEM_ACQUIRED` (1): Triggered when player obtains a specific item
- `LOCATION_VISITED` (2): Triggered when player visits a location
- `DIALOGUE_CHOICE` (3): Triggered when player selects a dialogue option
- `QUEST_COMPLETED` (4): Triggered when a quest is completed
- `CHARACTER_RELATIONSHIP` (5): Triggered when relationship level changes

## Integration with Other Systems

The Memory System integrates with:

- **Dialogue System**: For conditional dialogue options based on discoveries
- **Quest System**: For quest objectives based on memory discovery
- **Relationship System**: To award relationship points for memory discoveries

## Example Test Quest

See `data/memories/poison.json` and `data/dialogues/poison_memories.dialogue` for a complete example of the "Memories in the Thread" quest.

## Dev Commands

For debugging purposes, you can use:

```
# In-game console
memory_list                # Lists all memory chains
memory_set [tag]           # Manually sets a memory tag
memory_trigger [type] [id] # Manually triggers a memory
memory_reset               # Resets all memory progress
```
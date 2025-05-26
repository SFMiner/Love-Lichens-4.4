extends Node

# Main logic for the game.tscn scene.
# This script can interact with the GameController autoload globally (e.g., GameController.some_method())
# and manage the child nodes of game.tscn.

func _ready():
    print("game.tscn main logic ready.")
    # Example: Accessing the autoload GameController
    # if GameController:
    #     GameController.perform_some_initialization_if_needed()
    pass

# Add other game scene specific logic here if needed in the future.

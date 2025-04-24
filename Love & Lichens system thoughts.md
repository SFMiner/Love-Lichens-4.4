Here's a comprehensive compilation of all the latest versions of the game systems we've discussed for your "Love & Lichens" RPG:

gdscript  
Copy  
\# Main Game Controller  
extends Node

\# Global game state  
var player\_data \= {  
	"name": "",  
	"stats": {  
		"charisma": 5,  
		"knowledge": 5,  
		"creativity": 5  
	},  
	"currency": 100  
}

\# Game systems  
var inventory\_system  
var relationship\_system  
var dialog\_system  
var combat\_system  
var quest\_system  
var special\_events\_system  
var world\_controller  
var magic\_system

func \_ready():  
	\# Initialize systems  
	inventory\_system \= $InventorySystem  
	relationship\_system \= $RelationshipSystem  
	dialog\_system \= $DialogSystem  
	combat\_system \= $CombatSystem  
	quest\_system \= $QuestSystem  
	special\_events\_system \= $SpecialEventsSystem  
	world\_controller \= $WorldController  
	magic\_system \= $MagicSystem  
	  
	\# Connect signals between systems  
	inventory\_system.connect("item\_used", self, "\_on\_item\_used")  
	dialog\_system.connect("dialog\_choice\_made", self, "\_on\_dialog\_choice")  
	combat\_system.connect("combat\_ended", self, "\_on\_combat\_ended")  
	quest\_system.connect("quest\_completed", self, "\_on\_quest\_completed")  
	special\_events\_system.connect("special\_event\_completed", self, "\_on\_special\_event\_completed")  
	magic\_system.connect("power\_used", self, "\_on\_power\_used")

func \_on\_item\_used(item\_id, target):  
	\# Handle effects of using items \- might affect relationships, combat, etc.  
	pass

func \_on\_dialog\_choice(choice\_id, npc\_id):  
	\# Handle effects of dialog choices  
	\# Might affect relationships, inventory, quests  
	relationship\_system.update\_relationship(npc\_id, choice\_id)  
	pass

func \_on\_combat\_ended(result):  
	\# Handle outcomes of combat encounters  
	pass

func \_on\_quest\_completed(quest\_id, rewards):  
	\# Apply quest rewards  
	pass

func \_on\_special\_event\_completed(event\_id):  
	\# Handle event completion  
	pass

func \_on\_power\_used(power\_id, target, effect):  
	\# Handle effects of using magical powers  
	pass

func save\_game():  
	\# Logic to serialize game state to disk  
	pass

func load\_game():  
	\# Logic to deserialize game state from disk  
	pass  
gdscript  
Copy  
\# Inventory System  
extends Node

signal item\_used(item\_id, target)  
signal item\_added(item\_id, quantity)  
signal item\_removed(item\_id, quantity)

\# Store items as dictionary with quantities  
var items \= {}

\# Item definitions \- could be loaded from a JSON/CSV file  
var item\_database \= {  
	"field\_notebook": {  
		"name": "Field Notebook",  
		"description": "For documenting your scientific observations",  
		"icon": "res://assets/icons/notebook.png",  
		"usable": true,  
		"effect": "knowledge\_boost"  
	},  
	"friendship\_bracelet": {  
		"name": "Friendship Bracelet",  
		"description": "A handmade token of affection",  
		"icon": "res://assets/icons/bracelet.png",  
		"usable": true,  
		"effect": "relationship\_boost"  
	},  
	"rare\_lichen\_sample": {  
		"name": "Rare Lichen Sample",  
		"description": "A specimen of a previously undocumented lichen",  
		"icon": "res://assets/icons/lichen.png",  
		"usable": true,  
		"effect": "special\_dialog"  
	},  
	"debate\_trophy": {  
		"name": "Debate Trophy",  
		"description": "Evidence of your rhetorical prowess",  
		"icon": "res://assets/icons/trophy.png",  
		"usable": false  
	},  
	"water\_testing\_kit": {  
		"name": "Water Testing Kit",  
		"description": "Used to analyze water quality",  
		"icon": "res://assets/icons/test\_kit.png",  
		"usable": true,  
		"effect": "water\_analysis"  
	}  
	\# More items...  
}

func add\_item(item\_id, quantity \= 1):  
	if item\_id in item\_database:  
		if item\_id in items:  
			items\[item\_id\] \+= quantity  
		else:  
			items\[item\_id\] \= quantity  
		emit\_signal("item\_added", item\_id, quantity)  
		return true  
	return false

func remove\_item(item\_id, quantity \= 1):  
	if item\_id in items:  
		if items\[item\_id\] \>= quantity:  
			items\[item\_id\] \-= quantity  
			if items\[item\_id\] \<= 0:  
				items.erase(item\_id)  
			emit\_signal("item\_removed", item\_id, quantity)  
			return true  
	return false

func use\_item(item\_id, target \= null):  
	if item\_id in items and item\_database\[item\_id\]\["usable"\]:  
		var effect \= item\_database\[item\_id\]\["effect"\]  
		emit\_signal("item\_used", item\_id, target)  
		remove\_item(item\_id, 1\)  
		return true  
	return false

func get\_item\_info(item\_id):  
	if item\_id in item\_database:  
		return item\_database\[item\_id\]  
	return null  
gdscript  
Copy  
\# Relationship System  
extends Node

\# Relationship status enum  
enum RelationshipStatus {  
	STRANGER,  
	ACQUAINTANCE,  
	FRIEND,  
	CLOSE\_FRIEND,  
	ROMANTIC  
}

\# Stores relationship values with each NPC  
var relationships \= {}

\# NPC database with default values  
var npc\_database \= {  
	"professor\_moss": {  
		"name": "Professor Moss",  
		"default\_status": RelationshipStatus.STRANGER,  
		"interests": \["lichens", "ecology", "poetry"\],  
		"dislikes": \["pollution", "deforestation"\]  
	},  
	"luna\_meadows": {  
		"name": "Luna Meadows",  
		"default\_status": RelationshipStatus.ACQUAINTANCE,  
		"interests": \["mushrooms", "art", "sustainability"\],  
		"dislikes": \["corporate agriculture", "plastic waste"\]  
	},  
	"river\_stone": {  
		"name": "River Stone",  
		"default\_status": RelationshipStatus.STRANGER,  
		"interests": \["water conservation", "kayaking", "local politics"\],  
		"dislikes": \["water pollution", "industrial farming"\]  
	},  
	"drama\_club\_president": {  
		"name": "Alex Winters",  
		"default\_status": RelationshipStatus.STRANGER,  
		"interests": \["theater", "climate activism", "public speaking"\],  
		"dislikes": \["apathy", "censorship"\]  
	},  
	"performance\_artist": {  
		"name": "Jade Rivers",  
		"default\_status": RelationshipStatus.STRANGER,  
		"interests": \["performance art", "ecology", "urban gardening"\],  
		"dislikes": \["conventional thinking", "corporate art"\]  
	},  
	"environmental\_activist": {  
		"name": "Sam Greene",  
		"default\_status": RelationshipStatus.STRANGER,  
		"interests": \["direct action", "community organizing", "permaculture"\],  
		"dislikes": \["greenwashing", "political inaction"\]  
	},  
	"corporate\_exec": {  
		"name": "Vincent Sterling",  
		"default\_status": RelationshipStatus.STRANGER,  
		"interests": \["profit margins", "development", "reputation management"\],  
		"dislikes": \["regulations", "protests", "bad press"\]  
	},  
	"skeptical\_student": {  
		"name": "Taylor Brooks",  
		"default\_status": RelationshipStatus.ACQUAINTANCE,  
		"interests": \["debate", "critical thinking", "technology"\],  
		"dislikes": \["unquestioned beliefs", "pseudoscience"\]  
	},  
	"nature\_guide": {  
		"name": "Robin Fields",  
		"default\_status": RelationshipStatus.STRANGER,  
		"interests": \["wildlife tracking", "plant identification", "outdoor education"\],  
		"dislikes": \["habitat destruction", "invasive species"\]  
	},  
	"philosophy\_student": {  
		"name": "Morgan Lee",  
		"default\_status": RelationshipStatus.STRANGER,  
		"interests": \["environmental ethics", "philosophical debates", "literature"\],  
		"dislikes": \["moral relativism", "anthropocentrism"\]  
	}  
	\# More NPCs...  
}

func \_ready():  
	\# Initialize all relationships to their default values  
	for npc\_id in npc\_database:  
		relationships\[npc\_id\] \= {  
			"status": npc\_database\[npc\_id\]\["default\_status"\],  
			"value": 0, \# Numerical value within the current status level  
			"interactions": \[\], \# Could log history of interactions  
			"nemesis\_level": 0 \# 0 means not a nemesis  
		}

func get\_relationship\_status(npc\_id):  
	if npc\_id in relationships:  
		return relationships\[npc\_id\]\["status"\]  
	return RelationshipStatus.STRANGER

func update\_relationship(npc\_id, change\_value):  
	if npc\_id in relationships:  
		relationships\[npc\_id\]\["value"\] \+= change\_value  
		  
		\# Check if we should upgrade/downgrade the relationship status  
		var current\_value \= relationships\[npc\_id\]\["value"\]  
		var current\_status \= relationships\[npc\_id\]\["status"\]  
		  
		\# Thresholds for status changes  
		if current\_value \>= 100 and current\_status \< RelationshipStatus.ROMANTIC:  
			relationships\[npc\_id\]\["status"\] \= current\_status \+ 1  
			relationships\[npc\_id\]\["value"\] \= 0  
		elif current\_value \<= \-50 and current\_status \> RelationshipStatus.STRANGER:  
			relationships\[npc\_id\]\["status"\] \= current\_status \- 1  
			relationships\[npc\_id\]\["value"\] \= 0  
		  
		return true  
	return false

func get\_relationship\_description(npc\_id):  
	if npc\_id in relationships:  
		var status \= relationships\[npc\_id\]\["status"\]  
		var name \= npc\_database\[npc\_id\]\["name"\]  
		  
		match status:  
			RelationshipStatus.STRANGER:  
				return "You barely know " \+ name  
			RelationshipStatus.ACQUAINTANCE:  
				return name \+ " is an acquaintance"  
			RelationshipStatus.FRIEND:  
				return name \+ " is your friend"  
			RelationshipStatus.CLOSE\_FRIEND:  
				return name \+ " is a close friend"  
			RelationshipStatus.ROMANTIC:  
				return "You and " \+ name \+ " are romantically involved"  
	return "Unknown relationship"

func log\_interaction(npc\_id, interaction\_type, details):  
	if npc\_id in relationships:  
		relationships\[npc\_id\]\["interactions"\].append({  
			"type": interaction\_type,  
			"details": details,  
			"timestamp": OS.get\_unix\_time()  
		})

func get\_nemesis\_list():  
	var nemesis\_results \= \[\]  
	  
	for npc\_id in relationships:  
		if relationships\[npc\_id\]\["status"\] \== RelationshipStatus.STRANGER and relationships\[npc\_id\]\["value"\] \< \-50:  
			nemesis\_results.append(npc\_id)  
	  
	return nemesis\_results

func is\_nemesis(npc\_id):  
	return npc\_id in get\_nemesis\_list()

func become\_nemesis(npc\_id):  
	if npc\_id in relationships:  
		relationships\[npc\_id\]\["status"\] \= RelationshipStatus.STRANGER  
		relationships\[npc\_id\]\["value"\] \= \-60  
		relationships\[npc\_id\]\["nemesis\_level"\] \= 1  
		return true  
	return false

func upgrade\_nemesis(npc\_id):  
	if npc\_id in relationships and "nemesis\_level" in relationships\[npc\_id\]:  
		relationships\[npc\_id\]\["nemesis\_level"\] \+= 1  
		relationships\[npc\_id\]\["value"\] \-= 10  
		return relationships\[npc\_id\]\["nemesis\_level"\]  
	return 0  
gdscript  
Copy  
\# Dialog System  
extends Node

signal dialog\_started(npc\_id)  
signal dialog\_ended(npc\_id)  
signal dialog\_choice\_made(choice\_id, npc\_id)

\# Current dialog state  
var current\_npc \= null  
var current\_dialog \= null  
var current\_node \= null

\# Dialog database structure  
\# This could be loaded from JSON files for easier editing  
var dialog\_database \= {  
	"professor\_moss": {  
		"intro": {  
			"text": "Ah, another eager student of environmental science\! What can I help you with today?",  
			"portrait": "res://assets/portraits/professor\_moss.png",  
			"choices": \[  
				{  
					"text": "I'm interested in learning more about lichens.",  
					"next\_node": "lichen\_topic",  
					"effects": {  
						"relationship": 5  
					}  
				},  
				{  
					"text": "Nothing right now, just saying hello.",  
					"next\_node": "casual\_greeting",  
					"effects": {  
						"relationship": 2  
					}  
				},  
				{  
					"text": "I heard you're assigning a difficult project soon...",  
					"next\_node": "project\_concern",  
					"effects": {  
						"relationship": \-2  
					}  
				}  
			\]  
		},  
		"lichen\_topic": {  
			"text": "Excellent\! Lichens are fascinating symbiotic organisms...",  
			"portrait": "res://assets/portraits/professor\_moss\_happy.png",  
			"choices": \[  
				{  
					"text": "Can you tell me more about their ecological importance?",  
					"next\_node": "lichen\_ecology",  
					"effects": {  
						"relationship": 5,  
						"player\_stats": {"knowledge": 1}  
					}  
				},  
				{  
					"text": "I should get going, but thanks for the information.",  
					"next\_node": "end",  
					"effects": {}  
				}  
			\]  
		},  
		\# More dialog nodes...  
	},  
	"luna\_meadows": {  
		"intro": {  
			"text": "Hey there\! Beautiful day to appreciate the interconnectedness of all living things, isn't it?",  
			"portrait": "res://assets/portraits/luna\_meadows.png",  
			"choices": \[  
				{  
					"text": "Absolutely\! I was just admiring the mushrooms growing near that tree.",  
					"next\_node": "mushroom\_enthusiasm",  
					"effects": {  
						"relationship": 8  
					}  
				},  
				{  
					"text": "I guess so. What are you up to?",  
					"next\_node": "neutral\_response",  
					"effects": {  
						"relationship": 2  
					}  
				},  
				{  
					"text": "Actually, I was looking for you. I heard you know a lot about fungi.",  
					"next\_node": "fungi\_knowledge",  
					"effects": {  
						"relationship": 5  
					}  
				}  
			\]  
		},  
		\# More dialog nodes...  
	}  
	\# More NPCs...  
}

func start\_dialog(npc\_id):  
	if npc\_id in dialog\_database:  
		current\_npc \= npc\_id  
		current\_dialog \= dialog\_database\[npc\_id\]  
		current\_node \= "intro"  
		emit\_signal("dialog\_started", npc\_id)  
		return get\_current\_dialog\_node()  
	return null

func get\_current\_dialog\_node():  
	if current\_dialog \!= null and current\_node in current\_dialog:  
		return current\_dialog\[current\_node\]  
	return null

func make\_choice(choice\_index):  
	var node \= get\_current\_dialog\_node()  
	if node \!= null and choice\_index \< node\["choices"\].size():  
		var choice \= node\["choices"\]\[choice\_index\]  
		  
		\# Apply effects from the choice  
		if "effects" in choice:  
			var effects \= choice\["effects"\]  
			  
			\# Handle relationship changes  
			if "relationship" in effects:  
				\# This is where we'd call the relationship system  
				emit\_signal("dialog\_choice\_made", effects\["relationship"\], current\_npc)  
			  
			\# Handle inventory changes  
			if "inventory" in effects:  
				for item\_id in effects\["inventory"\]:  
					var quantity \= effects\["inventory"\]\[item\_id\]  
					\# Add or remove items based on quantity  
					\# This is where we'd call the inventory system  
			  
			\# Handle player stat changes  
			if "player\_stats" in effects:  
				for stat in effects\["player\_stats"\]:  
					\# This is where we'd update player stats  
					pass  
		  
		\# Move to the next dialog node  
		current\_node \= choice\["next\_node"\]  
		  
		\# Check if dialog is ending  
		if current\_node \== "end":  
			var npc \= current\_npc  
			current\_npc \= null  
			current\_dialog \= null  
			current\_node \= null  
			emit\_signal("dialog\_ended", npc)  
			return null  
		  
		return get\_current\_dialog\_node()  
	return null  
gdscript  
Copy  
\# Environmental Debate Combat System  
extends Node

signal combat\_started(opponent\_id, context)  
signal combat\_ended(result)  
signal turn\_started(is\_player\_turn)  
signal action\_performed(performer, action, target, effect)

\# Combat state  
var in\_combat \= false  
var player\_turn \= true  
var opponent \= null  
var player\_resolve \= 100  
var opponent\_resolve \= 100

\# Combat context enum  
enum CombatContext {  
	STANDARD,  
	THEATRICAL,  
	CLASSROOM,  
	RALLY,  
	FORMAL\_DEBATE  
}

var current\_context \= CombatContext.STANDARD

\# Standard moves for everyday debates  
var move\_database \= {  
	"logical\_argument": {  
		"name": "Logical Argument",  
		"description": "Present a reasoned case supported by evidence",  
		"base\_effect": 15,  
		"stat\_modifier": "knowledge",  
		"animation": "thinking\_animation"  
	},  
	"passionate\_appeal": {  
		"name": "Passionate Appeal",  
		"description": "Make an emotional plea for environmental stewardship",  
		"base\_effect": 12,  
		"stat\_modifier": "charisma",  
		"animation": "gesturing\_animation"  
	},  
	"scientific\_evidence": {  
		"name": "Scientific Evidence",  
		"description": "Share research data supporting your position",  
		"base\_effect": 18,  
		"stat\_modifier": "knowledge",  
		"animation": "research\_animation"  
	},  
	"personal\_anecdote": {  
		"name": "Personal Anecdote",  
		"description": "Share a personal story that illustrates your point",  
		"base\_effect": 10,  
		"stat\_modifier": "charisma",  
		"animation": "storytelling\_animation"  
	},  
	"compromise\_proposal": {  
		"name": "Compromise Proposal",  
		"description": "Suggest a middle ground that meets both parties' needs",  
		"base\_effect": 8,  
		"stat\_modifier": "creativity",  
		"animation": "brainstorming\_animation"  
	}  
	\# More standard moves...  
}

\# Theatrical special moves \- available in specific contexts  
var theatrical\_moves \= {  
	"dramatic\_monologue": {  
		"name": "Dramatic Monologue",  
		"description": "Deliver a passionate speech about environmental ethics",  
		"base\_effect": 25,  
		"stat\_modifier": "charisma",  
		"animation": "monologue\_animation",  
		"unlocked": false,  
		"associated\_npcs": \["professor\_moss", "drama\_club\_president"\]  
	},  
	"interpretive\_dance": {  
		"name": "Interpretive Dance",  
		"description": "Express the interconnectedness of ecosystems through movement",  
		"base\_effect": 30,  
		"stat\_modifier": "creativity",  
		"animation": "dance\_animation",  
		"unlocked": false,  
		"associated\_npcs": \["luna\_meadows", "performance\_artist"\]  
	},  
	"lichen\_facts": {  
		"name": "Lichen Facts",  
		"description": "Overwhelm your opponent with fascinating lichen trivia",  
		"base\_effect": 22,  
		"stat\_modifier": "knowledge",  
		"animation": "fact\_animation",  
		"unlocked": false,  
		"associated\_npcs": \["professor\_moss", "nature\_guide"\]  
	},  
	"ethical\_argument": {  
		"name": "Ethical Argument",  
		"description": "Present a compelling case for environmental stewardship",  
		"base\_effect": 20,  
		"stat\_modifier": "knowledge",  
		"animation": "argument\_animation",  
		"unlocked": false,  
		"associated\_npcs": \["environmental\_activist", "philosophy\_student"\]  
	}  
	\# More theatrical moves...  
}

\# Opponent database  
var opponent\_database \= {  
	"corporate\_exec": {  
		"name": "Corporate Executive",  
		"resolve": 80,  
		"weakness": "scientific\_evidence",  
		"strength": "personal\_anecdote",  
		"moves": \["economic\_argument", "legal\_threat", "dismissive\_remark"\],  
		"defeat\_reaction": "storming\_off",  
		"defeat\_dialog": "This isn't over\! Our legal team will be in touch.",  
		"nemesis\_potential": true  
	},  
	"skeptical\_student": {  
		"name": "Skeptical Student",  
		"resolve": 60,  
		"weakness": "passionate\_appeal",  
		"strength": "logical\_argument",  
		"moves": \["devil's\_advocate", "request\_for\_evidence", "sarcastic\_comment"\],  
		"defeat\_reaction": "grudging\_respect",  
		"defeat\_dialog": "Fine, you've made your point. I'll think about it.",  
		"nemesis\_potential": false  
	},  
	"drama\_club\_president": {  
		"name": "Drama Club President",  
		"resolve": 70,  
		"weakness": "scientific\_evidence",  
		"strength": "dramatic\_monologue",  
		"moves": \["theatrical\_flourish", "audience\_appeal", "emotional\_rhetoric"\],  
		"defeat\_reaction": "dramatic\_bow",  
		"defeat\_dialog": "An impressive performance\! You've won this round, but the show must go on\!",  
		"nemesis\_potential": false  
	},  
	"environmental\_activist": {  
		"name": "Environmental Activist",  
		"resolve": 75,  
		"weakness": "compromise\_proposal",  
		"strength": "passionate\_appeal",  
		"moves": \["moral\_argument", "dire\_warning", "call\_to\_action"\],  
		"defeat\_reaction": "respectful\_nod",  
		"defeat\_dialog": "Your points are valid. Perhaps we can work together on this issue.",  
		"nemesis\_potential": false  
	},  
	"philosophy\_student": {  
		"name": "Philosophy Student",  
		"resolve": 65,  
		"weakness": "personal\_anecdote",  
		"strength": "logical\_argument",  
		"moves": \["socratic\_questioning", "thought\_experiment", "conceptual\_analysis"\],  
		"defeat\_reaction": "thoughtful\_pause",  
		"defeat\_dialog": "Interesting... you've given me much to reflect upon.",  
		"nemesis\_potential": false  
	}  
	\# More opponents...  
}

\# Nemesis tracking  
var nemesis\_list \= {}

\# Function to get available moves based on context  
func get\_available\_moves():  
	var available\_moves \= {}  
	  
	\# Always include standard moves  
	for move\_id in move\_database:  
		available\_moves\[move\_id\] \= move\_database\[move\_id\]  
	  
	\# Add theatrical moves if context allows and they're unlocked  
	if current\_context \== CombatContext.THEATRICAL or current\_context \== CombatContext.RALLY:  
		for move\_id in theatrical\_moves:  
			if theatrical\_moves\[move\_id\]\["unlocked"\]:  
				available\_moves\[move\_id\] \= theatrical\_moves\[move\_id\]  
	  
	\# Add specific theatrical moves based on context and relationship  
	elif current\_context \== CombatContext.CLASSROOM:  
		\# In classroom, educational theatrical moves are appropriate  
		for move\_id in \["lichen\_facts", "ethical\_argument"\]:  
			if theatrical\_moves\[move\_id\]\["unlocked"\]:  
				available\_moves\[move\_id\] \= theatrical\_moves\[move\_id\]  
	  
	\# Check for NPC-specific moves  
	if opponent \!= null:  
		var relationship\_system \= get\_tree().get\_root().get\_node("GameController/RelationshipSystem")  
		  
		for move\_id in theatrical\_moves:  
			var move \= theatrical\_moves\[move\_id\]  
			if move\["unlocked"\] and "associated\_npcs" in move:  
				\# If this NPC appreciates this move specifically  
				if opponent\["name"\] in move\["associated\_npcs"\]:  
					available\_moves\[move\_id\] \= move  
				  
				\# Or if you have a good relationship with an NPC who uses this move  
				for npc\_id in move\["associated\_npcs"\]:  
					if relationship\_system.get\_relationship\_status(npc\_id) \>= relationship\_system.RelationshipStatus.FRIEND:  
						available\_moves\[move\_id\] \= move  
						break  
	  
	return available\_moves

func start\_combat(opponent\_id, context \= CombatContext.STANDARD):  
	if opponent\_id in opponent\_database:  
		opponent \= opponent\_database\[opponent\_id\].duplicate(true)  
		player\_resolve \= 100  
		opponent\_resolve \= opponent\["resolve"\]  
		in\_combat \= true  
		player\_turn \= true  
		current\_context \= context  
		emit\_signal("combat\_started", opponent\_id, context)  
		emit\_signal("turn\_started", player\_turn)  
		return true  
	return false

func perform\_player\_move(move\_id):  
	if in\_combat and player\_turn:  
		var move \= null  
		var available\_moves \= get\_available\_moves()  
		  
		if move\_id in available\_moves:  
			move \= available\_moves\[move\_id\]  
		  
		if move \!= null:  
			\# Calculate effect based on player stats and move properties  
			var effect \= move\["base\_effect"\]  
			  
			\# Apply modifiers (reference player stats)  
			if "stat\_modifier" in move:  
				var stat\_modifier \= move\["stat\_modifier"\]  
				var player\_data \= get\_tree().get\_root().get\_node("GameController").player\_data  
				effect \+= (player\_data\["stats"\]\[stat\_modifier\] \* 0.5)  
			  
			\# Check for opponent weakness/strength  
			if "weakness" in opponent and opponent\["weakness"\] \== move\_id:  
				effect \*= 1.5  
			elif "strength" in opponent and opponent\["strength"\] \== move\_id:  
				effect \*= 0.7  
			  
			\# Apply effect to opponent  
			opponent\_resolve \-= effect  
			  
			emit\_signal("action\_performed", "player", move\_id, "opponent", effect)  
			  
			\# Check for victory  
			if opponent\_resolve \<= 0:  
				end\_combat("victory")  
				return true  
			  
			\# Switch turns  
			player\_turn \= false  
			emit\_signal("turn\_started", player\_turn)  
			  
			\# Schedule opponent's move  
			call\_deferred("perform\_opponent\_move")  
			return true  
	return false

func perform\_opponent\_move():  
	if in\_combat and \!player\_turn:  
		\# Select a random move from opponent's move list  
		var move\_id \= opponent\["moves"\]\[randi() % opponent\["moves"\].size()\]  
		  
		\# Calculate effect (could be more sophisticated)  
		var effect \= 8 \+ (randi() % 8\)  
		  
		\# Apply effect to player  
		player\_resolve \-= effect  
		  
		emit\_signal("action\_performed", "opponent", move\_id, "player", effect)  
		  
		\# Check for defeat  
		if player\_resolve \<= 0:  
			end\_combat("defeat")  
			return  
		  
		\# Switch turns  
		player\_turn \= true  
		emit\_signal("turn\_started", player\_turn)  
	return

func end\_combat(result):  
	in\_combat \= false  
	  
	\# Handle nemesis potential  
	if opponent\["nemesis\_potential"\]:  
		if result \== "victory":  
			\# When defeated, they might become a nemesis  
			if not opponent\["name"\] in nemesis\_list:  
				nemesis\_list\[opponent\["name"\]\] \= {  
					"defeats": 1,  
					"level": 1,  
					"last\_seen": OS.get\_unix\_time()  
				}  
			else:  
				nemesis\_list\[opponent\["name"\]\]\["defeats"\] \+= 1  
				  
				\# Level up nemesis if defeated multiple times  
				if nemesis\_list\[opponent\["name"\]\]\["defeats"\] % 3 \== 0:  
					nemesis\_list\[opponent\["name"\]\]\["level"\] \+= 1  
			  
			\# Add to relationship system as a negative relationship  
			var relationship\_system \= get\_tree().get\_root().get\_node("GameController/RelationshipSystem")  
			relationship\_system.update\_relationship(opponent\["name"\], \-20)  
		elif result \== "defeat":  
			\# If they defeat you, they might gloat or come back stronger  
			if opponent\["name"\] in nemesis\_list:  
				nemesis\_list\[opponent\["name"\]\]\["victories"\] \= nemesis\_list\[opponent\["name"\]\].get("victories", 0\) \+ 1  
	  
	\# Show defeat/victory dialog  
	if result \== "victory":  
		\# Show opponent's defeat reaction  
		print(opponent\["defeat\_dialog"\])  
	else:  
		\# Show player defeat dialog  
		print("You've lost this argument, but you'll find a better approach\!")  
	  
	emit\_signal("combat\_ended", result)  
	  
	\# Handle rewards/consequences based on result  
	if result \== "victory":  
		\# Add rewards \- could give items, relationship boosts, etc.  
		\# Maybe get special item from the opponent  
		var inventory\_system \= get\_tree().get\_root().get\_node("GameController/InventorySystem")  
		inventory\_system.add\_item("debate\_trophy", 1\)  
	else:  
		\# Handle defeat \- maybe lose some items or get a relationship penalty  
		\# Nothing too punishing \- just encouragement to try again  
		pass

func unlock\_theatrical\_move(move\_id):  
	if move\_id in theatrical\_moves:  
		theatrical\_moves\[move\_id\]\["unlocked"\] \= true  
		return true  
	return false  
		  
func check\_for\_nemesis\_encounter():  
	\# This could be called when entering certain areas  
	\# Chance for a nemesis to reappear based on relationship status  
	  
	for nemesis\_name in nemesis\_list:  
		var nemesis \= nemesis\_list\[nemesis\_name\]  
		  
		\# Check if enough time has passed since last encounter  
		var time\_since\_last\_seen \= OS.get\_unix\_time() \- nemesis\["last\_seen"\]  
		if time\_since\_last\_seen \> 86400: \# One in-game day  
			\# Roll for chance of appearance  
			var chance \= 0.1 \* nemesis\["level"\] \# 10% per level  
			if randf() \<= chance:  
				\# Trigger a nemesis encounter\!  
				nemesis\["last\_seen"\] \= OS.get\_unix\_time()  
				return nemesis\_name  
	  
	return null

func get\_special\_moves\_for\_npc(npc\_id):  
	var available\_moves \= \[\]  
	var relationship\_system \= get\_tree().get\_root().get\_node("GameController/RelationshipSystem")  
	  
	for move\_id in theatrical\_moves:  
		if "associated\_npcs" in theatrical\_moves\[move\_id\] and npc\_id in theatrical\_moves\[move\_id\]\["associated\_npcs"\]:  
			if theatrical\_moves\[move\_id\]\["unlocked"\]:  
				available\_moves.append(move\_id)  
	  
	return available\_moves  
gdscript  
Copy  
\# Quest System with Environmental Focus  
extends Node

signal quest\_started(quest\_id)  
signal quest\_completed(quest\_id, rewards)  
signal quest\_failed(quest\_id)  
signal quest\_objective\_updated(quest\_id, objective\_id, progress)

\# Quest database  
var quest\_database \= {  
	"water\_quality\_study": {  
		"title": "Water Quality Crisis",  
		"description": "Investigate pollution in the campus lake and find the source",  
		"objectives": {  
			"collect\_samples": {  
				"description": "Collect water samples from 5 locations",  
				"type": "collection",  
				"target": 5,  
				"progress": 0  
			},  
			"analyze\_data": {  
				"description": "Analyze the samples in the lab",  
				"type": "interaction",  
				"target": "lab\_equipment",  
				"completed": false  
			},  
			"confront\_polluter": {  
				"description": "Present your findings to the responsible party",  
				"type": "dialog",  
				"target": "corporate\_exec",  
				"completed": false  
			}  
		},  
		"rewards": {  
			"items": {"water\_testing\_kit": 1, "research\_grant": 1},  
			"relationships": {"professor\_moss": 15, "river\_stone": 20},  
			"player\_stats": {"knowledge": 2}  
		}  
	},  
	"lichen\_biodiversity": {  
		"title": "Lichen Biodiversity Survey",  
		"description": "Document lichen species diversity in the old-growth forest",  
		"objectives": {  
			"photograph\_lichens": {  
				"description": "Photograph 10 different lichen species",  
				"type": "collection",  
				"target": 10,  
				"progress": 0  
			},  
			"identify\_species": {  
				"description": "Identify and catalog your findings",  
				"type": "minigame",  
				"target": "lichen\_identification",  
				"completed": false  
			},  
			"present\_research": {  
				"description": "Present your findings at the campus symposium",  
				"type": "theatrical\_combat",  
				"target": "skeptical\_student",  
				"completed": false  
			}  
		},  
		"rewards": {  
			"items": {"rare\_lichen\_sample": 1, "research\_publication": 1},  
			"relationships": {"luna\_meadows": 15, "professor\_moss": 10},  
			"player\_stats": {"creativity": 1, "knowledge": 1}  
		}  
	}  
	\# More quests...  
}

\# Player's active and completed quests  
var active\_quests \= {}  
var completed\_quests \= \[\]

\# Theatrical move quests  
var theatrical\_move\_quests \= {  
	"learn\_interpretive\_dance": {  
		"title": "The Language of Movement",  
		"description": "Luna Meadows believes ecological concepts can be communicated through dance. Learn her unique interpretive style.",  
		"objectives": {  
			"meet\_luna": {  
				"description": "Meet Luna in the campus garden",  
				"type": "location",  
				"target": "garden",  
				"completed": false  
			},  
			"learn\_basics": {  
				"description": "Learn the basic movements",  
				"type": "minigame",  
				"target": "dance\_minigame",  
				"completed": false  
			},  
			"perform\_dance": {  
				"description": "Perform a dance representing forest succession",  
				"type": "theatrical\_combat",  
				"target": "dance\_performance",  
				"completed": false  
			}  
		},  
		"rewards": {  
			"theatrical\_move": "interpretive\_dance",  
			"relationships": {"luna\_meadows": 20},  
			"player\_stats": {"creativity": 2}  
		},  
		"prerequisites": {  
			"relationship": {"luna\_meadows": RelationshipStatus.ACQUAINTANCE}  
		}  
	},  
	"learn\_lichen\_facts": {  
		"title": "Lichen Chronicles",  
		"description": "Professor Moss challenges you to become a lichen expert, able to wield knowledge as a powerful tool in debates.",  
		"objectives": {  
			"research\_assignment": {  
				"description": "Complete Professor Moss's research assignment",  
				"type": "collection",  
				"target": 5, \# Collect 5 lichen specimens  
				"progress": 0  
			},  
			"quiz\_challenge": {  
				"description": "Pass the lichen identification quiz",  
				"type": "minigame",  
				"target": "lichen\_quiz",  
				"completed": false  
			},  
			"teaching\_practice": {  
				"description": "Successfully teach a fellow student about lichens",  
				"type": "dialog",  
				"target": "skeptical\_student",  
				"completed": false  
			}  
		},  
		"rewards": {  
			"theatrical\_move": "lichen\_facts",  
			"relationships": {"professor\_moss": 15},  
			"player\_stats": {"knowledge": 2}  
		},  
		"prerequisites": {  
			"relationship": {"professor\_moss": RelationshipStatus.ACQUAINTANCE}  
		}  
	},  
	"learn\_dramatic\_monologue": {  
		"title": "The Power of Words",  
		"description": "The Drama Club is hosting a workshop on environmental monologues. This could be a powerful tool for persuasion.",  
		"objectives": {  
			"attend\_workshop": {  
				"description": "Attend the workshop at the campus theater",  
				"type": "location",  
				"target": "theater",  
				"completed": false  
			},  
			"write\_monologue": {  
				"description": "Write a compelling environmental monologue",  
				"type": "minigame",  
				"target": "writing\_minigame",  
				"completed": false  
			},  
			"perform\_monologue": {  
				"description": "Deliver your monologue to an audience",  
				"type": "theatrical\_combat",  
				"target": "monologue\_performance",  
				"completed": false  
			}  
		},  
		"rewards": {  
			"theatrical\_move": "dramatic\_monologue",  
			"relationships": {"drama\_club\_president": 15},  
			"player\_stats": {"charisma": 2}  
		},  
		"prerequisites": {  
			"player\_stats": {"charisma": 3}  
		}  
	},  
	"learn\_ethical\_argument": {  
		"title": "Environmental Ethics",  
		"description": "Develop your ability to make compelling ethical arguments about environmental issues.",  
		"objectives": {  
			"philosophy\_class": {  
				"description": "Attend the environmental ethics seminar",  
				"type": "location",  
				"target": "classroom",  
				"completed": false  
			},  
			"ethical\_framework": {  
				"description": "Develop your own environmental ethical framework",  
				"type": "minigame",  
				"target": "ethics\_minigame",  
				"completed": false  
			},  
			"ethical\_debate": {  
				"description": "Defend your ethical framework in a formal debate",  
				"type": "theatrical\_combat",  
				"target": "philosophy\_student",  
				"completed": false  
			}  
		},  
		"rewards": {  
			"theatrical\_move": "ethical\_argument",  
			"relationships": {"philosophy\_student": 15},  
			"player\_stats": {"knowledge": 1, "charisma": 1}  
		},  
		"prerequisites": {  
			"player\_stats": {"knowledge": 3}  
		}  
	}  
	\# More theatrical move quests...  
}

func start\_quest(quest\_id):  
	if quest\_id in quest\_database and not quest\_id in active\_quests and not quest\_id in completed\_quests:  
		\# Clone the quest data to track progress  
		active\_quests\[quest\_id\] \= quest\_database\[quest\_id\].duplicate(true)  
		emit\_signal("quest\_started", quest\_id)  
		return true  
	return false

func update\_objective(quest\_id, objective\_id, progress):  
	if quest\_id in active\_quests and objective\_id in active\_quests\[quest\_id\]\["objectives"\]:  
		var objective \= active\_quests\[quest\_id\]\["objectives"\]\[objective\_id\]  
		  
		if objective\["type"\] \== "collection":  
			objective\["progress"\] \+= progress  
			if objective\["progress"\] \>= objective\["target"\]:  
				objective\["progress"\] \= objective\["target"\]  
		else:  
			objective\["completed"\] \= true  
		  
		emit\_signal("quest\_objective\_updated", quest\_id, objective\_id, objective)  
		  
		\# Check if all objectives are complete  
		var all\_complete \= true  
		for obj\_id in active\_quests\[quest\_id\]\["objectives"\]:  
			var obj \= active\_quests\[quest\_id\]\["objectives"\]\[obj\_id\]  
			if (obj\["type"\] \== "collection" and obj\["progress"\] \< obj\["target"\]) or \\  
			   (obj\["type"\] \!= "collection" and not obj\["completed"\]):  
				all\_complete \= false  
				break  
		  
		if all\_complete:  
			complete\_quest(quest\_id)  
		  
		return true  
	return false

func complete\_quest(quest\_id):  
	if quest\_id in active\_quests:  
		var rewards \= active\_quests\[quest\_id\]\["rewards"\]  
		completed\_quests.append(quest\_id)  
		active\_quests.erase(quest\_id)  
		emit\_signal("quest\_completed", quest\_id, rewards)  
		  
		\# Here you would actually distribute the rewards  
		\# \- Add items to inventory  
		\# \- Update relationships  
		\# \- Improve player stats  
		  
		return true  
	return false

func fail\_quest(quest\_id):  
	if quest\_id in active\_quests:  
		active\_quests.erase(quest\_id)  
		emit\_signal("quest\_failed", quest\_id)  
		return true  
	return false

func get\_quest\_description(quest\_id):  
	if quest\_id in active\_quests:  
		return active\_quests\[quest\_id\]\["description"\]  
	elif quest\_id in quest\_database:  
		return quest\_database\[quest\_id\]\["description"\]  
	return "Unknown quest"

func get\_objective\_progress(quest\_id, objective\_id):  
	if quest\_id in active\_quests and objective\_id in active\_quests\[quest\_id\]\["objectives"\]:  
		var objective \= active\_quests\[quest\_id\]\["objectives"\]\[objective\_id\]  
		if objective\["type"\] \== "collection":  
			return objective\["progress"\] \+ "/" \+ objective\["target"\] \+ " " \+ objective\["description"\]  
		else:  
			return (objective\["completed"\] and "Completed" or "Incomplete") \+ ": " \+ objective\["description"\]  
	return "Unknown objective"

func start\_theatrical\_move\_quest(quest\_id):  
	if quest\_id in theatrical\_move\_quests:  
		var quest \= theatrical\_move\_quests\[quest\_id\]  
		  
		\# Check prerequisites  
		var prerequisites\_met \= true  
		  
		if "prerequisites" in quest:  
			\# Check relationship prerequisites  
			if "relationship" in quest\["prerequisites"\]:  
				var relationship\_system \= get\_tree().get\_root().get\_node("GameController/RelationshipSystem")  
				for npc\_id in quest\["prerequisites"\]\["relationship"\]:  
					var required\_status \= quest\["prerequisites"\]\["relationship"\]\[npc\_id\]  
					if relationship\_system.get\_relationship\_status(npc\_id) \< required\_status:  
						prerequisites\_met \= false  
						break  
			  
			\# Check player stat prerequisites  
			if "player\_stats" in quest\["prerequisites"\]:  
				var player\_data \= get\_tree().get\_root().get\_node("GameController").player\_data  
				for stat in quest\["prerequisites"\]\["player\_stats"\]:  
					if player\_data\["stats"\]\[stat\] \< quest\["prerequisites"\]\["player\_stats"\]\[stat\]:  
						prerequisites\_met \= false  
						break  
		  
		if prerequisites\_met:  
			\# Add to active quests  
			active\_quests\[quest\_id\] \= theatrical\_move\_quests\[quest\_id\].duplicate(true)  
			emit\_signal("quest\_started", quest\_id)  
			return true  
	return false

func complete\_theatrical\_move\_quest(quest\_id):  
	if quest\_id in active\_quests and quest\_id in theatrical\_move\_quests:  
		var quest \= active\_quests\[quest\_id\]  
		  
		\# Award theatrical move  
		if "theatrical\_move" in quest\["rewards"\]:  
			var move\_id \= quest\["rewards"\]\["theatrical\_move"\]  
			get\_tree().get\_root().get\_node("GameController/CombatSystem").unlock\_theatrical\_move(move\_id)  
		  
		\# Award other rewards  
		if "relationships" in quest\["rewards"\]:  
			var relationship\_system \= get\_tree().get\_root().get\_node("GameController/RelationshipSystem")  
			for npc\_id in quest\["rewards"\]\["relationships"\]:  
				relationship\_system.update\_relationship(npc\_id, quest\["rewards"\]\["relationships"\]\[npc\_id\])  
		  
		if "player\_stats" in quest\["rewards"\]:  
			var player\_data \= get\_tree().get\_root().get\_node("GameController").player\_data  
			for stat in quest\["rewards"\]\["player\_stats"\]:  
				player\_data\["stats"\]\[stat\] \+= quest\["rewards"\]\["player\_stats"\]\[stat\]  
		  
		\# Complete quest  
		completed\_quests.append(quest\_id)  
		active\_quests.erase(quest\_id)  
		emit\_signal("quest\_completed", quest\_id, quest\["rewards"\])  
		return true  
	return false

func check\_available\_theatrical\_move\_quests():  
	var available \= \[\]  
	  
	for quest\_id in theatrical\_move\_quests:  
		if not quest\_id in active\_quests and not quest\_id in completed\_quests:  
			var quest \= theatrical\_move\_quests\[quest\_id\]  
			var prerequisites\_met \= true  
			  
			if "prerequisites" in quest:  
				\# Check relationship prerequisites  
				if "relationship" in quest\["prerequisites"\]:  
					var relationship\_system \= get\_tree().get\_root().get\_node("GameController/RelationshipSystem")  
					for npc\_id in quest\["prerequisites"\]\["relationship"\]:  
						var required\_status \= quest\["prerequisites"\]\["relationship"\]\[npc\_id\]  
						if relationship\_system.get\_relationship\_status(npc\_id) \< required\_status:  
							prerequisites\_met \= false  
							break  
				  
				\# Check player stat prerequisites  
				if "player\_stats" in quest\["prerequisites"\]:  
					var player\_data \= get\_tree().get\_root().get\_node("GameController").player\_data  
					for stat in quest\["prerequisites"\]\["player\_stats"\]:  
						if player\_data\["stats"\]\[stat\] \< quest\["prerequisites"\]\["player\_stats"\]\[stat\]:  
							prerequisites\_met \= false  
							break  
			  
			if prerequisites\_met:  
				available.append(quest\_id)  
	  
	return available

func generate\_nemesis\_quest(nemesis\_id):  
	\# Create a dynamic quest based on the nemesis  
	var nemesis\_name \= get\_tree().get\_root().get\_node("GameController/RelationshipSystem").npc\_database\[nemesis\_id\]\["name"\]  
	var location \= get\_random\_location\_for\_nemesis(nemesis\_id)  
	  
	var quest\_id \= "confront\_" \+ nemesis\_id \+ "\_" \+ str(OS.get\_unix\_time())  
	var quest \= {  
		"title": "Confrontation with " \+ nemesis\_name,  
		"description": nemesis\_name \+ " has been causing trouble at " \+ location \+ ". It's time to settle things.",  
		"objectives": {  
			"locate\_nemesis": {  
				"description": "Find " \+ nemesis\_name \+ " at " \+ location,  
				"type": "location",  
				"target": location,  
				"completed": false  
			},  
			"defeat\_nemesis": {  
				"description": "Defeat " \+ nemesis\_name \+ " in a debate",  
				"type": "theatrical\_combat",  
				"target": nemesis\_id,  
				"completed": false  
			},  
			"resolution": {  
				"description": "Choose whether to reconcile or escalate the conflict",  
				"type": "choice",  
				"options": \["reconcile", "escalate"\],  
				"completed": false  
			}  
		},  
		"rewards": {  
			"items": {"reconciliation\_token": 1},  
			"relationships": {},  
			"player\_stats": {"charisma": 1}  
		},  
		"dynamic": true  
	}  
	  
	\# Add to quest database  
	quest\_database\[quest\_id\] \= quest  
	  
	return quest\_id

func get\_random\_location\_for\_nemesis(nemesis\_id):  
	\# Choose an appropriate location based on the nemesis type  
	var world\_controller \= get\_tree().get\_root().get\_node("GameController/WorldController")  
	var locations \= world\_controller.locations  
	  
	var potential\_locations \= \[\]  
	for location\_id in locations:  
		var location \= locations\[location\_id\]  
		  
		\# Match nemesis with appropriate locations  
		\# For example, corporate execs might be found in offices or meeting rooms  
		if nemesis\_id \== "corporate\_exec" and location\_id in \["science\_building", "library"\]:  
			potential\_locations.append(location\["name"\])  
		elif nemesis\_id \== "skeptical\_student" and location\_id in \["campus\_quad", "library", "dormitory"\]:  
			potential\_locations.append(location\["name"\])  
		\# Add more specific location matching  
	  
	if potential\_locations.size() \> 0:  
		return potential\_locations\[randi() % potential\_locations.size()\]  
	else:  
		\# Default fallback location  
		return "campus\_quad"

func complete\_nemesis\_quest(quest\_id, resolution\_choice):  
	if quest\_id in active\_quests and active\_quests\[quest\_id\].get("dynamic", false):  
		var objectives \= active\_quests\[quest\_id\]\["objectives"\]  
		var nemesis\_id \= objectives\["defeat\_nemesis"\]\["target"\]  
		  
		\# Update the relationship based on resolution choice  
		var relationship\_system \= get\_tree().get\_root().get\_node("GameController/RelationshipSystem")  
		  
		if resolution\_choice \== "reconcile":  
			\# Improve relationship slightly, reduce nemesis status  
			relationship\_system.update\_relationship(nemesis\_id, 20\)  
			  
			\# If relationship improved enough, they might no longer be a nemesis  
			if relationship\_system.get\_relationship\_status(nemesis\_id) \> RelationshipStatus.STRANGER:  
				\# Remove from nemesis list  
				get\_tree().get\_root().get\_node("GameController/CombatSystem").nemesis\_list.erase(nemesis\_id)  
		else: \# escalate  
			\# Further deteriorate relationship, increase nemesis level  
			relationship\_system.update\_relationship(nemesis\_id, \-10)  
			relationship\_system.upgrade\_nemesis(nemesis\_id)  
		  
		\# Complete the quest  
		objectives\["resolution"\]\["completed"\] \= true  
		complete\_quest(quest\_id)  
		  
		return true  
	return false

\# Special Events System  
extends Node

signal special\_event\_available(event\_id)  
signal special\_event\_started(event\_id)  
signal special\_event\_completed(event\_id)

\# Special events that enable theatrical combat  
var special\_events \= {  
	"campus\_eco\_rally": {  
		"title": "Campus Eco-Rally",  
		"description": "Students are gathering to protest a new development project that threatens wetlands near campus. This charged atmosphere is perfect for theatrical confrontations.",  
		"location": "campus\_quad",  
		"duration": 3, \# In-game days  
		"start\_time": 0, \# Set when event starts  
		"active": false,  
		"opponents": \["corporate\_exec", "skeptical\_student"\],  
		"combat\_context": CombatContext.RALLY,  
		"prerequisites": {  
			"progress": "wetlands\_threatened"  
		}  
	},  
	"environmental\_theater\_night": {  
		"title": "Environmental Theater Night",  
		"description": "The drama club is hosting a night of environmentally-themed performances. It's the perfect venue for theatrical debate.",  
		"location": "theater",  
		"duration": 1,  
		"start\_time": 0,  
		"active": false,  
		"opponents": \["drama\_club\_president", "performance\_artist"\],  
		"combat\_context": CombatContext.THEATRICAL,  
		"prerequisites": {  
			"relationship": {"drama\_club\_president": RelationshipStatus.ACQUAINTANCE}  
		}  
	},  
	"ecosystems\_lecture": {  
		"title": "Advanced Ecosystems Lecture",  
		"description": "Professor Moss is giving a special lecture where students are encouraged to debate ecological concepts in creative ways.",  
		"location": "science\_building",  
		"duration": 1,  
		"start\_time": 0,  
		"active": false,  
		"opponents": \["skeptical\_student", "nature\_guide"\],  
		"combat\_context": CombatContext.CLASSROOM,  
		"prerequisites": {  
			"relationship": {"professor\_moss": RelationshipStatus.ACQUAINTANCE}  
		}  
	},  
	"formal\_debate\_competition": {  
		"title": "Campus Sustainability Debate",  
		"description": "A formal debate on campus sustainability policies is being held. Show off your rhetorical skills\!",  
		"location": "library",  
		"duration": 2,  
		"start\_time": 0,  
		"active": false,  
		"opponents": \["corporate\_exec", "environmental\_activist", "philosophy\_student"\],  
		"combat\_context": CombatContext.FORMAL\_DEBATE,  
		"prerequisites": {  
			"player\_stats": {"charisma": 4, "knowledge": 4}  
		}  
	}  
	\# More special events...  
}

\# Game progression flags  
var game\_progress \= {}

func \_process(delta):  
	\# Check for expired events  
	var current\_time \= OS.get\_unix\_time()  
	for event\_id in special\_events:  
		var event \= special\_events\[event\_id\]  
		if event\["active"\] and current\_time \> event\["start\_time"\] \+ (event\["duration"\] \* 86400): \# Convert days to seconds  
			event\["active"\] \= false

func set\_progress\_flag(flag, value \= true):  
	game\_progress\[flag\] \= value  
	  
	\# Check if new events can be triggered  
	check\_for\_available\_events()

func check\_for\_available\_events():  
	var newly\_available \= \[\]  
	  
	for event\_id in special\_events:  
		var event \= special\_events\[event\_id\]  
		if not event\["active"\]:  
			var prerequisites\_met \= true  
			  
			\# Check progress prerequisites  
			if "prerequisites" in event:  
				if "progress" in event\["prerequisites"\]:  
					var required\_flag \= event\["prerequisites"\]\["progress"\]  
					if not required\_flag in game\_progress or not game\_progress\[required\_flag\]:  
						prerequisites\_met \= false  
				  
				\# Check relationship prerequisites  
				if "relationship" in event\["prerequisites"\]:  
					var relationship\_system \= get\_tree().get\_root().get\_node("GameController/RelationshipSystem")  
					for npc\_id in event\["prerequisites"\]\["relationship"\]:  
						var required\_status \= event\["prerequisites"\]\["relationship"\]\[npc\_id\]  
						if relationship\_system.get\_relationship\_status(npc\_id) \< required\_status:  
							prerequisites\_met \= false  
							break  
				  
				\# Check player stat prerequisites  
				if "player\_stats" in event\["prerequisites"\]:  
					var player\_data \= get\_tree().get\_root().get\_node("GameController").player\_data  
					for stat in event\["prerequisites"\]\["player\_stats"\]:  
						if player\_data\["stats"\]\[stat\] \< event\["prerequisites"\]\["player\_stats"\]\[stat\]:  
							prerequisites\_met \= false  
							break  
			  
			if prerequisites\_met:  
				newly\_available.append(event\_id)  
	  
	for event\_id in newly\_available:  
		emit\_signal("special\_event\_available", event\_id)

func start\_special\_event(event\_id):  
	if event\_id in special\_events:  
		var event \= special\_events\[event\_id\]  
		if not event\["active"\]:  
			event\["active"\] \= true  
			event\["start\_time"\] \= OS.get\_unix\_time()  
			emit\_signal("special\_event\_started", event\_id)  
			return true  
	return false

func is\_event\_active(event\_id):  
	if event\_id in special\_events:  
		return special\_events\[event\_id\]\["active"\]  
	return false

func get\_active\_events\_at\_location(location\_id):  
	var active\_events \= \[\]  
	  
	for event\_id in special\_events:  
		var event \= special\_events\[event\_id\]  
		if event\["active"\] and event\["location"\] \== location\_id:  
			active\_events.append(event\_id)  
	  
	return active\_events

func start\_theatrical\_combat\_from\_event(event\_id):  
	if is\_event\_active(event\_id):  
		var event \= special\_events\[event\_id\]  
		var combat\_system \= get\_tree().get\_root().get\_node("GameController/CombatSystem")  
		  
		\# Choose a random opponent from the event  
		var opponent\_id \= event\["opponents"\]\[randi() % event\["opponents"\].size()\]  
		  
		\# Start combat with theatrical context  
		combat\_system.start\_combat(opponent\_id, event\["combat\_context"\])  
		return true  
	return false

\# World Controller  
extends Node2D

\# Areas/locations in the game  
var locations \= {  
	"campus\_quad": {  
		"name": "Campus Quad",  
		"connections": \["science\_building", "library", "dormitory", "theater"\],  
		"npcs": \["luna\_meadows"\],  
		"environment": "outdoor"  
	},  
	"science\_building": {  
		"name": "Environmental Science Building",  
		"connections": \["campus\_quad", "laboratory", "greenhouse", "classroom"\],  
		"npcs": \["professor\_moss"\],  
		"environment": "indoor"  
	},  
	"laboratory": {  
		"name": "Research Laboratory",  
		"connections": \["science\_building"\],  
		"npcs": \[\],  
		"environment": "indoor"  
	},  
	"classroom": {  
		"name": "Lecture Hall",  
		"connections": \["science\_building"\],  
		"npcs": \["philosophy\_student"\],  
		"environment": "indoor"  
	},  
	"greenhouse": {  
		"name": "Campus Greenhouse",  
		"connections": \["science\_building", "garden"\],  
		"npcs": \[\],  
		"environment": "indoor"  
	},  
	"library": {  
		"name": "Sustainability Library",  
		"connections": \["campus\_quad"\],  
		"npcs": \["skeptical\_student"\],  
		"environment": "indoor"  
	},  
	"dormitory": {  
		"name": "Eco-Friendly Dormitory",  
		"connections": \["campus\_quad"\],  
		"npcs": \["river\_stone"\],  
		"environment": "indoor"  
	},  
	"garden": {  
		"name": "Permaculture Garden",  
		"connections": \["greenhouse"\],  
		"npcs": \["nature\_guide"\],  
		"environment": "outdoor"  
	},  
	"forest": {  
		"name": "Old Growth Forest Preserve",  
		"connections": \["campus\_quad"\],  
		"npcs": \[\],  
		"environment": "outdoor"  
	},  
	"lake": {  
		"name": "Campus Lake",  
		"connections": \["forest"\],  
		"npcs": \[\],  
		"environment": "outdoor"  
	},  
	"theater": {  
		"name": "Campus Theater",  
		"connections": \["campus\_quad"\],  
		"npcs": \["drama\_club\_president", "performance\_artist"\],  
		"environment": "indoor"  
	}  
	\# More locations...  
}

\# Current location  
var current\_location \= "campus\_quad"

func change\_location(location\_id):  
	if location\_id in locations and location\_id in locations\[current\_location\]\["connections"\]:  
		current\_location \= location\_id  
		\# Update the scene to reflect the new location  
		\# \- Change background  
		\# \- Update available NPCs  
		\# \- Update interactive objects  
		return true  
	return false

func get\_available\_npcs():  
	if current\_location in locations:  
		return locations\[current\_location\]\["npcs"\]  
	return \[\]

func get\_connected\_locations():  
	if current\_location in locations:  
		return locations\[current\_location\]\["connections"\]  
	return \[\]

func interact\_with\_npc(npc\_id):  
	var npcs \= get\_available\_npcs()  
	if npc\_id in npcs:  
		\# Start a dialog with this NPC  
		get\_tree().get\_root().get\_node("GameController/DialogSystem").start\_dialog(npc\_id)  
		return true  
	return false

func check\_for\_theatrical\_opportunities():  
	var opportunities \= \[\]  
	  
	\# Check for active events at current location  
	var special\_events\_system \= get\_tree().get\_root().get\_node("GameController/SpecialEventsSystem")  
	var active\_events \= special\_events\_system.get\_active\_events\_at\_location(current\_location)  
	  
	if active\_events.size() \> 0:  
		for event\_id in active\_events:  
			opportunities.append({  
				"type": "event",  
				"id": event\_id,  
				"title": special\_events\_system.special\_events\[event\_id\]\["title"\],  
				"description": special\_events\_system.special\_events\[event\_id\]\["description"\]  
			})  
	  
	\# Check for available theatrical move quests  
	var quest\_system \= get\_tree().get\_root().get\_node("GameController/QuestSystem")  
	var available\_quests \= quest\_system.check\_available\_theatrical\_move\_quests()  
	  
	if available\_quests.size() \> 0:  
		for quest\_id in available\_quests:  
			opportunities.append({  
				"type": "quest",  
				"id": quest\_id,  
				"title": quest\_system.theatrical\_move\_quests\[quest\_id\]\["title"\],  
				"description": quest\_system.theatrical\_move\_quests\[quest\_id\]\["description"\]  
			})  
	  
	return opportunities

\# Magic and Environmental Powers System  
extends Node

signal power\_unlocked(power\_id)  
signal power\_used(power\_id, target, effect)

\# Available powers  
var power\_database \= {  
	"lichen\_whisper": {  
		"name": "Lichen Whisper",  
		"description": "Communicate with lichen to gain ecological insights",  
		"required\_knowledge": 3,  
		"cooldown": 60, \# seconds  
		"effect": "reveal\_hidden\_info"  
	},  
	"mycelial\_network": {  
		"name": "Mycelial Network",  
		"description": "Connect to the fungal information network to locate objects or NPCs",  
		"required\_knowledge": 5,  
		"cooldown": 120,  
		"effect": "locate\_target"  
	},  
	"photosynthesis\_burst": {  
		"name": "Photosynthesis Burst",  
		"description": "Channel the power of sunlight to heal or energize",  
		"required\_creativity": 4,  
		"cooldown": 180,  
		"effect": "healing"  
	},  
	"ecological\_projection": {  
		"name": "Ecological Projection",  
		"description": "Visualize past or future ecological states of an area",  
		"required\_knowledge": 6,  
		"required\_creativity": 3,  
		"cooldown": 240,  
		"effect": "time\_vision"  
	}  
	\# More powers...  
}

\# Player's unlocked powers and their cooldown status  
var unlocked\_powers \= {}  
var power\_cooldowns \= {}

func \_process(delta):  
	\# Update cooldowns  
	var current\_time \= OS.get\_unix\_time()  
	for power\_id in power\_cooldowns.keys():  
		if current\_time \>= power\_cooldowns\[power\_id\]:  
			power\_cooldowns.erase(power\_id)

func unlock\_power(power\_id):  
	if power\_id in power\_database and not power\_id in unlocked\_powers:  
		\# Check if player meets requirements  
		var power \= power\_database\[power\_id\]  
		var meets\_requirements \= true  
		  
		if "required\_knowledge" in power:  
			\# Check player knowledge stat  
			var player\_data \= get\_tree().get\_root().get\_node("GameController").player\_data  
			meets\_requirements \= meets\_requirements and (player\_data\["stats"\]\["knowledge"\] \>= power\["required\_knowledge"\])  
			  
		if "required\_creativity" in power:  
			\# Check player creativity stat  
			var player\_data \= get\_tree().get\_root().get\_node("GameController").player\_data  
			meets\_requirements \= meets\_requirements and (player\_data\["stats"\]\["creativity"\] \>= power\["required\_creativity"\])  
		  
		if meets\_requirements:  
			unlocked\_powers\[power\_id\] \= true  
			emit\_signal("power\_unlocked", power\_id)  
			return true  
	return false

func use\_power(power\_id, target \= null):  
	if power\_id in unlocked\_powers and not power\_id in power\_cooldowns:  
		var power \= power\_database\[power\_id\]  
		var effect \= null  
		  
		\# Apply the power effect based on its type  
		match power\["effect"\]:  
			"reveal\_hidden\_info":  
				\# Logic to reveal hidden objects or information  
				effect \= "Revealed hidden information about " \+ str(target)  
			"locate\_target":  
				\# Logic to help find a character or object  
				effect \= "Located " \+ str(target)  
			"healing":  
				\# Logic for healing effect  
				effect \= "Healed " \+ str(target)  
			"time\_vision":  
				\# Logic for seeing past/future state  
				effect \= "Visualized ecological timeline for " \+ str(target)  
		  
		\# Set cooldown  
		power\_cooldowns\[power\_id\] \= OS.get\_unix\_time() \+ power\["cooldown"\]  
		  
		emit\_signal("power\_used", power\_id, target, effect)  
		return effect  
	return null

func get\_available\_powers():  
	var available \= \[\]  
	var current\_time \= OS.get\_unix\_time()  
	  
	for power\_id in unlocked\_powers:  
		if not power\_id in power\_cooldowns:  
			available.append(power\_id)  
	  
	return available

func get\_power\_info(power\_id):  
	if power\_id in power\_database:  
		var info \= power\_database\[power\_id\].duplicate()  
		  
		\# Add cooldown status if applicable  
		if power\_id in power\_cooldowns:  
			var remaining \= power\_cooldowns\[power\_id\] \- OS.get\_unix\_time()  
			info\["cooldown\_remaining"\] \= remaining  
		else:  
			info\["cooldown\_remaining"\] \= 0  
			  
		return info  
	return null

\# Main UI Controller  
extends CanvasLayer

\# UI components  
var inventory\_panel  
var dialog\_panel  
var combat\_panel  
var quest\_log  
var relationship\_menu  
var power\_menu

func \_ready():  
	inventory\_panel \= $InventoryPanel  
	dialog\_panel \= $DialogPanel  
	combat\_panel \= $CombatPanel  
	quest\_log \= $QuestLog  
	relationship\_menu \= $RelationshipMenu  
	power\_menu \= $PowerMenu  
	  
	\# Hide all panels initially  
	inventory\_panel.visible \= false  
	dialog\_panel.visible \= false  
	combat\_panel.visible \= false  
	quest\_log.visible \= false  
	relationship\_menu.visible \= false  
	power\_menu.visible \= false  
	  
	\# Connect signal handlers  
	var game\_controller \= get\_tree().get\_root().get\_node("GameController")  
	game\_controller.dialog\_system.connect("dialog\_started", self, "\_on\_dialog\_started")  
	game\_controller.dialog\_system.connect("dialog\_ended", self, "\_on\_dialog\_ended")  
	game\_controller.combat\_system.connect("combat\_started", self, "\_on\_combat\_started")  
	game\_controller.combat\_system.connect("combat\_ended", self, "\_on\_combat\_ended")  
	game\_controller.quest\_system.connect("quest\_started", self, "\_on\_quest\_started")  
	game\_controller.quest\_system.connect("quest\_completed", self, "\_on\_quest\_completed")  
	game\_controller.special\_events\_system.connect("special\_event\_available", self, "\_on\_special\_event\_available")

func \_input(event):  
	if event.is\_action\_pressed("inventory\_toggle"):  
		toggle\_panel(inventory\_panel)  
	elif event.is\_action\_pressed("quest\_log\_toggle"):  
		toggle\_panel(quest\_log)  
	elif event.is\_action\_pressed("relationship\_menu\_toggle"):  
		toggle\_panel(relationship\_menu)  
	elif event.is\_action\_pressed("power\_menu\_toggle"):  
		toggle\_panel(power\_menu)

func toggle\_panel(panel):  
	\# Hide all panels  
	inventory\_panel.visible \= false  
	quest\_log.visible \= false  
	relationship\_menu.visible \= false  
	power\_menu.visible \= false  
	  
	\# Then show the requested panel if it wasn't already visible  
	if panel \!= null:  
		panel.visible \= \!panel.visible

func \_on\_dialog\_started(npc\_id):  
	dialog\_panel.visible \= true  
	\# Update dialog panel with the current dialog content  
	dialog\_panel.update\_content()

func \_on\_dialog\_ended(npc\_id):  
	dialog\_panel.visible \= false

func \_on\_combat\_started(opponent\_id, context):  
	combat\_panel.visible \= true  
	\# Update combat panel with the opponent info  
	combat\_panel.update\_content(context)

func \_on\_combat\_ended(result):  
	combat\_panel.visible \= false  
	\# Maybe show a result screen

func \_on\_quest\_started(quest\_id):  
	\# Show notification  
	show\_notification("New Quest: " \+ get\_tree().get\_root().get\_node("GameController/QuestSystem").get\_quest\_title(quest\_id))

func \_on\_quest\_completed(quest\_id, rewards):  
	\# Show notification and rewards  
	show\_notification("Quest Completed: " \+ get\_tree().get\_root().get\_node("GameController/QuestSystem").get\_quest\_title(quest\_id))  
	  
	\# Show rewards popup  
	show\_rewards\_popup(rewards)

func \_on\_special\_event\_available(event\_id):  
	\# Show notification  
	var special\_events\_system \= get\_tree().get\_root().get\_node("GameController/SpecialEventsSystem")  
	show\_notification("New Event: " \+ special\_events\_system.special\_events\[event\_id\]\["title"\])

func show\_notification(text):  
	var notification \= $NotificationPanel  
	notification.get\_node("Label").text \= text  
	notification.visible \= true  
	  
	\# Hide notification after a delay  
	yield(get\_tree().create\_timer(3.0), "timeout")  
	notification.visible \= false

func show\_rewards\_popup(rewards):  
	var popup \= $RewardsPopup  
	var rewards\_text \= "Rewards:\\n"  
	  
	if "items" in rewards:  
		rewards\_text \+= "\\nItems:"  
		for item\_id in rewards\["items"\]:  
			var quantity \= rewards\["items"\]\[item\_id\]  
			rewards\_text \+= "\\n- " \+ get\_tree().get\_root().get\_node("GameController/InventorySystem").get\_item\_info(item\_id)\["name"\] \+ " x" \+ str(quantity)  
	  
	if "relationships" in rewards:  
		rewards\_text \+= "\\n\\nRelationship Changes:"  
		for npc\_id in rewards\["relationships"\]:  
			var value \= rewards\["relationships"\]\[npc\_id\]  
			var npc\_name \= get\_tree().get\_root().get\_node("GameController/RelationshipSystem").npc\_database\[npc\_id\]\["name"\]  
			rewards\_text \+= "\\n- " \+ npc\_name \+ ": " \+ (value \> 0 ? "+" : "") \+ str(value)  
	  
	if "player\_stats" in rewards:  
		rewards\_text \+= "\\n\\nStat Improvements:"  
		for stat in rewards\["player\_stats"\]:  
			var value \= rewards\["player\_stats"\]\[stat\]  
			rewards\_text \+= "\\n- " \+ stat.capitalize() \+ ": \+" \+ str(value)  
	  
	if "theatrical\_move" in rewards:  
		rewards\_text \+= "\\n\\nUnlocked Theatrical Move: " \+ get\_tree().get\_root().get\_node("GameController/CombatSystem").theatrical\_moves\[rewards\["theatrical\_move"\]\]\["name"\]  
	  
	popup.get\_node("RewardsLabel").text \= rewards\_text  
	popup.visible \= true

\# Dialog UI Panel  
extends Panel

\# UI components  
var npc\_name\_label  
var dialog\_text  
var portrait\_texture  
var choice\_buttons \= \[\]

func \_ready():  
	npc\_name\_label \= $NPCNameLabel  
	dialog\_text \= $DialogText  
	portrait\_texture \= $PortraitTexture  
	  
	\# Setup choice buttons (assuming we have 3 max choices)  
	for i in range(3):  
		choice\_buttons.append(get\_node("ChoiceButton" \+ str(i)))  
		choice\_buttons\[i\].connect("pressed", self, "\_on\_choice\_button\_pressed", \[i\])  
		choice\_buttons\[i\].visible \= false

func update\_content():  
	var dialog\_system \= get\_tree().get\_root().get\_node("GameController/DialogSystem")  
	var current\_node \= dialog\_system.get\_current\_dialog\_node()  
	  
	if current\_node \!= null:  
		\# Get NPC name  
		var npc\_id \= dialog\_system.current\_npc  
		var npc\_name \= get\_tree().get\_root().get\_node("GameController/RelationshipSystem").npc\_database\[npc\_id\]\["name"\]  
		  
		\# Update UI elements  
		npc\_name\_label.text \= npc\_name  
		dialog\_text.text \= current\_node\["text"\]  
		  
		\# Load portrait texture  
		var portrait\_path \= current\_node\["portrait"\]  
		portrait\_texture.texture \= load(portrait\_path)  
		  
		\# Setup choice buttons  
		var choices \= current\_node\["choices"\]  
		for i in range(choice\_buttons.size()):  
			if i \< choices.size():  
				choice\_buttons\[i\].text \= choices\[i\]\["text"\]  
				choice\_buttons\[i\].visible \= true  
			else:  
				choice\_buttons\[i\].visible \= false

func \_on\_choice\_button\_pressed(choice\_index):  
	var dialog\_system \= get\_tree().get\_root().get\_node("GameController/DialogSystem")  
	var next\_node \= dialog\_system.make\_choice(choice\_index)  
	  
	if next\_node \!= null:  
		update\_content()

\# Combat UI Panel  
extends Panel

\# UI components  
var opponent\_name\_label  
var opponent\_resolve\_bar  
var player\_resolve\_bar  
var move\_buttons \= \[\]  
var special\_move\_buttons \= \[\]  
var combat\_log  
var combat\_context\_label  
var encounter\_description\_label

func \_ready():  
	opponent\_name\_label \= $OpponentNameLabel  
	opponent\_resolve\_bar \= $OpponentResolveBar  
	player\_resolve\_bar \= $PlayerResolveBar  
	combat\_log \= $CombatLog  
	combat\_context\_label \= $CombatContextLabel  
	encounter\_description\_label \= $EncounterDescription  
	  
	\# Setup move buttons  
	for i in range(5): \# Assuming 5 standard moves  
		move\_buttons.append(get\_node("MoveButton" \+ str(i)))  
		move\_buttons\[i\].connect("pressed", self, "\_on\_move\_button\_pressed", \[i\])  
	  
	\# Setup special move buttons  
	for i in range(2): \# Assuming up to 2 special moves  
		special\_move\_buttons.append(get\_node("SpecialMoveButton" \+ str(i)))  
		special\_move\_buttons\[i\].connect("pressed", self, "\_on\_special\_move\_button\_pressed", \[i\])  
		special\_move\_buttons\[i\].visible \= false  
	  
	\# Connect to combat system signals  
	var combat\_system \= get\_tree().get\_root().get\_node("GameController/CombatSystem")  
	combat\_system.connect("combat\_started", self, "\_on\_combat\_started")  
	combat\_system.connect("turn\_started", self, "\_on\_turn\_started")  
	combat\_system.connect("action\_performed", self, "\_on\_action\_performed")  
	combat\_system.connect("combat\_ended", self, "\_on\_combat\_ended")

func update\_content(context \= CombatContext.STANDARD):  
	var combat\_system \= get\_tree().get\_root().get\_node("GameController/CombatSystem")  
	  
	if combat\_system.opponent \!= null:  
		opponent\_name\_label.text \= combat\_system.opponent\["name"\]  
		opponent\_resolve\_bar.value \= combat\_system.opponent\_resolve  
		opponent\_resolve\_bar.max\_value \= combat\_system.opponent\["resolve"\]  
		player\_resolve\_bar.value \= combat\_system.player\_resolve  
		player\_resolve\_bar.max\_value \= 100  
		  
		\# Get available moves based on context  
		var available\_moves \= combat\_system.get\_available\_moves()  
		var move\_ids \= available\_moves.keys()  
		  
		\# Update standard move buttons  
		var standard\_move\_count \= 0  
		for i in range(move\_buttons.size()):  
			move\_buttons\[i\].visible \= false  
		  
		for i in range(move\_ids.size()):  
			var move\_id \= move\_ids\[i\]  
			if move\_id in combat\_system.move\_database:  
				if standard\_move\_count \< move\_buttons.size():  
					var move \= available\_moves\[move\_id\]  
					move\_buttons\[standard\_move\_count\].text \= move\["name"\]  
					move\_buttons\[standard\_move\_count\].hint\_tooltip \= move\["description"\]  
					move\_buttons\[standard\_move\_count\].visible \= true  
					\# Store move\_id in button metadata for reference  
					move\_buttons\[standard\_move\_count\].set\_meta("move\_id", move\_id)  
					standard\_move\_count \+= 1  
		  
		\# Get theatrical moves if applicable  
		var theatrical\_move\_ids \= \[\]  
		for move\_id in move\_ids:  
			if move\_id in combat\_system.theatrical\_moves:  
				theatrical\_move\_ids.append(move\_id)  
		  
		\# Update special move buttons  
		for i in range(special\_move\_buttons.size()):  
			if i \< theatrical\_move\_ids.size():  
				var move\_id \= theatrical\_move\_ids\[i\]  
				var move \= available\_moves\[move\_id\]  
				special\_move\_buttons\[i\].text \= move\["name"\]  
				special\_move\_buttons\[i\].hint\_tooltip \= move\["description"\]  
				special\_move\_buttons\[i\].visible \= true  
				special\_move\_buttons\[i\].set\_meta("move\_id", move\_id)  
			else:  
				special\_move\_buttons\[i\].visible \= false

func \_on\_combat\_started(opponent\_id, context):  
	update\_content(context)  
	  
	\# Update context-specific UI elements  
	match context:  
		CombatContext.STANDARD:  
			combat\_context\_label.text \= "Standard Debate"  
		CombatContext.THEATRICAL:  
			combat\_context\_label.text \= "Theatrical Performance"  
		CombatContext.CLASSROOM:  
			combat\_context\_label.text \= "Classroom Discussion"  
		CombatContext.RALLY:  
			combat\_context\_label.text \= "Rally Confrontation"  
		CombatContext.FORMAL\_DEBATE:  
			combat\_context\_label.text \= "Formal Debate"  
	  
	\# Show theatrical move buttons only in appropriate contexts  
	for i in range(special\_move\_buttons.size()):  
		special\_move\_buttons\[i\].visible \= (context \!= CombatContext.STANDARD and special\_move\_buttons\[i\].visible)  
	  
	combat\_log.text \= "Confrontation with " \+ opponent\_name\_label.text \+ " begins in " \+ combat\_context\_label.text \+ " context\!"

func \_on\_turn\_started(is\_player\_turn):  
	\# Enable/disable buttons based on whose turn it is  
	for button in move\_buttons:  
		button.disabled \= \!is\_player\_turn  
	  
	for button in special\_move\_buttons:  
		button.disabled \= \!is\_player\_turn  
	  
	if is\_player\_turn:  
		combat\_log.text \+= "\\nYour turn. Choose your approach."  
	else:  
		combat\_log.text \+= "\\n" \+ opponent\_name\_label.text \+ "'s turn..."

func \_on\_action\_performed(performer, action\_id, target, effect):  
	var combat\_system \= get\_tree().get\_root().get\_node("GameController/CombatSystem")  
	  
	\# Update the UI based on the action  
	if performer \== "player":  
		\# Find move info  
		var move\_name \= action\_id  
		var available\_moves \= combat\_system.get\_available\_moves()  
		if action\_id in available\_moves:  
			move\_name \= available\_moves\[action\_id\]\["name"\]  
		  
		combat\_log.text \+= "\\nYou used " \+ move\_name \+ " for " \+ str(effect) \+ " effect\!"  
		opponent\_resolve\_bar.value \= combat\_system.opponent\_resolve  
	else: \# opponent  
		combat\_log.text \+= "\\n" \+ opponent\_name\_label.text \+ " responded with " \+ action\_id \+ " for " \+ str(effect) \+ " effect\!"  
		player\_resolve\_bar.value \= combat\_system.player\_resolve

func \_on\_combat\_ended(result):  
	\# Display result  
	if result \== "victory":  
		combat\_log.text \+= "\\nYou've won the debate\! " \+ get\_tree().get\_root().get\_node("GameController/CombatSystem").opponent\["defeat\_dialog"\]  
	else:  
		combat\_log.text \+= "\\nYou've lost this debate. Better luck next time."  
	  
	\# Disable all buttons  
	for button in move\_buttons:  
		button.disabled \= true  
	  
	for button in special\_move\_buttons:  
		button.disabled \= true

func \_on\_move\_button\_pressed(index):  
	var move\_id \= move\_buttons\[index\].get\_meta("move\_id")  
	get\_tree().get\_root().get\_node("GameController/CombatSystem").perform\_player\_move(move\_id)

func \_on\_special\_move\_button\_pressed(index):  
	var move\_id \= special\_move\_buttons\[index\].get\_meta("move\_id")  
	get\_tree().get\_root().get\_node("GameController/CombatSystem").perform\_player\_move(move\_id)  
\# Inventory UI Panel  
extends Panel

\# UI components  
var item\_list  
var item\_description  
var item\_icon  
var use\_button  
var drop\_button

func \_ready():  
	item\_list \= $ItemList  
	item\_description \= $ItemDescription  
	item\_icon \= $ItemIcon  
	use\_button \= $UseButton  
	drop\_button \= $DropButton  
	  
	\# Connect signals  
	item\_list.connect("item\_selected", self, "\_on\_item\_selected")  
	use\_button.connect("pressed", self, "\_on\_use\_button\_pressed")  
	drop\_button.connect("pressed", self, "\_on\_drop\_button\_pressed")  
	  
	\# Connect to inventory system signals  
	var inventory\_system \= get\_tree().get\_root().get\_node("GameController/InventorySystem")  
	inventory\_system.connect("item\_added", self, "\_on\_inventory\_changed")  
	inventory\_system.connect("item\_removed", self, "\_on\_inventory\_changed")  
	  
	\# Disable buttons initially  
	use\_button.disabled \= true  
	drop\_button.disabled \= true  
	  
	\# Initial update  
	update\_item\_list()

func update\_item\_list():  
	var inventory\_system \= get\_tree().get\_root().get\_node("GameController/InventorySystem")  
	item\_list.clear()  
	  
	var index \= 0  
	for item\_id in inventory\_system.items:  
		var item\_info \= inventory\_system.get\_item\_info(item\_id)  
		var quantity \= inventory\_system.items\[item\_id\]  
		  
		item\_list.add\_item(item\_info\["name"\] \+ " x" \+ str(quantity))  
		item\_list.set\_item\_metadata(index, item\_id)  
		  
		if item\_info\["icon"\] \!= null:  
			var icon \= load(item\_info\["icon"\])  
			item\_list.set\_item\_icon(index, icon)  
		  
		index \+= 1

func \_on\_item\_selected(index):  
	var item\_id \= item\_list.get\_item\_metadata(index)  
	var inventory\_system \= get\_tree().get\_root().get\_node("GameController/InventorySystem")  
	var item\_info \= inventory\_system.get\_item\_info(item\_id)  
	  
	\# Update description and icon  
	item\_description.text \= item\_info\["description"\]  
	  
	if item\_info\["icon"\] \!= null:  
		item\_icon.texture \= load(item\_info\["icon"\])  
	else:  
		item\_icon.texture \= null  
	  
	\# Enable/disable buttons based on item properties  
	use\_button.disabled \= \!item\_info\["usable"\]  
	drop\_button.disabled \= false

func \_on\_use\_button\_pressed():  
	var selected\_index \= item\_list.get\_selected\_items()  
	if selected\_index.size() \> 0:  
		var item\_id \= item\_list.get\_item\_metadata(selected\_index\[0\])  
		var inventory\_system \= get\_tree().get\_root().get\_node("GameController/InventorySystem")  
		inventory\_system.use\_item(item\_id)

func \_on\_drop\_button\_pressed():  
	var selected\_index \= item\_list.get\_selected\_items()  
	if selected\_index.size() \> 0:  
		var item\_id \= item\_list.get\_item\_metadata(selected\_index\[0\])  
		var inventory\_system \= get\_tree().get\_root().get\_node("GameController/InventorySystem")  
		inventory\_system.remove\_item(item\_id, 1\)

func \_on\_inventory\_changed(item\_id, quantity):  
	update\_item\_list()  
	  
	\# Reset selection  
	item\_description.text \= ""  
	item\_icon.texture \= null  
	use\_button.disabled \= true  
	drop\_button.disabled \= true

\# Relationship UI Panel

extends Panel

\# UI components

var npc\_list

var relationship\_info

var relationship\_status

var relationship\_value

var last\_interactions

func \_ready():

	npc\_list \= $NPCList

	relationship\_info \= $RelationshipInfo

	relationship\_status \= $RelationshipStatus

	relationship\_value \= $RelationshipValue

	last\_interactions \= $LastInteractions

	

	\# Connect signals

	npc\_list.connect("item\_selected", self, "\_on\_npc\_selected")

	

	\# Connect to relationship system signals

	var relationship\_system \= get\_tree().get\_root().get\_node("GameController/RelationshipSystem")

	

	\# Initial update

	update\_npc\_list()

func update\_npc\_list():

	var relationship\_system \= get\_tree().get\_root().get\_node("GameController/RelationshipSystem")

	npc\_list.clear()

	

	for npc\_id in relationship\_system.relationships:

		var npc\_info \= relationship\_system.npc\_database\[npc\_id\]

		var relationship \= relationship\_system.relationships\[npc\_id\]

		

		\# Add to list

		npc\_list.add\_item(npc\_info\["name"\])

		npc\_list.set\_item\_metadata(npc\_list.get\_item\_count() \- 1, npc\_id)

		

		\# Set icon based on relationship status

		var status\_icon

		match relationship\["status"\]:

			RelationshipStatus.STRANGER:

				status\_icon \= preload("res://assets/icons/stranger\_icon.png")

			RelationshipStatus.ACQUAINTANCE:

				status\_icon \= preload("res://assets/icons/acquaintance\_icon.png")

			RelationshipStatus.FRIEND:

				status\_icon \= preload("res://assets/icons/friend\_icon.png")

			RelationshipStatus.CLOSE\_FRIEND:

				status\_icon \= preload("res://assets/icons/close\_friend\_icon.png")

			RelationshipStatus.ROMANTIC:

				status\_icon \= preload("res://assets/icons/romantic\_icon.png")

		

		if status\_icon:

			npc\_list.set\_item\_icon(npc\_list.get\_item\_count() \- 1, status\_icon)

func \_on\_npc\_selected(index):

	var npc\_id \= npc\_list.get\_item\_metadata(index)

	var relationship\_system \= get\_tree().get\_root().get\_node("GameController/RelationshipSystem")

	var npc\_info \= relationship\_system.npc\_database\[npc\_id\]

	var relationship \= relationship\_system.relationships\[npc\_id\]

	

	\# Update relationship info

	relationship\_info.text \= relationship\_system.get\_relationship\_description(npc\_id)

	

	\# Set status text

	var status\_text

	match relationship\["status"\]:

		RelationshipStatus.STRANGER:

			status\_text \= "Stranger"

		RelationshipStatus.ACQUAINTANCE:

			status\_text \= "Acquaintance"

		RelationshipStatus.FRIEND:

			status\_text \= "Friend"

		RelationshipStatus.CLOSE\_FRIEND:

			status\_text \= "Close Friend"

		RelationshipStatus.ROMANTIC:

			status\_text \= "Romantic Interest"

	

	relationship\_status.text \= "Status: " \+ status\_text

	

	\# Set value

	relationship\_value.text \= "Progress to next level: " \+ str(relationship\["value"\]) \+ "/100"

	

	\# Show interests and dislikes

	var interests\_text \= "Interests: " \+ ", ".join(npc\_info\["interests"\])

	var dislikes\_text \= "Dislikes: " \+ ", ".join(npc\_info\["dislikes"\])

	

	\# Update last interactions

	last\_interactions.text \= "Last Interactions:\\n"

	if "interactions" in relationship and relationship\["interactions"\].size() \> 0:

		for i in range(min(5, relationship\["interactions"\].size())):

			var interaction \= relationship\["interactions"\]\[relationship\["interactions"\].size() \- 1 \- i\]

			last\_interactions.text \+= "- " \+ interaction\["type"\] \+ ": " \+ interaction\["details"\] \+ "\\n"

	else:

		last\_interactions.text \+= "No interactions yet."

\# Quest Log UI Panel

extends Panel

\# UI components

var quest\_list

var quest\_title

var quest\_description

var objectives\_list

var rewards\_list

func \_ready():

	quest\_list \= $QuestList

	quest\_title \= $QuestTitle

	quest\_description \= $QuestDescription

	objectives\_list \= $ObjectivesList

	rewards\_list \= $RewardsList

	

	\# Connect signals

	quest\_list.connect("item\_selected", self, "\_on\_quest\_selected")

	

	\# Connect to quest system signals

	var quest\_system \= get\_tree().get\_root().get\_node("GameController/QuestSystem")

	quest\_system.connect("quest\_started", self, "\_on\_quest\_changed")

	quest\_system.connect("quest\_completed", self, "\_on\_quest\_changed")

	quest\_system.connect("quest\_failed", self, "\_on\_quest\_changed")

	quest\_system.connect("quest\_objective\_updated", self, "\_on\_objective\_updated")

	

	\# Initial update

	update\_quest\_list()

func update\_quest\_list():

	var quest\_system \= get\_tree().get\_root().get\_node("GameController/QuestSystem")

	quest\_list.clear()

	

	\# Add active quests

	for quest\_id in quest\_system.active\_quests:

		var quest \= quest\_system.active\_quests\[quest\_id\]

		quest\_list.add\_item(quest\["title"\])

		quest\_list.set\_item\_metadata(quest\_list.get\_item\_count() \- 1, quest\_id)

func \_on\_quest\_selected(index):

	var quest\_id \= quest\_list.get\_item\_metadata(index)

	var quest\_system \= get\_tree().get\_root().get\_node("GameController/QuestSystem")

	var quest \= quest\_system.active\_quests\[quest\_id\]

	

	\# Update quest info

	quest\_title.text \= quest\["title"\]

	quest\_description.text \= quest\["description"\]

	

	\# Update objectives

	objectives\_list.clear()

	for objective\_id in quest\["objectives"\]:

		var objective \= quest\["objectives"\]\[objective\_id\]

		var progress\_text \= quest\_system.get\_objective\_progress(quest\_id, objective\_id)

		objectives\_list.add\_item(progress\_text)

	

	\# Update rewards

	rewards\_list.clear()

	var rewards \= quest\["rewards"\]

	

	if "items" in rewards:

		for item\_id in rewards\["items"\]:

			var quantity \= rewards\["items"\]\[item\_id\]

			var item\_name \= get\_tree().get\_root().get\_node("GameController/InventorySystem").get\_item\_info(item\_id)\["name"\]

			rewards\_list.add\_item("Item: " \+ item\_name \+ " x" \+ str(quantity))

	

	if "relationships" in rewards:

		for npc\_id in rewards\["relationships"\]:

			var value \= rewards\["relationships"\]\[npc\_id\]

			var npc\_name \= get\_tree().get\_root().get\_node("GameController/RelationshipSystem").npc\_database\[npc\_id\]\["name"\]

			rewards\_list.add\_item("Relationship: " \+ npc\_name \+ " " \+ (value \> 0 ? "+" : "") \+ str(value))

	

	if "player\_stats" in rewards:

		for stat in rewards\["player\_stats"\]:

			var value \= rewards\["player\_stats"\]\[stat\]

			rewards\_list.add\_item("Stat: " \+ stat.capitalize() \+ " \+" \+ str(value))

	

	if "theatrical\_move" in rewards:

		var move\_name \= get\_tree().get\_root().get\_node("GameController/CombatSystem").theatrical\_moves\[rewards\["theatrical\_move"\]\]\["name"\]

		rewards\_list.add\_item("Unlock: " \+ move\_name \+ " move")

func \_on\_quest\_changed(quest\_id, rewards \= null):

	update\_quest\_list()

	

	\# Reset selection

	quest\_title.text \= ""

	quest\_description.text \= ""

	objectives\_list.clear()

	rewards\_list.clear()

func \_on\_objective\_updated(quest\_id, objective\_id, objective):

	\# If this quest is currently selected, update its display

	var selected\_indices \= quest\_list.get\_selected\_items()

	if selected\_indices.size() \> 0:

		var selected\_quest\_id \= quest\_list.get\_item\_metadata(selected\_indices\[0\])

		if selected\_quest\_id \== quest\_id:

			\_on\_quest\_selected(selected\_indices\[0\])

\# Power Menu UI Panel

extends Panel

\# UI components

var power\_list

var power\_description

var cooldown\_label

var use\_button

func \_ready():

	power\_list \= $PowerList

	power\_description \= $PowerDescription

	cooldown\_label \= $CooldownLabel

	use\_button \= $UseButton

	

	\# Connect signals

	power\_list.connect("item\_selected", self, "\_on\_power\_selected")

	use\_button.connect("pressed", self, "\_on\_use\_button\_pressed")

	

	\# Connect to magic system signals

	var magic\_system \= get\_tree().get\_root().get\_node("GameController/MagicSystem")

	magic\_system.connect("power\_unlocked", self, "\_on\_power\_changed")

	magic\_system.connect("power\_used", self, "\_on\_power\_changed")

	

	\# Disable button initially

	use\_button.disabled \= true

	

	\# Initial update

	update\_power\_list()

func update\_power\_list():

	var magic\_system \= get\_tree().get\_root().get\_node("GameController/MagicSystem")

	power\_list.clear()

	

	for power\_id in magic\_system.unlocked\_powers:

		var power\_info \= magic\_system.get\_power\_info(power\_id)

		

		power\_list.add\_item(power\_info\["name"\])

		power\_list.set\_item\_metadata(power\_list.get\_item\_count() \- 1, power\_id)

		

		\# Gray out if on cooldown

		if power\_info\["cooldown\_remaining"\] \> 0:

			power\_list.set\_item\_custom\_fg\_color(power\_list.get\_item\_count() \- 1, Color(0.5, 0.5, 0.5))

func \_on\_power\_selected(index):

	var power\_id \= power\_list.get\_item\_metadata(index)

	var magic\_system \= get\_tree().get\_root().get\_node("GameController/MagicSystem")

	var power\_info \= magic\_system.get\_power\_info(power\_id)

	

	\# Update description

	power\_description.text \= power\_info\["description"\]

	

	\# Update cooldown

	if power\_info\["cooldown\_remaining"\] \> 0:

		var minutes \= power\_info\["cooldown\_remaining"\] / 60

		var seconds \= power\_info\["cooldown\_remaining"\] % 60

		cooldown\_label.text \= "Cooldown: " \+ str(minutes) \+ "m " \+ str(seconds) \+ "s"

		use\_button.disabled \= true

	else:

		cooldown\_label.text \= "Ready to use"

		use\_button.disabled \= false

func \_on\_use\_button\_pressed():

	var selected\_index \= power\_list.get\_selected\_items()

	if selected\_index.size() \> 0:

		var power\_id \= power\_list.get\_item\_metadata(selected\_index\[0\])

		

		\# Show target selection if needed

		\# For simplicity, we'll just use the current location as the target

		var target \= get\_tree().get\_root().get\_node("GameController/WorldController").current\_location

		

		var magic\_system \= get\_tree().get\_root().get\_node("GameController/MagicSystem")

		var effect \= magic\_system.use\_power(power\_

		var effect \= magic\_system.use\_power(power\_id, target)

		

		if effect \!= null:

			\# Show effect notification

			get\_tree().get\_root().get\_node("GameController/UIController").show\_notification("Power Effect: " \+ effect)

		

		\# Update the UI

		update\_power\_list()

		

		\# Reset selection info

		power\_description.text \= ""

		cooldown\_label.text \= ""

		use\_button.disabled \= true

func \_on\_power\_changed(power\_id, target \= null, effect \= null):

	update\_power\_list()

	

	\# Reset selection if no longer valid

	var selected\_indices \= power\_list.get\_selected\_items()

	if selected\_indices.size() \> 0:

		var selected\_power\_id \= power\_list.get\_item\_metadata(selected\_indices\[0\])

		if selected\_power\_id \== power\_id:

			\_on\_power\_selected(selected\_indices\[0\])

\# Save/Load System

extends Node

var save\_path \= "user://love\_lichens\_save.json"

func save\_game():

	var save\_data \= {

		"player\_data": {},

		"inventory": {},

		"relationships": {},

		"quests": {},

		"special\_events": {},

		"unlocked\_powers": {},

		"theatrical\_moves": {},

		"nemesis\_list": {},

		"completed\_quests": \[\],

		"completed\_events": \[\],

		"game\_progress": {},

		"current\_location": ""

	}

	

	\# Get game controller reference

	var game\_controller \= get\_tree().get\_root().get\_node("GameController")

	

	\# Save player data

	save\_data\["player\_data"\] \= game\_controller.player\_data.duplicate(true)

	

	\# Save inventory

	save\_data\["inventory"\] \= game\_controller.inventory\_system.items.duplicate(true)

	

	\# Save relationships

	save\_data\["relationships"\] \= game\_controller.relationship\_system.relationships.duplicate(true)

	

	\# Save active quests

	save\_data\["quests"\] \= game\_controller.quest\_system.active\_quests.duplicate(true)

	save\_data\["completed\_quests"\] \= game\_controller.quest\_system.completed\_quests.duplicate(true)

	

	\# Save special events

	for event\_id in game\_controller.special\_events\_system.special\_events:

		var event \= game\_controller.special\_events\_system.special\_events\[event\_id\]

		save\_data\["special\_events"\]\[event\_id\] \= {

			"active": event\["active"\],

			"start\_time": event\["start\_time"\]

		}

	

	\# Save game progress flags

	save\_data\["game\_progress"\] \= game\_controller.special\_events\_system.game\_progress.duplicate(true)

	

	\# Save unlocked powers

	save\_data\["unlocked\_powers"\] \= game\_controller.magic\_system.unlocked\_powers.duplicate(true)

	save\_data\["power\_cooldowns"\] \= game\_controller.magic\_system.power\_cooldowns.duplicate(true)

	

	\# Save theatrical moves

	for move\_id in game\_controller.combat\_system.theatrical\_moves:

		save\_data\["theatrical\_moves"\]\[move\_id\] \= game\_controller.combat\_system.theatrical\_moves\[move\_id\]\["unlocked"\]

	

	\# Save nemesis data

	save\_data\["nemesis\_list"\] \= game\_controller.combat\_system.nemesis\_list.duplicate(true)

	

	\# Save current location

	save\_data\["current\_location"\] \= game\_controller.world\_controller.current\_location

	

	\# Convert to JSON

	var json\_string \= JSON.print(save\_data)

	

	\# Write to file

	var save\_file \= File.new()

	var error \= save\_file.open(save\_path, File.WRITE)

	if error \== OK:

		save\_file.store\_string(json\_string)

		save\_file.close()

		print("Game saved successfully")

		return true

	else:

		print("Error saving game: " \+ str(error))

		return false

func load\_game():

	var save\_file \= File.new()

	if not save\_file.file\_exists(save\_path):

		print("No save file found")

		return false

	

	var error \= save\_file.open(save\_path, File.READ)

	if error \!= OK:

		print("Error opening save file: " \+ str(error))

		return false

	

	var json\_string \= save\_file.get\_as\_text()

	save\_file.close()

	

	var json\_result \= JSON.parse(json\_string)

	if json\_result.error \!= OK:

		print("Error parsing save data: " \+ str(json\_result.error))

		return false

	

	var save\_data \= json\_result.result

	

	\# Get game controller reference

	var game\_controller \= get\_tree().get\_root().get\_node("GameController")

	

	\# Load player data

	game\_controller.player\_data \= save\_data\["player\_data"\]

	

	\# Load inventory

	game\_controller.inventory\_system.items.clear()

	for item\_id in save\_data\["inventory"\]:

		game\_controller.inventory\_system.items\[item\_id\] \= save\_data\["inventory"\]\[item\_id\]

	

	\# Load relationships

	game\_controller.relationship\_system.relationships.clear()

	for npc\_id in save\_data\["relationships"\]:

		game\_controller.relationship\_system.relationships\[npc\_id\] \= save\_data\["relationships"\]\[npc\_id\]

	

	\# Load quests

	game\_controller.quest\_system.active\_quests.clear()

	for quest\_id in save\_data\["quests"\]:

		game\_controller.quest\_system.active\_quests\[quest\_id\] \= save\_data\["quests"\]\[quest\_id\]

	

	game\_controller.quest\_system.completed\_quests \= save\_data\["completed\_quests"\]

	

	\# Load special events

	for event\_id in save\_data\["special\_events"\]:

		if event\_id in game\_controller.special\_events\_system.special\_events:

			game\_controller.special\_events\_system.special\_events\[event\_id\]\["active"\] \= save\_data\["special\_events"\]\[event\_id\]\["active"\]

			game\_controller.special\_events\_system.special\_events\[event\_id\]\["start\_time"\] \= save\_data\["special\_events"\]\[event\_id\]\["start\_time"\]

	

	\# Load game progress flags

	game\_controller.special\_events\_system.game\_progress \= save\_data\["game\_progress"\]

	

	\# Load unlocked powers

	game\_controller.magic\_system.unlocked\_powers.clear()

	for power\_id in save\_data\["unlocked\_powers"\]:

		game\_controller.magic\_system.unlocked\_powers\[power\_id\] \= save\_data\["unlocked\_powers"\]\[power\_id\]

	

	game\_controller.magic\_system.power\_cooldowns.clear()

	if "power\_cooldowns" in save\_data:

		for power\_id in save\_data\["power\_cooldowns"\]:

			game\_controller.magic\_system.power\_cooldowns\[power\_id\] \= save\_data\["power\_cooldowns"\]\[power\_id\]

	

	\# Load theatrical moves

	for move\_id in save\_data\["theatrical\_moves"\]:

		if move\_id in game\_controller.combat\_system.theatrical\_moves:

			game\_controller.combat\_system.theatrical\_moves\[move\_id\]\["unlocked"\] \= save\_data\["theatrical\_moves"\]\[move\_id\]

	

	\# Load nemesis data

	game\_controller.combat\_system.nemesis\_list.clear()

	for nemesis\_name in save\_data\["nemesis\_list"\]:

		game\_controller.combat\_system.nemesis\_list\[nemesis\_name\] \= save\_data\["nemesis\_list"\]\[nemesis\_name\]

	

	\# Load current location and update world

	var new\_location \= save\_data\["current\_location"\]

	game\_controller.world\_controller.current\_location \= new\_location

	

	print("Game loaded successfully")

	return true


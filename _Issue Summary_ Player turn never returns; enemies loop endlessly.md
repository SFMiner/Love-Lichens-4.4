### **🐛 Issue Summary: Player turn never returns; enemies loop endlessly**

**Observed behavior:**  
 In the current implementation, after the player performs an action (attack, skill, or item), the game does not return control to the player. Instead, enemies continuously attack in a loop, creating duplicate UI nodes and repeatedly calling `update_appearance()`.

---

### **📂 Key Files & Functions Involved**

#### **1\. `combat_ui.gd`**

* `process_player_action(action: Dictionary)`

  * This function handles player actions and appears to call **both**:

    * `combat_manager.advance_turn()`

    * `combat_manager.end_turn()`

  * It sets `ui_state = State.RESOLVING_ACTION` at the start and `ui_state = State.IDLE` before or after ending the turn.

  * Each action type (`attack`, `skill`, `item`) also calls `combat_manager.end_turn()` again **after** already advancing the turn.

---

#### **2\. `combat_initializer.gd`**

* `func _on_action_selected(action, combat_ui, combat_manager)`

  * Calls `combat_ui.process_player_action(action)`

---

#### **3\. `combat_manager.gd` (assumed)**

* `advance_turn()` and `end_turn()` manage combat turns.

* If both are called in succession, this may cause multiple enemies to act in a single round or skip over the player entirely.

---

### **🧠 Diagnosis**

Calling both `advance_turn()` and `end_turn()` inside `process_player_action()` is likely causing:

* The turn order to skip the player

* Enemies to re-enter the queue without player input

* Opponent UI entries to be duplicated (re-instantiated each time enemies attack)

---

### **✅ Suggested Fix**

Use **only one** of the two:

* Either `advance_turn()` if it leads to `end_turn()` elsewhere

* Or just `end_turn()` if it handles everything internally

Refactor `process_player_action()` to rely on a single, clean transition mechanism to the next turn.


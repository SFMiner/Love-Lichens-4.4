# **Test Quest: Poison's Memory Chain**

## **📋 Quest Title:**

**"Memories in the Thread"**

## **📜 Quest Description:**

Poison carries a necklace containing the ashes of their grandfather, affectionately known as Pee-Paw. Through careful observation and conversation, Adam can uncover stories about Poison's past and build a stronger bond of trust.

---

## **🛤️ Quest Flow:**

### **1\. Initial Discovery**

* **Trigger:** Player uses **Look At** on Poison.

* **Effect:**

  * Set tag: `poison_necklace_seen`

  * Display text:

	 "Poison’s wearing a small metal vial necklace. It catches the light strangely, and they touch it without seeming to realize."

* **Unlock Dialogue Choice:**

   "What's that necklace you're wearing?"

---

### **2\. Learning About Pee-Paw**

* **Trigger:** Player asks about the necklace.

* **Effect:**

  * Set tag: `poison_peepaw_known`

  * Display text:

	 "Poison laughs awkwardly, explaining it holds some of Pee-Paw’s ashes. A way of keeping family close, even now."

* **Unlock Dialogue Choice (now or later):**

   "Tell me about your Pee-Paw."

---

### **3\. Deeper Memory Unlock**

* **Trigger:** Player overhears or participates in a conversation about family (e.g., Dusty mentions missing their grandmother).

* **Condition:** Must have `poison_peepaw_known` tag active.

* **Effect:**

  * Set tag: `poison_peepaw_memory_stirred`

  * Poison offers, quietly:

	 "Hey... remind me later. I got a story about Pee-Paw. Might make you laugh."

---

### **4\. Final Memory Story**

* **Trigger:** Adam follows up (special option appears once they’re alone or resting).

* **Effect:**

  * Dialogue:

	 "*Poison recounts sitting on a creaky porch swing, drinking gas station root beer, while Pee-Paw solemnly advised them: 'If you ever find yourself on a roof with a goat and a weathervane, bet on the goat.'*"

* **Reward:**

  * Relationship points with Poison.

  * Quiet emotional payoff: the player understands more about Poison’s roots and resilience.

---

✅ **Designed to feel natural and emotional, not mechanical.**  
 ✅ **Fully optional — can be missed if players aren’t observant.**

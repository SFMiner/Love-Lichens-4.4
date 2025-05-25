
# In-Game Phone Interface System – Technical Specification

## Purpose
A modular phone interface that allows the player to access various apps, each representing different narrative channels (texts, social media, email, photos, etc.). It is implemented as a full-screen UI built around a base phone scene. All content is drawn from tagged resources and optionally handled through the Dialogue Manager plugin for interaction.

---

## Architecture

### 1. PhoneScene (Main Container)
The main Control scene representing the phone. It persists as the foundational visual and interaction layer.

#### Primary Children:
```
PhoneScene (Control)
├── PhoneCase (Texture/UI Elements, for now represent with ColorRect, will change to TextureRect later)
├── PhoneScreen
│   ├──PhoneShell (Texture/UI Elements, for now use a Panel, may/may not change to TextureRect)
│      ├── PhoneIcons (HBoxClockLabel (Label)
│      │   ├── BatteryIcon
│      │   ├── SignalIcon
│      │   └── AppGrid (GridContainer)
│      │── AppButton_Messages (All buttons in this should be square, like the usual 
│      │   │   home screen on a normal smartphone; make the grid 4 buttons wide.)
│      │   ├── AppButton_Messages
│      │   ├── AppButton_Discord
│      │   ├── AppButton_SocialFeed
│      │   ├── AppButton_Journal
│      │   ├── AppButton_Email
│      │   ├── AppButton_Grades
│      │   ├── AppButton_Snake
│      │   ├── AppButton_CameraRoll
│      │   ├── AppButton_Spore
│      ├── AppPanel (Control)  → Loads active app scenes here
│      ├── BackButton (Button) → Closes current app and returns to home screen
├── PopupLayer (Control, optional) → Global overlays like image viewers
└── TransitionLayer (optional) → Animations for switching apps
```
Notes:
	1. BackButton should appear to be part of the PhoneCase, so it should not overlap the PhoneScreen. 
		(This is in place)
	2. The children of PhoneIcons have not yet been added.
	3. EACH of the apps, when opened, MUST befit inside PhoneScreen, which represents the screen.
		(This is not yet the case: CameraApp extends past the edges of both PhoneScreen and AppPanel, and I can't tell why)
---



### 2. App Loading
Apps are modular `.tscn` scenes loaded dynamically into `AppPanel`.

- Only one app is active at a time
- On app open:
  - If `AppPanel` has a child, free it
  - Load and instance new app into `AppPanel`
- On close:
  - Free active app
  - Return view to PhoneShell (home screen)

---

## 3. App Template Specification
Each app is a Control scene containing its own layout and logic. All apps must be able to:
- Run independently
- Accept tagged data entries
- Integrate with Dialogue Manager if applicable

---

## 4. Supported Apps and Core Features

### MessagesApp
- SMS-style chat interface
- One `DialogueRunner` per conversation thread
- Timestamp per message
- Displays avatar, name, and timestamp

### DiscordApp
- Simulated group chat view (scrolling log)
- One `DialogueRunner` per session (e.g., daily or topic-based)
- Timestamp header per block
- Username, icon, and message body display

### SocialFeedApp
- Scrollable feed of social posts
- Each post can be a single Dialogue node or static text
- Timestamps below each post
- Image thumbnails optional

### JournalApp
- Static long-form entries
- One entry per tagged resource
- Optional timestamp and title per entry
- Read-only text

### EmailApp
- Email list view: subject, sender, date
- Click to open full message view
- Timestamps in both list and message view
- Attachment support: image or audio links

### GradesApp
- Table: Course | Professor | Grade
- Clicking entries can open related dialogue nodes or notes
- Distorted or glitched entries are possible for narrative effect

### SnakeApp
- A very simple "Snake" game, on one non-scrolling screen
	- Start screen
	- Player moves "Snake" which grows as it consumes randomly-spawning dots.
	- Snake moves only in straight lines up, down, left, and right
	- Snake is cont4rolled by the same bvuttons as the player (see player.gd for action names)
	- Body of snake follows the exact path of the "head"
	- If the head crashes into (movces into) a space taken up by any part of its trailing body, the game is over.
	- Game Over scene upon game ending
	- Play Again? cene with restart icon to restart game.

### CameraRollApp
- Grid of image thumbnails (tagged)
- Clicking opens viewer:
  - Full image
  - Caption/description
  - Metadata panel: timestamp, tags, source
- Images are tagged on creation/import
- Timestamps displayed only when viewing metadata
- Supports standard and anomalous time formats

### SporeApp
- Displayed as a normal app button
- No internal narrative behavior defined in this system
- Exists as a triggerable interface element

---

## 5. Tag Integration
All app content is tagged using your existing tag framework (shared with quests/dialogue). Each resource entry (image, message thread, post, etc.) must support:

- One or more tags for filtering/unlocking (e.g., `#owner_photo`, `#event_014`, `#location_dorm`)
- Timestamps, optional per entry
- Source metadata (for distinguishing player-created vs. inherited data)

---

## 6. Timestamps by App

| App            | Displayed Where           | Frequency                     |
|----------------|---------------------------|-------------------------------|
| Messages       | Next to each message      | Every message                 |
| Discord        | Above each block/session  | Per grouped conversation      |
| Social Feed    | Below each post           | Per post                      |
| Journal        | Top of entry (optional)   | Per entry                     |
| Email          | List view and message     | Standard per message          |
| Camera Roll    | Metadata panel (on click) | Hidden until viewed           |

Timestamps support full formatting flexibility, including unconventional or anomalous formats (e.g., “417 million BCE”).

---

## 7. Multimedia Handling

- **Images**: Displayed as thumbnails or full-screen textures
- **Videos/GIFs**: Optional support via `AnimatedTexture` or embedded player
- **Audio**: Optional playback UI for voice memos or ambient sounds
- **PopupLayer** may be used for shared media viewers across all apps

---

## 8. Dialogue System Integration

- **Text source** The branching conversations are stored int he *.dialogue files in data/dialogues
- **Dialogue system** The dialogue system handles both branching dialogue and player dialogue options, and should be used for each active exchange
- **Persistent text** The DialogueBalloon scene and script used by the dialogue system holds only one exchange at a time. For most apps (DiscrdApp, MessagesApp, Email), the information from each exchange must be taken from this eschange and stored in a running RichTextLabel which is iteself child of a ScrollContainer, to resemble an actrual app of the same nature.
- **Dialogue system files** 
  - res://scripts/autoloads/DialogueSystem
  - res://scripts/autoloads/DialogueMemoryExtension
  - res://scripts/ui/DialoguePanel
  - res://scenes/ui/DialogueBalloon
  - res://addons/dialogue_manager/
---

## 9. UX Features

- **Back button** exits app and returns to home screen
- **Bookmarking** (optional): store references to messages/posts/images
- **TransitionLayer** (optional): tween/fade animations between app loads
- **Search or filter bar** (optional): filter entries by tag or keyword

---

This structure provides a clean, extensible phone UI that integrates seamlessly with your branching dialogue, media-driven storytelling, and magical-realist world logic.

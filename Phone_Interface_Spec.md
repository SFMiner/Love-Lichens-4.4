
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
├── PhoneShell (Texture/UI Elements)
│   ├── ClockLabel
│   ├── BatteryIcon
│   ├── SignalIcon
│   └── AppGrid (GridContainer)
│       ├── AppButton_Messages
│       ├── AppButton_Discord
│       ├── AppButton_SocialFeed
│       ├── AppButton_Journal
│       ├── AppButton_Email
│       ├── AppButton_Grades
│       ├── AppButton_CameraRoll
│       ├── AppButton_Spore
├── AppPanel (Control)  → Loads active app scenes here
├── BackButton (Button) → Closes current app and returns to home screen
├── PopupLayer (Control, optional) → Global overlays like image viewers
└── TransitionLayer (optional) → Animations for switching apps
```

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

## 8. UX Features

- **Back button** exits app and returns to home screen
- **Bookmarking** (optional): store references to messages/posts/images
- **TransitionLayer** (optional): tween/fade animations between app loads
- **Search or filter bar** (optional): filter entries by tag or keyword

---

This structure provides a clean, extensible phone UI that integrates seamlessly with your branching dialogue, media-driven storytelling, and magical-realist world logic.

extends Control

# EmailApp.gd
# Conceptual structure:
# 1. EmailListView (ScrollContainer > VBoxContainer of EmailItemButtons)
#    - Each EmailItemButton shows: Sender, Subject, Snippet, Timestamp, Read/Unread status.
#    - Clicking an EmailItemButton opens FullEmailView for that email.
# 2. FullEmailView (ScrollContainer > VBoxContainer)
#    - Header: Subject, Sender, Recipient(s), Timestamp.
#    - Body: RichTextLabel for email content (HTML-like or BBCode).
#    - Actions: Reply (optional), Delete (optional), Mark Unread.
#    - "Back to List" button in header.
# Data will come from a DialogueManager-like system or a dedicated EmailDataManager.

func _ready():
    print("EmailApp placeholder ready.")
    # pass # Implement UI and logic here

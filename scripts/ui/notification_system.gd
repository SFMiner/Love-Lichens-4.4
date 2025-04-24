# notification_system.gd
extends CanvasLayer

const NOTIFICATION_DURATION = 2.0  # seconds

var notification_queue = []
var is_showing = false

@onready var notification_panel = $NotificationPanel
@onready var notification_label = $NotificationPanel/Label

func _ready():
	# Initialize panel
	notification_panel.visible = false

func show_notification(message):
	# Add to queue
	notification_queue.append(message)
	
	# If not already showing a notification, start now
	if not is_showing:
		_process_next_notification()

func _process_next_notification():
	if notification_queue.size() > 0:
		is_showing = true
		var message = notification_queue.pop_front()
		
		# Show panel and set text
		notification_label.text = message
		notification_panel.visible = true
		
		# Create timer to hide
		var timer = get_tree().create_timer(NOTIFICATION_DURATION)
		timer.timeout.connect(_on_notification_timer_timeout)
	else:
		is_showing = false
		notification_panel.visible = false

func _on_notification_timer_timeout():
	# Hide current notification and process next
	notification_panel.visible = false
	is_showing = false
	_process_next_notification()

# Convenience function for showing item pickup
func show_item_pickup(item_name, amount=1):
	var message = "Picked up: " + item_name
	if amount > 1:
		message += " x" + str(amount)
	show_notification(message)

# Convenience function for showing item drop
func show_item_drop(item_name, amount=1):
	var message = "Dropped: " + item_name
	if amount > 1:
		message += " x" + str(amount)
	show_notification(message)

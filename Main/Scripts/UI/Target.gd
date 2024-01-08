extends FollowWorldPosition
class_name Target

@export var panel: Panel

@export_category("Panel Dimensions")
@export var unselected_dimensions: Vector4
@export var selected_dimensions: Vector4

var selected : bool:
	set(value):
		if value:
			panel.anchor_left = selected_dimensions.x
			panel.anchor_top = selected_dimensions.y
			panel.anchor_right = selected_dimensions.z
			panel.anchor_bottom = selected_dimensions.w
		else:
			panel.anchor_left = unselected_dimensions.x
			panel.anchor_top = unselected_dimensions.y
			panel.anchor_right = unselected_dimensions.z
			panel.anchor_bottom = unselected_dimensions.w
		selected = value
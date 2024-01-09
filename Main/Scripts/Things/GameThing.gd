extends Node3D
class_name GameThing

# Called when the node enters the scene tree for the first time.
func _ready():
	health = max_health
	
	for path in inventory_paths:
		var node = get_node(path)
		# print("Node fetched for path: ", path, " is: ", node)
		if node:
			inventory.append(node)
	# print("Final Inventory:", inventory)

# Variables
@export_category("Variables")
@export var thing_name : String
@export var thing_description : String = ""
@export var thing_value : int = 0
@export var thing_weight : int = 5
@export var variables: Dictionary

var thing_type : String
var thing_subtype : String

@export_category("Inventory")
@export var inventory_paths : Array[NodePath] = []
var inventory : Array = []

var thing_top: Node3D = null:
	get:
		if thing_top == null:
			thing_top = find_child("Top", true, true)

			if thing_top == null:
				print("No thing_top found for ", name, ". Setting to transform.")
				thing_top = self
			else:
				print("thing_top found for ", name, ": ", thing_top)
		return thing_top
	set(value):
		thing_top = value

var health: int = 0:
	set(value):
		if value < 0:
			value = 0
			die()
		if value > max_health:
			value = max_health
		health = value
	get:
		return health

@export var max_health: int = 10

func damage(amount):
	health -= amount

# Functions
func _init():
	thing_type = "Game"
	thing_subtype = "Game"

func die():
	# Destroy self
	if !is_queued_for_deletion():
		print("Dying!")
		queue_free()

func move(_direction):
	pass

func aim(_direction):
	pass
	
func primary(_pressed):
	pass

func secondary(_pressed):
	pass

func tertiary(_pressed):
	pass

func quaternary(_pressed):
	pass

func left_trigger(_pressed):
	pass

func right_trigger(_pressed):
	pass

func previous_target(_pressed):
	pass

func next_target(_pressed):
	pass

func pause(_pressed):
	pass

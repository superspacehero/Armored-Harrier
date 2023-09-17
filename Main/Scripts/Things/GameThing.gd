extends Node3D
class_name GameThing

# Called when the node enters the scene tree for the first time.
func _ready():
	# max_health = variables.GetVariable("health")
	health = maxHealth
	
	for path in inventory_paths:
		var node = get_node(path)
		# print("Node fetched for path: ", path, " is: ", node)
		if node and node is GameThing:
			inventory.append(node)
			# print("Node added to inventory: ", node)
		else:
			printerr("Node at path %s is not a GameThing!" % path)
	print("Final Inventory:", inventory)

# Variables
var thingName : String
var thingDescription : String = ""

@export var inventory_paths : Array[NodePath] = []
var inventory : Array[GameThing] = []

var thing_top: Node3D = null:
	get:
		if _thing_top == null:
			_thing_top = find_child("Top", true, true)
		if _thing_top == null:
			print("No thing_top found for", name, ". Setting to transform.")
			_thing_top = self
		return _thing_top
var _thing_top: Node

var health: int = 0:
	set(value):
		if value < 0:
			value = 0
			die()
		if value > maxHealth:
			value = maxHealth
		health = value
	get:
		return health

var maxHealth: int = 100

# Functions

func die():
	print("Dying!")
	# Destroy self
	queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func move(direction):
	print("Moving in direction: ", direction)
	pass

func aim(direction):
	pass
	
func primary(pressed):
	pass

func secondary(pressed):
	pass

func tertiary(pressed):
	pass

func quaternary(pressed):
	pass

func left_trigger(pressed):
	pass

func right_trigger(pressed):
	pass

func pause(pressed):
	pass

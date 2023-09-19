extends Resource
class_name CharacterInfo

# An array to store the paths to the PackedScene of each character part.
var character_parts: Array

# Additional variables related to the character (e.g., stats, energy).
var energy = 100
var speed = 10

# Methods to serialize and deserialize the data to/from JSON.
func to_json() -> String:
	var data = {
		"parts": character_parts,
		"energy": energy,
		"speed": speed
	}
	return to_json()

func from_json(json_string: String):
	var data = from_json(json_string)
	character_parts = data["parts"]
	energy = data["energy"]
	speed = data["speed"]

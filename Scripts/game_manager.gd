extends Node
var score = 0
@onready var score_label: Label = get_node("/root/Game/UI/ScoreLabel")

func add_point():
	score += 1
	score_label.text = " " + str(score) + " coins."
 
func _on_body_entered(body: Node2D) -> void:
	pass # Replace with function body.

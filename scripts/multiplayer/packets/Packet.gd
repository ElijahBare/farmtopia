class_name Packet
extends RefCounted

var packet_type: String

func _init(type: String):
	packet_type = type

func to_dict() -> Dictionary:
	return {}

func process(world: Node) -> void:
	pass

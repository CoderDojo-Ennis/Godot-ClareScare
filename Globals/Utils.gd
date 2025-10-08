extends Node
## Utility functions for Godot Engine projects

## Finds the nearest ancestor of a given node that belongs to a specified group.
func FindParentWithGroup(node: Node, group_name: String) -> Node:
	var current_node = node
	while current_node:
		if current_node.is_in_group(group_name):
			return current_node
		current_node = current_node.get_parent()
	return null

extends TileMap

onready var ground = preload("res://src/environment/Ground.tscn")
onready var ladder = preload("res://src/environment/Ladder.tscn")
onready var decor = preload("res://src/environment/Decor.tscn")

enum TILES {
	GROUND = 0,
	LADDER = 1,
	DECOR = 2
}

#var TILE_NAMES = {
#	TILES.GROUND: "Tiles/Ground",
#	TILES.LADDER: "Tiles/Ladder",
#	TILES.DECOR: "Tiles/Decor",
#}

var TILE_Z = {
	TILES.GROUND: 0,
	TILES.LADDER: -1,
	TILES.DECOR: 1,
}

func _ready():
	#1 - grab all cells in tilemap
	var used_cells_pos = get_used_cells()
	#2 - looped in, replace each cell wtih corresponding tile	
	for cell_pos in used_cells_pos:
		var tile_index = get_cellv(cell_pos)
		
		var new_tile
		match tile_index:
			TILES.GROUND: #ground
				new_tile = ground.instance()
			TILES.LADDER: # ladder
				new_tile = ladder.instance() 
			TILES.DECOR: # decor
				new_tile = decor.instance()
				pass
		#3 - Add to get_parent().get_node("Tiles")
		new_tile.position = map_to_world(cell_pos)
		new_tile.z_index = TILE_Z[tile_index]
		set_cellv(cell_pos, -1)
		get_parent().get_node("Tiles").add_child(new_tile)
	#queue_free() - deferred to keep decor
	pass

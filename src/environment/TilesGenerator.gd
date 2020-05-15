extends TileMap

onready var ground = preload("res://src/environment/Ground.tscn")
onready var mid_ground = preload("res://src/environment/MidGround.tscn")
onready var ladder = preload("res://src/environment/Ladder.tscn")
onready var decor = preload("res://src/environment/Decor.tscn")
onready var spikes = preload("res://src/environment/Spikes.tscn")
onready var floating_spikes = preload("res://src/environment/FloatingSpikes.tscn")

var tile_exists = true
enum TILES {
	GROUND = 0,
	LADDER = 1,
	DECOR = 2,
	SPIKES = 3,
	SMALL_TREE = 4,
	BIG_TREE = 5
	FLOATING_SPIKES = 6,
	HANGING_SPIKES = 7
	MID_GROUND = 8
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
	TILES.SPIKES: -1,
	TILES.BIG_TREE: -1,
	TILES.SMALL_TREE: -1,
	TILES.FLOATING_SPIKES: 0,
	TILES.HANGING_SPIKES: -1,
	TILES.MID_GROUND: 0,
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
			TILES.MID_GROUND: #ground
				new_tile = mid_ground.instance()	
			TILES.LADDER: # ladder
				new_tile = ladder.instance() 
			TILES.DECOR: # decor
				new_tile = decor.instance()
			TILES.SPIKES: # decor
				new_tile = spikes.instance()
			TILES.FLOATING_SPIKES: # decor
				new_tile = floating_spikes.instance()
			TILES.HANGING_SPIKES: # decor
				new_tile = spikes.instance()
				new_tile.rotation_degrees = 180
			_:
				tile_exists = false
		if tile_exists:
			new_tile.position = map_to_world(cell_pos)
			new_tile.z_index = TILE_Z[tile_index]
			get_parent().get_node("Tiles").add_child(new_tile)
		set_cellv(cell_pos, -1)		
		tile_exists = true
	#queue_free() - deferred to keep decor
	pass

@tool
extends EditorScript

func _run():
	print("Creating simple item textures...")
	
	# Define texture designs for different item types
	var weapon_designs = {
		"iron_sword.png": {"base": Color.GRAY, "accent": Color.DARK_GRAY, "shape": "sword"},
		"wooden_bow.png": {"base": Color.SADDLE_BROWN, "accent": Color.DARK_GOLDENROD, "shape": "bow"},
		"rusty_dagger.png": {"base": Color.DIM_GRAY, "accent": Color.DARK_RED, "shape": "dagger"},
		"steel_sword.png": {"base": Color.SILVER, "accent": Color.LIGHT_GRAY, "shape": "sword"},
		"legendary_sword.png": {"base": Color.GOLD, "accent": Color.YELLOW, "shape": "sword"}
	}
	
	var consumable_designs = {
		"health_potion.png": {"base": Color.RED, "accent": Color.DARK_RED, "shape": "potion"},
		"mana_potion.png": {"base": Color.BLUE, "accent": Color.DARK_BLUE, "shape": "potion"}
	}
	
	var other_designs = {
		"coin.png": {"base": Color.GOLD, "accent": Color.YELLOW, "shape": "circle"},
		"iron_ore.png": {"base": Color.DIM_GRAY, "accent": Color.GRAY, "shape": "rock"},
		"dragon_scale.png": {"base": Color.DARK_RED, "accent": Color.RED, "shape": "scale"},
		"magic_crystal.png": {"base": Color.CYAN, "accent": Color.WHITE, "shape": "crystal"},
		"magic_ring.png": {"base": Color.PURPLE, "accent": Color.MAGENTA, "shape": "ring"},
		"ancient_artifact.png": {"base": Color.ORANGE, "accent": Color.YELLOW, "shape": "artifact"},
		"fire_gem.png": {"base": Color.ORANGE_RED, "accent": Color.YELLOW, "shape": "gem"}
	}
	
	# Create directories
	ensure_directory("res://textures/items/weapons")
	ensure_directory("res://textures/items/consumables")
	ensure_directory("res://textures/items/materials")
	ensure_directory("res://textures/items/currency")
	ensure_directory("res://textures/items/accessories")
	ensure_directory("res://textures/items/artifacts")
	ensure_directory("res://textures/items/gems")
	
	# Create weapon textures
	for filename in weapon_designs.keys():
		var design = weapon_designs[filename]
		create_item_texture("weapons/" + filename, design.base, design.accent, design.shape)
	
	# Create consumable textures
	for filename in consumable_designs.keys():
		var design = consumable_designs[filename]
		create_item_texture("consumables/" + filename, design.base, design.accent, design.shape)
	
	# Create other textures
	var paths = {
		"coin.png": "currency/",
		"iron_ore.png": "materials/",
		"dragon_scale.png": "materials/",
		"magic_crystal.png": "materials/",
		"magic_ring.png": "accessories/",
		"ancient_artifact.png": "artifacts/",
		"fire_gem.png": "gems/"
	}
	
	for filename in other_designs.keys():
		var design = other_designs[filename]
		var path = paths[filename] + filename
		create_item_texture(path, design.base, design.accent, design.shape)
	
	print("Simple textures created successfully!")
	EditorInterface.get_resource_filesystem().scan()

func ensure_directory(path: String):
	var dir = DirAccess.open("res://")
	if not dir.dir_exists(path):
		dir.make_dir_recursive(path)

func create_item_texture(relative_path: String, base_color: Color, accent_color: Color, shape_type: String):
	var size = Vector2i(32, 32)
	var image = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	match shape_type:
		"sword":
			draw_sword(image, base_color, accent_color, size)
		"dagger":
			draw_dagger(image, base_color, accent_color, size)
		"bow":
			draw_bow(image, base_color, accent_color, size)
		"potion":
			draw_potion(image, base_color, accent_color, size)
		"circle":
			draw_circle(image, base_color, accent_color, size)
		"rock":
			draw_rock(image, base_color, accent_color, size)
		"scale":
			draw_scale(image, base_color, accent_color, size)
		"crystal":
			draw_crystal(image, base_color, accent_color, size)
		"ring":
			draw_ring(image, base_color, accent_color, size)
		"artifact":
			draw_artifact(image, base_color, accent_color, size)
		"gem":
			draw_gem(image, base_color, accent_color, size)
	
	# Add border
	add_border(image, Color.BLACK, size)
	
	var full_path = "res://textures/items/" + relative_path
	var error = image.save_png(full_path)
	if error != OK:
		print("Failed to save: ", full_path)
	else:
		print("Created: ", full_path)

func draw_sword(image: Image, base_color: Color, accent_color: Color, size: Vector2i):
	# Draw blade (vertical rectangle)
	for x in range(14, 18):
		for y in range(4, 24):
			image.set_pixel(x, y, base_color)
	
	# Draw crossguard (horizontal line)
	for x in range(10, 22):
		for y in range(20, 22):
			image.set_pixel(x, y, accent_color)
	
	# Draw handle
	for x in range(15, 17):
		for y in range(22, 28):
			image.set_pixel(x, y, accent_color.darkened(0.3))

func draw_dagger(image: Image, base_color: Color, accent_color: Color, size: Vector2i):
	# Draw blade (smaller than sword)
	for x in range(15, 17):
		for y in range(8, 20):
			image.set_pixel(x, y, base_color)
	
	# Draw handle
	for x in range(14, 18):
		for y in range(20, 24):
			image.set_pixel(x, y, accent_color)

func draw_bow(image: Image, base_color: Color, accent_color: Color, size: Vector2i):
	# Draw bow curve
	for y in range(6, 26):
		var curve_offset = int(abs(y - 16) * 0.3)
		if curve_offset < 8:
			image.set_pixel(8 + curve_offset, y, base_color)
			image.set_pixel(23 - curve_offset, y, base_color)
	
	# Draw string
	for y in range(8, 24):
		image.set_pixel(12, y, accent_color)

func draw_potion(image: Image, base_color: Color, accent_color: Color, size: Vector2i):
	# Draw bottle body
	for x in range(12, 20):
		for y in range(12, 26):
			image.set_pixel(x, y, base_color)
	
	# Draw neck
	for x in range(14, 18):
		for y in range(8, 12):
			image.set_pixel(x, y, base_color.darkened(0.2))
	
	# Draw cork/cap
	for x in range(13, 19):
		for y in range(6, 8):
			image.set_pixel(x, y, accent_color)

func draw_circle(image: Image, base_color: Color, accent_color: Color, size: Vector2i):
	var center = Vector2i(16, 16)
	var radius = 8
	
	for x in range(size.x):
		for y in range(size.y):
			var dist = Vector2i(x, y).distance_to(center)
			if dist <= radius:
				if dist <= radius - 2:
					image.set_pixel(x, y, base_color)
				else:
					image.set_pixel(x, y, accent_color)

func draw_rock(image: Image, base_color: Color, accent_color: Color, size: Vector2i):
	# Draw irregular rock shape
	var points = [
		Vector2i(16, 8), Vector2i(22, 12), Vector2i(20, 20),
		Vector2i(12, 22), Vector2i(10, 16), Vector2i(14, 10)
	]
	
	# Fill roughly rectangular area with some variation
	for x in range(10, 22):
		for y in range(10, 22):
			if (x + y) % 3 != 0:  # Add some texture
				image.set_pixel(x, y, base_color)
			else:
				image.set_pixel(x, y, accent_color)

func draw_scale(image: Image, base_color: Color, accent_color: Color, size: Vector2i):
	# Draw scale shape (teardrop)
	for y in range(8, 24):
		var width = int((24 - y) * 0.5)
		for x in range(16 - width, 16 + width):
			if x >= 0 and x < size.x:
				image.set_pixel(x, y, base_color)
	
	# Add scale lines
	for y in range(10, 22, 2):
		for x in range(12, 20):
			image.set_pixel(x, y, accent_color)

func draw_crystal(image: Image, base_color: Color, accent_color: Color, size: Vector2i):
	# Draw crystal facets
	var center = Vector2i(16, 16)
	
	# Draw diamond shape
	for y in range(8, 24):
		var width = 8 - abs(y - 16) / 2
		for x in range(center.x - width, center.x + width):
			if x >= 0 and x < size.x:
				image.set_pixel(x, y, base_color)
	
	# Add highlight
	for y in range(10, 18):
		image.set_pixel(14, y, accent_color)

func draw_ring(image: Image, base_color: Color, accent_color: Color, size: Vector2i):
	var center = Vector2i(16, 16)
	var outer_radius = 8
	var inner_radius = 5
	
	for x in range(size.x):
		for y in range(size.y):
			var dist = Vector2i(x, y).distance_to(center)
			if dist <= outer_radius and dist >= inner_radius:
				if dist <= outer_radius - 1:
					image.set_pixel(x, y, base_color)
				else:
					image.set_pixel(x, y, accent_color)

func draw_artifact(image: Image, base_color: Color, accent_color: Color, size: Vector2i):
	# Draw mystical artifact (star-like shape)
	var center = Vector2i(16, 16)
	
	# Draw center
	for x in range(14, 18):
		for y in range(14, 18):
			image.set_pixel(x, y, base_color)
	
	# Draw rays
	var rays = [
		Vector2i(0, -6), Vector2i(6, 0), Vector2i(0, 6), Vector2i(-6, 0),
		Vector2i(4, -4), Vector2i(4, 4), Vector2i(-4, 4), Vector2i(-4, -4)
	]
	
	for ray in rays:
		for i in range(1, 4):
			var pos = center + ray.normalized() * i * 2
			if pos.x >= 0 and pos.x < size.x and pos.y >= 0 and pos.y < size.y:
				image.set_pixel(pos.x, pos.y, accent_color)

func draw_gem(image: Image, base_color: Color, accent_color: Color, size: Vector2i):
	# Draw gem (hexagonal)
	for y in range(10, 22):
		var width = 6 - abs(y - 16) / 3
		for x in range(16 - width, 16 + width):
			if x >= 0 and x < size.x:
				image.set_pixel(x, y, base_color)
	
	# Add gem facets
	for x in range(13, 19):
		image.set_pixel(x, 13, accent_color)
		image.set_pixel(x, 19, accent_color)

func add_border(image: Image, border_color: Color, size: Vector2i):
	# Add 1-pixel border
	for x in range(size.x):
		image.set_pixel(x, 0, border_color)
		image.set_pixel(x, size.y - 1, border_color)
	
	for y in range(size.y):
		image.set_pixel(0, y, border_color)
		image.set_pixel(size.x - 1, y, border_color)

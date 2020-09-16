# A star algorithm
static func find_the_path(came_from_map: Dictionary, current_position: Vector2, target_position: Vector2):
    var target_was_found = target_position in came_from_map

    # combine path from came_from_map notes
    if target_was_found:
        if randi() % 100 > 99: print_debug('combine')
        var way_points = [target_position]
        var previous_cell = target_position
        while current_position.distance_squared_to(previous_cell) != 0:
            previous_cell = came_from_map[previous_cell]
            way_points.push_front(previous_cell)

        return way_points
    else:
        return []

static func get_came_from_map(battlefield_data, current_position: Vector2, target_position: Vector2):
    var came_from_map = {}

    var queue = [current_position]
    while (len(queue) != 0):
        if randi() % 100 > 99: print_debug('get came from map')
        var next_position = queue.pop_front()
        if next_position.distance_squared_to(target_position) == 0:
            break

        var neighbors = find_free_neighbour(battlefield_data, next_position, 1)

        for nei in neighbors:
            if not nei in came_from_map:
                came_from_map[nei] = next_position

                var is_nei_in_queue = false
                for pos in queue:
                    if nei.distance_squared_to(pos) == 0:
                        is_nei_in_queue = true
                        break

                if not is_nei_in_queue:
                    queue.push_back(nei)

    return came_from_map

static func find_free_neighbour(battlefield_data, cell_position: Vector2, free_cell_type: int):
    var free_neighbours = []
    for i in range(-1,2):
        for j in range(-1,2):
            if i == cell_position.x and j == cell_position.y:
                continue

            if abs(i) == abs(j):
                continue

            var cell_type = battlefield_data[cell_position.y + j][cell_position.x + i].type
            if free_cell_type == cell_type:
                free_neighbours.push_back(Vector2(cell_position.x + i, cell_position.y + j))

    return free_neighbours

static func convert_tilemap_positions_to_real(tile_map: TileMap, cells_positions):
    var real_positions = []
    var cell_center = Vector2(25, 25)
    for cell_position in cells_positions:
        real_positions.push_back(tile_map.map_to_world(cell_position) + cell_center)

    return real_positions

class_name Zipline extends Path3D

@export var FOLLOW_RATE = 1
@export var DROOP_Y = 10
@export var INSTANCE_DISTANCE = 1.5:
    set(value):
        INSTANCE_DISTANCE = value
        is_dirty = true
@export var END_POS_LOCAL  = Vector3(0,0,1)




@onready var player: CharacterBody3D = get_tree().root.get_children()[0].get_player()
#@onready var END_POS = $END.position


var path_follow
var mm

var direction = 0

var is_dirty = false
var has_player = false

var init_player_pos
var goal = 0
var abs_progress = 0

var start_col
var end_col


func new_collider(pos=null):
    var new_area = Area3D.new()
    add_child(new_area)
    
    if pos:
        var mesh = MeshInstance3D.new()
        mesh.mesh = SphereMesh.new()
        mesh.mesh.radius = 6
        mesh.mesh.height = 6
        new_area.position = pos
        mesh.position = pos
        new_area.add_child(mesh)
    
    var new_col = CollisionShape3D.new()
    new_area.add_child(new_col)
    new_col.shape = preload("res://Zipline/zipline_collision_shape.tres")
    return new_area
     
# Called when the node enters the scene tree for the first time.
func _ready():
    # adding all items to tree
    #curve = preload("res://Zipline/zipline_base_curve.tres")
    curve.add_point(Vector3.ZERO)
    curve.add_point(Vector3.ZERO)
    #curve.set_point_position(0, position)
    print(END_POS_LOCAL)
    curve.set_point_position(1, END_POS_LOCAL)
    var end_in = ( END_POS_LOCAL - END_POS_LOCAL/2 ) * -1
    end_in.y = END_POS_LOCAL.y - DROOP_Y
    curve.set_point_in(1, end_in)
    path_follow = PathFollow3D.new()
    add_child(path_follow)
    # path_follow.loop = false
    
    var multi_mesh = MultiMeshInstance3D.new()
    add_child(multi_mesh)
    multi_mesh.multimesh = MultiMesh.new()
    multi_mesh.multimesh.transform_format = MultiMesh.TRANSFORM_3D
    multi_mesh.multimesh.set_mesh(preload("res://art/particles/zip_mesh.tres"))
    mm = multi_mesh.multimesh
    
    var csg_poly = CSGPolygon3D.new()
    add_child(csg_poly)
    csg_poly.polygon = PackedVector2Array([Vector2(0,0), Vector2(0,0.1), Vector2(0.1,0.1)])
    csg_poly.mode = CSGPolygon3D.MODE_PATH
    csg_poly.set_path_node("..")
    csg_poly.path_local = true
    csg_poly.material = preload("res://Zipline/M_zipline.tres")
    
    start_col = new_collider()
    end_col = new_collider(END_POS_LOCAL)
    
    _update_multimesh()

func toggle_grab_player():
    has_player = true
    init_player_pos = player.position


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    if Input.is_action_just_pressed("jump"):
        if start_col.overlaps_body(player):
            print("this fuck")
            direction = 1
            toggle_grab_player()
    
    if has_player:
        if not abs_progress:
            path_follow.progress_ratio = 0 if direction > 0 else 1
        
        print(abs_progress)
        if abs_progress >= 0.95:
            has_player = false
            abs_progress = 0
        else:
            abs_progress += FOLLOW_RATE * delta
            path_follow.progress_ratio = abs_progress
            #print(path_follow.progress)
            player.position = init_player_pos + path_follow.position
#    if is_dirty:
#        _update_multimesh()
#        is_dirty = false
    pass

func _update_multimesh():
    curve.set_point_position(1, END_POS_LOCAL)
    
    var path_length: float = curve.get_baked_length()
    var count = floor(path_length / INSTANCE_DISTANCE)

    mm.instance_count = count
    var offset = INSTANCE_DISTANCE/2.0

    for i in range(0, count):
        var curve_distance = offset + INSTANCE_DISTANCE * i
        var position = curve.sample_baked(curve_distance, true)

        var basis = Basis()
        
        var up = curve.sample_baked_up_vector(curve_distance, true)
        var forward = position.direction_to(curve.sample_baked(curve_distance + 0.1, true))

        basis.y = up
        basis.x = forward.cross(up).normalized()
        basis.z = -forward
        
        var transform = Transform3D(basis, position)
        mm.set_instance_transform(i, transform)


func _on_curve_changed():
    is_dirty = true

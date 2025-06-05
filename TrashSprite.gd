extends Sprite2D

@export var frames: Array[Vector4] = [
	Vector4(0, 0, 18.609, 64),   
	Vector4(18.386, 0, 40.889, 64),
	Vector4(58.803, 0, 38.519, 64),
	Vector4(96.53, 0, 53.997, 64),
	Vector4(150.008, 0, 55.058, 64),
	Vector4(205.144, 0, 37.145, 64),
	Vector4(241.895, 0, 19.753, 64),
	Vector4(260.66, 0, 25.481, 64),
	Vector4(285.746, 0, 19.358, 64), 
	Vector4(303.919, 0, 25.284, 64), 
	Vector4(328.767, 0, 23.704, 64), 
	Vector4(352.195, 0, 20.148, 64), 
	Vector4(371.903, 0, 30.42, 64), 
	Vector4(402.288, 0, 62.222, 64), 
	Vector4(463.631, 0, 31.605, 64),
	Vector4(494.299, 0, 20.741, 64),
]

func _ready():
	region_enabled = true
	if frames.size() > 0:
		randomize()
		var frame = frames[randi() % frames.size()]
		region_rect = Rect2(frame.x, frame.y, frame.z, frame.w)

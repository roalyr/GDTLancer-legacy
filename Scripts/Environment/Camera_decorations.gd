extends Spatial

func _process(_delta):
	self.global_transform.origin = Paths.camera.global_transform.origin

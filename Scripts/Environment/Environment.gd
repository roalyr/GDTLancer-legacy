extends WorldEnvironment

# GLOBAL VALUES
export var global_brightness = 1.0
export var global_contrast = 1.0
export var global_saturation = 0.0

# Upper limit values so preserve your eyes.
var brightness_cap = 4.0
var contrast_cap = 2.0
var saturation_cap = 0.0

# Global rate of adjustment.
var refresh_rate = 0.05
var increment_step = 0.01

# Individual rates of change (mult. by physical delta).
var brightness_change_rate = 1e-2
var contrast_change_rate = 1e-2
var saturation_change_rate = 1e-2

# INTERNAL VALUES
# Connect to those variables from other scripts.
var brightness_variation = 0.0
var contrast_variation = 0.0
var saturation_variation = 0.0

# Ship velocity effects.
var warp_brightness_variation = 0.0
var warp_brightness_variation_prev = 0.0

# Summary variation
var zone_brightness_variation = 0.0
var zone_contrast_variation = 0.0
var zone_saturation_variation = 0.0

# Different kinds of zones
var nebula_global_brightness_variation = 0.0
var nebula_global_contrast_variation = 0.0
var nebula_global_saturation_variation = 0.0

var nebula_brightness_variation = 0.0
var nebula_contrast_variation = 0.0
var nebula_saturation_variation = 0.0

var system_brightness_variation = 0.0
var system_contrast_variation = 0.0
var system_saturation_variation = 0.0

var star_brightness_variation = 0.0
var star_contrast_variation = 0.0
var star_saturation_variation = 0.0

var planet_brightness_variation = 0.0
var planet_contrast_variation = 0.0
var planet_saturation_variation = 0.0

var structure_brightness_variation = 0.0
var structure_contrast_variation = 0.0
var structure_saturation_variation = 0.0


enum Adjustment_kind {BRIGHTNESS, CONTRAST, SATURATION}

var brightness_increment = 0.0
var contrast_increment = 0.0
var saturation_increment = 0.0


var saturation_delta = 0.0

var timer = 0.0



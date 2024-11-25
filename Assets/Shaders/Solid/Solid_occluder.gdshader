shader_type spatial;

render_mode depth_draw_always, unshaded, vertex_lighting;

void fragment() {
    ALPHA = 0.0;        // Full opacity to ensure depth writes
}

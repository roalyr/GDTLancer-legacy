# This work is marked with CC0 1.0. To view a copy of this license, 
# visit https://creativecommons.org/publicdomain/zero/1.0/

import png

def hex_to_rgb(hex_color):
    hex_color = hex_color.lstrip('#')
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))

def generate_gradient(width, height, flip_gradient, colors, filename):
    total_width = sum(relative_width for _, relative_width in colors)
    normalized_colors = [(color, relative_width / total_width) for color, relative_width in colors]
    
    color_stops = []
    current_position = 0
    for color, relative_width in normalized_colors:
        stop_position = int(current_position + relative_width * width)
        color_stops.append((hex_to_rgb(color), stop_position))
        current_position = stop_position

    gradient = []
    for x in range(width):
        for i in range(len(color_stops) - 1):
            start_color, start_pos = color_stops[i]
            end_color, end_pos = color_stops[i + 1]
            if start_pos <= x < end_pos:
                t = (x - start_pos) / (end_pos - start_pos)
                interpolated_color = tuple(int(start_color[j] * (1 - t) + end_color[j] * t) for j in range(3))
                gradient.append(interpolated_color)
                break
        else:
            interpolated_color = color_stops[-1][0]
            gradient.append(interpolated_color)

    png_rows = []
    for _ in range(height):
        row = []
        which_gradient = gradient
        if flip_gradient:
            which_gradient = reversed(gradient)
        for color in which_gradient:
            row.extend(color)
        png_rows.append(row)

    expected_row_length = width * 3
    for row in png_rows:
        if len(row) != expected_row_length:
            raise ValueError(f"Row has incorrect length: expected {expected_row_length}, got {len(row)}")

    rotated_png_rows = []
    for x in range(width):
        rotated_row = []
        for y in range(height):
            rotated_row.extend(png_rows[y][x * 3: (x + 1) * 3])  # Extend only the RGB values for the pixel
        rotated_png_rows.append(rotated_row)

    with open(filename, 'wb') as f:
        writer = png.Writer(width=height, height=width, greyscale=False)
        writer.write(f, rotated_png_rows)
    print(f"Gradient saved as {filename}")

def main():
    
    
    ######################### DEFINE PRESETS HERE ######################
    
    gradients = [
    {
        "filename": "night_sky_1.png",
        "colors": [
            ("#000000", 0.0),
            ("#8B0000", 0.2),
            ("#FF4500", 0.6),
            ("#FFD700", 0.8),
            ("#000000", 1.0),
        ],
    },
    {
        "filename": "night_sky_2.png",
        "colors": [
            ("#000000", 0.0),
            ("#FF6347", 0.3),
            ("#FF8C00", 0.6),
            ("#2F4F4F", 1.0),
        ],
    },
    {
        "filename": "night_sky_3.png",
        "colors": [
            ("#000000", 0.0),
            ("#7B68EE", 0.4),
            ("#FF1493", 0.6),
            ("#800080", 0.9),
            ("#000000", 1.0),
        ],
    },
    {
        "filename": "night_sky_4.png",
        "colors": [
            ("#000000", 0.0),
            ("#4B0082", 0.5),
            ("#8A2BE2", 0.8),
            ("#191970", 1.0),
        ],
    },
    {
        "filename": "night_sky_5.png",
        "colors": [
            ("#000000", 0.0),
            ("#FFD700", 0.25),
            ("#FF6347", 0.5),
            ("#2F4F4F", 0.9),
            ("#000000", 1.0),
        ],
    },
    {
        "filename": "night_sky_6.png",
        "colors": [
            ("#000000", 0.0),
            ("#FF4500", 0.3),
            ("#DC143C", 0.5),
            ("#00008B", 0.75),
            ("#000000", 1.0),
        ],
    },
    {
        "filename": "night_sky_7.png",
        "colors": [
            ("#000000", 0.0),
            ("#B22222", 0.3),
            ("#D2691E", 0.6),
            ("#2F4F4F", 0.9),
            ("#000000", 1.0),
        ],
    },
    {
        "filename": "night_sky_8.png",
        "colors": [
            ("#000000", 0.0),
            ("#FF1493", 0.4),
            ("#FFD700", 0.6),
            ("#000000", 1.0),
        ],
    },
    {
        "filename": "night_sky_9.png",
        "colors": [
            ("#000000", 0.0),
            ("#00008B", 0.4),
            ("#B0C4DE", 0.6),
            ("#191970", 1.0),
        ],
    },
    {
        "filename": "night_sky_10.png",
        "colors": [
            ("#000000", 0.0),
            ("#B0E0E6", 0.25),
            ("#87CEEB", 0.5),
            ("#4682B4", 0.8),
            ("#000000", 1.0),
        ],
    },
    {
        "filename": "night_sky_11.png",
        "colors": [
            ("#000000", 0.0),
            ("#800080", 0.3),
            ("#FF6347", 0.6),
            ("#2F4F4F", 0.9),
            ("#000000", 1.0),
        ],
    },
    {
        "filename": "night_sky_12.png",
        "colors": [
            ("#000000", 0.0),
            ("#B22222", 0.4),
            ("#8B4513", 0.7),
            ("#000000", 1.0),
        ],
    },
]

    ######################### ADJUST PARAMETERS ########################
    
    width = 256
    height = 128
    flip_gradient = True # Bottom to top
    
    ####################################################################

    for gradient in gradients:
        generate_gradient(height, width, flip_gradient, gradient["colors"], gradient["filename"])

if __name__ == "__main__":
    main()

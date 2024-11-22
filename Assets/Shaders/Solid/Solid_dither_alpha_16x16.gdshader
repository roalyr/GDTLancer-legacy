shader_type spatial;

render_mode blend_mix, cull_back, diffuse_lambert, specular_blinn, depth_draw_opaque;

// Uniforms for material properties
uniform float specular = 0.5;
uniform float metallic = 0.5;
uniform float roughness = 0.5;

// Uniforms for fade parameters
uniform float fade_start = 0.0;
uniform float fade_end = 5e4;
uniform float fade_power = 2.0;

// Dither threshold for the effect
uniform float dither_threshold : hint_range(0.0, 1.0) = 0.5;

// Function to return the value from the 16x16 Bayer matrix
float bayer16x16(int x, int y) {
    float bayer[256];
    bayer[0] = 0.0; bayer[1] = 128.0; bayer[2] = 32.0; bayer[3] = 160.0;
    bayer[4] = 8.0; bayer[5] = 136.0; bayer[6] = 40.0; bayer[7] = 168.0;
    bayer[8] = 2.0; bayer[9] = 130.0; bayer[10] = 34.0; bayer[11] = 162.0;
    bayer[12] = 10.0; bayer[13] = 138.0; bayer[14] = 42.0; bayer[15] = 170.0;
    bayer[16] = 192.0; bayer[17] = 64.0; bayer[18] = 224.0; bayer[19] = 96.0;
    bayer[20] = 200.0; bayer[21] = 72.0; bayer[22] = 232.0; bayer[23] = 104.0;
    bayer[24] = 194.0; bayer[25] = 66.0; bayer[26] = 226.0; bayer[27] = 98.0;
    bayer[28] = 202.0; bayer[29] = 74.0; bayer[30] = 234.0; bayer[31] = 106.0;
    bayer[32] = 48.0; bayer[33] = 176.0; bayer[34] = 16.0; bayer[35] = 144.0;
    bayer[36] = 56.0; bayer[37] = 184.0; bayer[38] = 24.0; bayer[39] = 152.0;
    bayer[40] = 50.0; bayer[41] = 178.0; bayer[42] = 18.0; bayer[43] = 146.0;
    bayer[44] = 58.0; bayer[45] = 186.0; bayer[46] = 26.0; bayer[47] = 154.0;
    bayer[48] = 240.0; bayer[49] = 112.0; bayer[50] = 208.0; bayer[51] = 80.0;
    bayer[52] = 248.0; bayer[53] = 120.0; bayer[54] = 216.0; bayer[55] = 88.0;
    bayer[56] = 242.0; bayer[57] = 114.0; bayer[58] = 210.0; bayer[59] = 82.0;
    bayer[60] = 250.0; bayer[61] = 122.0; bayer[62] = 218.0; bayer[63] = 90.0;
    bayer[64] = 12.0; bayer[65] = 140.0; bayer[66] = 44.0; bayer[67] = 172.0;
    bayer[68] = 4.0; bayer[69] = 132.0; bayer[70] = 36.0; bayer[71] = 164.0;
    bayer[72] = 14.0; bayer[73] = 142.0; bayer[74] = 46.0; bayer[75] = 174.0;
    bayer[76] = 6.0; bayer[77] = 134.0; bayer[78] = 38.0; bayer[79] = 166.0;
    bayer[80] = 204.0; bayer[81] = 76.0; bayer[82] = 236.0; bayer[83] = 108.0;
    bayer[84] = 196.0; bayer[85] = 68.0; bayer[86] = 228.0; bayer[87] = 100.0;
    bayer[88] = 206.0; bayer[89] = 78.0; bayer[90] = 238.0; bayer[91] = 110.0;
    bayer[92] = 198.0; bayer[93] = 70.0; bayer[94] = 230.0; bayer[95] = 102.0;
    bayer[96] = 60.0; bayer[97] = 188.0; bayer[98] = 28.0; bayer[99] = 156.0;
    bayer[100] = 52.0; bayer[101] = 180.0; bayer[102] = 20.0; bayer[103] = 148.0;
    bayer[104] = 62.0; bayer[105] = 190.0; bayer[106] = 30.0; bayer[107] = 158.0;
    bayer[108] = 54.0; bayer[109] = 182.0; bayer[110] = 22.0; bayer[111] = 150.0;
    bayer[112] = 252.0; bayer[113] = 124.0; bayer[114] = 220.0; bayer[115] = 92.0;
    bayer[116] = 244.0; bayer[117] = 116.0; bayer[118] = 212.0; bayer[119] = 84.0;
    bayer[120] = 254.0; bayer[121] = 126.0; bayer[122] = 222.0; bayer[123] = 94.0;
    bayer[124] = 246.0; bayer[125] = 118.0; bayer[126] = 214.0; bayer[127] = 86.0;
    bayer[128] = 3.0; bayer[129] = 131.0; bayer[130] = 35.0; bayer[131] = 163.0;
    bayer[132] = 11.0; bayer[133] = 139.0; bayer[134] = 43.0; bayer[135] = 171.0;
    bayer[136] = 1.0; bayer[137] = 129.0; bayer[138] = 33.0; bayer[139] = 161.0;
    bayer[140] = 9.0; bayer[141] = 137.0; bayer[142] = 41.0; bayer[143] = 169.0;
    bayer[144] = 195.0; bayer[145] = 67.0; bayer[146] = 227.0; bayer[147] = 99.0;
    bayer[148] = 203.0; bayer[149] = 75.0; bayer[150] = 235.0; bayer[151] = 107.0;
    bayer[152] = 193.0; bayer[153] = 65.0; bayer[154] = 225.0; bayer[155] = 97.0;
    bayer[156] = 201.0; bayer[157] = 73.0; bayer[158] = 233.0; bayer[159] = 105.0;
    bayer[160] = 51.0; bayer[161] = 179.0; bayer[162] = 19.0; bayer[163] = 147.0;
    bayer[164] = 59.0; bayer[165] = 187.0; bayer[166] = 27.0; bayer[167] = 155.0;
    bayer[168] = 49.0; bayer[169] = 177.0; bayer[170] = 17.0; bayer[171] = 145.0;
    bayer[172] = 57.0; bayer[173] = 185.0; bayer[174] = 25.0; bayer[175] = 153.0;
    bayer[176] = 243.0; bayer[177] = 115.0; bayer[178] = 211.0; bayer[179] = 83.0;
    bayer[180] = 251.0; bayer[181] = 123.0; bayer[182] = 219.0; bayer[183] = 91.0;
    bayer[184] = 241.0; bayer[185] = 113.0; bayer[186] = 209.0; bayer[187] = 81.0;
    bayer[188] = 249.0; bayer[189] = 121.0; bayer[190] = 217.0; bayer[191] = 89.0;
    bayer[192] = 15.0; bayer[193] = 143.0; bayer[194] = 47.0; bayer[195] = 175.0;
    bayer[196] = 7.0; bayer[197] = 135.0; bayer[198] = 39.0; bayer[199] = 167.0;
    bayer[200] = 13.0; bayer[201] = 141.0; bayer[202] = 45.0; bayer[203] = 173.0;
    bayer[204] = 5.0; bayer[205] = 133.0; bayer[206] = 37.0; bayer[207] = 165.0;
    bayer[208] = 207.0; bayer[209] = 79.0; bayer[210] = 239.0; bayer[211] = 111.0;
    bayer[212] = 199.0; bayer[213] = 71.0; bayer[214] = 231.0; bayer[215] = 103.0;
    bayer[216] = 205.0; bayer[217] = 77.0; bayer[218] = 237.0; bayer[219] = 109.0;
    bayer[220] = 197.0; bayer[221] = 69.0; bayer[222] = 229.0; bayer[223] = 101.0;
    bayer[224] = 63.0; bayer[225] = 191.0; bayer[226] = 31.0; bayer[227] = 159.0;
    bayer[228] = 55.0; bayer[229] = 183.0; bayer[230] = 23.0; bayer[231] = 151.0;
    bayer[232] = 61.0; bayer[233] = 189.0; bayer[234] = 29.0; bayer[235] = 157.0;
    bayer[236] = 53.0; bayer[237] = 181.0; bayer[238] = 21.0; bayer[239] = 149.0;
    bayer[240] = 255.0; bayer[241] = 127.0; bayer[242] = 223.0; bayer[243] = 95.0;
    bayer[244] = 247.0; bayer[245] = 119.0; bayer[246] = 215.0; bayer[247] = 87.0;
    bayer[248] = 253.0; bayer[249] = 125.0; bayer[250] = 221.0; bayer[251] = 93.0;
    bayer[252] = 245.0; bayer[253] = 117.0; bayer[254] = 213.0; bayer[255] = 85.0;

    return bayer[x + y * 16] / 256.0;
}

void fragment() {
    // Calculate the distance from the camera to the current fragment
    float distance = length(VERTEX);

    // Calculate fade factor based on distance
    float fade_factor = pow(clamp((fade_end - distance) / (fade_end - fade_start), 0.0, 1.0), fade_power);

    // Get screen position in a 16x16 grid
    int x = int(mod(FRAGCOORD.x, 16.0));
    int y = int(mod(FRAGCOORD.y, 16.0));
    float dither_value = bayer16x16(x, y);

    // Discard pixel based on the fade factor and Bayer matrix value
    if (fade_factor <= dither_value * dither_threshold) {
        discard;
    }

    // Set the color without affecting the alpha channel
    ALBEDO = vec3(1.0); // White color as an example
    SPECULAR = specular;
    METALLIC = metallic;
    ROUGHNESS = roughness;
}
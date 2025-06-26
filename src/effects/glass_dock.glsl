uniform sampler2D tex;
uniform float width;
uniform float height;

uniform float u_blurAmount;
uniform float u_distortStrength;
uniform float u_chromaAberration;
uniform float u_specularBrightness;
uniform float u_brightnessBoost;

float random(vec2 _st) {
    return fract(sin(dot(_st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

vec3 gaussianBlur(vec2 uv) {
    vec2 texelSize = vec2(1.0 / width, 1.0 / height);
    vec3 result = vec3(0.0);
    float weights[5];
    weights[0] = 0.227027;
    weights[1] = 0.1945946;
    weights[2] = 0.1216216;
    weights[3] = 0.054054;
    weights[4] = 0.016216;

    vec2 hoffset = vec2(texelSize.x * u_blurAmount, 0.0);
    result += texture2D(tex, uv).rgb * weights[0];
    for (int i = 1; i < 5; ++i) {
        result += texture2D(tex, uv + hoffset * float(i)).rgb * weights[i];
        result += texture2D(tex, uv - hoffset * float(i)).rgb * weights[i];
    }

    vec3 finalResult = vec3(0.0);
    vec2 voffset = vec2(0.0, texelSize.y * u_blurAmount);
    finalResult += result * weights[0];
    for (int i = 1; i < 5; ++i) {
        finalResult += texture2D(tex, uv + voffset * float(i)).rgb * weights[i];
        finalResult += texture2D(tex, uv - voffset * float(i)).rgb * weights[i];
    }

    return finalResult / 2.2;
}

void main() {
    vec2 uv = cogl_tex_coord_in[0].st;

    // 1. Distortion
    float static_noise = (random(uv * 800.0) - 0.5);
    vec2 distorted_uv = uv + vec2(static_noise) * u_distortStrength;

    // 2. Convex edge bulge only near outer rim (~10-20%)
    vec2 local = uv - vec2(0.5);
    float radialDist = length(local);
    float edgeStart = 0.40;
    float edgeEnd = 0.50;
    float t = clamp((radialDist - edgeStart) / (edgeEnd - edgeStart), 0.0, 1.0);
    float bulgeFactor = t * t;
    vec2 bulgeDir = normalize(local + 1e-4);
    distorted_uv += bulgeDir * bulgeFactor * 0.01;

    // 3. Blur & Chromatic aberration
    vec2 uvR = distorted_uv + vec2(u_chromaAberration, 0.0);
    vec2 uvB = distorted_uv - vec2(u_chromaAberration, 0.0);

    float r = gaussianBlur(uvR).r;
    float g = gaussianBlur(distorted_uv).g;
    float b = gaussianBlur(uvB).b;

    vec3 refractedColor = vec3(r, g, b);

    // 4. Highlights
    float highlight = pow(max(0.0, uv.y), 40.0) * u_specularBrightness;
    float edgeGlow = pow(1.0 - abs(uv.x - 0.5) * 2.0, 20.0) * 0.1;
    vec3 finalColor = refractedColor + highlight + edgeGlow;

    // 5. Final color & opacity
    finalColor += u_brightnessBoost;

    float alpha = 0.45;
    cogl_color_out = vec4(clamp(finalColor, 0.0, 1.0), alpha);
} 
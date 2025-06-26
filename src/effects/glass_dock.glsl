uniform sampler2D tex;
uniform float width;
uniform float height;

uniform float u_blurAmount;
uniform float u_distortStrength;
uniform float u_chromaAberration;
uniform float u_specularBrightness;
uniform float u_brightnessBoost;
uniform float u_cornerRadius; // normalized 0-0.5
uniform float u_smoothness;   // edge feathering, in uv units (0.0-0.05)

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

float sdRoundedBox(vec2 p, vec2 b, float r) {
    vec2 q = abs(p) - b + r;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

void main() {
    vec2 uv = cogl_tex_coord_in[0].st;

    // ==== SDF mask for rounded rectangle ====
    vec2 p = (uv - vec2(0.5)) * 2.0; // center to (0,0), range -1..1
    float sdf = sdRoundedBox(p, vec2(1.0), u_cornerRadius * 2.0);
    float mask = 1.0 - smoothstep(-u_smoothness, u_smoothness, sdf);
    if (mask < 0.01) {
        cogl_color_out = vec4(0.0);
        return;
    }

    // модифицировать distort в зависимости от расстояния до края формы
    float edgeDistance = abs(sdf);
    float distortionMult = 1.0 - smoothstep(0.0, 0.1, edgeDistance);

    // 1. Distortion with mask multiplier
    float static_noise = (random(uv * 800.0) - 0.5);
    vec2 distorted_uv = uv + vec2(static_noise) * u_distortStrength * distortionMult;

    // дополнительная нормаль по SDF для имитации выпуклости
    vec2 grad = vec2(
        sdRoundedBox(p + vec2(0.001, 0.0), vec2(1.0), u_cornerRadius * 2.0) - sdRoundedBox(p - vec2(0.001, 0.0), vec2(1.0), u_cornerRadius * 2.0),
        sdRoundedBox(p + vec2(0.0, 0.001), vec2(1.0), u_cornerRadius * 2.0) - sdRoundedBox(p - vec2(0.0, 0.001), vec2(1.0), u_cornerRadius * 2.0)
    );
    vec2 normal = normalize(grad + 1e-4);
    distorted_uv += normal * edgeDistance * 0.02;

    // 3. Blur & chromatic aberration (unchanged)
    vec2 uvR = distorted_uv + vec2(u_chromaAberration, 0.0);
    vec2 uvB = distorted_uv - vec2(u_chromaAberration, 0.0);

    float r = gaussianBlur(uvR).r;
    float g = gaussianBlur(distorted_uv).g;
    float b = gaussianBlur(uvB).b;

    vec3 refractedColor = vec3(r, g, b);

    // 4. Highlights using mask
    float highlight = pow(1.0 - mask, 2.0) * u_specularBrightness;
    float edgeGlow = smoothstep(0.8, 1.0, mask) * 0.3;
    vec3 finalColor = refractedColor + (highlight + edgeGlow);

    // 5. Final brightness boost
    finalColor += u_brightnessBoost;

    float alpha = mask * 0.45;
    cogl_color_out = vec4(clamp(finalColor, 0.0, 1.0), alpha);
} 
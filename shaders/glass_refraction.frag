// Glass Refraction Shader
// Gerçek cam fiziği simülasyonu

#version 460 core

#include <flutter/runtime_effect.glsl>

// Uniforms
uniform vec2 uSize;
uniform sampler2D uTexture;
uniform float uThickness;      // Cam kalınlığı (0.0-1.0)
uniform float uRefractiveIndex; // Kırılma indeksi (1.0-2.0)
uniform float uBlur;           // Blur miktarı

// Input
in vec2 fragCoord;

// Output
out vec4 fragColor;

// Blur fonksiyonu
vec4 blur(sampler2D image, vec2 uv, float blurAmount) {
    vec4 color = vec4(0.0);
    float total = 0.0;
    
    // 9-tap Gaussian blur
    for(float x = -1.0; x <= 1.0; x += 1.0) {
        for(float y = -1.0; y <= 1.0; y += 1.0) {
            vec2 offset = vec2(x, y) * blurAmount / uSize;
            float weight = 1.0 / (1.0 + length(vec2(x, y)));
            color += texture(image, uv + offset) * weight;
            total += weight;
        }
    }
    
    return color / total;
}

void main() {
    // Normalize coordinates
    vec2 uv = fragCoord / uSize;
    
    // Center point
    vec2 center = vec2(0.5, 0.5);
    vec2 toCenter = uv - center;
    
    // Calculate distance from center (for radial distortion)
    float dist = length(toCenter);
    
    // Refraction distortion
    // Snell's law simulation: n1 * sin(θ1) = n2 * sin(θ2)
    float refractionStrength = uThickness * (uRefractiveIndex - 1.0);
    vec2 refractedUV = uv + toCenter * refractionStrength * 0.05;
    
    // Chromatic aberration (RGB split for realism)
    float aberration = refractionStrength * 0.002;
    vec4 color;
    color.r = blur(uTexture, refractedUV - toCenter * aberration, uBlur).r;
    color.g = blur(uTexture, refractedUV, uBlur).g;
    color.b = blur(uTexture, refractedUV + toCenter * aberration, uBlur).b;
    color.a = 1.0;
    
    // Glass tint (subtle white overlay)
    vec3 glassTint = vec3(1.0, 1.0, 1.0);
    float tintStrength = 0.05;
    color.rgb = mix(color.rgb, glassTint, tintStrength);
    
    fragColor = color;
}

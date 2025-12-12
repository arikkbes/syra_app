// SyraGlassSurface.swift
// iOS-FULL-2.5: SYRA Glass Standard - Claude/ChatGPT iOS premium vibe

import SwiftUI

/// Premium iOS glass component with material blur, highlights, and realistic depth
struct SyraGlassSurface: View {
    let cornerRadius: CGFloat
    let blurIntensity: SyraGlassStyle.BlurIntensity
    let tint: Color?
    
    init(
        cornerRadius: CGFloat = SyraTokens.Radius.card,
        blurIntensity: SyraGlassStyle.BlurIntensity = .standard,
        tint: Color? = nil
    ) {
        self.cornerRadius = cornerRadius
        self.blurIntensity = blurIntensity
        self.tint = tint
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            // Base material layer
            .fill(blurIntensity.material)
            // Optional subtle tint
            .overlay(
                Group {
                    if let tint = tint {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(tint.opacity(0.03))
                    }
                }
            )
            // Top highlight (premium touch)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.12),
                                Color.white.opacity(0.05),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
            )
            // Inner stroke (1px white subtle)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            // Outer shadow (very soft, realistic depth)
            .shadow(
                color: Color.black.opacity(0.04),
                radius: 2,
                x: 0,
                y: 1
            )
            .shadow(
                color: Color.black.opacity(0.06),
                radius: 8,
                x: 0,
                y: 4
            )
    }
}

/// Glass style configuration helper
enum SyraGlassStyle {
    enum BlurIntensity {
        case ultraLight
        case standard
        case heavy
        
        var material: Material {
            switch self {
            case .ultraLight:
                return .ultraThinMaterial
            case .standard:
                return .thinMaterial
            case .heavy:
                return .regularMaterial
            }
        }
    }
}

struct SyraGlassSurface_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            LinearGradient(
                colors: [Color.purple, Color.pink],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                SyraGlassSurface()
                    .frame(width: 200, height: 100)
                
                SyraGlassSurface(cornerRadius: 24)
                    .frame(width: 300, height: 150)
            }
        }
    }
}

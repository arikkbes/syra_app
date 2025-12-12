// SyraGlassSurface.swift
// iOS-FULL-2: Premium glass effect using SwiftUI materials

import SwiftUI

struct SyraGlassSurface: View {
    let cornerRadius: CGFloat
    let borderOpacity: CGFloat
    
    init(
        cornerRadius: CGFloat = SyraTokens.Radius.card,
        borderOpacity: CGFloat = 0.15
    ) {
        self.cornerRadius = cornerRadius
        self.borderOpacity = borderOpacity
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(.ultraThinMaterial) // iOS native material
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(borderOpacity),
                                Color.white.opacity(borderOpacity * 0.5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: SyraTokens.Shadow.medium.color,
                radius: SyraTokens.Shadow.medium.radius,
                x: SyraTokens.Shadow.medium.x,
                y: SyraTokens.Shadow.medium.y
            )
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

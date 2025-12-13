// SyraLogoShape.swift
// Custom SYRA logo path based on the actual Flutter design

import SwiftUI

/// SYRA Logo Shape - Matches the Flutter design exactly
struct SyraLogoShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        // Scale factor for the design
        let scaleX = width / 360
        let scaleY = height / 360
        
        // SYRA logo outline path (simplified version of the Flutter asset)
        // This is a simplified representation - you should replace with actual SVG path
        
        // Vertical line (left)
        path.move(to: CGPoint(x: 80 * scaleX, y: 80 * scaleY))
        path.addLine(to: CGPoint(x: 80 * scaleX, y: 200 * scaleY))
        path.addLine(to: CGPoint(x: 90 * scaleX, y: 200 * scaleY))
        path.addLine(to: CGPoint(x: 90 * scaleX, y: 80 * scaleY))
        path.closeSubpath()
        
        // S curve (center-left)
        path.move(to: CGPoint(x: 120 * scaleX, y: 120 * scaleY))
        path.addCurve(
            to: CGPoint(x: 140 * scaleX, y: 160 * scaleY),
            control1: CGPoint(x: 110 * scaleX, y: 130 * scaleY),
            control2: CGPoint(x: 150 * scaleX, y: 150 * scaleY)
        )
        path.addCurve(
            to: CGPoint(x: 120 * scaleX, y: 200 * scaleY),
            control1: CGPoint(x: 130 * scaleX, y: 170 * scaleY),
            control2: CGPoint(x: 110 * scaleX, y: 190 * scaleY)
        )
        
        // Horizontal lines (right)
        path.move(to: CGPoint(x: 200 * scaleX, y: 100 * scaleY))
        path.addLine(to: CGPoint(x: 280 * scaleX, y: 100 * scaleY))
        path.addLine(to: CGPoint(x: 280 * scaleX, y: 110 * scaleY))
        path.addLine(to: CGPoint(x: 200 * scaleX, y: 110 * scaleY))
        path.closeSubpath()
        
        path.move(to: CGPoint(x: 200 * scaleX, y: 140 * scaleY))
        path.addLine(to: CGPoint(x: 260 * scaleX, y: 140 * scaleY))
        path.addLine(to: CGPoint(x: 260 * scaleX, y: 150 * scaleY))
        path.addLine(to: CGPoint(x: 200 * scaleX, y: 150 * scaleY))
        path.closeSubpath()
        
        // P shape (bottom-right)
        path.move(to: CGPoint(x: 240 * scaleX, y: 200 * scaleY))
        path.addLine(to: CGPoint(x: 240 * scaleX, y: 280 * scaleY))
        path.addLine(to: CGPoint(x: 250 * scaleX, y: 280 * scaleY))
        path.addLine(to: CGPoint(x: 250 * scaleX, y: 240 * scaleY))
        path.addArc(
            center: CGPoint(x: 250 * scaleX, y: 220 * scaleY),
            radius: 20 * scaleX,
            startAngle: .degrees(0),
            endAngle: .degrees(180),
            clockwise: false
        )
        
        return path
    }
}

/// SYRA Logo View - Ready to use component
struct SyraLogoView: View {
    let size: CGFloat
    let color: Color
    
    init(size: CGFloat = 80, color: Color = SyraTokens.Colors.primary) {
        self.size = size
        self.color = color
    }
    
    var body: some View {
        // Since we don't have the actual SVG, use the actual image if available
        // For now, use a simplified custom drawn version
        ZStack {
            // Placeholder: Custom drawn SYRA-like pattern
            Canvas { context, size in
                let lineWidth: CGFloat = 8
                let spacing: CGFloat = 12
                
                // Draw flowing lines pattern similar to SYRA logo
                var path = Path()
                
                // Left vertical
                path.move(to: CGPoint(x: size.width * 0.2, y: size.height * 0.2))
                path.addLine(to: CGPoint(x: size.width * 0.2, y: size.height * 0.8))
                
                // Center S-curve
                path.move(to: CGPoint(x: size.width * 0.35, y: size.height * 0.3))
                path.addQuadCurve(
                    to: CGPoint(x: size.width * 0.55, y: size.height * 0.5),
                    control: CGPoint(x: size.width * 0.35, y: size.height * 0.4)
                )
                path.addQuadCurve(
                    to: CGPoint(x: size.width * 0.35, y: size.height * 0.7),
                    control: CGPoint(x: size.width * 0.55, y: size.height * 0.6)
                )
                
                // Right horizontal lines
                path.move(to: CGPoint(x: size.width * 0.65, y: size.height * 0.3))
                path.addLine(to: CGPoint(x: size.width * 0.85, y: size.height * 0.3))
                
                path.move(to: CGPoint(x: size.width * 0.65, y: size.height * 0.45))
                path.addLine(to: CGPoint(x: size.width * 0.8, y: size.height * 0.45))
                
                // Bottom P-like shape
                path.move(to: CGPoint(x: size.width * 0.7, y: size.height * 0.6))
                path.addLine(to: CGPoint(x: size.width * 0.7, y: size.height * 0.8))
                path.addArc(
                    center: CGPoint(x: size.width * 0.75, y: size.height * 0.65),
                    radius: size.width * 0.08,
                    startAngle: .degrees(90),
                    endAngle: .degrees(270),
                    clockwise: false
                )
                
                context.stroke(path, with: .color(color), lineWidth: lineWidth)
            }
            .frame(width: size, height: size)
        }
    }
}

struct SyraLogoView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
            VStack(spacing: 40) {
                SyraLogoView(size: 120)
                SyraLogoView(size: 80, color: .white.opacity(0.5))
            }
        }
    }
}

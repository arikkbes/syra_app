// RootContainer.swift
// iOS-FULL-2.5: Main container with premium native menu slide animation

import SwiftUI

struct RootContainer: View {
    @EnvironmentObject var appState: AppState
    @State private var isMenuOpen = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // MARK: - Main Content (Chat View)
                ChatView(
                    onMenuTap: {
                        SyraHaptics.light()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            isMenuOpen.toggle()
                        }
                    },
                    onActionTap: {
                        print("Action tapped")
                    }
                )
                .frame(width: geometry.size.width, height: geometry.size.height)
                .offset(x: isMenuOpen ? 340 : 0)
                .disabled(isMenuOpen)
                
                // MARK: - Side Menu
                if isMenuOpen {
                    SideMenuView(
                        isOpen: $isMenuOpen,
                        onClose: { closeMenu() }
                    )
                    .frame(width: 340)
                    .transition(.move(edge: .leading))
                }
                
                // MARK: - Overlay (tap to close menu)
                if isMenuOpen {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                        .offset(x: 340)
                        .onTapGesture {
                            closeMenu()
                        }
                }
            }
        }
        .ignoresSafeArea()
    }
    
    private func closeMenu() {
        SyraHaptics.light()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            isMenuOpen = false
        }
    }
}

struct RootContainer_Previews: PreviewProvider {
    static var previews: some View {
        RootContainer()
            .environmentObject(AppState())
    }
}

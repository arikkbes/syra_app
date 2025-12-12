// RootContainer.swift
// iOS-FULL-2: Main container with AppState integration

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
                        withAnimation(SyraAnimations.menuSlide) {
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
                    Color.black.opacity(0.3)
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
        withAnimation(SyraAnimations.menuSlide) {
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

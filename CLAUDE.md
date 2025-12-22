# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SYRA is an AI-powered relationship coaching app built with Flutter (frontend) and Firebase Cloud Functions (backend). It uses OpenAI's GPT models for conversational AI with intent-based model selection and psychological trait extraction.

## Build & Development Commands

### Flutter (Frontend)
```bash
flutter pub get              # Install dependencies
flutter analyze              # Run linting/static analysis
flutter run                  # Run the app
flutter test                 # Run tests
flutter build apk            # Build Android APK
flutter build ios            # Build iOS
flutter build web            # Build web
```

### Firebase Functions (Backend)
```bash
cd functions
npm run serve                # Start local emulator
npm run deploy               # Deploy functions
npm run logs                 # View function logs
npm run shell                # Interactive shell
```

### Firebase Emulator
The emulator UI runs on port 4000, functions on 5001, Firestore on 8080.

## Architecture

### Frontend (Flutter)
- **Entry point:** `lib/main.dart` - Auth gate pattern using StreamBuilder on FirebaseAuth
- **State management:** StatefulWidget with setState (no external state library)
- **Dependency injection:** Service Locator pattern in `lib/core/service_locator.dart`
- **Local storage:** Hive (chosen over SharedPreferences to avoid iOS native code issues)

**Key directories:**
- `lib/screens/` - UI pages (chat_screen.dart is the main interface)
- `lib/services/` - API clients and business logic
- `lib/widgets/` - Reusable UI components
- `lib/theme/` - Design system (syra_theme.dart is locked - do not modify colors)
- `lib/models/` - Data models

### Backend (Firebase Functions)
Clean/layered architecture with Node.js 22:

- `functions/src/config/` - Firebase Admin and OpenAI client initialization
- `functions/src/firestore/` - Data access repositories
- `functions/src/domain/` - Business logic engines (intent, persona, traits, patterns, predictions)
- `functions/src/services/` - Orchestration layer (chatOrchestrator.js coordinates all engines)
- `functions/src/http/` - HTTP request handlers

**Four endpoints:**
1. `flortIQChat` - Main chat (120s timeout)
2. `analyzeRelationshipChat` - WhatsApp analysis (300s timeout)
3. `tarotReading` - Tarot readings (60s timeout)
4. `getRelationshipStats` - Statistics (60s timeout)

### Chat Flow
```
HTTP Request → syraChatHandler → chatOrchestrator
  → Load user profile + history
  → Detect intent (6 types) → Select model
  → Detect gender (hybrid: pattern + AI fallback)
  → Extract psychological traits
  → Detect patterns (premium)
  → Predict outcome (premium)
  → Build dynamic persona
  → Call OpenAI
  → Save history + return response
```

## Design System

**Colors (DO NOT MODIFY - defined in syra_theme.dart):**
- Background: #11131A (Obsidian)
- Accent: #D6B35A (Champagne Gold)
- Text Primary: #E7E9EE
- Surface Elevated: #1B202C

Use `SyraColors` from `syra_theme.dart`. The deprecated `SyraTokens` class should not be used for new code.

## Key Patterns

1. **RevenueCat lazy initialization** - Do not initialize on app startup (causes iOS crashes). Initialize only when PremiumScreen is accessed.

2. **Premium vs Free:** Free users get 10 messages/day, premium gets unlimited (99999). Check via `userProfile.messageLimit`.

3. **Intent-based model selection:** Backend selects gpt-4o or gpt-4o-mini based on detected user intent.

4. **Glass UI effects:** Custom glassmorphism widgets in `lib/widgets/` (glass_background.dart, syra_liquid_glass_chat_bar.dart).

## Important Files

- `lib/main.dart` - App initialization
- `lib/screens/chat_screen.dart` - Main UI (large file, ~74KB)
- `lib/services/chat_service.dart` - Chat API client
- `lib/services/purchase_service.dart` - RevenueCat integration
- `functions/src/services/chatOrchestrator.js` - Core backend logic
- `functions/src/domain/intentEngine.js` - Intent detection
- `functions/README.md` - Comprehensive backend documentation

## Environment

- Firebase project: syra-ai-b562f
- RevenueCat product ID: `com.ariksoftware.syra.premium_monthly`
- Platforms: iOS, Android, Web, Windows, macOS
- CI/CD: Codemagic (codemagic.yaml)

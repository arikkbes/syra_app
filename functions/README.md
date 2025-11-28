# SYRA Backend - Clean Architecture

## 🏗️ Architecture Overview

This is a modular, production-ready Firebase Cloud Functions backend for the SYRA AI relationship coaching app.

### Design Principles

- **Separation of Concerns** - Each module has a single responsibility
- **Clean Architecture** - Business logic separated from infrastructure
- **Testability** - Each component can be tested independently
- **Maintainability** - Easy to understand, modify, and extend
- **Type Safety** - Clear contracts between modules

---

## 📁 Project Structure

```
functions/
├── index.js                           # Entry point (exports Cloud Functions)
├── package.json                       # Dependencies
├── .env                              # Environment variables
│
└── src/                              # Source code
    │
    ├── config/                       # Configuration layer
    │   ├── firebaseAdmin.js          # Firebase Admin SDK initialization
    │   └── openaiClient.js           # OpenAI client configuration
    │
    ├── firestore/                    # Data access layer
    │   ├── userProfileRepository.js  # User CRUD operations
    │   └── conversationRepository.js # Chat history & summaries
    │
    ├── domain/                       # Business logic layer
    │   ├── intentEngine.js           # Message intent detection
    │   ├── personaEngine.js          # SYRA personality building
    │   ├── traitEngine.js            # Psychological trait extraction
    │   ├── outcomePredictionEngine.js # Relationship outcome prediction
    │   ├── patternEngine.js          # Behavioral pattern recognition
    │   ├── genderEngine.js           # Gender detection (hybrid AI + patterns)
    │   └── limitEngine.js            # Rate limiting logic
    │
    ├── services/                     # Application services layer
    │   └── chatOrchestrator.js       # Main chat orchestration
    │
    ├── http/                         # HTTP presentation layer
    │   └── syraChatHandler.js        # HTTP request handler
    │
    └── utils/                        # Utilities
        └── constants.js              # Application constants
```

---

## 🚀 Quick Start

### 1. Install Dependencies

```bash
npm install
```

### 2. Set Environment Variables

Create `.env` file:

```bash
OPENAI_API_KEY=your_openai_api_key_here
```

### 3. Deploy

```bash
firebase deploy --only functions
```

### 4. Test

```bash
npm run serve  # Start local emulator
```

---

## 🔧 Module Descriptions

### Configuration Layer

**firebaseAdmin.js**
- Initializes Firebase Admin SDK
- Exports db, auth instances
- Single initialization point

**openaiClient.js**
- Configures OpenAI client
- Reads API key from environment
- Provides availability check

### Data Layer

**userProfileRepository.js**
- Get/update user profiles
- Increment message counts
- Gender detection attempts
- Backend limit checks

**conversationRepository.js**
- Load conversation history
- Save messages
- Create/update summaries
- Long-term memory management

### Domain Layer

**intentEngine.js**
- Detects message intent (6 types)
- Selects optimal AI model
- Configures temperature/tokens

**personaEngine.js**
- Builds SYRA's dynamic persona
- Tone normalization
- Gender-specific language
- Premium-aware prompting

**traitEngine.js**
- Extracts psychological traits
- Red/green flag detection
- Emotional state analysis
- Urgency assessment

**outcomePredictionEngine.js**
- Predicts relationship outcomes (Premium)
- Interest level calculation
- Date probability estimation
- Risk/opportunity identification

**patternEngine.js**
- Detects behavioral patterns (Premium)
- Repeating mistakes analysis
- Attachment style indicators
- Growth areas identification

**genderEngine.js**
- Hybrid gender detection
- Pattern matching first
- AI fallback (max 3 attempts)
- Smart caching

**limitEngine.js**
- Backend daily limits (150/day)
- Premium bypass
- Remaining message calculation
- Can-send-message check

### Service Layer

**chatOrchestrator.js**
- Main business logic orchestration
- Coordinates all domain engines
- Manages OpenAI completion
- Builds final response

### HTTP Layer

**syraChatHandler.js**
- HTTP request handling
- CORS configuration
- Authentication (Firebase ID token)
- Request validation
- Error handling
- Response formatting

---

## 🔐 Authentication

All requests must include Firebase ID token:

```javascript
Authorization: Bearer <firebase_id_token>
```

Token is verified using Firebase Admin SDK before processing.

---

## 📊 Request/Response Format

### Request

```json
{
  "message": "Sevgilim bana mesaj atmıyor, ne yapmalıyım?",
  "context": [
    {
      "role": "user",
      "content": "Dün kavga ettik"
    },
    {
      "role": "assistant", 
      "content": "Anlıyorum, neden kavga ettiniz?"
    }
  ]
}
```

### Response

```json
{
  "response": "Kanka şunu söyleyeyim...",
  "extractedTraits": {
    "flags": { "red": [], "green": [] },
    "tone": "anxious",
    "urgency": "medium",
    "relationshipStage": "dating"
  },
  "outcomePrediction": {  // Premium only
    "interestLevel": 65,
    "dateProbability": 45,
    "relationshipProspect": "medium"
  },
  "patterns": {  // Premium only
    "repeatingMistakes": ["..."],
    "relationshipType": "healthy"
  },
  "meta": {
    "intent": "advice",
    "model": "gpt-4o-mini",
    "premium": false,
    "processingTime": 2340
  }
}
```

---

## ⚡ Features

### Core Features (All Users)

- ✅ Intent-based AI model selection
- ✅ Psychological trait extraction
- ✅ Gender-aware responses
- ✅ Conversation memory
- ✅ Red/green flag detection
- ✅ Emotional tone adaptation
- ✅ Daily backend limits (150/day)

### Premium Features

- ⭐ Unlimited messages
- ⭐ Behavioral pattern recognition
- ⭐ Relationship outcome prediction
- ⭐ Advanced GPT-4o access
- ⭐ Long-term memory summaries
- ⭐ Deep psychological analysis

---

## 🎯 Intent Types

1. **technical** - Programming/tech questions → GPT-4o
2. **emergency** - Urgent emotional crisis → GPT-4o (Premium)
3. **deep_analysis** - Detailed analysis needed → GPT-4o (Premium)
4. **deep** - Complex relationship topic → GPT-4o (Premium with 20+ msgs)
5. **short** - Quick question → GPT-4o-mini
6. **normal** - Regular conversation → GPT-4o-mini (or 4o with Premium)

---

## 🔄 Data Flow

```
HTTP Request
    ↓
syraChatHandler (auth, validation)
    ↓
chatOrchestrator
    ↓
┌─────────────────────────────────────┐
│ 1. Load user profile                │
│ 2. Load conversation history         │
│ 3. Detect intent                     │
│ 4. Detect gender (hybrid)            │
│ 5. Extract traits                    │
│ 6. Detect patterns (Premium)         │
│ 7. Predict outcome (Premium)         │
│ 8. Build persona                     │
│ 9. Generate AI response              │
│ 10. Save history                     │
│ 11. Update profile                   │
└─────────────────────────────────────┘
    ↓
Format response
    ↓
HTTP Response
```

---

## 🐛 Error Handling

All errors return structured responses:

```json
{
  "error": true,
  "message": "User-friendly error message",
  "code": "ERROR_CODE"
}
```

**Error Codes:**
- `UNAUTHORIZED` - Invalid/missing token
- `METHOD_NOT_ALLOWED` - Not POST
- `EMPTY_MESSAGE` - Missing message
- `RATE_LIMIT_EXCEEDED` - Hit daily limit
- `INTERNAL_ERROR` - Server error

---

## 📈 Performance

### Typical Response Times

- Cold start: 8-12 seconds (first request)
- Warm requests: 1-3 seconds
- OpenAI call: 1-2 seconds
- Firestore operations: <100ms each

### Optimization

- Async operations where possible
- Fire-and-forget for non-critical tasks
- Smart model selection (cost vs quality)
- Efficient conversation history slicing

---

## 🧪 Testing

### Local Testing

```bash
npm run serve
```

Then make requests to:
```
http://localhost:5001/YOUR_PROJECT/us-central1/flortIQChat
```

### Unit Testing (Recommended to add)

Each module can be tested independently:

```javascript
import { detectIntentType } from './src/domain/intentEngine.js';

test('detects emergency intent', () => {
  const intent = detectIntentType('Çok kötüyüm yardım et');
  expect(intent).toBe('emergency');
});
```

---

## 🔒 Security

- ✅ Firebase ID token verification
- ✅ Request validation
- ✅ Message sanitization (5000 char limit)
- ✅ Rate limiting for free users
- ✅ No stack traces in production
- ✅ CORS properly configured

---

## 📝 Logging

All important events are logged:

```javascript
console.log(`[${uid}] Processing - Premium: ${isPremium}`);
console.log(`[${uid}] Intent: ${intent}, Model: ${model}`);
console.log(`[${uid}] Success - Response sent in ${time}ms`);
console.error(`[${uid}] Error:`, error);
```

View logs in Firebase Console → Functions → Logs

---

## 🚀 Deployment

### Production Deploy

```bash
firebase deploy --only functions
```

### Deploy Specific Function

```bash
firebase deploy --only functions:flortIQChat
```

### Rollback

```bash
firebase functions:log  # Check logs
# If needed, revert code and redeploy
```

---

## 🔧 Configuration

### Environment Variables

Create `.env` file:

```bash
OPENAI_API_KEY=sk-...
NODE_ENV=production  # or development
```

### Firebase Functions Config

In `index.js`:

```javascript
export const flortIQChat = onRequest({
  cors: true,
  timeoutSeconds: 120,
  memory: "256MiB"
}, syraChatHandler);
```

---

## 📚 Dependencies

```json
{
  "firebase-admin": "^12.6.0",
  "firebase-functions": "^4.4.1",
  "openai": "^6.8.1",
  "dotenv": "^16.4.5"
}
```

---

## 🎓 Best Practices

1. **Never put business logic in HTTP handlers**
2. **Always use repositories for data access**
3. **Keep domain engines pure (no side effects)**
4. **Use constants instead of magic numbers**
5. **Log important events and errors**
6. **Handle errors gracefully**
7. **Validate all inputs**
8. **Use TypeScript for new features (optional)**

---

## 🐛 Troubleshooting

### Issue: Function timeout

**Solution:** Increase timeout in function config (max 540s)

### Issue: Cold start too slow

**Solution:** Consider using min instances (costs $)

### Issue: OpenAI API errors

**Solution:** Check API key, check quota, add retry logic

### Issue: Firestore permission denied

**Solution:** Check Firebase rules, verify token

---

## 📞 Support

For issues or questions:

1. Check Cloud Functions logs
2. Review error codes
3. Test with simple messages
4. Verify environment variables
5. Check OpenAI API status

---

## ✨ Future Enhancements

### Recommended

- [ ] Add TypeScript
- [ ] Implement unit tests
- [ ] Add integration tests
- [ ] Set up CI/CD pipeline
- [ ] Add Redis caching
- [ ] Implement retry logic
- [ ] Add monitoring/alerting
- [ ] Create admin dashboard

### Optional

- [ ] Add more AI models (Claude, Gemini)
- [ ] Implement streaming responses
- [ ] Add voice support
- [ ] Multi-language support
- [ ] A/B testing framework

---

**Version:** 12.0 (Refactored)  
**Last Updated:** November 28, 2025  
**Status:** Production Ready ✅

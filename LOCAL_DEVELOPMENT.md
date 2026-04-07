# Local development (no Firebase deploy)

Yeh app **Firebase Emulator Suite** use karti hai: sab kuch tumhare machine par chalega — **production par deploy karne ki zaroorat nahi** jab tak tum khud `firebase deploy` na chalao.

## Pehle (ek baar)

1. **Flutter:** `flutter pub get`
2. **Functions:** `cd functions && npm install`
3. **Java 11+** (Functions emulator ke liye) — agar error aaye to [Adoptium Temurin](https://adoptium.net/) install karo.

## Terminal 1 — backend (emulators)

Project root se:

```bash
cd functions
npm run emulators
```

- Emulator UI: **http://localhost:56277** — ports `firebase.json` ke saath match (56273–56277; common 8080/18080 wagaira avoid)

| Service    | Port  |
|-----------|-------|
| Firestore | 56273 |
| Auth      | 56274 |
| Functions | 56275 |
| Storage   | 56276 |
| UI        | 56277 |

**“Port taken” / purana emulator:**

```bash
# Kaun use kar raha hai:
lsof -iTCP:56273 -sTCP:LISTEN

# Purane Firebase emulator processes (dhyan se):
pkill -f cloud-firestore-emulator 2>/dev/null; pkill -f cloud-storage-rules 2>/dev/null
```

Phir dubara `npm run emulators`. Agar koi port ab bhi busy ho to `firebase.json` mein **saare** emulators ke ports badlo aur `lib/core/config/firebase_emulator.dart` ke `defaultValue` (ya Flutter run par `--dart-define=FIRESTORE_EMULATOR_PORT=...` wagaira) **same** rakho.

- Pehli baar Firebase CLI tools download ho sakte hain — wait karo.

**Group game AI (AI Favorite / AI Random):** `generateGameContent` callable `GEMINI_API_KEY` use karti hai.

Local (recommended):

```bash
cd functions
cp .env.example .env
# Edit .env — paste key from https://aistudio.google.com/apikey (never commit .env)
npm run emulators
```

Ya ek session ke liye: `export GEMINI_API_KEY="your-key"` phir `npm run emulators`.

Production deploy: Google Cloud Console → Cloud Functions → `generateGameContent` → **Edit** → **Runtime environment variables** → `GEMINI_API_KEY`, ya `firebase functions:secrets:set` (project docs dekho).

## Terminal 2 — Flutter app

Project root se (emulator mode):

```bash
flutter run --dart-define=USE_FIREBASE_EMULATOR=true
```

- **Android Emulator:** app automatically `10.0.2.2` use karti hai.
- **Physical phone (same Wi‑Fi):** apne Mac/PC ka LAN IP do:

```bash
flutter run --dart-define=USE_FIREBASE_EMULATOR=true --dart-define=EMULATOR_HOST=192.168.x.x
```

(`192.168.x.x` ko apne computer ke IP se replace karo.)

## Global `firebase` install error (EACCES)

Zaroorat nahi — `cd functions` ke andar `npm run firebase -- ...` ya `npx firebase ...` use karo.

## `Error: An unexpected error has occurred` + `spawn ... firebase-functions EACCES`

Iska matlab `functions/node_modules/.bin/firebase-functions` par **execute permission** nahi hai (npm kabhi-kabhi aise install karta hai).

```bash
cd functions
npm install
```

(`package.json` mein `postinstall` script ab `.bin` files ko `chmod +x` karti hai.) Manual fix: `chmod +x node_modules/.bin/firebase-functions`.

## `multiple instances of the emulator suite`

Ek waqt par **sirf ek** `npm run emulators` — baaki terminals mein purana emulator band karo (Ctrl+C).

## Notes

- Emulator mode par **FCM push** band hai (local token / cloud messaging mix se bachne ke liye).
- Auth / Firestore / Storage / Functions sab **local** data use karte hain; production data **nahi** dikhega jab tak tum emulator flag use kar rahe ho.

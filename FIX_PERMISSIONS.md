# Fix PERMISSION_DENIED, DEVELOPER_ERROR & Storage 404

## Problems
- `Firestore: Listen for Query(groups) failed: PERMISSION_DENIED`
- `Firestore: Listen for Query(notifications/...) failed: PERMISSION_DENIED`
- `GoogleApiManager: DEVELOPER_ERROR - Unknown calling package name`
- `StorageException: Object does not exist at location (404)` - group image upload fails

## Solution (2 Steps)

### Step 1: Deploy Firestore Rules

```bash
cd /Users/user/Documents/codeconeyan/jobcrak
npx firebase-tools deploy --only firestore
```

Agar Firebase login nahi hai:
```bash
npx firebase-tools login
```

### Step 2: Add SHA-1 to Firebase (DEVELOPER_ERROR fix)

1. **Debug SHA-1 nikalo:**
   ```bash
   cd android && ./gradlew signingReport
   ```
   Ya:
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
   `SHA1:` ke baad wala value copy karo.

2. **Firebase Console:**
   - [Firebase Console](https://console.firebase.google.com/) → Project select
   - ⚙️ Project Settings → Your apps
   - Android app (com.example.jobcrak) pe click
   - "Add fingerprint" → SHA-1 paste karo → Save

3. **google-services.json download:**
   - Same page se "Download google-services.json" click karo
   - File ko `android/app/google-services.json` pe replace karo

4. **App rebuild:**
   ```bash
   flutter clean && flutter pub get && flutter run
   ```

### Step 3: Enable Firebase Storage (404 fix)

1. **Firebase Console** → Project → **Storage**
2. Agar "Get started" dikhe to click karo – Storage enable hoga
3. **Rules deploy:**
   ```bash
   npx firebase-tools deploy --only storage
   ```

**Note:** Ab group image upload fail hone par bhi group create ho jayega (image ke bina). Snackbar dikhega: "Image upload failed. Group will be created without image."

## Verify

- Firestore rules deploy: Firebase Console → Firestore → Rules (last published check karo)
- SHA-1 add: Project Settings → Your apps → SHA certificate fingerprints list mein dikhega
- Storage: Firebase Console → Storage → Files tab (bucket enabled hona chahiye)

# Product Requirements Document (PRD)
# Split Expense - Location-Based Community & Expense Splitting App

**Version:** 1.0  
**Last Updated:** March 2025  
**Product:** Split Expense (JobCrak)

---

## 1. Product Overview

### 1.1 Vision
A location-based community mobile app that helps friends, roommates, and travel groups create geo-fenced groups, split expenses fairly, chat in real-time, share photos, and settle payments via UPI QR—all in one place.

### 1.2 Problem Statement
- Groups struggle to track shared expenses (trips, dinners, bills)
- Manual settlement is error-prone and awkward
- No single app combines group chat + expense splitting + payment collection
- Location-based groups need privacy-aware discovery

### 1.3 Solution
A Flutter app with Firebase backend offering:
- **Groups**: Create/join geo-fenced groups (trip, home, couple, other)
- **Expenses**: Add, split, track with receipts and charts
- **Payments**: UPI QR for direct collection + push notifications with QR
- **Chat**: Real-time group messaging with multimedia
- **Gallery**: Shared photo gallery within groups
- **Notifications**: FCM push for messages and payment reminders

---

## 2. User Personas

| Persona | Description | Key Needs |
|---------|-------------|-----------|
| **Trip Organizer** | Plans group trips | Expense tracking, split by person, QR payments |
| **Roommate** | Shares bills at home | Recurring expenses, fair splits |
| **Friend Group** | Casual outings | Quick add expense, chat, photos |
| **Couple** | Shared expenses | Simple tracking, privacy |

---

## 3. Tech Stack

| Layer | Technology |
|-------|------------|
| **Frontend** | Flutter (Dart 3.x), Material Design |
| **State** | Flutter Bloc (Cubit) |
| **Navigation** | GoRouter |
| **Backend** | Firebase (Auth, Firestore, Storage, FCM) |
| **Location** | Google Maps, Geolocator |
| **Real-time** | Firestore Streams, Agora (voice/video) |
| **Media** | Image Picker, Cached Network Image |

---

## 4. Complete Screen Inventory

### 4.1 Onboarding & Auth Flow

| # | Screen | Route | Description | Key Elements |
|---|--------|-------|-------------|--------------|
| 1 | **Splash Screen** | `/` | App launch, auth check | Logo, loading, auto-navigate |
| 2 | **Onboarding** | `/onboarding` | First-time intro | Carousel slides, Skip, Let's Go |
| 3 | **Login** | `/login` | Sign in | Email/Phone toggle, Google sign-in, Forgot password |
| 4 | **Register** | `/register` | Create account | Name, email, phone, password |
| 5 | **Forgot Password** | `/forgot-password` | Reset password | Email input, send link |

### 4.2 Main App (Bottom Nav)

| # | Screen | Route | Tab | Description | Key Elements |
|---|--------|-------|-----|-------------|--------------|
| 6 | **Home (Groups)** | `/home` | Groups | List of user's groups | Search, sort, group cards with balance, FAB Add expense |
| 7 | **Contacts** | `/contacts` | Friends | Phone contacts | Import, invite, sync |
| 8 | **Shared With Me** | `/shared-with-me` | Activity | Gallery shares | Photos shared with user |
| 9 | **Profile** | `/profile` | Account | User profile | Avatar, name, edit, settings |

### 4.3 Group Management

| # | Screen | Route | Description | Key Elements |
|---|--------|-------|-------------|--------------|
| 10 | **Create Group** | `/create-group` | New group form | Name, description, category, location, radius, dates |
| 11 | **Location Search** | `/location-search` | Pick location on map | Map, search, pin, confirm |
| 12 | **Group Detail** | `/group-detail/:id` | Group overview | Header, members, expenses, chat, gallery tabs |
| 13 | **Add Member (Email)** | `/add-member/:id` | Invite by email | Email input, send invite |
| 14 | **Add Member (Contacts)** | `/add-member-from-contacts` | Invite from contacts | Contact picker, select |
| 15 | **Add Member Review** | `/add-member-review` | Review selections | List selected, confirm |
| 16 | **Add Someone New** | `/add-someone-new` | Manual add | Name, phone input |

### 4.4 Expenses

| # | Screen | Route | Description | Key Elements |
|---|--------|-------|-------------|--------------|
| 17 | **Add Expense Group Picker** | Modal | Choose group | Bottom sheet, group list |
| 18 | **Add/Edit Expense** | `/add-expense` | Expense form | Amount, description, paid by, split type, participants, receipt |
| 19 | **Expense Detail** | `/expense-detail` | Single expense | Title, amount, split breakdown, spending trends, comment input |
| 20 | **Request Payment QR** | `/request-payment-qr` | UPI QR + notify | QR code, member list, notify button |
| 21 | **Payment Request View** | `/payment-request-view` | View QR (from notification) | QR, amount, sender, scan instructions |

### 4.5 Chat & Notifications

| # | Screen | Route | Description | Key Elements |
|---|--------|-------|-------------|--------------|
| 22 | **Chats List** | `/chats` | Group chats | List of chat threads, unread badge |
| 23 | **Chat** | `/chat/:id` | Group chat room | Messages, input, send, long-press delete |
| 24 | **Notifications** | `/messages` | All notifications | List, mark read, clear by group |

### 4.6 Profile & Settings

| # | Screen | Route | Description | Key Elements |
|---|--------|-------|-------------|--------------|
| 25 | **User Profile** | `/user-profile/:id` | Other user's profile | Avatar, name, view only |
| 26 | **Edit Profile** | `/edit-profile` | Edit own profile | Name, avatar, UPI ID |
| 27 | **Settings** | `/settings` | App settings | Theme, FCM token debug, notifications |

### 4.7 Gallery

| # | Screen | Route | Description | Key Elements |
|---|--------|-------|-------------|--------------|
| 28 | **Share Gallery** | `/share-gallery` | My shared albums | Create, view albums |
| 29 | **Gallery Viewer** | `/gallery-viewer/:id` | View album | Grid of photos, full-screen |

### 4.8 History

| # | Screen | Route | Description | Key Elements |
|---|--------|-------|-------------|--------------|
| 30 | **Group History** | `/group-history` | Past groups | List of archived groups |

---

## 5. Screen Specifications (Design)

### 5.1 Design System

```
Colors:
  - Primary: #67A88B (Green)
  - Dark Background: #121212
  - Dark Card: #2C2C2C
  - Text Grey: #757575
  - Success: #4CAF50
  - Error: #F44336

Typography:
  - Font: Poppins
  - Sizes: 8, 10, 12, 14, 16, 18, 20, 24, 28, 32, 36

Spacing:
  - Padding: 4, 8, 12, 16, 20, 24, 32
  - Radius: 4, 8, 12, 16, 20, 24
```

### 5.2 Key Screen Wireframes (Description)

#### Home Screen
```
┌─────────────────────────────────┐
│ [🔔]                    Header   │
├─────────────────────────────────┤
│ [Search...] [Sort ▼]            │
├─────────────────────────────────┤
│ ┌─────────────────────────────┐ │
│ │ Overall Summary Card        │ │
│ │ You owe / You lent          │ │
│ └─────────────────────────────┘ │
│                                 │
│ Group Card 1 (name, balance)    │
│ [Chat] [→]                      │
│                                 │
│ Group Card 2                    │
│                                 │
│ [+ Start New Group]             │
├─────────────────────────────────┤
│ Groups | Friends | Activity | 👤 │
└─────────────────────────────────┘
        [➕ Add expense] FAB
```

#### Group Detail Tabs
```
┌─────────────────────────────────┐
│ ← Group Details                 │
├─────────────────────────────────┤
│ Group Header (name, admin)      │
│ Description, category, dates    │
├─────────────────────────────────┤
│ [Members] [Expenses] [Chat]     │
├─────────────────────────────────┤
│ Expenses Section:               │
│ [Settle] [Balances] [Totals]    │
│ [Charts]                        │
│                                 │
│ Total balance card              │
│ Expense list (month grouped)    │
│ [Notify] [Pay via QR]           │
└─────────────────────────────────┘
```

#### Add Expense
```
┌─────────────────────────────────┐
│ ← Add Expense                   │
├─────────────────────────────────┤
│ Amount        [___________]     │
│ Description   [___________]     │
│ Paid by       [You ▼]           │
│ Split         [Equally ▼]       │
│ Participants  [Select people]   │
│ Receipt       [📷 Add]          │
├─────────────────────────────────┤
│        [Save Expense]           │
└─────────────────────────────────┘
```

#### Request Payment QR
```
┌─────────────────────────────────┐
│ ← Pay via QR                    │
├─────────────────────────────────┤
│ Scan to pay                     │
│ Rs. 2,555.00                    │
│ ┌─────────────────────────┐    │
│ │     [QR CODE IMAGE]      │    │
│ └─────────────────────────┘    │
│ UPI ID: xxx@paytm               │
│                                 │
│ Members who owe you             │
│ ☑ User A - Rs. 1,277.50        │
│ ☑ User B - Rs. 1,277.50        │
│ [✓ Select all]                 │
│ [Notify selected (2)]          │
└─────────────────────────────────┘
```

---

## 6. User Flows

### 6.1 New User → First Group
1. Splash → Onboarding → Register/Login
2. Home (empty) → Create Group
3. Fill form → Location Search → Save
4. Group Detail → Add Members

### 6.2 Add & Split Expense
1. Home → FAB → Select Group (modal)
2. Add Expense → Amount, paid by, split, participants
3. Save → Group Detail → Expense appears in Settle tab
4. Tap expense → Expense Detail (Splitwise-style)

### 6.3 Request Payment
1. Group Detail → Expenses → Balances
2. Pay via QR → UPI QR page
3. Select members → Notify
4. Recipient gets FCM → Tap → Payment Request View (QR)

### 6.4 Chat
1. Home → Group card → Chat icon **or** Chats tab
2. Chat list → Select group
3. Send messages, long-press to delete own

### 6.5 Notifications
1. FCM arrives (message / payment reminder)
2. Tap → Navigate to Chat or Payment Request View
3. In-app Notifications page → List all, tap to navigate

---

## 7. Data Models (Summary)

| Model | Key Fields |
|-------|------------|
| **GroupModel** | id, name, description, location, radius, type, currency, category, members, settings |
| **ExpenseModel** | id, groupId, amount, currency, description, paidBy, participants, customAmounts, imageUrl |
| **NotificationModel** | id, type, title, body, data (groupId, upiUri, amount, etc.) |
| **GroupMember** | userId, role, joinedAt, locationSharingEnabled |
| **MessageModel** | id, groupId, senderId, content, type, createdAt |

---

## 8. API / Integrations

| Service | Purpose |
|---------|---------|
| Firebase Auth | Email, Google, phone login |
| Firestore | Groups, expenses, messages, notifications |
| Firebase Storage | Receipt images, gallery photos |
| FCM | Push notifications (Cloud Function triggers on notification create) |
| ImgBB (or similar) | Receipt image hosting for expenses |
| Google Maps | Location picker |
| UPI | Payment collection via QR |

---

## 9. Non-Functional Requirements

| Category | Requirement |
|----------|-------------|
| **Performance** | App launch < 3s, list load < 1s |
| **Offline** | Cache groups, show cached data when offline |
| **Security** | Firestore rules, auth-only access |
| **Accessibility** | Labels, contrast, touch targets ≥ 44pt |
| **Platform** | Android, iOS (Flutter) |

---

## 10. Future Enhancements (Roadmap)

- [ ] Voice/Video calls (Agora)
- [ ] Recurring expenses
- [ ] Expense categories & budget
- [ ] Multi-currency support
- [ ] Export to PDF/CSV
- [ ] Group analytics dashboard
- [ ] Dark/Light theme toggle in UI (if not present)

---

## Appendix A: Route Reference

```
/                     → Splash
/onboarding           → Onboarding
/login                → Login
/register             → Register
/forgot-password      → Forgot Password
/home                 → Home (Groups)
/contacts             → Contacts
/chats                → Chats List
/chat/:id             → Chat Room
/messages             → Notifications
/profile              → Profile
/edit-profile         → Edit Profile
/user-profile/:id     → User Profile
/settings             → Settings
/create-group         → Create Group
/location-search      → Location Search
/group-detail/:id     → Group Detail
/add-member/:id       → Add Member (Email)
/add-member-from-contacts → Add Member (Contacts)
/add-member-review    → Add Member Review
/add-someone-new      → Add Someone New
/add-expense          → Add/Edit Expense
/expense-detail       → Expense Detail
/request-payment-qr   → Request Payment QR
/payment-request-view → Payment Request View (from notification)
/share-gallery        → Share Gallery
/shared-with-me       → Shared With Me
/gallery-viewer/:id   → Gallery Viewer
/group-history        → Group History
```

---

## Appendix B: Screen Count Summary

| Category | Screens |
|----------|---------|
| Auth & Onboarding | 5 |
| Main Tabs | 4 |
| Group Management | 7 |
| Expenses | 5 |
| Chat & Notifications | 3 |
| Profile & Settings | 3 |
| Gallery | 3 |
| History | 1 |
| **Total** | **31** |

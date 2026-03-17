# Location-Based Community App - System Design

## Overview
A comprehensive location-based community application built with Flutter and Firebase, enabling users to create geo-fenced groups, communicate in real-time, share locations, and manage expenses.

## Tech Stack

### Frontend
- **Framework**: Flutter (Dart)
- **State Management**: Flutter Bloc (Cubit)
- **Navigation**: GoRouter
- **UI Components**: Custom widgets with Material Design

### Backend & Services
- **Authentication**: Firebase Authentication
- **Database**: Cloud Firestore
- **Real-time Updates**: Firestore Streams + Cloud Functions
- **File Storage**: Firebase Storage
- **Push Notifications**: Firebase Cloud Messaging (FCM)
- **Location Services**: Google Maps API + Geohashing
- **Voice/Video Calling**: Agora.io or Twilio (via Cloud Functions)
- **Cloud Functions**: Firebase Cloud Functions (Node.js)

## Core Features

### 1. Geo-fenced Group Creation
- Users can create groups with GPS-based radius (2km-5km)
- Automatic discovery of nearby groups
- Join/Leave group functionality
- Group privacy settings (Public/Private/Invite-only)

### 2. Real-time Communication
- **Text Messages**: Real-time chat with Firestore
- **Multimedia**: Images, Videos, Documents via Firebase Storage
- **Voice Calls**: P2P and Group calling via Agora/Twilio
- **Video Calls**: WebRTC-based video conferencing
- **Message Status**: Sent, Delivered, Read receipts

### 3. Advanced Location Sharing
- Real-time live location tracking
- Privacy toggle (On/Off)
- Location history within groups
- Geofence alerts (enter/exit notifications)

### 4. Integrated Expense Splitter
- Create expense entries
- Split expenses among group members
- Automated settlement calculations
- Payment reminders
- Expense history and analytics

## Database Schema (Firestore)

### Collections Structure

```
users/
  {userId}/
    - id: string
    - name: string
    - email: string
    - phone: string
    - avatarUrl: string
    - location: GeoPoint
    - locationSharingEnabled: boolean
    - lastSeen: timestamp
    - createdAt: timestamp
    - updatedAt: timestamp

groups/
  {groupId}/
    - id: string
    - name: string
    - description: string
    - creatorId: string
    - location: GeoPoint
    - radius: number (in meters: 2000-5000)
    - type: string (public/private/invite-only)
    - memberCount: number
    - createdAt: timestamp
    - updatedAt: timestamp
    - members/
      {userId}/
        - userId: string
        - role: string (admin/member)
        - joinedAt: timestamp
        - locationSharingEnabled: boolean
    - settings/
      - allowLocationSharing: boolean
      - allowExpenseTracking: boolean

messages/
  {groupId}/
    {messageId}/
      - id: string
      - groupId: string
      - senderId: string
      - senderName: string
      - type: string (text/image/video/audio/document/location)
      - content: string
      - mediaUrl: string (optional)
      - location: GeoPoint (optional)
      - createdAt: timestamp
      - readBy: array<{userId, timestamp}>

locations/
  {groupId}/
    {userId}/
      - userId: string
      - groupId: string
      - location: GeoPoint
      - timestamp: timestamp
      - isActive: boolean

expenses/
  {groupId}/
    {expenseId}/
      - id: string
      - groupId: string
      - createdBy: string
      - title: string
      - description: string
      - amount: number
      - currency: string
      - category: string
      - createdAt: timestamp
      - splits/
        {userId}/
          - userId: string
          - amount: number
          - paid: boolean
          - paidAt: timestamp (optional)
      - settled: boolean
      - settledAt: timestamp (optional)

notifications/
  {userId}/
    {notificationId}/
      - id: string
      - userId: string
      - type: string (group_invite/expense_reminder/location_alert/message)
      - title: string
      - body: string
      - data: map
      - read: boolean
      - createdAt: timestamp
```

## API Endpoints (Firebase Cloud Functions)

### Group Management
- `createGroup(groupData)` - Create new geo-fenced group
- `joinGroup(groupId, userId)` - Join existing group
- `leaveGroup(groupId, userId)` - Leave group
- `getNearbyGroups(location, radius)` - Discover nearby groups
- `updateGroupSettings(groupId, settings)` - Update group settings

### Messaging
- `sendMessage(groupId, messageData)` - Send message
- `getMessages(groupId, limit, lastMessageId)` - Get messages
- `markAsRead(groupId, messageId, userId)` - Mark message as read
- `deleteMessage(groupId, messageId)` - Delete message

### Location Services
- `updateLocation(userId, location)` - Update user location
- `getGroupMemberLocations(groupId)` - Get all member locations
- `toggleLocationSharing(userId, enabled)` - Toggle location sharing

### Expense Management
- `createExpense(groupId, expenseData)` - Create expense
- `splitExpense(expenseId, splits)` - Split expense among members
- `markExpensePaid(expenseId, userId)` - Mark expense as paid
- `getExpenseSummary(groupId)` - Get expense summary
- `settleExpenses(groupId)` - Settle all expenses

### Voice/Video Calling
- `initiateCall(groupId, callType, participants)` - Initiate call
- `endCall(callId)` - End call
- `getCallToken(userId, channelName)` - Get Agora/Twilio token

## Security Rules (Firestore)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Groups: Members can read, admins can write
    match /groups/{groupId} {
      allow read: if request.auth != null && 
        exists(/databases/$(database)/documents/groups/$(groupId)/members/$(request.auth.uid));
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
        resource.data.creatorId == request.auth.uid;
    }
    
    // Messages: Group members can read/write
    match /messages/{groupId}/{messageId} {
      allow read, write: if request.auth != null && 
        exists(/databases/$(database)/documents/groups/$(groupId)/members/$(request.auth.uid));
    }
    
    // Locations: Group members can read/write
    match /locations/{groupId}/{userId} {
      allow read: if request.auth != null && 
        exists(/databases/$(database)/documents/groups/$(groupId)/members/$(request.auth.uid));
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Expenses: Group members can read/write
    match /expenses/{groupId}/{expenseId} {
      allow read, write: if request.auth != null && 
        exists(/databases/$(database)/documents/groups/$(groupId)/members/$(request.auth.uid));
    }
  }
}
```

## Architecture Patterns

### Clean Architecture
```
features/
  community/
    data/
      datasources/
        - group_remote_datasource.dart
        - message_remote_datasource.dart
        - location_remote_datasource.dart
        - expense_remote_datasource.dart
      models/
        - group_model.dart
        - message_model.dart
        - location_model.dart
        - expense_model.dart
      repositories/
        - group_repository_impl.dart
        - message_repository_impl.dart
        - location_repository_impl.dart
        - expense_repository_impl.dart
    domain/
      entities/
        - group_entity.dart
        - message_entity.dart
        - location_entity.dart
        - expense_entity.dart
      repositories/
        - group_repository.dart
        - message_repository.dart
        - location_repository.dart
        - expense_repository.dart
    presentation/
      cubit/
        - group_cubit.dart
        - message_cubit.dart
        - location_cubit.dart
        - expense_cubit.dart
      pages/
        - home_page.dart
        - group_detail_page.dart
        - chat_page.dart
        - expense_page.dart
      widgets/
        - group_card.dart
        - message_bubble.dart
        - location_map.dart
        - expense_card.dart
```

## Real-time Features Implementation

### 1. Location Updates
- Use Firestore `onSnapshot` for real-time location updates
- Update location every 30 seconds when sharing is enabled
- Use Geohashing for efficient location queries

### 2. Messaging
- Firestore streams for real-time message delivery
- Cloud Functions for push notifications
- Message pagination for performance

### 3. Group Discovery
- Geohash-based queries for nearby groups
- Index on location field for efficient queries
- Cache nearby groups for offline access

## Performance Optimizations

1. **Pagination**: Implement pagination for messages and expenses
2. **Caching**: Cache frequently accessed data locally
3. **Indexing**: Proper Firestore indexes for location queries
4. **Image Optimization**: Compress images before upload
5. **Lazy Loading**: Load groups and messages on demand
6. **Background Sync**: Sync data in background

## Scalability Considerations

1. **Sharding**: Shard large collections (messages) by date
2. **Cloud Functions**: Use Cloud Functions for heavy computations
3. **CDN**: Use Firebase Storage CDN for media files
4. **Rate Limiting**: Implement rate limiting for API calls
5. **Monitoring**: Use Firebase Analytics and Crashlytics

## Feature Roadmap

### Phase 1 (MVP)
- ✅ User Authentication
- ✅ Geo-fenced Group Creation
- ✅ Basic Messaging (Text)
- ✅ Location Sharing
- ✅ Basic Expense Tracking

### Phase 2
- 📱 Multimedia Messages
- 📞 Voice Calling (P2P)
- 💰 Advanced Expense Splitter
- 🔔 Push Notifications

### Phase 3
- 📹 Video Calling
- 👥 Group Voice/Video Calls
- 📊 Expense Analytics
- 🗺️ Advanced Location Features

### Phase 4
- 🤖 AI-powered Group Recommendations
- 📈 Group Analytics Dashboard
- 🎨 Custom Themes
- 🌍 Multi-language Support


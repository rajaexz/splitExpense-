#!/bin/bash
# Deploy Firebase Cloud Functions for FCM push notifications
set -e
cd "$(dirname "$0")/../functions"
echo "Installing dependencies..."
npm install
echo "Building..."
npm run build
echo "Deploying to Firebase..."
firebase deploy --only functions
echo "Done! FCM push notifications ab background/terminated state mein bhi kaam karenge."

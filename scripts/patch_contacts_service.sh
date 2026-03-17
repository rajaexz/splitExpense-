#!/bin/bash
# Patch contacts_service to fix Android namespace error
# Run after: flutter pub get

FILE="$HOME/.pub-cache/hosted/pub.dev/contacts_service-0.6.3/android/build.gradle"
if [ ! -f "$FILE" ]; then
  echo "Run 'flutter pub get' first"
  exit 1
fi
if grep -q "namespace " "$FILE"; then
  echo "Already patched"
  exit 0
fi
sed -i.bak '/^android {/a\
    namespace '\''flutter.plugins.contactsservice.contactsservice'\''
' "$FILE"
echo "Patched successfully"

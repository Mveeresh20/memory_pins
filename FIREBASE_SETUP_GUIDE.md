# Firebase Setup Guide

## 🔥 **IMPORTANT: Deploy Firebase Rules**

The app is now configured with simple Firebase rules that allow all authenticated users to read and write data. You need to deploy these rules to your Firebase project.

### **Step 1: Go to Firebase Console**
1. Open [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `memory_pins_app`

### **Step 2: Deploy Rules**
1. In the left sidebar, click **"Realtime Database"**
2. Click on the **"Rules"** tab
3. Replace the existing rules with this simple rule:

```json
{
  "rules": {
    ".read": "auth != null",
    ".write": "auth != null"
  }
}
```

4. Click **"Publish"** to deploy the rules

### **Step 3: Test the App**
After deploying the rules:
1. Run the app: `flutter run`
2. Create a new pin
3. The pin should now appear on the home screen map
4. Tap the pin to see the details bottom sheet

## ✅ **What These Rules Do:**
- **Allow all authenticated users** to read and write to any path
- **Simple and permissive** - no complex restrictions
- **Perfect for development and testing**

## 🔒 **Security Note:**
These rules are very permissive for development. For production, you should implement more restrictive rules based on your security requirements.

## 🚀 **Next Steps:**
1. Deploy the rules above
2. Test creating and viewing pins
3. The app should work perfectly now!

---

**If you still get permission errors after deploying these rules, please let me know!** 
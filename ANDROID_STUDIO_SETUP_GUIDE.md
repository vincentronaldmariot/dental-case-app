# Android Studio Setup Guide for APK Building

## 🚀 **Step-by-Step Installation**

### **Step 1: Download Android Studio**
1. Go to: https://developer.android.com/studio
2. Click "Download Android Studio"
3. Choose the Windows version
4. Download the installer (about 1GB)

### **Step 2: Install Android Studio**
1. **Run the installer** as Administrator
2. **Choose "Standard" installation** (recommended)
3. **Let it install Android SDK automatically**
4. **Wait for installation** (10-15 minutes)
5. **Launch Android Studio** when prompted

### **Step 3: First Launch Setup**
1. **Welcome screen**: Click "Next"
2. **Choose UI Theme**: Select your preference
3. **SDK Setup**: Let it download additional components
4. **Wait for downloads** (may take 10-20 minutes)
5. **Click "Finish"** when complete

### **Step 4: Configure Android SDK**
1. **Open Android Studio**
2. **Go to Tools > SDK Manager**
3. **In "SDK Platforms" tab**:
   - ✅ Check "Android 14.0 (API 34)"
   - ✅ Check "Android 13.0 (API 33)"
   - ✅ Check "Android 12.0 (API 31)"
4. **In "SDK Tools" tab**:
   - ✅ Check "Android SDK Build-Tools"
   - ✅ Check "Android SDK Command-line Tools"
   - ✅ Check "Android Emulator"
5. **Click "Apply"** and wait for installation

### **Step 5: Configure Flutter**
1. **Open Command Prompt** in your project folder
2. **Run the setup script**:
   ```bash
   .\setup_android_studio.bat
   ```
3. **Accept Android licenses**:
   ```bash
   flutter doctor --android-licenses
   ```
   - Type "y" and press Enter for each license

### **Step 6: Verify Setup**
1. **Run Flutter doctor**:
   ```bash
   flutter doctor
   ```
2. **All Android items should show green checkmarks** ✅

### **Step 7: Build APK**
1. **Run the build script**:
   ```bash
   .\build_apk_local.bat
   ```
2. **APK will be created** at: `build\app\outputs\flutter-apk\app-debug.apk`

## 📱 **Installing APK on Android Device**

### **Method 1: USB Connection**
1. **Enable Developer Options** on your Android phone:
   - Go to Settings > About Phone
   - Tap "Build Number" 7 times
2. **Enable USB Debugging**:
   - Go to Settings > Developer Options
   - Turn on "USB Debugging"
3. **Connect phone via USB**
4. **Run**: `flutter install`

### **Method 2: Direct APK Transfer**
1. **Copy the APK file** from `build\app\outputs\flutter-apk\app-debug.apk`
2. **Transfer to your phone** via USB, email, or cloud storage
3. **Install on phone**:
   - Enable "Install from Unknown Sources"
   - Open the APK file
   - Follow installation prompts

## 🔧 **Troubleshooting**

### **Common Issues:**

#### **"Android SDK not found"**
- Run: `flutter config --android-sdk C:\Users\YourUsername\AppData\Local\Android\Sdk`
- Or set ANDROID_HOME environment variable

#### **"Build failed"**
- Make sure Android SDK Platform 33+ is installed
- Run: `flutter clean` then `flutter pub get`

#### **"License not accepted"**
- Run: `flutter doctor --android-licenses`
- Accept all licenses

#### **"Device not found"**
- Enable USB Debugging on your phone
- Install USB drivers for your phone model

## 📋 **Quick Commands**

```bash
# Check setup
flutter doctor

# Accept licenses
flutter doctor --android-licenses

# Build APK
flutter build apk --debug

# Install on connected device
flutter install

# Run setup script
.\setup_android_studio.bat

# Run build script
.\build_apk_local.bat
```

## 🎯 **Expected Results**

After setup, `flutter doctor` should show:
```
[√] Flutter (Channel stable, 3.32.7)
[√] Android toolchain - develop for Android devices
[√] Android Studio (version 2023.1.1)
[√] VS Code (version 1.102.1)
[√] Connected device (1 available)
```

## 📞 **Need Help?**

If you encounter issues:
1. Check the error message carefully
2. Run `flutter doctor -v` for detailed info
3. Make sure all Android SDK components are installed
4. Restart Android Studio and try again 
# 📷 PHOTO & GPS SYSTEM - Complete Image Capture & Storage Flow

## 📍 What is the Photo & GPS System?

The app captures **photos of commodities** along with **GPS coordinates** showing WHERE the photo was taken. This creates a georeferenced record of the crop/livestock/poultry.

**Example:**
```
Photo: crops_Carrot_14.5123_121.0234.jpg
└─ GPS Coordinates: 14.5123° N, 121.0234° E
   └─ Location: Batangas, Philippines
   └─ Accuracy: ±5 meters
```

---

## 📸 PHOTO CAPTURE FLOW

### Step 1: User Triggers Photo Capture

**File:** `step_07_trainings.dart` (or any step with camera button)

**User Action:** Clicks camera icon/button during Step 07

```dart
// In step_07_trainings.dart

ElevatedButton(
  onPressed: () => _capturePhoto(),
  child: Icon(Icons.camera),
)
```

### Step 2: Request Camera & Location Permissions

**File:** `step_07_trainings.dart`

```dart
Future<void> _capturePhoto() async {
  
  // Request camera permission
  final cameraStatus = await Permission.camera.request();
  if (!cameraStatus.isGranted) {
    showError('Camera permission denied');
    return;
  }
  
  // Request location permission (for GPS)
  final locationStatus = await Permission.location.request();
  if (!locationStatus.isDenied) {
    // Location permission granted or already granted
    _getCurrentLocation();
  }
  
  // Open camera
  final pickedFile = await ImagePicker().pickImage(
    source: ImageSource.camera,
    preferredCameraDevice: CameraDevice.rear,
  );
  
  if (pickedFile != null) {
    _photoPath = pickedFile.path;
    setState(() {});
  }
}
```

### Step 3: Get GPS Coordinates

**File:** `step_07_trainings.dart`

```dart
Future<void> _getCurrentLocation() async {
  try {
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
      timeLimit: Duration(seconds: 10),
    );
    
    // Store GPS data
    _photoLatitude = position.latitude;      // e.g., 14.5123
    _photoLongitude = position.longitude;    // e.g., 121.0234
    _photoAccuracy = position.accuracy;      // e.g., 5.0 meters
    
    print('🗺️ GPS Captured:');
    print('   Latitude: $_photoLatitude');
    print('   Longitude: $_photoLongitude');
    print('   Accuracy: $_photoAccuracy meters');
    
  } catch (e) {
    print('⚠️ Could not get GPS: $e');
    // Continue without GPS if unavailable
  }
}
```

### Step 4: Display Photo Preview

```dart
// After photo captured and GPS obtained

if (_photoPath != null) {
  return Column(
    children: [
      Image.file(File(_photoPath!), height: 250),
      SizedBox(height: 12),
      if (_photoLatitude != null)
        Text(
          '📍 GPS: $_photoLatitude, $_photoLongitude (±${_photoAccuracy?.toStringAsFixed(1)}m)',
          style: TextStyle(fontSize: 12, color: Colors.green),
        ),
      SizedBox(height: 12),
      Row(
        children: [
          ElevatedButton.icon(
            onPressed: _capturePhoto,
            icon: Icon(Icons.camera),
            label: Text('Retake'),
          ),
          ElevatedButton(
            onPressed: _savePhoto,
            child: Text('Use This Photo'),
          ),
        ],
      ),
    ],
  );
}
```

---

## 💾 PHOTO SAVING PROCESS

### Step 1: Get Commodity Name from Data

**File:** `step_07_trainings.dart` - Lines 722-732

```dart
// When user clicks "Save" at Step 07

final typeOfCrop = (jsonData['typeOfCrop'] as String? ?? '').trim();
final variety = (jsonData['variety'] as String? ?? '').trim();

// Create commodity name: "Carrot_Tall"
final commodityName = '${typeOfCrop}_$variety';

print('🌾 Commodity: $commodityName');
// Output: "Carrot_Tall"
```

### Step 2: Request Camera & GPS, Then Open Camera

**File:** `photo_capture_location_service.dart`

```dart
Future<PhotoWithLocation> captureFromCamera({
  required String productionType,
  required String implementationType,
  required String groupName,
  required String farmerName,
}) async {
  // Step 1: Get GPS FIRST (before opening camera)
  print('📍 [GPS CAPTURE] Requesting GPS position...');
  
  Position position = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.best,
      timeLimit: Duration(seconds: 15),
    ),
  );
  
  print('✅ [GPS CAPTURE] Got position: lat=${position.latitude}, lon=${position.longitude}');
  
  // Step 2: NOW open camera (GPS is already captured)
  final image = await _picker.pickImage(
    source: ImageSource.camera,
    imageQuality: 90,
  );
  
  if (image == null) throw Exception('Photo capture cancelled.');
  
  print('✅ [PHOTO CAPTURE] Photo taken');
  
  // Step 3: Move to organized storage
  final storedPath = await _moveToOrganizedStorage(
    sourcePath: image.path,
    productionType: productionType,
    implementationType: implementationType,
    groupName: groupName,
    farmerName: farmerName,
  );
  
  return PhotoWithLocation(
    path: storedPath,
    latitude: position.latitude,
    longitude: position.longitude,
    accuracy: position.accuracy,
    capturedAt: DateTime.now(),
  );
}
```

### Step 3: Create Organized Filename

**Actual Filename Format:**

```
{farmerName}_{productionType}_{timestamp}.jpg
```

**Examples:**
```
John_Fruto_Ambal_crop_20240115_143022.jpg
farm_photo_crop_20240115_143530.jpg
Maribel_Oflaria_livestock_20240115_144530.jpg
```

**Parts:**
- `{farmerName}` = Farmer name or group name (spaces → underscores)
- `{productionType}` = 'crop', 'livestock', or 'poultry'
- `{timestamp}` = YYYYMMDD_HHMMSS (e.g., 20240115_143022)

### Step 4: Store in Organized Directory Structure

```
/storage/emulated/0/Android/data/com.example.da_monitoring_app/files/
└── profiling_photos/
    ├── crop production/
    │   ├── collective/
    │   │   └── janeirohAgriculture/
    │   │       ├── farm_photo_crop_20240115_143022.jpg
    │   │       └── farm_photo_crop_20240115_143530.jpg
    │   │
    │   └── individual/
    │       ├── janeirohAgriculture/
    │       │   ├── John_Fruto_Ambal_crop_20240115_143022.jpg
    │       │   └── John_Fruto_Ambal_crop_20240115_150022.jpg
    │
    ├── livestock production/
    │   └── ... (same structure)
    │
    └── poultry production/
        └── ... (same structure)
```

### Step 5: Write GPS Coordinates to EXIF Metadata

**File:** `photo_capture_location_service.dart`

After photo is saved to organized storage, GPS coordinates are written to EXIF metadata using the `native_exif` package:

```dart
Future<void> _writeAndValidateGpsExif({
  required String imagePath,
  required Position position,
  required DateTime capturedAt,
}) async {
  try {
    print('📍 [EXIF WRITE] Starting GPS EXIF write...');
    
    // Convert GPS coordinates to EXIF format
    final latValue = '${position.latitude.abs()}';
    final lonValue = '${position.longitude.abs()}';
    
    // Write GPS to EXIF tags using native_exif package
    await NativeExif.writeExifFromMap(
      imagePath,
      {
        'GPSLatitudeRef': position.latitude >= 0 ? 'N' : 'S',
        'GPSLatitude': latValue,
        'GPSLongitudeRef': position.longitude >= 0 ? 'E' : 'W',
        'GPSLongitude': lonValue,
        'GPSDateStamp': _gpsDateStamp(capturedAt),
      },
    );
    
    print('✅ [EXIF WRITE] GPS coordinates written to EXIF:');
    print('   Latitude: ${position.latitude}° $latValue');
    print('   Longitude: ${position.longitude}° $lonValue');
    
  } catch (e) {
    print('⚠️ [EXIF WRITE] Failed to write GPS to EXIF: $e');
    // Photo still exists, just without GPS in EXIF
  }
}
```

### Stored GPS Metadata (EXIF Tags)

When you open the photo with an EXIF reader tool, you'll see:

```
GPSLatitudeRef:  N (North for positive)
GPSLatitude:     14.5123°
GPSLongitudeRef: E (East for positive)
GPSLongitude:    121.0234°
GPSDateStamp:    2024:01:15
```

---

## 📋 RETRIEVING GPS DATA

### From EXIF Metadata

```dart
// Read GPS from photo EXIF using native_exif
final exifData = await NativeExif.readExif(imagePath);

if (exifData != null) {
  final latitude = exifData['GPSLatitude'];  // "14.5123"
  final latRef = exifData['GPSLatitudeRef'];  // "N"
  final longitude = exifData['GPSLongitude'];  // "121.0234"
  final lonRef = exifData['GPSLongitudeRef'];  // "E"
  
  // Reconstruct coordinates with proper sign
  final lat = latRef == 'N' 
    ? double.parse(latitude) 
    : -double.parse(latitude);
    
  final lon = lonRef == 'E' 
    ? double.parse(longitude) 
    : -double.parse(longitude);
  
  print('📍 Photo taken at: $lat, $lon');
}
```
   ↓
Step 13: Photo ready for upload with full GPS metadata
```

---

## 🔥 PHOTO UPLOAD TO FIREBASE

### Current Implementation

**Photos are NOT automatically uploaded to Firebase yet.**

**What happens:**
1. ✅ Photos saved to local device storage
2. ✅ GPS coordinates saved in JSON
3. ⚠️ Photos stored locally only (not on Firebase Storage)
4. ⚠️ GPS in JSON synced to Firestore (visible in pending_monitoring)

### Future Enhancement Needed

To upload photos to Firebase Storage:

```dart
// (Not yet implemented)

Future<void> uploadPhotoToFirebase(String localPhotoPath) async {
  final file = File(localPhotoPath);
  final filename = file.path.split('/').last;
  
  try {
    await FirebaseStorage.instance
        .ref('monitoring_photos/$filename')
        .putFile(file);
    
    print('✅ Photo uploaded to Firebase Storage');
  } catch (e) {
    print('⚠️ Photo upload failed: $e');
  }
}
```

---

## 📊 Photo Filename Format

### Pattern
```
crops_{typeOfCrop}_{variety}_{latitude}_{longitude}.jpg
```

### Examples

**Crop Commodities:**
```
crops_Carrot_Tall_14.5123_121.0234.jpg
crops_Rice_IR64_14.5456_121.0567.jpg
crops_Coconut_Dwarf_14.5789_121.0890.jpg
```

**Livestock:**
```
livestock_Goat_Boer_14.6123_121.1234.jpg
livestock_Cattle_HolsteinFriesian_14.6456_121.1567.jpg
```

**Poultry:**
```
poultry_Chicken_BroilerNative_14.7123_121.2234.jpg
poultry_Duck_Muscovy_14.7456_121.2567.jpg
```

---

## 🔑 Key Points for Photo & GPS

1. **Filename encodes GPS:** Coordinates are visible in the filename
2. **Dual storage:** GPS stored in EXIF (photo metadata) AND in JSON
3. **Always captured:** Every photo gets GPS (when location permission granted)
4. **Accuracy matters:** ±5-20 meters typical accuracy for mobile GPS
5. **Used for verification:** Proves commodity was physically present at location
6. **Privacy consideration:** GPS coordinates identify exact farm location


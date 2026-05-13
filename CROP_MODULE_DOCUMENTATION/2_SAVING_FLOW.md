# 2️⃣ SAVING FLOW - How Data Gets Saved

## 🔄 The Complete Save Process

Your crop data goes through multiple save points, with the final save happening at **Step 07 (Trainings)**.

---

## 📝 STEP 01: Project Background

**File:** `step_01_project_background.dart`

**What Happens:**
1. User fills in group-level information
2. Clicks "Next" button
3. Data is saved to `group.json`

**Data Saved:**
```json
{
  "fcaName": "janeirohAgriculture",
  "reportingPeriod": "2026",
  "region": "Region IV-A (CALABARZON)",
  "province": "Batangas",
  "municipality": "Lipa City",
  "barangay": "Barangay 2",
  "projectTitle": "agriculture",
  "primaryIntervention": "Coconut",
  "supportInterventions": ["idk"],
  "members": [...]
}
```

**Save Location:**
```
/storage/.../crop/janeirohAgriculture/group.json
```

**Save Method:** `LocalFarmerStorageService.saveGroupData()`

**Important:** This is a **group-level save** - only happens once!

---

## 📝 STEPS 02-06: Incremental Form Filling

**Files:** 
- `step_02_commodity_information.dart`
- `step_03_planting_stage.dart`
- `step_04_fertilization.dart`
- `step_05_harvesting_stage.dart`
- `step_06_crop_damage.dart`

**What Happens:**
1. User fills in commodity information (crop type, variety, quantity)
2. Fills in planting details (land area, seed amount, date)
3. Fills in fertilizer data
4. Fills in harvest information
5. Fills in pest/disease damage
6. Clicks "Next" after each step

**Data Storage:** All data is stored in **memory** (in the form's state) during Steps 02-06

**NOT saved to disk yet** - waiting for final save at Step 07

**Why?** To ensure complete data before writing to file

---

## 💾 STEP 07: FINAL SAVE - Trainings (THE CRITICAL POINT)

**File:** `step_07_trainings.dart` - Lines 722-732

**This is where EVERYTHING is saved to disk!**

### Step 1: Prepare Directory
```dart
// Create farmer folder if it doesn't exist
/storage/.../crop/janeirohAgriculture/John_Fruto_Ambal/
```

### Step 2: Get GPS Coordinates (BEFORE saving)
```dart
double? _photoLatitude;    // Captured from camera GPS
double? _photoLongitude;   // Captured from camera GPS
double? _photoAccuracy;    // GPS accuracy in meters
```

### Step 3: Merge All Steps into data.json
```dart
// Combine Steps 02-07 into one complete JSON
final Map<String, dynamic> jsonData = {
  'fcaName': 'janeirohAgriculture',
  'reportingPeriod': '2026',
  'farmerName': 'John Fruto Ambal',
  'saadIdNo': '1',
  
  // Step 02 data
  'completedCommodities': [{
    'typeOfCrop': 'Vegetables',
    'variety': 'Carrot',
    'farmgatePrice': '50',
    // ... all commodity fields
  }],
  
  // Step 03 data
  'totalLandArea': '1 hectare',
  'landOwnership': 'Own',
  // ... all planting fields
  
  // Step 04 data
  'fertilizerType': ['Organic'],
  // ... all fertilizer fields
  
  // Step 05 data
  'dateHarvestCycles': ['2026-07-15'],
  // ... all harvest fields
  
  // Step 06 data
  'hasPest': true,
  // ... all damage fields
  
  // Step 07 data
  'trainings': [{
    'name': 'Climate-Smart Agriculture',
    'date': '2026-05-10'
  }]
};
```

### Step 4: Add GPS to Commodity
```dart
if (_photoLatitude != null && _photoLongitude != null) {
  currentCommodity['photoGPS'] = {
    'latitude': _photoLatitude!,
    'longitude': _photoLongitude!,
    'accuracy': _photoAccuracy ?? 0.0,
  };
}
```

### Step 5: Save data.json
```dart
// Write all merged data to farmer's data.json
File('/storage/.../crop/janeirohAgriculture/John_Fruto_Ambal/data.json')
  .writeAsString(jsonEncode(jsonData));
```

**Result:** 
```
/storage/.../crop/janeirohAgriculture/John_Fruto_Ambal/data.json ✓ Saved
```

### Step 6: Save Photo with GPS in Filename

**Current Implementation (Lines 722-732):**
```dart
final typeOfCrop = (jsonData['typeOfCrop'] as String? ?? '').trim();
final variety = (jsonData['variety'] as String? ?? '').trim();
final commodityName = '${typeOfCrop}_$variety';
final timestamp = DateTime.now().millisecondsSinceEpoch;

// Original: picture_1234567890.jpg
// NEW: crops_Carrot_14.5123_121.0234.jpg
final photoDestPath = '${farmerDir.path}/${commodityName}_$timestamp.jpg';

await _savePhotoWithLocation(_photoPath, photoDestPath);
```

**Photo Saving Method (Lines 871-920):**
```dart
Future<void> _savePhotoWithLocation(
    String sourcePhotoPath, String destPhotoPath) async {
  
  final photoFile = File(sourcePhotoPath);
  
  // Copy photo to new location
  await photoFile.copy(destPhotoPath);
  
  // Add GPS location to EXIF metadata
  if (_photoLatitude != null && _photoLongitude != null) {
    const platform = MethodChannel('com.example.da_monitoring_app/exif');
    await platform.invokeMethod('setExifGPS', {
      'imagePath': destPhotoPath,
      'latitude': _photoLatitude!,
      'longitude': _photoLongitude!,
      'accuracy': _photoAccuracy ?? 0.0,
    });
  }
}
```

**Result:**
```
/storage/.../crop/janeirohAgriculture/John_Fruto_Ambal/crops_Carrot_14.5123_121.0234.jpg ✓ Saved
```

---

## 🎯 Complete Step 07 Save Sequence

```
User clicks "Submit" on Step 07
        ↓
Check GPS is available
        ↓
Read all form data from Steps 02-07
        ↓
Create/Ensure farmer directory exists
        ↓
Merge commodity GPS data
        ↓
Write data.json with all steps
        ↓
Save photo file with GPS coordinates in:
  - Filename: crops_Carrot_14.5123_121.0234.jpg
  - EXIF metadata: latitude, longitude, accuracy
        ↓
Mark record as "unsync" (pending sync to Firebase)
        ↓
✅ Save Complete!
```

---

## 🚨 Important: Why GPS is Critical

1. **Captured BEFORE taking photo**
   ```dart
   _photoLatitude = await gps.getLatitude();  // Get location first
   _photoLongitude = await gps.getLongitude();
   openCamera();  // Then open camera
   ```

2. **Stored TWO places:**
   - In filename: `crops_Carrot_14.5123_121.0234.jpg`
   - In EXIF metadata: GPS tag in photo

3. **Used for tracking farm location**
   - Can map exactly where crop was planted
   - Useful for multi-location farms

---

## 📊 Save Flow Summary

| Step | Data | Location | Status |
|------|------|----------|--------|
| 01 | Project Background | group.json | Saved to disk |
| 02-06 | Commodity + all fields | Memory only | Not saved yet |
| 07 | Everything merged + photo | data.json + JPG | Saved to disk |

---

## ✅ Key Takeaway

```
Step 01 → Save to group.json (once)
         ↓
Steps 02-06 → Keep in memory
         ↓
Step 07 → FINAL SAVE: data.json + photo file
         ↓
Ready to view/edit/sync
```

---

**Next:** Read [3_VIEWING_FLOW.md](3_VIEWING_FLOW.md) to understand how this saved data is displayed

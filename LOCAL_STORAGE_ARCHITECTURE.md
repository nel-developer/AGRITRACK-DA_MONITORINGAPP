# Local Storage Architecture: Farmer Profiling Data

> **Core Pattern**: Group-based folder organization with farmer subfolders, JSON data files, and local image storage

## 📁 Complete Folder Structure

```
Documents/monitoring_records/
├── GroupName_A/
│   ├── JohnDoe_SAAD001/
│   │   ├── data.json
│   │   ├── picture.jpg
│   │   └── images/
│   │       ├── farm_01.jpg
│   │       ├── farm_02.jpg
│   │       └── crop_detail.jpg
│   ├── JaneSmith_SAAD002/
│   │   ├── data.json
│   │   ├── picture.jpg
│   │   └── images/
│   │       └── farm_field.jpg
│   └── MariaGarcia_SAAD003/
│       ├── data.json
│       └── picture.png
│
└── GroupName_B/
    ├── RobertoLee_SAAD004/
    │   ├── data.json
    │   ├── picture.jpg
    │   └── images/
    │       └── livestock_photo.jpg
    └── AnnaWilson_SAAD005/
        ├── data.json
        └── picture.jpg
```

### Why This Structure?

| Aspect | Benefit |
|--------|---------|
| **Group-first organization** | Easily access all farmers in a group; bulk operations efficient |
| **Farmer folder with ID** | Unique identity; multiple farmers with same name possible |
| **Timestamp in folder** (optional) | Prevent collisions; track data versions |
| **JSON + images together** | Self-contained farmer record; easy backup |
| **Local storage** | Works offline; no cloud sync delays; privacy-first |
| **Structured naming** | Sanitized names; no file system conflicts |

---

## 🏗️ Folder Creation & Naming

### 1. **Base Directory Setup**

```dart
Future<Directory> _getMonitoringDirectory() async {
  final appDocDir = await getApplicationDocumentsDirectory();
  final monitoringDir = Directory('${appDocDir.path}/monitoring_records');

  if (!await monitoringDir.exists()) {
    await monitoringDir.create(recursive: true);
  }

  return monitoringDir;
}
```

**Location**: `{app_documents}/monitoring_records/`  
**Created on**: First save attempt  
**Permissions**: Read/write by app only

---

### 2. **Group Folder Creation**

```dart
Future<Directory> _getGroupDirectory(String groupName) async {
  final baseDir = await _getMonitoringDirectory();
  
  // Sanitize folder name (remove invalid characters)
  final sanitizedGroupName =
      groupName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  
  final groupDir = Directory('${baseDir.path}/$sanitizedGroupName');

  if (!await groupDir.exists()) {
    await groupDir.create(recursive: true);
  }

  return groupDir;
}
```

**Naming**: `{groupName}` (sanitized)  
**Example**: `"Barangay_Santos_Farmers_Group"` → `Barangay_Santos_Farmers_Group/`  
**Sanitization**: Removes: `< > : " / \ | ? *`

---

### 3. **Farmer Folder Creation**

```dart
Future<Directory> _getFarmerDirectory(
  String groupName,
  String farmerName,
  String saadId,
) async {
  final groupDir = await _getGroupDirectory(groupName);
  
  final sanitizedFarmerName =
      farmerName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  final sanitizedSaadId = 
      saadId.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  
  // Format: {firstName}{lastName}_{SAADID}
  final folderName = '${sanitizedFarmerName}_$sanitizedSaadId';
  
  final farmerDir = Directory('${groupDir.path}/$folderName');

  if (!await farmerDir.exists()) {
    await farmerDir.create(recursive: true);
  }

  return farmerDir;
}
```

**Naming Pattern**: `{FarmerName}_{SAADID}`  
**Example**: `JohnDoe_SAAD001/`, `JaneSmith_SAAD002/`  
**Why SAADID?**: Unique identifier prevents duplicates when multiple farmers have the same name

---

### 4. **With Timestamp (Optional Enhancement)**

For versioning or collision prevention:

```dart
String _generateFarmerFolderName(
  String farmerName,
  String saadId,
  {bool includeTimestamp = false}
) {
  final sanitizedName = farmerName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  final sanitizedId = saadId.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  
  if (includeTimestamp) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${sanitizedName}_${sanitizedId}_$timestamp';
  }
  
  return '${sanitizedName}_$sanitizedId';
}

// Usage:
// "JohnDoe_SAAD001_1682684400000" (if versioning enabled)
// "JohnDoe_SAAD001" (standard)
```

---

## 📝 JSON Saving Flow

### Single Farmer Data Save

```dart
Future<String> saveFarmerData({
  required String groupName,
  required String farmerName,
  required String saadId,
  required Map<String, dynamic> data,
}) async {
  final farmerDir = await _getFarmerDirectory(groupName, farmerName, saadId);
  final dataFile = File('${farmerDir.path}/data.json');

  // Serialize with formatting for readability
  final jsonString = jsonEncode(data);
  await dataFile.writeAsString(jsonString);

  return dataFile.path;
}
```

### JSON Data Structure

```json
{
  "recordId": "auto-generated-uuid",
  "farmerName": "John Doe",
  "saadId": "SAAD001",
  "groupName": "Barangay Santos Farmers Group",
  "productionType": "crop",
  "implementationType": "individual",
  "createdAt": "2024-03-18T10:30:00Z",
  "updatedAt": "2024-03-18T10:30:00Z",
  "imagePaths": {
    "profilePicture": "picture.jpg",
    "farmPhotos": [
      "images/farm_01.jpg",
      "images/farm_02.jpg",
      "images/crop_detail.jpg"
    ]
  },
  "profiling": {
    "region": "Central Visayas",
    "province": "Cebu",
    "municipality": "Carcar",
    "barangay": "Santos",
    "farmArea": 2.5,
    "soilType": "loam",
    "waterSource": "well",
    "crops": [
      {
        "name": "Rice",
        "area": 1.5,
        "yieldPerSeason": 6000,
        "season": "wet"
      },
      {
        "name": "Corn",
        "area": 1.0,
        "yieldPerSeason": 4000,
        "season": "dry"
      }
    ],
    "trainingsAttended": [
      {
        "name": "Modern Rice Farming",
        "date": "2024-02-15",
        "venue": "Municipal Hall",
        "attendees": 45
      }
    ]
  }
}
```

### Updating Existing Data

```dart
Future<String> updateFarmerData({
  required String groupName,
  required String farmerName,
  required String saadId,
  required Map<String, dynamic> data,
}) async {
  final farmerDir = await _getFarmerDirectory(groupName, farmerName, saadId);
  final dataFile = File('${farmerDir.path}/data.json');

  // Read existing data
  Map<String, dynamic> existingData = {};
  if (await dataFile.exists()) {
    final content = await dataFile.readAsString();
    existingData = jsonDecode(content) as Map<String, dynamic>;
  }

  // Merge new data
  final mergedData = {...existingData, ...data, 'updatedAt': DateTime.now().toIso8601String()};

  await dataFile.writeAsString(jsonEncode(mergedData));

  return dataFile.path;
}
```

---

## 🖼️ Image Saving Flow

### Single Image Save (Profile Picture)

```dart
Future<String> saveFarmerPicture({
  required String groupName,
  required String farmerName,
  required String saadId,
  required List<int> pictureBytes,
  String imageExtension = 'jpg',
}) async {
  final farmerDir = await _getFarmerDirectory(groupName, farmerName, saadId);
  final pictureFile = File('${farmerDir.path}/picture.$imageExtension');

  // Write image bytes directly
  await pictureFile.writeAsBytes(pictureBytes);

  return pictureFile.path;
}
```

**Usage**:
```dart
// From file
final imageFile = File('/path/to/image.jpg');
final bytes = await imageFile.readAsBytes();
await storage.saveFarmerPicture(
  groupName: 'Barangay Santos',
  farmerName: 'John Doe',
  saadId: 'SAAD001',
  pictureBytes: bytes,
  imageExtension: 'jpg',
);

// From camera
final XFile? image = await ImagePicker().pickImage(source: ImageSource.camera);
if (image != null) {
  final bytes = await image.readAsBytes();
  await storage.saveFarmerPicture(
    groupName: groupName,
    farmerName: farmerName,
    saadId: saadId,
    pictureBytes: bytes,
    imageExtension: image.name.split('.').last, // Extract extension
  );
}
```

---

### Batch Image Save (Farm Photos)

```dart
Future<List<String>> saveBatchFarmImages({
  required String groupName,
  required String farmerName,
  required String saadId,
  required List<File> imageFiles,
}) async {
  final farmerDir = await _getFarmerDirectory(groupName, farmerName, saadId);
  final imagesDir = Directory('${farmerDir.path}/images');

  if (!await imagesDir.exists()) {
    await imagesDir.create(recursive: true);
  }

  final savedPaths = <String>[];

  for (int i = 0; i < imageFiles.length; i++) {
    final file = imageFiles[i];
    final extension = file.path.split('.').last;
    
    // Name: farm_01.jpg, farm_02.jpg, etc.
    final fileName = 'farm_${(i + 1).toString().padLeft(2, '0')}.$extension';
    final destFile = File('${imagesDir.path}/$fileName');

    await file.copy(destFile.path);
    savedPaths.add(destFile.path);
  }

  return savedPaths;
}
```

**Usage**:
```dart
final imageFiles = [
  File('/camera/image_1.jpg'),
  File('/camera/image_2.jpg'),
  File('/camera/image_3.jpg'),
];

final savedPaths = await storage.saveBatchFarmImages(
  groupName: groupName,
  farmerName: farmerName,
  saadId: saadId,
  imageFiles: imageFiles,
);

// savedPaths contains:
// [.../images/farm_01.jpg, .../images/farm_02.jpg, .../images/farm_03.jpg]
```

---

### Image Retrieval

```dart
Future<File?> getFarmerPicture({
  required String groupName,
  required String farmerName,
  required String saadId,
}) async {
  final farmerDir = await _getFarmerDirectory(groupName, farmerName, saadId);

  // Check common formats
  for (final extension in ['jpg', 'jpeg', 'png', 'gif']) {
    final pictureFile = File('${farmerDir.path}/picture.$extension');
    if (await pictureFile.exists()) {
      return pictureFile;
    }
  }
  return null;
}

Future<List<File>> getFarmImages({
  required String groupName,
  required String farmerName,
  required String saadId,
}) async {
  final farmerDir = await _getFarmerDirectory(groupName, farmerName, saadId);
  final imagesDir = Directory('${farmerDir.path}/images');

  if (!await imagesDir.exists()) {
    return [];
  }

  final imageFiles = <File>[];
  final files = imagesDir.listSync();

  for (final file in files) {
    if (file is File) {
      final extension = file.path.split('.').last.toLowerCase();
      if (['jpg', 'jpeg', 'png', 'gif'].contains(extension)) {
        imageFiles.add(file);
      }
    }
  }

  // Sort by name (farm_01, farm_02, etc.)
  imageFiles.sort((a, b) => a.path.compareTo(b.path));

  return imageFiles;
}
```

---

## 🔄 Complete Flow: User Form → Disk

### 1. **User Enters Profiling Data in Form**

```dart
class ProfileForm {
  final String groupName = 'Barangay Santos';
  final String farmerName = 'John Doe';
  final String saadId = 'SAAD001';
  
  final Map<String, dynamic> formData = {
    'region': 'Central Visayas',
    'province': 'Cebu',
    'farmArea': 2.5,
    'soilType': 'loam',
    'crops': ['Rice', 'Corn'],
    'trainings': [
      {'name': 'Modern Farming', 'date': '2024-02-15'}
    ],
  };

  final List<File> farmPhotos = []; // User-captured images
  final File profilePicture = File('...'); // User's profile photo
}
```

---

### 2. **Capture Images**

```dart
Future<void> _captureProfilePicture() async {
  final picker = ImagePicker();
  final XFile? image = await picker.pickImage(source: ImageSource.camera);
  
  if (image != null) {
    setState(() {
      profilePicture = File(image.path);
    });
  }
}

Future<void> _captureFarmPhotos() async {
  final picker = ImagePicker();
  final List<XFile>? images = await picker.pickMultiImage();
  
  if (images != null) {
    setState(() {
      farmPhotos = images.map((img) => File(img.path)).toList();
    });
  }
}
```

---

### 3. **Save to Local Storage (Complete Flow)**

```dart
Future<void> _saveProfiling() async {
  try {
    showDialog(context: context, builder: (_) => LoadingDialog());

    final storage = LocalFarmerStorageService.instance;

    // Step 1: Prepare JSON data
    final jsonData = {
      'recordId': const Uuid().v4(),
      'farmerName': farmerName,
      'saadId': saadId,
      'groupName': groupName,
      'productionType': 'crop',
      'implementationType': 'individual',
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
      'imagePaths': {
        'profilePicture': 'picture.jpg',
        'farmPhotos': [], // Will be filled below
      },
      'profiling': formData, // All form fields
    };

    // Step 2: Save JSON data
    final dataPath = await storage.saveFarmerData(
      groupName: groupName,
      farmerName: farmerName,
      saadId: saadId,
      data: jsonData,
    );
    print('✓ Data saved: $dataPath');

    // Step 3: Save profile picture
    if (profilePicture != null && await profilePicture.exists()) {
      final picturePath = await storage.saveFarmerPicture(
        groupName: groupName,
        farmerName: farmerName,
        saadId: saadId,
        pictureBytes: await profilePicture.readAsBytes(),
        imageExtension: 'jpg',
      );
      print('✓ Profile picture saved: $picturePath');
    }

    // Step 4: Save batch farm photos
    if (farmPhotos.isNotEmpty) {
      final imagePaths = await storage.saveBatchFarmImages(
        groupName: groupName,
        farmerName: farmerName,
        saadId: saadId,
        imageFiles: farmPhotos,
      );
      print('✓ ${imagePaths.length} farm photos saved');

      // Step 5: Update JSON with image paths
      final updatedData = jsonData;
      updatedData['imagePaths']['farmPhotos'] = 
          imagePaths.map((p) => p.split('/').last).toList();
      
      await storage.saveFarmerData(
        groupName: groupName,
        farmerName: farmerName,
        saadId: saadId,
        data: updatedData,
      );
    }

    Navigator.pop(context); // Close loading
    _showSuccessDialog('Profile saved successfully!');
    
  } catch (e) {
    Navigator.pop(context);
    _showErrorDialog('Failed to save: $e');
  }
}
```

**Result on Disk**:
```
Documents/monitoring_records/
└── Barangay_Santos/
    └── JohnDoe_SAAD001/
        ├── data.json (contains all form data + image paths)
        ├── picture.jpg (profile photo)
        └── images/
            ├── farm_01.jpg
            ├── farm_02.jpg
            └── farm_03.jpg
```

---

## 📂 Loading: Restoring Data + Images from Disk

### Load Single Farmer Profile

```dart
Future<void> _loadFarmerProfile() async {
  try {
    final storage = LocalFarmerStorageService.instance;

    // Step 1: Load JSON data
    final jsonData = await storage.getFarmerData(
      groupName: groupName,
      farmerName: farmerName,
      saadId: saadId,
    );

    if (jsonData == null) {
      print('No data found');
      return;
    }

    // Step 2: Load profile picture
    final profilePic = await storage.getFarmerPicture(
      groupName: groupName,
      farmerName: farmerName,
      saadId: saadId,
    );

    // Step 3: Load farm photos
    final farmPhotos = await storage.getFarmImages(
      groupName: groupName,
      farmerName: farmerName,
      saadId: saadId,
    );

    // Step 4: Populate UI
    setState(() {
      formData = jsonData['profiling'] ?? {};
      profilePicture = profilePic;
      this.farmPhotos = farmPhotos;
    });

  } catch (e) {
    print('Error loading profile: $e');
  }
}
```

---

### Load All Farmers in Group

```dart
Future<void> _loadAllFarmersInGroup() async {
  try {
    final storage = LocalFarmerStorageService.instance;

    final farmers = await storage.getAllFarmersInGroup(groupName);

    // farmers contains:
    // [
    //   { 'name': 'JohnDoe', 'saadId': 'SAAD001', 'data': {...} },
    //   { 'name': 'JaneSmith', 'saadId': 'SAAD002', 'data': {...} },
    // ]

    setState(() {
      farmerList = farmers;
    });

  } catch (e) {
    print('Error loading farmers: $e');
  }
}
```

---

### Load with Error Handling

```dart
Future<Map<String, dynamic>?> _loadFarmerDataWithFallback() async {
  try {
    final storage = LocalFarmerStorageService.instance;
    
    final data = await storage.getFarmerData(
      groupName: groupName,
      farmerName: farmerName,
      saadId: saadId,
    );

    if (data == null) {
      print('⚠️ No saved data found');
      return null;
    }

    // Validate data integrity
    if (data['imagePaths'] == null) {
      print('⚠️ Data missing imagePaths, trying to reconstruct...');
      final farmPhotos = await storage.getFarmImages(
        groupName: groupName,
        farmerName: farmerName,
        saadId: saadId,
      );
      data['imagePaths'] = {
        'farmPhotos': farmPhotos.map((f) => f.path.split('/').last).toList(),
      };
    }

    return data;

  } catch (e) {
    print('❌ Error loading data: $e');
    return null;
  }
}
```

---

## 🎨 Design Patterns: Why This Organization?

### **Pattern 1: Hierarchical Grouping**

```
Group (organizational unit)
  ↓
Farmer (individual within group)
  ↓
Records (JSON + images for farmer)
```

**Benefits**:
- Query all farmers in a group quickly
- Organize by administrative boundaries (Barangay, Municipality)
- Enable group-level analytics
- Support bulk operations (export, backup, sync)

---

### **Pattern 2: Self-Contained Farmer Records**

```
FarmerFolder/
├── data.json (metadata + image paths)
├── picture.jpg (profile)
└── images/ (farm photos)
```

**Benefits**:
- Single folder = complete farmer record
- Easy to backup/archive
- Can be synced to cloud as atomic unit
- No broken references (images always with data)

---

### **Pattern 3: Unique Identifier Strategy**

```
Folder: {SanitizedName}_{SAADID}
```

**Why not just name?**
- Multiple farmers can have "John Doe"
- SAAD ID is unique system identifier
- Prevents folder collisions

**Why sanitize?**
- File systems don't allow: `< > : " / \ | ? *`
- Cross-platform compatibility
- Prevents special character issues

---

### **Pattern 4: Image Organization**

```
Profile Picture:  picture.jpg (singular, for UI display)
Farm Photos:      images/farm_01.jpg, farm_02.jpg, etc. (batch)
```

**Reasoning**:
- Separate profile from content photos
- Numbered naming enables sorting
- `images/` subfolder keeps root clean
- JSON metadata maps logical to physical paths

---

### **Pattern 5: JSON as Single Source of Truth**

```json
{
  "imagePaths": {
    "profilePicture": "picture.jpg",
    "farmPhotos": ["farm_01.jpg", "farm_02.jpg"]
  },
  "profiling": { ...all form data... },
  "metadata": { ...timestamps, versions... }
}
```

**Pattern**: Files on disk referenced in JSON
- **Pro**: Audit trail of what data was captured
- **Pro**: Can validate image files exist before display
- **Pro**: Supports syncing (transfer files + metadata)
- **Pro**: Easy to reconstruct after file loss

---

### **Pattern 6: Offline-First Architecture**

```
All data saved locally immediately
  ↓
Optional: Sync to Firestore when connected
  ↓
Images stay local (not synced)
  ↓
Can work completely offline
```

**Trade-offs**:
- ✅ Works without connectivity
- ✅ Fast (no network delays)
- ✅ Privacy (sensitive farming data stays local)
- ❌ Requires sync strategy
- ❌ Disk space for large image collections

---

## ✅ Implementation Checklist

### **Project Setup**

- [ ] Add `path_provider` to `pubspec.yaml`
- [ ] Add `image_picker` for camera/gallery
- [ ] Add `uuid` for unique IDs
- [ ] Create `LocalFarmerStorageService` singleton
- [ ] Test on Android (Documents directory path)
- [ ] Test on iOS (Documents directory path)

---

### **Core Functions**

- [ ] `_getMonitoringDirectory()` — base folder setup
- [ ] `_getGroupDirectory(groupName)` — group folder creation
- [ ] `_getFarmerDirectory(groupName, farmerName, saadId)` — farmer subfolder
- [ ] `saveFarmerData()` — JSON persistence
- [ ] `saveFarmerPicture()` — single image save
- [ ] `saveBatchFarmImages()` — multiple images
- [ ] `getFarmerData()` — load JSON
- [ ] `getFarmerPicture()` — load profile photo
- [ ] `getFarmImages()` — load batch photos
- [ ] `getAllFarmersInGroup()` — list all in group

---

### **Form Integration**

- [ ] Create farmer data form (group, name, SAAD ID)
- [ ] Add form fields for profiling data
- [ ] Integrate image picker (profile + farm photos)
- [ ] Build save flow with loading indicator
- [ ] Add success/error dialogs
- [ ] Test with sample data

---

### **Data Display**

- [ ] Load and display farmer profile
- [ ] Show profile picture from `picture.jpg`
- [ ] Display farm photos from `images/`
- [ ] Load form data from `data.json`
- [ ] Handle missing files gracefully

---

### **Batch Operations**

- [ ] Load all farmers in group
- [ ] Display farmer list with thumbnails
- [ ] Implement edit functionality (update JSON + images)
- [ ] Delete farmer (remove entire folder)

---

### **Error Handling**

- [ ] Handle missing directories
- [ ] Handle corrupted JSON
- [ ] Handle missing image files
- [ ] Validate file permissions
- [ ] Add try-catch to all file operations
- [ ] Provide user-friendly error messages

---

### **Testing**

- [ ] Create test farmer records
- [ ] Verify folder structure
- [ ] Check JSON formatting
- [ ] Validate image bytes
- [ ] Test load/save cycle
- [ ] Test with special characters in names
- [ ] Test batch image operations
- [ ] Test on different device storage locations

---

### **Optimization**

- [ ] Cache loaded images in memory
- [ ] Implement image compression before save
- [ ] Add pagination for large farmer lists
- [ ] Consider database for metadata (vs. filesystem scan)
- [ ] Add progress indicators for batch operations

---

### **Sync Strategy (Future)**

- [ ] Design upload strategy (JSON only? + images?)
- [ ] Create sync service to Firestore
- [ ] Handle conflicts (device vs. cloud)
- [ ] Implement selective sync
- [ ] Add sync status indicator

---

## 🔐 Best Practices

| Practice | Implementation |
|----------|-----------------|
| **Sanitize paths** | Remove invalid characters before creating folders |
| **Use absolute paths** | Use `getApplicationDocumentsDirectory()` not hardcoded |
| **Validate before save** | Check data not null, images readable |
| **Handle permissions** | Wrap in try-catch for storage access |
| **Organize hierarchically** | Group → Farmer → Data (not flat) |
| **Keep images local** | Don't sync to Firestore, only reference paths |
| **Use JSON for metadata** | Single source of truth |
| **Version data** | Include timestamps in JSON |
| **Test thoroughly** | Different devices, special characters, missing files |

---

## 📊 Data Flow Diagram

```
┌─────────────────────────┐
│   User Form Input       │
│ - Farmer details        │
│ - Profiling data        │
│ - Camera images         │
└──────────┬──────────────┘
           │
           ↓
┌─────────────────────────┐
│  Image Processing       │
│ - Validate bytes        │
│ - Extract extension     │
│ - Create file objects   │
└──────────┬──────────────┘
           │
           ↓
┌─────────────────────────┐
│  Prepare JSON Data      │
│ - Add metadata          │
│ - Add image paths       │
│ - Add timestamps        │
└──────────┬──────────────┘
           │
      ┌────┴──────────────────────┐
      │                           │
      ↓                           ↓
┌──────────────┐          ┌──────────────────┐
│ Create       │          │ Create farmer    │
│ Group Folder │          │ subfolder        │
└──────┬───────┘          └────────┬─────────┘
       │                           │
       └───────────┬───────────────┘
                   │
      ┌────────────┼────────────┐
      │            │            │
      ↓            ↓            ↓
┌──────────┐ ┌──────────┐ ┌──────────────┐
│ Save     │ │ Save     │ │ Save batch   │
│ JSON     │ │ Profile  │ │ farm photos  │
│          │ │ Picture  │ │              │
└──────────┘ └──────────┘ └──────────────┘
      │            │            │
      └────────────┼────────────┘
                   │
                   ↓
         ┌──────────────────┐
         │ Local Storage    │
         │ (Disk complete)  │
         └──────────────────┘
```

---

## 🚀 Quick Start Example

```dart
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'services/local_farmer_storage_service.dart';

void main() async {
  final storage = LocalFarmerStorageService.instance;
  const uuid = Uuid();

  // Sample data
  final groupName = 'Barangay Santos';
  final farmerName = 'John Doe';
  final saadId = 'SAAD001';

  final farmerData = {
    'recordId': uuid.v4(),
    'farmArea': 2.5,
    'soilType': 'loam',
    'crops': ['Rice', 'Corn'],
    'createdAt': DateTime.now().toIso8601String(),
  };

  // Save data
  await storage.saveFarmerData(
    groupName: groupName,
    farmerName: farmerName,
    saadId: saadId,
    data: farmerData,
  );

  // Load data
  final loaded = await storage.getFarmerData(
    groupName: groupName,
    farmerName: farmerName,
    saadId: saadId,
  );

  print('Loaded: $loaded');
}
```

---

## 📞 Summary

| Component | Purpose | Location |
|-----------|---------|----------|
| **Base Directory** | Root for all monitoring records | `{Documents}/monitoring_records/` |
| **Group Folder** | Organize farmers by group/barangay | `{Base}/{GroupName}/` |
| **Farmer Folder** | Individual farmer record container | `{Group}/{Name}_{SAADID}/` |
| **data.json** | Profiling data + metadata | `{Farmer}/data.json` |
| **picture.jpg** | Profile photo | `{Farmer}/picture.jpg` |
| **images/** | Farm photos | `{Farmer}/images/farm_XX.jpg` |

This architecture enables:
- ✅ Offline-first operation
- ✅ Local privacy (no cloud images)
- ✅ Hierarchical organization
- ✅ Easy backup/restore
- ✅ Scalable to thousands of farmers

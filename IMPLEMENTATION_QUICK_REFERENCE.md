# Local Storage Implementation - Quick Reference

## 🎯 One-Page Reference

### Folder Structure Pattern

```
Documents/monitoring_records/
└── {GroupName}/
    └── {FarmerName}_{SAADID}/
        ├── data.json              ← All form data + image paths
        ├── picture.jpg            ← Profile photo
        └── images/                ← Farm photos
            ├── farm_01.jpg
            ├── farm_02.jpg
            └── farm_03.jpg
```

---

### Key Implementation Points

| Task | Method | Returns |
|------|--------|---------|
| Get/create group folder | `_getGroupDirectory(groupName)` | `Directory` |
| Get/create farmer folder | `_getFarmerDirectory(groupName, farmerName, saadId)` | `Directory` |
| Save JSON data | `saveFarmerData({...})` | File path |
| Save one image | `saveFarmerPicture({...})` | File path |
| Save multiple images | `saveBatchFarmImages({...})` | List of paths |
| Load JSON data | `getFarmerData({...})` | `Map<String, dynamic>?` |
| Load profile photo | `getFarmerPicture({...})` | `File?` |
| Load farm photos | `getFarmImages({...})` | `List<File>` |
| Get all farmers in group | `getAllFarmersInGroup(groupName)` | `List<Map>` |

---

### Naming Convention

| Item | Pattern | Example |
|------|---------|---------|
| Group folder | `{GroupName}` (sanitized) | `Barangay_Santos_Farmers_Group` |
| Farmer folder | `{Name}_{SAADID}` | `JohnDoe_SAAD001` |
| Profile image | `picture.{ext}` | `picture.jpg` |
| Farm photos | `farm_XX.{ext}` | `farm_01.jpg`, `farm_02.jpg` |
| Data file | `data.json` | `data.json` |

**Sanitization**: Remove `< > : " / \ | ? *`

---

### Complete Save Flow (5 Steps)

```dart
Future<void> _saveFarmerProfile() async {
  final storage = LocalFarmerStorageService.instance;

  // 1. Prepare JSON
  final jsonData = {
    'recordId': const Uuid().v4(),
    'farmerName': farmerName,
    'saadId': saadId,
    'groupName': groupName,
    'createdAt': DateTime.now().toIso8601String(),
    'imagePaths': {
      'profilePicture': 'picture.jpg',
      'farmPhotos': [],
    },
    'profiling': formData,
  };

  // 2. Save JSON
  await storage.saveFarmerData(
    groupName: groupName,
    farmerName: farmerName,
    saadId: saadId,
    data: jsonData,
  );

  // 3. Save profile picture
  if (profilePicture != null) {
    await storage.saveFarmerPicture(
      groupName: groupName,
      farmerName: farmerName,
      saadId: saadId,
      pictureBytes: await profilePicture.readAsBytes(),
      imageExtension: 'jpg',
    );
  }

  // 4. Save farm photos (batch)
  if (farmPhotos.isNotEmpty) {
    final paths = await storage.saveBatchFarmImages(
      groupName: groupName,
      farmerName: farmerName,
      saadId: saadId,
      imageFiles: farmPhotos,
    );

    // 5. Update JSON with actual image paths
    jsonData['imagePaths']['farmPhotos'] = 
        paths.map((p) => p.split('/').last).toList();
    
    await storage.saveFarmerData(
      groupName: groupName,
      farmerName: farmerName,
      saadId: saadId,
      data: jsonData,
    );
  }
}
```

---

### Complete Load Flow (4 Steps)

```dart
Future<void> _loadFarmerProfile() async {
  final storage = LocalFarmerStorageService.instance;

  // 1. Load JSON
  final jsonData = await storage.getFarmerData(
    groupName: groupName,
    farmerName: farmerName,
    saadId: saadId,
  );

  // 2. Load profile picture
  final profilePic = await storage.getFarmerPicture(
    groupName: groupName,
    farmerName: farmerName,
    saadId: saadId,
  );

  // 3. Load farm photos
  final farmPhotos = await storage.getFarmImages(
    groupName: groupName,
    farmerName: farmerName,
    saadId: saadId,
  );

  // 4. Update UI
  setState(() {
    formData = jsonData?['profiling'] ?? {};
    profilePicture = profilePic;
    this.farmPhotos = farmPhotos;
  });
}
```

---

### JSON Data Structure

```json
{
  "recordId": "uuid-here",
  "farmerName": "John Doe",
  "saadId": "SAAD001",
  "groupName": "Barangay Santos",
  "productionType": "crop",
  "implementationType": "individual",
  "createdAt": "2024-03-18T10:30:00Z",
  "updatedAt": "2024-03-18T10:30:00Z",
  "imagePaths": {
    "profilePicture": "picture.jpg",
    "farmPhotos": ["farm_01.jpg", "farm_02.jpg", "farm_03.jpg"]
  },
  "profiling": {
    "region": "Central Visayas",
    "province": "Cebu",
    "farmArea": 2.5,
    "soilType": "loam",
    "crops": ["Rice", "Corn"],
    "trainings": [
      {"name": "Modern Farming", "date": "2024-02-15"}
    ]
  }
}
```

---

### Why This Structure?

| Feature | Benefit |
|---------|---------|
| **Group → Farmer hierarchy** | Organize by administrative boundaries, easy group queries |
| **Farmer ID (SAAD)** | Handles multiple farmers with same name |
| **JSON + images together** | Self-contained record, easy to backup/sync |
| **Image paths in JSON** | Single source of truth, can validate file existence |
| **Local storage only** | Privacy-first, offline-capable, no cloud dependencies |
| **Numbered images** | Batch operations, sorting, reconstruction |

---

### Implementation Checklist

**Core**
- [ ] `LocalFarmerStorageService` created
- [ ] Directory creation methods implemented
- [ ] JSON serialization/deserialization working

**Images**
- [ ] Single image save (profile picture)
- [ ] Batch image save (farm photos)
- [ ] Image retrieval with extension search
- [ ] Batch retrieval with sorting

**Forms**
- [ ] Form captures group name
- [ ] Form captures farmer name
- [ ] Form captures SAAD ID
- [ ] Form captures profiling data
- [ ] Form enables multi-photo capture

**Save Flow**
- [ ] Loading indicator shown
- [ ] JSON saved first
- [ ] Profile picture saved
- [ ] Farm photos saved
- [ ] JSON updated with image paths
- [ ] Success feedback provided

**Load Flow**
- [ ] JSON loaded on open
- [ ] Images loaded from disk
- [ ] UI populated with data
- [ ] Error handling for missing files

---

### For Your Other Project

Copy this template to adapt:

1. **Replace these values**:
   - `groupName` → Your grouping unit (Barangay, Company, etc.)
   - `farmerName` → Your entity name (Person, Item, etc.)
   - `saadId` → Your unique ID field
   - `profiling` → Your domain data

2. **Create service following pattern**:
   ```dart
   class LocalEntityStorageService {
     // Get/create group folder
     Future<Directory> _getGroupDirectory(String groupName)
     
     // Get/create entity subfolder
     Future<Directory> _getEntityDirectory(
       String groupName,
       String entityName,
       String entityId,
     )
     
     // Save JSON data
     Future<String> saveEntityData({...})
     
     // Save images
     Future<String> saveEntityImage({...})
     Future<List<String>> saveEntityImages({...})
     
     // Load data
     Future<Map?> getEntityData({...})
     Future<File?> getEntityImage({...})
     Future<List<File>> getEntityImages({...})
   }
   ```

3. **Integrate into forms** following the 5-step save flow

4. **Load on screens** following the 4-step load flow

---

### Common Mistakes to Avoid

❌ **Don't**: Save images without saving image paths in JSON
✅ **Do**: Update JSON with relative image paths after saving

❌ **Don't**: Use hardcoded paths
✅ **Do**: Use `getApplicationDocumentsDirectory()` + build from there

❌ **Don't**: Save without error handling
✅ **Do**: Wrap in try-catch, show loading indicator, provide feedback

❌ **Don't**: Name folders without sanitizing
✅ **Do**: Remove invalid filesystem characters: `< > : " / \ | ? *`

❌ **Don't**: Store image bytes in JSON
✅ **Do**: Store relative file paths in JSON, images stay as files

❌ **Don't**: Ignore file permissions
✅ **Do**: Test on real devices, handle permission errors

---

### Testing Checklist

```dart
// Test folder creation
final dir = await storage._getGroupDirectory('Test Group');
assert(await dir.exists());

// Test JSON save/load
await storage.saveFarmerData(
  groupName: 'Test Group',
  farmerName: 'Test Farmer',
  saadId: 'TEST001',
  data: {'test': 'data'},
);
final loaded = await storage.getFarmerData(
  groupName: 'Test Group',
  farmerName: 'Test Farmer',
  saadId: 'TEST001',
);
assert(loaded?['test'] == 'data');

// Test image save/load
final imageBytes = await File('test.jpg').readAsBytes();
await storage.saveFarmerPicture(
  groupName: 'Test Group',
  farmerName: 'Test Farmer',
  saadId: 'TEST001',
  pictureBytes: imageBytes,
);
final retrieved = await storage.getFarmerPicture(
  groupName: 'Test Group',
  farmerName: 'Test Farmer',
  saadId: 'TEST001',
);
assert(retrieved != null);
```

---

### Dependencies Required

```yaml
dependencies:
  flutter:
    sdk: flutter
  path_provider: ^2.0.0
  image_picker: ^0.8.0
  uuid: ^3.0.0
```

---


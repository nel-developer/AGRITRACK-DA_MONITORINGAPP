# 8️⃣ COLLECTIVE IMPLEMENTATION - Complete Local & Firebase Flow

## 🏢 What is Collective Implementation?

**Collective** = One FCA group with NO individual farmers. All commodities belong to the group as a whole.

**Example:**
```
FCA: janeirohAgriculture
├── Type: COLLECTIVE
├── Commodity 1: Coconut (50 ha group plantation)
├── Commodity 2: Rice (30 ha group plantation)
└── All tracked at GROUP LEVEL (not per individual farmer)
```

---

## 💾 LOCAL STORAGE - Collective Saving Flow

### File Structure
```
/storage/.../crop/janeirohAgriculture/         (Group folder)
├── group.json                                  (Project Background)
│   └── Contains: fcaName, region, members=[], 
│                 implementationType='collective'
│
└── data.json                                   (Commodities & Trainings)
    └── Contains: completedCommodities[], trainings[], 
                  farmerName is GROUP NAME
```

### STEP 1: Project Background (group.json)

**File:** `step_01_project_background.dart`

**What Happens:**
1. User enters FCA name, region, province, municipality, barangay
2. Selects implementation type = **"COLLECTIVE"**
3. Clicks "Next"
4. Data saved to **group.json**

**Saved Data:**
```json
{
  "implementationType": "collective",
  "fcaName": "janeirohAgriculture",
  "reportingPeriod": "2026",
  "region": "Region IV-A (CALABARZON)",
  "province": "Batangas",
  "municipality": "Lipa City",
  "barangay": "Barangay 2",
  "projectTitle": "agriculture",
  "primaryIntervention": "Coconut",
  "supportInterventions": ["Fertilizers"],
  "members": [],                          ← EMPTY for collective
  "createdAt": "2026-05-13T15:15:18.871670"
}
```

**Save Location:**
```
/storage/.../crop/janeirohAgriculture/group.json
```

---

### STEP 2-7: Commodities & Trainings (data.json)

**File:** `step_02_commodity_information.dart` through `step_07_trainings.dart`

**Key Difference for Collective:**
- NO farmer folder created
- Data saved directly in group folder as `data.json`
- `farmerName` = FCA name (not individual farmer name)
- `completedCommodities` = array of group commodities

#### Adding Commodities (Collective)

**Process:**
```
Step 02: Commodity Information
┌──────────────────────────────┐
│ Type of Crop: Coconut        │
│ Variety: Tall                │
│ Farmgate Price: 100          │
│ Qty vs Area: 2000 nuts/ha    │
│ Cropping Cycles: 2           │
│ Peak Volume: 5000            │
│ [Add Another] [Next]         │
└──────────────────────────────┘
```

**User clicks "Add Another Commodity":**
```dart
// Current commodity stored in memory
commoditiesList.add({
  'typeOfCrop': 'Coconut',
  'variety': 'Tall',
  'farmgatePrice': '100',
  'qtyVsArea': '2000 nuts/ha',
  'croppingCycles': '2',
  'peakVolume': '5000'
});

// Form clears for second commodity
```

**User fills Commodity 2:**
```
Step 02: Commodity Information (Commodity 2)
┌──────────────────────────────┐
│ Type of Crop: Calamansi      │
│ Variety: Regular             │
│ Farmgate Price: 50           │
│ Qty vs Area: 500 kg/ha       │
│ Cropping Cycles: 4           │
│ Peak Volume: 800             │
│ [Add Another] [Next]         │
└──────────────────────────────┘
```

**User clicks "Next" after all commodities done:**
```
commoditiesList = [
  {
    'typeOfCrop': 'Coconut',
    'variety': 'Tall',
    'farmgatePrice': '100',
    'qtyVsArea': '2000 nuts/ha',
    'croppingCycles': '2',
    'peakVolume': '5000'
  },
  {
    'typeOfCrop': 'Calamansi',
    'variety': 'Regular',
    'farmgatePrice': '50',
    'qtyVsArea': '500 kg/ha',
    'croppingCycles': '4',
    'peakVolume': '800'
  }
]
```

#### Steps 03-06: Fill Commodity Details

All data collected in memory:
- Step 03: Planting Stage (land area, source of water, etc)
- Step 04: Fertilization (organic/inorganic bags, costs)
- Step 05: Harvesting (dates, quantities, costs)
- Step 06: Crop Damage (pests, diseases, environmental)

#### Step 07: FINAL SAVE (Trainings)

**File:** `step_07_trainings.dart` - Lines 722-732

**This is where EVERYTHING gets saved to disk:**

```dart
// Merge all steps into complete JSON
final Map<String, dynamic> jsonData = {
  'fcaName': 'janeirohAgriculture',
  'farmerName': 'janeirohAgriculture',  ← GROUP NAME (not individual)
  'reportingPeriod': '2026',
  'implementationType': 'collective',
  
  // All commodities (both)
  'completedCommodities': [
    {
      'typeOfCrop': 'Coconut',
      'variety': 'Tall',
      'farmgatePrice': '100',
      'totalLandArea': '50 hectares',
      'plantingDate': '2025-01-15',
      // ... all steps 03-06 data for Coconut
    },
    {
      'typeOfCrop': 'Calamansi',
      'variety': 'Regular',
      'farmgatePrice': '50',
      'totalLandArea': '10 hectares',
      'plantingDate': '2025-03-10',
      // ... all steps 03-06 data for Calamansi
    }
  ],
  
  // All trainings
  'trainings': [
    {
      'name': 'Climate-Smart Agriculture',
      'date': '2026-05-10',
      'attendees': '25'
    }
  ]
};

// Save to group folder
File('/storage/.../crop/janeirohAgriculture/data.json')
  .writeAsString(jsonEncode(jsonData));
```

**Result:**
```
/storage/.../crop/janeirohAgriculture/data.json ✓ SAVED
```

---

## 🔥 FIREBASE SYNC - Collective Upload Flow

**File:** `monitoring_record_service.dart`

### When & How Upload Happens

1. **User completes all 7 steps** → Local data saved
2. **User clicks "Submit to Firebase"** or goes to HomeScreen
3. **App automatically detects local records**
4. **Records uploaded to Firestore** with status = 'pending'

### Firebase Collection Structure

```
pending_monitoring/
├── janeirohAgriculture/              ← Group ID (documentId)
│   ├── implementationType: "collective"
│   ├── fcaName: "janeirohAgriculture"
│   ├── region: "Region IV-A"
│   ├── reportingPeriod: "2026"
│   │
│   ├── completedCommodities (ARRAY)
│   │   ├── [0] {
│   │   │   typeOfCrop: "Coconut",
│   │   │   variety: "Tall",
│   │   │   farmgatePrice: "100",
│   │   │   ... all commodity fields
│   │   │ }
│   │   └── [1] {
│   │       typeOfCrop: "Calamansi",
│   │       ... commodity fields
│   │     }
│   │
│   ├── trainings (ARRAY)
│   │   └── [0] { name, date, attendees }
│   │
│   ├── status: "pending"
│   ├── createdAt: timestamp
│   ├── updatedAt: timestamp
│   │
│   └── commodities/ (SUBCOLLECTION)
│       ├── coconut_tall_001/ → Full commodity document
│       └── calamansi_regular_001/ → Full commodity document
```

### Upload Code Flow

```dart
// In monitoring_record_service.dart

Future<void> syncPendingLocalRecords() async {
  final allLocalRecords = await getAllLocalRecords();
  
  for (final record in allLocalRecords) {
    if (record.isLocal && record.status == 'unsync') {
      
      // COLLECTIVE specific upload
      if (record.implType.toLowerCase() == 'collective') {
        
        // Create group document in pending_monitoring
        final groupDocId = record.data['fcaName']; // janeirohAgriculture
        
        final groupData = {
          'implementationType': 'collective',
          'fcaName': record.data['fcaName'],
          'reportingPeriod': record.data['reportingPeriod'],
          'region': record.data['region'],
          'province': record.data['province'],
          'municipality': record.data['municipality'],
          'barangay': record.data['barangay'],
          'projectTitle': record.data['projectTitle'],
          'primaryIntervention': record.data['primaryIntervention'],
          'supportInterventions': record.data['supportInterventions'],
          'trainings': record.data['trainings'] ?? [],
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };
        
        // Save group document
        await firestore
            .collection('pending_monitoring')
            .doc(groupDocId)
            .set(groupData);
        
        // Upload each commodity to subcollection
        final commodities = record.data['completedCommodities'] as List? ?? [];
        for (final commodity in commodities) {
          final commodityId = '${commodity['typeOfCrop']}_${commodity['variety']}'.toLowerCase();
          
          await firestore
              .collection('pending_monitoring')
              .doc(groupDocId)
              .collection('commodities')
              .doc(commodityId)
              .set({
                ...commodity,
                'createdAt': FieldValue.serverTimestamp(),
              });
        }
      }
    }
  }
}
```

---

## ✏️ EDITING COLLECTIVE ON FIREBASE

**File:** `record_edit_modal.dart` - `saveChanges()` method

### When Editing a Collective Record

1. User opens a "pending" collective record from HomeScreen
2. Clicks "Edit" → RecordEditModal opens
3. User changes commodity fields or trainings
4. Clicks "Save"

### What Gets Saved

```dart
// In record_edit_modal.dart - saveChanges() method

if (implementationType == 'collective') {
  
  // 1. Update group-level fields
  final groupDocRef = firestore.doc(widget.record.documentPath);
  // documentPath = 'pending_monitoring/janeirohAgriculture'
  
  final groupUpdates = {
    'trainings': updates['trainings'] ?? [],
    'updatedAt': FieldValue.serverTimestamp(),
  };
  
  // Add any group fields that changed (region, province, etc)
  if (updates.containsKey('region')) {
    groupUpdates['region'] = updates['region'];
  }
  
  await groupDocRef.update(groupUpdates);
  
  // 2. Update each commodity in subcollection
  for (var i = 0; i < _originalCommodityItems.length; i++) {
    final commodityData = _originalCommodityItems[i];
    final commodityId = (commodityData['id'] ?? 
                        commodityData['commodityId'] ?? '').toString();
    
    if (commodityId.isNotEmpty) {
      final updatedCommodity = {};
      
      // Copy all changed fields
      for (final field in _commodityFieldKeys) {
        final controller = _itemControllers['crop_${i}_$field'];
        if (controller != null) {
          updatedCommodity[field] = controller.text.trim();
        }
      }
      
      updatedCommodity['updatedAt'] = FieldValue.serverTimestamp();
      
      // Save to subcollection
      await groupDocRef
          .collection('commodities')
          .doc(commodityId)
          .update(updatedCommodity);
    }
  }
}
```

### Result

✅ Changes persisted to Firebase
✅ Collective record updated with new commodity data
✅ Trainings updated if changed

---

## 📊 Key Differences: Collective vs Individual/Hybrid

| Aspect | Collective | Individual/Hybrid |
|--------|-----------|------------------|
| **Local Folder** | `/group_name/` | `/group_name/farmer1/`, `/group_name/farmer2/` |
| **data.json** | 1 file per group | 1 file per farmer |
| **Commodities** | Group-level array | Individual farmer arrays |
| **Firebase Path** | `pending_monitoring/{groupId}` | `pending_monitoring/{groupId}/members/{saadId}` |
| **Firebase Subcollection** | `commodities/` | `members/{saadId}/commodities/` |
| **Members Array** | Empty [] | List of farmers |


# 9️⃣ INDIVIDUAL & HYBRID IMPLEMENTATION - Complete Local & Firebase Flow

## 👥 What are Individual & Hybrid Implementation Types?

**Individual** = One FCA group with MULTIPLE individual farmers. Each farmer tracks their own commodities.
**Hybrid** = Mix of individual farmers and collective group commodities.

**Example:**
```
FCA: janeirohAgriculture
├── Implementation: Individual
├── Members:
│   ├── Farmer 1: John Fruto Ambal (SAAD ID: 1)
│   │   ├── Commodity: Vegetables
│   │   └── Commodity: Coconut
│   │
│   └── Farmer 2: Maribel Oflaria (SAAD ID: 1000p)
│       ├── Commodity: Rice
│       └── Commodity: Livestock
│
└── Each farmer tracked SEPARATELY
```

---

## 💾 LOCAL STORAGE - Individual/Hybrid Saving Flow

### File Structure
```
/storage/.../crop/janeirohAgriculture/           (Group folder)
├── group.json                                    (Project Background)
│   └── Contains: fcaName, region, members=[],
│                 implementationType='individual' or 'hybrid'
│
├── John_Fruto_Ambal/                            (Farmer 1 folder)
│   ├── data.json                                (Farmer 1's commodities & trainings)
│   ├── crops_Vegetables_14.51_121.02.jpg
│   └── crops_Coconut_14.52_121.03.jpg
│
└── Maribel_Oflaria_Baltazar/                    (Farmer 2 folder)
    ├── data.json                                (Farmer 2's commodities & trainings)
    └── crops_Rice_14.53_121.04.jpg
```

---

## 📝 STEP 1: Project Background (group.json)

**File:** `step_01_project_background.dart`

**What Happens:**
1. User enters FCA name, region, province, municipality, barangay
2. Selects implementation type = **"INDIVIDUAL"** or **"HYBRID"**
3. Clicks "Next"
4. Data saved to **group.json**

**Saved Data:**
```json
{
  "implementationType": "individual",
  "fcaName": "janeirohAgriculture",
  "reportingPeriod": "2026",
  "region": "Region IV-A (CALABARZON)",
  "province": "Batangas",
  "municipality": "Lipa City",
  "barangay": "Barangay 2",
  "projectTitle": "agriculture",
  "primaryIntervention": "Coconut",
  "supportInterventions": ["Fertilizers"],
  "members": [],                                  ← Initially empty
  "createdAt": "2026-05-13T15:15:18.871670"
}
```

**Save Location:**
```
/storage/.../crop/janeirohAgriculture/group.json
```

---

## 👨‍🌾 ADDING A NEW FARMER (Individual/Hybrid Only)

**File:** `step_02_commodity_information.dart`

### Step 1: Add Farmer Dialog

**User Action:** Clicks "Add New Farmer" button (appears only for Individual/Hybrid)

```dart
// Dialog opens
showDialog(
  builder: (context) => AlertDialog(
    title: Text('Add New Farmer'),
    content: Column(
      children: [
        TextField(
          hint: 'Farmer Name',
          onChanged: (val) => farmerName = val,
        ),
        TextField(
          hint: 'SAAD ID Number',
          onChanged: (val) => saadIdNo = val,
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => addFarmer(farmerName, saadIdNo),
        child: Text('Add'),
      ),
    ],
  ),
);
```

### Step 2: Create Farmer Entry

```dart
// When "Add" clicked
final newFarmer = {
  'name': 'John Fruto Ambal',
  'saadIdNo': '1'
};

// Add to members array in group.json
group['members'].add(newFarmer);

// Create farmer folder on disk
final farmerDir = Directory('/storage/.../crop/janeirohAgriculture/John_Fruto_Ambal/');
await farmerDir.create(recursive: true);
```

### Step 3: Select Farmer to Enter Data For

```
Screen: Step 02 - Commodity Information

┌──────────────────────────────────┐
│ Select Farmer:  [v]              │
│ ├─ John Fruto Ambal              │
│ ├─ Maribel Oflaria Baltazar      │
│ └─ Add New Farmer...             │
└──────────────────────────────────┘

Once selected, proceed with Steps 02-07 for THIS FARMER ONLY
```

### Step 4: Fill Commodity Data for Selected Farmer

**Important:** All subsequent data (Steps 02-07) is filled and saved for the SELECTED FARMER ONLY

```dart
// Steps 02-07 data goes into farmer's folder
/storage/.../crop/janeirohAgriculture/John_Fruto_Ambal/data.json
```

---

## 📝 STEPS 2-7: Farmer Commodities & Trainings (data.json)

**Key Difference:** Data saved to **farmer's folder**, not group folder

### Adding Commodities for Individual Farmer

**Process:**
```
Select Farmer: John Fruto Ambal ✓

Step 02: Commodity Information
┌──────────────────────────────┐
│ Type of Crop: Vegetables     │
│ Variety: Carrot              │
│ Farmgate Price: 50           │
│ [Add Another] [Next]         │
└──────────────────────────────┘
```

**User clicks "Add Another Commodity":**
```dart
// First commodity stored for John Fruto Ambal
commoditiesList.add({
  'typeOfCrop': 'Vegetables',
  'variety': 'Carrot',
  ...
});

// Form clears for second commodity
```

**Result in data.json (Step 07):**
```json
{
  "fcaName": "janeirohAgriculture",
  "farmerName": "John Fruto Ambal",
  "saadIdNo": "1",
  "reportingPeriod": "2026",
  "implementationType": "individual",
  
  "completedCommodities": [
    {
      "typeOfCrop": "Vegetables",
      "variety": "Carrot",
      "farmgatePrice": "50",
      "totalLandArea": "1 hectare",
      ...
    },
    {
      "typeOfCrop": "Coconut",
      "variety": "Tall",
      "farmgatePrice": "100",
      "totalLandArea": "2 hectares",
      ...
    }
  ],
  
  "trainings": [
    {
      "name": "Climate-Smart Agriculture",
      "date": "2026-05-10",
      "attendees": "15"
    }
  ]
}
```

**Saved To:**
```
/storage/.../crop/janeirohAgriculture/John_Fruto_Ambal/data.json
```

---

### Handling Multiple Farmers

When adding data for **Farmer 2 (Maribel Oflaria)**:

1. User goes back to Step 02
2. Selects "Maribel Oflaria Baltazar" from dropdown
3. Fills Steps 02-07 for HER commodities
4. Her data saved to separate file:
```
/storage/.../crop/janeirohAgriculture/Maribel_Oflaria_Baltazar/data.json
```

**Result:**
```
janeirohAgriculture/
├── group.json (shared FCA info)
├── John_Fruto_Ambal/data.json (John's commodities)
└── Maribel_Oflaria_Baltazar/data.json (Maribel's commodities)
```

---

## 🔥 FIREBASE SYNC - Individual/Hybrid Upload Flow

### Firebase Structure for Individual/Hybrid

```
pending_monitoring/
└── janeirohAgriculture/                    ← Group ID
    ├── implementationType: "individual"
    ├── fcaName: "janeirohAgriculture"
    ├── region: "Region IV-A"
    ├── status: "pending"
    │
    └── members/ (SUBCOLLECTION)
        │
        ├── 1/ (Farmer 1 - SAAD ID is "1")
        │   ├── farmerName: "John Fruto Ambal"
        │   ├── saadIdNo: "1"
        │   ├── completedCommodities: [array]
        │   ├── trainings: [array]
        │   │
        │   └── commodities/ (SUBCOLLECTION)
        │       ├── vegetables_carrot_001/
        │       └── coconut_tall_001/
        │
        └── 1000p/ (Farmer 2 - SAAD ID is "1000p")
            ├── farmerName: "Maribel Oflaria Baltazar"
            ├── saadIdNo: "1000p"
            ├── completedCommodities: [array]
            ├── trainings: [array]
            │
            └── commodities/ (SUBCOLLECTION)
                ├── rice_ir64_001/
                └── livestock_goat_001/
```

### Upload Code Flow

```dart
// In monitoring_record_service.dart

Future<void> syncIndividualHybridRecords(RecordModel groupRecord) async {
  
  final groupId = groupRecord.data['fcaName']; // janeirohAgriculture
  
  // Create group document
  await firestore
      .collection('pending_monitoring')
      .doc(groupId)
      .set({
        'implementationType': 'individual',
        'fcaName': groupRecord.data['fcaName'],
        'region': groupRecord.data['region'],
        'province': groupRecord.data['province'],
        'reportingPeriod': groupRecord.data['reportingPeriod'],
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
  
  // Upload each farmer
  final members = groupRecord.data['members'] as List? ?? [];
  
  for (final member in members) {
    final saadId = member['saadIdNo']; // "1" or "1000p"
    final farmerName = member['name']; // "John Fruto Ambal"
    
    // Get farmer's local data.json
    final farmerDir = Directory('/storage/.../crop/$groupId/$farmerName/');
    final dataFile = File('${farmerDir.path}/data.json');
    
    if (await dataFile.exists()) {
      final farmerData = jsonDecode(await dataFile.readAsString());
      
      // Create farmer document in members subcollection
      await firestore
          .collection('pending_monitoring')
          .doc(groupId)
          .collection('members')
          .doc(saadId)
          .set({
            'farmerName': farmerName,
            'saadIdNo': saadId,
            'completedCommodities': farmerData['completedCommodities'] ?? [],
            'trainings': farmerData['trainings'] ?? [],
            'status': 'pending',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
      
      // Upload each commodity to farmer's subcollection
      final commodities = farmerData['completedCommodities'] as List? ?? [];
      
      for (final commodity in commodities) {
        final commodityId = '${commodity['typeOfCrop']}_${commodity['variety']}'.toLowerCase();
        
        await firestore
            .collection('pending_monitoring')
            .doc(groupId)
            .collection('members')
            .doc(saadId)
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
```

---

## ✏️ EDITING INDIVIDUAL/HYBRID ON FIREBASE

**File:** `record_edit_modal.dart` - `saveChanges()` method

### When Editing an Individual/Hybrid Record

1. User opens "pending" individual/hybrid record from HomeScreen
2. Record shows farmer's commodities (not group commodities)
3. User edits commodity fields or trainings
4. Clicks "Save"

### What Gets Saved

```dart
// In record_edit_modal.dart - saveChanges() method

else if (implementationType == 'individual' || 
         implementationType == 'hybrid') {
  
  // Extract group ID and farmer SAAD ID
  final groupDocId = widget.record.documentPath?.split('/')[1] ?? '';
  // documentPath = 'pending_monitoring/janeirohAgriculture'
  // groupDocId = 'janeirohAgriculture'
  
  final saadId = widget.record.data?['saadIdNo']?.toString() ?? '';
  // saadId = '1' or '1000p'
  
  if (groupDocId.isNotEmpty && saadId.isNotEmpty) {
    
    // Reference to farmer document in members subcollection
    final farmerDocRef = firestore
        .collection('pending_monitoring')
        .doc(groupDocId)
        .collection('members')
        .doc(saadId);
    
    // 1. Update farmer-level fields (trainings, name)
    final farmerUpdates = {
      'trainings': updates['trainings'] ?? [],
      'updatedAt': FieldValue.serverTimestamp(),
    };
    
    if (updates.containsKey('farmerName')) {
      farmerUpdates['farmerName'] = updates['farmerName'];
    }
    
    await farmerDocRef.update(farmerUpdates);
    print('✅ Updated farmer-level fields');
    
    // 2. Update each commodity in farmer's subcollection
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
        
        // Save to farmer's commodities subcollection
        await farmerDocRef
            .collection('commodities')
            .doc(commodityId)
            .update(updatedCommodity);
      }
    }
  }
}
```

### Result

✅ Farmer document updated
✅ Farmer's commodities updated in their subcollection
✅ Trainings persisted to Firebase

---

## 📊 Complete Individual/Hybrid Flow Summary

| Step | Action | Location | File |
|------|--------|----------|------|
| **1** | Add FCA & select Individual/Hybrid | HomeScreen → ProjectBackgroundForm | group.json |
| **2** | Add Farmer 1 | Step 02 → "Add New Farmer" dialog | group.json members[] |
| **3** | Fill Steps 02-07 for Farmer 1 | Step 02-07 | Farmer1/data.json |
| **4** | Add Farmer 2 | Step 02 → "Add New Farmer" dialog | group.json members[] |
| **5** | Fill Steps 02-07 for Farmer 2 | Step 02-07 | Farmer2/data.json |
| **6** | Upload to Firebase | HomeScreen → Auto-sync | pending_monitoring/{groupId}/members/{saadId} |
| **7** | Edit Farmer 1 Record | HomeScreen → MemberRecordsScreen → Edit | Firebase farmer doc + commodities subcollection |
| **8** | Edit Farmer 2 Record | HomeScreen → MemberRecordsScreen → Edit | Firebase farmer doc + commodities subcollection |

---

## 🔑 Key Points for Individual/Hybrid

1. **Each farmer is separate:** Data never mixed between farmers
2. **Multiple commodities per farmer:** Each farmer can add multiple commodities
3. **Separate Firebase documents:** `members/{saadId}` keeps farmer data isolated
4. **Editing is farmer-specific:** Edit button shows only that farmer's commodities
5. **Sync is automatic:** All farmers uploaded in one sync operation
6. **SAAD ID matters:** Used as document key in Firebase for farmer identification


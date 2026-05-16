# COLLECTIVE IMPLEMENTATION - Complete Guide (Crop & Livestock)

## Overview

**COLLECTIVE** = One FCA/Group with NO individual farmers. All commodities/batches belong to the GROUP as a whole.

---

## HOW YOUR CROP COLLECTIVE WORKS (ACTUAL)

### 1. DATA ENTRY (No Farmer Input)

When you select **"Collective"** in Step 01:
- ❌ NO farmer name entered
- ✅ Only FCA name entered (e.g., "janeirohAgriculture")
- ✅ Only project background fields entered
- ✅ `members = []` (empty)

### 2. ADDING COMMODITIES (All at Group Level)

Steps 02-07: You add multiple commodities:
```
Commodity 1: Coconut (type, variety, land area, fertilizer, etc)
Commodity 2: Calamansi (type, variety, land area, fertilizer, etc)
Commodity 3: Rice (type, variety, land area, fertilizer, etc)
```

All commodities stored in:
```dart
wrapper.completedCommodities = [
  { typeOfCrop: 'Coconut', variety: 'Tall', ... },
  { typeOfCrop: 'Calamansi', variety: 'Regular', ... },
  { typeOfCrop: 'Rice', variety: 'IR64', ... }
]
```

### 3. SAVING (Group Level Data)

When you click "Done", the code:

```dart
if (implementationType == 'collective') {
  // Build membersByFarmerId - but for collective it will be populated 
  // because of the initial checks in _done()
  // However when VIEWING/DISPLAYING, it shows NO members
}

// The key is in the _members initialization:
late final List<CropMember> _members = widget.members ??
    (widget.wrapper.implementationType == 'collective'
        ? []                    // ✅ Returns EMPTY list for collective
        : ...);
```

**Result**: Saves to local storage with:
- `completedCommodities[]` = All group commodities
- `trainings[]` = Group-level trainings
- `members[]` = Empty array
- `membersByFarmerId` = Populated for sync, but NOT displayed
- `farmerName` = FCA name or empty

### 4. VIEWING (No Members Shown)

When viewing a collective record:
```dart
// _members list is EMPTY for collective
// So UI shows:
- FCA Name
- List of Commodities (no farmer attribution)
- Trainings (group level)
- NO member list
- NO "View Member" buttons
```

### 5. EDITING (Commodities at Group Level)

User opens record → clicks Edit:
```dart
// In record_edit_modal.dart

if (implementationType == 'collective') {
  // Edit commodity data at group level
  await groupDocRef
      .collection('commodities')
      .doc(commodityId)
      .update(updatedCommodityData);
}
```

### 6. FIREBASE SYNC (Group Structure)

When syncing to Firebase:
```
pending_monitoring/
└── crop_janeirohAgriculture/              # Group ID
    ├── implementationType: "collective"
    ├── fcaName: "janeirohAgriculture"
    ├── farmerName: "janeirohAgriculture"  ← GROUP NAME
    ├── completedCommodities: [...]        ← GROUP LEVEL
    ├── trainings: [...]                   ← GROUP LEVEL
    ├── members: []                        ← EMPTY
    ├── membersByFarmerId: {...}           ← Used for sync
    │
    └── commodities/                       ← SUBCOLLECTION
        ├── coconut_tall_001/
        ├── calamansi_regular_001/
        └── rice_ir64_001/
```

### 7. APPROVAL (Whole Group)

Moderator approves the entire FCA group:
- ✅ All commodities move to `approved_monitoring`
- ✅ Single approval covers ALL commodities
- ✅ No per-commodity approvals

---

## KEY INSIGHT: membersByFarmerId Usage for Collective

**Important**: Your crop collective DOES populate `membersByFarmerId` internally, BUT:

1. **For Saving**: It needs `membersByFarmerId` for Firebase sync logic
2. **For Displaying**: The `_members` getter returns `[]` for collective, so UI shows NO members
3. **For Viewing Records**: `member_records_screen.dart` checks if group members exist and hides member list for collectives

This is **not a bug** - it's intentional! The membersByFarmerId is used for technical sync purposes, but the UI correctly displays collective records without individual farmers.

---

## LIVESTOCK COLLECTIVE - SHOULD WORK IDENTICALLY

Your livestock collective should follow the EXACT SAME PATTERN:

### 1. DATA ENTRY (No Farmer Input)
```dart
// In livestock_monitoring_summary_screen.dart
// Step 01: Only FCA name entered
// members = []
```

### 2. ADDING BATCHES (All at Group Level)
```dart
wrapper.completedBatches = [
  { breed: 'Broiler', maleStocks: 100, femaleStocks: 150, ... },
  { breed: 'Layer', maleStocks: 50, femaleStocks: 200, ... }
]
```

### 3. SAVING (Group Level Data)
```dart
if (implementationType == 'collective') {
  // Like crop: populate membersByFarmerId for sync
  // But display will show NO members
  dataToSave['membersByFarmerId'] = membersByFarmerId;
  dataToSave['members'] = membersByFarmerId.entries...toList();
}
```

### 4. VIEWING (No Members Shown)
```dart
// In livestock_member_records_screen.dart (NEW, needs to be created)
late final List<LivestockMember> _members = widget.wrapper.implementationType == 'collective'
    ? []  // ✅ Returns EMPTY list for collective
    : [...];
```

### 5. EDITING (Batches at Group Level)
```dart
// In livestock_record_edit_modal.dart (NEW, needs to be created)
if (implementationType == 'collective') {
  // Edit batch data at group level
  await groupDocRef
      .collection('completedBatches')
      .doc(batchId)
      .update(updatedBatchData);
}
```

### 6. FIREBASE SYNC (Group Structure)
```
pending_monitoring/
└── livestock_AgriGroup/                   # Group ID
    ├── implementationType: "collective"
    ├── fcaName: "AgriGroup FCA"
    ├── farmerName: "AgriGroup FCA"        ← GROUP NAME
    ├── completedBatches: [...]            ← GROUP LEVEL
    ├── trainings: [...]                   ← GROUP LEVEL
    ├── members: []                        ← EMPTY
    ├── membersByFarmerId: {...}           ← Used for sync
    │
    └── completedBatches/                  ← SUBCOLLECTION
        ├── broiler_001/
        └── layer_001/
```

### 7. APPROVAL (Whole Group)
```dart
// In monitoring_record_service.dart
Future<void> approveRecord({
  required String recordId,
  required bool isModerator,
  required bool isAdmin,
})
// Move ALL batches from pending → approved
```

---

## Summary: Collective Pattern

| Aspect | Crop | Livestock |
|--------|------|-----------|
| **Data Entry** | FCA name only | FCA name only |
| **Commodities/Batches** | Multiple at group level | Multiple at group level |
| **Farmers** | NONE (empty array) | NONE (empty array) |
| **Members Display** | Empty list in UI | Empty list in UI |
| **Firebase Structure** | `pending_monitoring/{groupId}/commodities/` | `pending_monitoring/{groupId}/completedBatches/` |
| **Approval** | Whole group | Whole group |
| **Editing** | Commodities at group level | Batches at group level |

---

## NO FARMERS IN COLLECTIVE

✅ **Your crop collective**:
- Saves correctly with NO farmer names
- Views correctly with NO farmer list
- Edits correctly at group level
- Syncs correctly to Firebase
- Approves correctly as one unit

✅ **Livestock collective should**:
- Save correctly with NO farmer names (already does via livestock_monitoring_summary_screen.dart)
- View correctly with NO farmer list (needs livestock_member_records_screen.dart)
- Edit correctly at group level (needs livestock_record_edit_modal.dart)
- Sync correctly to Firebase (already handled by monitoring_record_service.dart)
- Approve correctly as one unit (extend monitoring_record_service.dart for livestock)

**NO additional complexity - just apply crop pattern to livestock!**

# LIVESTOCK Collective - Current Implementation Analysis

## 1. Current State

### Data Flow & Storage (Livestock Monitoring Summary Screen)

**File**: [livestock_monitoring_summary_screen.dart](../lib/screens/livestock/livestock_monitoring_summary_screen.dart)

#### How Collective Records are Saved:

```dart
// When livestock monitoring is DONE:
_done() {
  // 1. Build completedBatches from current batch data
  completedBatches.add({
    'farmerName': wrapper.farmerName,
    'saadIdNo': wrapper.saadIdNo,
    'breed': wrapper.breed,
    'inputsReceived': [...],
    'inputsPurchased': [...],
    // ... other fields
  });

  // 2. Load existing group draft to preserve other farmers
  final existingDraft = _loadExistingGroupDraft();
  
  // 3. Build membersByFarmerId map (preserves all farmers)
  if (implementationType == 'collective') {
    // For collective: Store data directly in group record
    dataToSave['membersByFarmerId'] = {}; // EMPTY for collective
    dataToSave['members'] = [];
  } else if (implementationType == 'individual') {
    // For individual: Only current farmer
    dataToSave['membersByFarmerId'] = {farmerId: {...}};
  } else {
    // Hybrid: All farmers in membersByFarmerId
    dataToSave['membersByFarmerId'] = membersByFarmerId;
  }

  // 4. Save to PendingDraftService
  await PendingDraftService.instance.saveDraft(
    productionType: 'livestock',
    implementationType: wrapper.implementationType,
    data: dataToSave,
  );
}
```

**Key Fields Saved for Collective**:
- `completedBatches` (array of batch data)
- `trainings` (array of training records)
- `fcaName`, `projectTitle`, `reportingPeriod`
- `members` (list of member names for reference)
- `membersByFarmerId` (EMPTY for collective)

### Firebase Storage Structure (monitoring_record_service.dart)

**File**: [monitoring_record_service.dart](../lib/services/monitoring_record_service.dart)

```
pending_monitoring/
└── livestock_{fcaName}/           # Group document
    ├── fcaName, productionType, implementationType
    ├── trainings (stored at group level for COLLECTIVE)
    ├── completedBatches (stored at group level for COLLECTIVE)
    └── members/                    # For individual/hybrid only
        └── {saadId}/
            ├── farmerName, saadIdNo
            └── trainings (stored per farmer)
```

**Key Difference**:
- **CROP COLLECTIVE**: Uses `commodities` subcollection at group level
- **LIVESTOCK COLLECTIVE**: Uses `completedBatches` and `trainings` arrays at group level (NO members subcollection)

---

## 2. What's Missing for Approval Workflow

### A. NO Viewing/Editing Screen

❌ **Missing**: Livestock does NOT have viewing/editing screens like crops do
- Crops: `member_records_screen.dart` (shows group + farmers with edit modal)
- Livestock: NO equivalent

Currently, livestock records are:
1. Created in `livestock_monitoring_summary_screen.dart` (data entry)
2. Saved to local storage + Firebase via `PendingDraftService`
3. ✅ Visible in `DataScreen` but can't edit/view details
4. ❌ No approval workflow (no approve/decline buttons)

### B. NO Approval Service Methods

❌ **Missing**: `monitoring_record_service.dart` does NOT have for livestock:
- `approveRecord()` - NOT implemented for livestock
- `declineRecord()` - NOT implemented for livestock
- `fetchApprovedRecords()` - Likely doesn't handle livestock properly

### C. NO Edit Modal

❌ **Missing**: No modal to edit livestock data after initial entry
- Crops: `record_edit_modal.dart` allows editing commodities
- Livestock: No equivalent for batches/trainings

### D. NO Member Records Screen

❌ **Missing**: No screen showing livestock group with individual farmer records
- Crops: `member_records_screen.dart` shows all farmers in a group with edit buttons
- Livestock: Would need similar for livestock batches by farmer

---

## 3. How Livestock Collective CURRENTLY Works vs SHOULD Work

### Current Flow (Without Approval)
```
DATA ENTRY PHASE:
  ① Farmer enters livestock data in livestock_monitoring_summary_screen.dart
  ② Clicks "Done" → saves to PendingDraftService + Firebase pending_monitoring collection
  ③ Record status: 'unsync' or 'pending'
  
VIEWING PHASE:
  ④ DataScreen shows records from Firebase
  ❌ Can't edit, can't approve, can't decline
```

### Required Flow (With Approval - Matching Crop System)
```
DATA ENTRY PHASE:
  ① Farmer enters livestock data in livestock_monitoring_summary_screen.dart
  ② Clicks "Done" → saves to PendingDraftService + Firebase pending_monitoring collection
  ③ Record status: 'unsync' or 'pending'

VIEWING/EDITING PHASE: (NEW - NEEDED)
  ④ Profiler opens livestock record in NEW livestock_member_records_screen.dart
  ⑤ Sees group info + list of batches/trainings
  ⑥ Can EDIT batch/training details (all statuses)
  ⑦ Clicks "Edit" → opens livestock_record_edit_modal.dart
  
APPROVAL PHASE: (NEW - NEEDED)
  ⑧ Moderator/Admin opens livestock record
  ⑨ Sees locked Approve/Decline buttons (if pending)
  ⑩ Clicks Approve → moves from pending_monitoring → approved_monitoring
  
VIEWING APPROVED: (NEW - NEEDED)
  ⑪ Moderator/Admin can edit approved records
  ⑫ Farmer can still edit their own approved record data
```

---

## 4. What Needs to Be Created/Modified

### Phase 1: Create Viewing Screen (Similar to member_records_screen.dart)

**File to Create**: `lib/screens/livestock/livestock_member_records_screen.dart`

What it needs:
```dart
class LivestockMemberRecordsScreen extends StatefulWidget {
  final RecordModel record;           // The group record
  final bool isModerator;             // User role
  final bool isAdmin;                 // User role
}

// Methods needed:
- _viewBatch(context, batchData)     // Opens edit modal for a batch
- _updateReviewStatus(...)             // Approve/decline record
- _build()                             // Shows:
  - Group name & info
  - List of batches with edit buttons
  - Approve/Decline buttons (if pending + moderator)
```

### Phase 2: Create Edit Modal (Similar to record_edit_modal.dart)

**File to Create**: `lib/screens/livestock/livestock_record_edit_modal.dart`

What it needs:
```dart
class LivestockRecordEditModal extends StatefulWidget {
  final RecordModel record;           // Group record
  final Map<String, dynamic> batchData; // Individual batch data
  final bool isGroup;                 // Editing group or batch level
}

// Methods needed:
- saveChanges()                        // Firebase 3-level save:
  - For COLLECTIVE: Update completedBatches in group doc
  - For INDIVIDUAL: Update farmer/{saadId}/trainings
  - For HYBRID: Update farmer/{saadId}/trainings
```

### Phase 3: Update monitoring_record_service.dart

Add/extend for livestock:
```dart
// For fetching livestock records (may need adjustment)
Future<List<RecordModel>> fetchApprovedRecords(...)

// For approving livestock records (NEW)
Future<void> approveRecord({
  required String recordId,
  required bool isModerator,
  required bool isAdmin,
  required String productionType,  // 'livestock'
})

// For declining livestock records (NEW)
Future<void> declineRecord({
  required String recordId,
  required bool isModerator,
  required bool isAdmin,
  required String productionType,  // 'livestock'
})
```

### Phase 4: Update record_view_modal.dart (If Reusing)

Options:
- **Option A**: Reuse `record_view_modal.dart` for livestock too (generic approach)
- **Option B**: Create `livestock_record_view_modal.dart` (specific approach)

Current usage: Only for crop

---

## 5. Livestock-Specific Data Structure

### Collective Livestock Record Structure

```
pending_monitoring/
└── livestock_AgriGroup/                      # Group document
    ├── fcaName: "AgriGroup FCA"
    ├── productionType: "livestock"
    ├── implementationType: "collective"
    ├── createdBy: user.uid
    ├── trainings: [                          # Trainings at group level
    │   {
    │     'trainingType': 'Breed Selection',
    │     'date': '2024-05-15',
    │     'trainer': 'Dr. Smith'
    │   }
    │ ]
    ├── completedBatches: [                   # Batches at group level
    │   {
    │     'farmerName': 'Juan Dela Cruz',
    │     'saadIdNo': 'SAAD001',
    │     'breed': 'Broiler',
    │     'maleStocks': 100,
    │     'femaleStocks': 150,
    │     'inputsReceived': [...],
    │     'inputsPurchased': [...]
    │   }
    │ ]
    └── members/                              # EMPTY for collective
```

### Individual Livestock Record Structure

```
pending_monitoring/
└── livestock_JuanFarm/                       # Group document
    ├── fcaName: "Juan's Farm"
    ├── productionType: "livestock"
    ├── implementationType: "individual"
    ├── farmerName: "Juan Dela Cruz"
    ├── saadIdNo: "SAAD001"
    └── members/
        └── SAAD001/                          # One farmer
            ├── farmerName: "Juan Dela Cruz"
            └── trainings: [...]
```

### Hybrid Livestock Record Structure

```
pending_monitoring/
└── livestock_CoopFarm/                       # Group document
    ├── fcaName: "Coop Farm"
    ├── productionType: "livestock"
    ├── implementationType: "hybrid"
    ├── trainings: [...]                      # At group level
    └── members/
        ├── SAAD001/
        │   ├── farmerName: "Juan Dela Cruz"
        │   └── trainings: [...]
        └── SAAD002/
            ├── farmerName: "Maria Santos"
            └── trainings: [...]
```

---

## 6. Key Livestock Fields to Display/Edit

### Group Level (Collective/Hybrid)
- `fcaName` - FCA name
- `projectTitle` - Project name
- `reportingPeriod` - Period covered
- `trainings[]` - Training records
- `completedBatches[]` - Batch records (collective only)

### Batch Level (Individual Entry within Collective)
- `farmerName` - Farmer name
- `saadIdNo` - Farmer ID
- `breed` - Livestock breed (Broiler, Layer, etc.)
- `maleStocks` - Number of male animals
- `femaleStocks` - Number of female animals
- `maleToFemaleRatio` - Calculated ratio
- `dateReceived` - Date animals received
- `stocksReceived` - Total received
- `inputsReceived[]` - Items received
- `inputsPurchased[]` - Items purchased
- `farmgatePrices` - Price information

---

## 7. Implementation Roadmap for Livestock Approval System

### Step 1: Create livestock_member_records_screen.dart
- Copy structure from `member_records_screen.dart`
- Replace "commodities" terminology with "batches"
- Handle `completedBatches` array for collective
- Handle `members` subcollection for individual/hybrid

### Step 2: Create livestock_record_edit_modal.dart
- Copy structure from `record_edit_modal.dart`
- Update `saveChanges()` to handle:
  - **COLLECTIVE**: Update `completedBatches` in group doc
  - **INDIVIDUAL**: Update group doc directly (no members subcollection)
  - **HYBRID**: Update `members/{saadId}` documents

### Step 3: Extend monitoring_record_service.dart
- Add livestock support to `approveRecord()` and `declineRecord()`
- Ensure `fetchApprovedRecords()` works for livestock

### Step 4: Update record_view_modal.dart (Optional)
- Make generic to work with livestock fields
- Or create separate livestock_record_view_modal.dart

### Step 5: Integration Testing
- Create livestock record
- View in livestock_member_records_screen.dart
- Edit batch data
- Test approval workflow
- Verify data in Firebase

---

## 8. Current Livestock Issues/Limitations

| Issue | Impact | Status |
|-------|--------|--------|
| No viewing/editing screen | Can't edit records after creation | ❌ CRITICAL |
| No approval workflow | Can't moderate records | ❌ CRITICAL |
| No members screen | Can't view individual farmer data in group | ❌ HIGH |
| completedBatches at group level | Unusual structure vs crop (which uses members) | ⚠️ DESIGN |
| trainings at group level (collective) | Need special handling for editing | ⚠️ DESIGN |

---

## 9. Next Steps

1. **Analyze** the difference between livestock and crop data structures ✅ (THIS DOCUMENT)
2. **Plan** which fields need editing capability 
3. **Create** livestock_member_records_screen.dart
4. **Create** livestock_record_edit_modal.dart
5. **Extend** monitoring_record_service.dart for livestock
6. **Test** the complete workflow

---

## Summary

**Current State**: Livestock collective records are created and stored, but cannot be edited, viewed in detail, or approved.

**What's Missing**: 
- Member/batch viewing screen
- Edit modal for batch/training data
- Approval workflow (approve/decline)
- Role-based button visibility

**Solution**: Implement livestock screens similar to crop screens, but adapted for livestock-specific data structure (batches, trainings, stocks instead of commodities).

**Key Difference**: Livestock collective stores batches and trainings at GROUP level, not in members subcollection like crop does.

Ready to start implementation? 🚀

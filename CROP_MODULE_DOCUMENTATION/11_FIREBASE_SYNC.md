# 🔄 FIREBASE SYNC SYSTEM - Local to Firestore Synchronization

## 🔀 What is Firebase Sync?

**Sync** = Uploading local records from your device to Firebase Firestore, making them available on the server and visible to approvers.

**Flow:**
```
Local Device Storage (data.json)
         ↓
    [SYNC PROCESS]
         ↓
Firebase Firestore (pending_monitoring collection)
         ↓
Approvers can view & approve
```

---

## 📊 Record Statuses

Your records go through these states:

```
LOCAL & UNSYNC
   ↓
   User clicks "Sync" or auto-sync triggers
   ↓
SYNCING TO FIREBASE
   ↓
SYNCED & PENDING
   ↓
Approver reviews
   ↓
APPROVED (approved status) OR REJECTED
```

### Status Values

| Status | Meaning | Location |
|--------|---------|----------|
| `unsync` | Local only, not on Firebase | Device storage |
| `pending` | On Firebase, awaiting approval | Firestore |
| `approved` | Reviewed & approved by admin | Firestore |
| `rejected` | Sent back for corrections | Firestore |

---

## 🚀 HOW SYNC WORKS

### When Does Sync Happen?

**File: `monitoring_record_service.dart`**

When user completes all 7 steps and clicks the final "Save" button:

```dart
// In step_07_trainings.dart or wherever form completion happens

await MonitoringRecordService.instance.savePendingRecord(
  productionType: widget.productionType,  // 'crop', 'livestock', or 'poultry'
  implementationType: widget.implementationType,  // 'collective', 'individual', or 'hybrid'
  data: allFormData,  // Combined data from steps 01-07
);
```

**This single call handles EVERYTHING:**
1. Saves project background to FCA document
2. Saves farmer/member records (if individual/hybrid)
3. Saves commodities to subcollections
4. Uploads directly to Firebase (no separate sync step needed)

---

## 🔥 SYNC PROCESS - STEP BY STEP

### File: `monitoring_record_service.dart`

**Primary Method: `savePendingRecord()`**

```dart
Future<String> savePendingRecord({
  required String productionType,
  required String implementationType,
  required Map<String, dynamic> data,
}) async {
  try {
    print('🔥 savePendingRecord START:');
    print('   productionType: $productionType');
    print('   implementationType: $implementationType');
    
    // Step 1: Validate user & get FCA name
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    
    final fcaName = (data['fcaName'] as String? ?? 'Unknown Group').trim();
    
    // Step 2: Create group document ID
    // Format: {typePrefix}_{fcaName}
    // Example: crop_janeirohAgriculture
    final groupDocId = '${typePrefix}_$fcaName';
    
    // Step 3: Save to Firebase
    await _saveToFirebase(groupDocId, implementationType, data);
    
    return groupDocId;
    
  } catch (e) {
    print('❌ Save failed: $e');
    rethrow;
  }
}
```

---

## 📝 SYNCING COLLECTIVE RECORDS

### Collective Flow in savePendingRecord()

**File:** `monitoring_record_service.dart`

```dart
// Step 1: Create/update group document with background fields
final projectBackground = {
  'fcaName': fcaName,
  'productionType': productionType,
  'implementationType': 'collective',
  'region': data['region'],
  'province': data['province'],
  'municipality': data['municipality'],
  'barangay': data['barangay'],
  'projectTitle': data['projectTitle'],
  'primaryIntervention': data['primaryIntervention'],
  'supportInterventions': data['supportInterventions'],
  'reportingPeriod': data['reportingPeriod'],
  'createdAt': FieldValue.serverTimestamp(),
  'updatedAt': FieldValue.serverTimestamp(),
  'approvalStatus': 'pending',
};

// Save to Firebase
final groupDocRef = _firestore.collection('pending_monitoring').doc(groupDocId);
await groupDocRef.set(projectBackground, SetOptions(merge: true));
print('✅ Group document created');

// Step 2: Save trainings at group level
if (implementationType == 'collective') {
  await groupDocRef.set({
    'trainings': data['trainings'] ?? [],
  }, SetOptions(merge: true));
  print('✅ Trainings saved at group level');
}

// Step 3: Upload each commodity to group's commodities subcollection
final commodities = data['completedCommodities'] as List? ?? [];

for (final commodity in commodities) {
  final commodityId = CommodityIdService.generate(
    productionType: productionType,
    commodity: commodity,
  );
  
  await groupDocRef
      .collection('commodities')
      .doc(commodityId)
      .set({
        ...commodity,
        'createdAt': FieldValue.serverTimestamp(),
      });
  
  print('✅ Uploaded commodity: $commodityId');
}
```

### Result in Firebase

```
pending_monitoring/
└── crop_janeirohAgriculture/              ← Group doc
    ├── fcaName: "janeirohAgriculture"
    ├── implementationType: "collective"
    ├── trainings: [...]
    │
    └── commodities/                       ← Subcollection
        ├── crop_coconut_tall_001/
        └── crop_calamansi_regular_001/
```

---

## 👥 SYNCING INDIVIDUAL/HYBRID RECORDS

### Individual/Hybrid Flow in savePendingRecord()

**File:** `monitoring_record_service.dart`

```dart
// Step 1: Create group document (same as collective for background)
final groupDocRef = _firestore.collection('pending_monitoring').doc(groupDocId);
await groupDocRef.set(projectBackground, SetOptions(merge: true));
print('✅ Group document created');

// Step 2: For each farmer member, create farmer document in members subcollection
final members = data['members'] as List? ?? [];

for (final member in members) {
  final saadId = member['saadIdNo']?.toString() ?? '';
  final farmerName = member['name']?.toString() ?? '';
  
  if (saadId.isEmpty) continue;
  
  // Get farmer's specific data
  final farmerData = {
    'farmerName': farmerName,
    'saadIdNo': saadId,
    'completedCommodities': member['completedCommodities'] ?? [],
    'trainings': member['trainings'] ?? [],
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };
  
  // Create farmer document in members subcollection
  await groupDocRef
      .collection('members')
      .doc(saadId)
      .set(farmerData);
  
  print('✅ Farmer $saadId created');
  
  // Step 3: Upload farmer's commodities
  final commodities = member['completedCommodities'] as List? ?? [];
  
  for (final commodity in commodities) {
    final commodityId = CommodityIdService.generate(
      productionType: productionType,
      commodity: commodity,
    );
    
    await groupDocRef
        .collection('members')
        .doc(saadId)
        .collection('commodities')
        .doc(commodityId)
        .set({
          ...commodity,
          'createdAt': FieldValue.serverTimestamp(),
        });
    
    print('✅ Farmer $saadId commodity uploaded: $commodityId');
  }
}
```

### Result in Firebase

```
pending_monitoring/
└── crop_janeirohAgriculture/                      ← Group doc
    ├── fcaName: "janeirohAgriculture"
    ├── implementationType: "individual"
    │
    └── members/                                   ← Farmers subcollection
        ├── 1/                                     ← Farmer 1 (SAAD ID)
        │   ├── farmerName: "John Fruto Ambal"
        │   ├── completedCommodities: [...]
        │   ├── trainings: [...]
        │   │
        │   └── commodities/                       ← Farmer's commodities
        │       ├── crop_vegetables_carrot_001/
        │       └── crop_coconut_tall_001/
        │
        └── 1000p/                                 ← Farmer 2 (SAAD ID)
            ├── farmerName: "Maribel Oflaria"
            ├── completedCommodities: [...]
            ├── trainings: [...]
            │
            └── commodities/                       ← Farmer's commodities
                ├── crop_rice_ir64_001/
                └── crop_livestock_goat_001/
```

---

## ✅ MARKING AS SYNCED

After successful upload to Firebase:

```dart
// Update local record status
if (synced successfully) {
  
  // Update all local record metadata
  record.status = 'pending';
  record.documentPath = 'pending_monitoring/$groupId';
  record.documentId = groupId;
  record.isLocal = false;  // Now on Firebase
  
  // Update in local database (PendingDraftService)
  await PendingDraftService.instance.markAsSynced(
    localId: record.id!,
    documentPath: record.documentPath,
    status: 'pending',
  );
  
  print('✅ Record marked as synced in local database');
}
```

---

## ❌ ERROR HANDLING

### If Save Fails

**File:** `monitoring_record_service.dart`

```dart
Future<String> savePendingRecord({
  required String productionType,
  required String implementationType,
  required Map<String, dynamic> data,
}) async {
  try {
    // ... save logic ...
    
  } catch (e) {
    print('❌ Save failed: $e');
    // Error is thrown back to UI
    rethrow;
  }
}
```

### Possible Errors

| Error | Reason | Solution |
|-------|--------|----------|
| `User not authenticated` | User not logged in | Log in first |
| `Firebase permission denied` | No write access to collection | Check Firebase rules |
| `Network error` | No internet connection | Connect to internet and retry |
| Missing fields | Required data is empty | Check all form fields are filled |

### UI Error Handling

**Any screen calling savePendingRecord:**

```dart
try {
  final groupDocId = await MonitoringRecordService.instance.savePendingRecord(
    productionType: productionType,
    implementationType: implementationType,
    data: formData,
  );
  
  // Show success message
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('✅ Record saved successfully'),
      backgroundColor: Colors.green,
    )
  );
  
  // Navigate to next screen or back
  Navigator.pop(context);
  
} on FirebaseException catch (e) {
  // Firebase-specific errors
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('❌ Firebase error: ${e.code}'),
      backgroundColor: Colors.red,
    )
  );
  
} catch (e) {
  // Other errors
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('❌ Save failed: $e'),
      backgroundColor: Colors.red,
    )
  );
}
```

---

## 📊 Record Status After Save

When `savePendingRecord()` succeeds, your record is created in Firebase with status **'pending'**:

```dart
{
  'approvalStatus': 'pending',  // Waiting for admin review
  'createdAt': serverTimestamp,
  'updatedAt': serverTimestamp,
  // ... all your form data ...
}
```

### Admin Reviews Your Record

**File:** `monitoring_record_service.dart`

```dart
// Admin approves
Future<void> approveRecord({
  required String groupDocId,
  required String? saadId,  // null for collective, farmer ID for individual/hybrid
  required String commodityId,
}) async {
  // Copy from pending_monitoring to approved_monitoring
  final pendingRef = _firestore
      .collection('pending_monitoring')
      .doc(groupDocId);
  
  final recordData = await pendingRef.get();
  
  // Save to approved collection
  await _firestore
      .collection('approved_monitoring')
      .doc(groupDocId)
      .set(recordData.data() ?? {}, SetOptions(merge: true));
  
  // Update status
  await pendingRef.update({'approvalStatus': 'approved'});
  
  print('✅ Record approved');
}

// Admin rejects
Future<void> declineRecord({
  required String groupDocId,
  required String? saadId,
  required String commodityId,
  required String rejectionReason,
}) async {
  // Update status only (record stays in pending for editing)
  await _firestore
      .collection('pending_monitoring')
      .doc(groupDocId)
      .update({
        'approvalStatus': 'rejected',
        'rejectionReason': rejectionReason,
      });
  
  print('✅ Record rejected');
}
```

---

## 📊 Sync Process Summary

| Step | Action | Status | Location |
|------|--------|--------|----------|
| 1 | User completes all 7 steps | unsync | Local device |
| 2 | Auto-sync detects unsync records | unsync | Local device |
| 3 | Read data.json files | unsync | Local device |
| 4 | Create group document in Firestore | syncing | Firebase |
| 5 | Upload commodities to subcollection | syncing | Firebase |
| 6 | Upload farmer documents (if individual/hybrid) | syncing | Firebase |
| 7 | Mark record as synced in local DB | pending | Both (Local + Firebase) |
| 8 | Show record in "Pending Approval" list | pending | Firebase |
| 9 | Approver reviews record | pending | Firebase |
| 10 | Approver clicks "Approve" | approved | Firebase |

---

## 🔑 Key Points for Sync

1. **Automatic:** Sync happens automatically when app opens
2. **Status check:** Always check `status` field (unsync/pending/approved)
3. **Network required:** Must have internet connection to sync
4. **Retry on fail:** Failed syncs are retried automatically
5. **Document path:** After sync, `documentPath` points to Firebase location
6. **Idempotent:** Safe to sync same record multiple times
7. **Timestamp:** Firebase adds `createdAt`/`updatedAt` timestamps automatically


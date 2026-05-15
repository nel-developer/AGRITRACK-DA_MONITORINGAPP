# ✏️ EDITING PENDING RECORDS - Firebase Modification Flow

## 🔄 What is Editing Pending Records?

**Pending records** = Records already uploaded to Firebase waiting for approval. Users can edit these records to fix errors or add missing information BEFORE an approver reviews them.

**Example:**
```
HomeScreen
   ↓
User sees "Pending Approval" record for John's Carrot commodity
   ↓
User clicks "Edit"
   ↓
Form opens with current Firebase data
   ↓
User changes commodity price from 50 to 60
   ↓
User clicks "Save"
   ↓
Firebase document updated with new price
   ↓
Approver sees updated record
```

---

## 📲 ACCESSING EDIT FOR PENDING RECORDS

### File: `home_screen.dart`

1. **List shows both local and Firebase records:**

```dart
// Home screen displays:
// - Local (unsync) records with "Complete & Sync" button
// - Pending (Firebase) records with "View" / "Edit" buttons

ListView(
  children: [
    // Pending records from Firebase
    for (final record in pendingRecords)
      RecordCard(
        record: record,
        onEdit: () => _openEditModal(record),
        onView: () => _openViewModal(record),
      ),
    
    // Local records
    for (final record in localRecords)
      RecordCard(
        record: record,
        onComplete: () => _completeLocalRecord(record),
      ),
  ],
)
```

2. **User sees "Edit" button on pending record:**

```
┌─────────────────────────────────────┐
│ Pending: John's Carrot Commodity    │
│ Status: Pending Approval            │
│ [VIEW] [EDIT]                       │
└─────────────────────────────────────┘
```

3. **User clicks "EDIT":**

```dart
onEdit: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => RecordEditModal(
        record: pendingRecord,
        isGroup: false,  // Individual farmer record
        isMemberEditOnly: true,  // Can only edit commodity fields
      ),
    ),
  );
}
```

---

## 📖 VIEWING PENDING RECORD FLOW

**File:** `record_view_modal.dart`

### Step 1: Load Pending Record Data

```dart
// When viewing pending record
final record = widget.record;
// record.documentPath = 'pending_monitoring/janeirohAgriculture'
// or for individual: 'pending_monitoring/janeirohAgriculture/members/1'

// Record contains:
// {
//   fcaName: "janeirohAgriculture",
//   farmerName: "John Fruto Ambal",
//   saadIdNo: "1",
//   completedCommodities: [
//     { typeOfCrop: "Carrot", farmgatePrice: "50", ... }
//   ],
//   trainings: [...]
// }
```

### Step 2: Display Record Details

```dart
Column(
  children: [
    Text('FCA: ${record.data['fcaName']}'),
    Text('Farmer: ${record.data['farmerName']}'),
    Text('SAAD ID: ${record.data['saadIdNo']}'),
    
    // Show commodities
    for (final commodity in record.data['completedCommodities'])
      ListTile(
        title: Text('${commodity['typeOfCrop']} - ${commodity['variety']}'),
        subtitle: Text('Price: ₱${commodity['farmgatePrice']}'),
      ),
    
    // Edit button
    ElevatedButton(
      onPressed: () => _openEdit(context),
      child: Text('EDIT'),
    ),
  ],
)
```

### Step 3: Open Edit Modal

```dart
void _openEdit(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => RecordEditModal(
        record: widget.record,
        isGroup: widget.record.implType.toLowerCase() == 'collective',
        isMemberEditOnly: widget.record.implType.toLowerCase() != 'collective',
      ),
    ),
  );
}
```

---

## ✏️ EDITING PENDING RECORD - EDIT MODAL

**File:** `record_edit_modal.dart`

### Step 1: Modal Opens with Current Data

```dart
// RecordEditModal receives pending record
class RecordEditModal extends StatefulWidget {
  const RecordEditModal({
    required this.record,        // Pending record from Firebase
    this.isMemberEditOnly = false,
    this.isGroup = false,
  });
}

// In _DynamicEditFormState.initState()
@override
void initState() {
  super.initState();
  
  // Load original data from record
  _originalData = Map<String, dynamic>.from(
      widget.record.data ?? const <String, dynamic>{});
  
  // Extract commodities
  _originalCommodityItems = (_originalData['completedCommodities'] as List?)
      ?.whereType<Map<String, dynamic>>()
      .toList() ?? [];
  
  // Extract trainings
  _originalTrainings = (_originalData['trainings'] as List?)
      ?.whereType<Map<String, dynamic>>()
      .toList() ?? [];
  
  print('🔍 Loaded ${_originalCommodityItems.length} commodities to edit');
}
```

### Step 2: Display Editable Fields

**For Collective Records:**
```dart
// Show commodity dropdown
_buildCommodityEditorSection(type);

// User can edit:
// - Commodity fields (variety, farmgate price, etc.)
// - Trainings attended
// - NOT: FCA name, region, province (group-level)
```

**For Individual/Hybrid Records:**
```dart
// Show commodity dropdown
_buildCommodityEditorSection(type);

// User can edit:
// - Commodity fields (variety, farmgate price, etc.)
// - Trainings attended
// - NOT: FCA name, region, farmer name (background fields)
```

### Step 3: Select Commodity to Edit

```dart
// Commodity selector dropdown
Padding(
  padding: const EdgeInsets.only(bottom: 16),
  child: DropdownButtonFormField<int>(
    initialValue: _selectedCommodityIndex,
    items: _originalCommodityItems.asMap().entries.map((entry) {
      final idx = entry.key;
      return DropdownMenuItem(
        value: idx,
        child: Text('Commodity ${idx + 1}'),
      );
    }).toList(),
    onChanged: (val) {
      if (val != null) {
        setState(() => _selectedCommodityIndex = val);
      }
    },
  ),
)
```

### Step 4: Edit Commodity Fields

```dart
// Show fields for selected commodity

_buildCommodityEditorSection(type):
  // For crop:
  //   - typeOfCrop
  //   - variety
  //   - farmgatePrice
  //   - totalLandArea
  //   - landOwnership
  //   - plantingDate
  //   - fertilizer types & costs
  //   - harvest dates & quantities
  //   - pest/disease damage info
  // For livestock:
  //   - breed
  //   - stocksReceived
  //   - maleStocks
  //   - femaleStocks
  //   - avgMarketableWeight
  //   - milkVolumeDaily
```

### Step 5: User Makes Changes

```
BEFORE:
  farmgatePrice: "50"
  totalLandArea: "1 hectare"

AFTER (User edited):
  farmgatePrice: "60"        ← CHANGED
  totalLandArea: "1.5 hectares"  ← CHANGED
```

---

## 💾 SAVING EDITS TO FIREBASE

**File:** `record_edit_modal.dart` - `saveChanges()` method

### Step 1: Check If Record is Pending

```dart
Future<void> saveChanges() async {
  setState(() => _isSaving = true);
  
  try {
    // Only save if this is a pending Firebase record
    if (!widget.record.isLocal && widget.record.status == 'pending') {
      print('🔥 Updating PENDING record on Firebase');
      print('   Record: ${widget.record.name}');
    } else {
      print('⚠️ Record is not pending or is local');
      return;
    }
```

### Step 2: Get Document Path

```dart
    // Get the Firebase document path
    final docPath = widget.record.documentPath;
    // docPath = 'pending_monitoring/janeirohAgriculture'
    // or for individual: 'pending_monitoring/janeirohAgriculture/members/1'
    
    if (docPath == null) {
      print('⚠️ No documentPath found');
      return;
    }
    
    final implementationType = 
        (widget.record.data?['implementationType'] as String? ?? '')
            .toLowerCase();
    print('   Implementation Type: $implementationType');
    print('   Document Path: $docPath');
```

### Step 3: Collect Changes

```dart
    // Prepare updates object with user's changes
    final updates = Map<String, dynamic>.from(_originalData);
    
    // Update with modified values from form
    for (final entry in _controllers.entries) {
      updates[entry.key] = entry.value.text.trim();
    }
    
    // Also update trainings if modified
    if (updates.containsKey('trainings')) {
      updates['trainings'] = _originalTrainings;
    }
    
    print('   📝 Collected ${updates.length} field changes');
```

### Step 4: COLLECTIVE - Update Firebase

```dart
    if (implementationType == 'collective') {
      final firestore = FirebaseFirestore.instance;
      final groupDocRef = firestore.doc(docPath);
      
      // Update group-level fields
      final groupUpdates = <String, dynamic>{
        'trainings': updates['trainings'] ?? [],
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      // Include any changed group fields
      const groupFields = {
        'reportingPeriod', 'fcaName', 'region', 'province',
        'municipality', 'barangay', 'projectTitle',
        'primaryIntervention', 'supportInterventions'
      };
      
      for (final field in groupFields) {
        if (updates.containsKey(field)) {
          groupUpdates[field] = updates[field];
        }
      }
      
      // Save group updates
      await groupDocRef.update(groupUpdates);
      print('   ✅ Updated group-level fields');
      
      // Update each commodity in subcollection
      if (_originalCommodityItems.isNotEmpty) {
        final type = widget.record.productionType.toLowerCase();
        
        for (var i = 0; i < _originalCommodityItems.length; i++) {
          final commodityData = _originalCommodityItems[i];
          final commodityId = (commodityData['id'] as String?) ?? '';
          
          if (commodityId.isNotEmpty) {
            final updatedCommodity = <String, dynamic>{};
            
            // Copy user's changed field values
            for (final field in _commodityFieldKeys) {
              final controller = _itemControllers['${type}_${i}_$field'];
              if (controller != null) {
                updatedCommodity[field] = controller.text.trim();
              }
            }
            
            updatedCommodity['updatedAt'] = FieldValue.serverTimestamp();
            
            // Save to Firestore
            await groupDocRef
                .collection('commodities')
                .doc(commodityId)
                .update(updatedCommodity);
            
            print('   ✅ Updated commodity: $commodityId');
          }
        }
      }
    }
```

### Step 5: INDIVIDUAL/HYBRID - Update Firebase

```dart
    else if (implementationType == 'individual' || 
             implementationType == 'hybrid') {
      
      final firestore = FirebaseFirestore.instance;
      
      // Extract IDs from path
      final groupDocId = docPath.split('/')[1];
      // From 'pending_monitoring/janeirohAgriculture/members/1'
      // groupDocId = 'janeirohAgriculture'
      
      final saadId = widget.record.data?['saadIdNo']?.toString() ?? '';
      // saadId = '1' or '1000p'
      
      if (groupDocId.isEmpty || saadId.isEmpty) {
        print('⚠️ Could not extract farmer IDs');
        return;
      }
      
      // Reference to farmer document
      final farmerDocRef = firestore
          .collection('pending_monitoring')
          .doc(groupDocId)
          .collection('members')
          .doc(saadId);
      
      // Update farmer-level fields
      final farmerUpdates = <String, dynamic>{
        'trainings': updates['trainings'] ?? [],
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (updates.containsKey('farmerName')) {
        farmerUpdates['farmerName'] = updates['farmerName'];
      }
      
      await farmerDocRef.update(farmerUpdates);
      print('   ✅ Updated farmer-level fields');
      
      // Update each commodity in farmer's subcollection
      if (_originalCommodityItems.isNotEmpty) {
        final type = widget.record.productionType.toLowerCase();
        
        for (var i = 0; i < _originalCommodityItems.length; i++) {
          final commodityData = _originalCommodityItems[i];
          final commodityId = (commodityData['id'] as String?) ?? '';
          
          if (commodityId.isNotEmpty) {
            final updatedCommodity = <String, dynamic>{};
            
            for (final field in _commodityFieldKeys) {
              final controller = _itemControllers['${type}_${i}_$field'];
              if (controller != null) {
                updatedCommodity[field] = controller.text.trim();
              }
            }
            
            updatedCommodity['updatedAt'] = FieldValue.serverTimestamp();
            
            await farmerDocRef
                .collection('commodities')
                .doc(commodityId)
                .update(updatedCommodity);
            
            print('   ✅ Updated farmer commodity: $commodityId');
          }
        }
      }
    }
```

### Step 6: Show Success Message

```dart
    if (!mounted) return;
    
    // Close the modal
    Navigator.pop(context);
    
    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Changes saved!'),
        backgroundColor: DAColors.greenMid,
      ),
    );
    
    print('✅ ALL CHANGES SAVED TO FIREBASE');
    
  } catch (firebaseError) {
    print('❌ Firebase error: $firebaseError');
    
    // Show error to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error saving changes: $firebaseError'),
        backgroundColor: Colors.red,
      ),
    );
    
  } finally {
    if (mounted) {
      setState(() => _isSaving = false);
    }
  }
}
```

---

## 🔄 WHAT HAPPENS AFTER EDIT

### Firebase Update Cycle

```
BEFORE EDIT (Firebase):
{
  fcaName: "janeirohAgriculture",
  farmerName: "John Fruto Ambal",
  completedCommodities: [
    {
      typeOfCrop: "Carrot",
      farmgatePrice: "50",      ← OLD VALUE
      totalLandArea: "1 hectare"  ← OLD VALUE
    }
  ],
  updatedAt: 2026-05-14T10:00:00
}

USER EDITS & SAVES:
  farmgatePrice: "50" → "60"
  totalLandArea: "1 hectare" → "1.5 hectares"

AFTER EDIT (Firebase):
{
  fcaName: "janeirohAgriculture",
  farmerName: "John Fruto Ambal",
  completedCommodities: [
    {
      typeOfCrop: "Carrot",
      farmgatePrice: "60",       ← NEW VALUE ✅
      totalLandArea: "1.5 hectares"  ← NEW VALUE ✅
    }
  ],
  updatedAt: 2026-05-14T11:30:00  ← UPDATED
}
```

### User Sees Updated Record

1. Edit modal closes
2. User returns to HomeScreen
3. Pending record still shows but with updated values
4. Approver will see latest changes when reviewing

### No Record Duplication

- ✅ Same Firebase document updated (not replaced)
- ✅ `documentId` stays same
- ✅ `createdAt` timestamp unchanged
- ✅ `updatedAt` timestamp updated to now
- ✅ History preserved in Firestore version history (if enabled)

---

## ⚠️ FIELDS NOT EDITABLE

**Important:** Some fields are READ-ONLY after record is created:

```dart
// NOT editable (background/context fields):
// - fcaName (group name)
// - reportingPeriod
// - region, province, municipality, barangay
// - projectTitle
// - primaryIntervention (main crop focus)

// ARE editable (commodity/training data):
// ✅ Commodity fields (variety, farmgate price, land area, etc.)
// ✅ Trainings (attended trainings)
// ✅ Farmer name (for individual/hybrid)
```

---

## 🔑 Key Points for Editing Pending Records

1. **Status must be "pending":** Can't edit approved/rejected records
2. **Network required:** Must have internet to save to Firebase
3. **Real-time sync:** Changes appear immediately in Firebase
4. **Timestamps updated:** `updatedAt` changes to current time
5. **One commodity at a time:** Dropdown to select which commodity to edit
6. **Trainings editable:** Can add/edit training information
7. **Approver sees updates:** Reviewer will see latest edited data
8. **Non-destructive:** Old values preserved in Firebase version history


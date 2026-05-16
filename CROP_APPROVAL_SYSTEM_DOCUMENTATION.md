# CROP Approval & Editing System - Complete Documentation

## Overview
The Crop monitoring module now has a complete approval workflow with role-based editing permissions. This document explains how it works so you can replicate it for Poultry and Livestock.

---

## 1. User Roles & Permissions

### Role Hierarchy
- **Profiler**: Creates records, can only edit their own pending/unsync records (NOT approved)
- **Moderator**: Reviews and approves records, can edit group and farmer records when approved
- **Admin**: Same permissions as Moderator - can approve and edit records

### Permission Summary Table

| Action | Profiler | Moderator | Admin |
|--------|----------|-----------|-------|
| Create record | ✅ | ✅ | ✅ |
| Edit own pending record | ✅ | ✅ | ✅ |
| Edit own approved record | ❌ | ✅ | ✅ |
| View pending records | ✅ | ✅ | ✅ |
| Approve pending records | ❌ | ✅ | ✅ |
| Decline pending records | ❌ | ✅ | ✅ |
| Edit group records | ❌ | ✅ | ✅ |

---

## 2. Record Status Flow

```
unsync → pending → approved
  ↓
declined (deleted)
```

### Status Definitions
- **unsync**: Record exists locally, not yet synced to Firebase
- **pending**: Synced to Firebase, waiting for moderator/admin approval
- **approved**: Approved by moderator/admin, locked from changes (except by moderators/admins)
- **declined**: Rejected by moderator/admin, deleted from Firebase

---

## 3. Button Visibility Logic

### For Group/FCA Records (Collective Records)

#### When Status = `unsync` or `pending`
- **Edit Button**: ❌ Hidden
- **Sync Button**: ✅ Visible (to sync locally to Firebase)
- **Approve Button**: Visible but LOCKED for non-moderators/admins
- **Decline Button**: Visible but LOCKED for non-moderators/admins

**Code Location**: [member_records_screen.dart](member_records_screen.dart#L1832-L1845)
```dart
showEdit: (widget.record.status == 'approved' && (isModerator || isAdmin)),
showSync: widget.record.status == 'unsync' || widget.record.status == 'pending',
showApprove: widget.record.status == 'pending' && (isModerator || isAdmin),
approveLocked: widget.record.status == 'pending' && !(isModerator || isAdmin),
```

#### When Status = `approved`
- **Edit Button**: ✅ Visible ONLY for moderators/admins
- **Sync Button**: ❌ Hidden
- **Approve Button**: ❌ Hidden
- **Decline Button**: ❌ Hidden

---

### For Farmer/Individual Records

#### When Status = `pending` or `approved`
**For Profilers (Farmers)**:
- **Edit Button**: ✅ ALWAYS visible
- **Approve Button**: ❌ Hidden (locked display, not clickable)
- **Decline Button**: ❌ Hidden

**For Moderators/Admins**:
- **Edit Button**: ✅ Visible
- **Approve Button**: ✅ Visible (when pending)
- **Decline Button**: ✅ Visible (when pending)

**Code Location**: [member_records_screen.dart](member_records_screen.dart#L1586-L1615)
```dart
showEdit: true,  // ✅ Always visible for farmers
showApprove: memberRecord.record.status == 'pending' && (isModerator || isAdmin),
approveLocked: memberRecord.record.status == 'pending' && !(isModerator || isAdmin),
```

---

## 4. Button Logic in RecordViewModal

**File**: [record_view_modal.dart](record_view_modal.dart)

### Button Display Conditions

#### Condition 1: Farmer on Locked Record (Line 247-258)
When `isMemberEditOnly=true` AND `approveLocked=true` AND `showEdit=true`:
- Shows ONLY the **Edit** button
- Farmers can edit their commodity data even if locked from approval

```dart
if (isMemberEditOnly && (approveLocked || showApprove) && showEdit) {
  return Container(
    child: Row(children: [
      Expanded(child: _ActionBtn(label: 'Edit', ...))
    ]),
  );
}
```

#### Condition 2: Regular Viewing (Line 210-222)
When `showEdit=true` AND NOT syncing/approving:
- Shows ONLY the **Edit** button
- Used for approved moderator/admin viewing

```dart
if (showEdit && !showSync && !showApprove && !approveLocked) {
  return Container(
    child: Row(children: [
      Expanded(child: _ActionBtn(label: 'Edit', ...))
    ]),
  );
}
```

#### Condition 3: Approve/Decline Actions (Line 247+)
When `showApprove=true` OR `approveLocked=true` AND NOT member-only:
- Shows **Approve**, **Edit**, **Decline** buttons
- Edit is locked/unavailable if `approveLocked=true`
- All buttons locked with message "Moderators and Admins only" if `approveLocked=true`

```dart
if ((showApprove || approveLocked) && !isMemberEditOnly) {
  return Container(
    child: Row(children: [
      _LockedBtn(label: 'Approve', locked: approveLocked, ...),
      _LockedBtn(label: 'Edit', locked: approveLocked, ...),
      _LockedBtn(label: 'Decline', locked: approveLocked, ...),
    ]),
  );
}
```

---

## 5. Data Persistence & Firebase Structure

### Three-Level Hierarchy in Firestore

```
pending_monitoring/
├── {groupId}/                    # FCA/Group document
│   ├── name, location, ...       # Group fields
│   └── members/                  # Subcollection
│       └── {saadId}/             # Individual farmer
│           ├── name, ...         # Farmer fields
│           └── commodities/      # Farmer's commodities
│               └── {commodityId}/
│                   ├── cropName, quantity, ...

approved_monitoring/
└── Same structure as pending_monitoring
```

### When Farmer Edits Record

**Location**: [record_edit_modal.dart](record_edit_modal.dart#L868+)

For **Individual/Hybrid** implementation:
```dart
// Extract groupDocId and saadId from record
final groupDocId = record.documentPath.split('/')[1];  // pending_monitoring/{groupId}
final saadId = record.data['saadIdNo'];

// Update farmer's commodities
await _firestore
    .collection('pending_monitoring')
    .doc(groupDocId)
    .collection('members')
    .doc(saadId)
    .collection('commodities')
    .doc(commodityId)
    .set(updatedCommodityData, SetOptions(merge: true));
```

### When Moderator/Admin Approves Record

**Location**: [monitoring_record_service.dart](monitoring_record_service.dart#L1527+)

```dart
Future<void> approveRecord({
  required String recordId,
  required bool isModerator,
  required bool isAdmin,
})
```

Process:
1. ✅ Check role permission: `if (!isModerator && !isAdmin) throw Exception(...)`
2. ✅ Copy LEVEL 1: Group/FCA document to `approved_monitoring/{groupId}`
3. ✅ Copy LEVEL 2 & 3: All members and their commodities
4. ✅ Delete entire hierarchy from `pending_monitoring`
5. ✅ Set `approvalStatus`, `approvedBy`, `approvedAt` fields

---

## 6. Implementation Summary for Poultry/Livestock

To implement the same system for Poultry and Livestock:

### Key Files to Create/Modify:

1. **Screen File** (like `member_records_screen.dart`):
   - Create farmer/member record view modal with:
     - `showEdit: true` (always show edit for farmers)
     - `showApprove: status == 'pending' && (isModerator || isAdmin)`
     - `approveLocked: status == 'pending' && !(isModerator || isAdmin)`
   - Create group record view modal with:
     - `showEdit: status == 'approved' && (isModerator || isAdmin)`
     - `showSync: status == 'unsync' || status == 'pending'`
     - `showApprove: status == 'pending' && (isModerator || isAdmin)`

2. **Edit Modal** (like `record_edit_modal.dart`):
   - Implement `saveChanges()` method with three-branch logic:
     - **COLLECTIVE**: Update group commodities
     - **INDIVIDUAL/HYBRID**: Extract groupDocId and saadId, update farmer commodities

3. **Service** (like `monitoring_record_service.dart`):
   - Implement `approveRecord()`: Copy all levels from pending → approved
   - Implement `declineRecord()`: Delete entire hierarchy from pending
   - Implement `fetchApprovedRecords()`: Fetch with proper member/commodity hierarchy

4. **View Modal** (like `record_view_modal.dart`):
   - Implement button logic conditions as shown in Section 4
   - Key condition: If `isMemberEditOnly && (approveLocked || showApprove) && showEdit` → show ONLY Edit button

### Role Checks
Always use: `(isModerator || isAdmin)` NOT just `isModerator`

---

## 7. Field Names & Data Keys

### Required Fields in Record Data:
- `status`: 'unsync' | 'pending' | 'approved' | 'declined'
- `implType`: 'collective' | 'individual' | 'hybrid'
- `saadIdNo`: Farmer ID (for individual/hybrid)
- `documentPath`: Firebase path (e.g., 'pending_monitoring/{groupId}')
- `implementationType`: Full type name

### Updated Fields on Approval:
- `approvalStatus`: 'approved'
- `approvedBy`: Current user UID
- `approvedAt`: Server timestamp
- `updatedAt`: Server timestamp

---

## 8. Testing Checklist

### Profiler (Non-Moderator) View:
- [ ] Pending group record: Sees locked Approve/Decline buttons
- [ ] Pending farmer record: Sees Edit button (not locked)
- [ ] Approved farmer record: Sees Edit button
- [ ] Approved group record: No Edit button visible

### Moderator/Admin View:
- [ ] Pending group record: Sees unlocked Approve/Decline buttons
- [ ] Pending group record: Can click Approve to move to approved_monitoring
- [ ] Approved group record: Sees Edit button (not locked)
- [ ] Approved farmer record: Sees Edit button
- [ ] Farmer record edit: Can edit commodity data
- [ ] Group record edit: Can edit all fields

### Data Persistence:
- [ ] Farmer edits pending record → saved to pending_monitoring/{groupId}/members/{saadId}/commodities
- [ ] Farmer edits approved record → saved to approved_monitoring/{groupId}/members/{saadId}/commodities
- [ ] Moderator approves pending → all data copied to approved_monitoring, deleted from pending_monitoring
- [ ] Moderator declines pending → all data deleted from pending_monitoring

---

## 9. Code References

| Feature | File | Lines |
|---------|------|-------|
| Farmer record buttons | [member_records_screen.dart](member_records_screen.dart#L1586-L1615) | 1586-1615 |
| Group record buttons | [member_records_screen.dart](member_records_screen.dart#L1820-L1860) | 1820-1860 |
| Button display logic | [record_view_modal.dart](record_view_modal.dart#L210-280) | 210-280 |
| Farmer edit logic | [record_view_modal.dart](record_view_modal.dart#L247-258) | 247-258 |
| Firebase save | [record_edit_modal.dart](record_edit_modal.dart#L868+) | 868+ |
| Approve record | [monitoring_record_service.dart](monitoring_record_service.dart#L1527+) | 1527+ |
| Decline record | [monitoring_record_service.dart](monitoring_record_service.dart#L1650+) | 1650+ |

---

## Summary

✅ **Crop System Complete Features**:
1. Three-level Firebase hierarchy (Group → Members → Commodities)
2. Role-based editing (Farmers can edit own, Moderators/Admins can edit approved)
3. Smart button visibility (Locked approve buttons for non-moderators)
4. Farmer edit allowed on approved records
5. Proper data persistence across all status transitions
6. Admin role properly integrated (no longer moderator-only)

Ready to apply to Poultry and Livestock! 🚀

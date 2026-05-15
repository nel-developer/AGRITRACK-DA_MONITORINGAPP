# 🎯 COMPLETE SYSTEM OVERVIEW - Architecture Summary

## 📚 Documentation Map

This document provides a complete overview of all documentation and how it relates to each other.

---

## 🔍 Architecture Layers

### Layer 1: Data Storage (Foundation)
**Files:** 
- [1_DATA_STRUCTURE.md](1_DATA_STRUCTURE.md)
- [2_SAVING_FLOW.md](2_SAVING_FLOW.md)
- [10_PHOTO_GPS_SYSTEM.md](10_PHOTO_GPS_SYSTEM.md)

**What:** Where and how your data is organized
- **Local Device:** `/storage/.../crop/{groupName}/{farmerFolder}/data.json`
- **Metadata:** Photos with GPS coordinates encoded in filename
- **Format:** JSON files with hierarchical structure

---

### Layer 2: Implementation Types (Your Choice)
Pick ONE of these based on your needs:

#### A. Collective Implementation
**File:** [8_COLLECTIVE_FLOW.md](8_COLLECTIVE_FLOW.md)

**Structure:**
```
FCA Group (e.g., janeirohAgriculture)
└── Single data.json at group level
    ├── Commodities: [Group Commodity 1, Group Commodity 2]
    └── Trainings: [Group Training 1, Group Training 2]
```

**Key Points:**
- One FCA = One set of commodities
- All commodities belong to group
- No individual farmer separation
- Best for: Community gardens, shared plantations

**Files Involved:**
- `step_01_project_background.dart` → Creates group.json
- `step_02_commodity_information.dart` → Adds commodities to group
- `step_07_trainings.dart` → Final save to data.json

#### B. Individual Implementation
**File:** [9_INDIVIDUAL_HYBRID_FLOW.md](9_INDIVIDUAL_HYBRID_FLOW.md)

**Structure:**
```
FCA Group (e.g., janeirohAgriculture)
├── group.json (shared FCA info)
├── Farmer 1 (e.g., John Fruto Ambal)
│   └── data.json → [His Commodity 1, His Commodity 2]
└── Farmer 2 (e.g., Maribel Oflaria)
    └── data.json → [Her Commodity 1, Her Commodity 2]
```

**Key Points:**
- One FCA = Multiple farmers
- Each farmer has SEPARATE commodities
- Farmer SAAD ID used as identifier
- Best for: Farmer associations, co-ops

**Process:**
1. Create group with implementation type = "individual"
2. Add farmers (creates folders)
3. For each farmer, add their commodities
4. Each farmer's data isolated

#### C. Hybrid Implementation
**File:** [9_INDIVIDUAL_HYBRID_FLOW.md](9_INDIVIDUAL_HYBRID_FLOW.md)

**Structure:**
```
FCA Group (e.g., janeirohAgriculture)
├── GROUP-level commodities (in group.json)
├── Farmer 1
│   └── data.json → [His Commodity 1, His Commodity 2]
└── Farmer 2
    └── data.json → [Her Commodity 1]
```

**Key Points:**
- Mix of collective AND individual
- Some commodities at group level
- Some commodities at farmer level
- Best for: Mixed operations

---

### Layer 3: Special Systems

#### Photo & GPS Capture
**File:** [10_PHOTO_GPS_SYSTEM.md](10_PHOTO_GPS_SYSTEM.md)

**Flow:**
```
User clicks camera button
    ↓
Camera opens (requests permissions)
    ↓
GPS coordinates captured in background
    ↓
User takes photo
    ↓
Preview shows GPS: 14.5123°N, 121.0234°E
    ↓
Photo filename: crops_Carrot_14.5123_121.0234.jpg
    ↓
Saved locally with GPS in EXIF + JSON
```

**Key Features:**
- Automatic GPS capture (when location permission granted)
- Dual storage: EXIF metadata + JSON backup
- Filename encodes coordinates
- Used to verify commodity location

**Code Locations:**
- `step_07_trainings.dart` - Photo capture UI
- `_getCurrentLocation()` - GPS retrieval
- `_savePhotoWithLocation()` - Photo + GPS save

---

### Layer 4: Firebase Synchronization
**File:** [11_FIREBASE_SYNC.md](11_FIREBASE_SYNC.md)

**Status Flow:**
```
UNSYNC (Local only)
    ↓ User syncs or app auto-syncs
PENDING (On Firebase, awaiting approval)
    ↓ Approver reviews
APPROVED (Accepted by admin)
    ↓ or
REJECTED (Sent back for fixes)
```

**Upload Process:**
```
Local data.json
    ↓
[SYNC PROCESS]
    ↓
Firebase Firestore
    pending_monitoring/
    ├── {groupId}/                          (Collective)
    └── {groupId}/members/{saadId}/         (Individual/Hybrid)
```

**When Sync Happens:**
- **Automatic:** App checks on startup
- **Manual:** User clicks "Sync Now"
- **Required:** Internet connection

**Code Locations:**
- `home_screen.dart` - Auto-sync check
- `monitoring_record_service.dart` - Sync logic
- `syncPendingLocalRecords()` - Main sync function

---

### Layer 5: Editing Pending Records
**File:** [12_EDITING_PENDING.md](12_EDITING_PENDING.md)

**Flow:**
```
HomeScreen shows "Pending Approval" record
    ↓
User clicks "EDIT"
    ↓
RecordEditModal opens with current Firebase data
    ↓
User changes commodity fields (variety, price, etc.)
    ↓
User clicks "SAVE"
    ↓
Changes synced back to Firebase
    ↓
Approver sees updated record
```

**Editable vs. Read-Only:**
```
EDITABLE:
✅ Commodity fields (variety, farmgate price, land area, etc.)
✅ Trainings attended
✅ Farmer name (individual/hybrid only)

NOT EDITABLE (Background fields):
❌ FCA name
❌ Region, province, municipality, barangay
❌ Reporting period
❌ Primary intervention
```

**Code Locations:**
- `record_view_modal.dart` - Display pending record
- `record_edit_modal.dart` - Edit form
- `saveChanges()` - Save edits to Firebase
- Separate handlers for Collective vs Individual/Hybrid

---

## 🗺️ Complete Data Journey

### Example: John Adds 2 Commodities (Individual Implementation)

```
┌─────────────────────────────────────────────────────────┐
│ STEP 1: Local Entry                                     │
│ John fills 7 steps on his phone                         │
│ → data.json created locally                            │
│ Status: UNSYNC ✓                                       │
└─────────────────────────────────────────────────────────┘
              ↓
          [See: 2_SAVING_FLOW.md]
              ↓
┌─────────────────────────────────────────────────────────┐
│ STEP 2: Photo Capture                                  │
│ John takes photo of commodities                        │
│ → crops_Carrot_14.51_121.02.jpg saved                 │
│ → GPS embedded in EXIF and JSON ✓                     │
└─────────────────────────────────────────────────────────┘
          [See: 10_PHOTO_GPS_SYSTEM.md]
              ↓
┌─────────────────────────────────────────────────────────┐
│ STEP 3: Auto-Sync Detection                            │
│ App opens, detects unsync records                      │
│ → Automatically starts sync process ✓                 │
└─────────────────────────────────────────────────────────┘
          [See: 11_FIREBASE_SYNC.md]
              ↓
┌─────────────────────────────────────────────────────────┐
│ STEP 4: Upload to Firebase                             │
│ data.json uploaded to Firestore                        │
│ → pending_monitoring/janeirohAgriculture/members/1/    │
│ → 2 commodities in subcollection ✓                    │
│ Status: PENDING                                        │
└─────────────────────────────────────────────────────────┘
          [See: 11_FIREBASE_SYNC.md]
              ↓
┌─────────────────────────────────────────────────────────┐
│ STEP 5: Approver Reviews                               │
│ Approver sees pending record on dashboard              │
│ → Notices John's carrot price seems low                │
└─────────────────────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────────────────┐
│ STEP 6: John Edits                                     │
│ John opens HomeScreen, sees "Pending" record           │
│ → Clicks EDIT                                          │
│ → Changes carrot price: 50 → 60 ✓                    │
│ → Changes coconut variety: Tall → Dwarf ✓            │
│ → Clicks SAVE                                          │
│ → Changes sync back to Firebase ✓                     │
└─────────────────────────────────────────────────────────┘
          [See: 12_EDITING_PENDING.md]
              ↓
┌─────────────────────────────────────────────────────────┐
│ STEP 7: Approver Reviews Updated Record                │
│ Approver sees updated prices                           │
│ → Approves John's record ✓                            │
│ → Record status: APPROVED                              │
└─────────────────────────────────────────────────────────┘
              ↓
        ✅ COMPLETE
```

---

## 📊 File Organization Reference

```
project_root/
└── lib/screens/data/
    ├── record_edit_modal.dart        ← Editing pending records
    ├── record_view_modal.dart        ← Viewing records
    ├── member_records_screen.dart    ← Showing farmer list
    └── step_XX_*.dart                ← Individual step screens

project_root/
└── lib/services/
    ├── monitoring_record_service.dart    ← Sync & Firebase operations
    ├── pending_draft_service.dart        ← Local storage operations
    └── geolocator                        ← GPS coordinates

device_storage/
└── /storage/.../crop/
    ├── {groupName}/
    │   ├── group.json                    ← Collective: group data
    │   ├── data.json                     ← Collective: commodities
    │   └── {farmerName}/                 ← Individual/Hybrid: farmer folders
    │       ├── data.json                 ← Individual/Hybrid: farmer's commodities
    │       └── crops_*.jpg               ← Photos with GPS in filename

firebase/
└── pending_monitoring/
    ├── {groupId}/                        ← Collective path
    │   ├── completedCommodities: [...]
    │   ├── trainings: [...]
    │   └── commodities/                  ← Subcollection
    │       └── {commodityId}/            ← Individual commodity docs
    │
    └── {groupId}/members/{saadId}/       ← Individual/Hybrid path
        ├── completedCommodities: [...]
        ├── trainings: [...]
        └── commodities/                  ← Subcollection
            └── {commodityId}/            ← Individual farmer's commodities
```

---

## 🔑 Key Concepts

### Record Status
- `unsync` = On device only, not yet on server
- `pending` = On Firebase, waiting for approval
- `approved` = Approved by admin, finalized
- `rejected` = Needs corrections, sent back

### Implementation Type
- `collective` = Group-level tracking (one set of commodities)
- `individual` = Farmer-level tracking (separate farmer data)
- `hybrid` = Mix of both

### Document Path Pattern
- **Collective:** `pending_monitoring/{groupId}`
- **Individual/Hybrid:** `pending_monitoring/{groupId}/members/{saadId}`

### SAAD ID
- Unique identifier for each farmer
- Can be "1", "2", "1000p", etc.
- Used as subcollection key in Firebase

---

## 🚀 Quick Navigation

### Need to understand...?

| Topic | File |
|-------|------|
| Where data goes | [1_DATA_STRUCTURE.md](1_DATA_STRUCTURE.md) |
| How data saved locally | [2_SAVING_FLOW.md](2_SAVING_FLOW.md) |
| Collective groups | [8_COLLECTIVE_FLOW.md](8_COLLECTIVE_FLOW.md) |
| Individual/Hybrid groups | [9_INDIVIDUAL_HYBRID_FLOW.md](9_INDIVIDUAL_HYBRID_FLOW.md) |
| Photos & GPS | [10_PHOTO_GPS_SYSTEM.md](10_PHOTO_GPS_SYSTEM.md) |
| Sync to Firebase | [11_FIREBASE_SYNC.md](11_FIREBASE_SYNC.md) |
| Editing pending records | [12_EDITING_PENDING.md](12_EDITING_PENDING.md) |
| Visual diagrams | [6_COMPLETE_FLOW_DIAGRAM.md](6_COMPLETE_FLOW_DIAGRAM.md) |
| Quick reference | [7_KEY_POINTS.md](7_KEY_POINTS.md) |

---

## ✅ Verification Checklist

After reading the documentation, you should understand:

- [ ] Where local crop data is stored (`/storage/.../crop/`)
- [ ] Difference between group.json and data.json
- [ ] Three implementation types (Collective, Individual, Hybrid)
- [ ] How commodities are structured for each type
- [ ] How photos are captured with GPS
- [ ] How GPS is embedded in photo filenames
- [ ] When and how sync to Firebase happens
- [ ] Status transitions (unsync → pending → approved)
- [ ] How to edit pending records
- [ ] What fields can be edited after creation
- [ ] Firestore paths for different implementation types
- [ ] How SAAD ID is used in Firebase

If you understand all of these, you have a complete grasp of the system! ✅


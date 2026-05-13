# 4️⃣ ADDING ANOTHER FARMER - Complete Process

## 👥 How Adding a Farmer Works

**File:** `step_01_project_background.dart`

**User Action:** Click "Add Farmer" button on Step 01

---

## 🔄 Step-by-Step Process

### Step 1: User Fills Project Background & Clicks "Add Farmer"

```
UI Screen:
┌─────────────────────────────┐
│ FCA Name: janeirohAgriculture│
│ Region: Region IV-A         │
│ Province: Batangas          │
│ ...                         │
│ [Add Farmer] [Next] [Back]  │
└─────────────────────────────┘

User clicks [Add Farmer]
```

### Step 2: New Farmer Added to Members Array

```dart
// Inside step_01_project_background.dart

final groupData = {
  'fcaName': 'janeirohAgriculture',
  'implementationType': 'individual',
  'reportingPeriod': '2026',
  'region': 'Region IV-A (CALABARZON)',
  'province': 'Batangas',
  'municipality': 'Lipa City',
  'barangay': 'Barangay 2',
  'primaryIntervention': 'Coconut',
  'supportInterventions': ['idk'],
  
  // Members array UPDATED
  'members': [
    {'name': 'John Fruto Ambal', 'saadIdNo': '1'},
    {'name': 'Maribel Oflaria Baltazar', 'saadIdNo': '1000p'}  // ← NEW!
  ]
};
```

### Step 3: Update group.json in File System

```dart
// Write updated group.json with new member
File('/storage/.../crop/janeirohAgriculture/group.json')
  .writeAsString(jsonEncode(groupData));
```

**Result:**
```
Before: members.length = 1 (only John)
After:  members.length = 2 (John + Maribel)
```

### Step 4: Create New Farmer Directory (Auto-created on first save)

When Maribel fills her data on Steps 02-07, Step 07 triggers:

```dart
// step_07_trainings.dart - First save
// Creates directory structure automatically

Directory('/storage/.../crop/janeirohAgriculture/Maribel_Oflaria_Baltazar/')
  .create(recursive: true);
```

**Result:**
```
/storage/emulated/0/Android/data/com.example.da_monitoring_app/files/monitoring_records/crop/
│
└── janeirohAgriculture/
    ├── group.json (ALREADY EXISTS, just updated)
    ├── John_Fruto_Ambal/
    │   ├── data.json
    │   └── crops_Carrot_14.5123_121.0234.jpg
    │
    └── Maribel_Oflaria_Baltazar/  ← NEW FOLDER
        ├── data.json              ← NEW FILE
        └── crops_Coconut_14.5789_121.0890.jpg  ← NEW FILE
```

---

## 📋 What Gets Shared vs. What's New

### Shared (NOT duplicated):
```
group.json
├─ fcaName: janeirohAgriculture
├─ reportingPeriod: 2026
├─ region: Region IV-A
├─ province: Batangas
├─ municipality: Lipa City
├─ barangay: Barangay 2
├─ projectTitle: agriculture
├─ primaryIntervention: Coconut
└─ members: [John, Maribel]  ← Array updated

Both farmers see SAME project background!
```

### NEW for Each Farmer:
```
John's data.json                    Maribel's data.json
├─ farmerName: John...            ├─ farmerName: Maribel...
├─ saadIdNo: 1                    ├─ saadIdNo: 1000p
├─ completedCommodities: [...]    ├─ completedCommodities: [...]
├─ trainings: [...]               ├─ trainings: [...]
└─ photos: crops_...jpg           └─ photos: crops_...jpg

Each farmer has SEPARATE data!
```

---

## 🔍 How the System Knows About New Farmers

### When Viewing the Group:

```dart
// member_records_screen.dart - _loadMembers()

// Read group.json
final groupData = jsonDecode(groupJsonFile.readAsStringSync());

// Get members from array
final members = groupData['members'] as List;
// Result: [
//   {'name': 'John Fruto Ambal', 'saadIdNo': '1'},
//   {'name': 'Maribel Oflaria Baltazar', 'saadIdNo': '1000p'}
// ]

// Load data for EACH member
for (final member in members) {
  final farmerDir = '/storage/.../janeirohAgriculture/${member['name']}/';
  
  // Load John's data.json
  // Load Maribel's data.json
}

// Display both farmers in member list
```

---

## 🎯 Key Sequence

```
Add Farmer on Step 01
        ↓
Update group.json with new member in members array
        ↓
Save to: group.json
        ↓
New farmer fills Steps 02-07
        ↓
On Step 07 save:
  ├─ Create farmer directory
  ├─ Save farmer's data.json
  ├─ Save farmer's photos
  └─ Farmer folder appears on disk
        ↓
Next time viewing group:
  ├─ Reads group.json
  ├─ Finds 2 members in array
  └─ Displays both farmers
```

---

## 🚨 Important Rules

### Farmer Identification:
```dart
// Farmer ID is based on SAAD ID (if available)
final uniqueKey = actualSaadId.isNotEmpty
    ? actualSaadId
    : '${actualFarmerName}_${widget.record.data?.hashCode}';
```

**Why?** Multiple farmers might have same name. SAAD ID is unique.

---

## 💾 Filesystem View: Before and After Adding Farmer

### BEFORE: Only John
```
crop/janeirohAgriculture/
├── group.json (members: [John])
└── John_Fruto_Ambal/
    ├── data.json
    └── crops_Carrot_14.5123_121.0234.jpg
```

### AFTER: John + Maribel
```
crop/janeirohAgriculture/
├── group.json (members: [John, Maribel])  ← UPDATED
├── John_Fruto_Ambal/                      ← UNCHANGED
│   ├── data.json
│   └── crops_Carrot_14.5123_121.0234.jpg
└── Maribel_Oflaria_Baltazar/              ← NEW
    ├── data.json
    └── crops_Coconut_14.5789_121.0890.jpg
```

---

## ✅ Key Takeaway

```
Adding a farmer is a 3-step process:

1. UPDATE group.json
   └─ Add new member to members array

2. Create farmer directory
   └─ Happens automatically on Step 07 save

3. Separate data storage
   └─ Each farmer has own data.json + photos

Result: Both farmers share project background,
        but have separate commodities data
```

---

**Next:** Read [5_ADDING_COMMODITY.md](5_ADDING_COMMODITY.md) to understand how adding commodities works

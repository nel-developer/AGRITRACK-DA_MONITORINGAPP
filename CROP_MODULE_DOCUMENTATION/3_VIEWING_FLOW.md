# 3️⃣ VIEWING FLOW - How Data is Displayed

## 👁️ Two Viewing Modes

Your crop data can be viewed in two ways:
1. **View a Group** - See all farmers and their commodities together
2. **View a Specific Farmer** - See only one farmer's complete data with project background

---

## 🏢 Viewing a Group

**File:** `member_records_screen.dart`

**What Happens:**
1. User navigates to Data Screen
2. Selects group "janeirohAgriculture"
3. `MemberRecordsScreen` opens

**Process:**

### Step 1: Load Group.json
```dart
// Load project background ONCE for entire group
File groupJsonPath = File(
  '/storage/.../crop/janeirohAgriculture/group.json'
);
Map<String, dynamic> groupData = jsonDecode(groupJsonPath.readAsStringSync());

// Extract group info:
{
  'fcaName': 'janeirohAgriculture',
  'reportingPeriod': '2026',
  'region': 'Region IV-A',
  'province': 'Batangas',
  'municipality': 'Lipa City',
  'barangay': 'Barangay 2',
  'primaryIntervention': 'Coconut'
}
```

### Step 2: Get List of All Farmers
```dart
// From group.json members array
'members': [
  {'name': 'John Fruto Ambal', 'saadIdNo': '1'},
  {'name': 'Maribel Oflaria Baltazar', 'saadIdNo': '1000p'}
]
```

### Step 3: Load Each Farmer's data.json
```dart
// For John Fruto Ambal
File('/storage/.../crop/janeirohAgriculture/John_Fruto_Ambal/data.json')

// For Maribel Oflaria Baltazar
File('/storage/.../crop/janeirohAgriculture/Maribel_Oflaria_Baltazar/data.json')
```

### Step 4: Display Member List
```
📱 Display:
┌─────────────────────────────────┐
│ janeirohAgriculture             │
├─────────────────────────────────┤
│ ✓ John Fruto Ambal      unsync  │
│   1 commodities                 │
│                                 │
│ ✓ Maribel Oflaria...    unsync  │
│   1 commodity                   │
└─────────────────────────────────┘
```

---

## 👤 Viewing a Specific Farmer

**File:** `record_view_modal.dart`

**What Happens:**
1. User clicks on farmer "John Fruto Ambal"
2. `MemberRecordsScreen._viewMember()` is called
3. Modal opens showing John's complete data

### 🔄 The Critical Data Merge Process

**This is the KEY to your app!**

#### Step 1: Load FRESH group.json (Project Background)
```dart
// Lines 687-707 in member_records_screen.dart

File groupJsonPath = File(
  '/storage/.../crop/janeirohAgriculture/group.json'
);

Map<String, dynamic> freshGroupData = 
  jsonDecode(groupJsonPath.readAsStringSync());

// Result:
{
  'fcaName': 'janeirohAgriculture',
  'reportingPeriod': '2026',
  'region': 'Region IV-A (CALABARZON)',
  'province': 'Batangas',           // ← Missing before, now added!
  'municipality': 'Lipa City',      // ← Missing before, now added!
  'barangay': 'Barangay 2',         // ← Missing before, now added!
  'projectTitle': 'agriculture',
  'primaryIntervention': 'Coconut', // ← Missing before, now added!
  'supportInterventions': ['idk']   // ← Missing before, now added!
}
```

#### Step 2: Load Farmer's data.json (Commodities)
```dart
File farmerDataPath = File(
  '/storage/.../crop/janeirohAgriculture/John_Fruto_Ambal/data.json'
);

Map<String, dynamic> farmerData = 
  jsonDecode(farmerDataPath.readAsStringSync());

// Result:
{
  'farmerName': 'John Fruto Ambal',
  'saadIdNo': '1',
  'completedCommodities': [{
    'typeOfCrop': 'Vegetables',
    'variety': 'Carrot',
    'qtyVsCycles': '9',
    'volumesPerCycle': ['11'],
    'photoGPS': {
      'latitude': 14.5123,
      'longitude': 121.0234
    }
  }],
  'trainings': [...]
}
```

#### Step 3: MERGE Both Datasets
```dart
// Lines 839-851 in member_records_screen.dart

final projectBackgroundFields = [
  'fcaName',
  'reportingPeriod',
  'projectTitle',
  'implementationType',
  'region',
  'province',           // ✅ NOW PRESERVED
  'municipality',       // ✅ NOW PRESERVED
  'barangay',           // ✅ NOW PRESERVED
  'primaryIntervention',     // ✅ NOW PRESERVED
  'primaryInterventionOther',
  'supportInterventions',    // ✅ NOW PRESERVED
];

// Create merged data
Map<String, dynamic> mergedData = {
  // Project Background (from group.json)
  'fcaName': 'janeirohAgriculture',
  'reportingPeriod': '2026',
  'region': 'Region IV-A (CALABARZON)',
  'province': 'Batangas',
  'municipality': 'Lipa City',
  'barangay': 'Barangay 2',
  'projectTitle': 'agriculture',
  'primaryIntervention': 'Coconut',
  'supportInterventions': ['idk'],
  
  // Farmer Data (from farmer's data.json)
  'farmerName': 'John Fruto Ambal',
  'saadIdNo': '1',
  'completedCommodities': [{...}],
  'qtyVsCycles': '9',
  'volumesPerCycle': ['11'],
  'trainings': [...]
};
```

#### Step 4: Display in Modal
```dart
// RecordViewModal receives mergedData
showModalBottomSheet(
  builder: (_) => RecordViewModal(
    record: RecordModel(data: mergedData),
    memberName: 'John Fruto Ambal',
  )
);
```

---

## 📱 What Gets Displayed in the Modal

**File:** `record_view_modal.dart` - Lines 1020-1073

### Section 1: Project Background
```
PROJECT BACKGROUND
├─ Reporting Period: 2026
├─ FCA Name: janeirohAgriculture
├─ Region: Region IV-A (CALABARZON)
├─ Province: Batangas                  ✅ NOW SHOWS
├─ Municipality: Lipa City             ✅ NOW SHOWS
├─ Barangay: Barangay 2               ✅ NOW SHOWS
├─ Project Title: agriculture
├─ Primary Intervention: Coconut       ✅ NOW SHOWS
└─ Support Interventions: idk         ✅ NOW SHOWS
```

### Section 2: Commodity Information
```
COMMODITY INFORMATION
├─ Type of Crop: Vegetables
├─ Variety: Carrot
├─ Farmgate Price: 50
├─ Qty vs Area: 100 kg/ha
├─ Cropping Cycles: 3
├─ Qty vs Cycles: 9              ✅ NOW SHOWS
├─ Volumes Per Cycle: 11, 12, 10 ✅ NOW SHOWS
├─ Peak Volume: 12
├─ Peak Month: June
├─ Inputs Received: Seeds (2 kg)
└─ Inputs Purchased: Fertilizer (50 kg)
```

### Sections 3-6: Other Steps
```
PLANTING STAGE
├─ Total Land Area: 1 hectare
├─ Land Ownership: Own
├─ Machinery Type: Plow
├─ Planting Date: 2026-05-01
├─ Seed Amount: 20
└─ Seed Unit: kg

FERTILIZATION REQUIREMENT
├─ Fertilizer Type: Organic, Inorganic
├─ Organic Source: Compost
└─ ...

HARVESTING STAGE
├─ Date Harvest: 2026-07-15
├─ Quantity: 500 kg
└─ ...

CROP DAMAGE
├─ Has Pest: Yes
├─ Pest Occurrence: Caterpillar
└─ ...
```

---

## 🔀 Data Merge Protection

**Important:** The merge process PROTECTS project background fields:

```dart
// When merging farmer data, skip project background fields
for (final entry in farmerData.entries) {
  if (!projectBackgroundFields.contains(entry.key)) {
    mergedData[entry.key] = entry.value;
  }
}

// THEN re-apply group background to ensure it's never overwritten
mergedData.addAll(groupProjectBackground);
```

**Why?** To ensure that even if farmer's data.json somehow contains group fields, the fresh group.json always takes priority.

---

## 🔄 Viewing Flow Diagram

```
User navigates to Data Screen
          ↓
Selects group "janeirohAgriculture"
          ↓
MemberRecordsScreen loads:
  - group.json (project background)
  - All farmers from members array
          ↓
Display member list:
  ├─ John Fruto Ambal
  └─ Maribel Oflaria Baltazar
          ↓
User clicks "John Fruto Ambal"
          ↓
Modal opens, RecordViewModal:
  ├─ Load FRESH group.json
  ├─ Load farmer's data.json
  ├─ MERGE both
  └─ Display merged data
          ↓
User sees:
  - Project Background (9 fields)
  - Commodity Information (12 fields)
  - All Steps 03-07 data
```

---

## ✅ Key Points

1. **Group data is shared** - All farmers see same project background
2. **Farmer data is isolated** - Each farmer's commodities are separate
3. **Data is merged dynamically** - Combining group + farmer data on display
4. **Fresh load on view** - Always loads latest from disk, not cached
5. **Protected fields** - Project background fields cannot be overwritten

---

**Next:** Read [4_ADDING_FARMER.md](4_ADDING_FARMER.md) to understand how adding farmers works

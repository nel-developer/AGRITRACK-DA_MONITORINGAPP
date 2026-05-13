# 5️⃣ ADDING ANOTHER COMMODITY - Multiple Crops Per Farmer

## 🌾 How Multiple Commodities Work

**File:** `step_02_commodity_information.dart`

**User Action:** Click "Add Another Commodity" button on Step 02

---

## 🔄 Step-by-Step Process

### Step 1: Fill First Commodity

```
STEP 02: Commodity Information
┌────────────────────────────┐
│ Type of Crop: Vegetables   │
│ Variety: Carrot            │
│ Farmgate Price: 50         │
│ Qty vs Area: 100 kg/ha     │
│ Cropping Cycles: 3         │
│ Qty vs Cycles: 9           │
│ Peak Volume: 12            │
│ Peak Month: June           │
│ [Add Another] [Next]       │
└────────────────────────────┘
```

### Step 2: User Clicks "Add Another Commodity"

```dart
// step_02_commodity_information.dart

// Current commodity data stored in memory
final firstCommodity = {
  'typeOfCrop': 'Vegetables',
  'variety': 'Carrot',
  'farmgatePrice': '50',
  'qtyVsArea': '100 kg/ha',
  'croppingCycles': '3',
  'qtyVsCycles': '9',
  'volumesPerCycle': ['11', '12', '10'],
  'peakVolume': '12',
  'peakMonth': 'June'
};

// Add to array
commoditiesList.add(firstCommodity);

// Clear form for next commodity
formFields.clear();
```

**Result:**
```
commoditiesList = [
  {first commodity}  ✓
]

Form is now empty, ready for second commodity
```

### Step 3: Fill Second Commodity

```
STEP 02: Commodity Information (Commodity 2 of ?)
┌────────────────────────────┐
│ Type of Crop: Rice         │  ← Different from first
│ Variety: IR64              │
│ Farmgate Price: 30         │
│ Qty vs Area: 80 kg/ha      │
│ Cropping Cycles: 2         │
│ Qty vs Cycles: 8           │
│ Peak Volume: 10            │
│ Peak Month: August         │
│ [Add Another] [Next]       │
└────────────────────────────┘
```

### Step 4: Click "Next" (After all commodities added)

```dart
// All commodities saved in memory array
commoditiesList = [
  {
    'typeOfCrop': 'Vegetables',
    'variety': 'Carrot',
    'croppingCycles': '3',
    'qtyVsCycles': '9'
  },
  {
    'typeOfCrop': 'Rice',
    'variety': 'IR64',
    'croppingCycles': '2',
    'qtyVsCycles': '8'
  }
];

// User proceeds to Steps 03-06, filling each step completely
```

### Step 5: Step 07 - FINAL SAVE with All Commodities

**File:** `step_07_trainings.dart` - Lines 722-732

```dart
// Step 07 receives ALL accumulated commodity data

// Merge all commodities into array
final completedCommodities = [
  {
    'typeOfCrop': 'Vegetables',
    'variety': 'Carrot',
    'volumesPerCycle': ['11', '12', '10'],
    'photoGPS': {
      'latitude': 14.5123,
      'longitude': 121.0234
    }
  },
  {
    'typeOfCrop': 'Rice',
    'variety': 'IR64',
    'volumesPerCycle': ['8', '9', '7'],
    'photoGPS': {
      'latitude': 14.5456,
      'longitude': 121.0567
    }
  }
];

// Save ALL to data.json
final data = {
  'farmerName': 'John Fruto Ambal',
  'completedCommodities': completedCommodities,
  // ... all other steps
};

File('/storage/.../John_Fruto_Ambal/data.json')
  .writeAsString(jsonEncode(data));
```

---

## 📁 File Storage for Multiple Commodities

### Single File, Multiple Entries:

```
/storage/.../crop/janeirohAgriculture/John_Fruto_Ambal/data.json

{
  "farmerName": "John Fruto Ambal",
  "saadIdNo": "1",
  "completedCommodities": [
    {
      "typeOfCrop": "Vegetables",
      "variety": "Carrot",
      ...
    },
    {
      "typeOfCrop": "Rice",
      "variety": "IR64",
      ...
    }
  ]
}
```

### Multiple Photo Files:

```
/storage/.../crop/janeirohAgriculture/John_Fruto_Ambal/

├── data.json
├── crops_Carrot_14.5123_121.0234.jpg        ← Commodity 1 photo
└── crops_Rice_14.5456_121.0567.jpg          ← Commodity 2 photo
```

**Each commodity gets its own photo file!**

---

## 🔍 How Viewing Works with Multiple Commodities

### When Viewing Farmer (Modal):

```dart
// record_view_modal.dart

// Load farmer's data.json
final data = {
  'completedCommodities': [
    { Vegetable/Carrot },
    { Rice/IR64 }
  ]
};

// Display each commodity
for (final commodity in data['completedCommodities']) {
  displayCommodityCard(commodity);
}
```

### Display Shows:

```
📱 Modal: John Fruto Ambal

PROJECT BACKGROUND
├─ Reporting Period: 2026
├─ FCA Name: janeirohAgriculture
├─ Region: Region IV-A
└─ ...

COMMODITY INFORMATION 1
├─ Type of Crop: Vegetables
├─ Variety: Carrot
├─ Peak Volume: 12
└─ ...
[Photo: crops_Carrot_14.5123_121.0234.jpg]

COMMODITY INFORMATION 2
├─ Type of Crop: Rice
├─ Variety: IR64
├─ Peak Volume: 10
└─ ...
[Photo: crops_Rice_14.5456_121.0567.jpg]

PLANTING STAGE
├─ Total Land Area: 2 hectares (total for farmer)
└─ ...

TRAININGS
├─ Training 1: Climate-Smart Ag
└─ Training 2: ...
```

---

## 📊 Data Structure Example

### Raw JSON for Multiple Commodities:

```json
{
  "farmerName": "John Fruto Ambal",
  "saadIdNo": "1",
  "completedCommodities": [
    {
      "typeOfCrop": "Vegetables",
      "variety": "Carrot",
      "farmgatePrice": "50",
      "totalCostPurchased": "1000",
      "qtyVsArea": "100 kg/ha",
      "croppingCycles": "3",
      "qtyVsCycles": "9",
      "volumesPerCycle": ["11", "12", "10"],
      "peakVolume": "12",
      "peakMonth": "June",
      "photoGPS": {
        "latitude": 14.5123,
        "longitude": 121.0234
      }
    },
    {
      "typeOfCrop": "Rice",
      "variety": "IR64",
      "farmgatePrice": "30",
      "totalCostPurchased": "800",
      "qtyVsArea": "80 kg/ha",
      "croppingCycles": "2",
      "qtyVsCycles": "8",
      "volumesPerCycle": ["8", "9"],
      "peakVolume": "10",
      "peakMonth": "August",
      "photoGPS": {
        "latitude": 14.5456,
        "longitude": 121.0567
      }
    }
  ],
  "totalLandArea": "2 hectares",
  "plantingDate": "2026-05-01",
  "trainings": [...]
}
```

---

## 🎯 Key Sequence

```
Fill Commodity 1 (Vegetable/Carrot)
        ↓
Click "Add Another"
        ↓
Commodity 1 saved to array in memory
        ↓
Form cleared
        ↓
Fill Commodity 2 (Rice/IR64)
        ↓
Click "Next" (complete Step 02)
        ↓
Steps 03-06 (fill with values applying to ALL commodities)
        ↓
Step 07 (Final Save)
        ├─ Merge all commodities
        ├─ Save to data.json: completedCommodities array
        ├─ Save photo 1: crops_Carrot_14.5123_121.0234.jpg
        └─ Save photo 2: crops_Rice_14.5456_121.0567.jpg
        ↓
✓ Both commodities stored with own photos
```

---

## 🚨 Important Notes

### Same Steps for All Commodities:

```
Planting Stage (Step 03):
├─ Total Land Area: 2 hectares     ← Used for ALL commodities
├─ Land Ownership: Own             ← Used for ALL commodities
└─ Planting Date: 2026-05-01       ← Used for ALL commodities

Why?
- Land area is FARMER's total, not per-commodity
- One planting date for all crops that season
- One land ownership type
```

### But Different for Each Commodity:

```
Commodity Information (Step 02):
├─ Vegetable/Carrot has volumesPerCycle: [11, 12, 10]
└─ Rice/IR64 has volumesPerCycle: [8, 9]
```

---

## 📈 Memory Usage During Form Fill

```
Step 02 (Commodity Info):
  completedCommodities = [
    {vegetable}, {rice}
  ]
  
Step 03 (Planting):
  totalLandArea = "2 ha"
  
Step 04 (Fertilizer):
  fertilizerType = ["organic"]
  
Step 05 (Harvesting):
  dateHarvest = ["2026-07-15"]
  
Step 06 (Damage):
  hasPest = true
  
Step 07 (Trainings):
  trainings = [...]
  
Step 07 SAVE: ALL merged together
  {
    completedCommodities: [...],
    totalLandArea: ...,
    fertilizerType: ...,
    dateHarvest: ...,
    hasPest: ...,
    trainings: ...
  }
```

---

## ✅ Key Takeaway

```
Multiple Commodities = ONE farmer, MULTIPLE crops

Stored as:
├─ ONE data.json with completedCommodities array
├─ Multiple photo files (one per commodity)
└─ Shared values (land area, location, date)

When viewing:
├─ All commodities displayed in same modal
├─ Each commodity shows its own details + photo
└─ All under one farmer record
```

---

**Next:** Read [6_COMPLETE_FLOW_DIAGRAM.md](6_COMPLETE_FLOW_DIAGRAM.md) for visual flow diagrams

# 1️⃣ DATA STRUCTURE - Where & How Crop Data is Saved

## 📍 File Structure on Disk

Your crop data is saved locally at:
```
/storage/emulated/0/Android/data/com.example.da_monitoring_app/files/monitoring_records/crop/
│
└── janeirohAgriculture/                    (Group folder - named after FCA Name)
    ├── group.json                          (Step 01: Project Background)
    │
    ├── John_Fruto_Ambal/                   (Farmer 1 folder)
    │   ├── data.json                       (Steps 02-07: All farmer-specific data)
    │   ├── crops_Carrot_14.5123_121.0234.jpg
    │   └── crops_Vegetables_14.5456_121.0567.jpg
    │
    └── Maribel_Oflaria_Baltazar/           (Farmer 2 folder)
        ├── data.json
        └── crops_Coconut_14.5789_121.0890.jpg
```

## 📄 What Goes in group.json (Project Background - Step 01)

**File:** `group.json` in group folder

**Purpose:** Contains group-level information shared by ALL farmers

**Example Content:**
```json
{
  "implementationType": "individual",
  "reportingPeriod": "2026",
  "fcaName": "janeirohAgriculture",
  "region": "Region IV-A (CALABARZON)",
  "province": "Batangas",
  "municipality": "Lipa City",
  "barangay": "Barangay 2",
  "projectTitle": "agriculture",
  "primaryIntervention": "Coconut",
  "primaryInterventionOther": "",
  "supportInterventions": ["idk"],
  "members": [
    {
      "name": "John Fruto Ambal",
      "saadIdNo": "1"
    },
    {
      "name": "Maribel Oflaria Baltazar",
      "saadIdNo": "1000p"
    }
  ],
  "createdAt": "2026-05-13T15:15:18.871670"
}
```

**Key Fields:**
- `fcaName`: Organization name (used to create folder)
- `members`: Array of all farmers in the group
- `region`, `province`, `municipality`, `barangay`: Location data
- `primaryIntervention`: Main focus crop/activity
- `implementationType`: "individual", "collective", or "hybrid"

**Saved By:** `step_01_project_background.dart`

---

## 📄 What Goes in data.json (Farmer-Specific Data - Steps 02-07)

**File:** `data.json` in each farmer's folder

**Purpose:** Contains ALL data specific to ONE farmer

**Example Content:**
```json
{
  "fcaName": "janeirohAgriculture",
  "reportingPeriod": "2026",
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
        "longitude": 121.0234,
        "accuracy": 5.0
      },
      "inputsReceived": [
        {
          "name": "Seeds",
          "quantity": "2 kg"
        }
      ],
      "inputsPurchased": [
        {
          "name": "Fertilizer",
          "quantity": "50 kg",
          "cost": "1000",
          "month": "May"
        }
      ]
    }
  ],
  
  "totalLandArea": "1 hectare",
  "landOwnership": "Own",
  "machineryType": ["Plow"],
  
  "plantingDate": "2026-05-01",
  "seedAmount": "20",
  "seedUnit": "kg",
  
  "fertilizerType": ["Organic", "Inorganic"],
  "organicSource": "Compost",
  "organicBagsSAAD": "5",
  
  "trainings": [
    {
      "name": "Climate-Smart Agriculture",
      "date": "2026-05-10",
      "attendees": "15"
    }
  ]
}
```

**Key Sections:**
- **completedCommodities**: Array of all crops/commodities the farmer planted
- **Steps 03-06 fields**: Land, planting, fertilizer, harvest data
- **trainings**: Training records
- **photoGPS**: GPS coordinates stored with each commodity

**Saved By:** `step_07_trainings.dart`

---

## 📷 Photo Naming Convention

**Format:** `crops_{variety}_{latitude}_{longitude}.jpg`

**Examples:**
```
crops_Carrot_14.5123_121.0234.jpg
crops_Vegetables_14.5456_121.0567.jpg
crops_Rice_14.5789_121.0890.jpg
```

**Parts:**
- `crops`: Identifier showing it's a crop commodity photo
- `{variety}`: The crop variety from Step 02
- `{latitude}`: GPS latitude coordinate (with decimal separator as underscore)
- `{longitude}`: GPS longitude coordinate (with decimal separator as underscore)

**Why GPS in Filename?**
- Easy to identify location visually
- Makes it traceable without reading EXIF data
- Better file organization

---

## 🔄 Relationship Between Files

```
┌─────────────────────────────────────────┐
│         group.json                       │
│  (Project Background - Shared by ALL)    │
│  - region, province, municipality        │
│  - primaryIntervention                   │
│  - members: [farmer1, farmer2]           │
└──────────────┬──────────────┬────────────┘
               │              │
        ┌──────▼──┐      ┌────▼──────┐
        │ Farmer1 │      │  Farmer2  │
        │ data.json       data.json
        │ - commodities   - commodities
        │ - training      - training
        │ - machinery     - machinery
        └─────────┘      └───────────┘
```

---

## 📊 Data Isolation

- **Group.json is shared** - All farmers can access the same project background
- **data.json is isolated** - Each farmer's data is completely separate
- **This prevents:** One farmer's changes from affecting another farmer's data

---

## ✅ Key Takeaway

```
Group Level (1 file):
  └─ group.json → Project Background shared by all farmers

Farmer Level (multiple files):
  ├─ John's data.json → John's commodities, training, machinery
  ├─ John's photos → crops_Carrot_14.5123_121.0234.jpg
  ├─ Maribel's data.json → Maribel's commodities, training, machinery
  └─ Maribel's photos → crops_Coconut_14.5789_121.0890.jpg
```

---

**Next:** Read [2_SAVING_FLOW.md](2_SAVING_FLOW.md) to understand how this data gets saved

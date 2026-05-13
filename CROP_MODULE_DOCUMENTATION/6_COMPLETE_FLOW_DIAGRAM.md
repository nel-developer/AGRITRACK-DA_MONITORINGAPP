# 6️⃣ COMPLETE FLOW DIAGRAMS - Visual Overview

## 📊 Overall Crop Module Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                    CROP MONITORING SYSTEM                           │
│                                                                      │
│  GROUP LEVEL (Shared by all farmers)                                │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ group.json                                                   │  │
│  │ ├─ fcaName: janeirohAgriculture                             │  │
│  │ ├─ reportingPeriod: 2026                                    │  │
│  │ ├─ region, province, municipality, barangay                 │  │
│  │ ├─ primaryIntervention: Coconut                             │  │
│  │ └─ members: [John, Maribel]                                 │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  FARMER LEVEL (Separate for each farmer)                            │
│  ┌─────────────────────┐           ┌─────────────────────┐         │
│  │  JOHN FRUTO AMBAL   │           │ MARIBEL BALTAZAR    │         │
│  ├─────────────────────┤           ├─────────────────────┤         │
│  │ data.json           │           │ data.json           │         │
│  │ ├─ Commodity 1      │           │ ├─ Commodity 1      │         │
│  │ │  Vegetables/Carrot │          │ │ Coconut/Tall      │         │
│  │ ├─ Commodity 2      │           │ └─ Trainings        │         │
│  │ │  Rice/IR64        │           │                     │         │
│  │ ├─ Trainings        │           │ photos/             │         │
│  │ └─ Machinery, etc   │           │ crops_Coconut_...jpg│         │
│  │                     │           │                     │         │
│  │ photos/             │           │                     │         │
│  │ crops_Carrot_...jpg │           │                     │         │
│  │ crops_Rice_...jpg   │           │                     │         │
│  └─────────────────────┘           └─────────────────────┘         │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 💾 SAVING FLOW - From Start to Completion

```
USER START (Step 01)
        ↓
┌───────────────────────────┐
│ STEP 01: PROJECT BACKGROUND
│ ├─ Fill group info
│ └─ Save → group.json ✓
└───────────────────────────┘
        ↓
┌───────────────────────────┐
│ STEP 02-06: FORM FILLING
│ ├─ Step 02: Commodity
│ ├─ Step 03: Planting
│ ├─ Step 04: Fertilizer
│ ├─ Step 05: Harvesting
│ ├─ Step 06: Damage
│ └─ Status: IN MEMORY
└───────────────────────────┘
        ↓
┌───────────────────────────────────────────────────────────┐
│ STEP 07: FINAL SAVE - EVERYTHING TO DISK
│                                                           │
│ 1. Get GPS coordinates from camera
│    └─ latitude: 14.5123, longitude: 121.0234
│                                                           │
│ 2. Merge all Steps 02-07 data
│    └─ Create complete farmer record
│                                                           │
│ 3. Save to farmer's data.json
│    └─ /storage/.../John_Fruto_Ambal/data.json ✓
│                                                           │
│ 4. Save photo with GPS in filename
│    └─ /storage/.../John_Fruto_Ambal/
│       crops_Carrot_14.5123_121.0234.jpg ✓
│                                                           │
│ 5. Mark record as "unsync" (pending Firebase sync)
│                                                           │
└───────────────────────────────────────────────────────────┘
        ↓
✅ SAVE COMPLETE
   Ready to view/edit
```

---

## 👁️ VIEWING FLOW - How Data is Retrieved & Displayed

```
USER ACTION: Click on "janeirohAgriculture"
        ↓
        ┌─────────────────────────┐
        │ LOAD GROUP              │
        │ Read: group.json        │
        │ Result: Project BG data │
        │         Member list: 2  │
        └────────┬────────────────┘
                 ↓
    ┌────────────────────────────────┐
    │ DISPLAY MEMBER LIST            │
    │ ┌──────────────────────────┐  │
    │ │ John Fruto Ambal  unsync │  │
    │ │ [View] [Edit] [Sync]     │  │
    │ │ 2 commodities            │  │
    │ ├──────────────────────────┤  │
    │ │ Maribel Oflaria   unsync │  │
    │ │ [View] [Edit] [Sync]     │  │
    │ │ 1 commodity              │  │
    │ └──────────────────────────┘  │
    └────────┬──────────────────────┘
             ↓
USER CLICKS: [View] for "John Fruto Ambal"
        ↓
        ┌──────────────────────────────────────────────┐
        │ MODAL OPENS - LOAD FARMER DATA              │
        │                                              │
        │ 1. Load FRESH group.json                    │
        │    └─ Get: province, municipality, barangay,│
        │          primaryIntervention, etc.          │
        │                                              │
        │ 2. Load farmer's data.json                  │
        │    └─ Get: completedCommodities, trainings, │
        │          machinery, fertilizer, etc.        │
        │                                              │
        │ 3. MERGE both datasets                      │
        │    ├─ Project Background (from group.json) │
        │    ├─ Commodity Data (from farmer data.json)
        │    └─ All other steps                       │
        │                                              │
        │ 4. Display in 6 sections                     │
        │                                              │
        └──────────────┬───────────────────────────────┘
                       ↓
        ┌──────────────────────────────────────────────┐
        │ DISPLAY SECTIONS:                            │
        ├──────────────────────────────────────────────┤
        │ PROJECT BACKGROUND (9 fields)               │
        │ ├─ Reporting Period, FCA Name, Region...   │
        │ ├─ Province ✅, Municipality ✅, Barangay ✅
        │ └─ Primary Intervention ✅ ...              │
        ├──────────────────────────────────────────────┤
        │ COMMODITY INFORMATION (12+ fields)          │
        │ ├─ Type of Crop, Variety, Farmgate Price   │
        │ ├─ Qty vs Area, Cropping Cycles            │
        │ ├─ Qty vs Cycles ✅, Volumes Per Cycle ✅   │
        │ └─ Peak Volume, Peak Month                 │
        ├──────────────────────────────────────────────┤
        │ PLANTING STAGE (10+ fields)                 │
        │ ├─ Total Land Area, Land Ownership         │
        │ ├─ Planting Date, Seed Amount              │
        │ └─ ...                                      │
        ├──────────────────────────────────────────────┤
        │ FERTILIZATION (8+ fields)                  │
        │ ├─ Fertilizer Type, Organic Source         │
        │ └─ ...                                      │
        ├──────────────────────────────────────────────┤
        │ HARVESTING STAGE (fields)                   │
        │ ├─ Harvest Dates, Quantities               │
        │ └─ ...                                      │
        ├──────────────────────────────────────────────┤
        │ CROP DAMAGE (fields)                        │
        │ ├─ Pest, Disease, Environmental Damage     │
        │ └─ ...                                      │
        └──────────────────────────────────────────────┘
                       ↓
        ✅ COMPLETE FARMER RECORD DISPLAYED
```

---

## 🔀 DATA MERGE PROCESS - The Critical Step

```
┌─────────────────────────────────┐
│ Fresh group.json loaded         │
├─────────────────────────────────┤
│ {                               │
│   fcaName: 'janeirohAgriculture'│
│   province: 'Batangas'  ←─┐     │
│   municipality: 'Lipa'    │     │
│   primaryIntervention: 'Coconut' │
│   ...                     │     │
│ }                         │     │
└─────────────────────────┬───────┘
                          │
                          ├─ MERGE ─┐
                          │         │
                          ↓         │
┌──────────────────────────────────┴──┐
│ Farmer's data.json loaded           │
├─────────────────────────────────────┤
│ {                                   │
│   farmerName: 'John Fruto'          │
│   completedCommodities: [...]       │
│   qtyVsCycles: '9'                  │
│   volumesPerCycle: ['11']  ←─┐      │
│   trainings: [...]          │      │
│   ...                       │      │
│ }                           │      │
└──────────────────────────────┬──────┘
                               ↓
                ┌──────────────────────────┐
                │ MERGED RESULT            │
                ├──────────────────────────┤
                │ {                        │
                │   // Group fields       │
                │   fcaName: '...',       │
                │   province: '...',  ✅  │
                │   municipality: '...',✅ │
                │   primaryIntervention: '..',✅
                │                         │
                │   // Farmer fields      │
                │   farmerName: '...',    │
                │   completedCommodities: [...],
                │   qtyVsCycles: '9', ✅  │
                │   volumesPerCycle: [..],✅
                │   trainings: [...]      │
                │ }                       │
                └──────────────────────────┘
                           ↓
                    ✅ DISPLAY
```

---

## ➕ ADD FARMER FLOW

```
Step 01 Screen
        ↓
Click [Add Farmer]
        ↓
┌────────────────────────┐
│ Update group.json      │
│ ├─ Add to members[]    │
│ └─ Save file ✓         │
└────────────────────────┘
        ↓
New farmer fills Steps 02-07
        ↓
Step 07 save:
├─ Creates farmer directory ✓
├─ Creates data.json ✓
└─ Saves photos ✓
        ↓
Next view:
├─ Reads updated group.json
├─ Finds 2 members
└─ Displays both farmers
```

---

## ➕ ADD COMMODITY FLOW

```
Step 02 Screen - Commodity 1
        ↓
Fill commodity details
        ↓
Click [Add Another]
        ↓
┌────────────────────────┐
│ Commodity 1 stored     │
│ in memory array        │
│ completedCommodities[] │
└────────────────────────┘
        ↓
Form cleared
        ↓
Fill commodity details 2
        ↓
Click [Next]
        ↓
Steps 03-06 (apply to all commodities)
        ↓
Step 07 Save:
├─ Merge all commodities ✓
├─ Save to data.json:
│  completedCommodities: [
│    {commodity1},
│    {commodity2}
│  ]
├─ Save photo 1 ✓
└─ Save photo 2 ✓
```

---

## 📁 FILESYSTEM BEFORE & AFTER

### INITIAL STATE (After Step 01 only):
```
crop/janeirohAgriculture/
└── group.json (Step 01 data)
```

### AFTER FARMER 1 COMPLETES ALL STEPS:
```
crop/janeirohAgriculture/
├── group.json (Step 01)
└── John_Fruto_Ambal/
    ├── data.json (Steps 02-07)
    └── crops_Carrot_14.5123_121.0234.jpg
```

### AFTER FARMER 2 ADDED & COMPLETED:
```
crop/janeirohAgriculture/
├── group.json (Step 01 - UPDATED with 2 members)
├── John_Fruto_Ambal/
│   ├── data.json
│   ├── crops_Carrot_14.5123_121.0234.jpg
│   └── crops_Rice_14.5456_121.0567.jpg (2nd commodity)
└── Maribel_Oflaria_Baltazar/
    ├── data.json
    └── crops_Coconut_14.5789_121.0890.jpg
```

---

**Next:** Read [7_KEY_POINTS.md](7_KEY_POINTS.md) for quick reference summary

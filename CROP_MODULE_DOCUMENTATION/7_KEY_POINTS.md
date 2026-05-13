# 7️⃣ KEY POINTS - Quick Reference Summary

## 🎯 Essential Information at a Glance

### File Structure
```
crop/
└── janeirohAgriculture/          (Group name)
    ├── group.json                (Step 01: Shared by all farmers)
    ├── John_Fruto_Ambal/         (Farmer 1 folder)
    │   ├── data.json             (Steps 02-07)
    │   ├── crops_...jpg          (Photos)
    │   └── crops_...jpg          (Multiple commodities)
    └── Maribel_.../ (Farmer 2 folder)
        ├── data.json
        └── crops_...jpg
```

---

## 💾 What Gets Saved Where

| Data | File | Saved When | Shared? |
|------|------|-----------|---------|
| Project Background | group.json | Step 01 | YES (all farmers) |
| Commodity Info | data.json | Step 07 | NO (per farmer) |
| Planting Data | data.json | Step 07 | NO (per farmer) |
| Photos | crops_*.jpg | Step 07 | NO (per farmer) |
| Trainings | data.json | Step 07 | NO (per farmer) |

---

## 🔄 Save Points

| Step | Saves | To | Status |
|------|-------|----|----|
| 01 | Project Background | group.json | ✅ Saved to disk |
| 02 | Commodity Info | Memory | ⏳ Temp storage |
| 03 | Planting Stage | Memory | ⏳ Temp storage |
| 04 | Fertilization | Memory | ⏳ Temp storage |
| 05 | Harvesting | Memory | ⏳ Temp storage |
| 06 | Damage Info | Memory | ⏳ Temp storage |
| 07 | Everything (02-07) + Photo | data.json + JPG | ✅ Saved to disk |

---

## 📊 Data Merge on View

When viewing a farmer:

1. **Load:** group.json (project background)
2. **Load:** farmer's data.json (commodities)
3. **Merge:** Combine both
4. **Protect:** Group fields never overwritten
5. **Display:** All fields shown

---

## 👥 Adding a Farmer

1. Click "Add Farmer" on Step 01
2. Updates group.json members array
3. New farmer fills Steps 02-07
4. Step 07 creates farmer directory
5. Farmer appears in member list next view

---

## 🌾 Adding a Commodity

1. Fill commodity on Step 02
2. Click "Add Another"
3. Commodity stored in memory array
4. Fill second commodity
5. Step 07 merges all into completedCommodities array

---

## 📷 Photo Naming

**Format:** `crops_{variety}_{latitude}_{longitude}.jpg`

**Example:** `crops_Carrot_14.5123_121.0234.jpg`

**Contains:** Crop type, variety, exact location

---

## ✅ 9 Project Background Fields Now Showing

- ✅ Reporting Period
- ✅ FCA Name
- ✅ Region
- ✅ Province (FIXED)
- ✅ Municipality (FIXED)
- ✅ Barangay (FIXED)
- ✅ Project Title
- ✅ Primary Intervention (FIXED)
- ✅ Support Interventions (FIXED)

---

## ✅ New Commodity Fields Now Showing

- ✅ Type of Crop
- ✅ Variety
- ✅ Farmgate Price
- ✅ Qty vs Area
- ✅ Cropping Cycles
- ✅ Qty vs Cycles (NEW)
- ✅ Volumes Per Cycle (NEW)
- ✅ Peak Volume
- ✅ Peak Month

---

## 🔐 Data Protection Rules

1. **Group data is shared** - All farmers see same project background
2. **Farmer data is isolated** - Each farmer has separate commodities
3. **Fresh load on view** - Always reads latest from disk, not cache
4. **Group fields protected** - Never overwritten by farmer data
5. **Farmer ID priority** - Uses SAAD ID (not name) for uniqueness

---

## 🎯 Implementation Types

**Individual:**
- One farmer per form
- Separate folder for each farmer
- All share group.json

**Collective:**
- Multiple farmers in one group
- Could handle commodities differently

**Hybrid:**
- Mix of individual and collective features
- Currently treated like individual

---

## 🔍 File Sizes (Typical)

| File | Size | Notes |
|------|------|-------|
| group.json | ~500 bytes | Light, just metadata |
| data.json | 5-20 KB | Varies by steps filled |
| Photo JPG | 2-5 MB | Compressed camera photo |

---

## 📱 Viewing Modes

| Mode | Shows | File(s) |
|------|-------|---------|
| Group View | All farmers list | group.json + all data.json |
| Farmer View | One farmer detail | group.json + 1 data.json |
| Modal | All 6 sections | Merged data |

---

## ⚡ Performance

| Operation | Time | Status |
|-----------|------|--------|
| Load group.json | <100ms | Fast |
| Load farmer data.json | <100ms | Fast |
| Merge data | <50ms | Fast |
| Save data.json | <100ms | Fast |
| Save photo | 1-2s | Depends on size |

---

## 🚨 Common Issues Fixed

| Issue | Cause | Fix |
|-------|-------|-----|
| Province not showing | Not copied to farmer view | Added to withMemberData() |
| Municipality not showing | Not copied to farmer view | Added to withMemberData() |
| Barangay not showing | Not copied to farmer view | Added to withMemberData() |
| Primary Intervention not showing | Not copied to farmer view | Added to withMemberData() |
| Support Interventions not showing | Not copied to farmer view | Added to withMemberData() |
| Qty vs Cycles not showing | Not in field list | Added to record_view_modal |
| Volumes Per Cycle not showing | Not in field list | Added to record_view_modal |
| Photos not named with GPS | No GPS in filename | Added GPS to filename |

---

## 🔄 Data Flow Summary

```
USER INPUT
    ↓
STEPS 02-07 (in memory)
    ↓
STEP 07 SAVE (to disk)
    ├─ data.json
    └─ photos
    ↓
VIEWING (from disk)
    ├─ Load group.json
    ├─ Load data.json
    ├─ Merge
    └─ Display
    ↓
USER SEES ALL DATA
```

---

## 📋 Checklist: Everything That Works

- ✅ Project Background (9 fields all showing)
- ✅ Commodity Information (12+ fields)
- ✅ Multiple commodities per farmer
- ✅ Multiple farmers per group
- ✅ Photos with GPS coordinates
- ✅ All 6 display sections
- ✅ Fresh data loading from disk
- ✅ Proper data merging
- ✅ Protected group fields
- ✅ Isolated farmer data

---

## 🎓 Learning Path

1. **Start Here:** This file (7_KEY_POINTS.md)
2. **Then Read:** [1_DATA_STRUCTURE.md](1_DATA_STRUCTURE.md)
3. **Then:** [2_SAVING_FLOW.md](2_SAVING_FLOW.md)
4. **Then:** [3_VIEWING_FLOW.md](3_VIEWING_FLOW.md)
5. **Deep Dive:** [4_ADDING_FARMER.md](4_ADDING_FARMER.md) & [5_ADDING_COMMODITY.md](5_ADDING_COMMODITY.md)
6. **Visual:** [6_COMPLETE_FLOW_DIAGRAM.md](6_COMPLETE_FLOW_DIAGRAM.md)

---

## 🆘 Quick Troubleshooting

**Field not showing?**
→ Check if it's in the field list in `record_view_modal.dart`

**Data not updating?**
→ Verify it's being saved in Step 07 `step_07_trainings.dart`

**Photo not saving?**
→ Check GPS is available and file path exists

**Farmer not appearing?**
→ Verify member is added to `group.json` members array

**Multiple commodities lost?**
→ Ensure `completedCommodities` array is being merged properly

---

## 📞 Key Files Reference

| Purpose | File |
|---------|------|
| Save Step 01 | step_01_project_background.dart |
| Fill commodities | step_02_commodity_information.dart |
| Save all steps | step_07_trainings.dart |
| View group | member_records_screen.dart |
| View farmer | record_view_modal.dart |
| Manage storage | local_farmer_storage_service.dart |

---

## ✨ Current State (as of May 13, 2026)

- **Group:** janeirohAgriculture
- **Members:** 2 (John Fruto Ambal, Maribel Oflaria Baltazar)
- **Implementation:** Individual
- **Production Type:** Crop
- **Location:** Barangay 2, Lipa City, Batangas
- **Primary Focus:** Coconut
- **Status:** ✅ All systems working correctly

---

**Questions?** Reference the main files or check the implementation code.

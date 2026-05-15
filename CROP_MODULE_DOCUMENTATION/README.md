# 🌾 CROP MODULE - Complete Architecture Documentation

Welcome! This folder contains comprehensive documentation on how the crop module works in your AgriTrack application.

## 🎯 START HERE: [0_SYSTEM_OVERVIEW.md](0_SYSTEM_OVERVIEW.md) ⭐ BEST STARTING POINT
Complete system architecture, data journey, and quick reference guide.

## 📁 Files in This Documentation

### START HERE
0. **[0_SYSTEM_OVERVIEW.md](0_SYSTEM_OVERVIEW.md)** - Complete System Architecture ⭐ START HERE
   - Overview of all layers
   - Data journey example
   - File organization
   - Quick navigation guide
   - Verification checklist

### Foundation (Start Here)
1. **[1_DATA_STRUCTURE.md](1_DATA_STRUCTURE.md)** - Where and how crop data is saved
   - File structure on disk
   - What goes in group.json vs data.json
   - Photo naming conventions

2. **[2_SAVING_FLOW.md](2_SAVING_FLOW.md)** - How data gets saved locally
   - Step 01: Project Background saving
   - Steps 02-07: Farmer commodity saving
   - Photo saving with GPS coordinates

### Implementation Types (Pick One)
3. **[8_COLLECTIVE_FLOW.md](8_COLLECTIVE_FLOW.md)** - Collective Implementation Type ⭐ NEW
   - How collective groups work locally
   - Adding commodities at GROUP level
   - Firebase sync for collective
   - Editing collective pending records

4. **[9_INDIVIDUAL_HYBRID_FLOW.md](9_INDIVIDUAL_HYBRID_FLOW.md)** - Individual & Hybrid Implementation Types ⭐ NEW
   - How individual/hybrid groups work locally
   - Adding new farmers
   - Adding commodities at FARMER level
   - Firebase sync for individual/hybrid
   - Editing individual/hybrid pending records

### Special Systems
5. **[10_PHOTO_GPS_SYSTEM.md](10_PHOTO_GPS_SYSTEM.md)** - Photo & GPS Capture ⭐ NEW
   - How photos are captured with camera
   - GPS coordinate collection
   - Photo filename encoding
   - Photo storage and naming conventions
   - GPS metadata in EXIF and JSON

6. **[11_FIREBASE_SYNC.md](11_FIREBASE_SYNC.md)** - Firebase Synchronization ⭐ NEW
   - When and how sync happens (automatic & manual)
   - How local data uploads to Firestore
   - Record status tracking (unsync → pending → approved)
   - Sync for collective vs individual/hybrid
   - Error handling and retry logic

7. **[12_EDITING_PENDING.md](12_EDITING_PENDING.md)** - Editing Pending Records ⭐ NEW
   - How to view pending records
   - How to open edit modal
   - Editing commodity fields
   - Saving edits back to Firebase
   - What fields are editable vs read-only

### Legacy (Reference)
8. **[3_VIEWING_FLOW.md](3_VIEWING_FLOW.md)** - How viewing works
   - Viewing a group
   - Viewing a specific farmer
   - Data merging process

9. **[4_ADDING_FARMER.md](4_ADDING_FARMER.md)** - How adding another farmer works
   - Step-by-step process
   - File structure creation

10. **[5_ADDING_COMMODITY.md](5_ADDING_COMMODITY.md)** - How adding another commodity works
    - Multiple commodity handling
    - Storage in completedCommodities array

11. **[6_COMPLETE_FLOW_DIAGRAM.md](6_COMPLETE_FLOW_DIAGRAM.md)** - Visual flow diagrams
    - Saving flow diagram
    - Viewing flow diagram
    - Data merge illustration

12. **[7_KEY_POINTS.md](7_KEY_POINTS.md)** - Quick reference summary

## 🚀 Quick Start Reading Order

### First Time Understanding the System (Recommended Order)
0. **START:** [0_SYSTEM_OVERVIEW.md](0_SYSTEM_OVERVIEW.md) - Get the big picture first! ⭐
1. Read **[1_DATA_STRUCTURE.md](1_DATA_STRUCTURE.md)** - Understand WHERE data lives
2. Read **[2_SAVING_FLOW.md](2_SAVING_FLOW.md)** - Understand HOW data is saved
3. Choose YOUR implementation type:
   - **Collective?** → Read **[8_COLLECTIVE_FLOW.md](8_COLLECTIVE_FLOW.md)**
   - **Individual/Hybrid?** → Read **[9_INDIVIDUAL_HYBRID_FLOW.md](9_INDIVIDUAL_HYBRID_FLOW.md)**
4. Read **[10_PHOTO_GPS_SYSTEM.md](10_PHOTO_GPS_SYSTEM.md)** - Understand photos & GPS
5. Read **[11_FIREBASE_SYNC.md](11_FIREBASE_SYNC.md)** - Understand syncing to server
6. Read **[12_EDITING_PENDING.md](12_EDITING_PENDING.md)** - Understand editing pending records

### When Troubleshooting
- What is the complete system? → See [0_SYSTEM_OVERVIEW.md](0_SYSTEM_OVERVIEW.md)
- Data saving not working? → Check [2_SAVING_FLOW.md](2_SAVING_FLOW.md)
- Can't find data file? → Check [1_DATA_STRUCTURE.md](1_DATA_STRUCTURE.md)
- Sync not working? → Check [11_FIREBASE_SYNC.md](11_FIREBASE_SYNC.md)
- Editing not persisting? → Check [12_EDITING_PENDING.md](12_EDITING_PENDING.md)
- Photos missing GPS? → Check [10_PHOTO_GPS_SYSTEM.md](10_PHOTO_GPS_SYSTEM.md)
- Collective/Individual differences? → Check [8_COLLECTIVE_FLOW.md](8_COLLECTIVE_FLOW.md) vs [9_INDIVIDUAL_HYBRID_FLOW.md](9_INDIVIDUAL_HYBRID_FLOW.md)

### For Visual Learners
- See **[6_COMPLETE_FLOW_DIAGRAM.md](6_COMPLETE_FLOW_DIAGRAM.md)** for flow diagrams
- Use **[7_KEY_POINTS.md](7_KEY_POINTS.md)** as quick reference
- Navigate using [0_SYSTEM_OVERVIEW.md](0_SYSTEM_OVERVIEW.md) as a map

## 💾 Your Current Data Example

Your group: **janeirohAgriculture**
- Implementation Type: Can be `individual`, `collective`, or `hybrid`
- Members: Varies by type
  - **Collective:** No individual members listed (group as a whole)
  - **Individual/Hybrid:** Multiple farmers (e.g., John Fruto Ambal, Maribel Oflaria)
- Each farmer (if individual/hybrid) has their own separate commodities

## 🔄 Understanding the Three Implementation Types

### 🏢 Collective
One FCA group, commodities tracked at GROUP level. Good for:
- Community gardens or shared plantations
- Group farming operations
- Single decision-making entity
→ Read **[8_COLLECTIVE_FLOW.md](8_COLLECTIVE_FLOW.md)**

### 👥 Individual
One FCA group with MULTIPLE individual farmers. Each farmer tracks their own commodities. Good for:
- Farmer associations with separate members
- Each farmer has different crops/livestock
- Member-by-member tracking
→ Read **[9_INDIVIDUAL_HYBRID_FLOW.md](9_INDIVIDUAL_HYBRID_FLOW.md)**

### 🔗 Hybrid
Mix of both: some group commodities AND individual farmer commodities. Good for:
- FCA with shared resources (group land) AND private farms
- Combination of collective and individual activities
→ Read **[9_INDIVIDUAL_HYBRID_FLOW.md](9_INDIVIDUAL_HYBRID_FLOW.md)**
  - John Fruto Ambal (SAAD ID: 1)
  - Maribel Oflaria Baltazar (SAAD ID: 1000p)
- Reporting Period: 2026
- Primary Intervention: Coconut
- Location: Barangay 2, Lipa City, Batangas

---

**Last Updated:** May 13, 2026

# Crop Field Organization & Display Flow

## Overview
Crop monitoring collects data across **7 steps**, organizing fields by category. When viewing completed commodities, fields are accumulated from multiple steps into a single commodity object.

---

## Step-by-Step Field Breakdown

### **Step 01: Project Background**
**Purpose:** Group-level information (same for all farmers/commodities in a group)

**Fields Collected:**
- FCA Name
- Reporting Period
- Project Title
- Project Description
- Implementation Type (Individual/Collective/Hybrid)
- Members (for collective/hybrid)

**Display When Viewing:** Not shown in commodity (group-level only)

---

### **Step 02: Commodity Information**
**Purpose:** Individual commodity/batch identification

**Fields Collected:**
- Farmer Name
- SAAD ID No.
- **Type of Crop** ⭐ (Primary commodity identifier)
- **Variety** ⭐ (Secondary identifier)
- Spacing (in meters)
- Seedbed Preparation Method
- Pest Management Practice
- Source of Seedlings/Seeds

**Display When Viewing:** ✅ **ALL shown in commodity summary**
- Used to identify and list commodities
- Quick reference for commodity details

---

### **Step 03: Planting to Grow**
**Purpose:** Planting activities and early growth tracking

**Fields Collected:**
- Date Planted
- Farmer Provided Land (Y/N)
- Land Preparation Cost
- Seedlings/Seeds Procured
- FCA-Provided Seedlings (Y/N)
- FCA Seedlings Cost
- Planting Cost
- **Total Seedlings Planted**
- Date of First Weeding
- First Weeding Cost
- Date of Second Weeding
- Second Weeding Cost
- **Total Number Weeded**
- Date Started Fertilizer Application
- Fertilizer Type
- **Total Stocks Fertilized**

**Display When Viewing:** ✅ **ALL shown in commodity details**
- Groups as "Planting to Grow" section
- Shows all planting, land prep, and growth activities

---

### **Step 04: Growth to Flowering**
**Purpose:** Growth progression and flowering tracking

**Fields Collected:**
- Date of Flowering
- Flowering Cost (if any)
- Pest Incidence (Y/N)
- Pest Type (if yes)
- Pest Control Method
- Pest Control Cost
- **Total Number Affected by Pest**
- **Total Number Recovered**
- Disease Incidence (Y/N)
- Disease Type (if yes)
- Disease Management Practice
- Disease Management Cost
- **Total Number Affected by Disease**
- **Total Number Recovered**
- Fertilizer Application Update (date/details)
- Additional Fertilizer Cost

**Display When Viewing:** ✅ **ALL shown in commodity details**
- Groups as "Growth to Flowering" section
- Shows pest & disease tracking with recovery rates

---

### **Step 05: Harvesting Information**
**Purpose:** Harvest activities and yield data

**Fields Collected:**
- Date Started Harvesting
- Harvesting Cost
- **Total Produce Harvested (quantity)**
- **Harvesting Unit** (kg, pieces, bags, etc.)
- Quantity Damaged During Harvest
- Damaged Unit
- **Total Marketable Produce**
- Marketable Unit
- **Farmgate Price of Produce**

**Display When Viewing:** ✅ **ALL shown in commodity details**
- Groups as "Harvesting Information" section
- Shows complete harvest metrics

---

### **Step 06: Post-Harvest**
**Purpose:** Post-harvest handling and storage

**Fields Collected:**
- **Post-Harvest Handling Method**
- Storage Location Type
- **Total Produce Stored** (quantity)
- Storage Unit
- Storage Duration
- Storage Cost
- Quality After Storage
- Loss Due to Storage (%)

**Display When Viewing:** ✅ **ALL shown in commodity details**
- Groups as "Post-Harvest" section
- Shows storage & handling practices

---

### **Step 07: Trainings** _(Group-Level)_
**Purpose:** Record training activities for entire group

**Fields Collected:**
- Training Name
- Training Type
- Date Conducted
- Facilitator Name
- Attendees Count

**Display When Viewing:** ✅ Stored separately (trainings array, group-level)

---

## How Commodity Object is Built

### **Complete Commodity Object Structure:**
```dart
widget.wrapper.completedCommodities.add({
  // Step 02: Commodity Information
  'farmerName': widget.wrapper.farmerName,
  'saadIdNo': widget.wrapper.saadIdNo,
  'typeOfCrop': widget.wrapper.typeOfCrop,           // ← Primary key
  'variety': widget.wrapper.variety,                  // ← Secondary key
  'spacing': widget.wrapper.spacing,
  'seedbedMethod': widget.wrapper.seedbedMethod,
  'pestManagementPractice': widget.wrapper.pestManagementPractice,
  'sourceOfSeeds': widget.wrapper.sourceOfSeeds,
  
  // Step 03: Planting to Grow
  'datePlanted': widget.wrapper.datePlanted,
  'farmerProvidedLand': widget.wrapper.farmerProvidedLand,
  'landPreparationCost': widget.wrapper.landPreparationCost,
  'seedlingsProcured': widget.wrapper.seedlingsProcured,
  'fcaProvidedSeedlings': widget.wrapper.fcaProvidedSeedlings,
  'fcaSeedlingsCost': widget.wrapper.fcaSeedlingsCost,
  'plantingCost': widget.wrapper.plantingCost,
  'totalStocksPlanted': widget.wrapper.totalStocksPlanted,
  'dateFirstWeeding': widget.wrapper.dateFirstWeeding,
  'firstWeedingCost': widget.wrapper.firstWeedingCost,
  'dateSecondWeeding': widget.wrapper.dateSecondWeeding,
  'secondWeedingCost': widget.wrapper.secondWeedingCost,
  'totalStocksWeeded': widget.wrapper.totalStocksWeeded,
  'dateStartedFertilizer': widget.wrapper.dateStartedFertilizer,
  'fertilizerType': widget.wrapper.fertilizerType,
  'totalStocksFertilized': widget.wrapper.totalStocksFertilized,
  
  // Step 04: Growth to Flowering
  'dateFlowering': widget.wrapper.dateFlowering,
  'floweringCost': widget.wrapper.floweringCost,
  'pestIncidence': widget.wrapper.pestIncidence,
  'pestType': widget.wrapper.pestType,
  'pestControlMethod': widget.wrapper.pestControlMethod,
  'pestControlCost': widget.wrapper.pestControlCost,
  'totalAffectedByPest': widget.wrapper.totalAffectedByPest,
  'totalRecoveredFromPest': widget.wrapper.totalRecoveredFromPest,
  'diseaseIncidence': widget.wrapper.diseaseIncidence,
  'diseaseType': widget.wrapper.diseaseType,
  'diseaseManagementPractice': widget.wrapper.diseaseManagementPractice,
  'diseaseManagementCost': widget.wrapper.diseaseManagementCost,
  'totalAffectedByDisease': widget.wrapper.totalAffectedByDisease,
  'totalRecoveredFromDisease': widget.wrapper.totalRecoveredFromDisease,
  
  // Step 05: Harvesting Information
  'dateStartedHarvesting': widget.wrapper.dateStartedHarvesting,
  'harvestingCost': widget.wrapper.harvestingCost,
  'totalProduceHarvested': widget.wrapper.totalProduceHarvested,
  'harvestingUnit': widget.wrapper.harvestingUnit,
  'quantityDamagedDuringHarvest': widget.wrapper.quantityDamagedDuringHarvest,
  'damagedUnit': widget.wrapper.damagedUnit,
  'totalMarketableProduce': widget.wrapper.totalMarketableProduce,
  'marketableUnit': widget.wrapper.marketableUnit,
  'farmgatePriceOfProduce': widget.wrapper.farmgatePriceOfProduce,
  
  // Step 06: Post-Harvest
  'postHarvestHandlingMethod': widget.wrapper.postHarvestHandlingMethod,
  'storageLocationType': widget.wrapper.storageLocationType,
  'totalProduceStored': widget.wrapper.totalProduceStored,
  'storageUnit': widget.wrapper.storageUnit,
  'storageDuration': widget.wrapper.storageDuration,
  'storageCost': widget.wrapper.storageCost,
  'qualityAfterStorage': widget.wrapper.qualityAfterStorage,
  'lossPercentageDueToStorage': widget.wrapper.lossPercentageDueToStorage,
});
```

---

## Display Organization in Summary Screen

When viewing a completed commodity, fields are displayed in **7 organized sections**:

### **Section 1: Commodity Identification** (Step 02)
```
Farmer Name: [name]
SAAD ID: [id]
Crop Type: [type of crop] ⭐
Variety: [variety] ⭐
Spacing: [meters]
Seedbed Method: [method]
Pest Management: [practice]
Seeds Source: [source]
```

### **Section 2: Planting to Grow** (Step 03)
```
Date Planted: [date]
Land Provided by Farmer: [Y/N]
Land Prep Cost: [amount]
Seedlings Procured: [count]
FCA Provided Seedlings: [Y/N]
FCA Seedlings Cost: [amount]
Planting Cost: [amount]
Total Planted: [count] ⭐
[Weeding 1 details...]
[Weeding 2 details...]
Total Weeded: [count]
[Fertilizer details...]
Total Fertilized: [count] ⭐
```

### **Section 3: Growth to Flowering** (Step 04)
```
Flowering Date: [date]
Flowering Cost: [amount]
Pest Incidence: [Y/N]
  - Pest Type: [type]
  - Control Method: [method]
  - Control Cost: [amount]
  - Total Affected: [count]
  - Total Recovered: [count]
Disease Incidence: [Y/N]
  - Disease Type: [type]
  - Management: [practice]
  - Management Cost: [amount]
  - Total Affected: [count]
  - Total Recovered: [count]
```

### **Section 4: Harvesting Information** (Step 05)
```
Harvest Start Date: [date]
Harvesting Cost: [amount]
Total Harvested: [count] [unit] ⭐
Quantity Damaged: [count] [unit]
Total Marketable: [count] [unit] ⭐
Farmgate Price: [price] ⭐
```

### **Section 5: Post-Harvest** (Step 06)
```
Handling Method: [method]
Storage Location: [type]
Total Stored: [count] [unit]
Storage Duration: [duration]
Storage Cost: [amount]
Quality After Storage: [quality]
Storage Loss %: [percentage]
```

### **Section 6: Trainings** (Step 07 - Group Level)
```
Training Name: [name]
Type: [type]
Date: [date]
Facilitator: [name]
Attendees: [count]
```

---

## Key Metrics Tracked

### **Production Efficiency Metrics:**
- Total Planted → Total Weeded → Total Fertilized (progression)
- Pest/Disease impact: Affected vs Recovered rate
- Harvest yield: Total Harvested → Damaged → Marketable

### **Cost Tracking:**
- Land prep, seedlings, planting
- Weeding (1st & 2nd)
- Fertilizer application
- Pest/disease management
- Harvesting
- Post-harvest storage

### **Quality Indicators:**
- Storage loss percentage
- Quality after storage
- Marketable vs damaged produce ratio

---

## Summary

**Crop monitoring is organized as:**
- **5 Input Steps** (02-06): Collect specific production data at each stage
- **1 Output Step** (07): Track group-level trainings
- **2 Display Steps** (02-06): Show accumulated commodity data organized by production phase

**Complete commodity object contains 40+ fields** spread across:
- Identification (6 fields)
- Planting Phase (12 fields)
- Growth Phase (13 fields)
- Harvest Phase (9 fields)
- Post-Harvest Phase (8 fields)

This allows for **comprehensive production tracking** from land prep through storage, with visibility into costs, quantities, quality, and pest/disease management at each stage.

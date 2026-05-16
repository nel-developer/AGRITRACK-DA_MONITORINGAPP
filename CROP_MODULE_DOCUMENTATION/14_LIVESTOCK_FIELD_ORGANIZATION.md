# Livestock Field Organization & Display Flow

## Overview
Livestock monitoring collects data across **5 steps**, organizing fields by category. When viewing completed batches, fields are accumulated from multiple steps into a single batch object.

---

## Step-by-Step Field Breakdown

### **Step 01: Project Background**
**Purpose:** Group-level information (same for all farmers/batches in a group)

**Fields Collected:**
- FCA Name
- Reporting Period
- Project Title
- Project Description
- Implementation Type (Individual/Collective/Hybrid)
- Members (for collective/hybrid)

**Display When Viewing:** Not shown in batch (group-level only)

---

### **Step 02: Livestock Information**
**Purpose:** Individual batch/commodity identification and basic inputs

**Fields Collected:**
- Farmer Name
- SAAD ID No.
- **Breed** ⭐ (Primary batch identifier - similar to crop's "typeOfCrop")
- Inputs Received from SAAD (list)
- Inputs Purchased by FCA (list)
- Farmgate Price of Each Produce (list)

**Also Collected (Production Information Part):**
- Stocks Received (count)
- Date Received
- Male Stocks
- Female Stocks
- Male to Female Stocks Ratio

**Display When Viewing:** ✅ **ALL shown in batch summary**
- Used to identify and list batches
- Quick reference for batch details

---

### **Step 03: Production Information**
**Purpose:** Housing, management, and care practices

**Fields Collected:**
- Housing Type
- Farm Ownership (status)
- With Usufruct/Land Use Agreement (Y/N)
- Livestock Health Management Activities
- Waste Management/Disposal Practices

**Additional Fields:**
- Age Upon Receipt (months)
- Average Weight Upon Receipt
- Number of Pregnant Stocks

**Display When Viewing:** ⚠️ **NOT YET IMPLEMENTED** (need to add to batch object)

---

### **Step 04: Trainings** _(NOT MODIFIED)_
**Purpose:** Record training activities

**Fields Collected:**
- Training Name
- Training Type
- Date Conducted
- Facilitator Name
- Attendees Count

**Display When Viewing:** ✅ Stored separately (trainings array)

---

### **Step 05: Production & Harvesting Information**
**Purpose:** Purpose-specific production & output metrics

**Displayed First in Step 05:**
- **Purpose of Production Checkboxes:** (moved from Step 01)
  - Breeding (Y/N)
  - Meat / Fattener (Y/N)
  - Dairy (Y/N)

**Purpose-Specific Fields:**

#### **If Breeding = ON:**
- Identify Actual Grow-Out Period
- Number of Produced Offspring
- Male Offspring Stocks
- Female Offspring Stocks
- Male to Female Offspring Ratio
- Number of Mortalities After Birth
- Indicate Number of Remaining Offspring
- Indicate Number of Slaughtered Livestock
- Indicate Price of Slaughtered Livestock

#### **If Meat/Fattener = ON:**
- Identify Actual Grow-Out Period
- Sold as Liveweight (Y/N)
- Average Marketable Weight

#### **If Dairy = ON:**
- Identify Lactation Period (date)
- Identify Dry Period (date)
- Average Volume of Milk Produced Daily
- Farmgate Price of Milk in the Area
- Unit (of milk)

**Display When Viewing:** ⚠️ **NOT YET IMPLEMENTED** (need to add to batch object)

---

## How Batch Object is Built

### **Current Implementation (Step 02 only):**
```dart
widget.wrapper.completedBatches.add({
  'farmerName': widget.wrapper.farmerName,
  'saadIdNo': widget.wrapper.saadIdNo,
  'breed': widget.wrapper.breed,                    // ← Primary key
  'inputsReceived': widget.wrapper.inputsReceived.map(...),
  'inputsPurchased': widget.wrapper.inputsPurchased.map(...),
  'farmgatePrices': widget.wrapper.farmgatePrices,
  'stocksReceived': widget.wrapper.stocksReceived,
  'dateReceived': widget.wrapper.dateReceived,
  'maleStocks': widget.wrapper.maleStocks,
  'femaleStocks': widget.wrapper.femaleStocks,
  'maleToFemaleRatio': widget.wrapper.maleToFemaleRatio,
});
```

### **Needed (Full Implementation):**
```dart
widget.wrapper.completedBatches.add({
  // Step 02 fields (currently included)
  'farmerName': widget.wrapper.farmerName,
  'saadIdNo': widget.wrapper.saadIdNo,
  'breed': widget.wrapper.breed,
  'inputsReceived': widget.wrapper.inputsReceived.map(...),
  'inputsPurchased': widget.wrapper.inputsPurchased.map(...),
  'farmgatePrices': widget.wrapper.farmgatePrices,
  'stocksReceived': widget.wrapper.stocksReceived,
  'dateReceived': widget.wrapper.dateReceived,
  'maleStocks': widget.wrapper.maleStocks,
  'femaleStocks': widget.wrapper.femaleStocks,
  'maleToFemaleRatio': widget.wrapper.maleToFemaleRatio,
  
  // Step 03 fields (need to add)
  'ageUponReceipt': widget.wrapper.ageUponReceipt,
  'avgWeightUponReceipt': widget.wrapper.avgWeightUponReceipt,
  'pregnantStocks': widget.wrapper.pregnantStocks,
  'housingType': widget.wrapper.housingType,
  'farmOwnership': widget.wrapper.farmOwnership,
  'farmOwnershipOther': widget.wrapper.farmOwnershipOther,
  'usufruct': widget.wrapper.usufruct,
  'usufructRemarks': widget.wrapper.usufructRemarks,
  'healthActivities': widget.wrapper.healthActivities,
  'healthOthers': widget.wrapper.healthOthers,
  'wasteManagement': widget.wrapper.wasteManagement,
  
  // Step 05 fields (need to add)
  'purposeBreeding': widget.wrapper.purposeBreeding,
  'purposeMeat': widget.wrapper.purposeMeat,
  'purposeDairy': widget.wrapper.purposeDairy,
  'growOutPeriod': widget.wrapper.growOutPeriod,
  'lactationPeriod': widget.wrapper.lactationPeriod,
  'dryPeriod': widget.wrapper.dryPeriod,
  'producedOffspring': widget.wrapper.producedOffspring,
  'offspringMale': widget.wrapper.offspringMale,
  'offspringFemale': widget.wrapper.offspringFemale,
  'offspringMFRatio': widget.wrapper.offspringMFRatio,
  'mortalitiesAfterBirth': widget.wrapper.mortalitiesAfterBirth,
  'remainingOffspring': widget.wrapper.remainingOffspring,
  'soldAsLiveweight': widget.wrapper.soldAsLiveweight,
  'soldAsLiveweightRemarks': widget.wrapper.soldAsLiveweightRemarks,
  'avgMarketableWeight': widget.wrapper.avgMarketableWeight,
  'milkVolumeDaily': widget.wrapper.milkVolumeDaily,
  'farmgatePriceMilk': widget.wrapper.farmgatePriceMilk,
  'milkUnit': widget.wrapper.milkUnit,
  'slaughteredCount': widget.wrapper.slaughteredCount,
  'slaughteredPrice': widget.wrapper.slaughteredPrice,
});
```

---

## Comparison with Crop Monitoring

### **Crop:**
- **Step 02** → Crop Information (typeOfCrop, variety, spacing, etc.)
- **Steps 03-07** → All planting, growth, and harvesting details
- **Batch Display:** Shows all step fields together

### **Livestock (Current):**
- **Step 02** → Livestock Information (breed, stocks, inputs)
- **Step 03** → Production Information (housing, management)
- **Step 05** → Production & Harvesting (purposes, outputs)
- **Batch Display:** ⚠️ Only showing Step 02 fields

### **Key Difference:**
Livestock separates "production" and "harvesting" into different steps (03 vs 05), while crop combines them into a single workflow progression (Steps 03-07).

---

## Summary

| Step | Category | Status | In Batch? |
|------|----------|--------|-----------|
| 01 | Group Info | ✅ Complete | ❌ No (group-level) |
| 02 | Livestock Identification | ✅ Complete | ✅ **Yes** |
| 03 | Production Management | ✅ Complete | ⚠️ **Partially** |
| 04 | Trainings | ✅ Complete | ✅ **Yes** (separate array) |
| 05 | Production & Harvesting | ✅ Complete | ⚠️ **No** |

**Action Items:**
1. Update `completedBatches` to include Step 03 fields
2. Update `completedBatches` to include Step 05 fields
3. Update batch viewing screen to display all fields by section

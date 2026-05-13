class TrainingEntry {
  String name = '';
  String date = '';
  String attendees = '';

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'date': date,
      'attendees': attendees,
    };
  }
}

class InputReceived {
  String name = '';
  String quantity = '';

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
    };
  }
}

class InputPurchased {
  String name = '';
  String quantity = '';
  String cost = '';
  String month = '';

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'cost': cost,
      'month': month,
    };
  }
}

class CropStepWrapper {
  // Set by ImplementationTypeScreen BEFORE Step 1 is pushed
  String? implementationType; // 'individual' | 'collective' | 'hybrid'

  // True when navigating straight to Step 2 to add a new farmer (skip Step 1)
  bool isAddFarmer = false;

  // True when adding a new commodity to an existing farmer (not a new farmer)
  bool isAddingNewCommodity = false;

  // True when adding a new commodity to the GROUP (not to a farmer)
  bool isAddingGroupCommodity = false;

  // True when editing an existing draft
  bool isEditingDraft = false;

  // ── Step 1: Project Background ───────────────────────────────
  String reportingPeriod = '';
  String fcaName = '';
  String? region;
  String? province;
  String? municipality;
  String? barangay;
  String projectTitle = '';
  String? primaryIntervention;
  String primaryInterventionOther = '';
  List<String> supportInterventions = [];

  // ── Step 2: Commodity Information ───────────────────────────
  String saadIdNo = '';
  Map<String, dynamic> approvedFarmerProfile = {};
  String farmerName = '';
  List<Map<String, dynamic>> members = [];

  // ── Completed commodities for this farmer (tracks 1+ commodities per farmer) ──
  List<Map<String, dynamic>> completedCommodities = [];

  String typeOfCrop = '';
  String variety = '';
  List<InputReceived> inputsReceived = [];
  List<InputPurchased> inputsPurchased = [];
  String totalCostPurchased = '';
  String qtyVsArea = '';
  String croppingCycles = '';
  String qtyVsCycles = '';
  String peakVolume = '';
  String peakMonth = '';
  List<String> volumesPerCycle = [];
  String farmgatePrice = '';

  // ── Step 3: Planting to Growing Stage ───────────────────────
  String totalLandArea = '';
  String? landOwnership;
  String landOwnershipOther = '';
  String? usufructAgreement;
  List<String> landRemarks = [];
  String? machineryType;
  String machineryOther = '';
  List<String> machineryRemarks = [];
  List<String> landPrepCostPerCycle = [''];
  String landPrepStartDate = '';
  String landPrepDays = '';
  String sourceOfWater = '';
  String plantingDate = '';
  String seedAmount = '';
  String seedUnit = '';
  String germinationRate = '';
  String? goodGermination;
  String germinationReason = '';

  // ── Step 4: Fertilization Requirement ───────────────────────
  String? fertilizerType;
  String? organicSource;
  String organicBagsSAAD = '';
  String organicBagsCommercial = '';
  String organicTotalCost = '';
  String organicBagsCycle = '';
  String organicFrequency = '';
  String inorganicType = '';
  String inorganicBagsSAAD = '';
  String inorganicMeasure = '';
  String inorganicTotalCost = '';
  List<String> inorganicBagsCycle = [''];
  String inorganicFrequency = '';
  String pesticideRequirement = '';

  // ── Step 5: Harvesting Stage ─────────────────────────────────
  List<String> landAreaCycles = [''];
  List<String> dateHarvestCycles = [''];
  List<String> quantityCycles = [''];
  String avgHarvestPerHa = '';
  List<String> harvestCostCycles = [''];
  String foodConsumptionPct = '';
  String processingFile = '';
  List<String> processingRemarks = [];

  // ── Step 6: Crop Damage Information ─────────────────────────
  bool hasPest = false;
  String pestOccurrence = '';
  String pestDate = '';
  String pestDamageArea = '';
  String pestDamageHa = '';
  String pestTreatment = '';
  String pestAttached = '';

  bool hasDisease = false;
  String diseaseOccurrence = '';
  String diseaseDate = '';
  String diseaseDamageArea = '';
  String diseaseDamageHa = '';
  String diseaseTreatment = '';
  String diseaseAttached = '';

  bool hasEnvHazard = false;
  List<String> envHazards = [''];
  String envDate = '';
  String envDamageArea = '';
  String envDamageHa = '';
  String envTreatment = '';
  String envAttached = '';

  bool hasHumanDamage = false;
  String humanDamage = '';
  String humanMortality = '';
  String humanTreatment = '';
  String humanAttached = '';

  // ── Step 7: Trainings Attended (LAST STEP) ───────────────────
  List<TrainingEntry> trainings = [TrainingEntry()];
  String farmPhoto = '';

  /// Clears commodity and stage-specific fields while preserving
  /// completed commodities and project/group metadata.
  void resetCommodityStageFields() {
    typeOfCrop = '';
    variety = '';
    inputsReceived = [];
    inputsPurchased = [];
    totalCostPurchased = '';
    qtyVsArea = '';
    croppingCycles = '';
    qtyVsCycles = '';
    peakVolume = '';
    peakMonth = '';
    volumesPerCycle = [''];
    farmgatePrice = '';
    totalLandArea = '';
    landOwnership = null;
    landOwnershipOther = '';
    usufructAgreement = null;
    landRemarks = [];
    machineryType = null;
    machineryOther = '';
    machineryRemarks = [];
    landPrepCostPerCycle = [''];
    landPrepStartDate = '';
    landPrepDays = '';
    sourceOfWater = '';
    plantingDate = '';
    seedAmount = '';
    seedUnit = '';
    germinationRate = '';
    goodGermination = null;
    germinationReason = '';
    fertilizerType = null;
    organicSource = null;
    organicBagsSAAD = '';
    organicBagsCommercial = '';
    organicTotalCost = '';
    organicBagsCycle = '';
    organicFrequency = '';
    inorganicType = '';
    inorganicBagsSAAD = '';
    inorganicMeasure = '';
    inorganicTotalCost = '';
    inorganicBagsCycle = [''];
    inorganicFrequency = '';
    pesticideRequirement = '';
    landAreaCycles = [''];
    dateHarvestCycles = [''];
    quantityCycles = [''];
    avgHarvestPerHa = '';
    harvestCostCycles = [''];
    foodConsumptionPct = '';
    processingFile = '';
    processingRemarks = [];
    hasPest = false;
    pestOccurrence = '';
    pestDate = '';
    pestDamageArea = '';
    pestDamageHa = '';
    pestTreatment = '';
    pestAttached = '';
    hasDisease = false;
    diseaseOccurrence = '';
    diseaseDate = '';
    diseaseDamageArea = '';
    diseaseDamageHa = '';
    diseaseTreatment = '';
    diseaseAttached = '';
    hasEnvHazard = false;
    envHazards = [''];
    envDate = '';
    envDamageArea = '';
    envDamageHa = '';
    envTreatment = '';
    envAttached = '';
    hasHumanDamage = false;
    humanDamage = '';
    humanMortality = '';
    humanTreatment = '';
    humanAttached = '';
  }

  /// Resets farmer-specific data when adding a new farmer.
  /// Clears farmer name, SAAD ID, completed commodities, trainings, and photos.
  void resetForNewFarmer() {
    saadIdNo = '';
    approvedFarmerProfile = {};
    farmerName = '';
    completedCommodities = [];
    // Reset trainings and photos for new farmer (empty lists indicate fresh start)
    trainings = [];
    farmPhoto = '';
    resetCommodityStageFields();
  }

  /// Resets trainings and photo after saving/navigating.
  /// Prepares the wrapper for the next commodity entry.
  void resetTrainingAndPhoto() {
    trainings = [TrainingEntry()];
    farmPhoto = '';
  }

  Map<String, dynamic> toJson() {
    // ✅ FIX: HYBRID should ALWAYS include farmerName/saadIdNo when saving farmer-specific data
    // The isGroupRecord logic was incorrectly clearing farmer name when selecting approved farmers

    // CRITICAL: For collectives, NEVER include farmerName in JSON
    // This ensures the group name (fcaName) is never overwritten
    final isCollective = implementationType?.toLowerCase() == 'collective';
    final isHybrid = implementationType?.toLowerCase() == 'hybrid';

    // For HYBRID: ALWAYS keep farmerName and saadIdNo - they're needed for ALL farmer records
    // Whether we're adding a new farmer (isAddFarmer=true) or selecting approved farmer (isAddFarmer=false)
    // For INDIVIDUAL: Always keep farmerName and completedCommodities
    // For COLLECTIVE: Never include farmer-specific data

    // Since this method is used when saving farmer-specific records (not group background),
    // isGroupRecord should be false - we always save commodity data
    const isGroupRecord = false;

    return {
      'implementationType': implementationType,
      'isAddFarmer': isAddFarmer,
      'reportingPeriod': reportingPeriod,
      'fcaName': fcaName,
      'region': region,
      'province': province,
      'municipality': municipality,
      'barangay': barangay,
      'projectTitle': projectTitle,
      'primaryIntervention': primaryIntervention,
      'primaryInterventionOther': primaryInterventionOther,
      'supportInterventions': supportInterventions,
      'saadIdNo':
          isCollective ? '' : saadIdNo, // ✅ Always keep for HYBRID & INDIVIDUAL
      'approvedFarmerProfile': isCollective
          ? {}
          : approvedFarmerProfile, // ✅ Always keep for HYBRID & INDIVIDUAL
      'farmerName': isCollective
          ? ''
          : farmerName, // ✅ Always keep for HYBRID & INDIVIDUAL
      'members': members,
      'completedCommodities': isGroupRecord
          ? []
          : completedCommodities, // ✅ Empty for HYBRID group records only
      'typeOfCrop': isGroupRecord
          ? ''
          : typeOfCrop, // ✅ Empty for HYBRID group records only
      'variety':
          isGroupRecord ? '' : variety, // ✅ Empty for HYBRID group records only
      'inputsReceived': isGroupRecord
          ? []
          : inputsReceived
              .map((item) => item.toJson())
              .toList(), // ✅ Empty for HYBRID group
      'inputsPurchased': isGroupRecord
          ? []
          : inputsPurchased
              .map((item) => item.toJson())
              .toList(), // ✅ Empty for HYBRID group
      'totalCostPurchased':
          isGroupRecord ? '' : totalCostPurchased, // ✅ Empty for HYBRID group
      'qtyVsArea': isGroupRecord ? '' : qtyVsArea, // ✅ Empty for HYBRID group
      'croppingCycles':
          isGroupRecord ? '' : croppingCycles, // ✅ Empty for HYBRID group
      'qtyVsCycles':
          isGroupRecord ? '' : qtyVsCycles, // ✅ Empty for HYBRID group
      'peakVolume': isGroupRecord ? '' : peakVolume, // ✅ Empty for HYBRID group
      'peakMonth': isGroupRecord ? '' : peakMonth, // ✅ Empty for HYBRID group
      'volumesPerCycle':
          isGroupRecord ? [] : volumesPerCycle, // ✅ Empty for group
      'farmgatePrice': isGroupRecord ? '' : farmgatePrice, // ✅ Empty for group
      'totalLandArea': isGroupRecord ? '' : totalLandArea, // ✅ Empty for group
      'landOwnership': isGroupRecord ? null : landOwnership, // ✅ Null for group
      'landOwnershipOther':
          isGroupRecord ? '' : landOwnershipOther, // ✅ Empty for group
      'usufructAgreement':
          isGroupRecord ? null : usufructAgreement, // ✅ Null for group
      'landRemarks': isGroupRecord ? [] : landRemarks, // ✅ Empty for group
      'machineryType': isGroupRecord ? null : machineryType, // ✅ Null for group
      'machineryOther':
          isGroupRecord ? '' : machineryOther, // ✅ Empty for group
      'machineryRemarks':
          isGroupRecord ? [] : machineryRemarks, // ✅ Empty for group
      'landPrepCostPerCycle':
          isGroupRecord ? [] : landPrepCostPerCycle, // ✅ Empty for group
      'landPrepStartDate':
          isGroupRecord ? '' : landPrepStartDate, // ✅ Empty for group
      'landPrepDays': isGroupRecord ? '' : landPrepDays, // ✅ Empty for group
      'sourceOfWater': isGroupRecord ? '' : sourceOfWater, // ✅ Empty for group
      'plantingDate': isGroupRecord ? '' : plantingDate, // ✅ Empty for group
      'seedAmount': isGroupRecord ? '' : seedAmount, // ✅ Empty for group
      'seedUnit': isGroupRecord ? '' : seedUnit, // ✅ Empty for group
      'germinationRate':
          isGroupRecord ? '' : germinationRate, // ✅ Empty for group
      'goodGermination':
          isGroupRecord ? '' : goodGermination, // ✅ Empty for group
      'germinationReason':
          isGroupRecord ? '' : germinationReason, // ✅ Empty for group
      'fertilizerType':
          isGroupRecord ? null : fertilizerType, // ✅ Null for group
      'organicSource': isGroupRecord ? '' : organicSource, // ✅ Empty for group
      'organicBagsSAAD':
          isGroupRecord ? '' : organicBagsSAAD, // ✅ Empty for group
      'organicBagsCommercial':
          isGroupRecord ? '' : organicBagsCommercial, // ✅ Empty for group
      'organicTotalCost':
          isGroupRecord ? '' : organicTotalCost, // ✅ Empty for group
      'organicBagsCycle':
          isGroupRecord ? '' : organicBagsCycle, // ✅ Empty for group
      'organicFrequency':
          isGroupRecord ? '' : organicFrequency, // ✅ Empty for group
      'inorganicType': isGroupRecord ? null : inorganicType, // ✅ Null for group
      'inorganicBagsSAAD':
          isGroupRecord ? '' : inorganicBagsSAAD, // ✅ Empty for group
      'inorganicMeasure':
          isGroupRecord ? '' : inorganicMeasure, // ✅ Empty for group
      'inorganicTotalCost':
          isGroupRecord ? '' : inorganicTotalCost, // ✅ Empty for group
      'inorganicBagsCycle':
          isGroupRecord ? '' : inorganicBagsCycle, // ✅ Empty for group
      'inorganicFrequency':
          isGroupRecord ? '' : inorganicFrequency, // ✅ Empty for group
      'pesticideRequirement':
          isGroupRecord ? '' : pesticideRequirement, // ✅ Empty for group
      'landAreaCycles':
          isGroupRecord ? [] : landAreaCycles, // ✅ Empty for group
      'dateHarvestCycles':
          isGroupRecord ? [] : dateHarvestCycles, // ✅ Empty for group
      'quantityCycles':
          isGroupRecord ? [] : quantityCycles, // ✅ Empty for group
      'avgHarvestPerHa':
          isGroupRecord ? '' : avgHarvestPerHa, // ✅ Empty for group
      'harvestCostCycles':
          isGroupRecord ? [] : harvestCostCycles, // ✅ Empty for group
      'foodConsumptionPct':
          isGroupRecord ? '' : foodConsumptionPct, // ✅ Empty for group

      'processingFile':
          isGroupRecord ? '' : processingFile, // ✅ Empty for group
      'processingRemarks':
          isGroupRecord ? '' : processingRemarks, // ✅ Empty for group
      'hasPest': isGroupRecord ? null : hasPest, // ✅ Null for group
      'pestOccurrence':
          isGroupRecord ? '' : pestOccurrence, // ✅ Empty for group
      'pestDate': isGroupRecord ? '' : pestDate, // ✅ Empty for group
      'pestDamageArea':
          isGroupRecord ? '' : pestDamageArea, // ✅ Empty for group
      'pestDamageHa': isGroupRecord ? '' : pestDamageHa, // ✅ Empty for group
      'pestTreatment': isGroupRecord ? '' : pestTreatment, // ✅ Empty for group
      'pestAttached': isGroupRecord ? '' : pestAttached, // ✅ Empty for group
      'hasDisease': isGroupRecord ? null : hasDisease, // ✅ Null for group
      'diseaseOccurrence':
          isGroupRecord ? '' : diseaseOccurrence, // ✅ Empty for group
      'diseaseDate': isGroupRecord ? '' : diseaseDate, // ✅ Empty for group
      'diseaseDamageArea':
          isGroupRecord ? '' : diseaseDamageArea, // ✅ Empty for group
      'diseaseDamageHa':
          isGroupRecord ? '' : diseaseDamageHa, // ✅ Empty for group
      'diseaseTreatment':
          isGroupRecord ? '' : diseaseTreatment, // ✅ Empty for group
      'diseaseAttached':
          isGroupRecord ? '' : diseaseAttached, // ✅ Empty for group
      'hasEnvHazard': isGroupRecord ? null : hasEnvHazard, // ✅ Null for group
      'envHazards': isGroupRecord ? [] : envHazards, // ✅ Empty for group
      'envDate': isGroupRecord ? '' : envDate, // ✅ Empty for group
      'envDamageArea': isGroupRecord ? '' : envDamageArea, // ✅ Empty for group
      'envDamageHa': isGroupRecord ? '' : envDamageHa, // ✅ Empty for group
      'envTreatment': isGroupRecord ? '' : envTreatment, // ✅ Empty for group
      'envAttached': isGroupRecord ? '' : envAttached, // ✅ Empty for group
      'hasHumanDamage':
          isGroupRecord ? null : hasHumanDamage, // ✅ Null for group
      'humanDamage': isGroupRecord ? '' : humanDamage, // ✅ Empty for group
      'humanMortality':
          isGroupRecord ? '' : humanMortality, // ✅ Empty for group
      'humanTreatment':
          isGroupRecord ? '' : humanTreatment, // ✅ Empty for group
      'humanAttached': isGroupRecord ? '' : humanAttached, // ✅ Empty for group
      'trainings': isGroupRecord
          ? []
          : trainings
              .map((item) => item.toJson())
              .toList(), // ✅ Empty for group
      'farmPhoto': isGroupRecord ? '' : farmPhoto, // ✅ Empty for group
    };
  }
}

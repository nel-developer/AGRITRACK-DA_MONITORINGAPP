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

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'cost': cost,
    };
  }
}

class CropStepWrapper {
  // Set by ImplementationTypeScreen BEFORE Step 1 is pushed
  String? implementationType; // 'individual' | 'collective' | 'hybrid'

  // True when navigating straight to Step 2 to add a new farmer (skip Step 1)
  bool isAddFarmer = false;

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
  String postharvestFile = '';
  List<String> postharvestRemarks = [];
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
    postharvestFile = '';
    postharvestRemarks = [];
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
  /// Clears farmer name, SAAD ID, completed commodities, and resets commodity fields.
  void resetForNewFarmer() {
    saadIdNo = '';
    approvedFarmerProfile = {};
    farmerName = '';
    completedCommodities = [];
    resetCommodityStageFields();
  }

  Map<String, dynamic> toJson() {
    // CRITICAL: For collectives, NEVER include farmerName in JSON
    // This ensures the group name (fcaName) is never overwritten
    final isCollective = implementationType?.toLowerCase() == 'collective';

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
      'saadIdNo': saadIdNo,
      'approvedFarmerProfile': approvedFarmerProfile,
      'farmerName': isCollective ? '' : farmerName,
      'members': members,
      'completedCommodities': completedCommodities,
      'typeOfCrop': typeOfCrop,
      'variety': variety,
      'inputsReceived': inputsReceived.map((item) => item.toJson()).toList(),
      'inputsPurchased': inputsPurchased.map((item) => item.toJson()).toList(),
      'totalCostPurchased': totalCostPurchased,
      'qtyVsArea': qtyVsArea,
      'croppingCycles': croppingCycles,
      'qtyVsCycles': qtyVsCycles,
      'peakVolume': peakVolume,
      'peakMonth': peakMonth,
      'volumesPerCycle': volumesPerCycle,
      'farmgatePrice': farmgatePrice,
      'totalLandArea': totalLandArea,
      'landOwnership': landOwnership,
      'landOwnershipOther': landOwnershipOther,
      'usufructAgreement': usufructAgreement,
      'landRemarks': landRemarks,
      'machineryType': machineryType,
      'machineryOther': machineryOther,
      'machineryRemarks': machineryRemarks,
      'landPrepCostPerCycle': landPrepCostPerCycle,
      'landPrepStartDate': landPrepStartDate,
      'landPrepDays': landPrepDays,
      'sourceOfWater': sourceOfWater,
      'plantingDate': plantingDate,
      'seedAmount': seedAmount,
      'seedUnit': seedUnit,
      'germinationRate': germinationRate,
      'goodGermination': goodGermination,
      'germinationReason': germinationReason,
      'fertilizerType': fertilizerType,
      'organicSource': organicSource,
      'organicBagsSAAD': organicBagsSAAD,
      'organicBagsCommercial': organicBagsCommercial,
      'organicTotalCost': organicTotalCost,
      'organicBagsCycle': organicBagsCycle,
      'organicFrequency': organicFrequency,
      'inorganicType': inorganicType,
      'inorganicBagsSAAD': inorganicBagsSAAD,
      'inorganicMeasure': inorganicMeasure,
      'inorganicTotalCost': inorganicTotalCost,
      'inorganicBagsCycle': inorganicBagsCycle,
      'inorganicFrequency': inorganicFrequency,
      'pesticideRequirement': pesticideRequirement,
      'landAreaCycles': landAreaCycles,
      'dateHarvestCycles': dateHarvestCycles,
      'quantityCycles': quantityCycles,
      'avgHarvestPerHa': avgHarvestPerHa,
      'harvestCostCycles': harvestCostCycles,
      'foodConsumptionPct': foodConsumptionPct,
      'postharvestFile': postharvestFile,
      'postharvestRemarks': postharvestRemarks,
      'processingFile': processingFile,
      'processingRemarks': processingRemarks,
      'hasPest': hasPest,
      'pestOccurrence': pestOccurrence,
      'pestDate': pestDate,
      'pestDamageArea': pestDamageArea,
      'pestDamageHa': pestDamageHa,
      'pestTreatment': pestTreatment,
      'pestAttached': pestAttached,
      'hasDisease': hasDisease,
      'diseaseOccurrence': diseaseOccurrence,
      'diseaseDate': diseaseDate,
      'diseaseDamageArea': diseaseDamageArea,
      'diseaseDamageHa': diseaseDamageHa,
      'diseaseTreatment': diseaseTreatment,
      'diseaseAttached': diseaseAttached,
      'hasEnvHazard': hasEnvHazard,
      'envHazards': envHazards,
      'envDate': envDate,
      'envDamageArea': envDamageArea,
      'envDamageHa': envDamageHa,
      'envTreatment': envTreatment,
      'envAttached': envAttached,
      'hasHumanDamage': hasHumanDamage,
      'humanDamage': humanDamage,
      'humanMortality': humanMortality,
      'humanTreatment': humanTreatment,
      'humanAttached': humanAttached,
      'trainings': trainings.map((item) => item.toJson()).toList(),
      'farmPhoto': farmPhoto,
    };
  }
}

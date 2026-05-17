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

class PoultryInputReceived {
  String name = '';
  String quantity = '';

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
    };
  }
}

class PoultryInputPurchased {
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

class PoultryStepWrapper {
  // ── Step 1: Project Background ───────────────────────────────
  String reportingPeriod = '';
  String fcaName = '';
  String? region;
  String? province;
  String? municipality;
  String? barangay;
  String projectTitle = '';
  String? primaryIntervention;
  List<String> supportInterventions = [];
  // Purpose of Production
  bool purposeBreeding = false;
  bool purposeMeat = false; // Meat/Broiler
  bool purposeEgg = false; // Egg/Layer
  // Implementation type
  String? implementationType; // 'individual' | 'collective' | 'hybrid'

  // True when navigating straight to Step 2 to add a new farmer (skip Step 1)
  bool isAddFarmer = false;

  // ✅ True when adding a new commodity to existing farmer (clear commodity fields)
  bool isAddingNewCommodity = false;

  // ── Step 2: Poultry Information ──────────────────────────────
  String saadIdNo = '';
  Map<String, dynamic> approvedFarmerProfile = {};
  String farmerName = '';
  List<Map<String, dynamic>> members = [];

  // ── Completed commodities for this farmer (tracks 1+ commodities per farmer) ──
  List<Map<String, dynamic>> completedCommodities = [];

  String breed = '';
  List<PoultryInputReceived> inputsReceived = [];
  List<PoultryInputPurchased> inputsPurchased = [];
  List<String> farmgatePrices = [];

  // ── Step 3: Production Information ──────────────────────────
  String stocksReceived = '';
  String dateReceived = '';
  String ageUponReceipt = ''; // days or weeks
  String avgWeightUponReceipt = '';
  String totalProductiveCycle = ''; // days or months
  String? housingType;
  String? landOwnership;
  String landOwnershipOther = '';
  String? usufruct; // Y/N

  // ── For Breeding Production ──────────────────────────────────
  String maleToFemaleRatio = '';
  String eggsProduced = '';
  String fertilEggs = '';
  String eggsIncubated = '';
  String eggsHatched = '';
  String hatchingRate = '';
  String mortalitiesAfterHatch = '';
  String chicksSold = '';
  String eggsSold = '';

  // ── For Broiler/Meat Production ──────────────────────────────
  String harvestedBirds = '';
  String totalWeightHarvested = '';
  String avgDailyGain = '';
  String harvestRecovery = '';
  String avgLiveWeight = '';
  String feedConversionRatio = '';
  String avgAgeHarvested = '';
  String broilerPerformanceIndex = '';

  // ── For Layer/Egg Production ─────────────────────────────────
  String rangingAge = '';
  String totalEggsHarvested = '';
  String avgHarvestRate = '';
  String weeklyHenDayEggProduction = '';
  String weeklyHDEPFile = ''; // attached line chart
  String daysUnderMolting = '';

  // ── Step 4: Poultry Mortality Information ────────────────────
  bool hasPest = false;
  String pestOccurrence = '';
  String pestDate = '';
  String pestMortality = '';

  bool hasDisease = false;
  String diseaseOccurrence = '';
  String diseaseDate = '';
  String diseaseMortality = '';

  bool hasEnvHazard = false;
  String envOccurrence = '';
  String envDate = '';
  String envMortality = '';

  bool hasHumanInduced = false;
  String humanOccurrence = '';
  String humanDate = '';
  String humanMortality = '';

  String treatment = '';
  String attachedReport = '';
  String totalMortalities = '';
  String rejectsCulled = '';
  String remainingStocks = '';

  // ── Step 5: Feeding and Water Management ─────────────────────
  String feedType = '';
  String totalFeedConsumed = '';
  String feedPerDay = '';
  List<String> waterSources = [];

  // ── Step 6: Waste Management ─────────────────────────────────
  String sacksManureProduced = '';
  String sacksManureSold = '';
  String sacksManureUsed = '';
  String manurePricePerSack = '';

  // ── Step 7: Trainings Attended (LAST STEP) ───────────────────
  List<TrainingEntry> trainings = [];

  // ── Photo & GPS (nested inside each completed commodity) ─────
  String farmPhoto = '';
  Map<String, dynamic>? photoGPS;

  Map<String, dynamic> toJson() {
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
      'supportInterventions': supportInterventions,
      'purposeBreeding': purposeBreeding,
      'purposeMeat': purposeMeat,
      'purposeEgg': purposeEgg,
      'saadIdNo': saadIdNo,
      'approvedFarmerProfile': approvedFarmerProfile,
      'farmerName':
          implementationType?.toLowerCase() == 'collective' ? '' : farmerName,
      'members': members,
      'completedCommodities': completedCommodities,
      'breed': breed,
      'inputsReceived': inputsReceived.map((item) => item.toJson()).toList(),
      'inputsPurchased': inputsPurchased.map((item) => item.toJson()).toList(),
      'farmgatePrices': farmgatePrices,
      'stocksReceived': stocksReceived,
      'dateReceived': dateReceived,
      'ageUponReceipt': ageUponReceipt,
      'avgWeightUponReceipt': avgWeightUponReceipt,
      'totalProductiveCycle': totalProductiveCycle,
      'housingType': housingType,
      'landOwnership': landOwnership,
      'landOwnershipOther': landOwnershipOther,
      'usufruct': usufruct,
      'maleToFemaleRatio': maleToFemaleRatio,
      'eggsProduced': eggsProduced,
      'fertilEggs': fertilEggs,
      'eggsIncubated': eggsIncubated,
      'eggsHatched': eggsHatched,
      'hatchingRate': hatchingRate,
      'mortalitiesAfterHatch': mortalitiesAfterHatch,
      'chicksSold': chicksSold,
      'eggsSold': eggsSold,
      'harvestedBirds': harvestedBirds,
      'totalWeightHarvested': totalWeightHarvested,
      'avgDailyGain': avgDailyGain,
      'harvestRecovery': harvestRecovery,
      'avgLiveWeight': avgLiveWeight,
      'feedConversionRatio': feedConversionRatio,
      'avgAgeHarvested': avgAgeHarvested,
      'broilerPerformanceIndex': broilerPerformanceIndex,
      'rangingAge': rangingAge,
      'totalEggsHarvested': totalEggsHarvested,
      'avgHarvestRate': avgHarvestRate,
      'weeklyHenDayEggProduction': weeklyHenDayEggProduction,
      'weeklyHDEPFile': weeklyHDEPFile,
      'daysUnderMolting': daysUnderMolting,
      'hasPest': hasPest,
      'pestOccurrence': pestOccurrence,
      'pestDate': pestDate,
      'pestMortality': pestMortality,
      'hasDisease': hasDisease,
      'diseaseOccurrence': diseaseOccurrence,
      'diseaseDate': diseaseDate,
      'diseaseMortality': diseaseMortality,
      'hasEnvHazard': hasEnvHazard,
      'envOccurrence': envOccurrence,
      'envDate': envDate,
      'envMortality': envMortality,
      'hasHumanInduced': hasHumanInduced,
      'humanOccurrence': humanOccurrence,
      'humanDate': humanDate,
      'humanMortality': humanMortality,
      'treatment': treatment,
      'attachedReport': attachedReport,
      'totalMortalities': totalMortalities,
      'rejectsCulled': rejectsCulled,
      'remainingStocks': remainingStocks,
      'feedType': feedType,
      'totalFeedConsumed': totalFeedConsumed,
      'feedPerDay': feedPerDay,
      'waterSources': waterSources,
      'sacksManureProduced': sacksManureProduced,
      'sacksManureSold': sacksManureSold,
      'sacksManureUsed': sacksManureUsed,
      'manurePricePerSack': manurePricePerSack,
      'trainings': trainings.map((item) => item.toJson()).toList(),
    };
  }

  /// Returns the production type for this wrapper
  String get productionType => 'poultry';
}

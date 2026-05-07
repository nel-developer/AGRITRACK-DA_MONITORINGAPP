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

class LivestockInputReceived {
  String name = '';
  String quantity = '';

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
    };
  }
}

class LivestockInputPurchased {
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

class LivestockStepWrapper {
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
  List<String> supportInterventions = [];
  bool purposeBreeding = false;
  bool purposeMeat = false;
  bool purposeDairy = false;
  String? implementationType;

  // True when navigating straight to Step 2 to add a new farmer (skip Step 1)
  bool isAddFarmer = false;

  // ── Step 2: Livestock Information ───────────────────────────
  String saadIdNo = '';
  Map<String, dynamic> approvedFarmerProfile = {};
  String farmerName = '';
  List<Map<String, dynamic>> members = [];

  // ── Completed batches for this farmer (tracks 1+ batches per farmer) ──
  List<Map<String, dynamic>> completedBatches = [];

  String? breed;
  List<LivestockInputReceived> inputsReceived = [];
  List<LivestockInputPurchased> inputsPurchased = [];
  List<String> farmgatePrices = [];

  // ── Step 3: Production Information ──────────────────────────
  String stocksReceived = '';
  String dateReceived = '';
  String maleStocks = '';
  String femaleStocks = '';
  String maleToFemaleRatio = '';
  String ageUponReceipt = '';
  String avgWeightUponReceipt = '';
  String pregnantStocks = '';
  String? housingType;
  String? farmOwnership;
  String farmOwnershipOther = '';
  String? usufruct;
  String usufructRemarks = '';
  String? healthActivities;
  String healthOthers = '';
  String wasteManagement = '';
  String growOutPeriod = '';
  String lactationPeriod = '';
  String dryPeriod = '';
  String producedOffspring = '';
  String offspringMale = '';
  String offspringFemale = '';
  String offspringMFRatio = '';
  String mortalitiesAfterBirth = '';
  String remainingOffspring = '';

  // ── Step 4: Water and Feeding Requirement ───────────────────
  String grazingArea = '';
  List<dynamic> feeds = [];
  List<String> waterSources = [];

  // ── Step 5: Harvesting Information ──────────────────────────
  String? soldAsLiveweight;
  String soldAsLiveweightRemarks = '';
  String avgMarketableWeight = '';
  String milkVolumeDaily = '';
  String farmgatePriceMilk = '';
  String milkUnit = '';
  String slaughteredCount = '';
  String slaughteredPrice = '';
  String? postharvest;
  String postharvestRemarks = '';
  String? processing;
  String processingRemarks = '';

  // ── Step 6: Livestock Mortality Information ──────────────────
  bool hasPest = false;
  String pestOccurrence = '';
  String pestDate = '';
  String pestMortality = '';
  String pestTreatment = '';
  String pestAttached = '';

  bool hasDisease = false;
  String diseaseOccurrence = '';
  String diseaseDate = '';
  String diseaseMortality = '';
  String diseaseTreatment = '';
  String diseaseAttached = '';

  bool hasEnvHazard = false;
  String envOccurrence = '';
  String envDate = '';
  String envMortality = '';
  String envTreatment = '';
  String envAttached = '';

  bool hasHumanInduced = false;
  String humanOccurrence = '';
  String humanDate = '';
  String humanMortality = '';
  String humanRemainingStocks = '';
  String humanTreatment = '';
  String humanAttached = '';

  // ── Step 7: Trainings Attended (LAST STEP) ───────────────────
  List<TrainingEntry> trainings = [TrainingEntry()];
  String farmPhoto = '';

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
      'purposeDairy': purposeDairy,
      'saadIdNo': saadIdNo,
      'approvedFarmerProfile': approvedFarmerProfile,
      'farmerName':
          implementationType?.toLowerCase() == 'collective' ? '' : farmerName,
      'members': members,
      'completedBatches': completedBatches,
      'breed': breed,
      'inputsReceived': inputsReceived.map((item) => item.toJson()).toList(),
      'inputsPurchased': inputsPurchased.map((item) => item.toJson()).toList(),
      'farmgatePrices': farmgatePrices,
      'stocksReceived': stocksReceived,
      'dateReceived': dateReceived,
      'maleStocks': maleStocks,
      'femaleStocks': femaleStocks,
      'maleToFemaleRatio': maleToFemaleRatio,
      'ageUponReceipt': ageUponReceipt,
      'avgWeightUponReceipt': avgWeightUponReceipt,
      'pregnantStocks': pregnantStocks,
      'housingType': housingType,
      'farmOwnership': farmOwnership,
      'farmOwnershipOther': farmOwnershipOther,
      'usufruct': usufruct,
      'usufructRemarks': usufructRemarks,
      'healthActivities': healthActivities,
      'healthOthers': healthOthers,
      'wasteManagement': wasteManagement,
      'growOutPeriod': growOutPeriod,
      'lactationPeriod': lactationPeriod,
      'dryPeriod': dryPeriod,
      'producedOffspring': producedOffspring,
      'offspringMale': offspringMale,
      'offspringFemale': offspringFemale,
      'offspringMFRatio': offspringMFRatio,
      'mortalitiesAfterBirth': mortalitiesAfterBirth,
      'remainingOffspring': remainingOffspring,
      'grazingArea': grazingArea,
      'feeds': feeds.map((item) {
        if (item is Map<String, dynamic>) {
          return item;
        } else if (item.runtimeType.toString().contains('FeedEntry')) {
          return item.toJson();
        }
        return item;
      }).toList(),
      'waterSources': waterSources,
      'soldAsLiveweight': soldAsLiveweight,
      'soldAsLiveweightRemarks': soldAsLiveweightRemarks,
      'avgMarketableWeight': avgMarketableWeight,
      'milkVolumeDaily': milkVolumeDaily,
      'farmgatePriceMilk': farmgatePriceMilk,
      'milkUnit': milkUnit,
      'slaughteredCount': slaughteredCount,
      'slaughteredPrice': slaughteredPrice,
      'postharvest': postharvest,
      'postharvestRemarks': postharvestRemarks,
      'processing': processing,
      'processingRemarks': processingRemarks,
      'hasPest': hasPest,
      'pestOccurrence': pestOccurrence,
      'pestDate': pestDate,
      'pestMortality': pestMortality,
      'pestTreatment': pestTreatment,
      'pestAttached': pestAttached,
      'hasDisease': hasDisease,
      'diseaseOccurrence': diseaseOccurrence,
      'diseaseDate': diseaseDate,
      'diseaseMortality': diseaseMortality,
      'diseaseTreatment': diseaseTreatment,
      'diseaseAttached': diseaseAttached,
      'hasEnvHazard': hasEnvHazard,
      'envOccurrence': envOccurrence,
      'envDate': envDate,
      'envMortality': envMortality,
      'envTreatment': envTreatment,
      'envAttached': envAttached,
      'hasHumanInduced': hasHumanInduced,
      'humanOccurrence': humanOccurrence,
      'humanDate': humanDate,
      'humanMortality': humanMortality,
      'humanRemainingStocks': humanRemainingStocks,
      'humanTreatment': humanTreatment,
      'humanAttached': humanAttached,
      'trainings': trainings.map((item) => item.toJson()).toList(),
      'farmPhoto': farmPhoto,
    };
  }
}

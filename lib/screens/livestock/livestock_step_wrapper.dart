class TrainingEntry {
  String name      = '';
  String date      = '';
  String attendees = '';
}
class LivestockInputReceived {
  String name     = '';
  String quantity = '';
}

class LivestockInputPurchased {
  String name     = '';
  String quantity = '';
  String cost     = '';
}

class LivestockStepWrapper {

  // ── Step 1: Project Background ───────────────────────────────
  String  fcaName              = '';
  String? region;
  String? province;
  String? municipality;
  String? barangay;
  String  projectTitle         = '';
  String? primaryIntervention;
  List<String> supportInterventions = [];
  bool purposeBreeding  = false;
  bool purposeMeat      = false;
  bool purposeDairy     = false;
  String? implementationType;

  // ── Step 2: Livestock Information ───────────────────────────
  String  farmerName           = '';
  String? breed;
  List<LivestockInputReceived>  inputsReceived  = [];
  List<LivestockInputPurchased> inputsPurchased = [];
  List<String> farmgatePrices  = [];

  // ── Step 3: Production Information ──────────────────────────
  String  stocksReceived        = '';
  String  dateReceived          = '';
  String  maleStocks            = '';
  String  femaleStocks          = '';
  String  maleToFemaleRatio     = '';
  String  ageUponReceipt        = '';
  String  avgWeightUponReceipt  = '';
  String  pregnantStocks        = '';
  String? housingType;
  String? farmOwnership;
  String  farmOwnershipOther    = '';
  String? usufruct;
  String  usufructRemarks       = '';
  String? healthActivities;
  String  healthOthers          = '';
  String  wasteManagement       = '';
  String  growOutPeriod         = '';
  String  lactationPeriod       = '';
  String  dryPeriod             = '';
  String  producedOffspring     = '';
  String  offspringMale         = '';
  String  offspringFemale       = '';
  String  offspringMFRatio      = '';
  String  mortalitiesAfterBirth = '';
  String  remainingOffspring    = '';

  // ── Step 4: Water and Feeding Requirement ───────────────────
  String        grazingArea  = '';
  List<dynamic> feeds        = [];
  List<String>  waterSources = [];

  // ── Step 5: Harvesting Information ──────────────────────────
  String? soldAsLiveweight;
  String  soldAsLiveweightRemarks = '';
  String  avgMarketableWeight     = '';
  String  milkVolumeDaily   = '';
  String  farmgatePriceMilk = '';
  String  milkUnit          = '';
  String  slaughteredCount  = '';
  String  slaughteredPrice  = '';
  String? postharvest;
  String  postharvestRemarks = '';
  String? processing;
  String  processingRemarks  = '';

  // ── Step 6: Livestock Mortality Information ──────────────────
  bool   hasPest             = false;
  String pestOccurrence      = '';
  String pestDate            = '';
  String pestMortality       = '';
  String pestTreatment       = '';
  String pestAttached        = '';

  bool   hasDisease          = false;
  String diseaseOccurrence   = '';
  String diseaseDate         = '';
  String diseaseMortality    = '';
  String diseaseTreatment    = '';
  String diseaseAttached     = '';

  bool   hasEnvHazard        = false;
  String envOccurrence       = '';
  String envDate             = '';
  String envMortality        = '';
  String envTreatment        = '';
  String envAttached         = '';

  bool   hasHumanInduced      = false;
  String humanOccurrence      = '';
  String humanDate            = '';
  String humanMortality       = '';
  String humanRemainingStocks = '';
  String humanTreatment       = '';
  String humanAttached        = '';

  // ── Step 7: Trainings Attended (LAST STEP) ───────────────────
  List<TrainingEntry> trainings = [TrainingEntry()];
  String       farmPhoto = '';
}
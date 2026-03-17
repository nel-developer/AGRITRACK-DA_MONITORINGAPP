class TrainingEntry {
  String name      = '';
  String date      = '';
  String attendees = '';
}
class PoultryInputReceived {
  String name     = '';
  String quantity = '';
}

class PoultryInputPurchased {
  String name     = '';
  String quantity = '';
  String cost     = '';
}

class PoultryStepWrapper {

  // ── Step 1: Project Background ───────────────────────────────
  String  reportingPeriod           = '';
  String  fcaName                   = '';
  String? region;
  String? province;
  String? municipality;
  String? barangay;
  String  projectTitle              = '';
  String? primaryIntervention;
  List<String> supportInterventions = [];
  // Purpose of Production
  bool purposeBreeding = false;
  bool purposeMeat     = false; // Meat/Broiler
  bool purposeEgg      = false; // Egg/Layer
  // Implementation type
  String? implementationType; // 'individual' | 'collective' | 'hybrid'

  // ── Step 2: Poultry Information ──────────────────────────────
  String  farmerName                = '';
  String  breed                     = '';
  List<PoultryInputReceived>  inputsReceived  = [];
  List<PoultryInputPurchased> inputsPurchased = [];
  List<String> farmgatePrices       = [];

  // ── Step 3: Production Information ──────────────────────────
  String  stocksReceived            = '';
  String  dateReceived              = '';
  String  ageUponReceipt            = ''; // days or weeks
  String  avgWeightUponReceipt      = '';
  String  totalProductiveCycle      = ''; // days or months
  String? housingType;
  String? landOwnership;
  String  landOwnershipOther        = '';
  String? usufruct;                        // Y/N

  // ── For Breeding Production ──────────────────────────────────
  String  maleToFemaleRatio         = '';
  String  eggsProduced              = '';
  String  fertilEggs                = '';
  String  eggsIncubated             = '';
  String  eggsHatched               = '';
  String  hatchingRate              = '';
  String  mortalitiesAfterHatch     = '';
  String  chicksSold                = '';
  String  eggsSold                  = '';
  String? breedingPostharvest;
  String  breedingPostharvestRemarks = '';
  String? breedingProcessing;
  String  breedingProcessingRemarks  = '';

  // ── For Broiler/Meat Production ──────────────────────────────
  String  harvestedBirds            = '';
  String  totalWeightHarvested      = '';
  String  avgDailyGain              = '';
  String  harvestRecovery           = '';
  String  avgLiveWeight             = '';
  String  feedConversionRatio       = '';
  String  avgAgeHarvested           = '';
  String  broilerPerformanceIndex   = '';
  String? broilerPostharvest;
  String  broilerPostharvestRemarks  = '';
  String? broilerProcessing;
  String  broilerProcessingRemarks   = '';

  // ── For Layer/Egg Production ─────────────────────────────────
  String  rangingAge                = '';
  String  totalEggsHarvested        = '';
  String  avgHarvestRate            = '';
  String  weeklyHenDayEggProduction = '';
  String  weeklyHDEPFile            = ''; // attached line chart
  String  daysUnderMolting          = '';
  String? layerPostharvest;
  String  layerPostharvestRemarks    = '';
  String? layerProcessing;
  String  layerProcessingRemarks     = '';

  // ── Step 4: Poultry Mortality Information ────────────────────
  bool   hasPest             = false;
  String pestOccurrence      = '';
  String pestDate            = '';
  String pestMortality       = '';

  bool   hasDisease          = false;
  String diseaseOccurrence   = '';
  String diseaseDate         = '';
  String diseaseMortality    = '';

  bool   hasEnvHazard        = false;
  String envOccurrence       = '';
  String envDate             = '';
  String envMortality        = '';

  bool   hasHumanInduced     = false;
  String humanDate           = '';
  String humanMortality      = '';

  String treatment           = '';
  String attachedReport      = '';
  String totalMortalities    = '';
  String rejectsCulled       = '';
  String remainingStocks     = '';

  // ── Step 5: Feeding and Water Management ─────────────────────
  String  feedType           = '';
  String  totalFeedConsumed  = '';
  String  feedPerDay         = '';
  List<String> waterSources  = [];

  // ── Step 6: Waste Management ─────────────────────────────────
  String  sacksManureProduced = '';
  String  sacksManureSold     = '';
  String  sacksManureUsed     = '';
  String  manurePricePerSack  = '';

  // ── Step 7: Trainings Attended (LAST STEP) ───────────────────
  List<TrainingEntry> trainings = [TrainingEntry()];
  String       farmPhoto     = '';
}
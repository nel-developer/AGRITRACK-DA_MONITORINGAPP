class TrainingEntry {
  String name      = '';
  String date      = '';
  String attendees = '';
}
class InputReceived {
  String name     = '';
  String quantity = '';
}

class InputPurchased {
  String name     = '';
  String quantity = '';
  String cost     = '';
}

class CropStepWrapper {

  // Set by ImplementationTypeScreen BEFORE Step 1 is pushed
  String? implementationType;       // 'individual' | 'collective' | 'hybrid'

  // ── Step 1: Project Background ───────────────────────────────
  String  reportingPeriod           = '';
  String  fcaName                   = '';
  String? region;
  String? province;
  String? municipality;
  String? barangay;
  String  projectTitle              = '';
  String? primaryIntervention;
  String  primaryInterventionOther        = '';
  List<String> supportInterventions = [];

  // ── Step 2: Commodity Information ───────────────────────────
  String farmerName                 = '';
  String typeOfCrop                 = '';
  String variety                    = '';
  List<InputReceived>  inputsReceived  = [];
  List<InputPurchased> inputsPurchased = [];
  String totalCostPurchased         = '';
  String qtyVsArea                  = '';
  String croppingCycles             = '';
  String qtyVsCycles                = '';
  String peakVolume                 = '';
  String peakMonth                  = '';
  List<String> volumesPerCycle      = [];
  String farmgatePrice              = '';

  // ── Step 3: Planting to Growing Stage ───────────────────────
  String  totalLandArea             = '';
  String? landOwnership;
  String  landOwnershipOther        = '';
  String? usufructAgreement;
  List<String> landRemarks          = [];
  String? machineryType;
  String  machineryOther            = '';
  List<String> machineryRemarks     = [];
  List<String> landPrepCostPerCycle = [''];
  String  landPrepStartDate         = '';
  String  landPrepDays              = '';
  String  sourceOfWater             = '';
  String  plantingDate              = '';
  String  seedAmount                = '';
  String  seedUnit                  = '';
  String  germinationRate           = '';
  String? goodGermination;
  String  germinationReason         = '';

  // ── Step 4: Fertilization Requirement ───────────────────────
  String? fertilizerType;
  String? organicSource;
  String  organicBagsSAAD        = '';
  String  organicBagsCommercial  = '';
  String  organicTotalCost       = '';
  String  organicBagsCycle       = '';
  String  organicFrequency       = '';
  String  inorganicType          = '';
  String  inorganicBagsSAAD      = '';
  String  inorganicMeasure       = '';
  String  inorganicTotalCost     = '';
  List<String> inorganicBagsCycle = [''];
  String  inorganicFrequency     = '';
  String  pesticideRequirement   = '';

  // ── Step 5: Harvesting Stage ─────────────────────────────────
  List<String> landAreaCycles     = [''];
  List<String> dateHarvestCycles  = [''];
  List<String> quantityCycles     = [''];
  String  avgHarvestPerHa         = '';
  List<String> harvestCostCycles  = [''];
  String  foodConsumptionPct      = '';
  String  postharvestFile         = '';
  List<String> postharvestRemarks = [];
  String  processingFile          = '';
  List<String> processingRemarks  = [];

  // ── Step 6: Crop Damage Information ─────────────────────────
  bool   hasPest           = false;
  String pestOccurrence    = '';
  String pestDate          = '';
  String pestDamageArea    = '';
  String pestDamageHa      = '';
  String pestTreatment     = '';
  String pestAttached      = '';

  bool   hasDisease        = false;
  String diseaseOccurrence = '';
  String diseaseDate       = '';
  String diseaseDamageArea = '';
  String diseaseDamageHa   = '';
  String diseaseTreatment  = '';
  String diseaseAttached   = '';

  bool   hasEnvHazard      = false;
  List<String> envHazards  = [''];
  String envDate           = '';
  String envDamageArea     = '';
  String envDamageHa       = '';
  String envTreatment      = '';
  String envAttached       = '';

  bool   hasHumanDamage    = false;
  String humanDamage       = '';
  String humanMortality    = '';
  String humanTreatment    = '';
  String humanAttached     = '';

  // ── Step 7: Trainings Attended (LAST STEP) ───────────────────
  List<TrainingEntry> trainings = [TrainingEntry()];
  String       farmPhoto   = '';
}
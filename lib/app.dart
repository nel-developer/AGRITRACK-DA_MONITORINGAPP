import 'package:flutter/material.dart';
import 'routes/app_routes.dart';
import 'theme/da_theme.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/forgot_password.dart';
import 'screens/implementation/implementation_type_screen.dart';
import 'screens/data/member_records_screen.dart';
import 'widgets/record_card.dart';
import 'layout/main_scaffold.dart';
import 'screens/crop/crop_step_wrapper.dart';
import 'screens/crop/crop_monitoring_summary_screen.dart';
import 'screens/crop/step_01_project_background.dart';
import 'screens/crop/step_02_commodity_information.dart';
import 'screens/crop/step_03_planting_stage.dart';
import 'screens/crop/step_04_fertilization.dart';
import 'screens/crop/step_05_harvesting_stage.dart';
import 'screens/crop/step_06_crop_damage.dart';
import 'screens/crop/step_07_trainings.dart';
import 'screens/livestock/livestock_step_wrapper.dart';
import 'screens/livestock/step_01_project_background.dart';
import 'screens/livestock/step_02_livestock_information.dart';
import 'screens/livestock/step_03_production_information.dart';
import 'screens/livestock/step_04_feeding_water.dart';
import 'screens/livestock/step_05_harvesting_information.dart';
import 'screens/livestock/step_06_mortality_information.dart';
import 'screens/livestock/step_07_trainings.dart';
import 'screens/livestock/livestock_monitoring_summary_screen.dart';
import 'screens/poultry/poultry_step_wrapper.dart';
import 'screens/poultry/step_01_project_background.dart';
import 'screens/poultry/step_02_poultry_information.dart';
import 'screens/poultry/step_03_production_information.dart';
import 'screens/poultry/step_04_mortality_information.dart';
import 'screens/poultry/step_05_feeding_water.dart';
import 'screens/poultry/step_06_waste_management.dart';
import 'screens/poultry/step_07_trainings.dart';
import 'screens/poultry/poultry_monitoring_summary_screen.dart';

class AgriTrackApp extends StatelessWidget {
  const AgriTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgriTrack', debugShowCheckedModeBanner: false,
      theme: DATheme.light, initialRoute: AppRoutes.splash,
      onUnknownRoute: (s) => MaterialPageRoute(
          builder: (_) => const SplashScreen()),
      routes: {
        AppRoutes.splash:         (_) => const SplashScreen(),
        AppRoutes.login:          (_) => const LoginScreen(),
        AppRoutes.forgotPassword: (_) => const ForgotPasswordScreen(),
        AppRoutes.home:           (_) => const MainScaffold(),
      },
      onGenerateRoute: (settings) {
        switch (settings.name) {

          case AppRoutes.implementation:
            return MaterialPageRoute(
              builder: (_) => ImplementationTypeScreen(
                  productionType:
                      (settings.arguments as String?) ?? 'crop'));

          case AppRoutes.memberRecords:
            return MaterialPageRoute(
              builder: (_) => MemberRecordsScreen(
                  record: settings.arguments as RecordModel));

          // ── Crop steps ───────────────────────────────────────
          case AppRoutes.cropStep1:
            return MaterialPageRoute(
              builder: (_) => CropStep1ProjectBackground(
                  controller: (settings.arguments as CropStepWrapper?)
                      ?? CropStepWrapper()));
          case AppRoutes.cropStep2:
            return MaterialPageRoute(
              builder: (_) => CropStep2CommodityInformation(
                  wrapper: settings.arguments as CropStepWrapper));
          case AppRoutes.cropStep3:
            return MaterialPageRoute(
              builder: (_) => CropStep3PlantingStage(
                  wrapper: settings.arguments as CropStepWrapper));
          case AppRoutes.cropStep4:
            return MaterialPageRoute(
              builder: (_) => CropStep4Fertilization(
                  wrapper: settings.arguments as CropStepWrapper));
          case AppRoutes.cropStep5:
            return MaterialPageRoute(
              builder: (_) => CropStep5HarvestingStage(
                  wrapper: settings.arguments as CropStepWrapper));
          case AppRoutes.cropStep6:
            return MaterialPageRoute(
              builder: (_) => CropStep6CropDamage(
                  wrapper: settings.arguments as CropStepWrapper));
          case AppRoutes.cropStep7:
            return MaterialPageRoute(
              builder: (_) => CropStep7Trainings(
                  wrapper: settings.arguments as CropStepWrapper));
          case AppRoutes.cropSummary:
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => CropMonitoringSummaryScreen(
                wrapper:          args['wrapper'] as CropStepWrapper,
                completedRecords: args['records'] as List<CropMonitoringRecord>,
              ));

          // ── Livestock steps ──────────────────────────────────
          case AppRoutes.livestockStep1:
            return MaterialPageRoute(
              builder: (_) => LivestockStep1ProjectBackground(
                  controller: (settings.arguments as LivestockStepWrapper?)
                      ?? LivestockStepWrapper()));
          case AppRoutes.livestockStep2:
            return MaterialPageRoute(
              builder: (_) => LivestockStep2LivestockInformation(
                  wrapper: settings.arguments as LivestockStepWrapper));
          case AppRoutes.livestockStep3:
            return MaterialPageRoute(
              builder: (_) => LivestockStep3ProductionInformation(
                  wrapper: settings.arguments as LivestockStepWrapper));
          case AppRoutes.livestockStep4:
            return MaterialPageRoute(
              builder: (_) => LivestockStep4WaterAndFeeding(
                  wrapper: settings.arguments as LivestockStepWrapper));
          case AppRoutes.livestockStep5:
            return MaterialPageRoute(
              builder: (_) => LivestockStep5HarvestingInformation(
                  wrapper: settings.arguments as LivestockStepWrapper));
          case AppRoutes.livestockStep6:
            return MaterialPageRoute(
              builder: (_) => LivestockStep6Mortality(
                  wrapper: settings.arguments as LivestockStepWrapper));
          case AppRoutes.livestockStep7:
            return MaterialPageRoute(
              builder: (_) => LivestockStep7Trainings(
                  wrapper: settings.arguments as LivestockStepWrapper));
          case AppRoutes.livestockSummary:
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => LivestockMonitoringSummaryScreen(
                wrapper:          args['wrapper'] as LivestockStepWrapper,
                completedRecords: args['records'] as List<LivestockMonitoringRecord>,
              ));

          // ── Poultry steps ─────────────────────────────────────
          case AppRoutes.poultryStep1:
            return MaterialPageRoute(
              builder: (_) => PoultryStep1ProjectBackground(
                  controller: (settings.arguments as PoultryStepWrapper?)
                      ?? PoultryStepWrapper()));
          case AppRoutes.poultryStep2:
            return MaterialPageRoute(
              builder: (_) => PoultryStep2PoultryInformation(
                  wrapper: settings.arguments as PoultryStepWrapper));
          case AppRoutes.poultryStep3:
            return MaterialPageRoute(
              builder: (_) => PoultryStep3ProductionInformation(
                  wrapper: settings.arguments as PoultryStepWrapper));
          case AppRoutes.poultryStep4:
            return MaterialPageRoute(
              builder: (_) => PoultryStep4MortalityInformation(
                  wrapper: settings.arguments as PoultryStepWrapper));
          case AppRoutes.poultryStep5:
            return MaterialPageRoute(
              builder: (_) => PoultryStep5FeedingWater(
                  wrapper: settings.arguments as PoultryStepWrapper));
          case AppRoutes.poultryStep6:
            return MaterialPageRoute(
              builder: (_) => PoultryStep6WasteManagement(
                  wrapper: settings.arguments as PoultryStepWrapper));
          case AppRoutes.poultryStep7:
            return MaterialPageRoute(
              builder: (_) => PoultryStep7Trainings(
                  wrapper: settings.arguments as PoultryStepWrapper));
          case AppRoutes.poultrySummary:
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => PoultryMonitoringSummaryScreen(
                wrapper:          args['wrapper'] as PoultryStepWrapper,
                completedRecords: args['records'] as List<PoultryMonitoringRecord>,
              ));

          default:
            return MaterialPageRoute(
                builder: (_) => const SplashScreen());
        }
      },
    );
  }
}
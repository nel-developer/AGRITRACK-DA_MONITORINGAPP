# da_monitoring_app

A new Flutter project.

## Firebase Role Setup

This app now uses Firebase Auth + Firestore roles. The user role is read from:

- `users/{uid}` document
- `role` field with one of: `profiler`, `moderator`, `admin`

Example user document:

```json
{
  "role": "profiler",
  "name": "Juan Dela Cruz",
  "email": "juan@example.com"
}
```

## Firestore Rules

This repository includes:

- `firestore.rules`
- `firestore.indexes.json`
- `firebase.json`

Rules behavior:

- Users can read their own role document.
- Moderators/Admins can read user documents.
- Only Admin can create/update/delete user documents.
- All other collections are denied by default.

### Deploy rules

```bash
firebase login
firebase use <your-project-id>
firebase deploy --only firestore:rules
```

## Profiling Data Collection Structure

Profiling records are saved to Firestore with the following structure:

```
profiler/
  profiling/
    crop_production/
      collective/
        records/
          {recordId}: { profiling data }
      individual/
        records/
          {recordId}: { profiling data }
      hybrid/
        records/
          {recordId}: { profiling data }
    livestock_production/
      collective/
        records/
          {recordId}: { profiling data }
      individual/
        records/
          {recordId}: { profiling data }
      hybrid/
        records/
          {recordId}: { profiling data }
    poultry_production/
      collective/
        records/
          {recordId}: { profiling data }
      individual/
        records/
          {recordId}: { profiling data }
      hybrid/
        records/
          {recordId}: { profiling data }
```

### Profiling Record Example

```json
{
  "recordId": "auto-generated-id",
  "productionType": "crop",
  "implementationType": "collective",
  "createdBy": "user-uid",
  "createdAt": "2024-03-18T10:30:00Z",
  "updatedAt": "2024-03-18T10:30:00Z",
  "reportingPeriod": "Q1 2024",
  "fcaName": "Farmers Association Name",
  "region": "Region Name",
  "province": "Province Name",
  "municipality": "Municipality Name",
  "barangay": "Barangay Name",
  "projectTitle": "Project Title",
  "primaryIntervention": "Intervention Type",
  "supportInterventions": ["Support 1", "Support 2"],
  "farmerName": "Farmer Name",
  "typeOfCrop": "Rice",
  "variety": "Variety Name",
  "totalCostPurchased": "5000",
  "qtyVsArea": "100kg/hectare",
  "croppingCycles": "2",
  "farmPhoto": "path/to/photo"
}
```

### ProfilingService Usage

The app provides `ProfilingService` to save and manage profiling records:

```dart
import 'package:agritrack/services/profiling_service.dart';

// Save profiling data
final recordId = await ProfilingService.instance.saveProfilingWithAutoId(
  productionType: 'crop',       // 'crop', 'livestock', or 'poultry'
  implementationType: 'collective',  // 'collective', 'individual', or 'hybrid'
  data: {
    'farmerName': 'John Doe',
    'typeOfCrop': 'Rice',
    // ... other fields
  },
);

// Access as stream
ProfilingService.instance.getProfilingRecords(
  productionType: 'crop',
  implementationType: 'collective',
).listen((records) {
  // Update UI with records
});
```

### Firestore Security Rules for Profiling

- Only Profilers can create/update profiling records
- Moderators and Admins can read all profiling records
- Records are automatically timestamped and tagged with creator UID

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

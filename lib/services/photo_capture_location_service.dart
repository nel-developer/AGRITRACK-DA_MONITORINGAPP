import 'dart:io';
import 'dart:math';

import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:native_exif/native_exif.dart';
import 'package:path_provider/path_provider.dart';

class PhotoWithLocation {
  const PhotoWithLocation({
    required this.path,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.capturedAt,
  });

  final String path;
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime capturedAt;
}

class PhotoCaptureLocationService {
  PhotoCaptureLocationService._();

  static final PhotoCaptureLocationService instance =
      PhotoCaptureLocationService._();

  final ImagePicker _picker = ImagePicker();

  Future<PhotoWithLocation> captureFromCamera({
    required String productionType,
    required String implementationType,
    required String groupName,
    required String farmerName,
  }) async {
    await _ensureLocationReady();

    // Try to get a valid GPS fix before opening the camera
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (e) {
      throw Exception(
          'Could not get a valid GPS location. Please move to an open area and try again.');
    }

    if (position.latitude.isNaN ||
        position.longitude.isNaN ||
        !position.latitude.isFinite ||
        !position.longitude.isFinite) {
      throw Exception(
          'Could not get a valid GPS location. Please move to an open area and try again.');
    }

    // Only open the camera if GPS is available
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );

    if (image == null) {
      throw Exception('Photo capture cancelled.');
    }

    await _writeAndValidateGpsExif(
      imagePath: image.path,
      position: position,
      capturedAt: DateTime.now().toUtc(),
    );

    final storedPath = await _moveToOrganizedStorage(
      sourcePath: image.path,
      productionType: productionType,
      implementationType: implementationType,
      groupName: groupName,
      farmerName: farmerName,
    );

    return PhotoWithLocation(
      path: storedPath,
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      capturedAt: DateTime.now(),
    );
  }

  Future<void> _ensureLocationReady() async {
    final locationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!locationServiceEnabled) {
      await Geolocator.openLocationSettings();
      final enabledAfterPrompt = await Geolocator.isLocationServiceEnabled();
      if (!enabledAfterPrompt) {
        throw Exception(
            'Please turn on location services to capture photo location.');
      }
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      // Ask one more time in case the first request was dismissed.
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      throw Exception(
          'Location permission is permanently denied. Please allow location in app settings and try again.');
    }

    if (permission == LocationPermission.denied) {
      throw Exception(
          'Location permission is required to take profiling photos.');
    }
  }

  Future<void> _writeAndValidateGpsExif({
    required String imagePath,
    required Position position,
    required DateTime capturedAt,
  }) async {
    final exif = await Exif.fromPath(imagePath);

    // Validate latitude and longitude before writing EXIF
    if (position.latitude.isNaN ||
        position.longitude.isNaN ||
        !position.latitude.isFinite ||
        !position.longitude.isFinite) {
      await exif.close();
      throw Exception(
          'Invalid GPS coordinates: latitude or longitude is not a valid number.');
    }

    try {
      final latValue = position.latitude.abs().toString();
      final lonValue = position.longitude.abs().toString();

      await exif.writeAttributes({
        'GPSLatitudeRef': position.latitude >= 0 ? 'N' : 'S',
        'GPSLatitude': latValue,
        'GPSLongitudeRef': position.longitude >= 0 ? 'E' : 'W',
        'GPSLongitude': lonValue,
        'GPSDateStamp': _gpsDateStamp(capturedAt),
        'GPSTimeStamp': _gpsTimeStamp(capturedAt),
      });

      final lat = await exif.getAttribute('GPSLatitude');
      final lon = await exif.getAttribute('GPSLongitude');
      final latString = lat?.toString().trim() ?? '';
      final lonString = lon?.toString().trim() ?? '';
      if (latString.isEmpty || lonString.isEmpty) {
        throw Exception('Unable to confirm GPS metadata in photo.');
      }
    } finally {
      await exif.close();
    }
  }

  String _gpsDateStamp(DateTime utc) {
    final y = utc.year.toString().padLeft(4, '0');
    final m = utc.month.toString().padLeft(2, '0');
    final d = utc.day.toString().padLeft(2, '0');
    return '$y:$m:$d';
  }

  String _gpsTimeStamp(DateTime utc) {
    final h = utc.hour;
    final m = utc.minute;
    final s = max(0, utc.second);
    return '$h/1,$m/1,$s/1';
  }

  Future<String> _moveToOrganizedStorage({
    required String sourcePath,
    required String productionType,
    required String implementationType,
    required String groupName,
    required String farmerName,
  }) async {
    final rootDirectory = await getApplicationDocumentsDirectory();
    final folderLabel = groupName.trim().isNotEmpty ? groupName : farmerName;
    final folderName = _sanitizeFolderPart(
      folderLabel.trim().isEmpty ? 'profiling_photos' : folderLabel,
    );
    final productionFolder = _sanitizeFolderPart(
      _productionFolderName(productionType),
    );
    final implementationFolder = _sanitizeFolderPart(
      _implementationFolderName(implementationType),
    );
    final productionPart = _sanitizeFilePart(
      productionType.trim().isEmpty ? 'production' : productionType,
    );
    final fileStemSource =
        farmerName.trim().isNotEmpty ? farmerName : groupName;
    final fileStem = _sanitizeFilePart(
      fileStemSource.trim().isEmpty ? 'farm_photo' : fileStemSource,
    );
    final timestamp = _fileTimestamp(DateTime.now());
    final extension = _fileExtension(sourcePath);

    final targetDirectory = Directory(
      '${rootDirectory.path}${Platform.pathSeparator}profiling_photos${Platform.pathSeparator}$productionFolder${Platform.pathSeparator}$implementationFolder${Platform.pathSeparator}$folderName',
    );
    if (!await targetDirectory.exists()) {
      await targetDirectory.create(recursive: true);
    }

    final targetPath =
        '${targetDirectory.path}${Platform.pathSeparator}${fileStem}_${productionPart}_$timestamp$extension';

    final sourceFile = File(sourcePath);
    final storedFile = await sourceFile.copy(targetPath);
    if (await sourceFile.exists()) {
      await sourceFile.delete();
    }
    return storedFile.path;
  }

  String _sanitizeFolderPart(String value) {
    final cleaned = value.trim().replaceAll(RegExp(r'[\\/:*?"<>|]+'), '_');
    final normalized = cleaned.replaceAll(RegExp(r'\s+'), ' ');
    return normalized.isEmpty ? 'unknown' : normalized;
  }

  String _sanitizeFilePart(String value) {
    final cleaned = value.trim().replaceAll(RegExp(r'[\\/:*?"<>|]+'), '_');
    final normalized = cleaned.replaceAll(RegExp(r'\s+'), '_');
    return normalized.isEmpty ? 'unknown' : normalized;
  }

  String _productionFolderName(String productionType) {
    switch (productionType.trim().toLowerCase()) {
      case 'crop':
        return 'crop production';
      case 'livestock':
        return 'livestock production';
      case 'poultry':
        return 'poultry production';
      default:
        return productionType.trim().isEmpty ? 'production' : productionType;
    }
  }

  String _implementationFolderName(String implementationType) {
    switch (implementationType.trim().toLowerCase()) {
      case 'individual':
        return 'individual';
      case 'collective':
        return 'collective';
      case 'hybrid':
        return 'hybrid';
      default:
        return implementationType.trim().isEmpty
            ? 'unspecified'
            : implementationType;
    }
  }

  String _fileTimestamp(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    final second = value.second.toString().padLeft(2, '0');
    return '$year$month${day}_$hour$minute$second';
  }

  String _fileExtension(String path) {
    final dotIndex = path.lastIndexOf('.');
    if (dotIndex == -1) return '.jpg';
    return path.substring(dotIndex);
  }
}

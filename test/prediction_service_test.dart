import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:paddy_disease_detection/models/disease_prediction.dart';
import 'package:paddy_disease_detection/services/prediction_service.dart';

void main() {
  group('DiseasePrediction Model Tests', () {
    test('Parses actual backend JSON correctly', () {
      final json = {
        'class_id': 8,
        'confidence': 1.0,
        'prediction': 'normal',
        'success': true,
      };

      final prediction = DiseasePrediction.fromJson(json);

      expect(prediction.classId, 8);
      expect(prediction.confidence, 1.0);
      expect(prediction.rawPrediction, 'normal');
      expect(prediction.success, true);
      expect(prediction.displayName, 'Normal / Healthy');
      expect(prediction.formattedConfidence, '100.0%');
    });

    test('Maps all 10 supported disease classes properly', () {
      final cases = {
        'bacterial_leaf_blight': 'Bacterial Leaf Blight',
        'bacterial_leaf_streak': 'Bacterial Leaf Streak',
        'bacterial_panicle_blight': 'Bacterial Panicle Blight',
        'blast': 'Blast',
        'brown_spot': 'Brown Spot',
        'dead_heart': 'Dead Heart',
        'downy_mildew': 'Downy Mildew',
        'hispa': 'Hispa',
        'normal': 'Normal / Healthy',
        'healthy': 'Normal / Healthy',
        'tungro': 'Tungro',
      };

      cases.forEach((raw, expectedName) {
        final p = DiseasePrediction(
          rawPrediction: raw,
          confidence: 0.954,
          success: true,
        );
        expect(p.displayName, expectedName);
      });
    });

    test('Confidence formats cleanly and handles null', () {
      final p1 = DiseasePrediction(rawPrediction: 'blast', confidence: 0.876, success: true);
      expect(p1.formattedConfidence, '87.6%');

      final p2 = DiseasePrediction(rawPrediction: 'blast', confidence: null, success: true);
      expect(p2.formattedConfidence, isNull);
    });
  });

  group('PredictionService Tests', () {
    test('Successfully parses prediction from mock response', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'class_id': 3,
            'confidence': 0.985,
            'prediction': 'blast',
            'success': true,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = PredictionService(
        baseUrl: 'https://test-api.example.com',
        client: mockClient,
      );

      final tempDir = Directory.systemTemp.createTempSync();
      final tempFile = File('${tempDir.path}/test_leaf.png')..writeAsStringSync('dummy');

      final result = await service.predict(tempFile);

      expect(result.displayName, 'Blast');
      expect(result.formattedConfidence, '98.5%');

      tempDir.deleteSync(recursive: true);
    });

    test('Throws ApiException when API returns 400 error message', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': "No image file provided in request field 'image'",
            'success': false,
          }),
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = PredictionService(
        baseUrl: 'https://test-api.example.com',
        client: mockClient,
      );

      final tempDir = Directory.systemTemp.createTempSync();
      final tempFile = File('${tempDir.path}/dummy.png')..writeAsStringSync('dummy');

      await expectLater(
        () => service.predict(tempFile),
        throwsA(isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains("No image file provided in request field 'image'"),
        )),
      );

      tempDir.deleteSync(recursive: true);
    });

    test('Throws ApiException when API is unavailable (500)', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Server error', 500);
      });

      final service = PredictionService(
        baseUrl: 'https://test-api.example.com',
        client: mockClient,
      );

      final tempDir = Directory.systemTemp.createTempSync();
      final tempFile = File('${tempDir.path}/dummy.png')..writeAsStringSync('dummy');

      await expectLater(
        () => service.predict(tempFile),
        throwsA(isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('API is currently unavailable'),
        )),
      );

      tempDir.deleteSync(recursive: true);
    });

    test('Throws ApiException if file does not exist', () async {
      final service = PredictionService(baseUrl: 'https://test-api.example.com');
      final missingFile = File('/nonexistent/leaf.png');

      await expectLater(
        () => service.predict(missingFile),
        throwsA(isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('Selected image file was not found'),
        )),
      );
    });
  });
}

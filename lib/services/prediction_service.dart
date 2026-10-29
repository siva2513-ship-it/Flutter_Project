import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/disease_prediction.dart';

/// Exception thrown when the prediction API fails or network fails.
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class PredictionService {
  static const String defaultBaseUrl = 'https://paddy-disease-detection-iuk4.onrender.com';
  final String baseUrl;
  final http.Client _client;

  PredictionService({
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = baseUrl ?? defaultBaseUrl,
        _client = client ?? http.Client();

  /// Sends an image file to the backend API and returns a [DiseasePrediction].
  ///
  /// Handles Render cold starts with a 60-second timeout and translates
  /// network and API error statuses into clear, user-facing error messages.
  Future<DiseasePrediction> predict(File imageFile) async {
    if (!imageFile.existsSync()) {
      throw ApiException('Selected image file was not found. Please select an image again.');
    }

    final uri = Uri.parse('$baseUrl/predict');

    try {
      final request = http.MultipartRequest('POST', uri);

      // The backend expects the multipart file in the field named 'image'
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
        ),
      );

      // Free Render instances spin down when inactive, so allow up to 60s
      final streamedResponse = await _client.send(request).timeout(
        const Duration(seconds: 60),
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          if (decoded['success'] == false) {
            final errorMsg = decoded['error']?.toString() ?? 'Prediction failed.';
            throw ApiException(errorMsg);
          }
          return DiseasePrediction.fromJson(decoded);
        } else {
          throw ApiException('Unexpected response format received from server.');
        }
      } else if (response.statusCode == 400) {
        try {
          final dynamic decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic> && decoded['error'] != null) {
            throw ApiException(decoded['error'].toString());
          }
        } catch (e) {
          if (e is ApiException) rethrow;
        }
        throw ApiException('The uploaded image cannot be processed.');
      } else if (response.statusCode >= 500) {
        throw ApiException('The API is currently unavailable (Error ${response.statusCode}). Please try again later.');
      } else {
        throw ApiException('Server returned unexpected status code: ${response.statusCode}');
      }
    } on FileSystemException {
      throw ApiException('Unable to read the selected image file. Please choose another image.');
    } on SocketException {
      throw ApiException('Internet connection failed. Please check your network and try again.');
    } on TimeoutException {
      throw ApiException('Request timed out. The server may be waking up from cold start. Please try again.');
    } on http.ClientException {
      throw ApiException('Internet connection failed. Please verify your connection and try again.');
    } on FormatException {
      throw ApiException('The server returned an invalid response. Please try again later.');
    }
  }
}

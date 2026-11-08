import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../theme/nomad_kit.dart';

class ErrorHandler {
  ErrorHandler._();

  /// Converts any exception into a standardized, clear English error message
  static String getErrorMessage(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Request timed out. The server took too long to respond.';
        case DioExceptionType.connectionError:
          return 'Cannot connect to Gateway server. Please verify network status.';
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final responseData = error.response?.data;

          // Check if backend returned an error message in body
          if (responseData is Map<String, dynamic>) {
            final msg = responseData['errorMessage'] ??
                responseData['detail'] ??
                responseData['title'] ??
                responseData['message'];
            if (msg != null && msg.toString().trim().isNotEmpty) {
              return msg.toString();
            }
          }

          switch (statusCode) {
            case 400:
              return 'Invalid request data. Please check your inputs.';
            case 401:
              return 'Authentication required. Please sign in again.';
            case 403:
              return 'Access denied. You do not have permission for this action.';
            case 404:
              return 'The requested resource was not found on the server.';
            case 409:
              return 'Concurrency conflict. This version was modified by another user.';
            case 410:
              return 'Draft has expired (30-minute limit). Please request a new draft.';
            case 422:
              return 'Cannot modify a locked or approved recipe version.';
            case 500:
            case 502:
            case 503:
              return 'Central server encountered an internal error. Please try again later.';
            default:
              return 'Server returned error status code: $statusCode.';
          }
        case DioExceptionType.cancel:
          return 'The operation was cancelled.';
        default:
          return 'An unexpected network error occurred.';
      }
    }

    if (error is SocketException) {
      return 'Network connection failed. Please check your internet or Wi-Fi.';
    }

    if (error is FormatException) {
      return 'Data parsing format error.';
    }

    return error?.toString() ?? 'An unknown error occurred.';
  }

  /// Displays an English error notification banner in NomadKit style
  static void showErrorSnackBar(BuildContext context, dynamic error) {
    final message = getErrorMessage(error);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: NomadKit.ink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: NomadKit.warning.withValues(alpha: 0.5)),
        ),
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: NomadKit.warning, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Displays an English success notification banner in NomadKit style
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: NomadKit.ink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: NomadKit.forest.withValues(alpha: 0.5)),
        ),
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: NomadKit.forest, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

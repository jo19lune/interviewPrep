import 'dart:async';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../network/api_client.dart';

class AppDialog {
  const AppDialog._();

  static Future<void> success(
    BuildContext context, {
    required String title,
    required String message,
    String buttonText = 'Continuer',
    VoidCallback? onConfirm,
  }) {
    return _show(
      context,
      type: DialogType.success,
      title: title,
      message: message,
      buttonText: buttonText,
      onConfirm: onConfirm,
    );
  }

  static Future<void> error(
    BuildContext context, {
    required String title,
    required String message,
    String buttonText = 'Fermer',
    VoidCallback? onConfirm,
  }) {
    return _show(
      context,
      type: DialogType.error,
      title: title,
      message: message,
      buttonText: buttonText,
      onConfirm: onConfirm,
    );
  }

  static Future<void> warning(
    BuildContext context, {
    required String title,
    required String message,
    String buttonText = 'Compris',
    VoidCallback? onConfirm,
  }) {
    return _show(
      context,
      type: DialogType.warning,
      title: title,
      message: message,
      buttonText: buttonText,
      onConfirm: onConfirm,
    );
  }

  static Future<void> info(
    BuildContext context, {
    required String title,
    required String message,
    String buttonText = 'Fermer',
    VoidCallback? onConfirm,
  }) {
    return _show(
      context,
      type: DialogType.info,
      title: title,
      message: message,
      buttonText: buttonText,
      onConfirm: onConfirm,
    );
  }

  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String cancelText = 'Annuler',
    String confirmText = 'Confirmer',
    Color confirmColor = AppTheme.primaryContainer,
  }) {
    final result = Completer<bool>();

    void complete(bool value) {
      if (!result.isCompleted) {
        result.complete(value);
      }
    }

    AwesomeDialog(
      context: context,
      dialogType: DialogType.noHeader,
      animType: AnimType.scale,
      customHeader: _header(DialogType.warning),
      title: title,
      desc: message,
      btnCancelText: cancelText,
      btnCancelColor: AppTheme.outline,
      btnCancelOnPress: () => complete(false),
      btnOkText: confirmText,
      btnOkColor: confirmColor,
      btnOkOnPress: () => complete(true),
      dismissOnTouchOutside: false,
      dismissOnBackKeyPress: false,
      dialogBackgroundColor: AppTheme.surfaceContainerLowest,
      buttonsTextStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
    ).show();

    return result.future;
  }

  static Future<void> showException(
    BuildContext context,
    Object error, {
    required String fallback,
  }) {
    if (error is DioException && isConnectivityError(error)) {
      return warning(
        context,
        title: 'Connexion Internet requise',
        message:
            'Vérifiez votre connexion Internet puis réessayez. '
            'Le serveur peut également être temporairement indisponible.',
      );
    }

    final message = error is DioException
        ? ApiClient.errorMessage(error, fallback)
        : _cleanMessage(error.toString(), fallback);
    return AppDialog.error(
      context,
      title: 'Une erreur est survenue',
      message: message,
    );
  }

  static bool isConnectivityError(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionError ||
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.unknown => error.response == null,
      _ => false,
    };
  }

  static String _cleanMessage(String value, String fallback) {
    final cleaned = value.replaceAll('Exception: ', '').trim();
    return cleaned.isEmpty ? fallback : cleaned;
  }

  static Future<void> _show(
    BuildContext context, {
    required DialogType type,
    required String title,
    required String message,
    required String buttonText,
    VoidCallback? onConfirm,
  }) {
    return AwesomeDialog(
      context: context,
      dialogType: DialogType.noHeader,
      animType: AnimType.scale,
      customHeader: _header(type),
      title: title,
      desc: message,
      btnOkText: buttonText,
      btnOkColor: AppTheme.primaryContainer,
      btnOkOnPress: onConfirm,
      dismissOnTouchOutside: false,
      dialogBackgroundColor: AppTheme.surfaceContainerLowest,
      buttonsTextStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
    ).show();
  }

  static Widget _header(DialogType type) {
    final (IconData icon, Color color) = switch (type) {
      DialogType.success => (Icons.check_circle, Colors.green),
      DialogType.error => (Icons.error, AppTheme.error),
      DialogType.warning => (Icons.warning, Colors.orange),
      _ => (Icons.info, AppTheme.secondaryColor),
    };

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 42),
    );
  }
}

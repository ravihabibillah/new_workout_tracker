import '../constants/app_strings.dart';

/// Input validation utilities
class Validators {
  Validators._();

  /// Validates required fields
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null 
          ? '$fieldName is required' 
          : AppStrings.fieldRequired;
    }
    return null;
  }

  /// Validates numeric input
  static String? number(String? value, {bool allowNegative = false}) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.fieldRequired;
    }

    final number = double.tryParse(value);
    if (number == null) {
      return AppStrings.invalidNumber;
    }

    if (!allowNegative && number < 0) {
      return AppStrings.mustBePositive;
    }

    return null;
  }

  /// Validates positive numbers
  static String? positiveNumber(String? value) {
    final requiredError = required(value);
    if (requiredError != null) return requiredError;

    final number = double.tryParse(value!);
    if (number == null) {
      return AppStrings.invalidNumber;
    }

    if (number <= 0) {
      return AppStrings.mustBePositive;
    }

    return null;
  }

  /// Validates weight input
  static String? weight(String? value) {
    return positiveNumber(value);
  }

  /// Validates reps input
  static String? reps(String? value) {
    final error = positiveNumber(value);
    if (error != null) return error;

    final number = int.tryParse(value!);
    if (number == null) {
      return 'Reps must be a whole number';
    }

    return null;
  }

  /// Validates email format
  static String? email(String? value) {
    final requiredError = required(value);
    if (requiredError != null) return requiredError;

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value!)) {
      return 'Please enter a valid email';
    }

    return null;
  }
}

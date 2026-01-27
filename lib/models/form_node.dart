import 'package:flutter/services.dart';
import 'package:json_annotation/json_annotation.dart';

import '../formatting/formatters.dart';

/*
  Form node parent class. 
  A form node is a base class used to be able to pass around FormNodes 
*/

sealed class FormNode {
  final String id;
  final String label;

  const FormNode({required this.id, required this.label});

  static final Map<String, FormNode Function(String, Map<String, dynamic>)> _factories = {
    'textInput': TextInputNode.fromJson,
    'choiceInput': ChoiceInputNode.fromJson,
  };

  factory FormNode.fromJson(String id, Map<String, dynamic> json) {
    final type = json['type'] as String;
    final factory = _factories[type];
    if (factory == null) {
      throw ArgumentError('Unknown FormNode type: $type');
    }
    return factory(id, json);
  }

  Map<String, dynamic> toJson();
}


enum ChoiceCardinality {
  @JsonValue('single')
  single,
  @JsonValue('multiple')
  multiple,
}

/*
  DataSpec is the specifications on the type of data the form node is asking for.
  We use the term ValueKind to show that this is not a Json Type, not a Dart type but our own 'custom' types.
  Of course at some point we will use validation logic against dart types, but this is our higher level respresentation of what the data should be.
*/

class DataSpec {
  final String formNodeID;
  final ValueKind valueKind;
  final bool required;
  final ValueProfile profile;
  final List<FieldValidator> validators;

  DataSpec({
    required this.formNodeID,
    required this.valueKind,
    this.required = true,
    this.profile = ValueProfile.plainText,
    this.validators = const [],
  });

  factory DataSpec.fromJson(String nodeId, Map<String, dynamic> json) {
    final kind = json['kind'];
    if (kind == null) {
      throw ArgumentError('DataSpec for "$nodeId" missing "kind"');
    }

    final profileName = json['profile'] as String?;
    final profile = profileName == null
        ? ValueProfile.plainText
        : ValueProfile.values.firstWhere(
            (e) => e.name == profileName,
            orElse: () => ValueProfile.plainText,
          );

    return DataSpec(
      formNodeID: nodeId,
      valueKind: ValueKind.values.firstWhere(
        (e) => e.name == kind,
        orElse: () => throw ArgumentError(
          'Unknown ValueKind "$kind" for node "$nodeId"',
        ),
      ),
      required: json['required'] ?? true,
      profile: profile,
    );
  }

  Map<String, dynamic> toJson() => {
        'kind': valueKind.name,
        'required': required,
        'profile': profile.name,
      };
}


enum ValueKind {
  @JsonValue('string')
  string,
  @JsonValue('boolean')
  boolean,
  @JsonValue('number')
  number,
  @JsonValue('date')
  date,
  @JsonValue('stringList')
  stringList,
}

/// Semantic profiles for text input fields.
/// Determines formatting, keyboard type, and canonical parsing.
enum ValueProfile {
  plainText,
  dateDdMmYyyy,
  moneyCents,
  sinCanada,
  phoneNorthAmerica,
}

/// Base class for field formatting configuration.
sealed class FieldFormatting {
  const FieldFormatting();
  List<TextInputFormatter> formatters();
  TextInputType keyboardType() => TextInputType.text;
  String? prefixText() => null;
}

class PlainTextFormatting extends FieldFormatting {
  const PlainTextFormatting();
  @override
  List<TextInputFormatter> formatters() => const [];
}

class DateFormatting extends FieldFormatting {
  const DateFormatting();
  @override
  List<TextInputFormatter> formatters() => [
        FilteringTextInputFormatter.digitsOnly,
        const DateDdMmYyyyFormatter(),
      ];
  @override
  TextInputType keyboardType() => TextInputType.datetime;
}

class MoneyFormatting extends FieldFormatting {
  const MoneyFormatting();
  @override
  List<TextInputFormatter> formatters() => [
        FilteringTextInputFormatter.allow(RegExp(r'[\d\-]')),
        const MoneyCentsFormatter(),
      ];
  @override
  TextInputType keyboardType() => const TextInputType.numberWithOptions(signed: true);
  @override
  String? prefixText() => '\$';
}

class SinFormatting extends FieldFormatting {
  const SinFormatting();
  @override
  List<TextInputFormatter> formatters() => [
        FilteringTextInputFormatter.digitsOnly,
        const SinSpacerFormatter(),
      ];
  @override
  TextInputType keyboardType() => TextInputType.number;
}

class PhoneFormatting extends FieldFormatting {
  const PhoneFormatting();
  @override
  List<TextInputFormatter> formatters() => [
        FilteringTextInputFormatter.digitsOnly,
        const PhoneNanpFormatter(),
      ];
  @override
  TextInputType keyboardType() => TextInputType.phone;
}

/// Base class for field validators.
sealed class FieldValidator {
  const FieldValidator();
  String? validate(String rawText);
}

class RequiredValidator extends FieldValidator {
  const RequiredValidator();
  @override
  String? validate(String rawText) =>
      rawText.trim().isEmpty ? 'Required' : null;
}

class SinCanadaValidator extends FieldValidator {
  const SinCanadaValidator();

  @override
  String? validate(String rawText) {
    final digits = rawText.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 9) return 'SIN must be 9 digits';
    if (!_luhnIsValid(digits)) return 'Invalid SIN';
    return null;
  }
}

bool _luhnIsValid(String digits) {
  var sum = 0;
  var alt = false;
  for (var i = digits.length - 1; i >= 0; i--) {
    var n = digits.codeUnitAt(i) - 48;
    if (alt) {
      n *= 2;
      if (n > 9) n -= 9;
    }
    sum += n;
    alt = !alt;
  }
  return sum % 10 == 0;
}

class DateDdMmYyyyValidator extends FieldValidator {
  const DateDdMmYyyyValidator();

  @override
  String? validate(String rawText) {
    if (rawText.length != 10) return null;

    final parts = rawText.split('/');
    if (parts.length != 3) return 'Invalid date';

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);

    if (day == null || month == null || year == null) return 'Invalid date';
    if (month < 1 || month > 12) return 'Invalid date';
    if (day < 1 || day > _daysInMonth(month, year)) return 'Invalid date';

    final today = DateTime.now();
    final inputDate = DateTime(year, month, day);
    if (inputDate.isAfter(today)) return 'Date cannot be in the future';

    return null;
  }
}

int _daysInMonth(int month, int year) {
  const days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
  if (month == 2 && _isLeapYear(year)) return 29;
  return days[month - 1];
}

bool _isLeapYear(int year) {
  return (year % 4 == 0) && (year % 100 != 0 || year % 400 == 0);
}

/// Returns formatting configuration for a given profile.
FieldFormatting formattingFor(ValueProfile profile) {
  return switch (profile) {
    ValueProfile.plainText => const PlainTextFormatting(),
    ValueProfile.dateDdMmYyyy => const DateFormatting(),
    ValueProfile.moneyCents => const MoneyFormatting(),
    ValueProfile.sinCanada => const SinFormatting(),
    ValueProfile.phoneNorthAmerica => const PhoneFormatting(),
  };
}

/// Returns effective validators for a DataSpec.
/// Includes RequiredValidator if spec.required is true.
List<FieldValidator> effectiveValidatorsFor(DataSpec spec) {
  return [
    if (spec.required) const RequiredValidator(),
    ...spec.validators,
  ];
}

/// Parses raw text to canonical value based on profile.
Object? parseCanonical(ValueProfile profile, String text) {
  return switch (profile) {
    ValueProfile.moneyCents => _parseMoneyValue(text),
    ValueProfile.sinCanada => () {
      final digits = text.replaceAll(RegExp(r'\D'), '');
      return digits.isEmpty ? null : digits;
    }(),
    ValueProfile.phoneNorthAmerica => () {
      final digits = text.replaceAll(RegExp(r'\D'), '');
      return digits.isEmpty ? null : digits;
    }(),
    ValueProfile.dateDdMmYyyy => text.trim().isEmpty ? null : text,
    ValueProfile.plainText => text,
  };
}

/// Parses money text to cents, supporting negative values.
int? _parseMoneyValue(String text) {
  final isNegative = text.contains('-');
  final digits = text.replaceAll(RegExp(r'[^\d]'), '');
  if (digits.isEmpty) return null;
  final value = int.tryParse(digits);
  if (value == null) return null;
  return isNegative ? -value : value;
}

/* 
  Now we get into the applications or extenstions of our FormNode Abstract class
*/

// Text input node 
class TextInputNode extends FormNode {
  final bool multiLine;

  const TextInputNode({required super.id, required super.label, this.multiLine = false});

  factory TextInputNode.fromJson(String id, Map<String, dynamic> json) {
    return TextInputNode(
      id: id,
      label: json['label'] as String,
      multiLine: json['multiLine'] as bool? ?? false,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'textInput',
        'label': label,
        'multiLine': multiLine,
      };
}

// Checkboxes group node
class ChoiceInputNode extends FormNode {
  final List<String> choiceLabels;
  final ChoiceCardinality choiceCardinality;

  const ChoiceInputNode({
    required super.id,
    required super.label,
    required this.choiceLabels,
    required this.choiceCardinality,
  });

  factory ChoiceInputNode.fromJson(String id, Map<String, dynamic> json) {
    return ChoiceInputNode(
      id: id,
      label: json['label'] as String,
      choiceLabels: List<String>.from(json['choiceLabels']),
      choiceCardinality: ChoiceCardinality.values.firstWhere(
        (e) => e.name == json['choiceCardinality'],
        orElse: () => throw ArgumentError(
            'Unknown ChoiceCardinality: ${json['choiceCardinality']}'),
      ),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'choiceInput',
        'label': label,
        'choiceLabels': choiceLabels,
        'choiceCardinality': choiceCardinality.name,
      };
}



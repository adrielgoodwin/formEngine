import 'package:flutter/services.dart';

class DateDdMmYyyyFormatter extends TextInputFormatter {
  const DateDdMmYyyyFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final capped = digits.length > 8 ? digits.substring(0, 8) : digits;

    final buf = StringBuffer();
    for (var i = 0; i < capped.length; i++) {
      if (i == 2 || i == 4) buf.write('/');
      buf.write(capped[i]);
    }

    final text = buf.toString();

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class MoneyCentsFormatter extends TextInputFormatter {
  const MoneyCentsFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return const TextEditingValue(text: '');

    final cents = int.tryParse(digits) ?? 0;
    final dollars = cents ~/ 100;
    final centPart = (cents % 100).toString().padLeft(2, '0');

    final dollarsStr = _groupThousands(dollars.toString());
    final text = '$dollarsStr.$centPart';

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  String _groupThousands(String s) {
    final chars = s.split('');
    final out = <String>[];
    var count = 0;
    for (var i = chars.length - 1; i >= 0; i--) {
      out.add(chars[i]);
      count++;
      if (count == 3 && i != 0) {
        out.add(',');
        count = 0;
      }
    }
    return out.reversed.join();
  }
}

class SinSpacerFormatter extends TextInputFormatter {
  const SinSpacerFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final capped = digits.length > 9 ? digits.substring(0, 9) : digits;

    final buf = StringBuffer();
    for (var i = 0; i < capped.length; i++) {
      if (i == 3 || i == 6) buf.write(' ');
      buf.write(capped[i]);
    }

    final text = buf.toString();

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class PhoneNanpFormatter extends TextInputFormatter {
  const PhoneNanpFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final capped = digits.length > 11 ? digits.substring(0, 11) : digits;

    if (capped.isEmpty) {
      return const TextEditingValue(text: '');
    }

    final hasCountry = capped.length == 11 && capped.startsWith('1');
    final local = hasCountry ? capped.substring(1) : capped;

    final formattedLocal = _formatLocal(local);
    final text = hasCountry ? '+1 $formattedLocal' : formattedLocal;

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  String _formatLocal(String digits) {
    if (digits.isEmpty) return '';

    final capped = digits.length > 10 ? digits.substring(0, 10) : digits;
    final area = capped.substring(0, capped.length.clamp(0, 3));
    final prefix = capped.length > 3
        ? capped.substring(3, capped.length.clamp(3, 6))
        : '';
    final line = capped.length > 6 ? capped.substring(6) : '';

    final buf = StringBuffer();
    buf.write('(');
    buf.write(area);

    if (capped.length >= 3) {
      buf.write(')');
    }

    if (prefix.isNotEmpty) {
      if (capped.length >= 3) {
        buf.write(' ');
      }
      buf.write(prefix);
    }

    if (line.isNotEmpty) {
      buf.write('-');
      buf.write(line);
    }

    return buf.toString();
  }
}

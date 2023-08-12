library file_sizes;

const int _divider = 1024;

class FileSizeUtil {
  static const _precisionValue = PrecisionValue.two;

  ///  [size] can be passed as number or as string
  ///  the optional parameter [PrecisionValue] specifies the number
  ///  of digits after comma/point (default is [PrecisionValue.Two])
  ///
  /// Example:
  /// ```dart
  ///    FileSize.getSize(1024)
  ///    FileSize.getSize(1024, precisionValue = PrecisionValue.Four)
  ///  ```
  static String getSize(dynamic size,
      {PrecisionValue precision = PrecisionValue.two}) {
    int? size0 = _parseValue(size);

    if (size0 < _divider) return getBytes(size0);
    if (size0 < _getDividerValue(2)) return getKiloBytes(size0);
    if (size0 < _getDividerValue(3)) return getMegaBytes(size0);
    if (size0 < _getDividerValue(4)) return getGigaBytes(size0);
    if (size0 < _getDividerValue(5)) return getTeraBytes(size0);
    if (size0 < _getDividerValue(6)) return getPetaBytes(size0);
    if (size0 < _getDividerValue(7)) return getExaBytes(size0);
    if (size0 < _getDividerValue(8)) return getYottaBytes(size0);
    if (size0 < _getDividerValue(9)) return getZettaBytes(size0);
    return getZettaBytes(size0);
  }

  /// It returns the size of the file in bytes
  ///
  /// [FileSizeType.bytes]
  static String getBytes(dynamic data) => "${_parseValue(data)} B";

  /// It returns the size of the file in kilo bytes
  ///
  /// [FileSizeType.kiloBytes]
  static String getKiloBytes(dynamic data, {PrecisionValue? value}) {
    return "${(_parseValue(data) / 1024).toStringAsFixed(_getPrecisionValue(value ?? _precisionValue))} KB";
  }

  /// It returns the size of the file in mega bytes
  ///
  /// [FileSizeType.megaBytes]
  static String getMegaBytes(dynamic data, {PrecisionValue? value}) {
    return "${(_parseValue(data) / _getDividerValue(2)).toStringAsFixed(_getPrecisionValue(value ?? _precisionValue))} MB";
  }

  /// It returns the size of the file in giga bytes
  ///
  /// [FileSizeType.gigaBytes]
  static String getGigaBytes(dynamic data, {PrecisionValue? value}) {
    return "${(_parseValue(data) / _getDividerValue(3)).toStringAsFixed(_getPrecisionValue(value ?? _precisionValue))} GB";
  }

  /// It returns the size of the file in tera bytes
  ///
  /// [FileSizeType.teraBytes]
  static String getTeraBytes(dynamic data, {PrecisionValue? value}) {
    num r = _parseValue(data) / _getDividerValue(4);
    return "${r.toStringAsFixed(_getPrecisionValue(value ?? _precisionValue))} TB";
  }

  /// It returns the size of the file in peta bytes
  ///
  /// [FileSizeType.petaBytes]
  static String getPetaBytes(dynamic data, {PrecisionValue? value}) {
    num r = _parseValue(data) / _getDividerValue(5);
    return "${r.toStringAsFixed(_getPrecisionValue(value ?? _precisionValue))} PB";
  }

  /// It returns the size of the file in exa bytes
  ///
  /// [FileSizeType.exaBytes]
  static String getExaBytes(dynamic data, {PrecisionValue? value}) {
    num r = _parseValue(data) / _getDividerValue(6);
    return "${r.toStringAsFixed(_getPrecisionValue(value ?? _precisionValue))} EB";
  }

  /// It returns the size of the file in yotta bytes
  ///
  /// [FileSizeType.yottaBytes]
  static String getYottaBytes(dynamic data, {PrecisionValue? value}) {
    num r = _parseValue(data) / _getDividerValue(7);
    return "${r.toStringAsFixed(_getPrecisionValue(value ?? _precisionValue))} YB";
  }

  /// It returns the size of the file in zetta bytes
  ///
  /// [FileSizeType.zettaBytes]
  static String getZettaBytes(dynamic data, {PrecisionValue? value}) {
    num r = _parseValue(data) / _getDividerValue(8);
    return "${r.toStringAsFixed(_getPrecisionValue(value ?? _precisionValue))} ZB";
  }

  static int _parseValue(dynamic size) {
    try {
      return size is int ? size : int.parse(size.toString());
    } on FormatException catch (e) {
      throw FormatException("Can not parse the size parameter: ${e.message}");
    }
  }
}

int _getDividerValue(int numberOf) {
  int finalValue = _divider;
  for (int i = 0; i < numberOf - 1; i++) {
    finalValue *= _divider;
  }
  return finalValue;
}

int _getPrecisionValue(PrecisionValue value) =>
    PrecisionValue.values.indexOf(value);

/// It is for getting the result in the desired string representation
/// By default, it is set to [FileSizeType.Default]
enum FileSizeType {
  // Default,
  bytes,
  kiloBytes,
  megaBytes,
  gigaBytes,
  teraBytes,
  petaBytes,
  exaBytes,
  zettaBytes,
  yottaBytes
}

enum PrecisionValue { none, one, two, three, four, five, six, seven }

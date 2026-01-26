import 'dart:convert';

/// Configuration model for custom data and log paths
class AppConfig {
  final String dataPath;
  final String logPath;

  const AppConfig({
    required this.dataPath,
    required this.logPath,
  });

  /// Creates AppConfig from JSON
  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      dataPath: json['dataPath'] as String,
      logPath: json['logPath'] as String,
    );
  }

  /// Converts AppConfig to JSON
  Map<String, dynamic> toJson() => {
        'dataPath': dataPath,
        'logPath': logPath,
      };

  /// Creates default config with current hardcoded paths
  factory AppConfig.defaultConfig() {
    return const AppConfig(
      dataPath: r'C:\ProgramData\EstateIntake\cases',
      logPath: r'C:\ProgramData\EstateIntake\logs',
    );
  }

  /// Creates default config as JSON string
  static String defaultConfigJson() {
    return jsonEncode(AppConfig.defaultConfig().toJson());
  }

  @override
  String toString() => 'AppConfig(dataPath: $dataPath, logPath: $logPath)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppConfig &&
        other.dataPath == dataPath &&
        other.logPath == logPath;
  }

  @override
  int get hashCode => dataPath.hashCode ^ logPath.hashCode;
}

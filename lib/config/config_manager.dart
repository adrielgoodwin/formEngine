import 'dart:convert';
import 'dart:io';

import '../logging/app_logger.dart';
import 'config_model.dart';

/// Manages loading and providing configuration paths
/// Looks for config.json beside the executable, falls back to defaults
class ConfigManager {
  static AppConfig? _cachedConfig;
  static bool _loadAttempted = false;

  /// Gets the data path from config or defaults
  static String get dataPath {
    return _getConfig().dataPath;
  }

  /// Gets the log path from config or defaults
  static String get logPath {
    return _getConfig().logPath;
  }

  /// Gets the loaded config, loading it if necessary
  static AppConfig _getConfig() {
    if (_cachedConfig != null) {
      return _cachedConfig!;
    }

    if (!_loadAttempted) {
      _loadAttempted = true;
      _cachedConfig = _loadConfig();
    }

    return _cachedConfig ?? AppConfig.defaultConfig();
  }

  /// Attempts to load config.json from the executable directory
  static AppConfig? _loadConfig() {
    try {
      final configPath = _getConfigFilePath();
      final configFile = File(configPath);

      if (!configFile.existsSync()) {
        AppLogger.instance.info(
          'config',
          'Config file not found at $configPath, using defaults',
        );
        return null;
      }

      final content = configFile.readAsStringSync(encoding: utf8);
      final json = jsonDecode(content) as Map<String, dynamic>;

      final config = AppConfig.fromJson(json);
      
      // Validate that paths are reasonable
      if (config.dataPath.isEmpty || config.logPath.isEmpty) {
        AppLogger.instance.warn(
          'config',
          'Config contains empty paths, using defaults',
        );
        return null;
      }

      AppLogger.instance.info(
        'config',
        'Loaded config from $configPath: $config',
      );

      return config;
    } catch (e, st) {
      AppLogger.instance.warn(
        'config',
        'Failed to load config, using defaults',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  /// Gets the path to config.json beside the executable
  static String _getConfigFilePath() {
    final exePath = Platform.executable;
    final exeDir = Directory(exePath).parent;
    return '${exeDir.path}/config.json';
  }

  /// Forces a reload of the config (useful for testing)
  static void reload() {
    _cachedConfig = null;
    _loadAttempted = false;
  }

  /// Gets the directory where the executable is located
  static String get executableDirectory {
    return Directory(Platform.executable).parent.path;
  }

  /// Creates a default config file at the expected location
  /// Returns true if successful, false if failed or already exists
  static Future<bool> createDefaultConfigFile() async {
    try {
      final configPath = _getConfigFilePath();
      final configFile = File(configPath);

      if (configFile.existsSync()) {
        AppLogger.instance.info('config', 'Config file already exists at $configPath');
        return false;
      }

      await configFile.writeAsString(AppConfig.defaultConfigJson(), encoding: utf8);
      AppLogger.instance.info('config', 'Created default config at $configPath');
      return true;
    } catch (e, st) {
      AppLogger.instance.warn(
        'config',
        'Failed to create default config file',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  /// Validates that the configured paths are accessible
  static Future<bool> validatePaths() async {
    final config = _getConfig();
    bool allValid = true;

    try {
      // Test data path
      final dataDir = Directory(config.dataPath);
      if (!dataDir.existsSync()) {
        await dataDir.create(recursive: true);
        AppLogger.instance.info('config', 'Created data directory: ${config.dataPath}');
      }
    } catch (e) {
      AppLogger.instance.warn('config', 'Data path not accessible: ${config.dataPath}', error: e);
      allValid = false;
    }

    try {
      // Test log path
      final logDir = Directory(config.logPath);
      if (!logDir.existsSync()) {
        await logDir.create(recursive: true);
        AppLogger.instance.info('config', 'Created log directory: ${config.logPath}');
      }
    } catch (e) {
      AppLogger.instance.warn('config', 'Log path not accessible: ${config.logPath}', error: e);
      allValid = false;
    }

    return allValid;
  }
}

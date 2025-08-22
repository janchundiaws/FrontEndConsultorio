class AppConfig {
  // Configuración de la aplicación
  static const String appName = 'Clínica Odontológica';
  static const String appVersion = '1.0.0';
  
  // Configuración de la API
  static const String apiBaseUrl = 'https://backendconsultorio.onrender.com';
  static const String apiVersion = 'v1';
  
  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Configuración de CORS
  static const Map<String, String> corsHeaders = {
    'Accept': '*/*',
    'x-tenant-id': 'Admin',
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization, X-Requested-With',
  };
  
  // Configuración de autenticación
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const Duration tokenExpiration = Duration(hours: 24);
  
  // Configuración de almacenamiento
  static const String storagePrefix = 'odontologo_';
  
  // Configuración de logging
  static const bool enableLogging = true;
  static const String logLevel = 'INFO';
  
  // Configuración de errores
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  
  // URLs de endpoints
  static const String loginEndpoint = '/api/login';
  static const String logoutEndpoint = '/api/logout';
  static const String verifyTokenEndpoint = '/api/verify-token';
  static const String refreshTokenEndpoint = '/api/refresh-token';
  static const String healthCheckEndpoint = '/api/health';
  
  // Configuración de archivos
  static const List<String> allowedFileExtensions = ['pdf', 'jpg', 'jpeg', 'png'];
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  
  // Configuración de validación
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 50;
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 50;
  
  // Configuración de UI
  static const double defaultBorderRadius = 12.0;
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration toastDuration = Duration(seconds: 3);
  
  // Configuración de paginación
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Configuración de caché
  static const Duration cacheExpiration = Duration(minutes: 30);
  static const int maxCacheSize = 100;
  
  // Configuración de notificaciones
  static const bool enablePushNotifications = false;
  static const String notificationChannelId = 'odontologo_channel';
  static const String notificationChannelName = 'Odontólogo Notifications';
  
  // Configuración de analytics
  static const bool enableAnalytics = false;
  static const String analyticsKey = '';
  
  // Configuración de crash reporting
  static const bool enableCrashReporting = false;
  static const String crashReportingKey = '';
  
  // Configuración de feature flags
  static const bool enableExperimentalFeatures = false;
  static const bool enableBetaFeatures = false;
  
  // Configuración de seguridad
  static const bool enableBiometricAuth = false;
  static const bool enableAutoLogout = true;
  static const Duration autoLogoutDuration = Duration(minutes: 30);
  
  // Configuración de backup
  static const bool enableAutoBackup = false;
  static const Duration backupInterval = Duration(days: 7);
  
  // Configuración de sincronización
  static const bool enableOfflineMode = true;
  static const bool enableAutoSync = true;
  static const Duration syncInterval = Duration(minutes: 15);
  
  // Configuración de exportación
  static const List<String> supportedExportFormats = ['pdf', 'csv', 'xlsx'];
  static const int maxExportRecords = 10000;
  
  // Configuración de importación
  static const List<String> supportedImportFormats = ['csv', 'xlsx'];
  static const int maxImportRecords = 1000;
  
  // Configuración de reportes
  static const bool enableCustomReports = true;
  static const int maxReportRecords = 5000;
  
  // Configuración de auditoría
  static const bool enableAuditLog = true;
  static const Duration auditLogRetention = Duration(days: 365);
  
  // Configuración de respaldo
  static const bool enableDataBackup = true;
  static const Duration backupRetention = Duration(days: 30);
  
  // Configuración de limpieza
  static const bool enableAutoCleanup = true;
  static const Duration cleanupInterval = Duration(days: 1);
  
  // Configuración de monitoreo
  static const bool enablePerformanceMonitoring = false;
  static const Duration monitoringInterval = Duration(minutes: 5);
  
  // Configuración de debugging
  static const bool enableDebugMode = false;
  static const bool enableVerboseLogging = false;
  
  // Configuración de testing
  static const bool enableTestMode = false;
  static const String testApiUrl = 'http://localhost:3000';
  
  // Configuración de staging
  static const bool enableStagingMode = false;
  static const String stagingApiUrl = 'https://staging-backendconsultorio.onrender.com';
  
  // Configuración de producción
  static const bool enableProductionMode = true;
  static const String productionApiUrl = 'https://backendconsultorio.onrender.com';
  
  // Métodos de utilidad
  static String getApiUrl() {
    if (enableTestMode) return testApiUrl;
    if (enableStagingMode) return stagingApiUrl;
    return productionApiUrl;
  }
  
  static bool isDevelopment() {
    return enableDebugMode || enableTestMode || enableStagingMode;
  }
  
  static bool isProduction() {
    return enableProductionMode && !isDevelopment();
  }
  
  static String getFullApiUrl(String endpoint) {
    return '${getApiUrl()}$endpoint';
  }
  
  static Map<String, String> getHeaders({String? token}) {
    final headers = Map<String, String>.from(corsHeaders);
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }
} 
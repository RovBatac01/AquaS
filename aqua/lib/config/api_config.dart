class ApiConfig {
  // Toggle this between development and production
  static const bool isDevelopment = true;
  
  // API Base URLs
  static const String _developmentUrl = "https://aquasense-p36u.onrender.com";
  static const String _productionUrl = "http://localhost:5000";
  
  // Get the current base URL based on environment
  static String get baseUrl {
    return isDevelopment ? _developmentUrl : _productionUrl;
  }
  
  // Common endpoints
  static String get loginEndpoint => "$baseUrl/login";
  static String get logoutEndpoint => "$baseUrl/logout";
  static String get signupEndpoint => "$baseUrl/api/signup-otp";
  static String get verifyOtpEndpoint => "$baseUrl/api/verify-signup-otp";
  static String get resendOtpEndpoint => "$baseUrl/api/resend-signup-otp";
  static String get forgotPasswordEndpoint => "$baseUrl/api/forgot-password";
  static String get verifyPasswordOtpEndpoint => "$baseUrl/api/verify-otp";
  static String get changePasswordEndpoint => "$baseUrl/api/change-password";
  static String get registerEndpoint => "$baseUrl/register";
  static String get dataEndpoint => "$baseUrl/data";
  static String get apiBase => "$baseUrl/api";
  
  // User profile endpoints
  static String get userProfileEndpoint => "$baseUrl/api/user/profile";
  static String get adminProfileEndpoint => "$baseUrl/api/admin/profile";
  static String get superAdminProfileEndpoint => "$baseUrl/api/super-admin/profile";
  static String get superAdminChangePasswordEndpoint => "$baseUrl/api/super-admin/change-password";
  
  // Notification endpoints
  static String get adminNotificationsEndpoint => "$baseUrl/api/notifications/admin";
  static String get superAdminNotificationsEndpoint => "$baseUrl/api/notifications/superadmin";
  
  // Helper method to get notification endpoint by ID
  static String getSuperAdminNotificationEndpoint(int id) => "$baseUrl/api/notifications/superadmin/$id";
  
  // Device request endpoints
  static String get deviceRequestEndpoint => "$baseUrl/api/device-request";
  static String get pendingDeviceRequestsEndpoint => "$baseUrl/api/device-requests/pending";
  static String deviceRequestResponseEndpoint(String requestId) => "$baseUrl/api/device-requests/$requestId/respond";
  static String get userDeviceAccessEndpoint => "$baseUrl/api/user/device-access";
  static String get userDeviceRequestsEndpoint => "$baseUrl/api/user/device-requests";
  
  // Establishment sensors endpoints
  static String establishmentSensorsEndpoint(int establishmentId) => "$baseUrl/api/establishment/$establishmentId/sensors";
  static String deviceSensorsEndpoint(String deviceId) => "$baseUrl/api/device/$deviceId/sensors";
}
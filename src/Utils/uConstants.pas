unit uConstants;

interface

const
  // API Configuration
  // DataSnap REST API - VDS sunucu adresi
  // Derleme oncesi kendi sunucu IP'nizi buraya yazin
  API_BASE_URL = 'http://2.56.152.155:8080/datasnap/';
  API_VERSION = 'v1';
  API_TIMEOUT = 30000; // 30 seconds

  // App Info
  APP_NAME = 'TicariERP Mobil';
  APP_VERSION = '1.0.0';
  APP_PACKAGE = 'com.ticarierp.mobil';

  // Colors
  COLOR_PRIMARY = $FF1565C0;       // Dark Blue
  COLOR_PRIMARY_LIGHT = $FF1976D2; // Blue
  COLOR_ACCENT = $FFFF5722;        // Orange-Red
  COLOR_SUCCESS = $FF4CAF50;       // Green
  COLOR_WARNING = $FFFF9800;       // Orange
  COLOR_DANGER = $FFF44336;        // Red
  COLOR_INFO = $FF2196F3;          // Light Blue
  COLOR_BACKGROUND = $FFF5F5F5;    // Light Grey
  COLOR_TEXT_PRIMARY = $FF212121;   // Almost Black
  COLOR_TEXT_SECONDARY = $FF757575; // Grey

  // Order Status Colors
  COLOR_STATUS_HAZIRLANIYOR = $FFFF9800;
  COLOR_STATUS_YOLDA = $FF2196F3;
  COLOR_STATUS_TESLIM = $FF4CAF50;
  COLOR_STATUS_IPTAL = $FFF44336;

  // SharedPreferences Keys
  PREF_TOKEN = 'auth_token';
  PREF_USER_ID = 'user_id';
  PREF_USER_NAME = 'user_name';
  PREF_BAYI_NAME = 'bayi_name';
  PREF_REMEMBER_ME = 'remember_me';

  // Pagination
  DEFAULT_PAGE_SIZE = 20;

  // Date Formats
  DATE_FORMAT_DISPLAY = 'dd.mm.yyyy';
  DATE_FORMAT_TIME = 'hh:nn';
  DATE_FORMAT_FULL = 'dd.mm.yyyy hh:nn';

implementation

end.

/// Nova Agent — App-wide constants
class AppConstants {
  AppConstants._();

  // ── Branding ──────────────────────────────────────────────────────────────
  static const String version    = '1.1.0';
  static const String appName    = 'Nova Agent';
  static const String cliCommand = 'novax';
  static const String npmPackage = 'nova-agent';
  static const String githubRepo = 'https://github.com/lekhanpro/nova-agent';

  // ── Termux paths ──────────────────────────────────────────────────────────
  static const String termuxHome  = '/data/data/com.termux/files/home';
  static const String termuxBin   = '/data/data/com.termux/files/usr/bin';
  static const String novaxPath   = '/data/data/com.termux/files/usr/bin/novax';
  static const String configDir   = '/data/data/com.termux/files/home/.nova_agent';
  static const String configFile  = '/data/data/com.termux/files/home/.nova_agent/config';
  static const String historyFile = '/data/data/com.termux/files/home/.nova_agent/history.json';

  // ── SharedPreferences keys ────────────────────────────────────────────────
  static const String prefSetupDone = 'setup_done';
  static const String prefProvider  = 'provider';
  static const String prefModel     = 'model';
  static const String prefAutoStart = 'auto_start';

  // ── Providers with models ─────────────────────────────────────────────────
  static const List<Map<String, dynamic>> providers = [
    {
      'id': 'gemini',
      'name': 'Google Gemini',
      'free': true,
      'url': 'https://aistudio.google.com/app/apikey',
      'envKey': 'GEMINI_API_KEY',
      'models': ['gemini-2.0-flash', 'gemini-2.0-pro-exp', 'gemini-1.5-pro', 'gemini-1.5-flash'],
      'default': 'gemini-2.0-flash',
    },
    {
      'id': 'openai',
      'name': 'OpenAI',
      'free': false,
      'url': 'https://platform.openai.com/api-keys',
      'envKey': 'OPENAI_API_KEY',
      'models': ['gpt-4.1', 'gpt-4o', 'gpt-4o-mini', 'o4-mini', 'gpt-4-turbo'],
      'default': 'gpt-4.1',
    },
    {
      'id': 'anthropic',
      'name': 'Anthropic',
      'free': false,
      'url': 'https://console.anthropic.com/',
      'envKey': 'ANTHROPIC_API_KEY',
      'models': ['claude-opus-4-5', 'claude-sonnet-4-5', 'claude-3-5-haiku-latest', 'claude-3-5-sonnet-latest'],
      'default': 'claude-sonnet-4-5',
    },
  ];

  // ── Setup steps (nova-agent bootstrap) ────────────────────────────────────
  static const List<String> setupSteps = [
    'Updating Termux packages',
    'Installing Node.js & Python',
    'Installing Termux:API bridge',
    'Installing Nova Agent globally',
    'Verifying installation',
  ];

  // ── 27 available tools ────────────────────────────────────────────────────
  static const List<String> availableTools = [
    'get_location', 'take_photo', 'list_files', 'read_file', 'write_file',
    'send_sms', 'list_sms', 'list_contacts', 'vibrate', 'get_battery',
    'get_device_info', 'get_clipboard', 'set_clipboard', 'play_sound',
    'send_notification', 'get_wifi_info', 'get_volume', 'set_volume',
    'list_installed_apps', 'take_screenshot', 'open_url', 'run_command',
    'get_brightness', 'set_brightness', 'get_sensor_data', 'get_call_log', 'make_call',
  ];
}


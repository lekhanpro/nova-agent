/// Nova Agent — App-wide constants
class AppConstants {
  AppConstants._();

  // ── Branding ──────────────────────────────────────────────────────────────
  static const String appName        = 'Nova Agent';
  static const String cliCommand     = 'novax';
  static const String npmPackage     = 'nova-agent';
  static const String version        = '1.0.0';

  // ── GitHub ────────────────────────────────────────────────────────────────
  static const String githubRepo     = 'https://github.com/lekhanpro/nova-agent';
  static const String githubReleases = 'https://github.com/lekhanpro/nova-agent/releases';
  static const String githubIssues   = 'https://github.com/lekhanpro/nova-agent/issues';

  // ── Network ───────────────────────────────────────────────────────────────
  static const String webDashboard   = 'http://localhost:8000';
  static const int    webPort        = 8000;

  // ── proot paths (inside Ubuntu container) ────────────────────────────────
  static const String autogptDir     = '/root/autogpt';
  static const String logFile        = '/tmp/autogpt.log';
  static const String pidFile        = '/tmp/autogpt.pid';
  static const String webServerPath  = '/root/autogpt-web/server.py';

  // ── SharedPreferences keys ────────────────────────────────────────────────
  static const String prefSetupDone    = 'setup_done';
  static const String prefApiKey       = 'api_key_openai';
  static const String prefAnthropicKey = 'api_key_anthropic';
  static const String prefGoogleKey    = 'api_key_google';
  static const String prefModel        = 'selected_model';
  static const String prefAutoStart    = 'auto_start';

  // ── AI Providers ──────────────────────────────────────────────────────────
  static const List<Map<String, String>> providers = [
    {
      'name': 'OpenAI',
      'models': 'gpt-4o,gpt-4o-mini,gpt-4-turbo',
      'url': 'https://platform.openai.com/api-keys',
      'envKey': 'OPENAI_API_KEY',
    },
    {
      'name': 'Anthropic',
      'models': 'claude-3-5-sonnet-20241022,claude-3-haiku-20240307',
      'url': 'https://console.anthropic.com/',
      'envKey': 'ANTHROPIC_API_KEY',
    },
    {
      'name': 'Google Gemini',
      'models': 'gemini-1.5-flash,gemini-1.5-pro',
      'url': 'https://aistudio.google.com/app/apikey',
      'envKey': 'GOOGLE_API_KEY',
    },
  ];

  // ── Setup steps ───────────────────────────────────────────────────────────
  static const List<String> setupSteps = [
    'Updating Termux packages',
    'Installing proot-distro & Node.js',
    'Installing Ubuntu container (~500 MB)',
    'Installing Python 3.11 + build tools',
    'Cloning AutoGPT repository',
    'Setting up Python virtual environment',
    'Configuring environment (.env)',
    'Installing web log viewer',
  ];
}

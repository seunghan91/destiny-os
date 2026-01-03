import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 환경 설정
/// .env 파일과 --dart-define 모두 지원
/// 우선순위: --dart-define > .env > 기본값
class EnvConfig {
  EnvConfig._();

  // ============================================
  // BizRouter API 설정 (권장)
  // ============================================
  static String get bizRouterApiKey {
    // 1순위: --dart-define
    const compileTimeKey = String.fromEnvironment('BIZROUTER_API_KEY', defaultValue: '');
    if (compileTimeKey.isNotEmpty) return compileTimeKey;

    // 2순위: .env 파일
    return dotenv.get('BIZROUTER_API_KEY', fallback: '');
  }

  static const String bizRouterBaseUrl = 'https://bizrouter.ai/api/v1';

  // 상담용 모델 (GPT-4o: 감성적, 자연스러운 대화)
  static const String consultationModel = 'openai/gpt-4o';

  // 분석용 모델 (Gemini 2.5 Flash: 빠르고 저렴, 분석에 강함)
  static const String analysisModel = 'google/gemini-2.5-flash';

  // ============================================
  // OpenAI API 설정 (레거시/폴백용)
  // ============================================
  static String get openAiApiKey {
    const compileTimeKey = String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');
    if (compileTimeKey.isNotEmpty) return compileTimeKey;

    return dotenv.get('OPENAI_API_KEY', fallback: '');
  }

  static const String openAiBaseUrl = 'https://api.openai.com/v1';
  static const String openAiModel = 'gpt-4o-mini';

  // ============================================
  // Supabase 설정 (선택)
  // ============================================
  static String get supabaseUrl {
    const compileTimeUrl = String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://eunnaxqjyitxjdkrjaau.supabase.co',
    );
    if (compileTimeUrl != 'https://eunnaxqjyitxjdkrjaau.supabase.co') {
      return compileTimeUrl;
    }

    return dotenv.get(
      'SUPABASE_URL',
      fallback: 'https://eunnaxqjyitxjdkrjaau.supabase.co',
    );
  }

  static String get supabaseAnonKey {
    const compileTimeKey = String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV1bm5heHFqeWl0eGpka3JqYWF1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjcyNTI1ODIsImV4cCI6MjA4MjgyODU4Mn0.lecssEWJ1JfneF_O5WPNDvc8Z_OYcAJ4q952Q00PM6I',
    );
    if (compileTimeKey != 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV1bm5heHFqeWl0eGpka3JqYWF1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjcyNTI1ODIsImV4cCI6MjA4MjgyODU4Mn0.lecssEWJ1JfneF_O5WPNDvc8Z_OYcAJ4q952Q00PM6I') {
      return compileTimeKey;
    }

    return dotenv.get(
      'SUPABASE_ANON_KEY',
      fallback: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV1bm5heHFqeWl0eGpka3JqYWF1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjcyNTI1ODIsImV4cCI6MjA4MjgyODU4Mn0.lecssEWJ1JfneF_O5WPNDvc8Z_OYcAJ4q952Q00PM6I',
    );
  }

  // Edge Function URL
  static String get aiConsultationUrl =>
      '$supabaseUrl/functions/v1/ai-consultation';

  // API 키 유효성 검사
  static bool get hasBizRouterKey => bizRouterApiKey.isNotEmpty;
  static bool get hasOpenAiKey => openAiApiKey.isNotEmpty;
  static bool get hasSupabaseKey => supabaseAnonKey.isNotEmpty;

  // ============================================
  // 개발 모드 설정
  // ============================================
  static bool get useLocalFallback {
    const compileTime = String.fromEnvironment('USE_LOCAL_FALLBACK', defaultValue: 'true');
    if (compileTime != 'true') return compileTime == 'true';

    return dotenv.get('USE_LOCAL_FALLBACK', fallback: 'true') == 'true';
  }
}

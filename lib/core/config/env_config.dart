/// 환경 설정
/// 실제 API 키는 .env 파일이나 환경 변수에서 관리하세요
class EnvConfig {
  EnvConfig._();

  // ============================================
  // BizRouter API 설정 (권장)
  // ============================================
  static const String bizRouterApiKey = String.fromEnvironment(
    'BIZROUTER_API_KEY',
    defaultValue: '',
  );

  static const String bizRouterBaseUrl = 'https://bizrouter.ai/api/v1';

  // 상담용 모델 (GPT-4o: 감성적, 자연스러운 대화)
  static const String consultationModel = 'openai/gpt-4o';

  // 분석용 모델 (Gemini 2.5 Flash: 빠르고 저렴, 분석에 강함)
  static const String analysisModel = 'google/gemini-2.5-flash';

  // ============================================
  // OpenAI API 설정 (레거시/폴백용)
  // ============================================
  static const String openAiApiKey = String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue: '',
  );

  static const String openAiBaseUrl = 'https://api.openai.com/v1';
  static const String openAiModel = 'gpt-4o-mini';

  // Supabase 설정 (추후 활성화 시 사용)
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://darrlxppnvdntdxtystb.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  // Edge Function URL
  static String get aiConsultationUrl =>
      '$supabaseUrl/functions/v1/ai-consultation';

  // API 키 유효성 검사
  static bool get hasBizRouterKey => bizRouterApiKey.isNotEmpty;
  static bool get hasOpenAiKey => openAiApiKey.isNotEmpty;
  static bool get hasSupabaseKey => supabaseAnonKey.isNotEmpty;
}

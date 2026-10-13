/// MẪU CẤU HÌNH SUPABASE CLOUD (STORAGE & DATABASE)
///
/// Hướng dẫn thiết lập:
/// 1. Sao chép file này và đổi tên thành: supabase_config.dart (nằm cùng thư mục)
/// 2. Lấy thông số từ Supabase Dashboard:
///    - Đăng nhập https://supabase.com -> Chọn Project của bạn
///    - Vào Project Settings -> API
///    - Copy Project URL (https://xxxx.supabase.co) -> Dán vào [supabaseUrl]
///    - Copy Project API keys (anon public) -> Dán vào [supabaseAnonKey]
/// 3. File supabase_config.dart đã được cấu hình trong .gitignore nên sẽ KHÔNG bị lộ lên GitHub.
class SupabaseConfig {
  // Thay thế URL Project Supabase của bạn:
  static const String supabaseUrl = 'YOUR_SUPABASE_PROJECT_URL';

  // Thay thế anon public API key của bạn:
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  // Tên bucket lưu trữ tài liệu đã tạo trên Supabase Storage:
  static const String storageBucketName = 'studyhub-files';

  /// Kiểm tra xem đã điền thông tin Supabase hợp lệ hay chưa
  static bool get isConfigured {
    return supabaseUrl.isNotEmpty &&
        supabaseUrl != 'YOUR_SUPABASE_PROJECT_URL' &&
        supabaseUrl.startsWith('https://') &&
        supabaseAnonKey.isNotEmpty &&
        supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY';
  }
}

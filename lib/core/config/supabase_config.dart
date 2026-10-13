/// Cấu hình kết nối Supabase Cloud (Storage & Database)
/// 
/// Hướng dẫn lấy thông số từ Supabase Dashboard:
/// 1. Đăng nhập https://supabase.com -> Chọn Project của bạn
/// 2. Bấm icon bánh răng "Project Settings" (góc dưới bên trái) -> Chọn "API"
/// 3. Sao chép:
///    - Project URL (dạng: https://abcdefghijklm.supabase.co) -> Dán vào [supabaseUrl]
///    - Project API keys -> "anon" "public" (chuỗi eyJhbGciOi...) -> Dán vào [supabaseAnonKey]
class SupabaseConfig {
  // Thay thế URL Project Supabase của bạn vào đây:
  static const String supabaseUrl = 'YOUR_SUPABASE_PROJECT_URL';

  // Thay thế anon public API key của bạn vào đây:
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  // Tên bucket lưu trữ tài liệu đã tạo trên Supabase Storage:
  static const String storageBucketName = 'studyhub-files';

  /// Kiểm tra xem người dùng đã điền thông tin Supabase hợp lệ hay chưa
  static bool get isConfigured {
    return supabaseUrl.isNotEmpty &&
        supabaseUrl != 'YOUR_SUPABASE_PROJECT_URL' &&
        supabaseUrl.startsWith('https://') &&
        supabaseAnonKey.isNotEmpty &&
        supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY';
  }
}

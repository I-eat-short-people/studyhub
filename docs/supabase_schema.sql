-- =========================================================================
-- STUDYHUB - SUPABASE DATABASE & STORAGE SCHEMA
-- Chạy đoạn script SQL này trong mục "SQL Editor" trên Supabase Dashboard
-- =========================================================================

-- 1. TẠO BẢNG DOCUMENTS (Lưu trữ metadata tài liệu trên Cloud)
CREATE TABLE IF NOT EXISTS public.documents (
    id TEXT PRIMARY KEY,                           -- UUID của tài liệu (đồng bộ với documentPk trong máy)
    name TEXT NOT NULL,                            -- Tên hiển thị của tài liệu
    subject_name TEXT,                             -- Tên môn học
    owner_uid TEXT NOT NULL,                       -- Firebase UID của người sở hữu
    owner_email TEXT NOT NULL,                     -- Email Google của người sở hữu
    file_name TEXT NOT NULL,                       -- Tên file đính kèm (vd: de_thi_giua_ky.pdf)
    file_size INTEGER DEFAULT 0,                   -- Dung lượng bytes
    mime_type TEXT DEFAULT 'application/pdf',      -- MIME type (application/pdf, msword...)
    storage_path TEXT NOT NULL,                    -- Đường dẫn trong bucket Supabase Storage
    download_url TEXT,                             -- Link tải hoặc preview file
    category INTEGER DEFAULT 0,                    -- 0: lecture, 1: reference, 2: exercise, 3: exam
    note TEXT,                                     -- Ghi chú kèm theo tài liệu
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tạo Index để truy vấn nhanh theo chủ sở hữu và ngày tạo
CREATE INDEX IF NOT EXISTS idx_documents_owner_email ON public.documents(owner_email);
CREATE INDEX IF NOT EXISTS idx_documents_owner_uid ON public.documents(owner_uid);
CREATE INDEX IF NOT EXISTS idx_documents_created_at ON public.documents(created_at DESC);

-- 2. TẠO BẢNG DOCUMENT_SHARES (Phân quyền chia sẻ tài liệu giữa người dùng)
CREATE TABLE IF NOT EXISTS public.document_shares (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id TEXT NOT NULL REFERENCES public.documents(id) ON DELETE CASCADE,
    shared_by_uid TEXT NOT NULL,                   -- Firebase UID của người chia sẻ
    shared_by_email TEXT NOT NULL,                 -- Email người chia sẻ
    shared_with_email TEXT NOT NULL,               -- Email người được chia sẻ (luôn lưu chữ thường)
    permission TEXT DEFAULT 'view',                -- 'view' (chỉ đọc/tải) hoặc 'edit' (được chỉnh sửa)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(document_id, shared_with_email)         -- Mỗi tài liệu chỉ chia sẻ 1 lần cho 1 người
);

-- Tạo Index để người nhận truy vấn tức thời các tài liệu được chia sẻ với mình
CREATE INDEX IF NOT EXISTS idx_shares_shared_with_email ON public.document_shares(shared_with_email);
CREATE INDEX IF NOT EXISTS idx_shares_document_id ON public.document_shares(document_id);

-- 3. CẤU HÌNH BẢO MẬT & QUYỀN TRUY CẬP (Row Level Security - RLS)
-- Bật RLS cho 2 bảng
ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.document_shares ENABLE ROW LEVEL SECURITY;

-- Tạo policy cho phép app truy cập thông qua Supabase anon key
-- (Do ứng dụng xác thực qua Firebase Auth, app sẽ truyền email/uid để kiểm soát)
DROP POLICY IF EXISTS "Allow anon read write documents" ON public.documents;
CREATE POLICY "Allow anon read write documents" ON public.documents
    FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow anon read write shares" ON public.document_shares;
CREATE POLICY "Allow anon read write shares" ON public.document_shares
    FOR ALL USING (true) WITH CHECK (true);

-- =========================================================================
-- 4. HƯỚNG DẪN TẠO STORAGE BUCKET TRÊN SUPABASE:
-- =========================================================================
-- Bước 1: Vào Supabase Dashboard -> Menu bên trái chọn "Storage"
-- Bước 2: Bấm nút "New bucket"
-- Bước 3: Đặt tên bucket là: studyhub-files
-- Bước 4: Bật công tắc "Public bucket" sang ON (để cho phép xem preview & tải file nhanh)
-- Bước 5: Bấm "Save bucket"

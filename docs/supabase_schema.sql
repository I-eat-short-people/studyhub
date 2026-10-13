-- =========================================================================
-- STUDYHUB - SUPABASE DATABASE & STORAGE SCHEMA
-- Chạy đoạn script SQL này trong mục "SQL Editor" trên Supabase Dashboard
-- để sửa triệt để lỗi 403 Row-Level Security (RLS) khi upload và lưu tài liệu.
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

CREATE INDEX IF NOT EXISTS idx_shares_shared_with_email ON public.document_shares(shared_with_email);
CREATE INDEX IF NOT EXISTS idx_shares_document_id ON public.document_shares(document_id);

-- 3. CẤU HÌNH BẢO MẬT & QUYỀN TRUY CẬP (Row Level Security - RLS) CHO DATABASE
GRANT ALL ON TABLE public.documents TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.document_shares TO anon, authenticated, service_role;

ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.document_shares ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow anon read write documents" ON public.documents;
CREATE POLICY "Allow anon read write documents" ON public.documents
    FOR ALL TO public
    USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow anon read write shares" ON public.document_shares;
CREATE POLICY "Allow anon read write shares" ON public.document_shares
    FOR ALL TO public
    USING (true) WITH CHECK (true);

-- =========================================================================
-- 4. FIX LỖI 403 RLS CHO SUPABASE STORAGE (BUCKET studyhub-files)
-- Lỗi 403 xảy ra vì bảng storage.objects mặc định chặn quyền upload của anon key.
-- Các câu lệnh sau sẽ mở quyền upload/tải cho bucket studyhub-files:
-- =========================================================================

-- Đảm bảo bucket studyhub-files tồn tại và là public
INSERT INTO storage.buckets (id, name, public)
VALUES ('studyhub-files', 'studyhub-files', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Mở quyền INSERT (Upload file)
DROP POLICY IF EXISTS "Allow public uploads to studyhub-files" ON storage.objects;
CREATE POLICY "Allow public uploads to studyhub-files" ON storage.objects
    FOR INSERT TO public
    WITH CHECK (bucket_id = 'studyhub-files');

-- Mở quyền SELECT (Xem/Tải file)
DROP POLICY IF EXISTS "Allow public read from studyhub-files" ON storage.objects;
CREATE POLICY "Allow public read from studyhub-files" ON storage.objects
    FOR SELECT TO public
    USING (bucket_id = 'studyhub-files');

-- Mở quyền UPDATE (Ghi đè file nếu đã tồn tại)
DROP POLICY IF EXISTS "Allow public update in studyhub-files" ON storage.objects;
CREATE POLICY "Allow public update in studyhub-files" ON storage.objects
    FOR UPDATE TO public
    USING (bucket_id = 'studyhub-files')
    WITH CHECK (bucket_id = 'studyhub-files');

-- Mở quyền DELETE (Xóa file)
DROP POLICY IF EXISTS "Allow public delete in studyhub-files" ON storage.objects;
CREATE POLICY "Allow public delete in studyhub-files" ON storage.objects
    FOR DELETE TO public
    USING (bucket_id = 'studyhub-files');

# 📘 TÀI LIỆU PHÂN TÍCH YÊU CẦU CHỨC NĂNG (FRD)
## DỰ ÁN: STUDYHUB - HỆ THỐNG QUẢN LÝ TÀI LIỆU HỌC TẬP THÔNG MINH

---

## 1. TỔNG QUAN HỆ THỐNG
**StudyHub** là ứng dụng di động và desktop phục vụ học sinh, sinh viên và giảng viên trong việc lưu trữ, phân loại, tìm kiếm và xem trực tiếp tài liệu học tập của các học phần/môn học. Ứng dụng được xây dựng theo kiến trúc **Local-First & Offline-First** kế thừa từ nền tảng ứng dụng **Cashew**, sử dụng **Flutter**, **Drift ORM (SQLite)** và **Material Design 3**.

---

## 2. TÁC NHÂN HỆ THỐNG (ACTORS)
- **Người học / Sinh viên (Primary User)**: Người dùng chính thực hiện thêm môn học, tải lên bài giảng, slide, đề cương, đánh dấu tài liệu quan trọng và đọc trực tiếp tài liệu PDF.
- **Hệ thống tệp cục bộ (Local File System / Storage)**: Lưu trữ các bản sao tệp tài liệu PDF, DOCX, PPTX an toàn trong thư mục ứng dụng.
- **Drift SQLite Engine (Local Database)**: Nguồn chân lý duy nhất (Single Source of Truth) lưu trữ toàn bộ thực thể và log xóa phục vụ đồng bộ.

---

## 3. DANH SÁCH YÊU CẦU CHỨC NĂNG CHI TIẾT

### 3.1. Phân hệ Quản lý Môn học (Subject Management)
| Mã yêu cầu | Tên chức năng | Mô tả chi tiết |
|---|---|---|
| **FR-SUB-01** | Tạo môn học mới | Người dùng nhập Tên môn học, Mã học phần (VD: CSE441), chọn Màu sắc nhận diện từ bảng màu Pastel của Cashew, chọn Biểu tượng (Book, Smartphone, Cloud, Calculate,...). Hệ thống sinh mã UUID tự động cho `subjectPk`. |
| **FR-SUB-02** | Xem danh sách môn học | Hiển thị toàn bộ môn học dạng danh sách (Mobile) hoặc lưới (Desktop). Mỗi thẻ môn học hiển thị mã học phần, tên môn học, icon đại diện và số lượng tài liệu hiện có (cập nhật phản ứng tức thì qua Reactive Stream). |
| **FR-SUB-03** | Chỉnh sửa môn học | Cho phép cập nhật tên, mã môn, màu sắc và biểu tượng của môn học đã tồn tại. Tự động cập nhật `dateTimeModified`. |
| **FR-SUB-04** | Xóa môn học an toàn | Khi xóa một môn học, hệ thống thực hiện trong một Transaction: xóa môn học, xóa toàn bộ tài liệu thuộc môn học đó, và ghi nhận đầy đủ bản ghi Tombstone vào bảng `DeleteLogs`. |
| **FR-SUB-05** | Xem chi tiết môn học | Mở màn hình riêng của môn học, hiển thị thông tin học phần, bộ lọc tài liệu theo loại, sắp xếp và toàn bộ tài liệu trực thuộc môn học đó. |

### 3.2. Phân hệ Quản lý Tài liệu Học tập (Document Management)
| Mã yêu cầu | Tên chức năng | Mô tả chi tiết |
|---|---|---|
| **FR-DOC-01** | Thêm tài liệu từ tệp cục bộ | Hỗ trợ chọn tệp từ bộ nhớ thiết bị với các định dạng: **PDF (.pdf)**, **Word (.doc, .docx)**, **PowerPoint (.ppt, .pptx)**. Hệ thống tự động sao chép tệp vào thư mục riêng của app (`studyhub_files`) để tránh mất tệp khi tệp gốc bị di chuyển. Tự động nhận diện dung lượng (`fileSize`), loại tài liệu và đề xuất tiêu đề. |
| **FR-DOC-02** | Thêm tài liệu liên kết web (URL) | Cho phép lưu liên kết web (Google Drive, Notion, bài viết trực tuyến, tài liệu tham khảo chính thức) vào môn học cụ thể. |
| **FR-DOC-03** | Chỉnh sửa thông tin tài liệu | Cho phép đổi tên tài liệu, chuyển đổi môn học liên kết, sửa ghi chú/mô tả và cập nhật URL nếu là dạng liên kết. |
| **FR-DOC-04** | Xóa tài liệu với cơ chế Tombstone | Xóa bản ghi tài liệu khỏi bảng `Documents` và tự động ghi một dòng vào bảng `DeleteLogs` (lưu `entryPk`, `type = DeleteLogType.document`, `dateTimeModified = now`) theo đúng kiến trúc Cashew. |
| **FR-DOC-05** | Hiển thị Metadata tài liệu | Hiển thị ngày thêm (dưới dạng tương đối như "Vừa xong", "5 phút trước", "Hôm qua" hoặc ngày giờ đầy đủ), loại tệp (PDF/Word/PPT/Link), dung lượng tệp (B/KB/MB/GB), môn học trực thuộc và ghi chú ngắn. |

### 3.3. Phân hệ Xem & Xuất Tài liệu (View & Export)
| Mã yêu cầu | Tên chức năng | Mô tả chi tiết |
|---|---|---|
| **FR-VIEW-01** | Xem PDF trực tiếp (In-app PDF Viewer) | Mở và đọc nội dung tài liệu PDF trực tiếp bên trong ứng dụng bằng trình xem chuyên dụng tích hợp `SfPdfViewer`, hỗ trợ cả tệp trên máy lẫn tệp PDF qua đường dẫn mạng. |
| **FR-VIEW-02** | Điều khiển thu phóng (Zoom & Navigation) | Cho phép phóng to, thu nhỏ tài liệu PDF mượt mà, cuộn liên tục giữa các trang mà không bị trễ khung hình. |
| **FR-VIEW-03** | Tải xuống / Xuất file (Download/Export) | Cho phép người dùng xuất tệp tài liệu từ ứng dụng ra thư mục người dùng tự chọn trên máy tính hoặc điện thoại thông qua hộp thoại lưu file hệ thống. |
| **FR-VIEW-04** | Mở liên kết ngoài (External Launcher) | Đối với tài liệu liên kết hoặc các định dạng Word/PPT, hỗ trợ một chạm mở trực tiếp trên trình duyệt hoặc ứng dụng chuyên dụng tương ứng của hệ điều hành. |

### 3.4. Phân hệ Tìm kiếm, Lọc & Sắp xếp (Search, Filter & Sort)
| Mã yêu cầu | Tên chức năng | Mô tả chi tiết |
|---|---|---|
| **FR-SRCH-01** | Tìm kiếm đa năng theo từ khóa | Tìm kiếm thời gian thực (real-time) theo tên tài liệu và nội dung ghi chú. |
| **FR-SRCH-02** | Lọc theo môn học | Cho phép chọn xem tài liệu của tất cả các môn hoặc chỉ định một môn học cụ thể. |
| **FR-SRCH-03** | Lọc theo loại tệp tin | Bộ lọc Chip cho phép lọc nhanh: Tất cả, PDF, Word, PowerPoint, Liên kết. |
| **FR-SRCH-04** | Sắp xếp linh hoạt | Sắp xếp tài liệu theo: Mới nhất trước, Cũ nhất trước, Tên tài liệu từ A → Z, Tên tài liệu từ Z → A. |

### 3.5. Phân hệ Tài liệu Quan trọng / Gắn sao (Favorites & Bookmarks)
| Mã yêu cầu | Tên chức năng | Mô tả chi tiết |
|---|---|---|
| **FR-FAV-01** | Đánh dấu sao một chạm | Chạm vào biểu tượng ngôi sao trên Card tài liệu để bật/tắt trạng thái `isPinned`. Giao diện cập nhật tức thì với màu vàng sao chuẩn Cashew (`starYellow = #FFB300`). |
| **FR-FAV-02** | Màn hình Tài liệu Quan trọng | Tab riêng biệt chuyên hiển thị toàn bộ tài liệu đã được gắn sao, hỗ trợ tìm kiếm riêng trong danh mục quan trọng. |

### 3.6. Phân hệ Bộ lọc Nâng cao (Advanced Filter)
| Mã yêu cầu | Tên chức năng | Mô tả chi tiết |
|---|---|---|
| **FR-FLT-01** | Hộp thoại Lọc Nâng cao gom cụm | Gom toàn bộ tiêu chí lọc rườm rà vào một nút "Lọc nâng cao". Hộp thoại hỗ trợ lọc đa chiều: Loại tài liệu (Bài giảng/Bài tập/Đề thi/Khác), Định dạng file (PDF, Word, PPT, Link), và Môn học liên kết. |
| **FR-FLT-02** | Cơ chế Áp dụng Hoãn lại (Deferred Apply) | Khi người dùng tương tác với các chip lọc trong hộp thoại, danh sách nền không bị lọc giật cục. Bộ lọc chỉ thực sự có hiệu lực khi người dùng nhấn nút "Áp dụng bộ lọc". Có nút "Đặt lại" để xóa nhanh mọi tiêu chí. |

### 3.7. Phân hệ Mượn - Trả Tài liệu Học tập (Borrow & Lending Management)
| Mã yêu cầu | Tên chức năng | Mô tả chi tiết |
|---|---|---|
| **FR-BRW-01** | Gửi yêu cầu mượn sách vật lý | Người dùng khám phá sách của bạn bè/cộng đồng, chọn thời hạn cần mượn, nhập ghi chú lời nhắn và gửi yêu cầu mượn trực tiếp lên Cloud Supabase. |
| **FR-BRW-02** | Quản lý Yêu cầu đã gửi | Xem danh sách các yêu cầu mượn mình đã gửi kèm trạng thái: Đang chờ duyệt, Đã chấp thuận, Đã từ chối, Đang mượn, Đã hoàn trả. Cho phép hủy yêu cầu khi chủ sách chưa duyệt; xem vị trí kệ sách khi đã được duyệt. |
| **FR-BRW-03** | Quản lý Yêu cầu nhận được (Dành cho chủ sách) | Chủ sở hữu sách nhận thông báo yêu cầu mượn, xem thông tin người mượn và thực hiện: Duyệt cho mượn (kèm ghi chú điểm hẹn), Từ chối cho mượn, hoặc Xác nhận đã nhận lại sách khi người mượn trả xong. |

### 3.8. Phân hệ Bản đồ Tài liệu & Kệ sách Vật lý (Bookshelf Map Explorer)
| Mã yêu cầu | Tên chức năng | Mô tả chi tiết |
|---|---|---|
| **FR-MAP-01** | Trực quan hóa điểm ghim sách trên Bản đồ | Sử dụng `flutter_map` và OpenStreetMap để hiển thị tọa độ GPS các cuốn sách giáo trình, tài liệu vật lý trong khuôn viên trường hoặc khu vực lân cận mà không phụ thuộc Google Maps API có phí. |
| **FR-MAP-02** | Phân quyền tương tác theo chủ sở hữu | Chạm vào một điểm ghim trên bản đồ: <br>- **Nếu là sách của chính mình:** Hiển thị nút "Xem thông tin sách" và tình trạng mượn hiện tại (chưa cho ai mượn / đang cho bạn mượn), không hiển thị nút "Yêu cầu mượn".<br>- **Nếu là sách của người khác:** Hiển thị nút "Yêu cầu mượn". |
| **FR-MAP-03** | Ghim vị trí ngăn kệ và địa chỉ cụ thể | Khi thêm hoặc sửa tài liệu vật lý, cho phép ghim trực tiếp vị trí ngăn/tủ/kệ sách (ví dụ: Tủ A3 - Tầng 2 Thư viện) và chọn tọa độ trên bản đồ qua hộp thoại tương tác. |

### 3.9. Phân hệ Gợi ý Học tập & Trung tâm Thông báo (Smart Engine & Notifications)
| Mã yêu cầu | Tên chức năng | Mô tả chi tiết |
|---|---|---|
| **FR-REC-01** | Top 10 gợi ý tài liệu thông minh | Động cơ đề xuất chạy cục bộ dựa trên độ tương đồng Jaccard giữa Tag sở thích của sinh viên và Tag tài liệu, kết hợp trọng số môn học quan tâm. Tự động loại trừ sách của chính người dùng khỏi danh sách gợi ý. |
| **FR-NTF-01** | Chuông thông báo & Trung tâm tin tức | Biểu tượng chuông trên AppBar với huy hiệu số lượng thông báo chưa đọc. Tự động phát hiện và thông báo: Yêu cầu mượn mới, Yêu cầu được chấp thuận/từ chối, Cảnh báo hạn trả sách. Chạm vào thông báo tự động điều hướng đúng phân hệ. |
| **FR-NTF-02** | Hồ sơ cá nhân & Đồng bộ Google | Avatar người dùng ở góc trên bên phải AppBar, hiển thị ảnh Google nếu đã đăng nhập hoặc icon mặc định nếu chưa đăng nhập. Hỗ trợ xem trạng thái đồng bộ và đăng xuất an toàn. |

---

## 4. YÊU CẦU PHI CHỨC NĂNG (NON-FUNCTIONAL REQUIREMENTS)
1. **Kiến trúc Local-First & Offline-First**: Ứng dụng hoạt động 100% không phụ thuộc Internet. Dữ liệu đọc/ghi tức thì từ SQLite nội bộ.
2. **Hiệu năng & MultiExecutor**: Áp dụng mô hình tách luồng của Cashew, các truy vấn ghi SQLite được đẩy vào Dart Background Isolate để giữ UI luôn đạt 60-120 FPS không giật lag.
3. **Reactive UI (No-Refresh)**: Mọi màn hình sử dụng `StreamBuilder` gắn với Drift Watch Streams (`watchFilteredDocuments()`, `watchAllSubjects()`). Khi thêm/sửa/xóa, giao diện tự động cập nhật mà không cần gọi `setState()` hay nạp lại dữ liệu thủ công.
4. **UI/UX Material 3 & Cashew Design Tokens**:
   - Tuân thủ bảng màu chuẩn truy xuất qua `getColor(context, token)`.
   - Bo góc thẻ chuẩn mực 20px, bo góc nút 16px, bo góc sheet 28px.
   - Hỗ trợ đầy đủ Dark Mode & Light Mode thích ứng mượt mà.
   - Thiết kế đáp ứng (Responsive Layout): NavigationBar trên di động, NavigationRail trên màn hình lớn/desktop.

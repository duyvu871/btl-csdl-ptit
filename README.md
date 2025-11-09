# Hệ thống Quản lý Cơ sở Dữ liệu - PTIT

Dự án cơ sở dữ liệu quản lý chương trình truyền hình, lịch phát sóng và quảng cáo sử dụng PostgreSQL.

## Yêu cầu hệ thống

- Docker
- Docker Compose

## Cấu trúc dự án

```
csdl-ptit/
├── docker-compose.yml    # Cấu hình Docker Compose
├── init.sql             # Script khởi tạo database
└── README.md            # File hướng dẫn này
```

## Cơ sở dữ liệu

### Schema chính

Database bao gồm các bảng quản lý:

- **nguoi**: Thông tin người tham gia (diễn viên, đạo diễn, biên tập viên...)
- **chuong_trinh**: Thông tin chương trình truyền hình
- **quang_cao**: Thông tin quảng cáo
- **khac**: Các chương trình khác (phim, show...)
- **tap**: Thông tin từng tập của chương trình
- **kenh**: Thông tin kênh truyền hình
- **lich_phat_song**: Lịch phát sóng các tập
- **lich_quang_cao**: Lịch phát quảng cáo
- **tham_gia**: Quan hệ giữa người và chương trình

### Các kiểu dữ liệu tùy chỉnh

- `gioi_tinh`: NAM, NU, KHAC
- `trang_thai`: NHAP, SAN_SANG, PHAT_SONG, TAM_DUNG, NGUNG
- `loai_ct`: QUANG_CAO, KHAC

## Hướng dẫn sử dụng

### 1. Khởi động dịch vụ

Chạy lệnh sau để khởi động PostgreSQL và pgAdmin:

```bash
docker compose up -d
```

Lần đầu tiên khởi động, file `init.sql` sẽ tự động chạy để tạo các bảng và kiểu dữ liệu.

### 2. Kiểm tra trạng thái

Xem trạng thái các container:

```bash
docker compose ps
```

Xem logs:

```bash
docker compose logs -f
```

### 3. Kết nối database

#### Thông tin kết nối

- **Host**: localhost
- **Port**: 5432
- **Database**: csdl_ptit
- **Username**: postgres
- **Password**: postgres

#### Kết nối qua psql (Terminal)

```bash
docker compose exec db psql -U postgres -d csdl_ptit
```

#### Kết nối qua pgAdmin (Giao diện web)

1. Mở trình duyệt và truy cập: http://localhost:8080
2. Đăng nhập với thông tin:
   - Email: admin@local
   - Password: admin
3. Thêm server mới:
   - Tên: CSDL PTIT (tùy chọn)
   - Host: db
   - Port: 5432
   - Database: csdl_ptit
   - Username: postgres
   - Password: postgres

### 4. Các lệnh thường dùng

#### Dừng dịch vụ

```bash
docker compose stop
```

#### Khởi động lại

```bash
docker compose start
```

#### Tắt và xóa container (giữ dữ liệu)

```bash
docker compose down
```

#### Tắt và xóa toàn bộ (bao gồm dữ liệu)

```bash
docker compose down -v
```

#### Khởi động lại database từ đầu

Lệnh này sẽ xóa toàn bộ dữ liệu và chạy lại `init.sql`:

```bash
docker compose down -v
docker compose up -d
```

#### Xem logs của một dịch vụ cụ thể

```bash
docker compose logs -f db        # Logs của PostgreSQL
docker compose logs -f pgadmin   # Logs của pgAdmin
```

### 5. Truy vấn mẫu

Sau khi kết nối vào database, bạn có thể thực hiện các truy vấn:

```sql
-- Xem danh sách các bảng
\dt

-- Xem cấu trúc bảng
\d nguoi
\d chuong_trinh

-- Thêm dữ liệu mẫu
INSERT INTO nguoi (ma_dinh_danh, ho_dem, ten_rieng, gioi_tinh, ngay_sinh, email)
VALUES ('NV001', 'Nguyen Van', 'A', 'NAM', '1990-01-01', 'nguyenvana@email.com');

-- Truy vấn dữ liệu
SELECT * FROM nguoi;
```

## Backup và Restore

### Backup database

```bash
docker compose exec db pg_dump -U postgres csdl_ptit > backup.sql
```

### Restore database

```bash
docker compose exec -T db psql -U postgres -d csdl_ptit < backup.sql
```

## Xử lý sự cố

### Không kết nối được database

1. Kiểm tra container đang chạy: `docker compose ps`
2. Xem logs lỗi: `docker compose logs db`
3. Thử khởi động lại: `docker compose restart db`

### Port 5432 hoặc 8080 đã được sử dụng

Sửa file `docker-compose.yml` để đổi port:

```yaml
ports:
  - "5433:5432"  # Đổi port PostgreSQL
  - "8081:80"    # Đổi port pgAdmin
```

### Muốn reset toàn bộ dữ liệu

```bash
docker compose down -v
docker compose up -d
```

## Ghi chú

- Dữ liệu được lưu trong Docker volumes (`db_data` và `pgadmin_data`) nên không bị mất khi tắt container
- File `init.sql` chỉ chạy khi database được tạo lần đầu (khi volume rỗng)
- Để chạy lại `init.sql`, cần xóa volume: `docker compose down -v`

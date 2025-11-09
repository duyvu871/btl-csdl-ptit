-- ================================
-- Tiện ích & ENUM/CHECK
-- ================================
CREATE TYPE gioi_tinh AS ENUM ('NAM', 'NU', 'KHAC');
CREATE TYPE trang_thai AS ENUM ('NHAP', 'SAN_SANG', 'PHAT_SONG', 'TAM_DUNG', 'NGUNG');
CREATE TYPE loai_ct AS ENUM ('QUANG_CAO', 'KHAC');

-- ================================
-- 1) Nguoi & thuộc tính đa trị
-- ================================
CREATE TABLE nguoi (
  ma_dinh_danh    VARCHAR(50) PRIMARY KEY,
  ho_dem          TEXT NOT NULL,
  ten_rieng       TEXT NOT NULL,
  gioi_tinh       gioi_tinh,
  ngay_sinh       DATE,
  -- tuoi dẫn xuất từ ngay_sinh (lấy phần năm của age)
  tuoi            INT GENERATED ALWAYS AS (EXTRACT(YEAR FROM age(current_date, ngay_sinh))::INT) STORED,
  email           TEXT UNIQUE,
  dia_chi         TEXT
);

-- Đa trị: số điện thoại (mỗi người có nhiều số)
CREATE TABLE nguoi_so_dien_thoai (
  ma_dinh_danh    VARCHAR(50) REFERENCES nguoi(ma_dinh_danh) ON DELETE CASCADE,
  so_dien_thoai   VARCHAR(20),
  PRIMARY KEY (ma_dinh_danh, so_dien_thoai)
);

-- ================================
-- 2) ChuongTrinh + thuộc tính đa trị + phân hệ con
-- ================================
CREATE TABLE chuong_trinh (
  ma_chuong_trinh     VARCHAR(50) PRIMARY KEY,
  nam_san_xuat        INT,
  do_tuoi_phu_hop     TEXT,
  mo_ta_noi_dung      TEXT,
  quoc_gia_san_xuat   TEXT,
  linh_vuc            TEXT,
  loai_chuong_trinh   loai_ct NOT NULL, -- phân biệt QUANG_CAO/KHAC
  trang_thai          trang_thai,
  thoi_luong          INT                -- phút (quảng cáo hoặc thời lượng mỗi tập)
);

-- Danh mục thể loại (tùy ý, có thể bỏ nếu không cần chuẩn hóa)
CREATE TABLE the_loai (
  the_loai_chuong_trinh TEXT PRIMARY KEY
);

-- Đa trị: 1 chương trình thuộc nhiều thể loại
CREATE TABLE chuong_trinh_the_loai (
  ma_chuong_trinh       VARCHAR(50) REFERENCES chuong_trinh(ma_chuong_trinh) ON DELETE CASCADE,
  the_loai_chuong_trinh TEXT        REFERENCES the_loai(the_loai_chuong_trinh) ON DELETE RESTRICT,
  PRIMARY KEY (ma_chuong_trinh, the_loai_chuong_trinh)
);

-- Thực thể con: Quảng cáo (PK=FK tới chuong_trinh)
CREATE TABLE quang_cao (
  ma_chuong_trinh   VARCHAR(50) PRIMARY KEY
                    REFERENCES chuong_trinh(ma_chuong_trinh) ON DELETE CASCADE,
  ten_quang_cao     TEXT NOT NULL,
  hopdong_ngay_batdau DATE,
  hopdong_ngay_ketthuc DATE,
  -- đảm bảo loại ở bảng cha khớp
  CONSTRAINT quang_cao_loai_chk CHECK (
    (SELECT loai_chuong_trinh FROM chuong_trinh WHERE chuong_trinh.ma_chuong_trinh = quang_cao.ma_chuong_trinh) = 'QUANG_CAO'
  )
);

-- Thực thể con: Chương trình khác (PK=FK tới chuong_trinh)
CREATE TABLE khac (
  ma_chuong_trinh   VARCHAR(50) PRIMARY KEY
                    REFERENCES chuong_trinh(ma_chuong_trinh) ON DELETE CASCADE,
  ten_chuong_trinh  TEXT NOT NULL,
  tong_so_tap       INT CHECK (tong_so_tap IS NULL OR tong_so_tap >= 0),
  CONSTRAINT khac_loai_chk CHECK (
    (SELECT loai_chuong_trinh FROM chuong_trinh WHERE chuong_trinh.ma_chuong_trinh = khac.ma_chuong_trinh) = 'KHAC'
  )
);

-- ================================
-- 3) Kenh
-- ================================
CREATE TABLE kenh (
  ma_kenh    VARCHAR(50) PRIMARY KEY,
  ten_kenh   TEXT NOT NULL,
  mo_ta_kenh TEXT,
  the_loai_kenh TEXT
);

-- ================================
-- 4) Tap (tập của "Khac")
--     PK kép: (ma_chuong_trinh, so_tap)
-- ================================
CREATE TABLE tap (
  ma_chuong_trinh  VARCHAR(50) REFERENCES khac(ma_chuong_trinh) ON DELETE CASCADE,
  so_tap           INT NOT NULL CHECK (so_tap > 0),
  tieu_de          TEXT,
  trang_thai       trang_thai,
  PRIMARY KEY (ma_chuong_trinh, so_tap)
);

-- ================================
-- 5) Tham gia (Nguoi <-> ChuongTrinh) n–m
--     Thuộc tính: vaiTro; thoiGian là đa trị (ngayBatDau, ngayKetThuc)
-- ================================
-- Bản ghi vai trò (một người có thể nhiều vai trò trên cùng CT)
CREATE TABLE tham_gia (
  ma_dinh_danh      VARCHAR(50) REFERENCES nguoi(ma_dinh_danh) ON DELETE CASCADE,
  ma_chuong_trinh   VARCHAR(50) REFERENCES chuong_trinh(ma_chuong_trinh) ON DELETE CASCADE,
  vai_tro           TEXT NOT NULL,
  PRIMARY KEY (ma_dinh_danh, ma_chuong_trinh, vai_tro)
);

-- Khoảng thời gian (đa trị) cho từng vai trò
CREATE TABLE tham_gia_thoi_gian (
  ma_dinh_danh      VARCHAR(50),
  ma_chuong_trinh   VARCHAR(50),
  vai_tro           TEXT,
  ngay_bat_dau      DATE NOT NULL,
  ngay_ket_thuc     DATE,
  PRIMARY KEY (ma_dinh_danh, ma_chuong_trinh, vai_tro, ngay_bat_dau),
  FOREIGN KEY (ma_dinh_danh, ma_chuong_trinh, vai_tro)
    REFERENCES tham_gia(ma_dinh_danh, ma_chuong_trinh, vai_tro)
    ON DELETE CASCADE,
  CHECK (ngay_ket_thuc IS NULL OR ngay_ket_thuc >= ngay_bat_dau)
);

-- ================================
-- 6) LichPhatSong (thực thể yếu)
--     PK theo mô tả: (nam, thang, ngay, gio, phut, ma_kenh, ma_chuong_trinh, so_tap)
--     1–n Kenh–Lich, 1–1 Lich–Tap
-- ================================
CREATE TABLE lich_phat_song (
  nam              INT NOT NULL CHECK (nam BETWEEN 1900 AND 3000),
  thang            INT NOT NULL CHECK (thang BETWEEN 1 AND 12),
  ngay             INT NOT NULL CHECK (ngay BETWEEN 1 AND 31),
  gio              INT NOT NULL CHECK (gio BETWEEN 0 AND 23),
  phut             INT NOT NULL CHECK (phut BETWEEN 0 AND 59),

  ma_kenh          VARCHAR(50) NOT NULL REFERENCES kenh(ma_kenh) ON DELETE CASCADE,
  ma_chuong_trinh  VARCHAR(50) NOT NULL,
  so_tap           INT NOT NULL,

  -- Ràng buộc tới tap (chỉ áp dụng với CT loại KHAC)
  FOREIGN KEY (ma_chuong_trinh, so_tap)
    REFERENCES tap(ma_chuong_trinh, so_tap)
    ON DELETE CASCADE,

  -- Khóa chính tổng hợp theo yêu cầu
  PRIMARY KEY (nam, thang, ngay, gio, phut, ma_kenh, ma_chuong_trinh, so_tap),

  -- 1–1 Lich <-> Tap: một tập chỉ có thể xuất hiện ở tối đa 1 lịch
  CONSTRAINT uniq_lich_moi_tap UNIQUE (ma_chuong_trinh, so_tap)
);

-- Chỉ mục phụ trợ tìm kiếm theo thời điểm & kênh
CREATE INDEX idx_lich_time_kenh
  ON lich_phat_song (nam, thang, ngay, gio, phut, ma_kenh);

-- ================================
-- 7) Lich <-> QuangCao (n–m) với thứ tự phát
-- ================================
CREATE TABLE lich_quang_cao (
  nam              INT,
  thang            INT,
  ngay             INT,
  gio              INT,
  phut             INT,
  ma_kenh          VARCHAR(50),
  ma_chuong_trinh_tap VARCHAR(50), -- để phân biệt với quảng cáo (tên hơi dài để rõ nghĩa)
  so_tap           INT,

  -- quảng cáo:
  ma_quang_cao     VARCHAR(50) REFERENCES quang_cao(ma_chuong_trinh) ON DELETE CASCADE,

  thu_tu           INT NOT NULL CHECK (thu_tu > 0),

  PRIMARY KEY (nam, thang, ngay, gio, phut, ma_kenh, ma_chuong_trinh_tap, so_tap, ma_quang_cao),

  FOREIGN KEY (nam, thang, ngay, gio, phut, ma_kenh, ma_chuong_trinh_tap, so_tap)
    REFERENCES lich_phat_song(nam, thang, ngay, gio, phut, ma_kenh, ma_chuong_trinh, so_tap)
    ON DELETE CASCADE
);

-- (Tùy chọn) đảm bảo thứ tự phát trong cùng một lịch là duy nhất
CREATE UNIQUE INDEX uniq_thu_tu_trong_lich
  ON lich_quang_cao (nam, thang, ngay, gio, phut, ma_kenh, ma_chuong_trinh_tap, so_tap, thu_tu);

-- ===========================================
-- ENUM / CHECK Types
-- ===========================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'gioi_tinh') THEN
        CREATE TYPE gioi_tinh AS ENUM ('NAM', 'NU', 'KHAC');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'trang_thai') THEN
        CREATE TYPE trang_thai AS ENUM ('NHAP', 'SAN_SANG', 'PHAT_SONG', 'TAM_DUNG', 'NGUNG');
    END IF;
END$$;

-- ===========================================
-- 1) Nguoi & số điện thoại (đa trị)
-- ===========================================
CREATE TABLE IF NOT EXISTS nguoi (
    ma_dinh_danh VARCHAR(50) PRIMARY KEY,
    ho TEXT NOT NULL,
    ten_dem TEXT NOT NULL,
    ten_rieng TEXT NOT NULL,
    gioi_tinh gioi_tinh,
    ngay_sinh DATE,
    tuoi INT,
    email TEXT UNIQUE,
    dia_chi TEXT
);

CREATE TABLE IF NOT EXISTS nguoi_so_dien_thoai (
    ma_dinh_danh VARCHAR(50) REFERENCES nguoi(ma_dinh_danh) ON DELETE CASCADE,
    so_dien_thoai VARCHAR(20),
    PRIMARY KEY (ma_dinh_danh, so_dien_thoai)
);

-- ===========================================
-- 2) Chương trình + Thể loại + Quảng cáo
-- ===========================================
CREATE TABLE IF NOT EXISTS chuong_trinh (
    ma_chuong_trinh VARCHAR(50) PRIMARY KEY,
    nam_san_xuat INT CHECK (nam_san_xuat >= 1900),
    do_tuoi_phu_hop TEXT,
    linh_vuc TEXT,
    mo_ta_noi_dung TEXT,
    quoc_gia_san_xuat TEXT,
    trang_thai trang_thai,
    ten_chuong_trinh TEXT NOT NULL,
    tong_so_tap INT CHECK (tong_so_tap IS NULL OR tong_so_tap > 0)
);

CREATE TABLE IF NOT EXISTS the_loai_chuong_trinh (
    the_loai_chuong_trinh TEXT PRIMARY KEY
);

CREATE TABLE IF NOT EXISTS chuong_trinh_the_loai (
    ma_chuong_trinh VARCHAR(50) REFERENCES chuong_trinh(ma_chuong_trinh) ON DELETE CASCADE,
    the_loai_chuong_trinh TEXT REFERENCES the_loai_chuong_trinh(the_loai_chuong_trinh) ON DELETE CASCADE,
    PRIMARY KEY (ma_chuong_trinh, the_loai_chuong_trinh)
);

CREATE TABLE IF NOT EXISTS quang_cao (
    ma_hop_dong VARCHAR(50) PRIMARY KEY,
    ten_thuong_hieu TEXT NOT NULL,
    thoi_luong INT CHECK (thoi_luong IS NULL OR thoi_luong > 0),
    noi_dung TEXT,
    ngay_bat_dau DATE,
    ngay_ket_thuc DATE,
    CHECK (ngay_ket_thuc IS NULL OR ngay_bat_dau < ngay_ket_thuc)
);

-- ===========================================
-- 3) Kênh + Thể loại kênh
-- ===========================================
CREATE TABLE IF NOT EXISTS kenh (
    ma_kenh VARCHAR(50) PRIMARY KEY,
    ten_kenh TEXT NOT NULL,
    mo_ta_kenh TEXT
);

CREATE TABLE IF NOT EXISTS the_loai_kenh (
    the_loai_kenh TEXT PRIMARY KEY
);

CREATE TABLE IF NOT EXISTS kenh_the_loai (
    ma_kenh VARCHAR(50) REFERENCES kenh(ma_kenh) ON DELETE CASCADE,
    the_loai_kenh TEXT REFERENCES the_loai_kenh(the_loai_kenh) ON DELETE CASCADE,
    PRIMARY KEY (ma_kenh, the_loai_kenh)
);

-- ===========================================
-- 4) Tập (Episodes)
-- ===========================================
CREATE TABLE IF NOT EXISTS tap (
    ma_chuong_trinh VARCHAR(50) REFERENCES chuong_trinh(ma_chuong_trinh) ON DELETE CASCADE,
    so_tap INT NOT NULL CHECK (so_tap > 0),
    tieu_de TEXT,
    trang_thai trang_thai,
    PRIMARY KEY (ma_chuong_trinh, so_tap)
);

-- ===========================================
-- 5) Tham gia
-- ===========================================
CREATE TABLE IF NOT EXISTS tham_gia (
    ma_dinh_danh VARCHAR(50) REFERENCES nguoi(ma_dinh_danh) ON DELETE CASCADE,
    ma_chuong_trinh VARCHAR(50) REFERENCES chuong_trinh(ma_chuong_trinh) ON DELETE CASCADE,
    vai_tro TEXT NOT NULL,
    ngay_bat_dau DATE,
    ngay_ket_thuc DATE,
    CHECK (ngay_ket_thuc IS NULL OR ngay_bat_dau < ngay_ket_thuc),
    PRIMARY KEY (ma_dinh_danh, ma_chuong_trinh, vai_tro)
);

-- ===========================================
-- 6) Lịch phát sóng
-- ===========================================
CREATE TABLE IF NOT EXISTS lich_phat_song (
    ma_lich_phat_song VARCHAR(50) PRIMARY KEY,
    ma_kenh VARCHAR(50) REFERENCES kenh(ma_kenh) ON DELETE CASCADE,
    nam INT NOT NULL CHECK (nam BETWEEN 1900 AND 3000),
    thang INT NOT NULL CHECK (thang BETWEEN 1 AND 12),
    ngay INT NOT NULL CHECK (ngay BETWEEN 1 AND 31),
    gio INT NOT NULL CHECK (gio BETWEEN 0 AND 23),
    phut INT NOT NULL CHECK (phut BETWEEN 0 AND 59),
    ma_chuong_trinh VARCHAR(50) NOT NULL,
    so_tap INT NOT NULL,
    FOREIGN KEY (ma_chuong_trinh, so_tap)
        REFERENCES tap(ma_chuong_trinh, so_tap) ON DELETE CASCADE,
    CONSTRAINT uniq_kenh_thoi_gian UNIQUE (ma_kenh, nam, thang, ngay, gio, phut)
);

CREATE INDEX IF NOT EXISTS idx_lich_phat_song_kenh
    ON lich_phat_song (ma_kenh, nam, thang, ngay, gio, phut);

-- ===========================================
-- 7) Lịch phát sóng - Quảng cáo
-- ===========================================
CREATE TABLE IF NOT EXISTS lich_phat_song_quang_cao (
    ma_lich_phat_song VARCHAR(50) REFERENCES lich_phat_song(ma_lich_phat_song) ON DELETE CASCADE,
    ma_hop_dong VARCHAR(50) REFERENCES quang_cao(ma_hop_dong) ON DELETE CASCADE,
    thu_tu INT NOT NULL CHECK (thu_tu > 0),
    thoi_diem_chen_quang_cao INTERVAL NOT NULL CHECK (thoi_diem_chen_quang_cao >= INTERVAL '0 second'),
    PRIMARY KEY (ma_lich_phat_song, thu_tu)
);
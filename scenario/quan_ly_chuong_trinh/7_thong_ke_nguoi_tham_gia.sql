-- ===========================================
-- THỐNG KÊ DANH SÁCH NGƯỜI THAM GIA THEO CHƯƠNG TRÌNH
-- ===========================================

-- 1. Danh sách người tham gia chi tiết theo từng chương trình
SELECT 
    ct.ma_chuong_trinh,
    ct.ten_chuong_trinh,
    ct.trang_thai AS trang_thai_chuong_trinh,
    n.ma_dinh_danh,
    CONCAT(n.ho, ' ', n.ten_dem, ' ', n.ten_rieng) AS ho_ten_day_du,
    n.gioi_tinh,
    n.tuoi,
    n.email,
    tg.vai_tro,
    tg.ngay_bat_dau,
    tg.ngay_ket_thuc,
    CASE 
        WHEN tg.ngay_ket_thuc IS NULL THEN 'Đang tham gia'
        WHEN tg.ngay_ket_thuc > CURRENT_DATE THEN 'Đang tham gia'
        ELSE 'Đã kết thúc'
    END AS trang_thai_tham_gia,
    CASE 
        WHEN tg.ngay_ket_thuc IS NULL THEN 
            CURRENT_DATE - tg.ngay_bat_dau
        ELSE 
            tg.ngay_ket_thuc - tg.ngay_bat_dau
    END AS so_ngay_tham_gia
FROM chuong_trinh ct
JOIN tham_gia tg ON ct.ma_chuong_trinh = tg.ma_chuong_trinh
JOIN nguoi n ON tg.ma_dinh_danh = n.ma_dinh_danh
ORDER BY ct.ten_chuong_trinh, tg.vai_tro, n.ho, n.ten_dem, n.ten_rieng;

-- ===========================================
-- 2. THỐNG KÊ TỔNG QUAN THEO CHƯƠNG TRÌNH
-- ===========================================

-- Số lượng người tham gia theo từng chương trình
SELECT 
    ct.ma_chuong_trinh,
    ct.ten_chuong_trinh,
    ct.trang_thai,
    COUNT(DISTINCT tg.ma_dinh_danh) AS tong_so_nguoi_tham_gia,
    COUNT(tg.vai_tro) AS tong_so_vai_tro,
    COUNT(DISTINCT tg.vai_tro) AS so_loai_vai_tro,
    COUNT(CASE WHEN n.gioi_tinh = 'NAM' THEN 1 END) AS so_nam,
    COUNT(CASE WHEN n.gioi_tinh = 'NU' THEN 1 END) AS so_nu,
    COUNT(CASE WHEN n.gioi_tinh = 'KHAC' THEN 1 END) AS so_khac,
    ROUND(AVG(n.tuoi), 1) AS tuoi_trung_binh,
    MIN(n.tuoi) AS tuoi_nho_nhat,
    MAX(n.tuoi) AS tuoi_lon_nhat
FROM chuong_trinh ct
LEFT JOIN tham_gia tg ON ct.ma_chuong_trinh = tg.ma_chuong_trinh
LEFT JOIN nguoi n ON tg.ma_dinh_danh = n.ma_dinh_danh
GROUP BY ct.ma_chuong_trinh, ct.ten_chuong_trinh, ct.trang_thai
ORDER BY tong_so_nguoi_tham_gia DESC;

-- ===========================================
-- 3. THỐNG KÊ THEO VAI TRÒ
-- ===========================================

-- Phân tích vai trò trong từng chương trình
SELECT 
    ct.ma_chuong_trinh,
    ct.ten_chuong_trinh,
    tg.vai_tro,
    COUNT(*) AS so_nguoi,
    STRING_AGG(
        CONCAT(n.ho, ' ', n.ten_dem, ' ', n.ten_rieng), 
        ', ' ORDER BY n.ho, n.ten_dem, n.ten_rieng
    ) AS danh_sach_nguoi,
    COUNT(CASE WHEN n.gioi_tinh = 'NAM' THEN 1 END) AS nam,
    COUNT(CASE WHEN n.gioi_tinh = 'NU' THEN 1 END) AS nu,
    ROUND(AVG(n.tuoi), 1) AS tuoi_tb_vai_tro
FROM chuong_trinh ct
JOIN tham_gia tg ON ct.ma_chuong_trinh = tg.ma_chuong_trinh
JOIN nguoi n ON tg.ma_dinh_danh = n.ma_dinh_danh
GROUP BY ct.ma_chuong_trinh, ct.ten_chuong_trinh, tg.vai_tro
ORDER BY ct.ten_chuong_trinh, tg.vai_tro;

-- ===========================================
-- 4. TÌM CHƯƠNG TRÌNH THEO SỐ NGƯỜI THAM GIA
-- ===========================================

-- Chương trình có nhiều người tham gia nhất
SELECT
    ct.ma_chuong_trinh,
    ct.ten_chuong_trinh,
    COUNT(DISTINCT tg.ma_dinh_danh) AS so_nguoi_tham_gia,
    STRING_AGG(DISTINCT tg.vai_tro, ', ') AS cac_vai_tro
FROM chuong_trinh ct
JOIN tham_gia tg ON ct.ma_chuong_trinh = tg.ma_chuong_trinh
GROUP BY ct.ma_chuong_trinh, ct.ten_chuong_trinh
ORDER BY so_nguoi_tham_gia DESC
LIMIT 5;

-- Chương trình chưa có người tham gia
SELECT 
    'Chưa có người tham gia' AS loai,
    ct.ma_chuong_trinh,
    ct.ten_chuong_trinh,
    0 AS so_nguoi_tham_gia,
    'Không có' AS cac_vai_tro
FROM chuong_trinh ct
LEFT JOIN tham_gia tg ON ct.ma_chuong_trinh = tg.ma_chuong_trinh
WHERE tg.ma_chuong_trinh IS NULL
ORDER BY loai, so_nguoi_tham_gia DESC;

-- ===========================================
-- 5. THỐNG KÊ NGƯỜI THAM GIA ĐANG HOẠT ĐỘNG
-- ===========================================

-- Người đang tham gia (chưa kết thúc)
SELECT 
    ct.ma_chuong_trinh,
    ct.ten_chuong_trinh,
    COUNT(CASE 
        WHEN (tg.ngay_ket_thuc IS NULL OR tg.ngay_ket_thuc > CURRENT_DATE)
        THEN 1 
    END) AS dang_tham_gia,
    COUNT(CASE 
        WHEN tg.ngay_ket_thuc IS NOT NULL AND tg.ngay_ket_thuc <= CURRENT_DATE
        THEN 1 
    END) AS da_ket_thuc,
    COUNT(*) AS tong_cong,
    ROUND(
        COUNT(CASE WHEN (tg.ngay_ket_thuc IS NULL OR tg.ngay_ket_thuc > CURRENT_DATE) THEN 1 END) * 100.0 / COUNT(*), 
        1
    ) AS ty_le_dang_hoat_dong
FROM chuong_trinh ct
LEFT JOIN tham_gia tg ON ct.ma_chuong_trinh = tg.ma_chuong_trinh
WHERE tg.ma_chuong_trinh IS NOT NULL
GROUP BY ct.ma_chuong_trinh, ct.ten_chuong_trinh
ORDER BY ty_le_dang_hoat_dong DESC, dang_tham_gia DESC;

-- ===========================================
-- 6. THỐNG KÊ CHI TIẾT THEO CHƯƠNG TRÌNH CỤ THỂ
-- ===========================================

-- Chi tiết một chương trình cụ thể (ví dụ: CT001)
SELECT 
    'THÔNG TIN CHUNG' AS phan,
    '' AS ma_dinh_danh,
    ct.ten_chuong_trinh AS thong_tin,
    ct.trang_thai AS chi_tiet,
    NULL AS vai_tro,
    NULL::DATE AS ngay_bat_dau,
    NULL::DATE AS ngay_ket_thuc
FROM chuong_trinh ct
WHERE ct.ma_chuong_trinh = 'CT001'

UNION ALL

SELECT 
    'NGƯỜI THAM GIA' AS phan,
    n.ma_dinh_danh,
    CONCAT(n.ho, ' ', n.ten_dem, ' ', n.ten_rieng) AS thong_tin,
    CONCAT(n.gioi_tinh, ' - ', n.tuoi, ' tuổi') AS chi_tiet,
    tg.vai_tro,
    tg.ngay_bat_dau,
    tg.ngay_ket_thuc
FROM chuong_trinh ct
JOIN tham_gia tg ON ct.ma_chuong_trinh = tg.ma_chuong_trinh
JOIN nguoi n ON tg.ma_dinh_danh = n.ma_dinh_danh
WHERE ct.ma_chuong_trinh = 'CT001'

ORDER BY phan DESC, vai_tro, thong_tin;

-- ===========================================
-- 7. BÁO CÁO TỔNG HỢP HỆ THỐNG
-- ===========================================

-- Báo cáo tổng quan toàn hệ thống
SELECT 
    'Tổng số chương trình' AS chi_tieu,
    COUNT(DISTINCT ct.ma_chuong_trinh)::TEXT AS gia_tri
FROM chuong_trinh ct
UNION ALL
SELECT 
    'Chương trình có người tham gia',
    COUNT(DISTINCT ct.ma_chuong_trinh)::TEXT
FROM chuong_trinh ct
JOIN tham_gia tg ON ct.ma_chuong_trinh = tg.ma_chuong_trinh
UNION ALL
SELECT 
    'Tổng số người tham gia',
    COUNT(DISTINCT tg.ma_dinh_danh)::TEXT
FROM tham_gia tg
UNION ALL
SELECT 
    'Tổng số vai trò',
    COUNT(*)::TEXT
FROM tham_gia tg
UNION ALL
SELECT 
    'Số vai trò khác nhau',
    COUNT(DISTINCT vai_tro)::TEXT
FROM tham_gia
UNION ALL
SELECT 
    'Người đang tham gia',
    COUNT(*)::TEXT
FROM tham_gia
WHERE ngay_ket_thuc IS NULL OR ngay_ket_thuc > CURRENT_DATE;
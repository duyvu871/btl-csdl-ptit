-- ===========================================
-- THEO DÕI DANH SÁCH CHƯƠNG TRÌNH PHÁT TRÊN TỪNG KÊNH
-- ===========================================

-- 1. Danh sách chương trình đang phát trên tất cả các kênh
SELECT 
    k.ma_kenh,
    k.ten_kenh,
    ct.ma_chuong_trinh,
    ct.ten_chuong_trinh,
    ct.trang_thai AS trang_thai_chuong_trinh,
    lps.so_tap,
    t.tieu_de AS tieu_de_tap,
    lps.thoi_gian_bat_dau,
    lps.thoi_gian_ket_thuc,
    EXTRACT(EPOCH FROM (lps.thoi_gian_ket_thuc - lps.thoi_gian_bat_dau))/60 AS thoi_luong_phut,
    CASE 
        WHEN lps.thoi_gian_bat_dau > CURRENT_TIMESTAMP THEN 'Sắp phát'
        WHEN lps.thoi_gian_bat_dau <= CURRENT_TIMESTAMP 
         AND lps.thoi_gian_ket_thuc >= CURRENT_TIMESTAMP THEN 'Đang phát'
        ELSE 'Đã phát'
    END AS trang_thai_phat_song
FROM kenh k
JOIN lich_phat_song lps ON k.ma_kenh = lps.ma_kenh
JOIN chuong_trinh ct ON lps.ma_chuong_trinh = ct.ma_chuong_trinh
LEFT JOIN tap t ON lps.ma_chuong_trinh = t.ma_chuong_trinh AND lps.so_tap = t.so_tap
ORDER BY k.ten_kenh, lps.thoi_gian_bat_dau;

-- ===========================================
-- 2. THỐNG KÊ CHƯƠNG TRÌNH THEO TỪNG KÊNH
-- ===========================================

-- Tổng quan chương trình trên mỗi kênh
SELECT 
    k.ma_kenh,
    k.ten_kenh,
    COUNT(DISTINCT lps.ma_chuong_trinh) AS so_chuong_trinh_khac_nhau,
    COUNT(lps.ma_lich_phat_song) AS tong_so_lich_phat,
    COUNT(CASE 
        WHEN lps.thoi_gian_bat_dau > CURRENT_TIMESTAMP 
        THEN 1 
    END) AS lich_sap_phat,
    COUNT(CASE 
        WHEN lps.thoi_gian_bat_dau <= CURRENT_TIMESTAMP 
         AND lps.thoi_gian_ket_thuc >= CURRENT_TIMESTAMP 
        THEN 1 
    END) AS lich_dang_phat,
    COUNT(CASE 
        WHEN lps.thoi_gian_ket_thuc < CURRENT_TIMESTAMP 
        THEN 1 
    END) AS lich_da_phat,
    ROUND(
        SUM(EXTRACT(EPOCH FROM (lps.thoi_gian_ket_thuc - lps.thoi_gian_bat_dau)))/3600, 
        2
    ) AS tong_gio_phat_song
FROM kenh k
LEFT JOIN lich_phat_song lps ON k.ma_kenh = lps.ma_kenh
GROUP BY k.ma_kenh, k.ten_kenh
ORDER BY tong_so_lich_phat DESC;

-- ===========================================
-- 3. LỊCH PHÁT THEO KÊNH CHO HÔM NAY
-- ===========================================

-- Lịch phát sóng hôm nay của từng kênh
SELECT 
    k.ma_kenh,
    k.ten_kenh,
    TO_CHAR(lps.thoi_gian_bat_dau, 'HH24:MI') AS gio_bat_dau,
    TO_CHAR(lps.thoi_gian_ket_thuc, 'HH24:MI') AS gio_ket_thuc,
    ct.ten_chuong_trinh,
    CASE 
        WHEN lps.so_tap = 1 AND ct.tong_so_tap = 1 THEN 'Tập duy nhất'
        ELSE CONCAT('Tập ', lps.so_tap, '/', COALESCE(ct.tong_so_tap::TEXT, '?'))
    END AS thong_tin_tap,
    t.tieu_de AS tieu_de_tap,
    EXTRACT(EPOCH FROM (lps.thoi_gian_ket_thuc - lps.thoi_gian_bat_dau))/60 AS thoi_luong_phut,
    CASE 
        WHEN lps.thoi_gian_bat_dau > CURRENT_TIMESTAMP THEN '⏰ Sắp phát'
        WHEN lps.thoi_gian_bat_dau <= CURRENT_TIMESTAMP 
         AND lps.thoi_gian_ket_thuc >= CURRENT_TIMESTAMP THEN '🔴 Đang phát'
        ELSE '✅ Đã phát'
    END AS trang_thai
FROM kenh k
JOIN lich_phat_song lps ON k.ma_kenh = lps.ma_kenh
JOIN chuong_trinh ct ON lps.ma_chuong_trinh = ct.ma_chuong_trinh
LEFT JOIN tap t ON lps.ma_chuong_trinh = t.ma_chuong_trinh AND lps.so_tap = t.so_tap
WHERE DATE(lps.thoi_gian_bat_dau) = CURRENT_DATE
ORDER BY k.ten_kenh, lps.thoi_gian_bat_dau;

-- ===========================================
-- 4. CHƯƠNG TRÌNH PHỔ BIẾN NHẤT TRÊN CÁC KÊNH
-- ===========================================

-- Top chương trình được phát nhiều nhất
SELECT 
    ct.ma_chuong_trinh,
    COUNT(DISTINCT lps.ma_kenh) AS so_kenh_phat,
    COUNT(lps.ma_lich_phat_song) AS so_lan_phat,
    STRING_AGG(DISTINCT k.ten_kenh, ', ' ORDER BY k.ten_kenh) AS cac_kenh_phat,
    MIN(lps.thoi_gian_bat_dau) AS lan_dau_phat,
    MAX(lps.thoi_gian_ket_thuc) AS lan_cuoi_phat,
    ROUND(
        AVG(EXTRACT(EPOCH FROM (lps.thoi_gian_ket_thuc - lps.thoi_gian_bat_dau)))/60, 
        1
    ) AS thoi_luong_trung_binh_phut
FROM chuong_trinh ct
JOIN lich_phat_song lps ON ct.ma_chuong_trinh = lps.ma_chuong_trinh
JOIN kenh k ON lps.ma_kenh = k.ma_kenh
GROUP BY ct.ma_chuong_trinh, ct.ten_chuong_trinh
ORDER BY so_lan_phat DESC, so_kenh_phat DESC
LIMIT 10;

-- ===========================================
-- 5. KÊNH VÀ CHƯƠNG TRÌNH ĐANG PHÁT HIỆN TẠI
-- ===========================================

-- Xem kênh nào đang phát chương trình gì ngay bây giờ
SELECT 
    k.ma_kenh,
    k.ten_kenh,
    ct.ten_chuong_trinh,
    CONCAT('Tập ', lps.so_tap) AS tap_dang_phat,
    t.tieu_de AS tieu_de_tap,
    TO_CHAR(lps.thoi_gian_bat_dau, 'DD/MM/YYYY HH24:MI') AS bat_dau,
    TO_CHAR(lps.thoi_gian_ket_thuc, 'DD/MM/YYYY HH24:MI') AS ket_thuc,
    ROUND(
        EXTRACT(EPOCH FROM (lps.thoi_gian_ket_thuc - CURRENT_TIMESTAMP))/60,
        0
    ) AS con_lai_phut,
    ROUND(
        EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - lps.thoi_gian_bat_dau))/
        EXTRACT(EPOCH FROM (lps.thoi_gian_ket_thuc - lps.thoi_gian_bat_dau)) * 100,
        1
    ) AS phan_tram_da_phat
FROM kenh k
JOIN lich_phat_song lps ON k.ma_kenh = lps.ma_kenh
JOIN chuong_trinh ct ON lps.ma_chuong_trinh = ct.ma_chuong_trinh
LEFT JOIN tap t ON lps.ma_chuong_trinh = t.ma_chuong_trinh AND lps.so_tap = t.so_tap
WHERE lps.thoi_gian_bat_dau <= CURRENT_TIMESTAMP 
  AND lps.thoi_gian_ket_thuc >= CURRENT_TIMESTAMP
ORDER BY k.ten_kenh;

-- ===========================================
-- 6. LỊCH PHÁT TUẦN TỚI THEO KÊNH
-- ===========================================

-- Xem lịch phát 7 ngày tới của từng kênh
SELECT 
    k.ma_kenh,
    k.ten_kenh,
    DATE(lps.thoi_gian_bat_dau) AS ngay_phat,
    TO_CHAR(lps.thoi_gian_bat_dau, 'Day') AS thu_trong_tuan,
    COUNT(*) AS so_chuong_trinh_trong_ngay,
    STRING_AGG(
        CONCAT(
            TO_CHAR(lps.thoi_gian_bat_dau, 'HH24:MI'), 
            ' - ', 
            ct.ten_chuong_trinh,
            ' (T', lps.so_tap, ')'
        ), 
        '; ' 
        ORDER BY lps.thoi_gian_bat_dau
    ) AS lich_phat_chi_tiet
FROM kenh k
JOIN lich_phat_song lps ON k.ma_kenh = lps.ma_kenh
JOIN chuong_trinh ct ON lps.ma_chuong_trinh = ct.ma_chuong_trinh
WHERE lps.thoi_gian_bat_dau >= CURRENT_TIMESTAMP
  AND lps.thoi_gian_bat_dau < CURRENT_TIMESTAMP + INTERVAL '7 days'
GROUP BY k.ma_kenh, k.ten_kenh, DATE(lps.thoi_gian_bat_dau), TO_CHAR(lps.thoi_gian_bat_dau, 'Day')
ORDER BY k.ten_kenh, DATE(lps.thoi_gian_bat_dau);

-- ===========================================
-- 7. THỐNG KÊ THEO THỂ LOẠI KÊNH
-- ===========================================

-- Phân tích chương trình theo thể loại kênh
SELECT 
    ktl.the_loai_kenh,
    COUNT(DISTINCT k.ma_kenh) AS so_kenh,
    STRING_AGG(DISTINCT k.ten_kenh, ', ') AS cac_kenh,
    COUNT(DISTINCT lps.ma_chuong_trinh) AS so_chuong_trinh_phat,
    COUNT(lps.ma_lich_phat_song) AS tong_lich_phat,
    ROUND(
        AVG(EXTRACT(EPOCH FROM (lps.thoi_gian_ket_thuc - lps.thoi_gian_bat_dau)))/60,
        1
    ) AS thoi_luong_tb_phut
FROM the_loai_kenh tlk
JOIN kenh_the_loai ktl ON tlk.the_loai_kenh = ktl.the_loai_kenh
JOIN kenh k ON ktl.ma_kenh = k.ma_kenh
LEFT JOIN lich_phat_song lps ON k.ma_kenh = lps.ma_kenh
GROUP BY ktl.the_loai_kenh
ORDER BY tong_lich_phat DESC;

-- ===========================================
-- 8. CHI TIẾT MỘT KÊNH CỤ THỂ
-- ===========================================

-- Xem chi tiết lịch phát của một kênh cụ thể (ví dụ: VTV1)
SELECT 
    'THÔNG TIN KÊNH' AS loai,
    k.ma_kenh AS ma,
    k.ten_kenh AS ten,
    k.mo_ta_kenh AS mo_ta,
    NULL::TIMESTAMP AS thoi_gian,
    NULL AS chuong_trinh,
    NULL::INT AS tap
FROM kenh k
WHERE k.ma_kenh = 'VTV1'

UNION ALL

SELECT 
    'LỊCH PHÁT' AS loai,
    lps.ma_lich_phat_song AS ma,
    ct.ten_chuong_trinh AS ten,
    CONCAT('Tập ', lps.so_tap, ' - ', COALESCE(t.tieu_de, 'Không có tiêu đề')) AS mo_ta,
    lps.thoi_gian_bat_dau AS thoi_gian,
    ct.ma_chuong_trinh AS chuong_trinh,
    lps.so_tap AS tap
FROM kenh k
JOIN lich_phat_song lps ON k.ma_kenh = lps.ma_kenh
JOIN chuong_trinh ct ON lps.ma_chuong_trinh = ct.ma_chuong_trinh
LEFT JOIN tap t ON lps.ma_chuong_trinh = t.ma_chuong_trinh AND lps.so_tap = t.so_tap
WHERE k.ma_kenh = 'VTV1'
  AND lps.thoi_gian_bat_dau >= CURRENT_TIMESTAMP - INTERVAL '1 day'
  AND lps.thoi_gian_bat_dau <= CURRENT_TIMESTAMP + INTERVAL '7 days'

ORDER BY loai DESC, thoi_gian NULLS FIRST;
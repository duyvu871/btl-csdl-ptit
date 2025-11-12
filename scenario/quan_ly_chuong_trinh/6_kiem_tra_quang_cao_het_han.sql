-- ===========================================
-- KIỂM TRA QUẢNG CÁO SẮP HẾT HẠN HỢP ĐỒNG
-- ===========================================

-- Danh sách quảng cáo sắp hết hạn trong 60 ngày tới
SELECT 
    qc.ma_hop_dong,
    qc.ten_thuong_hieu,
    qc.ngay_bat_dau,
    qc.ngay_ket_thuc,
    qc.ngay_ket_thuc - CURRENT_DATE AS so_ngay_con_lai,
    COUNT(lpqc.ma_lich_phat_song) AS so_lich_phat_sap_toi,
    COUNT(CASE 
        WHEN lps.thoi_gian_bat_dau > CURRENT_TIMESTAMP 
        THEN 1 
    END) AS so_lich_chua_phat
FROM quang_cao qc
LEFT JOIN lich_phat_song_quang_cao lpqc ON qc.ma_hop_dong = lpqc.ma_hop_dong
LEFT JOIN lich_phat_song lps ON lpqc.ma_lich_phat_song = lps.ma_lich_phat_song
WHERE qc.ngay_ket_thuc IS NOT NULL
  AND qc.ngay_ket_thuc <= CURRENT_DATE + INTERVAL '60 days'
  AND qc.ngay_ket_thuc >= CURRENT_DATE
GROUP BY qc.ma_hop_dong, qc.ten_thuong_hieu, qc.ngay_bat_dau, qc.ngay_ket_thuc
ORDER BY qc.ngay_ket_thuc ASC;

-- ===========================================
-- CHI TIẾT LỊCH PHÁT CỦA QUẢNG CÁO SẮP HẾT HẠN
-- ===========================================

-- Lịch phát chi tiết của các quảng cáo sắp hết hạn
SELECT 
    qc.ma_hop_dong,
    qc.ten_thuong_hieu,
    qc.ngay_ket_thuc,
    qc.ngay_ket_thuc - CURRENT_DATE AS ngay_con_lai,
    k.ten_kenh,
    lps.thoi_gian_bat_dau,
    lps.thoi_gian_ket_thuc,
    ct.ten_chuong_trinh,
    lps.so_tap,
    lpqc.thu_tu AS thu_tu_quang_cao,
    lpqc.thoi_diem_chen_quang_cao,
    CASE 
        WHEN lps.thoi_gian_bat_dau > CURRENT_TIMESTAMP THEN 'Chưa phát'
        WHEN lps.thoi_gian_bat_dau <= CURRENT_TIMESTAMP 
         AND lps.thoi_gian_ket_thuc >= CURRENT_TIMESTAMP THEN 'Đang phát'
        ELSE 'Đã phát'
    END AS trang_thai_phat_song
FROM quang_cao qc
JOIN lich_phat_song_quang_cao lpqc ON qc.ma_hop_dong = lpqc.ma_hop_dong
JOIN lich_phat_song lps ON lpqc.ma_lich_phat_song = lps.ma_lich_phat_song
JOIN kenh k ON lps.ma_kenh = k.ma_kenh
JOIN chuong_trinh ct ON lps.ma_chuong_trinh = ct.ma_chuong_trinh
WHERE qc.ngay_ket_thuc IS NOT NULL
  AND qc.ngay_ket_thuc <= CURRENT_DATE + INTERVAL '30 days'
  AND qc.ngay_ket_thuc >= CURRENT_DATE
ORDER BY qc.ngay_ket_thuc ASC, lps.thoi_gian_bat_dau ASC, lpqc.thu_tu ASC;

-- ===========================================
-- THỐNG KÊ TỔNG QUAN QUẢNG CÁO SẮP HẾT HẠN
-- ===========================================

-- Thống kê theo khoảng thời gian hết hạn
SELECT 
    CASE 
        WHEN qc.ngay_ket_thuc <= CURRENT_DATE + INTERVAL '7 days' THEN '1-7 ngày tới'
        WHEN qc.ngay_ket_thuc <= CURRENT_DATE + INTERVAL '15 days' THEN '8-15 ngày tới'
        WHEN qc.ngay_ket_thuc <= CURRENT_DATE + INTERVAL '30 days' THEN '16-30 ngày tới'
    END AS nhom_het_han,
    COUNT(DISTINCT qc.ma_hop_dong) AS so_hop_dong_het_han,
    COUNT(lpqc.ma_lich_phat_song) AS tong_lich_phat_anh_huong,
    COUNT(CASE 
        WHEN lps.thoi_gian_bat_dau > CURRENT_TIMESTAMP 
        THEN 1 
    END) AS lich_phat_chua_phat,
    SUM(qc.thoi_luong) AS tong_thoi_luong_giay
FROM quang_cao qc
LEFT JOIN lich_phat_song_quang_cao lpqc ON qc.ma_hop_dong = lpqc.ma_hop_dong
LEFT JOIN lich_phat_song lps ON lpqc.ma_lich_phat_song = lps.ma_lich_phat_song
WHERE qc.ngay_ket_thuc IS NOT NULL
  AND qc.ngay_ket_thuc <= CURRENT_DATE + INTERVAL '30 days'
  AND qc.ngay_ket_thuc >= CURRENT_DATE
GROUP BY 
    CASE 
        WHEN qc.ngay_ket_thuc <= CURRENT_DATE + INTERVAL '7 days' THEN '1-7 ngày tới'
        WHEN qc.ngay_ket_thuc <= CURRENT_DATE + INTERVAL '15 days' THEN '8-15 ngày tới'
        WHEN qc.ngay_ket_thuc <= CURRENT_DATE + INTERVAL '30 days' THEN '16-30 ngày tới'
    END
ORDER BY 
    MIN(qc.ngay_ket_thuc);

-- ===========================================
-- CẢNH BÁO QUẢNG CÁO HẾT HẠN TRONG 7 NGÀY
-- ===========================================

-- Danh sách cảnh báo khẩn cấp (hết hạn trong 7 ngày)
SELECT 
    'CẢNH BÁO KHẨN CẤP' AS loai_canh_bao,
    qc.ma_hop_dong,
    qc.ten_thuong_hieu,
    qc.ngay_ket_thuc,
    qc.ngay_ket_thuc - CURRENT_DATE AS ngay_con_lai,
    COUNT(CASE 
        WHEN lps.thoi_gian_bat_dau > CURRENT_TIMESTAMP 
        THEN 1 
    END) AS lich_phat_se_bi_anh_huong,
    STRING_AGG(DISTINCT k.ten_kenh, ', ') AS cac_kenh_anh_huong
FROM quang_cao qc
LEFT JOIN lich_phat_song_quang_cao lpqc ON qc.ma_hop_dong = lpqc.ma_hop_dong
LEFT JOIN lich_phat_song lps ON lpqc.ma_lich_phat_song = lps.ma_lich_phat_song
LEFT JOIN kenh k ON lps.ma_kenh = k.ma_kenh
WHERE qc.ngay_ket_thuc IS NOT NULL
  AND qc.ngay_ket_thuc <= CURRENT_DATE + INTERVAL '7 days'
  AND qc.ngay_ket_thuc >= CURRENT_DATE
GROUP BY qc.ma_hop_dong, qc.ten_thuong_hieu, qc.ngay_ket_thuc
ORDER BY qc.ngay_ket_thuc ASC;

-- ===========================================
-- QUẢNG CÁO CÓ LỊCH PHÁT NHIỀU NHẤT SẮP HẾT HẠN
-- ===========================================

-- Top quảng cáo có nhiều lịch phát nhất mà sắp hết hạn
SELECT 
    qc.ma_hop_dong,
    qc.ten_thuong_hieu,
    qc.ngay_ket_thuc,
    COUNT(lpqc.ma_lich_phat_song) AS tong_lich_phat,
    COUNT(CASE 
        WHEN lps.thoi_gian_bat_dau > CURRENT_TIMESTAMP 
        THEN 1 
    END) AS lich_phat_chua_phat,
    COUNT(DISTINCT lps.ma_kenh) AS so_kenh_phat,
    ROUND(
        COUNT(lpqc.ma_lich_phat_song) * qc.thoi_luong / 60.0, 2
    ) AS tong_thoi_gian_phat_phut
FROM quang_cao qc
JOIN lich_phat_song_quang_cao lpqc ON qc.ma_hop_dong = lpqc.ma_hop_dong
JOIN lich_phat_song lps ON lpqc.ma_lich_phat_song = lps.ma_lich_phat_song
WHERE qc.ngay_ket_thuc IS NOT NULL
  AND qc.ngay_ket_thuc <= CURRENT_DATE + INTERVAL '30 days'
  AND qc.ngay_ket_thuc >= CURRENT_DATE
GROUP BY qc.ma_hop_dong, qc.ten_thuong_hieu, qc.ngay_ket_thuc, qc.thoi_luong
HAVING COUNT(lpqc.ma_lich_phat_song) > 0
ORDER BY tong_lich_phat DESC, qc.ngay_ket_thuc ASC
LIMIT 10;
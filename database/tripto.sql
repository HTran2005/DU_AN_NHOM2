-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Máy chủ: 127.0.0.1
-- Thời gian đã tạo: Th4 27, 2026 lúc 03:01 PM
-- Phiên bản máy phục vụ: 10.4.32-MariaDB
-- Phiên bản PHP: 8.0.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Cơ sở dữ liệu: `tripto`
--

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `danh_gia`
--

CREATE TABLE `danh_gia` (
  `id` int(11) NOT NULL,
  `id_nguoi_dung` int(11) NOT NULL,
  `id_dat_tour` int(11) DEFAULT NULL,
  `id_tour` int(11) DEFAULT NULL,
  `id_goi_combo` int(11) DEFAULT NULL,
  `so_sao` int(11) NOT NULL COMMENT '1-5',
  `binh_luan` text DEFAULT NULL,
  `ngay_tao` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Đang đổ dữ liệu cho bảng `danh_gia`
--

INSERT INTO `danh_gia` (`id`, `id_nguoi_dung`, `id_dat_tour`, `id_tour`, `id_goi_combo`, `so_sao`, `binh_luan`, `ngay_tao`) VALUES
(11, 3, NULL, 576, NULL, 5, 'Chuyến đi rất tuyệt vời, hướng dẫn viên nhiệt tình và dịch vụ tốt.', '2026-04-01 06:43:28'),
(12, 3, NULL, 576, NULL, 4, 'Phong cảnh đẹp, nhưng lịch trình hơi dày, cần thêm thời gian nghỉ.', '2026-04-01 06:43:28'),
(13, 2, NULL, 576, NULL, 5, 'Trải nghiệm xuất sắc, khách sạn sang trọng và đồ ăn ngon.', '2026-04-01 06:43:28'),
(14, 3, NULL, 576, NULL, 5, 'Tour ổn nhưng xe di chuyển hơi chật, mong cải thiện.', '2026-04-01 06:43:28'),
(15, 4, NULL, 576, NULL, 3, 'Dịch vụ chưa tốt, check-in khách sạn chậm.', '2026-04-01 06:43:28'),
(16, 3, NULL, NULL, 21, 5, 'tuyệt vời', '2026-04-12 13:41:40'),
(17, 3, NULL, 16, NULL, 4, 'có cơ hội sẽ đặt lại', '2026-04-12 13:42:23'),
(18, 3, NULL, 29, NULL, 5, 'Tôi rất thích tour này, sẽ đi lại lần sau', '2026-04-17 05:42:02');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `dat_tour`
--

CREATE TABLE `dat_tour` (
  `id` int(11) NOT NULL,
  `so_dat_tour` varchar(50) NOT NULL,
  `id_nguoi_dung` int(11) NOT NULL,
  `id_tour` int(11) DEFAULT NULL,
  `id_goi_combo` int(11) DEFAULT NULL,
  `so_nguoi_lon` int(11) DEFAULT 1,
  `so_tre_em` int(11) DEFAULT 0,
  `ngay_khoi_hanh` date NOT NULL,
  `ghi_chu` text DEFAULT NULL,
  `phuong_thuc_thanh_toan` enum('Chuyển khoản','Ví điện tử','Thẻ tín dụng','Thanh toán tại văn phòng') NOT NULL,
  `id_phuong_thuc_thanh_toan` int(11) DEFAULT NULL,
  `tong_tien` decimal(12,2) NOT NULL,
  `trang_thai` enum('Chờ Xác Nhận Hủy','Chờ xác nhận','Đã hủy','Đã xác nhận') DEFAULT 'Chờ xác nhận',
  `ngay_tao` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Đang đổ dữ liệu cho bảng `dat_tour`
--

INSERT INTO `dat_tour` (`id`, `so_dat_tour`, `id_nguoi_dung`, `id_tour`, `id_goi_combo`, `so_nguoi_lon`, `so_tre_em`, `ngay_khoi_hanh`, `ghi_chu`, `phuong_thuc_thanh_toan`, `id_phuong_thuc_thanh_toan`, `tong_tien`, `trang_thai`, `ngay_tao`) VALUES
(17, 'BOOK-3-1775013356', 3, 578, NULL, 3, 1, '2026-04-30', '', 'Ví điện tử', NULL, 32510000.00, 'Đã xác nhận', '2026-04-01 03:15:56'),
(26, 'BOOK-2-1775191071', 2, 573, NULL, 2, 0, '2026-04-30', '', 'Chuyển khoản', NULL, 13550000.00, 'Đã xác nhận', '2026-04-03 04:37:51'),
(27, 'BOOK-4-1775191108', 4, 560, NULL, 2, 0, '2026-04-27', '', 'Chuyển khoản', NULL, 4750000.00, 'Chờ xác nhận', '2026-04-03 04:38:28'),
(34, 'BOOK-3-1775460422', 3, 16, NULL, 2, 0, '2025-04-30', '', 'Chuyển khoản', NULL, 4950000.00, 'Đã hủy', '2026-04-06 07:27:02'),
(36, 'BOOK-3-1775460804', 3, NULL, 21, 2, 0, '2025-04-30', '', 'Chuyển khoản', NULL, 14950000.00, 'Đã hủy', '2026-04-06 07:33:24'),
(37, 'BOOK-3-1775460886', 3, 565, NULL, 2, 0, '2026-04-22', '', 'Thanh toán tại văn phòng', NULL, 4750000.00, '', '2026-04-06 07:34:46'),
(38, 'BOOK-3-1775972428', 3, 20, NULL, 2, 0, '2026-04-16', 'Hủy bởi người dùng: Thay đổi kế hoạch', 'Chuyển khoản', NULL, 6750000.00, 'Đã hủy', '2026-04-12 05:40:28'),
(39, 'BOOK-3-1775997328', 3, NULL, 10, 2, 0, '2025-04-30', '', 'Chuyển khoản', NULL, 9530000.00, 'Đã hủy', '2026-04-12 12:35:28'),
(40, 'BOOK-3-1775999328', 3, 560, NULL, 2, 0, '2026-04-27', '', 'Chuyển khoản', NULL, 4750000.00, '', '2026-04-12 13:08:48'),
(41, 'BOOK-3-1776001744', 3, 359, NULL, 2, 0, '2026-04-28', '', 'Ví điện tử', NULL, 6350000.00, 'Đã xác nhận', '2026-04-12 13:49:04'),
(42, 'BOOK-3-1776002727', 3, 546, NULL, 2, 0, '2026-04-23', '', 'Thanh toán tại văn phòng', NULL, 4750000.00, '', '2026-04-12 14:05:27'),
(50, 'BOOK-3-1776090971', 3, 281, NULL, 2, 0, '2026-04-18', '', 'Ví điện tử', NULL, 4750000.00, 'Đã hủy', '2026-04-13 14:36:11'),
(51, 'BOOK-3-1776091678', 3, 5, NULL, 2, 0, '2026-04-16', '', 'Chuyển khoản', NULL, 6350000.00, 'Đã hủy', '2026-04-13 14:47:58'),
(56, 'BOOK-3-1776325609', 3, 576, NULL, 2, 0, '2026-04-30', '', 'Chuyển khoản', NULL, 19550000.00, 'Đã xác nhận', '2026-04-16 07:46:49'),
(57, 'BOOK-3-1776404423', 3, 571, NULL, 3, 0, '2026-04-30', 'Hủy bởi người dùng: Thay đổi kế hoạch', 'Thanh toán tại văn phòng', NULL, 22450000.00, 'Đã xác nhận', '2026-04-17 05:40:23'),
(60, 'BOOK-2-1776428311', 2, 574, NULL, 1, 1, '2026-04-30', '', 'Chuyển khoản', NULL, 15250000.00, 'Đã xác nhận', '2026-04-17 12:18:31'),
(61, 'DT02', 27, 244, NULL, 2, 1, '2026-05-14', NULL, 'Thanh toán tại văn phòng', NULL, 6430000.00, 'Chờ xác nhận', '2026-04-17 12:32:38'),
(62, 'BOOK-2-1776431568', 2, 566, NULL, 2, 1, '2026-04-23', '', 'Ví điện tử', NULL, 5890000.00, 'Đã hủy', '2026-04-17 13:12:48'),
(63, 'BOOK-2-1776431699', 2, 519, NULL, 2, 0, '2026-04-26', '', 'Thanh toán tại văn phòng', NULL, 3550000.00, 'Đã hủy', '2026-04-17 13:14:59'),
(64, 'BOOK-3-1776575583', 3, 571, NULL, 2, 0, '2026-04-30', '', 'Chuyển khoản', NULL, 14950000.00, 'Đã xác nhận', '2026-04-19 05:13:03'),
(72, 'BOOK-3-1776593106', 3, 575, NULL, 2, 0, '2026-04-30', '', 'Thanh toán tại văn phòng', NULL, 14350000.00, 'Đã xác nhận', '2026-04-19 10:05:06'),
(73, 'BOOK-3-1776593164', 3, 563, NULL, 2, 0, '2026-04-20', '', 'Chuyển khoản', 2, 4950000.00, '', '2026-04-19 10:06:04'),
(74, 'BOOK-3-1776593218', 3, 558, NULL, 2, 0, '2026-04-25', '', 'Chuyển khoản', 1, 4550000.00, '', '2026-04-19 10:06:58'),
(75, 'BOOK-3-1776604398', 3, 571, NULL, 2, 2, '2026-04-30', 'Hủy bởi người dùng: Thay đổi kế hoạch', 'Chuyển khoản', 1, 25450000.00, 'Đã hủy', '2026-04-19 13:13:18'),
(76, 'BOOK-3-1777255856', 3, 575, NULL, 2, 0, '2026-04-30', '', 'Chuyển khoản', 1, 14350000.00, 'Đã xác nhận', '2026-04-27 02:10:56'),
(79, 'BOOK-3-1777257771', 3, 572, NULL, 2, 0, '2026-04-30', '', 'Thanh toán tại văn phòng', NULL, 16350000.00, 'Đã xác nhận', '2026-04-27 02:42:51'),
(80, 'BOOK-3-1777257919', 3, 575, NULL, 2, 0, '2026-04-30', '', 'Thanh toán tại văn phòng', NULL, 14350000.00, 'Đã xác nhận', '2026-04-27 02:45:19'),
(82, 'BOOK-3-1777264238', 3, NULL, 28, 2, 0, '2026-04-30', '', 'Chuyển khoản', 2, 13550000.00, 'Đã xác nhận', '2026-04-27 04:30:38');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `dia_diem`
--

CREATE TABLE `dia_diem` (
  `id` int(11) NOT NULL,
  `ten` varchar(100) NOT NULL,
  `quoc_gia` varchar(100) NOT NULL,
  `mo_ta` text DEFAULT NULL,
  `url_anh` varchar(255) DEFAULT NULL,
  `ngay_tao` timestamp NOT NULL DEFAULT current_timestamp(),
  `vung_mien` enum('Miền Bắc','Miền Trung','Miền Nam','Tây Nguyên') DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Đang đổ dữ liệu cho bảng `dia_diem`
--

INSERT INTO `dia_diem` (`id`, `ten`, `quoc_gia`, `mo_ta`, `url_anh`, `ngay_tao`, `vung_mien`) VALUES
(1, 'Hà Nội', 'Việt Nam', 'Thủ đô ngàn năm văn hiến', 'hanoi.jpg', '2026-03-22 03:32:43', 'Miền Bắc'),
(4, 'Lào Cai', 'Việt Nam', 'Quần thể Tràng An, Tam Cốc', 'ninhbinh.jpg', '2026-03-22 03:32:43', 'Miền Bắc'),
(5, 'Hà Giang', 'Việt Nam', 'Cao nguyên đá Đồng Văn', 'hagiang.jpg', '2026-03-22 03:32:43', 'Miền Bắc'),
(6, 'Cao Bằng', 'Việt Nam', 'Thác Bản Giốc, động Ngườm Ngao', 'caobang.jpg', '2026-03-22 03:32:43', 'Miền Bắc'),
(7, 'Lạng Sơn', 'Việt Nam', 'Động Tam Thanh, núi Tô Thị', 'langson.jpg', '2026-03-22 03:32:43', 'Miền Bắc'),
(8, 'Quảng Ninh', 'Việt Nam', 'Yên Tử, biển Bãi Cháy', 'quangninh.jpg', '2026-03-22 03:32:43', 'Miền Bắc'),
(9, 'Thái Nguyên', 'Việt Nam', 'Hồ Núi Cốc', 'thaineuyen.jpg', '2026-03-22 03:32:43', 'Miền Bắc'),
(10, 'Phú Thọ', 'Việt Nam', 'Đền Hùng', 'phutho.jpg', '2026-03-22 03:32:43', 'Miền Bắc'),
(11, 'Đà Nẵng', 'Việt Nam', 'Cầu Rồng, Bà Nà Hills', 'danang.jpg', '2026-03-22 03:32:43', 'Miền Trung'),
(13, 'Huế', 'Việt Nam', 'Kinh thành Huế, sông Hương', 'hue.jpg', '2026-03-22 03:32:43', 'Miền Trung'),
(14, 'Quảng Bình', 'Việt Nam', 'Phong Nha - Kẻ Bàng', 'quangbinh.jpg', '2026-03-22 03:32:43', 'Miền Trung'),
(15, 'Quảng Trị', 'Việt Nam', 'Thành cổ Quảng Trị', 'quangtri.jpg', '2026-03-22 03:32:43', 'Miền Trung'),
(16, 'Quảng Ngãi', 'Việt Nam', 'Đảo Lý Sơn', 'lyson.jpg', '2026-03-22 03:32:43', 'Miền Trung'),
(17, 'Khánh Hòa', 'Việt Nam', 'Nha Trang, Vinpearl', 'nhatrang.jpg', '2026-03-22 03:32:43', 'Miền Trung'),
(18, 'Phú Yên', 'Việt Nam', 'Ghềnh Đá Đĩa', 'phuyen.jpg', '2026-03-22 03:32:43', 'Miền Trung'),
(19, 'Bình Định', 'Việt Nam', 'Eo Gió, Kỳ Co', 'binhdinh.jpg', '2026-03-22 03:32:43', 'Miền Trung'),
(20, 'Đà Lạt', 'Việt Nam', 'Thành phố ngàn hoa', 'dalat.jpg', '2026-03-22 03:32:43', 'Tây Nguyên'),
(21, 'Kon Tum', 'Việt Nam', 'Nhà thờ gỗ, Ngọc Linh', 'kontum.jpg', '2026-03-22 03:32:43', 'Tây Nguyên'),
(22, 'Gia Lai', 'Việt Nam', 'Biển Hồ, thác Phú Cường', 'gialai.jpg', '2026-03-22 03:32:43', 'Tây Nguyên'),
(23, 'Đắk Lắk', 'Việt Nam', 'Buôn Đôn, hồ Lắk', 'daklak.jpg', '2026-03-22 03:32:43', 'Tây Nguyên'),
(24, 'Đắk Nông', 'Việt Nam', 'Thác Dray Nur, Dray Sap', 'daknong.jpg', '2026-03-22 03:32:43', 'Tây Nguyên'),
(26, 'Bình Thuận', 'Việt Nam', 'Mũi Né, đồi cát bay', 'binhthuan.jpg', '2026-03-22 03:32:43', 'Miền Nam'),
(27, 'Phan Thiết', 'Việt Nam', 'Biển Lagi, Cù Lao Câu', 'phanthiet.jpg', '2026-03-22 03:32:43', 'Miền Nam'),
(28, 'Vũng Tàu', 'Việt Nam', 'Thành phố biển gần Sài Gòn', 'vungtau.jpg', '2026-03-22 03:32:43', 'Miền Nam'),
(29, 'TP. Hồ Chí Minh', 'Việt Nam', 'Đô thị hiện đại, Bến Nhà Rồng', 'hcm.jpg', '2026-03-22 03:32:43', 'Miền Nam'),
(30, 'Cần Thơ', 'Việt Nam', 'Chợ nổi Cái Răng', 'cantho.jpg', '2026-03-22 03:32:43', 'Miền Nam'),
(31, 'An Giang', 'Việt Nam', 'Núi Sam, rừng tràm Trà Sư', 'angiang.jpg', '2026-03-22 03:32:43', 'Miền Nam'),
(32, 'Đồng Tháp', 'Việt Nam', 'Làng hoa Sa Đéc, Tràm Chim', 'dongthap.jpg', '2026-03-22 03:32:43', 'Miền Nam'),
(33, 'Tiền Giang', 'Việt Nam', 'Chợ nổi Cái Bè, cù lao Thới Sơn', 'tiengiang.jpg', '2026-03-22 03:32:43', 'Miền Nam'),
(34, 'Bến Tre', 'Việt Nam', 'Xứ dừa, du lịch miệt vườn', 'bentre.jpg', '2026-03-22 03:32:43', 'Miền Nam'),
(35, 'Trà Vinh', 'Việt Nam', 'Ao Bà Om, chùa Khmer', 'travinh.jpg', '2026-03-22 03:32:43', 'Miền Nam'),
(36, 'Sóc Trăng', 'Việt Nam', 'Chùa Dơi, lễ hội Oóc Om Bóc', 'soctrang.jpg', '2026-03-22 03:32:43', 'Miền Nam'),
(37, 'Bạc Liêu', 'Việt Nam', 'Nhà công tử Bạc Liêu, điện gió', 'baclieu.jpg', '2026-03-22 03:32:43', 'Miền Nam'),
(38, 'Cà Mau', 'Việt Nam', 'Mũi Cà Mau, rừng U Minh Hạ', 'camau.jpg', '2026-03-22 03:32:43', 'Miền Nam'),
(39, 'Kiên Giang', 'Việt Nam', 'Phú Quốc, Hà Tiên', 'kiengiang.jpg', '2026-03-22 03:32:43', 'Miền Nam'),
(40, 'Hà Tĩnh', 'Việt Nam', 'Biển Thiên Cầm', 'hatinh.jpg', '2026-03-22 03:32:43', 'Miền Trung'),
(41, 'Nam Định', 'Việt Nam', 'Nhà thờ Phú Nhai', 'namdinh.jpg', '2026-03-22 03:32:43', 'Miền Bắc'),
(42, 'Thanh Hóa', 'Việt Nam', 'Biển Sầm Sơn', 'thanhhoa.jpg', '2026-03-22 03:32:43', 'Miền Trung'),
(43, 'Nghệ An', 'Việt Nam', 'Quê Bác Hồ, biển Cửa Lò', 'nghean.jpg', '2026-03-22 03:32:43', 'Miền Trung'),
(44, 'Bắc Ninh', 'Việt Nam', 'Làng quan họ, chùa Dâu', 'bacninh.jpg', '2026-03-22 03:32:43', 'Miền Bắc'),
(45, 'Bắc Giang', 'Việt Nam', 'Chùa Vĩnh Nghiêm, Tây Yên Tử', 'bacgiang.jpg', '2026-03-22 03:32:43', 'Miền Bắc'),
(46, 'Hòa Bình', 'Việt Nam', 'Thung Nai, Mai Châu', 'hoabinh.jpg', '2026-03-22 03:32:43', 'Miền Bắc'),
(47, 'Sơn La', 'Việt Nam', 'Mộc Châu, đồi chè', 'sonla.jpg', '2026-03-22 03:32:43', 'Miền Bắc'),
(48, 'Điện Biên', 'Việt Nam', 'Chiến thắng Điện Biên Phủ', 'dienbien.jpg', '2026-03-22 03:32:43', 'Miền Bắc'),
(49, 'Lai Châu', 'Việt Nam', 'Đỉnh Pu Ta Leng, Ô Quy Hồ', 'laichau.jpg', '2026-03-22 03:32:43', 'Miền Bắc'),
(50, 'Yên Bái', 'Việt Nam', 'Ruộng bậc thang Mù Cang Chải', 'yenbai.jpg', '2026-03-22 03:32:43', 'Miền Bắc');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `goi_combo`
--

CREATE TABLE `goi_combo` (
  `id` int(11) NOT NULL,
  `ten` varchar(150) NOT NULL,
  `mo_ta` text DEFAULT NULL,
  `id_dia_diem` int(11) NOT NULL,
  `gia_goc` decimal(10,2) DEFAULT NULL,
  `gia_ban` decimal(10,2) NOT NULL,
  `phan_tram_khuyen_mai` int(11) DEFAULT NULL,
  `url_anh` varchar(255) DEFAULT NULL,
  `trang_thai_hoat_dong` tinyint(4) DEFAULT 1,
  `ngay_tao` timestamp NOT NULL DEFAULT current_timestamp(),
  `loai_combo` enum('Gói du lịch gia đình','Gói du lịch nghỉ dưỡng','Gói du lịch biển đảo','Gói du lịch khám phá','Gói du lịch hè') DEFAULT NULL,
  `thoi_gian_combo` enum('2N1Đ','3N2Đ','4N3Đ','5N4Đ','Trên 5N') DEFAULT NULL,
  `ngay_khoi_hanh` date DEFAULT NULL,
  `tien_ich` text DEFAULT NULL,
  `label_khuyen_mai` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Đang đổ dữ liệu cho bảng `goi_combo`
--

INSERT INTO `goi_combo` (`id`, `ten`, `mo_ta`, `id_dia_diem`, `gia_goc`, `gia_ban`, `phan_tram_khuyen_mai`, `url_anh`, `trang_thai_hoat_dong`, `ngay_tao`, `loai_combo`, `thoi_gian_combo`, `ngay_khoi_hanh`, `tien_ich`, `label_khuyen_mai`) VALUES
(1, 'Combo Đà Lạt – Langbiang – Hồ Xuân Hương 3N2Đ', 'Khám phá Langbiang, hồ Xuân Hương và chợ đêm Đà Lạt', 20, 4500000.00, 3990000.00, 12, 'dalat1.jpg', 1, '2026-03-30 04:45:10', 'Gói du lịch khám phá', '3N2Đ', '2026-04-30', 'Khách sạn 3★; Ăn sáng; Vé tham quan', '-12%'),
(2, 'Combo Đà Lạt – Vườn Hoa – Thác Datanla 2N1Đ', 'Tham quan vườn hoa thành phố và thác Datanla', 20, 3500000.00, 2990000.00, 15, 'dalat2.jpg', 1, '2026-03-30 04:45:10', 'Gói du lịch gia đình', '2N1Đ', '2026-05-01', 'Khách sạn 3★; Buffet sáng; Xe đưa đón', '-15%'),
(3, 'Combo Đà Lạt – Thiền viện Trúc Lâm – Hồ Tuyền Lâm 4N3Đ', 'Khám phá Thiền viện Trúc Lâm và hồ Tuyền Lâm', 20, 5200000.00, 4590000.00, 12, 'dalat3.jpg', 0, '2026-03-30 04:45:10', 'Gói du lịch nghỉ dưỡng', '4N3Đ', '2026-04-30', 'Khách sạn 4★; Hướng dẫn viên; Trekking', '-12%'),
(4, 'Combo Đà Lạt – Đồi chè Cầu Đất – Thác Pongour 5N4Đ', 'Khám phá đồi chè Cầu Đất và thác Pongour', 20, 6500000.00, 5590000.00, 14, 'dalat4.jpg', 0, '2026-03-30 04:45:10', 'Gói du lịch hè', '5N4Đ', '2026-04-30', 'Resort 4★; Buffet sáng; Xe đưa đón', '-14%'),
(5, 'Combo Đà Lạt – Làng Cù Lần – Núi Langbiang 3N2Đ', 'Trải nghiệm văn hóa Tây Nguyên tại làng Cù Lần và Langbiang', 20, 4000000.00, 3490000.00, 13, 'dalat5.jpg', 0, '2026-03-30 04:45:10', 'Gói du lịch khám phá', '3N2Đ', '2026-04-29', 'Khách sạn 3★; Ăn sáng; Vé tham quan', '-13%'),
(6, 'Combo Hà Giang – Đồng Văn – Lũng Cú 3N2Đ', 'Khám phá cao nguyên đá Đồng Văn và cột cờ Lũng Cú', 5, 4800000.00, 4290000.00, 11, 'hagiang1.jpg', 0, '2026-03-30 04:45:10', 'Gói du lịch khám phá', '3N2Đ', '2026-04-30', 'Khách sạn 3★; Ăn sáng; Xe đưa đón', '-11%'),
(7, 'Combo Hà Giang – Mã Pí Lèng – Sủng Là 4N3Đ', 'Chinh phục đèo Mã Pí Lèng và tham quan làng Sủng Là', 5, 5200000.00, 4590000.00, 12, 'hagiang2.jpg', 0, '2026-03-30 04:45:10', 'Gói du lịch gia đình', '4N3Đ', '2026-04-22', 'Khách sạn 3★; Hướng dẫn viên; Ăn sáng', '-12%'),
(8, 'Combo Hà Giang – Hoàng Su Phì – Lũng Cú 5N4Đ', 'Ngắm ruộng bậc thang Hoàng Su Phì và check-in Lũng Cú', 5, 5800000.00, 4990000.00, 14, 'hagiang3.jpg', 0, '2026-03-30 04:45:10', 'Gói du lịch khám phá', '5N4Đ', '2026-04-30', 'Khách sạn 4★; Trekking; Xe đưa đón', '-14%'),
(9, 'Combo Hà Giang – Đồng Văn – Mèo Vạc 3N2Đ', 'Khám phá phố cổ Đồng Văn và thị trấn Mèo Vạc', 5, 4500000.00, 3990000.00, 11, 'hagiang4.jpg', 0, '2026-03-30 04:45:10', 'Gói du lịch nghỉ dưỡng', '3N2Đ', '2026-04-23', 'Khách sạn 3★; Ăn sáng; Vé tham quan', '-11%'),
(10, 'Combo Hà Giang – Lũng Cú – Sủng Là 4N3Đ', 'Khám phá văn hóa vùng cao tại Lũng Cú và Sủng Là', 5, 5500000.00, 4790000.00, 13, 'hagiang5.jpg', 0, '2026-03-30 04:45:10', 'Gói du lịch hè', '4N3Đ', '2026-04-23', 'Khách sạn 4★; Buffet sáng; Xe đưa đón', '-13%'),
(11, 'Combo Bắc Ninh – Quan họ – Chùa Dâu 2N1Đ', 'Trải nghiệm làng quan họ và tham quan chùa Dâu cổ kính', 44, 3200000.00, 2790000.00, 13, 'bacninh1.jpg', 0, '2026-03-30 04:45:34', 'Gói du lịch gia đình', '2N1Đ', '2026-04-27', 'Khách sạn 3★; Ăn sáng; Vé tham quan', '-13%'),
(12, 'Combo Bắc Ninh – Làng nghề – Đền Đô 3N2Đ', 'Khám phá làng nghề truyền thống và tham quan Đền Đô', 44, 4000000.00, 3490000.00, 13, 'bacninh2.jpg', 0, '2026-03-30 04:45:34', 'Gói du lịch nghỉ dưỡng', '3N2Đ', '2026-04-24', 'Khách sạn 3★; Buffet sáng; Xe đưa đón', '-13%'),
(13, 'Combo Bắc Ninh – Chùa Phật Tích – Chùa Dâu 2N1Đ', '', 44, 3000000.00, 2590000.00, 14, 'bacninh3.jpg', 0, '2026-03-30 04:45:34', 'Gói du lịch khám phá', '2N1Đ', '2026-04-23', 'Khách sạn 3★; Ăn sáng; Hướng dẫn viên', '-14%'),
(14, 'Combo Bắc Ninh – Lễ hội Lim – Quan họ 3N2Đ', 'Tham gia lễ hội Lim và thưởng thức dân ca quan họ', 44, 4200000.00, 3690000.00, 12, 'bacninh4.jpg', 0, '2026-03-30 04:45:34', 'Gói du lịch hè', '3N2Đ', '2026-04-26', 'Khách sạn 4★; Ăn sáng; Vé tham quan', '-12%'),
(15, 'Combo Bắc Ninh – Văn hóa – Làng Diềm 4N3Đ', 'Khám phá văn hóa Bắc Ninh tại làng Diềm', 44, 5000000.00, 4390000.00, 12, 'bacninh5.jpg', 0, '2026-03-30 04:45:34', 'Gói du lịch nghỉ dưỡng', '4N3Đ', '2025-04-30', 'Khách sạn 4★; Buffet sáng; Xe đưa đón', '-12%'),
(16, 'Combo Hòa Bình – Thung Nai – Suối khoáng Kim Bôi 2N1Đ', 'Khám phá Thung Nai và thư giãn tại suối khoáng Kim Bôi', 46, 3500000.00, 2990000.00, 15, 'hoabinh1.jpg', 0, '2026-03-30 04:45:55', 'Gói du lịch nghỉ dưỡng', '2N1Đ', '2025-04-30', 'Khách sạn 3★; Ăn sáng; Vé tham quan', '-15%'),
(17, 'Combo Hòa Bình – Mai Châu – Bản Lác 3N2Đ', 'Trải nghiệm văn hóa dân tộc Thái tại Mai Châu và bản Lác', 46, 4200000.00, 3690000.00, 12, 'hoabinh2.jpg', 0, '2026-03-30 04:45:55', 'Gói du lịch gia đình', '3N2Đ', '2025-04-30', 'Khách sạn 3★; Ăn sáng; Xe đưa đón', '-12%'),
(18, 'Combo Hòa Bình – Hồ Hòa Bình – Thủy điện 4N3Đ', 'Du thuyền trên hồ Hòa Bình và tham quan nhà máy thủy điện', 46, 5200000.00, 4590000.00, 12, 'hoabinh3.jpg', 0, '2026-03-30 04:45:55', 'Gói du lịch hè', '3N2Đ', '2025-04-30', 'Resort 4★; Buffet sáng; Vé tham quan', '-12%'),
(19, 'Combo Hòa Bình – Bản Mường – Suối khoáng 3N2Đ', 'Khám phá văn hóa dân tộc Mường và suối khoáng nóng', 46, 4000000.00, 3490000.00, 13, 'hoabinh4.jpg', 0, '2026-03-30 04:45:55', 'Gói du lịch khám phá', '3N2Đ', '2025-04-30', 'Khách sạn 3★; Hướng dẫn viên; Ăn sáng', '-13%'),
(20, 'Combo Hòa Bình – Thung Nai – Mai Châu 5N4Đ', 'Khám phá Thung Nai và trải nghiệm văn hóa Mai Châu', 46, 6500000.00, 5590000.00, 14, 'hoabinh5.jpg', 0, '2026-03-30 04:45:55', 'Gói du lịch nghỉ dưỡng', '5N4Đ', '2025-04-30', 'Resort 4★; Buffet sáng; Xe đưa đón', '-14%'),
(21, 'Combo Đà Lạt Hồ Xuân Hương', 'Nghỉ dưỡng trung tâm, tham quan hồ, chợ đêm, cafe', 20, 9000000.00, 7500000.00, 17, 'dalat1.jpg', 0, '2026-03-14 17:00:00', 'Gói du lịch nghỉ dưỡng', '3N2Đ', '2025-04-30', 'Khách sạn 3*, ăn sáng, xe đưa đón, vé tham quan', 'Giảm 17%'),
(22, 'Combo Đà Lạt Langbiang', 'Leo núi, săn mây, cắm trại và nghỉ dưỡng', 20, 9500000.00, 8000000.00, 16, 'dalat2.jpg', 0, '2026-03-14 17:00:00', 'Gói du lịch nghỉ dưỡng', '2N1Đ', '2026-04-28', 'Resort, BBQ, xe jeep, hướng dẫn viên', 'Giảm 16%'),
(23, 'Combo Đà Lạt Thung Lũng Tình Yêu', 'Không gian lãng mạn, tham quan, nghỉ dưỡng', 20, 8500000.00, 6900000.00, 19, 'dalat3.jpg', 0, '2026-03-15 17:00:00', 'Gói du lịch nghỉ dưỡng', '3N2Đ', '2026-04-25', 'Khách sạn 3*, ăn sáng, vé tham quan', 'Giảm 19%'),
(24, 'Combo Đà Lạt Thác Datanla', 'Trải nghiệm máng trượt, thác nước', 20, 9200000.00, 7800000.00, 15, 'dalat4.jpg', 0, '2026-03-31 17:00:00', 'Gói du lịch nghỉ dưỡng', '3N2Đ', '2026-04-30', 'Khách sạn, vé trò chơi, xe đưa đón', 'Giảm 15%'),
(25, 'Combo Đà Lạt Hồ Tuyền Lâm', 'Resort ven hồ, chèo kayak, nghỉ dưỡng cao cấp', 20, 10000000.00, 8500000.00, 15, 'dalat5.jpg', 0, '2026-04-01 17:00:00', 'Gói du lịch nghỉ dưỡng', '2N1Đ', '2026-04-30', 'Resort 4*, buffet sáng, chèo thuyền', 'Giảm 15%'),
(26, 'Combo Đà Lạt Đồi chè Cầu Đất', 'Săn mây, check-in đồi chè', 20, 8800000.00, 7200000.00, 18, 'dalat6.jpg', 0, '2026-03-16 17:00:00', 'Gói du lịch nghỉ dưỡng', '2N1Đ', '2026-04-30', 'Homestay, ăn sáng, xe tham quan', 'Giảm 18%'),
(27, 'Combo Đà Lạt Làng Cù Lần', 'Khám phá thiên nhiên, nghỉ dưỡng rừng thông', 20, 8700000.00, 7000000.00, 20, 'dalat7.jpg', 0, '2026-03-17 17:00:00', 'Gói du lịch nghỉ dưỡng', '3N2Đ', '2026-04-29', 'Nhà gỗ, BBQ, xe đưa đón', 'Giảm 20%'),
(28, 'Combo Đà Lạt Đồi Mộng Mơ', 'Tham quan vườn hoa, cảnh đẹp', 20, 8300000.00, 6800000.00, 18, 'dalat8.jpg', 0, '2026-03-17 17:00:00', 'Gói du lịch nghỉ dưỡng', '2N1Đ', '2026-04-30', 'Khách sạn, vé tham quan, ăn sáng', 'Giảm 18%'),
(32, 'COMBO NGHỈ DƯỠNG', 'ttt', 17, 4500000.00, 4000000.00, NULL, 'ag1.jpg', 0, '2026-04-27 09:10:54', NULL, '2N1Đ', '2026-05-01', NULL, NULL);

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `hidden_conversations`
--

CREATE TABLE `hidden_conversations` (
  `id` int(11) NOT NULL,
  `customer_id` int(11) NOT NULL,
  `hidden_date` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Đang đổ dữ liệu cho bảng `hidden_conversations`
--

INSERT INTO `hidden_conversations` (`id`, `customer_id`, `hidden_date`) VALUES
(1, 28, '2026-04-27 05:05:00');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `khuyen_mai`
--

CREATE TABLE `khuyen_mai` (
  `id` int(11) NOT NULL,
  `code` varchar(50) NOT NULL,
  `loai_giam` enum('Phần trăm','Cố định') DEFAULT 'Phần trăm',
  `gia_tri_giam` decimal(10,2) NOT NULL,
  `so_lan_toi_da` int(11) DEFAULT NULL,
  `so_lan_da_su_dung` int(11) DEFAULT 0,
  `co_hieu_luc_tu` datetime DEFAULT NULL,
  `co_hieu_luc_den` datetime DEFAULT NULL,
  `trang_thai` enum('Hoạt động','Không hoạt động') DEFAULT 'Hoạt động',
  `ngay_tao` timestamp NOT NULL DEFAULT current_timestamp(),
  `id_tour` int(11) DEFAULT NULL,
  `id_goi_combo` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Đang đổ dữ liệu cho bảng `khuyen_mai`
--

INSERT INTO `khuyen_mai` (`id`, `code`, `loai_giam`, `gia_tri_giam`, `so_lan_toi_da`, `so_lan_da_su_dung`, `co_hieu_luc_tu`, `co_hieu_luc_den`, `trang_thai`, `ngay_tao`, `id_tour`, `id_goi_combo`) VALUES
(1, 'GIAM30DL', 'Phần trăm', 30.00, 100, 0, '2026-04-30 00:00:00', '2026-05-30 00:00:00', 'Hoạt động', '2026-04-01 08:16:50', 214, NULL),
(2, 'PQFIX500K', 'Cố định', 500000.00, 20, 0, '2026-04-08 00:00:00', '2026-04-29 00:00:00', 'Hoạt động', '2026-04-01 08:16:50', 281, NULL),
(3, 'HGCOMBO25', 'Phần trăm', 25.00, 10, 0, '2026-03-01 00:00:00', '2026-05-01 00:00:00', 'Hoạt động', '2026-04-01 08:16:50', 309, NULL),
(4, 'DNFAMILY10', 'Phần trăm', 10.00, 70, 0, '2026-04-30 00:00:00', '2026-05-12 00:00:00', 'Hoạt động', '2026-04-01 08:16:50', NULL, 5),
(5, 'PQHONEYMOON15', 'Phần trăm', 15.00, 5, 0, '2026-04-30 00:00:00', '2026-05-20 00:00:00', 'Hoạt động', '2026-04-01 08:16:50', NULL, 13),
(18, 'SUPER', 'Phần trăm', 5.00, 15, 0, '2026-04-17 00:00:00', '2026-05-01 00:00:00', 'Hoạt động', '2026-04-16 03:51:41', 283, NULL),
(20, 'TRAN', 'Phần trăm', 5.00, 5, 0, '2026-04-23 00:00:00', '2026-05-02 00:00:00', 'Hoạt động', '2026-04-16 08:47:29', NULL, NULL);

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `khuyen_mai_combo`
--

CREATE TABLE `khuyen_mai_combo` (
  `id` int(11) NOT NULL,
  `id_khuyen_mai` int(11) NOT NULL,
  `id_goi_combo` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `khuyen_mai_tour`
--

CREATE TABLE `khuyen_mai_tour` (
  `id` int(11) NOT NULL,
  `id_khuyen_mai` int(11) NOT NULL,
  `id_tour` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Đang đổ dữ liệu cho bảng `khuyen_mai_tour`
--

INSERT INTO `khuyen_mai_tour` (`id`, `id_khuyen_mai`, `id_tour`) VALUES
(8, 1, 380),
(4, 2, 526),
(7, 3, 181),
(1, 4, 33),
(2, 4, 340),
(6, 18, 566),
(9, 20, 519);

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `lich_su_dang_nhap`
--

CREATE TABLE `lich_su_dang_nhap` (
  `id` int(11) NOT NULL,
  `id_nguoi_dung` int(11) NOT NULL,
  `thoi_gian_dang_nhap` timestamp NOT NULL DEFAULT current_timestamp(),
  `dia_chi_ip` varchar(45) DEFAULT NULL,
  `tac_nhan_user` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `lich_trinh_chi_tiet`
--

CREATE TABLE `lich_trinh_chi_tiet` (
  `id` int(11) NOT NULL,
  `lich_trinh_id` int(11) NOT NULL,
  `thoi_gian` varchar(50) DEFAULT NULL,
  `noi_dung` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Đang đổ dữ liệu cho bảng `lich_trinh_chi_tiet`
--

INSERT INTO `lich_trinh_chi_tiet` (`id`, `lich_trinh_id`, `thoi_gian`, `noi_dung`) VALUES
(1, 1, '7:30 AM', 'Khởi đầu hành trình: Quý khách được đón tại điểm hẹn. Hướng dẫn viên hỗ trợ kiểm tra danh sách và chuẩn bị cho chuyến đi.'),
(2, 1, '8:00 AM', 'Khởi hành: Xe đưa quý khách di chuyển đến điểm tham quan. Trên đường đi, hướng dẫn viên giới thiệu về lịch sử, văn hóa và các địa danh nổi bật.'),
(3, 1, '11:00 AM', 'Dừng chân: Xe dừng tại trạm nghỉ để quý khách thư giãn, vệ sinh cá nhân và thưởng thức các món ăn nhẹ.'),
(4, 1, '12:00 PM', 'Đến nơi: Quý khách đến điểm du lịch, nhận phòng khách sạn và nghĩ nghơi.'),
(5, 1, '12:30 PM', 'Ăn trưa: Thưởng thức buffet với nhiều món đặc sản địa phương phong phú, đảm bảo hợp khẩu vị.'),
(6, 1, '2:00 PM', 'Hoạt động: Bắt đầu chương trình tham quan chính. Quý khách tham gia các hoạt động trải nghiệm theo lịch trình.'),
(7, 1, '3:00 PM', 'Tham quan: Khám phá các điểm nổi bật, chụp ảnh lưu niệm và tìm hiểu văn hóa địa phương.'),
(8, 1, '5:30 PM', 'Thư giãn: Tự do nghỉ ngơi, ngắm cảnh hoàng hôn hoặc tham gia các hoạt động nhẹ nhàng.'),
(9, 1, '6:30 PM', 'Ăn tối: Dùng bữa tối tại nhà hàng với thực đơn đa dạng, không gian ấm cúng.'),
(10, 1, '10:00 PM', 'Nghỉ ngơi: Quý khách trở về phòng, tự do nghỉ ngơi và chuẩn bị cho ngày tiếp theo.'),
(11, 2, '07:00 AM', 'Ăn sáng tại khách sạn'),
(12, 2, '08:00 AM', 'Di chuyển đến sân golf Hồ Tuyền Lâm'),
(13, 2, '09:00 AM', 'Trải nghiệm chơi golf và tham quan khu nghỉ dưỡng'),
(14, 2, '12:00 PM', 'Ăn trưa tại nhà hàng trong khu resort'),
(15, 2, '02:00 PM', 'Tham quan vườn hoa thành phố và chụp ảnh lưu niệm'),
(16, 2, '06:00 PM', 'Ăn tối tại nhà hàng địa phương'),
(17, 2, '08:00 PM', 'Tự do khám phá chợ đêm Đà Lạt'),
(18, 3, '07:00 AM', 'Ăn sáng tại khách sạn'),
(19, 3, '08:00 AM', 'Tham quan Hồ Tuyền Lâm, đi thuyền ngắm cảnh'),
(20, 3, '10:00 AM', 'Check-in Thiền viện Trúc Lâm'),
(21, 3, '12:00 PM', 'Ăn trưa tại nhà hàng địa phương'),
(22, 3, '02:00 PM', 'Tham quan đồi chè Cầu Đất'),
(23, 3, '04:00 PM', 'Mua sắm đặc sản Đà Lạt'),
(24, 3, '06:00 PM', 'Ăn tối và chuẩn bị hành lý'),
(25, 3, '08:00 PM', 'Kết thúc hành trình, xe đưa khách ra sân bay/bến xe'),
(26, 13, '07:00', 'Đón khách tại điểm hẹn, khởi hành đi Hà Giang'),
(27, 13, '11:30', 'Ăn trưa tại Quản Bạ, ngắm Núi Đôi Cô Tiên'),
(28, 13, '13:30', 'Tham quan Cổng Trời Quản Bạ, chụp ảnh lưu niệm'),
(29, 13, '15:30', 'Di chuyển qua Yên Minh, tham quan rừng thông Yên Minh'),
(30, 13, '18:00', 'Ăn tối, nghỉ đêm tại thị trấn Yên Minh'),
(31, 14, '07:00', 'Ăn sáng tại khách sạn'),
(32, 14, '08:00', 'Khám phá cao nguyên đá Đồng Văn, tham quan các điểm nổi bật'),
(33, 14, '11:00', 'Ăn trưa tại nhà hàng địa phương'),
(34, 14, '13:30', 'Chinh phục Cột cờ Lũng Cú – điểm cực Bắc của Tổ quốc'),
(35, 14, '16:00', 'Tham quan phố cổ Đồng Văn, tự do mua sắm'),
(36, 14, '19:00', 'Ăn tối, nghỉ đêm tại Đồng Văn'),
(37, 15, '07:00', 'Ăn sáng tại khách sạn'),
(38, 15, '08:00', 'Di chuyển đến Mèo Vạc, tham quan chợ phiên (nếu đúng ngày)'),
(39, 15, '10:00', 'Chinh phục đèo Mã Pí Lèng – một trong “tứ đại đỉnh đèo” Việt Nam'),
(40, 15, '12:00', 'Ăn trưa tại nhà hàng địa phương'),
(41, 15, '13:30', 'Khởi hành về lại Hà Giang, kết thúc hành trình');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `lich_trinh_tour`
--

CREATE TABLE `lich_trinh_tour` (
  `id` int(11) NOT NULL,
  `id_tour` int(11) DEFAULT NULL,
  `id_goi_combo` int(11) DEFAULT NULL,
  `so_ngay` int(11) NOT NULL,
  `tieu_de` varchar(150) DEFAULT NULL,
  `mo_ta` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Đang đổ dữ liệu cho bảng `lich_trinh_tour`
--

INSERT INTO `lich_trinh_tour` (`id`, `id_tour`, `id_goi_combo`, `so_ngay`, `tieu_de`, `mo_ta`) VALUES
(1, 576, NULL, 1, 'Đà Lạt – Hồ Tuyền Lâm & Golf Resort 3 ngày 2 đêm', 'Khởi hành đến Đà Lạt, quý khách nhận phòng tại resort ven Hồ Tuyền Lâm. Không gian yên tĩnh, thiên nhiên trong lành giúp thư giãn sau hành trình di chuyển.'),
(2, 576, NULL, 2, 'Đà Lạt – Hồ Tuyền Lâm & Golf Resort 3 ngày 2 đêm', 'Trải nghiệm sân golf cao cấp giữa rừng thông và hồ nước. Kết hợp nghỉ dưỡng, spa và tận hưởng dịch vụ chuẩn 5 sao.'),
(3, 576, NULL, 3, 'Đà Lạt – Hồ Tuyền Lâm & Golf Resort 3 ngày 2 đêm', 'Tham quan Hồ Tuyền Lâm và các điểm check-in nhẹ nhàng. Kết thúc hành trình, trở về với nhiều kỷ niệm thư giãn.'),
(13, NULL, 6, 1, 'Ngày 1: Khởi hành – Quản Bạ – Yên Minh', 'Đón khách, tham quan Núi Đôi Cô Tiên, rừng thông Yên Minh, nghỉ đêm tại Yên Minh'),
(14, NULL, 6, 2, 'Ngày 2: Đồng Văn – Lũng Cú – Phố cổ', 'Khám phá cao nguyên đá, chinh phục Cột cờ Lũng Cú, tham quan phố cổ Đồng Văn'),
(15, NULL, 6, 3, 'Ngày 3: Mèo Vạc – Đèo Mã Pí Lèng – Trở về', 'Tham quan chợ phiên Mèo Vạc, chinh phục đèo Mã Pí Lèng, kết thúc hành trình');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `nguoi_dung`
--

CREATE TABLE `nguoi_dung` (
  `id` int(11) NOT NULL,
  `ten_dau` varchar(50) NOT NULL,
  `ten_cuoi` varchar(50) NOT NULL,
  `email` varchar(100) NOT NULL,
  `facebook_id` varchar(255) DEFAULT NULL,
  `so_dien_thoai` varchar(20) DEFAULT NULL,
  `mat_khau` varchar(255) NOT NULL,
  `anh_dai_dien` varchar(255) DEFAULT NULL,
  `gioi_tinh` enum('Nam','Nữ','Khác') DEFAULT 'Khác',
  `ngay_sinh` date DEFAULT NULL,
  `quoc_gia` varchar(100) DEFAULT NULL,
  `dia_chi` varchar(255) DEFAULT NULL,
  `ma_buu_chinh` varchar(20) DEFAULT NULL,
  `trang_thai_hoat_dong` tinyint(4) DEFAULT 1,
  `ngay_tao` timestamp NOT NULL DEFAULT current_timestamp(),
  `ngay_cap_nhat` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `vai_tro` enum('user','admin') NOT NULL DEFAULT 'user'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Đang đổ dữ liệu cho bảng `nguoi_dung`
--

INSERT INTO `nguoi_dung` (`id`, `ten_dau`, `ten_cuoi`, `email`, `facebook_id`, `so_dien_thoai`, `mat_khau`, `anh_dai_dien`, `gioi_tinh`, `ngay_sinh`, `quoc_gia`, `dia_chi`, `ma_buu_chinh`, `trang_thai_hoat_dong`, `ngay_tao`, `ngay_cap_nhat`, `vai_tro`) VALUES
(2, 'HUỲNH', 'HOÀNG DUNG', '0023412291@student.dthu.edu.vn', NULL, '0567812345', '$2y$10$rcJANOtSZ4ukzDHCcrPHtuWg8TC8ycBPrJemjf1EXawe5akOm4cSq', '../image/avatar_user_2.jpg', 'Nữ', '2005-01-01', 'Thuỵ Sĩ', 'Bang Bern', '1000-9999', 1, '2026-03-25 14:45:16', '2026-04-19 14:21:07', 'user'),
(3, 'Huyền', 'Trân', '0023412433@student.dthu.edu.vn', NULL, '0678123566', '$2y$10$8x7Nuk5/GDx8BcPeffmVOeekRvRPu4P/1U2YKjTkJmftqSGlSM8rW', '../image/avatar_user_3.jpg', 'Nữ', '2005-01-01', 'Việt Nam', 'tổ 14, khóm 15, phường Mỹ Ngãi, tỉnh Đồng Tháp', '010000-090999', 1, '2026-03-25 14:59:00', '2026-04-19 14:21:07', 'user'),
(4, 'Anh', 'Kỹ Sư', '0023412018@student.dthu.edu.vn', NULL, '0784561234', '$2y$10$pkGUWtkgqW2OZbfoGV2vl.OFFg.tg/IFKcwdipYmeSTmxOG0ZdDAu', '../image/avatar_user_4.jpg', 'Khác', '0000-00-00', 'Việt Nam', 'cao lãnh, Đồng Tháp', NULL, 1, '2026-03-25 15:02:17', '2026-04-19 14:22:36', 'user'),
(5, 'TRƯƠNG', 'THỊ CẨM LY', '0023411896@student.dthu.edu.vn', NULL, '0678456123', '$2y$10$V2rutG8fqAz65yj2G52Br.zMOMGAZxMzRcjgf49j2gpKklCPrFT1y', '../image/avatar_user_5.jpg', 'Nữ', '2026-01-01', 'Việt Nam', 'cao lãnh, Đồng Tháp', '010000-090999', 1, '2026-03-27 06:22:32', '2026-04-19 14:21:07', 'user'),
(8, 'Admin', 'GTD', 'tran09102005@gmail.com', NULL, NULL, '$2y$10$Z59qNOVbfS6b3tMI8f82luK51IuEhYEqB4mTUTLI422cFwnDQSrKS', NULL, 'Khác', NULL, NULL, NULL, NULL, 1, '2026-04-12 11:17:32', '2026-04-27 12:54:00', 'admin'),
(26, 'Trương', 'Thị Cẩm Ly', 'ly@gmail.com', NULL, '0684561234', '', NULL, 'Khác', '0000-00-00', 'Việt Nam', 'cao lãnh, Đồng Tháp', NULL, 1, '2026-04-17 12:07:41', '2026-04-19 14:22:36', 'user'),
(27, 'Lê', 'Thị Ngọc Bích', 'bich@gmail.com', NULL, '0684561234', '', NULL, 'Nữ', '2001-01-01', 'Việt Nam', 'cao lãnh, Đồng Tháp', NULL, 1, '2026-04-17 12:32:38', '2026-04-19 14:22:36', 'user'),
(28, 'Ngọc', 'Lan', '0023413456@student.dthu.edu.vn', NULL, '0456782344', '$2y$10$Yvw2iNDNREQee2x/XTSCb.ij2eAiepR5LHBDgTYj8asLh.YTepe06', NULL, 'Khác', '0000-00-00', 'Việt Nam', 'cao lãnh, Đồng Tháp', NULL, 1, '2026-04-18 02:41:19', '2026-04-19 14:22:36', 'user');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `nhom_yeuthich`
--

CREATE TABLE `nhom_yeuthich` (
  `id` int(11) NOT NULL,
  `id_nguoi_dung` int(11) NOT NULL,
  `ten_nhom` varchar(100) NOT NULL,
  `ngay_tao` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Đang đổ dữ liệu cho bảng `nhom_yeuthich`
--

INSERT INTO `nhom_yeuthich` (`id`, `id_nguoi_dung`, `ten_nhom`, `ngay_tao`) VALUES
(1, 3, 'Tour đi biển', '2026-04-06 08:26:14'),
(2, 3, 'Tour Đà Lạt', '2026-04-06 08:27:20'),
(3, 3, 'Tour khám phá', '2026-04-06 08:31:43'),
(4, 3, 'Ngắm cảnh', '2026-04-07 12:18:38');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `password_reset`
--

CREATE TABLE `password_reset` (
  `id` int(11) NOT NULL,
  `id_nguoi_dung` int(11) NOT NULL,
  `otp` varchar(10) NOT NULL,
  `email` varchar(100) NOT NULL,
  `so_lan_thu` int(11) DEFAULT 0,
  `ngay_tao` timestamp NOT NULL DEFAULT current_timestamp(),
  `ngay_het_han` timestamp NULL DEFAULT NULL,
  `trang_thai` varchar(20) DEFAULT 'Chờ xác nhận'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Đang đổ dữ liệu cho bảng `password_reset`
--

INSERT INTO `password_reset` (`id`, `id_nguoi_dung`, `otp`, `email`, `so_lan_thu`, `ngay_tao`, `ngay_het_han`, `trang_thai`) VALUES
(7, 3, '045254', '0023412433@student.dthu.edu.vn', 0, '2026-04-14 02:51:58', '2026-04-13 21:56:58', 'Đã dùng'),
(8, 3, '538280', '0023412433@student.dthu.edu.vn', 0, '2026-04-14 02:54:51', '2026-04-13 21:59:51', 'Đã dùng'),
(9, 3, '048715', '0023412433@student.dthu.edu.vn', 0, '2026-04-14 03:03:13', '2026-04-13 22:08:13', 'Đã dùng'),
(10, 3, '074009', '0023412433@student.dthu.edu.vn', 0, '2026-04-14 03:08:29', '2026-04-13 22:13:29', 'Đã dùng'),
(11, 3, '592130', '0023412433@student.dthu.edu.vn', 0, '2026-04-14 04:03:43', '2026-04-13 23:08:43', 'Đã dùng'),
(12, 3, '872464', '0023412433@student.dthu.edu.vn', 0, '2026-04-14 05:16:24', '2026-04-14 00:21:24', 'Đã dùng'),
(13, 3, '601811', '0023412433@student.dthu.edu.vn', 0, '2026-04-16 06:12:54', '2026-04-16 01:17:54', 'Đã dùng'),
(14, 3, '884321', '0023412433@student.dthu.edu.vn', 0, '2026-04-17 00:19:02', '2026-04-16 19:24:02', 'Đã dùng');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `phuong_thuc_thanh_toan`
--

CREATE TABLE `phuong_thuc_thanh_toan` (
  `id` int(11) NOT NULL,
  `id_nguoi_dung` int(11) NOT NULL,
  `ten_chu_the` varchar(100) DEFAULT NULL,
  `so_the` varchar(20) DEFAULT NULL,
  `loai_the` varchar(100) DEFAULT 'Khác',
  `ten_ngan_hang` varchar(100) DEFAULT NULL,
  `ngay_het_han` date DEFAULT NULL,
  `la_phuong_thuc_chinh` tinyint(4) DEFAULT 0,
  `ngay_tao` timestamp NOT NULL DEFAULT current_timestamp(),
  `thong_tin_them` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`thong_tin_them`))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Đang đổ dữ liệu cho bảng `phuong_thuc_thanh_toan`
--

INSERT INTO `phuong_thuc_thanh_toan` (`id`, `id_nguoi_dung`, `ten_chu_the`, `so_the`, `loai_the`, `ten_ngan_hang`, `ngay_het_han`, `la_phuong_thuc_chinh`, `ngay_tao`, `thong_tin_them`) VALUES
(1, 3, 'LE THI HUYEN TRAN', '4356', 'Thẻ tín dụng nội địa', 'BIDV', '2030-07-17', 0, '2026-04-18 23:56:22', NULL),
(2, 3, 'LE THI HUYEN TRAN', '0456', 'Visa', 'Visa', '2028-10-19', 0, '2026-04-18 23:57:54', '{\"cvv\":\"453\"}'),
(3, 2, 'HUYNH HOANG DUNG', '4563', 'Thẻ tín dụng nội địa', 'Techcombank', '0000-00-00', 0, '2026-04-19 00:35:13', NULL);

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `thanh_toan`
--

CREATE TABLE `thanh_toan` (
  `id` int(11) NOT NULL,
  `id_dat_tour` int(11) NOT NULL,
  `trang_thai` enum('Chờ xử lý','Thành công','Thất bại','Hoàn tiền') DEFAULT 'Chờ xử lý',
  `so_tien_hoan` decimal(12,2) DEFAULT NULL,
  `ngay_hoan_tien` timestamp NULL DEFAULT NULL,
  `ghi_chu` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Đang đổ dữ liệu cho bảng `thanh_toan`
--

INSERT INTO `thanh_toan` (`id`, `id_dat_tour`, `trang_thai`, `so_tien_hoan`, `ngay_hoan_tien`, `ghi_chu`) VALUES
(1, 17, 'Thành công', NULL, NULL, 'Thanh toán đầy đủ bằng Ví điện tử'),
(2, 26, 'Thành công', NULL, NULL, 'Khách đã chuyển khoản thành công'),
(3, 27, 'Chờ xử lý', NULL, NULL, 'Đang chờ xác nhận chuyển khoản'),
(5, 34, 'Thành công', NULL, NULL, 'Thanh toán qua chuyển khoản thành công'),
(6, 36, 'Thành công', NULL, NULL, 'Thanh toán qua chuyển khoản thành công'),
(7, 37, 'Thành công', NULL, NULL, 'Thanh toán tại văn phòng'),
(8, 38, 'Hoàn tiền', 6750000.00, '2026-04-13 11:45:16', 'Đơn hủy bởi người dùng, hoàn tiền toàn bộ'),
(9, 39, 'Thành công', NULL, NULL, 'Khách đã chuyển khoản đầy đủ'),
(10, 40, 'Thành công', NULL, NULL, 'Thanh toán đang chờ xác nhận'),
(11, 41, 'Thành công', NULL, NULL, 'Thanh toán bằng Ví điện tử thành công'),
(12, 42, 'Thành công', NULL, NULL, 'Thanh toán tại văn phòng'),
(23, 50, 'Chờ xử lý', NULL, NULL, NULL),
(24, 51, 'Chờ xử lý', NULL, NULL, NULL),
(25, 56, 'Chờ xử lý', NULL, NULL, NULL),
(26, 57, 'Thành công', NULL, NULL, NULL),
(29, 61, 'Chờ xử lý', NULL, NULL, NULL),
(30, 60, 'Chờ xử lý', NULL, NULL, NULL),
(31, 62, 'Chờ xử lý', NULL, NULL, NULL),
(32, 63, 'Chờ xử lý', NULL, NULL, NULL),
(33, 64, 'Thành công', NULL, NULL, NULL),
(34, 72, 'Chờ xử lý', NULL, NULL, NULL),
(35, 73, 'Chờ xử lý', NULL, NULL, NULL),
(36, 74, 'Chờ xử lý', NULL, NULL, NULL),
(37, 75, 'Hoàn tiền', NULL, NULL, NULL),
(38, 76, 'Thành công', NULL, NULL, NULL),
(39, 79, 'Thành công', NULL, NULL, NULL),
(40, 80, 'Thành công', NULL, NULL, NULL),
(42, 82, 'Chờ xử lý', NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `tin_nhan`
--

CREATE TABLE `tin_nhan` (
  `id` int(11) NOT NULL,
  `nguoi_gui_id` int(11) NOT NULL,
  `nguoi_nhan_id` int(11) NOT NULL,
  `noi_dung` text NOT NULL,
  `thoi_gian` timestamp NOT NULL DEFAULT current_timestamp(),
  `trang_thai` enum('sent','delivered','read') DEFAULT 'sent'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Đang đổ dữ liệu cho bảng `tin_nhan`
--

INSERT INTO `tin_nhan` (`id`, `nguoi_gui_id`, `nguoi_nhan_id`, `noi_dung`, `thoi_gian`, `trang_thai`) VALUES
(1, 3, 8, 'hi', '2026-04-17 04:36:10', 'sent'),
(2, 3, 8, 'tôi muốn tìm tour ở Đà Lạt, hãy giới thiệu cho tôi một số tour phù hợp', '2026-04-17 04:48:18', 'sent'),
(3, 8, 3, 'Cảm ơn bạn đã liên hệ với chúng tôi.', '2026-04-17 05:10:21', ''),
(4, 3, 8, 'Tôi chưa nhận được tiền hoàn', '2026-04-17 05:15:44', 'sent'),
(5, 8, 3, 'ok', '2026-04-17 05:16:34', ''),
(6, 2, 8, 'hi', '2026-04-17 05:57:50', 'sent'),
(7, 8, 2, 'Cảm ơn bạn đã liên hệ! Chúng tôi sẽ hỗ trợ bạn sớm nhất.', '2026-04-17 05:57:50', 'sent'),
(8, 8, 2, 'Hãy cho chúng tôi biết bạn cần hỗ trợ những vấn đề gì', '2026-04-18 02:22:40', ''),
(9, 4, 8, 'Giúp tôi tư vấn một số tour phù hợp cho gia đình đi nghĩ dưỡng ở Đà Lạt trong 5 đến 7 ngày', '2026-04-18 02:35:08', 'sent'),
(10, 5, 8, 'tôi muốn đặt tour nhưng không thanh toán trước được không', '2026-04-18 02:39:07', 'sent'),
(11, 28, 8, 'hi', '2026-04-18 02:41:27', 'sent'),
(12, 8, 28, 'Xin chào! 👋\n\nCảm ơn bạn đã liên hệ với Tripto. Đội hỗ trợ của chúng tôi sẽ sớm trả lời bạn!\n\n✈️ Tripto Team', '2026-04-18 02:41:27', ''),
(13, 3, 8, 'hi', '2026-04-27 09:08:29', 'sent');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `tour`
--

CREATE TABLE `tour` (
  `id` int(11) NOT NULL,
  `ten` varchar(150) NOT NULL,
  `mo_ta` text DEFAULT NULL,
  `id_dia_diem` int(11) NOT NULL,
  `gia` decimal(10,2) NOT NULL,
  `so_ngay` int(11) NOT NULL COMMENT 'Số ngày',
  `so_nguoi_toi_da` int(11) DEFAULT NULL,
  `url_anh_chinh` varchar(255) DEFAULT NULL,
  `danh_gia` decimal(3,2) DEFAULT 0.00,
  `so_danh_gia` int(11) DEFAULT 0,
  `la_tour_noi_bat` tinyint(4) DEFAULT 0,
  `trang_thai` enum('Hoạt động','Không hoạt động','Hết vé') DEFAULT 'Hoạt động',
  `ngay_tao` timestamp NOT NULL DEFAULT current_timestamp(),
  `ngay_cap_nhat` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `gia_khuyen_mai` decimal(10,2) DEFAULT NULL,
  `loai_tour` varchar(100) DEFAULT NULL,
  `ngay_khoi_hanh` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Đang đổ dữ liệu cho bảng `tour`
--

INSERT INTO `tour` (`id`, `ten`, `mo_ta`, `id_dia_diem`, `gia`, `so_ngay`, `so_nguoi_toi_da`, `url_anh_chinh`, `danh_gia`, `so_danh_gia`, `la_tour_noi_bat`, `trang_thai`, `ngay_tao`, `ngay_cap_nhat`, `gia_khuyen_mai`, `loai_tour`, `ngay_khoi_hanh`) VALUES
(1, 'Hà Nội – Phố Cổ – Hồ Gươm 2 Ngày 1 Đêm', 'Khám phá phố cổ, Hồ Gươm và văn hóa Hà Nội', 1, 3200000.00, 2, 30, 'hanoi1.jpg', 4.80, 250, 1, 'Hoạt động', '2026-03-26 08:41:42', '2026-03-27 07:14:38', 2900000.00, 'Văn hóa & Lịch sử', '2026-04-15'),
(2, 'Hà Nội – Văn Miếu – Hoàng Thành 2 Ngày 1 Đêm', 'Tham quan Văn Miếu, Hoàng thành Thăng Long', 1, 3300000.00, 2, 30, 'hanoi2.jpg', 4.70, 220, 1, 'Hoạt động', '2026-03-26 08:41:42', '2026-03-27 07:14:38', 3000000.00, 'Văn hóa & Lịch sử', '2026-04-15'),
(3, 'Hà Nội – Lăng Bác – Chùa Một Cột 2 Ngày 1 Đêm', 'Tham quan Lăng Chủ tịch Hồ Chí Minh và Chùa Một Cột', 1, 3400000.00, 2, 30, 'hanoi3.jpg', 4.90, 280, 1, 'Hoạt động', '2026-03-26 08:41:42', '2026-03-27 07:14:38', 3100000.00, 'Văn hóa & Lịch sử', '2026-04-15'),
(4, 'Hà Nội – Hồ Tây – Chùa Trấn Quốc 2 Ngày 1 Đêm', 'Khám phá Hồ Tây và Chùa Trấn Quốc', 1, 3300000.00, 2, 25, 'hanoi4.jpg', 4.80, 240, 0, 'Hoạt động', '2026-03-26 08:41:42', '2026-03-27 07:14:38', 3000000.00, 'Văn hóa & Lịch sử', '2026-04-15'),
(5, 'Hà Nội – Bát Tràng – Làng Gốm 2 Ngày 1 Đêm', 'Trải nghiệm làm gốm tại làng nghề Bát Tràng', 1, 3200000.00, 2, 25, 'hanoi5.jpg', 4.70, 200, 0, 'Hoạt động', '2026-03-26 08:41:42', '2026-03-27 07:14:38', 2900000.00, 'Văn hóa & Lịch sử', '2026-04-16'),
(6, 'Hà Nội – Làng Cổ Đường Lâm 2 Ngày 1 Đêm', 'Tham quan làng cổ Đường Lâm, trải nghiệm văn hóa', 1, 3500000.00, 2, 25, 'hanoi6.jpg', 4.90, 300, 1, 'Hoạt động', '2026-03-26 08:41:42', '2026-03-27 07:14:38', 3200000.00, 'Văn hóa & Lịch sử', '2026-04-16'),
(7, 'Hà Nội – Ba Vì – Vườn Quốc Gia 2 Ngày 1 Đêm', 'Khám phá thiên nhiên Ba Vì', 1, 3600000.00, 2, 25, 'hanoi7.jpg', 4.80, 260, 1, 'Hoạt động', '2026-03-26 08:41:42', '2026-03-27 07:14:38', 3300000.00, 'Nghỉ dưỡng', '2026-04-16'),
(8, 'Hà Nội – Chùa Hương – Suối Yến 2 Ngày 1 Đêm', 'Tham quan Chùa Hương và Suối Yến', 1, 3400000.00, 2, 25, 'hanoi8.jpg', 4.70, 210, 0, 'Hoạt động', '2026-03-26 08:41:42', '2026-03-27 07:14:38', 3100000.00, 'Nghỉ dưỡng', '2026-04-16'),
(9, 'Hà Nội – Tour Ẩm Thực Phố Cổ 2 Ngày 1 Đêm', 'Khám phá ẩm thực Hà Nội về đêm', 1, 3300000.00, 2, 25, 'hanoi9.jpg', 4.80, 230, 1, 'Hoạt động', '2026-03-26 08:41:42', '2026-03-27 07:14:38', 3000000.00, 'Nghỉ dưỡng', '2026-04-16'),
(10, 'Hà Nội – Nhà Hát Lớn – Phố Pháp 2 Ngày 1 Đêm', 'Tham quan Nhà hát Lớn và phố Pháp cổ', 1, 3200000.00, 2, 25, 'hanoi10.jpg', 4.70, 200, 0, 'Hoạt động', '2026-03-26 08:41:42', '2026-03-27 07:14:38', 2900000.00, 'Văn hóa & Lịch sử', '2026-04-16'),
(11, 'Hà Nội – Tam Cốc – Bích Động 3 Ngày 2 Đêm', 'Khám phá hang động và cảnh quan Ninh Bình', 1, 4200000.00, 3, 30, 'hanoi11.jpg', 4.90, 310, 1, 'Hoạt động', '2026-03-26 08:41:42', '2026-03-27 07:14:39', 3900000.00, 'Mạo hiểm', '2026-04-15'),
(12, 'Hà Nội – Tràng An – Hoa Lư 3 Ngày 2 Đêm', 'Tham quan Tràng An và cố đô Hoa Lư', 1, 4300000.00, 3, 30, 'hanoi12.jpg', 4.80, 280, 1, 'Hoạt động', '2026-03-26 08:41:42', '2026-03-27 07:14:39', 4000000.00, 'Mạo hiểm', '2026-04-15'),
(13, 'Hà Nội – Hạ Long Du Thuyền 3 Ngày 2 Đêm', 'Trải nghiệm du thuyền trên Vịnh Hạ Long', 1, 4600000.00, 3, 30, 'hanoi13.jpg', 4.90, 350, 1, 'Hoạt động', '2026-03-26 08:41:42', '2026-03-27 07:14:38', 4300000.00, 'Biển & Đảo', '2026-04-16'),
(14, 'Hà Nội – Sapa – Fansipan 4 Ngày 3 Đêm', 'Khám phá Sapa và chinh phục Fansipan', 1, 5200000.00, 4, 30, 'hanoi14.jpg', 4.90, 400, 1, 'Hoạt động', '2026-03-26 08:41:42', '2026-03-27 07:14:39', 4900000.00, 'Mạo hiểm', '2026-04-16'),
(15, 'Hà Nội – Mai Châu – Mộc Châu 4 Ngày 3 Đêm', 'Tham quan Mai Châu và cao nguyên Mộc Châu', 1, 5100000.00, 4, 30, 'hanoi15.jpg', 4.80, 370, 1, 'Hoạt động', '2026-03-26 08:41:42', '2026-03-27 07:14:39', 4800000.00, 'Mạo hiểm', '2026-04-16'),
(16, 'Hà Nội – Yên Tử – Quảng Ninh 3 Ngày 2 Đêm', 'Tham quan chùa Yên Tử và Quảng Ninh', 1, 4400000.00, 3, 30, 'hanoi16.jpg', 4.70, 260, 0, 'Hoạt động', '2026-03-26 08:41:42', '2026-03-27 07:14:39', 4100000.00, 'Mạo hiểm', '2026-04-16'),
(17, 'Hà Nội – Làng Nghề Vạn Phúc 2 Ngày 1 Đêm', 'Khám phá làng lụa Vạn Phúc', 1, 3300000.00, 2, 25, 'hanoi17.jpg', 4.80, 220, 1, 'Hoạt động', '2026-03-26 08:41:42', '2026-03-27 07:14:38', 3000000.00, 'Văn hóa & Lịch sử', '2026-04-16'),
(18, 'Hà Nội – Tour Xe Đạp Hồ Tây 2 Ngày 1 Đêm', 'Trải nghiệm xe đạp quanh Hồ Tây', 1, 3200000.00, 2, 25, 'hanoi18.jpg', 4.70, 200, 0, 'Hoạt động', '2026-03-26 08:41:42', '2026-03-27 07:14:39', 2900000.00, 'Gia đình', '2026-04-16'),
(19, 'Hà Nội – Tour Đêm Phố Cổ 2 Ngày 1 Đêm', 'Khám phá phố cổ Hà Nội về đêm', 1, 3300000.00, 2, 25, 'hanoi19.jpg', 4.80, 230, 1, 'Hoạt động', '2026-03-26 08:41:42', '2026-03-27 07:14:39', 3000000.00, 'Gia đình', '2026-04-16'),
(20, 'Hà Nội – Tour Sinh Thái Yên Sở 2 Ngày 1 Đêm', 'Tham quan công viên Yên Sở, trải nghiệm sinh thái', 1, 3400000.00, 2, 25, 'hanoi20.jpg', 4.70, 210, 0, 'Hoạt động', '2026-03-26 08:41:42', '2026-03-27 07:14:38', 3100000.00, 'Nghỉ dưỡng', '2026-04-16'),
(21, 'Hà Giang – Cao Nguyên Đá Đồng Văn 3 Ngày 2 Đêm', 'Khám phá cao nguyên đá, phố cổ Đồng Văn', 5, 4500000.00, 3, 30, 'hagiang1.jpg', 4.90, 320, 1, 'Hoạt động', '2026-03-26 11:44:02', '2026-03-27 15:16:37', 4200000.00, 'Mạo hiểm', '2026-04-20'),
(22, 'Hà Giang – Cột Cờ Lũng Cú 3 Ngày 2 Đêm', 'Tham quan cực Bắc Tổ quốc, check-in Lũng Cú', 5, 4400000.00, 3, 30, 'hagiang2.jpg', 4.80, 280, 1, 'Hoạt động', '2026-03-26 11:44:02', '2026-03-27 15:16:37', 4100000.00, 'Văn hóa & Lịch sử', '2026-04-21'),
(23, 'Hà Giang – Đèo Mã Pí Lèng 3 Ngày 2 Đêm', 'Chinh phục đèo Mã Pí Lèng hùng vĩ', 5, 4600000.00, 3, 30, 'hagiang3.jpg', 4.90, 350, 1, 'Hoạt động', '2026-03-26 11:44:02', '2026-03-27 15:16:37', 4300000.00, 'Mạo hiểm', '2026-04-22'),
(24, 'Hà Giang – Phố Cáo – Sủng Là 3 Ngày 2 Đêm', 'Khám phá thung lũng Sủng Là, làng văn hóa Phố Cáo', 5, 4300000.00, 3, 25, 'hagiang4.jpg', 4.70, 210, 0, 'Hoạt động', '2026-03-26 11:44:02', '2026-03-27 15:16:37', 4000000.00, 'Văn hóa & Lịch sử', '2026-04-23'),
(25, 'Hà Giang – Hoàng Su Phì – Ruộng Bậc Thang 4 Ngày 3 Đêm', 'Ngắm ruộng bậc thang mùa lúa chín', 5, 5200000.00, 4, 30, 'hagiang5.jpg', 4.90, 370, 1, 'Hoạt động', '2026-03-26 11:44:02', '2026-03-27 15:16:37', 4900000.00, 'Nghỉ dưỡng', '2026-04-24'),
(26, 'Hà Giang – Làng Văn Hóa Dân Tộc 3 Ngày 2 Đêm', 'Trải nghiệm văn hóa dân tộc Mông, Dao', 5, 4400000.00, 3, 25, 'hagiang6.jpg', 4.80, 260, 0, 'Hoạt động', '2026-03-26 11:44:02', '2026-03-27 15:16:37', 4100000.00, 'Văn hóa & Lịch sử', '2026-04-25'),
(27, 'Hà Giang – Thác Tiên – Núi Đôi Quản Bạ 3 Ngày 2 Đêm', 'Tham quan Núi Đôi Quản Bạ, Thác Tiên', 5, 4300000.00, 3, 25, 'hagiang7.jpg', 4.70, 220, 0, 'Hoạt động', '2026-03-26 11:44:02', '2026-03-27 15:16:37', 4000000.00, 'Gia đình', '2026-04-26'),
(28, 'Hà Giang – Làng Dệt Thổ Cẩm 3 Ngày 2 Đêm', 'Khám phá nghề dệt thổ cẩm truyền thống', 5, 4200000.00, 3, 25, 'hagiang8.jpg', 4.60, 200, 0, 'Hoạt động', '2026-03-26 11:44:02', '2026-03-27 15:16:37', 3900000.00, 'Văn hóa & Lịch sử', '2026-04-27'),
(29, 'Hà Giang – Du Lịch Cộng Đồng 3 Ngày 2 Đêm', 'Trải nghiệm homestay, văn hóa bản địa', 5, 4400000.00, 3, 25, 'hagiang9.jpg', 4.80, 250, 1, 'Hoạt động', '2026-03-26 11:44:02', '2026-03-27 15:16:37', 4100000.00, 'Gia đình', '2026-04-28'),
(30, 'Hà Giang – Khám Phá Ẩm Thực 3 Ngày 2 Đêm', 'Thưởng thức thắng cố, rượu ngô, bánh tam giác mạch', 5, 4300000.00, 3, 25, 'hagiang10.jpg', 4.70, 230, 0, 'Hoạt động', '2026-03-26 11:44:02', '2026-03-27 15:16:37', 4000000.00, 'Nghỉ dưỡng', '2026-04-29'),
(31, 'Hà Giang – Lễ Hội Hoa Tam Giác Mạch 4 Ngày 3 Đêm', 'Ngắm hoa tam giác mạch rực rỡ', 5, 5100000.00, 4, 30, 'hagiang11.jpg', 4.90, 400, 1, 'Hoạt động', '2026-03-26 11:44:02', '2026-03-27 15:16:37', 4800000.00, 'Văn hóa & Lịch sử', '2026-04-30'),
(32, 'Hà Giang – Du Thuyền Sông Nho Quế 3 Ngày 2 Đêm', 'Trải nghiệm du thuyền trên sông Nho Quế', 5, 4600000.00, 3, 30, 'hagiang12.jpg', 4.90, 360, 1, 'Hoạt động', '2026-03-26 11:44:02', '2026-03-27 15:16:37', 4300000.00, 'Nghỉ dưỡng', '2026-05-01'),
(33, 'Hà Giang – Khám Phá Bản Làng 3 Ngày 2 Đêm', 'Tham quan bản làng người H’Mông, Dao', 5, 4400000.00, 3, 25, 'hagiang13.jpg', 4.80, 270, 0, 'Hoạt động', '2026-03-26 11:44:02', '2026-03-27 15:16:37', 4100000.00, 'Gia đình', '2026-05-02'),
(34, 'Hà Giang – Trekking Núi Đá 4 Ngày 3 Đêm', 'Chinh phục núi đá Hà Giang', 5, 5200000.00, 4, 25, 'hagiang14.jpg', 4.90, 380, 1, 'Hoạt động', '2026-03-26 11:44:02', '2026-03-27 15:16:37', 4900000.00, 'Mạo hiểm', '2026-05-03'),
(35, 'Hà Giang – Khám Phá Chợ Phiên 3 Ngày 2 Đêm', 'Trải nghiệm chợ phiên vùng cao', 5, 4300000.00, 3, 25, 'hagiang15.jpg', 4.70, 240, 0, 'Hoạt động', '2026-03-26 11:44:02', '2026-03-27 15:16:37', 4000000.00, 'Văn hóa & Lịch sử', '2026-05-04'),
(36, 'Hà Giang – Du Lịch Sinh Thái 3 Ngày 2 Đêm', 'Khám phá thiên nhiên, nghỉ dưỡng sinh thái', 5, 4400000.00, 3, 25, 'hagiang16.jpg', 4.80, 260, 1, 'Hoạt động', '2026-03-26 11:44:02', '2026-03-27 15:16:37', 4100000.00, 'Nghỉ dưỡng', '2026-05-05'),
(37, 'Hà Giang – Khám Phá Văn Hóa Dao 3 Ngày 2 Đêm', 'Tìm hiểu phong tục tập quán người Dao', 5, 4200000.00, 3, 25, 'hagiang17.jpg', 4.60, 210, 0, 'Hoạt động', '2026-03-26 11:44:02', '2026-03-27 15:16:37', 3900000.00, 'Văn hóa & Lịch sử', '2026-05-06'),
(38, 'Hà Giang – Khám Phá Văn Hóa Mông 3 Ngày 2 Đêm', 'Tìm hiểu văn hóa người Mông', 5, 4300000.00, 3, 25, 'hagiang18.jpg', 4.70, 220, 0, 'Hoạt động', '2026-03-26 11:44:02', '2026-03-27 15:16:37', 4000000.00, 'Văn hóa & Lịch sử', '2026-05-07'),
(39, 'Hà Giang – Khám Phá Hang Động 3 Ngày 2 Đêm', 'Tham quan hang động kỳ thú', 5, 4400000.00, 3, 25, 'hagiang19.jpg', 4.80, 250, 1, 'Hoạt động', '2026-03-26 11:44:02', '2026-03-27 15:16:37', 4100000.00, 'Mạo hiểm', '2026-05-08'),
(40, 'Hà Giang – Khám Phá Núi Rừng 4 Ngày 3 Đêm', 'Khám phá núi rừng hùng vĩ Hà Giang', 5, 5200000.00, 4, 30, 'hagiang20.jpg', 4.90, 390, 1, 'Hoạt động', '2026-03-26 11:44:02', '2026-03-27 15:16:37', 4900000.00, 'Mạo hiểm', '2026-05-09'),
(41, 'Lào Cai – Sa Pa 2 ngày 1 đêm', 'Khám phá Sa Pa và văn hóa dân tộc', 4, 2500000.00, 2, 30, 'laocai1.jpg', 4.80, 200, 1, 'Hoạt động', '2025-04-10 01:00:00', '2026-03-27 15:16:37', 2300000.00, 'Gia đình', '2026-05-10'),
(42, 'Lào Cai – Fansipan 3 ngày 2 đêm', 'Chinh phục Fansipan và ngắm cảnh đẹp', 4, 3500000.00, 3, 25, 'laocai2.jpg', 4.90, 250, 1, 'Hoạt động', '2025-04-11 02:00:00', '2026-03-27 15:16:38', 3200000.00, 'Mạo hiểm', '2026-05-11'),
(43, 'Lào Cai – Bản Cát Cát 2 ngày 1 đêm', 'Tham quan bản làng và văn hóa H’Mông', 4, 2200000.00, 2, 30, 'laocai3.jpg', 4.70, 180, 0, 'Hoạt động', '2025-04-12 03:00:00', '2026-03-27 15:16:38', 2000000.00, 'Văn hóa & Lịch sử', '2026-05-12'),
(44, 'Lào Cai – Núi Hàm Rồng 2 ngày 1 đêm', 'Ngắm cảnh Sa Pa từ trên cao', 4, 2300000.00, 2, 25, 'laocai4.jpg', 4.60, 150, 0, 'Hoạt động', '2025-04-13 01:30:00', '2026-03-27 15:16:38', 2100000.00, 'Gia đình', '2026-05-13'),
(45, 'Lào Cai – Thác Bạc 2 ngày 1 đêm', 'Khám phá thác nước đẹp vùng Tây Bắc', 4, 2100000.00, 2, 30, 'laocai5.jpg', 4.70, 170, 0, 'Hoạt động', '2025-04-14 02:15:00', '2026-03-27 15:16:38', 1900000.00, 'Gia đình', '2026-05-14'),
(46, 'Lào Cai – Thác Tình Yêu 2 ngày 1 đêm', 'Check-in thác đẹp và không gian lãng mạn', 4, 2200000.00, 2, 25, 'laocai6.jpg', 4.80, 190, 0, 'Hoạt động', '2025-04-15 03:20:00', '2026-03-27 15:16:38', 2000000.00, 'Gia đình', '2026-05-15'),
(47, 'Lào Cai – Bản Tả Van 3 ngày 2 đêm', 'Trải nghiệm homestay và đời sống địa phương', 4, 3000000.00, 3, 20, 'laocai7.jpg', 4.90, 210, 1, 'Hoạt động', '2025-04-16 01:00:00', '2026-03-27 15:16:38', 2700000.00, 'Gia đình', '2026-05-16'),
(48, 'Lào Cai – Bản Lao Chải 3 ngày 2 đêm', 'Khám phá ruộng bậc thang tuyệt đẹp', 4, 3100000.00, 3, 20, 'laocai8.jpg', 4.80, 220, 1, 'Hoạt động', '2025-04-17 02:00:00', '2026-03-27 15:16:38', 2800000.00, 'Gia đình', '2026-05-17'),
(49, 'Lào Cai – Đèo Ô Quy Hồ 2 ngày 1 đêm', 'Săn mây và ngắm núi hùng vĩ', 4, 2400000.00, 2, 25, 'laocai9.jpg', 4.70, 160, 0, 'Hoạt động', '2025-04-18 03:00:00', '2026-03-27 15:16:38', 2200000.00, 'Mạo hiểm', '2026-05-18'),
(50, 'Lào Cai – Y Tý 3 ngày 2 đêm', 'Săn mây và khám phá thiên nhiên hoang sơ', 4, 3300000.00, 3, 20, 'laocai10.jpg', 4.90, 300, 1, 'Hoạt động', '2025-04-19 01:00:00', '2026-03-27 15:16:38', 3000000.00, 'Mạo hiểm', '2026-05-19'),
(51, 'Lào Cai – Bắc Hà 3 ngày 2 đêm', 'Khám phá cao nguyên và văn hóa dân tộc', 4, 3200000.00, 3, 25, 'laocai11.jpg', 4.80, 210, 0, 'Hoạt động', '2025-04-20 02:00:00', '2026-03-27 15:16:38', 2900000.00, 'Văn hóa & Lịch sử', '2026-05-20'),
(52, 'Lào Cai – Chợ phiên Bắc Hà 2 ngày 1 đêm', 'Trải nghiệm chợ phiên vùng cao đặc sắc', 4, 2300000.00, 2, 30, 'laocai12.jpg', 4.70, 180, 0, 'Hoạt động', '2025-04-21 03:00:00', '2026-03-27 15:16:38', 2100000.00, 'Văn hóa & Lịch sử', '2026-05-21'),
(53, 'Lào Cai – Dinh Hoàng A Tưởng 2 ngày 1 đêm', 'Tham quan dinh thự cổ nổi tiếng', 4, 2200000.00, 2, 25, 'laocai13.jpg', 4.60, 140, 0, 'Hoạt động', '2025-04-22 01:00:00', '2026-03-27 15:16:38', 2000000.00, 'Văn hóa & Lịch sử', '2026-05-22'),
(54, 'Lào Cai – Cửa khẩu Lào Cai 1 ngày', 'Tham quan cửa khẩu và mua sắm', 4, 1500000.00, 1, 40, 'laocai14.jpg', 4.50, 120, 0, 'Hoạt động', '2025-04-23 02:00:00', '2026-03-27 15:16:38', 1300000.00, 'Gia đình', '2026-05-23'),
(55, 'Lào Cai – Mường Hum 3 ngày 2 đêm', 'Khám phá chợ và bản làng vùng cao', 4, 3000000.00, 3, 20, 'laocai15.jpg', 4.80, 200, 0, 'Hoạt động', '2025-04-24 03:00:00', '2026-03-27 15:16:38', 2700000.00, 'Văn hóa & Lịch sử', '2026-05-24'),
(56, 'Lào Cai – A Lù 3 ngày 2 đêm', 'Check-in thiên nhiên hoang sơ vùng núi', 4, 3100000.00, 3, 20, 'laocai16.jpg', 4.70, 190, 0, 'Hoạt động', '2025-04-25 01:00:00', '2026-03-27 15:16:38', 2800000.00, 'Mạo hiểm', '2026-05-25'),
(57, 'Lào Cai – Ngải Thầu 3 ngày 2 đêm', 'Săn mây và ngắm bình minh đẹp', 4, 3200000.00, 3, 20, 'laocai17.jpg', 4.90, 260, 1, 'Hoạt động', '2025-04-26 02:00:00', '2026-03-27 15:16:38', 2900000.00, 'Nghỉ dưỡng', '2026-05-26'),
(58, 'Lào Cai – Sín Chéng 2 ngày 1 đêm', 'Tham quan chợ phiên và văn hóa địa phương', 4, 2200000.00, 2, 25, 'laocai18.jpg', 4.60, 150, 0, 'Hoạt động', '2025-04-27 03:00:00', '2026-03-27 15:16:38', 2000000.00, 'Văn hóa & Lịch sử', '2026-05-27'),
(59, 'Lào Cai – Bát Xát 3 ngày 2 đêm', 'Khám phá thiên nhiên và đời sống dân tộc', 4, 3300000.00, 3, 20, 'laocai19.jpg', 4.80, 210, 0, 'Hoạt động', '2025-04-28 01:00:00', '2026-03-27 15:16:38', 3000000.00, 'Gia đình', '2026-05-28'),
(60, 'Lào Cai – Thung lũng Mường Hoa 2 ngày 1 đêm', 'Ngắm ruộng bậc thang và cảnh đẹp', 4, 2400000.00, 2, 25, 'laocai20.jpg', 4.90, 280, 1, 'Hoạt động', '2025-04-29 02:00:00', '2026-03-27 15:16:38', 2200000.00, 'Nghỉ dưỡng', '2026-05-29'),
(61, 'Hà Giang – Đồng Văn 3 ngày 2 đêm', 'Khám phá phố cổ và cao nguyên đá', 5, 3200000.00, 3, 25, 'hagiang1.jpg', 4.90, 250, 1, 'Hoạt động', '2025-04-10 01:00:00', '2026-03-27 15:20:05', 2900000.00, 'Văn hóa & Lịch sử', '2025-04-10'),
(62, 'Hà Giang – Mã Pí Lèng 3 ngày 2 đêm', 'Ngắm đèo đẹp và sông Nho Quế', 5, 3300000.00, 3, 20, 'hagiang2.jpg', 4.90, 300, 1, 'Hoạt động', '2025-04-11 02:00:00', '2026-03-27 15:20:05', 3000000.00, 'Mạo hiểm', '2025-04-11'),
(63, 'Hà Giang – Lũng Cú 3 ngày 2 đêm', 'Check-in cột cờ cực Bắc Việt Nam', 5, 3100000.00, 3, 25, 'hagiang3.jpg', 4.80, 220, 1, 'Hoạt động', '2025-04-12 03:00:00', '2026-03-27 15:20:05', 2800000.00, 'Văn hóa & Lịch sử', '2025-04-12'),
(64, 'Hà Giang – Hoàng Su Phì 3 ngày 2 đêm', 'Ngắm ruộng bậc thang nổi tiếng', 5, 3400000.00, 3, 20, 'hagiang4.jpg', 4.90, 260, 1, 'Hoạt động', '2025-04-13 01:30:00', '2026-03-27 15:20:05', 3100000.00, 'Mạo hiểm', '2025-04-13'),
(65, 'Hà Giang – Quản Bạ 2 ngày 1 đêm', 'Check-in núi đôi và cổng trời', 5, 2400000.00, 2, 30, 'hagiang5.jpg', 4.80, 190, 0, 'Hoạt động', '2025-04-14 02:15:00', '2026-03-27 15:20:05', 2200000.00, 'Nghỉ dưỡng', '2025-04-14'),
(66, 'Hà Giang – Yên Minh 2 ngày 1 đêm', 'Khám phá rừng thông và núi đá', 5, 2500000.00, 2, 30, 'hagiang6.jpg', 4.70, 180, 0, 'Hoạt động', '2025-04-15 03:20:00', '2026-03-27 15:20:05', 2300000.00, 'Gia đình', '2025-04-15'),
(67, 'Hà Giang – Dinh Vua Mèo 3 ngày 2 đêm', 'Tham quan dinh họ Vương cổ kính', 5, 3100000.00, 3, 25, 'hagiang7.jpg', 4.80, 200, 0, 'Hoạt động', '2025-04-16 01:00:00', '2026-03-27 15:20:05', 2800000.00, 'Văn hóa & Lịch sử', '2025-04-16'),
(68, 'Hà Giang – Sông Nho Quế 3 ngày 2 đêm', 'Đi thuyền ngắm hẻm Tu Sản', 5, 3300000.00, 3, 20, 'hagiang8.jpg', 4.90, 270, 1, 'Hoạt động', '2025-04-17 02:00:00', '2026-03-27 15:20:05', 3000000.00, 'Mạo hiểm', '2025-04-17'),
(69, 'Hà Giang – Du Già 3 ngày 2 đêm', 'Khám phá bản làng và thác nước', 5, 3000000.00, 3, 20, 'hagiang9.jpg', 4.70, 170, 0, 'Hoạt động', '2025-04-18 03:00:00', '2026-03-27 15:20:05', 2700000.00, 'Văn hóa & Lịch sử', '2025-04-18'),
(70, 'Hà Giang – Phó Bảng 2 ngày 1 đêm', 'Tham quan làng cổ yên bình vùng cao', 5, 2600000.00, 2, 25, 'hagiang10.jpg', 4.60, 150, 0, 'Hoạt động', '2025-04-19 01:00:00', '2026-03-27 15:20:05', 2400000.00, 'Nghỉ dưỡng', '2025-04-19'),
(71, 'Cao Bằng – Thác Bản Giốc 2 ngày 1 đêm', 'Tham quan thác nước đẹp nhất Việt Nam', 6, 2600000.00, 2, 30, 'caobang1.jpg', 4.90, 300, 1, 'Hoạt động', '2025-04-10 01:00:00', '2026-03-27 15:20:05', 2400000.00, 'Văn hóa & Lịch sử', '2025-04-10'),
(72, 'Cao Bằng – Động Ngườm Ngao 2 ngày 1 đêm', 'Khám phá hang động đá vôi kỳ vĩ', 6, 2500000.00, 2, 25, 'caobang2.jpg', 4.80, 220, 0, 'Hoạt động', '2025-04-11 02:00:00', '2026-03-27 15:20:05', 2300000.00, 'Mạo hiểm', '2025-04-11'),
(73, 'Cao Bằng – Hồ Thang Hen 2 ngày 1 đêm', 'Ngắm hồ nước xanh giữa núi đá', 6, 2400000.00, 2, 30, 'caobang3.jpg', 4.70, 180, 0, 'Hoạt động', '2025-04-12 03:00:00', '2026-03-27 15:20:05', 2200000.00, 'Gia đình', '2025-04-12'),
(74, 'Cao Bằng – Pác Bó 2 ngày 1 đêm', 'Tham quan khu di tích lịch sử cách mạng', 6, 2300000.00, 2, 30, 'caobang4.jpg', 4.80, 200, 0, 'Hoạt động', '2025-04-13 01:30:00', '2026-03-27 15:20:05', 2100000.00, 'Văn hóa & Lịch sử', '2025-04-13'),
(75, 'Cao Bằng – Suối Lê Nin 2 ngày 1 đêm', 'Ngắm suối xanh trong tại Pác Bó', 6, 2300000.00, 2, 25, 'caobang5.jpg', 4.90, 260, 1, 'Hoạt động', '2025-04-14 02:15:00', '2026-03-27 15:20:05', 2100000.00, 'Nghỉ dưỡng', '2025-04-14'),
(76, 'Cao Bằng – Núi Mắt Thần 2 ngày 1 đêm', 'Check-in núi thủng độc đáo Cao Bằng', 6, 2500000.00, 2, 25, 'caobang6.jpg', 4.80, 210, 1, 'Hoạt động', '2025-04-15 03:20:00', '2026-03-27 15:20:05', 2300000.00, 'Văn hóa & Lịch sử', '2025-04-15'),
(77, 'Cao Bằng – Làng rèn Phúc Sen 2 ngày 1 đêm', 'Tìm hiểu nghề rèn truyền thống lâu đời', 6, 2200000.00, 2, 30, 'caobang7.jpg', 4.60, 150, 0, 'Hoạt động', '2025-04-16 01:00:00', '2026-03-27 15:20:05', 2000000.00, 'Mạo hiểm', '2025-04-16'),
(78, 'Cao Bằng – Đèo Mã Phục 2 ngày 1 đêm', 'Ngắm cảnh đèo mã phục tuyệt đẹp', 6, 2400000.00, 2, 25, 'caobang8.jpg', 4.70, 170, 0, 'Hoạt động', '2025-04-17 02:00:00', '2026-03-27 15:20:05', 2200000.00, 'Gia đình', '2025-04-17'),
(79, 'Cao Bằng – Thác Nặm Trá 2 ngày 1 đêm', 'Khám phá thác nước hoang sơ yên bình', 6, 2500000.00, 2, 20, 'caobang9.jpg', 4.70, 160, 0, 'Hoạt động', '2025-04-18 03:00:00', '2026-03-27 15:20:06', 2300000.00, 'Văn hóa & Lịch sử', '2025-04-18'),
(80, 'Cao Bằng – Bản Giốc – Ngườm Ngao 3 ngày 2 đêm', 'Kết hợp thác và hang động nổi tiếng', 6, 3300000.00, 3, 25, 'caobang10.jpg', 4.90, 280, 1, 'Hoạt động', '2025-04-19 01:00:00', '2026-03-27 15:20:06', 3000000.00, 'Nghỉ dưỡng', '2025-04-19'),
(81, 'Lạng Sơn – Mẫu Sơn 2 ngày 1 đêm', 'Ngắm núi cao và khí hậu mát mẻ', 7, 2500000.00, 2, 30, 'langson1.jpg', 4.80, 220, 1, 'Hoạt động', '2025-04-10 01:00:00', '2026-03-27 15:20:06', 2300000.00, 'Văn hóa & Lịch sử', '2025-04-10'),
(82, 'Lạng Sơn – Động Tam Thanh 2 ngày 1 đêm', 'Khám phá hang động và chùa cổ', 7, 2200000.00, 2, 30, 'langson2.jpg', 4.70, 180, 0, 'Hoạt động', '2025-04-11 02:00:00', '2026-03-27 15:20:06', 2000000.00, 'Mạo hiểm', '2025-04-11'),
(83, 'Lạng Sơn – Động Nhị Thanh 2 ngày 1 đêm', 'Tham quan hang động và di tích lịch sử', 7, 2200000.00, 2, 25, 'langson3.jpg', 4.60, 150, 0, 'Hoạt động', '2025-04-12 03:00:00', '2026-03-27 15:20:06', 2000000.00, 'Văn hóa & Lịch sử', '2025-04-12'),
(84, 'Lạng Sơn – Núi Tô Thị 2 ngày 1 đêm', 'Check-in tượng đá nàng Tô Thị', 7, 2100000.00, 2, 25, 'langson4.jpg', 4.70, 160, 0, 'Hoạt động', '2025-04-13 01:30:00', '2026-03-27 15:20:06', 1900000.00, 'Nghỉ dưỡng', '2025-04-13'),
(85, 'Lạng Sơn – Thành nhà Mạc 2 ngày 1 đêm', 'Khám phá di tích lịch sử cổ xưa', 7, 2300000.00, 2, 25, 'langson5.jpg', 4.70, 170, 0, 'Hoạt động', '2025-04-14 02:15:00', '2026-03-27 15:20:06', 2100000.00, 'Gia đình', '2025-04-14'),
(86, 'Lạng Sơn – Chợ Đông Kinh 1 ngày', 'Mua sắm hàng hóa nổi tiếng biên giới', 7, 1500000.00, 1, 40, 'langson6.jpg', 4.50, 140, 0, 'Hoạt động', '2025-04-15 03:20:00', '2026-03-27 15:20:06', 1300000.00, 'Mạo hiểm', '2025-04-15'),
(87, 'Lạng Sơn – Cửa khẩu Hữu Nghị 1 ngày', 'Tham quan cửa khẩu và hoạt động giao thương', 7, 1600000.00, 1, 40, 'langson7.jpg', 4.60, 150, 0, 'Hoạt động', '2025-04-16 01:00:00', '2026-03-27 15:20:06', 1400000.00, 'Văn hóa & Lịch sử', '2025-04-16'),
(88, 'Lạng Sơn – Ải Chi Lăng 2 ngày 1 đêm', 'Khám phá cửa ải lịch sử nổi tiếng', 7, 2400000.00, 2, 30, 'langson8.jpg', 4.80, 200, 1, 'Hoạt động', '2025-04-17 02:00:00', '2026-03-27 15:20:06', 2200000.00, 'Mạo hiểm', '2025-04-17'),
(89, 'Lạng Sơn – Đền Kỳ Cùng 2 ngày 1 đêm', 'Tham quan đền và văn hóa tâm linh', 7, 2200000.00, 2, 25, 'langson9.jpg', 4.60, 150, 0, 'Hoạt động', '2025-04-18 03:00:00', '2026-03-27 15:20:06', 2000000.00, 'Nghỉ dưỡng', '2025-04-18'),
(90, 'Lạng Sơn – Bắc Sơn 3 ngày 2 đêm', 'Ngắm thung lũng và ruộng lúa đẹp', 7, 3100000.00, 3, 20, 'langson10.jpg', 4.90, 260, 1, 'Hoạt động', '2025-04-19 01:00:00', '2026-03-27 15:20:06', 2800000.00, 'Văn hóa & Lịch sử', '2025-04-19'),
(91, 'Quảng Ninh – Vịnh Hạ Long 2 ngày 1 đêm', 'Tham quan vịnh và hang động nổi tiếng', 8, 3500000.00, 2, 30, 'quangninh1.jpg', 4.90, 500, 1, 'Hoạt động', '2025-04-10 01:00:00', '2026-03-27 15:20:06', 3200000.00, 'Nghỉ dưỡng', '2025-04-10'),
(92, 'Quảng Ninh – Đảo Tuần Châu 2 ngày 1 đêm', 'Nghỉ dưỡng biển và vui chơi giải trí', 8, 3000000.00, 2, 30, 'quangninh2.jpg', 4.80, 320, 1, 'Hoạt động', '2025-04-11 02:00:00', '2026-03-27 15:20:06', 2700000.00, 'Gia đình', '2025-04-11'),
(93, 'Quảng Ninh – Hang Sửng Sốt 2 ngày 1 đêm', 'Khám phá hang động đẹp nhất Hạ Long', 8, 3200000.00, 2, 25, 'quangninh3.jpg', 4.90, 400, 1, 'Hoạt động', '2025-04-12 03:00:00', '2026-03-27 15:20:06', 2900000.00, 'Mạo hiểm', '2025-04-12'),
(94, 'Quảng Ninh – Đảo Cô Tô 3 ngày 2 đêm', 'Tắm biển và nghỉ dưỡng đảo hoang sơ', 8, 3600000.00, 3, 25, 'quangninh4.jpg', 4.90, 420, 1, 'Hoạt động', '2025-04-13 01:30:00', '2026-03-27 15:20:06', 3300000.00, 'Văn hóa & Lịch sử', '2025-04-13'),
(95, 'Quảng Ninh – Đảo Quan Lạn 3 ngày 2 đêm', 'Khám phá biển đẹp và bãi cát trắng', 8, 3400000.00, 3, 25, 'quangninh5.jpg', 4.80, 300, 0, 'Hoạt động', '2025-04-14 02:15:00', '2026-03-27 15:28:45', 3100000.00, 'Biển & Đảo', '2026-04-20'),
(96, 'Quảng Ninh – Yên Tử 2 ngày 1 đêm', 'Hành hương và tham quan chùa linh thiêng', 8, 2800000.00, 2, 30, 'quangninh6.jpg', 4.80, 280, 1, 'Hoạt động', '2025-04-15 03:20:00', '2026-03-27 15:28:45', 2500000.00, 'Văn hoá & lịch sử', '2026-04-21'),
(97, 'Quảng Ninh – Bãi Cháy 2 ngày 1 đêm', 'Tắm biển và vui chơi giải trí', 8, 2700000.00, 2, 30, 'quangninh7.jpg', 4.70, 260, 0, 'Hoạt động', '2025-04-16 01:00:00', '2026-03-27 15:28:45', 2400000.00, 'Biển & Đảo', '2026-04-22'),
(98, 'Quảng Ninh – Đảo Minh Châu 3 ngày 2 đêm', 'Thư giãn biển xanh và cát trắng đẹp', 8, 3500000.00, 3, 25, 'quangninh8.jpg', 4.80, 290, 0, 'Hoạt động', '2025-04-17 02:00:00', '2026-03-27 15:28:45', 3200000.00, 'Biển & Đảo', '2026-04-23'),
(99, 'Quảng Ninh – Núi Bài Thơ 2 ngày 1 đêm', 'Ngắm toàn cảnh vịnh Hạ Long từ cao', 8, 2600000.00, 2, 25, 'quangninh9.jpg', 4.70, 240, 0, 'Hoạt động', '2025-04-18 03:00:00', '2026-03-27 15:28:45', 2300000.00, 'Mạo hiểm', '2026-04-24'),
(100, 'Quảng Ninh – Bảo tàng Quảng Ninh 1 ngày', 'Tham quan bảo tàng kiến trúc độc đáo', 8, 1800000.00, 1, 40, 'quangninh10.jpg', 4.60, 200, 0, 'Hoạt động', '2025-04-19 01:00:00', '2026-03-27 15:28:45', 1600000.00, 'Văn hoá & lịch sử', '2026-04-25'),
(101, 'Thái Nguyên – Hồ Núi Cốc 2 ngày 1 đêm', 'Tham quan hồ và khu du lịch nổi tiếng', 9, 2400000.00, 2, 30, 'thainguyen1.jpg', 4.70, 180, 1, 'Hoạt động', '2025-04-10 01:00:00', '2026-03-27 15:28:45', 2200000.00, 'Gia đình', '2026-04-20'),
(102, 'Thái Nguyên – ATK Định Hóa 2 ngày 1 đêm', 'Tham quan khu di tích lịch sử cách mạng', 9, 2300000.00, 2, 30, 'thainguyen2.jpg', 4.80, 200, 0, 'Hoạt động', '2025-04-11 02:00:00', '2026-03-27 15:28:45', 2100000.00, 'Văn hoá & lịch sử', '2026-04-21'),
(103, 'Thái Nguyên – Đồi chè Tân Cương 1 ngày', 'Check-in đồi chè xanh mướt nổi tiếng', 9, 1500000.00, 1, 40, 'thainguyen3.jpg', 4.60, 150, 0, 'Hoạt động', '2025-04-12 03:00:00', '2026-03-27 15:28:45', 1300000.00, 'Gia đình', '2026-04-22'),
(104, 'Thái Nguyên – Hang Phượng Hoàng 2 ngày 1 đêm', 'Khám phá hang động và suối Mỏ Gà', 9, 2500000.00, 2, 25, 'thainguyen4.jpg', 4.70, 170, 0, 'Hoạt động', '2025-04-13 01:30:00', '2026-03-27 15:28:45', 2300000.00, 'Mạo hiểm', '2026-04-23'),
(105, 'Thái Nguyên – Suối Mỏ Gà 2 ngày 1 đêm', 'Tắm suối và nghỉ dưỡng thiên nhiên mát mẻ', 9, 2400000.00, 2, 25, 'thainguyen5.jpg', 4.70, 160, 0, 'Hoạt động', '2025-04-14 02:15:00', '2026-03-27 15:28:45', 2200000.00, 'Nghỉ dưỡng', '2026-04-24'),
(106, 'Thái Nguyên – Bảo tàng Văn hóa các dân tộc 1 ngày', 'Tìm hiểu văn hóa 54 dân tộc Việt Nam', 9, 1600000.00, 1, 40, 'thainguyen6.jpg', 4.60, 140, 0, 'Hoạt động', '2025-04-15 03:20:00', '2026-03-27 15:28:45', 1400000.00, 'Văn hoá & lịch sử', '2026-04-25'),
(107, 'Thái Nguyên – Núi Văn Núi Võ 2 ngày 1 đêm', 'Khám phá di tích lịch sử và cảnh đẹp', 9, 2300000.00, 2, 30, 'thainguyen7.jpg', 4.60, 150, 0, 'Hoạt động', '2025-04-16 01:00:00', '2026-03-27 15:28:45', 2100000.00, 'Văn hoá & lịch sử', '2026-04-26'),
(108, 'Thái Nguyên – Hồ Ghềnh Chè 2 ngày 1 đêm', 'Ngắm hồ đẹp và chèo thuyền thư giãn', 9, 2500000.00, 2, 25, 'thainguyen8.jpg', 4.70, 170, 0, 'Hoạt động', '2025-04-17 02:00:00', '2026-03-27 15:28:45', 2300000.00, 'Nghỉ dưỡng', '2026-04-27'),
(109, 'Thái Nguyên – Đền Đuổm 2 ngày 1 đêm', 'Tham quan đền cổ và văn hóa tâm linh', 9, 2200000.00, 2, 30, 'thainguyen9.jpg', 4.60, 150, 0, 'Hoạt động', '2025-04-18 03:00:00', '2026-03-27 15:28:45', 2000000.00, 'Văn hoá & lịch sử', '2026-04-28'),
(110, 'Thái Nguyên – Khu du lịch Dũng Tân 2 ngày 1 đêm', 'Nghỉ dưỡng và vui chơi giải trí cuối tuần', 9, 2400000.00, 2, 25, 'thainguyen10.jpg', 4.50, 130, 0, 'Hoạt động', '2025-04-19 01:00:00', '2026-03-27 15:28:45', 2200000.00, 'Gia đình', '2026-04-29'),
(111, 'Phú Thọ – Làng cổ Hùng Lô 2 ngày 1 đêm', 'Khám phá làng cổ và văn hóa truyền thống', 10, 2300000.00, 2, 30, 'phutho1.jpg', 4.80, 220, 0, 'Hoạt động', '2025-04-10 01:00:00', '2026-03-27 15:28:45', 2100000.00, 'Văn hoá & lịch sử', '2026-04-20'),
(112, 'Phú Thọ – Khu di tích Đền Hùng 1 ngày', 'Tham quan đền và tìm hiểu lịch sử', 10, 1500000.00, 1, 40, 'phutho2.jpg', 4.80, 260, 1, 'Hoạt động', '2025-04-11 02:00:00', '2026-03-27 15:28:45', 1300000.00, 'Văn hoá & lịch sử', '2026-04-21'),
(113, 'Phú Thọ – Vườn quốc gia Xuân Sơn 3 ngày 2 đêm', 'Khám phá rừng nguyên sinh và hang động', 10, 3200000.00, 3, 25, 'phutho3.jpg', 4.90, 220, 1, 'Hoạt động', '2025-04-12 03:00:00', '2026-03-27 15:28:45', 2900000.00, 'Mạo hiểm', '2026-04-22'),
(114, 'Phú Thọ – Đồi chè Long Cốc 2 ngày 1 đêm', 'Check-in đồi chè xanh đẹp như tranh', 10, 2500000.00, 2, 30, 'phutho4.jpg', 4.80, 200, 0, 'Hoạt động', '2025-04-13 01:30:00', '2026-03-27 15:28:45', 2300000.00, 'Gia đình', '2026-04-23'),
(115, 'Phú Thọ – Ao Giời Suối Tiên 2 ngày 1 đêm', 'Khám phá thác nước và thiên nhiên hoang sơ', 10, 2600000.00, 2, 25, 'phutho5.jpg', 4.70, 180, 0, 'Hoạt động', '2025-04-14 02:15:00', '2026-03-27 15:28:45', 2400000.00, 'Mạo hiểm', '2026-04-24'),
(116, 'Phú Thọ – Đầm Ao Châu 2 ngày 1 đêm', 'Ngắm cảnh hồ và nghỉ dưỡng sinh thái', 10, 2400000.00, 2, 30, 'phutho6.jpg', 4.70, 170, 0, 'Hoạt động', '2025-04-15 03:20:00', '2026-03-27 15:28:45', 2200000.00, 'Nghỉ dưỡng', '2026-04-25'),
(117, 'Phú Thọ – Đền Lăng Sương 2 ngày 1 đêm', 'Tham quan đền cổ và văn hóa tâm linh', 10, 2300000.00, 2, 25, 'phutho7.jpg', 4.60, 150, 0, 'Hoạt động', '2025-04-16 01:00:00', '2026-03-27 15:28:45', 2100000.00, 'Văn hoá & lịch sử', '2026-04-26'),
(118, 'Phú Thọ – Thanh Thủy 2 ngày 1 đêm', 'Tắm khoáng nóng và nghỉ dưỡng thư giãn', 10, 2700000.00, 2, 25, 'phutho8.jpg', 4.80, 210, 1, 'Hoạt động', '2025-04-17 02:00:00', '2026-03-27 15:28:45', 2500000.00, 'Nghỉ dưỡng', '2026-04-27'),
(119, 'Phú Thọ – Đền Mẫu Âu Cơ 2 ngày 1 đêm', 'Tham quan đền và tín ngưỡng dân gian', 10, 2200000.00, 2, 30, 'phutho9.jpg', 4.60, 150, 0, 'Hoạt động', '2025-04-18 03:00:00', '2026-03-27 15:28:45', 2000000.00, 'Văn hoá & lịch sử', '2026-04-28'),
(120, 'Phú Thọ – Khu du lịch Bạch Hạc 1 ngày', 'Tham quan ngã ba sông linh thiêng', 10, 1600000.00, 1, 40, 'phutho10.jpg', 4.50, 130, 0, 'Hoạt động', '2025-04-19 01:00:00', '2026-03-27 15:28:45', 1400000.00, 'Gia đình', '2026-04-29'),
(121, 'Đà Nẵng – Bà Nà Hills 2 ngày 1 đêm', 'Tham quan cáp treo và cầu vàng nổi tiếng', 11, 3500000.00, 2, 30, 'danang1.jpg', 4.90, 500, 1, 'Hoạt động', '2025-04-10 01:00:00', '2026-03-27 15:28:45', 3200000.00, 'Gia đình', '2026-04-20'),
(122, 'Đà Nẵng – Cầu Rồng 1 ngày', 'Xem cầu phun lửa và check-in đẹp', 11, 1500000.00, 1, 40, 'danang2.jpg', 4.70, 300, 0, 'Hoạt động', '2025-04-11 02:00:00', '2026-03-27 15:28:45', 1300000.00, 'Gia đình', '2026-04-21'),
(123, 'Đà Nẵng – Biển Mỹ Khê 2 ngày 1 đêm', 'Tắm biển và nghỉ dưỡng bãi biển đẹp', 11, 2800000.00, 2, 30, 'danang3.jpg', 4.80, 350, 1, 'Hoạt động', '2025-04-12 03:00:00', '2026-03-27 15:28:45', 2500000.00, 'Biển & Đảo', '2026-04-22'),
(124, 'Đà Nẵng – Ngũ Hành Sơn 2 ngày 1 đêm', 'Khám phá núi đá và chùa linh thiêng', 11, 2600000.00, 2, 25, 'danang4.jpg', 4.70, 280, 0, 'Hoạt động', '2025-04-13 01:30:00', '2026-03-27 15:28:45', 2300000.00, 'Văn hoá & lịch sử', '2026-04-23'),
(125, 'Đà Nẵng – Bán đảo Sơn Trà 2 ngày 1 đêm', 'Ngắm cảnh biển và chùa Linh Ứng', 11, 2700000.00, 2, 25, 'danang5.jpg', 4.80, 320, 1, 'Hoạt động', '2025-04-14 02:15:00', '2026-03-27 15:28:45', 2400000.00, 'Biển & Đảo', '2026-04-24'),
(126, 'Đà Nẵng – Cầu Tình Yêu 1 ngày', 'Check-in cầu và tượng cá chép hóa rồng', 11, 1500000.00, 1, 40, 'danang6.jpg', 4.60, 200, 0, 'Hoạt động', '2025-04-15 03:20:00', '2026-03-27 15:28:45', 1300000.00, 'Gia đình', '2026-04-25'),
(127, 'Đà Nẵng – Asia Park 1 ngày', 'Vui chơi giải trí tại công viên châu Á', 11, 1800000.00, 1, 40, 'danang7.jpg', 4.70, 260, 0, 'Hoạt động', '2025-04-16 01:00:00', '2026-03-27 15:28:45', 1600000.00, 'Gia đình', '2026-04-26'),
(128, 'Đà Nẵng – Hải Vân Quan 2 ngày 1 đêm', 'Ngắm đèo đẹp và cảnh biển hùng vĩ', 11, 2600000.00, 2, 25, 'danang8.jpg', 4.80, 290, 1, 'Hoạt động', '2025-04-17 02:00:00', '2026-03-27 15:28:45', 2300000.00, 'Mạo hiểm', '2026-04-27'),
(129, 'Đà Nẵng – Bảo tàng Chăm 1 ngày', 'Tìm hiểu văn hóa Chăm Pa cổ', 11, 1600000.00, 1, 40, 'danang9.jpg', 4.60, 180, 0, 'Hoạt động', '2025-04-18 03:00:00', '2026-03-27 15:28:45', 1400000.00, 'Văn hoá & lịch sử', '2026-04-28'),
(130, 'Đà Nẵng – Suối khoáng Núi Thần Tài 2 ngày 1 đêm', 'Tắm khoáng nóng và nghỉ dưỡng thư giãn', 11, 3000000.00, 2, 25, 'danang10.jpg', 4.80, 310, 1, 'Hoạt động', '2025-04-19 01:00:00', '2026-03-27 15:28:45', 2700000.00, 'Nghỉ dưỡng', '2026-04-29'),
(131, 'Huế – Đại Nội 2 ngày 1 đêm', 'Tham quan kinh thành và di tích triều Nguyễn', 13, 2600000.00, 2, 30, 'hue1.jpg', 4.90, 400, 1, 'Hoạt động', '2025-04-10 01:00:00', '2026-03-27 15:28:45', 2400000.00, 'Văn hoá & lịch sử', '2026-04-20'),
(132, 'Huế – Chùa Thiên Mụ 1 ngày', 'Tham quan chùa cổ bên sông Hương', 13, 1500000.00, 1, 40, 'hue2.jpg', 4.80, 320, 0, 'Hoạt động', '2025-04-11 02:00:00', '2026-03-27 15:28:45', 1300000.00, 'Văn hoá & lịch sử', '2026-04-21'),
(133, 'Huế – Lăng Khải Định 2 ngày 1 đêm', 'Khám phá kiến trúc lăng vua độc đáo', 13, 2500000.00, 2, 25, 'hue3.jpg', 4.80, 300, 1, 'Hoạt động', '2025-04-12 03:00:00', '2026-03-27 15:28:45', 2300000.00, 'Văn hoá & lịch sử', '2026-04-22'),
(134, 'Huế – Lăng Minh Mạng 2 ngày 1 đêm', 'Tham quan lăng tẩm và cảnh quan thiên nhiên', 13, 2500000.00, 2, 25, 'hue4.jpg', 4.70, 280, 0, 'Hoạt động', '2025-04-13 01:30:00', '2026-03-27 15:28:45', 2300000.00, 'Văn hoá & lịch sử', '2026-04-23'),
(135, 'Huế – Sông Hương 2 ngày 1 đêm', 'Du thuyền và nghe ca Huế trên sông', 13, 2700000.00, 2, 30, 'hue5.jpg', 4.80, 350, 1, 'Hoạt động', '2025-04-14 02:15:00', '2026-03-27 15:28:45', 2500000.00, 'Gia đình', '2026-04-24'),
(136, 'Huế – Biển Lăng Cô 2 ngày 1 đêm', 'Tắm biển và nghỉ dưỡng cảnh đẹp', 13, 2800000.00, 2, 30, 'hue6.jpg', 4.90, 360, 1, 'Hoạt động', '2025-04-15 03:20:00', '2026-03-27 15:28:45', 2600000.00, 'Biển & Đảo', '2026-04-25'),
(137, 'Huế – Đầm Lập An 2 ngày 1 đêm', 'Ngắm hoàng hôn và cảnh đẹp yên bình', 13, 2600000.00, 2, 25, 'hue7.jpg', 4.80, 300, 0, 'Hoạt động', '2025-04-16 01:00:00', '2026-03-27 15:28:45', 2400000.00, 'Nghỉ dưỡng', '2026-04-26'),
(138, 'Huế – Vườn quốc gia Bạch Mã 3 ngày 2 đêm', 'Khám phá rừng và thác nước thiên nhiên', 13, 3300000.00, 3, 20, 'hue8.jpg', 4.90, 280, 1, 'Hoạt động', '2025-04-17 02:00:00', '2026-03-27 15:28:45', 3000000.00, 'Mạo hiểm', '2026-04-27'),
(139, 'Huế – Chợ Đông Ba 1 ngày', 'Mua sắm đặc sản và ẩm thực Huế', 13, 1600000.00, 1, 40, 'hue9.jpg', 4.60, 200, 0, 'Hoạt động', '2025-04-18 03:00:00', '2026-03-27 15:28:45', 1400000.00, 'Gia đình', '2026-04-28'),
(140, 'Huế – Cầu Trường Tiền 1 ngày', 'Check-in biểu tượng nổi tiếng xứ Huế', 13, 1500000.00, 1, 40, 'hue10.jpg', 4.70, 220, 0, 'Hoạt động', '2025-04-19 01:00:00', '2026-03-27 15:28:45', 1300000.00, 'Gia đình', '2026-04-29'),
(141, 'Quảng Bình – Phong Nha Kẻ Bàng 2 ngày 1 đêm', 'Khám phá di sản thiên nhiên thế giới nổi tiếng', 14, 2800000.00, 2, 30, 'quangbinh1.jpg', 4.90, 400, 1, 'Hoạt động', '2025-04-10 01:00:00', '2026-03-27 15:28:45', 2600000.00, 'Mạo hiểm', '2026-04-20'),
(142, 'Quảng Bình – Hang Én 2 ngày 1 đêm', 'Khám phá hang động lớn và thiên nhiên hoang sơ', 14, 3000000.00, 2, 20, 'quangbinh2.jpg', 4.90, 250, 1, 'Hoạt động', '2025-04-11 02:00:00', '2026-03-27 15:28:45', 2800000.00, 'Mạo hiểm', '2026-04-21'),
(143, 'Quảng Bình – Động Thiên Đường 2 ngày 1 đêm', 'Khám phá hang động khô dài nhất châu Á', 14, 2700000.00, 2, 25, 'quangbinh3.jpg', 4.90, 350, 1, 'Hoạt động', '2025-04-12 03:00:00', '2026-03-27 15:28:45', 2500000.00, 'Mạo hiểm', '2026-04-22'),
(144, 'Quảng Bình – Hang Sơn Đoòng 3 ngày 2 đêm', 'Chinh phục hang động lớn nhất thế giới', 14, 8000000.00, 3, 10, 'quangbinh4.jpg', 5.00, 150, 1, 'Hoạt động', '2025-04-13 01:30:00', '2026-03-27 15:28:45', 7500000.00, 'Mạo hiểm', '2026-04-23'),
(145, 'Quảng Bình – Biển Nhật Lệ 2 ngày 1 đêm', 'Tắm biển và nghỉ dưỡng bãi biển đẹp', 14, 2600000.00, 2, 30, 'quangbinh5.jpg', 4.80, 300, 0, 'Hoạt động', '2025-04-14 02:15:00', '2026-03-27 15:28:45', 2400000.00, 'Biển & Đảo', '2026-04-24'),
(146, 'Quảng Bình – Suối nước Moọc 2 ngày 1 đêm', 'Tắm suối và vui chơi giữa thiên nhiên', 14, 2500000.00, 2, 25, 'quangbinh6.jpg', 4.70, 280, 0, 'Hoạt động', '2025-04-15 03:20:00', '2026-03-27 15:28:45', 2300000.00, 'Nghỉ dưỡng', '2026-04-25'),
(147, 'Quảng Bình – Đảo Yến 2 ngày 1 đêm', 'Khám phá đảo và hệ sinh thái biển', 14, 2900000.00, 2, 20, 'quangbinh7.jpg', 4.70, 200, 0, 'Hoạt động', '2025-04-16 01:00:00', '2026-03-27 15:28:46', 2700000.00, 'Biển & Đảo', '2026-04-26'),
(148, 'Quảng Bình – Vũng Chùa Đảo Yến 2 ngày 1 đêm', 'Tham quan nơi an nghỉ Đại tướng Giáp', 14, 2600000.00, 2, 25, 'quangbinh8.jpg', 4.80, 320, 1, 'Hoạt động', '2025-04-17 02:00:00', '2026-03-27 15:28:46', 2400000.00, 'Văn hoá & lịch sử', '2026-04-27'),
(149, 'Quảng Bình – Đèo Ngang 1 ngày', 'Ngắm cảnh đèo nổi tiếng miền Trung', 14, 1500000.00, 1, 40, 'quangbinh9.jpg', 4.60, 180, 0, 'Hoạt động', '2025-04-18 03:00:00', '2026-03-27 15:28:46', 1300000.00, 'Gia đình', '2026-04-28'),
(150, 'Quảng Bình – Bãi Đá Nhảy 1 ngày', 'Check-in bãi đá độc đáo ven biển', 14, 1600000.00, 1, 40, 'quangbinh10.jpg', 4.70, 200, 0, 'Hoạt động', '2025-04-19 01:00:00', '2026-03-27 15:28:46', 1400000.00, 'Gia đình', '2026-04-29'),
(151, 'Quảng Trị – Thành cổ Quảng Trị 2 ngày 1 đêm', 'Tham quan di tích lịch sử nổi tiếng', 15, 2400000.00, 2, 30, 'quangtri1.jpg', 4.80, 300, 1, 'Hoạt động', '2025-04-10 01:00:00', '2026-03-27 15:30:35', 2200000.00, 'Văn hoá & lịch sử', '2026-05-01'),
(152, 'Quảng Trị – Nghĩa trang Trường Sơn 2 ngày 1 đêm', 'Thăm viếng và tri ân anh hùng liệt sĩ', 15, 2300000.00, 2, 30, 'quangtri2.jpg', 4.90, 320, 1, 'Hoạt động', '2025-04-11 02:00:00', '2026-03-27 15:30:35', 2100000.00, 'Văn hoá & lịch sử', '2026-05-02'),
(153, 'Quảng Trị – Nghĩa trang Đường 9 2 ngày 1 đêm', 'Tìm hiểu lịch sử và tưởng niệm liệt sĩ', 15, 2300000.00, 2, 25, 'quangtri3.jpg', 4.80, 280, 0, 'Hoạt động', '2025-04-12 03:00:00', '2026-03-27 15:30:35', 2100000.00, 'Văn hoá & lịch sử', '2026-05-03'),
(154, 'Quảng Trị – Cầu Hiền Lương 1 ngày', 'Tham quan cầu lịch sử vĩ tuyến 17', 15, 1500000.00, 1, 40, 'quangtri4.jpg', 4.70, 260, 0, 'Hoạt động', '2025-04-13 01:30:00', '2026-03-27 15:30:35', 1300000.00, 'Văn hoá & lịch sử', '2026-05-04'),
(155, 'Quảng Trị – Sông Bến Hải 1 ngày', 'Tìm hiểu lịch sử chia cắt hai miền', 15, 1500000.00, 1, 40, 'quangtri5.jpg', 4.70, 240, 0, 'Hoạt động', '2025-04-14 02:15:00', '2026-03-27 15:30:35', 1300000.00, 'Văn hoá & lịch sử', '2026-05-05'),
(156, 'Quảng Trị – Địa đạo Vịnh Mốc 2 ngày 1 đêm', 'Khám phá hệ thống địa đạo độc đáo', 15, 2500000.00, 2, 25, 'quangtri6.jpg', 4.90, 300, 1, 'Hoạt động', '2025-04-15 03:20:00', '2026-03-27 15:30:35', 2300000.00, 'Mạo hiểm', '2026-05-06'),
(157, 'Quảng Trị – Biển Cửa Tùng 2 ngày 1 đêm', 'Tắm biển và nghỉ dưỡng ven biển đẹp', 15, 2600000.00, 2, 30, 'quangtri7.jpg', 4.70, 220, 0, 'Hoạt động', '2025-04-16 01:00:00', '2026-03-27 15:30:35', 2400000.00, 'Biển & Đảo', '2026-05-07'),
(158, 'Quảng Trị – Biển Cửa Việt 2 ngày 1 đêm', 'Thư giãn và thưởng thức hải sản tươi ngon', 15, 2600000.00, 2, 30, 'quangtri8.jpg', 4.70, 210, 0, 'Hoạt động', '2025-04-17 02:00:00', '2026-03-27 15:30:35', 2400000.00, 'Biển & Đảo', '2026-05-08'),
(159, 'Quảng Trị – Nhà tù Lao Bảo 2 ngày 1 đêm', 'Tham quan di tích lịch sử thời chiến', 15, 2400000.00, 2, 25, 'quangtri9.jpg', 4.80, 230, 0, 'Hoạt động', '2025-04-18 03:00:00', '2026-03-27 15:30:35', 2200000.00, 'Văn hoá & lịch sử', '2026-05-09'),
(160, 'Quảng Trị – Khe Sanh 3 ngày 2 đêm', 'Khám phá chiến trường xưa và thiên nhiên', 15, 3200000.00, 3, 20, 'quangtri10.jpg', 4.90, 260, 1, 'Hoạt động', '2025-04-19 01:00:00', '2026-03-27 15:30:35', 2900000.00, 'Mạo hiểm', '2026-05-10'),
(161, 'Quảng Trị – Thành cổ Quảng Trị 2 ngày 1 đêm', 'Tham quan di tích lịch sử nổi tiếng', 15, 2400000.00, 2, 30, 'quangtri1.jpg', 4.80, 300, 1, 'Hoạt động', '2025-04-10 01:00:00', '2026-03-27 15:30:35', 2200000.00, 'Văn hoá & lịch sử', '2026-05-01'),
(162, 'Quảng Trị – Nghĩa trang Trường Sơn 2 ngày 1 đêm', 'Thăm viếng và tri ân anh hùng liệt sĩ', 15, 2300000.00, 2, 30, 'quangtri2.jpg', 4.90, 320, 1, 'Hoạt động', '2025-04-11 02:00:00', '2026-03-27 15:30:35', 2100000.00, 'Văn hoá & lịch sử', '2026-05-02'),
(163, 'Quảng Trị – Nghĩa trang Đường 9 2 ngày 1 đêm', 'Tìm hiểu lịch sử và tưởng niệm liệt sĩ', 15, 2300000.00, 2, 25, 'quangtri3.jpg', 4.80, 280, 0, 'Hoạt động', '2025-04-12 03:00:00', '2026-03-27 15:30:35', 2100000.00, 'Văn hoá & lịch sử', '2026-05-03'),
(164, 'Quảng Trị – Cầu Hiền Lương 1 ngày', 'Tham quan cầu lịch sử vĩ tuyến 17', 15, 1500000.00, 1, 40, 'quangtri4.jpg', 4.70, 260, 0, 'Hoạt động', '2025-04-13 01:30:00', '2026-03-27 15:30:35', 1300000.00, 'Văn hoá & lịch sử', '2026-05-04'),
(165, 'Quảng Trị – Sông Bến Hải 1 ngày', 'Tìm hiểu lịch sử chia cắt hai miền', 15, 1500000.00, 1, 40, 'quangtri5.jpg', 4.70, 240, 0, 'Hoạt động', '2025-04-14 02:15:00', '2026-03-27 15:30:35', 1300000.00, 'Văn hoá & lịch sử', '2026-05-05'),
(166, 'Quảng Trị – Địa đạo Vịnh Mốc 2 ngày 1 đêm', 'Khám phá hệ thống địa đạo độc đáo', 15, 2500000.00, 2, 25, 'quangtri6.jpg', 4.90, 300, 1, 'Hoạt động', '2025-04-15 03:20:00', '2026-03-27 15:30:35', 2300000.00, 'Mạo hiểm', '2026-05-06'),
(167, 'Quảng Trị – Biển Cửa Tùng 2 ngày 1 đêm', 'Tắm biển và nghỉ dưỡng ven biển đẹp', 15, 2600000.00, 2, 30, 'quangtri7.jpg', 4.70, 220, 0, 'Hoạt động', '2025-04-16 01:00:00', '2026-03-27 15:30:35', 2400000.00, 'Biển & Đảo', '2026-05-07'),
(168, 'Quảng Trị – Biển Cửa Việt 2 ngày 1 đêm', 'Thư giãn và thưởng thức hải sản tươi ngon', 15, 2600000.00, 2, 30, 'quangtri8.jpg', 4.70, 210, 0, 'Hoạt động', '2025-04-17 02:00:00', '2026-03-27 15:30:35', 2400000.00, 'Biển & Đảo', '2026-05-08'),
(169, 'Quảng Trị – Nhà tù Lao Bảo 2 ngày 1 đêm', 'Tham quan di tích lịch sử thời chiến', 15, 2400000.00, 2, 25, 'quangtri9.jpg', 4.80, 230, 0, 'Hoạt động', '2025-04-18 03:00:00', '2026-03-27 15:30:35', 2200000.00, 'Văn hoá & lịch sử', '2026-05-09'),
(170, 'Quảng Trị – Khe Sanh 3 ngày 2 đêm', 'Khám phá chiến trường xưa và thiên nhiên', 15, 3200000.00, 3, 20, 'quangtri10.jpg', 4.90, 260, 1, 'Hoạt động', '2025-04-19 01:00:00', '2026-03-27 15:30:35', 2900000.00, 'Mạo hiểm', '2026-05-10'),
(171, 'Quảng Ngãi – Đảo Lý Sơn 3 ngày 2 đêm', 'Khám phá đảo núi lửa và biển xanh', 16, 3500000.00, 3, 25, 'quangngai1.jpg', 4.90, 400, 1, 'Hoạt động', '2025-04-10 01:00:00', '2026-03-27 15:30:35', 3200000.00, 'Biển & Đảo', '2026-05-01'),
(172, 'Quảng Ngãi – Mũi Ba Làng An 2 ngày 1 đêm', 'Check-in ghềnh đá và biển hoang sơ đẹp', 16, 2900000.00, 2, 25, 'quangngai2.jpg', 4.80, 260, 1, 'Hoạt động', '2025-04-11 02:00:00', '2026-03-27 15:30:35', 2700000.00, 'Biển & Đảo', '2026-05-02'),
(173, 'Quảng Ngãi – Biển Mỹ Khê 2 ngày 1 đêm', 'Tắm biển và nghỉ dưỡng ven biển đẹp', 16, 2600000.00, 2, 30, 'quangngai3.jpg', 4.80, 300, 0, 'Hoạt động', '2025-04-12 03:00:00', '2026-03-27 15:30:35', 2400000.00, 'Biển & Đảo', '2026-05-03'),
(174, 'Quảng Ngãi – Sa Huỳnh 2 ngày 1 đêm', 'Khám phá bãi biển và văn hóa Sa Huỳnh', 16, 2700000.00, 2, 25, 'quangngai4.jpg', 4.70, 250, 0, 'Hoạt động', '2025-04-13 01:30:00', '2026-03-27 15:30:35', 2500000.00, 'Biển & Đảo', '2026-05-04'),
(175, 'Quảng Ngãi – Núi Thiên Ấn 2 ngày 1 đêm', 'Tham quan núi và chùa cổ nổi tiếng', 16, 2200000.00, 2, 25, 'quangngai5.jpg', 4.60, 200, 0, 'Hoạt động', '2025-04-14 02:15:00', '2026-03-27 15:30:35', 2000000.00, 'Gia đình', '2026-05-05'),
(176, 'Quảng Ngãi – Chùa Hang 2 ngày 1 đêm', 'Khám phá chùa trong hang độc đáo', 16, 2400000.00, 2, 25, 'quangngai6.jpg', 4.70, 220, 0, 'Hoạt động', '2025-04-15 03:20:00', '2026-03-27 15:30:35', 2200000.00, 'Gia đình', '2026-05-06'),
(177, 'Quảng Ngãi – Thác Trắng Minh Long 2 ngày 1 đêm', 'Khám phá thác nước và thiên nhiên đẹp', 16, 2500000.00, 2, 25, 'quangngai7.jpg', 4.80, 210, 0, 'Hoạt động', '2025-04-16 01:00:00', '2026-03-27 15:30:35', 2300000.00, 'Mạo hiểm', '2026-05-07'),
(178, 'Quảng Ngãi – Khu chứng tích Sơn Mỹ 2 ngày 1 đêm', 'Tìm hiểu lịch sử và văn hóa địa phương', 16, 2300000.00, 2, 25, 'quangngai8.jpg', 4.70, 230, 0, 'Hoạt động', '2025-04-17 02:00:00', '2026-03-27 15:30:35', 2100000.00, 'Văn hoá & lịch sử', '2026-05-08'),
(179, 'Quảng Ngãi – Đầm An Khê 2 ngày 1 đêm', 'Ngắm cảnh đầm nước và thiên nhiên yên bình', 16, 2400000.00, 2, 25, 'quangngai9.jpg', 4.60, 180, 0, 'Hoạt động', '2025-04-18 03:00:00', '2026-03-27 15:30:35', 2200000.00, 'Nghỉ dưỡng', '2026-05-09'),
(180, 'Quảng Ngãi – Cửa biển Sa Kỳ 2 ngày 1 đêm', 'Tham quan cảng biển và cảnh đẹp', 16, 2300000.00, 2, 25, 'quangngai10.jpg', 4.60, 190, 0, 'Hoạt động', '2025-04-19 01:00:00', '2026-03-27 15:30:35', 2100000.00, 'Gia đình', '2026-05-10'),
(181, 'Khánh Hòa – Nha Trang 3 ngày 2 đêm', 'Khám phá thành phố biển và ẩm thực', 17, 3500000.00, 3, 30, 'khanhhoa1.jpg', 4.90, 500, 1, 'Hoạt động', '2025-04-10 01:00:00', '2026-03-27 15:30:35', 3200000.00, 'Biển & Đảo', '2026-05-01'),
(182, 'Khánh Hòa – Viện Hải dương học Nha Trang 2 ngày 1 đêm', 'Tìm hiểu sinh vật biển và hệ sinh thái', 17, 2800000.00, 2, 25, 'khanhhoa2.jpg', 4.80, 350, 0, 'Hoạt động', '2025-04-11 02:00:00', '2026-03-27 15:30:35', 2600000.00, 'Gia đình', '2026-05-02'),
(183, 'Khánh Hòa – Hòn Mun 2 ngày 1 đêm', 'Lặn biển ngắm san hô tuyệt đẹp', 17, 3000000.00, 2, 25, 'khanhhoa3.jpg', 4.80, 400, 1, 'Hoạt động', '2025-04-12 03:00:00', '2026-03-27 15:30:35', 2700000.00, 'Biển & Đảo', '2026-05-03'),
(184, 'Khánh Hòa – Hòn Tằm 2 ngày 1 đêm', 'Nghỉ dưỡng và tắm bùn khoáng thư giãn', 17, 3100000.00, 2, 25, 'khanhhoa4.jpg', 4.80, 380, 1, 'Hoạt động', '2025-04-13 01:30:00', '2026-03-27 15:30:35', 2800000.00, 'Nghỉ dưỡng', '2026-05-04'),
(185, 'Khánh Hòa – Đảo Bình Ba 3 ngày 2 đêm', 'Khám phá đảo tôm hùm và biển xanh', 17, 3400000.00, 3, 20, 'khanhhoa5.jpg', 4.90, 420, 1, 'Hoạt động', '2025-04-14 02:15:00', '2026-03-27 15:30:35', 3100000.00, 'Biển & Đảo', '2026-05-05'),
(186, 'Khánh Hòa – Đảo Bình Hưng 2 ngày 1 đêm', 'Check-in biển trong và bãi đá đẹp', 17, 3000000.00, 2, 25, 'khanhhoa6.jpg', 4.80, 350, 0, 'Hoạt động', '2025-04-15 03:20:00', '2026-03-27 15:30:35', 2700000.00, 'Biển & Đảo', '2026-05-06'),
(187, 'Khánh Hòa – Đảo Điệp Sơn 2 ngày 1 đêm', 'Đi bộ giữa biển trên con đường cát', 17, 2900000.00, 2, 25, 'khanhhoa7.jpg', 4.80, 360, 1, 'Hoạt động', '2025-04-16 01:00:00', '2026-03-27 15:30:35', 2600000.00, 'Biển & Đảo', '2026-05-07'),
(188, 'Khánh Hòa – Tháp Bà Ponagar 2 ngày 1 đêm', 'Tham quan di tích Chăm Pa cổ', 17, 2600000.00, 2, 25, 'khanhhoa8.jpg', 4.70, 300, 0, 'Hoạt động', '2025-04-17 02:00:00', '2026-03-27 15:30:35', 2300000.00, 'Văn hoá & lịch sử', '2026-05-08'),
(189, 'Khánh Hòa – Suối Ba Hồ 2 ngày 1 đêm', 'Khám phá suối và thiên nhiên hoang sơ', 17, 2700000.00, 2, 25, 'khanhhoa9.jpg', 4.70, 280, 0, 'Hoạt động', '2025-04-18 03:00:00', '2026-03-27 15:30:35', 2400000.00, 'Mạo hiểm', '2026-05-09'),
(190, 'Khánh Hòa – Dốc Lết 2 ngày 1 đêm', 'Tắm biển và nghỉ dưỡng bãi biển đẹp', 17, 2800000.00, 2, 30, 'khanhhoa10.jpg', 4.80, 320, 0, 'Hoạt động', '2025-04-19 01:00:00', '2026-03-27 15:30:35', 2500000.00, 'Biển & Đảo', '2026-05-10'),
(191, 'Phú Yên – Gành Đá Đĩa 2 ngày 1 đêm', 'Khám phá kỳ quan đá bazan độc đáo', 18, 2600000.00, 2, 30, 'phuyen1.jpg', 4.90, 400, 1, 'Hoạt động', '2025-04-10 01:00:00', '2026-03-27 15:30:35', 2400000.00, 'Mạo hiểm', '2026-05-01'),
(192, 'Phú Yên – Mũi Điện 2 ngày 1 đêm', 'Đón bình minh đầu tiên trên đất liền', 18, 2700000.00, 2, 25, 'phuyen2.jpg', 4.90, 380, 1, 'Hoạt động', '2025-04-11 02:00:00', '2026-03-27 15:30:35', 2500000.00, 'Mạo hiểm', '2026-05-02'),
(193, 'Phú Yên – Bãi Xép 2 ngày 1 đêm', 'Check-in phim Tôi thấy hoa vàng', 18, 2500000.00, 2, 30, 'phuyen3.jpg', 4.80, 350, 0, 'Hoạt động', '2025-04-12 03:00:00', '2026-03-27 15:30:35', 2300000.00, 'Gia đình', '2026-05-03'),
(194, 'Phú Yên – Đầm Ô Loan 2 ngày 1 đêm', 'Thưởng thức hải sản và ngắm cảnh đầm', 18, 2600000.00, 2, 25, 'phuyen4.jpg', 4.70, 300, 0, 'Hoạt động', '2025-04-13 01:30:00', '2026-03-27 15:30:35', 2400000.00, 'Nghỉ dưỡng', '2026-05-04'),
(195, 'Phú Yên – Vịnh Vũng Rô 2 ngày 1 đêm', 'Khám phá vịnh biển và lịch sử tàu không số', 18, 2700000.00, 2, 25, 'phuyen5.jpg', 4.80, 320, 1, 'Hoạt động', '2025-04-14 02:15:00', '2026-03-27 15:30:35', 2500000.00, 'Biển & Đảo', '2026-05-05'),
(196, 'Phú Yên – Nhà thờ Mằng Lăng 2 ngày 1 đêm', 'Tham quan nhà thờ cổ và lịch sử', 18, 2400000.00, 2, 25, 'phuyen6.jpg', 4.70, 280, 0, 'Hoạt động', '2025-04-15 03:20:00', '2026-03-27 15:30:35', 2200000.00, 'Văn hoá & lịch sử', '2026-05-06'),
(197, 'Phú Yên – Tháp Nhạn 2 ngày 1 đêm', 'Check-in di tích Chăm Pa cổ', 18, 2400000.00, 2, 25, 'phuyen7.jpg', 4.70, 260, 0, 'Hoạt động', '2025-04-16 01:00:00', '2026-03-27 15:30:35', 2200000.00, 'Văn hoá & lịch sử', '2026-05-07'),
(198, 'Phú Yên – Hòn Yến 2 ngày 1 đêm', 'Ngắm san hô gần bờ độc đáo', 18, 2600000.00, 2, 25, 'phuyen8.jpg', 4.80, 300, 0, 'Hoạt động', '2025-04-17 02:00:00', '2026-03-27 15:30:35', 2400000.00, 'Biển & Đảo', '2026-05-08'),
(199, 'Phú Yên – Cao nguyên Vân Hòa 2 ngày 1 đêm', 'Khám phá thiên nhiên mát mẻ vùng cao', 18, 2700000.00, 2, 25, 'phuyen9.jpg', 4.80, 280, 0, 'Hoạt động', '2025-04-18 03:00:00', '2026-03-27 15:30:35', 2500000.00, 'Mạo hiểm', '2026-05-09'),
(200, 'Phú Yên – Hải đăng Gành Đèn 2 ngày 1 đêm', 'Ngắm biển và check-in cảnh đẹp hoang sơ', 18, 2500000.00, 2, 25, 'phuyen10.jpg', 4.70, 260, 0, 'Hoạt động', '2025-04-19 01:00:00', '2026-03-27 15:30:35', 2300000.00, 'Biển & Đảo', '2026-05-10'),
(201, 'Bình Định – Quy Nhơn 3 ngày 2 đêm', 'Khám phá thành phố biển và ẩm thực', 19, 3200000.00, 3, 30, 'binhdinh1.jpg', 4.90, 400, 1, 'Hoạt động', '2025-04-10 01:00:00', '2026-03-27 15:32:14', 3000000.00, 'Văn hoá & lịch sử', '2026-05-11'),
(202, 'Bình Định – Kỳ Co 2 ngày 1 đêm', 'Tắm biển và check-in nước xanh', 19, 2800000.00, 2, 25, 'binhdinh2.jpg', 4.90, 380, 1, 'Hoạt động', '2025-04-11 02:00:00', '2026-03-27 15:32:14', 2600000.00, 'Văn hoá & lịch sử', '2026-05-12'),
(203, 'Bình Định – Eo Gió 2 ngày 1 đêm', 'Ngắm biển và cảnh đẹp hùng vĩ', 19, 2700000.00, 2, 25, 'binhdinh3.jpg', 4.80, 350, 0, 'Hoạt động', '2025-04-12 03:00:00', '2026-03-27 15:32:14', 2500000.00, 'Mạo hiểm', '2026-05-13'),
(204, 'Bình Định – Hòn Khô 2 ngày 1 đêm', 'Lặn biển và ngắm san hô đẹp', 19, 2900000.00, 2, 25, 'binhdinh4.jpg', 4.80, 320, 0, 'Hoạt động', '2025-04-13 01:30:00', '2026-03-27 15:32:14', 2700000.00, 'Biển & Đảo', '2026-05-14'),
(205, 'Bình Định – Cù Lao Xanh 3 ngày 2 đêm', 'Khám phá đảo và hải đăng đẹp', 19, 3300000.00, 3, 20, 'binhdinh5.jpg', 4.90, 300, 1, 'Hoạt động', '2025-04-14 02:15:00', '2026-03-27 15:32:14', 3100000.00, 'Gia đình', '2026-05-15'),
(206, 'Bình Định – Tháp Đôi 2 ngày 1 đêm', 'Tham quan di tích Chăm Pa cổ', 19, 2500000.00, 2, 25, 'binhdinh6.jpg', 4.70, 280, 0, 'Hoạt động', '2025-04-15 03:20:00', '2026-03-27 15:32:14', 2300000.00, 'Nghỉ dưỡng', '2026-05-16'),
(207, 'Bình Định – Chùa Ông Núi 2 ngày 1 đêm', 'Tham quan tượng Phật lớn và cảnh đẹp', 19, 2600000.00, 2, 25, 'binhdinh7.jpg', 4.70, 260, 0, 'Hoạt động', '2025-04-16 01:00:00', '2026-03-27 15:32:14', 2400000.00, 'Biển & Đảo', '2026-05-17'),
(208, 'Bình Định – Bãi Xép 2 ngày 1 đêm', 'Check-in bãi biển hoang sơ đẹp', 19, 2700000.00, 2, 25, 'binhdinh8.jpg', 4.80, 300, 0, 'Hoạt động', '2025-04-17 02:00:00', '2026-03-27 15:32:14', 2500000.00, 'Mạo hiểm', '2026-05-18'),
(209, 'Bình Định – Ghềnh Ráng 2 ngày 1 đêm', 'Tham quan mộ Hàn Mặc Tử và biển', 19, 2600000.00, 2, 25, 'binhdinh9.jpg', 4.70, 270, 0, 'Hoạt động', '2025-04-18 03:00:00', '2026-03-27 15:32:14', 2400000.00, 'Văn hoá & lịch sử', '2026-05-19');
INSERT INTO `tour` (`id`, `ten`, `mo_ta`, `id_dia_diem`, `gia`, `so_ngay`, `so_nguoi_toi_da`, `url_anh_chinh`, `danh_gia`, `so_danh_gia`, `la_tour_noi_bat`, `trang_thai`, `ngay_tao`, `ngay_cap_nhat`, `gia_khuyen_mai`, `loai_tour`, `ngay_khoi_hanh`) VALUES
(210, 'Bình Định – Đầm Thị Nại 2 ngày 1 đêm', 'Ngắm cảnh đầm và thiên nhiên đẹp', 19, 2600000.00, 2, 25, 'binhdinh10.jpg', 4.70, 250, 0, 'Hoạt động', '2025-04-19 01:00:00', '2026-03-27 15:32:14', 2400000.00, 'Gia đình', '2026-05-20'),
(211, 'Đà Lạt – Hồ Xuân Hương 2 ngày 1 đêm', 'Dạo hồ và check-in trung tâm thành phố', 20, 2400000.00, 2, 30, 'dalat1.jpg', 4.80, 400, 1, 'Hoạt động', '2025-04-10 01:00:00', '2026-03-27 15:32:14', 2200000.00, 'Biển & Đảo', '2026-05-11'),
(212, 'Đà Lạt – Thung lũng Tình Yêu 2 ngày 1 đêm', 'Khám phá khu du lịch lãng mạn', 20, 2500000.00, 2, 25, 'dalat2.jpg', 4.80, 380, 0, 'Hoạt động', '2025-04-11 02:00:00', '2026-03-27 15:32:14', 2300000.00, 'Biển & Đảo', '2026-05-12'),
(213, 'Đà Lạt – Đồi chè Cầu Đất 2 ngày 1 đêm', 'Check-in đồi chè xanh bát ngát', 20, 2600000.00, 2, 25, 'dalat3.jpg', 4.90, 420, 1, 'Hoạt động', '2025-04-12 03:00:00', '2026-03-27 15:32:14', 2400000.00, 'Gia đình', '2026-05-13'),
(214, 'Đà Lạt – Langbiang 2 ngày 1 đêm', 'Chinh phục núi và ngắm toàn cảnh', 20, 2600000.00, 2, 25, 'dalat4.jpg', 4.80, 390, 0, 'Hoạt động', '2025-04-13 01:30:00', '2026-03-27 15:32:14', 2400000.00, 'Nghỉ dưỡng', '2026-05-14'),
(215, 'Đà Lạt – Thác Datanla 2 ngày 1 đêm', 'Khám phá thác và trò chơi mạo hiểm', 20, 2600000.00, 2, 25, 'dalat5.jpg', 4.80, 360, 0, 'Hoạt động', '2025-04-14 02:15:00', '2026-03-27 15:32:14', 2400000.00, 'Biển & Đảo', '2026-05-15'),
(216, 'Đà Lạt – Thác Prenn 2 ngày 1 đêm', 'Tham quan thác và thiên nhiên đẹp', 20, 2500000.00, 2, 25, 'dalat6.jpg', 4.70, 330, 0, 'Hoạt động', '2025-04-15 03:20:00', '2026-03-27 15:32:14', 2300000.00, 'Văn hoá & lịch sử', '2026-05-16'),
(217, 'Đà Lạt – Chùa Linh Phước 2 ngày 1 đêm', 'Tham quan chùa ve chai độc đáo', 20, 2400000.00, 2, 25, 'dalat7.jpg', 4.70, 300, 0, 'Hoạt động', '2025-04-16 01:00:00', '2026-03-27 15:32:14', 2200000.00, 'Văn hoá & lịch sử', '2026-05-17'),
(218, 'Đà Lạt – Nhà thờ Con Gà 2 ngày 1 đêm', 'Check-in nhà thờ cổ nổi tiếng', 20, 2400000.00, 2, 25, 'dalat8.jpg', 4.60, 280, 0, 'Hoạt động', '2025-04-17 02:00:00', '2026-03-27 15:32:14', 2200000.00, 'Biển & Đảo', '2026-05-18'),
(219, 'Đà Lạt – Hồ Tuyền Lâm 2 ngày 1 đêm', 'Ngắm hồ và nghỉ dưỡng yên bình', 20, 2600000.00, 2, 25, 'dalat9.jpg', 4.80, 340, 0, 'Hoạt động', '2025-04-18 03:00:00', '2026-03-27 15:32:14', 2400000.00, 'Mạo hiểm', '2026-05-19'),
(220, 'Đà Lạt – Đường hầm đất sét 2 ngày 1 đêm', 'Check-in kiến trúc độc đáo', 20, 2500000.00, 2, 25, 'dalat10.jpg', 4.70, 320, 0, 'Hoạt động', '2025-04-19 01:00:00', '2026-03-27 15:32:14', 2300000.00, 'Biển & Đảo', '2026-05-20'),
(221, 'Đà Lạt – Fresh Garden 2 ngày 1 đêm', 'Vườn hoa và tiểu cảnh đẹp', 20, 2500000.00, 2, 25, 'dalat11.jpg', 4.70, 300, 0, 'Hoạt động', '2025-04-20 02:00:00', '2026-03-27 15:32:14', 2300000.00, 'Mạo hiểm', '2026-05-11'),
(222, 'Đà Lạt – Puppy Farm 2 ngày 1 đêm', 'Vui chơi và check-in trang trại thú', 20, 2600000.00, 2, 25, 'dalat12.jpg', 4.80, 310, 0, 'Hoạt động', '2025-04-21 03:00:00', '2026-03-27 15:32:14', 2400000.00, 'Mạo hiểm', '2026-05-12'),
(223, 'Đà Lạt – Mongo Land 2 ngày 1 đêm', 'Check-in phong cách Mông Cổ độc đáo', 20, 2600000.00, 2, 25, 'dalat13.jpg', 4.70, 290, 0, 'Hoạt động', '2025-04-22 01:00:00', '2026-03-27 15:32:14', 2400000.00, 'Gia đình', '2026-05-13'),
(224, 'Đà Lạt – Thác Pongour 2 ngày 1 đêm', 'Khám phá thác nước lớn đẹp', 20, 2700000.00, 2, 25, 'dalat14.jpg', 4.80, 310, 0, 'Hoạt động', '2025-04-23 02:00:00', '2026-03-27 15:32:14', 2500000.00, 'Nghỉ dưỡng', '2026-05-14'),
(225, 'Đà Lạt – Thác Voi 2 ngày 1 đêm', 'Khám phá thác và chùa Linh Ẩn', 20, 2700000.00, 2, 25, 'dalat15.jpg', 4.70, 300, 0, 'Hoạt động', '2025-04-24 03:00:00', '2026-03-27 15:32:14', 2500000.00, 'Biển & Đảo', '2026-05-15'),
(226, 'Đà Lạt – Dinh Bảo Đại 2 ngày 1 đêm', 'Tham quan dinh thự vua Bảo Đại', 20, 2500000.00, 2, 25, 'dalat16.jpg', 4.60, 280, 0, 'Hoạt động', '2025-04-25 01:00:00', '2026-03-27 15:32:14', 2300000.00, 'Văn hoá & lịch sử', '2026-05-16'),
(227, 'Đà Lạt – Chợ đêm Đà Lạt 2 ngày 1 đêm', 'Khám phá ẩm thực và mua sắm', 20, 2400000.00, 2, 30, 'dalat17.jpg', 4.80, 350, 1, 'Hoạt động', '2025-04-26 02:00:00', '2026-03-27 15:32:14', 2200000.00, 'Văn hoá & lịch sử', '2026-05-17'),
(228, 'Đà Lạt – Làng Cù Lần 2 ngày 1 đêm', 'Khám phá làng và thiên nhiên rừng', 20, 2600000.00, 2, 25, 'dalat18.jpg', 4.70, 300, 0, 'Hoạt động', '2025-04-27 03:00:00', '2026-03-27 15:32:14', 2400000.00, 'Biển & Đảo', '2026-05-18'),
(229, 'Đà Lạt – Zoodoo 2 ngày 1 đêm', 'Tham quan sở thú kiểu Úc', 20, 2600000.00, 2, 25, 'dalat19.jpg', 4.70, 290, 0, 'Hoạt động', '2025-04-28 01:00:00', '2026-03-27 15:32:14', 2400000.00, 'Mạo hiểm', '2026-05-19'),
(230, 'Đà Lạt – Đỉnh Hòn Bồ 2 ngày 1 đêm', 'Săn mây và cắm trại thiên nhiên', 20, 2700000.00, 2, 20, 'dalat20.jpg', 4.90, 310, 1, 'Hoạt động', '2025-04-29 02:00:00', '2026-03-27 15:32:14', 2500000.00, 'Biển & Đảo', '2026-05-20'),
(231, 'Kon Tum – Nhà thờ Gỗ 2 ngày 1 đêm', 'Tham quan nhà thờ cổ và kiến trúc đẹp', 21, 2400000.00, 2, 25, 'kontum1.jpg', 4.80, 300, 0, 'Hoạt động', '2025-04-10 01:00:00', '2026-03-27 15:32:14', 2200000.00, 'Biển & Đảo', '2026-05-11'),
(232, 'Kon Tum – Cầu treo Kon Klor 2 ngày 1 đêm', 'Check-in cầu treo nổi tiếng Kon Tum', 21, 2500000.00, 2, 25, 'kontum2.jpg', 4.80, 280, 0, 'Hoạt động', '2025-04-11 02:00:00', '2026-03-27 15:32:14', 2300000.00, 'Gia đình', '2026-05-12'),
(233, 'Kon Tum – Măng Đen 3 ngày 2 đêm', 'Khám phá thiên nhiên và khí hậu mát mẻ', 21, 3200000.00, 3, 20, 'kontum3.jpg', 4.90, 350, 1, 'Hoạt động', '2025-04-12 03:00:00', '2026-03-27 15:32:14', 3000000.00, 'Biển & Đảo', '2026-05-13'),
(234, 'Kon Tum – Thác Pa Sỹ 2 ngày 1 đêm', 'Khám phá thác nước giữa rừng nguyên sinh', 21, 2600000.00, 2, 25, 'kontum4.jpg', 4.80, 270, 0, 'Hoạt động', '2025-04-13 01:30:00', '2026-03-27 15:32:14', 2400000.00, 'Nghỉ dưỡng', '2026-05-14'),
(235, 'Kon Tum – Hồ Đắk Ke 2 ngày 1 đêm', 'Ngắm hồ và thiên nhiên yên bình', 21, 2500000.00, 2, 25, 'kontum5.jpg', 4.70, 260, 0, 'Hoạt động', '2025-04-14 02:15:00', '2026-03-27 15:32:14', 2300000.00, 'Biển & Đảo', '2026-05-15'),
(236, 'Kon Tum – Chùa Khánh Lâm 2 ngày 1 đêm', 'Tham quan chùa và cảnh núi rừng đẹp', 21, 2400000.00, 2, 25, 'kontum6.jpg', 4.70, 250, 0, 'Hoạt động', '2025-04-15 03:20:00', '2026-03-27 15:32:14', 2200000.00, 'Biển & Đảo', '2026-05-16'),
(237, 'Kon Tum – Ngã ba Đông Dương 3 ngày 2 đêm', 'Check-in điểm tiếp giáp ba nước Đông Dương', 21, 3400000.00, 3, 20, 'kontum7.jpg', 4.90, 300, 1, 'Hoạt động', '2025-04-16 01:00:00', '2026-03-27 15:32:14', 3200000.00, 'Biển & Đảo', '2026-05-17'),
(238, 'Kon Tum – Làng Kon K’Tu 2 ngày 1 đêm', 'Trải nghiệm văn hóa dân tộc bản địa', 21, 2500000.00, 2, 25, 'kontum8.jpg', 4.80, 260, 0, 'Hoạt động', '2025-04-17 02:00:00', '2026-03-27 15:32:14', 2300000.00, 'Văn hoá & lịch sử', '2026-05-18'),
(239, 'Kon Tum – Núi Ngọc Linh 3 ngày 2 đêm', 'Khám phá núi cao và thiên nhiên hoang sơ', 21, 3600000.00, 3, 20, 'kontum9.jpg', 4.90, 280, 1, 'Hoạt động', '2025-04-18 03:00:00', '2026-03-27 15:32:14', 3300000.00, 'Mạo hiểm', '2026-05-19'),
(240, 'Kon Tum – Vườn quốc gia Chư Mom Ray 3 ngày 2 đêm', 'Khám phá hệ sinh thái rừng đa dạng', 21, 3500000.00, 3, 20, 'kontum10.jpg', 4.90, 270, 1, 'Hoạt động', '2025-04-19 01:00:00', '2026-03-27 15:32:14', 3200000.00, 'Gia đình', '2026-05-20'),
(241, 'Gia Lai – Biển Hồ T’Nưng 2 ngày 1 đêm', 'Ngắm hồ nước xanh và cảnh đẹp', 22, 2500000.00, 2, 25, 'gialai1.jpg', 4.90, 350, 1, 'Hoạt động', '2025-04-10 01:00:00', '2026-03-27 15:32:14', 2300000.00, 'Mạo hiểm', '2026-05-11'),
(242, 'Gia Lai – Núi lửa Chư Đăng Ya 2 ngày 1 đêm', 'Khám phá núi lửa đã tắt', 22, 2600000.00, 2, 25, 'gialai2.jpg', 4.80, 330, 0, 'Hoạt động', '2025-04-11 02:00:00', '2026-03-27 15:32:14', 2400000.00, 'Mạo hiểm', '2026-05-12'),
(243, 'Gia Lai – Thác Phú Cường 2 ngày 1 đêm', 'Khám phá thác nước hùng vĩ', 22, 2600000.00, 2, 25, 'gialai3.jpg', 4.80, 300, 0, 'Hoạt động', '2025-04-12 03:00:00', '2026-03-27 15:32:14', 2400000.00, 'Mạo hiểm', '2026-05-13'),
(244, 'Gia Lai – Chùa Minh Thành 2 ngày 1 đêm', 'Tham quan chùa đẹp phong cách Nhật', 22, 2400000.00, 2, 25, 'gialai4.jpg', 4.70, 280, 0, 'Hoạt động', '2025-04-13 01:30:00', '2026-03-27 15:32:14', 2200000.00, 'Mạo hiểm', '2026-05-14'),
(245, 'Gia Lai – Thủy điện Ialy 2 ngày 1 đêm', 'Tham quan công trình thủy điện lớn', 22, 2500000.00, 2, 25, 'gialai5.jpg', 4.70, 260, 0, 'Hoạt động', '2025-04-14 02:15:00', '2026-03-27 15:32:14', 2300000.00, 'Biển & Đảo', '2026-05-15'),
(246, 'Gia Lai – Hồ Ayun Hạ 2 ngày 1 đêm', 'Ngắm hồ và thiên nhiên yên bình', 22, 2500000.00, 2, 25, 'gialai6.jpg', 4.70, 250, 0, 'Hoạt động', '2025-04-15 03:20:00', '2026-03-27 15:32:14', 2300000.00, 'Nghỉ dưỡng', '2026-05-16'),
(247, 'Gia Lai – Rừng thông Hà Tam 2 ngày 1 đêm', 'Check-in rừng thông và cảnh đẹp', 22, 2600000.00, 2, 25, 'gialai7.jpg', 4.80, 270, 0, 'Hoạt động', '2025-04-16 01:00:00', '2026-03-27 15:32:14', 2400000.00, 'Biển & Đảo', '2026-05-17'),
(248, 'Gia Lai – Làng Pleiku 2 ngày 1 đêm', 'Trải nghiệm văn hóa dân tộc Tây Nguyên', 22, 2400000.00, 2, 25, 'gialai8.jpg', 4.70, 260, 0, 'Hoạt động', '2025-04-17 02:00:00', '2026-03-27 15:32:14', 2200000.00, 'Văn hoá & lịch sử', '2026-05-18'),
(249, 'Gia Lai – Núi Hàm Rồng 2 ngày 1 đêm', 'Chinh phục núi lửa và ngắm cảnh', 22, 2600000.00, 2, 25, 'gialai9.jpg', 4.80, 290, 0, 'Hoạt động', '2025-04-18 03:00:00', '2026-03-27 15:32:14', 2400000.00, 'Gia đình', '2026-05-19'),
(250, 'Gia Lai – Vườn quốc gia Kon Ka Kinh 3 ngày 2 đêm', 'Khám phá rừng và hệ sinh thái', 22, 3400000.00, 3, 20, 'gialai10.jpg', 4.90, 280, 1, 'Hoạt động', '2025-04-19 01:00:00', '2026-03-27 15:32:14', 3100000.00, 'Gia đình', '2026-05-20'),
(251, 'Đắk Lắk – Buôn Ma Thuột 2 ngày 1 đêm', 'Tham quan thành phố, bảo tàng cà phê', 23, 2500000.00, 2, 25, 'daklak1.jpg', 4.50, 120, 1, 'Hoạt động', '2026-04-14 01:00:00', '2026-04-14 01:00:00', 2300000.00, 'Văn hoá & lịch sử', '2026-04-18'),
(252, 'Đắk Lắk – Thác Dray Nur 2 ngày 1 đêm', 'Khám phá thác nước nổi tiếng Tây Nguyên', 23, 2700000.00, 2, 20, 'daklak2.jpg', 4.70, 95, 1, 'Hoạt động', '2026-04-15 02:00:00', '2026-04-15 02:00:00', 2500000.00, 'Mạo hiểm', '2026-04-20'),
(253, 'Đắk Lắk – Buôn Đôn cưỡi voi 2 ngày 1 đêm', 'Trải nghiệm cưỡi voi và văn hoá Ê Đê', 23, 3000000.00, 2, 15, 'daklak3.jpg', 4.60, 140, 1, 'Hoạt động', '2026-04-16 03:00:00', '2026-04-16 03:00:00', 2800000.00, 'Gia đình', '2026-04-22'),
(254, 'Đắk Lắk – Hồ Lắk nghỉ dưỡng 3 ngày 2 đêm', 'Nghỉ dưỡng, chèo thuyền, ngắm cảnh hồ', 23, 3200000.00, 3, 20, 'daklak4.jpg', 4.80, 110, 1, 'Hoạt động', '2026-04-17 01:30:00', '2026-04-17 01:30:00', 2900000.00, 'Nghỉ dưỡng', '2026-04-24'),
(255, 'Đắk Lắk – Văn hoá cồng chiêng 2 ngày 1 đêm', 'Giao lưu văn hoá bản địa Tây Nguyên', 23, 2200000.00, 2, 30, 'daklak5.jpg', 4.40, 80, 0, 'Hoạt động', '2026-04-18 00:45:00', '2026-04-18 00:45:00', 2000000.00, 'Văn hoá & lịch sử', '2026-04-23'),
(256, 'Đắk Lắk – Trekking Yok Đôn 3 ngày 2 đêm', 'Khám phá rừng quốc gia Yok Đôn', 23, 3500000.00, 3, 15, 'daklak6.jpg', 4.70, 70, 1, 'Hoạt động', '2026-04-20 02:15:00', '2026-04-20 02:15:00', 3200000.00, 'Mạo hiểm', '2026-04-26'),
(257, 'Đắk Lắk – Đồi cà phê trải nghiệm 2 ngày 1 đêm', 'Tham quan và thưởng thức cà phê', 23, 2100000.00, 2, 25, 'daklak7.jpg', 4.30, 60, 0, 'Hoạt động', '2026-04-22 03:10:00', '2026-04-22 03:10:00', 1900000.00, 'Gia đình', '2026-04-27'),
(258, 'Đắk Lắk – Ẩm thực Tây Nguyên 2 ngày 1 đêm', 'Thưởng thức cơm lam, gà nướng', 23, 2000000.00, 2, 30, 'daklak8.jpg', 4.50, 90, 0, 'Hoạt động', '2026-04-24 01:20:00', '2026-04-24 01:20:00', 1800000.00, 'Gia đình', '2026-04-29'),
(259, 'Đắk Lắk – Thác Gia Long 2 ngày 1 đêm', 'Check-in thác hoang sơ đẹp', 23, 2600000.00, 2, 20, 'daklak9.jpg', 4.60, 85, 0, 'Hoạt động', '2026-04-25 02:00:00', '2026-04-25 02:00:00', 2400000.00, 'Mạo hiểm', '2026-05-01'),
(260, 'Đắk Lắk – Du lịch sinh thái 3 ngày 2 đêm', 'Nghỉ dưỡng và khám phá thiên nhiên', 23, 2800000.00, 3, 20, 'daklak10.jpg', 4.70, 75, 1, 'Hoạt động', '2026-04-27 00:30:00', '2026-04-27 00:30:00', 2500000.00, 'Nghỉ dưỡng', '2026-05-04'),
(261, 'Đắk Nông – Hồ Tà Đùng 2 ngày 1 đêm', 'Tham quan Hồ Tà Đùng – vịnh Hạ Long Tây Nguyên', 24, 2600000.00, 2, 20, 'dn1.jpg', 4.60, 80, 1, 'Hoạt động', '2026-04-14 01:00:00', '2026-04-14 01:00:00', 2400000.00, 'Nghỉ dưỡng', '2026-04-18'),
(262, 'Đắk Nông – Thác Dray Sap 2 ngày 1 đêm', 'Khám phá thác Dray Sap nổi tiếng', 24, 2500000.00, 2, 25, 'dn2.jpg', 4.50, 70, 0, 'Hoạt động', '2026-04-15 01:00:00', '2026-04-15 01:00:00', 2300000.00, 'Mạo hiểm', '2026-04-20'),
(263, 'Đắk Nông – Hang động núi lửa Krông Nô 3 ngày 2 đêm', 'Khám phá hệ thống hang động núi lửa Krông Nô', 24, 3500000.00, 3, 15, 'dn3.jpg', 4.80, 90, 1, 'Hoạt động', '2026-04-16 01:00:00', '2026-04-16 01:00:00', 3200000.00, 'Mạo hiểm', '2026-04-22'),
(264, 'Đắk Nông – Thác Gia Long 2 ngày 1 đêm', 'Tham quan thác Gia Long hoang sơ', 24, 2200000.00, 2, 30, 'dn4.jpg', 4.40, 60, 0, 'Hoạt động', '2026-04-17 01:00:00', '2026-04-17 01:00:00', 2000000.00, 'Gia đình', '2026-04-23'),
(265, 'Đắk Nông – Thác Liêng Nung 2 ngày 1 đêm', 'Khám phá thác Liêng Nung giữa rừng', 24, 2300000.00, 2, 25, 'dn5.jpg', 4.50, 55, 0, 'Hoạt động', '2026-04-18 01:00:00', '2026-04-18 01:00:00', 2100000.00, 'Văn hoá & lịch sử', '2026-04-24'),
(266, 'Đắk Nông – Vườn quốc gia Tà Đùng 3 ngày 2 đêm', 'Trekking rừng tại vườn quốc gia Tà Đùng', 24, 3600000.00, 3, 15, 'dn6.jpg', 4.70, 50, 1, 'Hoạt động', '2026-04-19 01:00:00', '2026-04-19 01:00:00', 3300000.00, 'Mạo hiểm', '2026-04-25'),
(267, 'Đắk Nông – Hồ Ea Snô 2 ngày 1 đêm', 'Check-in hồ Ea Snô thơ mộng', 24, 2100000.00, 2, 20, 'dn7.jpg', 4.30, 40, 0, 'Hoạt động', '2026-04-20 01:00:00', '2026-04-20 01:00:00', 1900000.00, 'Gia đình', '2026-04-26'),
(268, 'Đắk Nông – Bon Bu Nơr 2 ngày 1 đêm', 'Tìm hiểu văn hoá người M’nông', 24, 2000000.00, 2, 25, 'dn8.jpg', 4.40, 35, 0, 'Hoạt động', '2026-04-21 01:00:00', '2026-04-21 01:00:00', 1800000.00, 'Văn hoá & lịch sử', '2026-04-27'),
(269, 'Đắk Nông – Núi lửa Nâm Kar 2 ngày 1 đêm', 'Khám phá núi lửa Nâm Kar', 24, 2400000.00, 2, 20, 'dn9.jpg', 4.50, 45, 0, 'Hoạt động', '2026-04-22 01:00:00', '2026-04-22 01:00:00', 2200000.00, 'Mạo hiểm', '2026-04-28'),
(270, 'Đắk Nông – Hồ Tây Gia Nghĩa 3 ngày 2 đêm', 'Nghỉ dưỡng tại Gia Nghĩa', 24, 2800000.00, 3, 20, 'dn10.jpg', 4.60, 50, 1, 'Hoạt động', '2026-04-23 01:00:00', '2026-04-23 01:00:00', 2500000.00, 'Nghỉ dưỡng', '2026-04-30'),
(281, 'Bình Thuận – Mũi Né 2 ngày 1 đêm', 'Du lịch biển Mũi Né', 26, 2400000.00, 2, 30, 'bt1.jpg', 4.60, 140, 1, 'Hoạt động', '2026-04-14 03:00:00', '2026-04-14 03:00:00', 2200000.00, 'Nghỉ dưỡng', '2026-04-18'),
(282, 'Bình Thuận – Đồi cát bay 2 ngày 1 đêm', 'Trượt cát tại Mũi Né', 26, 2300000.00, 2, 25, 'bt2.jpg', 4.50, 120, 1, 'Hoạt động', '2026-04-15 03:00:00', '2026-04-15 03:00:00', 2100000.00, 'Mạo hiểm', '2026-04-20'),
(283, 'Bình Thuận – Làng chài Mũi Né 2 ngày 1 đêm', 'Khám phá làng chài truyền thống', 26, 2200000.00, 2, 25, 'bt3.jpg', 4.40, 90, 0, 'Hoạt động', '2026-04-16 03:00:00', '2026-04-16 03:00:00', 2000000.00, 'Văn hoá & lịch sử', '2026-04-22'),
(284, 'Bình Thuận – Bàu Trắng 2 ngày 1 đêm', 'Check-in sa mạc Bàu Trắng', 26, 2600000.00, 2, 20, 'bt4.jpg', 4.70, 110, 1, 'Hoạt động', '2026-04-17 03:00:00', '2026-04-17 03:00:00', 2400000.00, 'Mạo hiểm', '2026-04-23'),
(285, 'Bình Thuận – Hàm Tiến 3 ngày 2 đêm', 'Nghỉ dưỡng tại biển Hàm Tiến', 26, 3200000.00, 3, 20, 'bt5.jpg', 4.80, 130, 1, 'Hoạt động', '2026-04-18 03:00:00', '2026-04-18 03:00:00', 2900000.00, 'Nghỉ dưỡng', '2026-04-24'),
(286, 'Bình Thuận – Hải đăng Kê Gà 2 ngày 1 đêm', 'Tham quan hải đăng Kê Gà', 26, 2500000.00, 2, 20, 'bt6.jpg', 4.60, 85, 0, 'Hoạt động', '2026-04-19 03:00:00', '2026-04-19 03:00:00', 2300000.00, 'Gia đình', '2026-04-25'),
(287, 'Bình Thuận – Suối Tiên 2 ngày 1 đêm', 'Khám phá suối Tiên', 26, 2100000.00, 2, 30, 'bt7.jpg', 4.50, 70, 0, 'Hoạt động', '2026-04-20 03:00:00', '2026-04-20 03:00:00', 1900000.00, 'Gia đình', '2026-04-26'),
(288, 'Bình Thuận – Tháp Chăm Poshanu 2 ngày 1 đêm', 'Tham quan di tích Chăm cổ', 26, 2200000.00, 2, 30, 'bt8.jpg', 4.60, 95, 0, 'Hoạt động', '2026-04-21 03:00:00', '2026-04-21 03:00:00', 2000000.00, 'Văn hoá & lịch sử', '2026-04-27'),
(289, 'Bình Thuận – Hòn Rơm 3 ngày 2 đêm', 'Du lịch biển Hòn Rơm', 26, 3600000.00, 3, 15, 'bt9.jpg', 4.80, 100, 1, 'Hoạt động', '2026-04-22 03:00:00', '2026-04-22 03:00:00', 3300000.00, 'Mạo hiểm', '2026-04-28'),
(290, 'Bình Thuận – Resort Mũi Né 3 ngày 2 đêm', 'Nghỉ dưỡng cao cấp tại Mũi Né', 26, 4000000.00, 3, 20, 'bt10.jpg', 4.90, 150, 1, 'Hoạt động', '2026-04-23 03:00:00', '2026-04-23 03:00:00', 3700000.00, 'Nghỉ dưỡng', '2026-04-30'),
(301, 'Phan Thiết – Mũi Né 2 ngày 1 đêm', 'Du lịch biển Mũi Né', 27, 2400000.00, 2, 30, 'pt1.jpg', 4.60, 120, 1, 'Hoạt động', '2026-04-14 01:00:00', '2026-03-27 16:17:33', 2200000.00, 'Nghỉ dưỡng', '2026-04-18'),
(302, 'Phan Thiết – Đồi cát bay 2 ngày 1 đêm', 'Trượt cát Mũi Né', 27, 2300000.00, 2, 25, 'pt2.jpg', 4.50, 100, 1, 'Hoạt động', '2026-04-14 17:00:00', '2026-03-27 16:17:33', 2100000.00, 'Mạo hiểm', '2026-04-20'),
(303, 'Phan Thiết – Bàu Trắng 2 ngày 1 đêm', 'Check-in Bàu Trắng', 27, 2600000.00, 2, 20, 'pt3.jpg', 4.70, 110, 1, 'Hoạt động', '2026-04-15 17:00:00', '2026-03-27 16:17:33', 2400000.00, 'Mạo hiểm', '2026-04-22'),
(304, 'Phan Thiết – Làng chài 2 ngày 1 đêm', 'Khám phá làng chài', 27, 2200000.00, 2, 25, 'pt4.jpg', 4.40, 80, 0, 'Hoạt động', '2026-04-16 17:00:00', '2026-03-27 16:17:33', 2000000.00, 'Văn hoá & lịch sử', '2026-04-23'),
(305, 'Phan Thiết – Suối Tiên 2 ngày 1 đêm', 'Khám phá suối Tiên', 27, 2100000.00, 2, 30, 'pt5.jpg', 4.50, 70, 0, 'Hoạt động', '2026-04-17 17:00:00', '2026-03-27 16:17:33', 1900000.00, 'Gia đình', '2026-04-24'),
(306, 'Phan Thiết – Hòn Rơm 3 ngày 2 đêm', 'Du lịch biển Hòn Rơm', 27, 3500000.00, 3, 20, 'pt6.jpg', 4.80, 130, 1, 'Hoạt động', '2026-04-18 17:00:00', '2026-03-27 16:17:33', 3200000.00, 'Nghỉ dưỡng', '2026-04-25'),
(307, 'Phan Thiết – Tháp Chăm Poshanu 2 ngày 1 đêm', 'Tham quan tháp Chăm', 27, 2200000.00, 2, 25, 'pt7.jpg', 4.60, 90, 0, 'Hoạt động', '2026-04-19 17:00:00', '2026-03-27 16:17:33', 2000000.00, 'Văn hoá & lịch sử', '2026-04-26'),
(308, 'Phan Thiết – Hải đăng Kê Gà 2 ngày 1 đêm', 'Khám phá Kê Gà', 27, 2500000.00, 2, 20, 'pt8.jpg', 4.60, 85, 0, 'Hoạt động', '2026-04-20 17:00:00', '2026-03-27 16:17:33', 2300000.00, 'Gia đình', '2026-04-27'),
(309, 'Phan Thiết – Resort cao cấp 3 ngày 2 đêm', 'Nghỉ dưỡng resort', 27, 4200000.00, 3, 20, 'pt9.jpg', 4.90, 150, 1, 'Hoạt động', '2026-04-21 17:00:00', '2026-03-27 16:17:33', 3900000.00, 'Nghỉ dưỡng', '2026-04-28'),
(310, 'Phan Thiết – Núi Tà Cú 2 ngày 1 đêm', 'Chinh phục núi Tà Cú, tham quan chùa Linh Sơn Trường Thọ', 27, 2700000.00, 2, 20, 'pt10.jpg', 4.60, 95, 0, 'Hoạt động', '2026-04-22 17:00:00', '2026-03-27 16:17:33', 2500000.00, 'Mạo hiểm', '2026-04-30'),
(311, 'Vũng Tàu – Bãi Sau 2 ngày 1 đêm', 'Tắm biển Bãi Sau', 28, 1900000.00, 2, 30, 'vt1.jpg', 4.50, 200, 1, 'Hoạt động', '2026-04-13 17:00:00', '2026-03-27 16:17:33', 1700000.00, 'Nghỉ dưỡng', '2026-04-18'),
(312, 'Vũng Tàu – Bãi Trước 2 ngày 1 đêm', 'Dạo biển Bãi Trước', 28, 1800000.00, 2, 30, 'vt2.jpg', 4.40, 180, 0, 'Hoạt động', '2026-04-14 17:00:00', '2026-03-27 16:17:33', 1600000.00, 'Gia đình', '2026-04-20'),
(313, 'Vũng Tàu – Hồ Mây 2 ngày 1 đêm', 'Khu du lịch Hồ Mây', 28, 2000000.00, 2, 25, 'vt3.jpg', 4.60, 150, 1, 'Hoạt động', '2026-04-15 17:00:00', '2026-03-27 16:17:33', 1800000.00, 'Gia đình', '2026-04-22'),
(314, 'Vũng Tàu – Tượng Chúa Kitô 2 ngày 1 đêm', 'Leo núi tượng Chúa', 28, 1700000.00, 2, 30, 'vt4.jpg', 4.50, 140, 0, 'Hoạt động', '2026-04-16 17:00:00', '2026-03-27 16:17:33', 1500000.00, 'Văn hoá & lịch sử', '2026-04-23'),
(315, 'Vũng Tàu – Hải đăng 2 ngày 1 đêm', 'Check-in hải đăng', 28, 1800000.00, 2, 25, 'vt5.jpg', 4.40, 120, 0, 'Hoạt động', '2026-04-17 17:00:00', '2026-03-27 16:17:33', 1600000.00, 'Gia đình', '2026-04-24'),
(316, 'Vũng Tàu – Long Hải 3 ngày 2 đêm', 'Biển Long Hải', 28, 3000000.00, 3, 20, 'vt6.jpg', 4.70, 130, 1, 'Hoạt động', '2026-04-18 17:00:00', '2026-03-27 16:17:33', 2700000.00, 'Nghỉ dưỡng', '2026-04-25'),
(317, 'Vũng Tàu – Hồ Tràm 3 ngày 2 đêm', 'Nghỉ dưỡng Hồ Tràm', 28, 3500000.00, 3, 20, 'vt7.jpg', 4.80, 140, 1, 'Hoạt động', '2026-04-19 17:00:00', '2026-03-27 16:17:33', 3200000.00, 'Nghỉ dưỡng', '2026-04-26'),
(318, 'Vũng Tàu – Suối nước nóng Bình Châu 2 ngày 1 đêm', 'Tắm khoáng nóng', 28, 2600000.00, 2, 25, 'vt8.jpg', 4.60, 110, 0, 'Hoạt động', '2026-04-20 17:00:00', '2026-03-27 16:17:33', 2300000.00, 'Gia đình', '2026-04-27'),
(319, 'Vũng Tàu – Đảo Gò Găng 2 ngày 1 đêm', 'Khám phá đảo', 28, 2200000.00, 2, 20, 'vt9.jpg', 4.50, 90, 0, 'Hoạt động', '2026-04-21 17:00:00', '2026-03-27 16:17:33', 2000000.00, 'Mạo hiểm', '2026-04-28'),
(320, 'Vũng Tàu – Đèo Nước Ngọt 2 ngày 1 đêm', 'Cắm trại và ngắm biển tại Đèo Nước Ngọt', 28, 2100000.00, 2, 25, 'vt10.jpg', 4.50, 110, 0, 'Hoạt động', '2026-04-22 17:00:00', '2026-03-27 16:17:33', 1900000.00, 'Gia đình', '2026-04-30'),
(321, 'TP.HCM – Địa đạo Củ Chi 1 ngày', 'Tham quan địa đạo', 29, 900000.00, 1, 30, 'hcm1.jpg', 4.60, 300, 1, 'Hoạt động', '2026-04-13 17:00:00', '2026-03-27 16:17:33', 800000.00, 'Văn hoá & lịch sử', '2026-04-18'),
(322, 'TP.HCM – Dinh Độc Lập 1 ngày', 'Tham quan lịch sử', 29, 800000.00, 1, 30, 'hcm2.jpg', 4.50, 250, 0, 'Hoạt động', '2026-04-14 17:00:00', '2026-03-27 16:17:33', 700000.00, 'Văn hoá & lịch sử', '2026-04-20'),
(323, 'TP.HCM – Nhà thờ Đức Bà 1 ngày', 'Check-in trung tâm', 29, 700000.00, 1, 30, 'hcm3.jpg', 4.40, 220, 0, 'Hoạt động', '2026-04-15 17:00:00', '2026-03-27 16:17:33', 600000.00, 'Gia đình', '2026-04-22'),
(324, 'TP.HCM – Bưu điện Thành phố 1 ngày', 'Kiến trúc cổ', 29, 700000.00, 1, 30, 'hcm4.jpg', 4.40, 200, 0, 'Hoạt động', '2026-04-16 17:00:00', '2026-03-27 16:17:33', 600000.00, 'Gia đình', '2026-04-23'),
(325, 'TP.HCM – Landmark 81 1 ngày', 'Ngắm thành phố từ trên cao', 29, 1200000.00, 1, 25, 'hcm5.jpg', 4.70, 180, 1, 'Hoạt động', '2026-04-17 17:00:00', '2026-03-27 16:17:33', 1000000.00, 'Nghỉ dưỡng', '2026-04-24'),
(326, 'TP.HCM – Chợ Bến Thành 1 ngày', 'Mua sắm đặc sản', 29, 800000.00, 1, 30, 'hcm6.jpg', 4.50, 210, 0, 'Hoạt động', '2026-04-18 17:00:00', '2026-03-27 16:17:33', 700000.00, 'Gia đình', '2026-04-25'),
(327, 'TP.HCM – Phố đi bộ Nguyễn Huệ 1 ngày', 'Dạo phố trung tâm', 29, 600000.00, 1, 30, 'hcm7.jpg', 4.30, 190, 0, 'Hoạt động', '2026-04-19 17:00:00', '2026-03-27 16:17:33', 500000.00, 'Gia đình', '2026-04-26'),
(328, 'TP.HCM – Thảo Cầm Viên 1 ngày', 'Vui chơi gia đình', 29, 700000.00, 1, 30, 'hcm8.jpg', 4.40, 170, 0, 'Hoạt động', '2026-04-20 17:00:00', '2026-03-27 16:17:33', 600000.00, 'Gia đình', '2026-04-27'),
(329, 'TP.HCM – Bitexco Skydeck 1 ngày', 'Ngắm skyline', 29, 1000000.00, 1, 25, 'hcm9.jpg', 4.60, 160, 1, 'Hoạt động', '2026-04-21 17:00:00', '2026-03-27 16:17:33', 900000.00, 'Nghỉ dưỡng', '2026-04-28'),
(330, 'TP.HCM – City tour 2 ngày 1 đêm', 'Khám phá Sài Gòn', 29, 2200000.00, 2, 20, 'hcm10.jpg', 4.70, 200, 1, 'Hoạt động', '2026-04-22 17:00:00', '2026-03-27 16:17:33', 2000000.00, 'Gia đình', '2026-04-30'),
(331, 'Cần Thơ – Chợ nổi Cái Răng 2 ngày 1 đêm', 'Trải nghiệm chợ nổi miền Tây', 30, 1800000.00, 2, 25, 'ct1.jpg', 4.60, 150, 1, 'Hoạt động', '2026-04-13 17:00:00', '2026-04-13 17:00:00', 1600000.00, 'Văn hoá & lịch sử', '2026-04-18'),
(332, 'Cần Thơ – Bến Ninh Kiều 2 ngày 1 đêm', 'Dạo bến Ninh Kiều', 30, 1700000.00, 2, 25, 'ct2.jpg', 4.50, 120, 0, 'Hoạt động', '2026-04-14 17:00:00', '2026-04-14 17:00:00', 1500000.00, 'Gia đình', '2026-04-20'),
(333, 'Cần Thơ – Nhà cổ Bình Thuỷ 2 ngày 1 đêm', 'Tham quan nhà cổ', 30, 1600000.00, 2, 20, 'ct3.jpg', 4.40, 90, 0, 'Hoạt động', '2026-04-15 17:00:00', '2026-04-15 17:00:00', 1400000.00, 'Văn hoá & lịch sử', '2026-04-22'),
(334, 'Cần Thơ – Làng du lịch Mỹ Khánh 2 ngày 1 đêm', 'Vui chơi sinh thái', 30, 1900000.00, 2, 25, 'ct4.jpg', 4.60, 110, 1, 'Hoạt động', '2026-04-16 17:00:00', '2026-04-16 17:00:00', 1700000.00, 'Gia đình', '2026-04-23'),
(335, 'Cần Thơ – Cồn Sơn 2 ngày 1 đêm', 'Du lịch cộng đồng Cồn Sơn', 30, 2000000.00, 2, 20, 'ct5.jpg', 4.70, 100, 1, 'Hoạt động', '2026-04-17 17:00:00', '2026-04-17 17:00:00', 1800000.00, 'Gia đình', '2026-04-24'),
(336, 'Cần Thơ – Thiền viện Trúc Lâm Nam Phương 2 ngày 1 đêm', 'Tham quan thiền viện', 30, 1500000.00, 2, 30, 'ct6.jpg', 4.50, 80, 0, 'Hoạt động', '2026-04-18 17:00:00', '2026-04-18 17:00:00', 1300000.00, 'Văn hoá & lịch sử', '2026-04-25'),
(337, 'Cần Thơ – Chợ đêm Tây Đô 2 ngày 1 đêm', 'Khám phá chợ đêm', 30, 1600000.00, 2, 30, 'ct7.jpg', 4.40, 85, 0, 'Hoạt động', '2026-04-19 17:00:00', '2026-04-19 17:00:00', 1400000.00, 'Gia đình', '2026-04-26'),
(338, 'Cần Thơ – Vườn trái cây 2 ngày 1 đêm', 'Trải nghiệm miệt vườn', 30, 1800000.00, 2, 25, 'ct8.jpg', 4.60, 95, 0, 'Hoạt động', '2026-04-20 17:00:00', '2026-04-20 17:00:00', 1600000.00, 'Gia đình', '2026-04-27'),
(339, 'Cần Thơ – Du thuyền sông Hậu 3 ngày 2 đêm', 'Du thuyền cao cấp', 30, 3500000.00, 3, 20, 'ct9.jpg', 4.80, 120, 1, 'Hoạt động', '2026-04-21 17:00:00', '2026-04-21 17:00:00', 3200000.00, 'Nghỉ dưỡng', '2026-04-28'),
(340, 'Cần Thơ – City tour 2 ngày 1 đêm', 'Khám phá trung tâm', 30, 2000000.00, 2, 25, 'ct10.jpg', 4.70, 110, 1, 'Hoạt động', '2026-04-22 17:00:00', '2026-04-22 17:00:00', 1800000.00, 'Gia đình', '2026-04-30'),
(341, 'An Giang – Núi Cấm 2 ngày 1 đêm', 'Chinh phục núi Cấm', 31, 2100000.00, 2, 20, 'ag1.jpg', 4.70, 130, 1, 'Hoạt động', '2026-04-13 17:00:00', '2026-04-13 17:00:00', 1900000.00, 'Mạo hiểm', '2026-04-18'),
(342, 'An Giang – Rừng tràm Trà Sư 2 ngày 1 đêm', 'Khám phá rừng tràm', 31, 2000000.00, 2, 25, 'ag2.jpg', 4.60, 120, 1, 'Hoạt động', '2026-04-14 17:00:00', '2026-04-14 17:00:00', 1800000.00, 'Sinh thái', '2026-04-20'),
(343, 'An Giang – Miếu Bà Chúa Xứ 2 ngày 1 đêm', 'Du lịch tâm linh', 31, 1800000.00, 2, 30, 'ag3.jpg', 4.50, 200, 0, 'Hoạt động', '2026-04-15 17:00:00', '2026-04-15 17:00:00', 1600000.00, 'Văn hoá & lịch sử', '2026-04-22'),
(344, 'An Giang – Núi Sam 2 ngày 1 đêm', 'Tham quan núi Sam', 31, 1700000.00, 2, 30, 'ag4.jpg', 4.40, 150, 0, 'Hoạt động', '2026-04-16 17:00:00', '2026-04-16 17:00:00', 1500000.00, 'Gia đình', '2026-04-23'),
(345, 'An Giang – Làng Chăm Châu Giang 2 ngày 1 đêm', 'Khám phá văn hoá Chăm', 31, 1900000.00, 2, 20, 'ag5.jpg', 4.60, 90, 0, 'Hoạt động', '2026-04-17 17:00:00', '2026-04-17 17:00:00', 1700000.00, 'Văn hoá & lịch sử', '2026-04-24'),
(346, 'An Giang – Hồ Tà Pạ 2 ngày 1 đêm', 'Check-in hồ Tà Pạ', 31, 2000000.00, 2, 20, 'ag6.jpg', 4.60, 95, 0, 'Hoạt động', '2026-04-18 17:00:00', '2026-04-18 17:00:00', 1800000.00, 'Gia đình', '2026-04-25'),
(347, 'An Giang – Núi Két 2 ngày 1 đêm', 'Khám phá núi Két', 31, 2100000.00, 2, 20, 'ag7.jpg', 4.50, 85, 0, 'Hoạt động', '2026-04-19 17:00:00', '2026-04-19 17:00:00', 1900000.00, 'Mạo hiểm', '2026-04-26'),
(348, 'An Giang – Chợ Tịnh Biên 2 ngày 1 đêm', 'Mua sắm biên giới', 31, 1800000.00, 2, 25, 'ag8.jpg', 4.40, 80, 0, 'Hoạt động', '2026-04-20 17:00:00', '2026-04-20 17:00:00', 1600000.00, 'Gia đình', '2026-04-27'),
(349, 'An Giang – Thất Sơn 3 ngày 2 đêm', 'Khám phá vùng Bảy Núi', 31, 3500000.00, 3, 20, 'ag9.jpg', 4.80, 100, 1, 'Hoạt động', '2026-04-21 17:00:00', '2026-04-21 17:00:00', 3200000.00, 'Mạo hiểm', '2026-04-28'),
(350, 'An Giang – City tour 2 ngày 1 đêm', 'Khám phá Long Xuyên', 31, 2200000.00, 2, 25, 'ag10.jpg', 4.70, 90, 1, 'Hoạt động', '2026-04-22 17:00:00', '2026-04-22 17:00:00', 2000000.00, 'Gia đình', '2026-04-30'),
(351, 'Đồng Tháp – Làng hoa Sa Đéc 2 ngày 1 đêm', 'Tham quan làng hoa', 32, 1700000.00, 2, 25, 'dt1.jpg', 4.60, 130, 1, 'Hoạt động', '2026-04-13 17:00:00', '2026-04-13 17:00:00', 1500000.00, 'Gia đình', '2026-04-18'),
(352, 'Đồng Tháp – Tràm Chim 2 ngày 1 đêm', 'Khám phá VQG Tràm Chim', 32, 2000000.00, 2, 20, 'dt2.jpg', 4.70, 120, 1, 'Hoạt động', '2026-04-14 17:00:00', '2026-04-14 17:00:00', 1800000.00, 'Sinh thái', '2026-04-20'),
(353, 'Đồng Tháp – Khu di tích Xẻo Quýt 2 ngày 1 đêm', 'Tham quan lịch sử', 32, 1800000.00, 2, 25, 'dt3.jpg', 4.50, 90, 0, 'Hoạt động', '2026-04-15 17:00:00', '2026-04-15 17:00:00', 1600000.00, 'Văn hoá & lịch sử', '2026-04-22'),
(354, 'Đồng Tháp – Chùa Lá Sen 2 ngày 1 đêm', 'Check-in lá sen khổng lồ', 32, 1600000.00, 2, 30, 'dt4.jpg', 4.40, 100, 0, 'Hoạt động', '2026-04-16 17:00:00', '2026-04-16 17:00:00', 1400000.00, 'Gia đình', '2026-04-23'),
(355, 'Đồng Tháp – Gáo Giồng 2 ngày 1 đêm', 'Du lịch sinh thái', 32, 1900000.00, 2, 20, 'dt5.jpg', 4.60, 95, 0, 'Hoạt động', '2026-04-17 17:00:00', '2026-04-17 17:00:00', 1700000.00, 'Sinh thái', '2026-04-24'),
(356, 'Đồng Tháp – Nhà cổ Huỳnh Thuỷ Lê 2 ngày 1 đêm', 'Kiến trúc cổ', 32, 1700000.00, 2, 25, 'dt6.jpg', 4.50, 80, 0, 'Hoạt động', '2026-04-18 17:00:00', '2026-04-18 17:00:00', 1500000.00, 'Văn hoá & lịch sử', '2026-04-25'),
(357, 'Đồng Tháp – Vườn quýt Lai Vung 2 ngày 1 đêm', 'Trải nghiệm trái cây', 32, 1800000.00, 2, 25, 'dt7.jpg', 4.60, 85, 0, 'Hoạt động', '2026-04-19 17:00:00', '2026-04-19 17:00:00', 1600000.00, 'Gia đình', '2026-04-26'),
(358, 'Đồng Tháp – Chợ Cao Lãnh 2 ngày 1 đêm', 'Ẩm thực địa phương', 32, 1500000.00, 2, 30, 'dt8.jpg', 4.40, 70, 0, 'Hoạt động', '2026-04-20 17:00:00', '2026-04-20 17:00:00', 1300000.00, 'Gia đình', '2026-04-27'),
(359, 'Đồng Tháp – Đồng sen Tháp Mười 3 ngày 2 đêm', 'Check-in mùa sen', 32, 3200000.00, 3, 20, 'dt9.jpg', 4.80, 110, 1, 'Hoạt động', '2026-04-21 17:00:00', '2026-04-21 17:00:00', 2900000.00, 'Nghỉ dưỡng', '2026-04-28'),
(360, 'Đồng Tháp – City tour 2 ngày 1 đêm', 'Khám phá Cao Lãnh', 32, 2100000.00, 2, 25, 'dt10.jpg', 4.70, 95, 1, 'Hoạt động', '2026-04-22 17:00:00', '2026-04-22 17:00:00', 1900000.00, 'Gia đình', '2026-04-30'),
(361, 'Tiền Giang – Chùa Vĩnh Tràng 2 ngày 1 đêm', 'Tham quan chùa cổ nổi tiếng', 33, 1600000.00, 2, 25, 'tg1.jpg', 4.50, 120, 1, 'Hoạt động', '2026-04-13 17:00:00', '2026-04-13 17:00:00', 1400000.00, 'Văn hoá & lịch sử', '2026-04-18'),
(362, 'Tiền Giang – Cù lao Thới Sơn 2 ngày 1 đêm', 'Du lịch miệt vườn', 33, 1700000.00, 2, 25, 'tg2.jpg', 4.60, 110, 0, 'Hoạt động', '2026-04-14 17:00:00', '2026-04-14 17:00:00', 1500000.00, 'Gia đình', '2026-04-20'),
(363, 'Tiền Giang – Chợ nổi Cái Bè 2 ngày 1 đêm', 'Trải nghiệm chợ nổi', 33, 1800000.00, 2, 20, 'tg3.jpg', 4.60, 100, 0, 'Hoạt động', '2026-04-15 17:00:00', '2026-04-15 17:00:00', 1600000.00, 'Văn hoá & lịch sử', '2026-04-22'),
(364, 'Tiền Giang – Làng cổ Đông Hòa Hiệp 2 ngày 1 đêm', 'Khám phá nhà cổ', 33, 1900000.00, 2, 20, 'tg4.jpg', 4.70, 95, 1, 'Hoạt động', '2026-04-16 17:00:00', '2026-04-16 17:00:00', 1700000.00, 'Văn hoá & lịch sử', '2026-04-23'),
(365, 'Tiền Giang – Trại rắn Đồng Tâm 2 ngày 1 đêm', 'Tham quan trung tâm nuôi rắn', 33, 1500000.00, 2, 30, 'tg5.jpg', 4.40, 80, 0, 'Hoạt động', '2026-04-17 17:00:00', '2026-04-17 17:00:00', 1300000.00, 'Gia đình', '2026-04-24'),
(366, 'Tiền Giang – Biển Tân Thành 2 ngày 1 đêm', 'Check-in biển đen', 33, 1700000.00, 2, 25, 'tg6.jpg', 4.50, 85, 0, 'Hoạt động', '2026-04-18 17:00:00', '2026-04-18 17:00:00', 1500000.00, 'Nghỉ dưỡng', '2026-04-25'),
(367, 'Tiền Giang – Vườn trái cây Cái Bè 2 ngày 1 đêm', 'Trải nghiệm hái trái', 33, 1800000.00, 2, 25, 'tg7.jpg', 4.60, 90, 0, 'Hoạt động', '2026-04-19 17:00:00', '2026-04-19 17:00:00', 1600000.00, 'Gia đình', '2026-04-26'),
(368, 'Tiền Giang – Nhà cổ Ba Đức 2 ngày 1 đêm', 'Tham quan nhà cổ', 33, 1600000.00, 2, 20, 'tg8.jpg', 4.50, 70, 0, 'Hoạt động', '2026-04-20 17:00:00', '2026-04-20 17:00:00', 1400000.00, 'Văn hoá & lịch sử', '2026-04-27'),
(369, 'Tiền Giang – Cồn Phụng 3 ngày 2 đêm', 'Du lịch sinh thái sông nước', 33, 3200000.00, 3, 20, 'tg9.jpg', 4.80, 100, 1, 'Hoạt động', '2026-04-21 17:00:00', '2026-04-21 17:00:00', 2900000.00, 'Nghỉ dưỡng', '2026-04-28'),
(370, 'Tiền Giang – Cù lao Tân Phong 2 ngày 1 đêm', 'Khám phá cù lao trái cây nổi tiếng', 33, 2000000.00, 2, 25, 'tg10_new.jpg', 4.70, 95, 1, 'Hoạt động', '2026-04-22 17:00:00', '2026-03-27 16:34:49', 1800000.00, 'Gia đình', '2026-04-30'),
(371, 'Bến Tre – Cồn Phụng 2 ngày 1 đêm', 'Du lịch sinh thái', 34, 1700000.00, 2, 25, 'bt1.jpg', 4.60, 110, 1, 'Hoạt động', '2026-04-13 17:00:00', '2026-04-13 17:00:00', 1500000.00, 'Gia đình', '2026-04-18'),
(372, 'Bến Tre – Cồn Quy 2 ngày 1 đêm', 'Khám phá miệt vườn', 34, 1800000.00, 2, 25, 'bt2.jpg', 4.50, 100, 0, 'Hoạt động', '2026-04-14 17:00:00', '2026-04-14 17:00:00', 1600000.00, 'Gia đình', '2026-04-20'),
(373, 'Bến Tre – Làng dừa 2 ngày 1 đêm', 'Trải nghiệm nghề dừa', 34, 1600000.00, 2, 25, 'bt3.jpg', 4.50, 90, 0, 'Hoạt động', '2026-04-15 17:00:00', '2026-04-15 17:00:00', 1400000.00, 'Gia đình', '2026-04-22'),
(374, 'Bến Tre – Khu du lịch Lan Vương 2 ngày 1 đêm', 'Vui chơi dân gian', 34, 1800000.00, 2, 30, 'bt4.jpg', 4.60, 95, 1, 'Hoạt động', '2026-04-16 17:00:00', '2026-04-16 17:00:00', 1600000.00, 'Gia đình', '2026-04-23'),
(375, 'Bến Tre – Sân chim Vàm Hồ 2 ngày 1 đêm', 'Xem chim tự nhiên', 34, 1700000.00, 2, 20, 'bt5.jpg', 4.60, 85, 0, 'Hoạt động', '2026-04-17 17:00:00', '2026-04-17 17:00:00', 1500000.00, 'Sinh thái', '2026-04-24'),
(376, 'Bến Tre – Cồn Ốc 2 ngày 1 đêm', 'Khám phá cồn nhỏ', 34, 1600000.00, 2, 20, 'bt6.jpg', 4.40, 70, 0, 'Hoạt động', '2026-04-18 17:00:00', '2026-04-18 17:00:00', 1400000.00, 'Gia đình', '2026-04-25'),
(377, 'Bến Tre – Biển Thạnh Phú 2 ngày 1 đêm', 'Du lịch biển', 34, 1900000.00, 2, 25, 'bt7.jpg', 4.50, 80, 0, 'Hoạt động', '2026-04-19 17:00:00', '2026-04-19 17:00:00', 1700000.00, 'Nghỉ dưỡng', '2026-04-26'),
(378, 'Bến Tre – Vườn trái cây Chợ Lách 2 ngày 1 đêm', 'Hái trái cây', 34, 1800000.00, 2, 25, 'bt8.jpg', 4.60, 85, 0, 'Hoạt động', '2026-04-20 17:00:00', '2026-04-20 17:00:00', 1600000.00, 'Gia đình', '2026-04-27'),
(379, 'Bến Tre – Du thuyền sông Hàm Luông 3 ngày 2 đêm', 'Trải nghiệm cao cấp', 34, 3400000.00, 3, 20, 'bt9.jpg', 4.80, 95, 1, 'Hoạt động', '2026-04-21 17:00:00', '2026-04-21 17:00:00', 3100000.00, 'Nghỉ dưỡng', '2026-04-28'),
(380, 'Bến Tre – Làng hoa kiểng Cái Mơn 2 ngày 1 đêm', 'Tham quan làng hoa nổi tiếng miền Tây', 34, 2000000.00, 2, 25, 'bt10_new.jpg', 4.70, 90, 1, 'Hoạt động', '2026-04-22 17:00:00', '2026-03-27 16:34:49', 1800000.00, 'Gia đình', '2026-04-30'),
(381, 'Trà Vinh – Chùa Ang 2 ngày 1 đêm', 'Chùa Khmer nổi tiếng', 35, 1600000.00, 2, 25, 'tv1.jpg', 4.50, 100, 1, 'Hoạt động', '2026-04-13 17:00:00', '2026-04-13 17:00:00', 1400000.00, 'Văn hoá & lịch sử', '2026-04-18'),
(382, 'Trà Vinh – Ao Bà Om 2 ngày 1 đêm', 'Danh thắng nổi tiếng', 35, 1700000.00, 2, 25, 'tv2.jpg', 4.60, 90, 0, 'Hoạt động', '2026-04-14 17:00:00', '2026-04-14 17:00:00', 1500000.00, 'Gia đình', '2026-04-20'),
(383, 'Trà Vinh – Biển Ba Động 2 ngày 1 đêm', 'Du lịch biển', 35, 1800000.00, 2, 20, 'tv3.jpg', 4.50, 80, 0, 'Hoạt động', '2026-04-15 17:00:00', '2026-04-15 17:00:00', 1600000.00, 'Nghỉ dưỡng', '2026-04-22'),
(384, 'Trà Vinh – Chùa Hang 2 ngày 1 đêm', 'Kiến trúc độc đáo', 35, 1600000.00, 2, 25, 'tv4.jpg', 4.40, 75, 0, 'Hoạt động', '2026-04-16 17:00:00', '2026-04-16 17:00:00', 1400000.00, 'Văn hoá & lịch sử', '2026-04-23'),
(385, 'Trà Vinh – Cồn Chim 2 ngày 1 đêm', 'Du lịch sinh thái', 35, 1800000.00, 2, 20, 'tv5.jpg', 4.60, 85, 0, 'Hoạt động', '2026-04-17 17:00:00', '2026-04-17 17:00:00', 1600000.00, 'Sinh thái', '2026-04-24'),
(386, 'Trà Vinh – Chùa Âng cổ 2 ngày 1 đêm', 'Văn hóa Khmer', 35, 1700000.00, 2, 25, 'tv6.jpg', 4.50, 70, 0, 'Hoạt động', '2026-04-18 17:00:00', '2026-04-18 17:00:00', 1500000.00, 'Văn hoá & lịch sử', '2026-04-25'),
(387, 'Trà Vinh – Bảo tàng Khmer 2 ngày 1 đêm', 'Tìm hiểu văn hóa', 35, 1600000.00, 2, 30, 'tv7.jpg', 4.40, 65, 0, 'Hoạt động', '2026-04-19 17:00:00', '2026-04-19 17:00:00', 1400000.00, 'Văn hoá & lịch sử', '2026-04-26'),
(388, 'Trà Vinh – Vườn dừa 2 ngày 1 đêm', 'Trải nghiệm nông nghiệp', 35, 1700000.00, 2, 25, 'tv8.jpg', 4.50, 70, 0, 'Hoạt động', '2026-04-20 17:00:00', '2026-04-20 17:00:00', 1500000.00, 'Gia đình', '2026-04-27'),
(389, 'Trà Vinh – Cồn Hô 3 ngày 2 đêm', 'Sinh thái sông nước', 35, 3200000.00, 3, 20, 'tv9.jpg', 4.70, 85, 1, 'Hoạt động', '2026-04-21 17:00:00', '2026-04-21 17:00:00', 2900000.00, 'Nghỉ dưỡng', '2026-04-28'),
(390, 'Trà Vinh – Chùa Nodol 2 ngày 1 đêm', 'Khám phá chùa Khmer độc đáo', 35, 2000000.00, 2, 25, 'tv10_new.jpg', 4.60, 75, 1, 'Hoạt động', '2026-04-22 17:00:00', '2026-03-27 16:34:49', 1800000.00, 'Văn hoá & lịch sử', '2026-04-30'),
(391, 'Sóc Trăng – Chùa Dơi 2 ngày 1 đêm', 'Chùa nổi tiếng', 36, 1600000.00, 2, 25, 'st1.jpg', 4.60, 110, 1, 'Hoạt động', '2026-04-13 17:00:00', '2026-04-13 17:00:00', 1400000.00, 'Văn hoá & lịch sử', '2026-04-18'),
(392, 'Sóc Trăng – Chùa Đất Sét 2 ngày 1 đêm', 'Chùa độc đáo', 36, 1700000.00, 2, 25, 'st2.jpg', 4.50, 100, 0, 'Hoạt động', '2026-04-14 17:00:00', '2026-04-14 17:00:00', 1500000.00, 'Văn hoá & lịch sử', '2026-04-20'),
(393, 'Sóc Trăng – Chùa Kh’leang 2 ngày 1 đêm', 'Di tích Khmer', 36, 1600000.00, 2, 25, 'st3.jpg', 4.40, 80, 0, 'Hoạt động', '2026-04-15 17:00:00', '2026-04-15 17:00:00', 1400000.00, 'Văn hoá & lịch sử', '2026-04-22'),
(394, 'Sóc Trăng – Biển Mỏ Ó 2 ngày 1 đêm', 'Check-in biển', 36, 1800000.00, 2, 20, 'st4.jpg', 4.50, 70, 0, 'Hoạt động', '2026-04-16 17:00:00', '2026-04-16 17:00:00', 1600000.00, 'Nghỉ dưỡng', '2026-04-23'),
(395, 'Sóc Trăng – Cồn Mỹ Phước 2 ngày 1 đêm', 'Miệt vườn', 36, 1700000.00, 2, 25, 'st5.jpg', 4.60, 75, 0, 'Hoạt động', '2026-04-17 17:00:00', '2026-04-17 17:00:00', 1500000.00, 'Gia đình', '2026-04-24'),
(396, 'Sóc Trăng – Bảo tàng Khmer 2 ngày 1 đêm', 'Văn hoá', 36, 1600000.00, 2, 25, 'st6.jpg', 4.40, 60, 0, 'Hoạt động', '2026-04-18 17:00:00', '2026-04-18 17:00:00', 1400000.00, 'Văn hoá & lịch sử', '2026-04-25'),
(397, 'Sóc Trăng – Chợ nổi Ngã Năm 2 ngày 1 đêm', 'Chợ nổi miền Tây', 36, 1800000.00, 2, 20, 'st7.jpg', 4.60, 85, 0, 'Hoạt động', '2026-04-19 17:00:00', '2026-04-19 17:00:00', 1600000.00, 'Gia đình', '2026-04-26'),
(398, 'Sóc Trăng – Vườn cò Tân Long 2 ngày 1 đêm', 'Xem cò', 36, 1700000.00, 2, 20, 'st8.jpg', 4.50, 70, 0, 'Hoạt động', '2026-04-20 17:00:00', '2026-04-20 17:00:00', 1500000.00, 'Sinh thái', '2026-04-27'),
(399, 'Sóc Trăng – Cù lao Dung 3 ngày 2 đêm', 'Sinh thái', 36, 3200000.00, 3, 20, 'st9.jpg', 4.70, 80, 1, 'Hoạt động', '2026-04-21 17:00:00', '2026-04-21 17:00:00', 2900000.00, 'Nghỉ dưỡng', '2026-04-28'),
(400, 'Sóc Trăng – Chùa Som Rong 2 ngày 1 đêm', 'Check-in tượng Phật nằm lớn', 36, 2000000.00, 2, 25, 'st10_new.jpg', 4.60, 75, 1, 'Hoạt động', '2026-04-22 17:00:00', '2026-03-27 16:34:49', 1800000.00, 'Văn hoá & lịch sử', '2026-04-30'),
(401, 'Bạc Liêu – Nhà công tử Bạc Liêu 2 ngày 1 đêm', 'Di tích nổi tiếng', 37, 1700000.00, 2, 25, 'bl1.jpg', 4.60, 120, 1, 'Hoạt động', '2026-04-13 17:00:00', '2026-04-13 17:00:00', 1500000.00, 'Văn hoá & lịch sử', '2026-04-18'),
(402, 'Bạc Liêu – Cánh đồng điện gió 2 ngày 1 đêm', 'Check-in turbine gió', 37, 1800000.00, 2, 25, 'bl2.jpg', 4.70, 110, 1, 'Hoạt động', '2026-04-14 17:00:00', '2026-04-14 17:00:00', 1600000.00, 'Gia đình', '2026-04-20'),
(403, 'Bạc Liêu – Chùa Xiêm Cán 2 ngày 1 đêm', 'Chùa Khmer đẹp', 37, 1600000.00, 2, 25, 'bl3.jpg', 4.50, 90, 0, 'Hoạt động', '2026-04-15 17:00:00', '2026-04-15 17:00:00', 1400000.00, 'Văn hoá & lịch sử', '2026-04-22'),
(404, 'Bạc Liêu – Vườn chim Bạc Liêu 2 ngày 1 đêm', 'Xem chim', 37, 1700000.00, 2, 20, 'bl4.jpg', 4.60, 85, 0, 'Hoạt động', '2026-04-16 17:00:00', '2026-04-16 17:00:00', 1500000.00, 'Sinh thái', '2026-04-23'),
(405, 'Bạc Liêu – Nhà thờ Tắc Sậy 2 ngày 1 đêm', 'Du lịch tâm linh', 37, 1600000.00, 2, 30, 'bl5.jpg', 4.50, 95, 0, 'Hoạt động', '2026-04-17 17:00:00', '2026-04-17 17:00:00', 1400000.00, 'Văn hoá & lịch sử', '2026-04-24'),
(406, 'Bạc Liêu – Khu lưu niệm Đờn ca tài tử 2 ngày 1 đêm', 'Âm nhạc dân tộc', 37, 1700000.00, 2, 25, 'bl6.jpg', 4.50, 80, 0, 'Hoạt động', '2026-04-18 17:00:00', '2026-04-18 17:00:00', 1500000.00, 'Văn hoá & lịch sử', '2026-04-25'),
(407, 'Bạc Liêu – Biển Nhà Mát 2 ngày 1 đêm', 'Du lịch biển', 37, 1800000.00, 2, 25, 'bl7.jpg', 4.60, 85, 0, 'Hoạt động', '2026-04-19 17:00:00', '2026-04-19 17:00:00', 1600000.00, 'Nghỉ dưỡng', '2026-04-26'),
(408, 'Bạc Liêu – Khu du lịch Hồ Nam 2 ngày 1 đêm', 'Sinh thái', 37, 1700000.00, 2, 20, 'bl8.jpg', 4.40, 70, 0, 'Hoạt động', '2026-04-20 17:00:00', '2026-04-20 17:00:00', 1500000.00, 'Gia đình', '2026-04-27'),
(409, 'Bạc Liêu – Cồn Én 3 ngày 2 đêm', 'Sinh thái sông nước', 37, 3200000.00, 3, 20, 'bl9.jpg', 4.70, 80, 1, 'Hoạt động', '2026-04-21 17:00:00', '2026-04-21 17:00:00', 2900000.00, 'Nghỉ dưỡng', '2026-04-28'),
(410, 'Bạc Liêu – Vườn nhãn cổ Bạc Liêu 2 ngày 1 đêm', 'Tham quan vườn nhãn trăm năm', 37, 2000000.00, 2, 25, 'bl10_new.jpg', 4.60, 75, 1, 'Hoạt động', '2026-04-22 17:00:00', '2026-03-27 16:34:49', 1800000.00, 'Sinh thái', '2026-04-30'),
(411, 'Cà Mau – Mũi Cà Mau 2 ngày 1 đêm', 'Điểm cực Nam', 38, 2000000.00, 2, 25, 'cm1.jpg', 4.80, 150, 1, 'Hoạt động', '2026-04-13 17:00:00', '2026-04-13 17:00:00', 1800000.00, 'Khám phá', '2026-04-18'),
(412, 'Cà Mau – Rừng U Minh Hạ 2 ngày 1 đêm', 'Khám phá rừng', 38, 1900000.00, 2, 20, 'cm2.jpg', 4.70, 120, 1, 'Hoạt động', '2026-04-14 17:00:00', '2026-04-14 17:00:00', 1700000.00, 'Sinh thái', '2026-04-20'),
(413, 'Cà Mau – Hòn Đá Bạc 2 ngày 1 đêm', 'Check-in đảo đá', 38, 1800000.00, 2, 25, 'cm3.jpg', 4.60, 110, 0, 'Hoạt động', '2026-04-15 17:00:00', '2026-04-15 17:00:00', 1600000.00, 'Gia đình', '2026-04-22'),
(414, 'Cà Mau – Đầm Thị Tường 2 ngày 1 đêm', 'Đầm lớn miền Tây', 38, 1700000.00, 2, 20, 'cm4.jpg', 4.50, 90, 0, 'Hoạt động', '2026-04-16 17:00:00', '2026-04-16 17:00:00', 1500000.00, 'Sinh thái', '2026-04-23'),
(415, 'Cà Mau – Sân chim Cà Mau 2 ngày 1 đêm', 'Xem chim', 38, 1600000.00, 2, 25, 'cm5.jpg', 4.40, 80, 0, 'Hoạt động', '2026-04-17 17:00:00', '2026-04-17 17:00:00', 1400000.00, 'Sinh thái', '2026-04-24'),
(416, 'Cà Mau – Hòn Khoai 2 ngày 1 đêm', 'Khám phá đảo', 38, 2100000.00, 2, 20, 'cm6.jpg', 4.70, 95, 1, 'Hoạt động', '2026-04-18 17:00:00', '2026-04-18 17:00:00', 1900000.00, 'Khám phá', '2026-04-25'),
(417, 'Cà Mau – Chợ nổi Cà Mau 2 ngày 1 đêm', 'Trải nghiệm chợ', 38, 1700000.00, 2, 25, 'cm7.jpg', 4.50, 85, 0, 'Hoạt động', '2026-04-19 17:00:00', '2026-04-19 17:00:00', 1500000.00, 'Gia đình', '2026-04-26'),
(418, 'Cà Mau – Vườn quốc gia Mũi Cà Mau 2 ngày 1 đêm', 'Sinh thái rừng ngập mặn', 38, 2000000.00, 2, 20, 'cm8.jpg', 4.80, 100, 1, 'Hoạt động', '2026-04-20 17:00:00', '2026-04-20 17:00:00', 1800000.00, 'Sinh thái', '2026-04-27'),
(419, 'Cà Mau – Đảo Hòn Chuối 3 ngày 2 đêm', 'Khám phá đảo hoang sơ', 38, 3400000.00, 3, 20, 'cm9.jpg', 4.90, 110, 1, 'Hoạt động', '2026-04-21 17:00:00', '2026-04-21 17:00:00', 3100000.00, 'Khám phá', '2026-04-28'),
(420, 'Cà Mau – Đảo Hòn Chuối 2 ngày 1 đêm', 'Khám phá đảo hoang sơ cực Nam', 38, 2100000.00, 2, 25, 'cm10_new.jpg', 4.70, 95, 1, 'Hoạt động', '2026-04-22 17:00:00', '2026-03-27 16:34:49', 1900000.00, 'Khám phá', '2026-04-30'),
(421, 'Kiên Giang – Phú Quốc Bãi Sao 2 ngày 1 đêm', 'Tắm biển đẹp nhất Phú Quốc', 39, 2500000.00, 2, 25, 'kg1.jpg', 4.80, 150, 1, 'Hoạt động', '2026-04-13 17:00:00', '2026-04-13 17:00:00', 2200000.00, 'Nghỉ dưỡng', '2026-04-18'),
(422, 'Kiên Giang – VinWonders Phú Quốc 2 ngày 1 đêm', 'Vui chơi giải trí', 39, 3000000.00, 2, 25, 'kg2.jpg', 4.70, 130, 1, 'Hoạt động', '2026-04-14 17:00:00', '2026-04-14 17:00:00', 2700000.00, 'Gia đình', '2026-04-20'),
(423, 'Kiên Giang – Hòn Thơm 2 ngày 1 đêm', 'Cáp treo vượt biển', 39, 2800000.00, 2, 20, 'kg3.jpg', 4.80, 120, 1, 'Hoạt động', '2026-04-15 17:00:00', '2026-04-15 17:00:00', 2500000.00, 'Nghỉ dưỡng', '2026-04-22'),
(424, 'Kiên Giang – Dinh Cậu 2 ngày 1 đêm', 'Biểu tượng Phú Quốc', 39, 2000000.00, 2, 25, 'kg4.jpg', 4.60, 100, 0, 'Hoạt động', '2026-04-16 17:00:00', '2026-04-16 17:00:00', 1800000.00, 'Văn hoá & lịch sử', '2026-04-23'),
(425, 'Kiên Giang – Suối Tranh 2 ngày 1 đêm', 'Sinh thái suối', 39, 2200000.00, 2, 20, 'kg5.jpg', 4.50, 90, 0, 'Hoạt động', '2026-04-17 17:00:00', '2026-04-17 17:00:00', 2000000.00, 'Sinh thái', '2026-04-24'),
(426, 'Kiên Giang – Rạch Giá 2 ngày 1 đêm', 'Khám phá biển Tây', 39, 2100000.00, 2, 25, 'kg6.jpg', 4.50, 80, 0, 'Hoạt động', '2026-04-18 17:00:00', '2026-04-18 17:00:00', 1900000.00, 'Gia đình', '2026-04-25'),
(427, 'Kiên Giang – Hà Tiên Thạch Động 2 ngày 1 đêm', 'Hang động nổi tiếng', 39, 2300000.00, 2, 20, 'kg7.jpg', 4.60, 85, 0, 'Hoạt động', '2026-04-19 17:00:00', '2026-04-19 17:00:00', 2100000.00, 'Khám phá', '2026-04-26'),
(428, 'Kiên Giang – Đảo Nam Du 3 ngày 2 đêm', 'Biển hoang sơ', 39, 3600000.00, 3, 20, 'kg8.jpg', 4.90, 110, 1, 'Hoạt động', '2026-04-20 17:00:00', '2026-04-20 17:00:00', 3300000.00, 'Nghỉ dưỡng', '2026-04-27'),
(429, 'Kiên Giang – Hòn Sơn 3 ngày 2 đêm', 'Du lịch đảo', 39, 3400000.00, 3, 20, 'kg9.jpg', 4.80, 100, 1, 'Hoạt động', '2026-04-21 17:00:00', '2026-04-21 17:00:00', 3100000.00, 'Khám phá', '2026-04-28'),
(430, 'Kiên Giang – Chùa Hang Hà Tiên 2 ngày 1 đêm', 'Tâm linh biển đảo', 39, 2200000.00, 2, 25, 'kg10.jpg', 4.60, 90, 0, 'Hoạt động', '2026-04-22 17:00:00', '2026-04-22 17:00:00', 2000000.00, 'Văn hoá & lịch sử', '2026-04-30'),
(431, 'Hà Tĩnh – Biển Thiên Cầm 2 ngày 1 đêm', 'Bãi biển đẹp', 40, 2000000.00, 2, 25, 'ht1.jpg', 4.60, 120, 1, 'Hoạt động', '2026-04-13 17:00:00', '2026-04-13 17:00:00', 1800000.00, 'Nghỉ dưỡng', '2026-04-18'),
(432, 'Hà Tĩnh – Ngã ba Đồng Lộc 2 ngày 1 đêm', 'Di tích lịch sử', 40, 1800000.00, 2, 25, 'ht2.jpg', 4.70, 140, 1, 'Hoạt động', '2026-04-14 17:00:00', '2026-04-14 17:00:00', 1600000.00, 'Văn hoá & lịch sử', '2026-04-20'),
(433, 'Hà Tĩnh – Chùa Hương Tích 2 ngày 1 đêm', 'Tâm linh', 40, 1900000.00, 2, 20, 'ht3.jpg', 4.60, 100, 0, 'Hoạt động', '2026-04-15 17:00:00', '2026-04-15 17:00:00', 1700000.00, 'Văn hoá & lịch sử', '2026-04-22'),
(434, 'Hà Tĩnh – Hồ Kẻ Gỗ 2 ngày 1 đêm', 'Sinh thái hồ', 40, 2000000.00, 2, 20, 'ht4.jpg', 4.50, 90, 0, 'Hoạt động', '2026-04-16 17:00:00', '2026-04-16 17:00:00', 1800000.00, 'Sinh thái', '2026-04-23'),
(435, 'Hà Tĩnh – Biển Xuân Thành 2 ngày 1 đêm', 'Du lịch biển', 40, 1900000.00, 2, 25, 'ht5.jpg', 4.50, 80, 0, 'Hoạt động', '2026-04-17 17:00:00', '2026-04-17 17:00:00', 1700000.00, 'Nghỉ dưỡng', '2026-04-24'),
(436, 'Hà Tĩnh – Khu lưu niệm Nguyễn Du 2 ngày 1 đêm', 'Văn học', 40, 1800000.00, 2, 25, 'ht6.jpg', 4.60, 85, 0, 'Hoạt động', '2026-04-18 17:00:00', '2026-04-18 17:00:00', 1600000.00, 'Văn hoá & lịch sử', '2026-04-25'),
(437, 'Hà Tĩnh – Thác Vũ Môn 2 ngày 1 đêm', 'Check-in thác', 40, 2100000.00, 2, 20, 'ht7.jpg', 4.60, 75, 0, 'Hoạt động', '2026-04-19 17:00:00', '2026-04-19 17:00:00', 1900000.00, 'Khám phá', '2026-04-26'),
(438, 'Hà Tĩnh – Đèo Ngang 2 ngày 1 đêm', 'Ngắm cảnh đẹp', 40, 2000000.00, 2, 25, 'ht8.jpg', 4.50, 70, 0, 'Hoạt động', '2026-04-20 17:00:00', '2026-04-20 17:00:00', 1800000.00, 'Khám phá', '2026-04-27'),
(439, 'Hà Tĩnh – Biển Kỳ Xuân 3 ngày 2 đêm', 'Nghỉ dưỡng biển', 40, 3200000.00, 3, 20, 'ht9.jpg', 4.70, 80, 1, 'Hoạt động', '2026-04-21 17:00:00', '2026-04-21 17:00:00', 2900000.00, 'Nghỉ dưỡng', '2026-04-28'),
(440, 'Hà Tĩnh – Đền Chợ Củi 2 ngày 1 đêm', 'Du lịch tâm linh', 40, 1900000.00, 2, 25, 'ht10.jpg', 4.60, 75, 0, 'Hoạt động', '2026-04-22 17:00:00', '2026-04-22 17:00:00', 1700000.00, 'Văn hoá & lịch sử', '2026-04-30'),
(441, 'Nam Định – Nhà thờ Phú Nhai 2 ngày 1 đêm', 'Nhà thờ lớn nhất VN', 41, 1800000.00, 2, 25, 'nd1.jpg', 4.70, 130, 1, 'Hoạt động', '2026-04-13 17:00:00', '2026-04-13 17:00:00', 1600000.00, 'Văn hoá & lịch sử', '2026-04-18'),
(442, 'Nam Định – Biển Thịnh Long 2 ngày 1 đêm', 'Du lịch biển', 41, 1900000.00, 2, 25, 'nd2.jpg', 4.50, 90, 0, 'Hoạt động', '2026-04-14 17:00:00', '2026-04-14 17:00:00', 1700000.00, 'Nghỉ dưỡng', '2026-04-20'),
(443, 'Nam Định – Phủ Dầy 2 ngày 1 đêm', 'Tâm linh', 41, 1800000.00, 2, 30, 'nd3.jpg', 4.60, 120, 1, 'Hoạt động', '2026-04-15 17:00:00', '2026-04-15 17:00:00', 1600000.00, 'Văn hoá & lịch sử', '2026-04-22'),
(444, 'Nam Định – Vườn quốc gia Xuân Thuỷ 2 ngày 1 đêm', 'Sinh thái Ramsar', 41, 2000000.00, 2, 20, 'nd4.jpg', 4.70, 100, 1, 'Hoạt động', '2026-04-16 17:00:00', '2026-04-16 17:00:00', 1800000.00, 'Sinh thái', '2026-04-23'),
(445, 'Nam Định – Chùa Keo Hành Thiện 2 ngày 1 đêm', 'Chùa cổ', 41, 1700000.00, 2, 25, 'nd5.jpg', 4.50, 80, 0, 'Hoạt động', '2026-04-17 17:00:00', '2026-04-17 17:00:00', 1500000.00, 'Văn hoá & lịch sử', '2026-04-24'),
(446, 'Nam Định – Đền Trần 2 ngày 1 đêm', 'Di tích lịch sử', 41, 1800000.00, 2, 30, 'nd6.jpg', 4.60, 110, 1, 'Hoạt động', '2026-04-18 17:00:00', '2026-04-18 17:00:00', 1600000.00, 'Văn hoá & lịch sử', '2026-04-25'),
(447, 'Nam Định – Biển Quất Lâm 2 ngày 1 đêm', 'Biển nổi tiếng', 41, 1900000.00, 2, 25, 'nd7.jpg', 4.50, 90, 0, 'Hoạt động', '2026-04-19 17:00:00', '2026-04-19 17:00:00', 1700000.00, 'Nghỉ dưỡng', '2026-04-26'),
(448, 'Nam Định – Làng nghề Tống Xá 2 ngày 1 đêm', 'Đúc đồng', 41, 1700000.00, 2, 20, 'nd8.jpg', 4.40, 70, 0, 'Hoạt động', '2026-04-20 17:00:00', '2026-04-20 17:00:00', 1500000.00, 'Văn hoá & lịch sử', '2026-04-27'),
(449, 'Nam Định – Hải Hậu 3 ngày 2 đêm', 'Du lịch biển', 41, 3200000.00, 3, 20, 'nd9.jpg', 4.70, 80, 1, 'Hoạt động', '2026-04-21 17:00:00', '2026-04-21 17:00:00', 2900000.00, 'Nghỉ dưỡng', '2026-04-28'),
(450, 'Nam Định – Chùa Cổ Lễ 2 ngày 1 đêm', 'Kiến trúc độc đáo', 41, 1800000.00, 2, 25, 'nd10.jpg', 4.60, 85, 0, 'Hoạt động', '2026-04-22 17:00:00', '2026-04-22 17:00:00', 1600000.00, 'Văn hoá & lịch sử', '2026-04-30'),
(451, 'Thanh Hoá – Sầm Sơn 2 ngày 1 đêm', 'Biển nổi tiếng', 42, 2000000.00, 2, 25, 'th1.jpg', 4.60, 150, 1, 'Hoạt động', '2026-04-13 17:00:00', '2026-04-13 17:00:00', 1800000.00, 'Nghỉ dưỡng', '2026-04-18'),
(452, 'Thanh Hoá – Pù Luông 2 ngày 1 đêm', 'Sinh thái núi', 42, 2300000.00, 2, 20, 'th2.jpg', 4.80, 120, 1, 'Hoạt động', '2026-04-14 17:00:00', '2026-04-14 17:00:00', 2100000.00, 'Sinh thái', '2026-04-20'),
(453, 'Thanh Hoá – Thành Nhà Hồ 2 ngày 1 đêm', 'Di sản thế giới', 42, 1900000.00, 2, 25, 'th3.jpg', 4.70, 110, 1, 'Hoạt động', '2026-04-15 17:00:00', '2026-04-15 17:00:00', 1700000.00, 'Văn hoá & lịch sử', '2026-04-22'),
(454, 'Thanh Hoá – Suối cá Cẩm Lương 2 ngày 1 đêm', 'Hiện tượng tự nhiên', 42, 1800000.00, 2, 20, 'th4.jpg', 4.60, 90, 0, 'Hoạt động', '2026-04-16 17:00:00', '2026-04-16 17:00:00', 1600000.00, 'Khám phá', '2026-04-23'),
(455, 'Thanh Hoá – Hải Tiến 2 ngày 1 đêm', 'Biển đẹp', 42, 2000000.00, 2, 25, 'th5.jpg', 4.50, 100, 0, 'Hoạt động', '2026-04-17 17:00:00', '2026-04-17 17:00:00', 1800000.00, 'Nghỉ dưỡng', '2026-04-24');
INSERT INTO `tour` (`id`, `ten`, `mo_ta`, `id_dia_diem`, `gia`, `so_ngay`, `so_nguoi_toi_da`, `url_anh_chinh`, `danh_gia`, `so_danh_gia`, `la_tour_noi_bat`, `trang_thai`, `ngay_tao`, `ngay_cap_nhat`, `gia_khuyen_mai`, `loai_tour`, `ngay_khoi_hanh`) VALUES
(456, 'Thanh Hoá – Thác Mây 2 ngày 1 đêm', 'Check-in thác', 42, 2100000.00, 2, 20, 'th6.jpg', 4.60, 80, 0, 'Hoạt động', '2026-04-18 17:00:00', '2026-04-18 17:00:00', 1900000.00, 'Khám phá', '2026-04-25'),
(457, 'Thanh Hoá – Bến En 2 ngày 1 đêm', 'Hồ sinh thái', 42, 2200000.00, 2, 20, 'th7.jpg', 4.70, 85, 0, 'Hoạt động', '2026-04-19 17:00:00', '2026-04-19 17:00:00', 2000000.00, 'Sinh thái', '2026-04-26'),
(458, 'Thanh Hoá – Lam Kinh 2 ngày 1 đêm', 'Di tích lịch sử', 42, 1800000.00, 2, 25, 'th8.jpg', 4.60, 90, 0, 'Hoạt động', '2026-04-20 17:00:00', '2026-04-20 17:00:00', 1600000.00, 'Văn hoá & lịch sử', '2026-04-27'),
(459, 'Thanh Hoá – Pù Luông 3 ngày 2 đêm', 'Nghỉ dưỡng thiên nhiên', 42, 3500000.00, 3, 20, 'th9.jpg', 4.90, 110, 1, 'Hoạt động', '2026-04-21 17:00:00', '2026-04-21 17:00:00', 3200000.00, 'Nghỉ dưỡng', '2026-04-28'),
(460, 'Thanh Hoá – Hải Hoà 2 ngày 1 đêm', 'Biển hoang sơ', 42, 2000000.00, 2, 25, 'th10.jpg', 4.50, 80, 0, 'Hoạt động', '2026-04-22 17:00:00', '2026-04-22 17:00:00', 1800000.00, 'Nghỉ dưỡng', '2026-04-30'),
(461, 'Nghệ An – Cửa Lò 2 ngày 1 đêm', 'Biển nổi tiếng', 43, 2000000.00, 2, 25, 'na1.jpg', 4.60, 150, 1, 'Hoạt động', '2026-04-13 17:00:00', '2026-04-13 17:00:00', 1800000.00, 'Nghỉ dưỡng', '2026-04-18'),
(462, 'Nghệ An – Quê Bác Kim Liên 2 ngày 1 đêm', 'Di tích lịch sử', 43, 1800000.00, 2, 25, 'na2.jpg', 4.80, 200, 1, 'Hoạt động', '2026-04-14 17:00:00', '2026-04-14 17:00:00', 1600000.00, 'Văn hoá & lịch sử', '2026-04-20'),
(463, 'Nghệ An – Pù Mát 2 ngày 1 đêm', 'Vườn quốc gia', 43, 2200000.00, 2, 20, 'na3.jpg', 4.70, 120, 1, 'Hoạt động', '2026-04-15 17:00:00', '2026-04-15 17:00:00', 2000000.00, 'Sinh thái', '2026-04-22'),
(464, 'Nghệ An – Đảo Lan Châu 2 ngày 1 đêm', 'Biển đẹp', 43, 1900000.00, 2, 25, 'na4.jpg', 4.50, 90, 0, 'Hoạt động', '2026-04-16 17:00:00', '2026-04-16 17:00:00', 1700000.00, 'Nghỉ dưỡng', '2026-04-23'),
(465, 'Nghệ An – Thác Khe Kèm 2 ngày 1 đêm', 'Check-in thác', 43, 2100000.00, 2, 20, 'na5.jpg', 4.60, 85, 0, 'Hoạt động', '2026-04-17 17:00:00', '2026-04-17 17:00:00', 1900000.00, 'Khám phá', '2026-04-24'),
(466, 'Nghệ An – Đền Cuông 2 ngày 1 đêm', 'Tâm linh', 43, 1800000.00, 2, 25, 'na6.jpg', 4.50, 80, 0, 'Hoạt động', '2026-04-18 17:00:00', '2026-04-18 17:00:00', 1600000.00, 'Văn hoá & lịch sử', '2026-04-25'),
(467, 'Nghệ An – Hang Bua 2 ngày 1 đêm', 'Khám phá hang', 43, 2000000.00, 2, 20, 'na7.jpg', 4.60, 75, 0, 'Hoạt động', '2026-04-19 17:00:00', '2026-04-19 17:00:00', 1800000.00, 'Khám phá', '2026-04-26'),
(468, 'Nghệ An – Biển Quỳnh 2 ngày 1 đêm', 'Biển hoang sơ', 43, 1900000.00, 2, 25, 'na8.jpg', 4.50, 70, 0, 'Hoạt động', '2026-04-20 17:00:00', '2026-04-20 17:00:00', 1700000.00, 'Nghỉ dưỡng', '2026-04-27'),
(469, 'Nghệ An – Đảo Hòn Ngư 3 ngày 2 đêm', 'Du lịch đảo', 43, 3300000.00, 3, 20, 'na9.jpg', 4.80, 90, 1, 'Hoạt động', '2026-04-21 17:00:00', '2026-04-21 17:00:00', 3000000.00, 'Nghỉ dưỡng', '2026-04-28'),
(470, 'Nghệ An – Thác Sao Va 2 ngày 1 đêm', 'Thác đẹp miền núi', 43, 2100000.00, 2, 20, 'na10.jpg', 4.60, 80, 0, 'Hoạt động', '2026-04-22 17:00:00', '2026-04-22 17:00:00', 1900000.00, 'Khám phá', '2026-04-30'),
(501, 'Bắc Ninh – Chùa Dâu 2 ngày 1 đêm', 'Tham quan chùa Dâu cổ kính', 44, 1800000.00, 2, 25, 'bn1.jpg', 4.50, 50, 0, 'Hoạt động', '2026-04-13 17:00:00', '2026-04-13 17:00:00', 1600000.00, 'Văn hoá & lịch sử', '2026-04-18'),
(502, 'Bắc Ninh – Chùa Bút Tháp 2 ngày 1 đêm', 'Chiêm ngưỡng tượng Quan Âm nghìn tay', 44, 1900000.00, 2, 20, 'bn2.jpg', 4.60, 55, 1, 'Hoạt động', '2026-04-14 17:00:00', '2026-04-14 17:00:00', 1700000.00, 'Văn hoá & lịch sử', '2026-04-19'),
(503, 'Bắc Ninh – Đền Đô 2 ngày 1 đêm', 'Tìm hiểu lịch sử triều Lý', 44, 1700000.00, 2, 25, 'bn3.jpg', 4.40, 45, 0, 'Hoạt động', '2026-04-15 17:00:00', '2026-04-15 17:00:00', 1500000.00, 'Văn hoá & lịch sử', '2026-04-20'),
(504, 'Bắc Ninh – Làng tranh Đông Hồ 2 ngày 1 đêm', 'Trải nghiệm làm tranh dân gian', 44, 2000000.00, 2, 20, 'bn4.jpg', 4.70, 60, 1, 'Hoạt động', '2026-04-16 17:00:00', '2026-04-16 17:00:00', 1800000.00, 'Gia đình', '2026-04-21'),
(505, 'Bắc Ninh – Chùa Phật Tích 2 ngày 1 đêm', 'Khám phá chùa cổ trên núi', 44, 1800000.00, 2, 20, 'bn5.jpg', 4.50, 40, 0, 'Hoạt động', '2026-04-17 17:00:00', '2026-04-17 17:00:00', 1600000.00, 'Tâm linh', '2026-04-22'),
(506, 'Bắc Ninh – Làng quan họ Viêm Xá 2 ngày 1 đêm', 'Nghe dân ca quan họ', 44, 2100000.00, 2, 20, 'bn6.jpg', 4.80, 70, 1, 'Hoạt động', '2026-04-18 17:00:00', '2026-04-18 17:00:00', 1900000.00, 'Văn hoá', '2026-04-23'),
(507, 'Bắc Ninh – Chùa Hàm Long 2 ngày 1 đêm', 'Tham quan chùa nổi tiếng', 44, 1700000.00, 2, 25, 'bn7.jpg', 4.30, 35, 0, 'Hoạt động', '2026-04-19 17:00:00', '2026-04-19 17:00:00', 1500000.00, 'Tâm linh', '2026-04-24'),
(508, 'Bắc Ninh – Đền Bà Chúa Kho 2 ngày 1 đêm', 'Cầu tài lộc đầu năm', 44, 1800000.00, 2, 30, 'bn8.jpg', 4.60, 80, 1, 'Hoạt động', '2026-04-20 17:00:00', '2026-04-20 17:00:00', 1600000.00, 'Tâm linh', '2026-04-25'),
(509, 'Bắc Ninh – Làng gốm Phù Lãng 2 ngày 1 đêm', 'Trải nghiệm làm gốm', 44, 2000000.00, 2, 20, 'bn9.jpg', 4.50, 50, 0, 'Hoạt động', '2026-04-21 17:00:00', '2026-04-21 17:00:00', 1800000.00, 'Trải nghiệm', '2026-04-26'),
(510, 'Bắc Ninh – Hồ Đồng Quan 2 ngày 1 đêm', 'Dã ngoại thiên nhiên', 44, 1600000.00, 2, 25, 'bn10.jpg', 4.20, 30, 0, 'Hoạt động', '2026-04-22 17:00:00', '2026-04-22 17:00:00', 1400000.00, 'Sinh thái', '2026-04-27'),
(511, 'Bắc Giang – Tây Yên Tử 3 ngày 2 đêm', 'Hành hương Tây Yên Tử', 45, 3200000.00, 3, 20, 'bg1.jpg', 4.80, 90, 1, 'Hoạt động', '2026-04-13 17:00:00', '2026-04-13 17:00:00', 2900000.00, 'Tâm linh', '2026-04-18'),
(512, 'Bắc Giang – Suối Mỡ 2 ngày 1 đêm', 'Khám phá suối Mỡ', 45, 2000000.00, 2, 25, 'bg2.jpg', 4.50, 60, 0, 'Hoạt động', '2026-04-14 17:00:00', '2026-04-14 17:00:00', 1800000.00, 'Sinh thái', '2026-04-19'),
(513, 'Bắc Giang – Hồ Khuôn Thần 2 ngày 1 đêm', 'Cắm trại hồ Khuôn Thần', 45, 2100000.00, 2, 20, 'bg3.jpg', 4.60, 55, 0, 'Hoạt động', '2026-04-15 17:00:00', '2026-04-15 17:00:00', 1900000.00, 'Sinh thái', '2026-04-20'),
(514, 'Bắc Giang – Đồng Cao 2 ngày 1 đêm', 'Check-in thảo nguyên Đồng Cao', 45, 2200000.00, 2, 20, 'bg4.jpg', 4.70, 70, 1, 'Hoạt động', '2026-04-16 17:00:00', '2026-04-16 17:00:00', 2000000.00, 'Khám phá', '2026-04-21'),
(515, 'Bắc Giang – Chùa Vĩnh Nghiêm 2 ngày 1 đêm', 'Tham quan chùa cổ', 45, 1800000.00, 2, 25, 'bg5.jpg', 4.50, 50, 0, 'Hoạt động', '2026-04-17 17:00:00', '2026-04-17 17:00:00', 1600000.00, 'Tâm linh', '2026-04-22'),
(516, 'Bắc Giang – Rừng Khe Rỗ 3 ngày 2 đêm', 'Trekking rừng nguyên sinh', 45, 3300000.00, 3, 15, 'bg6.jpg', 4.80, 60, 1, 'Hoạt động', '2026-04-18 17:00:00', '2026-04-18 17:00:00', 3000000.00, 'Mạo hiểm', '2026-04-23'),
(517, 'Bắc Giang – Hồ Cấm Sơn 2 ngày 1 đêm', 'Du lịch hồ Cấm Sơn', 45, 2100000.00, 2, 20, 'bg7.jpg', 4.40, 45, 0, 'Hoạt động', '2026-04-19 17:00:00', '2026-04-19 17:00:00', 1900000.00, 'Sinh thái', '2026-04-24'),
(518, 'Bắc Giang – Làng Thổ Hà 2 ngày 1 đêm', 'Làng nghề truyền thống', 45, 2000000.00, 2, 25, 'bg8.jpg', 4.50, 50, 0, 'Hoạt động', '2026-04-20 17:00:00', '2026-04-20 17:00:00', 1800000.00, 'Văn hoá', '2026-04-25'),
(519, 'Bắc Giang – Chùa Bổ Đà 2 ngày 1 đêm', 'Khám phá chùa cổ', 45, 1800000.00, 2, 25, 'bg9.jpg', 4.60, 55, 0, 'Hoạt động', '2026-04-21 17:00:00', '2026-04-21 17:00:00', 1600000.00, 'Tâm linh', '2026-04-26'),
(520, 'Bắc Giang – Hồ Khe Chão 2 ngày 1 đêm', 'Dã ngoại thiên nhiên', 45, 1900000.00, 2, 20, 'bg10.jpg', 4.30, 35, 0, 'Hoạt động', '2026-04-22 17:00:00', '2026-04-22 17:00:00', 1700000.00, 'Sinh thái', '2026-04-27'),
(521, 'Hoà Bình – Mai Châu 2 ngày 1 đêm', 'Khám phá bản Lác', 46, 2500000.00, 2, 30, 'hb1.jpg', 4.70, 120, 1, 'Hoạt động', '2026-04-13 17:00:00', '2026-04-13 17:00:00', 2300000.00, 'Nghỉ dưỡng', '2026-04-18'),
(522, 'Hoà Bình – Thung Nai 2 ngày 1 đêm', 'Du lịch lòng hồ sông Đà', 46, 2400000.00, 2, 25, 'hb2.jpg', 4.60, 90, 1, 'Hoạt động', '2026-04-14 17:00:00', '2026-04-14 17:00:00', 2200000.00, 'Sinh thái', '2026-04-19'),
(523, 'Hoà Bình – Hồ Hoà Bình 2 ngày 1 đêm', 'Du thuyền hồ', 46, 2300000.00, 2, 20, 'hb3.jpg', 4.50, 80, 0, 'Hoạt động', '2026-04-15 17:00:00', '2026-04-15 17:00:00', 2100000.00, 'Sinh thái', '2026-04-20'),
(524, 'Hoà Bình – Kim Bôi 2 ngày 1 đêm', 'Tắm khoáng nóng', 46, 2600000.00, 2, 25, 'hb4.jpg', 4.60, 85, 1, 'Hoạt động', '2026-04-16 17:00:00', '2026-04-16 17:00:00', 2400000.00, 'Nghỉ dưỡng', '2026-04-21'),
(525, 'Hoà Bình – Hang Kia 3 ngày 2 đêm', 'Săn mây Hang Kia', 46, 3300000.00, 3, 15, 'hb5.jpg', 4.80, 70, 1, 'Hoạt động', '2026-04-17 17:00:00', '2026-04-17 17:00:00', 3000000.00, 'Khám phá', '2026-04-22'),
(526, 'Hoà Bình – Pù Luông 3 ngày 2 đêm', 'Trekking ruộng bậc thang', 46, 3400000.00, 3, 20, 'hb6.jpg', 4.90, 95, 1, 'Hoạt động', '2026-04-18 17:00:00', '2026-04-18 17:00:00', 3100000.00, 'Mạo hiểm', '2026-04-23'),
(527, 'Hoà Bình – Bản Pom Coọng 2 ngày 1 đêm', 'Trải nghiệm văn hoá Thái', 46, 2500000.00, 2, 25, 'hb7.jpg', 4.70, 80, 0, 'Hoạt động', '2026-04-19 17:00:00', '2026-04-19 17:00:00', 2300000.00, 'Văn hoá', '2026-04-24'),
(528, 'Hoà Bình – Suối khoáng Kim Bôi 2 ngày 1 đêm', 'Thư giãn nghỉ dưỡng', 46, 2600000.00, 2, 20, 'hb8.jpg', 4.60, 70, 0, 'Hoạt động', '2026-04-20 17:00:00', '2026-04-20 17:00:00', 2400000.00, 'Nghỉ dưỡng', '2026-04-25'),
(529, 'Hoà Bình – Thác Mu 2 ngày 1 đêm', 'Khám phá thác đẹp', 46, 2200000.00, 2, 20, 'hb9.jpg', 4.50, 60, 0, 'Hoạt động', '2026-04-21 17:00:00', '2026-04-21 17:00:00', 2000000.00, 'Sinh thái', '2026-04-26'),
(530, 'Hoà Bình – Đèo Thung Khe 2 ngày 1 đêm', 'Check-in đèo đá trắng', 46, 2100000.00, 2, 25, 'hb10.jpg', 4.40, 50, 0, 'Hoạt động', '2026-04-22 17:00:00', '2026-04-22 17:00:00', 1900000.00, 'Khám phá', '2026-04-27'),
(531, 'Sơn La – Mộc Châu 2 ngày 1 đêm', 'Khám phá cao nguyên Mộc Châu', 47, 2600000.00, 2, 25, 'sl1.jpg', 4.70, 120, 1, 'Hoạt động', '2026-04-13 17:00:00', '2026-04-13 17:00:00', 2400000.00, 'Nghỉ dưỡng', '2026-04-18'),
(532, 'Sơn La – Đồi chè Mộc Châu 2 ngày 1 đêm', 'Check-in đồi chè trái tim', 47, 2400000.00, 2, 20, 'sl2.jpg', 4.60, 90, 1, 'Hoạt động', '2026-04-14 17:00:00', '2026-04-14 17:00:00', 2200000.00, 'Sinh thái', '2026-04-19'),
(533, 'Sơn La – Thác Dải Yếm 2 ngày 1 đêm', 'Tham quan thác nổi tiếng', 47, 2300000.00, 2, 25, 'sl3.jpg', 4.50, 80, 0, 'Hoạt động', '2026-04-15 17:00:00', '2026-04-15 17:00:00', 2100000.00, 'Sinh thái', '2026-04-20'),
(534, 'Sơn La – Rừng thông Bản Áng 2 ngày 1 đêm', 'Dã ngoại rừng thông', 47, 2200000.00, 2, 25, 'sl4.jpg', 4.50, 70, 0, 'Hoạt động', '2026-04-16 17:00:00', '2026-04-16 17:00:00', 2000000.00, 'Gia đình', '2026-04-21'),
(535, 'Sơn La – Ngũ động Bản Ôn 3 ngày 2 đêm', 'Khám phá hang động', 47, 3200000.00, 3, 15, 'sl5.jpg', 4.70, 60, 1, 'Hoạt động', '2026-04-17 17:00:00', '2026-04-17 17:00:00', 2900000.00, 'Mạo hiểm', '2026-04-22'),
(536, 'Sơn La – Tà Xùa 3 ngày 2 đêm', 'Săn mây Tà Xùa', 47, 3500000.00, 3, 20, 'sl6.jpg', 4.90, 100, 1, 'Hoạt động', '2026-04-18 17:00:00', '2026-04-18 17:00:00', 3200000.00, 'Khám phá', '2026-04-23'),
(537, 'Sơn La – Hang Dơi 2 ngày 1 đêm', 'Khám phá hang Dơi', 47, 2100000.00, 2, 20, 'sl7.jpg', 4.40, 50, 0, 'Hoạt động', '2026-04-19 17:00:00', '2026-04-19 17:00:00', 1900000.00, 'Khám phá', '2026-04-24'),
(538, 'Sơn La – Thung lũng mận Nà Ka 2 ngày 1 đêm', 'Check-in mùa hoa mận', 47, 2400000.00, 2, 25, 'sl8.jpg', 4.60, 75, 0, 'Hoạt động', '2026-04-20 17:00:00', '2026-04-20 17:00:00', 2200000.00, 'Sinh thái', '2026-04-25'),
(539, 'Sơn La – Đỉnh Pha Luông 3 ngày 2 đêm', 'Chinh phục đỉnh núi', 47, 3600000.00, 3, 15, 'sl9.jpg', 4.80, 65, 1, 'Hoạt động', '2026-04-21 17:00:00', '2026-04-21 17:00:00', 3300000.00, 'Mạo hiểm', '2026-04-26'),
(540, 'Sơn La – Bản Pa Phách 2 ngày 1 đêm', 'Khám phá bản làng người Mông', 47, 2200000.00, 2, 20, 'sl10.jpg', 4.50, 55, 0, 'Hoạt động', '2026-04-22 17:00:00', '2026-04-22 17:00:00', 2000000.00, 'Văn hoá', '2026-04-27'),
(541, 'Điện Biên – Mường Phăng 2 ngày 1 đêm', 'Tham quan Sở chỉ huy chiến dịch', 48, 2300000.00, 2, 25, 'db1.jpg', 4.60, 80, 1, 'Hoạt động', '2026-04-13 17:00:00', '2026-04-13 17:00:00', 2100000.00, 'Lịch sử', '2026-04-18'),
(542, 'Điện Biên – Đồi A1 2 ngày 1 đêm', 'Di tích chiến trường Điện Biên', 48, 2200000.00, 2, 25, 'db2.jpg', 4.70, 90, 1, 'Hoạt động', '2026-04-14 17:00:00', '2026-04-14 17:00:00', 2000000.00, 'Lịch sử', '2026-04-19'),
(543, 'Điện Biên – Hầm Đờ Cát 2 ngày 1 đêm', 'Khám phá hầm chỉ huy', 48, 2100000.00, 2, 20, 'db3.jpg', 4.50, 70, 0, 'Hoạt động', '2026-04-15 17:00:00', '2026-04-15 17:00:00', 1900000.00, 'Lịch sử', '2026-04-20'),
(544, 'Điện Biên – Hồ Pá Khoang 2 ngày 1 đêm', 'Du lịch sinh thái hồ', 48, 2300000.00, 2, 20, 'db4.jpg', 4.60, 60, 0, 'Hoạt động', '2026-04-16 17:00:00', '2026-04-16 17:00:00', 2100000.00, 'Sinh thái', '2026-04-21'),
(545, 'Điện Biên – Cầu Mường Thanh 2 ngày 1 đêm', 'Di tích lịch sử nổi tiếng', 48, 2000000.00, 2, 25, 'db5.jpg', 4.40, 50, 0, 'Hoạt động', '2026-04-17 17:00:00', '2026-04-17 17:00:00', 1800000.00, 'Lịch sử', '2026-04-22'),
(546, 'Điện Biên – Suối nước nóng U Va 2 ngày 1 đêm', 'Thư giãn suối khoáng', 48, 2400000.00, 2, 20, 'db6.jpg', 4.70, 75, 1, 'Hoạt động', '2026-04-18 17:00:00', '2026-04-18 17:00:00', 2200000.00, 'Nghỉ dưỡng', '2026-04-23'),
(547, 'Điện Biên – Tượng đài chiến thắng 2 ngày 1 đêm', 'Check-in biểu tượng', 48, 2100000.00, 2, 25, 'db7.jpg', 4.50, 65, 0, 'Hoạt động', '2026-04-19 17:00:00', '2026-04-19 17:00:00', 1900000.00, 'Lịch sử', '2026-04-24'),
(548, 'Điện Biên – Đèo Pha Đin 2 ngày 1 đêm', 'Chinh phục đèo hiểm trở', 48, 2500000.00, 2, 20, 'db8.jpg', 4.80, 85, 1, 'Hoạt động', '2026-04-20 17:00:00', '2026-04-20 17:00:00', 2300000.00, 'Khám phá', '2026-04-25'),
(549, 'Điện Biên – Bản Ten 2 ngày 1 đêm', 'Trải nghiệm văn hoá Thái', 48, 2200000.00, 2, 20, 'db9.jpg', 4.60, 55, 0, 'Hoạt động', '2026-04-21 17:00:00', '2026-04-21 17:00:00', 2000000.00, 'Văn hoá', '2026-04-26'),
(550, 'Điện Biên – Hang Thẩm Púa 2 ngày 1 đêm', 'Khám phá hang động', 48, 2300000.00, 2, 20, 'db10.jpg', 4.50, 50, 0, 'Hoạt động', '2026-04-22 17:00:00', '2026-04-22 17:00:00', 2100000.00, 'Khám phá', '2026-04-27'),
(551, 'Lai Châu – Đèo Ô Quy Hồ 2 ngày 1 đêm', 'Check-in đèo nổi tiếng', 49, 2600000.00, 2, 20, 'lc1.jpg', 4.80, 90, 1, 'Hoạt động', '2026-04-13 17:00:00', '2026-04-13 17:00:00', 2400000.00, 'Khám phá', '2026-04-18'),
(552, 'Lai Châu – Pu Ta Leng 3 ngày 2 đêm', 'Chinh phục đỉnh núi cao', 49, 3800000.00, 3, 15, 'lc2.jpg', 4.90, 80, 1, 'Hoạt động', '2026-04-14 17:00:00', '2026-04-14 17:00:00', 3500000.00, 'Mạo hiểm', '2026-04-19'),
(553, 'Lai Châu – Thác Tác Tình 2 ngày 1 đêm', 'Tham quan thác đẹp', 49, 2300000.00, 2, 25, 'lc3.jpg', 4.60, 60, 0, 'Hoạt động', '2026-04-15 17:00:00', '2026-04-15 17:00:00', 2100000.00, 'Sinh thái', '2026-04-20'),
(554, 'Lai Châu – Bản Sin Suối Hồ 2 ngày 1 đêm', 'Du lịch cộng đồng', 49, 2400000.00, 2, 20, 'lc4.jpg', 4.70, 65, 0, 'Hoạt động', '2026-04-16 17:00:00', '2026-04-16 17:00:00', 2200000.00, 'Văn hoá', '2026-04-21'),
(555, 'Lai Châu – Đỉnh Bạch Mộc Lương Tử 3 ngày 2 đêm', 'Leo núi mạo hiểm', 49, 3900000.00, 3, 15, 'lc5.jpg', 4.90, 75, 1, 'Hoạt động', '2026-04-17 17:00:00', '2026-04-17 17:00:00', 3600000.00, 'Mạo hiểm', '2026-04-22'),
(556, 'Lai Châu – Cao nguyên Sìn Hồ 2 ngày 1 đêm', 'Khám phá vùng cao', 49, 2500000.00, 2, 20, 'lc6.jpg', 4.60, 55, 0, 'Hoạt động', '2026-04-18 17:00:00', '2026-04-18 17:00:00', 2300000.00, 'Khám phá', '2026-04-23'),
(557, 'Lai Châu – Động Tiên Sơn 2 ngày 1 đêm', 'Khám phá hang động', 49, 2200000.00, 2, 20, 'lc7.jpg', 4.50, 50, 0, 'Hoạt động', '2026-04-19 17:00:00', '2026-04-19 17:00:00', 2000000.00, 'Khám phá', '2026-04-24'),
(558, 'Lai Châu – Hồ Thầu 2 ngày 1 đêm', 'Check-in săn mây', 49, 2300000.00, 2, 20, 'lc8.jpg', 4.70, 60, 0, 'Hoạt động', '2026-04-20 17:00:00', '2026-04-20 17:00:00', 2100000.00, 'Sinh thái', '2026-04-25'),
(559, 'Lai Châu – Bản Nậm Ló 2 ngày 1 đêm', 'Khám phá văn hoá dân tộc', 49, 2100000.00, 2, 25, 'lc9.jpg', 4.40, 45, 0, 'Hoạt động', '2026-04-21 17:00:00', '2026-04-21 17:00:00', 1900000.00, 'Văn hoá', '2026-04-26'),
(560, 'Lai Châu – Hang Pusamcap 2 ngày 1 đêm', 'Khám phá quần thể hang động', 49, 2400000.00, 2, 20, 'lc10.jpg', 4.60, 55, 0, 'Hoạt động', '2026-04-22 17:00:00', '2026-04-22 17:00:00', 2200000.00, 'Khám phá', '2026-04-27'),
(561, 'Yên Bái – Mù Cang Chải 3 ngày 2 đêm', 'Ruộng bậc thang nổi tiếng', 50, 3500000.00, 3, 20, 'yb1.jpg', 4.90, 120, 1, 'Hoạt động', '2026-04-13 17:00:00', '2026-04-13 17:00:00', 3200000.00, 'Khám phá', '2026-04-18'),
(562, 'Yên Bái – Tú Lệ 2 ngày 1 đêm', 'Khám phá cốm Tú Lệ', 50, 2400000.00, 2, 25, 'yb2.jpg', 4.60, 80, 0, 'Hoạt động', '2026-04-14 17:00:00', '2026-04-14 17:00:00', 2200000.00, 'Ẩm thực', '2026-04-19'),
(563, 'Yên Bái – Đèo Khau Phạ 2 ngày 1 đêm', 'Check-in đèo nổi tiếng', 50, 2500000.00, 2, 20, 'yb3.jpg', 4.80, 90, 1, 'Hoạt động', '2026-04-15 17:00:00', '2026-04-15 17:00:00', 2300000.00, 'Khám phá', '2026-04-20'),
(564, 'Yên Bái – Hồ Thác Bà 2 ngày 1 đêm', 'Du lịch hồ', 50, 2300000.00, 2, 25, 'yb4.jpg', 4.50, 70, 0, 'Hoạt động', '2026-04-16 17:00:00', '2026-04-16 17:00:00', 2100000.00, 'Sinh thái', '2026-04-21'),
(565, 'Yên Bái – Suối Giàng 2 ngày 1 đêm', 'Tham quan chè cổ thụ', 50, 2400000.00, 2, 20, 'yb5.jpg', 4.60, 75, 0, 'Hoạt động', '2026-04-17 17:00:00', '2026-04-17 17:00:00', 2200000.00, 'Sinh thái', '2026-04-22'),
(566, 'Yên Bái – Bản Lìm Mông 2 ngày 1 đêm', 'Khám phá bản làng', 50, 2200000.00, 2, 20, 'yb6.jpg', 4.50, 60, 0, 'Hoạt động', '2026-04-18 17:00:00', '2026-04-18 17:00:00', 2000000.00, 'Văn hoá', '2026-04-23'),
(567, 'Yên Bái – Thác Háng Tề Chơ 3 ngày 2 đêm', 'Khám phá thác hùng vĩ', 50, 3600000.00, 3, 15, 'yb7.jpg', 4.80, 65, 1, 'Hoạt động', '2026-04-19 17:00:00', '2026-04-19 17:00:00', 3300000.00, 'Mạo hiểm', '2026-04-24'),
(568, 'Yên Bái – Bản Thái Nghĩa Lộ 2 ngày 1 đêm', 'Trải nghiệm văn hoá Thái', 50, 2300000.00, 2, 25, 'yb8.jpg', 4.60, 70, 0, 'Hoạt động', '2026-04-20 17:00:00', '2026-04-20 17:00:00', 2100000.00, 'Văn hoá', '2026-04-25'),
(569, 'Yên Bái – Đỉnh Tà Chì Nhù 3 ngày 2 đêm', 'Chinh phục đỉnh núi', 50, 3700000.00, 3, 15, 'yb9.jpg', 4.90, 80, 1, 'Hoạt động', '2026-04-21 17:00:00', '2026-04-21 17:00:00', 3400000.00, 'Mạo hiểm', '2026-04-26'),
(570, 'Yên Bái – Cánh đồng Mường Lò 2 ngày 1 đêm', 'Khám phá cánh đồng lớn', 50, 2200000.00, 2, 25, 'yb10.jpg', 4.50, 60, 0, 'Hoạt động', '2026-04-22 17:00:00', '2026-04-22 17:00:00', 2000000.00, 'Sinh thái', '2026-04-27'),
(571, 'Đà Lạt – Hồ Tuyền Lâm nghỉ dưỡng 3 ngày 2 đêm', 'Resort ven hồ, thư giãn và chèo thuyền', 20, 7500000.00, 3, 20, 'dalat21.jpg', 4.90, 250, 1, 'Hoạt động', '2026-04-09 17:00:00', '2026-04-09 17:00:00', 7000000.00, 'Nghỉ dưỡng', '2026-04-30'),
(572, 'Đà Lạt – Langbiang & Resort cao cấp 3 ngày 2 đêm', 'Nghỉ dưỡng kết hợp ngắm núi và săn mây', 20, 8200000.00, 3, 20, 'dalat22.jpg', 4.90, 230, 1, 'Hoạt động', '2026-04-09 17:00:00', '2026-04-09 17:00:00', 7800000.00, 'Nghỉ dưỡng', '2026-04-30'),
(573, 'Đà Lạt – Hồ Xuân Hương & Spa 3 ngày 2 đêm', 'Nghỉ dưỡng trung tâm, spa thư giãn', 20, 6800000.00, 3, 25, 'dalat23.jpg', 4.80, 260, 0, 'Hoạt động', '2026-04-09 17:00:00', '2026-04-09 17:00:00', 6500000.00, 'Nghỉ dưỡng', '2026-04-30'),
(574, 'Đà Lạt – Resort đồi chè Cầu Đất 3 ngày 2 đêm', 'Không gian xanh, nghỉ dưỡng yên tĩnh', 20, 9000000.00, 3, 20, 'dalat24.jpg', 4.90, 200, 1, 'Hoạt động', '2026-04-09 17:00:00', '2026-04-09 17:00:00', 8500000.00, 'Nghỉ dưỡng', '2026-04-30'),
(575, 'Đà Lạt – Thung lũng Tình Yêu & Resort 3 ngày 2 đêm', 'Không gian lãng mạn, nghỉ dưỡng cao cấp', 20, 7200000.00, 3, 25, 'dalat25.jpg', 4.80, 240, 0, 'Không hoạt động', '2026-04-09 17:00:00', '2026-04-27 03:45:51', 6800000.00, 'Nghỉ dưỡng', '2026-04-30'),
(576, 'Đà Lạt – Hồ Tuyền Lâm & Golf Resort 3 ngày 2 đêm', '“Tour Đà Lạt – Hồ Tuyền Lâm & Golf Resort 3N2Đ” đưa du khách đến thành phố ngàn hoa, nghỉ dưỡng tại resort ven hồ Tuyền Lâm, kết hợp trải nghiệm sân golf giữa rừng thông và tham quan các điểm nổi tiếng như Thiền viện Trúc Lâm, vườn hoa thành phố, chợ đêm Đà Lạt.', 20, 9800000.00, 3, 15, 'dalat26.jpg', 5.00, 180, 1, 'Hoạt động', '2026-04-09 17:00:00', '2026-03-30 11:51:49', 9200000.00, 'Nghỉ dưỡng', '2026-04-30'),
(577, 'Đà Lạt – Làng Cù Lần & Resort rừng 3 ngày 2 đêm', 'Nghỉ dưỡng giữa thiên nhiên rừng thông', 20, 6500000.00, 3, 25, 'dalat27.jpg', 4.80, 220, 0, 'Hoạt động', '2026-04-09 17:00:00', '2026-04-09 17:00:00', 6200000.00, 'Nghỉ dưỡng', '2026-04-30'),
(578, 'Đà Lạt – Zen Retreat & Thiền 3 ngày 2 đêm', 'Trải nghiệm thiền và nghỉ dưỡng cao cấp', 20, 8800000.00, 3, 20, 'dalat28.jpg', 4.90, 210, 1, 'Không hoạt động', '2026-04-09 17:00:00', '2026-04-12 11:29:36', 8300000.00, 'Nghỉ dưỡng', '2026-04-30'),
(584, 'Tour khám phá  Hòn Sơn', 'Tham quan đảo và săn mây', 31, 2000000.00, 2, 25, 'ag5.jpg', 0.00, 0, 0, 'Không hoạt động', '2026-04-10 12:20:40', '2026-04-12 10:32:21', NULL, NULL, '2026-05-09'),
(587, 'Tour khám phá biển đảo', 'Tắm biển, ngắm bình minh', 11, 3000000.00, 3, 24, 'ag2.jpg', 0.00, 0, 0, 'Hoạt động', '2026-04-27 04:26:32', '2026-04-27 04:26:32', NULL, NULL, '2026-04-30');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `trang_web_tham_quan`
--

CREATE TABLE `trang_web_tham_quan` (
  `id` int(11) NOT NULL,
  `id_nguoi_dung` int(11) DEFAULT NULL,
  `ngay_truy_cap` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `trang_web_tham_quan`
--

INSERT INTO `trang_web_tham_quan` (`id`, `id_nguoi_dung`, `ngay_truy_cap`) VALUES
(1, 3, '2026-04-16 15:49:38'),
(2, 5, '2026-04-16 15:49:52'),
(3, 4, '2026-04-16 15:50:01'),
(4, 2, '2026-04-16 15:50:10'),
(5, 5, '2026-04-16 15:50:16'),
(6, 2, '2026-04-16 15:54:55'),
(7, 2, '2026-04-16 15:56:06'),
(8, 2, '2026-04-16 15:56:33'),
(9, 3, '2026-04-17 07:20:02'),
(10, 3, '2026-04-17 10:53:05'),
(11, 3, '2026-04-17 11:16:20'),
(12, 3, '2026-04-17 11:25:42'),
(13, 3, '2026-04-17 11:40:57'),
(14, 3, '2026-04-17 11:43:55'),
(15, 3, '2026-04-17 12:39:05'),
(16, 2, '2026-04-17 12:57:41'),
(17, 3, '2026-04-17 12:59:24'),
(18, 2, '2026-04-17 12:59:49'),
(19, 3, '2026-04-17 18:47:20'),
(20, 2, '2026-04-17 18:49:29'),
(21, 3, '2026-04-17 20:43:37'),
(22, 3, '2026-04-18 08:07:10'),
(23, 2, '2026-04-18 09:22:52'),
(24, 4, '2026-04-18 09:33:45'),
(25, 5, '2026-04-18 09:38:47'),
(26, 28, '2026-04-18 09:41:23'),
(27, 28, '2026-04-18 09:42:43'),
(28, 3, '2026-04-19 11:24:26'),
(29, 2, '2026-04-19 12:11:49'),
(30, 3, '2026-04-19 12:12:48'),
(31, 2, '2026-04-19 12:21:50'),
(32, 3, '2026-04-19 12:22:20'),
(33, 2, '2026-04-19 12:22:40'),
(34, 2, '2026-04-19 12:28:57'),
(35, 3, '2026-04-19 12:29:33'),
(36, 2, '2026-04-19 12:29:57'),
(37, 3, '2026-04-19 12:32:51'),
(38, 2, '2026-04-19 12:33:03'),
(39, 3, '2026-04-19 12:35:45'),
(40, 2, '2026-04-19 12:42:25'),
(41, 3, '2026-04-19 16:54:58'),
(42, 3, '2026-04-19 20:12:26'),
(43, 3, '2026-04-27 09:06:35'),
(44, 3, '2026-04-27 11:45:15'),
(45, 28, '2026-04-27 12:05:12'),
(46, 3, '2026-04-27 15:49:37'),
(47, 3, '2026-04-27 15:56:37'),
(48, 3, '2026-04-27 16:00:02'),
(49, 3, '2026-04-27 16:03:25'),
(50, 4, '2026-04-27 16:03:43'),
(51, 3, '2026-04-27 16:07:54'),
(52, 3, '2026-04-27 16:08:50'),
(53, 3, '2026-04-27 16:16:58'),
(54, 3, '2026-04-27 19:14:52'),
(55, 3, '2026-04-27 19:55:46'),
(56, 2, '2026-04-27 19:57:33');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `yeu_thich`
--

CREATE TABLE `yeu_thich` (
  `id` int(11) NOT NULL,
  `id_nguoi_dung` int(11) NOT NULL,
  `id_tour` int(11) DEFAULT NULL,
  `id_goi_combo` int(11) DEFAULT NULL,
  `id_nhom` int(11) DEFAULT NULL,
  `ngay_them` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Đang đổ dữ liệu cho bảng `yeu_thich`
--

INSERT INTO `yeu_thich` (`id`, `id_nguoi_dung`, `id_tour`, `id_goi_combo`, `id_nhom`, `ngay_them`) VALUES
(1, 2, 578, NULL, NULL, '2026-04-01 12:52:13'),
(4, 3, 574, NULL, NULL, '2026-04-01 12:53:35'),
(10, 3, NULL, 14, NULL, '2026-04-06 07:21:03'),
(13, 3, NULL, 17, NULL, '2026-04-06 07:41:18'),
(14, 3, 564, NULL, NULL, '2026-04-06 07:43:30'),
(20, 3, 560, NULL, NULL, '2026-04-06 08:13:00'),
(44, 3, NULL, 20, 2, '2026-04-06 08:35:46'),
(45, 3, NULL, 19, NULL, '2026-04-06 08:35:59'),
(50, 3, 562, NULL, 3, '2026-04-06 08:41:40'),
(51, 3, NULL, 6, 3, '2026-04-06 08:41:50'),
(58, 3, NULL, 22, NULL, '2026-04-06 08:58:19'),
(67, 3, NULL, 24, 2, '2026-04-07 11:38:28'),
(72, 3, 576, NULL, 4, '2026-04-18 01:07:18');

--
-- Chỉ mục cho các bảng đã đổ
--

--
-- Chỉ mục cho bảng `danh_gia`
--
ALTER TABLE `danh_gia`
  ADD PRIMARY KEY (`id`),
  ADD KEY `id_dat_tour` (`id_dat_tour`),
  ADD KEY `idx_danh_gia_tour` (`id_tour`),
  ADD KEY `idx_danh_gia_nguoi_dung` (`id_nguoi_dung`),
  ADD KEY `fk_danhgia_combo` (`id_goi_combo`);

--
-- Chỉ mục cho bảng `dat_tour`
--
ALTER TABLE `dat_tour`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `so_dat_tour` (`so_dat_tour`),
  ADD KEY `id_goi_combo` (`id_goi_combo`),
  ADD KEY `idx_dat_tour_nguoi_dung` (`id_nguoi_dung`),
  ADD KEY `idx_dat_tour_tour` (`id_tour`);

--
-- Chỉ mục cho bảng `dia_diem`
--
ALTER TABLE `dia_diem`
  ADD PRIMARY KEY (`id`);

--
-- Chỉ mục cho bảng `goi_combo`
--
ALTER TABLE `goi_combo`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_combo_diadiem` (`id_dia_diem`);

--
-- Chỉ mục cho bảng `hidden_conversations`
--
ALTER TABLE `hidden_conversations`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `customer_id` (`customer_id`);

--
-- Chỉ mục cho bảng `khuyen_mai`
--
ALTER TABLE `khuyen_mai`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `code` (`code`),
  ADD KEY `idx_ma_khuyen_mai_code` (`code`),
  ADD KEY `fk_khuyenmai_tour` (`id_tour`),
  ADD KEY `fk_khuyenmai_combo` (`id_goi_combo`);

--
-- Chỉ mục cho bảng `khuyen_mai_combo`
--
ALTER TABLE `khuyen_mai_combo`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_promo_combo` (`id_khuyen_mai`,`id_goi_combo`),
  ADD KEY `id_goi_combo` (`id_goi_combo`);

--
-- Chỉ mục cho bảng `khuyen_mai_tour`
--
ALTER TABLE `khuyen_mai_tour`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_promo_tour` (`id_khuyen_mai`,`id_tour`),
  ADD KEY `id_tour` (`id_tour`);

--
-- Chỉ mục cho bảng `lich_su_dang_nhap`
--
ALTER TABLE `lich_su_dang_nhap`
  ADD PRIMARY KEY (`id`),
  ADD KEY `id_nguoi_dung` (`id_nguoi_dung`);

--
-- Chỉ mục cho bảng `lich_trinh_chi_tiet`
--
ALTER TABLE `lich_trinh_chi_tiet`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_chitiet_lichtrinh` (`lich_trinh_id`);

--
-- Chỉ mục cho bảng `lich_trinh_tour`
--
ALTER TABLE `lich_trinh_tour`
  ADD PRIMARY KEY (`id`),
  ADD KEY `id_tour` (`id_tour`),
  ADD KEY `fk_lichtrinh_combo` (`id_goi_combo`);

--
-- Chỉ mục cho bảng `nguoi_dung`
--
ALTER TABLE `nguoi_dung`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`),
  ADD UNIQUE KEY `facebook_id` (`facebook_id`),
  ADD KEY `idx_nguoi_dung_email` (`email`),
  ADD KEY `idx_nguoi_dung_so_dien_thoai` (`so_dien_thoai`);

--
-- Chỉ mục cho bảng `nhom_yeuthich`
--
ALTER TABLE `nhom_yeuthich`
  ADD PRIMARY KEY (`id`),
  ADD KEY `id_nguoi_dung` (`id_nguoi_dung`);

--
-- Chỉ mục cho bảng `password_reset`
--
ALTER TABLE `password_reset`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_email` (`email`),
  ADD KEY `idx_otp` (`otp`),
  ADD KEY `idx_trang_thai` (`trang_thai`);

--
-- Chỉ mục cho bảng `phuong_thuc_thanh_toan`
--
ALTER TABLE `phuong_thuc_thanh_toan`
  ADD PRIMARY KEY (`id`),
  ADD KEY `id_nguoi_dung` (`id_nguoi_dung`);

--
-- Chỉ mục cho bảng `thanh_toan`
--
ALTER TABLE `thanh_toan`
  ADD PRIMARY KEY (`id`),
  ADD KEY `id_dat_tour` (`id_dat_tour`);

--
-- Chỉ mục cho bảng `tin_nhan`
--
ALTER TABLE `tin_nhan`
  ADD PRIMARY KEY (`id`),
  ADD KEY `nguoi_gui_id` (`nguoi_gui_id`),
  ADD KEY `nguoi_nhan_id` (`nguoi_nhan_id`);

--
-- Chỉ mục cho bảng `tour`
--
ALTER TABLE `tour`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_tour_dia_diem` (`id_dia_diem`),
  ADD KEY `idx_tour_trang_thai` (`trang_thai`);

--
-- Chỉ mục cho bảng `trang_web_tham_quan`
--
ALTER TABLE `trang_web_tham_quan`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_ngay` (`ngay_truy_cap`),
  ADD KEY `idx_user` (`id_nguoi_dung`);

--
-- Chỉ mục cho bảng `yeu_thich`
--
ALTER TABLE `yeu_thich`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `yeu_thich_duy_nhat` (`id_nguoi_dung`,`id_tour`),
  ADD KEY `id_tour` (`id_tour`),
  ADD KEY `idx_yeu_thich_nguoi_dung` (`id_nguoi_dung`),
  ADD KEY `fk_yeuthich_combo` (`id_goi_combo`),
  ADD KEY `fk_yeuthich_nhom` (`id_nhom`);

--
-- AUTO_INCREMENT cho các bảng đã đổ
--

--
-- AUTO_INCREMENT cho bảng `danh_gia`
--
ALTER TABLE `danh_gia`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=19;

--
-- AUTO_INCREMENT cho bảng `dat_tour`
--
ALTER TABLE `dat_tour`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=84;

--
-- AUTO_INCREMENT cho bảng `dia_diem`
--
ALTER TABLE `dia_diem`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=51;

--
-- AUTO_INCREMENT cho bảng `goi_combo`
--
ALTER TABLE `goi_combo`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=33;

--
-- AUTO_INCREMENT cho bảng `hidden_conversations`
--
ALTER TABLE `hidden_conversations`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT cho bảng `khuyen_mai`
--
ALTER TABLE `khuyen_mai`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=23;

--
-- AUTO_INCREMENT cho bảng `khuyen_mai_combo`
--
ALTER TABLE `khuyen_mai_combo`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT cho bảng `khuyen_mai_tour`
--
ALTER TABLE `khuyen_mai_tour`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT cho bảng `lich_su_dang_nhap`
--
ALTER TABLE `lich_su_dang_nhap`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT cho bảng `lich_trinh_chi_tiet`
--
ALTER TABLE `lich_trinh_chi_tiet`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=42;

--
-- AUTO_INCREMENT cho bảng `lich_trinh_tour`
--
ALTER TABLE `lich_trinh_tour`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT cho bảng `nguoi_dung`
--
ALTER TABLE `nguoi_dung`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=29;

--
-- AUTO_INCREMENT cho bảng `nhom_yeuthich`
--
ALTER TABLE `nhom_yeuthich`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT cho bảng `password_reset`
--
ALTER TABLE `password_reset`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT cho bảng `phuong_thuc_thanh_toan`
--
ALTER TABLE `phuong_thuc_thanh_toan`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT cho bảng `thanh_toan`
--
ALTER TABLE `thanh_toan`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=43;

--
-- AUTO_INCREMENT cho bảng `tin_nhan`
--
ALTER TABLE `tin_nhan`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT cho bảng `tour`
--
ALTER TABLE `tour`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=588;

--
-- AUTO_INCREMENT cho bảng `trang_web_tham_quan`
--
ALTER TABLE `trang_web_tham_quan`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=57;

--
-- AUTO_INCREMENT cho bảng `yeu_thich`
--
ALTER TABLE `yeu_thich`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=73;

--
-- Các ràng buộc cho các bảng đã đổ
--

--
-- Các ràng buộc cho bảng `danh_gia`
--
ALTER TABLE `danh_gia`
  ADD CONSTRAINT `danh_gia_ibfk_1` FOREIGN KEY (`id_nguoi_dung`) REFERENCES `nguoi_dung` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `danh_gia_ibfk_2` FOREIGN KEY (`id_dat_tour`) REFERENCES `dat_tour` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `danh_gia_ibfk_3` FOREIGN KEY (`id_tour`) REFERENCES `tour` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_danhgia_combo` FOREIGN KEY (`id_goi_combo`) REFERENCES `goi_combo` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Các ràng buộc cho bảng `dat_tour`
--
ALTER TABLE `dat_tour`
  ADD CONSTRAINT `dat_tour_ibfk_1` FOREIGN KEY (`id_nguoi_dung`) REFERENCES `nguoi_dung` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `dat_tour_ibfk_2` FOREIGN KEY (`id_tour`) REFERENCES `tour` (`id`),
  ADD CONSTRAINT `dat_tour_ibfk_3` FOREIGN KEY (`id_goi_combo`) REFERENCES `goi_combo` (`id`) ON DELETE SET NULL;

--
-- Các ràng buộc cho bảng `goi_combo`
--
ALTER TABLE `goi_combo`
  ADD CONSTRAINT `fk_combo_diadiem` FOREIGN KEY (`id_dia_diem`) REFERENCES `dia_diem` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Các ràng buộc cho bảng `khuyen_mai`
--
ALTER TABLE `khuyen_mai`
  ADD CONSTRAINT `fk_khuyenmai_combo` FOREIGN KEY (`id_goi_combo`) REFERENCES `goi_combo` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_khuyenmai_tour` FOREIGN KEY (`id_tour`) REFERENCES `tour` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Các ràng buộc cho bảng `khuyen_mai_combo`
--
ALTER TABLE `khuyen_mai_combo`
  ADD CONSTRAINT `khuyen_mai_combo_ibfk_1` FOREIGN KEY (`id_khuyen_mai`) REFERENCES `khuyen_mai` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `khuyen_mai_combo_ibfk_2` FOREIGN KEY (`id_goi_combo`) REFERENCES `goi_combo` (`id`) ON DELETE CASCADE;

--
-- Các ràng buộc cho bảng `khuyen_mai_tour`
--
ALTER TABLE `khuyen_mai_tour`
  ADD CONSTRAINT `khuyen_mai_tour_ibfk_1` FOREIGN KEY (`id_khuyen_mai`) REFERENCES `khuyen_mai` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `khuyen_mai_tour_ibfk_2` FOREIGN KEY (`id_tour`) REFERENCES `tour` (`id`) ON DELETE CASCADE;

--
-- Các ràng buộc cho bảng `lich_su_dang_nhap`
--
ALTER TABLE `lich_su_dang_nhap`
  ADD CONSTRAINT `lich_su_dang_nhap_ibfk_1` FOREIGN KEY (`id_nguoi_dung`) REFERENCES `nguoi_dung` (`id`) ON DELETE CASCADE;

--
-- Các ràng buộc cho bảng `lich_trinh_chi_tiet`
--
ALTER TABLE `lich_trinh_chi_tiet`
  ADD CONSTRAINT `fk_chitiet_lichtrinh` FOREIGN KEY (`lich_trinh_id`) REFERENCES `lich_trinh_tour` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Các ràng buộc cho bảng `lich_trinh_tour`
--
ALTER TABLE `lich_trinh_tour`
  ADD CONSTRAINT `fk_lichtrinh_combo` FOREIGN KEY (`id_goi_combo`) REFERENCES `goi_combo` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_lichtrinh_tour` FOREIGN KEY (`id_tour`) REFERENCES `tour` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `lich_trinh_tour_ibfk_1` FOREIGN KEY (`id_tour`) REFERENCES `tour` (`id`) ON DELETE CASCADE;

--
-- Các ràng buộc cho bảng `nhom_yeuthich`
--
ALTER TABLE `nhom_yeuthich`
  ADD CONSTRAINT `nhom_yeuthich_ibfk_1` FOREIGN KEY (`id_nguoi_dung`) REFERENCES `nguoi_dung` (`id`) ON DELETE CASCADE;

--
-- Các ràng buộc cho bảng `phuong_thuc_thanh_toan`
--
ALTER TABLE `phuong_thuc_thanh_toan`
  ADD CONSTRAINT `phuong_thuc_thanh_toan_ibfk_1` FOREIGN KEY (`id_nguoi_dung`) REFERENCES `nguoi_dung` (`id`) ON DELETE CASCADE;

--
-- Các ràng buộc cho bảng `thanh_toan`
--
ALTER TABLE `thanh_toan`
  ADD CONSTRAINT `thanh_toan_ibfk_1` FOREIGN KEY (`id_dat_tour`) REFERENCES `dat_tour` (`id`);

--
-- Các ràng buộc cho bảng `tin_nhan`
--
ALTER TABLE `tin_nhan`
  ADD CONSTRAINT `tin_nhan_ibfk_1` FOREIGN KEY (`nguoi_gui_id`) REFERENCES `nguoi_dung` (`id`),
  ADD CONSTRAINT `tin_nhan_ibfk_2` FOREIGN KEY (`nguoi_nhan_id`) REFERENCES `nguoi_dung` (`id`);

--
-- Các ràng buộc cho bảng `tour`
--
ALTER TABLE `tour`
  ADD CONSTRAINT `tour_ibfk_1` FOREIGN KEY (`id_dia_diem`) REFERENCES `dia_diem` (`id`) ON DELETE CASCADE;

--
-- Các ràng buộc cho bảng `trang_web_tham_quan`
--
ALTER TABLE `trang_web_tham_quan`
  ADD CONSTRAINT `trang_web_tham_quan_ibfk_1` FOREIGN KEY (`id_nguoi_dung`) REFERENCES `nguoi_dung` (`id`) ON DELETE CASCADE;

--
-- Các ràng buộc cho bảng `yeu_thich`
--
ALTER TABLE `yeu_thich`
  ADD CONSTRAINT `fk_yeuthich_combo` FOREIGN KEY (`id_goi_combo`) REFERENCES `goi_combo` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_yeuthich_nhom` FOREIGN KEY (`id_nhom`) REFERENCES `nhom_yeuthich` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `yeu_thich_ibfk_1` FOREIGN KEY (`id_nguoi_dung`) REFERENCES `nguoi_dung` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `yeu_thich_ibfk_2` FOREIGN KEY (`id_tour`) REFERENCES `tour` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;

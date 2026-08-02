<?php
/**
 * Admin API Handler
 * Xử lý tất cả request từ admin panel
 */

// Kết nối database
require_once __DIR__ . '/config.php';

// Set header cho JSON response
header('Content-Type: application/json; charset=utf-8');

// Kiểm tra action từ client
$action = isset($_GET['action']) ? $_GET['action'] : '';

// Nếu không có action từ GET, kiểm tra POST body (JSON)
if (empty($action)) {
    $requestBody = json_decode(file_get_contents('php://input'), true);
    if (isset($requestBody['action'])) {
        $action = $requestBody['action'];
    }
}

// Routing các action
switch($action) {
    case 'admin_login':
        adminLogin();
        break;
    case 'get_tours':
        getTours();
        break;
    case 'get_tour_detail':
        getTourDetail();
        break;
    case 'delete_tour':
        deleteTour();
        break;
    case 'add_tour':
        addTour();
        break;
    case 'update_tour':
        updateTour();
        break;
    case 'search_tours':
        searchToursAPI();
        break;
    case 'get_bookings':
        getBookings();
        break;
    case 'get_upcoming_departures':
        getUpcomingDepartures();
        break;
    case 'confirm_booking':
        confirmBooking();
        break;
    case 'delete_booking':
        deleteBooking();
        break;
    case 'update_booking':
        updateBooking();
        break;
    case 'get_destinations':
        getDestinations();
        break;
    case 'get_tour_types':
        getTourTypes();
        break;
    case 'get_users':
        getUsers();
        break;
    case 'get_payments':
        getPayments();
        break;
    case 'confirm_payment':
        confirmPayment();
        break;
    case 'delete_payment':
        deletePayment();
        break;
    case 'get_customer_stats':
        getCustomerStats();
        break;
    case 'get_dashboard_stats':
        getDashboardStats();
        break;
    case 'update_user':
        updateUser();
        break;
    case 'delete_user':
        deleteUser();
        break;
    case 'get_payment_methods':
        echo json_encode(getPaymentMethods());
        break;
    default:
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Action không tồn tại'
        ]);
}

/**
 * Admin Login
 */
function adminLogin() {
    global $conn;
    
    try {
        $requestBody = json_decode(file_get_contents('php://input'), true);
        $email = isset($requestBody['email']) ? trim($requestBody['email']) : '';
        $password = isset($requestBody['password']) ? trim($requestBody['password']) : '';
        
        error_log("Login attempt - Email: " . $email);
        
        if (empty($email) || empty($password)) {
            throw new Exception("Email và mật khẩu không được để trống");
        }
        
        // Query admin user - include vai_tro to check role
        $query = "SELECT id, email, ten_dau, ten_cuoi, mat_khau, vai_tro FROM nguoi_dung WHERE email = ?";
        $stmt = $conn->prepare($query);
        if (!$stmt) {
            error_log("Prepare error: " . $conn->error);
            throw new Exception("Database prepare error: " . $conn->error);
        }
        
        $stmt->bind_param('s', $email);
        if (!$stmt->execute()) {
            error_log("Execute error: " . $stmt->error);
            throw new Exception("Database execute error: " . $stmt->error);
        }
        
        $result = $stmt->get_result();
        $admin = $result->fetch_assoc();
        $stmt->close();
        
        error_log("Admin found: " . ($admin ? "yes" : "no"));
        error_log("Vai tro: " . ($admin ? $admin['vai_tro'] : "N/A"));
        
        if (!$admin) {
            throw new Exception("Email hoặc mật khẩu không chính xác");
        }
        
        // Check password - support both hashed and plain text
        $passwordMatch = password_verify($password, $admin['mat_khau']) || $password === $admin['mat_khau'];
        
        error_log("Password match: " . ($passwordMatch ? "yes" : "no"));
        error_log("DB password: " . substr($admin['mat_khau'], 0, 20) . "...");
        
        if (!$passwordMatch) {
            throw new Exception("Email hoặc mật khẩu không chính xác");
        }
        
        // Check vai_tro - only admin can login
        if ($admin['vai_tro'] !== 'admin') {
            throw new Exception("Tài khoản này không có quyền truy cập trang quản lý. Chỉ có admin mới có thể đăng nhập.");
        }
        
        // Login success
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'message' => 'Đăng nhập thành công',
            'admin' => [
                'id' => $admin['id'],
                'email' => $admin['email'],
                'name' => $admin['ten_dau'] . ' ' . $admin['ten_cuoi']
            ]
        ], JSON_UNESCAPED_UNICODE);
        
    } catch (Exception $e) {
        error_log("Login error: " . $e->getMessage());
        http_response_code(401);
        echo json_encode([
            'success' => false,
            'message' => $e->getMessage()
        ], JSON_UNESCAPED_UNICODE);
    }
}

/**
 * Lấy danh sách tour với phân trang, lọc và sắp xếp
 */
function getTours() {
    global $conn;
    
    try {
        // Lấy parameters từ GET
        $page = isset($_GET['page']) ? max(1, intval($_GET['page'])) : 1;
        $sort = isset($_GET['sort']) ? $_GET['sort'] : 'newest';
        $filter = isset($_GET['filter']) ? $_GET['filter'] : 'all';
        $limit = 10; // Số tour mỗi trang
        
        // Tính offset
        $offset = ($page - 1) * $limit;
        
        // Xây dựng query cơ bản
        $query = "SELECT id, ten, mo_ta, gia, id_dia_diem, so_ngay, url_anh_chinh, 
                         danh_gia, so_danh_gia, trang_thai, ngay_khoi_hanh 
                  FROM tour";
        
        // Filter theo status
        $queryWhere = " WHERE 1=1";
        if ($filter === 'active') {
            $queryWhere .= " AND trang_thai = 'Hoạt động'";
        } elseif ($filter === 'inactive') {
            $queryWhere .= " AND trang_thai = 'Không hoạt động'";
        }
        
        // Sắp xếp
        $queryOrder = " ORDER BY";
        switch($sort) {
            case 'price-asc':
            case 'price_low':
                $queryOrder .= " gia ASC";
                break;
            case 'price-desc':
            case 'price_high':
                $queryOrder .= " gia DESC";
                break;
            case 'name-asc':
                $queryOrder .= " ten ASC";
                break;
            case 'name-desc':
                $queryOrder .= " ten DESC";
                break;
            case 'oldest':
                $queryOrder .= " ngay_tao ASC";
                break;
            case 'rating':
                $queryOrder .= " danh_gia DESC";
                break;
            case 'newest':
            default:
                $queryOrder .= " id DESC";
        }
        
        // Thêm limit
        $queryFull = $query . $queryWhere . $queryOrder . " LIMIT ? OFFSET ?";
        
        // Chuẩn bị statement
        $stmt = $conn->prepare($queryFull);
        if (!$stmt) {
            throw new Exception("Prepare failed: " . $conn->error);
        }
        
        $stmt->bind_param('ii', $limit, $offset);
        $stmt->execute();
        $result = $stmt->get_result();
        
        // Lấy dữ liệu tour
        $tours = [];
        while ($row = $result->fetch_assoc()) {
            $tours[] = formatTourData($row);
        }
        $stmt->close();
        
        // Lấy tổng số tour để tính pagination
        $countQuery = "SELECT COUNT(*) as total FROM tour" . $queryWhere;
        $countStmt = $conn->prepare($countQuery);
        if (!$countStmt) {
            throw new Exception("Count prepare failed: " . $conn->error);
        }
        
        $countStmt->execute();
        $countResult = $countStmt->get_result();
        $countRow = $countResult->fetch_assoc();
        $totalTours = $countRow['total'];
        $countStmt->close();
        
        // Tính pagination
        $totalPages = ceil($totalTours / $limit);
        
        // Trả response
        echo json_encode([
            'success' => true,
            'data' => $tours,
            'pagination' => [
                'current_page' => $page,
                'total_pages' => $totalPages,
                'total_items' => $totalTours,
                'items_per_page' => $limit,
                'has_prev' => $page > 1,
                'has_next' => $page < $totalPages
            ]
        ], JSON_UNESCAPED_UNICODE);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Lỗi lấy dữ liệu: ' . $e->getMessage()
        ], JSON_UNESCAPED_UNICODE);
    }
}

/**
 * Lấy chi tiết 1 tour
 */
function getTourDetail() {
    global $conn;
    
    try {
        $tourId = isset($_GET['id']) ? intval($_GET['id']) : 0;
        
        if ($tourId <= 0) {
            throw new Exception("ID tour không hợp lệ");
        }
        
        $query = "SELECT 
                    t.id,
                    t.ten,
                    t.mo_ta,
                    t.id_dia_diem,
                    d.ten as dia_diem_name,
                    t.gia,
                    t.so_ngay,
                    t.so_nguoi_toi_da,
                    t.so_danh_gia,
                    t.url_anh_chinh,
                    t.ngay_khoi_hanh,
                    t.trang_thai,
                    t.ngay_tao,
                    t.gia_khuyen_mai,
                    t.loai_tour
                  FROM tour t
                  LEFT JOIN dia_diem d ON t.id_dia_diem = d.id
                  WHERE t.id = ?";
        $stmt = $conn->prepare($query);
        
        if (!$stmt) {
            throw new Exception("Prepare failed: " . $conn->error);
        }
        
        $stmt->bind_param('i', $tourId);
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($result->num_rows === 0) {
            throw new Exception("Tour không tồn tại");
        }
        
        $row = $result->fetch_assoc();
        $stmt->close();
        
        echo json_encode([
            'success' => true,
            'data' => $row
        ], JSON_UNESCAPED_UNICODE);
        
    } catch (Exception $e) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => $e->getMessage()
        ], JSON_UNESCAPED_UNICODE);
    }
}

/**
 * Xóa tour
 */
function deleteTour() {
    global $conn;
    
    try {
        $tourId = isset($_GET['id']) ? intval($_GET['id']) : 0;
        
        if ($tourId <= 0) {
            throw new Exception("ID tour không hợp lệ");
        }
        
        $query = "DELETE FROM tour WHERE id = ?";
        $stmt = $conn->prepare($query);
        
        if (!$stmt) {
            throw new Exception("Prepare failed: " . $conn->error);
        }
        
        $stmt->bind_param('i', $tourId);
        $stmt->execute();
        
        if ($stmt->affected_rows === 0) {
            throw new Exception("Tour không tồn tại");
        }
        
        $stmt->close();
        
        echo json_encode([
            'success' => true,
            'message' => 'Xóa tour thành công'
        ], JSON_UNESCAPED_UNICODE);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Lỗi xóa tour: ' . $e->getMessage()
        ], JSON_UNESCAPED_UNICODE);
    }
}

/**
 * Thêm tour mới vào database
 */
function addTour() {
    global $conn;
    
    try {
        // Kiểm tra dữ liệu bắt buộc
        $ten = isset($_POST['ten']) ? trim($_POST['ten']) : '';
        $mo_ta = isset($_POST['mo_ta']) ? trim($_POST['mo_ta']) : '';
        $id_dia_diem = isset($_POST['id_dia_diem']) ? intval($_POST['id_dia_diem']) : 0;
        $gia = isset($_POST['gia']) ? floatval($_POST['gia']) : 0;
        $so_ngay = isset($_POST['so_ngay']) ? intval($_POST['so_ngay']) : 0;
        $so_nguoi_toi_da = isset($_POST['so_nguoi_toi_da']) ? intval($_POST['so_nguoi_toi_da']) : 0;
        $ngay_khoi_hanh = isset($_POST['ngay_khoi_hanh']) ? $_POST['ngay_khoi_hanh'] : '';
        
        // Dữ liệu không bắt buộc
        $trang_thai = isset($_POST['trang_thai']) ? $_POST['trang_thai'] : 'Hoạt động';
        
        // Validation
        if (empty($ten) || empty($mo_ta) || $id_dia_diem <= 0 || $gia <= 0 || $so_ngay <= 0 || $so_nguoi_toi_da <= 0 || empty($ngay_khoi_hanh)) {
            throw new Exception('Vui lòng điền đầy đủ thông tin bắt buộc');
        }
        
        // Xử lý ảnh
        $url_anh_chinh = '';
        
        // Nếu nhận base64 từ client
        if (isset($_POST['anh_base64']) && !empty($_POST['anh_base64']) && isset($_POST['anh_filename']) && !empty($_POST['anh_filename'])) {
            // Decode base64 image data
            $imageData = $_POST['anh_base64'];
            
            // Lấy tên file gốc
            $originalFilename = $_POST['anh_filename'];
            $filename = basename($originalFilename); // Lấy tên file cuối cùng, tránh path traversal
            
            $imageData = base64_decode($imageData);
            
            // Tạo folder nếu chưa tồn tại - Lưu vào img/
            $uploadDir = '../img/';
            if (!is_dir($uploadDir)) {
                mkdir($uploadDir, 0755, true);
            }
            
            $filepath = $uploadDir . $filename;
            
            // Lưu file
            if (file_put_contents($filepath, $imageData)) {
                $url_anh_chinh = $filename;
            } else {
                throw new Exception('Lỗi lưu ảnh tour');
            }
        } else if (isset($_FILES['anh_file']) && $_FILES['anh_file']['error'] === 0) {
            // Xử lý upload file từ form - Lưu vào img/
            $uploadDir = '../img/';
            if (!is_dir($uploadDir)) {
                mkdir($uploadDir, 0755, true);
            }
            
            // Lấy tên file gốc
            $filename = basename($_FILES['anh_file']['name']);
            $filepath = $uploadDir . $filename;
            
            if (move_uploaded_file($_FILES['anh_file']['tmp_name'], $filepath)) {
                $url_anh_chinh = $filename;
            } else {
                throw new Exception('Lỗi upload ảnh tour');
            }
        } else {
            throw new Exception('Vui lòng chọn ảnh tour');
        }
        
        // Chuẩn bị câu lệnh INSERT
        $query = "INSERT INTO tour 
                  (ten, mo_ta, id_dia_diem, gia, so_ngay, so_nguoi_toi_da, url_anh_chinh, trang_thai, ngay_khoi_hanh)
                  VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";
        
        $stmt = $conn->prepare($query);
        if (!$stmt) {
            throw new Exception("Prepare failed: " . $conn->error);
        }
        
        $stmt->bind_param(
            'ssiidisss',
            $ten,
            $mo_ta,
            $id_dia_diem,
            $gia,
            $so_ngay,
            $so_nguoi_toi_da,
            $url_anh_chinh,
            $trang_thai,
            $ngay_khoi_hanh
        );
        
        if (!$stmt->execute()) {
            throw new Exception("Execute failed: " . $stmt->error);
        }
        
        $tourId = $conn->insert_id;
        $stmt->close();
        
        echo json_encode([
            'success' => true,
            'message' => 'Thêm tour thành công',
            'tour_id' => $tourId
        ], JSON_UNESCAPED_UNICODE);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Lỗi thêm tour: ' . $e->getMessage()
        ], JSON_UNESCAPED_UNICODE);
    }
}

/**
 * Cập nhật thông tin tour
 */
function updateTour() {
    global $conn;
    
    try {
        // Kiểm tra dữ liệu bắt buộc
        $id = isset($_POST['id']) ? intval($_POST['id']) : 0;
        $ten = isset($_POST['ten']) ? trim($_POST['ten']) : '';
        $mo_ta = isset($_POST['mo_ta']) ? trim($_POST['mo_ta']) : '';
        $id_dia_diem = isset($_POST['id_dia_diem']) ? intval($_POST['id_dia_diem']) : 0;
        $gia = isset($_POST['gia']) ? floatval($_POST['gia']) : 0;
        $so_ngay = isset($_POST['so_ngay']) ? intval($_POST['so_ngay']) : 0;
        $so_nguoi_toi_da = isset($_POST['so_nguoi_toi_da']) ? intval($_POST['so_nguoi_toi_da']) : 0;
        $ngay_khoi_hanh = isset($_POST['ngay_khoi_hanh']) ? $_POST['ngay_khoi_hanh'] : '';
        $trang_thai = isset($_POST['trang_thai']) ? $_POST['trang_thai'] : 'Hoạt động';
        
        // Validation
        if ($id <= 0 || empty($ten) || empty($mo_ta) || $id_dia_diem <= 0 || $gia <= 0 || $so_ngay <= 0 || $so_nguoi_toi_da <= 0 || empty($ngay_khoi_hanh)) {
            throw new Exception('Vui lòng điền đầy đủ thông tin bắt buộc');
        }
        
        // Lấy tour hiện tại
        $getCurrent = "SELECT url_anh_chinh FROM tour WHERE id = ?";
        $stmtCurrent = $conn->prepare($getCurrent);
        $stmtCurrent->bind_param('i', $id);
        $stmtCurrent->execute();
        $resultCurrent = $stmtCurrent->get_result();
        
        if ($resultCurrent->num_rows === 0) {
            throw new Exception('Tour không tồn tại');
        }
        
        $current = $resultCurrent->fetch_assoc();
        $url_anh_chinh = $current['url_anh_chinh']; // Giữ ảnh cũ nếu không upload ảnh mới
        $stmtCurrent->close();
        
        // Xử lý ảnh (nếu có ảnh mới)
        if ((isset($_POST['anh_base64']) && !empty($_POST['anh_base64'])) || (isset($_FILES['anh_file']) && $_FILES['anh_file']['error'] === 0)) {
            
            if (isset($_POST['anh_base64']) && !empty($_POST['anh_base64']) && isset($_POST['anh_filename']) && !empty($_POST['anh_filename'])) {
                // Decode base64 image data
                $imageData = $_POST['anh_base64'];
                
                // Lấy tên file gốc
                $originalFilename = $_POST['anh_filename'];
                $filename = basename($originalFilename);
                
                $imageData = base64_decode($imageData);
                
                // Tạo folder nếu chưa tồn tại
                $uploadDir = '../img/';
                if (!is_dir($uploadDir)) {
                    mkdir($uploadDir, 0755, true);
                }
                
                $filepath = $uploadDir . $filename;
                
                // Lưu file
                if (file_put_contents($filepath, $imageData)) {
                    $url_anh_chinh = $filename;
                } else {
                    throw new Exception('Lỗi lưu ảnh tour');
                }
            } else if (isset($_FILES['anh_file']) && $_FILES['anh_file']['error'] === 0) {
                // Xử lý upload file từ form
                $uploadDir = '../img/';
                if (!is_dir($uploadDir)) {
                    mkdir($uploadDir, 0755, true);
                }
                
                // Lấy tên file gốc
                $filename = basename($_FILES['anh_file']['name']);
                $filepath = $uploadDir . $filename;
                
                if (move_uploaded_file($_FILES['anh_file']['tmp_name'], $filepath)) {
                    $url_anh_chinh = $filename;
                } else {
                    throw new Exception('Lỗi upload ảnh tour');
                }
            }
        }
        
        // Chuẩn bị câu lệnh UPDATE
        $query = "UPDATE tour 
                  SET ten = ?, mo_ta = ?, id_dia_diem = ?, gia = ?, so_ngay = ?, so_nguoi_toi_da = ?, url_anh_chinh = ?, trang_thai = ?, ngay_khoi_hanh = ?
                  WHERE id = ?";
        
        $stmt = $conn->prepare($query);
        if (!$stmt) {
            throw new Exception("Prepare failed: " . $conn->error);
        }
        
        $stmt->bind_param(
            'ssiidisssi',
            $ten,
            $mo_ta,
            $id_dia_diem,
            $gia,
            $so_ngay,
            $so_nguoi_toi_da,
            $url_anh_chinh,
            $trang_thai,
            $ngay_khoi_hanh,
            $id
        );
        
        if (!$stmt->execute()) {
            throw new Exception("Execute failed: " . $stmt->error);
        }
        
        $stmt->close();
        
        echo json_encode([
            'success' => true,
            'message' => 'Cập nhật tour thành công'
        ], JSON_UNESCAPED_UNICODE);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Lỗi cập nhật tour: ' . $e->getMessage()
        ], JSON_UNESCAPED_UNICODE);
    }
}

/**
 * Tìm kiếm tour trong database
 */
function searchToursAPI() {
    global $conn;
    
    try {
        $keyword = isset($_GET['keyword']) ? trim($_GET['keyword']) : '';
        
        if (empty($keyword)) {
            throw new Exception("Từ khóa tìm kiếm không được để trống");
        }
        
        // Tìm kiếm theo tên, mô tả hoặc địa điểm
        $searchKeyword = '%' . $keyword . '%';
        
        $query = "SELECT DISTINCT t.* FROM tour t
                  LEFT JOIN dia_diem dd ON t.id_dia_diem = dd.id
                  WHERE t.ten LIKE ? OR t.mo_ta LIKE ? OR dd.ten LIKE ?
                  ORDER BY t.id DESC";
        
        $stmt = $conn->prepare($query);
        if (!$stmt) {
            throw new Exception("Prepare failed: " . $conn->error);
        }
        
        $stmt->bind_param('sss', $searchKeyword, $searchKeyword, $searchKeyword);
        $stmt->execute();
        $result = $stmt->get_result();
        
        $tours = [];
        while ($row = $result->fetch_assoc()) {
            $tours[] = formatTourDataForAPI($row);
        }
        
        $stmt->close();
        
        echo json_encode([
            'success' => true,
            'data' => $tours,
            'count' => count($tours)
        ], JSON_UNESCAPED_UNICODE);
        
    } catch (Exception $e) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Lỗi tìm kiếm: ' . $e->getMessage()
        ], JSON_UNESCAPED_UNICODE);
    }
}

/**
 * Định dạng dữ liệu tour để trả về API
 */
function formatTourDataForAPI($row) {
    $imagePath = '/img/' . $row['url_anh_chinh'];
    
    return [
        'id' => intval($row['id']),
        'name' => $row['ten'],
        'description' => $row['mo_ta'],
        'location' => getLocationName($row['id_dia_diem']),
        'price' => floatval($row['gia']),
        'price_formatted' => number_format($row['gia'], 0, ',', '.') . ' VND',
        'days' => $row['so_ngay'],
        'image' => $imagePath,
        'rating' => floatval($row['danh_gia']),
        'status' => $row['trang_thai'] === 'Hoạt động' ? 'active' : 'inactive',
        'status_text' => $row['trang_thai'],
        'duration' => $row['so_ngay'] . ' ngày',
        'start_date' => $row['ngay_khoi_hanh']
    ];
}

/**
 * Lấy danh sách đơn đặt tour/combo với phân trang, lọc và sắp xếp
 */
function getBookings() {
    global $conn;
    
    try {
        // Kiểm tra nếu có id parameter - lấy chi tiết booking cụ thể
        $bookingId = isset($_GET['id']) ? intval($_GET['id']) : 0;
        
        if ($bookingId > 0) {
            // Lấy chi tiết booking - với JOIN combo để lấy đầy đủ dữ liệu
            $query = "SELECT 
                        dt.id, 
                        dt.so_dat_tour,
                        dt.id_tour,
                        dt.id_goi_combo,
                        dt.id_nguoi_dung,
                        dt.ngay_tao AS ngay_dat,
                        dt.ngay_khoi_hanh,
                        dt.so_nguoi_lon,
                        dt.so_tre_em,
                        dt.phuong_thuc_thanh_toan,
                        dt.tong_tien,
                        dt.trang_thai,
                        CONCAT(nd.ten_dau, ' ', nd.ten_cuoi) AS customer_name,
                        nd.email AS customer_email,
                        nd.so_dien_thoai AS customer_phone,
                        nd.dia_chi AS customer_address,
                        nd.anh_dai_dien AS customer_avatar,
                        t.ten AS tour_name,
                        t.so_ngay AS tour_days,
                        t.gia AS tour_price,
                        dd_tour.ten AS tour_location,
                        gc.ten AS combo_name,
                        gc.thoi_gian_combo AS combo_days,
                        gc.gia_ban AS combo_price,
                        gc.gia_goc AS combo_price_original,
                        gc.id_dia_diem AS combo_dia_diem_id,
                        gc.ngay_khoi_hanh AS combo_ngay_khoi_hanh,
                        dd_combo.ten AS combo_location
                    FROM dat_tour dt
                    LEFT JOIN nguoi_dung nd ON dt.id_nguoi_dung = nd.id
                    LEFT JOIN tour t ON dt.id_tour = t.id
                    LEFT JOIN dia_diem dd_tour ON t.id_dia_diem = dd_tour.id
                    LEFT JOIN goi_combo gc ON dt.id_goi_combo = gc.id
                    LEFT JOIN dia_diem dd_combo ON gc.id_dia_diem = dd_combo.id
                    WHERE dt.id = ?";
            
            $stmt = $conn->prepare($query);
            if (!$stmt) {
                throw new Exception("Prepare failed: " . $conn->error);
            }
            
            $stmt->bind_param('i', $bookingId);
            $stmt->execute();
            $result = $stmt->get_result();
            
            $bookings = [];
            while ($row = $result->fetch_assoc()) {
                $bookings[] = formatBookingData($row);
            }
            $stmt->close();
            
            echo json_encode([
                'success' => true,
                'data' => $bookings
            ], JSON_UNESCAPED_UNICODE);
            return;
        }
        
        // Auto-update: Đánh dấu những tour có ngày khởi hành đã qua thành "Đã hoàn thành"
        $autoCompleteQuery = "UPDATE dat_tour 
                              SET trang_thai = 'Đã hoàn thành' 
                              WHERE ngay_khoi_hanh < CURDATE() 
                              AND trang_thai NOT IN ('Đã hủy', 'Đã hoàn thành')";
        $conn->query($autoCompleteQuery);
        
        // Lấy parameters từ GET
        $page = isset($_GET['page']) ? max(1, intval($_GET['page'])) : 1;
        $sort = isset($_GET['sort']) ? $_GET['sort'] : 'newest';
        $filter = isset($_GET['filter']) ? $_GET['filter'] : 'all';
        $month = isset($_GET['month']) ? $_GET['month'] : 'all';
        $limit = 10; // Số đơn mỗi trang
        
        // Tính offset
        $offset = ($page - 1) * $limit;
        
        // Xây dựng query - JOIN với user, tour, goi_combo, dia_diem (cho cả tour và combo)
        $query = "SELECT 
                    dt.id, 
                    dt.so_dat_tour,
                    dt.id_tour,
                    dt.id_goi_combo,
                    dt.id_nguoi_dung,
                    dt.ngay_tao AS ngay_dat,
                    dt.ngay_khoi_hanh,
                    dt.so_nguoi_lon,
                    dt.so_tre_em,
                    dt.phuong_thuc_thanh_toan,
                    dt.tong_tien,
                    dt.trang_thai,
                    CONCAT(nd.ten_dau, ' ', nd.ten_cuoi) AS customer_name,
                    nd.email AS customer_email,
                    nd.so_dien_thoai AS customer_phone,
                    nd.dia_chi AS customer_address,
                    nd.anh_dai_dien AS customer_avatar,
                    t.ten AS tour_name,
                    t.so_ngay AS tour_days,
                    t.gia AS tour_price,
                    dd_tour.ten AS tour_location,
                    gc.ten AS combo_name,
                    gc.thoi_gian_combo AS combo_days,
                    gc.gia_ban AS combo_price,
                    gc.gia_goc AS combo_price_original,
                    gc.id_dia_diem AS combo_dia_diem_id,
                    gc.ngay_khoi_hanh AS combo_ngay_khoi_hanh,
                    dd_combo.ten AS combo_location,
                    CASE 
                        WHEN dt.ngay_khoi_hanh > CURDATE() THEN 'Sắp diễn ra'
                        WHEN dt.ngay_khoi_hanh = CURDATE() THEN 'Đang diễn ra'
                        WHEN dt.ngay_khoi_hanh < CURDATE() THEN 'Đã hoàn thành'
                        ELSE 'Chưa xác định'
                    END AS departure_status,
                    DATEDIFF(dt.ngay_khoi_hanh, CURDATE()) AS days_until_departure
                FROM dat_tour dt
                LEFT JOIN nguoi_dung nd ON dt.id_nguoi_dung = nd.id
                LEFT JOIN tour t ON dt.id_tour = t.id
                LEFT JOIN dia_diem dd_tour ON t.id_dia_diem = dd_tour.id
                LEFT JOIN goi_combo gc ON dt.id_goi_combo = gc.id
                LEFT JOIN dia_diem dd_combo ON gc.id_dia_diem = dd_combo.id";
        
        // Filter theo status
        $queryWhere = " WHERE 1=1";
        if ($filter === 'pending') {
            $queryWhere .= " AND dt.trang_thai = 'Chờ xác nhận'";
        } elseif ($filter === 'pending_cancel') {
            $queryWhere .= " AND dt.trang_thai = 'Chờ Xác Nhận Hủy'";
        } elseif ($filter === 'confirmed') {
            $queryWhere .= " AND dt.trang_thai = 'Đã xác nhận'";
        } elseif ($filter === 'completed') {
            // Filter tour đã hoàn thành dựa trên ngày khởi hành < hôm nay
            $queryWhere .= " AND dt.ngay_khoi_hanh < CURDATE()";
        } elseif ($filter === 'cancelled') {
            $queryWhere .= " AND dt.trang_thai = 'Đã hủy'";
        }
        
        // Filter theo tháng khởi hành
        if ($month !== 'all') {
            $monthNum = intval($month);
            $queryWhere .= " AND MONTH(dt.ngay_khoi_hanh) = " . $monthNum;
        }
        
        // Sắp xếp
        $queryOrder = " ORDER BY";
        switch($sort) {
            case 'price-asc':
            case 'price_low':
                $queryOrder .= " dt.tong_tien ASC";
                break;
            case 'price-desc':
            case 'price_high':
                $queryOrder .= " dt.tong_tien DESC";
                break;
            case 'oldest':
                $queryOrder .= " dt.ngay_tao ASC";
                break;
            case 'newest':
            default:
                $queryOrder .= " dt.ngay_tao DESC";
        }
        
        // Thêm limit
        $queryFull = $query . $queryWhere . $queryOrder . " LIMIT ? OFFSET ?";
        
        // Chuẩn bị statement
        $stmt = $conn->prepare($queryFull);
        if (!$stmt) {
            throw new Exception("Prepare failed: " . $conn->error);
        }
        
        $stmt->bind_param('ii', $limit, $offset);
        $stmt->execute();
        $result = $stmt->get_result();
        
        // Lấy dữ liệu booking
        $bookings = [];
        while ($row = $result->fetch_assoc()) {
            $bookings[] = formatBookingData($row);
        }
        $stmt->close();
        
        // Lấy tổng số booking để tính pagination
        $countQuery = "SELECT COUNT(*) as total FROM dat_tour dt" . $queryWhere;
        $countResult = $conn->query($countQuery);
        if (!$countResult) {
            throw new Exception("Count query failed: " . $conn->error);
        }
        
        $countRow = $countResult->fetch_assoc();
        $totalBookings = isset($countRow['total']) ? intval($countRow['total']) : 0;
        
        // Tính pagination
        $totalPages = ceil($totalBookings / $limit);
        
        // Lấy thống kê
        $stats = getBookingStats();
        
        // Trả response
        echo json_encode([
            'success' => true,
            'data' => $bookings,
            'stats' => $stats,
            'pagination' => [
                'current_page' => $page,
                'total_pages' => $totalPages,
                'total_items' => $totalBookings,
                'items_per_page' => $limit,
                'has_prev' => $page > 1,
                'has_next' => $page < $totalPages
            ]
        ], JSON_UNESCAPED_UNICODE);
        
    } catch (Exception $e) {
        error_log("ERROR in getBookings: " . $e->getMessage());
        error_log("SQL Query: " . (isset($queryFull) ? $queryFull : 'Not set'));
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Lỗi lấy dữ liệu: ' . $e->getMessage(),
            'debug' => isset($queryFull) ? $queryFull : 'Query not prepared'
        ], JSON_UNESCAPED_UNICODE);
    }
}

/**
 * Lấy danh sách khởi hành sắp tới (tours sắp khởi hành)
 */
function getUpcomingDepartures() {
    global $conn;
    
    try {
        $limit = isset($_GET['limit']) ? max(1, intval($_GET['limit'])) : 5;
        $today = date('Y-m-d');
        
        // Query lấy booking sắp khởi hành (ngay_khoi_hanh trong tương lai, trạng thái đã xác nhận)
        $query = "SELECT 
                    dt.id, 
                    dt.so_dat_tour,
                    dt.id_tour,
                    dt.id_goi_combo,
                    dt.ngay_khoi_hanh,
                    dt.so_nguoi_lon,
                    dt.so_tre_em,
                    dt.tong_tien,
                    dt.trang_thai,
                    COALESCE(t.ten, gc.ten) AS ten_tour,
                    COALESCE(t.url_anh_chinh, gc.url_anh) AS anh,
                    COALESCE(dd_tour.ten, dd_combo.ten) AS dia_diem,
                    t.id AS id_tour_check
                FROM dat_tour dt
                LEFT JOIN tour t ON dt.id_tour = t.id
                LEFT JOIN dia_diem dd_tour ON t.id_dia_diem = dd_tour.id
                LEFT JOIN goi_combo gc ON dt.id_goi_combo = gc.id
                LEFT JOIN dia_diem dd_combo ON gc.id_dia_diem = dd_combo.id
                WHERE dt.ngay_khoi_hanh > ? 
                  AND dt.trang_thai IN ('Đã xác nhận', 'Chờ xác nhận')
                ORDER BY dt.ngay_khoi_hanh ASC
                LIMIT ?";
        
        $stmt = $conn->prepare($query);
        if (!$stmt) {
            throw new Exception("Prepare failed: " . $conn->error);
        }
        
        $stmt->bind_param('si', $today, $limit);
        $stmt->execute();
        $result = $stmt->get_result();
        
        $departures = [];
        while ($row = $result->fetch_assoc()) {
            // Xử lý đường dẫn ảnh
            $anh = $row['anh'] ?? '';
            
            if (!$anh) {
                // Nếu không có ảnh, dùng placeholder
                $anh = 'https://images.unsplash.com/photo-1488646953014-85cb44e7b915?w=100&h=100&fit=crop';
            } elseif (!filter_var($anh, FILTER_VALIDATE_URL)) {
                // Nếu không phải URL (tức là tên file từ database)
                // Thêm đuôi .jpg nếu chưa có
                if (!preg_match('/\.(jpg|jpeg|png|gif|webp)$/i', $anh)) {
                    $anh = $anh . '.jpg';
                }
                // Thêm đường dẫn từ /img/ (trực tiếp ở htdocs/img)
                $anh = '/img/' . $anh;
            }
            
            $departures[] = [
                'id' => $row['id'],
                'so_dat_tour' => $row['so_dat_tour'],
                'ten_tour' => $row['ten_tour'] ?? 'Tour không xác định',
                'anh' => $anh,
                'ngay_khoi_hanh' => $row['ngay_khoi_hanh'],
                'dia_diem' => $row['dia_diem'] ?? 'Không xác định',
                'so_nguoi' => (int)$row['so_nguoi_lon'] + (int)$row['so_tre_em'],
                'trang_thai' => $row['trang_thai']
            ];
        }
        $stmt->close();
        
        echo json_encode([
            'success' => true,
            'data' => $departures
        ], JSON_UNESCAPED_UNICODE);
        
    } catch (Exception $e) {
        error_log("ERROR in getUpcomingDepartures: " . $e->getMessage());
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Lỗi lấy dữ liệu: ' . $e->getMessage()
        ], JSON_UNESCAPED_UNICODE);
    }
}

/**
 * Xóa đơn đặt tour
 */
function deleteBooking() {
    global $conn;
    
    try {
        $id = isset($_POST['id']) ? intval($_POST['id']) : 0;
        
        if ($id <= 0) {
            throw new Exception("ID đơn đặt không hợp lệ");
        }
        
        // Delete booking
        $query = "DELETE FROM dat_tour WHERE id = ?";
        $stmt = $conn->prepare($query);
        
        if (!$stmt) {
            throw new Exception("Prepare failed: " . $conn->error);
        }
        
        $stmt->bind_param('i', $id);
        
        if (!$stmt->execute()) {
            throw new Exception("Execute failed: " . $stmt->error);
        }
        
        $stmt->close();
        
        echo json_encode([
            'success' => true,
            'message' => 'Xóa đơn đặt thành công',
            'id' => $id
        ], JSON_UNESCAPED_UNICODE);
        
    } catch (Exception $e) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => $e->getMessage()
        ], JSON_UNESCAPED_UNICODE);
    }
}

/**
 * Xác nhận đặt tour (cập nhật trạng thái)
 */
function confirmBooking() {
    global $conn;
    
    try {
        $id = isset($_POST['id']) ? intval($_POST['id']) : 0;
        $trang_thai = isset($_POST['trang_thai']) ? $_POST['trang_thai'] : 'Đã xác nhận';
        
        if ($id <= 0) {
            throw new Exception("ID đơn đặt không hợp lệ");
        }
        
        // Update booking status
        $query = "UPDATE dat_tour SET trang_thai = ? WHERE id = ?";
        $stmt = $conn->prepare($query);
        
        if (!$stmt) {
            throw new Exception("Prepare failed: " . $conn->error);
        }
        
        $stmt->bind_param('si', $trang_thai, $id);
        
        if (!$stmt->execute()) {
            throw new Exception("Execute failed: " . $stmt->error);
        }
        
        $stmt->close();
        
        echo json_encode([
            'success' => true,
            'message' => 'Xác nhận đơn đặt thành công',
            'id' => $id
        ], JSON_UNESCAPED_UNICODE);
        
    } catch (Exception $e) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => $e->getMessage()
        ], JSON_UNESCAPED_UNICODE);
    }
}

/**
 * Cập nhật thông tin đặt tour (khách hàng, số người)
 */
function updateBooking() {
    global $conn;
    
    try {
        $id = isset($_POST['id']) ? intval($_POST['id']) : 0;
        $customer_name = isset($_POST['customer_name']) ? $_POST['customer_name'] : '';
        $customer_email = isset($_POST['customer_email']) ? $_POST['customer_email'] : '';
        $customer_phone = isset($_POST['customer_phone']) ? $_POST['customer_phone'] : '';
        $customer_address = isset($_POST['customer_address']) ? $_POST['customer_address'] : '';
        $guests = isset($_POST['guests']) ? intval($_POST['guests']) : 0;
        
        if ($id <= 0) {
            throw new Exception("ID đơn đặt không hợp lệ");
        }
        
        if ($guests <= 0) {
            throw new Exception("Số người phải lớn hơn 0");
        }
        
        // Lấy customer ID từ booking
        $query = "SELECT id_nguoi_dung FROM dat_tour WHERE id = ?";
        $stmt = $conn->prepare($query);
        $stmt->bind_param('i', $id);
        $stmt->execute();
        $result = $stmt->get_result();
        $row = $result->fetch_assoc();
        $customer_id = $row['id_nguoi_dung'];
        $stmt->close();
        
        // Cập nhật thông tin khách hàng
        $query = "UPDATE nguoi_dung SET ten_dau = ?, email = ?, so_dien_thoai = ?, dia_chi = ? WHERE id = ?";
        $stmt = $conn->prepare($query);
        
        if (!$stmt) {
            throw new Exception("Prepare failed: " . $conn->error);
        }
        
        $stmt->bind_param('ssssi', $customer_name, $customer_email, $customer_phone, $customer_address, $customer_id);
        
        if (!$stmt->execute()) {
            throw new Exception("Execute failed: " . $stmt->error);
        }
        
        $stmt->close();
        
        // Cập nhật số người đặt tour
        $query = "UPDATE dat_tour SET so_nguoi_lon = ? WHERE id = ?";
        $stmt = $conn->prepare($query);
        
        if (!$stmt) {
            throw new Exception("Prepare failed: " . $conn->error);
        }
        
        $stmt->bind_param('ii', $guests, $id);
        
        if (!$stmt->execute()) {
            throw new Exception("Execute failed: " . $stmt->error);
        }
        
        $stmt->close();
        
        echo json_encode([
            'success' => true,
            'message' => 'Cập nhật thông tin thành công'
        ], JSON_UNESCAPED_UNICODE);
        
    } catch (Exception $e) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'error' => $e->getMessage()
        ], JSON_UNESCAPED_UNICODE);
    }
}

/**
 * Lấy thống kê số lượng đơn đặt theo trạng thái
 */
function getBookingStats() {
    global $conn;
    
    try {
        // Tổng số đơn đặt
        $query = "SELECT COUNT(*) as total FROM dat_tour";
        $result = $conn->query($query);
        $row = $result->fetch_assoc();
        $totalBookings = isset($row['total']) ? intval($row['total']) : 0;
        
        // Đã xác nhận
        $query = "SELECT COUNT(*) as count FROM dat_tour WHERE trang_thai = 'Đã xác nhận'";
        $result = $conn->query($query);
        $row = $result->fetch_assoc();
        $confirmedBookings = isset($row['count']) ? intval($row['count']) : 0;
        
        // Chờ xác nhận
        $query = "SELECT COUNT(*) as count FROM dat_tour WHERE trang_thai = 'Chờ xác nhận' OR trang_thai = 'Chờ Xác Nhận Hủy'";
        $result = $conn->query($query);
        $row = $result->fetch_assoc();
        $pendingBookings = isset($row['count']) ? intval($row['count']) : 0;
        
        // Tổng doanh thu
        $query = "SELECT SUM(tong_tien) as total FROM dat_tour";
        $result = $conn->query($query);
        $row = $result->fetch_assoc();
        $totalRevenue = isset($row['total']) ? floatval($row['total']) : 0;
        
        return [
            'total_bookings' => $totalBookings,
            'confirmed_bookings' => $confirmedBookings,
            'pending_bookings' => $pendingBookings,
            'total_revenue' => $totalRevenue,
            'total_revenue_formatted' => number_format($totalRevenue, 0, ',', '.') . ' VND'
        ];
    } catch (Exception $e) {
        error_log("Error getting booking stats: " . $e->getMessage());
        return [
            'total_bookings' => 0,
            'confirmed_bookings' => 0,
            'pending_bookings' => 0,
            'total_revenue' => 0,
            'total_revenue_formatted' => '0 VND'
        ];
    }
}

/**
 * Format dữ liệu booking để trả về client
 */
function formatBookingData($row) {
    $totalGuests = intval($row['so_nguoi_lon']) + intval($row['so_tre_em']);
    $toursName = '';
    $toursDuration = '';
    $tourPrice = 0;
    $tourLocation = '';
    $tourDays = 0;
    
    // Kiểm tra tour hay combo
    $isTour = !empty($row['tour_name']) && intval($row['id_tour']) > 0;
    $isCombo = !empty($row['combo_name']) && intval($row['id_goi_combo']) > 0;
    
    if ($isTour) {
        $toursName = $row['tour_name'];
        $tourDays = intval($row['tour_days']);
        if ($tourDays > 0) {
            $toursDuration = $tourDays . ' ngày ' . ($tourDays - 1) . ' đêm';
        } else {
            $toursDuration = '';
        }
        $tourPrice = floatval($row['tour_price']);
        $tourLocation = isset($row['tour_location']) ? $row['tour_location'] : '';
    } elseif ($isCombo) {
        $toursName = $row['combo_name'];
        $toursDuration = isset($row['combo_days']) ? $row['combo_days'] : '';
        // Lấy số ngày từ combo_days (ví dụ '2N1D' -> 2 days, '3N2D' -> 3 days)
        if (!empty($row['combo_days'])) {
            // Thử regex đầu tiên: tìm pattern như '2N1D'
            if (preg_match('/(\d+)N(\d+)D/', $row['combo_days'], $matches)) {
                $tourDays = intval($matches[1]); // $matches[1] là số ngày
            } else {
                // Fallback: nếu không match, tìm số đầu tiên trong string
                if (preg_match('/\d+/', $row['combo_days'], $matches)) {
                    $tourDays = intval($matches[0]);
                }
            }
        }
        // Combo có giá bán (gia_ban)
        $tourPrice = floatval($row['combo_price']);
        $tourLocation = isset($row['combo_location']) ? $row['combo_location'] : '';
        // Bonus: lấy ngày khởi hành từ combo nếu có
        if (!empty($row['combo_ngay_khoi_hanh'])) {
            $row['ngay_khoi_hanh'] = $row['combo_ngay_khoi_hanh'];
        }
    }
    
    // Return actual status from database (Vietnamese)
    // Use trang_thai directly for consistency with frontend
    $status = !empty($row['trang_thai']) ? trim($row['trang_thai']) : 'Chờ xác nhận';
    
    $customerName = isset($row['customer_name']) && !empty($row['customer_name']) ? $row['customer_name'] : 'Khách hàng';
    $customerEmail = isset($row['customer_email']) && !empty($row['customer_email']) ? $row['customer_email'] : 'N/A';
    $customerPhone = isset($row['customer_phone']) && !empty($row['customer_phone']) ? $row['customer_phone'] : '-';
    $customerAddress = isset($row['customer_address']) && !empty($row['customer_address']) ? $row['customer_address'] : '-';
    
    // Normalize avatar path from database
    $avatarPath = '../../USER/image/Avatar.png';
    if (isset($row['customer_avatar']) && !empty($row['customer_avatar'])) {
        $avatar = trim($row['customer_avatar']);
        
        // Remove any existing path prefixes
        if (strpos($avatar, '../') === 0 || strpos($avatar, '/') === 0) {
            $avatar = basename($avatar);
        }
        
        // Add .jpg extension if missing
        if (!preg_match('/\.(jpg|jpeg|png|gif)$/i', $avatar)) {
            $avatar .= '.jpg';
        }
        
        // Build full path
        $avatarPath = '../../USER/image/' . $avatar;
    }
    
    // FALLBACK: Nếu combo mà vẫn không có tourDays, thử lấy lần nữa
    if ($isCombo && $tourDays == 0 && !empty($row['combo_days'])) {
        if (preg_match('/\d+/', $row['combo_days'], $matches)) {
            $tourDays = intval($matches[0]);
        }
    }
    
    return [
        'id' => intval($row['id']),
        'so_dat_tour' => $row['so_dat_tour'],
        'customerName' => $customerName,
        'customerEmail' => $customerEmail,
        'customerPhone' => $customerPhone,
        'customerAddress' => $customerAddress,
        'customerAvatar' => $avatarPath,
        'tourName' => $toursName,
        'tourLocation' => $tourLocation,
        'tourPrice' => number_format($tourPrice, 0, ',', '.') . ' VND',
        'tourDuration' => $toursDuration,
        'bookingDate' => date('d/m/Y', strtotime($row['ngay_dat'])),
        'departureDate' => isset($row['ngay_khoi_hanh']) ? date('d/m/Y', strtotime($row['ngay_khoi_hanh'])) : '-',
        'guests' => $totalGuests,
        'days' => $tourDays,
        'paymentMethod' => $row['phuong_thuc_thanh_toan'],
        'total' => number_format($row['tong_tien'], 0, ',', '.') . ' VND',
        'totalRaw' => intval($row['tong_tien']),
        'status' => $status,
        'status_text' => $row['trang_thai'],
        'departureStatus' => isset($row['departure_status']) ? $row['departure_status'] : 'Chưa xác định',
        'daysUntilDeparture' => isset($row['days_until_departure']) ? intval($row['days_until_departure']) : null
    ];
}

/**
 * Format dữ liệu tour để trả về client
 */
function formatTourData($row) {
    // Fix đường dẫn ảnh: thêm /img/ vào đầu
    $imagePath = '/img/' . $row['url_anh_chinh'];
    
    return [
        'id' => intval($row['id']),
        'name' => $row['ten'],
        'description' => $row['mo_ta'],
        'location' => getLocationName($row['id_dia_diem']),
        'price' => floatval($row['gia']),
        'price_formatted' => number_format($row['gia'], 0, ',', '.') . ' VND',
        'days' => $row['so_ngay'],
        'image' => $imagePath,
        'rating' => floatval($row['danh_gia']),
        'rating_count' => intval($row['so_danh_gia']),
        'status' => $row['trang_thai'] === 'Hoạt động' ? 'active' : 'inactive',
        'status_text' => $row['trang_thai'],
        'duration' => $row['so_ngay'] . ' ngày',
        'start_date' => $row['ngay_khoi_hanh']
    ];
}

/**
 * Lấy tên địa điểm từ ID
 */
function getLocationName($locationId) {
    global $conn;
    
    if (!$locationId) {
        return "Chưa xác định";
    }
    
    $query = "SELECT ten FROM dia_diem WHERE id = ?";
    $stmt = $conn->prepare($query);
    
    if (!$stmt) {
        error_log("Query prepare failed: " . $conn->error);
        return "Chưa xác định";
    }
    
    $stmt->bind_param('i', $locationId);
    if (!$stmt->execute()) {
        error_log("Query execute failed: " . $stmt->error);
        $stmt->close();
        return "Chưa xác định";
    }
    
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        $row = $result->fetch_assoc();
        $name = $row['ten'] ?: "Chưa xác định";
    } else {
        error_log("Location ID not found: " . $locationId);
        $name = "Chưa xác định";
    }
    
    $stmt->close();
    return $name;
}

/**
 * Lấy danh sách tất cả điểm đến từ database
 */
function getDestinations() {
    global $conn;
    
    try {
        $query = "SELECT id, ten FROM dia_diem ORDER BY ten ASC";
        $result = $conn->query($query);
        
        if (!$result) {
            throw new Exception("Query failed: " . $conn->error);
        }
        
        $destinations = [];
        while ($row = $result->fetch_assoc()) {
            $destinations[] = [
                'id' => intval($row['id']),
                'name' => $row['ten']
            ];
        }
        
        echo json_encode([
            'success' => true,
            'data' => $destinations
        ], JSON_UNESCAPED_UNICODE);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Lỗi lấy danh sách điểm đến: ' . $e->getMessage()
        ], JSON_UNESCAPED_UNICODE);
    }
}

/**
 * Lấy danh sách tất cả loại tour từ database
 */
function getTourTypes() {
    global $conn;
    
    try {
        $query = "SELECT DISTINCT loai_tour FROM tour 
                  WHERE loai_tour IS NOT NULL AND loai_tour != ''
                  ORDER BY loai_tour ASC";
        $result = $conn->query($query);
        
        if (!$result) {
            throw new Exception("Query failed: " . $conn->error);
        }
        
        $tourTypes = [];
        while ($row = $result->fetch_assoc()) {
            $tourTypes[] = [
                'value' => $row['loai_tour'],
                'label' => $row['loai_tour']
            ];
        }
        
        echo json_encode([
            'success' => true,
            'data' => $tourTypes
        ], JSON_UNESCAPED_UNICODE);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Lỗi lấy danh sách loại tour: ' . $e->getMessage()
        ], JSON_UNESCAPED_UNICODE);
    }
}

/**
 * Lấy danh sách khách hàng từ database với phân trang
 */
function getUsers() {
    global $conn;
    
    try {
        // Lấy parameters từ GET
        $page = isset($_GET['page']) ? max(1, intval($_GET['page'])) : 1;
        $limit = 10; // Số khách hàng mỗi trang
        
        // Tính offset
        $offset = ($page - 1) * $limit;
        
        // Xây dựng query - chỉ lấy users (không admin)
        $query = "SELECT id, ten_dau, ten_cuoi, email, so_dien_thoai, anh_dai_dien, 
                         gioi_tinh, ngay_sinh, quoc_gia, dia_chi
                  FROM nguoi_dung 
                  WHERE vai_tro = 'user'
                  ORDER BY id DESC
                  LIMIT ? OFFSET ?";
        
        // Chuẩn bị statement
        $stmt = $conn->prepare($query);
        if (!$stmt) {
            throw new Exception("Prepare failed: " . $conn->error);
        }
        
        $stmt->bind_param('ii', $limit, $offset);
        $stmt->execute();
        $result = $stmt->get_result();
        
        // Lấy dữ liệu khách hàng
        $users = [];
        while ($row = $result->fetch_assoc()) {
            $users[] = formatUserData($row);
        }
        $stmt->close();
        
        // Lấy tổng số khách hàng để tính pagination (chỉ users)
        $countQuery = "SELECT COUNT(*) as total FROM nguoi_dung WHERE vai_tro = 'user'";
        $countResult = $conn->query($countQuery);
        if (!$countResult) {
            throw new Exception("Count query failed: " . $conn->error);
        }
        
        $countRow = $countResult->fetch_assoc();
        $totalUsers = isset($countRow['total']) ? intval($countRow['total']) : 0;
        
        // Tính pagination
        $totalPages = ceil($totalUsers / $limit);
        
        // Trả response
        echo json_encode([
            'success' => true,
            'data' => $users,
            'pagination' => [
                'current_page' => $page,
                'total_pages' => $totalPages,
                'total_items' => $totalUsers,
                'items_per_page' => $limit,
                'has_prev' => $page > 1,
                'has_next' => $page < $totalPages
            ]
        ], JSON_UNESCAPED_UNICODE);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Lỗi lấy danh sách khách hàng: ' . $e->getMessage()
        ], JSON_UNESCAPED_UNICODE);
    }
}

/**
 * Format dữ liệu khách hàng để trả về client
 */
function formatUserData($row) {
    // Normalize avatar path from database
    $avatarPath = 'Avatar.png';
    if (isset($row['anh_dai_dien']) && !empty($row['anh_dai_dien'])) {
        $avatar = trim($row['anh_dai_dien']);
        
        // Remove any existing path prefixes
        if (strpos($avatar, '../') === 0 || strpos($avatar, '/') === 0) {
            $avatar = basename($avatar);
        }
        
        // Add .jpg extension if missing
        if (!preg_match('/\.(jpg|jpeg|png|gif)$/i', $avatar)) {
            $avatar .= '.jpg';
        }
        
        $avatarPath = $avatar;
    }
    
    return [
        'id' => intval($row['id']),
        'firstName' => $row['ten_dau'],
        'lastName' => $row['ten_cuoi'],
        'fullName' => trim($row['ten_dau'] . ' ' . $row['ten_cuoi']),
        'email' => $row['email'],
        'phone' => $row['so_dien_thoai'],
        'avatar' => $avatarPath,
        'gender' => $row['gioi_tinh'],
        'birthDate' => $row['ngay_sinh'],
        'country' => $row['quoc_gia'],
        'address' => $row['dia_chi']
    ];
}

/**
 * Lấy danh sách thanh toán/đơn đặt từ database với phân trang
 */
function getPayments() {
    global $conn;
    
    try {
        // Lấy parameters từ GET
        $page = isset($_GET['page']) ? max(1, intval($_GET['page'])) : 1;
        $sort = isset($_GET['sort']) ? $_GET['sort'] : 'newest';
        $filter = isset($_GET['filter']) ? $_GET['filter'] : 'all';
        $paymentMethod = isset($_GET['payment_method']) ? $_GET['payment_method'] : 'all';
        $limit = 10; // Số thanh toán mỗi trang
        
        // Tính offset
        $offset = ($page - 1) * $limit;
        
        // Xây dựng query cơ bản
        $query = "SELECT dt.id, 
                         CONCAT(nd.ten_dau, ' ', nd.ten_cuoi) AS customer_name,
                         nd.email AS customer_email,
                         nd.anh_dai_dien AS customer_avatar,
                         t.ten AS tour_name,
                         t.so_ngay,
                         gc.ten AS combo_name,
                         gc.thoi_gian_combo AS combo_days,
                         dt.tong_tien,
                         dt.ngay_tao,
                         dt.trang_thai,
                         dt.phuong_thuc_thanh_toan,
                         dt.so_nguoi_lon,
                         dt.so_tre_em
                FROM dat_tour dt
                LEFT JOIN nguoi_dung nd ON dt.id_nguoi_dung = nd.id
                LEFT JOIN tour t ON dt.id_tour = t.id
                LEFT JOIN goi_combo gc ON dt.id_goi_combo = gc.id";
        
        // Filter theo status - dựa trên payment method và booking status
        // success: NOT "Đã hủy" AND NOT ("Tiền mặt" OR "Thanh toán tại văn phòng")
        // pending: ("Tiền mặt" OR "Thanh toán tại văn phòng")
        // failed: "Đã hủy"
        $queryWhere = " WHERE 1=1";
        if ($filter === 'success') {
            $queryWhere .= " AND dt.trang_thai != 'Đã hủy' 
                            AND dt.phuong_thuc_thanh_toan NOT IN ('Tiền mặt', 'Thanh toán tại văn phòng')";
        } elseif ($filter === 'pending') {
            $queryWhere .= " AND (dt.phuong_thuc_thanh_toan = 'Tiền mặt' OR dt.phuong_thuc_thanh_toan = 'Thanh toán tại văn phòng')";
        } elseif ($filter === 'failed') {
            $queryWhere .= " AND dt.trang_thai = 'Đã hủy'";
        }
        
        // Filter theo phương thức thanh toán
        if ($paymentMethod !== 'all' && !empty($paymentMethod)) {
            $paymentMethod = $conn->real_escape_string($paymentMethod);
            $queryWhere .= " AND dt.phuong_thuc_thanh_toan = '{$paymentMethod}'";
        }
        $queryOrder = " ORDER BY";
        switch($sort) {
            case 'oldest':
                $queryOrder .= " dt.ngay_tao ASC";
                break;
            case 'amount_high':
                $queryOrder .= " dt.tong_tien DESC";
                break;
            case 'amount_low':
                $queryOrder .= " dt.tong_tien ASC";
                break;
            default: // 'newest'
                $queryOrder .= " dt.ngay_tao DESC";
        }
        
        // Thêm limit
        $queryFull = $query . $queryWhere . $queryOrder . " LIMIT ? OFFSET ?";
        
        // Chuẩn bị statement
        $stmt = $conn->prepare($queryFull);
        if (!$stmt) {
            throw new Exception("Prepare failed: " . $conn->error);
        }
        
        $stmt->bind_param('ii', $limit, $offset);
        $stmt->execute();
        $result = $stmt->get_result();
        
        // Lấy dữ liệu thanh toán
        $payments = [];
        while ($row = $result->fetch_assoc()) {
            $payments[] = formatPaymentData($row);
        }
        $stmt->close();
        
        // Lấy tổng số thanh toán để tính pagination
        $countQuery = "SELECT COUNT(*) as total FROM dat_tour dt" . $queryWhere;
        $countResult = $conn->query($countQuery);
        if (!$countResult) {
            throw new Exception("Count query failed: " . $conn->error);
        }
        
        $countRow = $countResult->fetch_assoc();
        $totalPayments = isset($countRow['total']) ? intval($countRow['total']) : 0;
        
        // Tính pagination
        $totalPages = ceil($totalPayments / $limit);
        
        // Lấy thống kê thanh toán
        $stats = getPaymentStats();
        
        // Trả response
        echo json_encode([
            'success' => true,
            'data' => $payments,
            'stats' => $stats,
            'pagination' => [
                'current_page' => $page,
                'total_pages' => $totalPages,
                'total_items' => $totalPayments,
                'items_per_page' => $limit,
                'has_prev' => $page > 1,
                'has_next' => $page < $totalPages
            ]
        ], JSON_UNESCAPED_UNICODE);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Lỗi lấy dữ liệu thanh toán: ' . $e->getMessage()
        ], JSON_UNESCAPED_UNICODE);
    }
}

/**
 * Format dữ liệu thanh toán để trả về client
 */
function formatPaymentData($row) {
    $totalGuests = intval($row['so_nguoi_lon']) + intval($row['so_tre_em']);
    $tourName = '';
    $tourDuration = '';
    
    if (!empty($row['tour_name'])) {
        $tourName = $row['tour_name'];
        $tourDuration = intval($row['so_ngay']) . ' ngày ' . (intval($row['so_ngay']) - 1) . ' đêm';
    } elseif (!empty($row['combo_name'])) {
        $tourName = $row['combo_name'];
        $tourDuration = $row['combo_days'];
    }
    
    // Xác định payment status dựa trên booking status và payment method
    // Nếu tour "Đã hủy" → status: 'failed' (Bồi thường)
    // Nếu "Tiền mặt" hoặc "Thanh toán tại văn phòng" → status: 'pending' (Chờ xử lí)
    // Mặc định → status: 'success' (Đã thanh toán)
    if ($row['trang_thai'] === 'Đã hủy') {
        $paymentStatus = 'failed';
    } elseif (trim($row['phuong_thuc_thanh_toan']) === 'Tiền mặt' || 
              trim($row['phuong_thuc_thanh_toan']) === 'Thanh toán tại văn phòng') {
        $paymentStatus = 'pending';
    } else {
        // Mặc định: Đã thanh toán
        $paymentStatus = 'success';
    }
    
    // Normalize avatar path
    $avatarPath = 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=50&h=50&fit=crop';
    if (isset($row['customer_avatar']) && !empty($row['customer_avatar'])) {
        $avatar = trim($row['customer_avatar']);
        if (strpos($avatar, '../') === 0 || strpos($avatar, '/') === 0) {
            $avatar = basename($avatar);
        }
        if (!preg_match('/\.(jpg|jpeg|png|gif)$/i', $avatar)) {
            $avatar .= '.jpg';
        }
        $avatarPath = '../../USER/image/' . $avatar;
    }
    
    $customerName = isset($row['customer_name']) && !empty($row['customer_name']) ? $row['customer_name'] : 'Khách hàng';
    $customerEmail = isset($row['customer_email']) && !empty($row['customer_email']) ? $row['customer_email'] : 'N/A';
    
    // Mảng hỗ trợ các phương thức thanh toán từ DB
    $paymentMethod = trim($row['phuong_thuc_thanh_toan']);
    $paymentMethodDisplay = $paymentMethod; // Hiển thị tên gốc từ DB
    
    return [
        'id' => intval($row['id']),
        'transactionId' => 'TT-' . str_pad(intval($row['id']), 3, '0', STR_PAD_LEFT),
        'customerName' => $customerName,
        'customerEmail' => $customerEmail,
        'customerAvatar' => $avatarPath,
        'tourName' => $tourName,
        'tourDuration' => $tourDuration,
        'paymentMethod' => $paymentMethod,
        'paymentMethodName' => $paymentMethodDisplay,
        'amount' => floatval($row['tong_tien']),
        'amount_formatted' => number_format($row['tong_tien'], 0, ',', '.') . ' VND',
        'paymentDate' => date('d/m/Y', strtotime($row['ngay_tao'])),
        'paymentDateTime' => $row['ngay_tao'],
        'status' => $paymentStatus,
        'status_text' => $row['trang_thai'],
        'so_nguoi_lon' => intval($row['so_nguoi_lon']),
        'so_tre_em' => intval($row['so_tre_em']),
        'total_guests' => $totalGuests
    ];
}

/**
 * Lấy danh sách phương thức thanh toán từ database
 */
function getPaymentMethods() {
    global $conn;
    
    try {
        $query = "SELECT DISTINCT phuong_thuc_thanh_toan 
                  FROM dat_tour 
                  WHERE phuong_thuc_thanh_toan IS NOT NULL 
                  AND phuong_thuc_thanh_toan != ''
                  ORDER BY phuong_thuc_thanh_toan ASC";
        
        $result = $conn->query($query);
        
        if (!$result) {
            throw new Exception("Query failed: " . $conn->error);
        }
        
        $methods = [];
        while ($row = $result->fetch_assoc()) {
            $methods[] = $row['phuong_thuc_thanh_toan'];
        }
        
        return [
            'success' => true,
            'data' => $methods,
            'message' => 'Lấy danh sách phương thức thanh toán thành công'
        ];
    } catch (Exception $e) {
        return [
            'success' => false,
            'data' => [],
            'message' => $e->getMessage()
        ];
    }
}

/**
 * Xác nhận thanh toán thành công
 */
function confirmPayment() {
    global $conn;
    
    try {
        $requestBody = json_decode(file_get_contents('php://input'), true);
        $paymentId = isset($requestBody['payment_id']) ? intval($requestBody['payment_id']) : 0;
        
        if ($paymentId <= 0) {
            throw new Exception("ID thanh toán không hợp lệ");
        }
        
        // Cập nhật trạng thái thanh toán thành "Đã xác nhận"
        $query = "UPDATE dat_tour SET trang_thai = 'Đã xác nhận' WHERE id = ?";
        $stmt = $conn->prepare($query);
        if (!$stmt) {
            throw new Exception("Prepare failed: " . $conn->error);
        }
        
        $stmt->bind_param('i', $paymentId);
        if (!$stmt->execute()) {
            throw new Exception("Execute failed: " . $stmt->error);
        }
        
        $stmt->close();
        
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'message' => 'Xác nhận thanh toán thành công'
        ], JSON_UNESCAPED_UNICODE);
        
    } catch (Exception $e) {
        error_log("ERROR in confirmPayment: " . $e->getMessage());
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Lỗi xác nhận thanh toán: ' . $e->getMessage()
        ], JSON_UNESCAPED_UNICODE);
    }
}

/**
 * Xóa thanh toán
 */
function deletePayment() {
    global $conn;
    
    try {
        $requestBody = json_decode(file_get_contents('php://input'), true);
        $paymentId = isset($requestBody['payment_id']) ? intval($requestBody['payment_id']) : 0;
        
        if ($paymentId <= 0) {
            throw new Exception("ID thanh toán không hợp lệ");
        }
        
        // Xóa thanh toán
        $query = "DELETE FROM dat_tour WHERE id = ?";
        $stmt = $conn->prepare($query);
        if (!$stmt) {
            throw new Exception("Prepare failed: " . $conn->error);
        }
        
        $stmt->bind_param('i', $paymentId);
        if (!$stmt->execute()) {
            throw new Exception("Execute failed: " . $stmt->error);
        }
        
        $stmt->close();
        
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'message' => 'Xóa thanh toán thành công'
        ], JSON_UNESCAPED_UNICODE);
        
    } catch (Exception $e) {
        error_log("ERROR in deletePayment: " . $e->getMessage());
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Lỗi xóa thanh toán: ' . $e->getMessage()
        ], JSON_UNESCAPED_UNICODE);
    }
}

/**
 * Lấy thống kê thanh toán
 */
function getPaymentStats() {
    global $conn;
    
    try {
        // Tổng doanh thu
        $query = "SELECT SUM(tong_tien) as total FROM dat_tour";
        $result = $conn->query($query);
        $row = $result->fetch_assoc();
        $totalAmount = isset($row['total']) ? floatval($row['total']) : 0;
        
        // Đã xác nhận (thành công)
        $query = "SELECT COUNT(*) as count FROM dat_tour WHERE trang_thai = 'Đã xác nhận'";
        $result = $conn->query($query);
        $row = $result->fetch_assoc();
        $successCount = isset($row['count']) ? intval($row['count']) : 0;
        
        // Chờ xử lý
        $query = "SELECT COUNT(*) as count FROM dat_tour WHERE trang_thai = 'Chờ xác nhận'";
        $result = $conn->query($query);
        $row = $result->fetch_assoc();
        $pendingCount = isset($row['count']) ? intval($row['count']) : 0;
        
        // Thất bại/hủy
        $query = "SELECT COUNT(*) as count FROM dat_tour WHERE trang_thai = 'Đã hủy' OR trang_thai = 'Đã hoàn thành'";
        $result = $conn->query($query);
        $row = $result->fetch_assoc();
        $failedCount = isset($row['count']) ? intval($row['count']) : 0;
        
        return [
            'total_amount' => $totalAmount,
            'total_amount_formatted' => number_format($totalAmount, 0, ',', '.') . ' VND',
            'success_count' => $successCount,
            'pending_count' => $pendingCount,
            'failed_count' => $failedCount
        ];
    } catch (Exception $e) {
        error_log("Error getting payment stats: " . $e->getMessage());
        return [
            'total_amount' => 0,
            'total_amount_formatted' => '0 VND',
            'success_count' => 0,
            'pending_count' => 0,
            'failed_count' => 0
        ];
    }
}

/**
 * Lấy thống kê khách hàng
 */
function getCustomerStats() {
    global $conn;
    
    try {
        // Tổng khách hàng (chỉ users)
        $query = "SELECT COUNT(*) as total FROM nguoi_dung WHERE vai_tro = 'user'";
        $result = $conn->query($query);
        $row = $result->fetch_assoc();
        $totalCustomers = isset($row['total']) ? intval($row['total']) : 0;
        
        // Khách hàng đang hoạt động (có email xác thực hoặc trang_thai = 1)
        $query = "SELECT COUNT(*) as count FROM nguoi_dung WHERE vai_tro = 'user' AND email IS NOT NULL AND email != ''";
        $result = $conn->query($query);
        $row = $result->fetch_assoc();
        $activeCount = isset($row['count']) ? intval($row['count']) : 0;
        
        // Khách hàng mới trong tháng này
        $query = "SELECT COUNT(*) as count FROM nguoi_dung WHERE vai_tro = 'user' AND (MONTH(ngay_sinh) = MONTH(CURDATE()) OR MONTH(ngay_tao) = MONTH(CURDATE()))";
        $result = $conn->query($query);
        $row = $result->fetch_assoc();
        $newThisMonthCount = isset($row['count']) ? intval($row['count']) : 0;
        
        // Khách hàng bị khóa (có thể add trường status/trang_thai nếu có)
        // Tạm thời để 0 vì không có trường khóa account trong DB
        $lockedCount = 0;
        
        echo json_encode([
            'success' => true,
            'data' => [
                'total_customers' => $totalCustomers,
                'active_customers' => $activeCount,
                'new_this_month' => $newThisMonthCount,
                'locked_customers' => $lockedCount
            ]
        ], JSON_UNESCAPED_UNICODE);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Lỗi lấy thống kê khách hàng: ' . $e->getMessage()
        ], JSON_UNESCAPED_UNICODE);
    }
}

/**
 * Lấy dữ liệu thống kê dashboard
 */
function getDashboardStats() {
    global $conn;
    
    try {
        // Tổng số tour
        $query = "SELECT COUNT(*) as total FROM tour";
        $result = $conn->query($query);
        $row = $result->fetch_assoc();
        $totalTours = isset($row['total']) ? intval($row['total']) : 0;
        
        // Tour hoạt động
        $query = "SELECT COUNT(*) as total FROM tour WHERE trang_thai = 'Hoạt động'";
        $result = $conn->query($query);
        $row = $result->fetch_assoc();
        $activeTours = isset($row['total']) ? intval($row['total']) : 0;
        
        // Số đơn đặt tour - Đã xác nhận
        $query = "SELECT COUNT(*) as total FROM dat_tour WHERE trang_thai = 'Đã xác nhận'";
        $result = $conn->query($query);
        $row = $result->fetch_assoc();
        $confirmedBookings = isset($row['total']) ? intval($row['total']) : 0;
        
        // Số đơn đặt tour - Chờ xác nhận
        $query = "SELECT COUNT(*) as total FROM dat_tour WHERE trang_thai = 'Chờ xác nhận'";
        $result = $conn->query($query);
        $row = $result->fetch_assoc();
        $pendingBookings = isset($row['total']) ? intval($row['total']) : 0;
        
        // Tổng số đơn đặt tour
        $query = "SELECT COUNT(*) as total FROM dat_tour";
        $result = $conn->query($query);
        $row = $result->fetch_assoc();
        $totalBookings = isset($row['total']) ? intval($row['total']) : 0;
        
        // Doanh thu từ tất cả tour
        $query = "SELECT SUM(tong_tien) as total FROM dat_tour";
        $result = $conn->query($query);
        $row = $result->fetch_assoc();
        $totalRevenue = isset($row['total']) ? floatval($row['total']) : 0;
        
        // Tính doanh thu theo định dạng (K, M, B)
        $revenueFormatted = formatRevenue($totalRevenue);
        
        echo json_encode([
            'success' => true,
            'data' => [
                'total_tours' => $totalTours,
                'active_tours' => $activeTours,
                'confirmed_bookings' => $confirmedBookings,
                'pending_bookings' => $pendingBookings,
                'total_bookings' => $totalBookings,
                'total_revenue' => $totalRevenue,
                'total_revenue_formatted' => $revenueFormatted
            ]
        ], JSON_UNESCAPED_UNICODE);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Lỗi lấy thống kê dashboard: ' . $e->getMessage()
        ], JSON_UNESCAPED_UNICODE);
    }
}

/**
 * Định dạng doanh thu theo VND
 */
function formatRevenue($amount) {
    return number_format($amount, 0, ',', '.') . ' VND';
}

/**
 * Cập nhật thông tin khách hàng
 */
function updateUser() {
    global $conn;
    
    try {
        $id = isset($_POST['id']) ? intval($_POST['id']) : 0;
        
        if ($id <= 0) {
            http_response_code(400);
            throw new Exception('ID khách hàng không hợp lệ');
        }
        
        $ten_dau = isset($_POST['ten_dau']) ? trim($_POST['ten_dau']) : '';
        $ten_cuoi = isset($_POST['ten_cuoi']) ? trim($_POST['ten_cuoi']) : '';
        $email = isset($_POST['email']) ? trim($_POST['email']) : '';
        $so_dien_thoai = isset($_POST['so_dien_thoai']) ? trim($_POST['so_dien_thoai']) : '';
        $gioi_tinh = isset($_POST['gioi_tinh']) ? trim($_POST['gioi_tinh']) : '';
        $ngay_sinh = isset($_POST['ngay_sinh']) ? trim($_POST['ngay_sinh']) : '';
        $quoc_gia = isset($_POST['quoc_gia']) ? trim($_POST['quoc_gia']) : '';
        $dia_chi = isset($_POST['dia_chi']) ? trim($_POST['dia_chi']) : '';
        
        // Kiểm tra email tồn tại
        if (!empty($email)) {
            $check_query = "SELECT id FROM nguoi_dung WHERE email = ? AND id != ?";
            $stmt = $conn->prepare($check_query);
            $stmt->bind_param("si", $email, $id);
            $stmt->execute();
            if ($stmt->get_result()->num_rows > 0) {
                throw new Exception('Email này đã được sử dụng');
            }
            $stmt->close();
        }
        
        $update_query = "UPDATE nguoi_dung SET 
                        ten_dau = ?, 
                        ten_cuoi = ?, 
                        email = ?, 
                        so_dien_thoai = ?, 
                        gioi_tinh = ?, 
                        ngay_sinh = ?, 
                        quoc_gia = ?, 
                        dia_chi = ? 
                        WHERE id = ?";
        
        $stmt = $conn->prepare($update_query);
        $stmt->bind_param("ssssssssi", $ten_dau, $ten_cuoi, $email, $so_dien_thoai, $gioi_tinh, $ngay_sinh, $quoc_gia, $dia_chi, $id);
        
        if ($stmt->execute()) {
            echo json_encode([
                'success' => true,
                'message' => 'Cập nhật khách hàng thành công'
            ], JSON_UNESCAPED_UNICODE);
        } else {
            throw new Exception('Không thể cập nhật khách hàng');
        }
        $stmt->close();
        
    } catch (Exception $e) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => $e->getMessage()
        ], JSON_UNESCAPED_UNICODE);
    }
}

/**
 * Xóa khách hàng
 */
function deleteUser() {
    global $conn;
    
    try {
        $id = isset($_GET['id']) ? intval($_GET['id']) : 0;
        
        if ($id <= 0) {
            http_response_code(400);
            throw new Exception('ID khách hàng không hợp lệ');
        }
        
        // Kiểm tra khách hàng tồn tại
        $check_query = "SELECT id FROM nguoi_dung WHERE id = ?";
        $stmt = $conn->prepare($check_query);
        $stmt->bind_param("i", $id);
        $stmt->execute();
        if ($stmt->get_result()->num_rows === 0) {
            throw new Exception('Khách hàng không tồn tại');
        }
        $stmt->close();
        
        // Xóa khách hàng
        $delete_query = "DELETE FROM nguoi_dung WHERE id = ?";
        $stmt = $conn->prepare($delete_query);
        $stmt->bind_param("i", $id);
        
        if ($stmt->execute()) {
            echo json_encode([
                'success' => true,
                'message' => 'Xóa khách hàng thành công'
            ], JSON_UNESCAPED_UNICODE);
        } else {
            throw new Exception('Không thể xóa khách hàng');
        }
        $stmt->close();
        
    } catch (Exception $e) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => $e->getMessage()
        ], JSON_UNESCAPED_UNICODE);
    }
}

?>

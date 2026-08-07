const { app } = require('@azure/functions');
const nodemailer = require("nodemailer");

app.http('SendBookingEmail', {
    methods: ['POST', 'OPTIONS'],
    authLevel: 'anonymous',

    handler: async (request, context) => {

        // ==========================
        // CORS
        // ==========================

        if (request.method === 'OPTIONS') {
            context.log('OPTIONS preflight request received');

            return {
                status: 204,
                headers: {
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Methods': 'POST, OPTIONS',
                    'Access-Control-Allow-Headers': 'Content-Type'
                }
            };
        }

        try {

            // ==========================
            // Đọc dữ liệu
            // ==========================

            const body = await request.json();

            context.log("===== REQUEST RECEIVED =====");
            context.log(body);

            // ==========================
            // Xử lý Event Grid
            // ==========================

            if (Array.isArray(body)) {

                const event = body[0];

                // Event Grid Validation
                if (
                    event.eventType ===
                    "Microsoft.EventGrid.SubscriptionValidationEvent"
                ) {

                    context.log("Event Grid Validation");

                    return {
                        status: 200,
                        jsonBody: {
                            validationResponse:
                                event.data.validationCode
                        }
                    };
                }

                // Blob Created
                if (
                    event.eventType ===
                    "Microsoft.Storage.BlobCreated"
                ) {

                    context.log("Blob Created!");
                    context.log("Blob URL:", event.data.url);

                    return {
                        status: 200,
                        jsonBody: {
                            success: true,
                            message: "Blob Event Received"
                        }
                    };
                }
            }

            // ==========================
            // Booking từ Frontend
            // ==========================

            context.log("===== BOOKING INFO =====");
            context.log(body);

            const {
                name,
                email,
                phone,
                tour,
                departDate,
                total,
                bookingCode
            } = body;

            // ==========================
            // Kiểm tra dữ liệu
            // ==========================

            if (!name || !email) {

                context.log("❌ Missing name or email");

                return {
                    status: 400,
                    headers: {
                        'Access-Control-Allow-Origin': '*'
                    },
                    jsonBody: {
                        success: false,
                        message: "Thiếu thông tin khách hàng."
                    }
                };
            }

            // ==========================
            // Kiểm tra Environment Variables
            // ==========================

            context.log("===== ENV CHECK =====");
            context.log(
                "EMAIL_USER exists:",
                !!process.env.EMAIL_USER
            );

            context.log(
                "EMAIL_PASS exists:",
                !!process.env.EMAIL_PASS
            );

            // ==========================
            // Tạo SMTP Gmail
            // ==========================

            const transporter = nodemailer.createTransport({
                service: "gmail",

                auth: {
                    user: process.env.EMAIL_USER,
                    pass: process.env.EMAIL_PASS
                }
            });

            // ==========================
            // Kiểm tra kết nối Gmail
            // ==========================

            await transporter.verify();

            context.log("✅ Gmail SMTP connection successful");

            // ==========================
            // Gửi email
            // ==========================

            const info = await transporter.sendMail({

                from: `"Tripto" <${process.env.EMAIL_USER}>`,

                to: email,

                subject: "🎉 Xác nhận đặt tour thành công",

                html: `
                <div style="font-family:Arial,sans-serif;padding:20px">

                    <h2 style="color:#0d6efd">
                        Xin chào ${name},
                    </h2>

                    <p>
                        Cảm ơn bạn đã đặt tour tại
                        <b>Tripto</b>.
                    </p>

                    <table
                        style="
                            border-collapse:collapse;
                            width:100%;
                            max-width:600px;
                        "
                    >

                        <tr>
                            <td>
                                <b>Mã đặt tour:</b>
                            </td>

                            <td>
                                ${bookingCode}
                            </td>
                        </tr>

                        <tr>
                            <td>
                                <b>Khách hàng:</b>
                            </td>

                            <td>
                                ${name}
                            </td>
                        </tr>

                        <tr>
                            <td>
                                <b>SĐT:</b>
                            </td>

                            <td>
                                ${phone || ""}
                            </td>
                        </tr>

                        <tr>
                            <td>
                                <b>Tour:</b>
                            </td>

                            <td>
                                ${tour || ""}
                            </td>
                        </tr>

                        <tr>
                            <td>
                                <b>Ngày khởi hành:</b>
                            </td>

                            <td>
                                ${departDate || ""}
                            </td>
                        </tr>

                        <tr>
                            <td>
                                <b>Tổng tiền:</b>
                            </td>

                            <td>
                                <b style="color:red">
                                    ${Number(total || 0)
                                        .toLocaleString('vi-VN')}
                                    VNĐ
                                </b>
                            </td>
                        </tr>

                    </table>

                    <br>

                    <p>
                        Chúng tôi sẽ liên hệ với bạn
                        trong thời gian sớm nhất.
                    </p>

                    <hr>

                    <p style="color:gray">
                        Tripto Travel<br>
                        Email tự động - vui lòng không trả lời.
                    </p>

                </div>
                `
            });

            // ==========================
            // KẾT QUẢ SMTP
            // ==========================

            context.log("========== EMAIL RESULT ==========");

            context.log(
                "Email người nhận:",
                email
            );

            context.log(
                "Accepted:",
                info.accepted
            );

            context.log(
                "Rejected:",
                info.rejected
            );

            context.log(
                "Message ID:",
                info.messageId
            );

            context.log(
                "SMTP Response:",
                info.response
            );

            context.log("==================================");

            // ==========================
            // Trả kết quả thành công
            // ==========================

            return {
                status: 200,

                headers: {
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Methods': 'POST, OPTIONS',
                    'Access-Control-Allow-Headers': 'Content-Type'
                },

                jsonBody: {
                    success: true,
                    message: "Đã gửi email xác nhận thành công.",
                    email: email,
                    accepted: info.accepted,
                    rejected: info.rejected
                }
            };

        } catch (err) {

            // ==========================
            // ERROR
            // ==========================

            context.log("========== EMAIL ERROR ==========");

            context.log("Error message:", err.message);

            context.log("Error code:", err.code);

            context.log("Error command:", err.command);

            context.log("Error response:", err.response);

            context.log("=================================");

            return {
                status: 500,

                headers: {
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Methods': 'POST, OPTIONS',
                    'Access-Control-Allow-Headers': 'Content-Type'
                },

                jsonBody: {
                    success: false,
                    message: err.message
                }
            };
        }
    }
});
const { app } = require('@azure/functions');
const nodemailer = require("nodemailer");

app.http('SendBookingEmail', {
    methods: ['POST', 'OPTIONS'],
    authLevel: 'anonymous',

    handler: async (request, context) => {

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
            // Đọc dữ liệu gửi từ frontend
            const body = await request.json();

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

            // Kiểm tra dữ liệu
            if (!name || !email) {
                return {
                    status: 400,
                    jsonBody: {
                        success: false,
                        message: "Thiếu thông tin khách hàng."
                    }
                };
            }

            context.log("===== ENV =====");
            context.log("EMAIL_USER:", process.env.EMAIL_USER);
            context.log("EMAIL_PASS exists:", !!process.env.EMAIL_PASS);

            // SMTP Gmail
            const transporter = nodemailer.createTransport({
                service: "gmail",
                auth: {
                    user: process.env.EMAIL_USER,
                    pass: process.env.EMAIL_PASS
                }
            });

            // Gửi email
            await transporter.sendMail({
                from: `"Tripto" <${process.env.EMAIL_USER}>`,
                to: email,
                subject: "🎉 Xác nhận đặt tour thành công",

                html: `
                <div style="font-family:Arial,sans-serif;padding:20px">
                    <h2 style="color:#0d6efd">
                        Xin chào ${name},
                    </h2>

                    <p>Cảm ơn bạn đã đặt tour tại <b>Tripto</b>.</p>

                    <table style="border-collapse:collapse">
                        <tr>
                            <td><b>Mã đặt tour:</b></td>
                            <td>${bookingCode}</td>
                        </tr>

                        <tr>
                            <td><b>Khách hàng:</b></td>
                            <td>${name}</td>
                        </tr>

                        <tr>
                            <td><b>SĐT:</b></td>
                            <td>${phone}</td>
                        </tr>

                        <tr>
                            <td><b>Tour:</b></td>
                            <td>${tour}</td>
                        </tr>

                        <tr>
                            <td><b>Ngày khởi hành:</b></td>
                            <td>${departDate}</td>
                        </tr>

                        <tr>
                            <td><b>Tổng tiền:</b></td>
                            <td><b style="color:red">
                                ${Number(total).toLocaleString('vi-VN')} VNĐ
                            </b></td>
                        </tr>
                    </table>

                    <br>

                    <p>
                        Chúng tôi sẽ liên hệ với bạn trong thời gian sớm nhất.
                    </p>

                    <hr>

                    <p style="color:gray">
                        Tripto Travel<br>
                        Email tự động - vui lòng không trả lời.
                    </p>
                </div>
                `
            });

            context.log("✅ Email sent successfully.");

            return {
                status: 200,
                headers: {
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Methods': 'POST, OPTIONS',
                    'Access-Control-Allow-Headers': 'Content-Type'
                },
                jsonBody: {
                    success: true,
                    message: "Đã gửi email xác nhận thành công."
                }
            };

        } catch (err) {

            context.log(err);

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
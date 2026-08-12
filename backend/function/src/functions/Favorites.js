const { app } = require("@azure/functions");
const { createClient } = require("redis");

// ======================================================
// AZURE CACHE FOR REDIS — Favorite lưu tạm
// ------------------------------------------------------
// Key      : tripto:favorite:user:<userId>  (SET chứa tour:<id> / combo:<id>)
// Key meta : tripto:favorite:user:<userId>:meta  (Hash: field=tour:<id>,
//            value=JSON {userId, tourId, tourName, timestamp})
//
// GET    /api/favorites?userId=<id>  -> đọc Redis, trả JSON để xem trực tiếp
// POST   /api/favorites              -> body {userId, tourId, tourName} (thêm)
// DELETE /api/favorites?userId=<id>&tourId=<id> -> xoá khỏi Redis
// ======================================================

const FAVORITE_TTL = Number(process.env.REDIS_FAVORITE_TTL || 600);

let redisClient = null;

async function getRedisClient(context) {
    if (redisClient && redisClient.isReady) {
        return redisClient;
    }

    const host = process.env.REDIS_HOST;
    const port = process.env.REDIS_PORT || "10000";
    const password = process.env.REDIS_PASSWORD;

    if (!host || !password) {
        throw new Error("REDIS_HOST / REDIS_PASSWORD chưa được cấu hình.");
    }

    redisClient = createClient({
        socket: {
            host: host,
            port: Number(port),
            tls: true
        },
        password: password
    });

    redisClient.on("error", (error) => {
        console.error("Redis error:", error.message);
    });

    await redisClient.connect();

    if (context) context.log("✅ Redis (Azure Cache) connected.");

    return redisClient;
}

const favoritesKey = (userId) => `tripto:favorite:user:${userId}`;
const favoritesMetaKey = (userId) => `${favoritesKey(userId)}:meta`;

const CORS_HEADERS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, POST, DELETE, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type"
};

function asMember(tourId) {
    const raw = String(tourId || "").trim();
    return /^(tour|combo):/i.test(raw) ? raw : `tour:${raw}`;
}

// Bỏ tiền tố "tour:" / "combo:" để trả tourId gọn (khớp ví dụ: "tour01")
function stripTypePrefix(value) {
    return String(value || "").replace(/^(tour|combo):/i, "");
}

app.http("Favorites", {
    methods: ["GET", "POST", "DELETE", "OPTIONS"],
    authLevel: "anonymous",
    route: "favorites",

    handler: async (request, context) => {
        if (request.method === "OPTIONS") {
            return { status: 204, headers: CORS_HEADERS };
        }

        try {
            const redis = await getRedisClient(context);
            const query = new URL(request.url).searchParams;
            const userId = (query.get("userId") || "").trim();

            if (!userId) {
                return {
                    status: 400,
                    headers: CORS_HEADERS,
                    jsonBody: {
                        status: "Error",
                        source: "Azure Redis",
                        message: "Thiếu tham số userId."
                    }
                };
            }

            const key = favoritesKey(userId);
            const metaKey = favoritesMetaKey(userId);

            // ==============================================
            // GET /api/favorites?userId=<id> — ĐỌC TỪ REDIS
            // ==============================================
            if (request.method === "GET") {
                const members = await redis.sMembers(key);
                let meta = {};
                try {
                    meta = (await redis.hGetAll(metaKey)) || {};
                } catch (error) {
                    meta = {};
                }

                const favorites = [];
                for (const member of members || []) {
                    let entry = {};
                    try {
                        entry = JSON.parse(meta[member] || "null") || {};
                    } catch (error) {
                        entry = {};
                    }
                    favorites.push({
                        tourId: stripTypePrefix(entry.tourId || member),
                        tourName: entry.tourName || "",
                        timestamp: entry.timestamp || null
                    });
                }

                // Sắp xếp mới nhất lên đầu (theo timestamp nếu có)
                favorites.sort((a, b) => {
                    return String(b.timestamp || "").localeCompare(String(a.timestamp || ""));
                });

                return {
                    status: 200,
                    headers: {
                        ...CORS_HEADERS,
                        "Content-Type": "application/json; charset=utf-8"
                    },
                    jsonBody: {
                        status: "Success",
                        source: "Azure Redis",
                        redisKey: key,
                        userId: userId,
                        favorites: favorites
                    }
                };
            }

            // ==============================================
            // POST /api/favorites — THÊM VÀO REDIS (lưu tạm)
            // body: { userId, tourId, tourName }
            // ==============================================
            if (request.method === "POST") {
                const body = await request.json();
                const tourId = String(body.tourId ?? "").trim();
                const tourName = String(body.tourName ?? "").trim();

                if (!tourId || !tourName) {
                    return {
                        status: 400,
                        headers: CORS_HEADERS,
                        jsonBody: {
                            status: "Error",
                            message: "Thiếu tourId hoặc tourName."
                        }
                    };
                }

                const member = asMember(tourId);
                const value = JSON.stringify({
                    userId: userId,
                    tourId: member,
                    tourName: tourName,
                    timestamp: new Date().toISOString()
                });

                await redis.sAdd(key, member);
                await redis.hSet(metaKey, member, value);
                await redis.expire(key, FAVORITE_TTL);
                await redis.expire(metaKey, FAVORITE_TTL);

                context.log(
                    `❤️ Favorite saved -> key=${key} member=${member} tourName=${tourName}`
                );

                return {
                    status: 200,
                    headers: CORS_HEADERS,
                    jsonBody: {
                        status: "Success",
                        source: "Azure Redis",
                        userId: userId,
                        tourId: member,
                        tourName: tourName,
                        message: `Đã lưu tạm "${tourName}" vào Azure Redis.`
                    }
                };
            }

            // ==============================================
            // DELETE /api/favorites?userId=<id>&tourId=<id>
            // — XOÁ TOUR KHỎI REDIS
            // ==============================================
            if (request.method === "DELETE") {
                const tourId = (query.get("tourId") || "").trim();

                if (!tourId) {
                    return {
                        status: 400,
                        headers: CORS_HEADERS,
                        jsonBody: {
                            status: "Error",
                            message: "Thiếu tham số tourId."
                        }
                    };
                }

                const member = asMember(tourId);
                await redis.sRem(key, member);
                await redis.hDel(metaKey, member);

                context.log(
                    `🗑 Favorite removed -> key=${key} member=${member}`
                );

                return {
                    status: 200,
                    headers: CORS_HEADERS,
                    jsonBody: {
                        status: "Success",
                        source: "Azure Redis",
                        userId: userId,
                        tourId: member,
                        message: "Đã xóa khỏi Azure Redis."
                    }
                };
            }

            return {
                status: 405,
                headers: CORS_HEADERS,
                jsonBody: {
                    status: "Error",
                    message: `Method ${request.method} not allowed.`
                }
            };
        } catch (error) {
            context.error("Favorites error:", error);
            return {
                status: 500,
                headers: CORS_HEADERS,
                jsonBody: {
                    status: "Error",
                    message: error.message
                }
            };
        }
    }
});
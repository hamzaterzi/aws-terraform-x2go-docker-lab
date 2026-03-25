const http = require("http");
const redis = require("redis");

const PORT = process.env.PORT || 3000;
const REDIS_HOST = process.env.REDIS_HOST || "";
const REDIS_PORT = process.env.REDIS_PORT || 6379;
const APP_NAME = process.env.APP_NAME || "unknown-app";

const redisEnabled = REDIS_HOST.trim() !== "";

let client = null;
let redisReady = false;
let localVisits = 0;

if (redisEnabled) {
  client = redis.createClient({
    socket: {
      host: REDIS_HOST,
      port: Number(REDIS_PORT)
    }
  });

  client.on("error", (err) => {
    redisReady = false;
    console.error("Redis error:", err.message);
  });
}

async function connectToRedisIfConfigured() {
  if (!redisEnabled || !client) {
    console.log("Redis is not configured. Running in local counter mode.");
    return;
  }

  try {
    await client.connect();
    redisReady = true;
    console.log("Connected to Redis");
  } catch (err) {
    redisReady = false;
    console.error("Redis connection failed, continuing without Redis:", err.message);
  }
}

async function getVisits() {
  if (redisEnabled && client && redisReady) {
    let visits = await client.get("visits");
    visits = visits ? parseInt(visits, 10) + 1 : 1;
    await client.set("visits", visits);
    return visits;
  }

  localVisits += 1;
  return localVisits;
}

async function handleRoot(res) {
  const visits = await getVisits();

  res.writeHead(200, { "Content-Type": "text/html" });
  res.end(`
    <h1>Docker Compose to AWS ECS Demo</h1>
    <p>Handled by: ${APP_NAME}</p>
    <p>Visits: ${visits}</p>
    <p>Redis enabled: ${redisEnabled}</p>
    <p>Redis connected: ${redisReady}</p>
    <p>Redis Host: ${REDIS_HOST || "not-configured"}</p>
    <p>Redis Port: ${REDIS_PORT}</p>
  `);
}

function handleHealth(res) {
  res.writeHead(200, { "Content-Type": "application/json" });
  res.end(
    JSON.stringify({
      status: "ok",
      app: APP_NAME,
      redisEnabled,
      redisReady
    })
  );
}

async function start() {
  await connectToRedisIfConfigured();

  const server = http.createServer(async (req, res) => {
    try {
      if (req.url === "/health") {
        return handleHealth(res);
      }

      if (req.url === "/") {
        return await handleRoot(res);
      }

      res.writeHead(404, { "Content-Type": "application/json" });
      res.end(JSON.stringify({ error: "Not Found" }));
    } catch (err) {
      console.error("Request handling error:", err);
      res.writeHead(500, { "Content-Type": "application/json" });
      res.end(JSON.stringify({ error: "Internal Server Error" }));
    }
  });

  server.listen(PORT, () => {
    console.log(`${APP_NAME} running on port ${PORT}`);
  });
}

start();
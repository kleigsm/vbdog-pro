// Supabase 代理 — 转发模拟器请求到 Supabase API
const http = require("http")
const https = require("https")
const SUPABASE_HOST = "bxecdhlbnpwahwswnqzr.supabase.co"
const SUPABASE_KEY = "sb_publishable_UkKBNurH0MXBStUtXjlCeg_5NxQBaJU"
const PORT = 3456

const server = http.createServer((req, res) => {
  const options = {
    hostname: SUPABASE_HOST, port: 443, path: req.url, method: req.method,
    headers: { ...req.headers, host: SUPABASE_HOST, apikey: SUPABASE_KEY, authorization: "Bearer " + SUPABASE_KEY },
  }
  console.log("[" + new Date().toLocaleTimeString() + "] " + req.method + " " + req.url)
  const proxyReq = https.request(options, (proxyRes) => {
    res.writeHead(proxyRes.statusCode, proxyRes.headers); proxyRes.pipe(res)
  })
  proxyReq.on("error", (err) => { console.error("Proxy error:", err.message); res.writeHead(502); res.end("Proxy error") })
  if (req.method === "POST" || req.method === "PATCH") {
    let body = ""; req.on("data", (chunk) => body += chunk); req.on("end", () => proxyReq.end(body))
  } else { proxyReq.end() }
})

server.listen(PORT, "0.0.0.0", () => {
  console.log("Supabase Proxy on http://localhost:" + PORT)
  console.log("Emulator access: http://10.0.2.2:" + PORT)
})

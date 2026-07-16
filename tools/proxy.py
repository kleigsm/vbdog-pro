import subprocess, sys, urllib.parse

SUPABASE = "https://bxecdhlbnpwahwswnqzr.supabase.co"
KEY = "sb_publishable_UkKBNurH0MXBStUtXjlCeg_5NxQBaJU"
PORT = 3456

from http.server import HTTPServer, BaseHTTPRequestHandler

class P(BaseHTTPRequestHandler):
    def do_GET(self): self.send("GET")
    def do_POST(self): self.send("POST")
    def do_PATCH(self): self.send("PATCH")
    def do_DELETE(self): self.send("DELETE")
    def do_OPTIONS(self): self.send_response(200); self.end_headers()

    def send(self, method):
        url = SUPABASE + self.path
        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length) if length > 0 else b""
        cmd = ["curl.exe", "-s", "-X", method, url, "--proxy", "http://127.0.0.1:7897",
               "-H", "apikey: " + KEY, "-H", "Authorization: Bearer " + KEY,
               "-H", "Content-Type: application/json", "--max-time", "30"]
        if body: cmd.extend(["-d", "@-"])
        text_body = body.decode("utf-8", errors="ignore") if body else None
        r = subprocess.run(cmd, input=text_body, capture_output=True, text=True, timeout=35)
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(r.stdout.encode("utf-8"))

print("Starting Supabase Proxy on port " + str(PORT) + "...")
HTTPServer.allow_reuse_address = True
HTTPServer(("0.0.0.0", PORT), P).serve_forever()

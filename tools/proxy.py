# Supabase Proxy v5 — stdin body, reliable
from http.server import HTTPServer, BaseHTTPRequestHandler
import subprocess

SUPABASE_HOST = "bxecdhlbnpwahwswnqzr.supabase.co"
SUPABASE_KEY = "sb_publishable_UkKBNurH0MXBStUtXjlCeg_5NxQBaJU"
PORT = 3456

class ProxyHandler(BaseHTTPRequestHandler):
    def log_message(self, *a): pass  # suppress logs

    def do_GET(self): self.proxy("GET")
    def do_POST(self): self.proxy("POST")
    def do_PATCH(self): self.proxy("PATCH")
    def do_DELETE(self): self.proxy("DELETE")
    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "*")
        self.send_header("Access-Control-Allow-Headers", "*")
        self.end_headers()

    def proxy(self, method):
        url = f"https://{SUPABASE_HOST}{self.path}"
        body = b""
        if method in ("POST", "PATCH"):
            length = int(self.headers.get("Content-Length", 0))
            if length > 0:
                body = self.rfile.read(length)

        cmd = ["curl.exe", "-s", "-X", method, url,
               "--proxy", "http://127.0.0.1:7897",
               "-H", f"apikey: {SUPABASE_KEY}",
               "-H", f"Authorization: Bearer {SUPABASE_KEY}",
               "-H", "Content-Type: application/json",
               "--max-time", "30", "-w", "\nHTTP:%{http_code}"]
        if body:
            cmd.extend(["-d", "@-"])

        try:
            inp = body.decode("utf-8") if body else None
            result = subprocess.run(cmd, input=inp, capture_output=True, text=True, timeout=35)
            output = result.stdout
            hdr_end = output.rfind("\nHTTP:")
            if hdr_end >= 0:
                resp_body = output[:hdr_end]
                status = int(output[hdr_end+1:].strip().replace("HTTP:", ""))
            else:
                resp_body = output
                status = 200

            self.send_response(status)
            self.send_header("Content-Type", "application/json")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(resp_body.encode("utf-8"))
        except Exception as e:
            self.send_response(502)
            self.end_headers()
            self.wfile.write(f"Proxy error: {e}".encode())

if __name__ == "__main__":
    HTTPServer.allow_reuse_address = True
    server = HTTPServer(("0.0.0.0", PORT), ProxyHandler)
    print(f"✅ Supabase Proxy on http://localhost:{PORT} (curl-backed)")
    print(f"   Emulator: http://10.0.2.2:{PORT}")
    server.serve_forever()

#!/usr/bin/env python3
# Accepts HTTP PUT uploads from the watch (curl -T file http://192.168.2.1:8098/name)
# into ~/sfos-skipjack-env/uploads. Bound to the USB link only.
import http.server, os
DIR = os.path.expanduser("~/sfos-skipjack-env/uploads")
class H(http.server.BaseHTTPRequestHandler):
    def do_PUT(self):
        name = os.path.basename(self.path) or "upload.bin"
        n = int(self.headers.get("Content-Length", 0))
        with open(os.path.join(DIR, name), "wb") as f:
            f.write(self.rfile.read(n))
        self.send_response(201); self.end_headers()
    def log_message(self, *a): pass
http.server.HTTPServer(("192.168.2.1", 8098), H).serve_forever()

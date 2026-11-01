#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Move and click a virtual pointer in the current Wayland session. Only for a nested compositor, and a click that misses can still reach real
hardware controls in the shell under test (the backlight, for example), so stub those first.
Usage: virtual-pointer.py WIDTH HEIGHT move X Y | click X Y
Speaks the Wayland wire protocol directly, so it needs no extra packages."""
import os, socket, struct, sys, time

def string(s):
    b = s.encode() + b"\0"
    return struct.pack("=I", len(b)) + b + b"\0" * (-len(b) % 4)

class Client:
    def __init__(self):
        self.sock = socket.socket(socket.AF_UNIX)
        self.sock.connect(os.path.join(os.environ["XDG_RUNTIME_DIR"], os.environ["WAYLAND_DISPLAY"]))
        self.next_id = 2
    def new_id(self):
        self.next_id += 1
        return self.next_id - 1
    def send(self, obj, op, body=b""):
        self.sock.sendall(struct.pack("=II", obj, (len(body) + 8) << 16 | op) + body)
    def roundtrip(self):
        """Returns the wl_registry globals seen until the sync callback fires."""
        cb = self.new_id()
        self.send(1, 0, struct.pack("=I", cb))
        buf, globals_ = b"", {}
        while True:
            buf += self.sock.recv(65536)
            while len(buf) >= 8:
                obj, word = struct.unpack("=II", buf[:8])
                size, op = word >> 16, word & 0xffff
                if len(buf) < size: break
                body, buf = buf[8:size], buf[size:]
                if obj == cb: return globals_
                if obj == self.registry and op == 0:
                    name, n = struct.unpack("=II", body[:8])
                    globals_[body[8:8 + n - 1].decode()] = name

if os.environ.get("KOTILO_TEST_NESTED") != "1":
    sys.exit("refusing to run: this clicks real controls, so set KOTILO_TEST_NESTED=1 inside a nested compositor only")

W, H, cmd, X, Y = int(sys.argv[1]), int(sys.argv[2]), sys.argv[3], int(sys.argv[4]), int(sys.argv[5])
c = Client()
c.registry = c.new_id()
c.send(1, 1, struct.pack("=I", c.registry))
iface = "zwlr_virtual_pointer_manager_v1"
name = c.roundtrip()[iface]
mgr = c.new_id()
c.send(c.registry, 0, struct.pack("=I", name) + string(iface) + struct.pack("=II", 1, mgr))
ptr = c.new_id()
c.send(mgr, 0, struct.pack("=II", 0, ptr))
now = lambda: int(time.monotonic() * 1000) & 0xffffffff
def motion(x, y):
    c.send(ptr, 1, struct.pack("=IIIII", now(), x, y, W, H))
    c.send(ptr, 4)
    c.roundtrip()
# Two steps: a client sees the second as a real move across its surface.
motion(max(0, X - 3), Y); time.sleep(0.05); motion(X, Y); time.sleep(0.05)
if cmd == "click":
    c.send(ptr, 2, struct.pack("=III", now(), 0x110, 1)); c.send(ptr, 4); c.roundtrip(); time.sleep(0.05)
    c.send(ptr, 2, struct.pack("=III", now(), 0x110, 0)); c.send(ptr, 4); c.roundtrip()
time.sleep(0.1)

"""A minimal WebSocket client (RFC 6455) on the standard library, enough for ComfyUI's /ws.

Text and binary messages, fragmented messages, ping and close. No TLS, no extensions. recv() can time out
without losing a partially received frame: bytes stay in the buffer until the frame is complete.
"""
import base64
import hashlib
import os
import socket
import struct
from urllib.parse import urlsplit

GUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"


class WebSocketClosed(Exception):
    pass


class WebSocket:
    def __init__(self, url, timeout=10.0):
        parts = urlsplit(url)
        if parts.scheme != "ws":
            raise ValueError(f"only ws:// URLs are supported, not {url}")
        host = parts.hostname
        port = parts.port or 80
        path = parts.path or "/"
        if parts.query:
            path += "?" + parts.query
        self.sock = socket.create_connection((host, port), timeout=timeout)
        key = base64.b64encode(os.urandom(16)).decode()
        request = (
            f"GET {path} HTTP/1.1\r\nHost: {host}:{port}\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n"
            f"Sec-WebSocket-Key: {key}\r\nSec-WebSocket-Version: 13\r\n\r\n"
        )
        self.sock.sendall(request.encode())
        self.buf = b""
        while b"\r\n\r\n" not in self.buf:
            chunk = self.sock.recv(4096)
            if not chunk:
                raise WebSocketClosed("connection closed during the handshake")
            self.buf += chunk
        head, self.buf = self.buf.split(b"\r\n\r\n", 1)
        lines = head.decode("latin-1").split("\r\n")
        if " 101 " not in lines[0] + " ":
            raise WebSocketClosed(f"handshake refused: {lines[0]}")
        headers = {k.strip().lower(): v.strip() for k, v in (l.split(":", 1) for l in lines[1:] if ":" in l)}
        expected = base64.b64encode(hashlib.sha1((key + GUID).encode()).digest()).decode()
        if headers.get("sec-websocket-accept") != expected:
            raise WebSocketClosed("bad Sec-WebSocket-Accept")
        self.fragments = []
        self.fragment_opcode = None
        self.closed = False

    def settimeout(self, seconds):
        self.sock.settimeout(seconds)

    def _parse_frame(self):
        b = self.buf
        if len(b) < 2:
            return None
        fin = b[0] & 0x80
        opcode = b[0] & 0x0F
        masked = b[1] & 0x80
        length = b[1] & 0x7F
        pos = 2
        if length == 126:
            if len(b) < 4:
                return None
            length = struct.unpack(">H", b[2:4])[0]
            pos = 4
        elif length == 127:
            if len(b) < 10:
                return None
            length = struct.unpack(">Q", b[2:10])[0]
            pos = 10
        mask = b""
        if masked:
            if len(b) < pos + 4:
                return None
            mask = b[pos:pos + 4]
            pos += 4
        if len(b) < pos + length:
            return None
        payload = b[pos:pos + length]
        if masked:
            payload = bytes(c ^ mask[i % 4] for i, c in enumerate(payload))
        self.buf = b[pos + length:]
        return bool(fin), opcode, payload

    def _send_frame(self, opcode, payload=b""):
        mask = os.urandom(4)
        header = bytes([0x80 | opcode])
        n = len(payload)
        if n < 126:
            header += bytes([0x80 | n])
        elif n < 65536:
            header += bytes([0x80 | 126]) + struct.pack(">H", n)
        else:
            header += bytes([0x80 | 127]) + struct.pack(">Q", n)
        masked = bytes(c ^ mask[i % 4] for i, c in enumerate(payload))
        self.sock.sendall(header + mask + masked)

    def recv(self):
        """Returns (opcode, payload) for a complete text (1) or binary (2) message.

        Raises socket.timeout when nothing complete arrived in time, WebSocketClosed when the server closed."""
        if self.closed:
            raise WebSocketClosed("already closed")
        while True:
            frame = self._parse_frame()
            if frame is None:
                try:
                    chunk = self.sock.recv(65536)
                except (ConnectionError, OSError) as e:
                    if isinstance(e, socket.timeout):
                        raise
                    self.closed = True
                    raise WebSocketClosed(str(e)) from e
                if not chunk:
                    self.closed = True
                    raise WebSocketClosed("connection closed by the server")
                self.buf += chunk
                continue
            fin, opcode, payload = frame
            if opcode == 0x8:
                self.closed = True
                raise WebSocketClosed("close frame received")
            if opcode == 0x9:
                self._send_frame(0xA, payload)
                continue
            if opcode == 0xA:
                continue
            if opcode in (0x1, 0x2):
                if fin:
                    return opcode, payload
                self.fragment_opcode = opcode
                self.fragments = [payload]
                continue
            if opcode == 0x0:
                self.fragments.append(payload)
                if fin:
                    data = b"".join(self.fragments)
                    self.fragments = []
                    return self.fragment_opcode, data
                continue

    def close(self):
        if not self.closed:
            try:
                self._send_frame(0x8, struct.pack(">H", 1000))
            except OSError:
                pass
        self.closed = True
        try:
            self.sock.close()
        except OSError:
            pass

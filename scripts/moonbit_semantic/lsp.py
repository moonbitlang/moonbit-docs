"""Small synchronous JSON-RPC/LSP client specialized for snapshot generation."""

from __future__ import annotations

import json
import os
import select
import subprocess
import threading
import time
from pathlib import Path
from typing import Any, BinaryIO, Protocol


class LspError(RuntimeError):
    pass


class Transport(Protocol):
    def request(self, method: str, params: dict[str, Any]) -> Any: ...
    def notify(self, method: str, params: dict[str, Any]) -> None: ...
    def close(self) -> None: ...


class JsonRpcProcess:
    def __init__(self, command: list[str], cwd: Path, timeout: float = 120.0):
        self.process = subprocess.Popen(
            command, cwd=cwd, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL, env={**os.environ, "NO_COLOR": "1"},
        )
        if self.process.stdin is None or self.process.stdout is None:
            raise LspError("failed to open LSP pipes")
        self.reader: BinaryIO = self.process.stdout
        self.writer: BinaryIO = self.process.stdin
        self._read_buffer = bytearray()
        self.next_id = 1
        self.lock = threading.Lock()
        self.timeout = timeout

    def request(self, method: str, params: dict[str, Any]) -> Any:
        with self.lock:
            request_id = self.next_id
            self.next_id += 1
            self._send({"jsonrpc": "2.0", "id": request_id, "method": method, "params": params})
            while True:
                message = self._receive()
                if message.get("id") != request_id:
                    if "id" in message and "method" in message:
                        self._send({"jsonrpc": "2.0", "id": message["id"], "result": None})
                    continue
                if "error" in message:
                    raise LspError(f"{method}: {message['error']}")
                return message.get("result")

    def notify(self, method: str, params: dict[str, Any]) -> None:
        with self.lock:
            self._send({"jsonrpc": "2.0", "method": method, "params": params})

    def close(self) -> None:
        try:
            if self.process.poll() is None:
                try:
                    self.request("shutdown", {})
                    self.notify("exit", {})
                    self.process.wait(timeout=3)
                except Exception:
                    self.process.kill()
                    self.process.wait()
        finally:
            self.writer.close()
            self.reader.close()

    def _send(self, value: dict[str, Any]) -> None:
        body = json.dumps(value, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
        self.writer.write(f"Content-Length: {len(body)}\r\n\r\n".encode("ascii") + body)
        self.writer.flush()

    def _receive(self) -> dict[str, Any]:
        deadline = time.monotonic() + self.timeout
        while b"\r\n\r\n" not in self._read_buffer and b"\n\n" not in self._read_buffer:
            self._read_more(deadline)
        crlf_end = self._read_buffer.find(b"\r\n\r\n")
        lf_end = self._read_buffer.find(b"\n\n")
        if crlf_end >= 0 and (lf_end < 0 or crlf_end <= lf_end):
            header_end, delimiter_size = crlf_end, 4
        else:
            header_end, delimiter_size = lf_end, 2
        header_block = bytes(self._read_buffer[:header_end])
        del self._read_buffer[: header_end + delimiter_size]
        headers: dict[str, str] = {}
        for line in header_block.splitlines():
            key, _, value = line.decode("ascii", "replace").partition(":")
            headers[key.lower().strip()] = value.strip()
        try:
            length = int(headers["content-length"])
        except (KeyError, ValueError) as exc:
            raise LspError("invalid JSON-RPC Content-Length") from exc
        self._fill_size(length, deadline)
        body = bytes(self._read_buffer[:length])
        del self._read_buffer[:length]
        try:
            message = json.loads(body)
        except json.JSONDecodeError as exc:
            raise LspError("invalid JSON-RPC response") from exc
        if not isinstance(message, dict):
            raise LspError("JSON-RPC response is not an object")
        return message

    def _fill_size(self, length: int, deadline: float) -> None:
        while len(self._read_buffer) < length:
            self._read_more(deadline)

    def _read_more(self, deadline: float) -> None:
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            raise LspError(f"language server response timed out after {self.timeout}s")
        ready, _, _ = select.select([self.reader.fileno()], [], [], remaining)
        if not ready:
            raise LspError(f"language server response timed out after {self.timeout}s")
        chunk = os.read(self.reader.fileno(), 65536)
        if not chunk:
            code = self.process.poll()
            detail = f" with {code}" if code is not None else ""
            raise LspError(f"language server closed the stream{detail}")
        self._read_buffer.extend(chunk)


class LspSession:
    def __init__(self, transport: Transport, root: Path):
        self.transport = transport
        self.root = root.resolve()
        result = transport.request("initialize", {
            "processId": os.getpid(),
            "rootUri": self.root.as_uri(),
            "capabilities": {"general": {"positionEncodings": ["utf-16", "utf-8"]}},
            "workspaceFolders": [{"uri": self.root.as_uri(), "name": self.root.name}],
        }) or {}
        capabilities = result.get("capabilities", {}) if isinstance(result, dict) else {}
        self.position_encoding = capabilities.get("positionEncoding", "utf-16")
        if self.position_encoding not in {"utf-8", "utf-16", "utf-32"}:
            raise LspError(f"unsupported negotiated position encoding: {self.position_encoding}")
        transport.notify("initialized", {})

    def open(self, path: Path, text: str) -> str:
        uri = path.resolve().as_uri()
        language = "markdown" if path.name.endswith(".mbt.md") else "moonbit"
        self.transport.notify("textDocument/didOpen", {
            "textDocument": {"uri": uri, "languageId": language, "version": 1, "text": text}
        })
        return uri

    def hover(self, uri: str, position: dict[str, int]) -> Any:
        return self.transport.request("textDocument/hover", {"textDocument": {"uri": uri}, "position": position})

    def definition(self, uri: str, position: dict[str, int]) -> Any:
        return self.transport.request("textDocument/definition", {"textDocument": {"uri": uri}, "position": position})

    def close_document(self, uri: str) -> None:
        self.transport.notify("textDocument/didClose", {"textDocument": {"uri": uri}})

    def close(self) -> None:
        self.transport.close()


def normalize_hover_contents(contents: Any) -> dict[str, str] | None:
    if isinstance(contents, str):
        return {"kind": "plaintext", "value": contents}
    if isinstance(contents, dict) and isinstance(contents.get("value"), str):
        kind = contents.get("kind", "plaintext")
        return {"kind": kind if kind in {"plaintext", "markdown"} else "plaintext", "value": contents["value"]}
    if isinstance(contents, list):
        parts = []
        for item in contents:
            normalized = normalize_hover_contents(item)
            if normalized and normalized["value"]:
                parts.append(normalized["value"])
        return {"kind": "markdown", "value": "\n\n".join(parts)} if parts else None
    return None


def definition_locations(result: Any) -> list[dict[str, Any]]:
    if result is None:
        return []
    values = result if isinstance(result, list) else [result]
    locations = []
    for item in values:
        if not isinstance(item, dict):
            continue
        if isinstance(item.get("targetUri"), str) and isinstance(item.get("targetSelectionRange"), dict):
            locations.append({
                "response_kind": "location-link",
                "uri": item["targetUri"],
                "target_range": item.get("targetRange", item["targetSelectionRange"]),
                "target_selection_range": item["targetSelectionRange"],
                "origin_selection_range": item.get("originSelectionRange"),
            })
        elif isinstance(item.get("uri"), str) and isinstance(item.get("range"), dict):
            locations.append({
                "response_kind": "location",
                "uri": item["uri"],
                "target_range": item["range"],
                "target_selection_range": item["range"],
                "origin_selection_range": None,
            })
    return locations

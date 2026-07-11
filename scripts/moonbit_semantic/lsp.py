"""Small synchronous JSON-RPC/LSP client specialized for snapshot generation."""

from __future__ import annotations

import json
import os
import select
import subprocess
import threading
import time
from concurrent.futures import Future, TimeoutError as FutureTimeoutError
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
        self._state_lock = threading.Lock()
        self._send_lock = threading.Lock()
        self._pending: dict[int, Future[Any]] = {}
        self._reader_error: BaseException | None = None
        self.timeout = timeout
        self._reader_thread = threading.Thread(
            target=self._read_loop,
            name="moonbit-semantic-jsonrpc-reader",
            daemon=True,
        )
        self._reader_thread.start()

    def request(self, method: str, params: dict[str, Any]) -> Any:
        request_id, future = self.request_async(method, params)
        try:
            return future.result(timeout=self.timeout)
        except FutureTimeoutError as exc:
            with self._state_lock:
                self._pending.pop(request_id, None)
            raise LspError(f"{method}: response timed out after {self.timeout}s") from exc

    def request_async(
        self,
        method: str,
        params: dict[str, Any],
    ) -> tuple[int, Future[Any]]:
        future: Future[Any] = Future()
        with self._state_lock:
            if self._reader_error is not None:
                raise LspError(f"language server reader failed: {self._reader_error}")
            request_id = self.next_id
            self.next_id += 1
            self._pending[request_id] = future
        try:
            self._send(
                {
                    "jsonrpc": "2.0",
                    "id": request_id,
                    "method": method,
                    "params": params,
                }
            )
        except BaseException as exc:
            with self._state_lock:
                self._pending.pop(request_id, None)
            future.set_exception(exc)
            raise
        return request_id, future

    def notify(self, method: str, params: dict[str, Any]) -> None:
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
            self._reader_thread.join(timeout=1)

    def _send(self, value: dict[str, Any]) -> None:
        body = json.dumps(value, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
        with self._send_lock:
            self.writer.write(f"Content-Length: {len(body)}\r\n\r\n".encode("ascii") + body)
            self.writer.flush()

    def _read_loop(self) -> None:
        try:
            while True:
                message = self._receive()
                request_id = message.get("id")
                if request_id is not None and "method" not in message:
                    with self._state_lock:
                        future = self._pending.pop(request_id, None)
                    if future is None:
                        continue
                    if "error" in message:
                        future.set_exception(LspError(str(message["error"])))
                    else:
                        future.set_result(message.get("result"))
                elif request_id is not None and "method" in message:
                    self._send(
                        {"jsonrpc": "2.0", "id": request_id, "result": None}
                    )
        except BaseException as exc:
            with self._state_lock:
                self._reader_error = exc
                pending = list(self._pending.values())
                self._pending.clear()
            for future in pending:
                if not future.done():
                    future.set_exception(LspError(f"language server reader failed: {exc}"))

    def _receive(self) -> dict[str, Any]:
        deadline = None
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

    def _fill_size(self, length: int, deadline: float | None) -> None:
        while len(self._read_buffer) < length:
            self._read_more(deadline)

    def _read_more(self, deadline: float | None) -> None:
        while True:
            remaining = 1.0 if deadline is None else deadline - time.monotonic()
            if remaining <= 0:
                raise LspError(f"language server response timed out after {self.timeout}s")
            ready, _, _ = select.select([self.reader.fileno()], [], [], remaining)
            if ready:
                break
            if deadline is not None or self.process.poll() is not None:
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

    def hover_definitions(
        self,
        uri: str,
        positions: list[dict[str, int]],
        *,
        window: int,
    ) -> list[tuple[Any, Any, str]]:
        request_async = getattr(self.transport, "request_async", None)
        if request_async is None:
            return [
                (
                    self.hover(uri, position),
                    self.definition(uri, position),
                    "requested",
                )
                for position in positions
            ]
        definitions = self._request_many(
            request_async,
            "textDocument/definition",
            uri,
            positions,
            window,
        )
        groups: dict[str, list[int]] = {}
        for index, definition in enumerate(definitions):
            if isinstance(definition, BaseException):
                continue
            locations = definition_locations(definition)
            if locations:
                targets = sorted(
                    (
                        str(location["uri"]),
                        json.dumps(
                            location["target_selection_range"],
                            ensure_ascii=False,
                            sort_keys=True,
                            separators=(",", ":"),
                        ),
                    )
                    for location in locations
                )
                key = json.dumps(targets, ensure_ascii=False, separators=(",", ":"))
            else:
                # A no-definition token can still have position-specific hover
                # information, so it must not share another token's response.
                key = f"no-definition:{index}"
            groups.setdefault(key, []).append(index)

        representatives = [indices[0] for indices in groups.values()]
        requested_hovers = self._request_many(
            request_async,
            "textDocument/hover",
            uri,
            [positions[index] for index in representatives],
            window,
        )
        hovers: list[Any] = [None] * len(positions)
        statuses = ["not-requested-definition-error"] * len(positions)
        for indices, hover in zip(groups.values(), requested_hovers):
            for offset, index in enumerate(indices):
                if offset == 0:
                    hovers[index] = hover
                    statuses[index] = "requested"
                    continue
                # Hover.range belongs to the representative occurrence.  Reuse
                # only its semantic contents; the consumer keeps this token's
                # verified candidate range.
                if isinstance(hover, dict):
                    hovers[index] = {
                        key: value for key, value in hover.items() if key != "range"
                    }
                else:
                    hovers[index] = hover
                statuses[index] = "reused-definition"
        return list(zip(hovers, definitions, statuses))

    def _request_many(
        self,
        request_async: Any,
        method: str,
        uri: str,
        positions: list[dict[str, int]],
        window: int,
    ) -> list[Any]:
        timeout = float(getattr(self.transport, "timeout", 120.0))
        results: list[Any] = []
        for offset in range(0, len(positions), max(1, window)):
            batch = positions[offset : offset + max(1, window)]
            pending = []
            for position in batch:
                pending.append(request_async(
                    method,
                    {"textDocument": {"uri": uri}, "position": position},
                ))
            for _request_id, future in pending:
                try:
                    value: Any = future.result(timeout=timeout)
                except FutureTimeoutError as exc:
                    value = LspError(
                        f"{method} request timed out after {timeout}s"
                    )
                except BaseException as exc:
                    value = exc
                results.append(value)
        return results

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

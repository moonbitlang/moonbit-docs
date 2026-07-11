"""Injectable subprocess boundary used by the indexer and tests."""

from __future__ import annotations

import os
import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import Protocol, Sequence


@dataclass(frozen=True)
class CommandResult:
    args: tuple[str, ...]
    returncode: int
    stdout: bytes
    stderr: bytes


class Runner(Protocol):
    def run(self, args: Sequence[str], *, cwd: Path | None = None, input: bytes | None = None, timeout: float | None = None) -> CommandResult: ...


class SubprocessRunner:
    def run(self, args: Sequence[str], *, cwd: Path | None = None, input: bytes | None = None, timeout: float | None = None) -> CommandResult:
        completed = subprocess.run(
            list(args), cwd=cwd, input=input, capture_output=True, timeout=timeout,
            env={**os.environ, "NO_COLOR": "1"}, check=False,
        )
        return CommandResult(tuple(args), completed.returncode, completed.stdout, completed.stderr)


class CommandError(RuntimeError):
    def __init__(self, result: CommandResult):
        command = " ".join(result.args)
        detail = (result.stdout + result.stderr).decode("utf-8", "replace").strip()
        super().__init__(f"command failed ({result.returncode}): {command}\n{detail}")
        self.result = result

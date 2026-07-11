from __future__ import annotations

from collections import Counter
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
from pathlib import Path
import sys
import tempfile
import threading
import time
import unittest


REPO_ROOT = Path(__file__).resolve().parents[2]
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from scripts.moonbit_semantic.mooncakes import (
    CACHE_SCHEMA,
    DefinitionEvidence,
    MooncakesClient,
)


BASE_URL = "https://mooncakes.test"
MODULE = "acme/lib"
VERSION = "1.2.3"
PACKAGE = "acme/lib/api"


def loc(line: int, column: int, file: str = "api.mbt") -> dict[str, object]:
    return {
        "path": PACKAGE,
        "file": file,
        "line": line,
        "column": column,
    }


PACKAGE_INDEX = {
    "path": PACKAGE,
    "typealias": ["Alias"],
    "traits": [{"name": "Readable", "impls": []}],
    "errors": [
        {"name": "Failure", "methods": ["retry"], "impls": []}
    ],
    "types": [
        {"name": "Widget", "methods": ["run"], "impls": []}
    ],
    "values": ["make"],
    "misc": [
        {"name": "Builtin", "methods": ["inspect"], "impls": []}
    ],
}

MODULE_INDEX = {
    "name": "acme",
    "package": None,
    "childs": [
        {
            "name": "lib",
            "package": None,
            "childs": [
                {"name": "api", "package": PACKAGE_INDEX, "childs": []}
            ],
        }
    ],
}

PACKAGE_DATA = {
    "name": PACKAGE,
    "typealias": [
        {"name": "Alias", "docstring": "", "signature": "", "loc": loc(10, 16)}
    ],
    "traits": [
        {
            "name": "Readable",
            "docstring": "",
            "signature": "",
            "loc": loc(20, 11),
            "impls": [],
        }
    ],
    "errors": [
        {
            "name": "Failure",
            "docstring": "",
            "signature": "",
            "loc": loc(30, 11),
            "methods": [
                {
                    "name": "retry",
                    "docstring": "",
                    "signature": "",
                    "loc": loc(31, 13),
                }
            ],
            "impls": [],
        }
    ],
    "types": [
        {
            "name": "Widget",
            "docstring": "",
            "signature": "",
            "loc": loc(40, 16),
            "methods": [
                {
                    "name": "run",
                    "docstring": "",
                    "signature": "",
                    "loc": loc(41, 12),
                }
            ],
            "impls": [
                {
                    "methods": [
                        {
                            "name": "hidden_impl_method",
                            "docstring": "",
                            "signature": "",
                            "loc": loc(42, 12),
                        }
                    ]
                }
            ],
        }
    ],
    "values": [
        {"name": "make", "docstring": "", "signature": "", "loc": loc(50, 8)}
    ],
    # Current Mooncakes misc records can lack ``loc``.  The resolver supports a
    # location when the provider adds one, while still refusing to guess when it
    # is absent.
    "misc": [
        {
            "name": "Builtin",
            "loc": loc(60, 1),
            "methods": [
                {
                    "name": "inspect",
                    "docstring": "",
                    "signature": "",
                    "loc": loc(61, 12),
                }
            ],
            "impls": [],
        }
    ],
}


class FakeFetcher:
    def __init__(self, responses: dict[str, object], *, delay: float = 0.0):
        self.responses = responses
        self.delay = delay
        self.calls: list[str] = []
        self.lock = threading.Lock()

    def __call__(self, url: str):
        with self.lock:
            self.calls.append(url)
        if self.delay:
            time.sleep(self.delay)
        if url not in self.responses:
            raise OSError(f"unexpected URL: {url}")
        # Return bytes to exercise the same decoding path as the real fetcher.
        return json.dumps(self.responses[url]).encode("utf-8")


def endpoints(
    *,
    module: str = MODULE,
    version: str = VERSION,
    package: str = PACKAGE,
    core: bool = False,
) -> tuple[str, str, str]:
    suffix = package.removeprefix(module).lstrip("/")
    manifest_module = module if core else f"{module}@{version}"
    manifest = f"{BASE_URL}/api/v0/manifest/{manifest_module}"
    if suffix:
        manifest += "/" + suffix
    asset = f"{BASE_URL}/assets/{module}@{version}"
    module_index = asset + "/module_index.json"
    package_data = asset + ("/" + suffix if suffix else "") + "/package_data.json"
    return manifest, module_index, package_data


def responses(
    *,
    manifest: dict[str, object] | None = None,
    module_index: dict[str, object] | None = None,
    package_data: dict[str, object] | None = None,
) -> dict[str, object]:
    manifest_url, module_index_url, package_data_url = endpoints()
    return {
        manifest_url: manifest
        or {
            "name": PACKAGE,
            "module": MODULE,
            "version": VERSION,
            "has_package": True,
            "build_status": "success",
        },
        module_index_url: module_index or MODULE_INDEX,
        package_data_url: package_data or PACKAGE_DATA,
    }


def evidence(line: int, column: int, file: str = "api.mbt") -> DefinitionEvidence:
    return DefinitionEvidence(MODULE, VERSION, PACKAGE, file, line, column)


class MooncakesResolverTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.cache = Path(self.temp.name) / "cache"

    def tearDown(self) -> None:
        self.temp.cleanup()

    def client(
        self,
        fetcher: FakeFetcher,
        *,
        offline: bool = False,
        refresh: bool = False,
        cache: Path | None = None,
    ) -> MooncakesClient:
        return MooncakesClient(
            cache or self.cache,
            offline=offline,
            refresh=refresh,
            fetcher=fetcher,
            base_url=BASE_URL,
        )

    def test_resolves_only_supported_top_levels_and_direct_methods(self) -> None:
        fetcher = FakeFetcher(responses())
        client = self.client(fetcher)
        cases = [
            (10, 16, "Alias", "typealias"),
            (20, 11, "Readable", "trait"),
            (30, 11, "Failure", "error"),
            (31, 13, "Failure::retry", "method"),
            (40, 16, "Widget", "type"),
            (41, 12, "Widget::run", "method"),
            (50, 8, "make", "value"),
            (60, 1, "Builtin", "misc"),
            (61, 12, "Builtin::inspect", "method"),
        ]
        for line, column, fragment, kind in cases:
            with self.subTest(fragment=fragment):
                result = client.resolve(evidence(line, column))
                self.assertTrue(result.exact, result)
                self.assertEqual(result.fragment, fragment)
                self.assertEqual(result.symbol_kind, kind)
                self.assertEqual(
                    result.url,
                    f"{BASE_URL}/docs/{MODULE}@{VERSION}/api#{fragment}",
                )
                self.assertNotIn("%3A", result.url)

        hidden = client.resolve(evidence(42, 12))
        self.assertEqual(hidden.status, "unsupported")
        self.assertEqual(hidden.url, "")

    def test_requires_exact_one_based_file_line_and_column(self) -> None:
        fetcher = FakeFetcher(responses())
        client = self.client(fetcher)
        exact = client.resolve(evidence(50, 8))
        self.assertTrue(exact.exact)
        for item in (
            evidence(49, 8),
            evidence(50, 7),
            evidence(50, 8, "other.mbt"),
        ):
            with self.subTest(item=item):
                result = client.resolve(item)
                self.assertEqual(result.status, "unsupported")
                self.assertEqual(result.url, "")

    def test_core_uses_unversioned_manifest_and_docs_but_versioned_assets(self) -> None:
        module = "moonbitlang/core"
        package = "moonbitlang/core/cmp"
        published = "0.1.20260622+a46be2066"
        manifest_url, module_index_url, package_data_url = endpoints(
            module=module, version=published, package=package, core=True
        )
        core_index = {
            "name": "moonbitlang",
            "package": None,
            "childs": [
                {
                    "name": "core",
                    "package": None,
                    "childs": [
                        {
                            "name": "cmp",
                            "package": {
                                "path": package,
                                "typealias": [],
                                "traits": [],
                                "errors": [],
                                "types": [],
                                "values": ["maximum"],
                                "misc": [],
                            },
                            "childs": [],
                        }
                    ],
                }
            ],
        }
        core_data = {
            "name": package,
            "typealias": [],
            "traits": [],
            "errors": [],
            "types": [],
            "values": [
                {
                    "name": "maximum",
                    "loc": {
                        "path": package,
                        "file": "cmp.mbt",
                        "line": 103,
                        "column": 21,
                    },
                }
            ],
            "misc": [],
        }
        fetcher = FakeFetcher(
            {
                manifest_url: {
                    "name": package,
                    "module": module,
                    "version": published,
                    "has_package": True,
                    "build_status": "success",
                },
                module_index_url: core_index,
                package_data_url: core_data,
            }
        )
        client = self.client(fetcher)
        result = client.resolve(
            DefinitionEvidence(
                module,
                "0.10.2+toolchain-version",
                package,
                "cmp.mbt",
                103,
                21,
            )
        )

        self.assertTrue(result.exact, result)
        self.assertEqual(result.resolved_version, published)
        self.assertEqual(result.manifest_url, manifest_url)
        self.assertEqual(result.module_index_url, module_index_url)
        self.assertEqual(result.package_data_url, package_data_url)
        self.assertEqual(
            result.url,
            f"{BASE_URL}/docs/moonbitlang/core/cmp#maximum",
        )
        self.assertNotIn("toolchain-version", "\n".join(fetcher.calls))

        # A new online build must revalidate the mutable, unversioned core
        # manifest while retaining the immutable versioned asset cache.
        cached_fetcher = FakeFetcher(fetcher.responses)
        cached = self.client(cached_fetcher).resolve(
            DefinitionEvidence(
                module,
                "0.10.2+toolchain-version",
                package,
                "cmp.mbt",
                103,
                21,
            )
        )
        self.assertTrue(cached.exact, cached)
        self.assertEqual(cached_fetcher.calls, [manifest_url])

    def test_manifest_and_module_index_are_required_evidence(self) -> None:
        wrong_manifest = {
            "name": PACKAGE,
            "module": MODULE,
            "version": "9.9.9",
            "has_package": True,
            "build_status": "success",
        }
        wrong_fetcher = FakeFetcher(responses(manifest=wrong_manifest))
        wrong = self.client(wrong_fetcher).resolve(evidence(50, 8))
        self.assertEqual(wrong.status, "unavailable")
        self.assertEqual(len(wrong_fetcher.calls), 1)

        no_route_index = json.loads(json.dumps(MODULE_INDEX))
        package_index = no_route_index["childs"][0]["childs"][0]["package"]
        package_index["values"] = []
        missing = self.client(
            FakeFetcher(responses(module_index=no_route_index)),
            cache=self.cache / "missing-route",
        ).resolve(evidence(50, 8))
        self.assertEqual(missing.status, "unsupported")
        self.assertEqual(missing.url, "")

    def test_duplicate_exact_locations_are_ambiguous(self) -> None:
        duplicate_index = json.loads(json.dumps(MODULE_INDEX))
        duplicate_package_index = duplicate_index["childs"][0]["childs"][0]["package"]
        duplicate_package_index["values"] = ["first", "second"]
        duplicate_data = json.loads(json.dumps(PACKAGE_DATA))
        duplicate_data["values"] = [
            {"name": "first", "loc": loc(70, 8)},
            {"name": "second", "loc": loc(70, 8)},
        ]
        client = self.client(
            FakeFetcher(
                responses(
                    module_index=duplicate_index,
                    package_data=duplicate_data,
                )
            )
        )

        result = client.resolve(evidence(70, 8))

        self.assertEqual(result.status, "ambiguous")
        self.assertEqual(result.url, "")

    def test_url_hash_cache_supports_fully_offline_resolution(self) -> None:
        online_fetcher = FakeFetcher(responses())
        online = self.client(online_fetcher)
        first = online.resolve(evidence(50, 8))
        self.assertTrue(first.exact)
        self.assertEqual(len(online_fetcher.calls), 3)

        for url in online_fetcher.calls:
            path = online.cache_path(url)
            self.assertEqual(
                path.name,
                hashlib.sha256(url.encode("utf-8")).hexdigest() + ".json",
            )
            value = json.loads(path.read_text(encoding="utf-8"))
            self.assertEqual(value["schema"], CACHE_SCHEMA)
            self.assertEqual(value["url"], url)
            self.assertIsInstance(value["payload"], dict)
            self.assertEqual(
                value["payload_digest"],
                "sha256:"
                + hashlib.sha256(
                    json.dumps(
                        value["payload"],
                        ensure_ascii=False,
                        sort_keys=True,
                        separators=(",", ":"),
                    ).encode("utf-8")
                    + b"\n"
                ).hexdigest(),
            )
        self.assertFalse(list(self.cache.glob("*.tmp")))

        # Version-qualified dependency data is immutable and remains a normal
        # online cache hit across client lifecycles.
        cached_fetcher = FakeFetcher({})
        cached = self.client(cached_fetcher)
        cached_result = cached.resolve(evidence(50, 8))
        self.assertTrue(cached_result.exact, cached_result)
        self.assertEqual(cached_fetcher.calls, [])

        offline_fetcher = FakeFetcher({})
        offline = self.client(offline_fetcher, offline=True)
        second = offline.resolve(evidence(50, 8))
        self.assertTrue(second.exact, second)
        self.assertEqual(offline_fetcher.calls, [])

    def test_offline_cache_miss_does_not_call_fetcher(self) -> None:
        fetcher = FakeFetcher({})
        client = self.client(
            fetcher,
            offline=True,
            cache=self.cache / "empty",
        )

        result = client.resolve(evidence(50, 8))

        self.assertEqual(result.status, "offline-miss")
        self.assertIn("/api/v0/manifest/", result.reason)
        self.assertEqual(result.url, "")
        self.assertEqual(fetcher.calls, [])

    def test_concurrent_resolutions_single_flight_every_url(self) -> None:
        fetcher = FakeFetcher(responses(), delay=0.03)
        # Refresh bypasses an existing on-disk entry, but each URL must still
        # be fetched only once for this client lifecycle.
        client = self.client(fetcher, refresh=True)

        with ThreadPoolExecutor(max_workers=12) as executor:
            results = list(executor.map(lambda _index: client.resolve(evidence(50, 8)), range(24)))

        self.assertTrue(all(result.exact for result in results), results)
        self.assertEqual(Counter(fetcher.calls), Counter({url: 1 for url in responses()}))

    def test_invalid_evidence_never_fetches(self) -> None:
        fetcher = FakeFetcher({})
        client = self.client(fetcher)

        result = client.resolve(
            DefinitionEvidence(MODULE, "", "other/package", "../bad.mbt", 0, 0)
        )

        self.assertEqual(result.status, "invalid-evidence")
        self.assertEqual(fetcher.calls, [])


if __name__ == "__main__":
    unittest.main()

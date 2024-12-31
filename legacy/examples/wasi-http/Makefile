.DEFAULT_GOAL = build

serve: build
	@wasmtime serve target/wasm/debug/build/gen/gen.wasm

build:
	@moon build --target wasm -g
	@wasm-tools component embed wit target/wasm/debug/build/gen/gen.wasm -o target/wasm/debug/build/gen/gen.wasm --encoding utf16 -g
	@wasm-tools component new target/wasm/debug/build/gen/gen.wasm -o target/wasm/debug/build/gen/gen.wasm -g

regenerate:
	@wit-deps update
	@wit-bindgen moonbit --out-dir . wit --derive-show --derive-eq --derive-error --project-name moonbit-community/wasi-http
	@moon fmt
run:
	moon build
	wat2wasm target/build/main/main.wat --output=target/tetris.wasm
	sudo python3 -m http.server 80
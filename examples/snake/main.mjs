
// @ts-check
import ffi from './.mooncakes/peter-jerry-ye/canvas/import.mjs';
const canvas = /** @type {HTMLCanvasElement | null} */ (document.getElementById("canvas"));
const context = canvas?.getContext("2d")
if (!canvas || !context) {
    throw Error("Canvas not found");
}
const WIDTH = 480
const HEIGHT = WIDTH

canvas.width = WIDTH
canvas.height = HEIGHT

context.scale(24, 24)

/** @type {WebAssembly.Memory} */
let memory

const importObject = {
    ...ffi(() => memory),
    game: {
        get_context: () => context,
    },
    Math: {
        random: Math.random,
        floor: Math.floor,
    },
};

WebAssembly.instantiateStreaming(fetch("target/wasm-gc/release/build/main/main.wasm"), importObject).then(
    (obj) => {
        memory = /** @type {WebAssembly.Memory} */ (obj.instance.exports["moonbit.memory"]);
        // @ts-ignore
        obj.instance.exports._start();
    }
)

import ffi from './.mooncakes/peter-jerry-ye/canvas/import.mjs';
const canvas = (document.getElementById("canvas"));
const context = canvas?.getContext("2d")
if (!canvas || !context) {
    throw Error("Canvas not found");
}
const WIDTH = 480
const HEIGHT = WIDTH

canvas.width = WIDTH
canvas.height = HEIGHT

context.scale(24, 24)

let memory

const importObject = {
    ...ffi(() => memory)
};

WebAssembly.instantiateStreaming(fetch("target/wasm-gc/release/build/main/main.wasm"), importObject).then(
    (obj) => {
        memory = (obj.instance.exports["moonbit.memory"]);
        obj.instance.exports._start();
        obj.instance.exports.entry(context, new Date().getTime());
    }
)
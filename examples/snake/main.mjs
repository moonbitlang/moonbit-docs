
// @ts-check

const canvas = /** @type {HTMLCanvasElement | null} */ (document.getElementById("canvas"));
const context = canvas?.getContext("2d")
if (!canvas || !context) {
    throw Error("Canvas not found");
}

context.scale(24, 24)

const [log, flush] = (() => {
    var buffer = [];
    function flush() {
        if (buffer.length > 0) {
            console.log(new TextDecoder("utf-16").decode(new Uint16Array(buffer).valueOf()));
            buffer = [];
        }
    }
    function log(ch) {
        if (ch == '\n'.charCodeAt(0)) { flush(); }
        else if (ch == '\r'.charCodeAt(0)) { /* noop */ }
        else { buffer.push(ch); }
    }
    return [log, flush]
})();

const importObject = {
    canvas: {
        get_context: () => context,
        stroke_rect: (ctx, x, y, width, height) => ctx.strokeRect(x, y, width, height),
        set_line_width: (ctx, width) => ctx.lineWidth = width,
        fill_rect: (ctx, x, y, width, height) => ctx.fillRect(x, y, width, height),
        set_stroke_color: (ctx, color) => ctx.strokeStyle = color,
        set_fill_style: (ctx, color) => ctx.fillStyle = color
    },
    spectest: {
        print_char: log,
    },
    array: {
        new: () => [],
        /** @type {(array: number[], value: number) => void} */
        push: (array, value) => { array.push(value) },
    },
    string: {
        /** @type {(points: number[]) => String} */
        fromCodePoint: (points) => String.fromCodePoint(...points),
        /** @type {(str: String, callback: (arg: number) => void) => void} */
        iter: (str, callback) => {
            for (const ch of str) { callback(ch.codePointAt(0) || 0) }
        }
    },
    Math: {
        random: Math.random,
        floor: Math.floor,
    },
    keyboard_event: {
        /** @type {(event: KeyboardEvent) => String} */
        key: (event) => event.key,
    },
    document: {
        /** @type {(callback: (ev: KeyboardEvent) => void) => void} */
        set_onkeydown: (callback) => { document.onkeydown = callback },
    },
    window: {
        requestAnimationFrame: window.requestAnimationFrame
    },
    "moonbit:ffi": {
        make_closure: (funcref, closure) => funcref.bind(null, closure)
    },
};

WebAssembly.instantiateStreaming(fetch("target/wasm/release/build/main/main.wasm"), importObject).then(
    (obj) => {
        // @ts-ignore
        obj.instance.exports._start();
        flush();
    }
)
//  Copyright 2024 International Digital Economy Academy
// 
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
// 
//      http://www.apache.org/licenses/LICENSE-2.0
// 
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

let memory;

const [log, flush] = (() => {
    let buffer = [];
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
    spectest: {
        print_char: log
    },
    js_string: {
        new: (offset, length) => {
            const bytes = new Uint16Array(memory.buffer, offset, length);
            const string = new TextDecoder("utf-16").decode(bytes);
            return string
        },
        empty: () => { return "" },
        log: (string) => { console.log(string) },
        append: (s1, s2) => { return (s1 + s2) },
    }
};
WebAssembly.instantiateStreaming(fetch(new URL("target/wasm-gc/release/build/main/main.wasm", import.meta.url)), importObject)
    .catch(async (reason) => {
        if (reason instanceof TypeError && reason.cause.message === "not implemented... yet...") {
            /// Node.js
            const { readFile } = await import('node:fs/promises');
            await WebAssembly.instantiate(await readFile(new URL("target/wasm-gc/release/build/main/main.wasm", import.meta.url)), importObject);
        } else {
            throw reason;
        }
    })
    .then(
        (obj) => {
            memory = obj.instance.exports["moonbit.memory"];
            obj.instance.exports._start();
            flush();
        }
    )
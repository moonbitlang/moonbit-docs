import mod from './lib.wasm';

const spectest = {
  spectest: {
    print_i32: (x) => () => {},
    print_char: (x) => () => {},
    print_f64: (x) => () => {},
  },
};

const instance = await WebAssembly.instantiate(mod, spectest);

export default {
  async fetch() {
    // wat2wasm src/lib.wat -o src/lib.wasm
    const retval = instance.exports['cf_worker_demo/lib::add'](2, 5);
    return new Response(`Success: ${retval}`);
  },
};

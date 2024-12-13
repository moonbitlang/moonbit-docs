import { defineConfig } from "vite";
import { BASE } from "./dev/const";
import generatePlugin from "./dev/generate-plugin";
import indexPlugin from "./dev/index-plugin";

export default defineConfig({
  base: BASE,
  build: {
    outDir: "dist/tour",
    rollupOptions: {
      output: {
        entryFileNames: `assets/[name].js`,
        chunkFileNames: `assets/[name].js`,
        assetFileNames: `assets/[name].[ext]`,
      },
    },
  },
  worker: {
    rollupOptions: {
      output: {
        entryFileNames: `assets/[name].js`,
        chunkFileNames: `assets/[name].js`,
        assetFileNames: `assets/[name].[ext]`,
      },
    },
  },
  plugins: [indexPlugin(), generatePlugin()],
});

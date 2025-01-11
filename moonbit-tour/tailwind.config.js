/** @type {import('tailwindcss').Config} */
export default {
  darkMode: "class",
  content: ["./index.html", "./src/**/*.{js,ts,jsx,tsx}", "./build/*.ts"],
  theme: {
    fontFamily: {
      sans: [
        '"Inter"',
        "ui-sans-serif",
        "system-ui",
        "sans-serif",
        '"Apple Color Emoji"',
        '"Segoe UI Emoji"',
        '"Segoe UI Symbol"',
        '"Noto Color Emoji"',
      ],
      mono: [
        "ui-monospace",
        "SFMono-Regular",
        "Menlo",
        "Monaco",
        "Consolas",
        '"Liberation Mono"',
        '"Courier New"',
        "monospace",
      ],
      serif: [
        "ui-serif",
        "Georgia",
        "Cambria",
        '"Times New Roman"',
        "Times",
        "serif",
      ],
    },
    extend: {
      typography: {
        DEFAULT: {
          css: {
            "code::before": {
              content: '""',
            },
            "code::after": {
              content: '""',
            },
            code: {
              backgroundColor: "#f7fafc",
              borderRadius: "0.25rem",
              padding: "0.125rem 0.25rem",
              border: "1px solid #e9e9e9",
              color: "#222",
            },
          },
        },
        invert: {
          css: {
            code: {
              backgroundColor: "#1f2937",
              border: "1px solid #374151",
              color: "#d1d5db",
            },
          },
        },
      },
    },
  },
  plugins: [require("@tailwindcss/typography")],
};

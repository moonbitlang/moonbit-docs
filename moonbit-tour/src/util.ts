import type * as type from "./type";

export function debounce<P extends any[], R>(
  f: (...args: P) => R,
  timeout: number,
) {
  let timer: ReturnType<typeof setTimeout> | null = null;
  return (...args: P) => {
    if (timer !== null) {
      clearTimeout(timer);
    }
    timer = setTimeout(() => {
      f(...args);
      timer = null;
    }, timeout);
  };
}

export function getTheme(): type.Theme {
  return (localStorage.getItem("theme") as type.Theme) ?? "light";
}

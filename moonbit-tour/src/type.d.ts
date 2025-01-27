export type RouteState = {
  title: string;
  markdownHtml: string;
  code: string;
  back: string;
  next: string;
  index: number;
  total: number;
};

export type Theme = "light" | "dark";

interface CustomEventMap {
  "route-change": CustomEvent<RouteState>;
  "theme-change": CustomEvent<Theme>;
}
declare global {
  interface Window {
    addEventListener<K extends keyof CustomEventMap>(
      type: K,
      listener: (this: Document, ev: CustomEventMap[K]) => void,
    ): void;
    dispatchEvent<K extends keyof CustomEventMap>(ev: CustomEventMap[K]): void;
  }
}

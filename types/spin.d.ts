declare module 'spin' {
  interface SpinnerOptions {
    lines?: number;
    length?: number;
    width?: number;
    radius?: number;
    scale?: number;
    corners?: number;
    color?: string | string[];
    fadeColor?: string;
    opacity?: number;
    rotate?: number;
    direction?: 1 | -1;
    speed?: number;
    trail?: number;
    fps?: number;
    zIndex?: number;
    className?: string;
    top?: string;
    left?: string;
    shadow?: string;
    position?: string;
  }

  interface SpinnerInstance {
    spin(target?: HTMLElement): this;
    stop(): this;
    el?: HTMLElement;
  }

  interface SpinnerConstructor {
    new(options?: SpinnerOptions): SpinnerInstance;
  }

  const Spinner: SpinnerConstructor;
  export = Spinner;
}

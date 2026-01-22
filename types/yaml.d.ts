declare module '*/globals.yaml' {
  import type { GlobalConfig } from '../src/types';
  const content: GlobalConfig;
  export default content;
}

declare module '*/pluginHooks.yaml' {
  const content: string[];
  export default content;
}

declare module '*.yaml' {
  const content: Record<string, unknown>;
  export default content;
}

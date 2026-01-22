import type { Object3D, WebGLRenderer, PerspectiveCamera, WebGLRenderTarget } from 'three'
import type Bundle from '../client/bundle.js'
import type Node from '../common/project/node.js'

export interface Plugin {
  name: string;
  version: string;
  description?: string;

  // Lifecycle hooks
  init?(bundle?: Bundle): void;
  init3d?(threeNode: Object3D): void;

  // Event hooks
  onNodeAdd?(node: Node): void | Promise<void>;
  onNodeRemove?(node: Node): void | Promise<void>;
  on3dUpdate?(timestamp: number): void;
  onPaint?(
    renderer: WebGLRenderer,
    camera: PerspectiveCamera,
    target: WebGLRenderTarget
  ): void;
  onStateUpdate?(state: unknown): void;

  // Optional methods
  getHotkeys?(): HotkeyConfig | undefined;
  getDownload?(node: Node, options: DownloadOptions): Promise<DownloadResult[]> | null;

  // Allow additional properties for plugin-specific data
  [key: string]: unknown;
}

export interface HotkeyConfig {
  title: string;
  events: HotkeyEvent[];
}

export interface HotkeyEvent {
  hotkey: string;
  description: string;
  callback: () => void;
}

export interface DownloadOptions {
  type: 'stl' | 'lego' | 'instructions';
  studRadius?: number;
  holeRadius?: number;
}

export interface DownloadResult {
  data: string | ArrayBuffer | Blob;
  fileName: string;
}

export interface PluginPackageJson {
  name: string;
  version: string;
  description?: string;
  brickify?: {
    type: string;
  };
  browser?: string;
}

export interface PluginConstructor {
  new (): Plugin;
}

export interface PluginModule {
  default: PluginConstructor;
}

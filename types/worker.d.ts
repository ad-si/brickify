declare const self: DedicatedWorkerGlobalScope;

export interface WorkerMessage {
  type: string;
  data?: unknown;
}

export interface VoxelizeMessage extends WorkerMessage {
  type: 'voxelize';
  data: {
    model: {
      faceVertexIndices: number[];
      coordinates: number[];
      directions: number[];
    };
    lineStepSize: number;
    floatDelta: number;
    voxelRoundingThreshold: number;
  };
}

export interface ProgressMessage {
  state: 'progress' | 'finished' | 'error';
  progress?: number;
  data?: unknown;
  error?: string;
}

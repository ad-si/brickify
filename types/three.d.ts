// Type declarations for the custom Three.js fork (brickify/three.js#dev-20150416)
// This fork may have APIs that differ from official Three.js types

declare module 'three' {
  // Core Math
  export class Vector2 {
    constructor(x?: number, y?: number);
    x: number;
    y: number;
    set(x: number, y: number): this;
    clone(): Vector2;
    copy(v: Vector2): this;
    add(v: Vector2): this;
    sub(v: Vector2): this;
    multiply(v: Vector2): this;
    divide(v: Vector2): this;
    multiplyScalar(s: number): this;
    divideScalar(s: number): this;
    normalize(): this;
    length(): number;
    lengthSq(): number;
    dot(v: Vector2): number;
    equals(v: Vector2): boolean;
    fromArray(array: number[], offset?: number): this;
    toArray(array?: number[], offset?: number): number[];
  }

  export class Vector3 {
    constructor(x?: number, y?: number, z?: number);
    x: number;
    y: number;
    z: number;
    set(x: number, y: number, z: number): this;
    setX(x: number): this;
    setY(y: number): this;
    setZ(z: number): this;
    clone(): Vector3;
    copy(v: Vector3): this;
    add(v: Vector3): this;
    addScalar(s: number): this;
    addVectors(a: Vector3, b: Vector3): this;
    sub(v: Vector3): this;
    subScalar(s: number): this;
    subVectors(a: Vector3, b: Vector3): this;
    multiply(v: Vector3): this;
    multiplyScalar(s: number): this;
    multiplyVectors(a: Vector3, b: Vector3): this;
    divide(v: Vector3): this;
    divideScalar(s: number): this;
    applyMatrix3(m: Matrix3): this;
    applyMatrix4(m: Matrix4): this;
    applyProjection(m: Matrix4): this;
    applyQuaternion(q: Quaternion): this;
    applyEuler(euler: Euler): this;
    applyAxisAngle(axis: Vector3, angle: number): this;
    transformDirection(m: Matrix4): this;
    min(v: Vector3): this;
    max(v: Vector3): this;
    clamp(min: Vector3, max: Vector3): this;
    clampScalar(min: number, max: number): this;
    clampLength(min: number, max: number): this;
    floor(): this;
    ceil(): this;
    round(): this;
    roundToZero(): this;
    negate(): this;
    dot(v: Vector3): number;
    lengthSq(): number;
    length(): number;
    manhattanLength(): number;
    normalize(): this;
    setLength(length: number): this;
    lerp(v: Vector3, alpha: number): this;
    lerpVectors(v1: Vector3, v2: Vector3, alpha: number): this;
    cross(v: Vector3): this;
    crossVectors(a: Vector3, b: Vector3): this;
    projectOnVector(v: Vector3): this;
    projectOnPlane(planeNormal: Vector3): this;
    reflect(normal: Vector3): this;
    angleTo(v: Vector3): number;
    distanceTo(v: Vector3): number;
    distanceToSquared(v: Vector3): number;
    manhattanDistanceTo(v: Vector3): number;
    setFromSpherical(s: Spherical): this;
    setFromSphericalCoords(radius: number, phi: number, theta: number): this;
    setFromCylindrical(c: Cylindrical): this;
    setFromCylindricalCoords(radius: number, theta: number, y: number): this;
    setFromMatrixPosition(m: Matrix4): this;
    setFromMatrixScale(m: Matrix4): this;
    setFromMatrixColumn(m: Matrix4, index: number): this;
    equals(v: Vector3): boolean;
    fromArray(array: ArrayLike<number>, offset?: number): this;
    toArray(array?: number[], offset?: number): number[];
    project(camera: Camera): this;
    unproject(camera: Camera): this;
  }

  export class Vector4 {
    constructor(x?: number, y?: number, z?: number, w?: number);
    x: number;
    y: number;
    z: number;
    w: number;
    set(x: number, y: number, z: number, w: number): this;
    clone(): Vector4;
    copy(v: Vector4): this;
    add(v: Vector4): this;
    sub(v: Vector4): this;
    multiplyScalar(s: number): this;
    normalize(): this;
    length(): number;
    lengthSq(): number;
    equals(v: Vector4): boolean;
  }

  export class Matrix3 {
    elements: number[];
    constructor();
    set(
      n11: number, n12: number, n13: number,
      n21: number, n22: number, n23: number,
      n31: number, n32: number, n33: number
    ): this;
    identity(): this;
    clone(): Matrix3;
    copy(m: Matrix3): this;
    setFromMatrix4(m: Matrix4): this;
    multiply(m: Matrix3): this;
    premultiply(m: Matrix3): this;
    multiplyMatrices(a: Matrix3, b: Matrix3): this;
    multiplyScalar(s: number): this;
    determinant(): number;
    getInverse(m: Matrix3, throwOnDegenerate?: boolean): this;
    transpose(): this;
    getNormalMatrix(m: Matrix4): this;
    transposeIntoArray(r: number[]): this;
    fromArray(array: number[], offset?: number): this;
    toArray(array?: number[], offset?: number): number[];
  }

  export class Matrix4 {
    elements: number[];
    constructor();
    set(
      n11: number, n12: number, n13: number, n14: number,
      n21: number, n22: number, n23: number, n24: number,
      n31: number, n32: number, n33: number, n34: number,
      n41: number, n42: number, n43: number, n44: number
    ): this;
    identity(): this;
    clone(): Matrix4;
    copy(m: Matrix4): this;
    copyPosition(m: Matrix4): this;
    extractBasis(xAxis: Vector3, yAxis: Vector3, zAxis: Vector3): this;
    makeBasis(xAxis: Vector3, yAxis: Vector3, zAxis: Vector3): this;
    extractRotation(m: Matrix4): this;
    makeRotationFromEuler(euler: Euler): this;
    makeRotationFromQuaternion(q: Quaternion): this;
    lookAt(eye: Vector3, target: Vector3, up: Vector3): this;
    multiply(m: Matrix4): this;
    premultiply(m: Matrix4): this;
    multiplyMatrices(a: Matrix4, b: Matrix4): this;
    multiplyScalar(s: number): this;
    determinant(): number;
    transpose(): this;
    setPosition(v: Vector3): this;
    setPosition(x: number, y: number, z: number): this;
    getInverse(m: Matrix4, throwOnDegenerate?: boolean): this;
    scale(v: Vector3): this;
    getMaxScaleOnAxis(): number;
    makeTranslation(x: number, y: number, z: number): this;
    makeRotationX(theta: number): this;
    makeRotationY(theta: number): this;
    makeRotationZ(theta: number): this;
    makeRotationAxis(axis: Vector3, angle: number): this;
    makeScale(x: number, y: number, z: number): this;
    makeShear(x: number, y: number, z: number): this;
    compose(position: Vector3, quaternion: Quaternion, scale: Vector3): this;
    decompose(position: Vector3, quaternion: Quaternion, scale: Vector3): this;
    makePerspective(
      left: number, right: number, top: number, bottom: number,
      near: number, far: number
    ): this;
    makeOrthographic(
      left: number, right: number, top: number, bottom: number,
      near: number, far: number
    ): this;
    equals(m: Matrix4): boolean;
    fromArray(array: ArrayLike<number>, offset?: number): this;
    toArray(array?: number[], offset?: number): number[];
  }

  export class Quaternion {
    constructor(x?: number, y?: number, z?: number, w?: number);
    x: number;
    y: number;
    z: number;
    w: number;
    set(x: number, y: number, z: number, w: number): this;
    clone(): Quaternion;
    copy(q: Quaternion): this;
    setFromEuler(euler: Euler, update?: boolean): this;
    setFromAxisAngle(axis: Vector3, angle: number): this;
    setFromRotationMatrix(m: Matrix4): this;
    setFromUnitVectors(vFrom: Vector3, vTo: Vector3): this;
    angleTo(q: Quaternion): number;
    rotateTowards(q: Quaternion, step: number): this;
    inverse(): this;
    conjugate(): this;
    dot(q: Quaternion): number;
    lengthSq(): number;
    length(): number;
    normalize(): this;
    multiply(q: Quaternion): this;
    premultiply(q: Quaternion): this;
    multiplyQuaternions(a: Quaternion, b: Quaternion): this;
    slerp(q: Quaternion, t: number): this;
    equals(q: Quaternion): boolean;
    fromArray(array: ArrayLike<number>, offset?: number): this;
    toArray(array?: number[], offset?: number): number[];
  }

  export class Euler {
    constructor(x?: number, y?: number, z?: number, order?: string);
    x: number;
    y: number;
    z: number;
    order: string;
    set(x: number, y: number, z: number, order?: string): this;
    clone(): Euler;
    copy(euler: Euler): this;
    setFromRotationMatrix(m: Matrix4, order?: string, update?: boolean): this;
    setFromQuaternion(q: Quaternion, order?: string, update?: boolean): this;
    setFromVector3(v: Vector3, order?: string): this;
    reorder(newOrder: string): this;
    equals(euler: Euler): boolean;
    fromArray(array: ArrayLike<number>): this;
    toArray(array?: number[], offset?: number): number[];
    toVector3(optionalResult?: Vector3): Vector3;
  }

  // Geometry
  export class Box2 {
    constructor(min?: Vector2, max?: Vector2);
    min: Vector2;
    max: Vector2;
    set(min: Vector2, max: Vector2): this;
    setFromPoints(points: Vector2[]): this;
    setFromCenterAndSize(center: Vector2, size: Vector2): this;
    clone(): Box2;
    copy(box: Box2): this;
    makeEmpty(): this;
    isEmpty(): boolean;
    getCenter(target?: Vector2): Vector2;
    getSize(target?: Vector2): Vector2;
    expandByPoint(point: Vector2): this;
    expandByVector(vector: Vector2): this;
    expandByScalar(scalar: number): this;
    containsPoint(point: Vector2): boolean;
    containsBox(box: Box2): boolean;
    getParameter(point: Vector2, target?: Vector2): Vector2;
    intersectsBox(box: Box2): boolean;
    clampPoint(point: Vector2, target?: Vector2): Vector2;
    distanceToPoint(point: Vector2): number;
    intersect(box: Box2): this;
    union(box: Box2): this;
    translate(offset: Vector2): this;
    equals(box: Box2): boolean;
  }

  export class Box3 {
    constructor(min?: Vector3, max?: Vector3);
    min: Vector3;
    max: Vector3;
    set(min: Vector3, max: Vector3): this;
    setFromArray(array: ArrayLike<number>): this;
    setFromBufferAttribute(attribute: BufferAttribute): this;
    setFromPoints(points: Vector3[]): this;
    setFromCenterAndSize(center: Vector3, size: Vector3): this;
    setFromObject(object: Object3D): this;
    clone(): Box3;
    copy(box: Box3): this;
    makeEmpty(): this;
    isEmpty(): boolean;
    getCenter(target?: Vector3): Vector3;
    getSize(target?: Vector3): Vector3;
    center(): Vector3;
    size(): Vector3;
    expandByPoint(point: Vector3): this;
    expandByVector(vector: Vector3): this;
    expandByScalar(scalar: number): this;
    expandByObject(object: Object3D): this;
    containsPoint(point: Vector3): boolean;
    containsBox(box: Box3): boolean;
    getParameter(point: Vector3, target?: Vector3): Vector3;
    intersectsBox(box: Box3): boolean;
    intersectsSphere(sphere: Sphere): boolean;
    intersectsPlane(plane: Plane): boolean;
    intersectsTriangle(triangle: Triangle): boolean;
    clampPoint(point: Vector3, target?: Vector3): Vector3;
    distanceToPoint(point: Vector3): number;
    getBoundingSphere(target?: Sphere): Sphere;
    intersect(box: Box3): this;
    union(box: Box3): this;
    applyMatrix4(matrix: Matrix4): this;
    translate(offset: Vector3): this;
    equals(box: Box3): boolean;
  }

  export class Sphere {
    constructor(center?: Vector3, radius?: number);
    center: Vector3;
    radius: number;
    set(center: Vector3, radius: number): this;
    setFromPoints(points: Vector3[], optionalCenter?: Vector3): this;
    clone(): Sphere;
    copy(sphere: Sphere): this;
    isEmpty(): boolean;
    makeEmpty(): this;
    containsPoint(point: Vector3): boolean;
    distanceToPoint(point: Vector3): number;
    intersectsSphere(sphere: Sphere): boolean;
    intersectsBox(box: Box3): boolean;
    intersectsPlane(plane: Plane): boolean;
    clampPoint(point: Vector3, target?: Vector3): Vector3;
    getBoundingBox(target?: Box3): Box3;
    applyMatrix4(matrix: Matrix4): this;
    translate(offset: Vector3): this;
    equals(sphere: Sphere): boolean;
  }

  export class Plane {
    constructor(normal?: Vector3, constant?: number);
    normal: Vector3;
    constant: number;
    set(normal: Vector3, constant: number): this;
    setComponents(x: number, y: number, z: number, w: number): this;
    setFromNormalAndCoplanarPoint(normal: Vector3, point: Vector3): this;
    setFromCoplanarPoints(a: Vector3, b: Vector3, c: Vector3): this;
    clone(): Plane;
    copy(plane: Plane): this;
    normalize(): this;
    negate(): this;
    distanceToPoint(point: Vector3): number;
    distanceToSphere(sphere: Sphere): number;
    projectPoint(point: Vector3, target?: Vector3): Vector3;
    intersectLine(line: Line3, target?: Vector3): Vector3 | undefined;
    intersectsLine(line: Line3): boolean;
    intersectsBox(box: Box3): boolean;
    intersectsSphere(sphere: Sphere): boolean;
    coplanarPoint(target?: Vector3): Vector3;
    applyMatrix4(matrix: Matrix4, optionalNormalMatrix?: Matrix3): this;
    translate(offset: Vector3): this;
    equals(plane: Plane): boolean;
  }

  export class Ray {
    constructor(origin?: Vector3, direction?: Vector3);
    origin: Vector3;
    direction: Vector3;
    set(origin: Vector3, direction: Vector3): this;
    clone(): Ray;
    copy(ray: Ray): this;
    at(t: number, target?: Vector3): Vector3;
    lookAt(v: Vector3): this;
    recast(t: number): this;
    closestPointToPoint(point: Vector3, target?: Vector3): Vector3;
    distanceToPoint(point: Vector3): number;
    distanceSqToPoint(point: Vector3): number;
    distanceSqToSegment(
      v0: Vector3, v1: Vector3,
      optionalPointOnRay?: Vector3, optionalPointOnSegment?: Vector3
    ): number;
    intersectSphere(sphere: Sphere, target?: Vector3): Vector3 | null;
    intersectsSphere(sphere: Sphere): boolean;
    distanceToPlane(plane: Plane): number | null;
    intersectPlane(plane: Plane, target?: Vector3): Vector3 | null;
    intersectsPlane(plane: Plane): boolean;
    intersectBox(box: Box3, target?: Vector3): Vector3 | null;
    intersectsBox(box: Box3): boolean;
    intersectTriangle(
      a: Vector3, b: Vector3, c: Vector3,
      backfaceCulling: boolean, target?: Vector3
    ): Vector3 | null;
    applyMatrix4(matrix4: Matrix4): this;
    equals(ray: Ray): boolean;
  }

  export class Line3 {
    constructor(start?: Vector3, end?: Vector3);
    start: Vector3;
    end: Vector3;
    set(start: Vector3, end: Vector3): this;
    clone(): Line3;
    copy(line: Line3): this;
    getCenter(target?: Vector3): Vector3;
    delta(target?: Vector3): Vector3;
    distanceSq(): number;
    distance(): number;
    at(t: number, target?: Vector3): Vector3;
    closestPointToPointParameter(point: Vector3, clampToLine?: boolean): number;
    closestPointToPoint(point: Vector3, clampToLine?: boolean, target?: Vector3): Vector3;
    applyMatrix4(matrix: Matrix4): this;
    equals(line: Line3): boolean;
  }

  export class Triangle {
    constructor(a?: Vector3, b?: Vector3, c?: Vector3);
    a: Vector3;
    b: Vector3;
    c: Vector3;
    set(a: Vector3, b: Vector3, c: Vector3): this;
    setFromPointsAndIndices(
      points: Vector3[], i0: number, i1: number, i2: number
    ): this;
    clone(): Triangle;
    copy(triangle: Triangle): this;
    getArea(): number;
    getMidpoint(target?: Vector3): Vector3;
    getNormal(target?: Vector3): Vector3;
    getPlane(target?: Plane): Plane;
    getBarycoord(point: Vector3, target?: Vector3): Vector3;
    containsPoint(point: Vector3): boolean;
    closestPointToPoint(point: Vector3, target?: Vector3): Vector3;
    equals(triangle: Triangle): boolean;

    static getNormal(a: Vector3, b: Vector3, c: Vector3, target?: Vector3): Vector3;
    static getBarycoord(
      point: Vector3, a: Vector3, b: Vector3, c: Vector3, target?: Vector3
    ): Vector3;
    static containsPoint(point: Vector3, a: Vector3, b: Vector3, c: Vector3): boolean;
  }

  export interface Spherical {
    radius: number;
    phi: number;
    theta: number;
  }

  export interface Cylindrical {
    radius: number;
    theta: number;
    y: number;
  }

  // Colors
  export class Color {
    constructor(color?: number | string | Color);
    constructor(r: number, g: number, b: number);
    r: number;
    g: number;
    b: number;
    set(color: number | string | Color): this;
    setScalar(scalar: number): this;
    setHex(hex: number): this;
    setRGB(r: number, g: number, b: number): this;
    setHSL(h: number, s: number, l: number): this;
    setStyle(style: string): this;
    clone(): Color;
    copy(color: Color): this;
    copyGammaToLinear(color: Color, gammaFactor?: number): this;
    copyLinearToGamma(color: Color, gammaFactor?: number): this;
    convertGammaToLinear(gammaFactor?: number): this;
    convertLinearToGamma(gammaFactor?: number): this;
    getHex(): number;
    getHexString(): string;
    getHSL(target?: { h: number; s: number; l: number }): { h: number; s: number; l: number };
    getStyle(): string;
    offsetHSL(h: number, s: number, l: number): this;
    add(color: Color): this;
    addColors(color1: Color, color2: Color): this;
    addScalar(s: number): this;
    sub(color: Color): this;
    multiply(color: Color): this;
    multiplyScalar(s: number): this;
    lerp(color: Color, alpha: number): this;
    lerpHSL(color: Color, alpha: number): this;
    equals(c: Color): boolean;
    fromArray(array: ArrayLike<number>, offset?: number): this;
    toArray(array?: number[], offset?: number): number[];
  }

  // Object3D and Scene
  export class Object3D {
    constructor();

    id: number;
    uuid: string;
    name: string;
    type: string;
    parent: Object3D | null;
    children: Object3D[];
    up: Vector3;
    position: Vector3;
    rotation: Euler;
    quaternion: Quaternion;
    scale: Vector3;
    modelViewMatrix: Matrix4;
    normalMatrix: Matrix3;
    matrix: Matrix4;
    matrixWorld: Matrix4;
    matrixAutoUpdate: boolean;
    matrixWorldNeedsUpdate: boolean;
    visible: boolean;
    castShadow: boolean;
    receiveShadow: boolean;
    frustumCulled: boolean;
    renderOrder: number;
    userData: Record<string, unknown>;

    // Custom Brickify properties
    associatedPlugin?: unknown;
    brickifyNode?: string;

    onBeforeRender: (
      renderer: WebGLRenderer,
      scene: Scene,
      camera: Camera,
      geometry: Geometry | BufferGeometry,
      material: Material,
      group: unknown
    ) => void;
    onAfterRender: (
      renderer: WebGLRenderer,
      scene: Scene,
      camera: Camera,
      geometry: Geometry | BufferGeometry,
      material: Material,
      group: unknown
    ) => void;

    applyMatrix(matrix: Matrix4): void;
    applyMatrix4(matrix: Matrix4): this;
    applyQuaternion(quaternion: Quaternion): this;
    setRotationFromAxisAngle(axis: Vector3, angle: number): void;
    setRotationFromEuler(euler: Euler): void;
    setRotationFromMatrix(m: Matrix4): void;
    setRotationFromQuaternion(q: Quaternion): void;
    rotateOnAxis(axis: Vector3, angle: number): this;
    rotateOnWorldAxis(axis: Vector3, angle: number): this;
    rotateX(angle: number): this;
    rotateY(angle: number): this;
    rotateZ(angle: number): this;
    translateOnAxis(axis: Vector3, distance: number): this;
    translateX(distance: number): this;
    translateY(distance: number): this;
    translateZ(distance: number): this;
    localToWorld(vector: Vector3): Vector3;
    worldToLocal(vector: Vector3): Vector3;
    lookAt(x: number | Vector3, y?: number, z?: number): void;
    add(...object: Object3D[]): this;
    remove(...object: Object3D[]): this;
    removeFromParent(): this;
    clear(): this;
    attach(object: Object3D): this;
    getObjectById(id: number): Object3D | undefined;
    getObjectByName(name: string): Object3D | undefined;
    getObjectByProperty(name: string, value: unknown, recursive?: boolean): Object3D | undefined;
    getWorldPosition(target?: Vector3): Vector3;
    getWorldQuaternion(target?: Quaternion): Quaternion;
    getWorldScale(target?: Vector3): Vector3;
    getWorldDirection(target?: Vector3): Vector3;
    raycast(raycaster: Raycaster, intersects: Intersection[]): void;
    traverse(callback: (object: Object3D) => void): void;
    traverseVisible(callback: (object: Object3D) => void): void;
    traverseAncestors(callback: (object: Object3D) => void): void;
    updateMatrix(): void;
    updateMatrixWorld(force?: boolean): void;
    updateWorldMatrix(updateParents: boolean, updateChildren: boolean): void;
    toJSON(meta?: unknown): unknown;
    clone(recursive?: boolean): this;
    copy(source: Object3D, recursive?: boolean): this;
  }

  export class Scene extends Object3D {
    constructor();
    type: 'Scene';
    fog: Fog | FogExp2 | null;
    background: Color | Texture | null;
    environment: Texture | null;
    overrideMaterial: Material | null;
    autoUpdate: boolean;
    toJSON(meta?: unknown): unknown;
  }

  export class Fog {
    constructor(color: number | string, near?: number, far?: number);
    name: string;
    color: Color;
    near: number;
    far: number;
    clone(): Fog;
    toJSON(): unknown;
  }

  export class FogExp2 {
    constructor(color: number | string, density?: number);
    name: string;
    color: Color;
    density: number;
    clone(): FogExp2;
    toJSON(): unknown;
  }

  // Cameras
  export class Camera extends Object3D {
    constructor();
    type: string;
    matrixWorldInverse: Matrix4;
    projectionMatrix: Matrix4;
    projectionMatrixInverse: Matrix4;
    getWorldDirection(target?: Vector3): Vector3;
    updateMatrixWorld(force?: boolean): void;
    clone(): this;
    copy(source: Camera, recursive?: boolean): this;
  }

  export class PerspectiveCamera extends Camera {
    constructor(fov?: number, aspect?: number, near?: number, far?: number);
    type: 'PerspectiveCamera';
    fov: number;
    zoom: number;
    near: number;
    far: number;
    focus: number;
    aspect: number;
    view: null | {
      enabled: boolean;
      fullWidth: number;
      fullHeight: number;
      offsetX: number;
      offsetY: number;
      width: number;
      height: number;
    };
    filmGauge: number;
    filmOffset: number;
    setFocalLength(focalLength: number): void;
    getFocalLength(): number;
    getEffectiveFOV(): number;
    getFilmWidth(): number;
    getFilmHeight(): number;
    setViewOffset(
      fullWidth: number, fullHeight: number,
      x: number, y: number,
      width: number, height: number
    ): void;
    clearViewOffset(): void;
    updateProjectionMatrix(): void;
    toJSON(meta?: unknown): unknown;
  }

  export class OrthographicCamera extends Camera {
    constructor(
      left?: number, right?: number,
      top?: number, bottom?: number,
      near?: number, far?: number
    );
    type: 'OrthographicCamera';
    zoom: number;
    view: null | {
      enabled: boolean;
      fullWidth: number;
      fullHeight: number;
      offsetX: number;
      offsetY: number;
      width: number;
      height: number;
    };
    left: number;
    right: number;
    top: number;
    bottom: number;
    near: number;
    far: number;
    setViewOffset(
      fullWidth: number, fullHeight: number,
      x: number, y: number,
      width: number, height: number
    ): void;
    clearViewOffset(): void;
    updateProjectionMatrix(): void;
    toJSON(meta?: unknown): unknown;
  }

  // Geometry
  export class Face3 {
    constructor(
      a: number, b: number, c: number,
      normal?: Vector3 | Vector3[],
      color?: Color | Color[],
      materialIndex?: number
    );
    a: number;
    b: number;
    c: number;
    normal: Vector3;
    vertexNormals: Vector3[];
    color: Color;
    vertexColors: Color[];
    materialIndex: number;
    clone(): Face3;
    copy(source: Face3): this;
  }

  export class Geometry {
    constructor();
    id: number;
    uuid: string;
    name: string;
    type: string;
    vertices: Vector3[];
    colors: Color[];
    faces: Face3[];
    faceVertexUvs: Vector2[][][];
    morphTargets: MorphTarget[];
    morphNormals: MorphNormals[];
    skinWeights: Vector4[];
    skinIndices: Vector4[];
    lineDistances: number[];
    boundingBox: Box3 | null;
    boundingSphere: Sphere | null;
    elementsNeedUpdate: boolean;
    verticesNeedUpdate: boolean;
    uvsNeedUpdate: boolean;
    normalsNeedUpdate: boolean;
    colorsNeedUpdate: boolean;
    lineDistancesNeedUpdate: boolean;
    groupsNeedUpdate: boolean;

    applyMatrix(matrix: Matrix4): this;
    applyMatrix4(matrix: Matrix4): this;
    rotateX(angle: number): this;
    rotateY(angle: number): this;
    rotateZ(angle: number): this;
    translate(x: number, y: number, z: number): this;
    scale(x: number, y: number, z: number): this;
    lookAt(vector: Vector3): void;
    fromBufferGeometry(geometry: BufferGeometry): this;
    center(): this;
    normalize(): this;
    computeFaceNormals(): void;
    computeVertexNormals(areaWeighted?: boolean): void;
    computeFlatVertexNormals(): void;
    computeMorphNormals(): void;
    computeBoundingBox(): void;
    computeBoundingSphere(): void;
    merge(
      geometry: Geometry,
      matrix?: Matrix4,
      materialIndexOffset?: number
    ): void;
    mergeMesh(mesh: Mesh): void;
    mergeVertices(): number;
    setFromPoints(points: Vector3[] | Vector2[]): this;
    sortFacesByMaterialIndex(): void;
    toJSON(): unknown;
    clone(): Geometry;
    copy(source: Geometry): this;
    dispose(): void;
  }

  interface MorphTarget {
    name: string;
    vertices: Vector3[];
  }

  interface MorphNormals {
    name: string;
    normals: Vector3[];
  }

  export class BufferAttribute {
    constructor(array: ArrayLike<number>, itemSize: number, normalized?: boolean);
    name: string;
    array: ArrayLike<number>;
    itemSize: number;
    count: number;
    normalized: boolean;
    usage: number;
    updateRange: { offset: number; count: number };
    version: number;
    needsUpdate: boolean;

    onUploadCallback: () => void;
    setUsage(usage: number): this;
    copy(source: BufferAttribute): this;
    copyAt(index1: number, attribute: BufferAttribute, index2: number): this;
    copyArray(array: ArrayLike<number>): this;
    copyColorsArray(colors: Array<{ r: number; g: number; b: number }>): this;
    copyVector2sArray(vectors: Vector2[]): this;
    copyVector3sArray(vectors: Vector3[]): this;
    copyVector4sArray(vectors: Vector4[]): this;
    applyMatrix3(m: Matrix3): this;
    applyMatrix4(m: Matrix4): this;
    applyNormalMatrix(m: Matrix3): this;
    transformDirection(m: Matrix4): this;
    set(value: ArrayLike<number>, offset?: number): this;
    getX(index: number): number;
    setX(index: number, x: number): this;
    getY(index: number): number;
    setY(index: number, y: number): this;
    getZ(index: number): number;
    setZ(index: number, z: number): this;
    getW(index: number): number;
    setW(index: number, w: number): this;
    setXY(index: number, x: number, y: number): this;
    setXYZ(index: number, x: number, y: number, z: number): this;
    setXYZW(index: number, x: number, y: number, z: number, w: number): this;
    onUpload(callback: () => void): this;
    clone(): BufferAttribute;
    toJSON(): unknown;
  }

  export class BufferGeometry {
    constructor();
    id: number;
    uuid: string;
    name: string;
    type: string;
    index: BufferAttribute | null;
    attributes: Record<string, BufferAttribute>;
    morphAttributes: Record<string, BufferAttribute[]>;
    morphTargetsRelative: boolean;
    groups: Array<{ start: number; count: number; materialIndex?: number }>;
    boundingBox: Box3 | null;
    boundingSphere: Sphere | null;
    drawRange: { start: number; count: number };
    userData: Record<string, unknown>;

    getIndex(): BufferAttribute | null;
    setIndex(index: BufferAttribute | number[] | null): this;
    // Legacy API (older Three.js versions)
    fromGeometry(geometry: Geometry): this;
    getAttribute(name: string): BufferAttribute | undefined;
    setAttribute(name: string, attribute: BufferAttribute): this;
    deleteAttribute(name: string): this;
    hasAttribute(name: string): boolean;
    addGroup(start: number, count: number, materialIndex?: number): void;
    clearGroups(): void;
    setDrawRange(start: number, count: number): void;
    applyMatrix(matrix: Matrix4): this;
    applyMatrix4(matrix: Matrix4): this;
    applyQuaternion(q: Quaternion): this;
    rotateX(angle: number): this;
    rotateY(angle: number): this;
    rotateZ(angle: number): this;
    translate(x: number, y: number, z: number): this;
    scale(x: number, y: number, z: number): this;
    lookAt(vector: Vector3): this;
    center(): this;
    setFromPoints(points: Vector3[] | Vector2[]): this;
    computeBoundingBox(): void;
    computeBoundingSphere(): void;
    computeVertexNormals(): void;
    merge(geometry: BufferGeometry, offset?: number): this;
    normalizeNormals(): void;
    toNonIndexed(): BufferGeometry;
    toJSON(): unknown;
    clone(): BufferGeometry;
    copy(source: BufferGeometry): this;
    dispose(): void;
  }

  // Materials
  export interface MaterialParameters {
    alphaTest?: number;
    blending?: number;
    clipIntersection?: boolean;
    clippingPlanes?: Plane[];
    clipShadows?: boolean;
    colorWrite?: boolean;
    depthFunc?: number;
    depthTest?: boolean;
    depthWrite?: boolean;
    fog?: boolean;
    name?: string;
    opacity?: number;
    polygonOffset?: boolean;
    polygonOffsetFactor?: number;
    polygonOffsetUnits?: number;
    precision?: 'highp' | 'mediump' | 'lowp' | null;
    premultipliedAlpha?: boolean;
    dithering?: boolean;
    side?: number;
    shadowSide?: number;
    toneMapped?: boolean;
    transparent?: boolean;
    vertexColors?: boolean;
    visible?: boolean;
    stencilWrite?: boolean;
    stencilFunc?: number;
    stencilRef?: number;
    stencilWriteMask?: number;
    stencilFuncMask?: number;
    stencilFail?: number;
    stencilZFail?: number;
    stencilZPass?: number;
  }

  export class Material {
    constructor();
    id: number;
    uuid: string;
    name: string;
    type: string;
    fog: boolean;
    blending: number;
    side: number;
    vertexColors: boolean;
    opacity: number;
    transparent: boolean;
    blendSrc: number;
    blendDst: number;
    blendEquation: number;
    blendSrcAlpha: number | null;
    blendDstAlpha: number | null;
    blendEquationAlpha: number | null;
    depthFunc: number;
    depthTest: boolean;
    depthWrite: boolean;
    stencilWriteMask: number;
    stencilFunc: number;
    stencilRef: number;
    stencilFuncMask: number;
    stencilFail: number;
    stencilZFail: number;
    stencilZPass: number;
    stencilWrite: boolean;
    clippingPlanes: Plane[] | null;
    clipIntersection: boolean;
    clipShadows: boolean;
    shadowSide: number | null;
    colorWrite: boolean;
    precision: 'highp' | 'mediump' | 'lowp' | null;
    polygonOffset: boolean;
    polygonOffsetFactor: number;
    polygonOffsetUnits: number;
    dithering: boolean;
    alphaTest: number;
    premultipliedAlpha: boolean;
    visible: boolean;
    toneMapped: boolean;
    userData: Record<string, unknown>;
    version: number;
    needsUpdate: boolean;

    onBeforeCompile(shader: unknown, renderer: WebGLRenderer): void;
    customProgramCacheKey(): string;
    setValues(values: MaterialParameters): void;
    toJSON(meta?: unknown): unknown;
    clone(): this;
    copy(source: Material): this;
    dispose(): void;
  }

  export interface MeshBasicMaterialParameters extends MaterialParameters {
    color?: number | string | Color;
    map?: Texture | null;
    lightMap?: Texture | null;
    lightMapIntensity?: number;
    aoMap?: Texture | null;
    aoMapIntensity?: number;
    specularMap?: Texture | null;
    alphaMap?: Texture | null;
    envMap?: Texture | null;
    combine?: number;
    reflectivity?: number;
    refractionRatio?: number;
    wireframe?: boolean;
    wireframeLinewidth?: number;
    wireframeLinecap?: string;
    wireframeLinejoin?: string;
    skinning?: boolean;
    morphTargets?: boolean;
  }

  export class MeshBasicMaterial extends Material {
    constructor(parameters?: MeshBasicMaterialParameters);
    type: 'MeshBasicMaterial';
    color: Color;
    map: Texture | null;
    lightMap: Texture | null;
    lightMapIntensity: number;
    aoMap: Texture | null;
    aoMapIntensity: number;
    specularMap: Texture | null;
    alphaMap: Texture | null;
    envMap: Texture | null;
    combine: number;
    reflectivity: number;
    refractionRatio: number;
    wireframe: boolean;
    wireframeLinewidth: number;
    wireframeLinecap: string;
    wireframeLinejoin: string;
    skinning: boolean;
    morphTargets: boolean;
  }

  export interface MeshLambertMaterialParameters extends MaterialParameters {
    color?: number | string | Color;
    emissive?: number | string | Color;
    emissiveIntensity?: number;
    emissiveMap?: Texture | null;
    map?: Texture | null;
    lightMap?: Texture | null;
    lightMapIntensity?: number;
    aoMap?: Texture | null;
    aoMapIntensity?: number;
    specularMap?: Texture | null;
    alphaMap?: Texture | null;
    envMap?: Texture | null;
    combine?: number;
    reflectivity?: number;
    refractionRatio?: number;
    wireframe?: boolean;
    wireframeLinewidth?: number;
    wireframeLinecap?: string;
    wireframeLinejoin?: string;
    skinning?: boolean;
    morphTargets?: boolean;
    morphNormals?: boolean;
  }

  export class MeshLambertMaterial extends Material {
    constructor(parameters?: MeshLambertMaterialParameters);
    type: 'MeshLambertMaterial';
    color: Color;
    emissive: Color;
    emissiveIntensity: number;
    emissiveMap: Texture | null;
    map: Texture | null;
    lightMap: Texture | null;
    lightMapIntensity: number;
    aoMap: Texture | null;
    aoMapIntensity: number;
    specularMap: Texture | null;
    alphaMap: Texture | null;
    envMap: Texture | null;
    combine: number;
    reflectivity: number;
    refractionRatio: number;
    wireframe: boolean;
    wireframeLinewidth: number;
    wireframeLinecap: string;
    wireframeLinejoin: string;
    skinning: boolean;
    morphTargets: boolean;
    morphNormals: boolean;
  }

  export interface MeshPhongMaterialParameters extends MaterialParameters {
    color?: number | string | Color;
    specular?: number | string | Color;
    shininess?: number;
    emissive?: number | string | Color;
    emissiveIntensity?: number;
    emissiveMap?: Texture | null;
    map?: Texture | null;
    lightMap?: Texture | null;
    lightMapIntensity?: number;
    aoMap?: Texture | null;
    aoMapIntensity?: number;
    bumpMap?: Texture | null;
    bumpScale?: number;
    normalMap?: Texture | null;
    normalMapType?: number;
    normalScale?: Vector2;
    displacementMap?: Texture | null;
    displacementScale?: number;
    displacementBias?: number;
    specularMap?: Texture | null;
    alphaMap?: Texture | null;
    envMap?: Texture | null;
    combine?: number;
    reflectivity?: number;
    refractionRatio?: number;
    wireframe?: boolean;
    wireframeLinewidth?: number;
    wireframeLinecap?: string;
    wireframeLinejoin?: string;
    skinning?: boolean;
    morphTargets?: boolean;
    morphNormals?: boolean;
  }

  export class MeshPhongMaterial extends Material {
    constructor(parameters?: MeshPhongMaterialParameters);
    type: 'MeshPhongMaterial';
    color: Color;
    specular: Color;
    shininess: number;
    emissive: Color;
    emissiveIntensity: number;
    emissiveMap: Texture | null;
    map: Texture | null;
    lightMap: Texture | null;
    lightMapIntensity: number;
    aoMap: Texture | null;
    aoMapIntensity: number;
    bumpMap: Texture | null;
    bumpScale: number;
    normalMap: Texture | null;
    normalMapType: number;
    normalScale: Vector2;
    displacementMap: Texture | null;
    displacementScale: number;
    displacementBias: number;
    specularMap: Texture | null;
    alphaMap: Texture | null;
    envMap: Texture | null;
    combine: number;
    reflectivity: number;
    refractionRatio: number;
    wireframe: boolean;
    wireframeLinewidth: number;
    wireframeLinecap: string;
    wireframeLinejoin: string;
    skinning: boolean;
    morphTargets: boolean;
    morphNormals: boolean;
  }

  export interface ShaderMaterialParameters extends MaterialParameters {
    uniforms?: Record<string, { value: unknown; type?: string }>;
    vertexShader?: string;
    fragmentShader?: string;
    linewidth?: number;
    wireframe?: boolean;
    wireframeLinewidth?: number;
    lights?: boolean;
    clipping?: boolean;
    skinning?: boolean;
    morphTargets?: boolean;
    morphNormals?: boolean;
    extensions?: {
      derivatives?: boolean;
      fragDepth?: boolean;
      drawBuffers?: boolean;
      shaderTextureLOD?: boolean;
    };
  }

  export class ShaderMaterial extends Material {
    constructor(parameters?: ShaderMaterialParameters);
    type: 'ShaderMaterial';
    defines: Record<string, unknown>;
    uniforms: Record<string, { value: unknown; type?: string }>;
    vertexShader: string;
    fragmentShader: string;
    linewidth: number;
    wireframe: boolean;
    wireframeLinewidth: number;
    lights: boolean;
    clipping: boolean;
    skinning: boolean;
    morphTargets: boolean;
    morphNormals: boolean;
    extensions: {
      derivatives: boolean;
      fragDepth: boolean;
      drawBuffers: boolean;
      shaderTextureLOD: boolean;
    };
    defaultAttributeValues: Record<string, unknown>;
    index0AttributeName: string | undefined;
    uniformsNeedUpdate: boolean;
  }

  export interface LineBasicMaterialParameters extends MaterialParameters {
    color?: number | string | Color;
    linewidth?: number;
    linecap?: string;
    linejoin?: string;
  }

  export class LineBasicMaterial extends Material {
    constructor(parameters?: LineBasicMaterialParameters);
    type: 'LineBasicMaterial';
    color: Color;
    linewidth: number;
    linecap: string;
    linejoin: string;
  }

  export interface LineDashedMaterialParameters extends LineBasicMaterialParameters {
    scale?: number;
    dashSize?: number;
    gapSize?: number;
  }

  export class LineDashedMaterial extends LineBasicMaterial {
    constructor(parameters?: LineDashedMaterialParameters);
    type: 'LineDashedMaterial';
    scale: number;
    dashSize: number;
    gapSize: number;
  }

  // Meshes and Lines
  export class Mesh extends Object3D {
    constructor(geometry?: Geometry | BufferGeometry, material?: Material | Material[]);
    type: 'Mesh';
    geometry: Geometry | BufferGeometry;
    material: Material | Material[];
    morphTargetInfluences?: number[];
    morphTargetDictionary?: Record<string, number>;
    updateMorphTargets(): void;
    raycast(raycaster: Raycaster, intersects: Intersection[]): void;
  }

  export class Line extends Object3D {
    constructor(geometry?: Geometry | BufferGeometry, material?: Material);
    type: 'Line';
    geometry: Geometry | BufferGeometry;
    material: Material;
    computeLineDistances(): this;
    raycast(raycaster: Raycaster, intersects: Intersection[]): void;
  }

  export class LineSegments extends Line {
    constructor(geometry?: Geometry | BufferGeometry, material?: Material);
    type: 'LineSegments';
  }

  export class LineLoop extends Line {
    constructor(geometry?: Geometry | BufferGeometry, material?: Material);
    type: 'LineLoop';
  }

  export class Points extends Object3D {
    constructor(geometry?: Geometry | BufferGeometry, material?: Material);
    type: 'Points';
    geometry: Geometry | BufferGeometry;
    material: Material;
    raycast(raycaster: Raycaster, intersects: Intersection[]): void;
  }

  // Lights
  export class Light extends Object3D {
    constructor(color?: number | string, intensity?: number);
    type: 'Light';
    color: Color;
    intensity: number;
    isLight: true;
  }

  export class AmbientLight extends Light {
    constructor(color?: number | string, intensity?: number);
    type: 'AmbientLight';
    isAmbientLight: true;
  }

  export class DirectionalLight extends Light {
    constructor(color?: number | string, intensity?: number);
    type: 'DirectionalLight';
    target: Object3D;
    shadow: unknown;
    isDirectionalLight: true;
  }

  export class PointLight extends Light {
    constructor(color?: number | string, intensity?: number, distance?: number, decay?: number);
    type: 'PointLight';
    distance: number;
    decay: number;
    shadow: unknown;
    power: number;
    isPointLight: true;
  }

  export class SpotLight extends Light {
    constructor(
      color?: number | string,
      intensity?: number,
      distance?: number,
      angle?: number,
      penumbra?: number,
      decay?: number
    );
    type: 'SpotLight';
    target: Object3D;
    distance: number;
    angle: number;
    penumbra: number;
    decay: number;
    shadow: unknown;
    power: number;
    isSpotLight: true;
  }

  export class HemisphereLight extends Light {
    constructor(skyColor?: number | string, groundColor?: number | string, intensity?: number);
    type: 'HemisphereLight';
    groundColor: Color;
    isHemisphereLight: true;
  }

  // Textures
  export class Texture {
    constructor(
      image?: HTMLImageElement | HTMLCanvasElement | HTMLVideoElement,
      mapping?: number,
      wrapS?: number,
      wrapT?: number,
      magFilter?: number,
      minFilter?: number,
      format?: number,
      type?: number,
      anisotropy?: number,
      encoding?: number
    );
    id: number;
    uuid: string;
    name: string;
    image: HTMLImageElement | HTMLCanvasElement | HTMLVideoElement | unknown;
    mipmaps: unknown[];
    mapping: number;
    wrapS: number;
    wrapT: number;
    magFilter: number;
    minFilter: number;
    anisotropy: number;
    format: number;
    internalFormat: string | null;
    type: number;
    offset: Vector2;
    repeat: Vector2;
    center: Vector2;
    rotation: number;
    generateMipmaps: boolean;
    premultiplyAlpha: boolean;
    flipY: boolean;
    unpackAlignment: number;
    encoding: number;
    version: number;
    needsUpdate: boolean;
    onUpdate: (() => void) | null;

    clone(): Texture;
    copy(source: Texture): this;
    toJSON(meta?: unknown): unknown;
    dispose(): void;
    transformUv(uv: Vector2): Vector2;
  }

  export class DataTexture extends Texture {
    constructor(
      data?: ArrayBufferView,
      width?: number,
      height?: number,
      format?: number,
      type?: number,
      mapping?: number,
      wrapS?: number,
      wrapT?: number,
      magFilter?: number,
      minFilter?: number,
      anisotropy?: number,
      encoding?: number
    );
    image: { data: ArrayBufferView; width: number; height: number };
    isDataTexture: true;
  }

  // Render Targets
  export interface WebGLRenderTargetOptions {
    wrapS?: number;
    wrapT?: number;
    magFilter?: number;
    minFilter?: number;
    format?: number;
    type?: number;
    anisotropy?: number;
    depthBuffer?: boolean;
    stencilBuffer?: boolean;
    generateMipmaps?: boolean;
    depthTexture?: DepthTexture;
    encoding?: number;
  }

  export class WebGLRenderTarget {
    constructor(width: number, height: number, options?: WebGLRenderTargetOptions);
    uuid: string;
    width: number;
    height: number;
    scissor: Vector4;
    scissorTest: boolean;
    viewport: Vector4;
    texture: Texture;
    depthBuffer: boolean;
    stencilBuffer: boolean;
    depthTexture: DepthTexture | null;
    format: number;

    setSize(width: number, height: number): void;
    clone(): WebGLRenderTarget;
    copy(source: WebGLRenderTarget): this;
    dispose(): void;
  }

  export class DepthTexture extends Texture {
    constructor(
      width: number,
      height: number,
      type?: number,
      mapping?: number,
      wrapS?: number,
      wrapT?: number,
      magFilter?: number,
      minFilter?: number,
      anisotropy?: number,
      format?: number
    );
    isDepthTexture: true;
  }

  // Renderer
  export interface WebGLRendererParameters {
    canvas?: HTMLCanvasElement;
    context?: WebGLRenderingContext;
    precision?: string;
    alpha?: boolean;
    premultipliedAlpha?: boolean;
    antialias?: boolean;
    stencil?: boolean;
    preserveDrawingBuffer?: boolean;
    powerPreference?: string;
    depth?: boolean;
    logarithmicDepthBuffer?: boolean;
    failIfMajorPerformanceCaveat?: boolean;
  }

  export interface WebGLInfo {
    memory: {
      geometries: number;
      textures: number;
    };
    render: {
      calls: number;
      triangles: number;
      points: number;
      lines: number;
      frame: number;
    };
    programs: unknown[] | null;
    autoReset: boolean;
    reset(): void;
  }

  export interface WebGLCapabilities {
    isWebGL2: boolean;
    precision: string;
    logarithmicDepthBuffer: boolean;
    maxTextures: number;
    maxVertexTextures: number;
    maxTextureSize: number;
    maxCubemapSize: number;
    maxAttributes: number;
    maxVertexUniforms: number;
    maxVaryings: number;
    maxFragmentUniforms: number;
    vertexTextures: boolean;
    floatFragmentTextures: boolean;
    floatVertexTextures: boolean;
  }

  export interface WebGLExtensions {
    has(name: string): boolean;
    get(name: string): unknown;
  }

  export class WebGLRenderer {
    constructor(parameters?: WebGLRendererParameters);

    domElement: HTMLCanvasElement;
    context: WebGLRenderingContext;
    autoClear: boolean;
    autoClearColor: boolean;
    autoClearDepth: boolean;
    autoClearStencil: boolean;
    debug: { checkShaderErrors: boolean };
    sortObjects: boolean;
    clippingPlanes: Plane[];
    localClippingEnabled: boolean;
    extensions: WebGLExtensions;
    outputEncoding: number;
    physicallyCorrectLights: boolean;
    toneMapping: number;
    toneMappingExposure: number;
    maxMorphTargets: number;
    maxMorphNormals: number;
    info: WebGLInfo;
    shadowMap: unknown;
    pixelRatio: number;
    capabilities: WebGLCapabilities;

    // Custom brickify property
    hasStencilBuffer: boolean;

    getContext(): WebGLRenderingContext;
    getContextAttributes(): WebGLContextAttributes;
    forceContextLoss(): void;
    forceContextRestore(): void;
    getMaxAnisotropy(): number;
    getPrecision(): string;
    getPixelRatio(): number;
    setPixelRatio(value: number): void;
    getSize(target: Vector2): Vector2;
    setSize(width: number, height: number, updateStyle?: boolean): void;
    getDrawingBufferSize(target: Vector2): Vector2;
    setDrawingBufferSize(width: number, height: number, pixelRatio: number): void;
    getCurrentViewport(target: Vector4): Vector4;
    getViewport(target: Vector4): Vector4;
    setViewport(x: number | Vector4, y?: number, width?: number, height?: number): void;
    getScissor(target: Vector4): Vector4;
    setScissor(x: number | Vector4, y?: number, width?: number, height?: number): void;
    getScissorTest(): boolean;
    setScissorTest(boolean: boolean): void;
    setOpaqueSort(method: ((a: unknown, b: unknown) => number) | null): void;
    setTransparentSort(method: ((a: unknown, b: unknown) => number) | null): void;
    getClearColor(target?: Color): Color;
    setClearColor(color: number | string | Color, alpha?: number): void;
    getClearAlpha(): number;
    setClearAlpha(alpha: number): void;
    clear(color?: boolean, depth?: boolean, stencil?: boolean): void;
    clearColor(): void;
    clearDepth(): void;
    clearStencil(): void;
    dispose(): void;
    renderBufferImmediate(object: Object3D, program: unknown): void;
    renderBufferDirect(
      camera: Camera,
      scene: Scene,
      geometry: BufferGeometry,
      material: Material,
      object: Object3D,
      group: unknown
    ): void;
    compile(scene: Scene, camera: Camera): void;
    render(scene: Scene, camera: Camera, renderTarget?: WebGLRenderTarget | null, forceClear?: boolean): void;
    setRenderTarget(renderTarget: WebGLRenderTarget | null, activeCubeFace?: number, activeMipMapLevel?: number): void;
    getRenderTarget(): WebGLRenderTarget | null;
    readRenderTargetPixels(
      renderTarget: WebGLRenderTarget,
      x: number,
      y: number,
      width: number,
      height: number,
      buffer: ArrayBufferView,
      activeCubeFaceIndex?: number
    ): void;
    copyFramebufferToTexture(position: Vector2, texture: Texture, level?: number): void;
    copyTextureToTexture(position: Vector2, srcTexture: Texture, dstTexture: Texture, level?: number): void;
    initTexture(texture: Texture): void;
    setAnimationLoop(callback: ((time: number) => void) | null): void;
  }

  // Raycaster
  export interface Intersection {
    distance: number;
    distanceToRay?: number;
    point: Vector3;
    index?: number;
    face?: Face3 | null;
    faceIndex?: number;
    object: Object3D;
    uv?: Vector2;
    uv2?: Vector2;
    instanceId?: number;
  }

  export interface RaycasterParameters {
    Mesh?: Record<string, unknown>;
    Line?: { threshold: number };
    LOD?: Record<string, unknown>;
    Points?: { threshold: number };
    Sprite?: Record<string, unknown>;
  }

  export class Raycaster {
    constructor(origin?: Vector3, direction?: Vector3, near?: number, far?: number);
    ray: Ray;
    near: number;
    far: number;
    camera: Camera | null;
    layers: Layers;
    params: RaycasterParameters;

    set(origin: Vector3, direction: Vector3): void;
    setFromCamera(coords: Vector2, camera: Camera): void;
    intersectObject(object: Object3D, recursive?: boolean, optionalTarget?: Intersection[]): Intersection[];
    intersectObjects(objects: Object3D[], recursive?: boolean, optionalTarget?: Intersection[]): Intersection[];
  }

  export class Layers {
    mask: number;
    set(channel: number): void;
    enable(channel: number): void;
    enableAll(): void;
    toggle(channel: number): void;
    disable(channel: number): void;
    disableAll(): void;
    test(layers: Layers): boolean;
  }

  // Helpers and Utilities
  export namespace ImageUtils {
    function loadTexture(
      url: string,
      mapping?: number,
      onLoad?: (texture: Texture) => void,
      onError?: (error: Error) => void
    ): Texture;
    function loadTextureCube(
      array: string[],
      mapping?: number,
      onLoad?: (texture: Texture) => void,
      onError?: (error: Error) => void
    ): Texture;
  }

  export class TextureLoader {
    constructor(manager?: LoadingManager);
    crossOrigin: string;
    path: string;
    load(
      url: string,
      onLoad?: (texture: Texture) => void,
      onProgress?: (event: ProgressEvent) => void,
      onError?: (error: Error) => void
    ): Texture;
    loadAsync(url: string, onProgress?: (event: ProgressEvent) => void): Promise<Texture>;
    setCrossOrigin(crossOrigin: string): this;
    setPath(path: string): this;
  }

  export class LoadingManager {
    constructor(
      onLoad?: () => void,
      onProgress?: (url: string, itemsLoaded: number, itemsTotal: number) => void,
      onError?: (url: string) => void
    );
    onStart: ((url: string, itemsLoaded: number, itemsTotal: number) => void) | undefined;
    onLoad: (() => void) | undefined;
    onProgress: ((url: string, itemsLoaded: number, itemsTotal: number) => void) | undefined;
    onError: ((url: string) => void) | undefined;
    setURLModifier(callback?: (url: string) => string): this;
    resolveURL(url: string): string;
    itemStart(url: string): void;
    itemEnd(url: string): void;
    itemError(url: string): void;
    addHandler(regex: RegExp, loader: unknown): this;
    removeHandler(regex: RegExp): this;
    getHandler(file: string): unknown | null;
  }

  // Standard Geometries
  export class PlaneGeometry extends BufferGeometry {
    constructor(width?: number, height?: number, widthSegments?: number, heightSegments?: number);
    type: 'PlaneGeometry';
    parameters: {
      width: number;
      height: number;
      widthSegments: number;
      heightSegments: number;
    };
  }

  export class BoxGeometry extends BufferGeometry {
    constructor(
      width?: number, height?: number, depth?: number,
      widthSegments?: number, heightSegments?: number, depthSegments?: number
    );
    type: 'BoxGeometry';
    parameters: {
      width: number;
      height: number;
      depth: number;
      widthSegments: number;
      heightSegments: number;
      depthSegments: number;
    };
  }

  export class SphereGeometry extends BufferGeometry {
    constructor(
      radius?: number,
      widthSegments?: number,
      heightSegments?: number,
      phiStart?: number,
      phiLength?: number,
      thetaStart?: number,
      thetaLength?: number
    );
    type: 'SphereGeometry';
    parameters: {
      radius: number;
      widthSegments: number;
      heightSegments: number;
      phiStart: number;
      phiLength: number;
      thetaStart: number;
      thetaLength: number;
    };
  }

  export class CylinderGeometry extends BufferGeometry {
    constructor(
      radiusTop?: number,
      radiusBottom?: number,
      height?: number,
      radialSegments?: number,
      heightSegments?: number,
      openEnded?: boolean,
      thetaStart?: number,
      thetaLength?: number
    );
    type: 'CylinderGeometry';
    parameters: {
      radiusTop: number;
      radiusBottom: number;
      height: number;
      radialSegments: number;
      heightSegments: number;
      openEnded: boolean;
      thetaStart: number;
      thetaLength: number;
    };
  }

  // Constants
  export const REVISION: string;

  // Blend modes
  export const NoBlending: number;
  export const NormalBlending: number;
  export const AdditiveBlending: number;
  export const SubtractiveBlending: number;
  export const MultiplyBlending: number;
  export const CustomBlending: number;

  // Side
  export const FrontSide: number;
  export const BackSide: number;
  export const DoubleSide: number;

  // Shading
  export const FlatShading: number;
  export const SmoothShading: number;

  // Colors
  export const NoColors: number;
  export const FaceColors: number;
  export const VertexColors: number;

  // Texture Wrapping
  export const RepeatWrapping: number;
  export const ClampToEdgeWrapping: number;
  export const MirroredRepeatWrapping: number;

  // Texture Filters
  export const NearestFilter: number;
  export const NearestMipmapNearestFilter: number;
  export const NearestMipmapLinearFilter: number;
  export const LinearFilter: number;
  export const LinearMipmapNearestFilter: number;
  export const LinearMipmapLinearFilter: number;

  // Texture Formats
  export const AlphaFormat: number;
  export const RGBFormat: number;
  export const RGBAFormat: number;
  export const LuminanceFormat: number;
  export const LuminanceAlphaFormat: number;
  export const DepthFormat: number;
  export const DepthStencilFormat: number;
  export const RedFormat: number;
  export const RedIntegerFormat: number;
  export const RGFormat: number;
  export const RGIntegerFormat: number;
  export const RGBIntegerFormat: number;
  export const RGBAIntegerFormat: number;

  // Texture Types
  export const UnsignedByteType: number;
  export const ByteType: number;
  export const ShortType: number;
  export const UnsignedShortType: number;
  export const IntType: number;
  export const UnsignedIntType: number;
  export const FloatType: number;
  export const HalfFloatType: number;
  export const UnsignedShort4444Type: number;
  export const UnsignedShort5551Type: number;
  export const UnsignedShort565Type: number;
  export const UnsignedInt248Type: number;

  // Depth Modes
  export const NeverDepth: number;
  export const AlwaysDepth: number;
  export const LessDepth: number;
  export const LessEqualDepth: number;
  export const EqualDepth: number;
  export const GreaterEqualDepth: number;
  export const GreaterDepth: number;
  export const NotEqualDepth: number;

  // Stencil Operations
  export const ZeroStencilOp: number;
  export const KeepStencilOp: number;
  export const ReplaceStencilOp: number;
  export const IncrementStencilOp: number;
  export const DecrementStencilOp: number;
  export const IncrementWrapStencilOp: number;
  export const DecrementWrapStencilOp: number;
  export const InvertStencilOp: number;

  // Stencil Functions
  export const NeverStencilFunc: number;
  export const LessStencilFunc: number;
  export const EqualStencilFunc: number;
  export const LessEqualStencilFunc: number;
  export const GreaterStencilFunc: number;
  export const NotEqualStencilFunc: number;
  export const GreaterEqualStencilFunc: number;
  export const AlwaysStencilFunc: number;

  // Default export for "import THREE from 'three'" pattern
  const THREE: {
    Vector2: typeof Vector2;
    Vector3: typeof Vector3;
    Vector4: typeof Vector4;
    Matrix3: typeof Matrix3;
    Matrix4: typeof Matrix4;
    Quaternion: typeof Quaternion;
    Euler: typeof Euler;
    Box2: typeof Box2;
    Box3: typeof Box3;
    Sphere: typeof Sphere;
    Plane: typeof Plane;
    Ray: typeof Ray;
    Line3: typeof Line3;
    Triangle: typeof Triangle;
    Color: typeof Color;
    Object3D: typeof Object3D;
    Scene: typeof Scene;
    Fog: typeof Fog;
    FogExp2: typeof FogExp2;
    Camera: typeof Camera;
    PerspectiveCamera: typeof PerspectiveCamera;
    OrthographicCamera: typeof OrthographicCamera;
    Face3: typeof Face3;
    Geometry: typeof Geometry;
    BufferAttribute: typeof BufferAttribute;
    BufferGeometry: typeof BufferGeometry;
    Material: typeof Material;
    MeshBasicMaterial: typeof MeshBasicMaterial;
    MeshLambertMaterial: typeof MeshLambertMaterial;
    MeshPhongMaterial: typeof MeshPhongMaterial;
    ShaderMaterial: typeof ShaderMaterial;
    LineBasicMaterial: typeof LineBasicMaterial;
    LineDashedMaterial: typeof LineDashedMaterial;
    Mesh: typeof Mesh;
    Line: typeof Line;
    LineSegments: typeof LineSegments;
    LineLoop: typeof LineLoop;
    Points: typeof Points;
    Light: typeof Light;
    AmbientLight: typeof AmbientLight;
    DirectionalLight: typeof DirectionalLight;
    PointLight: typeof PointLight;
    SpotLight: typeof SpotLight;
    HemisphereLight: typeof HemisphereLight;
    Texture: typeof Texture;
    DataTexture: typeof DataTexture;
    DepthTexture: typeof DepthTexture;
    WebGLRenderTarget: typeof WebGLRenderTarget;
    WebGLRenderer: typeof WebGLRenderer;
    Raycaster: typeof Raycaster;
    Layers: typeof Layers;
    TextureLoader: typeof TextureLoader;
    LoadingManager: typeof LoadingManager;
    PlaneGeometry: typeof PlaneGeometry;
    BoxGeometry: typeof BoxGeometry;
    SphereGeometry: typeof SphereGeometry;
    CylinderGeometry: typeof CylinderGeometry;
    ImageUtils: typeof ImageUtils;
    REVISION: string;
    NoBlending: number;
    NormalBlending: number;
    AdditiveBlending: number;
    SubtractiveBlending: number;
    MultiplyBlending: number;
    CustomBlending: number;
    FrontSide: number;
    BackSide: number;
    DoubleSide: number;
    FlatShading: number;
    SmoothShading: number;
    NoColors: number;
    FaceColors: number;
    VertexColors: number;
    RepeatWrapping: number;
    ClampToEdgeWrapping: number;
    MirroredRepeatWrapping: number;
    NearestFilter: number;
    NearestMipmapNearestFilter: number;
    NearestMipmapLinearFilter: number;
    LinearFilter: number;
    LinearMipmapNearestFilter: number;
    LinearMipmapLinearFilter: number;
    AlphaFormat: number;
    RGBFormat: number;
    RGBAFormat: number;
    LuminanceFormat: number;
    LuminanceAlphaFormat: number;
    DepthFormat: number;
    DepthStencilFormat: number;
    RedFormat: number;
    UnsignedByteType: number;
    ByteType: number;
    ShortType: number;
    UnsignedShortType: number;
    IntType: number;
    UnsignedIntType: number;
    FloatType: number;
    HalfFloatType: number;
  };

  export default THREE;
}

// Add namespace exports for type usage like THREE.Vector3
declare namespace THREE {
  export { Vector2, Vector3, Vector4, Matrix3, Matrix4, Quaternion, Euler } from 'three';
  export { Box2, Box3, Sphere, Plane, Ray, Line3, Triangle } from 'three';
  export { Color, Object3D, Scene, Fog, FogExp2 } from 'three';
  export { Camera, PerspectiveCamera, OrthographicCamera } from 'three';
  export { Face3, Geometry, BufferAttribute, BufferGeometry } from 'three';
  export { Material, MeshBasicMaterial, MeshLambertMaterial, MeshPhongMaterial, ShaderMaterial, LineBasicMaterial, LineDashedMaterial } from 'three';
  export { Mesh, Line, LineSegments, LineLoop, Points } from 'three';
  export { Light, AmbientLight, DirectionalLight, PointLight, SpotLight, HemisphereLight } from 'three';
  export { Texture, DataTexture, DepthTexture, WebGLRenderTarget, WebGLRenderer } from 'three';
  export { Raycaster, Layers, TextureLoader, LoadingManager } from 'three';
  export { PlaneGeometry, BoxGeometry, SphereGeometry, CylinderGeometry } from 'three';
}

declare module 'three-pointer-controls' {
  import type { PerspectiveCamera, Vector3 } from 'three';

  interface PointerControlsConfig {
    enabled: boolean;
    dolly?: {
      minDistance?: number;
      maxDistance?: number;
    };
    animation?: {
      afterInteraction?: number;
    };
  }

  interface PointerControls {
    config: PointerControlsConfig;
    target: Vector3;
    control(camera: PerspectiveCamera): { with(element: HTMLElement): void };
    set(options: { target?: Vector3; position?: Vector3 }): void;
  }

  interface PointerControlsConstructor {
    new (): PointerControls;
  }

  export default function threePointerControls(THREE: unknown): PointerControlsConstructor;
}

part of '../raylib_dartified_unhinged.dart';

/// Tracks frame timing for an [App] instance: elapsed time, frame count,
/// time scaling, and target FPS.
///
/// Time values are updated once per frame via [_update], which is expected
/// to be driven by the app's main loop.
class AppTime<T extends App<T>> {
  final T app;

  AppTime(this.app);

  /// See [time].
  double _time = 0.0;

  /// Total elapsed time in seconds since the app started.
  ///
  /// Accumulated from raw, unscaled per-frame deltas, unlike [dt], this
  /// is unaffected by [timeScale].
  double get time => _time;

  /// See [timeScaled].
  double _timeScaled = 0.0;

  /// Total elapsed time in seconds since the app started, scaled by
  /// [timeScale].
  ///
  /// Unlike [time], this respects pausing and slow-motion/fast-forward.
  /// It accumulates [dt] rather than the raw frame delta, so it stalls
  /// while [timeScale] is `0` and advances faster/slower otherwise. Use
  /// this for anything that should track elapsed time from the game
  /// world's perspective (cooldowns, animations, particle lifetimes),
  /// as opposed to [time], which always ticks at real speed.
  double get timeScaled => _timeScaled;

  /// See [timeScale].
  double _timeScale = 1.0;

  /// Multiplier applied to the per-frame delta time ([dt]).
  ///
  /// `1.0` is normal speed, `0.0` pauses time progression, and values
  /// above `1.0` fast-forward.
  double get timeScale => _timeScale;

  /// See [frameCount].
  int _frameCount = 0;

  /// Number of frames rendered since the app started.
  int get frameCount => _frameCount;

  /// See [fps].
  int _fps = 60;

  /// The current target frames-per-second, as last set via [setFPS].
  int get fps => _fps;

  /// See [dt].
  double _dt = 0;

  /// Time elapsed since the previous frame, in seconds, already multiplied
  /// by [timeScale].
  ///
  /// Use this instead of the raw frame time for any per-frame
  /// calculation that should respect pausing/slow-motion/fast-forward.
  double get dt => _dt;

  /// Advances time state for the current frame.
  ///
  /// Pulls the raw frame delta, accumulates it into [time] and
  /// [frameCount] (unscaled), and updates [dt] with the [timeScale]-adjusted
  /// value for this frame. Intended to be called once per frame by the
  /// app's main loop.
   void _update() {
    final dt = app.rl.CoreD.GetFrameTime();
    _time += dt;
    _frameCount++;
    _dt = dt * timeScale;
    _timeScaled += _dt;
  }

  /// Sets the speed at which [dt] progresses relative to real time.
  ///
  /// Negative values are clamped to `0`. Does not affect [time] or
  /// [frameCount], only future values of [dt].
  void setTimeScale(double timeScale) {
    if (timeScale < 0) timeScale = 0;
    _timeScale = timeScale;
  }

  /// Updates [timeScale] by applying [fn] to its current value.
  ///
  /// A convenience wrapper around [setTimeScale] for relative changes,
  /// so you don't need to read [timeScale] yourself first. Goes through
  /// [setTimeScale], so the usual negative-value clamping still applies.
  ///
  /// Example:
  /// ```dart
  /// app.time.updateTimeScale((ts) => ts - 0.1); // slow down by 0.1
  /// ```
  void updateTimeScale(double Function(double timeScale) fn)
    => setTimeScale(fn(_timeScale));

  /// Changes the target FPS backend renders at.
  ///
  /// No-op if [newFPS] equals the current [fps]. Otherwise updates backend's
  /// target FPS, then notifies the app about the FPS change and emits
  /// [EventFPSChanged] with the old and new values.
  void setFPS(int newFPS) {
    if (newFPS == _fps) return;
    app.rl.CoreD.SetTargetFPS(newFPS);
    int oldFPS = _fps;
    _fps = newFPS;
    app._doFPSChange(oldFPS, newFPS);
    app.emit(EventFPSChanged(app, oldFPS, newFPS));
  }
}

class App<T extends App<T>> extends ECSBase<T> with

  // identity
  Self<T>,

  // has
  HasSceneAccess<T>,
  HasVars<T, T>,

  // is
  IsEventEmittable<T, T>, // needs to be before `IsAppSystemManagable`
  IsEventQueueHolder<T, T>,
  IsEventHistoryHolder<T, T>,

  IsAppSystemManagable<T, T>,
  IsBeginEndFrameable<T, T>,
  IsClonable<T, T, AppCloner<T>>,
  IsDisposable<T, T>,
  IsInputHandleable<T>,

  IsSceneTransitionable<T, T>, // needs to be before `IsSceneManagable`
  IsSceneManagable<T, T>,
  IsStateHolder<T, App<T>, AppSnapshot<T>>,
  IsPersistable<T, App<T>, AppSnapshot<T>>
  
{

  @override
  late AssetManager<T> assets = .new(self);
  
  @override
  late Renderer<T> renderer = .new(self);
  
  @override
  late InputSystem<T> input = .new(self);

  @override
  late Drawers<T> draw = .new(self);

  @override
  T get app => self;

  @override
  final Raylib rl;

  @override
  late AppTime<T> time;

  App(this.rl) {
    time = .new(self);
    _assignDummyScene();
  }

  MouseInfo<Vector2D> mouse = .new();

  Vector2D get _screenSize => .vec2(800, 450);
  
  @override
  Vector2D get screenSize => _screenSize;

  bool _initialized = false;
  bool _dependenciesAssigned = false;

  late FontD defaultFont = rl.CoreD.GetFontDefault();

  bool _exitApp = false; // internal
  bool shouldExit() => false;

  @nonVirtual
  bool get shouldAppExit => _exitApp || _doShouldExit();

  // ░███     ░███    ░███    ░██████░███    ░██ 
  // ░████   ░████   ░██░██     ░██  ░████   ░██ 
  // ░██░██ ░██░██  ░██  ░██    ░██  ░██░██  ░██ 
  // ░██ ░████ ░██ ░█████████   ░██  ░██ ░██ ░██ 
  // ░██  ░██  ░██ ░██    ░██   ░██  ░██  ░██░██ 
  // ░██       ░██ ░██    ░██   ░██  ░██   ░████ 
  // ░██       ░██ ░██    ░██ ░██████░██    ░███ 

  void init() {
    _doInit();
    _enterScene(_scenes.first);
  }

  void frame() {
    time._update();
    _doBeginFrame(time.dt);
    _doUpdate(time.dt);
    _doDraw(time.dt);
    _doEndFrame(time.dt);
  }

  void exit() => _doExit();

  // ░██     ░██   ░██████     ░██████   ░██     ░██   ░██████   
  // ░██     ░██  ░██   ░██   ░██   ░██  ░██    ░██   ░██   ░██  
  // ░██     ░██ ░██     ░██ ░██     ░██ ░██   ░██   ░██         
  // ░██████████ ░██     ░██ ░██     ░██ ░███████     ░████████  
  // ░██     ░██ ░██     ░██ ░██     ░██ ░██   ░██           ░██ 
  // ░██     ░██  ░██   ░██   ░██   ░██  ░██    ░██   ░██   ░██  
  // ░██     ░██   ░██████     ░██████   ░██     ░██   ░██████   

  List<bool Function(T self)> _shouldExitFns = [];
  
  List<void Function(T self, double dt, int frame)> _onFrameFns = [];
  
  List<void Function(T self, int oldFps, int newFps)> _onFPSChangeFns = [];
  
  List<void Function(T self)> _onInitFns = [];

  List<void Function(T self)> _onExitFns = [];

  bool _doShouldExit() {
    if (_shouldExitFns.any((f) => f(self))) return true;
    return shouldExit();
  }
  
  @nonVirtual
  T listenShouldExit(bool Function(T self) fn) {
    _shouldExitFns.add(fn);
    return self;
  }

  @nonVirtual
  T listenOnFrame(void Function(T self, double dt, int frame) fn) {
    _onFrameFns.add(fn);
    return self;
  }

  @nonVirtual
  T listenOnFPSChange(void Function(T self, int oldFps, int newFps) fn) {
    _onFPSChangeFns.add(fn);
    return self;
  }  

  @nonVirtual
  T listenOnInit(void Function(T self) fn) {
    _onInitFns.add(fn);
    return self;
  }

  @nonVirtual
  T listenOnExit(void Function(T self) fn) {
    _onExitFns.add(fn);
    return self;
  }

  @nonVirtual
  void _doFrame(double dt, int frame) {
    _onFrameFns.forEach((f) => f(self, dt, time.frameCount));
    onFrame(dt, time.frameCount);
  }

  @nonVirtual
  void _doFPSChange(int oldFPS, int newFPS) {
    _onFPSChangeFns.forEach((f) => f(self, oldFPS, newFPS));
    onFPSChange(oldFPS, newFPS);
  }

  @nonVirtual
  void _doInit() {
    if (_initialized) return;
    _doOnEvent(EventAppInitializing(app));
    _initialized = true;
    _onInitFns.forEach((f) => f(self));
    onInit();
    _doOnEvent(EventAppInitialized(app));
  }

  @nonVirtual
  void _doExit() {
    _doOnEvent(EventAppExiting(app));
    _onExitFns.forEach((f) => f(self));
    onExit();
    _doOnDispose();
    rl.dispose();
    _doOnEvent(EventAppExited(app));
  }

  void onFrame(double dt, int frame) {}

  void onFPSChange(int oldFPS, int newFPS) {}
  
  void onInit() {}

  void onExit() {}

  // ░██████████ ░██    ░██ ░██████████ ░███    ░██ ░██████████  ░██████   
  // ░██         ░██    ░██ ░██         ░████   ░██     ░██     ░██   ░██  
  // ░██         ░██    ░██ ░██         ░██░██  ░██     ░██    ░██         
  // ░█████████  ░██    ░██ ░█████████  ░██ ░██ ░██     ░██     ░████████  
  // ░██          ░██  ░██  ░██         ░██  ░██░██     ░██            ░██ 
  // ░██           ░██░██   ░██         ░██   ░████     ░██     ░██   ░██  
  // ░██████████    ░███    ░██████████ ░██    ░███     ░██      ░██████   

  /// Overridden to break the forwarding loop inherent in the [IsEventEmittable] mixin.
  @override
  void _dispatchEvent(Event<T> event) {
    // The mixin has no concept of being at the root.
    // App must opt out explicitly.
  }

  @override
  bool _doEventLocal(Event<T> event) {
    if (_doEventLocalCheck(event)) return true;

    // `self` check
    if (event.scope == .self) {
      if (event.origin == self) {
        _doOnEvent(event);
      }
      return true; // 'self'
    }

    // `local` check
    if (event.scope == .local) {
      if (event.origin == self) {
        _doOnEvent(event);

        for (final s in getSystems()) {
          if (event.isStopped) return true;
          s._propagate(event);
        }

        return true;
      }

      _doOnEvent(event);
    }

    if (
      event.scope != .local &&
      event.scope != .scene &&
      event.scope != .sceneOnly
    ) {
      if (event.isStopped) return true;
      _doOnEvent(event);

      for (final s in getSystems()) {
        if (event.isStopped) return true;
        s._propagate(event);
      }
    }

    if (event.scope == .local || event.isStopped) return true;

    scene._propagate(event);

    return true; // do not go back to yourself!
  }

  // ░██████░███     ░███ ░█████████  ░██         
  //   ░██  ░████   ░████ ░██     ░██ ░██         
  //   ░██  ░██░██ ░██░██ ░██     ░██ ░██         
  //   ░██  ░██ ░████ ░██ ░█████████  ░██         
  //   ░██  ░██  ░██  ░██ ░██         ░██         
  //   ░██  ░██       ░██ ░██         ░██         
  // ░██████░██       ░██ ░██         ░██████████ 

  void _doUpdate(double dt) {
    _doFrame(dt, time.frameCount);
    getCurrentScene()._doUpdate(dt);
  }

  void _doDraw(double dt) => getCurrentScene()._doDraw(dt);

  @override
  void _doHandleInput() {
    getSystems().forEach((s) => s._doHandleInput());
    getCurrentScene()._doHandleInput();
    super._doHandleInput();
  }

  @override
  void _doBeginFrame(double dt) {
    mouse = rl.CoreD.GetMouseInfo();
    input._doBeginFrame(dt);
    _doHandleInput();
    getSystems().forEach((s) => s._doBeginFrame(dt));
    getCurrentScene()._doBeginFrame(dt);
    super._doBeginFrame(dt); // observe fully-prepared frame
  }

  @override
  void _doEndFrame(double dt) {
    super._doEndFrame(dt); // observe before teardown begins
    getCurrentScene()._doEndFrame(dt);
    getSystems().forEach((s) => s._doEndFrame(dt));
    input._doEndFrame(dt);
  }

  @override
  void _doOnDispose() {
    getScenes().forEach((s) => s._doOnDispose());
    getSystems().forEach((s) => s._doOnDispose());
    assets._doOnDispose();
    renderer._doOnDispose();
    input._doOnDispose();
    super._doOnDispose();
  }

  //   ░██████  ░██           ░██████   ░███    ░██ ░██████████ 
  //  ░██   ░██ ░██          ░██   ░██  ░████   ░██ ░██         
  // ░██        ░██         ░██     ░██ ░██░██  ░██ ░██         
  // ░██        ░██         ░██     ░██ ░██ ░██ ░██ ░█████████  
  // ░██        ░██         ░██     ░██ ░██  ░██░██ ░██         
  //  ░██   ░██ ░██          ░██   ░██  ░██   ░████ ░██         
  //   ░██████  ░██████████   ░██████   ░██    ░███ ░██████████ 

  void _doCloneDependencies(T target) {
    if (target._dependenciesAssigned) return;
    _clones.add(target);
    target._dependenciesAssigned = true;
    target.assets = assets;
    target.renderer = renderer;
    target.input = input.clone();
    target.defaultFont = defaultFont;
  }

  @override
  void _assignClone(T clone) {
    super._assignClone(clone);
    _doCloneDependencies(clone);
  }

  @override
  @nonVirtual
  void _doOnClone(T copy, [AppCloner<T>? cloner]) {
    // NOTE: we can call cloneInto without createInstance()
    _doCloneDependencies(copy);

    _doOnEvent(EventAppCloning(self, self, copy));

    getScenes().forEach((s) {
      if (!(cloner?.allowScene(copy, s) ?? true)) return;
      copy.addScene(s.clone(cloner?.sceneCloner));
    });

    getSystems().forEach((s) {
      if (!(cloner?.allowAppSystem(copy, s) ?? true)) return;
      copy.addSystem(s.clone(cloner?.systemCloner));
    });

    super._doOnClone(copy, cloner);
  }

  @override
  @nonVirtual
  void _doCloneAfter(T target, [AppCloner<T>? cloner]) {
    super._doCloneAfter(target, cloner);
    app._doOnEvent(EventAppCloned(app, self, target));
  }

  @override
  AppSnapshot<T> createSnapshot() => .new(namedId);  

  @override
  @nonVirtual
  AppSnapshot<T> captureSnapshot() {
    final snapshot = createSnapshot();
    snapshot.systemSnapshots = _systems
      .map((c) => c.captureSnapshot())
      .toList();
    snapshot.sceneSnapshots = _scenes
      .map((c) => c.captureSnapshot())
      .toList();
    return snapshot;
  }

  @override
  @mustCallSuper
  void restoreSnapshot(covariant AppSnapshot<T> snapshot) {
    _restoreSnapshotList(
      originSnapshot: snapshot,
      sourceList: _systems.toList(),
      sourceSnapshots: snapshot.systemSnapshots,
      onRecreate: (x) => addSystem(x),
      onRestore: (x, s) => x.restoreSnapshot(s),
      onRemove: _removeAppSystemInstance,
    );

    _restoreSnapshotList(
      originSnapshot: snapshot,
      sourceList: _scenes.toList(),
      sourceSnapshots: snapshot.sceneSnapshots,
      onRecreate: (x) => addScene(x),
      onRestore: (x, s) => x.restoreSnapshot(s),
      onRemove: removeScene,
    );
  }
}

class AppSnapshot<T extends App<T>> extends StateSnapshot<T, T> {
  late List<AnyAppSystemSnapshot<T>> systemSnapshots;
  late List<AnySceneSnapshot<T>> sceneSnapshots;

  AppSnapshot(super.namedId);

  @override
  T createInstance(T app) => App<T>(app.rl) as T;

  T assignSystems(T app, T destination) {
    for (final snap in systemSnapshots) {
      destination.addSystem(snap.reconstruct(app));
    }
    return destination;
  }

  T assignScenes(T app, T destination) {
    for (final snap in sceneSnapshots) {
      destination.addScene(snap.reconstruct(app));
    }
    return destination;
  }

  @override
  T reconstruct(T app) {
    final s = createInstance(app);
    assignSystems(app, s);
    assignScenes(app, s);
    return s;
  }
}
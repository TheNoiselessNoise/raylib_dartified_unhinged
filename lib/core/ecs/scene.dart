part of '../raylib_dartified_unhinged.dart';

/// A self-contained game scene, the primary organizational unit of the ECS.
///
/// A [Scene] owns a set of [Entity] objects, a collection of [SceneSystem]s,
/// an event queue, and a deferred callback queue. The app lifecycle drives the
/// scene through a fixed sequence each frame:
///
/// ```
/// _doUpdate(dt)
///   ├─ _processEvents()
///   ├─ _updateScene(dt)
///   │    ├─ _doHandleInput()
///   │    ├─ _doPreUpdate(dt)
///   │    ├─ systems (preEntities phase)
///   │    ├─ _updateEntities(dt)
///   │    ├─ systems (postEntities phase)
///   │    └─ _doPostUpdate(dt)
///   └─ onUpdate callbacks (happens after everything updated)
///
/// _doDraw(dt)
///   └─ per render layer:
///        ├─ onDrawBackground   (on RenderLayers.background)
///        ├─ systems (preEntities draw phase)
///        ├─ _drawEntities(dt)
///        ├─ systems (postEntities draw phase)
///        ├─ onDrawForeground   (on RenderLayers.foreground)
///        └─ onDraw callbacks (happens after everything drawn)
///
/// _doBeginFrame(dt)
///   ├─ beginFrame callbacks (happens before anything)
///   └─ systems beginFrame
///
/// _doEndFrame(dt)
///   ├─ process callbacks
///   ├─ process tasks
///   ├─ process commands
///   ├─ systems endFrame
///   └─ endFrame callbacks (happens after everything)
/// ```
/// 
/// ## Drawing
/// 
/// For scenes that render directly to the screen, prefer [DrawScene], which
/// handles [RaylibCoreD.BeginDrawing]/[RaylibCoreD.EndDrawing] automatically.
/// Use [Scene] directly only when you need manual control over the drawing lifecycle.
///
/// ## Events
///
/// Events posted via [emit] are queued and processed in priority order at the
/// start of the next [_doUpdate]. Events posted via [dispatch] are delivered immediately.
///
/// ## Cloning
///
/// [clone] produces a deep copy of the `scene`, `entities`, `systems`, `hooks`, and
/// the `event queue`, subject to an optional [SceneCloner] that can selectively
/// exclude or transform individual elements.
///
/// ## Key
///
/// Each scene has a [key] used to identify it in the app's scene registry.
/// If not supplied at construction, defaults to `'$runtimeType.$id'`.
class Scene<T extends App<T>> extends ECSBase<T> with

  // identity
  Self<Scene<T>>,

  // has
  HasSceneAccess<T>,
  HasVars<T, Scene<T>>,

  // is
  IsAddable<T, Scene<T>>,
  IsBeginEndFrameable<T, Scene<T>>,
  IsClonable<T, Scene<T>, SceneCloner<T>>,
  IsDisposable<T, Scene<T>>,
  IsDrawable<T, Scene<T>>,
  IsEnterable<T, Scene<T>>,
  IsEntityManagable<T, Scene<T>, Entity<T>>,
  IsEventEmittable<T, Scene<T>>,
  IsEventHistoryHolder<T, Scene<T>>,
  IsInputHandleable<Scene<T>>,
  IsLeavable<T, Scene<T>>,
  IsPrePostDrawable<T, Scene<T>>,
  IsPrePostUpdatable<T, Scene<T>>,
  IsRemovable<T, Scene<T>>,
  IsSceneSystemManagable<T, Scene<T>>,
  IsStartable<T, Scene<T>>,
  IsTaskProcessable<T, Scene<T>>,
  IsUpdatable<T, Scene<T>>,

  // special
  IsCallbackProcessable<T, Scene<T>>,
  IsCommandProcessable<T, Scene<T>>,
  IsStateHolder<T, Scene<T>, AnySceneSnapshot<T>>,
  IsPersistable<T, Scene<T>, AnySceneSnapshot<T>>

{

  @override
  final T app;

  /// Unique identifier for this scene within the app's scene registry.
  ///
  /// Defaults to `'$runtimeType.$id'` if not provided at construction.
  late final String key;

  /// Creates a new scene bound to [app].
  ///
  /// Automatically registers a [TransformSyncSystem] and emits
  /// [EventSceneInitialized].
  Scene(this.app, {String? key}) {
    this.key = key ?? '$runtimeType.$id';
    addSystem(TransformSyncSystem(app));
    emit(EventSceneInitialized(app, this));
  }

  @override
  late Bounds sceneBounds = .bounds(0, 0, screenHeight, screenWidth);

  @override
  Scene<T> get scene => this;

  @override
  InputSystem<T> get input => app.input;

  //   ░██████  ░██           ░██████   ░███    ░██ ░██████████ 
  //  ░██   ░██ ░██          ░██   ░██  ░████   ░██ ░██         
  // ░██        ░██         ░██     ░██ ░██░██  ░██ ░██         
  // ░██        ░██         ░██     ░██ ░██ ░██ ░██ ░█████████  
  // ░██        ░██         ░██     ░██ ░██  ░██░██ ░██         
  //  ░██   ░██ ░██          ░██   ░██  ░██   ░████ ░██         
  //   ░██████  ░██████████   ░██████   ░██    ░███ ░██████████ 

  @override
  @nonVirtual
  void _doOnClone(Scene<T> copy, [SceneCloner<T>? cloner]) {
    emit(EventSceneCloning(app, self, copy));

    _entities.forEach((e) {
      if (!(cloner?.allowEntity(copy, e) ?? true)) return;
      copy.addEntity(e.clone(cloner?.entityCloner));
    });

    _systems.forEach((s) {
      if (!(cloner?.allowSceneSystem(copy, s) ?? true)) return;
      copy.addSystem(s.clone(cloner?.systemCloner));
    });

    super._doOnClone(copy, cloner);
  }

  @override
  @nonVirtual
  void _doCloneAfter(Scene<T> target, [SceneCloner<T>? cloner]) {
    super._doCloneAfter(target, cloner);
    emit(EventSceneCloned(app, self, target));
  }

  @override
  Scene<T> createInstance() => .new(app);

  @override
  AnySceneSnapshot<T> createSnapshot() => .new(namedId);  

  @override
  @nonVirtual
  AnySceneSnapshot<T> captureSnapshot() {
    final snapshot = createSnapshot();
    snapshot.systemSnapshots = _systems
      .map((c) => c.captureSnapshot())
      .toList();
    snapshot.entitySnapshots = _entities
      .map((c) => c.captureSnapshot())
      .toList();
    return snapshot;
  }

  @override
  @mustCallSuper
  void restoreSnapshot(covariant AnySceneSnapshot<T> snapshot) {
    _restoreSnapshotList(
      originSnapshot: snapshot,
      sourceList: _systems.toList(),
      sourceSnapshots: snapshot.systemSnapshots,
      onRecreate: (x) => addSystem(x),
      onRestore: (x, s) => x.restoreSnapshot(s),
      onRemove: _removeSceneSystemInstance,
    );

    _restoreSnapshotList(
      originSnapshot: snapshot,
      sourceList: _entities.toList(),
      sourceSnapshots: snapshot.entitySnapshots,
      onRecreate: (x) => addEntity(x),
      onRestore: (x, s) => x.restoreSnapshot(s),
      onRemove: removeEntity,
    );
  }

  //   ░██████   ░██     ░██ ░██████████ ░█████████  ░██     ░██ 
  //  ░██   ░██  ░██     ░██ ░██         ░██     ░██  ░██   ░██  
  // ░██     ░██ ░██     ░██ ░██         ░██     ░██   ░██ ░██   
  // ░██     ░██ ░██     ░██ ░█████████  ░█████████     ░████    
  // ░██     ░██ ░██     ░██ ░██         ░██   ░██       ░██     
  //  ░██   ░██   ░██   ░██  ░██         ░██    ░██      ░██     
  //   ░██████     ░██████   ░██████████ ░██     ░██     ░██     
  //        ░██                                                   

  /// Returns a fresh [QueryEntity] scoped to this scene.
  ///
  /// Entry point for the **Query-like DSL**:
  ///
  /// ```dart
  ///   .With<Health>()
  ///   .Except<Dead>()
  ///   .DoForEachWith<Health>((e, h) => h.regen(dt));
  /// ```
  QueryEntities<T, Scene<T>> get QueryEntity => .new(app, self);

  // ░██     ░██   ░██████     ░██████   ░██     ░██   ░██████   
  // ░██     ░██  ░██   ░██   ░██   ░██  ░██    ░██   ░██   ░██  
  // ░██     ░██ ░██     ░██ ░██     ░██ ░██   ░██   ░██         
  // ░██████████ ░██     ░██ ░██     ░██ ░███████     ░████████  
  // ░██     ░██ ░██     ░██ ░██     ░██ ░██   ░██           ░██ 
  // ░██     ░██  ░██   ░██   ░██   ░██  ░██    ░██   ░██   ░██  
  // ░██     ░██   ░██████     ░██████   ░██     ░██   ░██████   

  @override
  @nonVirtual
  void _doHandleInput() {
    _systems.forEach((e) => e._doHandleInput());
    _entities.forEach((e) => e._doHandleInput());
    super._doHandleInput();
  }

  List<void Function(Scene<T> self, double dt)> _onDrawBackgroundFns = [];

  /// Registers [fn] to be called each frame during the background draw pass,
  /// before [onDrawBackground]. Returns `self` for chaining.
  @nonVirtual
  Scene<T> listenOnDrawBackground(void Function(Scene<T> self, double dt) fn) {
    _onDrawBackgroundFns.add(fn);
    return self;
  }

  @nonVirtual
  void _doDrawBackground(double dt) {
    _onDrawBackgroundFns.forEach((f) => f(self, dt));
    onDrawBackground();
  }
  
  List<void Function(Scene<T> self, double dt)> _onDrawForegroundFns = [];
  
  /// Registers [fn] to be called each frame during the foreground draw pass,
  /// before [onDrawForeground]. Returns `self` for chaining.
  @nonVirtual
  Scene<T> listenOnDrawForeground(void Function(Scene<T> self, double dt) fn) {
    _onDrawForegroundFns.add(fn);
    return self;
  }

  @nonVirtual
  void _doDrawForeground(double dt) {
    _onDrawForegroundFns.forEach((f) => f(self, dt));
    onDrawForeground();
  }

  /// Override to draw content behind entities on the [RenderLayers.background]
  /// layer. Called after all [listenOnDrawBackground] listeners.
  void onDrawBackground() {}

  /// Override to draw content in front of entities on the
  /// [RenderLayers.foreground] layer. Called after all
  /// [listenOnDrawForeground] listeners.
  void onDrawForeground() {}

  // ░██████░███     ░███ ░█████████  ░██         
  //   ░██  ░████   ░████ ░██     ░██ ░██         
  //   ░██  ░██░██ ░██░██ ░██     ░██ ░██         
  //   ░██  ░██ ░████ ░██ ░█████████  ░██         
  //   ░██  ░██  ░██  ░██ ░██         ░██         
  //   ░██  ░██       ░██ ░██         ░██         
  // ░██████░██       ░██ ░██         ░██████████ 

  /// Runs one update tick: `input` > `pre-update` > `systems (pre)` > `entities` >
  /// `systems (post)` > `post-update`.
  void _updateScene(double dt) {
    _doPreUpdate(dt);

    _runUpdateSystems(.preEntities, dt);
    _updateEntities(dt);
    _runUpdateSystems(.postEntities, dt);

    _doPostUpdate(dt);
  }

  /// Called by the app each frame to process the event queue and advance the
  /// scene by [dt] seconds.
  @override
  @nonVirtual
  void _doUpdate(double dt) {
    _updateScene(dt);
    super._doUpdate(dt);
  }

  /// Called by the app each frame to draw the scene.
  ///
  /// Iterates [Renderer.layers] in order, dispatching background/foreground
  /// hooks on the appropriate layers and calling system and entity draw methods
  /// for each layer.
  @override
  void _doDraw(double dt) {
    _doOnPreDraw(dt);

    for (final layer in renderer.layers) {
      renderer.setLayer(layer.name);

      if (layer.name == RenderLayers.background.name) {
        _doDrawBackground(dt);
      }

      _runDrawSystems(.preEntities, dt);
      _drawEntities(dt);
      _runDrawSystems(.postEntities, dt);

      if (layer.name == RenderLayers.foreground.name) {
        _doDrawForeground(dt);
      }
    }

    _doOnPostDraw(dt);

    super._doDraw(dt);
  }

  @override
  void _doBeginFrame(double dt) {
    super._doBeginFrame(dt);
    _systems.forEach((s) => s._doBeginFrame(dt));
  }

  void _doDrainLoop() {
    const maxIterations = 8;
    var iterations = 0;
    bool hadWork;
    do {
      hadWork = false;
      hadWork |= _processCallbacks();
      hadWork |= app._processEvents();
      hadWork |= _processCommands();
      iterations++;
    } while (hadWork && iterations < maxIterations);
  }

  /// Called by the app at the very end of each frame, after update and render.
  ///
  /// Drains the callback queue, then processes pending tasks and lastly commands.
  /// Deferred mutations (entity removal, scene transitions) should be
  /// posted here via [command] or [callback] to avoid mutating collections
  /// mid-iteration.
  @override
  void _doEndFrame(double dt) {
    _doDrainLoop();
    _processTasks(dt);
    _doDrainLoop();
    _systems.forEach((s) => s._doEndFrame(dt));
    super._doEndFrame(dt);
  }

  /// Calls the update hook on every system for the given [phase].
  void _runUpdateSystems(SystemPhase phase, double dt) 
    => _systems.forEach((s) => switch (phase) {
      .preEntities => s._doPreUpdate(dt),
      .postEntities => s._doPostUpdate(dt),
    });

  /// Calls the draw hook on every system for the given [phase].
  void _runDrawSystems(SystemPhase phase, double dt) 
    => _systems.forEach((s) => switch (phase) {
      .preEntities => s._doOnPreDraw(dt),
      .postEntities => s._doOnPostDraw(dt),
    });

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

        for (final s in _systems) {
          if (event.isStopped) return true;
          s._propagate(event);
        }

        return true;
      }

      _doOnEvent(event);
    }

    // Scene Systems
    if (event.scope != .local) {
      _doOnEvent(event);

      for (final s in _systems) {
        if (event.isStopped) return true;
        s._propagate(event);
      }
    }

    // defer to Entities
    if (event.isStopped) return true;
    if (
      event.scope != .sceneOnly &&
      event.scope != .globalNoEntities &&
      event.scope != .local
    ) {
      for (final entity in _entities) {
        if (event.isStopped) return true;
        entity._propagate(event);
      }
    }

    if (event.isStopped) return true;

    return event.origin != self;
  }

  @override
  void _doOnDispose() {
    _entities.forEach((s) => s._doOnDispose());
    _systems.forEach((s) => s._doOnDispose());
    super._doOnDispose();
  }
}

/// A [Scene] that wraps each frame in a Raylib drawing context.
///
/// Calls [RaylibCoreD.BeginDrawing] and [RaylibCoreD.ClearBackground] at the start of every frame,
/// and [RaylibCoreD.EndDrawing] at the end. Override [backgroundColor] to control the
/// clear color (defaults to [ColorD.BLACK]).
///
/// This is the correct base class for any scene that renders directly to the
/// screen; use [Scene] only if you need manual control over the drawing
/// lifecycle.
class DrawScene<T extends App<T>> extends Scene<T> {
  DrawScene(super.app, {super.key});

  ColorD get backgroundColor => .BLACK;

  @override
  void _doBeginFrame(double dt) {
    backend.render.beginDrawing();
    backend.render.clearBackground(backgroundColor);
    super._doBeginFrame(dt);
  }

  @override
  void _doEndFrame(double dt) {
    super._doEndFrame(dt);
    backend.render.endDrawing();
  }
}

typedef AnySceneSnapshot<T extends App<T>> = SceneSnapshot<T, Scene<T>>;

class SceneSnapshot<T extends App<T>, S extends Scene<T>> extends StateSnapshot<T, S> {
  late List<AnySceneSystemSnapshot<T>> systemSnapshots;
  late List<AnyEntitySnapshot<T>> entitySnapshots;

  SceneSnapshot(super.namedId);

  @override
  S createInstance(T app) => Scene<T>(app) as S;

  S assignSystems(T app, S destination) {
    for (final snap in systemSnapshots) {
      destination.addSystem(snap.reconstruct(app));
    }
    return destination;
  }

  S assignEntities(T app, S destination) {
    for (final snap in entitySnapshots) {
      destination.addEntity(snap.reconstruct(app));
    }
    return destination;
  }

  @override
  S reconstruct(T app) {
    final s = createInstance(app);
    assignSystems(app, s);
    assignEntities(app, s);
    return s;
  }
}
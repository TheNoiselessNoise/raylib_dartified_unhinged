part of '../../raylib_dartified_unhinged.dart';

/// Adds scene add/remove lifecycle hooks to an ECS object.
///
/// Covers two events: scene add and scene remove, each with a full three-phase contract:
/// - **before** => cancelable; any listener or override returning `false` aborts the operation
/// - **on** => the operation is about to complete; called by the host after all before-checks pass
/// - **after** => the operation has completed; side-effects and cleanup go here
mixin IsSceneManagable<
  T extends App<T>,
  E extends ECSBase<T>
> on
  Self<E>,
  ECSBase<T>,
  IsEventEmittable<T, E>,
  IsSceneTransitionable<T, E>
{
  // ░██     ░██   ░██████     ░██████   ░██     ░██   ░██████   
  // ░██     ░██  ░██   ░██   ░██   ░██  ░██    ░██   ░██   ░██  
  // ░██     ░██ ░██     ░██ ░██     ░██ ░██   ░██   ░██         
  // ░██████████ ░██     ░██ ░██     ░██ ░███████     ░████████  
  // ░██     ░██ ░██     ░██ ░██     ░██ ░██   ░██           ░██ 
  // ░██     ░██  ░██   ░██   ░██   ░██  ░██    ░██   ░██   ░██  
  // ░██     ░██   ░██████     ░██████   ░██     ░██   ░██████   

  late final hookOnBeforeSceneAddKey = ECSHookKey<bool Function(E self, Scene<T> scene)>(
    'IsSceneManagable', 'onBeforeSceneAdd'
  );

  late final hookOnSceneAddKey = ECSHookKey<void Function(E self, Scene<T> scene)>(
    'IsSceneManagable', 'onSceneAdd'
  );

  late final hookOnAfterSceneAddKey = ECSHookKey<void Function(E self, Scene<T> scene)>(
    'IsSceneManagable', 'onAfterSceneAdd'
  );

  late final hookOnBeforeSceneRemoveKey = ECSHookKey<bool Function(E self, Scene<T> scene)>(
    'IsSceneManagable', 'onBeforeSceneRemove'
  );

  late final hookOnSceneRemoveKey = ECSHookKey<void Function(E self, Scene<T> scene)>(
    'IsSceneManagable', 'onSceneRemove'
  );

  late final hookOnAfterSceneRemoveKey = ECSHookKey<void Function(E self, Scene<T> scene)>(
    'IsSceneManagable', 'onAfterSceneRemove'
  );

  Iterable<bool Function(E self, Scene<T> scene)> get _onBeforeSceneAddFns
    => hooksOf(hookOnBeforeSceneAddKey);
  
  Iterable<void Function(E self, Scene<T> scene)> get _onSceneAddFns
    => hooksOf(hookOnSceneAddKey);

  Iterable<void Function(E self, Scene<T> scene)> get _onAfterSceneAddFns
    => hooksOf(hookOnAfterSceneAddKey);

  Iterable<bool Function(E self, Scene<T> scene)> get _onBeforeSceneRemoveFns
    => hooksOf(hookOnBeforeSceneRemoveKey);

  Iterable<void Function(E self, Scene<T> scene)> get _onSceneRemoveFns
    => hooksOf(hookOnSceneRemoveKey);

  Iterable<void Function(E self, Scene<T> scene)> get _onAfterSceneRemoveFns
    => hooksOf(hookOnAfterSceneRemoveKey);

  /// Registers [fn] as a before-add listener.
  ///
  /// [fn] returning `false` cancels the scene add.
  @nonVirtual
  E listenOnBeforeSceneAdd(bool Function(E self, Scene<T> scene) fn) {
    addHook(hookOnBeforeSceneAddKey, fn);
    return self;
  }

  /// Registers [fn] as an add listener.
  ///
  /// Called when the add operation is about to happen and was not canceled.
  @nonVirtual
  E listenOnSceneAdd(void Function(E self, Scene<T> scene) fn) {
    addHook(hookOnSceneAddKey, fn);
    return self;
  }

  /// Registers [fn] as an after-add listener.
  ///
  /// Called only if the scene add was not canceled.
  @nonVirtual
  E listenOnAfterSceneAdd(void Function(E self, Scene<T> scene) fn) {
    addHook(hookOnAfterSceneAddKey, fn);
    return self;
  }

  /// Registers [fn] as a before-remove listener.
  ///
  /// [fn] returning `false` cancels the scene remove.
  @nonVirtual
  E listenOnBeforeSceneRemove(bool Function(E self, Scene<T> scene) fn) {
    addHook(hookOnBeforeSceneRemoveKey, fn);
    return self;
  }

  /// Registers [fn] as a remove listener.
  ///
  /// Called when the remove operation is about to happen and was not canceled.
  @nonVirtual
  E listenOnSceneRemove(void Function(E self, Scene<T> scene) fn) {
    addHook(hookOnSceneRemoveKey, fn);
    return self;
  }

  /// Registers [fn] as an after-remove listener.
  ///
  /// Called only if the scene remove was not canceled.
  @nonVirtual
  E listenOnAfterSceneRemove(void Function(E self, Scene<T> scene) fn) {
    addHook(hookOnAfterSceneRemoveKey, fn);
    return self;
  }

  /// Runs all before-add listeners and [onBeforeSceneAdd].
  ///
  /// Returns `false` if any listener or the override cancels the add.
  bool _doOnBeforeSceneAdd(Scene<T> scene) {
    if (!_onBeforeSceneAddFns.every((f) => f(self, scene))) return false;
    return onBeforeSceneAdd(scene);
  }

  /// Runs all add listeners and [onSceneAdd].
  void _doOnSceneAdd(Scene<T> scene) {
    _onSceneAddFns.forEach((f) => f(self, scene));
    onSceneAdd(scene);
  }

  /// Runs all after-add listeners and [onAfterSceneAdd].
  void _doOnAfterSceneAdd(Scene<T> scene) {
    _onAfterSceneAddFns.forEach((f) => f(self, scene));
    onAfterSceneAdd(scene);
  }

  /// Runs all before-remove listeners and [onBeforeSceneRemove].
  ///
  /// Returns `false` if any listener or the override cancels the remove.
  bool _doOnBeforeSceneRemove(Scene<T> scene) {
    if (!_onBeforeSceneRemoveFns.every((f) => f(self, scene))) return false;
    return onBeforeSceneRemove(scene);
  }

  /// Runs all remove listeners and [onSceneRemove].
  void _doOnSceneRemove(Scene<T> scene) {
    _onSceneRemoveFns.forEach((f) => f(self, scene));
    onSceneRemove(scene);
  }

  /// Runs all after-remove listeners and [onAfterSceneRemove].
  void _doOnAfterSceneRemove(Scene<T> scene) {
    _onAfterSceneRemoveFns.forEach((f) => f(self, scene));
    onAfterSceneRemove(scene);
  }

  /// Override to cancel a scene add from within the class.
  ///
  /// Return `false` to abort. Called after all registered [listenOnBeforeSceneAdd] listeners.
  bool onBeforeSceneAdd(Scene<T> scene) => true;

  /// Override to react when a scene add is about to complete.
  ///
  /// Called by the host after all before-checks have passed.
  void onSceneAdd(Scene<T> scene) {}

  /// Override to react after a scene add has completed.
  ///
  /// Called after all registered [listenOnAfterSceneAdd] listeners.
  void onAfterSceneAdd(Scene<T> scene) {}

  /// Override to cancel a scene remove from within the class.
  ///
  /// Return `false` to abort. Called after all registered [listenOnBeforeSceneRemove] listeners.
  bool onBeforeSceneRemove(Scene<T> scene) => true;

  /// Override to react when a scene remove is about to complete.
  ///
  /// Called by the host after all before-checks have passed.
  void onSceneRemove(Scene<T> scene) {}

  /// Override to react after a scene remove has completed.
  ///
  /// Called after all registered [listenOnAfterSceneRemove] listeners.
  void onAfterSceneRemove(Scene<T> scene) {}

  // ░██████░███     ░███ ░█████████  ░██         
  //   ░██  ░████   ░████ ░██     ░██ ░██         
  //   ░██  ░██░██ ░██░██ ░██     ░██ ░██         
  //   ░██  ░██ ░████ ░██ ░█████████  ░██         
  //   ░██  ░██  ░██  ░██ ░██         ░██         
  //   ░██  ░██       ░██ ░██         ░██         
  // ░██████░██       ░██ ░██         ░██████████ 

  late final List<Scene<T>> _scenes = [];
  bool _dummyScenePresent = true;
  late Scene<T> _currentScene;

  void _assignDummyScene() {
    final dummyScene = FWidgetScene<T>(app);

    // message
    dummyScene.listenOnStart((_) => dummyScene.addEntity(FCenter(app,
      vertical: true,
      child: FColumn(app,
        alignment: .center,
        gap: 16,
        children: [
          FLabel(app, text: 'No scene is currently active.'),
          FLabel(app, text: 'Add a scene to get started.'),
        ],
      ),
    )));

    // background
    double time = 0.0;
    dummyScene.listenOnDraw((_, dt) {
      time += dt;

      final screen = sceneBounds.size;
      const waveCount = 6;
      
      for (int waveIndex = 0; waveIndex < waveCount; waveIndex++) {
        int x = 0;
        while (x < screen.x) {
          final y = (
            ((screen.y / waveCount) * waveIndex) +
            math.sin((x * 0.012) + (time * (1.2 + waveIndex * 0.3)) + (waveIndex * 0.8)) *
            (18.0 + waveIndex * 4.0)
          );
          
          final alpha = 40 + (waveIndex * 12);
          backend.render.drawPixel(x, y, .color(30, 120, 220, alpha));
          x += 2;
        }
      }
    });

    _dummyScenePresent = true;
    _currentScene = dummyScene;

    _scenes.clear();
    _scenes.add(_currentScene);
  }

  Iterable<Scene<T>> getScenes() => _scenes;

  Scene<T> get currentScene => _currentScene;

  /// Replaces the first scene whose `runtimeType == scene.runtimeType` with [scene].
  E replaceScene(Scene<T> scene) {
    final old = _scenes.where((c) => c.runtimeType == scene.runtimeType).firstOrNull;
    if (old != null) removeScene(old);
    addScene(scene);
    return self;
  }

  S? getSceneByKey<S extends Scene<T>>(String key) => _scenes.where((s) => s.key == key).firstOrNull as S?;

  S? getScene<S extends Scene<T>>() => _scenes.whereType<S>().firstOrNull;

  void swapScene(Scene<T> oldScene, Scene<T> newScene) {
    if (getSceneByKey(oldScene.key) != null) {
      removeScene(oldScene);
    }
    
    addScene(newScene);
    
    if (oldScene.id == _currentScene.id) {
      setScene(newScene);
    }
  }

  E addScene(Scene<T> scene) {
    final existingScene = getSceneByKey(scene.key);
    if (existingScene != null) {
      throw StateError('You are trying to register already registered Scene $scene.');
    }

    emit(EventSceneAdding(app, scene));

    if (!_doOnBeforeSceneAdd(scene)) {
      emit(EventSceneAddCancelled(app, scene));
      return self;
    }

    if (!scene._doOnBeforeAdd(self)) {
      emit(EventSceneAddCancelled(app, scene));
      return self;
    }

    if (_dummyScenePresent) {
      _scenes.clear();
    }
    
    _doOnSceneAdd(scene);
    if (!scene.isClone) scene._doAdd(self);
    _scenes.add(scene);

    if (_dummyScenePresent) {
      _dummyScenePresent = false;
      _currentScene = scene;
    }

    scene._doOnAfterAdd(self);
    _doOnAfterSceneAdd(scene);
    emit(EventSceneAdded(app, scene));

    return self;
  }

  E removeScene(Scene<T> scene) {
    emit(EventSceneRemoving(app, scene));
    
    if (!_doOnBeforeSceneRemove(scene)) {
      emit(EventSceneRemoveCancelled(app, scene));
      return self;
    }

    if (!scene._doOnBeforeRemove()) {
      emit(EventSceneRemoveCancelled(app, scene));
      return self;
    }
    
    _doOnSceneRemove(scene);
    scene._doRemove();
    _scenes.remove(scene);

    scene._doOnAfterRemove();
    _doOnAfterSceneRemove(scene);
    emit(EventSceneRemoved(app, scene));
    return self;
  }

  void nextScene() => setSceneByIndex((_scenes.indexOf(_currentScene) + 1) % _scenes.length);

  void previousScene() => setSceneByIndex((_scenes.indexOf(_currentScene) - 1) % _scenes.length);

  bool _leaveCurrentScene() {
    final scene = _currentScene;

    emit(EventSceneLeaving(app, scene));

    if (!_doOnBeforeSceneLeave(scene)) {
      emit(EventSceneLeaveCancelled(app, scene));
      return false;
    }

    if (!scene._doOnBeforeLeave()) {
      emit(EventSceneLeaveCancelled(app, scene));
      return false;
    } 

    _doOnSceneLeave(scene);
    scene._doOnLeave();

    _doOnAfterSceneLeave(scene);
    scene._doOnAfterLeave();
    emit(EventSceneLeft(app, scene));
    return true;
  }

  bool _enterScene(Scene<T> scene) {
    emit(EventSceneEntering(app, scene));

    if (!_doOnBeforeSceneEnter(scene)) {
      emit(EventSceneEnterCancelled(app, scene));
      return false;
    }

    if (!scene._doOnBeforeEnter()) {
      emit(EventSceneEnterCancelled(app, scene));
      return false;
    }

    _doOnSceneEnter(scene);
    scene._doOnEnter();
    _currentScene = scene;
    if (!scene.isClone) scene._doStart();

    _doOnAfterSceneEnter(scene);
    scene._doOnAfterEnter();
    emit(EventSceneEntered(app, scene));
    return true;
  }

  void setScene(Scene<T> scene) {
    final from = _currentScene;
    final to = scene;

    emit(EventSceneTransitioning(app, from, to));

    if (!_doOnBeforeSceneTransition(from, to)) {
      emit(EventSceneTransitionCancelled(app, from, to));
      return;
    }

    _doOnSceneTransition(from, to);

    if (from != to) {
      if (!_leaveCurrentScene()) {
        emit(EventSceneTransitionCancelled(app, from, to));
        return;
      }
    }

    if (!_enterScene(to)) {
      emit(EventSceneTransitionCancelled(app, from, to));
      return;
    }

    _doOnAfterSceneTransition(from, to);
    emit(EventSceneTransitioned(app, from, to));
  }

  void setSceneByIndex(int index) {
    var scene = _scenes.elementAtOrNull(index);
    if (scene == null) throw Exception('Invalid scene index: $index');
    setScene(scene);
  }

  void setSceneByKey(String key) {
    var scene = _scenes.where((s) => s.key == key).firstOrNull;
    if (scene == null) throw Exception('Invalid scene key: $key');
    setScene(scene);
  }
}
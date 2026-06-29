part of '../raylib_dartified_unhinged.dart';

abstract class AppService<T extends App<T>> extends ECSBase<T> with
  Self<AppService<T>>,
  IsDisposable<T, AppService<T>>
{

  @override
  final T app;

  AppService(this.app);
}

class AppSystem<T extends App<T>> extends ECSBase<T> with

  // identity
  Self<AppSystem<T>>,

  // has
  HasSceneAccess<T>,

  // is
  IsAddable<T, AppSystem<T>>,
  IsBeginEndFrameable<T, AppSystem<T>>,
  IsClonable<T, AppSystem<T>, AppSystemCloner<T>>,
  IsDisposable<T, AppSystem<T>>,
  IsEventEmittable<T, AppSystem<T>>,
  IsEventHistoryHolder<T, AppSystem<T>>,
  IsInputHandleable<AppSystem<T>>,
  IsRemovable<T, AppSystem<T>>,
  IsStateHolder<T, AppSystem<T>, AnyAppSystemSnapshot<T>>,
  IsPersistable<T, AppSystem<T>, AnyAppSystemSnapshot<T>>

{

  @override
  final T app;
  
  AppSystem(this.app);

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
        return true;
      }

      _doOnEvent(event);
    }

    if (event.isStopped) return true;
    if (
      event.scope != .local &&
      event.scope != .scene &&
      event.scope != .sceneOnly
    ) _doOnEvent(event);

    if (event.isStopped) return true;
    
    return event.origin != self;
  }

  //   ░██████  ░██           ░██████   ░███    ░██ ░██████████ 
  //  ░██   ░██ ░██          ░██   ░██  ░████   ░██ ░██         
  // ░██        ░██         ░██     ░██ ░██░██  ░██ ░██         
  // ░██        ░██         ░██     ░██ ░██ ░██ ░██ ░█████████  
  // ░██        ░██         ░██     ░██ ░██  ░██░██ ░██         
  //  ░██   ░██ ░██          ░██   ░██  ░██   ░████ ░██         
  //   ░██████  ░██████████   ░██████   ░██    ░███ ░██████████ 

  @override
  @nonVirtual
  void _doOnClone(AppSystem<T> copy, [AppSystemCloner<T>? cloner]) {
    app._doOnEvent(EventAppSystemCloning(app, self, copy));
    super._doOnClone(copy, cloner);
  }

  @override
  @nonVirtual
  void _doCloneAfter(AppSystem<T> target, [AppSystemCloner<T>? cloner]) {
    super._doCloneAfter(target, cloner);
    app._doOnEvent(EventAppSystemCloned(app, self, target));
  }

  @override
  AppSystem<T> createInstance() => .new(app);

  @override
  AnyAppSystemSnapshot<T> createSnapshot() => .new(namedId);  

  @override
  @nonVirtual
  AnyAppSystemSnapshot<T> captureSnapshot() => createSnapshot();

  @override
  @mustCallSuper
  void restoreSnapshot(covariant AnyAppSystemSnapshot<T> snapshot) {}
}

typedef AnyAppSystemSnapshot<T extends App<T>> = AppSystemSnapshot<T, AppSystem<T>>;

class AppSystemSnapshot<T extends App<T>, S extends AppSystem<T>> extends StateSnapshot<T, S> {
  AppSystemSnapshot(super.namedId);

  @override
  S createInstance(T app) => AppSystem<T>(app) as S;

  @override
  S reconstruct(T app) => createInstance(app);
}
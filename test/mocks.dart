import 'package:meta/meta.dart';
import 'package:raylib_dartified_unhinged/raylib_dartified_unhinged.dart';

enum TestingEmitterType {
  app,
  appSystem,
  scene,
  sceneSystem,
  entity1,
  comp1,
  entity2,
  comp2,
  comp3,
}

typedef TestingOnEventHandler<T extends TestingApp<T>> = void Function(Event<T> event);

mixin TestingIsOnEventCallbackHandler<T extends TestingApp<T>, E extends ECSBase<T>> on IsEventEmittable<T, E> {
  TestingOnEventHandler<T>? _onEventHandler;

  @override
  @mustCallSuper
  void onEvent(Event<T> event) => _onEventHandler?.call(event);
}

class TestingOnEventCallbackPackage<T extends TestingApp<T>> {
  final TestingOnEventHandler<T>? appOnEvent;
  final TestingOnEventHandler<T>? appSystemOnEvent;
  final TestingOnEventHandler<T>? sceneOnEvent;
  final TestingOnEventHandler<T>? sceneSystemOnEvent;
  final TestingOnEventHandler<T>? entity1OnEvent;
  final TestingOnEventHandler<T>? comp1OnEvent;
  final TestingOnEventHandler<T>? entity2OnEvent;
  final TestingOnEventHandler<T>? comp2OnEvent;
  final TestingOnEventHandler<T>? comp3OnEvent;

  TestingOnEventCallbackPackage({
    this.appOnEvent,
    this.appSystemOnEvent,
    this.sceneOnEvent,
    this.sceneSystemOnEvent,
    this.entity1OnEvent,
    this.comp1OnEvent,
    this.entity2OnEvent,
    this.comp2OnEvent,
    this.comp3OnEvent,
  });
}

class TestingEvent<T extends App<T>> extends Event<T> {
  final String? source;

  TestingEvent(super.app, [this.source]);
}

class TestingApp<T extends TestingApp<T>> extends App<T> with TestingIsOnEventCallbackHandler<T, T> {
  final TestingOnEventCallbackPackage<T>? onEventCallbackPackage;
  late final TestingAppSystem<T> appSystem;
  late final TestingScene<T> testScene;

  TestingApp(super.backend, {
    this.onEventCallbackPackage,
  }) {
    addSystem(appSystem = .new(app));
    addScene(testScene = .new(app));

    _onEventHandler = onEventCallbackPackage?.appOnEvent;
    appSystem._onEventHandler = onEventCallbackPackage?.appSystemOnEvent;
    testScene._onEventHandler = onEventCallbackPackage?.sceneOnEvent;
    testScene.sceneSystem._onEventHandler = onEventCallbackPackage?.sceneSystemOnEvent;
    testScene.entity1._onEventHandler = onEventCallbackPackage?.entity1OnEvent;
    testScene.entity1.comp1._onEventHandler = onEventCallbackPackage?.comp1OnEvent;
    testScene.entity2._onEventHandler = onEventCallbackPackage?.entity2OnEvent;
    testScene.entity2.comp2._onEventHandler = onEventCallbackPackage?.comp2OnEvent;
    testScene.entity2.comp2.comp3._onEventHandler = onEventCallbackPackage?.comp3OnEvent;
  }

  Map<TestingEmitterType, IsAnyEventHistoryHolder<T>> get eventHistoryHolders => {
    .app: app,
    .appSystem: app.appSystem,
    .scene: app.testScene,
    .sceneSystem: app.testScene.sceneSystem,
    .entity1: app.testScene.entity1,
    .comp1: app.testScene.entity1.comp1,
    .entity2: app.testScene.entity2,
    .comp2: app.testScene.entity2.comp2,
    .comp3: app.testScene.entity2.comp2.comp3,
  };
}

class TestingAppSystem<T extends TestingApp<T>> extends AppSystem<T> with TestingIsOnEventCallbackHandler<T, AppSystem<T>> {
  TestingAppSystem(super.app);
}

class TestingSceneSystem<T extends TestingApp<T>> extends SceneSystem<T> with TestingIsOnEventCallbackHandler<T, SceneSystem<T>> {
  TestingSceneSystem(super.app);
}

class TestingScene<T extends TestingApp<T>> extends Scene<T> with TestingIsOnEventCallbackHandler<T, Scene<T>> {
  late final TestingSceneSystem<T> sceneSystem;
  late final TestingEntity1<T> entity1;
  late final TestingEntity2<T> entity2;

  TestingScene(super.app) {
    addSystem(sceneSystem = .new(app));
    addEntity(entity1 = .new(app));
    addEntity(entity2 = .new(app));
  }
}

class TestingComponent1<T extends TestingApp<T>> extends Comp<T> with TestingIsOnEventCallbackHandler<T, Comp<T>> {
  TestingComponent1(super.app);
}

class TestingEntity1<T extends TestingApp<T>> extends Entity<T> with TestingIsOnEventCallbackHandler<T, Entity<T>> {
  late final TestingComponent1<T> comp1;

  TestingEntity1(super.app) {
    addComp(comp1 = .new(app));
  }
}

class TestingComponent2<T extends TestingApp<T>> extends Comp<T> with TestingIsOnEventCallbackHandler<T, Comp<T>> {
  late final TestingComponent3<T> comp3;

  TestingComponent2(super.app);
}

class TestingEntity2<T extends TestingApp<T>> extends Entity<T> with TestingIsOnEventCallbackHandler<T, Entity<T>> {
  late final TestingComponent2<T> comp2;

  TestingEntity2(super.app) {
    addComp(comp2 = .new(app));
    comp2.addComp(comp2.comp3 = .new(app));
  }
}

class TestingComponent3<T extends TestingApp<T>> extends Comp<T> with TestingIsOnEventCallbackHandler<T, Comp<T>> {
  TestingComponent3(super.app);
}

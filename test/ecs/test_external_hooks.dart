import 'package:raylib_dartified_unhinged/raylib_dartified_unhinged.dart';
import 'package:test/test.dart';
import '../mocks.dart';

typedef G = TestApp;

class TestApp extends TestingApp<G> {
  TestApp(super.backend, {
    super.onEventCallbackPackage,
  });
}

TestApp createTestApp({
  bool clearEventQueue = false,
}) {
  final TestApp app = .new(HeadlessBackend())..init();
  if (clearEventQueue) app.clearEventQueue();
  return app;
}

void main2() {
  final app = createTestApp();
  final sceneSystem = app.testScene.sceneSystem;

  sceneSystem.listenOnActivate((self) {
    print('I have been de/activated: ${self.isActive}');
  });

  print(sceneSystem.hooksOf(sceneSystem.hookOnActivateKey));

  final clonedSceneSystem = sceneSystem.clone();
  app.testScene.replaceSystem(clonedSceneSystem);
  print(clonedSceneSystem.hooksOf(clonedSceneSystem.hookOnActivateKey));

  clonedSceneSystem.setActive(false);
  clonedSceneSystem.setActive(true);
}

void main() {
  group('External Hooks', () {
    bool? isActive;
    late G app;
    late SceneSystem<G> sceneSystem;

    void doOnActivate(SceneSystem<G> sceneSystem) => isActive = sceneSystem.isActive;

    setUp(() {
      isActive = null;
      app = createTestApp();
      sceneSystem = app.testScene.sceneSystem;
    });

    test('Registration', () {
      sceneSystem.listenOnActivate(doOnActivate);
      sceneSystem.setActive(false);
      expect(isActive, isFalse);
    });

    test('Clone', () {
      sceneSystem.listenOnActivate(doOnActivate);
      final clonedSceneSystem = sceneSystem.clone();
      clonedSceneSystem.setActive(false);
      expect(isActive, isFalse);
    });

    test('Clone independence', () {
      sceneSystem.listenOnActivate(doOnActivate);
      final clonedSceneSystem = sceneSystem.clone();
      sceneSystem.clearExternalHooks([sceneSystem.hookOnActivateKey]);
      clonedSceneSystem.setActive(false);
      expect(isActive, isFalse); // clone's hook should still fire
    });

    test('Unregister (by closure)', () {
      sceneSystem.listenOnActivate(doOnActivate);
      sceneSystem.removeHook(sceneSystem.hookOnActivateKey, doOnActivate);
      sceneSystem.setActive(false);
      expect(isActive, isNull);
    });

    test('Unregister (by key)', () {
      sceneSystem.listenOnActivate(doOnActivate);
      sceneSystem.clearExternalHooks([sceneSystem.hookOnActivateKey]);
      sceneSystem.setActive(false);
      expect(isActive, isNull);
    });

    test('Unregister (by family)', () {
      sceneSystem.listenOnActivate(doOnActivate);
      sceneSystem.clearExternalHookFamily('IsActivatable');
      sceneSystem.setActive(false);
      expect(isActive, isNull);
    });
  });
}

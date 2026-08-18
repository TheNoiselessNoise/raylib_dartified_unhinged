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

  sceneSystem.listenOnEnable((self) {
    print('${self.isEnabled}) I have been ${self.isEnabled ? 'enabled' : 'disabled'}');
  });

  print(sceneSystem.hooksOf(sceneSystem.hookOnEnableKey));

  final clonedSceneSystem = sceneSystem.clone();
  app.testScene.replaceSystem(clonedSceneSystem);
  print(clonedSceneSystem.hooksOf(clonedSceneSystem.hookOnEnableKey));

  clonedSceneSystem.setEnabled(false);
  clonedSceneSystem.setEnabled(true);
}

void main() {
  group('External Hooks', () {
    bool? isEnabled;
    late G app;
    late SceneSystem<G> sceneSystem;

    void doOnEnabled(SceneSystem<G> sceneSystem) => isEnabled = sceneSystem.isEnabled;

    setUp(() {
      isEnabled = null;
      app = createTestApp();
      sceneSystem = app.testScene.sceneSystem;
    });

    test('Registration', () {
      sceneSystem.listenOnEnable(doOnEnabled);
      sceneSystem.setEnabled(false);
      expect(isEnabled, isFalse);
    });

    test('Clone', () {
      sceneSystem.listenOnEnable(doOnEnabled);
      final clonedSceneSystem = sceneSystem.clone();
      clonedSceneSystem.setEnabled(false);
      expect(isEnabled, isFalse);
    });

    test('Clone independence', () {
      sceneSystem.listenOnEnable(doOnEnabled);
      final clonedSceneSystem = sceneSystem.clone();
      sceneSystem.clearExternalHooks([sceneSystem.hookOnEnableKey]);
      clonedSceneSystem.setEnabled(false);
      expect(isEnabled, isFalse); // clone's hook should still fire
    });

    test('Unregister (by closure)', () {
      sceneSystem.listenOnEnable(doOnEnabled);
      sceneSystem.removeHook(sceneSystem.hookOnEnableKey, doOnEnabled);
      sceneSystem.setEnabled(false);
      expect(isEnabled, isNull);
    });

    test('Unregister (by key)', () {
      sceneSystem.listenOnEnable(doOnEnabled);
      sceneSystem.clearExternalHooks([sceneSystem.hookOnEnableKey]);
      sceneSystem.setEnabled(false);
      expect(isEnabled, isNull);
    });

    test('Unregister (by family)', () {
      sceneSystem.listenOnEnable(doOnEnabled);
      sceneSystem.clearExternalHookFamily('IsEnableable');
      sceneSystem.setEnabled(false);
      expect(isEnabled, isNull);
    });
  });
}

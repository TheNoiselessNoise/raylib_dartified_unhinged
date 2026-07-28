import 'package:raylib_dartified_unhinged/raylib_dartified_unhinged.dart';
import 'package:test/test.dart';

typedef G = TestApp;

class TestScene extends FWidgetScene<G> {
  late TestSceneSystem testSceneSystem;
  late TestEntity1 entity1;
  late TestEntity2 entity2;

  TestScene(super.app) {
    addSystem(testSceneSystem = .new(app));
    addEntity(entity1 = .new(app));
    addEntity(entity2 = .new(app));
  }
}

class TestSceneSystem extends SceneSystem<G> {
  TestSceneSystem(super.app);
}

class TestComponent1 extends Comp<G> {
  TestComponent1(super.app);
}

class TestEntity1 extends Entity<G> {
  late TestComponent1 comp1;

  TestEntity1(super.app) {
    addComp(comp1 = .new(app));
  }
}

class TestComponent2 extends Comp<G> {
  late TestComponent3 comp3;

  TestComponent2(super.app);
}

class TestEntity2 extends Entity<G> {
  late TestComponent2 comp2;

  TestEntity2(super.app) {
    addComp(comp2 = .new(app));
    comp2.addComp(comp2.comp3 = .new(app));
  }
}

class TestComponent3 extends Comp<G> {
  TestComponent3(super.app);
}

class TestAppSystem extends AppSystem<G> {
  TestAppSystem(super.app);
}

class TestApp extends App<G> {
  late TestAppSystem testAppSystem;
  late TestScene testScene;

  TestApp(super.backend) {
    addSystem(testAppSystem = .new(app));
    addScene(testScene = .new(app));
  }
}

void main() {
  // group('Debug', () {
    TestApp app = .new(HeadlessBackend());
    app.enableDebug(true);

    app.testScene.entity2.dbg('hello world!');
  // });
}
// Run it: dart run test_animations.dart
import '_base.dart';

class MyEntity extends Entity<G> {
  double entityField;

  late CAnimation<G, MyEntity> animation;

  MyEntity(super.app, {
    required this.entityField
  }) {
    addComp(CTransform(app, position: screenSize.divideBy(2)));
    addComp(CRectCollider(app, size: .vec2(64, 64), debugDraw: true, debugColor: .GREEN));
    addComp(animation = .new(app, this)
      ..property((e) => e.entityField, (s, v) => s.entityField = v, from: 0, to: 1, duration: 0.5)
      ..onComplete(() {
        addMessage('Animation completed!');
        // animation.reset();
      })
    );
  } 
}

extension on HasAppAccess<G> {
  TestStateMachineScene get testScene => app.getScene()!;
  void addMessage(String message, {bool? isValid})
    => testScene.messagesWidget.setState(() => testScene.messagesWidget.addMessage(message, isValid: isValid));
}

class TestStateMachineScene extends DrawScene<G> {
  late MyEntity myEntity;
  late ExampleMessagesWidget<G> messagesWidget;

  TestStateMachineScene(super.app) {
    addEntity(messagesWidget = .new(app));
    addEntity(myEntity = MyEntity(app, entityField: 69));
  }

  @override
  void onInput() {
    if (rl.CoreD.IsKeyDown(.KEY_UP)) myEntity.entityField++;
    if (rl.CoreD.IsKeyDown(.KEY_DOWN)) myEntity.entityField--;
  }

  @override
  void onDraw(double dt) {
    rl.CoreD.DrawText('entityField: ${myEntity.entityField}', 10, screenHeight - 30, 20, .WHITE);
  }

  @override
  TestStateMachineScene createInstance() => .new(app);
}

typedef G = TestStateMachineApp;

class TestStateMachineApp extends ExampleApp<G> {
  TestStateMachineApp(super.rl);

  @override
  void onInit() {
    rl.CoreD.InitWindow(screenWidth, screenHeight, "test_animations");
    rl.CoreD.SetWindowMonitor(0);
    rl.CoreD.SetTargetFPS(60);
    addScene(TestStateMachineScene(app));
  }

  @override
  TestStateMachineApp createInstance() => .new(rl);
}

void main() => runExample((rl) => G(rl));

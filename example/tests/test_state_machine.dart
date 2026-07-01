// Run it: dart run test_state_machine.dart
import '_base.dart';

class MyEntity extends Entity<G> {
  int entityField;

  late CStateMachine<G> stateMachine;

  MyEntity(super.app, {
    required this.entityField
  }) {
    addComp(CTransform(app, position: screenSize.divideBy(2)));
    addComp(CRectCollider(app, size: .vec2(64, 64), debugDraw: true, debugColor: .GREEN));
    addComp(stateMachine = .new(app)
      ..addState('above100',
        onEnter: () => addMessage('state machine: `above100` onEnter'),
        // onUpdate: (dt) => print('state machine: `above100` onUpdate:'),
        onExit: () => addMessage('state machine: `above100` onExit'))
      ..addState('below100',
        onEnter: () => addMessage('state machine: `below100` onEnter'),
        // onUpdate: (dt) => print('state machine: `below100` onUpdate:'),
        onExit: () => addMessage('state machine: `below100` onExit'))
      ..transition('above100', 'below100', when: () => entityField < 100)
      ..transition('below100', 'above100', when: () => entityField > 100)
      ..start(entityField < 100 ? 'below100' : 'above100')
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

class TestStateMachineApp extends ExampleRaylibApp<G> {
  TestStateMachineApp(super.backend);

  @override
  void onInit() {
    rl.CoreD.InitWindow(screenWidth, screenHeight, "test_state_machine");
    rl.CoreD.SetWindowMonitor(0);
    rl.CoreD.SetTargetFPS(60);
    addScene(TestStateMachineScene(app));
  }

  @override
  TestStateMachineApp createInstance() => .new(backend);
}

void main() => runExample((backend) => G(backend));

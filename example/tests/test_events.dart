// Run it: dart run test_events.dart
import '_base.dart';
import '../../test/ecs/test_events.dart'
  show
    TestEventsAppSystem,
    TestEventsScene,
    EventMethod,
    EmitterType,
    IsTestingApp,
    TestEventPropagationResult,
    testEventPropagation;

class MessagesWidget extends ExampleMessagesWidget<G> {
  MessagesWidget(super.app);

  @override
  get header => FSized(app,
    heightMode: .flexible,
    widthMode: .flexible,
    child: FRow(app,
      gap: 8,
      children: [
        FLabel(app, fontSize: 14, text: 'SCOPE: ${testScene.selectedScope.name}'),
        FLabel(app, fontSize: 14, text: 'METHOD: ${testScene.selectedMethod.name}'),
        FLabel(app, fontSize: 14, text: 'EMITTER: ${testScene.selectedEmitter}'),
        FLabel(app, fontSize: 14, text: '[SPACE=AUTO ENTER=THIS]'),
      ],
    ),
  );
}

extension on EventMethod {
  EventMethod get prev => switch (this) {
    .dispatch => .emit,
    .emit => .dispatch
  };

  EventMethod get next => prev;
}

extension on EmitterType {
  EmitterType get prev => switch (this) {
    .appSystem => .app, .scene => .appSystem,
    .sceneSystem => .scene, .entity1 => .sceneSystem,
    .comp1 => .entity1, .entity2 => .comp1,
    .comp2 => .entity2, .comp3 => .comp2, .app => .comp3,
  };

  EmitterType get next => switch (this) {
    .app => .appSystem, .appSystem => .scene,
    .scene => .sceneSystem, .sceneSystem => .entity1,
    .entity1 => .comp1, .comp1 => .entity2,
    .entity2 => .comp2, .comp2 => .comp3, .comp3 => .app,
  };
}

extension on HasAppAccess<G> {
  TestEventsGuiScene get testScene => app.testScene;
  void addMessage(String message, {bool? isValid}) => testScene.messagesWidget.addMessage(message, isValid: isValid);
  void clearMessages() => testScene.messagesWidget.clear();
  void rebuildWidget() => testScene.messagesWidget.rebuild();
}

class TestEventsGuiScene extends TestEventsScene<G> {
  late MessagesWidget messagesWidget;

  TestEventsGuiScene(super.app);

  @override
  void onStart() {
    super.onStart();
    addEntity(messagesWidget = .new(app));
  }

  EventMethod selectedMethod = .emit;
  EventScope selectedScope = .global;
  EmitterType selectedEmitter = .app;

  TestEventPropagationResult runTest({
    required EmitterType emitter,
    required EventMethod method,
    required EventScope scope,
  }) {
    final result = testEventPropagation(app,
      emitter: emitter,
      method: selectedMethod,
      scope: scope
    );

    final scopeName = scope.name;

    if (result.isValid) {
      addMessage('$emitter > $scopeName', isValid: true);
    } else {
      final parts = [
        if (result.missing.isNotEmpty)
          'missing: {${result.missing.join(', ')}}',
        
        if (result.extra.isNotEmpty)
          'extra: {${result.extra.join(', ')}}',
        
        if (result.tooMany.isNotEmpty)
          'tooMany: {${result.tooMany.map((x) => '${x.$1.name}(${x.$2})').join(', ')}}',
      ].join('  ');

      addMessage('$emitter > $scopeName | $parts', isValid: false);
    }

    return result;
  }

  void runAutoTest() {
    clearMessages();
    addMessage('=== AUTO-TEST START ===');

    int passed = 0;
    int failed = 0;

    for (final scope in EventScope.values) {
      for (final emitter in EmitterType.values) {
        final result = runTest(
          emitter: emitter,
          method: selectedMethod,
          scope: scope
        );

        passed += result.isValid ? 1 : 0;
        failed += result.isValid ? 0 : 1;
      }
    }

    addMessage('=== DONE: $passed passed, $failed failed ===');
    rebuildWidget();
  }

  void runCustomTest() {
    clearMessages();
    addMessage('=== CUSTOM-TEST START ===');
    final result = runTest(
      emitter: selectedEmitter,
      method: selectedMethod,
      scope: selectedScope,
    );
    addMessage('=== DONE: ${result.isValid ? 'passed' : 'failed'} ===');
    rebuildWidget();
  }

  @override
  void onInput() {
    if (rl.CoreD.IsKeyPressed(.KEY_K))     messagesWidget.setState(() => selectedMethod = selectedMethod.prev);
    if (rl.CoreD.IsKeyPressed(.KEY_L))     messagesWidget.setState(() => selectedMethod = selectedMethod.next);
    if (rl.CoreD.IsKeyPressed(.KEY_LEFT))  messagesWidget.setState(() => selectedScope = selectedScope.prev);
    if (rl.CoreD.IsKeyPressed(.KEY_RIGHT)) messagesWidget.setState(() => selectedScope = selectedScope.next);
    if (rl.CoreD.IsKeyPressed(.KEY_UP))    messagesWidget.setState(() => selectedEmitter = selectedEmitter.prev);
    if (rl.CoreD.IsKeyPressed(.KEY_DOWN))  messagesWidget.setState(() => selectedEmitter = selectedEmitter.next);
    if (rl.CoreD.IsKeyPressed(.KEY_SPACE)) runAutoTest();
    if (rl.CoreD.IsKeyPressed(.KEY_ENTER)) runCustomTest();
  }
}

typedef G = TestEventsGuiApp;

class TestEventsGuiApp extends ExampleRaylibApp<G> with IsTestingApp<G> {
  @override late TestEventsAppSystem<G> appSystem;
  @override late TestEventsGuiScene testScene;

  TestEventsGuiApp(super.backend);

  @override
  void onInit() {
    rl.CoreD.InitWindow(screenWidth, screenHeight, "test_events");
    rl.CoreD.SetWindowMonitor(0);
    rl.CoreD.SetTargetFPS(60);

    addSystem(appSystem = .new(app));
    addScene(testScene = .new(app));
  }
}

void main() => runExample((backend) => G(backend));
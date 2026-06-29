// Run it: dart run test_events.dart
import '_base.dart';

class TestEvent extends Event<G> {
  TestEvent(super.app);
}

class TestEventsComponent1 extends Comp<G> {
  TestEventsComponent1(super.app);

  @override
  void onEvent(Event<G> event) {
    if (event is TestEvent) eventsScene.addTestResult(R.comp1);
  }
}

class TestEventsEntity1 extends Entity<G> {
  TestEventsEntity1(super.app) {
    addComp(TestEventsComponent1(app));
  }

  @override
  void onEvent(Event<G> event) {
    if (event is TestEvent) eventsScene.addTestResult(R.entity1);
  }
}

class TestEventsComponent2 extends Comp<G> {
  TestEventsComponent2(super.app);

  @override
  void onEvent(Event<G> event) {
    if (event is TestEvent) eventsScene.addTestResult(R.comp2);
  }
}

class TestEventsEntity2 extends Entity<G> {
  TestEventsEntity2(super.app) {
    final comp3 = TestEventsComponent2(app);
    addComp(comp3);
    comp3.addComp(TestEventsComponent3(app));
  }

  @override
  void onEvent(Event<G> event) {
    if (event is TestEvent) eventsScene.addTestResult(R.entity2);
  }
}

class TestEventsComponent3 extends Comp<G> {
  TestEventsComponent3(super.app);

  @override
  void onEvent(Event<G> event) {
    if (event is TestEvent) eventsScene.addTestResult(R.comp3);
  }
}

class MessagesWidget extends ExampleMessagesWidget<G> {
  MessagesWidget(super.app);

  @override
  get header => FSized(app,
    heightMode: .flexible,
    widthMode: .flexible,
    child: FRow(app,
      gap: 8,
      children: [
        FLabel(app, fontSize: 14, text: 'SCOPE: ${eventsScene.selectedScope.name}'),
        FLabel(app, fontSize: 14, text: 'EMITTER: ${eventsScene.selectedEmitter}'),
        FLabel(app, fontSize: 14, text: '[SPACE=AUTO ENTER=THIS]'),
      ],
    ),
  );
}

class R {
  static const String app         = 'App';
  static const String appSystem   = 'AppSystem';
  static const String scene       = 'Scene';
  static const String sceneSystem = 'SceneSystem';
  static const String entity1     = 'Entity1';
  static const String comp1       = 'Comp1';
  static const String entity2     = 'Entity2';
  static const String comp2       = 'Comp2';
  static const String comp3       = 'Comp3';
}

class E {
  static const String app         = 'app';
  static const String appSystem   = 'appSystem';
  static const String scene       = 'scene';
  static const String sceneSystem = 'sceneSystem';
  static const String entity1     = 'entity1';
  static const String comp1       = 'comp1';
  static const String entity2     = 'entity2';
  static const String comp2       = 'comp2';
  static const String comp3       = 'comp3';

  /// order for auto-test loop
  static const List<String> all = [
    app, appSystem,
    scene, sceneSystem,
    entity1, entity2,
    comp1, comp2, comp3
  ];

  static String prev(String current) => switch (current) {
    appSystem => app, scene => appSystem,
    sceneSystem => scene, entity1 => sceneSystem,
    comp1 => entity1, entity2 => comp1,
    comp2 => entity2, comp3 => comp2, app => comp3,
    _ => throw UnsupportedError('Unknown emittor $current'),
  };

  static String next(String current) => switch (current) {
    app => appSystem, appSystem => scene,
    scene => sceneSystem, sceneSystem => entity1,
    entity1 => comp1, comp1 => entity2,
    entity2 => comp2, comp2 => comp3, comp3 => app,
    _ => throw UnsupportedError('Unknown emittor $current'),
  };
}

const Map<(String, EventScope), Set<String>> _expectedReceivers = {

  (E.app,         .global): {R.app, R.appSystem, R.scene, R.sceneSystem, R.entity1, R.comp1, R.entity2, R.comp2, R.comp3},
  (E.appSystem,   .global): {R.app, R.appSystem, R.scene, R.sceneSystem, R.entity1, R.comp1, R.entity2, R.comp2, R.comp3},
  (E.scene,       .global): {R.app, R.appSystem, R.scene, R.sceneSystem, R.entity1, R.comp1, R.entity2, R.comp2, R.comp3},
  (E.sceneSystem, .global): {R.app, R.appSystem, R.scene, R.sceneSystem, R.entity1, R.comp1, R.entity2, R.comp2, R.comp3},
  (E.entity1,     .global): {R.app, R.appSystem, R.scene, R.sceneSystem, R.entity1, R.comp1, R.entity2, R.comp2, R.comp3},
  (E.comp1,       .global): {R.app, R.appSystem, R.scene, R.sceneSystem, R.entity1, R.comp1, R.entity2, R.comp2, R.comp3},
  (E.entity2,     .global): {R.app, R.appSystem, R.scene, R.sceneSystem, R.entity1, R.comp1, R.entity2, R.comp2, R.comp3},
  (E.comp2,       .global): {R.app, R.appSystem, R.scene, R.sceneSystem, R.entity1, R.comp1, R.entity2, R.comp2, R.comp3},
  (E.comp3,       .global): {R.app, R.appSystem, R.scene, R.sceneSystem, R.entity1, R.comp1, R.entity2, R.comp2, R.comp3},

  (E.app,         .globalNoEntities): {R.app, R.appSystem, R.scene, R.sceneSystem},
  (E.appSystem,   .globalNoEntities): {R.app, R.appSystem, R.scene, R.sceneSystem},
  (E.scene,       .globalNoEntities): {R.app, R.appSystem, R.scene, R.sceneSystem},
  (E.sceneSystem, .globalNoEntities): {R.app, R.appSystem, R.scene, R.sceneSystem},
  (E.entity1,     .globalNoEntities): {R.app, R.appSystem, R.scene, R.sceneSystem},
  (E.comp1,       .globalNoEntities): {R.app, R.appSystem, R.scene, R.sceneSystem},
  (E.entity2,     .globalNoEntities): {R.app, R.appSystem, R.scene, R.sceneSystem},
  (E.comp2,       .globalNoEntities): {R.app, R.appSystem, R.scene, R.sceneSystem},
  (E.comp3,       .globalNoEntities): {R.app, R.appSystem, R.scene, R.sceneSystem},

  (E.app,         .scene): {R.scene, R.sceneSystem, R.entity1, R.comp1, R.entity2, R.comp2, R.comp3},
  (E.appSystem,   .scene): {R.scene, R.sceneSystem, R.entity1, R.comp1, R.entity2, R.comp2, R.comp3},
  (E.scene,       .scene): {R.scene, R.sceneSystem, R.entity1, R.comp1, R.entity2, R.comp2, R.comp3},
  (E.sceneSystem, .scene): {R.scene, R.sceneSystem, R.entity1, R.comp1, R.entity2, R.comp2, R.comp3},
  (E.entity1,     .scene): {R.scene, R.sceneSystem, R.entity1, R.comp1, R.entity2, R.comp2, R.comp3},
  (E.comp1,       .scene): {R.scene, R.sceneSystem, R.entity1, R.comp1, R.entity2, R.comp2, R.comp3},
  (E.entity2,     .scene): {R.scene, R.sceneSystem, R.entity1, R.comp1, R.entity2, R.comp2, R.comp3},
  (E.comp2,       .scene): {R.scene, R.sceneSystem, R.entity1, R.comp1, R.entity2, R.comp2, R.comp3},
  (E.comp3,       .scene): {R.scene, R.sceneSystem, R.entity1, R.comp1, R.entity2, R.comp2, R.comp3},

  (E.app,         .sceneOnly): {R.scene, R.sceneSystem},
  (E.appSystem,   .sceneOnly): {R.scene, R.sceneSystem},
  (E.scene,       .sceneOnly): {R.scene, R.sceneSystem},
  (E.sceneSystem, .sceneOnly): {R.scene, R.sceneSystem},
  (E.entity1,     .sceneOnly): {R.scene, R.sceneSystem},
  (E.comp1,       .sceneOnly): {R.scene, R.sceneSystem},
  (E.entity2,     .sceneOnly): {R.scene, R.sceneSystem},
  (E.comp2,       .sceneOnly): {R.scene, R.sceneSystem},
  (E.comp3,       .sceneOnly): {R.scene, R.sceneSystem},

  (E.app,         .local): {R.app, R.appSystem},
  (E.appSystem,   .local): {R.appSystem},
  (E.scene,       .local): {R.scene, R.sceneSystem},
  (E.sceneSystem, .local): {R.sceneSystem},
  (E.entity1,     .local): {R.entity1, R.comp1},
  (E.comp1,       .local): {R.comp1},
  (E.entity2,     .local): {R.entity2, R.comp2, R.comp3},
  (E.comp2,       .local): {R.comp2, R.comp3},
  (E.comp3,       .local): {R.comp3},

  (E.app,         .self): {R.app},
  (E.appSystem,   .self): {R.appSystem},
  (E.scene,       .self): {R.scene},
  (E.sceneSystem, .self): {R.sceneSystem},
  (E.entity1,     .self): {R.entity1},
  (E.comp1,       .self): {R.comp1},
  (E.entity2,     .self): {R.entity2},
  (E.comp2,       .self): {R.comp2},
  (E.comp3,       .self): {R.comp3},
};

class TestEventsSceneSystem extends SceneSystem<G> {
  TestEventsSceneSystem(super.app);

  @override
  void onEvent(Event<G> event) {
    if (event is TestEvent) eventsScene.addTestResult(R.sceneSystem);
  }
}

extension on HasAppAccess<G> {
  TestEventsScene get eventsScene => app.getScene()!;
  void addMessage(String message, {bool? isValid}) => eventsScene.messagesWidget.addMessage(message, isValid: isValid);
  void clearMessages() => eventsScene.messagesWidget.clear();
  void rebuildWidget() => eventsScene.messagesWidget.rebuild();
}

class TestEventsScene extends FWidgetScene<G> {
  late MessagesWidget messagesWidget;

  TestEventsScene(super.app);

  @override
  void onStart() {
    addEntity(messagesWidget = MessagesWidget(app));
    addSystem(TestEventsSceneSystem(app));
    addEntity(TestEventsEntity1(app));
    addEntity(TestEventsEntity2(app));
  }

  EventScope selectedScope = .global;
  String selectedEmitter = E.app;

  final Set<String> _testCollector = {};
  final Map<String, int> _testCounts = {};
  void addTestResult(String emitter) {
    _testCollector.add(emitter);
    _testCounts[emitter] = _testCounts.putIfAbsent(emitter, () => 0) + 1;
  }

  bool test(EventScope scope, String emitter) {
    _testCollector.clear();
    _testCounts.clear();

    final scopeName = scope.name;

    bool passed = true;

    void fire(String emitterName) {
      final event = TestEvent(app)..scope = scope;

      switch (emitterName) {
        case E.app:         app.dispatch(event);
        case E.appSystem:   app.getSystem<TestEventsAppSystem>()!.dispatch(event);
        
        case E.scene:       dispatch(event);
        case E.sceneSystem: getSystem<TestEventsSceneSystem>()!.dispatch(event);
        
        case E.entity1:     QueryEntity.On<TestEventsEntity1>().First.dispatch(event);
        case E.comp1:       QueryEntity.On<TestEventsEntity1>().First
                              .QueryComp.On<TestEventsComponent1>().First.dispatch(event);
        
        case E.entity2:     QueryEntity.On<TestEventsEntity2>().First.dispatch(event);
        case E.comp2:       QueryEntity.On<TestEventsEntity2>().First
                              .QueryComp.On<TestEventsComponent2>().First.dispatch(event);
        
        case E.comp3:       QueryEntity.On<TestEventsEntity2>().First
                              .QueryComp.On<TestEventsComponent2>().First
                              .QueryComp.On<TestEventsComponent3>().First.dispatch(event);
      }
    }

    final key = (emitter, scope);
    final expected = _expectedReceivers[key];

    if (expected == null) {
      // Should never happen
      addMessage('?? $emitter > $scopeName [no entry for \'$key\']');
      return false;
    }

    fire(emitter);
    final missing = expected.difference(_testCollector);
    final extra   = _testCollector.difference(expected);
    final tooMany = <String>[];

    for (final ex in _testCounts.entries) {
      if (!expected.contains(ex.key)) continue;
      if (ex.value > 1) tooMany.add('${ex.key}(${ex.value})');
    }

    if (missing.isEmpty && extra.isEmpty && tooMany.isEmpty) {
      addMessage('$emitter > $scopeName', isValid: true);
    } else {
      passed = false;
      final parts = [
        if (missing.isNotEmpty) 'missing: {${missing.join(', ')}}',
        if (extra.isNotEmpty)   'extra: {${extra.join(', ')}}',
        if (tooMany.isNotEmpty) 'tooMany: {${tooMany.join(', ')}}',
      ].join('  ');
      addMessage('$emitter > $scopeName | $parts', isValid: false);
    }

    return passed;
  }

  void runAutoTest() {
    clearMessages();
    addMessage('=== AUTO-TEST START ===');

    int passed = 0;
    int failed = 0;

    for (final scope in EventScope.values) {
      for (final emitter in E.all) {
        if (test(scope, emitter)) {
          passed++;
        } else {
          failed++;
        }
      }
    }

    addMessage('=== DONE: $passed passed, $failed failed ===');
    rebuildWidget();
  }

  void runCustomTest() {
    clearMessages();
    addMessage('=== CUSTOM-TEST START ===');
    final passed = test(selectedScope, selectedEmitter);
    addMessage('=== DONE: ${passed ? 'passed' : 'failed'} ===');
    rebuildWidget();
  }

  @override
  void onEvent(Event<G> event) {
    if (event is TestEvent) _testCollector.add(R.scene);
  }

  @override
  void onInput() {
    if (rl.CoreD.IsKeyPressed(.KEY_LEFT))  messagesWidget.setState(() => selectedScope = selectedScope.prev);
    if (rl.CoreD.IsKeyPressed(.KEY_RIGHT)) messagesWidget.setState(() => selectedScope = selectedScope.next);
    if (rl.CoreD.IsKeyPressed(.KEY_UP))    messagesWidget.setState(() => selectedEmitter = E.prev(selectedEmitter));
    if (rl.CoreD.IsKeyPressed(.KEY_DOWN))  messagesWidget.setState(() => selectedEmitter = E.next(selectedEmitter));
    if (rl.CoreD.IsKeyPressed(.KEY_SPACE)) runAutoTest();
    if (rl.CoreD.IsKeyPressed(.KEY_ENTER)) runCustomTest();
  }
}

class TestEventsAppSystem extends AppSystem<G> {
  TestEventsAppSystem(super.app);

  @override
  void onEvent(Event<G> event) {
    if (event is TestEvent) eventsScene.addTestResult(R.appSystem);
  }
}

typedef G = TestEventsApp;

class TestEventsApp extends ExampleApp<G> {
  TestEventsApp(super.rl);

  @override
  void onInit() {
    rl.CoreD.InitWindow(screenWidth, screenHeight, "test_events");
    rl.CoreD.SetWindowMonitor(0);
    rl.CoreD.SetTargetFPS(60);

    addSystem(TestEventsAppSystem(app));
    addScene(TestEventsScene(app));
  }

  @override
  void onEvent(Event<G> event) {
    if (event is TestEvent) eventsScene.addTestResult(R.app);
  }
}

void main() => runExample((rl) => G(rl));
import 'package:raylib_dartified_unhinged/raylib_dartified_unhinged.dart';
import 'package:test/test.dart';

final Set<EmitterType> testCollector = {};
final Map<EmitterType, int> testCounts = {};

void addTestResult(EmitterType emitter) {
  testCollector.add(emitter);
  testCounts[emitter] = testCounts.putIfAbsent(emitter, () => 0) + 1;
}

mixin IsTestingApp<T extends IsTestingApp<T>> on App<T> {
  TestAppSystem<T> get appSystem;
  TestScene<T> get testScene;

  Map<EmitterType, IsAnyEventHistoryHolder<T>> get eventHistoryHolders => {
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

  @override
  void onEvent(Event<T> event) {
    if (event is TestEvent<T>) addTestResult(.app);
  }
}

class TestEventPropagationResult {
  ExpectedValues expected = .new(0, 0, {});
  Set<(EmitterType, int)> got = {};

  Set<EmitterType> missing = {};
  Set<EmitterType> extra = {};
  Set<(EmitterType, int)> tooMany = {};

  bool get isValid => missing.isEmpty && extra.isEmpty && tooMany.isEmpty;

  String get reason => [
    '\nEXPECTED: ',
    expected.allEvents.map((x) => '${x.name}(1)').join(', '),

    '\nGOT:      ',
    got.map((x) => '${x.$1.name}(${x.$2})').join(', '),

    '\n--- REASON ---',

    if (missing.isNotEmpty) [
      '\nMISSING:  ',
      missing.map((x) => x.name).join(', '),
    ].join(''),

    if (extra.isNotEmpty) [
      '\nEXTRA:    ',
      extra.map((x) => x.name).join(', '),
    ].join(''),

    if (tooMany.isNotEmpty) [
      '\nTOO MANY: ',
      tooMany.map((x) => '${x.$1.name}(${x.$2})').join(', '),
    ].join(''),

  ].join('');
}

void fireEvent<T extends IsTestingApp<T>>(T app, EmitterType emitter, EventMethod method, EventScope scope) {
  final IsAnyEventEmittable<T> emittable = switch (emitter) {
    .app         => app,
    .appSystem   => app.appSystem,
    .scene       => app.testScene,
    .sceneSystem => app.testScene.sceneSystem,
    .entity1     => app.testScene.entity1,
    .comp1       => app.testScene.entity1.comp1,
    .entity2     => app.testScene.entity2,
    .comp2       => app.testScene.entity2.comp2,
    .comp3       => app.testScene.entity2.comp2.comp3,
  };

  switch (method) {
    case .emit:     emittable.emit(TestEvent(app), scope: scope);
    case .dispatch: emittable.dispatch(TestEvent(app), scope: scope);
  }

  if (method == .emit) {
    app.processQueuedEventsForTest();
  }
}

TestEventPropagationResult testEventPropagation<T extends IsTestingApp<T>>(T app, {
  required EmitterType emitter,
  required EventMethod method,
  required EventScope scope,
}) {
  final result = TestEventPropagationResult();

  testCollector.clear();
  testCounts.clear();

  final key = (emitter, scope);
  result.expected = expectedReceivers[key]!;

  fireEvent(app, emitter, method, scope);
  result.missing = result.expected.allEvents.difference(testCollector);
  result.extra   = testCollector.difference(result.expected.allEvents);

  for (final ex in testCounts.entries) {
    result.got.add((ex.key, ex.value));

    if (!result.expected.allEvents.contains(ex.key)) continue;
    if (ex.value > 1) result.tooMany.add((ex.key, ex.value));
  }

  return result;
}

enum EventMethod {
  emit,
  dispatch,
}

enum EmitterType {
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

class ExpectedValues {
  final int appEventCount;
  final int holderEventCount;
  final Set<EmitterType> allEvents;

  const ExpectedValues(this.appEventCount, this.holderEventCount, this.allEvents);
}

const Map<(EmitterType, EventScope), ExpectedValues> expectedReceivers = {

  (.app, .global):           .new(1, 1, {.app, .appSystem, .scene, .sceneSystem, .entity1, .comp1, .entity2, .comp2, .comp3}),
  (.app, .globalNoEntities): .new(1, 1, {.app, .appSystem, .scene, .sceneSystem}),
  (.app, .scene):            .new(0, 0, {.scene, .sceneSystem, .entity1, .comp1, .entity2, .comp2, .comp3}),
  (.app, .sceneOnly):        .new(0, 0, {.scene, .sceneSystem}),
  (.app, .local):            .new(1, 1, {.app, .appSystem}),
  (.app, .self):             .new(1, 1, {.app}),
    
  (.appSystem, .global):           .new(1, 1, {.app, .appSystem, .scene, .sceneSystem, .entity1, .comp1, .entity2, .comp2, .comp3}),
  (.appSystem, .globalNoEntities): .new(1, 1, {.app, .appSystem, .scene, .sceneSystem}),
  (.appSystem, .scene):            .new(0, 0, {.scene, .sceneSystem, .entity1, .comp1, .entity2, .comp2, .comp3}),
  (.appSystem, .sceneOnly):        .new(0, 0, {.scene, .sceneSystem}),
  (.appSystem, .local):            .new(1, 1, {.appSystem}),
  (.appSystem, .self):             .new(1, 1, {.appSystem}),
  
  (.scene, .global):           .new(1, 1, {.app, .appSystem, .scene, .sceneSystem, .entity1, .comp1, .entity2, .comp2, .comp3}),
  (.scene, .globalNoEntities): .new(1, 1, {.app, .appSystem, .scene, .sceneSystem}),
  (.scene, .scene):            .new(1, 1, {.scene, .sceneSystem, .entity1, .comp1, .entity2, .comp2, .comp3}),
  (.scene, .sceneOnly):        .new(1, 1, {.scene, .sceneSystem}),
  (.scene, .local):            .new(1, 1, {.scene, .sceneSystem}),
  (.scene, .self):             .new(1, 1, {.scene}),

  (.sceneSystem, .global):           .new(1, 1, {.app, .appSystem, .scene, .sceneSystem, .entity1, .comp1, .entity2, .comp2, .comp3}),
  (.sceneSystem, .globalNoEntities): .new(1, 1, {.app, .appSystem, .scene, .sceneSystem}),
  (.sceneSystem, .scene):            .new(1, 1, {.scene, .sceneSystem, .entity1, .comp1, .entity2, .comp2, .comp3}),
  (.sceneSystem, .sceneOnly):        .new(1, 1, {.scene, .sceneSystem}),
  (.sceneSystem, .local):            .new(1, 1, {.sceneSystem}),
  (.sceneSystem, .self):             .new(1, 1, {.sceneSystem}),

  (.entity1, .global):           .new(1, 1, {.app, .appSystem, .scene, .sceneSystem, .entity1, .comp1, .entity2, .comp2, .comp3}),
  (.entity1, .globalNoEntities): .new(1, 0, {.app, .appSystem, .scene, .sceneSystem}),
  (.entity1, .scene):            .new(1, 1, {.scene, .sceneSystem, .entity1, .comp1, .entity2, .comp2, .comp3}),
  (.entity1, .sceneOnly):        .new(0, 0, {.scene, .sceneSystem}),
  (.entity1, .local):            .new(1, 1, {.entity1, .comp1}),
  (.entity1, .self):             .new(1, 1, {.entity1}),

  (.comp1, .global):           .new(1, 1, {.app, .appSystem, .scene, .sceneSystem, .entity1, .comp1, .entity2, .comp2, .comp3}),
  (.comp1, .globalNoEntities): .new(1, 0, {.app, .appSystem, .scene, .sceneSystem}),
  (.comp1, .scene):            .new(1, 1, {.scene, .sceneSystem, .entity1, .comp1, .entity2, .comp2, .comp3}),
  (.comp1, .sceneOnly):        .new(0, 0, {.scene, .sceneSystem}),
  (.comp1, .local):            .new(1, 1, {.comp1}),
  (.comp1, .self):             .new(1, 1, {.comp1}),

  (.entity2, .global):           .new(1, 1, {.app, .appSystem, .scene, .sceneSystem, .entity1, .comp1, .entity2, .comp2, .comp3}),
  (.entity2, .globalNoEntities): .new(1, 0, {.app, .appSystem, .scene, .sceneSystem}),
  (.entity2, .scene):            .new(1, 1, {.scene, .sceneSystem, .entity1, .comp1, .entity2, .comp2, .comp3}),
  (.entity2, .sceneOnly):        .new(0, 0, {.scene, .sceneSystem}),
  (.entity2, .local):            .new(1, 1, {.entity2, .comp2, .comp3}),
  (.entity2, .self):             .new(1, 1, {.entity2}),

  (.comp2, .global):           .new(1, 1, {.app, .appSystem, .scene, .sceneSystem, .entity1, .comp1, .entity2, .comp2, .comp3}),
  (.comp2, .globalNoEntities): .new(1, 0, {.app, .appSystem, .scene, .sceneSystem}),
  (.comp2, .scene):            .new(1, 1, {.scene, .sceneSystem, .entity1, .comp1, .entity2, .comp2, .comp3}),
  (.comp2, .sceneOnly):        .new(0, 0, {.scene, .sceneSystem}),
  (.comp2, .local):            .new(1, 1, {.comp2, .comp3}),
  (.comp2, .self):             .new(1, 1, {.comp2}),

  (.comp3, .global):           .new(1, 1, {.app, .appSystem, .scene, .sceneSystem, .entity1, .comp1, .entity2, .comp2, .comp3}),
  (.comp3, .globalNoEntities): .new(1, 0, {.app, .appSystem, .scene, .sceneSystem}),
  (.comp3, .scene):            .new(1, 1, {.scene, .sceneSystem, .entity1, .comp1, .entity2, .comp2, .comp3}),
  (.comp3, .sceneOnly):        .new(0, 0, {.scene, .sceneSystem}),
  (.comp3, .local):            .new(1, 1, {.comp3}),
  (.comp3, .self):             .new(1, 1, {.comp3}),
};

typedef G = TestApp;

class TestApp extends App<G> with IsTestingApp<G> {
  @override late TestAppSystem<G> appSystem;
  @override late TestScene<G> testScene;

  TestApp(super.backend) {
    addSystem(appSystem = .new(app));
    addScene(testScene = .new(app));
  }
}

class TestAppSystem<T extends App<T>> extends AppSystem<T> {
  TestAppSystem(super.app);

  @override
  void onEvent(Event<T> event) {
    if (event is TestEvent<T>) addTestResult(.appSystem);
  }
}

class TestSceneSystem<T extends App<T>> extends SceneSystem<T> {
  TestSceneSystem(super.app);

  @override
  void onEvent(Event<T> event) {
    if (event is TestEvent<T>) addTestResult(.sceneSystem);
  }
}

class TestScene<T extends App<T>> extends FWidgetScene<T> {
  late TestSceneSystem<T> sceneSystem;
  late TestEntity1<T> entity1;
  late TestEntity2<T> entity2;

  TestScene(super.app);

  @override
  void onStart() {
    addSystem(sceneSystem = .new(app));
    addEntity(entity1 = .new(app));
    addEntity(entity2 = .new(app));
  }

  @override
  void onEvent(Event<T> event) {
    if (event is TestEvent<T>) addTestResult(.scene);
  }
}

class TestEvent<T extends App<T>> extends Event<T> {
  TestEvent(super.app);
}

class TestComponent1<T extends App<T>> extends Comp<T> {
  TestComponent1(super.app);

  @override
  void onEvent(Event<T> event) {
    if (event is TestEvent<T>) addTestResult(.comp1);
  }
}

class TestEntity1<T extends App<T>> extends Entity<T> {
  late TestComponent1<T> comp1;

  TestEntity1(super.app) {
    addComp(comp1 = .new(app));
  }

  @override
  void onEvent(Event<T> event) {
    if (event is TestEvent<T>) addTestResult(.entity1);
  }
}

class TestComponent2<T extends App<T>> extends Comp<T> {
  late TestComponent3<T> comp3;

  TestComponent2(super.app);

  @override
  void onEvent(Event<T> event) {
    if (event is TestEvent<T>) addTestResult(.comp2);
  }
}

class TestEntity2<T extends App<T>> extends Entity<T> {
  late TestComponent2<T> comp2;

  TestEntity2(super.app) {
    addComp(comp2 = .new(app));
    comp2.addComp(comp2.comp3 = .new(app));
  }

  @override
  void onEvent(Event<T> event) {
    if (event is TestEvent<T>) addTestResult(.entity2);
  }
}

class TestComponent3<T extends App<T>> extends Comp<T> {
  TestComponent3(super.app);

  @override
  void onEvent(Event<T> event) {
    if (event is TestEvent<T>) addTestResult(.comp3);
  }
}

void main() {
  group('Propagation', () {
    final app = TestApp(HeadlessBackend())..init();

    for (final method in EventMethod.values) {
      group('method=${method.name}', () {
        for (final scope in EventScope.values) {
          group('scope=${scope.name}', () {
            for (final emitter in EmitterType.values) {
              test('emitter=${emitter.name}', () {
                final result = testEventPropagation(app,
                  method: method,
                  scope: scope,
                  emitter: emitter,
                );

                expect(result.isValid, equals(true), reason: result.reason);
              });
            }
          });
        }
      });
    }
  });

  group('regression: queue ordering', () {
    test('equal-priority events drain in insertion order', () {
      final app = TestApp(HeadlessBackend())..init();
      
      final holders = app.eventHistoryHolders;

      List<TestEvent<G>> events = List.generate(holders.length, (_) => .new(app));
      List<int> ids = events.map((e) => e.id).toList();

      for (final (i, emittable) in holders.values.indexed) {
        emittable.emit(events[i], scope: .self);
      }

      app.processQueuedEventsForTest();

      final historyEvents = app.eventHistory.whereType<TestEvent>().toList();
      List<int> historyIds = historyEvents.map((e) => e.id).toList();

      expect(historyEvents.length, equals(holders.length));
      expect(historyIds, equals(ids));

      for (final (i, emittable) in holders.values.indexed) {
        if (emittable is TestApp) continue;

        final historyEvents = emittable.eventHistory.whereType<TestEvent>().toList();
        List<int> historyIds = historyEvents.map((e) => e.id).toList();

        expect(historyEvents.length, equals(1));
        expect(historyIds, equals([events[i].id]));
      }
    });
  });

  group('replaying', () {
    late G app;

    setUp(() => app = .new(HeadlessBackend())..init()..clearEventQueue());

    test('reproduces live self-scope delivery order per holder', () {
      List<String> ids = [];

      for (final holder in app.eventHistoryHolders.values) {
        holder.listenOnEvent((x, event) {
          ids.add('${x.namedId}_${event.namedId}');
        });
      }

      for (final holder in app.eventHistoryHolders.values) {
        ids.clear();

        // some arbitrary number of events
        final List<TestEvent<G>> events = .generate(10, (_) => .new(app));        
        final expected = events.map((e) => '${holder.namedId}_${e.namedId}');

        for (final event in events) {
          holder.emit(event, scope: .self);
        }

        app.processQueuedEventsForTest();

        // current
        expect(ids.toList(), equals(expected));
        ids.clear();

        holder.replayRecordedEvents(filter: (e) => e is TestEvent);
        app.processQueuedEventsForTest();

        // recorded
        expect(ids.toList(), equals(expected));

        app.clearEventHistory();
        holder.clearEventHistory();
      }
    });

    test('multiple', () {
      const n = 10;
      const replays = 10;

      final List<String> ids = [];
      app.listenOnEvent((x, event) => ids.add('${x.namedId}_${event.namedId}'));

      final List<TestEvent<G>> events = .generate(n, (_) => .new(app));
      events.forEach((e) => app.emit(e, scope: .self));
      app.processQueuedEventsForTest();

      final singleBatch = events.map((e) => '${app.namedId}_${e.namedId}').toList();
      final expected = <String>[
        for (var i = 0; i < replays + 1; i++) ...singleBatch,
      ];

      for (var i = 0; i < replays; i++) {
        app.replayRecordedEvents(filter: (e) => e is TestEvent);
        app.processQueuedEventsForTest();
      }

      expect(ids.toList(), equals(expected));
    });
    
    test('recorded check', () {
      void reset() {
        for (final holder in app.eventHistoryHolders.values) {
          if (holder is G) holder.clearEventQueue();
          holder.clearEventHistory();
        }
      }

      for (final entry in app.eventHistoryHolders.entries) {
        for (final scope in EventScope.values) {
          reset();

          final emitter = entry.key;
          final holder = entry.value;

          testEventPropagation(app,
            emitter: emitter,
            method: .emit,
            scope: scope,
          );

          final key = (emitter, scope);
          final expected = expectedReceivers[key]!;
          final int eventCount = expected.allEvents.length;
          final appEvents = app.getRecordedEvents(filter: (e) => e is TestEvent);
          final holderEvents = holder.getRecordedEvents(filter: (e) => e is TestEvent);

          expect(testCollector.length, equals(eventCount));
          expect(appEvents.length, equals(expected.appEventCount));
          expect(holderEvents.length, equals(expected.holderEventCount));
        }
      }
    });
  });
}

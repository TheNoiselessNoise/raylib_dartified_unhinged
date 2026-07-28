import 'package:raylib_dartified_unhinged/raylib_dartified_unhinged.dart';
import 'package:test/test.dart';

typedef _E<T extends App<T>> = ECSDeveloperTestingEvent<T>;

final Set<EmitterType> testCollector = {};
final Map<EmitterType, int> testCounts = {};

void addTestResult<T extends App<T>>(Event<T> event, EmitterType emitter) {
  if (event is! _E<T>) return;
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
  void onEvent(Event<T> event) => addTestResult(event, .app);
}

class TestEventPropagationResult {
  ExpectedValues expected = .new({}, 0, 0);
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

void fireEvent<T extends IsTestingApp<T>>(T app, EmitterType emitter, EventMethod method, EventScope scope, {
  bool reset = false,
}) {
  if (reset) {
    testCollector.clear();
    testCounts.clear();
  }

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
    case .emit:     emittable.emit(ECSDeveloperTestingEvent(app), scope: scope);
    case .dispatch: emittable.dispatch(ECSDeveloperTestingEvent(app), scope: scope);
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

  final key = (emitter, scope);
  result.expected = expectedReceivers[key]!;

  fireEvent(app, emitter, method, scope, reset: true);
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

  const ExpectedValues(this.allEvents, [this.appEventCount = 1, this.holderEventCount = 1]);
}

const Map<(EmitterType, EventScope), ExpectedValues> expectedReceivers = {

  (.app, .root):             .new({.app, .appSystem}),
  (.app, .rootAndLocal):     .new({.app, .appSystem}),
  (.app, .global):           .new({.app, .appSystem, .scene, .sceneSystem, .entity1, .comp1, .entity2, .comp2, .comp3}),
  (.app, .globalNoEntities): .new({.app, .appSystem, .scene, .sceneSystem}),
  (.app, .scene):            .new({.scene, .sceneSystem, .entity1, .comp1, .entity2, .comp2, .comp3}),
  (.app, .sceneOnly):        .new({.scene, .sceneSystem}),
  (.app, .local):            .new({.app, .appSystem}),
  (.app, .self):             .new({.app}),
    
  (.appSystem, .root):             .new({.app, .appSystem}),
  (.appSystem, .rootAndLocal):     .new({.app, .appSystem}),
  (.appSystem, .global):           .new({.app, .appSystem, .scene, .sceneSystem, .entity1, .comp1, .entity2, .comp2, .comp3}),
  (.appSystem, .globalNoEntities): .new({.app, .appSystem, .scene, .sceneSystem}),
  (.appSystem, .scene):            .new({.scene, .sceneSystem, .entity1, .comp1, .entity2, .comp2, .comp3}),
  (.appSystem, .sceneOnly):        .new({.scene, .sceneSystem}),
  (.appSystem, .local):            .new({.appSystem}),
  (.appSystem, .self):             .new({.appSystem}),
  
  (.scene, .root):             .new({.app, .appSystem}),
  (.scene, .rootAndLocal):     .new({.app, .appSystem, .scene, .sceneSystem}),
  (.scene, .global):           .new({.app, .appSystem, .scene, .sceneSystem, .entity1, .comp1, .entity2, .comp2, .comp3}),
  (.scene, .globalNoEntities): .new({.app, .appSystem, .scene, .sceneSystem}),
  (.scene, .scene):            .new({.scene, .sceneSystem, .entity1, .comp1, .entity2, .comp2, .comp3}),
  (.scene, .sceneOnly):        .new({.scene, .sceneSystem}),
  (.scene, .local):            .new({.scene, .sceneSystem}),
  (.scene, .self):             .new({.scene}),

  (.sceneSystem, .root):             .new({.app, .appSystem}),
  (.sceneSystem, .rootAndLocal):     .new({.app, .appSystem, .sceneSystem}),
  (.sceneSystem, .global):           .new({.app, .appSystem, .scene, .sceneSystem, .entity1, .comp1, .entity2, .comp2, .comp3}),
  (.sceneSystem, .globalNoEntities): .new({.app, .appSystem, .scene, .sceneSystem}),
  (.sceneSystem, .scene):            .new({.scene, .sceneSystem, .entity1, .comp1, .entity2, .comp2, .comp3}),
  (.sceneSystem, .sceneOnly):        .new({.scene, .sceneSystem}),
  (.sceneSystem, .local):            .new({.sceneSystem}),
  (.sceneSystem, .self):             .new({.sceneSystem}),

  (.entity1, .root):             .new({.app, .appSystem}),
  (.entity1, .rootAndLocal):     .new({.app, .appSystem, .entity1, .comp1}),
  (.entity1, .global):           .new({.app, .appSystem, .scene, .sceneSystem, .entity1, .comp1, .entity2, .comp2, .comp3}),
  (.entity1, .globalNoEntities): .new({.app, .appSystem, .scene, .sceneSystem}),
  (.entity1, .scene):            .new({.scene, .sceneSystem, .entity1, .comp1, .entity2, .comp2, .comp3}),
  (.entity1, .sceneOnly):        .new({.scene, .sceneSystem}),
  (.entity1, .local):            .new({.entity1, .comp1}),
  (.entity1, .self):             .new({.entity1}),

  (.comp1, .root):             .new({.app, .appSystem}),
  (.comp1, .rootAndLocal):     .new({.app, .appSystem, .comp1}),
  (.comp1, .global):           .new({.app, .appSystem, .scene, .sceneSystem, .entity1, .comp1, .entity2, .comp2, .comp3}),
  (.comp1, .globalNoEntities): .new({.app, .appSystem, .scene, .sceneSystem}),
  (.comp1, .scene):            .new({.scene, .sceneSystem, .entity1, .comp1, .entity2, .comp2, .comp3}),
  (.comp1, .sceneOnly):        .new({.scene, .sceneSystem}),
  (.comp1, .local):            .new({.comp1}),
  (.comp1, .self):             .new({.comp1}),

  (.entity2, .root):             .new({.app, .appSystem}),
  (.entity2, .rootAndLocal):     .new({.app, .appSystem, .entity2, .comp2, .comp3}),
  (.entity2, .global):           .new({.app, .appSystem, .scene, .sceneSystem, .entity1, .comp1, .entity2, .comp2, .comp3}),
  (.entity2, .globalNoEntities): .new({.app, .appSystem, .scene, .sceneSystem}),
  (.entity2, .scene):            .new({.scene, .sceneSystem, .entity1, .comp1, .entity2, .comp2, .comp3}),
  (.entity2, .sceneOnly):        .new({.scene, .sceneSystem}),
  (.entity2, .local):            .new({.entity2, .comp2, .comp3}),
  (.entity2, .self):             .new({.entity2}),

  (.comp2, .root):             .new({.app, .appSystem}),
  (.comp2, .rootAndLocal):     .new({.app, .appSystem, .comp2, .comp3}),
  (.comp2, .global):           .new({.app, .appSystem, .scene, .sceneSystem, .entity1, .comp1, .entity2, .comp2, .comp3}),
  (.comp2, .globalNoEntities): .new({.app, .appSystem, .scene, .sceneSystem}),
  (.comp2, .scene):            .new({.scene, .sceneSystem, .entity1, .comp1, .entity2, .comp2, .comp3}),
  (.comp2, .sceneOnly):        .new({.scene, .sceneSystem}),
  (.comp2, .local):            .new({.comp2, .comp3}),
  (.comp2, .self):             .new({.comp2}),

  (.comp3, .root):             .new({.app, .appSystem}),
  (.comp3, .rootAndLocal):     .new({.app, .appSystem, .comp3}),
  (.comp3, .global):           .new({.app, .appSystem, .scene, .sceneSystem, .entity1, .comp1, .entity2, .comp2, .comp3}),
  (.comp3, .globalNoEntities): .new({.app, .appSystem, .scene, .sceneSystem}),
  (.comp3, .scene):            .new({.scene, .sceneSystem, .entity1, .comp1, .entity2, .comp2, .comp3}),
  (.comp3, .sceneOnly):        .new({.scene, .sceneSystem}),
  (.comp3, .local):            .new({.comp3}),
  (.comp3, .self):             .new({.comp3}),
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
  void onEvent(Event<T> event) => addTestResult(event, .appSystem);
}

class TestSceneSystem<T extends App<T>> extends SceneSystem<T> {
  TestSceneSystem(super.app);

  @override
  void onEvent(Event<T> event) => addTestResult(event, .sceneSystem);
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
  void onEvent(Event<T> event) => addTestResult(event, .scene);
}

class TestComponent1<T extends App<T>> extends Comp<T> {
  TestComponent1(super.app);

  @override
  void onEvent(Event<T> event) => addTestResult(event, .comp1);
}

class TestEntity1<T extends App<T>> extends Entity<T> {
  late TestComponent1<T> comp1;

  TestEntity1(super.app) {
    addComp(comp1 = .new(app));
  }

  @override
  void onEvent(Event<T> event) => addTestResult(event, .entity1);
}

class TestComponent2<T extends App<T>> extends Comp<T> {
  late TestComponent3<T> comp3;

  TestComponent2(super.app);

  @override
  void onEvent(Event<T> event) => addTestResult(event, .comp2);
}

class TestEntity2<T extends App<T>> extends Entity<T> {
  late TestComponent2<T> comp2;

  TestEntity2(super.app) {
    addComp(comp2 = .new(app));
    comp2.addComp(comp2.comp3 = .new(app));
  }

  @override
  void onEvent(Event<T> event) => addTestResult(event, .entity2);
}

class TestComponent3<T extends App<T>> extends Comp<T> {
  TestComponent3(super.app);

  @override
  void onEvent(Event<T> event) => addTestResult(event, .comp3);
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

      List<ECSDeveloperTestingEvent<G>> events = List.generate(holders.length, (_) => .new(app));
      List<int> ids = events.map((e) => e.id).toList();

      for (final (i, emittable) in holders.values.indexed) {
        emittable.emit(events[i], scope: .self);
      }

      app.processQueuedEventsForTest();

      final historyEvents = app.eventHistory.whereType<ECSDeveloperTestingEvent>().toList();
      List<int> historyIds = historyEvents.map((e) => e.id).toList();

      expect(historyEvents.length, equals(holders.length));
      expect(historyIds, equals(ids));

      for (final (i, emittable) in holders.values.indexed) {
        if (emittable is TestApp) continue;

        final historyEvents = emittable.eventHistory.whereType<ECSDeveloperTestingEvent>().toList();
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
        final List<ECSDeveloperTestingEvent<G>> events = .generate(10, (_) => .new(app));        
        final expected = events.map((e) => '${holder.namedId}_${e.namedId}');

        for (final event in events) {
          holder.emit(event, scope: .self);
        }

        app.processQueuedEventsForTest();

        // current
        expect(ids.toList(), equals(expected));
        ids.clear();

        holder.replayRecordedEvents(filter: (e) => e is ECSDeveloperTestingEvent);
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

      final List<ECSDeveloperTestingEvent<G>> events = .generate(n, (_) => .new(app));
      events.forEach((e) => app.emit(e, scope: .self));
      app.processQueuedEventsForTest();

      final singleBatch = events.map((e) => '${app.namedId}_${e.namedId}').toList();
      final expected = <String>[
        for (var i = 0; i < replays + 1; i++) ...singleBatch,
      ];

      for (var i = 0; i < replays; i++) {
        app.replayRecordedEvents(filter: (e) => e is ECSDeveloperTestingEvent);
        app.processQueuedEventsForTest();
      }

      expect(ids.toList(), equals(expected));
    });
  });

  group('recorded check', () {
    late G app = .new(HeadlessBackend())..init()..clearEventQueue();

    void reset() {
      for (final entry in app.eventHistoryHolders.values) {
        if (entry is G) entry.clearEventQueue();
        entry.clearEventHistory();
      }
    }

    for (final entry in app.eventHistoryHolders.entries) {
      final emitter = entry.key;
      final holder = entry.value;

      for (final scope in EventScope.values) {
        for (final method in EventMethod.values) {
          test('method=${method.name} scope=${scope.name} emitter=${emitter.name}', () {
            reset();

            fireEvent(app, emitter, method, scope, reset: true);

            final key = (emitter, scope);
            final expected = expectedReceivers[key]!;
            final int eventCount = expected.allEvents.length;
            final appEvents = app.getRecordedEvents(filter: (e) => e is ECSDeveloperTestingEvent);
            final holderEvents = holder.getRecordedEvents(filter: (e) => e is ECSDeveloperTestingEvent);

            expect(testCollector.length, equals(eventCount), reason: 'WHAT: testCollector: ${testCollector.map((e) => e.name)}');
            expect(appEvents.length, equals(expected.appEventCount), reason: 'WHAT: appEvents');
            expect(holderEvents.length, equals(expected.holderEventCount), reason: 'WHAT: holderEvents');
          });
        }
      }
    }
  });

  group('event history replay', () {
    test('replaying app history before comp history compounds the replay count', () {
      late G app = .new(HeadlessBackend())..init()..clearEventQueue();

      final comp3 = app.testScene.entity2.comp2.comp3;

      // Single dispatch cycle: comp3 is origin, app is root.
      // This records exactly once at origin and once at root.
      // 1 event in each history.
      comp3.dispatch(ECSDeveloperTestingEvent(app), scope: .sceneOnly);

      expect(app.getRecordedEvents().length, equals(1));
      expect(comp3.getRecordedEvents().length, equals(1));

      // Replays everything currently in app's history (1 event: `e1`).
      // Replaying re-dispatches `e1` from its original origin (comp3), which
      // is a fresh dispatch cycle -> records once more at comp3 AND once
      // more at app.
      // 
      // After this call: app = [e1, e2], comp3 = [e1, e2].
      app.replayRecordedEvents();

      // Replays everything currently in comp3's history -- but comp3's
      // history was just mutated by the app.replayRecordedEvents() call
      // above, so this replays 2 events (e1, e2), not the 1 comp3 started
      // with. Each of those 2 replays is its own fresh dispatch cycle from
      // comp3, so it adds 2 more events to BOTH comp3's and app's history.
      // Final: app = [e1, e2, e3, e4], comp3 = [e1, e2, e3, e4].
      //
      // Call order matters here: app.replayRecordedEvents() runs first and
      // grows comp3's history as a side effect (comp3 is origin for every
      // event), so comp3.replayRecordedEvents() then has more to replay
      // than it would if the order were reversed.
      comp3.replayRecordedEvents();

      expect(app.getRecordedEvents().length, equals(4));
      expect(comp3.getRecordedEvents().length, equals(4));
    });
  });
}

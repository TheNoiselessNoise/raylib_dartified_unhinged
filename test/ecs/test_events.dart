import 'package:raylib_dartified_unhinged/raylib_dartified_unhinged.dart';
import 'package:test/test.dart';
import '../mocks.dart';

final Set<ResultType> testCollector = {};
final Map<ResultType, int> testCounts = {};

void addTestResult(ResultType emitter) {
  testCollector.add(emitter);
  testCounts[emitter] = testCounts.putIfAbsent(emitter, () => 0) + 1;
}

mixin IsTestingApp<T extends IsTestingApp<T>> on App<T> {
  TestEventsAppSystem<T> get appSystem;
  TestEventsScene<T> get testScene;

  List<IsAnyEventHistoryHolder<T>> get eventHistoryHolders => [
    app,
    app.appSystem,
    app.testScene,
    app.testScene.sceneSystem,
    app.testScene.entity1,
    app.testScene.entity1.comp1,
    app.testScene.entity2.comp2,
    app.testScene.entity2.comp2.comp3,
  ];

  @override
  void onEvent(Event<T> event) {
    if (event is TestEvent<T>) addTestResult(.app);
  }
}

void fireEvent<T extends IsTestingApp<T>>(T app, EmitterType emitter, EventMethod method, EventScope scope) {
  void doFire(IsAnyEventEmittable<T> emittable) {
    switch (method) {
      case .emit: emittable.emit(TestEvent(app), scope: scope);
      case .dispatch: emittable.dispatch(TestEvent(app), scope: scope);
    }
  }

  switch (emitter) {
    case .app:         doFire(app);
    case .appSystem:   doFire(app.appSystem);
    
    case .scene:       doFire(app.testScene);
    case .sceneSystem: doFire(app.testScene.sceneSystem);
    
    case .entity1:     doFire(app.testScene.entity1);
    case .comp1:       doFire(app.testScene.entity1.comp1);
    
    case .entity2:     doFire(app.testScene.entity2);
    case .comp2:       doFire(app.testScene.entity2.comp2);
    
    case .comp3:       doFire(app.testScene.entity2.comp2.comp3);
  }

  if (method == .emit) {
    app.processQueuedEventsForTest();
  }
}

class TestEventPropagationResult {
  Set<ResultType> expected = {};
  Set<(ResultType, int)> got = {};

  Set<ResultType> missing = {};
  Set<ResultType> extra = {};
  Set<(ResultType, int)> tooMany = {};

  bool get isValid => missing.isEmpty && extra.isEmpty && tooMany.isEmpty;

  String get reason => [
    '\nEXPECTED: ',
    expected.map((x) => '${x.name}(1)').join(', '),

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
  result.missing = result.expected.difference(testCollector);
  result.extra   = testCollector.difference(result.expected);

  for (final ex in testCounts.entries) {
    result.got.add((ex.key, ex.value));

    if (!result.expected.contains(ex.key)) continue;
    if (ex.value > 1) result.tooMany.add((ex.key, ex.value));
  }

  return result;
}

enum EventMethod {
  emit,
  dispatch,
}

enum ResultType {
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

const Map<(EmitterType, EventScope), Set<ResultType>> expectedReceivers = {

  (.app,         .global): {.app, .appSystem, .scene, .sceneSystem, .entity1, .comp1, .entity2, .comp2, .comp3},
  (.appSystem,   .global): {.app, .appSystem, .scene, .sceneSystem, .entity1, .comp1, .entity2, .comp2, .comp3},
  (.scene,       .global): {.app, .appSystem, .scene, .sceneSystem, .entity1, .comp1, .entity2, .comp2, .comp3},
  (.sceneSystem, .global): {.app, .appSystem, .scene, .sceneSystem, .entity1, .comp1, .entity2, .comp2, .comp3},
  (.entity1,     .global): {.app, .appSystem, .scene, .sceneSystem, .entity1, .comp1, .entity2, .comp2, .comp3},
  (.comp1,       .global): {.app, .appSystem, .scene, .sceneSystem, .entity1, .comp1, .entity2, .comp2, .comp3},
  (.entity2,     .global): {.app, .appSystem, .scene, .sceneSystem, .entity1, .comp1, .entity2, .comp2, .comp3},
  (.comp2,       .global): {.app, .appSystem, .scene, .sceneSystem, .entity1, .comp1, .entity2, .comp2, .comp3},
  (.comp3,       .global): {.app, .appSystem, .scene, .sceneSystem, .entity1, .comp1, .entity2, .comp2, .comp3},

  (.app,         .globalNoEntities): {.app, .appSystem, .scene, .sceneSystem},
  (.appSystem,   .globalNoEntities): {.app, .appSystem, .scene, .sceneSystem},
  (.scene,       .globalNoEntities): {.app, .appSystem, .scene, .sceneSystem},
  (.sceneSystem, .globalNoEntities): {.app, .appSystem, .scene, .sceneSystem},
  (.entity1,     .globalNoEntities): {.app, .appSystem, .scene, .sceneSystem},
  (.comp1,       .globalNoEntities): {.app, .appSystem, .scene, .sceneSystem},
  (.entity2,     .globalNoEntities): {.app, .appSystem, .scene, .sceneSystem},
  (.comp2,       .globalNoEntities): {.app, .appSystem, .scene, .sceneSystem},
  (.comp3,       .globalNoEntities): {.app, .appSystem, .scene, .sceneSystem},

  (.app,         .scene): {.scene, .sceneSystem, .entity1, .comp1, .entity2, .comp2, .comp3},
  (.appSystem,   .scene): {.scene, .sceneSystem, .entity1, .comp1, .entity2, .comp2, .comp3},
  (.scene,       .scene): {.scene, .sceneSystem, .entity1, .comp1, .entity2, .comp2, .comp3},
  (.sceneSystem, .scene): {.scene, .sceneSystem, .entity1, .comp1, .entity2, .comp2, .comp3},
  (.entity1,     .scene): {.scene, .sceneSystem, .entity1, .comp1, .entity2, .comp2, .comp3},
  (.comp1,       .scene): {.scene, .sceneSystem, .entity1, .comp1, .entity2, .comp2, .comp3},
  (.entity2,     .scene): {.scene, .sceneSystem, .entity1, .comp1, .entity2, .comp2, .comp3},
  (.comp2,       .scene): {.scene, .sceneSystem, .entity1, .comp1, .entity2, .comp2, .comp3},
  (.comp3,       .scene): {.scene, .sceneSystem, .entity1, .comp1, .entity2, .comp2, .comp3},

  (.app,         .sceneOnly): {.scene, .sceneSystem},
  (.appSystem,   .sceneOnly): {.scene, .sceneSystem},
  (.scene,       .sceneOnly): {.scene, .sceneSystem},
  (.sceneSystem, .sceneOnly): {.scene, .sceneSystem},
  (.entity1,     .sceneOnly): {.scene, .sceneSystem},
  (.comp1,       .sceneOnly): {.scene, .sceneSystem},
  (.entity2,     .sceneOnly): {.scene, .sceneSystem},
  (.comp2,       .sceneOnly): {.scene, .sceneSystem},
  (.comp3,       .sceneOnly): {.scene, .sceneSystem},

  (.app,         .local): {.app, .appSystem},
  (.appSystem,   .local): {.appSystem},
  (.scene,       .local): {.scene, .sceneSystem},
  (.sceneSystem, .local): {.sceneSystem},
  (.entity1,     .local): {.entity1, .comp1},
  (.comp1,       .local): {.comp1},
  (.entity2,     .local): {.entity2, .comp2, .comp3},
  (.comp2,       .local): {.comp2, .comp3},
  (.comp3,       .local): {.comp3},

  (.app,         .self): {.app},
  (.appSystem,   .self): {.appSystem},
  (.scene,       .self): {.scene},
  (.sceneSystem, .self): {.sceneSystem},
  (.entity1,     .self): {.entity1},
  (.comp1,       .self): {.comp1},
  (.entity2,     .self): {.entity2},
  (.comp2,       .self): {.comp2},
  (.comp3,       .self): {.comp3},
};

typedef G = TestEventsApp;

class TestEventsApp extends App<G> with IsTestingApp<G> {
  @override late TestEventsAppSystem<G> appSystem;
  @override late TestEventsScene<G> testScene;

  TestEventsApp(super.backend) {
    addSystem(appSystem = .new(app));
    addScene(testScene = .new(app));
  }
}

class TestEventsAppSystem<T extends App<T>> extends AppSystem<T> {
  TestEventsAppSystem(super.app);

  @override
  void onEvent(Event<T> event) {
    if (event is TestEvent<T>) addTestResult(.appSystem);
  }
}

class TestEventsSceneSystem<T extends App<T>> extends SceneSystem<T> {
  TestEventsSceneSystem(super.app);

  @override
  void onEvent(Event<T> event) {
    if (event is TestEvent<T>) addTestResult(.sceneSystem);
  }
}

class TestEventsScene<T extends App<T>> extends FWidgetScene<T> {
  late TestEventsSceneSystem<T> sceneSystem;
  late TestEventsEntity1<T> entity1;
  late TestEventsEntity2<T> entity2;

  TestEventsScene(super.app);

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

class TestEventsComponent1<T extends App<T>> extends Comp<T> {
  TestEventsComponent1(super.app);

  @override
  void onEvent(Event<T> event) {
    if (event is TestEvent<T>) addTestResult(.comp1);
  }
}

class TestEventsEntity1<T extends App<T>> extends Entity<T> {
  late TestEventsComponent1<T> comp1;

  TestEventsEntity1(super.app) {
    addComp(comp1 = .new(app));
  }

  @override
  void onEvent(Event<T> event) {
    if (event is TestEvent<T>) addTestResult(.entity1);
  }
}

class TestEventsComponent2<T extends App<T>> extends Comp<T> {
  late TestEventsComponent3<T> comp3;

  TestEventsComponent2(super.app);

  @override
  void onEvent(Event<T> event) {
    if (event is TestEvent<T>) addTestResult(.comp2);
  }
}

class TestEventsEntity2<T extends App<T>> extends Entity<T> {
  late TestEventsComponent2<T> comp2;

  TestEventsEntity2(super.app) {
    addComp(comp2 = .new(app));
    comp2.addComp(comp2.comp3 = .new(app));
  }

  @override
  void onEvent(Event<T> event) {
    if (event is TestEvent<T>) addTestResult(.entity2);
  }
}

class TestEventsComponent3<T extends App<T>> extends Comp<T> {
  TestEventsComponent3(super.app);

  @override
  void onEvent(Event<T> event) {
    if (event is TestEvent<T>) addTestResult(.comp3);
  }
}

void main() {
  group('Propagation', () {
    TestEventsApp app = buildApp(
      factory: () => .new(HeadlessBackend()),
    );

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
      TestEventsApp app = buildApp(
        factory: () => .new(HeadlessBackend()),
      );
      
      final holders = app.eventHistoryHolders;

      List<TestEvent<G>> events = List.generate(holders.length, (_) => .new(app));
      List<int> ids = events.map((e) => e.id).toList();

      for (final (i, emittable) in holders.indexed) {
        emittable.emit(events[i], scope: .self);
      }

      app.processQueuedEventsForTest();

      final historyEvents = app.eventHistory.whereType<TestEvent>().toList();
      List<int> historyIds = historyEvents.map((e) => e.id).toList();

      expect(historyEvents.length, equals(holders.length));
      expect(historyIds, equals(ids));

      for (final (i, emittable) in holders.indexed) {
        if (emittable is TestEventsApp) continue;

        final historyEvents = emittable.eventHistory.whereType<TestEvent>().toList();
        List<int> historyIds = historyEvents.map((e) => e.id).toList();

        expect(historyEvents.length, equals(1));
        expect(historyIds, equals([events[i].id]));
      }
    });
  });

  group('replaying', () {
    test('reproduces live self-scope delivery order per holder', () {
      TestEventsApp app = buildApp(
        factory: () => .new(HeadlessBackend()),
        clearInitEvents: true,
      );

      final holders = app.eventHistoryHolders;
      List<String> ids = [];

      for (final holder in holders) {
        holder.listenOnEvent((x, event) {
          ids.add('${x.namedId}_${event.namedId}');
        });
      }

      for (final holder in holders) {
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

    // TODO: replay multiple

    // TODO: recorded check
    /*
      IsAnyEventHistoryHolder<T> origin = switch (selectedType) {
        .app => app,
        .scene => this,
        .entity1 => entity1,
        .comp => entity1.comp1,
        .entity2 => entity2,
      };

      final originEvents = origin.getRecordedEvents();
      check('Origin (${selectedType.name}) has ${originEvents.length} events recorded.');

      final rootEvents = app.getRecordedEvents(origin: all ? null : origin);
      final originStr = all ? '' : ' (origin: ${selectedType.name})';
      check('Root$originStr has ${rootEvents.length} events recorded.');
    */
  });
}

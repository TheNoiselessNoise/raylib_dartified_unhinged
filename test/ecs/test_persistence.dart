import 'dart:convert';
import 'package:raylib_dartified_unhinged/raylib_dartified_unhinged.dart';
import 'package:test/test.dart';
import 'dart:math' show Random;

typedef G = TestApp;

final Random random = Random();
final int MAX_RANDOM_INT = 255;

mixin HasRandomValues<E extends ECSBase<G>> on IsPersistableBase<G, E> {
  abstract int intValue;
  abstract double doubleValue;

  List<num> get collect => [intValue, doubleValue];
  
  @override
  MapData getPersistableData({bool force = false}) => {
    ...super.getPersistableData(force: force),
    'intValue': intValue,
    'doubleValue': doubleValue,
  };

  @override
  void restorePersistableData(MapTraversable data, {String? id}) {
    super.restorePersistableData(data, id: id);
    intValue = data.getInt('intValue');
    doubleValue = data.getDouble('doubleValue');
  }
}

class TestComponent extends Comp<G> with HasRandomValues {
  @override int intValue;
  @override double doubleValue;

  TestComponent(super.app, {
    super.populateDefaults,
    this.intValue = 0,
    this.doubleValue = 0,
  });

  // persistence

  static String get typeId => '$TestComponent';
  
  @override
  String get persistentTypeId => typeId;
}

class TestEntity extends Entity<G> with HasRandomValues {
  @override int intValue;
  @override double doubleValue;

  TestEntity(super.app, {
    super.populateDefaults,
    this.intValue = 0,
    this.doubleValue = 0,
  }) {
    if (populateDefaults) {
      addComp(CTransform(app, position: screenSize.divideBy(2)));
      
      addComp(CPulse(app));

      addComp(TestComponent(app,
        intValue: random.nextInt(MAX_RANDOM_INT),
        doubleValue: random.nextDouble(),
      ));
    }
  }

  @override
  List<num> get collect => [
    ...super.collect,
    ...QueryComp.FirstAs<TestComponent>().collect,
  ];
  
  // persistence

  static String get typeId => '$TestEntity';
  
  @override
  String get persistentTypeId => typeId;
}

class TestScene extends Scene<G> with HasRandomValues {
  @override int intValue;
  @override double doubleValue;

  TestScene(super.app, {
    super.populateDefaults,
    this.intValue = 0,
    this.doubleValue = 0,
  }) {
    if (populateDefaults) {
      addEntity(TestEntity(app,
        intValue: random.nextInt(MAX_RANDOM_INT),
        doubleValue: random.nextDouble(),
      ));
    }
  }

  @override
  List<num> get collect => [
    ...super.collect,
    ...QueryEntity.FirstAs<TestEntity>().collect,
  ];
  
  // persistence

  static String get typeId => '$TestScene';
  
  @override
  String get persistentTypeId => typeId;
}

class TestApp extends App<G> with HasRandomValues {
  @override int intValue;
  @override double doubleValue;

  TestApp(super.backend, {
    super.populateDefaults,
    this.intValue = 0,
    this.doubleValue = 0,
  }) {
    factories.scene.register(TestScene.typeId, TestScene.new);
    factories.entity.register(TestEntity.typeId, TestEntity.new);
    factories.comp.register(TestComponent.typeId, TestComponent.new);

    if (populateDefaults) {
      addScene(TestScene(app,
        intValue: random.nextInt(MAX_RANDOM_INT),
        doubleValue: random.nextDouble(),
      ));
    }
  }

  @override
  List<num> get collect => [
    ...super.collect,
    ...getScene<TestScene>()!.collect,
  ];
}

void main() {
  group('Persistence', () {
    late TestApp app;

    setUp(() => app = TestApp(HeadlessBackend(),
      intValue: random.nextInt(MAX_RANDOM_INT),
      doubleValue: random.nextDouble(),
    ));

    test('save and restore whole app', () async {
      final data = app.getPersistableData();
      print(JsonEncoder.withIndent('  ').convert(data));
      final expectedValues = app.collect;
      
      final secondApp = TestApp(HeadlessBackend(), populateDefaults: false);
      secondApp.restorePersistableData(.new(data));
      final restoredValues = secondApp.collect;

      expect(expectedValues, equals(restoredValues));

      final restoredData = secondApp.getPersistableData();
      expect(jsonEncode(data), equals(jsonEncode(restoredData)));
    });
  });
}
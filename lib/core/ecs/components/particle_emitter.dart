part of '../../raylib_dartified_unhinged.dart';

typedef ParticleFactory<T extends App<T>> = Entity<T> Function(Scene<T> scene);
typedef ParticleInitializer<T extends App<T>> = void Function(Entity<T> e);

class CParticleEmitter<T extends App<T>> extends Comp<T> {

  double rate;
  ParticleFactory<T> factory;
  double _acc = 0;

  CParticleEmitter(super.app, {
    required this.rate,
    required this.factory,
  });

  void spawn({int count = 1}) {
    if (isDisabled) return;
    for (var i = 0; i < count; i++) {
      _spawnOne();
    }
  }

  @override
  void onUpdate(double dt) {
    if (isDisabled) return;
    _acc += dt * rate;
    while (_acc >= 1) {
      _acc -= 1;
      _spawnOne();
    }
  }

  void _spawnOne() {
    if (isDisabled) return;
    final e = factory(scene);
    command(AddEntityCommand(app, e));
  }

  // clone

  @override
  CParticleEmitter<T> createInstance() => .new(app,
    rate: rate,
    factory: factory,
  );

  // state

  @override
  CParticleEmitterSnapshot<T> createSnapshot() {
    final snapshot = CParticleEmitterSnapshot<T>(namedId);
    snapshot.rate = rate;
    snapshot.factory = factory;
    snapshot._acc = _acc;
    return snapshot;
  }

  @override
  @mustCallSuper
  void restoreSnapshot(covariant CParticleEmitterSnapshot<T> snapshot) {
    super.restoreSnapshot(snapshot);
    
    rate = snapshot.rate;
    factory = snapshot.factory;
    _acc = snapshot._acc;
  }
}

class CParticleEmitterSnapshot<T extends App<T>> extends CompSnapshot<T, CParticleEmitter<T>> {
  late double rate;
  late ParticleFactory<T> factory;
  late double _acc;
  
  CParticleEmitterSnapshot(super.namedId);

  @override
  CParticleEmitter<T> createInstance(T app) {
    final c = CParticleEmitter<T>(app,
      rate: rate,
      factory: factory,
    );
    c._acc = _acc;
    return c;
  }
}
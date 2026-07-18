part of '../../raylib_dartified_unhinged.dart';

typedef ParticleFactory<T extends App<T>, E extends Entity<T>> = E Function();
typedef ParticleTransform<T extends App<T>, E extends Entity<T>> = void Function(E instance);

typedef CAnyParticleEmitter<T extends App<T>> = CParticleEmitter<T, Entity<T>>;

class CParticleEmitter<T extends App<T>, E extends Entity<T>> extends Comp<T> {

  double rate;
  ParticleFactory<T, E> factory;
  double _acc = 0;

  CParticleEmitter(super.app, {
    required this.rate,
    required this.factory,
  });

  void spawn({
    int count = 1,
    ParticleFactory<T, E>? factory,
    ParticleTransform<T, E>? transform,
  }) {
    if (isDisabled) return;
    for (var i = 0; i < count; i++) _spawnOne(
      factory: factory ?? this.factory,
      transform: transform,
    );
  }

  @override
  void onUpdate(double dt) {
    if (isDisabled) return;
    _acc += dt * rate;
    while (_acc >= 1) {
      _acc -= 1;
      _spawnOne(factory: factory);
    }
  }

  void _spawnOne({
    required ParticleFactory<T, E> factory,
    ParticleTransform<T, E>? transform,
  }) {
    if (isDisabled) return;
    final instance = factory();
    transform?.call(instance);
    command(AddEntityCommand(app, instance));
  }

  // clone

  @override
  CParticleEmitter<T, E> createInstance() => .new(app,
    rate: rate,
    factory: factory,
  );

  // state

  @override
  CParticleEmitterSnapshot<T, E> createSnapshot() {
    final snapshot = CParticleEmitterSnapshot<T, E>(namedId);
    snapshot.rate = rate;
    snapshot.factory = factory;
    snapshot._acc = _acc;
    return snapshot;
  }

  @override
  @mustCallSuper
  void restoreSnapshot(covariant CParticleEmitterSnapshot<T, E> snapshot) {
    super.restoreSnapshot(snapshot);
    
    rate = snapshot.rate;
    factory = snapshot.factory;
    _acc = snapshot._acc;
  }
}

class CParticleEmitterSnapshot<T extends App<T>, E extends Entity<T>> extends CompSnapshot<T, CParticleEmitter<T, E>> {
  late double rate;
  late ParticleFactory<T, E> factory;
  late double _acc;
  
  CParticleEmitterSnapshot(super.namedId);

  @override
  CParticleEmitter<T, E> createInstance(T app) {
    final c = CParticleEmitter<T, E>(app,
      rate: rate,
      factory: factory,
    );
    c._acc = _acc;
    return c;
  }
}
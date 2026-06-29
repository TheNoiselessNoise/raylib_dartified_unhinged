part of '../../raylib_dartified_unhinged.dart';

// physics stuff
class CPhysicsBody<T extends App<T>> extends Comp<T> {
  /// 0 = infinite mass (immovable)
  double mass;

  /// Bounciness (0 = no bounce, 1 = perfect elastic)
  double restitution;

  // defaults to true for normal bodies, false for kinematic
  bool transferVelocity;

  CPhysicsBody(super.app, {
    this.mass = 1.0,
    this.restitution = 1.0,
    this.transferVelocity = true,
  });

  factory CPhysicsBody.kinematic(T app, {
    double mass = 0.0,
    double restitution = 1.0,
    bool transferVelocity = false,
  }) => .new(app,
    mass: 0,
    restitution: restitution,
    transferVelocity: transferVelocity,
  );

  double get invMass => mass <= 0 ? 0.0 : 1.0 / mass;

  // clone

  @override
  CPhysicsBody<T> createInstance() => .new(app,
    mass: mass,
    restitution: restitution,
    transferVelocity: transferVelocity,
  );

  // state

  @override
  CPhysicsBodySnapshot<T> createSnapshot() {
    final snapshot = CPhysicsBodySnapshot<T>(namedId);
    snapshot.mass = mass;
    snapshot.restitution = restitution;
    snapshot.transferVelocity = transferVelocity;
    return snapshot;
  }

  @override
  @mustCallSuper
  void restoreSnapshot(covariant CPhysicsBodySnapshot<T> snapshot) {
    super.restoreSnapshot(snapshot);
    
    mass = snapshot.mass;
    restitution = snapshot.restitution;
    transferVelocity = snapshot.transferVelocity;
  }
}

class CPhysicsBodySnapshot<T extends App<T>> extends CompSnapshot<T, CPhysicsBody<T>> {
  late double mass;
  late double restitution;
  late bool transferVelocity;
  
  CPhysicsBodySnapshot(super.namedId);

  @override
  CPhysicsBody<T> createInstance(T app) => .new(app,
    mass: mass,
    restitution: restitution,
    transferVelocity: transferVelocity,
  );
}
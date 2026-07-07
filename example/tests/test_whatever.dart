// Run it: dart run test_whatever.dart
import '_base.dart';
import 'dart:math' as math;

final Vector2D ENTITY_SIZE = .vec2(50, 50);
final String TAG_ENTITY1 = 'entity1';
final String TAG_ENTITY2 = 'entity2';
final String TAG_BULLET = 'bullet';

class CHealth extends Comp<G> {
  CHealth(super.app, {this.maxHealth = 100}) : currentHealth = maxHealth;

  final int maxHealth;
  int currentHealth;
  void Function()? onZero;

  void damage(int amount) {
    if (currentHealth <= 0) return;
    currentHealth = (currentHealth - amount).clamp(0, maxHealth);
    if (currentHealth == 0) onZero?.call();
  }
}

class CHealthBar extends Comp<G> {
  CHealthBar(super.app, {
    this.width = 50,
    this.height = 6,
    this.offsetY = 12,
    this.lerpSpeed = 6.0, // higher = snappier, lower = smoother/slower
  });

  final double width;
  final double height;
  final double offsetY;
  final double lerpSpeed;

  double? _displayHealth;

  @override
  void onUpdate(double dt) {
    final health = entity.get<CHealth>();
    if (health == null) return;

    _displayHealth ??= health.currentHealth.toDouble();

    final target = health.currentHealth.toDouble();
    final diff = target - _displayHealth!;

    // snap when close enough to avoid infinite asymptotic creep
    if (diff.abs() < 0.5) {
      _displayHealth = target;
    } else {
      _displayHealth = _displayHealth! + diff * (1 - math.exp(-lerpSpeed * dt));
    }
  }

  @override
  void onDraw(double dt) => entity.onBounds((b) {
    final health = entity.get<CHealth>();
    if (health == null || health.currentHealth <= 0 && (_displayHealth ?? 0) < 0.5) return;

    final shown = _displayHealth ?? health.currentHealth;
    final ratio = (shown / health.maxHealth).clamp(0.0, 1.0);

    rl.CoreD.DrawRectangle(
      b.left, b.top - offsetY, width, height, .DARKGRAY,
    );
    rl.CoreD.DrawRectangle(
      b.left, b.top - offsetY, width * ratio, height, .GREEN,
    );
  });
}

class CDeathAnim extends Comp<G> {
  CDeathAnim(super.app);

  static const double _duration = 0.5;
  double _elapsed = 0;

  @override
  void onAdd(ECSBase<G> parent) {
    entity.get<CRectCollider<G>>()?.setActive(false);
  }

  @override
  void onUpdate(double dt) {
    _elapsed += dt;
    if (_elapsed >= _duration) entity.removeThis();
  }

  @override
  void onDraw(double dt) => entity.onBounds((b) {
    final progress = (_elapsed / _duration).clamp(0.0, 1.0);
    final alpha = 255 * (1 - progress);
    final shrink = 1 - progress * 0.5;
    rl.CoreD.DrawRectangle(b.left, b.top, ENTITY_SIZE.x * shrink, ENTITY_SIZE.y * shrink, .color(255, 0, 0, alpha));
  });
}

class BulletExplosion extends Entity<G> {
  BulletExplosion(super.app, Vector2D position) {
    addComp(CTransform(app, position: position));
    addComp(CExplosionAnim(app));
  }
}

class CExplosionAnim extends Comp<G> {
  CExplosionAnim(super.app);

  static const double _duration = 0.25;
  static const double _maxRadius = 30;
  double _elapsed = 0;

  @override
  void onUpdate(double dt) {
    _elapsed += dt;
    if (_elapsed >= _duration) entity.removeThis();
  }

  @override
  void onDraw(double dt) {
    final progress = (_elapsed / _duration).clamp(0.0, 1.0);
    final radius = _maxRadius * progress;
    final alpha = 255 * (1 - progress);
    final pos = entity.worldPosition;
    rl.CoreD.DrawCircle(pos.x, pos.y, radius, .color(255, 140, 0, alpha));
  }
}

class Bullet extends Entity<G> {
  static const double _travelDuration = 0.6;
  static const double _wobbleAmplitude = 40;

  Vector2D? _start;
  double _elapsed = 0;

  Bullet(super.app) {
    addComp(CVelocity(app));
    addComp(CCircleCollider(app, tag: TAG_BULLET, radius: 10, debugColor: .YELLOW, debugDraw: true));
    addComp(CPhysicsBody.kinematic(app));
  }

  @override
  void onUpdate(double dt) => onTransform((t) {
    _start ??= t.position.copy();

    final dest = scene.QueryEntity.FirstAs<Entity2>();

    final target = dest.worldPosition.add(ENTITY_SIZE.scale(0.5));
    _elapsed += dt;
    final progress = (_elapsed / _travelDuration).clamp(0.0, 1.0);

    final eased = 1 - math.pow(1 - progress, 3);
    final direct = _start!.add(target.sub(_start!).scale(eased));

    final toTarget = target.sub(_start!);
    final len = math.sqrt(toTarget.x * toTarget.x + toTarget.y * toTarget.y);
    final Vector2D perp = len == 0 ? .vec2(0, 0) : .vec2(-toTarget.y / len, toTarget.x / len);
    final wobble = perp.scale(math.sin(progress * math.pi * 3) * _wobbleAmplitude * (1 - progress));

    t.position = direct.add(wobble);
  });
}

class Entity1 extends Entity<G> {
  Entity1(super.app) {
    // TOP-LEFT CORNER
    addComp(CTransform(app, position: ENTITY_SIZE.copy()));
    addComp(CMoveUpDown(app)); // it's here, because `update` is in insertion order
    addComp(CRectCollider(app, tag: TAG_ENTITY1, size: ENTITY_SIZE.copy(), debugColor: .RED, debugDraw: true));
    addComp(CParticleEmitter(app, rate: 0, factory: (_) => Bullet(app)..addComp(transform!.clone())));
  }
}

class CMoveUpDown extends Comp<G> {
  int speed = 5;

  CMoveUpDown(super.app);

  @override
  void onUpdate(double dt) => entity.onBounds((b) {
    final t = entity.transform!;

    final ny = t.position.y + speed;
    if (ny >= sceneHeight - ENTITY_SIZE.y || ny <= sceneBounds.top + ENTITY_SIZE.y) {
      speed *= -1;
    } else {
      t.position.y += speed;
    }
  });
}

class Entity2 extends Entity<G> {
  late AnyEntitySnapshot<G> _snapshot;

  Entity2(super.app) {
    // BOTTOM-RIGHT CORNER
    addComp(CTransform(app, position: sceneSize.sub(ENTITY_SIZE)));
    addComp(CMoveUpDown(app)..setActive(false)); // it's here, because `update` is in insertion order
    addComp(CRectCollider(app, tag: TAG_ENTITY2, size: ENTITY_SIZE.copy(), debugColor: .GREEN, debugDraw: true));
    addComp(CHealth(app, maxHealth: 100)..onZero = () {
      get<CMoveUpDown>()?.setActive(false);
      addComp(CDeathAnim(app));
    });
    addComp(CHealthBar(app));
    _snapshot = captureSnapshot();
  }

  @override
  void onAdd(ECSBase<G> parent) => get<CMoveUpDown>()?.setActive(true);

  // NOTE: required, so `createSnapshot` => `Snapshot.createInstance` => `Entity2` type
  @override
  Entity2Snapshot createSnapshot() => .new(namedId);

  @override
  void onRemove() {
    final newSelf = _snapshot.reconstruct(app);
    newSelf.transform!.position = transform!.position.copy();
    command(AddEntityCommand(app, newSelf));
  }
}

// NOTE: required, so `createSnapshot` => `Snapshot.createInstance` => `Entity2` type
class Entity2Snapshot extends AnyEntitySnapshot<G> {
  Entity2Snapshot(super.app);

  @override
  Entity2 createInstance(G app) => .new(app);
}

class WhateverCollisionSystem extends CollisionResolverSystem<G> {
  WhateverCollisionSystem(super.app);

  @override
  bool onBeforeCollision(ColliderCollision<G> collision) {
    return collision.hasTags(TAG_BULLET, TAG_ENTITY2);
  }

  @override
  void onCollision(ColliderCollision<G> collision) {
    final bulletEntity2 = collision.asEntities<Bullet, Entity2>();
    if (bulletEntity2 == null) return;
    final (bullet, entity2) = bulletEntity2;

    entity2.get<CHealth>()?.damage(10);
    command(AddEntityCommand(app, BulletExplosion(bullet.app, bullet.worldPosition)));
    bullet.removeThis();
  }
}

class TestWhateverScene extends FWidgetScene<G> {
  TestWhateverScene(super.app);

  @override
  void onStart() {
    addSystem(WhateverCollisionSystem(app));
    addEntity(Entity1(app));
    addEntity(Entity2(app));

    task(IntervalTask(app,
      interval: 1,
      actionUpdate: (_, _) {
        QueryEntity
          .FirstAs<Entity1>()
          .get<CParticleEmitter<G>>()
          ?.spawn(count: 1);
      }
    ));
  }

  @override
  void onDrawBackground() {
    int y = 10;
    for (final (i, e) in getEntities().indexed) {
      rl.CoreD.DrawText('$i) ${e.namedId}', 150, y, 20, .WHITE);
      y += 20;
    }
  }
}

typedef G = TestWhateverApp;

class TestWhateverApp extends ExampleRaylibApp<G> {
  TestWhateverApp(super.backend);

  @override
  void onInit() {
    rl.CoreD.InitWindow(screenWidth, screenHeight, "test_whatever");
    rl.CoreD.SetWindowMonitor(0);
    rl.CoreD.SetTargetFPS(60);

    addScene(TestWhateverScene(app));
  }
}

void main() => runExample((backend) => G(backend));
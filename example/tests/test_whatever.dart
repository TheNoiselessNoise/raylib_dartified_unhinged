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

class _DamagePopup {
  _DamagePopup(this.amount);
  final int amount;
  double age = 0;
}

class CHealthBar extends Comp<G> {
  CHealthBar(super.app, {
    this.width = 50,
    this.height = 6,
    this.offsetY = 12,
    this.lerpSpeed = 6.0,
    this.popupDuration = 0.9,   // total lifetime, seconds
    this.popupRise = 24.0,      // total distance floated upward
    this.popupFontSize = 14,
  });

  final double width;
  final double height;
  final double offsetY;
  final double lerpSpeed;
  final double popupDuration;
  final double popupRise;
  final int popupFontSize;

  double? _displayHealth;
  int? _lastHealth;
  final List<_DamagePopup> _popups = [];

  @override
  void onUpdate(double dt) {
    final health = entity.get<CHealth>();
    if (health == null) return;

    _displayHealth ??= health.currentHealth.toDouble();
    _lastHealth ??= health.currentHealth;

    // Detect damage taken since last frame.
    final delta = _lastHealth! - health.currentHealth;
    if (delta > 0) {
      _popups.add(_DamagePopup(delta));
    }
    _lastHealth = health.currentHealth;

    final target = health.currentHealth.toDouble();
    final diff = target - _displayHealth!;
    if (diff.abs() < 0.5) {
      _displayHealth = target;
    } else {
      _displayHealth = _displayHealth! + diff * (1 - math.exp(-lerpSpeed * dt));
    }

    // Age popups, drop the dead ones.
    for (final p in _popups) {
      p.age += dt;
    }
    _popups.removeWhere((p) => p.age >= popupDuration);
  }

  @override
  void onDraw(double dt) => entity.onBounds((b) {
    final health = entity.get<CHealth>();
    if (health == null || health.currentHealth <= 0 && (_displayHealth ?? 0) < 0.5) return;

    final shown = _displayHealth ?? health.currentHealth;
    final ratio = (shown / health.maxHealth).clamp(0.0, 1.0);

    rl.CoreD.DrawRectangle(b.left, b.top - offsetY, width, height, .DARKGRAY);
    rl.CoreD.DrawRectangle(b.left, b.top - offsetY, width * ratio, height, .GREEN);

    for (final p in _popups) {
      final t = (p.age / popupDuration).clamp(0.0, 1.0);

      // ease-out rise: fast at first, settles near the top
      final rise = popupRise * (1 - math.pow(1 - t, 2));
      // fade in fast, hold, fade out over the last third
      final alpha = t < 0.85 ? 1.0 : (1.0 - t) / 0.15;

      draw.text
        .fontSize(popupFontSize)
        .position(b.left + width / 2, b.top - offsetY - rise)
        .sentence()
          .text('-${p.amount}', rl.CoreD.Fade(.RED, alpha))
        .flush(halign: .center, valign: .bottom);
    }
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

  int damage = 0;

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
    addComp(CParticleEmitter<G, Bullet>(app, rate: 0, factory: () =>
      Bullet(app)..addComp(transform!.clone())
    ));
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
  Entity2(super.app) {
    // BOTTOM-RIGHT CORNER
    addComp(CTransform(app, position: sceneSize.sub(ENTITY_SIZE)));
    addComp(CMoveUpDown(app)..setActive(false)); // it's here, because `update` is in insertion order
    addComp(CRectCollider(app, tag: TAG_ENTITY2, size: ENTITY_SIZE.copy(), debugColor: .GREEN, debugDraw: true));
    addComp(CHealth(app, maxHealth: 100)..onZero = () {
      disableEverything();
      addComp(CDeathAnim(app));
    });
    addComp(CHealthBar(app));
  }

  @override
  void onAdd(ECSBase<G> parent) => get<CMoveUpDown>()?.setActive(true);

  @override
  void onRemove() {
    final newSelf = Entity2(app);
    newSelf.transform!.position = transform!.position.copy();
    command(AddEntityCommand(app, newSelf));
  }
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

    entity2.get<CHealth>()?.damage(bullet.damage);
    command(AddEntityCommand(app, BulletExplosion(bullet.app, bullet.worldPosition)));
    bullet.removeThis();
  }
}

class TestWhateverScene extends FWidgetScene<G> {
  TestWhateverScene(super.app);

  int bulletDamage = 10;

  @override
  void onStart() {
    addSystem(WhateverCollisionSystem(app));
    addEntity(Entity1(app));
    addEntity(Entity2(app));

    task(IntervalTask(app,
      interval: 0.5,
      actionUpdate: (_, _) {
        QueryEntity
          .FirstAs<Entity1>()
          .get<CParticleEmitter<G, Bullet>>()
          ?.spawn(count: 1, transform: (b) => b.damage = bulletDamage);
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

    draw.text
      .fontSize(64)
      .position(screenWidth / 2, screenHeight / 2)
      .align(.center, .middle)
      .text('$bulletDamage', .GOLD..a = 100);
  }

  @override
  void onInput() {
    final mouseDelta = rl.CoreD.GetMouseWheelMoveV();

    int up = 0;
    if (rl.CoreD.IsKeyDown(.KEY_W) && time.frameCount % 20 == 0) up = 1;
    if (mouseDelta.y > 0) up = (mouseDelta.y * 2).toInt();
    bulletDamage += up;
    
    int down = 0;
    if (rl.CoreD.IsKeyDown(.KEY_S) && time.frameCount % 20 == 0) down = 1;
    if (mouseDelta.y < 0) down = -(mouseDelta.y * 2).toInt();
    bulletDamage -= down;
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
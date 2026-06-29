// dart run arkanoid_test.dart
import 'package:raylib_dartified_unhinged/raylib_dartified_unhinged.dart';

/* =========================
  EVENTS
========================= */

class BallHitBrick extends Event<G> {
  final Entity<G> ball;
  final Entity<G> brick;
  BallHitBrick(super.app, this.ball, this.brick);
}

class BallLost extends Event<G> {
  final Entity<G> ball;
  BallLost(super.app, this.ball);
}

class LevelComplete extends Event<G> {
  LevelComplete(super.app);
}

/* =========================
  IDENTIFIERS
========================= */

class CIsPaddle extends Comp<G>    { CIsPaddle(super.app); }
class CIsBall extends Comp<G>      { CIsBall(super.app); }
class CIsBrick extends Comp<G>     { CIsBrick(super.app); }
class CIsDestroyed extends Comp<G> { CIsDestroyed(super.app); }

/* =========================
  GAME
========================= */

// NOTE: you MUST have your own game class
//       this is the minimal example required
//       Take it as a namespace for your universe.
typedef G = Arkanoid;
class Arkanoid extends App<G> {
  Arkanoid(super.rl);
}

class ArkanoidInline extends UnhingedRaylibGame<G> {
  @override
  G create(Raylib rl) => G(rl).onSelf((app) {

    final String K_q = 'q';
    final String K_r = 'r';
    final String K_left = 'left';
    final String K_right = 'right';
    final String K_up = 'up';
    final String K_down = 'down';

    app.input.mapKeys({
      K_q: .KEY_Q,
      K_r: .KEY_R,
      K_left: .KEY_A,
      K_right: .KEY_D,
      K_up: .KEY_W,
      K_down: .KEY_S,
    });

    app.listenOnInit((app) {
      rl.CoreD.InitWindow(800, 450, 'arkanoid_structure_first');
      rl.CoreD.SetWindowMonitor(0);
      rl.CoreD.SetTargetFPS(60);
    });

    app.listenShouldExit((app) => rl.CoreD.WindowShouldClose());

    /* =========================
      SCENE
    ========================= */

    app.addScene(DrawScene(app)
      .listenOnDrawBackground((scene, alpha) {
        rl.CoreD.DrawText('DUMB ARKANOID', 20, 20, 20, .WHITE);
        rl.CoreD.DrawFPS(50, app.screenHeight - 80);
      })
      .listenOnStart((scene) {
        scene.addSystem(CollisionResolverSystem(app));
        scene.addSystem(ScreenBounceSystem(app, bottom: false));

        /**
         * ARKANOID STATE & EVENT DISTRIBUTION ENTITY
         */

        scene.addEntity(
          Entity(app)
          .listenOnEvent((self, e) {
            if (e is EventCollision<G>) {
              final ballBrick = e.has<CIsBall, CIsBrick>();

              if (ballBrick != null) {
                final (ball, brick) = ballBrick;
                scene.emit(BallHitBrick(app, ball, brick), scope: .global);
              }
            }
          })
          .listenOnUpdate((self, dt) {
            // check if there are any bricks that have not been destroyed yet
            // if so, return
            if (scene.QueryEntity
              .With<CIsBrick>()
              .Except<CIsDestroyed>()
              .IsNotEmpty) return;

            // otherwise level completed
            scene.emit(LevelComplete(app), scope: .global);
          })
        );

        /**
         * PADDLE ENTITY
         */

        final varSpeed = VarKey<double>('speed');
        final varPoints = VarKey<int>('points');
        scene.addEntity(
          Entity(app)
          .addComp(CIsPaddle(app))
          .addComp(CTransform(app,
            position: .vec2(
              app.screenWidth / 2,
              app.screenHeight - 40,
            ),
          ))
          .addComp(CVelocity(app))
          .addComp(CPhysicsBody(app, mass: 0, restitution: 1))
          .addComp(CRectCollider(app,
            tag: 'paddle',
            size: .vec2(120, 20),
            debugDraw: true,
          ))
          .listenOnAdd((self, parent) {
            self.setVar(varSpeed, 600.0);
            self.setVar(varPoints, 0);
          })
          .listenOnUpdate((self, dt) => self.onVelocity((v) {
            v.velocity.x = 0;
            final speed = self.getVar(varSpeed);
            if (scene.input.isKeyDown(K_left)) v.velocity.x = -speed;
            if (scene.input.isKeyDown(K_right)) v.velocity.x = speed;
            if (scene.input.isKeyDown(K_up)) self.incVar(varSpeed, 100*dt);
            if (scene.input.isKeyDown(K_down)) self.decVar(varSpeed, 100*dt);
          }))
          .listenOnDraw((self, alpha) {
            final speed = self.getVar(varSpeed);
            final points = self.getVar(varPoints);
            rl.CoreD.DrawText('Speed: ${speed.f2}', 50, app.screenHeight - 160, 20, .WHITE);
            rl.CoreD.DrawText('Points: $points', 50, app.screenHeight - 140, 20, .WHITE);
          })
          .listenOnEvent((self, e) {
            if (e is BallLost) {
              self.decVar(varPoints, 100);
            }
            if (e is BallHitBrick) {
              self.incVar(varPoints, 10);
            }
          })
        );

        /**
         * BALL ENTITY
         */

        scene.addEntity(Entity(app)
          .addComp(CIsBall(app))
          .addComp(CTransform(app,
            position: .vec2(
              app.screenWidth / 2,
              app.screenHeight / 2,
            ),
          ))
          .addComp(CVelocity(app,
            velocity: .vec2(rl.CoreD.GetRandomValue(-100, 100), -300),
            linearDamping: 0,
          ))
          .addComp(CPhysicsBody(app, mass: 1.0, restitution: 1.0))
          .addComp(CCircleCollider(app, radius: 8, debugDraw: true))
          .addComp(COutOfBounds(app,
            then: (c) {
              c.entity.onTransform((t) => t.position.set(app.screenWidth / 2, app.screenHeight - 150));
              c.entity.onVelocity((v) => v.velocity.y = -v.velocity.y.abs());
            }
          ))
          .listenOnUpdate((self, dt) => self.onTransform((t) {
            if (scene.input.isKeyDown(K_r)) {
              self.onTransform((t) => t.position.set(app.screenWidth / 2, app.screenHeight - 150));
              self.onVelocity((v) => v.velocity.y = -v.velocity.y.abs());
            }
          }))
          .listenOnEvent((self, e) {
            if (e is BallHitBrick) {
              e.brick.addComp(CIsDestroyed(app));
              e.brick.disableComps();
              e.stopPropagation();
            }
          })
        );

        /**
         * BRICK ENTITIES
         */

        for (int y = 0; y < 4; y++) {
          for (int x = 0; x < 10; x++) {
            scene.addEntity(
              Entity(app)
              .onSelf((e) => e..name = 'BRICK_${e.id}')
              .addComp(CIsBrick(app))
              .addComp(CTransform(app,
                position: .vec2(80 + x * 65, 60 + y * 30)
              ))
              .addComp(CRectCollider(app,
                tag: 'brick',
                size: .vec2(60, 20),
                debugDraw: true,
                debugColor: .ORANGE,
              ))
              .addComp(CPhysicsBody(app, mass: 0, restitution: 1))
              .listenOnUpdate((self, dt) {
                self.on<CRectCollider<G>>((c) {
                  final frameCount = app.time.frameCount;
                  if (frameCount == 1 || frameCount % 100 == 0) {
                    c.debugColor = .color(
                      rl.random.nextInt(156) + 100,
                      rl.random.nextInt(156) + 100,
                      rl.random.nextInt(156) + 100,
                      rl.random.nextInt(156) + 100,
                    );
                  }
                });
              })
              .listenOnEvent((self, e) {
                if (e is LevelComplete) {
                  self.removeComp<CIsDestroyed>();
                  self.enableEverything();
                }
              })
            );
          }
        }
      }
    ));

    app.listenHandleInput((self) {
      if (self.input.isKeyPressed(K_q)) {
        self.command(ExitAppCommand(app));
      }
    });
  });
}

void main() => runRaylib(
  ArkanoidInline(),
  nativeLibPath: 'raylib-5.5_linux_amd64/lib'
);
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(
    MaterialApp(
      home: GameWidget<MouseJointExample>.controlled(
        gameFactory: MouseJointExample.new,
      ),
    ),
  );
}

class MouseJointExample extends Forge2DGame with HasKeyboardHandlerComponents {
  late MouseJointWorld gameWorld;

  MouseJointExample() : super(gravity: Vector2(0, 10.0)) {
    gameWorld = MouseJointWorld();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    world = gameWorld; // Set the world
  }

  // Keyboard shortcuts (optional)
  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (keysPressed.contains(LogicalKeyboardKey.space)) {
      gameWorld.spawnBallRain(5);
      return KeyEventResult.handled;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyC)) {
      gameWorld.clearAllBalls();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }
}

class MouseJointWorld extends Forge2DWorld
    with DragCallbacks, HasGameReference<Forge2DGame> {
  final List<Ball> balls = [];
  late Body groundBody;
  MouseJoint? mouseJoint;
  Ball? selectedBall;

  // Ball spawning variables
  final Random random = Random();
  late TimerComponent ballSpawner;
  final int maxBalls = 50;
  final double spawnInterval = 0.5;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Create boundaries WITHOUT the top wall
    final boundaries = createBoundariesWithoutTop(game);
    addAll(boundaries);

    final groundBodyDef = BodyDef();
    groundBody = createBody(groundBodyDef);

    // Start spawning balls automatically
    startBallSpawning();

    // Spawn initial batch of balls
    spawnInitialBalls(5);
  }

  void startBallSpawning() {
    ballSpawner = TimerComponent(
      period: spawnInterval,
      repeat: true,
      onTick: () {
        if (balls.length < maxBalls) {
          spawnRandomBall();
        }
      },
    );
    add(ballSpawner);
  }

  void spawnInitialBalls(int count) {
    for (int i = 0; i < count; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (balls.length < maxBalls) {
          spawnRandomBall();
        }
      });
    }
  }

  void spawnRandomBall() {
    final visibleRect = game.camera.visibleWorldRect;

    final randomX = visibleRect.left + random.nextDouble() * visibleRect.width;
    // Spawn balls well above the visible area so they fall in
    final spawnY = visibleRect.top - 10;

    final radius = 2.0 + random.nextDouble() * 6.0;

    final ball = Ball(Vector2(randomX, spawnY), radius: radius);

    balls.add(ball);
    add(ball);

    // Add some random horizontal velocity
    Future.delayed(Duration(milliseconds: 100), () {
      if (ball.isMounted) {
        final horizontalForce = (random.nextDouble() - 0.5) * 200;
        ball.body.applyLinearImpulse(Vector2(horizontalForce, 0));
      }
    });
  }

  void spawnBallRain(int count) {
    for (int i = 0; i < count && balls.length < maxBalls; i++) {
      spawnRandomBall();
    }
  }

  void cleanupOffscreenBalls() {
    final visibleRect = game.camera.visibleWorldRect;
    final ballsToRemove = <Ball>[];

    for (final ball in balls) {
      if (ball.body.position.y > visibleRect.bottom + 50) {
        ballsToRemove.add(ball);
      }
    }

    for (final ball in ballsToRemove) {
      balls.remove(ball);
      ball.removeFromParent();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (balls.length > 10) {
      cleanupOffscreenBalls();
    }
  }

  Ball? findBallAtPosition(Vector2 position) {
    Ball? closestBall;
    double closestDistance = double.infinity;

    for (final ball in balls) {
      final distance = (ball.body.position - position).length;
      if (distance < ball.radius && distance < closestDistance) {
        closestDistance = distance;
        closestBall = ball;
      }
    }

    return closestBall;
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (mouseJoint != null) {
      return;
    }

    selectedBall = findBallAtPosition(event.localPosition);
    if (selectedBall == null) return;

    final mouseJointDef = MouseJointDef()
      ..maxForce = 3000 * selectedBall!.body.mass * 10
      ..dampingRatio = 0.1
      ..frequencyHz = 5
      ..target.setFrom(selectedBall!.body.position)
      ..collideConnected = false
      ..bodyA = groundBody
      ..bodyB = selectedBall!.body;

    mouseJoint = MouseJoint(mouseJointDef);
    createJoint(mouseJoint!);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    mouseJoint?.setTarget(event.localEndPosition);
  }

  @override
  void onDragEnd(DragEndEvent info) {
    super.onDragEnd(info);
    if (mouseJoint != null) {
      destroyJoint(mouseJoint!);
      mouseJoint = null;
      selectedBall = null;
    }
  }

  void clearAllBalls() {
    for (final ball in balls) {
      ball.removeFromParent();
    }
    balls.clear();
  }
}

// Ball component
class Ball extends BodyComponent {
  final Vector2 _position;
  final double radius;

  Ball(this._position, {this.radius = 2.0});

  @override
  Body createBody() {
    final bodyDef = BodyDef()
      ..type = BodyType.dynamic
      ..position.setFrom(_position);

    final body = world.createBody(bodyDef);
    final shape = CircleShape()..radius = radius;
    final fixtureDef = FixtureDef(shape)
      ..density = 1.0
      ..friction = 0.4
      ..restitution = 0.8;

    body.createFixture(fixtureDef);
    return body;
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset.zero, radius, paint);

    final borderPaint = Paint()
      ..color = Colors.deepOrange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.2;

    canvas.drawCircle(Offset.zero, radius, borderPaint);
  }
}

// Wall component
class Wall extends BodyComponent {
  final Vector2 _start;
  final Vector2 _end;

  Wall(this._start, this._end);

  @override
  Body createBody() {
    final bodyDef = BodyDef()..type = BodyType.static;
    final body = world.createBody(bodyDef);

    final shape = EdgeShape()..set(_start, _end);
    final fixtureDef = FixtureDef(shape)..friction = 0.3;

    body.createFixture(fixtureDef);
    return body;
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 0.4
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(_start.x, _start.y), Offset(_end.x, _end.y), paint);
  }
}

// Modified boundary creation - WITHOUT top wall
List<Wall> createBoundariesWithoutTop(Forge2DGame game) {
  final visibleRect = game.camera.visibleWorldRect;
  final topRight = visibleRect.topRight.toVector2();
  final bottomLeft = visibleRect.bottomLeft.toVector2();
  final bottomRight = visibleRect.bottomRight.toVector2();
  final topLeft = visibleRect.topLeft.toVector2();

  return [
    // No top wall - balls can fall in from above
    Wall(topRight, bottomRight), // Right wall
    Wall(bottomRight, bottomLeft), // Bottom wall
    Wall(bottomLeft, topLeft), // Left wall
  ];
}

// Alternative: Create boundaries with an invisible top (if you want to keep the function name)
List<Wall> createBoundaries(Forge2DGame game) {
  return createBoundariesWithoutTop(game);
}

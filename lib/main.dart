import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:suika_forge2d/ball.dart';
import 'package:suika_forge2d/basket.dart';
import 'package:suika_forge2d/wall.dart';

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
    world = gameWorld;
  }

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
  final List<BallWithSprite> balls = [];
  late Body groundBody;
  MouseJoint? mouseJoint;
  BallWithSprite? selectedBall;

  final Random random = Random();
  late TimerComponent ballSpawner;
  final int maxBalls = 5;
  final double spawnInterval = 10;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    final boundaries = createBoundariesWithoutTop(game);
    addAll(boundaries);

    add(BasketSprite(Vector2(8.5, 0)));
    add(BasketSprite(Vector2(-8.5, 0)));

    final groundBodyDef = BodyDef();
    groundBody = createBody(groundBodyDef);
    startBallSpawning();
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
    final leftLimit = visibleRect.left + 10;
    final rightLimit = visibleRect.right - 10;
    final randomX = leftLimit + random.nextDouble() * (rightLimit - leftLimit);
    final spawnY = visibleRect.top - 10;
    final radius = 2.0 + random.nextDouble() * 1.0;
    final ball = BallWithSprite(Vector2(randomX, spawnY), radius: radius);
    balls.add(ball);
    add(ball);
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
    final ballsToRemove = <BallWithSprite>[];
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

  BallWithSprite? findBallAtPosition(Vector2 position) {
    BallWithSprite? closestBall;
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

List<Wall> createBoundariesWithoutTop(Forge2DGame game) {
  final visibleRect = game.camera.visibleWorldRect;
  final topRight = visibleRect.topRight.toVector2();
  final bottomLeft = visibleRect.bottomLeft.toVector2();
  final bottomRight = visibleRect.bottomRight.toVector2();
  final topLeft = visibleRect.topLeft.toVector2();

  return [
    Wall(topRight - Vector2(10, 0), bottomRight - Vector2(10, 0)),
    Wall(bottomRight, bottomLeft),
    Wall(bottomLeft - Vector2(-10, 0), topLeft - Vector2(-10, 0)),
  ];
}

List<Wall> createBoundaries(Forge2DGame game) {
  return createBoundariesWithoutTop(game);
}

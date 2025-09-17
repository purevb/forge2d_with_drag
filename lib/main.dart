import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      home: GameWidget<MouseJointExample>.controlled(
        gameFactory: MouseJointExample.new,
      ),
    ),
  );
}

class MouseJointExample extends Forge2DGame {
  static const description = '''
    In this example we use a MouseJoint to make the ball follow the mouse
    when you drag it around.
  ''';

  MouseJointExample()
    : super(gravity: Vector2(0, 10.0), world: MouseJointWorld());
}

class MouseJointWorld extends Forge2DWorld
    with DragCallbacks, HasGameReference<Forge2DGame> {
  late Ball ball;
  late Body groundBody;
  MouseJoint? mouseJoint;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Create boundaries
    final boundaries = createBoundaries(game);
    addAll(boundaries);

    // Create ground body for mouse joint
    final groundBodyDef = BodyDef();
    groundBody = createBody(groundBodyDef);

    // Create ball at center
    final center = Vector2.zero();
    ball = Ball(center, radius: 5);
    add(ball);

    // Add some ramps for fun
    add(CornerRamp(center));
    add(CornerRamp(center, isMirrored: true));
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (mouseJoint != null) {
      return;
    }

    final mouseJointDef = MouseJointDef()
      ..maxForce = 3000 * ball.body.mass * 10
      ..dampingRatio = 0.1
      ..frequencyHz = 5
      ..target.setFrom(ball.body.position)
      ..collideConnected = false
      ..bodyA = groundBody
      ..bodyB = ball.body;

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
    }
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

    // Border
    final borderPaint = Paint()
      ..color = Colors.deepOrange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.2;

    canvas.drawCircle(Offset.zero, radius, borderPaint);
  }
}

// Corner ramp component
class CornerRamp extends BodyComponent {
  final Vector2 _position;
  final bool isMirrored;

  CornerRamp(this._position, {this.isMirrored = false});

  @override
  Body createBody() {
    final bodyDef = BodyDef()
      ..type = BodyType.static
      ..position.setFrom(_position);

    final body = world.createBody(bodyDef);

    final vertices = <Vector2>[
      Vector2(-20, 0),
      Vector2(-20, -10),
      Vector2(20, -10),
      Vector2(20, 0),
    ];

    if (isMirrored) {
      for (final vertex in vertices) {
        vertex.x *= -1;
      }
    }

    final shape = PolygonShape()..set(vertices);
    final fixtureDef = FixtureDef(shape)..friction = 0.3;

    body.createFixture(fixtureDef);
    return body;
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;

    final path = Path();
    final vertices = [
      Offset(-20, 0),
      Offset(-20, -10),
      Offset(20, -10),
      Offset(20, 0),
    ];

    if (isMirrored) {
      for (int i = 0; i < vertices.length; i++) {
        vertices[i] = Offset(-vertices[i].dx, vertices[i].dy);
      }
    }

    path.moveTo(vertices[0].dx, vertices[0].dy);
    for (int i = 1; i < vertices.length; i++) {
      path.lineTo(vertices[i].dx, vertices[i].dy);
    }
    path.close();

    canvas.drawPath(path, paint);
  }
}

// Boundary creation utility
List<Wall> createBoundaries(Forge2DGame game) {
  final visibleRect = game.camera.visibleWorldRect;
  final topLeft = visibleRect.topLeft.toVector2();
  final topRight = visibleRect.topRight.toVector2();
  final bottomLeft = visibleRect.bottomLeft.toVector2();
  final bottomRight = visibleRect.bottomRight.toVector2();

  return [
    Wall(topLeft, topRight), // Top
    Wall(topRight, bottomRight), // Right
    Wall(bottomRight, bottomLeft), // Bottom
    Wall(bottomLeft, topLeft), // Left
  ];
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

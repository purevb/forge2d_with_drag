import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_forge2d/body_component.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';

class BallWithSprite extends BodyComponent {
  final Vector2 _position;
  final double radius;
  late Sprite ballSprite;
  bool _spriteLoaded = false;

  BallWithSprite(this._position, {this.radius = 2.0});
  List<String> fruits = [
    'apple',
    'bananas',
    'fruit',
    'passion-fruit',
    'pineapple',
    'watermelon',
  ];
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    Random rand = Random();
    ballSprite = await game.loadSprite(
      '${fruits[rand.nextInt(fruits.length)]}.png',
    );
    _spriteLoaded = true;
  }

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
    if (_spriteLoaded) {
      ballSprite.render(
        canvas,
        position: Vector2(-radius, -radius),
        size: Vector2(radius * 2, radius * 2),
      );
    } else {
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
}

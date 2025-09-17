import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_forge2d/body_component.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';

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

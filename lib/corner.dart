// Corner ramp component
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_forge2d/body_component.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';

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

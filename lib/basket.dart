import 'package:flame/components.dart';
import 'package:flame_forge2d/body_component.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

class BasketSprite extends BodyComponent {
  final Vector2 position;
  late SpriteComponent spriteComponent;

  // Basket size
  final Vector2 size = Vector2(5, 5);

  BasketSprite(this.position);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final sprite = await game.loadSprite("basket.png");
    spriteComponent = SpriteComponent(
      sprite: sprite,
      size: size,
      anchor: Anchor.center,
    );
    add(spriteComponent);
  }

  @override
  Body createBody() {
    // Create
    final bodyDef = BodyDef()
      ..type = BodyType.static
      ..position.setFrom(position);

    final body = world.createBody(bodyDef);

    final shape = PolygonShape()..setAsBoxXY(size.x / 4, size.y / 2);

    final fixtureDef = FixtureDef(shape)
      ..density = 1.0
      ..friction = 0.4
      ..restitution = 0.3;

    body.createFixture(fixtureDef);
    return body;
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Make sprite follow the physics body
    spriteComponent.position = body.position;
    spriteComponent.angle = body.angle;
  }

  @override
  bool get renderBody => false; // hide debug body
}

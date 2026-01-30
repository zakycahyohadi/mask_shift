import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(GameWidget(game: MaskShiftGame()));
}

class MaskShiftGame extends FlameGame with HasKeyboardHandlerComponents, HasCollisionDetection {
  @override
  Future<void> onLoad() async {
    // 1. Tambahkan Lantai-lantai (Sekarang bisa bertingkat!)
    add(Platform(Vector2(0, 550), Vector2(1200, 50))); 
    add(Platform(Vector2(400, 400), Vector2(200, 20))); // Platform gantung
    
    // 2. Tambahkan Player
    add(Player(Vector2(100, 300)));
    
    // 3. Tambahkan Topeng
    add(MaskItem(Vector2(450, 350), Colors.blue, 'light'));
    add(MaskItem(Vector2(800, 480), Colors.red, 'heavy'));
  }
}

// --- CLASS PLAYER DENGAN GAMBAR (SPRITE) ---
class Player extends SpriteComponent with KeyboardHandler, HasGameRef<MaskShiftGame>, CollisionCallbacks {
  Vector2 velocity = Vector2.zero();
  double gravity = 1000;
  double jumpSpeed = -500;
  double moveSpeed = 300;
  int horizontalInput = 0;
  bool isOnGround = false;

  Player(Vector2 pos) : super(position: pos, size: Vector2(64, 110)); // Ukuran disesuaikan dengan karakter pixel art tadi

  @override
  Future<void> onLoad() async {
    sprite = await gameRef.loadSprite('asset/images/Main Character.png'); // Pastikan file ada di assets/images/
    add(RectangleHitbox(
      size: Vector2(size.x * 0.4, size.y), // Hitbox ramping biar gak gampang nyangkut
      position: Vector2(size.x * 0.3, 0),
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Gerak Kiri-Kanan
    velocity.x = horizontalInput * moveSpeed;
    
    // Gravitasi & Posisi
    velocity.y += gravity * dt;
    position += velocity * dt;

    // Flip Karakter (Menghadap arah jalan)
    if (horizontalInput > 0 && scale.x < 0) {
      flipHorizontallyAroundCenter();
    } else if (horizontalInput < 0 && scale.x > 0) {
      flipHorizontallyAroundCenter();
    }
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    horizontalInput = 0;
    horizontalInput += keysPressed.contains(LogicalKeyboardKey.keyA) ? -1 : 0;
    horizontalInput += keysPressed.contains(LogicalKeyboardKey.keyD) ? 1 : 0;

    if (keysPressed.contains(LogicalKeyboardKey.space) && isOnGround) {
      velocity.y = jumpSpeed;
      isOnGround = false;
    }
    return true;
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    
    if (other is Platform) {
      // Logika berdiri di atas platform (bukan cuma di y=500)
      if (velocity.y > 0 && position.y + size.y * 0.9 < other.position.y) {
        position.y = other.position.y - size.y;
        velocity.y = 0;
        isOnGround = true;
      }
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is MaskItem) {
      if (other.type == 'light') {
        applyPowerUp(300, -750, Colors.blue);
      } else if (other.type == 'heavy') {
        applyPowerUp(2500, -300, Colors.red);
      }
      other.removeFromParent();
    }
  }

  void applyPowerUp(double newGravity, double newJump, Color color) {
    gravity = newGravity;
    jumpSpeed = newJump;
    // Beri efek warna pada karakter saat pakai topeng
    paint.colorFilter = ColorFilter.mode(color.withOpacity(0.4), BlendMode.srcATop);

    Future.delayed(Duration(seconds: 5), () {
      gravity = 1000;
      jumpSpeed = -500;
      paint.colorFilter = null;
    });
  }
}

// --- CLASS LANTAI ---
class Platform extends RectangleComponent with CollisionCallbacks {
  Platform(Vector2 pos, Vector2 size) : super(
    position: pos, 
    size: size, 
    paint: Paint()..color = Colors.green.withOpacity(0.5)
  ) {
    add(RectangleHitbox());
  }
}

// --- CLASS TOPENG ---
class MaskItem extends RectangleComponent with CollisionCallbacks {
  final String type;
  MaskItem(Vector2 pos, Color color, this.type) : super(
    position: pos, 
    size: Vector2(30, 30), 
    paint: Paint()..color = color
  ) {
    add(RectangleHitbox());
  }
}
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
    // Tambahkan Lantai
    add(Platform(Vector2(0, 550), Vector2(1200, 50)));
    
    // Tambahkan Player
    add(Player(Vector2(100, 300)));
    
    // Tambahkan Topeng Biru (Ringan) di tengah jalan
    add(MaskItem(Vector2(400, 480), Colors.blue, 'light'));
    
    // Tambahkan Topeng Merah (Berat) lebih jauh
    add(MaskItem(Vector2(700, 480), Colors.red, 'heavy'));
  }
}

// --- CLASS PLAYER ---
class Player extends RectangleComponent with KeyboardHandler, HasGameRef<MaskShiftGame>, CollisionCallbacks {
  Vector2 velocity = Vector2.zero();
  double gravity = 1000;
  double jumpSpeed = -500;
  double moveSpeed = 300;
  int horizontalInput = 0;
  bool isOnGround = false;

  Player(Vector2 pos) : super(
    position: pos, 
    size: Vector2(50, 50), 
    paint: Paint()..color = Colors.white
  );

  @override
  Future<void> onLoad() async {
    // Tambahkan hitbox supaya bisa tabrakan
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Input Gerak Horizontal
    velocity.x = horizontalInput * moveSpeed;
    
    // Gravitasi
    velocity.y += gravity * dt;
    position += velocity * dt;

    // Batas bawah sementara (Ground simple logic)
    if (position.y > 500) {
      position.y = 500;
      velocity.y = 0;
      isOnGround = true;
    } else {
      isOnGround = false;
    }
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    horizontalInput = 0;
    horizontalInput += keysPressed.contains(LogicalKeyboardKey.keyA) ? -1 : 0;
    horizontalInput += keysPressed.contains(LogicalKeyboardKey.keyD) ? 1 : 0;

    if (keysPressed.contains(LogicalKeyboardKey.space) && isOnGround) {
      velocity.y = jumpSpeed;
    }
    return true;
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    
    if (other is MaskItem) {
      if (other.type == 'light') {
        applyPowerUp(300, -700, Colors.blue); // Jadi Ringan & Lompat Tinggi
      } else if (other.type == 'heavy') {
        applyPowerUp(2000, -300, Colors.red); // Jadi Berat & Lompat Pendek
      }
      other.removeFromParent(); // Hapus topeng setelah diambil
    }
  }

  void applyPowerUp(double newGravity, double newJump, Color color) {
    gravity = newGravity;
    jumpSpeed = newJump;
    paint.color = color;

    // Balik normal setelah 5 detik
    Future.delayed(Duration(seconds: 5), () {
      gravity = 1000;
      jumpSpeed = -500;
      paint.color = Colors.white;
    });
  }
}

// --- CLASS LANTAI ---
class Platform extends RectangleComponent with CollisionCallbacks {
  Platform(Vector2 pos, Vector2 size) : super(
    position: pos, 
    size: size, 
    paint: Paint()..color = Colors.green
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
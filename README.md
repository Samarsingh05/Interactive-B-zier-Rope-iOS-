This project renders an interactive cubic Bézier curve that behaves like a spring-driven rope.
All curve evaluation, tangent computation, and physics are implemented manually without UIKit’s built-in Bézier utilities or external animation libraries.

The curve is defined by four control points P₀, P₁, P₂, P₃.
P₀ and P₃ are fixed. P₁ and P₂ move using a spring–damping model:

a = −k (x − target) − c v
v = v + a·dt
x = x + v·dt


The curve is evaluated by sampling:

B(t) = (1−t)³ P₀ + 3(1−t)²t P₁ + 3(1−t)t² P₂ + t³ P₃


Tangent vectors use the derivative:

B'(t) = 3(1−t)²(P₁−P₀) + 6(1−t)t(P₂−P₁) + 3t²(P₃−P₂)


Tangent lines are drawn at selected samples.

Interaction

Tilt input comes from CoreMotion (pitch and roll mapped to target offsets).

P₁ and P₂ can also be dragged directly by touch.

Double-tap resets the rope.

The curve redraws at ~60 FPS using CADisplayLink.

Files

BezierRopeView.swift: Bézier math, physics, rendering, input

MotionManager.swift: CoreMotion wrapper

ViewController.swift: hosts the interactive view

Standard app setup in AppDelegate and SceneDelegate

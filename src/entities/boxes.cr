class Hurtbox < Collider::Capsule
  def initialize(@owner, *args)
    super(*args)
  end
  def load
    super
    color = SF::Color.new(255, 155, 0)
    @shape1.fill_color = color
    @shape2.fill_color = color
    @shape3.fill_color = color
  end
end

class Actor < Collider::Rectangle
  LEEWAY = 2f32

  @[Flags]
  enum Direction
    Up
    Down
    Left
    Right
  end
  getter tangent = false
  property collision_direction = Direction::None
  def initialize(@owner, a, b)
    super(a, b)
    @shape.fill_color = SF::Color.new(0, 255, 0)
  end
  def update
    super
    collision_direction = Direction::None
    true
  end
end

class Hitbox < Collider::Capsule
  property damage = 0.0
  property time = 0.0
  def initialize(@owner, origin1, origin2, radius, @damage, frames)
    super(origin1, origin2, radius)
    @time = frames.to_f / 60 + Engine.time - 1 / 60
    update
  end
  def update
    super
    @time -= Engine.time
    return @time > 0
  end
end

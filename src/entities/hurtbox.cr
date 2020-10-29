class Hurtbox < Collider::Capsule
  def load
    super
    @tag = "hurtbox"
    color = SF::Color.new(255, 155, 0)
    @shape1.fill_color = color
    @shape2.fill_color = color
    @shape3.fill_color = color
  end
end

class PlayerCollider < Collider::Rectangle
  def initialize(a, b)
    super
    @shape.fill_color = SF::Color.new(0, 255, 0)
    @tag = "playerbox"
  end
end

class Hitbox < Collider::Capsule
  property damage = 0.0
  property time = 0.0
  def initialize(origin1, origin2, radius, @damage, frames, @tag = "hurtbox.enemy")
    super(origin1, origin2, radius)
    @time = frames.to_f / 60
    update
  end
  def update
    super
    @time -= Engine.time
    return @time > 0
  end
end

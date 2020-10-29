class Hurtbox < Collider::Capsule
  def load
    super
    @tag = "hurtbox"
    color = SF::Color.new(255, 155, 0, 150)
    @shape1.fill_color = color
    @shape2.fill_color = color
    @shape3.fill_color = color
  end
end

class PlayerCollider < Collider::Rectangle
  def initialize(a, b)
    super
    @shape.fill_color = SF::Color.new(0, 255, 0, 50)
    @tag = "playerbox"
  end
end

class Solid < Collider::Rectangle
  def initialize(origin, size)
    super
    @shape.fill_color = SF::Color::Blue
  end
end

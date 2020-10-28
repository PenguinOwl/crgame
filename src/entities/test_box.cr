class TestBox < Entity
  property collider = Collider::Capsule.new(Vector.new, Vector.new(50, 20), 20f32)
  property touching = false
  def load
    collider.offset = ->(){position}
    add collider
    collider.on do |collider|
      @touching = true
    end
    super
  end
  def update
    @touching = false
    super
  end
end

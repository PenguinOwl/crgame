class TestBox < Entity
  property collider = Collider::Capsule.new(Vector.new, Vector.new(50, 0), 20f32)
  property touching = false
  @player : Player
  def initialize(@player)
    super()
  end
  def load
    collider.offset = ->(){position}
    add collider
  end
  def update
    @touching = collider.collide(@player.collider)
    super()
  end
end

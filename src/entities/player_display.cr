class PlayerDisplay < Entity
  @font = SF::Font.from_file("/usr/share/fonts/OTF/Hermit-Regular.otf")
  @text = SF::Text.new
  @player : Player
  @box : TestBox
  def initialize(@player, @box)
    super()
  end
  def load
    @text.font = @font
    @text.string = "0"
    @text.character_size = 24
  end
  def render(target, states)
    target.draw @text, states
  end
  def update
    super
    @text.string = [
      @player.velocity.x.floor,
      @player.velocity.y.floor,
      @player.collider.collision_direction,
    ].map(&.to_s.rjust(20)).join("\n")
    return true
  end
end

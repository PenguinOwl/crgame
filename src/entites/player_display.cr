class PlayerDisplay < Entity
  @font = SF::Font.from_file("/usr/share/fonts/OTF/Hermit-Regular.otf")
  @text = SF::Text.new
  @player : Player
  def initialize(@player)
    super()
  end
  def load
    @text.font = @font
    @text.string = "0"
    @text.character_size = 24
    self.position = Vector.new(30, 30)
  end
  def render(target, states)
    target.draw @text, states
  end
  def update
    @text.string = [
      @player.position.x.round,
      @player.position.y.round,
      @player.velocity.x.round,
      @player.velocity.y.round,
      @player.dashing,
      @player.children,
      @player._da,
    ].map(&.to_s.rjust(20)).join("\n")
    return true
  end
end

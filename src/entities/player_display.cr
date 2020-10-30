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
    @text.string = [
      @player.position.x.round,
      @player.position.y.round,
      @player.velocity.x.round,
      @player.velocity.y.round,
      @player.facing,
      @box.touching,
      Engine.instance.scene.debug,
    ].map(&.to_s.rjust(20)).join("\n")
    target.draw @text, states
  end
  def update
    return true
  end
end

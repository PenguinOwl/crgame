class PlayerDisplay < Entity
  @font = SF::Font.from_file("/usr/share/fonts/OTF/Hermit-Regular.otf")
  @text = SF::Text.new
  @player : Player
  def initialize(@player)
    super()
    @offset = ->(){Game.window.view.center - Game.window.view.size / 2}
  end
  def load
    @text.font = @font
    @text.string = "0"
    @text.character_size = 24
  end
  def render(target, states)
    @text.position = position
    target.draw @text, states
  end
  def update
    super
    @text.string = [
      @player.position.x.floor,
      @player.position.y.floor,
      @player.velocity.x.floor,
      @player.velocity.y.floor,
      @player.collider.collision_direction,
      @player.last_ground,
    ].map(&.to_s.rjust(20)).join("\n")
    return true
  end
end

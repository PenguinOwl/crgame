class InputDisplay < Entity
  @font = SF::Font.from_file("/usr/share/fonts/OTF/Hermit-Regular.otf")
  @text = SF::Text.new
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
    @text.string = ((@text.string.to_i + 1) % 60).to_s
    return true
  end
end

require "crsfml"
require "./entity"
require "./engine"
require "./player"
require "./input"
require "./entites/**"

module Game
  window = SF::RenderWindow.new(SF::VideoMode.new(1920, 1080), "Resonance", SF::Style::Fullscreen) # SF::Style::Resize | SF::Style::Close)
  window.framerate_limit = 60
  window.key_repeat_enabled = false
  clock = SF::Clock.new
  input = Input.new
  input.load_config(Input::Config.new)
  engine = Engine.new(Scene.new, input)
  player = Player.new
  player_display = PlayerDisplay.new(player)
  player_display.position = {0, 300}
  engine.scene.add player
  engine.scene.add InputDisplay.new
  engine.scene.add player_display
  player.position = {100, 100}
  while window.open?
    while event = window.poll_event
      if event.is_a? SF::Event::Closed
        window.close
      end
    end
    input.update if window.focus?
    elapsed = clock.restart
    engine.update(elapsed)
    engine.render(window)
    window.display
    window.clear(SF::Color::Black)
  end
end

require "crsfml"
require "./entity"
require "./engine"
require "./input"
require "./entities/collider"
require "./entities/**"

module Game
  def self.window
    @@window
  end
  @@window = SF::RenderWindow.new(SF::VideoMode.new(1920, 1080), "Resonance", settings: SF::ContextSettings.new(depth: 24, antialiasing: 8))
  @@window.framerate_limit = 60
  @@window.key_repeat_enabled = false
  clock = SF::Clock.new
  input = Input.new
  input.load_config(Input::Config.new)
  engine = Engine.new(Scene.new, input)
  player = Player.new
  player_display = PlayerDisplay.new(player)
  player_display.position = {0, 30}
  testbox1 = Solid.new(Vector.new(500, 0), Vector.new(300, 400))
  testbox2 = Solid.new(Vector.new(1000, -500), Vector.new(200, 100))
  testbox3 = Solid.new(Vector.new(0, 900), Vector.new(1920, 50))
  engine.scene.add player
  engine.scene.add InputDisplay.new
  engine.scene.add player_display
  engine.scene.add testbox1
  engine.scene.add testbox2
  engine.scene.add testbox3
  player.position = {100, 100}
  @@window.view = SF::View.new(SF.float_rect(0, 0, 1920, 1080))
  while @@window.open?
    while event = @@window.poll_event
      case event
      when SF::Event::Closed
        @@window.close
      when SF::Event::Resized
        view = @@window.view
        if event.width / event.height > 1920 / 1080
          scale = (1 - ((1920 / 1080) / (event.width / event.height))) / 2
          view.viewport = SF.float_rect(scale, 0, 1 - scale * 2, 1)
        elsif event.width / event.height == 1920 / 1080
          view.viewport = SF.float_rect(0, 0, 1, 1)
        else
          scale = (1 - ((1080 / 1920) / (event.height / event.width))) / 2
          view.viewport = SF.float_rect(0, scale, 1, 1 - scale * 2)
        end
        @@window.view = view
      else
        next
      end
    end
    @@window.clear(SF::Color::Black)
    input.update if @@window.focus?
    elapsed = clock.restart
    engine.update(elapsed)
    engine.render(@@window)
    @@window.display
  end
end

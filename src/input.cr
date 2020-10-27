require "json"
BUFFER_SIZE = 6
INPUTS = {
  "jump" => "c",
  "up" => "p",
  "left" => "l",
  "right" => "quote",
  "down" => "semicolon",
  "attack" => "x",
  "dash" => "z",
}
class Input
  class Config
    include JSON::Serializable
    {% for input, key in INPUTS %}
      property {{input.id}}_keys : Array(SF::Keyboard::Key) = [SF::Keyboard::{{key.id.capitalize}}]
    {% end %}
    def initialize
    end
  end
  enum Button
    {% for input, key in INPUTS %}
      {{input.id.upcase}}
    {% end %}
  end
  property handlers = {} of SF::Keyboard::Key => Button
  {% begin %}
    property buffers = {
      {% for input, key in INPUTS %}
        Button::{{input.id.upcase}} => 0,
      {% end %}
    }
    property held = {
      {% for input, key in INPUTS %}
        Button::{{input.id.upcase}} => false,
      {% end %}
    }
  {% end %}
  def clear_buffers
    {% begin %}
      @buffers = {
        {% for input, key in INPUTS %}
          Button::{{input.id.upcase}} => 0,
        {% end %}
      }
    {% end %}
  end
  def load_config(config)
    handlers.clear
    {% for input, key in INPUTS %}
      config.{{input.id}}_keys.each do |key|
        handlers[key] = Button::{{input.id.upcase}}
      end
    {% end %}
  end
  {% for input, key in INPUTS %}
    def consume_{{input.id}}
      if buffers[Button::{{input.id.upcase}}] > 0
        buffers[Button::{{input.id.upcase}}] = 0
        return true
      else
        return false
      end
    end
    def {{input.id}}_held?
      if held[Button::{{input.id.upcase}}]
        return true
      else
        return false
      end
    end
  {% end %}
  def clear_holds
    held.transform_values!{ false }
  end
  def decrement
    buffers.transform_values!{ |v| (v - 1).clamp(0, BUFFER_SIZE) }
  end
  def clean
    clear_holds
    decrement
  end
  def update
    decrement
    pressed_buttons = Set(Button).new
    handlers.each_key do |key|
      if SF::Keyboard.key_pressed?(key)
        pressed_buttons << handlers[key]
      end
    end
    pressed_buttons.each do |button|
      unless held[button]
        buffers[button] = BUFFER_SIZE
      end
    end
    clear_holds
    pressed_buttons.each do |button|
      held[button] = true
    end
  end
end

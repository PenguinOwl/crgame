macro frame(numb)
  {{numb / 60}}
end

alias Vector = SF::Vector2f

class Engine
  property scene : Scene
  @@time = SF.seconds(0)
  @@input : Input = Input.new
  def initialize(@scene, input)
    @@input = input
  end

  def self.time
    return @@time.as_seconds
  end

  def self.input
    return @@input
  end

  def self.lerp(current, target, rate)
    movement = rate * time
    diff = target - current
    if movement.abs - diff.abs > 0 && movement.sign == diff.sign
      return target
    else
      return current + movement * diff.sign
    end
  end

  def update(time)
    @@time = time
    @scene.update
  end

  def render(window)
    window.draw @scene
  end
end

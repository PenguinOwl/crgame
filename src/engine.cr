macro frame(numb)
  {{numb / 60}}
end

alias Vector = SF::Vector2f

class Engine
  property scene : Scene
  property freeze_time = 0.0
  @@instance : Engine | Nil
  @@time = SF.seconds(0)
  @@input : Input = Input.new
  @frame_step = false
  @step_ff_time : Float64 = 0
  def initialize(@scene, input)
    @@input = input
    @@instance = self
  end

  def self.instance
    @@instance.not_nil!
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

  def self.lerp(current : Vector, target : Vector, rate)
    movement = rate * time
    diff = target - current
    if movement - diff.norm > 0 || (movement - diff.norm).abs < 0.01
      return target
    else
      return current + (diff.normalize * movement)
    end
  end

  def freeze(time : Float64)
    @freeze_time = Math.max(@freeze_time, time)
  end

  def freeze(time : Int32)
    freeze((time/60).to_f)
  end

  def update(time)
    if Engine.input.step_held?
      @step_ff_time += time.as_seconds
    else
      @step_ff_time = 0
    end
    if Engine.input.consume_free
      @frame_step = false
    end
    if @frame_step
      unless Engine.input.consume_step || @step_ff_time > 0.5
        return
      end
    else
      @frame_step = true if Engine.input.consume_step
    end
    if time.as_seconds < @freeze_time
      @freeze_time -= time.as_seconds
      return
    end
    @@time = time - SF.seconds(@freeze_time)
    @freeze_time = Math.max(@freeze_time - time.as_seconds, 0.0)
    @scene.update
  end

  def render(window)
    window.draw @scene
  end
end

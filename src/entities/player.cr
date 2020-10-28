module Math
  def self.absmax(num1, num2)
    if num1.abs > num2.abs
      return num1
    else
      return num2
    end
  end
end

class Player < Entity
  RUN_SPEED = 900f32
  GROUND_FRICTION = 15000f32
  AIR_FRICTION = 6000f32
  AIR_DRAG = 1000f32

  WALL_JUMP_BOUNCE = 1400f32
  WALL_JUMP_SPEED = 900f32

  DASH_SPEED = 2400f32

  property velocity = Vector.new(0, 0)
  property controllable = true
  property dashing = false
  property physics = true
  property can_dash = true
  property collider = Collider::Capsule.new(Vector.new(25, 25), Vector.new(25, 75), 25f32)
  property facing = -1
  @dash_action = nil
  @jumping = 0
  @wall_jumping = 0
  @shape = SF::RectangleShape.new({50, 100})
  def load
    @shape.fill_color = SF.color(100, 250, 50)
    collider.offset = ->(){position}
    add collider
  end
  def render(target, states)
  end
  def update
    # Initial move
    self.position += velocity * Engine.time

    if physics
      # Jumping & Gravity
      if jumping? || wall_jumping?
        gravity = 50
      elsif Engine.input.jump_held? && velocity.y.abs < 30
        gravity = 500
      else
        gravity = 5000
      end
      @velocity += Vector.new(0, gravity * Engine.time)
      if position.x + 50 >= 1920 || position.x <= 0
        @velocity.x = 0
      end
      if position.y + 100 >= 1080
        @velocity.y = 0
      end

      if jumping?
        @velocity.y += -150
        @jumping -= 1
        @jumping = 0 unless Engine.input.jump_held?
      else
        if @velocity.y < 0 && !Engine.input.jump_held?
          @velocity.y *= 0.66
        end
      end
    end

    # Jump input bypasses physics
    if controllable && on_ground? && Engine.input.consume_jump
      @jumping = 5
      dash = end_dash
      @velocity.y += dash ? -400 : -800
      if dash
        @velocity.x *= 1.2
      end
    end

    if physics
      # Left & Right
      if controllable && (Engine.input.right_held? || Engine.input.left_held?)
        target = Engine.input.right_held? ? RUN_SPEED : RUN_SPEED * -1
        if on_ground?
          rate = GROUND_FRICTION
        elsif @velocity.x.abs < RUN_SPEED
          rate = AIR_FRICTION
        else
          rate = AIR_DRAG
          if (@velocity.x < 0 && Engine.input.right_held?) || (@velocity.x > 0 && Engine.input.left_held?)
            @velocity.x *= 0.95
          end
        end
        @velocity.x = Engine.lerp(@velocity.x, target, rate)
      else
        @velocity.x *= 0.8
      end
    end

    # Wall Jumping
    if controllable && (on_left_wall? || on_right_wall?) && Engine.input.consume_jump
      dash = end_dash
      @velocity.x = on_left_wall? ? WALL_JUMP_BOUNCE : WALL_JUMP_BOUNCE * -1
      @wall_jumping = 6
      @velocity.y = WALL_JUMP_SPEED * -1
      if dash
        @velocity.x *= 0.9
        @velocity.y *= 1.6
      end
    end
    if physics
      if wall_jumping?
        @wall_jumping -= 1
      end
    end

    # Dashing
    unless @dashing
      if @can_dash && controllable && Engine.input.consume_dash
        @dash_action = Action.new do |action|
          old_velocity = @velocity
          action.frame 1 do
            @velocity = Vector.new
            @physics = false
            @controllable = false
          end
          action.frame 3 do
            velocity = Vector.new
            norm_check = 0
            if Engine.input.left_held? || Engine.input.right_held?
              velocity.x = Math.max(old_velocity.x.abs, DASH_SPEED) * (Engine.input.left_held? ? -1 : 1)
              norm_check += 1
            end
            if Engine.input.up_held? || Engine.input.down_held?
              velocity.y = Engine.input.up_held? ? DASH_SPEED * -1 : DASH_SPEED
              norm_check += 1
            end
            if norm_check == 2
              velocity /= Math.sqrt 2f32
            elsif norm_check == 0
              velocity.x = DASH_SPEED * facing
            end
            @velocity = velocity
            @controllable = true
          end
          stored_velo = 0f32
          action.frame 10 do
            stored_velo = @velocity.x
            @velocity /= 5
          end
          action.frame 14 do
            @velocity.x = stored_velo / 3
            end_dash
          end
        end
        @dashing = true
        @can_dash = false
        add @dash_action.not_nil!
      end
    end

    # Refill actions
    if on_ground?
      @can_dash = true
    end

    # Facing
    if Engine.input.left_held?
      @facing = -1
    end
    if Engine.input.right_held?
      @facing = 1
    end

    # Final cleanup
    @shape.fill_color = SF.color(100, 250, 50)
    @velocity.y = @velocity.y.clamp(-3000f32, Engine.input.down_held? ? 2000f32 : 1400f32)
    self.position = Vector.new position.x.clamp(0.0, (1920-50)).to_f32, position.y.clamp(-100, (1080-100)).to_f32
    return super
  end
  def jumping?
    @jumping > 0
  end
  def wall_jumping?
    @wall_jumping > 0
  end
  def on_ground?
    self.position.y >= 1080 - 100
  end
  def on_left_wall?
    self.position.x < 15
  end
  def on_right_wall?
    self.position.x > 1920 - 50 - 15
  end
  def end_dash
    if action = @dash_action
      remove action
      @dash_action = nil
    end
    res = @dashing
    @dashing = false
    @physics = true
    return res
  end
end

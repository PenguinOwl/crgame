class Player < Entity
  RUN_SPEED = 800f32
  GROUND_FRICTION = 15000f32
  AIR_FRICTION = 5000f32

  WALL_JUMP_BOUNCE = 600f32
  WALL_JUMP_SPEED = 1150f32

  property velocity = Vector.new(0, 0)
  property controllable = true
  property dashing = false
  property physics = true
  @dash_action = nil
  @jumping = 0
  @wall_jumping = 0
  @shape = SF::RectangleShape.new({50, 100})
  def load
    @shape.fill_color = SF.color(100, 250, 50)
  end
  def render(target, states)
    target.draw @shape, states
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
      self.position = Vector.new position.x.clamp(0.0, (1920-50)).to_f32, position.y.clamp(-100, (1080-100)).to_f32

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
      end_dash
      @jumping = 5
      @velocity.y += -800
    end

    if physics
      # Left & Right
      if controllable && Engine.input.right_held?
        @velocity.x = Engine.lerp(@velocity.x, RUN_SPEED, on_ground? ? GROUND_FRICTION : AIR_FRICTION)
      elsif controllable && Engine.input.left_held?
        @velocity.x = Engine.lerp(@velocity.x, RUN_SPEED * -1, on_ground? ? GROUND_FRICTION : AIR_FRICTION)
      else
        @velocity.x *= 0.8
      end
    end

    # Wall Jumping
    if controllable && on_left_wall? && Engine.input.consume_jump
      end_dash
      @velocity.x = WALL_JUMP_BOUNCE
      @wall_jumping = 6
    end
    if controllable && on_right_wall? && Engine.input.consume_jump
      end_dash
      @velocity.x = WALL_JUMP_BOUNCE * -1
      @wall_jumping = 6
    end
    if physics
      if wall_jumping?
        @wall_jumping -= 1
        @velocity.y = WALL_JUMP_SPEED * -1
      end
    end

    # Dashing
    unless @dashing
      if controllable && Engine.input.consume_dash
        @dash_action = Action.new do |action|
          action.frame 1 do
            @velocity = Vector.new
            @physics = false
            @controllable = false
          end
          action.frame 3 do
            @velocity.x += Engine.input.left_held? ? -3000 : 3000
            @controllable = true
          end
          action.frame 14 do
            @velocity.x /= 3
            end_dash
          end
        end
        @dashing = true
        add @dash_action.not_nil!
      end
    end

    # Final cleanup
    @shape.fill_color = SF.color(100, 250, 50)
    @velocity.y = @velocity.y.clamp(-3000f32, Engine.input.down_held? ? 1600f32 : 1200f32)
    return super
  end
  def _da
    @dash_action
  end
  def jumping?
    @jumping > 0
  end
  def wall_jumping?
    @wall_jumping > 0
  end
  def on_ground?
    self.position.y == 1080 - 100
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
    @dashing = false
    @physics = true
  end
end

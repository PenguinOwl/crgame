module Math
  def self.absmax(num1, num2)
    if num1.abs > num2.abs
      return num1
    else
      return num2
    end
  end
end

struct SF::Vector2(T)
  def rotate(rad)
    rad = -1 * rad + Math::PI / 2
    return SF::Vector2.new(x*Math.cos(rad) - y*Math.sin(rad), x*Math.sin(rad) + y*Math.cos(rad))
  end
  def norm
    return Math.sqrt(x**2 + y**2)
  end
  def normalize
    norm_val = norm
    return SF::Vector2.new(x/norm_val, y/norm_val)
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
  property attacking = false
  property physics = true
  property can_dash = true
  property collider = Actor.new(nil, Vector.new(0, 0), Vector.new(50, 100))
  property hurtbox = Hurtbox.new(nil, Vector.new(25, 25), Vector.new(25, 75), 15f32)
  property facing = -1
  @dash_action = nil
  @jumping = 0
  @coyote = 0f32
  @wall_jumping = 0
  @times_attacked = 0
  getter last_ground = Vector.new
  @shape = SF::RectangleShape.new({50, 100})
  def load
    @shape.fill_color = SF.color(100, 250, 50)
    collider.offset = ->(){position}
    hurtbox.offset = ->(){position}
    collider.owner = self
    hurtbox.owner = self
    collider.on do |object|
      case object
      when Solid
        solid = object
        collider_bounds = collider.bounds
        solid_bounds = solid.bounds
        next_frame_bounds = collider_bounds.map{|point| point + (@velocity * Engine.time)}
        next unless next_frame_bounds[1].x >= solid_bounds[0].x &&
          next_frame_bounds[0].x <= solid_bounds[1].x &&
          next_frame_bounds[1].y >= solid_bounds[0].y &&
          next_frame_bounds[0].y <= solid_bounds[1].y
        next if @velocity.norm == 0
        case {@velocity.x.sign, @velocity.y.sign}
        when {0, 1}
          collider_left = collider_bounds[0].x
          collider_right = collider_bounds[1].x
          solid_left = solid_bounds[0].x
          solid_right = solid_bounds[1].x
          overlap_left = (solid_left - collider_left) * -1
          overlap_right = solid_right - collider_right
          overlap_bottom = solid_bounds[0].y - collider_bounds[1].y
          if overlap_left > 0 && overlap_right > 0
            collider.collision_direction |= Actor::Direction::Down
            self.position += Vector.new(0, overlap_bottom)
          else
            if overlap_left > 0 && overlap_right < -0.99 * collider.size.x
              collider.collision_direction |= Actor::Direction::Left
              self.position -= Vector.new(((overlap_right + collider.size.x) * -1 + 0.01).clamp(nil, 0f32), 0)
            elsif overlap_right > 0 && overlap_left < -0.99 * collider.size.x
              collider.collision_direction |= Actor::Direction::Right
              self.position += Vector.new(((overlap_left + collider.size.x) * -1 + 0.01).clamp(nil, 0f32), 0)
            else
              collider.collision_direction |= Actor::Direction::Down
              self.position += Vector.new(0, overlap_bottom)
            end
          end
        when {0, -1}
          collider_left = collider_bounds[0].x
          collider_right = collider_bounds[1].x
          solid_left = solid_bounds[0].x
          solid_right = solid_bounds[1].x
          overlap_left = (solid_left - collider_left) * -1
          overlap_right = solid_right - collider_right
          overlap_top = solid_bounds[1].y - collider_bounds[0].y
          if overlap_left > 0 && overlap_right > 0
            collider.collision_direction |= Actor::Direction::Up
            self.position += Vector.new(0, overlap_top)
          else
            if overlap_left > 0 && overlap_right < -0.1 * collider.size.x
              collider.collision_direction |= Actor::Direction::Left
              self.position -= Vector.new(((overlap_right + collider.size.x) * -1 + 0.01).clamp(nil, 0f32), 0)
            elsif overlap_right > 0 && overlap_left < -0.1 * collider.size.x
              collider.collision_direction |= Actor::Direction::Right
              self.position += Vector.new(((overlap_left + collider.size.x) * -1 + 0.01).clamp(nil, 0f32), 0)
            else
              collider.collision_direction |= Actor::Direction::Up
              self.position += Vector.new(0, overlap_top)
            end
          end
        when {1, 0}
          collider_botttom = collider_bounds[0].y
          collider_top = collider_bounds[1].y
          solid_botttom = solid_bounds[0].y
          solid_top = solid_bounds[1].y
          overlap_top = solid_top - collider_top
          overlap_bottom = (solid_botttom - collider_botttom) * -1
          overlap_right = solid_bounds[0].x - collider_bounds[1].x
          if overlap_top > 0 && overlap_bottom > 0
            collider.collision_direction |= Actor::Direction::Right
            self.position += Vector.new(overlap_right, 0)
          else
            if overlap_bottom > 0 && overlap_top < -0.9 * collider.size.y
              collider.collision_direction |= Actor::Direction::Up
              self.position -= Vector.new(0, ((overlap_top + collider.size.y) * -1 + 0.01).clamp(nil, 0f32))
            elsif overlap_top > 0 && overlap_bottom < -0.7 * collider.size.y
              collider.collision_direction |= Actor::Direction::Down
              self.position += Vector.new(0, ((overlap_bottom + collider.size.y) * -1 + 0.01).clamp(nil, 0f32))
            else
              collider.collision_direction |= Actor::Direction::Right
              self.position += Vector.new(overlap_right, 0)
            end
          end
        when {-1, 0}
          collider_botttom = collider_bounds[0].y
          collider_top = collider_bounds[1].y
          solid_botttom = solid_bounds[0].y
          solid_top = solid_bounds[1].y
          overlap_top = solid_top - collider_top
          overlap_bottom = (solid_botttom - collider_botttom) * -1
          overlap_left = solid_bounds[1].x - collider_bounds[0].x
          if overlap_top > 0 && overlap_bottom > 0
            collider.collision_direction |= Actor::Direction::Left
            self.position += Vector.new(overlap_left, 0)
          else
            if overlap_bottom > 0 && overlap_top < -0.9 * collider.size.y
              collider.collision_direction |= Actor::Direction::Up
              self.position -= Vector.new(0, ((overlap_top + collider.size.y) * -1 + 0.01).clamp(nil, 0f32))
            elsif overlap_top > 0 && overlap_bottom < -0.7 * collider.size.y
              collider.collision_direction |= Actor::Direction::Down
              self.position += Vector.new(0, ((overlap_bottom + collider.size.y) * -1 + 0.01).clamp(nil, 0f32))
            else
              collider.collision_direction |= Actor::Direction::Left
              self.position += Vector.new(overlap_left, 0)
            end
          end
        when {1, 1}
          collider_corner = collider_bounds[1]
          solid_corner = solid_bounds[0]
          overlap = collider_corner - solid_corner
          if overlap.normalize.x < @velocity.normalize.x
            collider.collision_direction |= Actor::Direction::Right
            self.position -= Vector.new(overlap.x, 0)
          else
            collider.collision_direction |= Actor::Direction::Down
            self.position -= Vector.new(0, overlap.y)
          end
        when {1, -1}
          collider_corner = Vector.new(collider_bounds[1].x, collider_bounds[0].y)
          solid_corner = Vector.new(solid_bounds[0].x, solid_bounds[1].y)
          overlap = collider_corner - solid_corner
          if overlap.normalize.x < @velocity.normalize.x
            collider.collision_direction |= Actor::Direction::Right
            self.position -= Vector.new(overlap.x, 0)
          else
            collider.collision_direction |= Actor::Direction::Up
            self.position -= Vector.new(0, overlap.y)
          end
        when {-1, 1}
          collider_corner = Vector.new(collider_bounds[0].x, collider_bounds[1].y)
          solid_corner = Vector.new(solid_bounds[1].x, solid_bounds[0].y)
          overlap = collider_corner - solid_corner
          if overlap.normalize.x > @velocity.normalize.x
            collider.collision_direction |= Actor::Direction::Left
            self.position -= Vector.new(overlap.x, 0)
          else
            collider.collision_direction |= Actor::Direction::Down
            self.position -= Vector.new(0, overlap.y) #
          end
        when {-1, -1}
          collider_corner = collider_bounds[0]
          solid_corner = solid_bounds[1]
          overlap = collider_corner - solid_corner
          if overlap.normalize.x > @velocity.normalize.x
            collider.collision_direction |= Actor::Direction::Left
            self.position -= Vector.new(overlap.x, 0)
          else
            collider.collision_direction |= Actor::Direction::Up
            self.position -= Vector.new(0, overlap.y)
          end
        end
      end
    end
    add collider
    add hurtbox
  end
  def render(target, states)
    super
    @collider.collision_direction = Actor::Direction::None
  end
  def update
    # Initial move
    move_x = @velocity.x
    if (on_right_wall? && @velocity.x > 0) || (on_left_wall? && @velocity.x < 0)
      move_x = 0f32
    end
    move_y = @velocity.y
    if (on_ground? && @velocity.y > 0) || (on_ceiling? && @velocity.y < 0)
      move_y = 0f32
    end
    self.position += Vector.new(move_x, move_y) * Engine.time

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
      if on_ground?
        @velocity.y = @velocity.y.clamp(nil, 80f32)
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
        if on_ground? && @velocity.x.abs < 100
          @velocity.x = 0
        end
      end
    end

    # Refill actions
    if on_ground?
      @times_attacked = 0
      @can_dash = true
      unless jumping?
        @coyote = 5f32 / 60
      end
    else
      @coyote = Math.max(0f32, @coyote - Engine.time)
    end

    # Attacking
    unless @attacking
      if controllable && Engine.input.consume_attack
        @attacking = true
        action = Action.new do |action|
          @times_attacked += 1
          old_velocity = @velocity
          start_pos = position + Vector.new(25, 50)
          action.frame 1 do
            if @velocity.y > 0 && !on_ground?
              case @times_attacked
              when 1
                @velocity.y *= 0.3
              when 2
                @velocity.y *= 0.5
              end
            end
            if @velocity.y.abs < 300 && !on_ground?
              @physics = false
              @velocity.y = 0
            end
            old_velocity = @velocity
          end
          direction_vector = Vector.new
          direction = 0.0
          action.frame 4 do
            norm_check = 0
            if Engine.input.left_held? || Engine.input.right_held?
              direction_vector.x = Engine.input.right_held? ? 1f32 : -1f32
              norm_check += 1
            end
            if Engine.input.up_held? || Engine.input.down_held?
              direction_vector.y = Engine.input.up_held? ? -1f32 : 1f32
              norm_check += 1
            end
            if norm_check == 2
              direction_vector /= Math.sqrt 2f32
            elsif norm_check == 0
              direction_vector.x = facing.to_f32
            end
            direction = Math.atan2(direction_vector.x, direction_vector.y)
            action.add hitbox = Hitbox.new(self, position + Vector.new(25, 50), position + Vector.new(25, 50) + Vector.new(150, -70).rotate(direction), 50f32, 10.0, 2)
          end
          action.frame 6 do
            action.add hitbox = Hitbox.new(self, position + Vector.new(25, 50), position + Vector.new(25, 50) + Vector.new(150, 0).rotate(direction), 50f32, 10.0, 2)
          end
          action.frame 8 do
            action.add hitbox = Hitbox.new(self, position + Vector.new(25, 50), position + Vector.new(25, 50) + Vector.new(150, 70).rotate(direction), 50f32, 10.0, 2)
          end
          action.frame 10 do
            @physics = true
          end
          action.frame 18 do
            @attacking = false
          end
        end
        add action
      end
    end


    # Dashing
    unless @dashing || @attacking
      if @can_dash && controllable && Engine.input.consume_dash
        @dash_action = Action.new do |action|
          old_velocity = @velocity
          start_pos = position + Vector.new(25, 50)
          action.frame 1 do
            @velocity = Vector.new
            @physics = false
            @controllable = false
            Engine.instance.freeze 2
          end
          action.frame 2 do
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
          direction = 0.0
          action.frame 7 do
            stored_velo = @velocity.x
            direction = Math.atan2(@velocity.x, @velocity.y)
            @velocity /= 5
            action.add hitbox = Hitbox.new(self, start_pos, position + Vector.new(25, 50), 40f32, 5.0, 3)
            action.add hitbox = Hitbox.new(self, position + Vector.new(25, 50), position + Vector.new(25, 50) + Vector.new(100, -130).rotate(direction), 40f32, 10.0, 2)
          end
          action.frame 8 do
            action.add hitbox = Hitbox.new(self, position + Vector.new(25, 50), position + Vector.new(25, 50) + Vector.new(180, 0).rotate(direction), 25f32, 12.0, 2)
          end
          action.frame 10 do
            action.add hitbox = Hitbox.new(self, position + Vector.new(25, 50), position + Vector.new(25, 50) + Vector.new(100, 130).rotate(direction), 35f32, 10.0, 2)
          end
          action.frame 16 do
            @velocity.x = stored_velo / 3
            end_dash
          end
        end
        @dashing = true
        @can_dash = false
        add @dash_action.not_nil!
      end
    end

    # Jump input bypasses physics
    if controllable && @coyote > 0 && Engine.input.consume_jump
      @jumping = 5
      @coyote = 0
      dash = end_dash
      @velocity.y = dash ? -400f32 : -800f32
      if dash
        @velocity.x = DASH_SPEED * 0.8 * facing
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

    # Set camera
    view = Game.window.view
    body_center = position + collider.size / 2
    if on_ground?
      @last_ground = body_center
    end
    if position.y - 100 < @last_ground.y
      distance_factor = (@last_ground - body_center).norm / 600 + 1
      body_center = (@last_ground + body_center * distance_factor) / (distance_factor + 1)
      body_center.y -= 170
    else
      body_center.y += 240
    end
    distance = (view.center - body_center).norm
    view.center = Engine.lerp(view.center, body_center, distance * 140f32 * Engine.time)
    Game.window.view = view
    return super
  end
  def jumping?
    @jumping > 0
  end
  def wall_jumping?
    @wall_jumping > 0
  end
  def on_ground?
    collider.collision_direction.includes?(Actor::Direction::Down) ||
      self.position.y >= 2080 - 100
  end
  def on_ceiling?
    collider.collision_direction.includes?(Actor::Direction::Up)
  end
  def on_left_wall?
    collider.collision_direction.includes?(Actor::Direction::Left)
  end
  def on_right_wall?
    collider.collision_direction.includes?(Actor::Direction::Right)
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

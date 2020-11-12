class Enemy < Entity
  INVULN_TIME = 0.2

  include Physical

  property hurtbox = Hurtbox.new(nil, Vector.new, Vector.new(0, 60), 50f32)
  getter max_health = 1000.0
  property health = 0.0
  getter weight = 1.0
  @damaged = false
  @damage_taken = 0.0
  @knockback = Vector.new
  getter invuln_time = 0.0
  def load
    @health = max_health
    hurtbox.offset = ->(){position}
    hurtbox.position = Vector.new(30, 30)
    hurtbox.owner = self
    add hurtbox
    hurtbox.on do |hitbox|
      if hitbox.is_a? Hitbox
        next if @invuln_time > 0
        @damaged = true
        @damage_taken = Math.max(@damage_taken, hitbox.damage)
        attack_knockback = hitbox.direction * (500.0 / weight) * (2 - health / max_health)
        attack_knockback *= 3
        attack_knockback += Vector.new(hitbox.direction.x.sign.to_f32, 0) * attack_knockback.norm
        attack_knockback /= 4
        if attack_knockback.norm > @knockback.norm
          @knockback = attack_knockback
        end
        hitbox_owner = hitbox.owner
        if hitbox_owner.is_a?(Player)
          unless hitbox_owner.dashing
            hitbox_owner.can_dash = true
          else
            hitbox_owner.times_attacked = -1
          end
        end
      end
    end
    super
    super
  end
  def update
    super
    super
    move_x = @velocity.x
    if (on_right_wall? && @velocity.x > 0) || (on_left_wall? && @velocity.x < 0)
      move_x = 0f32
    end
    move_y = @velocity.y
    if (on_ground? && @velocity.y > 0) || (on_ceiling? && @velocity.y < 0)
      move_y = 0f32
    end
    self.position += Vector.new(move_x, move_y) * Engine.time
    self.velocity = Engine.lerp(self.velocity, Engine.instance.scene.children[0].position - position, 1000.0)

    @invuln_time = Math.max(@invuln_time - Engine.time, 0.0)
    if @damaged
      Engine.instance.freeze(@damage_taken / 100)
      @velocity = @knockback
      @health -= @damage_taken
      @damage_taken = 0
      @invuln_time = INVULN_TIME
      @damaged = false
      @knockback = Vector.new
    end
    true
  end
end

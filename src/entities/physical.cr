module Physical
  property velocity = Vector.new(0, 0)
  property collider = Actor.new(nil, Vector.new(0, 0), Vector.new(60, 120))
  def load
    collider.offset = ->(){position}
    collider.owner = self
    add collider
    collider.on do |object|
      case object
      when Solid
        solid = object
        collider_bounds = collider.bounds
        solid_bounds = solid.bounds
        next_frame_bounds = collider_bounds.map{|point| point + (@velocity * Engine.time)}
        next unless next_frame_bounds[1].x > solid_bounds[0].x &&
          next_frame_bounds[0].x < solid_bounds[1].x &&
          next_frame_bounds[1].y > solid_bounds[0].y &&
          next_frame_bounds[0].y < solid_bounds[1].y
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
  end
  def update
    collider.collision_direction = Actor::Direction::None
  end
  def on_ground?
    collider.collision_direction.includes?(Actor::Direction::Down)
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
end

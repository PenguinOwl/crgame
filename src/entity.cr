abstract class Entity < SF::Transformable
  include SF::Drawable
  property children = [] of Entity
  property offset : Proc(Vector) = ->(){Vector.new}
  def position
    vector = super
    if offset = @offset.call
      return vector + offset
    else
      return vector
    end
  end
  def add(entity : Entity)
    @children << entity
  end
  def remove(entity : Entity)
    entity.unload
    @children.delete(entity)
  end
  def draw(target : SF::RenderTarget, states : SF::RenderStates)
    states.transform *= self.transform
    @children.each{|child| target.draw(child)}
    render(target, states)
  end
  def render(target, states)
  end
  def update : Bool
    @children.reject(&.update).each do |child|
      child.unload
      @children.delete(child)
    end
    return true
  end
  def initialize
    super
    load
  end
  def load
  end
  def unload
    @children.each(&.unload)
    @children.clear
  end
end

class Action < Entity
  property calls = {} of Float32 => Proc(Nil)
  @time = 0.0
  def initialize(&block)
    super()
    yield self
  end
  def frame(numb, &proc)
    calls[(numb/60).to_f32] = proc
  end
  def frame(range : Range, &proc)
    range.each do |numb|
      calls[(numb/60).to_f32] = proc
    end
  end
  def update
    super
    @time += Engine.time
    calls.select{|k, v| k <= @time}.each do |k, v|
      v.call
      calls.delete(k)
    end
    return !calls.empty?
  end
  def unload
    calls.clear
    super
  end
end

class Scene < Entity
  property debug = [] of Tuple(Collider, Collider)
  property colliders = [] of Collider
  def update
    super
    debug.clear
    colliders.sort_by!{|collider| collider.bounds[0].x.to_i}
    active = [] of Tuple(Collider, Tuple(Vector, Vector))
    possible = Deque(Tuple(Collider, Collider)).new
    colliders.map{|collider| {collider, collider.bounds}}.each do |collider, bounds|
      active.select! do |active_collider, active_bounds|
        if active_bounds[1].x < bounds[0].x || (collider.handlers.size == 0 && active_collider.handlers.size == 0)
          next false
        end
        possible.push({collider, active_collider})
        debug << {collider, active_collider}
        next true
      end
      active << {collider, bounds}
    end
    while pair = possible.shift?
      if pair[0].collide pair[1]
        pair[0].trigger pair[1]
        pair[1].trigger pair[0]
      end
    end
    true
  end
end

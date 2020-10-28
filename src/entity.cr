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
end

module Math
  def pfoot(p1, p2, p3)
    if ((p2.x - p1.x)**2 + (p2.y - p1.y)**2) == 0
      u = 0.0
    else
      u = ((p3.y - p1.y) * (p2.y - p1.y) + (p3.y - p1.y) * (p2.y - p1.y)) / ((p2.x - p1.x)**2 + (p2.y - p1.y)**2)
    end
    u = u.clamp(0.0, 1.0)
    intersect = p1 + ((p2 - p1) * u)
    return Math.sqrt((intersect.x - p3.x)**2 + (intersect.y - p3.y)**2)
  end
  def pfoot(p1, p2, p3, p4)
    distances = {
      pfoot(p1, p2, p3),
      pfoot(p1, p2, p4),
      pfoot(p3, p4, p1),
      pfoot(p3, p4, p2)
    }
    return 0.0 if check_intersect(p1, p2, p3, p4)
    return distances.min
  end
  def check_intersect(p1, p2, p3, p4)
    begin
      a1 = (p1.y-p2.y)/(p1.x-p2.x)
      a2 = (p3.y-p4.y)/(p3.x-p4.x)
      b1 = p1.y-a1*p1.x = p2.y-a1*p2.x
      b2 = p3.y-a2*p3.x = p4.y-a2*p4.x
      return false if a1 == a2
      xa = (b2 - b1) / (a1 - a2)
      ya = a1 * xa + b1
      return (xa < max(min(p1.x,p2.x), min(p3.x,p4.x)) && xa > min(max(p1.x,p2.x), max(p3.x,p4.x)))
    rescue
      return true
    end
  end
end

abstract class Collider < Entity
  property handlers = [] of Proc(Collider, Nil)
  property tag = ""
  property collidable = true
  def collide(collider : Collider) : Bool
    case collider
    when Rectangle
      collide collider.as Rectangle
    when Circle
      collide collider.as Circle
    when Capsule
      collide collider.as Capsule
    when Group
      collide collider.as Group
    else
      false
    end
  end
  abstract def collide(collider : Rectangle) : Bool
  abstract def collide(collider : Circle) : Bool
  abstract def collide(collider : Capsule) : Bool
  def collide(collider : Group) : Bool
    collider.nodes.each do |node|
      return true if collide(node)
    end
    return false
  end
  abstract def bounds
  def on(&block : Collider -> Nil)
    handlers << block
  end
  def trigger(collider)
    handlers.each(&.call(collider))
  end
  def load
    Engine.instance.scene.colliders << self
  end
  def unload
    Engine.instance.scene.colliders.delete(self)
  end
  class Rectangle < Collider
    property origin = Vector.new
    property size = Vector.new
    @shape : SF::RectangleShape
    def initialize(@origin, @size)
      super()
      @shape = SF::RectangleShape.new(@size)
      @shape.position = position + origin
      @shape.fill_color = SF::Color::Red
    end
    def load
      super
    end
    def collide(collider : Rectangle) : Bool
      return origin.x < collider.origin.x + collider.size.x
        origin.x + origin.size.x > collider.x &&
        origin.y < collider.y + collider.size.y &&
        origin.y + origin.size.y > collider.y
    end
    def collide(collider : Circle) : Bool
      return true if origin.x < collider.origin.x &&
        collider.origin.x < origin.x + size.x &&
        origin.y < collider.origin.y &&
        collider.origin.y < origin.y + size.y
      return (collider.origin.x + collider.radius > origin.x ||
              collider.origin.x - collider.radius < origin.x + size.x) &&
             (collider.origin.x + collider.radius > origin.x ||
              collider.origin.x - collider.radius < origin.x + size.x)
    end
    def collide(collider : Capsule) : Bool
      collider.collide(self)
    end
    def bounds
      return {position + origin, position + origin + size}
    end
    def update
      @shape.position = position + origin
      true
    end
    def render(target, states)
      super
      target.draw(@shape, states)
    end
  end
  class Circle < Collider
    property origin = Vector.new
    property radius = 0f32
    @center_offset : Vector
    def initialize(@origin, @radius)
      super()
      @center_offset = Vector.new(radius, radius)
    end
    @shape = SF::CircleShape.new
    def load
      super
      @shape.radius = radius
      @shape.fill_color = SF::Color::Red
    end
    def collide(collider : Circle) : Bool
      diff = origin - collider.origin
      return Math.sqrt(diff.x**2 + diff.y**2) < radius + collider.radius
    end
    def collide(collider : Rectangle) : Bool
      return collider.collide(self)
    end
    def collide(collider : Capsule) : Bool
      collider.collide(self)
    end
    def bounds
      return {position - @center_offset, position + @center_offset}
    end
    def update
      @shape.position = position - @center_offset
      true
    end
    def render(target, states)
      super
      target.draw(@shape, states)
    end
  end
  class Group < Collider
    property nodes = [] of Collider
    def collide(collider : Rectangle) : Bool
      collider.collide(self)
    end
    def collide(collider : Circle) : Bool
      collider.collide(self)
    end
    def collide(collider : Capsule) : Bool
      collider.collide(self)
    end
    def bounds
      return {Vector.new, Vector.new}
    end
  end
  class Capsule < Collider
    property origin1 = Vector.new
    property origin2 = Vector.new
    property radius = 0f32
    def initialize(@origin1, @origin2, @radius)
      @shape3 = SF::RectangleShape.new(SF.vector2(Math.sqrt((@origin1.x-@origin2.x)**2+(@origin1.y-@origin2.y)**2), radius*2))
      super()
    end
    @shape1 = SF::CircleShape.new
    @shape2 = SF::CircleShape.new
    @shape3 : SF::RectangleShape
    def load
      super
      @shape1.radius = radius
      @shape2.radius = radius
      color = SF::Color::Red
      # color.a = 150
      @shape1.fill_color = color
      @shape2.fill_color = color
      @shape3.fill_color = color
      @shape3.origin = Vector.new(0, radius)
      diff = origin1 - origin2
      @shape3.rotation = Math.atan2(diff.y, diff.x) * (180 / Math::PI) + 180
    end
    def collide(collider : Circle) : Bool
      return Math.pfoot(origin1, origin2, collider.origin) < collider.radius + radius
    end
    def collide(collider : Rectangle) : Bool
      points = [collider.origin.x, collider.origin.x + collider.size.x].product([collider.origin.y, collider.origin.y + collider.size.y])
      points = points.map{|point| Vector.new(point[0], point[1]) + collider.position}
      points.sort_by!{|point| Math.pfoot(position + origin1, position + origin2, point)}
      return Math.pfoot(position + origin1, position + origin2, points[0], points[1]) < radius
    end
    def collide(collider : Capsule) : Bool
      return Math.pfoot(position + origin1, position + origin2, collider.position + collider.origin1, collider.position + collider.origin2) < collider.radius + radius
    end
    def update
      center_offset = Vector.new(radius, radius)
      @shape1.position = position + origin1 - center_offset
      @shape2.position = position + origin2 - center_offset
      @shape3.position = position + origin1
      true
    end
    def render(target, states)
      line = [
        SF::Vertex.new(position + origin1),
        SF::Vertex.new(position + origin2)
      ]
      target.draw(@shape1, states)
      target.draw(@shape2, states)
      target.draw(@shape3, states)
      target.draw(line, SF::Lines)
    end
    def bounds
      return {
        Vector.new(
          Math.min(origin1.x, origin2.x) - radius,
          Math.min(origin1.y, origin2.y) - radius,
        ) + position,
        Vector.new(
          Math.max(origin1.x, origin2.x) + radius,
          Math.max(origin1.y, origin2.y) + radius,
        ) + position
      }
    end
  end
end

module Math
  def pfoot(p1, p2, p3)
    u = ((p3.y - p1.y) * (p2.y - p1.y) + (p3.y - p1.y) * (p2.y - p1.y)) / ((p2.x - p1.x)**2 +(p2.y - p1.y)**2)
    u = u.clamp(0.0, 1.0)
    # intersect.x = intersect.x.clamp(Math.min(p1.x, p2.x), Math.max(p1.x, p2.x))
    # intersect.y = intersect.y.clamp(Math.min(p1.y, p2.y), Math.may(p1.y, p2.y))
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
      return (xa < max(min(p1.x,p2.x), min(p3.x,p4.x)) || xa > min(max(p1.x,p2.x), max(p3.x,p4.x)))
    rescue
      return true
    end
  end
end

abstract class Collider < Entity
  abstract def collide(collider : Rectangle) : Bool
  abstract def collide(collider : Circle) : Bool
  def collide(collider : Capsule) : Bool
    collider.collide(self)
  end
  def collide(collider : Group) : Bool
    collider.nodes.each do |node|
      return true if collide(node)
    end
    return false
  end
  class Rectangle < Collider
    property origin = Vector.new
    property size = Vector.new
    def initialize(@origin, @size)
      super()
    end
    def collide(collider : Rectangle) : Bool
      return origin.x < collider.origin.x + collider.size.x
        origin.x + origin.size.x > collider.x &&
        origin.y < collider.y + collider.size.y &&
        origin.y + origin.size.y > collider.y
    end
    def collide(collider : Circle) : Bool
      return true if origin.x < collider.origin.x &&
        collider.origin.x < origin.x + origin.size.x &&
        origin.y < collider.origin.y &&
        collider.origin.y < origin.y + origin.size.y
      return (collider.origin.x + collider.radius > origin.x ||
              collider.origin.x - collider.radius < origin.x + origin.size.x) &&
             (collider.origin.x + collider.radius > origin.x ||
              collider.origin.x - collider.radius < origin.x + origin.size.x)
    end
  end
  class Circle < Collider
    property origin = Vector.new
    property radius = 0f32
    def initialize(@origin, @radius)
      super()
    end
    @shape = SF::CircleShape.new
    def load
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
    def update
      @shape.position = position
      true
    end
    def render(target, states)
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
  end
  class Capsule < Collider
    property origin1 = Vector.new
    property origin2 = Vector.new
    property radius = 0f32
    def initialize(@origin1, @origin2, @radius)
      super()
    end
    @shape1 = SF::CircleShape.new
    @shape2 = SF::CircleShape.new
    def load
      @shape1.radius = radius
      @shape2.radius = radius
      @shape1.fill_color = SF::Color::Red
      @shape2.fill_color = SF::Color::Red
    end
    def collide(collider : Circle) : Bool
      return Math.pfoot(origin1, origin2, collider.origin) < collider.radius + radius
    end
    def collide(collider : Rectangle) : Bool
      points = [collider.origin.x, collider.origin.x + origin.size.x].product([collider.origin.y, collider.origin.y + origin.size])
      points = points.map{|point| Vector.new(point[0], point[1])}
      points.sort!{|point| Math.pfoot(origin1, origin2, point)}
      return points.min < radius
    end
    def collide(collider : Capsule) : Bool
      return Math.pfoot(position + origin1, position + origin2, collider.position + collider.origin1, collider.position + collider.origin2) < collider.radius + radius
    end
    def update
      @shape1.position = position + origin1
      @shape2.position = position + origin2
      true
    end
    def render(target, states)
      target.draw(@shape1, states)
      target.draw(@shape2, states)
    end
  end
end

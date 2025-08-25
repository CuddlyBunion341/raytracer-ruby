class Vec3
  attr_accessor :x, :y, :z
  def initialize(x, y, z)
    @x = x
    @y = y
    @z = z
  end

  def length
    Math.sqrt(x * x + y * y + z * z)
  end

  def normalize
    Vec3.new(x / length, y / length, z / length)
  end

  def *(other)
    if other.is_a?(Vec3)
      Vec3.new(x * other.x, y * other.y, z * other.z)
    elsif other.is_a?(Numeric)
      Vec3.new(x * other, y * other, z * other)
    else
      raise "Invalid type"
    end
  end

  def +(other)
    if other.is_a?(Vec3)
      Vec3.new(x + other.x, y + other.y, z + other.z)
    elsif other.is_a?(Numeric)
      Vec3.new(x + other, y + other, z + other)
    else
      raise "Invalid type"
    end
  end

  def -(other)
    if other.is_a?(Vec3)
      Vec3.new(x - other.x, y - other.y, z - other.z)
    elsif other.is_a?(Numeric)
      Vec3.new(x - other, y - other, z - other)
    else
      raise "Invalid type"
    end
  end
end

class Sphere
  attr_accessor :center, :radius
  def initialize(center, radius)
    @center = center
    @radius = radius
  end

  def sdf(point)
    (point - center).length - radius
  end
end

class Scene
  attr_accessor :spheres
  def initialize
    @spheres = []
  end

  def sdf(point)
    min_distance = Float::INFINITY
    @spheres.each do |sphere|
      distance = sphere.sdf(point)
      min_distance = [min_distance, distance].min
    end
    min_distance
  end
end

class Ray
  attr_accessor :origin, :direction
  def initialize(origin, direction)
    @origin = origin
    @direction = direction
  end

  def march(scene, step_size, max_distance)
    max_steps = max_distance / step_size
    t = 0.0
    for i in 0..max_steps
      point = origin + direction * t
      distance = scene.sdf(point)
      if distance < 0.001
        return t
      end
      t += distance
    end
    return max_distance
  end
end

class Renderer
  attr_accessor :width, :height, :depth

  def initialize(width, height, depth)
    @width = width
    @height = height
    @depth = depth
  end

  def render(scene)
    rows = []
    @height.times do |y|
      row = []
      @width.times do |x|
        ray = Ray.new(Vec3.new(0, 0, 0), Vec3.new(x, y, 1))
        ray.direction = ray.direction.normalize
        distance = ray.march(scene, 0.01, @depth)
        if distance < @depth
          row << distance
        end
      end
      rows << row
    end
    rows
  end
end


class Main
  def initialize
    @scene = Scene.new
    @scene.spheres << Sphere.new(Vec3.new(0, 0, 0), 1)
    @renderer = Renderer.new(32, 32, 10)
  end

  def distance_to_color(distance)
    normalized_distance = rand(0..1)
    case normalized_distance
    when 0.95..1.0
      "\e[47m█\e[0m"  # White full block
    when 0.8...0.95
      "\e[47m▓\e[0m"  # Heavy shade
    when 0.6...0.8
      "\e[47m▒\e[0m"  # Medium shade
    when 0.4...0.6
      "\e[47m░\e[0m"  # Light shade
    when 0.2...0.4
      "\e[47m \e[0m"  # White space
    else
      "\e[40m \e[0m"  # Black space
    end * 2
  end

  def run
    rows = @renderer.render(@scene)
    rows.each do |row|
      row.each do |distance|
        print distance_to_color(distance)
      end
      print "\n"
    end
  end
end

Main.new.run

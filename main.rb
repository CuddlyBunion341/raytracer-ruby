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
    @spheres << Sphere.new(Vec3.new(0, 0, 5), 2)
    @spheres << Sphere.new(Vec3.new(-4, 0, 8), 2)
  end

  def sdf(point)
    @spheres.map { |sphere| sphere.sdf(point) }.min
  end
end

class Ray
  attr_accessor :origin, :direction
  def initialize(origin, direction)
    @origin = origin
    @direction = direction
  end

  def march(scene, max_distance)
    traversed = 0.0
    while traversed < max_distance
      point = origin + direction * traversed
      distance = scene.sdf(point)
      return traversed if distance < 0.01

      traversed += distance
    end
    max_distance
  end
end

class Renderer
  attr_accessor :width, :height, :depth

  def initialize(width, height, depth)
    @width = width
    @height = height
    @depth = depth

    @origin = Vec3.new(0, 0, 0)
    @fov_percent = 1.5
  end

  def render(scene)
    aspect_ratio = @width.to_f / @height.to_f
    far_plane_width = @depth * @fov_percent * aspect_ratio
    far_plane_height = @depth * @fov_percent

    rows = []
    @height.times do |y|
      row = []
      @width.times do |x|
        far_plane_point = Vec3.new(
          far_plane_width * (x / @width.to_f) - far_plane_width / 2,
          far_plane_height * (y / @height.to_f) - far_plane_height / 2,
          @depth
        )
        direction = far_plane_point - @origin
        ray = Ray.new(@origin, direction.normalize)
        row << ray.march(scene, @depth)
      end
      rows << row
    end
    rows
  end
end


class Main
  def initialize
    @scene = Scene.new
    @renderer = Renderer.new(32, 32, 10)
  end

  def distance_to_color(distance)
    normalized_distance = distance / @renderer.depth
    case normalized_distance
    when 0.95..1.0
      "\e[47m█\e[0m"
    when 0.8...0.95
      "\e[47m▓\e[0m"
    when 0.6...0.8
      "\e[47m▒\e[0m"
    when 0.4...0.6
      "\e[47m░\e[0m"
    when 0.2...0.4
      "\e[47m \e[0m"
    else
      "\e[40m \e[0m"
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

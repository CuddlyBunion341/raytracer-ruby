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

  def -@
    Vec3.new(-x, -y, -z)
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

class Color
  attr_accessor :r, :g, :b

  def self.rgb(r, g, b)
    new(r, g, b)
  end

  def initialize(r, g, b)
    @r = r
    @g = g
    @b = b
  end
end

class Sphere
  attr_accessor :center, :radius, :color

  def initialize(center, radius, color)
    @center = center
    @radius = radius
    @color = color
  end

  def sdf(point)
    (point - center).length - radius
  end

  def color(_point)
    @color
  end
end

class Plane
  def initialize(light_tile_color, dark_tile_color)
    @light_tile_color = light_tile_color
    @dark_tile_color = dark_tile_color
    @floor_height = 4
  end

  def sdf(point)
    (point.y - @floor_height).abs
  end

  def color(point)
    if point.x.floor.even? == point.z.floor.even?
      @light_tile_color
    else
      @dark_tile_color
    end
  end
end

class Scene
  attr_accessor :sdfs

  def initialize
    @sdfs = []
    @sdfs << Sphere.new(Vec3.new(2, 2, 6), 2, Color.rgb(255, 0, 0))
    @sdfs << Sphere.new(Vec3.new(-4, 2, 8), 2, Color.rgb(0, 255, 0))
    @sdfs << Sphere.new(Vec3.new(0, 2, 10), 2, Color.rgb(0, 0, 255))
    @sdfs << Plane.new(Color.rgb(255, 255, 255), Color.rgb(0, 0, 0))
  end

  def sdf(point)
    @sdfs.map { |obj| obj.sdf(point) }.min
  end

  def color(point)
    min_val = @sdfs.map { |obj| [obj.sdf(point), obj.color(point)] }.min_by { |val, _| val }
    if min_val[0] < 0.1
      min_val[1]
    else
      Color.rgb(255, 255, 255)
    end
  end

  def obj(point)
    min_val = @sdfs.map { |obj| [obj.sdf(point), obj] }.min_by { |val, _| val }
    return unless min_val[0] < 0.1

    min_val[1]
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
    @light_direction = Vec3.new(1, 1, 1).normalize
  end

  def shadow_at_point(origin, max_light_distance = 10)

  end

  def sphere_reflection(collision_point, ray_direction, sphere)

  end

  LIGHT_DISTANCE = 10

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
        direction = (far_plane_point - @origin).normalize

        primary_ray = Ray.new(@origin, direction)
        distance = primary_ray.march(scene, @depth)
        collision_point = @origin + direction * distance
        collision_obj = scene.obj(collision_point)
        pixi_color = collision_obj&.color(collision_point) || Color.rgb(255, 255, 255)

        light_ray = Ray.new(collision_point - @light_direction * 0.1, -@light_direction)
        light_distance = light_ray.march(scene, LIGHT_DISTANCE)
        in_shadow = light_distance < LIGHT_DISTANCE

        # normal
        collision_object = scene.obj(collision_point)
        if collision_object.is_a?(Sphere) && distance < @depth
          sphere = collision_object
          sphere_normal = (collision_point - sphere.center).normalize


          dot_product = ->(vec1, vec2) { 
            vec1.x * vec2.x + 
            vec1.y * vec2.y + 
            vec1.z * vec2.z
          }

          
          length = ->(vec) {
            Math.sqrt(length_squared.call(vec))
          }

          length_squared = ->(vec) {
              vec.x * vec.x +
              vec.y * vec.y +
              vec.z * vec.z
          }

          scale = ->(scalar, vec) {
            Vec3.new(
              scalar * vec.x,
              scalar * vec.y,
              scalar * vec.z,
            )
          }

          proj_a_onto_b = ->(a, b) {
            scale.call(dot_product.call(a, b) / length_squared.call(a), b)
          }

          inverse_prim_ray_dir = -primary_ray.direction

          projected = proj_a_onto_b.call(inverse_prim_ray_dir, sphere_normal)
          distance_to_projected = projected - inverse_prim_ray_dir

          reflection_direction = inverse_prim_ray_dir + scale.call(2, distance_to_projected)
          reflection_direction = reflection_direction.normalize

          ray_origin = collision_point + scale.call(0.01, reflection_direction)
          ray = Ray.new(ray_origin, reflection_direction)
          reflection_distance = ray.march(scene, 10)

          if reflection_distance < 10
            reflection_landing = collision_point + reflection_direction * reflection_distance
            reflection_object = scene.obj(reflection_landing)

            if !reflection_object.nil?
              color = reflection_object.color(reflection_landing)
              pixi_color = color

              # shitty non-dry stuff

              # if !reflection_object.is_a?(Sphere)
              #   pixi_color = reflection_object.color(reflection_landing) || Color.rgb(255, 255, 255)
              # else
              #   last_reflection_landing = reflection_landing
              #   last_reflection_object = reflection_object
              #
              #   reflection_direction = (last_reflection_landing - reflection_object.center).normalize
              #   ray = Ray.new(last_reflection_landing, reflection_direction)
              #
              #   scene.sdfs = scene.sdfs.filter { |s| s != last_reflection_object }
              #   reflection_distance = ray.march(scene, 10)
              #   scene.sdfs << last_reflection_object
              #
              #   if reflection_distance < 10
              #     reflection_landing = last_reflection_landing + reflection_direction * reflection_distance
              #     reflection_object = scene.obj(reflection_landing)
              #     if !reflection_object.nil? && reflection_object != last_reflection_object
              #       pixi_color = reflection_object.color(reflection_landing) || Color.rgb(255, 255, 255)
              #     end
              #   end
              # end
            end
          end
        end

        row << PixelValue.new(distance.to_f, in_shadow, pixi_color)
      end
      rows << row
    end
    rows
  end
end

class PixelValue
  attr_accessor :distance, :shadow, :color

  def initialize(distance, shadow, color)
    @distance = distance / 2 + 0.5
    @shadow = shadow
    @color = color
  end

  def chunky_val
    new_color = Color.new(@color.r, @color.g, @color.b)

    if shadow
      new_color.r *= 0.5
      new_color.g *= 0.5
      new_color.b *= 0.5
    end

    ChunkyPNG::Color.rgb(
      (new_color.r - @distance * 0.0).to_i,
      (new_color.g - @distance * 0.0).to_i,
      (new_color.b - @distance * 0.0).to_i
    )
  end
end

class Main
  def initialize
    @scene = Scene.new
    @renderer = Renderer.new(512, 512, 20)
  end

  def run
    require "chunky_png"

    rows = @renderer.render(@scene)
    height = rows.size
    width = rows.first.size
    img = ChunkyPNG::Image.new(width, height, ChunkyPNG::Color::WHITE)

    rows.each_with_index do |row, y|
      row.each_with_index do |val, x|
        img[x, y] = val.chunky_val
      end
    end
    img.save("out.png")
    puts "Written to './out.png'"
  end
end

Main.new.run

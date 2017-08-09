# frozen_string_literal: true

# Shout out to https://bheisler.github.io/post/writing-raytracer-in-rust-part-1/, from which I cribbed a bunch of code.

require 'bundler'
Bundler.require
require 'matrix'

Point = Vector
Direction = Vector

Material = Struct.new(:color)
Ray = Struct.new(:origin, :direction)
Light = Struct.new(:origin, :color)

# Scene Model
class Scene
  extend Forwardable
  def_delegators :@canvas, :display, :write

  attr_reader :models
  def initialize(models, width: 512, height: 512, fov: 90)
    @models = models
    @width = width
    @height = height
    @fov = fov
    @aspect_ratio = if width > height
                      width.to_f / height.to_f
                    else
                      height.to_f / width.to_f
                    end
    @fov_radians = (fov.to_f * Math::PI) / 180.0
    @fov_adjustment = Math.tan(@fov_radians / 2.0)
    @canvas = Magick::Image.new(width, height) do |img|
      img.background_color = 'black'
    end
  end

  def render
    draw = Magick::Draw.new

    # :orthographic vs perspective
    @height.times do |y|
      @width.times do |x|
        # take center of pixel, then normalize to (-1.0..1.0), then adjust for fov
        ray_x = (((x + 0.5) / @width) * 2.0 - 1.0) * @fov_adjustment
        ray_y = (1.0 - ((y + 0.5) / @height) * 2.0) * @fov_adjustment
        if @width > @height
          ray_x *= @aspect_ratio
        else
          ray_y *= @aspect_ratio
        end
        ray = Ray.new(Point[0.0, 0.0, 0.0], Direction[ray_x, ray_y, -1.0].normalize)

        if @models[0].intersects_with?(ray)
          draw.fill(@models[0].material)
          draw.point(x, y)
        end
      end
    end

    draw.draw(@canvas)
  end
end

# Sphere model
class Sphere
  attr_reader :origin, :radius, :material

  # Create a sphere
  #
  # @param origin [Point]
  # @param radius [Float]
  # @param material [Material] - Anything that ImageMagick can handle.
  #   See http://www.simplesystems.org/RMagick/doc/draw.html#fill
  # @return [Sphere]
  def initialize(origin, radius, material = 'white')
    @origin = origin
    @radius = radius
    @material = material
  end

  # Where do I intersect with the given ray?
  #
  # @param [Ray] - the ray to check against
  # @return [Point] - nearest point of intersection
  # @return [nil] - no intersection
  def intersects_with?(ray)
    hyp = origin - ray.origin
    adj = hyp.dot(ray.direction)
    opp = hyp.dot(hyp) - adj**2
    opp < @radius**2
  end
end

models = [
  Sphere.new(Point[0.0, 0.0, -2.0], 1.0, '#00ff0033')
]
scene = Scene.new(models, width: 666)
scene.render
scene.display

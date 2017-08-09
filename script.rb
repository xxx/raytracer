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

class Sphere
  attr_reader :origin, :radius, :material

  # Create a sphere
  #
  # @param origin [Point]
  # @param radius [Float]
  # @param material [Material]
  # @return [Sphere]
  def initialize(origin, radius, material)
    @origin = origin
    @radius = radius
    @material = material
  end

  def intersects_with?(ray)
    hyp = origin - ray.origin
    adj = hyp.dot(ray.direction)
    opp = hyp.dot(hyp) - adj**2
    opp < @radius**2
  end
end

width = 1024
height = 512
fov = 90
aspect_ratio = width > height ? (width.to_f / height.to_f) : (height.to_f / width.to_f)
fov_radians = (fov.to_f * Math::PI) / 180.0
fov_adjustment = Math.tan(fov_radians / 2.0)

sphere = Sphere.new(Point[0.0, 0.0, -2.0], 1.0, Material.new('black'))

canvas = Magick::Image.new(width, height) do |img|
  img.background_color = 'blue'
end

draw = Magick::Draw.new
draw.fill('yellow')

# :orthographic vs perspective
height.times do |y|
  width.times do |x|
    # send ray through center of pixel, then normalize to (-1.0..1.0)
    ray_x = (((x + 0.5) / width) * 2.0 - 1.0) * fov_adjustment
    ray_y = (1.0 - ((y + 0.5) / height) * 2.0) * fov_adjustment
    if width > height
      ray_x *= aspect_ratio
    else
      ray_y *= aspect_ratio
    end
    ray = Ray.new(Point[0.0, 0.0, 0.0], Direction[ray_x, ray_y, -1.0].normalize)
    if sphere.intersects_with?(ray)
      draw.point(x, y)
    end

  end
end

draw.draw(canvas)
# binding.pry

canvas.display

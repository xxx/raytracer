# frozen_string_literal: true

require 'bundler'
Bundler.require
require 'matrix'

require_relative 'lib/base'
require_relative 'lib/scene'
require_relative 'lib/color'
require_relative 'lib/material'
require_relative 'lib/models/shape'
require_relative 'lib/models/sphere'
require_relative 'lib/models/plane'

# Textures can be procs:
random_color_texture = lambda { |_x, _y|
  colorz = %w[#00ffff #ff0000 #ffffff #ff00ff #0000ff #00ffff]

  Color.new(colorz.sample)
}

# Or more complex...
checkerboard_texture = lambda { |x, y|
  # Generate a 2x2 texture:
  # BW
  # WB
  black = Color.new('#000000')
  white = Color.new('#ffffff')
  width = 2.0 # each color is 1x1
  height = 2.0

  xt, yt = Material.to_absolute_coordinates(x, y, width, height)

  color_width = width / 2
  color_height = height / 2
  if (xt < color_width && yt < color_height) || (xt >= color_width && yt >= color_height)
    black
  else
    white
  end
}

# Textures can be instances of a class that defines #call
class ImageTexture
  def initialize(path)
    @img_data = Magick::Image.read(path)[0]
    @width = @img_data.columns
    @height = @img_data.rows
  end

  def call(x, y)
    xt, yt = Material.to_absolute_coordinates(x, y, @width, @height)

    # Subtract xt and yt from the width and height to flip the image
    pixel = @img_data.pixel_color(@width - xt, @height - yt)

    # assume 16 bit quantum depth here, since that seems to be common.
    # Normalize down to 0-255 8 bit range
    r = (pixel.red * 255) / 65_535
    g = (pixel.green * 255) / 65_535
    b = (pixel.blue * 255) / 65_535
    Color.new([r, g, b])
  end
end

models = [
  Sphere.new(Point[0.0, 0.0, -5.0], 1.0, Material.new(color: '#33ff33', albedo: 0.18, reflectivity: 0.7)),
  Sphere.new(Point[-3.0, 1.0, -6.0], 2.0, Material.new(albedo: 0.58, texture: checkerboard_texture)),
  Sphere.new(
    Point[2.0, 1.0, -4.0],
    1.5,
    Material.new(
      color: '#ffffff',
      albedo: 0.18,
      refraction: Struct.new(:index, :transparency).new(1.5, 1.0)
    )
  ),
  Plane.new(
    Point[0.0, -2.0, -5.0],
    Vector[0.0, -1.0, 0.0],
    Material.new(albedo: 0.18, texture: checkerboard_texture, reflectivity: 0.5)
  ),
  Plane.new(
    Point[0.0, 0.0, -20.0],
    Vector[0.0, 0.0, -1.0],
    # Material.new(albedo: 0.6, texture: ImageTexture.new('img/ostrich.jpg'))
    Material.new(color: '#4455ff', albedo: 0.38)
  )
]

lights = [
  # DirectionalLight.new(
  #   Vector[0.0, 0.0, -1.0],
  #   '#ffffff',
  #   2.0
  # ),
  DirectionalLight.new(
    Vector[0.0, 0.0, -1.0],
    '#ffffff',
    0.0
  ),
  # DirectionalLight.new(
  #   Vector[-0.7, 0.0, -0.2],
  #   '#ffa500',
  #   4.0
  # ),
  SphericalLight.new(
    Point[-2.0, 10.0, -3.0],
    '#33aa33',
    10_000.0
  ),
  SphericalLight.new(
    Point[0.25, 0.0, -2.0],
    '#aa3333',
    250.0
  )
]

scene = Scene.new(models, width: 200, height: 200, background_color: '#222222', lights: lights)
scene.render(progress_bar: true)
scene.display
# scene.write('hello.png')

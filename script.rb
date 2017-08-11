# frozen_string_literal: true

# Shout out to https://bheisler.github.io/post/writing-raytracer-in-rust-part-1/, from which I cribbed a bunch of code.

require 'bundler'
Bundler.require
require 'matrix'

require_relative 'lib/base'
require_relative 'lib/scene'
require_relative 'lib/color'
require_relative 'lib/models/sphere'
require_relative 'lib/models/plane'

# Textures can be procs:
random_color_texture = lambda { |x, y|
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

    # Subject xt and yt from the width and height to flip the image
    pixel = @img_data.pixel_color(@width - xt, @height - yt)

    # assume 16 bit quantum depth here, since that seems to be common.
    # Normalize down to 0-255 8 bit range
    r = (pixel.red * 255) / 65535
    g = (pixel.green * 255) / 65535
    b = (pixel.blue * 255) / 65535
    Color.new([r, g, b])
  end
end

models = [
  Sphere.new(Point[-3.0, 1.0, -6.0], 2.0, Material.new('#ffff00', 0.58, checkerboard_texture, 0.1)),
  Sphere.new(Point[0.0, 0.0, -5.0], 1.0, Material.new('#ff00ff', 0.18, nil, 0.2)),
  Sphere.new(Point[2.0, 1.0, -4.0], 1.5, Material.new('#ffa500', 1.0, nil, 0.05)),
  Plane.new(
    Point[0.0, -2.0, -5.0],
    Vector[0.0, -1.0, 0.0],
    Material.new('#ffffff', 0.6, ImageTexture.new('img/ostrich.jpg'))
  ),
  # Plane.new(Point[0.0, 0.0, -20.0], Vector[0.0, 0.0, -1.0], Material.new('#ff0000', 0.38)),
]
lights = [
  # DirectionalLight.new(
  #   Vector[0.0, 0.0, -1.0],
  #   '#ffffff',
  #   2.0
  # ),
  DirectionalLight.new(
    Vector[1.0, -1.5, -1.0],
    '#ffffff',
    1.0
  ),
  # DirectionalLight.new(
  #   Vector[-0.7, 0.0, -0.2],
  #   '#ffa500',
  #   4.0
  # ),
  SphericalLight.new(
    Point[0.25, 0.0, -2.0],
    '#ffffff',
    200.0
  )
]
scene = Scene.new(models, width: 200, height: 200, background_color: '#222222', lights: lights)
scene.render(progress_bar: true)
scene.display
# scene.write('hello.png')

# frozen_string_literal: true

# Shout out to https://bheisler.github.io/post/writing-raytracer-in-rust-part-1/, from which I cribbed a bunch of code.

require 'bundler'
Bundler.require
require 'matrix'

require_relative 'lib/base'
require_relative 'lib/scene'
require_relative 'lib/models/sphere'
require_relative 'lib/models/plane'

models = [
  Sphere.new(Point[0.5, -0.5, -3.0], 1.0, Material.new('#00ff00', 0.6)),
  Sphere.new(Point[-1.0, 0.3, -1.2], 0.2, Material.new('#ffff00', 0.7)),
  Plane.new(Point[0.0, -2.0, -5.0], Vector[0.0, -1.0, 0.0], Material.new('#ff00ff')),
  # Plane.new(Point[0.0, 0.0, -20.0], Vector[0.0, 0.0, -1.0], Material.new('ff00ff')),
]
light = DirectionalLight.new(
  Vector[0.0, 0.0, -1.0],
  '#ffffff',
  2.0
)
# light = nil
scene = Scene.new(models, width: 100, height: 100, background_color: '#555555', light: light)
scene.render(progress_bar: false)
# binding.pry
scene.display
# scene.write('hello.png')

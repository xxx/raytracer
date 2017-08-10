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
  Sphere.new(Point[0.0, 0.0, -5.0], 1.0, Material.new('#77ff77', 0.18)),
  Sphere.new(Point[-3.0, 1.0, -6.0], 2.0, Material.new('#ffff00', 0.58)),
  Sphere.new(Point[2.0, 1.0, -4.0], 1.5, Material.new('#ffa500', 0.18)),
  Plane.new(Point[0.0, -2.0, -5.0], Vector[0.0, -1.0, 0.0], Material.new('#ff00ff', 0.18)),
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
    '#0000ff',
    2.0
  ),
  # DirectionalLight.new(
  #   Vector[-0.7, 0.0, -0.2],
  #   '#ffa500',
  #   4.0
  # ),
  SphericalLight.new(
    Point[0.25, 0.0, -2.0],
    '#ffffff',
    2500.0
  )
]
scene = Scene.new(models, width: 200, height: 200, background_color: '#555555', lights: lights)
scene.render(progress_bar: true)
# binding.pry
scene.display
# scene.write('hello.png')

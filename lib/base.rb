# frozen_string_literal: true

# Alias for readability
Point = Vector

Ray = Struct.new(:origin, :direction)

# Directional Light
#
# @param [Vector] direction
# @param [String] color - hex digits a la HTML
# @param [Float] intensity - 0.0 (no light) - ~4.0
DirectionalLight = Struct.new(:direction, :color, :intensity) do
  def initialize(*)
    super
    self.color = Color.new(color)

    freeze
  end

  def direction_from(_hit_point)
    -direction
  end

  def intensity_at(_hit_point)
    intensity
  end

  def distance_from(_hit_point)
    Float::INFINITY
  end
end

# Spherical Light
#
# @param [Point] position
# @param [String] color - hex digits a la HTML
# @param [Float] intensity - 0.0 (no light) - (anything)
SphericalLight = Struct.new(:position, :color, :intensity) do
  def initialize(*)
    super
    self.color = Color.new(color)

    freeze
  end

  def direction_from(hit_point)
    (position - hit_point).normalize
  end

  def intensity_at(hit_point)
    d = position - hit_point
    n = d.dot(d)
    intensity / (4.0 * Math::PI * n)
  end

  def distance_from(hit_point)
    (position - hit_point).magnitude
  end
end

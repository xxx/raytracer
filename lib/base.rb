# For readability
Point = Vector

Ray = Struct.new(:origin, :direction)

# Model materials
#
# @param [String] color - Any color handled by ImageMagick
# @param [Float] albedo - how much ambient light is reflected
Material = Struct.new(:color, :albedo) do
  def initialize(*)
    super
    self.color = Colorable::Color.new(color)
    self.albedo ||= 1.0 # Default to reflecting 100% of light
  end
end

# Directional Light
#
# @param [Vector] direction
# @param [String] color - Any color handled by ImageMagick
# @param [Float] intensity - 0.0 (no light) - ~4.0
DirectionalLight = Struct.new(:direction, :color, :intensity) do
  def initialize(*)
    super
    self.color = Colorable::Color.new(color)
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
# @param [String] color - Any color handled by ImageMagick
# @param [Float] intensity - 0.0 (no light) - (anything)
SphericalLight = Struct.new(:position, :color, :intensity) do
  def initialize(*)
    super
    self.color = Colorable::Color.new(color)
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
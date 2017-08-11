# For readability
Point = Vector

Ray = Struct.new(:origin, :direction)

# Model materials
#
# @param [String] color - Any color handled by ImageMagick
# @param [Float] albedo - how much ambient light is reflected
# @param [Proc] texture - proc taking x,y texture coordinates, and returns a color for that pixel from the texture.
#   Any object responding to #call will work.
#   Passing a texture will override the color, causing it to be ignored.
Material = Struct.new(:color, :albedo, :texture) do
  def initialize(*)
    super
    self.color = Colorable::Color.new(color) if color
    self.albedo ||= 1.0 # Default to reflecting 100% of light
  end

  def color_at(x, y)
    if texture
      texture.call(x, y)
    else
      color
    end
  end

  # A helper to translate from the normalized texture coordinates of a model
  # to absolute coordinates of a texture. Will just repeat the texture in any
  # dimension input is outside the range.
  def self.to_absolute_coordinates(x, y, texture_width, texture_height)
    xa_tmp = x * texture_width
    xa = xa_tmp % texture_width
    xa += texture_width if xa.negative?

    ya_tmp = y * texture_height
    ya = ya_tmp % texture_height
    ya += texture_height if ya.negative?

    [xa, ya]
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
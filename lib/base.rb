# For readability
Point = Vector

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

Ray = Struct.new(:origin, :direction)
# Directional Light
#
# @param [Vector] direction
# @param [String] color - Any color handled by ImageMagick
# @param [Float] intensity - 0.0 (no light) - (anything)
DirectionalLight = Struct.new(:direction, :color, :intensity) do
  def initialize(*)
    super
    self.color = Colorable::Color.new(color)
  end
end
# Model materials
class Material
  attr_reader :color, :albedo, :texture, :reflectivity, :refraction

  # @param [String] color - hex digits a la HTML. Defaults to '#ffffff'
  # @param [Float] albedo - how much ambient light is reflected. Defaults to 1.0
  # @param [Proc] texture - proc taking x,y texture coordinates, and returns a color for that pixel from the texture.
  #   Any object responding to #call will work.
  #   Passing a texture will override the color, causing it to be ignored.
  # @param [Float] reflectivity - range 0.0 (no reflection) - 1.0 (full mirror)
  # @param [Struct] refraction - Struct with members named index and transparency
  # Material = Struct.new(:color, :albedo, :texture, :reflectivity, :refraction) do
  def initialize(color: '#ffffff', albedo: 1.0, texture: nil, reflectivity: 0.0, refraction: nil)
    @color = Color.new(color)
    @albedo = albedo
    @texture = texture
    @reflectivity = reflectivity
    @refraction = refraction
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

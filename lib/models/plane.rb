# Plane model

class Plane
  attr_reader :origin, :normal, :material

  # Create a plane
  #
  # @param origin [Point]
  # @param normal [Vector] - assumed to already be normalized
  # @param material [Material] - Anything that ImageMagick can handle.
  #   See http://www.simplesystems.org/RMagick/doc/draw.html#fill
  # @return [Plane]
  def initialize(origin, normal, material = Material.new('white'))
    @origin = origin
    @normal = normal
    @material = material
  end

  # Where do I intersect with the given ray?
  #
  # @param [Ray] - the ray to check against
  # @return [Float] - distance of nearest point of intersection
  # @return [nil] - no intersection
  def intersection_with(ray)
    denom = @normal.dot(ray.direction)

    # if this is zero, ray and plane are parallel
    return nil if denom < 1e-3 # account for floating point errors

    v = @origin - ray.origin
    distance = v.dot(@normal) / denom
    return distance if distance.positive?
    nil
  end

  def surface_normal(_intersect_point)
    -@normal
  end
end
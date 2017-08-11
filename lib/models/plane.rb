# Plane model

class Plane
  attr_reader :origin, :normal, :material

  # Create a plane
  #
  # @param origin [Point]
  # @param normal [Vector] - assumed to already be normalized
  # @param material [Material]
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
    distance.positive? ? distance : nil
  end

  def surface_normal(_hit_point)
    -@normal
  end

  def texture_coordinates(hit_point)
    x_axis = @normal.cross(Vector[0.0, 0.0, 1.0])
    x_axis = @normal.cross(Vector[0.0, 1.0, 0.0]) if x_axis.magnitude.zero?
    y_axis = @normal.cross(x_axis)
    hit_vec = hit_point - @origin
    x = hit_vec.dot(x_axis)
    y = hit_vec.dot(y_axis)
    [x, y]
  end
end
# Sphere model

class Sphere
  attr_reader :origin, :radius, :material

  # Create a sphere
  #
  # @param origin [Point]
  # @param radius [Float]
  # @param material [Material] - Anything that ImageMagick can handle.
  #   See http://www.simplesystems.org/RMagick/doc/draw.html#fill
  # @return [Sphere]
  def initialize(origin, radius, material = Material.new('white'))
    @origin = origin
    @radius = radius
    @material = material
  end

  # Where do I intersect with the given ray?
  #
  # @param [Ray] - the ray to check against
  # @return [Float] - distance of nearest point of intersection
  # @return [nil] - no intersection
  def intersection_with(ray)
    hyp = @origin - ray.origin
    adj = hyp.dot(ray.direction)
    opp = hyp.dot(hyp) - adj**2
    radius2 = @radius**2
    return nil if opp > radius2 # no intersection

    # Now we check a second triangle to get the location of the intersection
    side3 = Math.sqrt(radius2 - opp)
    t0 = adj - side3
    t1 = adj + side3

    return nil if t0.negative? && t1.negative?

    t0 < t1 ? t0 : t1
  end

  def surface_normal(hit_point)
    (hit_point - @origin).normalize
  end

  def texture_coordinates(hit_point)
    hit_vec = hit_point - @origin
    x = (1.0 + Math.atan2(hit_vec[2], hit_vec[0]) / Math::PI) * 0.5
    y = Math.acos(hit_vec[1] - @radius) / Math::PI
    Struct.new(:x, :y).new(x, y)
  end
end
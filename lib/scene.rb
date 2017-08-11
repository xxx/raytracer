# Scene Model

class Scene
  SHADOW_BIAS = 1e-13
  MAX_RECURSION_DEPTH = 10

  extend Forwardable
  def_delegators :@canvas, :display, :write

  attr_reader :models

  def initialize(models, width: 512, height: 512, fov: 90, background_color: 'black', lights: [])
    @models = models
    @width = width
    @height = height
    @fov = fov
    @aspect_ratio = if width > height
      width.to_f / height.to_f
    else
      height.to_f / width.to_f
    end
    @fov_radians = (fov.to_f * Math::PI) / 180.0
    @fov_adjustment = Math.tan(@fov_radians / 2.0)
    @canvas = Magick::Image.new(width, height) do |img|
      img.background_color = background_color
    end
    @lights = lights
  end

  def render(progress_bar: false)
    draw = Magick::Draw.new

    bar = nil
    if progress_bar
      bar = ProgressBar.create(
        total: @width * @height,
        format: '%t: %c/%C %e |%w|'
      )
    end

    @height.times do |y|
      @width.times do |x|
        # take center of pixel, then normalize to (-1.0..1.0), then adjust for fov
        ray_x = (((x + 0.5) / @width) * 2.0 - 1.0) * @fov_adjustment
        ray_y = (1.0 - ((y + 0.5) / @height) * 2.0) * @fov_adjustment
        if @width > @height
          ray_x *= @aspect_ratio
        else
          ray_y *= @aspect_ratio
        end
        ray = Ray.new(Point[0.0, 0.0, 0.0], Vector[ray_x, ray_y, -1.0].normalize)

        closest = closest_intersection_of(ray)

        if closest
          model, distance = closest
          draw_color = get_color(ray, model, distance)

          draw.fill(draw_color.hex_gamma)
          draw.point(x, y)
        end

        bar&.increment
      end
    end

    draw.draw(@canvas)
  end

  private

  def get_color(ray, model, distance, recursion_depth = 1)
    hit_point = ray.origin + (ray.direction * distance)

    material = model.material
    surface_normal = model.surface_normal(hit_point)

    color = if @lights.length.positive?
      fill_color = Color.new('#000000')

      @lights.each do |light|
        direction_to_light = light.direction_from(hit_point)
        # use SHADOW_BIAS to correct shadow acne. can lead to peter panning, but better that than acne
        shadow_ray = Ray.new(hit_point + (surface_normal * SHADOW_BIAS), direction_to_light.normalize)
        shadow_intersection = closest_intersection_of(shadow_ray)

        lit = shadow_intersection.nil? || shadow_intersection[1] > light.distance_from(hit_point)
        light_intensity = lit ? light.intensity_at(hit_point) : 0.0
        light_power = surface_normal.dot(direction_to_light) * light_intensity
        light_power = 0.0 if light_power.negative?
        light_reflected = material.albedo / Math::PI
        light_color = Color.new(
          light.color.rgb.map { |c| [(c * light_power * light_reflected).to_i, 255].min }
        )

        fill_color += light_color * material.color_at(*model.texture_coordinates(hit_point))
      end

      fill_color
    else
      material.color
    end

    if material.reflectivity.positive? && recursion_depth <= MAX_RECURSION_DEPTH
      reflection_ray = Ray.new(
        hit_point + (surface_normal * SHADOW_BIAS),
        ray.direction - (2.0 * ray.direction.dot(surface_normal) * surface_normal)
      )

      reflector = closest_intersection_of(reflection_ray)

      if reflector
        color *= (1.0 - material.reflectivity)
        color += get_color(reflection_ray, reflector[0], reflector[1], recursion_depth + 1) * material.reflectivity
      end
    end

    color
  end

  def closest_intersection_of(ray)
    @models.map do |model|
      [model, model.intersection_with(ray)]
    end.delete_if do |i|
      i[1].nil?
    end.sort_by do |x|
      x[1]
    end.first
  end
end
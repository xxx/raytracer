# frozen_string_literal: true

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
    return Color.new('#000000') if recursion_depth > MAX_RECURSION_DEPTH

    hit_point = ray.origin + (ray.direction * distance)

    surface_normal = model.surface_normal(hit_point)

    color = diffuse_color(model, hit_point, surface_normal)

    if model.material.reflectivity.positive?
      color = reflective_color(color, model, hit_point, surface_normal, ray, recursion_depth)
    end

    if model.material.refraction
      color = refractive_color(color, model, hit_point, surface_normal, ray, recursion_depth)
    end

    color
  end

  def diffuse_color(model, hit_point, surface_normal)
    material = model.material
    return material.color unless @lights.length.positive?

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
  end

  def reflective_color(current_color, model, hit_point, surface_normal, ray, recursion_depth)
    material = model.material

    reflection_ray = Ray.new(
      hit_point + (surface_normal * SHADOW_BIAS),
      ray.direction - (2.0 * ray.direction.dot(surface_normal) * surface_normal)
    )

    reflector = closest_intersection_of(reflection_ray)

    if reflector
      current_color *= (1.0 - material.reflectivity)
      current_color += get_color(reflection_ray, reflector[0], reflector[1], recursion_depth + 1) * material.reflectivity
    end
    current_color
  end

  def refractive_color(current_color, model, hit_point, surface_normal, ray, recursion_depth)
    refraction_color = nil

    current_color = Color.new('#000000')
    material = model.material
    index_of_refraction = material.refraction.index
    kr = fresnel(ray.direction, surface_normal, index_of_refraction)
    # kr = 0.7

    if kr < 1.0
      ref_n = surface_normal
      eta_t = index_of_refraction
      eta_i = 1.0
      i_dot_n = ray.direction.dot(surface_normal)

      if i_dot_n < 0.0
        # Outside the surface
        i_dot_n = -i_dot_n
      else
        # Inside the surface. invert the normal and swap the indices of refraction
        ref_n = -ref_n
        eta_i = eta_t
        eta_t = 1.0
      end

      eta = eta_i / eta_t
      k = 1.0 - (eta * eta) * (1.0 - i_dot_n * i_dot_n)

      if k.positive?
        transmission_ray = Ray.new(
          hit_point + (ref_n * -SHADOW_BIAS),
          (ray.direction + i_dot_n * ref_n) * eta - ref_n * Math.sqrt(k)
        )

        refractor = closest_intersection_of(transmission_ray)

        if refractor
          refraction_color = get_color(transmission_ray, refractor[0], refractor[1], recursion_depth + 1)
        end
      end

      current_color *= refraction_color if refraction_color
      current_color * material.refraction.transparency
    end
  end

  def fresnel(incident, surface_normal, index_of_refraction)
    i_dot_n = incident.dot(surface_normal)
    eta_i = 1.0
    eta_t = index_of_refraction

    if i_dot_n > 0.0
      eta_i = eta_t
      eta_t = 1.0
    end

    sin_t = eta_i / eta_t * Math.sqrt([(1.0 - i_dot_n * i_dot_n), 0.0].max)
    return 1.0 if sin_t > 1.0 # total internal reflection

    cos_t = Math.sqrt([(1.0 - sin_t * sin_t), 0.0].max)
    cos_i = cos_t.abs
    r_s = ((eta_t * cos_i) - (eta_i * cos_t)) / ((eta_t * cos_i) + (eta_i * cos_t))
    r_p = ((eta_i * cos_i) - (eta_t * cos_t)) / ((eta_i * cos_i) + (eta_t * cos_t))

    (r_s * r_s + r_p * r_p) / 2.0
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

# frozen_string_literal: true

module Shape
  # @param [Point] hit_point
  # @return [Color] - base color (or texture color) at the hit_point,
  #   without taking other objects, lights, etc. into account.
  def base_color_at(hit_point)
    material.color_at(*texture_coordinates(hit_point))
  end
end
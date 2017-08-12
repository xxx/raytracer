# frozen_string_literal: true

class Color
  GAMMA = 2.2

  attr_reader :red, :green, :blue, :units

  def initialize(arg)
    case arg
    when String
      bytes = [arg.tr('#', '')].pack('H*').bytes
      # raise 'Pass an RRGGBB string, like HTML' unless bytes.length == 3
      @red, @green, @blue = bytes
    else
      @red, @green, @blue = arg[0..2]
    end
    @units = [@red / 255.0, @green / 255.0, @blue / 255.0]
  end

  def rgb
    [@red, @green, @blue]
  end

  def rgb_gamma
    @units.map { |c| (c**(1 / GAMMA)) * 255 }
  end

  def +(other)
    added = case other
            when Float
              @units.map { |unit| [unit + other, 1.0].min }
            when Color
              other_units = other.units
              @units.map.with_index { |unit, idx| [unit + other_units[idx], 1.0].min }
            else
              raise 'what are you giving me here?'
    end

    Color.new(added.map { |a| (a * 255).to_i })
  end

  def *(other)
    added = case other
            when Float
              @units.map { |unit| [unit * other, 1.0].min }
            when Color
              other_units = other.units
              @units.map.with_index { |unit, idx| [unit * other_units[idx], 1.0].min }
            else
              raise 'what are you giving me here?'
    end

    Color.new(added.map { |a| (a * 255).to_i })
  end

  def hex(sigil = '#')
    "#{sigil}#{format('%02x%02x%02x', @red, @green, @blue)}"
  end

  def hex_gamma(sigil = '#')
    "#{sigil}#{format('%02x%02x%02x', *rgb_gamma)}"
  end
end

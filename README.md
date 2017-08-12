# raytracer

A small ray tracer written in Ruby, based on
[this excellent series of posts](https://bheisler.github.io/post/writing-raytracer-in-rust-part-1/),
since I'd never written one before.

## Installation

1. Install Ruby 2.3+
1. Download this repo
1. `bundle`
1. `ruby script.rb`

Rendering is done in 4 threads and goes pretty quickly, but the final step of
drawing the image can take awhile (sometimes a few minutes, increasing with
the size of the output image). This drawing step is handled by ImageMagick.

`script.rb` has examples of image-based and programmatic textures, and changing
to save the rendered image to a file instead of displaying it is a one line
change to call `.write(filename)` rather than `display`.
#!/usr/bin/env ruby

require 'complex'
require 'rainbow'
require 'stringio'

class String
    # whiteness: between 0.0 and 1.0
    def grayscale whiteness
        whiteness *= 255
        whiteness = 255 if whiteness > 255
        self.color(whiteness, whiteness, whiteness)
    end
end

# Checks if complex number c is in the mandelbrot set after n iterations
# If yes, return nil
# If no, return the number of iterations it took to escape 
def mandelbrot c, n
    result = c
    (1..n).each do |n|
        if result.abs > 2
            return n
        end
        result = result*result + c
    end
    return nil
end

# Prints a number on the y axis of the plot
# Positive numbers have a preceeding space, so that they align with negatives
def print_num n
    prep = n < 0 ? "" : " "
    print "#{prep}%.2f | " % n
end

# Plots a rectangular graph from (-xmax, -ymax) to (xmax, ymax)
# xdiff and ydiff are deltas for adjacent pixels - i.e they determine resolution
# old points is the set of old computed points (for less iterations) or nil
def old_plot xmax, xmin, ymax, ymin, xdiff, ydiff, iterations, old_points
    puts "\e[H\e[2J" # clear screen
    ymax.step(ymin, -ydiff) do |y|
        print_num y
        (xmin).step(xmax, xdiff) do |x|
            itr = mandelbrot(Complex(x,y), iterations)
            #color = itr ? itr/iterations.to_f : 1.0
            #print "*".grayscale(color)
            whiteness = itr ? itr/iterations.to_f : 1
            print "*".grayscale(whiteness)
        end
        puts
    end
    (-xmax).step(xmax, xdiff) do |x|
        print_num x
    end
end

def plot xres, yres, iterations, points 
    points = Array.new(yres, Array.new(xres, nil)) unless points
    puts "\e[H\e[2J" # clear screen
    xmax, xmin = 1.0, -2.5
    ymax, ymin = 1.5, -1.5
    xstep = (xmax-xmin)/xres.to_f
    ystep = (ymax-ymin)/yres.to_f

    points.each_with_index do | col_vector, row |
        col_vector.each_with_index do | val, col |
            x = xmin+col*xstep
            y = ymax-row*ystep

            if x==xmin
                puts
                print_num y
            end

            # val is nil when it hasn't escaped, otherwise is the escape iteration 
            # this value hasn't escaped yet (TODO: keep the (n-1) val from before)
            if !val
                val = mandelbrot(Complex(x, y), iterations)
                # TODO: This should, cache the escape iteration for the future (it doesn't)
                # points[row][col] = val
            end

            # get print style
            if ARGV.length >= 1
                pstyle = ARGV[0].to_i
            else
                pstyle = 1
            end

            case pstyle
            when 0
                # grayscale
                whiteness = val ? val/iterations.to_f : 1
                print "*".grayscale(whiteness)
            when 1
                # colors are proportionate to the number of values tested
                red = val ? [10*val/iterations.to_f(), 1].min() : 1
                green = val ? [2*val/iterations.to_f(), 1].min() : 1
                blue = val ? [1*val/iterations.to_f(), 1].min() : 1
                print "*".color(red, blue*255, green*255)
            when 2
                # once we reach a certain value, everything remains the same
                red = val ? [10*val,255].min() : 255
                green = val ? [5*val,255].min() : 255
                blue = val ? [val,255].min() : 255
                print "*".color(red, blue, green)
            when 3
                # two colors only
                red = val ? [100*val/iterations.to_f(), 1].min() : 1
                blue = val ? [1*val/iterations.to_f(), 1].min() : 1
                print "*".color(red, blue*255, 255)
            end
        end
    end
    return points
end

# animate n times, passes each frame number to the block
def animate n
    buffer = StringIO.new
    old_stdout, $stdout = $stdout, buffer
    (1..n).each do |frame|
        yield frame
        old_stdout.write(buffer.string)
        buffer.string = ""
    end
    $stdout = old_stdout
end

points = nil
$vals = []
animate 100 do |iterations|
    points = plot 80, 30, iterations, points
end

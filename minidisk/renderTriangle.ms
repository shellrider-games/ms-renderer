gfx.clear color.clear, 480, 320
gfx.scale = 2
gfx.fillRect 0,0, gfx.width, gfx.height, color.lime

offset  = [gfx.width*0.5, gfx.height*0.5]

origin = [0,0]

drawPixel = function(position, color)
    gfx.setPixel position[0] + offset[0], position[1] + offset[1], color
end function


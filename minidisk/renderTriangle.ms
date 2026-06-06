gfx.clear color.clear, 480, 320
gfx.scale = 2
gfx.fillRect 0,0, gfx.width, gfx.height, color.lime

origin = [0,0]
unitScale = 64
offset  = [gfx.width*0.5/unitScale, gfx.height*0.5/unitScale]

drawPixel = function(position, color)
    gfx.setPixel unitScale * (position[0] + offset[0]),unitScale * ( position[1] + offset[1]), color
end function

drawTrianglepoints = function(triangle, color)
    for point in triangle
        drawPixel point, color
    end for
end function

triangle = [[-1,-0.42], [0,1], [1,-0.42]]
drawTrianglepoints triangle, color.fuchsia
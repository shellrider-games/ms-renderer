import "listUtil"

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

axisAlignedBoundingBox = function(points)
    xmin = points[0][0]
    xmax = points[0][0]
    ymin = points[0][1]
    ymax = points[0][1]
    for point in points
        if point[0] < xmin then xmin = point[0]
        if point[0] > xmax then xmax = point[0]
        if point[1] < ymin then ymin = point[1]
        if point[1] > ymax then ymax = point[1]
    end for
    return[xmin,xmax,ymin,ymax]
end function

triangle = [[-1,-0.42], [0,1], [1,-0.42]]
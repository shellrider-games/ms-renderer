clear
gfx.clear color.clear, 480, 360
gfx.scale = 3
gfx.fillRect 0,0, gfx.width, gfx.height, color.clear

origin = [0,0]
unitScale = 64
offset  = [(gfx.width/unitScale)*1/3, (gfx.height/unitScale)*1/3]

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

signedAreaForBarycentric = function(triangle)
    return (triangle[1][0]-triangle[0][0]) * (triangle[2][1] - triangle[0][1]) - (triangle[1][1] - triangle[0][1]) * (triangle[2][0] - triangle[0][0])
end function

edge = function(ax, ay, bx, by, px, py)
    return (px - ax) * (by - ay) - (py - ay) * (bx - ax)
end function

edgeTriangleFill = function(triangle)
    x0 = triangle[0][0]
    y0 = triangle[0][1]
    x1 = triangle[1][0]
    y1 = triangle[1][1]
    x2 = triangle[2][0]
    y2 = triangle[2][1]

    aabb = axisAlignedBoundingBox(triangle)
    area = signedAreaForBarycentric(triangle)
    reciprocalArea = 1/area

    xmin = aabb[0]
    xmax = aabb[1]
    ymin = aabb[2]
    ymax = aabb[3]

    step = 1 / unitScale
    halfStep = step * 0.5
    e0_dx = y1 - y0
    e0_dy = x0 - x1
    e1_dx = y2 - y1
    e1_dy = x1 - x2
    e2_dx = y0 - y2
    e2_dy = x2 - x0
    py = ymin + halfStep

    px = xmin + halfStep
    e0_row = edge(x0, y0, x1, y1, px, py)
    e1_row = edge(x1, y1, x2, y2, px, py)
    e2_row = edge(x2, y2, x0, y0, px, py)

    for y in range(ymin, ymax, step)
        e0 = e0_row
        e1 = e1_row
        e2 = e2_row
        for x in range(xmin, xmax, step)
            if e0 <= 0 and e1 <= 0 and e2 <= 0 then
                alpha = -e0*reciprocalArea
                beta = -e1*reciprocalArea
                gamma = -e2*reciprocalArea
                drawPixel [x, y], color.rgb(alpha*255, beta*255,gamma*255)
            end if
            e0 = e0 + e0_dx * step
            e1 = e1 + e1_dx * step
            e2 = e2 + e2_dx * step
        end for

        e0_row = e0_row + e0_dy * step
        e1_row = e1_row + e1_dy * step
        e2_row = e2_row + e2_dy * step
    end for
end function

triangle = [[-1,-0.42], [1,-0.42], [0,1]]

edgeTriangleFill triangle
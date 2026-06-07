clear
gfx.clear color.clear, 240, 160
gfx.scale = 4
gfx.fillRect 0,0, gfx.width, gfx.height, color.clear

origin = [0,0]
unitScale = 32
offset  = [gfx.width/4/unitScale, gfx.height/4/unitScale]

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

barycentricCoordinatesWithPrecalculatedArea = function(point, triangle, area)
    alpha = ((triangle[1][0] - point[0])*(triangle[2][1] - point[1]) - (triangle[1][1] - point[1]) * (triangle[2][0] - point[0])) / area
    beta = ((triangle[2][0] - point[0])*(triangle[0][1] - point[1]) - (triangle[2][1] - point[1]) * (triangle[0][0] - point[0])) / area
    gamma = 1 - alpha - beta
    return [alpha, beta, gamma]
end function

barycentricCoordinates = function(point, triangle)
    area = signedAreaForBarycentric(triangle)
    return barycentricCoordinatesWithPrecalculatedArea(point,triangle, area)
end function

drawTriangle = function(triangle)
    aabb = axisAlignedBoundingBox(triangle)
    area = signedAreaForBarycentric(triangle)
    for y in range(aabb[2], aabb[3], 1/unitScale)
        for x in range(aabb[0], aabb[1], 1/unitScale)
            baryCoords = barycentricCoordinatesWithPrecalculatedArea([x,y], triangle, area)
            if(baryCoords[0] >= 0 and baryCoords[1] >= 0 and baryCoords[2] >= 0) then drawPixel [x,y], color.rgb(baryCoords[0] * 255,baryCoords[1] * 255,baryCoords[2] * 255)
        end for
    end for
end function

edge = function(ax, ay, bx, by, px, py)
    return (px - ax) * (by - ay) - (py - ay) * (bx - ax)
end function

edgeTriangleFill = function(triangle, color)
    x0 = triangle[0][0]
    y0 = triangle[0][1]
    x1 = triangle[1][0]
    y1 = triangle[1][1]
    x2 = triangle[2][0]
    y2 = triangle[2][1]

    aabb = axisAlignedBoundingBox(triangle)

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
            if e0 >= 0 and e1 >= 0 and e2 >= 0 then
                gfx.setPixel unitScale * (x + offset[0]),unitScale * (y + offset[1]), color
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

triangle = [[-1,-0.42], [0,1], [1,-0.42]]

triangle2 = [[-2, 0], [-2,1], [-1, 0]]

t0 = time
edgeTriangleFill triangle, color.fuchsia
edgeTriangleFill triangle2, color.lime
t1 = time

print "Rendered in " + (t1 - t0) + " seconds."
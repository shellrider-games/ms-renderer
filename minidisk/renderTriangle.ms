import "listUtil"

clear
gfx.fillRect 0,0, gfx.width, gfx.height, color.clear

origin = [0,0]
unitScale = 32
offset  = [(gfx.width/unitScale)*0.5, (gfx.height/unitScale)*0.5]

maxDepth = 10
zBuffer = list.init(gfx.width * gfx.height, maxDepth)

textureCache = null
cachedTexturePath = null


drawPixel = function(position, color)
    gfx.setPixel unitScale * (position[0] + offset[0]),unitScale * ( position[1] + offset[1]), color
end function

interpolate5 = function(alpha, beta, gamma, a, b, c)
    return [
        alpha * a[0] + beta * b[0] + gamma * c[0],
        alpha * a[1] + beta * b[1] + gamma * c[1],
        alpha * a[2] + beta * b[2] + gamma * c[2],
        alpha * a[3] + beta * b[3] + gamma * c[3],
        alpha * a[4] + bata * b[4] + gamma * c[4]]
end function

interpolateUV = function(alpha, beta, gamma, a, b, c)
    ui = alpha * (a[3]/a[2]) + beta * (b[3]/b[2]) + gamma * (c[3]/c[2])
    vi = alpha * (a[4]/a[2]) + beta * (b[4]/b[2]) + gamma * (c[4]/c[2])
    wi = alpha * (1/a[2]) + beta * (1/b[2]) + gamma * (1/c[2])

    return [
        ui/wi,
        vi/wi]
end function


sampleChecker = function(u, v)
    iu = floor(u * 8)
    iv = floor (v * 8)
    if (iu + iv) % 2 then
        return color.black
    else
        return color.white
    end if
end function

sampleTexture = function(u, v, path)
    if outer.cachedTexturePath != path then
        outer.cachedTexturePath = path
        outer.textureCache = file.loadImage(outer.cachedTexturePath)
    end if
    iu = floor(u*(outer.textureCache.width-1))
    iv = floor(v*(outer.textureCache.height-1))
    return outer.textureCache.pixel(iu, iv)
end function

projectVertex = function(vertex)
    x = vertex[0]
    y = vertex[1]
    z = vertex[2]
    u = vertex[3]
    v = vertex[4]

    near = 0.1
    f = 4
    if z <= near then return null
    return [f*x/z, f*y/z, z, u, v]
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

edgeTriangleFill = function(triangle, col)
    x0 = triangle[0][0]
    y0 = triangle[0][1]
    x1 = triangle[1][0]
    y1 = triangle[1][1]
    x2 = triangle[2][0]
    y2 = triangle[2][1]

    aabb = axisAlignedBoundingBox(triangle)
    area = signedAreaForBarycentric(triangle)
    if area == 0 then return
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
                gamma = -e0*reciprocalArea
                alpha = -e1*reciprocalArea
                beta = -e2*reciprocalArea
                z = alpha * triangle[0][2] + beta * triangle[1][2] + gamma * triangle[2][2]
                screen_x = floor(unitScale * (x + offset[0]))
                screen_y = floor(unitScale * (y + offset[1]))

                if screen_x < 0 or screen_x > gfx.width then continue
                if screen_y < 0 or screen_y > gfx.height then continue

                if zBuffer[screen_y*gfx.width+screen_x] >= z then
                    zBuffer[screen_y*gfx.width+screen_x] = z
                    if col then
                        gfx.setPixel screen_x,screen_y, col
                    else
                        uv = interpolateUV(alpha, beta, gamma, triangle[0], triangle[1], triangle[2])
                        renderColor = sampleTexture(uv[0], uv[1], "textures/uvChecker.png")
                        gfx.setPixel screen_x,screen_y, renderColor
                    end if
                end if
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

projectTriangle = function(triangle)
    p0 = projectVertex(triangle[0])
    p1 = projectVertex(triangle[1])
    p2 = projectVertex(triangle[2])

    if p0 and p1 and p2 then return [p0, p1, p2]
    return null
end function

renderTriangle = function(triangle, col)
    projected = projectTriangle(triangle)
    if projected then edgeTriangleFill(projected, col)    
end function

triangle = [[-0.5, -0.5, 1, 0, 0], [0.5,-0.5, 2, 1, 0], [0.5, 0.5 , 2, 1, 1]]
triangle2 = [[-0.5, -0.5, 1, 0, 0], [0.5, 0.5, 2, 1, 1], [-0.5, 0.5, 1, 0, 1]]

renderTriangle triangle2
renderTriangle triangle

import "listUtil"

clear
gfx.fillRect 0,0, gfx.width, gfx.height, color.clear

origin = [0,0]
unitScale = 32
offset  = [(gfx.width/unitScale)*0.5, (gfx.height/unitScale)*0.5]
maxDepth = 10
xScale = gfx.width/gfx.height
zBuffer = list.init(gfx.width * gfx.height, maxDepth)

textureCache = null
cachedTexturePath = null

sunDirection = [1,-1, 0.3]
sunLen = sqrt(sunDirection[0] * sunDirection[0] + sunDirection[1] * sunDirection[1] + sunDirection[2] * sunDirection[2])
sunDirection = [sunDirection[0]/sunLen, sunDirection[1]/sunLen, sunDirection[2]/sunLen]
ambient = [0.4, 0.4, 0.4, 0]


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

v3cross = function(v1, v2)
    return [
        v1[1]*v2[2]-v1[2]*v2[1],
        v1[2]*v2[0]-v1[0]*v2[2],
        v1[0]*v2[1]-v1[1]*v2[0]]
end function

v3minus = function(v1, v2)
    return[v1[0]-v2[0],v1[1]-v2[1],v1[2]-v2[2]]
end function

v3len = function(v)
    return sqrt(v[0]*v[0]+v[1]*v[1]+v[2]*v[2])
end function

calculateNormal = function(triangle)
    v1 = v3minus (triangle[1], triangle[0])
    v2 = v3minus (triangle[2], triangle[0])
    cross = v3cross(v1, v2)
    normLen = v3len(cross)
    norm = [cross[0]/normLen, cross[1]/normLen, cross[2]/normLen]
    return norm
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
    f = 6
    if z <= near then return null
    return [(f*x*xScale)/z, (f*y)/z, z, u, v]
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

edgeTriangleFill = function(triangle, normal, col)
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
                        lambert = [0,normal.dot(sunDirection)].max
                        colList = color.toList(col)
                        gfx.setPixel screen_x,screen_y, color.rgb(colList[0]*(lambert+ambient[0]), colList[1]*(lambert+ambient[1]), colList[2]*(lambert+ambient[2]))
                    else
                        uv = interpolateUV(alpha, beta, gamma, triangle[0], triangle[1], triangle[2])
                        renderColor = sampleTexture(uv[0], uv[1], "textures/uvChecker.png")
                        lambert = [0,normal.dot(sunDirection)].max
                        colList = color.toList(renderColor)
                        gfx.setPixel screen_x,screen_y, color.rgb(colList[0]*(lambert+ambient[0]), colList[1]*(lambert+ambient[1]), colList[2]*(lambert+ambient[2]))
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
    normal = calculateNormal(triangle)
    if projected then edgeTriangleFill(projected, normal, col)    
end function

translate = function(vertex, v3)
    return [
        vertex[0] + v3[0],
        vertex[1] + v3[1],
        vertex[2] + v3[2],
        vertex[3],
        vertex[4]]
end function

rotateX = function(v, degrees)
	radians = degrees * pi / 180
	c = cos(radians)
	s = sin(radians)

	return [
		v[0],
		v[1] * c - v[2] * s,
		v[1] * s + v[2] * c,
		v[3],
		v[4]]
end function

rotateY = function(v, degrees)
	radians = degrees * pi / 180
	c = cos(radians)
	s = sin(radians)

	return [
		v[0] * c + v[2] * s,
		v[1],
		-v[0] * s + v[2] * c,
        v[3],
        v[4]]
end function

rotateZ = function(v, degrees)
	radians = degrees * pi / 180
	c = cos(radians)
	s = sin(radians)

    return [
		v[0] * c - v[1] * s,
		v[0] * s + v[1] * c,
		v[2],
		v[3],
		v[4]]
end function

triangle1 = [[-0.5, -0.5, -0.5, 0, 0], [0.5,-0.5, -0.5, 1, 0], [0.5, 0.5 , -0.5, 1, 1]]
triangle2 = [[-0.5, -0.5, -0.5, 0, 0], [0.5, 0.5, -0.5, 1, 1], [-0.5, 0.5, -0.5, 0, 1]]
triangle3 = [[0.5, -0.5, -0.5, 0, 0], [0.5,-0.5, 0.5, 1, 0], [0.5, 0.5 , 0.5, 1, 1]]
triangle4 = [[0.5, -0.5, -0.5, 0, 0], [0.5, 0.5, 0.5, 1, 1], [0.5, 0.5, -0.5, 0, 1]]
triangle5 = [[-0.5, 0.5, -0.5, 0,0], [0.5, 0.5, -0.5, 1, 0], [0.5, 0.5, 0.5, 1, 1]]
triangle6 = [[-0.5, 0.5, -0.5, 0,0], [0.5, 0.5, 0.5, 1, 1], [-0.5, 0.5, 0.5, 0, 1]]
triangle7 = [[-0.5, -0.5, 0.5, 0, 0], [0.5, 0.5, 0.5, 1, 1], [0.5, -0.5, 0.5, 1, 0]]
triangle8 = [[-0.5, -0.5, 0.5, 0, 0], [-0.5, 0.5, 0.5, 0, 1], [0.5, 0.5, 0.5, 1, 1]]
triangle9 = [[-0.5, -0.5, -0.5, 0, 0], [-0.5, 0.5, 0.5, 1, 1], [-0.5, -0.5, 0.5, 1, 0]]
triangle10 = [[-0.5, -0.5, -0.5, 0, 0], [-0.5, 0.5, -0.5, 0, 1], [-0.5, 0.5, 0.5, 1, 1]]
triangle11 = [[-0.5, -0.5, -0.5, 0, 0],[0.5, -0.5, 0.5, 1, 1],[0.5, -0.5, -0.5, 1, 0]]
triangle12 = [[-0.5, -0.5, -0.5, 0, 0], [-0.5, -0.5, 0.5, 0, 1], [0.5, -0.5, 0.5, 1, 1]]

cube = [triangle1, triangle2, triangle3, triangle4, triangle5, triangle6, triangle7, triangle8, triangle9, triangle10, triangle11, triangle12]

for tri in cube
    transformed = []
    for p in tri
        rotated = rotateZ(p, 0)
        rotated = rotateY(rotated, 40.89339465)
        rotated = rotateX(rotated, -33)
  
        translated = translate(rotated, [0,0,2])
        transformed.push translated
    end for
    renderTriangle transformed
end for

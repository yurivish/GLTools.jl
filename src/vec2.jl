# TODO: Parameterize by type
immutable Vec2
	x::GLfloat
	y::GLfloat
end
Base.getindex(a::Vec2, n) = n == 1 ? a.x : n == 2 ? a.y : error("Invalid Vec2 index: $n")
Base.length(a::Vec2) = 2
Base.norm(a::Vec2) = sqrt(a.x^2 + a.y^2)
normalize(a::Vec2) = a / norm(a)
flipx(a::Vec2) = Vec2(-a.x, a.y)
flipy(a::Vec2) = Vec2(a.x, -a.y)

-(a::Vec2) = Vec2(-a.x, -a.y)
-(a::Vec2, b::Vec2) = Vec2(a.x - b.x, a.y - b.y)
-(a::Vec2, b::Number) = Vec2(a.x - b, a.y - b)

+(a::Vec2, b::Vec2) = Vec2(a.x + b.x, a.y + b.y)
+(a::Number, b::Vec2) = Vec2(a + b.x, a + b.y)
+(a::Vec2, b::Number) = Vec2(a.x + b, a.y + b)

*(a::Vec2, b::Vec2) = Vec2(a.x * b.x, a.y * b.y)
*(a::Number, b::Vec2) = Vec2(a * b.x, a * b.y)
*(a::Vec2, b::Number) = Vec2(a.x * b, a.y * b)

/(a::Vec2, b::Vec2) = Vec2(a.x / b.x, a.y / b.y)
/(a::Vec2, b::Number) = Vec2(a.x / b, a.y / b)

⋅(a::Vec2, b::Vec2) = a.x * b.x + a.y * b.y # dot product
×(a::Vec2, b::Vec2) = a.x * b.y - a.y * b.x # 2d cross product

# http://mathworld.wolfram.com/Collinear.html
collinear(a::Vec2, b::Vec2, c::Vec2) = abs(a.x * (b.y - c.y) + b.x * (c.y - a.y) + c.x * (a.y - b.y)) < 0.00001

Base.rand(::Type{Vec2}) = Vec2(rand(GLfloat), rand(GLfloat))

rot90l(a::Vec2) = Vec2(-a.y,  a.x)
rot90r(a::Vec2) = Vec2( a.y, -a.x)

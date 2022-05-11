tag_pixel_width = 45#37
w = ceil(Int, tag_pixel_width*sqrt(2))
const min_widths = Vec2{Int}(w)
const widen = 5

frame2tag(frame, rect, detector) = detect(detector, crop(frame, rect))

function detect(detector, img)
  tags = detector(img)
  length(tags) ≠ 1 ? nothing : only(tags)
end

function crop(img, rect)
  ij1 = origin(rect)
  ij2 = ij1 + widths(rect) .- 1
  i, j = UnitRange{Int64}.(ij1, ij2)
  img[i, j]
end

tag2c(::Nothing) = nothing
tag2c(tag) = Vec2f(reverse(tag.H[1:2,3]))

tag2direction(::Nothing, ::Nothing) = nothing
tag2direction(tag, c) = normalize(sum(p -> Vec2f(reverse(p)) - c, tag.p[1:2]))

c2point(::Nothing, orig) = nothing
c2point(c, orig) = c + orig

function update_rect!(rect, ::Nothing) 
  o = max.(origin(rect[]) .- widen, (1,1))
  w = widths(rect[]) .+ 2widen
  s = min.(o + w .- 1, wh)
  rect[] = Rect2i(o, s - o .+ 1)
end

function update_rect!(rect, point)
  o = max.(round.(Int, point - min_widths/2), (1,1))
  s = min.(o + min_widths .- 1, wh)
  rect[] = Rect2i(o, s - o .+ 1)
end

# tag2direction(::Nothing) = nothing
# function tag2direction(tag) 
#   c = Vec2f(tag.H[1:2,3])
#   normalize(sum(p -> Vec2f(p) - c, tag.p[1:2]))
# end
#
# function update_rect!(rect, ::Nothing) 
#   o = max.(origin(rect[]) .- widen, (1,1))
#   w = widths(rect[]) .+ 2widen
#   s = min.(o + w .- 1, wh)
#   rect[] = Rect2i(o, s - o .+ 1)
# end
# function update_rect!(rect, tag)
#   o = max.(round.(Int, origin(rect[]) - min_widths/2 + reverse(tag.H[1:2,3])), (1,1))
#   s = min.(o + min_widths .- 1, wh)
#   rect[] = Rect2i(o, s - o .+ 1)
# end

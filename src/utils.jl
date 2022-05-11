round2deg(x) = string(round(Int, rad2deg(x)), "°")

Base.close(d::AprilTagDetector) = d.td ≠ C_NULL && freeDetector!(d)

function close_all()
  close(log[])
  close(camera[])
  isopen(strip[]) && update_strip!(strip[], zeros(5)...)
  close(strip[])
  close(detector[])
  nothing
end

function intensity_distribution(μ, σ, support)
    σ == 0 && return () -> μ
    w = pdf.(Normal(μ, σ), support)
    w ./= sum(w)
    d = DiscreteNonParametric(support, w)
    () -> rand(d)
end

invok(f) = f()
v2fun(v) = () -> v

# dark = false
# if dark
#   set_theme!(theme_black(); textcolor = :grey30)
#   sliderkw = Dict(:color_active_dimmed => :grey30, :color_active => :grey20, :color_inactive => :grey10)
# else
#   set_theme!()
#   sliderkw = Dict()
# end
#
#

# frame, roi, x, ab, settings = containers()
# fig = figure(frame, roi, x, ab, settings)
# rect = Ref(Rect2i((1,1), wh))
# rotations = Ref(0.0)
# oldu = Ref(Vec2f(1,0))

# n = 100
# ts = zeros(n)
# for i in 1:n
#   oneiteration(rect, oldu, rotations, x[], ab[])
#   yield()
#   ts[i] = time()
# end
# histogram(filter(<(60), 1 ./ diff(ts)))
# median(filter(<(60), round.(Int, 1 ./ diff(ts))))
#
# using BenchmarkTools
# @benchmark oneiteration($rect, $oldu, $rotations, $(x[]), $(ab[]))
#
# 64, 72 ms
#
# #
#
#
# function get_img_with_tag()
#   while isopen(camera[])
#     img = snap(camera[])
#     tag = frame2tag(img, rect[], detector[])
#     if !isnothing(tag)
#       return img
#     end
#   end
# end
# frame, roi, x, ab, settings = containers()
# rect = Ref(Rect2i((1,1), wh))
# rotations = Ref(0.0)
# oldu = Ref(Vec2f(1,0))
# img = get_img_with_tag()
#

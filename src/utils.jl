intensity_distribution(xs...) = _intensity_distribution.(Iterators.partition(xs, 5)..., (0:255, 0:255, 0:255, 1:2:nleds, range(0, step = 2π/nleds, length = nleds)))
function _intensity_distribution(μ, σ, support)
  σ == 0 && return DiscreteNonParametric([μ], [1.0]) 
  w = pdf.(Normal(μ, σ), support)
  w ./= sum(w)
  DiscreteNonParametric(support, w)
end

round2deg(x) = string(round(Int, rad2deg(x)), "°")

function close_all()
  close(camera)
  update_strip!(strip, zeros(5)...)
  close(strip)
  freeDetector!(detector)
end

# dark = false
# if dark
#   set_theme!(theme_black(); textcolor = :grey30)
#   sliderkw = Dict(:color_active_dimmed => :grey30, :color_active => :grey20, :color_inactive => :grey10)
# else
#   set_theme!()
#   sliderkw = Dict()
# end

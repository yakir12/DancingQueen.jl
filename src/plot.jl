const supports = (0:255, 0:255, 0:255, 1:2:nleds, range(0, step = 2π/nleds, length = nleds))

function figure(frame, roi, x, ab, settings)
  fig = Figure()
  ax = Axis(fig[1,1], aspect = AxisAspect(wh[1] / wh[2]))
  image!(ax, frame)
  poly!(ax, roi, color = :transparent, strokecolor = :red, strokewidth = 1, xautolimits=false, yautolimits=false)
  hidedecorations!(ax)
  hidespines!(ax)

  controls = fig[2,1] = GridLayout()
  ledsgrid = SliderGrid(controls[1,1], 
                        (label = "red", range = 0:255),
                        (label = "green", range = 0:255),
                        (label = "red", range = 0:255),
                        (label = "width", range = 1:2:nleds),
                        (label = "azimuth", range = range(0, step = 2π/nleds, length = nleds), format = round2deg))
  noisegrid = SliderGrid(controls[1,2], 
                         (; label = "", range = 0:50),
                         (; label = "", range = 0:50),
                         (; label = "", range = 0:50),
                         (; label = "", range = 0:30),
                         (label = "", range = range(0, π/2, 50), format = round2deg))
  dynamicgrid = SliderGrid(controls[2,:], 
                           (label = "a", range = 0:0.1:2, format = "{:.1f}"),
                           (label = "b", range = range(0, step = 2π/nleds, length = nleds), format = round2deg))
  record = Toggle(fig, active = false)
  record_label = Label(fig, map(x -> x ? "Recording!" : "Not recording", record.active))
  controls[3, :] = grid!(hcat(record, record_label))
  fig[2,1] = controls

  μobs = [s.value for s in ledsgrid.sliders]
  σobs = [s.value for s in noisegrid.sliders]
  onany(μobs..., σobs...) do μσs...
    μs = Tuple(μσs[1:5])
    σs = Tuple(μσs[6:10])
    x[] = intensity_distribution.(μs, σs, supports)
  end

  dynobs = [s.value for s in dynamicgrid.sliders]
  onany(dynobs...) do a, b
    ab[] = p -> mod(a*p + b, 2π)
  end

  onany(μobs..., σobs..., dynobs...) do xs...
    settings[] = Tuple(xs)
  end

  on(tf -> tf ? open(log[]) : close(log[]), record.active)

  fig
end


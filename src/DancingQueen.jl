module DancingQueen

using Statistics, Dates, LinearAlgebra
using VideoIO, GLMakie, AprilTags, LibSerialPort, Distributions, AngleBetweenVectors, Observables, ImageCore, Formatting, Glob, FFMPEG

using GLMakie: origin, widths

export main, close_all

const O = Observable

include("logs.jl")
include("leds.jl")
include("camera.jl")
include("detect.jl")
include("utils.jl")

function main()

  strip = Strip()
  camera = Camera()
  detector = AprilTagDetector()
  detector.nThreads = Threads.nthreads()

  frame = O(camera.img)
  rect = O(Rect2i((1,1), wh))
  tag = O{Union{Nothing, AprilTag}}(nothing)

  map!(img -> frame2tag(img, rect[], detector), tag, frame)
  map!(t -> change_rect(rect[], t), rect, tag)
  corners = map(t -> tag2corners(t, rect[]), tag)

  fig = Figure()
  ax = Axis(fig[1,1], aspect = AxisAspect(wh[1] / wh[2]))
  image!(ax, frame)
  poly!(ax, corners, color = RGBAf(0,1,0,0.9))
  poly!(ax, rect, color = :transparent, strokecolor = :red, strokewidth = 1, xautolimits=false, yautolimits=false)
  hidedecorations!(ax)
  hidespines!(ax)

  ledsgrid = labelslidergrid!(fig, ["red", "green", "blue", "width", "azimuth"], (0:255, 0:255, 0:255, 1:2:nleds, range(0, step = 2π/nleds, length = nleds)); formats = ["{:n}", "{:n}", "{:n}", "{:n}", round2deg])#, sliderkw)
  controls = GridLayout()
  controls[1,1] = ledsgrid.layout
  noisegrid = labelslidergrid!(fig, fill("", 5), [0:50, 0:50, 0:50, 0:30, range(0, π/2, 50)]; formats = ["{:n}", "{:n}", "{:n}", "{:n}", round2deg])#, sliderkw)
  controls[1,2] = noisegrid.layout
  dynamicgrid = labelslidergrid!(fig, ["a", "b"], (0:0.1:2, range(0, step = 2π/nleds, length = nleds)); formats = ["{:.1f}", round2deg])#, sliderkw)
  controls[2,:] = dynamicgrid.layout
  record = Toggle(fig, active = false)
  record_label = Label(fig, map(x -> x ? "Recording!" : "Not recording", record.active))
  controls[3, :] = grid!(hcat(record, record_label))
  fig[2,1] = controls

  ledsobs = [s.value for s in ledsgrid.sliders]
  onany((xs...) -> update_strip!(strip, xs...), ledsobs...)

  noiseobs = [s.value for s in noisegrid.sliders]
  vs = map(intensity_distribution, ledsobs..., noiseobs...)

  dynamicobs = [s.value for s in dynamicgrid.sliders]

  p = Ref(0.0)
  oldu = Ref(Point2f(1,0))
  on(xys -> dynamic_update(strip, xys, oldu, p, to_value(vs), to_value.(dynamicobs)...), corners)

  row = map(corners) do xys
    Iterators.flatten((reduce(vcat, xys), to_value.(ledsobs), to_value.(noiseobs), to_value.(dynamicobs)))
  end

  log = O{Union{Nothing, Log}}(nothing)
  map!(log, record.active) do tf
    if tf 
      Log(frame, row)
    else
      close(log[])
      nothing
    end
  end

  display(fig)

  t = @async while isopen(camera)
    frame[] = snap(camera)
    yield()
  end

  return strip, camera, detector

end

# strip, camera, detector = main()

# close_all(strip, camera, detector)

end

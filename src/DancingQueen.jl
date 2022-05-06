module DancingQueen

using Statistics, Dates, LinearAlgebra
using VideoIO, GLMakie, AprilTags, LibSerialPort, Distributions, AngleBetweenVectors, Observables, ImageCore, Formatting, Glob, FFMPEG

using GLMakie: origin, widths

export main, close_all

include("logs.jl")
include("leds.jl")
include("camera.jl")
include("detect.jl")
include("utils.jl")

const O = Observable
const strip = Strip()
const camera = Camera()
const detector = AprilTagDetector()
# detector.nThreads = Threads.nthreads()

function main()

  frame = O(camera.img)
  rect = O(Rect2i((1,1), wh))
  tag = O{Union{Nothing, AprilTag}}(nothing)
  direction = O{Union{Nothing, Vec2f}}(nothing)

  map!(img -> frame2tag(img, rect[], detector), tag, frame)
  map!(tag2direction, direction, tag)
  map!(t -> change_rect(rect[], t), rect, tag)

  fig = Figure()
  ax = Axis(fig[1,1], aspect = AxisAspect(wh[1] / wh[2]))
  image!(ax, frame)
  poly!(ax, rect, color = :transparent, strokecolor = :red, strokewidth = 1, xautolimits=false, yautolimits=false)
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

  ledsobs = [s.value for s in ledsgrid.sliders]
  onany((xs...) -> update_strip!(strip, xs...), ledsobs...)

  noiseobs = [s.value for s in noisegrid.sliders]
  vs = map(intensity_distribution, ledsobs..., noiseobs...)

  dynamicobs = [s.value for s in dynamicgrid.sliders]

  rotations = Ref(0.0)
  oldu = Ref(Vec2f(1,0))
  on(direction) do u
    @async dynamic_update(strip, u, oldu, rotations, to_value(vs), to_value.(dynamicobs)...)
  end

  row = map(direction) do u
    @async Iterators.flatten((mean(rect[]), atan(u...), rotations[], to_value.(ledsobs), to_value.(noiseobs), to_value.(dynamicobs)))
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

  t = @async while isopen(camera) && events(fig.scene).window_open[]
    frame[] = snap(camera)
    yield()
  end

  return t

  # return strip, camera, detector

end

# strip, camera, detector = main()

# close_all(strip, camera, detector)

end

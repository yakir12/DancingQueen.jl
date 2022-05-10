const fspec = FormatExpr("{:07d}.jpg")

framename(dt, i) = joinpath(dt, format(fspec, i))

mutable struct Log
  open::Bool
  name::String
  csvio::IOStream
  i::Int
end

function Log() 
  io = open(tempname(), "w")
  close(io)
  Log(false, "tmp", io, 0)
end

function Base.open(log::Log)
  dt = Dates.format(now(), "yyyymmddHHMMSS")
  mkpath(dt)
  csvio = open(joinpath(dt, "data.csv"), "w")
  println(csvio, "datetime,x,y,rotations,red,green,blue,width,azimuth,red_σ,green_σ,blue_σ,width_σ,azimuth_σ,a,b")
  log.name = dt
  log.csvio = csvio
  log.i = 0
  log.open = true
end

function Base.close(log::Log)
  log.open = false
  close(log.csvio)
  save2vid(log.name)
end

torow(::Nothing, rotations, settings) = join((now(), missing, rotations, settings...), ',')
torow(point, rotations, settings) = join((now(), point, rotations, settings...), ',')

function update_log(log::Log, point, rotations, settings, img)
  if log.open
    println(log.csvio, torow(point, rotations, settings))
    log.i += 1
    save(framename(log.name, log.i), img)
  end
end

function save2vid(fldr)
  files_in = joinpath(fldr, "*.jpg")
  file_out = joinpath(fldr, "video.mp4")
  ffmpeg_exe(`-framerate 15 -pattern_type glob -i $files_in -c:v libx264 -r 15 -pix_fmt gray -loglevel 16 $file_out`)
  foreach(rm, glob(files_in))
  @info "done saving $fldr"
end

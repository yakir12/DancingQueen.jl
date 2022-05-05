struct Log

  name::String
  csvio::IOStream
  # videoio::VideoIO.VideoWriter
  csvof::Observables.ObserverFunction
  videoof::Observables.ObserverFunction

  function Log(frame, row)

    dt = Dates.format(now(), "yyyymmddHHMMSS")
    mkpath(dt)

    csvio = open(joinpath(dt, "data.csv"), "w")
    println(csvio, "datetime,p1x,p1y,p2x,p2y,p3x,p3y,p4x,p4y,red,green,blue,width,azimuth,red_σ,green_σ,blue_σ,width_σ,azimuth_σ,a,b")

    csvof = on(row) do r
      println(csvio, now(), ",", join(r, ","))
    end

    fspec = FormatExpr("{:07d}.jpg")
    i = 0
    videoof = on(frame) do img
      i += 1
      isodd(i) && save(joinpath(dt, format(fspec, i)), img')
    end

    new(dt, csvio, csvof, videoof)
  end
end

function Base.close(l::Log) 
  off(l.csvof)
  close(l.csvio)
  off(l.videoof)
  @async save2vid(l.name)
end

Base.close(::Nothing) = nothing

function save2vid(fldr)
  files_in = joinpath(fldr, "%07d.jpg")
  file_out = joinpath(fldr, "video.mp4")
  ffmpeg_exe(` -framerate 15 -i $files_in -c:v libx264 -vf fps=15 -pix_fmt gray -loglevel 16 $file_out`)
  rm.(glob("$fldr/*.jpg"))
  @info "done saving $fldr"
end

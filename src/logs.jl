struct Log

  csvio::IOStream
  videoio::VideoIO.VideoWriter
  csvof::Observables.ObserverFunction
  videoof::Observables.ObserverFunction

  function Log(frame, row)

    dt = Dates.format(now(), "yyyymmddHHMMSS")

    csvio = open(string(dt, ".csv"), "w")
    println(csvio, "datetime,p1x,p1y,p2x,p2y,p3x,p3y,p4x,p4y,red,green,blue,width,azimuth,red_σ,green_σ,blue_σ,width_σ,azimuth_σ,a,b")

    framerate = 5
    encoder_options = (crf=23, preset="medium")
    videoio = open_video_out(string(dt, ".mp4"), rotl90(frame[]); framerate, encoder_options)

    csvof = on(row) do r
      println(csvio, now(), ",", join(r, ","))
    end

    t₀ = time_ns()
    videoof = on(frame) do img
      t = time_ns()
      if t - t₀ > 1000000000/framerate
        write(videoio, rotl90(img))
        t₀ = t
      end
    end

    new(csvio, videoio, csvof, videoof)
  end
end

function Base.close(l::Log) 
  off(l.csvof)
  close(l.csvio)
  off(l.videoof)
  close_video_out!(l.videoio)
  println("done saving!")
end

Base.close(::Nothing) = nothing


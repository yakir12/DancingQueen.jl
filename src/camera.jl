const w = 640
const h = 480
const wh = (w, h)

struct Camera
  device::String
  o::VideoIO.VideoReader
  buff::Vector{UInt8}
  img
  function Camera()
    device = get_device()
    o = opencamera(device; transcode = false)
    nb, buff = create_buffer(o)
    b = view(buff, 1:2:nb)
    h1, w1 = wh
    Y = reshape(b, h1, w1)
    img = colorview(Gray, normedview(view(Y, h1:-1:1, 1:w1)))
    new(device, o, buff, img)
  end
end

function get_image_dimensions(device)
  camera = opencamera(device)
  img = read(camera)
  close(camera)
  return size(img)
end

good_camera(device) = try
  return get_image_dimensions(device) == reverse(wh)
catch ex
  return false
end

function get_device()
VideoIO.init_camera_devices()
VideoIO.init_camera_settings()
VideoIO.DEFAULT_CAMERA_OPTIONS["video_size"] = "$(w)x$h"
VideoIO.DEFAULT_CAMERA_OPTIONS["framerate"] = 30
  cameras = VideoIO.CAMERA_DEVICES
  i = findfirst(good_camera, cameras)
  isnothing(i) && throw("No camera found")
  cameras[i]
end

function create_buffer(o)
  img = read(o)
  nb = length(img)
  return (nb, Vector{UInt8}(undef, nb))
end

Base.close(camera::Camera) = close(camera.o)
Base.isopen(camera::Camera) = isopen(camera.o)

function snap(camera)
  read!(camera.o, camera.buff)
  camera.img
end

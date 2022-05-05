const baudrate = 115200#9600##921600#
const nleds = 120

struct Strip
  sp::SerialPort
  buffer::Vector{UInt8}

  function Strip()
    port = get_port()
    sp = open(port, baudrate)
    buffer = zeros(UInt8, 5)
    new(sp, buffer)
  end
end

α2led(α) = round(Int, nleds*α/2π + 0.5 + eps(Float64))

function α2leds(w, α)
  δ = (w - 1)*π/nleds
  α1 = mod(α - δ, 2π)
  α2 = mod(α + δ, 2π)
  return α2led(α1), α2led(α2)
end

update_buffer!(buffer, bs...) = for (i, b) in enumerate(bs)
  buffer[i] = b
end

good_port(port) = try
  sp = open(port, baudrate)
  sleep(0.1)
  close(sp)
  sleep(0.1)
  return true
catch ex
  return false
end

function get_port()
  ports = get_port_list()
  i = findfirst(good_port, ports)
  isnothing(i) && throw("No LED strip found")
  ports[i]
end

function update_strip!(strip, r, g, b, w, α)
  i1, i2 = α2leds(w, α)
  update_buffer!(strip.buffer, r, g, b, i1, i2)
  write(strip.sp, strip.buffer)
end

Base.close(strip::Strip) = close(strip.sp)
Base.open(strip::Strip) = open(strip.sp)

function dynamic_update(strip, corners, oldu, p, vs, a, b)
  if !all(iszero, corners)
    c = mean(corners)
    u = normalize(mean(corners[1:2]) - c)
    δ = angle_between(oldu[], u)
    oldu[] = u
    p[] += δ
    red, green, blue, width, α = rand.(vs)
    α += mod(a*p[] + b, 2π)
    update_strip!(strip, red, green, blue, width, α)
  end
end

function angle_between(oldu, newu)
  x1, y1 = oldu
  x2, y2 = newu
  sign((x2 - x1)*(y2 + y1))*angle(oldu, newu)
end


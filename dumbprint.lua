function print(x, ...)
  io.write(tostring(x))
  if select("#",...) > 0 then
    io.write("\t")
    return print(...)
  else
    io.write("\n")
  end
end
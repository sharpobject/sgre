local select, stderr = select, io.stderr
function print(...)
  for i=1,select("#", ...) do
    if i>1 then
      stderr:write("\t")
    end
    stderr:write(tostring(select(i, ...)))
  end
  stderr:write("\n")
end

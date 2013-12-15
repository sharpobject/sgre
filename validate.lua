local type = type

function check_username(s)
  if type(s) ~= "string" then
    return false, "Username must be a string"
  elseif s:len() > 12 or s:len() < 3 then
    return false, "Username must be 3-12 characters"
  elseif s:match("[a-zA-Z0-9]+"):len() ~= s:len() then
    return false, "Username can only contain letters and numbers"
  end
  return true
end

function check_email(s)
  if type(s) ~= "string" then
    return false, "Email must be a string"
  elseif s:len() > 100 or s:len() < 3 then
    return false, "Email must be 3-100 characters"
  elseif not s:match(".+@.+") then
    return false, "Email must be stuff, then @, then more stuff"
  end
  return true
end

function check_password(s)
  if type(s) ~= "string" then
    return false, "Password must be a string"
  elseif s:len() < 6 or s:len() > 100 then
    return false, "Password must be 6-100 characters"
  end
  return true
end
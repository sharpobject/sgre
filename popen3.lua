--
-- Name: Lua 5.2 + popen3() implementation
-- Author: Kyle Manna <kyle [at] kylemanna.com>
-- License: MIT License <http://opensource.org/licenses/MIT>
-- Copyright (c) 2013 Kyle Manna
--
-- Description:
-- Open pipes for stdin, stdout, and stderr to a forked process
-- to allow for IPC with the process.  When the process terminates
-- return the status code.
--
-- Includes a pipe_multi() wrapper that is simple, straight to the point.
--

--[[

The MIT License (MIT)

Copyright (c) 2013 Kyle Manna

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

--]]

-- https://github.com/luaposix/luaposix

--
-- Simple popen3() implementation
--
function popen3(path, ...)
  local r1, w1 = posix.pipe()
  local r2, w2 = posix.pipe()
  local r3, w3 = posix.pipe()

  assert((w1 ~= nil and r2 ~= nil and r3 ~= nil), "pipe() failed")

  local pid, err = posix.fork()
  assert(pid ~= nil, "fork() failed")
  if pid == 0 then
    posix.close(w1)
    posix.close(r2)
    posix.close(r3)

    posix.dup2(r1, posix.fileno(io.stdin))
    posix.dup2(w2, posix.fileno(io.stdout))
    posix.dup2(w3, posix.fileno(io.stderr))

    local ret, err = posix.execp(path, ...)
    assert(ret ~= nil, "execp() failed")

    posix._exit(1)
    return
  end

  posix.close(r1)
  posix.close(w2)
  posix.close(w3)

  return pid, w1, r2, r3
end

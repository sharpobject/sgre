local random = math.random

local dp = {}
for i=0,20 do dp[i] = {} end

local function count_possibilities(buckets, balls)
  if dp[buckets][balls] then return dp[buckets][balls] end
  local ret = 0
  if balls == 0 then
    ret = 1
  elseif buckets == 0 then
    ret = 0
  elseif buckets == 1 then
    ret = 1
  else
    -- The equivalence of this formula to the commented out code
    -- is left as an exercise to the reader.
    local ret2 = count_possibilities(buckets, balls-1) + count_possibilities(buckets-1, balls)
    --[[for i=balls, 0, -1 do
      ret = ret + count_possibilities(buckets-1, balls-i)
    end
    assert(ret2==ret)--]]
    ret = ret2
  end
  dp[buckets][balls] = ret
  return ret
end

-- For mass polymorph, rearranges sizes so that each legal outcome
-- occurs with equal probability
local function tinymaids(in_sizes)
  local ret = {}
  local n = #in_sizes
  local spare_size = 0
  for i=1,#in_sizes do
    spare_size = spare_size + in_sizes[i] - 1
    ret[i] = 1
  end
  for i=#in_sizes, 1, -1 do
    local r = random()
    local total = count_possibilities(i, spare_size)
    local acc = 0
    for j=spare_size, 0, -1 do
      acc = acc + count_possibilities(i-1, spare_size-j)
      if r < (acc / total) then
        ret[i] = ret[i] + j
        spare_size = spare_size - j
        break
      end
    end
  end
  return ret
end

for i=1,1000 do
  count_possibilities(10, i)
end

return tinymaids

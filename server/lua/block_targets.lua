local function self()
  return { self = true }
end

local function chebyshev_neighbors(n)
  return { chebyshev = n }
end

return {
  self = self,
  chebyshev_neighbors = chebyshev_neighbors
}

local function eq(value)
  return { eq = value }
end

local function lt(value)
  return { lt = value }
end

local function gt(value)
  return { gt = value }
end

return {
  eq = eq,
  lt = lt,
  gt = gt
}

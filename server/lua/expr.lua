local function singular_value(prop)
  return { singular_value = prop }
end

local function count_where(prop, subexpr)
  -- TODO
  return { count_where = { prop = prop, subexpr = subexpr } }
end

local function eq(value)
  -- TODO
  return { eq = value }
end

local function lt(value)
  -- TODO
  return { lt = value }
end

local function gt(value)
  -- TODO
  return { gt = value }
end

return {
  singular_value = singular_value,
  count_where = count_where,
  eq = eq,
  lt = lt,
  gt = gt
}

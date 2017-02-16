local function singular_value(prop)
  return { singular_value = prop }
end

local function count_where(prop, b_expr)
  return { count_where = { prop = prop, b_expr = b_expr } }
end

return {
  singular_value = singular_value,
  count_where = count_where,
}

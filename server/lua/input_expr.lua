local function get_value(prop)
  return { get_value = prop }
end

local function count_where(prop, bexpr)
  return { count_where = { prop = prop, b_expr = b_expr } }
end

return {
  singular_value = singular_value,
  count_where = count_where,
}

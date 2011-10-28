---
-- Table extension module.
-- This module contains some utility fonction to handle lua table

local M = {}

local function tabletostring (tt, indent, done)
 done = done or {}
  indent = indent or 0
  if type(tt) == "table" then
    local sb = {}
    for key, value in pairs (tt) do
      local sindent = string.rep (" ", indent);  
      if type (value) == "table" and not done [value] then
        done [value] = true
        table.insert(sb, sindent .. "{");
        table.insert(sb, sindent .. tabletostring (value, indent + 2, done))
        table.insert(sb, sindent .. "}");
      elseif "number" == type(key) then
        table.insert(sb, sindent .. string.format("\"%s\"", tostring(value)))
      else
        table.insert(sb, string.format(
            "%s = \"%s\"", sindent .. tostring (key), tostring(value)))
       end
    end
    return table.concat(sb,"\n")
  else
    return tt
  end
end

---
-- Convert a table in string (show all the contain deeply)
-- @param tt the table to convert
-- @return a string representation of `tt`
function M.tabletostring (tt)
    return tabletostring (tt)
end


---
-- copy the content of a table from `start` to the end in a new table
-- @param t table to copy
-- @param start begin index of the copy
-- @return a partial copy of `t`
function M.icopy(t,start)
    local t2 = {}
    for i,v in ipairs(t) do
        if i >= start then
          table.insert(t2,v)
        end
    end
    return t2
end

return M
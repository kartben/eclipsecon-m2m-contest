---
-- XBee frame parser.
-- _Supported frames :_
-- 
-- * _0x90 : `receive packet`_
-- * To be completed..._
--
local M = {}

local specificparsers = {
    [0x90] = require "specificframeparsers.receivepacketparser"    
}

---
-- Parse a frame and return a table corresponding to the frame structure.   
-- See in specificframeparsers directory to have the table structure by frame type.
-- @param frame a table of bytes
-- @return a table or nil, err if an error occured
function M.parse(frame)
    -- do not manage empty frame
    if #frame == 0 then  return nil, "Empty frame." end
    
    -- get frame type (first byte)  
    frametype = frame[1]
    -- get reader for this kind of frametype
    specificparser = specificparsers[frametype]
    if not specificparser then return nil, string.format("Unsupporter frame type : %x",frametype) end
       
    -- parse the specific frame
    return specificparser.parse(frame)                
end

return M
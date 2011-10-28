---
-- `Receive Packet` frame parser.
-- Specific parser able to parse `Receive Packet`.
local log = require "log"
local tableext = require "tableext"

local M = {}


---
-- Parse a `Receive Packet` frame.
-- return a table with this structure :
--    { type = "receivepacket",
--      address64 = 0x0000000000000000,
--      address16 = 0x0000,
--      receiveoptions = {broadcast = boolean,encrypted = boolean,sentfromenddevice = boolean,acknowledged = boolean}
--      receivedata = a table of byte }
-- @param frame a table of byte
-- @return a table or nil, err if an error occured

function M.parse(frame)
    log("RECEIVE PACKET PARSER", "INFO", "Start to parse 'Receive Packet' frame")
    -- valid frame size
    if #frame < 12 then return nil, string.format ("Receive Packet : Bad frame size ( more than 12 expected, got %d)",#frame) end 
    
    -- get 64 bit address
    local address64 = string.format("0x%02X%02X%02X%02X%02X%02X%02X%02X", frame[2],frame[3],frame[4],frame[5],frame[6],frame[7],frame[8],frame[9])
    log("RECEIVE PACKET PARSER", "INFO", "64-bit source address : %s",address64)
    
    -- get 16 bit address
    local address16 = string.format("0x%02X%02X", frame[10],frame[11])
    log("RECEIVE PACKET PARSER", "INFO", "16-bit source network address : %s",address16)
    
    -- get receive options
    local receiveoptionsbyte = frame[12]
    local receiveoptions = {}
    -- 0x40 - Packet was sent from an end device (if known
    receiveoptions.sentfromenddevice =  receiveoptionsbyte - 0x40 >=0
        -- 0x20 - Packet encrypted with APS encryption
    receiveoptionsbyte = receiveoptionsbyte % 0x40
    receiveoptions.encrypted =  receiveoptionsbyte - 0x20 >=0
    -- 0x02 - Packet was a broadcast packet
    receiveoptionsbyte = receiveoptionsbyte % 0x20
    receiveoptions.broadcast =  receiveoptionsbyte - 0x02 >=0
    -- 0x01 - Packet Acknowledged
    receiveoptionsbyte = receiveoptionsbyte % 0x02
    receiveoptions.acknowledged =  receiveoptionsbyte - 0x01 >=0
    log("RECEIVE PACKET PARSER", "INFO", "receive options : \n%s",tableext.tabletostring(receiveoptions))
    
    -- get receive data
    local receivedata = tableext.icopy(frame,13)
    log("PARSER", "INFO", "'Receive Packet' Frame parsed !")    
    return {type = "receivepacket",address64=address64,address16=address16,receiveoptions=receiveoptions,receivedata=receivedata}
end

return M
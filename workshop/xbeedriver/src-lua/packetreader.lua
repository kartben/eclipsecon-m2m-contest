---
-- XBee Packet Reader
-- API To read Xbee packet
-- see http://ftp1.digi.com/support/documentation/90000976_G.pdf

local log = require "log"

local M = {}

local START_DELIMITER = "~"

---
-- read a Xbee packet (blocking function)
-- read on the serial device until wellform packet is readed
-- @param serial a serial device on which the packet must be read
-- @return the frame read or nil, err if an error occured
function M.readpacket(serial,escapedchar)
    log("PACKET_READER", "INFO", "Start to read packet")
    -- read until the start delimiter character was read
    log("PACKET_READER", "INFO", "waiting for start delimiter...")
    local startdelimiterread = false
    while not startdelimiterread do  
        -- read 1 byte
        local data,err=serial:read(1)
        if not data then return nil, err end
        
        log("PACKET_READER", "INFO","Byte readed: 0x%02X (Start delimiter)", string.byte(data,1))
        startdelimiterread =  data == START_DELIMITER 
    end
    
    -- read length
    local data,err=serial:read(2)
    if not data then return nil, err end
    log("PACKET_READER", "INFO","Bytes read: 0x%02X%02X (lenght)", string.byte(data,1,2))
    local msblength = string.byte(data,1)
    local lsblength = string.byte(data,2)
    local framelength = msblength * 256 + lsblength
    log("PACKET_READER", "INFO","Frame Length %d", framelength)

    -- read frame    
    local nbbyteread = 0 
    local bytesum = 0
    local frame={}
    while nbbyteread < framelength do
        -- read message byte
        local data,err=serial:read(1)
        if not data then return nil, err end

        -- manage escaped character
        local byte = string.byte(data,1)
        if escapedchar and byte == 0x7D then
            -- read real byte
            local data,err=serial:read(1)
            if not data then return nil, err end
            --  unescape char
            byte = string.byte(data,1)
            byte = byte - 0x20
            
            log("PACKET_READER", "INFO","Byte readed (escaped): 0x%02X (frame)", byte)
        else
            log("PACKET_READER", "INFO","Byte readed: 0x%02X (frame)", byte)
        end
        
        table.insert(frame,byte)
        bytesum = bytesum + byte
        nbbyteread = nbbyteread + 1 
    end
    
    -- read checksum 
    local data,err=serial:read(1)
    if not data then return nil, err end
    local checksum = string.byte(data,1)
    log("PACKET_READER", "INFO","Byte readed 0x%02X (Checksum)", checksum)
    
    -- check integrity
    local computedChecksum = (0xFF - bytesum % 256)
    if not computedChecksum ==  checksum then
        return nil, string.format("Checksum failure ! %02X computed, got %02X.",computedChecksum, checksum)
    else
        log("PACKET_READER", "INFO","Checksum success.")
    end
    
    log("PACKET_READER", "INFO","Packet read!")
    return frame
end

return M 
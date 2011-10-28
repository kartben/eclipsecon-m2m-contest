local sched = require 'sched'
local racoon = require "racoon"
local serial = require "serial"
local log = require "log"
local packetreader = require "packetreader"
local frameparser = require "frameparser"

local serialdev

local station1address = "0x0013A20040773379"
local station2address = "0x0013A20040773426"

local station1id = "Station1"
local station2id = "Station2"

local address2assetID = {}
address2assetID[station1address]=station1id
address2assetID[station2address]=station2id

local address2assets = {}

---
-- Stop the application
local function stop(exitcode)
	log("APP", "INFO", "bye bye, exit_code=%s", exitcode and tostring(exitcode) or "unknown, default to 0")
    if serial then serial:close() end
    racoon:close()
    os.exit(exitcode or 0)
end

---
-- main function
local function main ()
	-- set log level
	log.setlevel("INFO")
	
	-- wait for initialization
	sched.wait(5)
   
    -- start application
    log("APP", "INFO","Application Started!")
    
    -- configure serial port
	local serial_config = { parity = "none", flowcontrol = "none", data=8, stop=1, baudrate=9600 }

    -- open serial port
    local err
    serialdev,err = serial.open("/dev/ttyS0", serial_config)
    if not serial then log("APP", "ERROR","Serial open error", err); stop(1) end

    -- create and register new station 1
    local station1 = racoon.new(station1id)
    local status, err = station1:register()
    if not status then log("APP", "ERROR","Unable to register asset (%s) : %s",station1id, err); stop(1) end
    log("APP", "INFO", "Asset (%s) registered.",station1id)
    
     -- create and register new asset
    local station2 = racoon.new(station2id)
    local status, err = station2:register()
    if not status then log("APP", "ERROR","Unable to register asset (%s) : %s",station2id, err); stop(1) end
    log("APP", "INFO", "Asset (%s) registered.",station2id)  
    
    -- associate address to assets
    address2assets[station1address]=station1
    address2assets[station2address]=station2 
    
   	while true do
   	   -- read packet to extract the frame
	   local rawframe, err = packetreader.readpacket(serialdev,true)
	   if not rawframe then 
            log("APP", "ERROR","read packet error : %s.", err)
	   else
	        -- parse the frame
            local frame, err = frameparser.parse(rawframe)
            if not frame then 
                log("APP", "ERROR","parse frame error : %s.", err)
            else
                -- extract data
                local appdata =  frame.receivedata
                if #appdata ~=4 then 
                    log ("APP","ERROR","Bad receive data size (4 expected, got %d).",#appdata)
                else
                    -- get right asset
                    local asset = address2assets[frame.address64]
                    if not asset then 
                        log ("APP","ERROR","Unexpected asset addresse (got %s, expected %s or %s.",frame.address64,station1address,station2address)
                    else
                        -- get asset id
                        local assetID = address2assetID[frame.address64]
                        
                        -- get application data                                      
                        local illuminance = appdata[1]  * 256 +  appdata[2]
                        local temperature = (appdata[3]  * 256 +  appdata[4])/100
                        log ("APP","INFO","illuminance (%d lux),temperature(%.2f°C) for asset %s.",illuminance,temperature,assetID)
                    
                        --push data on the server
                        asset:pushdata ("", {illuminance=illuminance,temperature=temperature})
                        asset : triggerpolicy("*")
                        local status, err = asset:connecttoserver()
                        if not status then 
                           log ("APP","ERROR","Unable to connect to server! (%s).",err)
                        else
                           log ("APP","INFO","Data send to server for asset %s.",assetID)
                        end
                    end                    
                end
            end
	   end
   	end  
end


sched.run(main)
sched.loop()

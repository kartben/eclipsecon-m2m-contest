local sched = require 'sched'
local racoon = require "racoon"
local serial = require "serial"
local log = require "log"
local packetreader = require "packetreader"
local frameparser = require "frameparser"

local serialdev

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

    -- create and register new asset
    local assetid = "m2mcontest"
    local asset = racoon.new(assetid)
    local status, err = asset:register()
    if not status then log("APP", "ERROR","Unable to register asset (%s) : %s",assetid, err); stop(1) end
    log("APP", "INFO", "Asset (%s) registered.",assetid) 
    
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
                    -- we manage only broadcast frame from an end device.
                    if not (frame.receiveoptions.sentfromenddevice and frame.receiveoptions.broadcast)then
                        log ("APP","INFO","Packet ignored (not sent by broadcast from an end device).")
                    else
                        -- get application data                                      
                        local illuminance = appdata[1]  * 256 +  appdata[2]
                        local temperature = appdata[3]  * 256 +  appdata[4]
                        log ("APP","INFO","illuminance (%d lux),temperature(%.2f°C).",illuminance,temperature/100)
                    
                        --push data on the server
                        asset:pushdata ("", {illuminance=illuminance,temperature=temperature})
                        asset : triggerpolicy("*")
                        local status, err = asset:connecttoserver()
                        if not status then 
                            log ("APP","ERROR","Unable to connect to server! (%s).",err)
                        else
                            log ("APP","INFO","Data send to server.")
                        end
                    end
                end
            end
	   end
   	end  
end


sched.run(main)
sched.loop()

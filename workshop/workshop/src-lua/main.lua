local sched = require 'sched'
local racoon = require "racoon"
local serial = require "serial"
local log = require "log"
local packetreader = require "packetreader"
local frameparser = require "frameparser"
local MQTT = require "mqtt_library"
local http = require "socket.http"
local ltn12 = require "ltn12"

local serialdev

local station1address = "0x0013A200407A629F"
local station2address = "0x0013A200407A63BE"

local address2feedID = {}
address2feedID[station1address]= {}
address2feedID[station1address].temperature = 9038
address2feedID[station1address].illuminance = 9040

address2feedID[station2address]= {}
address2feedID[station2address].temperature = 9039
address2feedID[station2address].illuminance = 9041


local address2assets = {}

function callback(topic,payload)
	log("MQTT", "INFO", "callback"  .. payload)
end

---
-- Stop the application
local function stop(exitcode)
	log("APP", "INFO", "bye bye, exit_code=%s", exitcode and tostring(exitcode) or "unknown, default to 0")
	if serial then serial:close() end
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
	if not serial then log("APP", "ERROR", "Serial open error", err); stop(1) end

	-- register MQTT connection
	local mqtt_client = MQTT.client.create("m2m.eclipse.org", 1883, callback)
	mqtt_client:connect("Sierra GX400")
	mqtt_client:subscribe({ "ldt/demo2" })

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
					-- get application data
					local illuminance = appdata[1]  * 256 +  appdata[2]
					local temperature = (appdata[3]  * 256 +  appdata[4])/100
					log ("APP","INFO","illuminance (%d lux),temperature(%.2f°C) for xbee station %s.", illuminance, temperature, frame.address64)

					--publish data on the MQTT broker
					mqtt_client:handler()
					mqtt_client:publish("eclipsecon/station/" .. frame.address64, illuminance .. '#'.. temperature)

					--publish data on OpenSense
					local req_body = '[{"feed_id": ' .. address2feedID[frame.address64].temperature .. ', "value": '.. temperature .. '}, {"feed_id": ' 
												.. address2feedID[frame.address64].illuminance .. ', "value": '.. illuminance .. '}]'
					http.request { url = 'http://api.sen.se/events/?sense_key=o3QW3IvDOaR7mJaOga8NTw' ,
						source = ltn12.source.string(req_body) ,
						method = "POST",
						headers = { ["Content-Type"] = "application/json",
									["Content-Length"] = #req_body }
					}

				end
			end
		end
	end
end


sched.run(main)
sched.loop()

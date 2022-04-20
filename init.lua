station_cfg = {}
dofile("config.lua")

delayed_restart = tmr.create()
push_timer = tmr.create()
chip_id = node.chipid()
device_id = "esp8266_" .. chip_id
mqtt_prefix = "sensor/" .. device_id
mqttclient = mqtt.Client(device_id, 120)


print("ESP8266 " .. chip_id)

ledpin = 4
gpio.mode(ledpin, gpio.OUTPUT)
gpio.write(ledpin, 0)

scd4x = require("scd4x")
i2c.setup(0, 2, 1, i2c.SLOW)

function log_restart()
	print("Network error " .. wifi.sta.status() .. ". Restarting in 20 seconds.")
	delayed_restart:start()
end

function setup_client()
	print("Connected")
	gpio.write(ledpin, 1)
	if not scd4x.start() then
		print("SCD4x initialization error")
	end
	publishing = true
	mqttclient:publish(mqtt_prefix .. "/state", "online", 0, 1, function(client)
		publishing = false
		push_data()
	end)
end

function connect_mqtt()
	print("IP address: " .. wifi.sta.getip())
	print("Connecting to MQTT " .. mqtt_host)
	delayed_restart:stop()
	mqttclient:on("connect", hass_register)
	mqttclient:on("offline", log_restart)
	mqttclient:lwt(mqtt_prefix .. "/state", "offline", 0, 1)
	mqttclient:connect(mqtt_host)
end

function connect_wifi()
	print("WiFi MAC: " .. wifi.sta.getmac())
	print("Connecting to ESSID " .. station_cfg.ssid)
	wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, connect_mqtt)
	wifi.eventmon.register(wifi.eventmon.STA_DHCP_TIMEOUT, log_restart)
	wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, log_restart)
	wifi.setmode(wifi.STATION)
	wifi.sta.config(station_cfg)
	wifi.sta.connect()
end

function push_data()
	local co2, raw_temp, raw_humi = scd4x.read()
	if co2 == nil then
		print("SCD4x error")
	else
		local json_str = string.format('{"co2_ppm": %d, "temperature_degc": %d.%d, "humidity_relpercent": %d.%d, "rssi_dbm": %d}', co2, raw_temp/65536 - 45, (raw_temp%65536)/6554, raw_humi/65536, (raw_humi%65536)/6554, wifi.sta.getrssi())
		if not publishing then
			publishing = true
			gpio.write(ledpin, 0)
			mqttclient:publish(mqtt_prefix .. "/data", json_str, 0, 0, function(client)
				publishing = false
				gpio.write(ledpin, 1)
				collectgarbage()
			end)
		end
	end
	push_timer:start()
end

function hass_register()
	local hass_device = string.format('{"connections":[["mac","%s"]],"identifiers":["%s"],"model":"ESP8266","name":"ESP8266 with SCD4x","manufacturer":"DIY"}', wifi.sta.getmac(), device_id)
	local hass_entity_base = string.format('"device":%s,"state_topic":"%s/data","expire_after":600', hass_device, mqtt_prefix)
	local hass_co2 = string.format('{%s,"name":"CO₂","object_id":"%s_co2","unique_id":"%s_co2","device_class":"carbon_dioxide","unit_of_measurement":"ppm","value_template":"{{value_json.co2_ppm}}"}', hass_entity_base, device_id, device_id)
	local hass_temp = string.format('{%s,"name":"Temperature","object_id":"%s_temperature","unique_id":"%s_temperature","device_class":"temperature","unit_of_measurement":"°c","value_template":"{{value_json.temperature_degc}}"}', hass_entity_base, device_id, device_id)
	local hass_humi = string.format('{%s,"name":"Humidity","object_id":"%s_humidity","unique_id":"%s_humidity","device_class":"humidity","unit_of_measurement":"%%","value_template":"{{value_json.humidity_relpercent}}"}', hass_entity_base, device_id, device_id)
	local hass_rssi = string.format('{%s,"name":"RSSI","object_id":"%s_rssi","unique_id":"%s_rssi","device_class":"signal_strength","unit_of_measurement":"dBm","value_template":"{{value_json.rssi_dbm}}","entity_category":"diagnostic"}', hass_entity_base, device_id, device_id)

	mqttclient:publish("homeassistant/sensor/" .. device_id .. "/co2/config", hass_co2, 0, 1, function(client)
		mqttclient:publish("homeassistant/sensor/" .. device_id .. "/temperature/config", hass_temp, 0, 1, function(client)
			mqttclient:publish("homeassistant/sensor/" .. device_id .. "/humidity/config", hass_humi, 0, 1, function(client)
				mqttclient:publish("homeassistant/sensor/" .. device_id .. "/rssi/config", hass_rssi, 0, 1, function(client)
					collectgarbage()
					setup_client()
				end)
			end)
		end)
	end)
end

delayed_restart:register(20 * 1000, tmr.ALARM_SINGLE, node.restart)
push_timer:register(20 * 1000, tmr.ALARM_SEMI, push_data)

connect_wifi()

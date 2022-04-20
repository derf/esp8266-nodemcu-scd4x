# ESP8266 Lua/NodeMCU module for Sensirion SCD40/SCD41 CO₂ sensor

This repository contains a Lua module (`scd4x.lua`) as well as
MQTT-based HomeAssistant integration (`init.lua`) for **Sensirion SCD40/SCD41**
CO₂ sensors.

## Dependencies

scd4x.lua has been tested with Lua 5.1 on NodeMCU firmware 3.0.1 (Release
202112300746, integer build). It requires the following modules.

* i2c

The MQTT HomeAssistant integration in init.lua additionally needs the following
modules.

* gpio
* mqtt
* node
* tmr
* uart
* wifi

## Usage

Copy **scd4x.lua** to your NodeMCU board and set it up as follows.

```lua
scd4x = require("scd4x")
i2c.setup(0, sda_pin, scl_pin, i2c.SLOW)
scd4x.start()

-- can be called with up to 1 Hz
function some_timer_callback()
	local co2, raw_temp, raw_humi = scd4x.read()
	if co2 == nil then
		print("SCD4x error")
	else
		-- CO₂[ppm] == co2, Temperature[°c] == raw_temp/2¹⁶ - 45, Humidity[%] == raw_humi/2¹⁶
	end
end
```

See **init.lua** for an example. To use it, you need to create a **config.lua** file with WiFI and MQTT settings:

```lua
station_cfg.ssid = "..."
station_cfg.pwd = "..."
mqtt_host = "..."
```

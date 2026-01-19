# ESP8266 Lua/NodeMCU module for Sensirion SCD4x CO₂ sensors

This repository provides an ESP8266 NodeMCU Lua module (`scd4x.lua`) as well as
MQTT / HomeAssistant / InfluxDB integration example (`init.lua`) for
**Sensirion SCD4x** CO₂ sensors connected via I²C.

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
* wifi

## Setup

Connect the SCD4x sensor to your ESP8266/NodeMCU board as follows.

* SCD4x GND → ESP8266/NodeMCU GND
* SCD4x 3V3 → ESP8266/NodeMCU 3V3
* SCD4x SCL → NodeMCU D1 (ESP8266 GPIO4)
* SCD4x SDA → NodeMCU D2 (ESP8266 GPIO5)

SDA and SCL must have external pull-up resistors to 3V3.

If you use different pins for SDA and SCL, you need to adjust the
i2c.setup call in the examples provided in this repository to reflect
those changes. Keep in mind that some ESP8266 pins must have well-defined logic
levels at boot time and may therefore be unsuitable for SCD4x connection.

## Usage

Copy **scd4x.lua** to your NodeMCU board and set it up as follows.

```lua
scd4x = require("scd4x")
i2c.setup(0, 2, 1, i2c.SLOW)
scd4x.start()

-- can be called with up to 1 Hz
function some_timer_callback()
	local co2, raw_temp, raw_humi = scd4x.read()
	if co2 ~= nil then
		-- co2      : CO₂ concentration [ppm]
		-- raw_temp : raw_temp/2¹⁶ - 45 == Temperature [°C]
		-- raw_humi : raw_humi/2¹⁶ == Humidity [%]
	else
		print("SCD4x error")
	end
end
```

## Application Example

**init.lua** is an example application with HomeAssistant integration.
To use it, you need to create a **config.lua** file with WiFI and MQTT settings:

```lua
station_cfg = {ssid = "...", pwd = "..."}
mqtt_host = "..."
```

Optionally, it can also publish readings to an InfluxDB.
To do so, configure URL and attribute:

```lua
influx_url = "..."
influx_attr = "..."
```

Readings will be published as `scd4x[influx_attr] co2_ppm=%d,temperature_degc=%d.%d,humidity_relpercent=%d.%d`.
So, unless `influx_attr = ''`, it must start with a comma, e.g. `influx_attr = ',device=' .. device_id`.

## Resources

Mirrors of the esp8266-nodemcu-scd4x repository are maintained at the following locations:

* [Chaosdorf](https://chaosdorf.de/git/derf/esp8266-nodemcu-scd4x)
* [Finalrewind](https://git.finalrewind.org/derf/esp8266-nodemcu-scd4x)
* [GitHub](https://github.com/derf/esp8266-nodemcu-scd4x)

local scd4x = {}
local device_address = 0x62

scd4x.bus_id = 0

function scd4x.start()
	i2c.start(scd4x.bus_id)
	if not i2c.address(scd4x.bus_id, device_address, i2c.TRANSMITTER) then
		return false
	end
	i2c.write(scd4x.bus_id, {0x21, 0xb1})
	i2c.stop(scd4x.bus_id)
	return true
end

function scd4x.stop()
	i2c.start(scd4x.bus_id)
	if not i2c.address(scd4x.bus_id, device_address, i2c.TRANSMITTER) then
		return false
	end
	i2c.write(scd4x.bus_id, {0x3f, 0x86})
	i2c.stop(scd4x.bus_id)
	return true
end

function scd4x.read()
	i2c.start(scd4x.bus_id)
	if not i2c.address(scd4x.bus_id, device_address, i2c.TRANSMITTER) then
		return nil
	end
	i2c.write(scd4x.bus_id, {0xec, 0x05})
	i2c.stop(scd4x.bus_id)
	i2c.start(scd4x.bus_id)
	if not i2c.address(scd4x.bus_id, device_address, i2c.RECEIVER) then
		return nil
	end
	local data = i2c.read(scd4x.bus_id, 9)
	i2c.stop(scd4x.bus_id)
	local co2 = string.byte(data, 1) * 256 + string.byte(data, 2)
	local temp_raw = 175 * (string.byte(data, 4) * 256 + string.byte(data, 5))
	local humi_raw = 100 * (string.byte(data, 7) * 256 + string.byte(data, 8))
	return co2, temp_raw, humi_raw
end

return scd4x

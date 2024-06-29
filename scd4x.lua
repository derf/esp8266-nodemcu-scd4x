local scd4x = {}
local addr = 0x62

function scd4x.start()
	i2c.start(0)
	if not i2c.address(0, addr, i2c.TRANSMITTER) then
		return false
	end
	i2c.write(0, {0x21, 0xb1})
	i2c.stop(0)
	return true
end

function scd4x.stop()
	i2c.start(0)
	if not i2c.address(0, addr, i2c.TRANSMITTER) then
		return false
	end
	i2c.write(0, {0x3f, 0x86})
	i2c.stop(0)
	return true
end

function scd4x.read()
	i2c.start(0)
	if not i2c.address(0, addr, i2c.TRANSMITTER) then
		return nil
	end
	i2c.write(0, {0xec, 0x05})
	i2c.stop(0)
	i2c.start(0)
	if not i2c.address(0, addr, i2c.RECEIVER) then
		return nil
	end
	local data = i2c.read(0, 9)
	i2c.stop(0)
	if not scd4x.crc_valid(data, 9) then
		return nil
	end
	local co2 = string.byte(data, 1) * 256 + string.byte(data, 2)
	local temp_raw = 175 * (string.byte(data, 4) * 256 + string.byte(data, 5))
	local humi_raw = 100 * (string.byte(data, 7) * 256 + string.byte(data, 8))
	return co2, temp_raw, humi_raw
end

function scd4x.crc_word(data, index)
	local crc = 0xff
	for i = index, index+1 do
		crc = bit.bxor(crc, string.byte(data, i))
		for j = 8, 1, -1 do
			if bit.isset(crc, 7) then
				crc = bit.bxor(bit.lshift(crc, 1), 0x31)
			else
				crc = bit.lshift(crc, 1)
			end
			crc = bit.band(crc, 0xff)
		end
	end
	return bit.band(crc, 0xff)
end

function scd4x.crc_valid(data, length)
	for i = 1, length, 3 do
		if scd4x.crc_word(data, i) ~= string.byte(data, i+2) then
			return false
		end
	end
	return true
end

return scd4x

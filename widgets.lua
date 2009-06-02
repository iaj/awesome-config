-- Widget functions

-- {{{1 Clock
function clock_info(dateformat, timeformat)
    local date = os.date(dateformat)
    local time = os.date(timeformat)
    return date .. ' ' .. markup.fg.focus(time)
end

-- {{{1 Network activity
function net_info(interface)
	local net = io.open('/proc/net/dev') for line in net:lines() do if line:match('^%s+'..interface) then
			net_in  = tonumber(line:match(':%s*(%d+)'))
			net_out = tonumber(line:match('(%d+)%s+%d+%s+%d+%s+%d+%s+%d+%s+%d+%s+%d+$'))
		end
	end
	net:close()

	local function format_bytes(traffic)
		if traffic < 1073741824 then
			traffic = string.format('%.2fM', traffic / 1048576)
		else
			traffic = string.format('%.2fG', traffic / 1073741824)
		end
		return traffic
	end

	net_in  = format_bytes(net_in)
	net_out = format_bytes(net_out)

	return  net_in .. ' / ' .. net_out
end

-- {{{1 Moc
function moc_info(widget_type)
	widget_type = widget_type or nil

	local src = io.popen('mocp -Q %state'), state
	state = src:read()
	src:close()
 
	if widget_type == 'progressbar' or widget_type == 'popup' then
		local comptime, totatime, src

		src = io.popen('mocp -Q %ct')
		comptime = src:read()
		src:close()

		src = io.popen('mocp -Q %tt')
		totatime = src:read()
		src:close()

		local function time2int(time)
			if time:match(':.*:') then
				local hour, min, sec
				hour = tonumber(time:match('^(%d+)') )
				min  = tonumber(time:match(':(%d+):'))
				sec  = tonumber(time:match('(%d+)$') )
				return (hour * 60 * 60) + (min * 60) + sec
			else
				local min, sec
				min = tonumber(time:match('^(%d+)'))
				sec = tonumber(time:match('(%d+)$'))
				return (min * 60) + sec
			end
		end

		if widget_type == 'progressbar' then
			if state == (nil or 'STOP') then
				return 0
			else
				return (100 / time2int(totatime)) * time2int(comptime)
			end
		else
			if state == (nil or 'STOP') then
				return naughty.notify(
				{
					text = markup.fg.focus('[]: ') .. 'Not playing...',
					timeout       = 0,
					hover_timeout = 0.5,
					width         = 120,
				})
			else
				local album, artist, song, completed, comp_str = ''

				src = io.popen('mocp -Q %album')
				album = awful.util.escape(src:read())
				src:close()

				src = io.popen('mocp -Q %artist')
				artist = awful.util.escape(src:read())
				src:close()

				src = io.popen('mocp -Q %song')
				song = awful.util.escape(src:read())
				src:close()

				if album  == '' then album  = markup.fg.focus('nil') end
				if artist == '' then artist = markup.fg.focus('nil') end
				if song   == '' then song   = markup.fg.focus('nil') end

				completed = (100 / time2int(totatime)) * time2int(comptime)

				comp_str = ''
				for i = 1, math.floor(completed / 10) * 5          do comp_str = comp_str .. '▇' end
				for i =   (math.floor(completed / 10) + 1) * 5, 50 do comp_str = comp_str .. '─' end

				return naughty.notify(
				{
					icon = '/usr/share/icons/Tango/64x64/devices/gnome-dev-ipod.png',
					text = markup.fg.focus(' Title: ') .. song     .. '\n' ..
					       markup.fg.focus('Artist: ') .. artist   .. '\n' ..
					       markup.fg.focus(' Album: ') .. album    .. '\n' ..
					       markup.fg.focus('  Time: ') .. comp_str ..
					       markup.fg.focus(string.format(' %.2f%%', completed)),
					timeout       = 0,
					hover_timeout = 0.5,
					width         = 460,
				})
			end
		end
    elseif widget_type == (nil or 'textbox') then
		if state == (nil or 'STOP') then
			return markup.fg.focus('[]: ') .. 'Not playing...'
		else
			local artist, song

			src = io.popen('mocp -Q %artist')
			artist = awful.util.escape(src:read())
			src:close()

			src = io.popen('mocp -Q %song')
			song = awful.util.escape(src:read())
			src:close()

			if state == 'PAUSE' then
				return markup.fg.focus('|| ') .. artist .. ' - ' .. song
			else
				return markup.fg.focus('>> ') .. artist .. ' - ' .. song
			end
		end
	end
end

-- {{{1 Loadavg
function load_info()
	local ld = io.open('/proc/loadavg')
	avg_load = string.match(ld:read(), '^(%d%.%d%d)')
	ld:close()
	return avg_load
end

-- {{{1 HD
function hd_info(widget_type)
	widget_type = widget_type or nil

	local src = io.popen('df -Ph')

	if widget_type == 'progressbar' then
		for line in src:lines() do
			if line:match('/$') then
				return tonumber(line:match('(%d+)%%'))
			end
		end
		src:close()
	else
		local hdTotal, hdUsed, hdAvail, hdPerc

		for line in src:lines() do
			if line:match('/$') then
				hdTotal = line:match('^[%w/]+%s+(%d+%w)')
				hdUsed  = line:match('^[%w/]+%s+%d+%w%s+(%d+%w)')
				hdAvail = line:match('(%d+%w)%s+%d+%%')
				hdPerc  = line:match('(%d+)%%')
			end
		end
		src:close()

		if widget_type == 'popup' then
			return naughty.notify(
			{
				icon = '/usr/share/icons/Tango/64x64/devices/gnome-dev-harddisk.png',
				text = markup.fg.focus(' Perc: ') .. string.format('%6d%%', hdPerc) .. '\n' ..
				       markup.fg.focus(' Used: ') .. string.format('%7s', hdUsed)   .. '\n' ..
				       markup.fg.focus('Avail: ') .. string.format('%7s', hdAvail)  .. '\n' ..
				       markup.fg.focus('Total: ') .. string.format('%7s', hdTotal),
				timeout       = 0,
				hover_timeout = 0.5,
				width         = 190,
			})
		elseif widget_type == (nil or 'textbox') then
			return memPerc .. ' of ' .. memTotal .. ' (' .. memUsed .. ')'
		end
	end
end
	
-- {{{1 Memory
function memory_info(widget_type)
	local f = io.open('/proc/meminfo')
	local memTotal, memFree, memBuffs, memCached
 
	for line in f:lines() do
		if line:match('^MemTotal:') then
			memTotal  = tonumber(line:match('(%d+)'))
		elseif line:match('^MemFree:') then
			memFree   = tonumber(line:match('(%d+)'))
		elseif line:match('^Buffers:') then
			memBuffs  = tonumber(line:match('(%d+)'))
		elseif line:match('^Cached:') then
			memCached = tonumber(line:match('(%d+)'))
		end
	end

	f:close()

	local function fmt(amount)
		-- 1000^3 == 1000000; 1024^3 == 1048576
		-- ^ Manufacturer,    ^ Actual
		if amount > 1048576 then
			-- 1024^2 == 1048576
			return string.format('%6.2fG', amount / 1048576)
		elseif amount > 1024 then
			return string.format('%6.2fM', amount / 1024)
		else
			return string.format('%dK', amount )
		end
	end

	memAvail = memFree + memBuffs + memCached
	memUsed  = memTotal - memAvail
	memPerc  = (100 / memTotal) * memUsed

	memPerc = (100 / memTotal) * (memTotal - memFree - memBuffs - memCached)

    if widget_type == 'progressbar' then
		return memPerc
    elseif widget_type == 'popup' then
		return naughty.notify(
		{
			icon = '/usr/share/icons/Tango/64x64/devices/media-flash.png',
			text = markup.fg.focus(' Perc: ') .. string.format('%6.2f', memPerc) .. '%\n' ..
			       markup.fg.focus(' Used: ') .. fmt(memUsed)                    .. '\n'  ..
			       markup.fg.focus('Avail: ') .. fmt(memAvail)                   .. '\n'  ..
			       markup.fg.focus('Total: ') .. fmt(memTotal),
			timeout       = 0,
			hover_timeout = 0.5,
			width         = 190,
		})
	elseif widget_type == (nil or 'textbox') then
        return string.format('%6.2f', memPerc) .. '% of ' .. fmt(memTotal) .. ' (' .. fmt(memUsed) .. ')'
	end
end
-- {{{1 Volume
function volume_info()
	local vol = io.popen('amixer sget Master')
	local volume
	for line in vol:lines() do
		if line:match("%%") then
			if line:match('%[off]$') then
				volume = 'MUTE'
			else
				volume = line:match("%[(%d+%%)]")
			end
		end
	end
	vol:close()
	return volume
end

---- {{{1 Temperature
function temperature_info()
        local temp = io.popen('sensors -f')
        local temperature = 0
        local count = 0
        for line in temp:lines() do
                if line:match("^Core [0-9]:") then
                        temperature = temperature + tonumber(line:match("(%d+)°F"))
                        count = count + 1
                end
        end
        temperature = string.format('%.2f C', (temperature / count - 32) * 5 / 9)
        return temperature
end

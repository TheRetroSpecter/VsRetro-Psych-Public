function set(key, val)
	setProperty(key, val)
end
function get(key)
	return getProperty(key)
end
function addRel(key, val)
	setProperty(key, getProperty(key) + val)
end

function onCreate()
end

local laughId = 0

function onStepHit()
	if laughId == 0 and curStep >= 248 then
		triggerEvent('Play Animation', 'laugh', 'dad')
		
		laughId = laughId + 1
	end

	if laughId == 1 and curStep >= 1016 then
		triggerEvent('Play Animation', 'laugh', 'dad')
		
		laughId = laughId + 1
	end
end
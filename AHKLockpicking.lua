-- For menu & data
AHKLockpicking = {}
AHKLockpicking.name = "AHKLockpicking"

local ptk = LibPixelControl
local ms_time = GetGameTimeMilliseconds()
local function dmsg(txt)
	d((GetGameTimeMilliseconds() - ms_time) .. ") " .. txt)
	ms_time = GetGameTimeMilliseconds()
end

function AHKLockpicking:BeginLockpicking()
	dmsg("BeginLockpicking")
	ptk.SetIndOn(ptk.VM_MOVE_10_LEFT)
	zo_callLater(function() AHKLockpicking:CheckLockPickStatus() end, 500)
end
function AHKLockpicking:CheckLockPickStatus()
	--d("Stress:"..tostring(GetSettingChamberStress()).." Chambers:"..tostring(IsChamberSolved(1))..":"..tostring(IsChamberSolved(2))..":"..tostring(IsChamberSolved(3))..":"..tostring(IsChamberSolved(4))..":"..tostring(IsChamberSolved(5)))
	state1, prog1 = GetChamberState(1)
	state2, prog2 = GetChamberState(2)
	state3, prog3 = GetChamberState(3)
	state4, prog4 = GetChamberState(4)
	state5, prog5 = GetChamberState(5)
	d("Stress:"..tostring(GetSettingChamberStress()).." State,Prog"
		..":"..tostring(state1)..","..tostring(prog1)
		..":"..tostring(state2)..","..tostring(prog2)
		..":"..tostring(state3)..","..tostring(prog3)
		..":"..tostring(state4)..","..tostring(prog4)
		..":"..tostring(state5)..","..tostring(prog5))
	local verbose = true
	local repeatrate = 50
	d("Left:"..tostring(ptk.IsIndOn(ptk.VM_MOVE_10_LEFT))
		.." Right:"..tostring(ptk.IsIndOn(ptk.VM_MOVE_10_RIGHT))
		.." Mouse:"..tostring(ptk.IsIndOn(ptk.VM_BTN_LEFT)))
	if ptk.IsIndOn(ptk.VM_MOVE_10_LEFT) then
		ptk.SetIndOff(ptk.VM_MOVE_10_LEFT)
		ptk.SetIndOn(ptk.VM_BTN_LEFT)
		zo_callLater(function() AHKLockpicking:CheckLockPickStatus() end, repeatrate)
	elseif ptk.IsIndOn(ptk.VM_BTN_LEFT) then
		if GetSettingChamberStress() > 0 then
			if verbose then d("- chamber stressed, stop pressing and look for next pin") end
			ptk.SetIndOff(ptk.VM_BTN_LEFT)
			ptk.SetIndOn(ptk.VM_MOVE_10_RIGHT)
			zo_callLater(function() AHKLockpicking:CheckLockPickStatus() end, repeatrate)
		elseif (prog1 > 0 or prog2 > 0 or prog3 > 0 or prog4 > 0 or prog5 > 0) then
			if verbose then d("- pin is dropping, keep holding") end
			zo_callLater(function() AHKLockpicking:CheckLockPickStatus() end, repeatrate)
		else
			if verbose then d("- not on a pin so start moving right") end
			ptk.SetIndOff(ptk.VM_BTN_LEFT)
			ptk.SetIndOn(ptk.VM_MOVE_10_RIGHT)
			zo_callLater(function() AHKLockpicking:CheckLockPickStatus() end, repeatrate)
		end
	elseif ptk.IsIndOn(ptk.VM_MOVE_10_RIGHT) then
		if verbose then d("- stop moving right and check pin") end
		ptk.SetIndOff(ptk.VM_MOVE_10_RIGHT)
		ptk.SetIndOn(ptk.VM_BTN_LEFT)
		zo_callLater(function() AHKLockpicking:CheckLockPickStatus() end, repeatrate)
	end
end
function AHKLockpicking:EndLockpicking()
	dmsg("EndLockpicking")
	ptk.SetIndOff(ptk.VM_MOVE_10_LEFT) -- stop moving
	ptk.SetIndOff(ptk.VM_MOVE_10_RIGHT) -- stop moving
	ptk.SetIndOff(ptk.VM_BTN_LEFT) -- stop pressing
end


function AHKLockpicking:Initialize()
	EVENT_MANAGER:RegisterForEvent(AHKLockpicking.name, EVENT_BEGIN_LOCKPICK, AHKLockpicking.BeginLockpicking)
	EVENT_MANAGER:RegisterForEvent(AHKLockpicking.name, EVENT_LOCKPICK_FAILED, AHKLockpicking.EndLockpicking)
	EVENT_MANAGER:RegisterForEvent(AHKLockpicking.name, EVENT_LOCKPICK_SUCCESS, AHKLockpicking.EndLockpicking)
	EVENT_MANAGER:RegisterForEvent(AHKLockpicking.name, EVENT_LOCKPICK_BROKE, AHKLockpicking.EndLockpicking)
end

-- Then we create an event handler function which will be called when the "addon loaded" event
-- occurs. We'll use this to initialize our addon after all of its resources are fully loaded.
function AHKLockpicking.OnAddOnLoaded(event, addonName) -- The event fires each time *any* addon loads - but we only care about when our own addon loads.
    if addonName == AHKLockpicking.name then AHKLockpicking:Initialize() end
end

-- Finally, we'll register our event handler function to be called when the proper event occurs.
EVENT_MANAGER:RegisterForEvent(AHKLockpicking.name, EVENT_ADD_ON_LOADED, AHKLockpicking.OnAddOnLoaded)

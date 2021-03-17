-- For menu & data
AHKLockpicking = {}
AHKLockpicking.name = "AHKLockpicking"

local ptk = LibPixelControl
local ms_time = GetGameTimeMilliseconds()
local function dmsg(txt)
	d((GetGameTimeMilliseconds() - ms_time) .. ") " .. txt)
	ms_time = GetGameTimeMilliseconds()
end

local slideDirection = ptk.VM_MOVE_10_LEFT
local slideDistance = 0
local lastPin = 1
local directionText = {[ptk.VM_MOVE_10_LEFT]="Left10",[ptk.VM_MOVE_10_RIGHT]="Right10",}
function AHKLockpicking:BeginLockpicking()
	dmsg("BeginLockpicking")

	--ptk.SetIndOn(ptk.VM_MOVE_10_LEFT)
	--zo_callLater(function() AHKLockpicking:CheckLockPickStatus() end, 500)
	slideDistance = 0
	ptk.SetIndOn(slideDirection)
	AHKLockpicking:CheckLockPickStatus()
end
function AHKLockpicking:CheckLockPickStatus()
	local verbose = false
	local repeatrate = 50
	--d("Stress:"..tostring(GetSettingChamberStress()).." Chambers:"..tostring(IsChamberSolved(1))..":"..tostring(IsChamberSolved(2))..":"..tostring(IsChamberSolved(3))..":"..tostring(IsChamberSolved(4))..":"..tostring(IsChamberSolved(5)))
	state1, prog1 = GetChamberState(1)
	state2, prog2 = GetChamberState(2)
	state3, prog3 = GetChamberState(3)
	state4, prog4 = GetChamberState(4)
	state5, prog5 = GetChamberState(5)
	local state = {state1, state2, state3, state4, state5}
	local prog = {prog1, prog2, prog3, prog4, prog5}
	if verbose then
		d("Stress:"..tostring(GetSettingChamberStress()).." State,Prog"
			..":"..tostring(state1)..","..tostring(prog1)
			..":"..tostring(state2)..","..tostring(prog2)
			..":"..tostring(state3)..","..tostring(prog3)
			..":"..tostring(state4)..","..tostring(prog4)
			..":"..tostring(state5)..","..tostring(prog5))
		d("Left:"..tostring(ptk.IsIndOn(ptk.VM_MOVE_10_LEFT))
			.." Right:"..tostring(ptk.IsIndOn(ptk.VM_MOVE_10_RIGHT))
			.." Mouse:"..tostring(ptk.IsIndOn(ptk.VM_BTN_LEFT)))
	end
	if ptk.IsIndOn(ptk.VM_MOVE_10_RIGHT) or ptk.IsIndOn(ptk.VM_MOVE_10_LEFT) then
		slideDistance = slideDistance + 50
		if slideDistance > 500 then
			slideDistance = 0
			if slideDirection == ptk.VM_MOVE_10_LEFT then
				slideDirection = ptk.VM_MOVE_10_RIGHT
			else
				slideDirection = ptk.VM_MOVE_10_LEFT
			end
		end
	end
	if prog1 > 0 then lastPin = 1
	elseif prog2 > 0 then lastPin = 2
	elseif prog3 > 0 then lastPin = 3
	elseif prog4 > 0 then lastPin = 4
	elseif prog5 > 0 then lastPin = 5
	end

	if ptk.IsIndOn(ptk.VM_BTN_LEFT) then
		if GetSettingChamberStress() > 0 then
			if verbose then d("- chamber stressed, stop pressing and look for next pin") end

			local cntReadyL = 0
			local cntReadyR = 0
			for i=1,5 do
				if i < lastPin and state[i] == 0 then cntReadyL = cntReadyL + 1 end
				if i > lastPin and state[i] == 0 then cntReadyR = cntReadyR + 1 end
			end
			if cntReadyR == 0 then slideDirection = ptk.VM_MOVE_10_LEFT
			elseif cntReadyL == 0 then slideDirection = ptk.VM_MOVE_10_RIGHT
			elseif cntReadyL < cntReadyR then slideDirection = ptk.VM_MOVE_10_LEFT
			else slideDirection = ptk.VM_MOVE_10_RIGHT
			end

			if verbose then
				d(" lastPin:"..tostring(lastPin).." cntReadyL:"..tostring(cntReadyL).." cntReadyR:"..tostring(cntReadyR))
				if directionText[slideDirection] then d(directionText[slideDirection]) end
			end

			ptk.SetIndOff(ptk.VM_BTN_LEFT)
			ptk.SetIndOn(slideDirection) -- ptk.SetIndOn(ptk.VM_MOVE_10_RIGHT)
			zo_callLater(function() AHKLockpicking:CheckLockPickStatus() end, repeatrate)
		elseif (prog1 > 0 or prog2 > 0 or prog3 > 0 or prog4 > 0 or prog5 > 0) then
			if verbose then d("- pin is dropping, keep holding") end
			zo_callLater(function() AHKLockpicking:CheckLockPickStatus() end, repeatrate)
		else
			if verbose then d("- not on a pin so start moving right") end
			ptk.SetIndOff(ptk.VM_BTN_LEFT)
			ptk.SetIndOn(slideDirection) -- ptk.SetIndOn(ptk.VM_MOVE_10_RIGHT)
			zo_callLater(function() AHKLockpicking:CheckLockPickStatus() end, repeatrate)
		end
	elseif ptk.IsIndOn(ptk.VM_MOVE_10_RIGHT) then
		if verbose then d("- stop moving right and check pin") end
		ptk.SetIndOff(ptk.VM_MOVE_10_RIGHT)
		ptk.SetIndOn(ptk.VM_BTN_LEFT)
		zo_callLater(function() AHKLockpicking:CheckLockPickStatus() end, repeatrate)
	elseif ptk.IsIndOn(ptk.VM_MOVE_10_LEFT) then
		if verbose then d("- stop moving left and check pin") end
		ptk.SetIndOff(ptk.VM_MOVE_10_LEFT)
		ptk.SetIndOn(ptk.VM_BTN_LEFT)
		zo_callLater(function() AHKLockpicking:CheckLockPickStatus() end, repeatrate)
	end
end
local setBackGamepad = GetSetting(SETTING_TYPE_GAMEPAD, GAMEPAD_SETTING_INPUT_PREFERRED_MODE)
function AHKLockpicking:EndLockpicking()
	dmsg("EndLockpicking")
	ptk.SetIndOff(ptk.VM_MOVE_10_LEFT) -- stop moving
	ptk.SetIndOff(ptk.VM_MOVE_10_RIGHT) -- stop moving
	ptk.SetIndOff(ptk.VM_BTN_LEFT) -- stop pressing

	SetSetting(SETTING_TYPE_GAMEPAD, GAMEPAD_SETTING_INPUT_PREFERRED_MODE, setBackGamepad)
end

function AHKLockpicking:Initialize()
	EVENT_MANAGER:RegisterForEvent(AHKLockpicking.name, EVENT_BEGIN_LOCKPICK, AHKLockpicking.BeginLockpicking)
	EVENT_MANAGER:RegisterForEvent(AHKLockpicking.name, EVENT_LOCKPICK_FAILED, AHKLockpicking.EndLockpicking)
	EVENT_MANAGER:RegisterForEvent(AHKLockpicking.name, EVENT_LOCKPICK_SUCCESS, AHKLockpicking.EndLockpicking)
	EVENT_MANAGER:RegisterForEvent(AHKLockpicking.name, EVENT_LOCKPICK_BROKE, AHKLockpicking.EndLockpicking)

	EVENT_MANAGER:RegisterForEvent(AHKLockpicking.name, EVENT_CLIENT_INTERACT_RESULT, function()
			local curAction, curInteractableName, curInteractBlocked, curIsOwned, curAdditionalInfo, curContextualInfo, curContextualLink, curIsCriminalInteract = GetGameCameraInteractableActionInfo()
			if curAction == "Unlock" then
				setBackGamepad = GetSetting(SETTING_TYPE_GAMEPAD, GAMEPAD_SETTING_INPUT_PREFERRED_MODE)
				if setBackGamepad ~= 0 then SetSetting(SETTING_TYPE_GAMEPAD, GAMEPAD_SETTING_INPUT_PREFERRED_MODE, 0) end
			end
		end)

end

-- Then we create an event handler function which will be called when the "addon loaded" event
-- occurs. We'll use this to initialize our addon after all of its resources are fully loaded.
function AHKLockpicking.OnAddOnLoaded(event, addonName) -- The event fires each time *any* addon loads - but we only care about when our own addon loads.
    if addonName == AHKLockpicking.name then AHKLockpicking:Initialize() end
end

-- Finally, we'll register our event handler function to be called when the proper event occurs.
EVENT_MANAGER:RegisterForEvent(AHKLockpicking.name, EVENT_ADD_ON_LOADED, AHKLockpicking.OnAddOnLoaded)

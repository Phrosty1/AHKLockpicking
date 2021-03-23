-- For menu & data
AHKLockpicking = {}
AHKLockpicking.name = "AHKLockpicking"

local GetGameTimeMilliseconds = GetGameTimeMilliseconds
local GetChamberState = GetChamberState
local GetSettingChamberStress = GetSettingChamberStress
local zo_callLater = zo_callLater
local SetSetting = SetSetting
local GetSetting = GetSetting

local verbose = false
local ptk = LibPixelControl
local ms_time = GetGameTimeMilliseconds()
local function dmsg(txt)
	d((GetGameTimeMilliseconds() - ms_time) .. ") " .. txt)
	ms_time = GetGameTimeMilliseconds()
end

local isLockpicking = false
local handleRestoreGamepad
local identifierSmallCycle = "AHKLockpicking_SmallCycle"

-- intervals have a 15 ms minimum
local intervalWhileMoving = 30
local intervalWhileFinding = 90
local intervalWhilePressing = 15
local intervalWhileReleasing = 15
local intervalHoldUntil = GetGameTimeMilliseconds()

local pxlMouseLeft = ptk.VM_MOVE_10_LEFT
local pxlMouseRight = ptk.VM_MOVE_10_RIGHT
local pxlMouseButton = ptk.VM_BTN_LEFT
local slideDirection = pxlMouseLeft
local slideDistance = 0
local lastPin = 1
local directionText = {[ptk.VM_MOVE_LEFT]="Left1",[ptk.VM_MOVE_RIGHT]="Right1",[ptk.VM_MOVE_10_LEFT]="Left10",[ptk.VM_MOVE_10_RIGHT]="Right10",}
local InputPreferredMode = {[INPUT_PREFERRED_MODE_ALWAYS_GAMEPAD]="INPUT_PREFERRED_MODE_ALWAYS_GAMEPAD",[INPUT_PREFERRED_MODE_ALWAYS_KEYBOARD]="INPUT_PREFERRED_MODE_ALWAYS_KEYBOARD",[INPUT_PREFERRED_MODE_AUTOMATIC]="INPUT_PREFERRED_MODE_AUTOMATIC",}
local setBackGamepad = GetSetting(SETTING_TYPE_GAMEPAD, GAMEPAD_SETTING_INPUT_PREFERRED_MODE)

function AHKLockpicking:CleanUp()
	if handleRestoreGamepad then
		EVENT_MANAGER:UnregisterForUpdate("CallLaterFunction"..handleRestoreGamepad)
	end
	if isLockpicking then
		ptk.SetIndOff(pxlMouseLeft) -- stop moving
		ptk.SetIndOff(pxlMouseRight) -- stop moving
		ptk.SetIndOff(pxlMouseButton) -- stop pressing
	end
	if (isLockpicking or handleRestoreGamepad) and GetSetting(SETTING_TYPE_GAMEPAD, GAMEPAD_SETTING_INPUT_PREFERRED_MODE) ~= setBackGamepad then
		SetSetting(SETTING_TYPE_GAMEPAD, GAMEPAD_SETTING_INPUT_PREFERRED_MODE, setBackGamepad)
	end
	handleRestoreGamepad = nil
	isLockpicking = false
	EVENT_MANAGER:UnregisterForUpdate(identifierSmallCycle)
end
function AHKLockpicking:PreLockpicking()
	--dmsg("PreLockpicking")
	local curAction, curInteractableName, curInteractBlocked, curIsOwned, curAdditionalInfo, curContextualInfo, curContextualLink, curIsCriminalInteract = GetGameCameraInteractableActionInfo()
	if curAction == "Unlock" or (curAction == "Open" and curInteractableName == "Door" and GetMapNameById(GetCurrentMapId()) == "Stone Garden") then
		setBackGamepad = GetSetting(SETTING_TYPE_GAMEPAD, GAMEPAD_SETTING_INPUT_PREFERRED_MODE)
		if setBackGamepad ~= 0 then
			SetSetting(SETTING_TYPE_GAMEPAD, GAMEPAD_SETTING_INPUT_PREFERRED_MODE, 0)
		end
		handleRestoreGamepad = zo_callLater(AHKLockpicking.CleanUp, 700)
	end
end
local msCurTime = GetGameTimeMilliseconds()
local msPrvTime = GetGameTimeMilliseconds()
function AHKLockpicking:BeginLockpicking()
	dmsg("BeginLockpicking")
	isLockpicking = true
	if handleRestoreGamepad then
		EVENT_MANAGER:UnregisterForUpdate("CallLaterFunction"..handleRestoreGamepad)
		handleRestoreGamepad = nil
	end

	msCurTime = GetGameTimeMilliseconds()
	msPrvTime = msCurTime
	slideDistance = 0
	slideDirection = pxlMouseLeft
	if false then -- Start in the middle
		ptk.SetIndOn(pxlMouseButton)
		intervalHoldUntil = msCurTime + intervalWhileFinding
	else -- First, move to the left
		ptk.SetIndOn(slideDirection)
		intervalHoldUntil = msCurTime + 100
	end
	EVENT_MANAGER:RegisterForUpdate(identifierSmallCycle, 15, AHKLockpicking.CheckLockPickStatus) -- 15 seems to be minimum
end
function AHKLockpicking:CheckLockPickStatus()
	if not isLockpicking then return end
	msCurTime = GetGameTimeMilliseconds()
	if msCurTime < intervalHoldUntil then return end
	
	local state1, prog1 = GetChamberState(1)
	local state2, prog2 = GetChamberState(2)
	local state3, prog3 = GetChamberState(3)
	local state4, prog4 = GetChamberState(4)
	local state5, prog5 = GetChamberState(5)
	local stress = GetSettingChamberStress()
	local state = {state1, state2, state3, state4, state5}
	local prog = {prog1, prog2, prog3, prog4, prog5}
	if prog1 > 0 then lastPin = 1
	elseif prog2 > 0 then lastPin = 2
	elseif prog3 > 0 then lastPin = 3
	elseif prog4 > 0 then lastPin = 4
	elseif prog5 > 0 then lastPin = 5
	end
	local str = ""
	local isPressingLeft, isPressingRight, isPressingButton = ptk.IsIndOn(pxlMouseLeft), ptk.IsIndOn(pxlMouseRight), ptk.IsIndOn(pxlMouseButton)
	if verbose then
		local function FmtProg(prognum)
			if prognum > 0 and prognum < 1 then return 0.5 else return prognum end
		end
		if isPressingLeft then str = str.."L" else str = str.." " end
		if isPressingRight then str = str.."R" else str = str.." " end
		if isPressingButton then str = str.."B" else str = str.." " end
		str = str.." ("..tostring(state1)..","..tostring(FmtProg(prog1))..")"
		str = str.." ("..tostring(state2)..","..tostring(FmtProg(prog2))..")"
		str = str.." ("..tostring(state3)..","..tostring(FmtProg(prog3))..")"
		str = str.." ("..tostring(state4)..","..tostring(FmtProg(prog4))..")"
		str = str.." ("..tostring(state5)..","..tostring(FmtProg(prog5))..")"
		str = str.." S"..tostring(FmtProg(stress))
	end
	if isPressingRight or isPressingLeft then
		slideDistance = slideDistance + (msCurTime - msPrvTime)
		if slideDistance > 300 then
			slideDistance = 0
			if slideDirection == pxlMouseLeft then
				slideDirection = pxlMouseRight
			else
				slideDirection = pxlMouseLeft
			end
		end
	end

	if isPressingButton then
		if stress > 0 then -- chamber stressed, stop pressing, wait, then look for next pin
			slideDistance = 0
			local cntReadyL = 0
			local cntReadyR = 0
			for i=1,5 do
				if i < lastPin and state[i] == 0 then cntReadyL = cntReadyL + 1 end
				if i > lastPin and state[i] == 0 then cntReadyR = cntReadyR + 1 end
			end
			if cntReadyR == 0 then slideDirection = pxlMouseLeft
			elseif cntReadyL == 0 then slideDirection = pxlMouseRight
			elseif cntReadyL < cntReadyR then slideDirection = pxlMouseLeft
			else slideDirection = pxlMouseRight
			end

			ptk.SetIndOff(pxlMouseButton)
			if cntReadyL + cntReadyR == 0 then return end -- Finished
			--if cntReadyL + cntReadyR == 1 then dmsg("Press Esc") ptk.SetIndOnFor(ptk.VK_ESCAPE) return end -- FOR DEBUG - exit after 4 pins
			intervalHoldUntil = msCurTime + intervalWhileReleasing
		elseif (prog1 > 0 or prog2 > 0 or prog3 > 0 or prog4 > 0 or prog5 > 0) then -- pin is dropping, keep holding
			intervalHoldUntil = msCurTime + intervalWhilePressing
		else -- not on a pin so resume moving
			ptk.SetIndOff(pxlMouseButton)
			ptk.SetIndOn(slideDirection)
			intervalHoldUntil = msCurTime + intervalWhileMoving
		end
	elseif isPressingRight or isPressingLeft then -- stop moving and check pin
		if isPressingRight then ptk.SetIndOff(pxlMouseRight) end
		if isPressingLeft then ptk.SetIndOff(pxlMouseLeft) end
		ptk.SetIndOn(pxlMouseButton) -- isPressingButton = true
		intervalHoldUntil = msCurTime + intervalWhileFinding
	elseif stress > 0 then -- wait for stress to drop
		intervalHoldUntil = msCurTime + intervalWhileReleasing
	else
		ptk.SetIndOn(slideDirection)
		intervalHoldUntil = msCurTime + intervalWhileMoving
	end
	if verbose and str ~= nil then dmsg(str) end
	msPrvTime = msCurTime
end
function AHKLockpicking:EndLockpicking()
	ptk.SetIndOff(pxlMouseLeft) -- stop moving
	ptk.SetIndOff(pxlMouseRight) -- stop moving
	ptk.SetIndOff(pxlMouseButton) -- stop pressing
	if not isLockpicking then return end
	dmsg("EndLockpicking")
	AHKLockpicking:CleanUp()
end
function AHKLockpicking:Initialize()
	EVENT_MANAGER:RegisterForEvent(AHKLockpicking.name, EVENT_CLIENT_INTERACT_RESULT, AHKLockpicking.PreLockpicking)
	EVENT_MANAGER:RegisterForEvent(AHKLockpicking.name, EVENT_BEGIN_LOCKPICK, AHKLockpicking.BeginLockpicking)
	EVENT_MANAGER:RegisterForEvent(AHKLockpicking.name, EVENT_LOCKPICK_FAILED, AHKLockpicking.EndLockpicking)
	EVENT_MANAGER:RegisterForEvent(AHKLockpicking.name, EVENT_LOCKPICK_SUCCESS, AHKLockpicking.EndLockpicking)
	EVENT_MANAGER:RegisterForEvent(AHKLockpicking.name, EVENT_LOCKPICK_BROKE, AHKLockpicking.EndLockpicking)

	EVENT_MANAGER:RegisterForEvent(AHKLockpicking.name, EVENT_INTERACT_BUSY, AHKLockpicking.CleanUp)
	EVENT_MANAGER:RegisterForEvent(AHKLockpicking.name, EVENT_PENDING_INTERACTION_CANCELLED, AHKLockpicking.CleanUp)
end

-- Then we create an event handler function which will be called when the "addon loaded" event
-- occurs. We'll use this to initialize our addon after all of its resources are fully loaded.
function AHKLockpicking.OnAddOnLoaded(event, addonName) -- The event fires each time *any* addon loads - but we only care about when our own addon loads.
    if addonName == AHKLockpicking.name then AHKLockpicking:Initialize() end
end

-- Finally, we'll register our event handler function to be called when the proper event occurs.
EVENT_MANAGER:RegisterForEvent(AHKLockpicking.name, EVENT_ADD_ON_LOADED, AHKLockpicking.OnAddOnLoaded)

--Curvature drive is a drive mode that doesn't let you turn in place, like driving a car,
--but is better at driving curves at high speeds.
--Arcade drive is a drive that can turn in place, but the turning becomes wonky at higher speeds
--Blended drive sorta mashes the two together to have a more smooth way of turning and driving,
--both at high, low, and stopped speeds.
--(to speak technically it linearly interpolates between the two speed curves to have it 
--blend in a more intuitive(?) way.)

require("utils.math")

---@param moveValue number
---@param turnValue number
---@param inputThreshold number?
---@return number, number
function getBlendedMotorValues(moveValue, turnValue, inputThreshold)
	-- default value
	inputThreshold = inputThreshold or 0.1

	local arcadeLeft, arcadeRight = DifferentialDrive:curvatureDriveIK(moveValue, turnValue, true)
	local curvatureLeft, curvatureRight = DifferentialDrive:curvatureDriveIK(moveValue, turnValue, false)

	lerpT = math.abs(moveValue) / inputThreshold;
	lerpT = clamp(lerpT, 0, 1)
	leftBlend = lerp(arcadeLeft, curvatureLeft, lerpT)
	rightBlend = lerp(arcadeRight, curvatureRight, lerpT)

	return leftBlend, rightBlend
end

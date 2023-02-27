require("utils.geometry")
local ffi = require("ffi")

---@return PhotonPipelineResult
function PhotonCamera:getLatestResult()
	local instance = {
		_this = ffi.gc(ffi.C.PhotonCamera_GetLatestResult(self._this), ffi.C.liberate),
	}
	setmetatable(instance, PhotonPipelineResult)
	PhotonPipelineResult.__index = PhotonPipelineResult

	return instance
end

---@return PhotonTrackedTarget
function PhotonPipelineResult:getBestTarget()
	local instance = {
		_this = ffi.gc(ffi.C.PhotonPipelineResult_GetBestTarget(self._this), ffi.C.liberate),
	}
	setmetatable(instance, PhotonTrackedTarget)
	PhotonTrackedTarget.__index = PhotonTrackedTarget

	return instance
end

---@return Transform3d
function PhotonTrackedTarget:getBestCameraToTarget()
	local result = ffi.new("Pose*", ffi.C.PhotonTrackedTarget_GetBestCameraToTarget(self._this));

	local pos = Translate3d:new(result.x, result.y, result.z)
	local rot = Rotate3d:new(result.rotx, result.roty, result.rotz)

	return Transform3d:new(pos, rot)
end

---@param field number|string
---@param poseStrategy number
---@param camera PhotonCamera
---@param robotToCamera Transform3d
---@return PhotonPoseEstimator
function PhotonPoseEstimator:new(field, poseStrategy, camera, robotToCamera)
	poseStrategy = AssertEnumValue(PoseStrategy, poseStrategy)
	local instance
	if type(field) == "table" then
		field = AssertEnumValue(AprilTagField, field)
		
		instance = {
			_this = ffi.C.PhotonPoseEstimator_newFromEnum(field, poseStrategy, camera._this, robotToCamera.position.x, robotToCamera.position.y, robotToCamera.position.z, robotToCamera.rotation.x, robotToCamera.rotation.y, robotToCamera.rotation.z)
		}
	else
		instance = {
			_this = ffi.C.PhotonPoseEstimator_newFromPath(field, poseStrategy, camera._this, robotToCamera.position.x, robotToCamera.position.y, robotToCamera.position.z, robotToCamera.rotation.x, robotToCamera.rotation.y, robotToCamera.rotation.z)
		}
	end

	setmetatable(instance, self)
	self.__index = self

	return instance
end

---@param pose Transform3d
function PhotonPoseEstimator:setReferencePose(pose)
	ffi.C.PhotonPoseEstimator_SetReferencePose(pose.position.x, pose.position.y, pose.position.z, pose.rotation.x, pose.rotation.y, pose.rotation.z)
end

---@param pose Transform3d
function PhotonPoseEstimator:setLastPose(pose)
	ffi.C.PhotonPoseEstimator_SetLastPose(pose.position.x, pose.position.y, pose.position.z, pose.rotation.x, pose.rotation.y, pose.rotation.z)
end

---@return Transform3d? pose, number timestamp
function PhotonPoseEstimator:update()
	local result = ffi.new("PoseEstimate*", ffi.C.PhotonPoseEstimator_Update(self._this))

	local pos = Translate3d:new(result.pose.x, result.pose.y, result.pose.z)
	local rot = Rotate3d:new(result.pose.rotx, result.pose.roty, result.pose.rotz)

	if result.timestamp == -1 then
		return nil
	end

	return Transform3d:new(pos, rot), result.timestamp
end
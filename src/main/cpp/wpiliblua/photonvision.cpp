// Automatically generated by bindings.c. DO NOT EDIT.

#include <photonlib/PhotonCamera.h>
#include <photonlib/PhotonPoseEstimator.h>
#include <frc/apriltag/AprilTagFields.h>

#include "luadef.h"

LUAFUNC void* PhotonCamera_new(const char * cameraName) {
    return new photonlib::PhotonCamera((std::string_view)cameraName);
}

LUAFUNC void * PhotonCamera_GetLatestResult(void* _this) {
	return new photonlib::PhotonPipelineResult(((photonlib::PhotonCamera*)_this)->GetLatestResult());
}

LUAFUNC void PhotonCamera_SetDriverMode(void* _this, bool driverMode) {
    ((photonlib::PhotonCamera*)_this)
        ->SetDriverMode(driverMode);
}

LUAFUNC bool PhotonCamera_GetDriverMode(void* _this) {
    auto _result = ((photonlib::PhotonCamera*)_this)
        ->GetDriverMode();
    return (bool)_result;
}

LUAFUNC void PhotonCamera_TakeInputSnapshot(void* _this) {
    ((photonlib::PhotonCamera*)_this)
        ->TakeInputSnapshot();
}

LUAFUNC void PhotonCamera_TakeOutputSnapshot(void* _this) {
    ((photonlib::PhotonCamera*)_this)
        ->TakeOutputSnapshot();
}

LUAFUNC void PhotonCamera_SetPipelineIndex(void* _this, int index) {
    ((photonlib::PhotonCamera*)_this)
        ->SetPipelineIndex(index);
}

LUAFUNC int PhotonCamera_GetPipelineIndex(void* _this) {
    auto _result = ((photonlib::PhotonCamera*)_this)
        ->GetPipelineIndex();
    return (int)_result;
}

LUAFUNC void * PhotonPipelineResult_GetBestTarget(void* _this) {
	return new photonlib::PhotonTrackedTarget(((photonlib::PhotonPipelineResult*)_this)->GetBestTarget());
}

LUAFUNC bool PhotonPipelineResult_HasTargets(void* _this) {
    auto _result = ((photonlib::PhotonPipelineResult*)_this)
        ->HasTargets();
    return (bool)_result;
}

typedef struct { double x, y, z; double rotx, roty, rotz; } Pose;
LUAFUNC double PhotonTrackedTarget_GetYaw(void* _this) {
    auto _result = ((photonlib::PhotonTrackedTarget*)_this)
        ->GetYaw();
    return (double)_result;
}

LUAFUNC double PhotonTrackedTarget_GetPitch(void* _this) {
    auto _result = ((photonlib::PhotonTrackedTarget*)_this)
        ->GetPitch();
    return (double)_result;
}

LUAFUNC double PhotonTrackedTarget_GetArea(void* _this) {
    auto _result = ((photonlib::PhotonTrackedTarget*)_this)
        ->GetArea();
    return (double)_result;
}

LUAFUNC double PhotonTrackedTarget_GetSkew(void* _this) {
    auto _result = ((photonlib::PhotonTrackedTarget*)_this)
        ->GetSkew();
    return (double)_result;
}

LUAFUNC int PhotonTrackedTarget_GetFiducialId(void* _this) {
    auto _result = ((photonlib::PhotonTrackedTarget*)_this)
        ->GetFiducialId();
    return (int)_result;
}

LUAFUNC double PhotonTrackedTarget_GetPoseAmbiguity(void* _this) {
    auto _result = ((photonlib::PhotonTrackedTarget*)_this)
        ->GetPoseAmbiguity();
    return (double)_result;
}

LUAFUNC Pose * PhotonTrackedTarget_GetBestCameraToTarget(void* _this) {
	auto result = ((photonlib::PhotonTrackedTarget*)_this)->GetBestCameraToTarget();
	return new Pose{
		result.X().convert<units::inch>().value(), result.Y().convert<units::inch>().value(), result.Z().convert<units::inch>().value(),
		result.Rotation().X().value(), result.Rotation().Y().value(), result.Rotation().Z().value(),
	};
}

typedef struct { Pose pose; double timestamp; } PoseEstimate;
LUAFUNC void* PhotonPoseEstimator_newFromEnum(int field, int poseStrategy, void * camera, double x, double y, double z, double rotx, double roty, double rotz) {
	return new photonlib::PhotonPoseEstimator(frc::LoadAprilTagLayoutField((frc::AprilTagField)field), (photonlib::PoseStrategy)poseStrategy, std::move(*(photonlib::PhotonCamera*)camera), frc::Transform3d(frc::Translation3d(units::inch_t(x), units::inch_t(y), units::inch_t(z)), frc::Rotation3d(units::angle::radian_t(rotx), units::angle::radian_t(roty), units::angle::radian_t(rotz))));
}

LUAFUNC void* PhotonPoseEstimator_newFromPath(const char * fieldPath, int poseStrategy, void * camera, double x, double y, double z, double rotx, double roty, double rotz) {
	return new photonlib::PhotonPoseEstimator(frc::AprilTagFieldLayout((std::string_view)fieldPath), (photonlib::PoseStrategy)poseStrategy, std::move(*(photonlib::PhotonCamera*)camera), frc::Transform3d(frc::Translation3d(units::inch_t(x), units::inch_t(y), units::inch_t(z)), frc::Rotation3d(units::angle::radian_t(rotx), units::angle::radian_t(roty), units::angle::radian_t(rotz))));
}

LUAFUNC int PhotonPoseEstimator_GetPoseStrategy(void* _this) {
    auto _result = ((photonlib::PhotonPoseEstimator*)_this)
        ->GetPoseStrategy();
    return (int)_result;
}

LUAFUNC void PhotonPoseEstimator_SetPoseStrategy(void* _this, int poseStrategy) {
    ((photonlib::PhotonPoseEstimator*)_this)
        ->SetPoseStrategy((photonlib::PoseStrategy)poseStrategy);
}

LUAFUNC void PhotonPoseEstimator_SetReferencePose(void* _this, double x, double y, double z, double rotx, double roty, double rotz) {
	return ((photonlib::PhotonPoseEstimator*)_this)->SetReferencePose(frc::Pose3d(frc::Translation3d(units::inch_t(x), units::inch_t(y), units::inch_t(z)), frc::Rotation3d(units::angle::radian_t(rotx), units::angle::radian_t(roty), units::angle::radian_t(rotz))));
}

LUAFUNC void PhotonPoseEstimator_SetLastPose(void* _this, double x, double y, double z, double rotx, double roty, double rotz) {
	return ((photonlib::PhotonPoseEstimator*)_this)->SetLastPose(frc::Pose3d(frc::Translation3d(units::inch_t(x), units::inch_t(y), units::inch_t(z)), frc::Rotation3d(units::angle::radian_t(rotx), units::angle::radian_t(roty), units::angle::radian_t(rotz))));
}

LUAFUNC PoseEstimate * PhotonPoseEstimator_Update(void* _this) {
	auto [pose, timestamp] = ((photonlib::PhotonPoseEstimator*)_this)->Update().value_or(photonlib::EstimatedRobotPose(frc::Pose3d(), -1_s));
	return new PoseEstimate{{pose.X().convert<units::inch>().value(), pose.Y().convert<units::inch>().value(), pose.Z().convert<units::inch>().value(), pose.Rotation().X().value(), pose.Rotation().Y().value(), pose.Rotation().Z().value()}, timestamp.value()};
}

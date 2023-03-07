#include "luadef.h"

#include <frc/estimator/DifferentialDrivePoseEstimator.h>

const units::meter_t trackWidth = 22_in; // Distance from left wheels to right wheels. VALUE MAY CHANGE PLEASE UPDATE IF YOU NEED TO!!!

frc::DifferentialDriveKinematics kinematics(trackWidth);

LUAFUNC void *DDPE_new(double angleRad, double leftDistance, double rightDistance, double x, double y, double rotationRad)
{
	return new frc::DifferentialDrivePoseEstimator(kinematics, frc::Rotation2d{(units::radian_t)angleRad}, (units::inch_t)leftDistance, (units::inch_t)rightDistance, {(units::inch_t)x, (units::inch_t)y, (units::radian_t)rotationRad});
}

LUAFUNC void DDPE_SetVisionMeasurementStdDevs(void *_this, double x, double y, double headingRad)
{
	((frc::DifferentialDrivePoseEstimator *)_this)->SetVisionMeasurementStdDevs({x, y, headingRad});
}

LUAFUNC void DDPE_ResetPosition(void *_this, double angleRad, double leftDistance, double rightDistance, double x, double y, double rotationRad)
{
	((frc::DifferentialDrivePoseEstimator *)_this)->ResetPosition({(units::radian_t)angleRad}, (units::inch_t)leftDistance, (units::inch_t)rightDistance, {(units::inch_t)x, (units::inch_t)y, (units::radian_t)rotationRad});
}

LUAFUNC double DDPE_GetEstimatedX(void *_this)
{
	return ((units::inch_t)((frc::DifferentialDrivePoseEstimator *)_this)->GetEstimatedPosition().X()).value();
}

LUAFUNC double DDPE_GetEstimatedY(void *_this)
{
	return ((units::inch_t)((frc::DifferentialDrivePoseEstimator *)_this)->GetEstimatedPosition().Y()).value();
}

LUAFUNC double DDPE_GetEstimatedRotationRad(void *_this)
{
	return ((frc::DifferentialDrivePoseEstimator *)_this)->GetEstimatedPosition().Rotation().Radians().value();
}

LUAFUNC void DDPE_AddVisionMeasurement(void *_this, double x, double y, double angleRad, double timestampSeconds)
{
	((frc::DifferentialDrivePoseEstimator *)_this)->AddVisionMeasurement({(units::inch_t)x, (units::inch_t)y, (units::radian_t)angleRad}, (units::second_t)timestampSeconds);
}

LUAFUNC void DDPE_Update(void *_this, double angleRad, double leftDistance, double rightDistance)
{
	((frc::DifferentialDrivePoseEstimator *)_this)->Update({(units::radian_t)angleRad}, (units::inch_t)leftDistance, (units::inch_t)rightDistance);
}
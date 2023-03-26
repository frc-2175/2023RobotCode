#include "luadef.h"

#include <frc/smartdashboard/Field2d.h>

typedef struct {
	double x, y, rot;
} ObjectPose;

LUAFUNC void* Field2d_GetObject(void* _this, const char* name) {
    return ((frc::Field2d*)_this)->GetObject(name);
}

LUAFUNC void FieldObject2d_SetPose(void* _this, double x, double y, double rotation) {
    ((frc::FieldObject2d*)_this)->SetPose((units::inch_t)x, (units::inch_t)y, (units::radian_t)rotation);
}

LUAFUNC void FieldObject2d_SetPoses(void* _this, ObjectPose* poses, size_t count) {
	std::vector<frc::Pose2d> vec(count);
	
	for (size_t i = 0; i < count; i++) {
		vec[i] = frc::Pose2d{(units::inch_t)poses[i].x, (units::inch_t)poses[i].y, frc::Rotation2d((units::radian_t)poses[i].rot)};
	}

    ((frc::FieldObject2d*)_this)->SetPoses(vec);

}

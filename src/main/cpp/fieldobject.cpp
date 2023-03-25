#include "luadef.h"

#include <frc/smartdashboard/Field2d.h>

LUAFUNC void* Field2d_GetObject(void* _this, const char* name) {
    return ((frc::Field2d*)_this)->GetObject(name);
}

LUAFUNC void FieldObject2d_SetPose(void* _this, double x, double y, double rotation) {
    ((frc::FieldObject2d*)_this)->SetPose((units::inch_t)x, (units::inch_t)y, (units::radian_t)rotation);
}

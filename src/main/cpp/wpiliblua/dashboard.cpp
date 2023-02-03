// Automatically generated by bindings.c. DO NOT EDIT.

#include <string_view>
#include <span>
#include <frc/smartdashboard/SmartDashboard.h>
#include <frc/smartdashboard/SendableChooser.h>
#include <frc/smartdashboard/Field2d.h>

#include "luadef.h"

LUAFUNC void PutNumber(const char * keyName, double value) {
    frc::SmartDashboard::PutNumber((std::string_view)keyName, value);
}

LUAFUNC void PutNumberArray(const char * keyName, double * value, size_t size) {
	frc::SmartDashboard::PutNumberArray((std::string_view)keyName, std::span(value, size));
}

LUAFUNC void PutString(const char * keyName, const char* value) {
    frc::SmartDashboard::PutString((std::string_view)keyName, (std::string_view)value);
}

LUAFUNC void PutStringArray(const char * keyName, const char ** value, size_t size) {
	std::vector<std::string> strVec(value, value + size);
	frc::SmartDashboard::PutStringArray((std::string_view)keyName, std::span<std::string>(strVec));
}

LUAFUNC void PutBoolean(const char * keyName, bool value) {
    frc::SmartDashboard::PutBoolean((std::string_view)keyName, value);
}

LUAFUNC void PutBooleanArray(const char * keyName, int * value, size_t size) {
	frc::SmartDashboard::PutBooleanArray((std::string_view)keyName, std::span(value, size));
}

LUAFUNC void PutIntChooser(void * data) {
    frc::SmartDashboard::PutData((frc::SendableChooser<int>*)data);
}

LUAFUNC void PutField(void * field) {
    frc::SmartDashboard::PutData((frc::Field2d*)field);
}

LUAFUNC void* SendableChooser_new() {
    return new frc::SendableChooser<int>();
}

LUAFUNC void SendableChooser_AddOption(void* _this, const char * name, int object) {
    ((frc::SendableChooser<int>*)_this)
        ->AddOption((std::string_view)name, object);
}

LUAFUNC int SendableChooser_GetSelected(void* _this) {
    auto _result = ((frc::SendableChooser<int>*)_this)
        ->GetSelected();
    return (int)_result;
}

LUAFUNC void* Field2d_new() {
    return new frc::Field2d();
}

LUAFUNC void Field2d_SetRobotPose(void* _this, double x, double y, double rotation) {
    ((frc::Field2d*)_this)
        ->SetRobotPose(units::inch_t(x), units::inch_t(y), units::radian_t(rotation));
}

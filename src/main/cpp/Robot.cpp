// Copyright (c) FIRST and other WPILib contributors.
// Open Source Software; you can modify and/or share it under the terms of
// the WPILib BSD license file in the root directory of this project.

#include <frc/TimedRobot.h>
#include <lua.hpp>
#include <frc/smartdashboard/SendableChooser.h>
#include <frc/smartdashboard/SmartDashboard.h>

#include "httpserver.h"
#include "luahelpers.h"

class Robot : public frc::TimedRobot {
	lua_State* L;
	bool ok = false;

public:
	void RobotInit() override {
		L = luaL_newstate();
		luaL_openlibs(L);

		// Disable tests in real robot code
		RunLuaString(L, "function test() end");
		RunLuaString(L, "function isTesting() return false end");

		int initError = RunLuaFile(L, "init.lua");
		if (initError) {
			return;
		} else {
			ok = true;
		}

		RunLuaFile(L, "robot.lua");
		RunLuaString(L, "Robot.robotInit()");

		StartHTTPServer();
	}

	void RobotPeriodic() override {
		if (ok) RunLuaString(L, "Robot.robotPeriodic()");
	}

	void DisabledInit() override {
		if (ok) RunLuaString(L, "Robot.disabledInit()");
	}

	void DisabledPeriodic() override {
		if (ok) RunLuaString(L, "Robot.disabledPeriodic()");
	}

	void AutonomousInit() override {
		if (ok) RunLuaString(L, "Robot.autonomousInit()");
	}

	void AutonomousPeriodic() override {
		if (ok) RunLuaString(L, "Robot.autonomousPeriodic()");
	}

	void TeleopInit() override {
		if (ok) RunLuaString(L, "Robot.teleopInit()");
	}

	void TeleopPeriodic() override {
		if (ok) RunLuaString(L, "Robot.teleopPeriodic()");
	}

	void SimulationInit() override {
		if (ok) RunLuaString(L, "Robot.simulationInit()");
	}

	void SimulationPeriodic() override {
		if (ok) RunLuaString(L, "Robot.simulationPeriodic()");
	}
};

#ifndef RUNNING_FRC_TESTS
int main() {
	return frc::StartRobot<Robot>();
}
#endif

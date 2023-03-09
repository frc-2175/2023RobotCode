-- Automatically generated by bindings.c. DO NOT EDIT.

local ffi = require("ffi")
ffi.cdef[[
void* Joystick_new(int port);
double Joystick_GetX(void* _this);
double Joystick_GetY(void* _this);
double Joystick_GetZ(void* _this);
double Joystick_GetTwist(void* _this);
double Joystick_GetThrottle(void* _this);
bool Joystick_GetTriggerHeld(void* _this);
bool Joystick_GetTriggerPressed(void* _this);
bool Joystick_GetTriggerReleased(void* _this);
bool Joystick_GetTopHeld(void* _this);
bool Joystick_GetTopPressed(void* _this);
bool Joystick_GetTopReleased(void* _this);
double Joystick_GetMagnitude(void* _this);
double Joystick_GetDirectionRadians(void* _this);
double Joystick_GetDirectionDegrees(void* _this);
bool Joystick_GetButtonHeld(void* _this, int button);
bool Joystick_GetButtonPressed(void* _this, int button);
bool Joystick_GetButtonReleased(void* _this, int button);
double Joystick_GetRawAxis(void* _this, int axis);
int Joystick_GetPOV(void* _this, int port);
int Joystick_GetAxisCount(void* _this);
int Joystick_GetPOVCount(void* _this);
int Joystick_GetButtonCount(void* _this);
bool Joystick_IsConnected(void* _this);
int Joystick_GetPort(void* _this);
void* VictorSPX_ToSpeedController(void* _this);
void VictorSPX_Set(void* _this, double value);
void VictorSPX_SetVoltage(void* _this, double output);
double VictorSPX_Get(void* _this);
void VictorSPX_SetInvertedBool(void* _this, bool isInverted);
bool VictorSPX_GetInvertedBool(void* _this);
void VictorSPX_Disable(void* _this);
void VictorSPX_StopMotor(void* _this);
void* VictorSPX_ToIMotorController(void* _this);
void VictorSPX_SetWithControlMode(void* _this, int mode, double value);
void VictorSPX_SetWithControlModeAndDemands(void* _this, int mode, double demand0, int demand1Type, double demand1);
void VictorSPX_NeutralOutput(void* _this);
void VictorSPX_SetNeutralMode(void* _this, int neutralMode);
void VictorSPX_SetSensorPhase(void* _this, bool PhaseSensor);
void VictorSPX_SetInverted(void* _this, int invertType);
bool VictorSPX_GetInverted(void* _this);
int VictorSPX_ConfigFactoryDefault(void* _this, int timeoutMs);
int VictorSPX_ConfigOpenloopRamp(void* _this, double secondsFromNeutralToFull, int timeoutMs);
int VictorSPX_ConfigClosedloopRamp(void* _this, double secondsFromNeutralToFull, int timeoutMs);
int VictorSPX_ConfigPeakOutputForward(void* _this, double percentOut, int timeoutMs);
int VictorSPX_ConfigPeakOutputReverse(void* _this, double percentOut, int timeoutMs);
int VictorSPX_ConfigNominalOutputForward(void* _this, double percentOut, int timeoutMs);
int VictorSPX_ConfigNominalOutputReverse(void* _this, double percentOut, int timeoutMs);
int VictorSPX_ConfigNeutralDeadband(void* _this, double percentDeadband, int timeoutMs);
int VictorSPX_ConfigVoltageCompSaturation(void* _this, double voltage, int timeoutMs);
int VictorSPX_ConfigVoltageMeasurementFilter(void* _this, int filterWindowSamples, int timeoutMs);
void VictorSPX_EnableVoltageCompensation(void* _this, bool enable);
bool VictorSPX_IsVoltageCompensationEnabled(void* _this);
double VictorSPX_GetBusVoltage(void* _this);
double VictorSPX_GetMotorOutputPercent(void* _this);
double VictorSPX_GetMotorOutputVoltage(void* _this);
double VictorSPX_GetTemperature(void* _this);
int VictorSPX_ConfigSelectedFeedbackCoefficient(void* _this, double coefficient, int pidIdx, int timeoutMs);
int VictorSPX_ConfigSensorTerm(void* _this, int sensorTerm, int feedbackDevice);
double VictorSPX_GetSelectedSensorPosition(void* _this, int pidIdx);
double VictorSPX_GetSelectedSensorVelocity(void* _this, int pidIdx);
int VictorSPX_SetSelectedSensorPosition(void* _this, double sensorPos, int pidIdx, int timeoutMs);
int VictorSPX_SetControlFramePeriod(void* _this, int frame, int periodMs);
void VictorSPX_OverrideLimitSwitchesEnable(void* _this, bool enable);
int VictorSPX_ConfigForwardSoftLimitThreshold(void* _this, double forwardSensorLimit, int timeoutMs);
int VictorSPX_ConfigReverseSoftLimitThreshold(void* _this, double reverseSensorLimit, int timeoutMs);
int VictorSPX_ConfigForwardSoftLimitEnable(void* _this, bool enable, int timeoutMs);
int VictorSPX_ConfigReverseSoftLimitEnable(void* _this, bool enable, int timeoutMs);
void VictorSPX_OverrideSoftLimitsEnable(void* _this, bool enable);
int VictorSPX_Config_kP(void* _this, int slotIdx, double value, int timeoutMs);
int VictorSPX_Config_kI(void* _this, int slotIdx, double value, int timeoutMs);
int VictorSPX_Config_kD(void* _this, int slotIdx, double value, int timeoutMs);
int VictorSPX_Config_kF(void* _this, int slotIdx, double value, int timeoutMs);
int VictorSPX_Config_IntegralZone(void* _this, int slotIdx, double value, int timeoutMs);
int VictorSPX_ConfigAllowableClosedloopError(void* _this, int slotIdx, double allowableCloseLoopError, int timeoutMs);
int VictorSPX_ConfigMaxIntegralAccumulator(void* _this, int slotIdx, double iaccum, int timeoutMs);
int VictorSPX_ConfigClosedLoopPeakOutput(void* _this, int slotIdx, double percentOut, int timeoutMs);
int VictorSPX_ConfigClosedLoopPeriod(void* _this, int slotIdx, int loopTimeMs, int timeoutMs);
int VictorSPX_ConfigAuxPIDPolarity(void* _this, bool invert, int timeoutMs);
int VictorSPX_SetIntegralAccumulator(void* _this, double iaccum, int pidIdx, int timeoutMs);
double VictorSPX_GetClosedLoopError(void* _this, int pidIdx);
double VictorSPX_GetIntegralAccumulator(void* _this, int pidIdx);
double VictorSPX_GetErrorDerivative(void* _this, int pidIdx);
int VictorSPX_SelectProfileSlot(void* _this, int slotIdx, int pidIdx);
double VictorSPX_GetClosedLoopTarget(void* _this, int pidIdx);
double VictorSPX_GetActiveTrajectoryPosition(void* _this, int pidIdx);
double VictorSPX_GetActiveTrajectoryArbFeedFwd(void* _this, int pidIdx);
int VictorSPX_ConfigMotionCruiseVelocity(void* _this, double sensorUnitsPer100ms, int timeoutMs);
int VictorSPX_ConfigMotionAcceleration(void* _this, double sensorUnitsPer100msPerSec, int timeoutMs);
int VictorSPX_ConfigMotionSCurveStrength(void* _this, int curveStrength, int timeoutMs);
int VictorSPX_ClearMotionProfileTrajectories(void* _this);
int VictorSPX_GetMotionProfileTopLevelBufferCount(void* _this);
bool VictorSPX_IsMotionProfileFinished(void* _this);
bool VictorSPX_IsMotionProfileTopLevelBufferFull(void* _this);
void VictorSPX_ProcessMotionProfileBuffer(void* _this);
int VictorSPX_ClearMotionProfileHasUnderrun(void* _this, int timeoutMs);
int VictorSPX_ChangeMotionControlFramePeriod(void* _this, int periodMs);
int VictorSPX_ConfigMotionProfileTrajectoryPeriod(void* _this, int baseTrajDurationMs, int timeoutMs);
int VictorSPX_ConfigMotionProfileTrajectoryInterpolationEnable(void* _this, bool enable, int timeoutMs);
int VictorSPX_ConfigFeedbackNotContinuous(void* _this, bool feedbackNotContinuous, int timeoutMs);
int VictorSPX_ConfigClearPositionOnLimitF(void* _this, bool clearPositionOnLimitF, int timeoutMs);
int VictorSPX_ConfigClearPositionOnLimitR(void* _this, bool clearPositionOnLimitR, int timeoutMs);
int VictorSPX_ConfigClearPositionOnQuadIdx(void* _this, bool clearPositionOnQuadIdx, int timeoutMs);
int VictorSPX_ConfigLimitSwitchDisableNeutralOnLOS(void* _this, bool limitSwitchDisableNeutralOnLOS, int timeoutMs);
int VictorSPX_ConfigSoftLimitDisableNeutralOnLOS(void* _this, bool softLimitDisableNeutralOnLOS, int timeoutMs);
int VictorSPX_ConfigPulseWidthPeriod_EdgesPerRot(void* _this, int pulseWidthPeriod_EdgesPerRot, int timeoutMs);
int VictorSPX_ConfigPulseWidthPeriod_FilterWindowSz(void* _this, int pulseWidthPeriod_FilterWindowSz, int timeoutMs);
int VictorSPX_GetLastError(void* _this);
int VictorSPX_GetFirmwareVersion(void* _this);
bool VictorSPX_HasResetOccurred(void* _this);
int VictorSPX_GetBaseID(void* _this);
int VictorSPX_GetControlMode(void* _this);
void VictorSPX_Follow(void* _this, void * masterToFollow);
void VictorSPX_ValueUpdated(void* _this);
void VictorSPX_Feed(void* _this);
void VictorSPX_SetExpiration(void* _this, double expirationTime);
bool VictorSPX_IsAlive(void* _this);
void VictorSPX_SetSafetyEnabled(void* _this, bool enabled);
bool VictorSPX_IsSafetyEnabled(void* _this);
void* VictorSPX_new(int deviceNumber);
void VictorSPX_SetWithVictorSPXControlMode(void* _this, int mode, double value);
void VictorSPX_SetWithVictorSPXControlModeAndDemands(void* _this, int mode, double demand0, int demand1Type, double demand1);
double VictorSPX_GetExpiration(void* _this);
void* TalonSRX_ToSpeedController(void* _this);
void TalonSRX_Set(void* _this, double value);
void TalonSRX_SetVoltage(void* _this, double output);
double TalonSRX_Get(void* _this);
void TalonSRX_SetInvertedBool(void* _this, bool isInverted);
bool TalonSRX_GetInvertedBool(void* _this);
void TalonSRX_Disable(void* _this);
void TalonSRX_StopMotor(void* _this);
void* TalonSRX_ToIMotorController(void* _this);
void TalonSRX_SetWithControlMode(void* _this, int mode, double value);
void TalonSRX_SetWithControlModeAndDemands(void* _this, int mode, double demand0, int demand1Type, double demand1);
void TalonSRX_NeutralOutput(void* _this);
void TalonSRX_SetNeutralMode(void* _this, int neutralMode);
void TalonSRX_SetSensorPhase(void* _this, bool PhaseSensor);
void TalonSRX_SetInverted(void* _this, int invertType);
bool TalonSRX_GetInverted(void* _this);
int TalonSRX_ConfigFactoryDefault(void* _this, int timeoutMs);
int TalonSRX_ConfigOpenloopRamp(void* _this, double secondsFromNeutralToFull, int timeoutMs);
int TalonSRX_ConfigClosedloopRamp(void* _this, double secondsFromNeutralToFull, int timeoutMs);
int TalonSRX_ConfigPeakOutputForward(void* _this, double percentOut, int timeoutMs);
int TalonSRX_ConfigPeakOutputReverse(void* _this, double percentOut, int timeoutMs);
int TalonSRX_ConfigNominalOutputForward(void* _this, double percentOut, int timeoutMs);
int TalonSRX_ConfigNominalOutputReverse(void* _this, double percentOut, int timeoutMs);
int TalonSRX_ConfigNeutralDeadband(void* _this, double percentDeadband, int timeoutMs);
int TalonSRX_ConfigVoltageCompSaturation(void* _this, double voltage, int timeoutMs);
int TalonSRX_ConfigVoltageMeasurementFilter(void* _this, int filterWindowSamples, int timeoutMs);
void TalonSRX_EnableVoltageCompensation(void* _this, bool enable);
bool TalonSRX_IsVoltageCompensationEnabled(void* _this);
double TalonSRX_GetBusVoltage(void* _this);
double TalonSRX_GetMotorOutputPercent(void* _this);
double TalonSRX_GetMotorOutputVoltage(void* _this);
double TalonSRX_GetTemperature(void* _this);
int TalonSRX_ConfigSelectedFeedbackCoefficient(void* _this, double coefficient, int pidIdx, int timeoutMs);
int TalonSRX_ConfigSensorTerm(void* _this, int sensorTerm, int feedbackDevice);
double TalonSRX_GetSelectedSensorPosition(void* _this, int pidIdx);
double TalonSRX_GetSelectedSensorVelocity(void* _this, int pidIdx);
int TalonSRX_SetSelectedSensorPosition(void* _this, double sensorPos, int pidIdx, int timeoutMs);
int TalonSRX_SetControlFramePeriod(void* _this, int frame, int periodMs);
void TalonSRX_OverrideLimitSwitchesEnable(void* _this, bool enable);
int TalonSRX_ConfigForwardSoftLimitThreshold(void* _this, double forwardSensorLimit, int timeoutMs);
int TalonSRX_ConfigReverseSoftLimitThreshold(void* _this, double reverseSensorLimit, int timeoutMs);
int TalonSRX_ConfigForwardSoftLimitEnable(void* _this, bool enable, int timeoutMs);
int TalonSRX_ConfigReverseSoftLimitEnable(void* _this, bool enable, int timeoutMs);
void TalonSRX_OverrideSoftLimitsEnable(void* _this, bool enable);
int TalonSRX_Config_kP(void* _this, int slotIdx, double value, int timeoutMs);
int TalonSRX_Config_kI(void* _this, int slotIdx, double value, int timeoutMs);
int TalonSRX_Config_kD(void* _this, int slotIdx, double value, int timeoutMs);
int TalonSRX_Config_kF(void* _this, int slotIdx, double value, int timeoutMs);
int TalonSRX_Config_IntegralZone(void* _this, int slotIdx, double value, int timeoutMs);
int TalonSRX_ConfigAllowableClosedloopError(void* _this, int slotIdx, double allowableCloseLoopError, int timeoutMs);
int TalonSRX_ConfigMaxIntegralAccumulator(void* _this, int slotIdx, double iaccum, int timeoutMs);
int TalonSRX_ConfigClosedLoopPeakOutput(void* _this, int slotIdx, double percentOut, int timeoutMs);
int TalonSRX_ConfigClosedLoopPeriod(void* _this, int slotIdx, int loopTimeMs, int timeoutMs);
int TalonSRX_ConfigAuxPIDPolarity(void* _this, bool invert, int timeoutMs);
int TalonSRX_SetIntegralAccumulator(void* _this, double iaccum, int pidIdx, int timeoutMs);
double TalonSRX_GetClosedLoopError(void* _this, int pidIdx);
double TalonSRX_GetIntegralAccumulator(void* _this, int pidIdx);
double TalonSRX_GetErrorDerivative(void* _this, int pidIdx);
int TalonSRX_SelectProfileSlot(void* _this, int slotIdx, int pidIdx);
double TalonSRX_GetClosedLoopTarget(void* _this, int pidIdx);
double TalonSRX_GetActiveTrajectoryPosition(void* _this, int pidIdx);
double TalonSRX_GetActiveTrajectoryArbFeedFwd(void* _this, int pidIdx);
int TalonSRX_ConfigMotionCruiseVelocity(void* _this, double sensorUnitsPer100ms, int timeoutMs);
int TalonSRX_ConfigMotionAcceleration(void* _this, double sensorUnitsPer100msPerSec, int timeoutMs);
int TalonSRX_ConfigMotionSCurveStrength(void* _this, int curveStrength, int timeoutMs);
int TalonSRX_ClearMotionProfileTrajectories(void* _this);
int TalonSRX_GetMotionProfileTopLevelBufferCount(void* _this);
bool TalonSRX_IsMotionProfileFinished(void* _this);
bool TalonSRX_IsMotionProfileTopLevelBufferFull(void* _this);
void TalonSRX_ProcessMotionProfileBuffer(void* _this);
int TalonSRX_ClearMotionProfileHasUnderrun(void* _this, int timeoutMs);
int TalonSRX_ChangeMotionControlFramePeriod(void* _this, int periodMs);
int TalonSRX_ConfigMotionProfileTrajectoryPeriod(void* _this, int baseTrajDurationMs, int timeoutMs);
int TalonSRX_ConfigMotionProfileTrajectoryInterpolationEnable(void* _this, bool enable, int timeoutMs);
int TalonSRX_ConfigFeedbackNotContinuous(void* _this, bool feedbackNotContinuous, int timeoutMs);
int TalonSRX_ConfigClearPositionOnLimitF(void* _this, bool clearPositionOnLimitF, int timeoutMs);
int TalonSRX_ConfigClearPositionOnLimitR(void* _this, bool clearPositionOnLimitR, int timeoutMs);
int TalonSRX_ConfigClearPositionOnQuadIdx(void* _this, bool clearPositionOnQuadIdx, int timeoutMs);
int TalonSRX_ConfigLimitSwitchDisableNeutralOnLOS(void* _this, bool limitSwitchDisableNeutralOnLOS, int timeoutMs);
int TalonSRX_ConfigSoftLimitDisableNeutralOnLOS(void* _this, bool softLimitDisableNeutralOnLOS, int timeoutMs);
int TalonSRX_ConfigPulseWidthPeriod_EdgesPerRot(void* _this, int pulseWidthPeriod_EdgesPerRot, int timeoutMs);
int TalonSRX_ConfigPulseWidthPeriod_FilterWindowSz(void* _this, int pulseWidthPeriod_FilterWindowSz, int timeoutMs);
int TalonSRX_GetLastError(void* _this);
int TalonSRX_GetFirmwareVersion(void* _this);
bool TalonSRX_HasResetOccurred(void* _this);
int TalonSRX_GetBaseID(void* _this);
int TalonSRX_GetControlMode(void* _this);
void TalonSRX_Follow(void* _this, void * masterToFollow);
void TalonSRX_ValueUpdated(void* _this);
void TalonSRX_Feed(void* _this);
void TalonSRX_SetExpiration(void* _this, double expirationTime);
bool TalonSRX_IsAlive(void* _this);
void TalonSRX_SetSafetyEnabled(void* _this, bool enabled);
bool TalonSRX_IsSafetyEnabled(void* _this);
double TalonSRX_GetOutputCurrent(void* _this);
double TalonSRX_GetStatorCurrent(void* _this);
double TalonSRX_GetSupplyCurrent(void* _this);
int TalonSRX_ConfigVelocityMeasurementPeriod(void* _this, int period, int timeoutMs);
int TalonSRX_ConfigVelocityMeasurementWindow(void* _this, int windowSize, int timeoutMs);
int TalonSRX_ConfigForwardLimitSwitchSource(void* _this, int limitSwitchSource, int normalOpenOrClose, int timeoutMs);
int TalonSRX_ConfigReverseLimitSwitchSource(void* _this, int limitSwitchSource, int normalOpenOrClose, int timeoutMs);
int TalonSRX_IsFwdLimitSwitchClosed(void* _this);
int TalonSRX_IsRevLimitSwitchClosed(void* _this);
void* TalonSRX_new(int deviceNumber);
void TalonSRX_SetWithTalonSRXControlMode(void* _this, int mode, double value);
void TalonSRX_SetWithTalonSRXControlModeAndDemands(void* _this, int mode, double demand0, int demand1Type, double demand1);
int TalonSRX_ConfigSelectedFeedbackSensor(void* _this, int feedbackDevice, int pidIdx, int timeoutMs);
int TalonSRX_ConfigPeakCurrentLimit(void* _this, int amps, int timeoutMs);
int TalonSRX_ConfigPeakCurrentDuration(void* _this, int milliseconds, int timeoutMs);
int TalonSRX_ConfigContinuousCurrentLimit(void* _this, int amps, int timeoutMs);
void TalonSRX_EnableCurrentLimit(void* _this, bool enable);
double TalonSRX_GetExpiration(void* _this);
void* TalonFX_ToSpeedController(void* _this);
void TalonFX_Set(void* _this, double value);
void TalonFX_SetVoltage(void* _this, double output);
double TalonFX_Get(void* _this);
void TalonFX_SetInvertedBool(void* _this, bool isInverted);
bool TalonFX_GetInvertedBool(void* _this);
void TalonFX_Disable(void* _this);
void TalonFX_StopMotor(void* _this);
void* TalonFX_ToIMotorController(void* _this);
void TalonFX_SetWithControlMode(void* _this, int mode, double value);
void TalonFX_SetWithControlModeAndDemands(void* _this, int mode, double demand0, int demand1Type, double demand1);
void TalonFX_NeutralOutput(void* _this);
void TalonFX_SetNeutralMode(void* _this, int neutralMode);
void TalonFX_SetSensorPhase(void* _this, bool PhaseSensor);
void TalonFX_SetInverted(void* _this, int invertType);
bool TalonFX_GetInverted(void* _this);
int TalonFX_ConfigFactoryDefault(void* _this, int timeoutMs);
int TalonFX_ConfigOpenloopRamp(void* _this, double secondsFromNeutralToFull, int timeoutMs);
int TalonFX_ConfigClosedloopRamp(void* _this, double secondsFromNeutralToFull, int timeoutMs);
int TalonFX_ConfigPeakOutputForward(void* _this, double percentOut, int timeoutMs);
int TalonFX_ConfigPeakOutputReverse(void* _this, double percentOut, int timeoutMs);
int TalonFX_ConfigNominalOutputForward(void* _this, double percentOut, int timeoutMs);
int TalonFX_ConfigNominalOutputReverse(void* _this, double percentOut, int timeoutMs);
int TalonFX_ConfigNeutralDeadband(void* _this, double percentDeadband, int timeoutMs);
int TalonFX_ConfigVoltageCompSaturation(void* _this, double voltage, int timeoutMs);
int TalonFX_ConfigVoltageMeasurementFilter(void* _this, int filterWindowSamples, int timeoutMs);
void TalonFX_EnableVoltageCompensation(void* _this, bool enable);
bool TalonFX_IsVoltageCompensationEnabled(void* _this);
double TalonFX_GetBusVoltage(void* _this);
double TalonFX_GetMotorOutputPercent(void* _this);
double TalonFX_GetMotorOutputVoltage(void* _this);
double TalonFX_GetTemperature(void* _this);
int TalonFX_ConfigSelectedFeedbackCoefficient(void* _this, double coefficient, int pidIdx, int timeoutMs);
int TalonFX_ConfigSensorTerm(void* _this, int sensorTerm, int feedbackDevice);
double TalonFX_GetSelectedSensorPosition(void* _this, int pidIdx);
double TalonFX_GetSelectedSensorVelocity(void* _this, int pidIdx);
int TalonFX_SetSelectedSensorPosition(void* _this, double sensorPos, int pidIdx, int timeoutMs);
int TalonFX_SetControlFramePeriod(void* _this, int frame, int periodMs);
void TalonFX_OverrideLimitSwitchesEnable(void* _this, bool enable);
int TalonFX_ConfigForwardSoftLimitThreshold(void* _this, double forwardSensorLimit, int timeoutMs);
int TalonFX_ConfigReverseSoftLimitThreshold(void* _this, double reverseSensorLimit, int timeoutMs);
int TalonFX_ConfigForwardSoftLimitEnable(void* _this, bool enable, int timeoutMs);
int TalonFX_ConfigReverseSoftLimitEnable(void* _this, bool enable, int timeoutMs);
void TalonFX_OverrideSoftLimitsEnable(void* _this, bool enable);
int TalonFX_Config_kP(void* _this, int slotIdx, double value, int timeoutMs);
int TalonFX_Config_kI(void* _this, int slotIdx, double value, int timeoutMs);
int TalonFX_Config_kD(void* _this, int slotIdx, double value, int timeoutMs);
int TalonFX_Config_kF(void* _this, int slotIdx, double value, int timeoutMs);
int TalonFX_Config_IntegralZone(void* _this, int slotIdx, double value, int timeoutMs);
int TalonFX_ConfigAllowableClosedloopError(void* _this, int slotIdx, double allowableCloseLoopError, int timeoutMs);
int TalonFX_ConfigMaxIntegralAccumulator(void* _this, int slotIdx, double iaccum, int timeoutMs);
int TalonFX_ConfigClosedLoopPeakOutput(void* _this, int slotIdx, double percentOut, int timeoutMs);
int TalonFX_ConfigClosedLoopPeriod(void* _this, int slotIdx, int loopTimeMs, int timeoutMs);
int TalonFX_ConfigAuxPIDPolarity(void* _this, bool invert, int timeoutMs);
int TalonFX_SetIntegralAccumulator(void* _this, double iaccum, int pidIdx, int timeoutMs);
double TalonFX_GetClosedLoopError(void* _this, int pidIdx);
double TalonFX_GetIntegralAccumulator(void* _this, int pidIdx);
double TalonFX_GetErrorDerivative(void* _this, int pidIdx);
int TalonFX_SelectProfileSlot(void* _this, int slotIdx, int pidIdx);
double TalonFX_GetClosedLoopTarget(void* _this, int pidIdx);
double TalonFX_GetActiveTrajectoryPosition(void* _this, int pidIdx);
double TalonFX_GetActiveTrajectoryArbFeedFwd(void* _this, int pidIdx);
int TalonFX_ConfigMotionCruiseVelocity(void* _this, double sensorUnitsPer100ms, int timeoutMs);
int TalonFX_ConfigMotionAcceleration(void* _this, double sensorUnitsPer100msPerSec, int timeoutMs);
int TalonFX_ConfigMotionSCurveStrength(void* _this, int curveStrength, int timeoutMs);
int TalonFX_ClearMotionProfileTrajectories(void* _this);
int TalonFX_GetMotionProfileTopLevelBufferCount(void* _this);
bool TalonFX_IsMotionProfileFinished(void* _this);
bool TalonFX_IsMotionProfileTopLevelBufferFull(void* _this);
void TalonFX_ProcessMotionProfileBuffer(void* _this);
int TalonFX_ClearMotionProfileHasUnderrun(void* _this, int timeoutMs);
int TalonFX_ChangeMotionControlFramePeriod(void* _this, int periodMs);
int TalonFX_ConfigMotionProfileTrajectoryPeriod(void* _this, int baseTrajDurationMs, int timeoutMs);
int TalonFX_ConfigMotionProfileTrajectoryInterpolationEnable(void* _this, bool enable, int timeoutMs);
int TalonFX_ConfigFeedbackNotContinuous(void* _this, bool feedbackNotContinuous, int timeoutMs);
int TalonFX_ConfigClearPositionOnLimitF(void* _this, bool clearPositionOnLimitF, int timeoutMs);
int TalonFX_ConfigClearPositionOnLimitR(void* _this, bool clearPositionOnLimitR, int timeoutMs);
int TalonFX_ConfigClearPositionOnQuadIdx(void* _this, bool clearPositionOnQuadIdx, int timeoutMs);
int TalonFX_ConfigLimitSwitchDisableNeutralOnLOS(void* _this, bool limitSwitchDisableNeutralOnLOS, int timeoutMs);
int TalonFX_ConfigSoftLimitDisableNeutralOnLOS(void* _this, bool softLimitDisableNeutralOnLOS, int timeoutMs);
int TalonFX_ConfigPulseWidthPeriod_EdgesPerRot(void* _this, int pulseWidthPeriod_EdgesPerRot, int timeoutMs);
int TalonFX_ConfigPulseWidthPeriod_FilterWindowSz(void* _this, int pulseWidthPeriod_FilterWindowSz, int timeoutMs);
int TalonFX_GetLastError(void* _this);
int TalonFX_GetFirmwareVersion(void* _this);
bool TalonFX_HasResetOccurred(void* _this);
int TalonFX_GetBaseID(void* _this);
int TalonFX_GetControlMode(void* _this);
void TalonFX_Follow(void* _this, void * masterToFollow);
void TalonFX_ValueUpdated(void* _this);
void TalonFX_Feed(void* _this);
void TalonFX_SetExpiration(void* _this, double expirationTime);
bool TalonFX_IsAlive(void* _this);
void TalonFX_SetSafetyEnabled(void* _this, bool enabled);
bool TalonFX_IsSafetyEnabled(void* _this);
double TalonFX_GetOutputCurrent(void* _this);
double TalonFX_GetStatorCurrent(void* _this);
double TalonFX_GetSupplyCurrent(void* _this);
int TalonFX_ConfigVelocityMeasurementPeriod(void* _this, int period, int timeoutMs);
int TalonFX_ConfigVelocityMeasurementWindow(void* _this, int windowSize, int timeoutMs);
int TalonFX_ConfigForwardLimitSwitchSource(void* _this, int limitSwitchSource, int normalOpenOrClose, int timeoutMs);
int TalonFX_ConfigReverseLimitSwitchSource(void* _this, int limitSwitchSource, int normalOpenOrClose, int timeoutMs);
int TalonFX_IsFwdLimitSwitchClosed(void* _this);
int TalonFX_IsRevLimitSwitchClosed(void* _this);
void* TalonFX_new(int deviceNumber);
void TalonFX_SetWithTalonFXControlMode(void* _this, int mode, double value);
void TalonFX_SetWithTalonFXControlModeAndDemands(void* _this, int mode, double demand0, int demand1Type, double demand1);
void TalonFX_SetInvertedTalonFX(void* _this, int invertType);
void TalonFX_ConfigStatorCurrentLimit(void* _this, bool enable, double currentLimit);
void TalonFX_ConfigIntegratedSensorOffset(void* _this, double offsetDegrees, int timeoutMs);
int TalonFX_ConfigSelectedFeedbackSensor(void* _this, int feedbackDevice, int pidIdx, int timeoutMs);
double TalonFX_GetExpiration(void* _this);
void* CANSparkMax_new(int deviceID, int type);
void CANSparkMax_SetIdleMode(void* _this, int type);
void CANSparkMax_RestoreFactoryDefaults(void* _this);
void CANSparkMax_Set(void* _this, double speed);
void CANSparkMax_SetVoltage(void* _this, double output);
double CANSparkMax_Get(void* _this);
void CANSparkMax_SetInverted(void* _this, bool isInverted);
bool CANSparkMax_GetInverted(void* _this);
void CANSparkMax_Disable(void* _this);
void CANSparkMax_StopMotor(void* _this);
void CANSparkMax_Follow(void* _this, void * leader, bool invert);
void * CANSparkMax_GetEncoder(void* _this, int countsPerRev);
double SparkMaxRelativeEncoder_GetPosition(void* _this);
double SparkMaxRelativeEncoder_GetVelocity(void* _this);
void SparkMaxRelativeEncoder_SetPositionConversionFactor(void* _this, double factor);
void* DifferentialDrive_new(void * leftMotor, void * rightMotor);
void DifferentialDrive_ArcadeDrive(void* _this, double xSpeed, double zRotation, bool squareInputs);
void DifferentialDrive_TankDrive(void* _this, double leftSpeed, double rightSpeed, bool squareInputs);
void CurvatureDriveIK(double xSpeed, double zRotation, bool allowTurnInPlace, double * leftSpeed, double * rightSpeed);
void* Solenoid_new(int moduleType, int channel);
void Solenoid_Set(void* _this, bool on);
bool Solenoid_Get(void* _this);
void Solenoid_Toggle(void* _this);
int Solenoid_GetChannel(void* _this);
bool Solenoid_IsDisabled(void* _this);
void* DoubleSolenoid_new(int moduleType, int forwardChannel, int reverseChannel);
void DoubleSolenoid_Set(void* _this, int value);
int DoubleSolenoid_Get(void* _this);
void DoubleSolenoid_Toggle(void* _this);
int DoubleSolenoid_GetFwdChannel(void* _this);
int DoubleSolenoid_GetRevChannel(void* _this);
bool DoubleSolenoid_IsFwdSolenoidDisabled(void* _this);
bool DoubleSolenoid_IsRevSolenoidDisabled(void* _this);
void StartAutomaticCapture();
void* Timer_new();
double Timer_Get(void* _this);
void Timer_Reset(void* _this);
void Timer_Start(void* _this);
void Timer_Stop(void* _this);
bool Timer_HasElapsed(void* _this, double period);
bool Timer_AdvanceIfElapsed(void* _this, double period);
double GetFPGATimestamp();
double GetMatchTime();
void* AHRS_new(int value);
float AHRS_GetPitch(void* _this);
float AHRS_GetRoll(void* _this);
float AHRS_GetYaw(void* _this);
float AHRS_GetCompassHeading(void* _this);
void AHRS_ZeroYaw(void* _this);
bool AHRS_IsCalibrating(void* _this);
bool AHRS_IsConnected(void* _this);
double AHRS_GetByteCount(void* _this);
double AHRS_GetUpdateCount(void* _this);
float AHRS_GetWorldLinearAccelX(void* _this);
float AHRS_GetWorldLinearAccelY(void* _this);
float AHRS_GetWorldLinearAccelZ(void* _this);
bool AHRS_IsMoving(void* _this);
bool AHRS_IsRotating(void* _this);
float AHRS_GetBarometricPressure(void* _this);
float AHRS_GetAltitude(void* _this);
bool AHRS_IsAltitudeValid(void* _this);
bool AHRS_GetFusedHeading(void* _this);
bool AHRS_IsMagneticDisturbance(void* _this);
bool AHRS_IsMagnetometerCalibrated(void* _this);
float AHRS_GetQuaternionW(void* _this);
float AHRS_GetQuaternionX(void* _this);
float AHRS_GetQuaternionY(void* _this);
float AHRS_GetQuaternionZ(void* _this);
void AHRS_ResetDisplacement(void* _this);
void AHRS_UpdateDisplacement(void* _this, float accel_x_g, float accel_y_g, int update_rate_hz, bool is_moving);
float AHRS_GetVelocityX(void* _this);
float AHRS_GetVelocityY(void* _this);
float AHRS_GetVelocityZ(void* _this);
float AHRS_GetDisplacementX(void* _this);
float AHRS_GetDisplacementY(void* _this);
float AHRS_GetDisplacementZ(void* _this);
double AHRS_GetAngle(void* _this);
double AHRS_GetRate(void* _this);
void AHRS_SetAngleAdjustment(void* _this, double angle);
double AHRS_GetAngleAdjustment(void* _this);
void AHRS_Reset(void* _this);
float AHRS_GetRawGyroX(void* _this);
float AHRS_GetRawGyroY(void* _this);
float AHRS_GetRawAccelX(void* _this);
float AHRS_GetRawAccelY(void* _this);
float AHRS_GetRawAccelZ(void* _this);
float AHRS_GetRawMagX(void* _this);
float AHRS_GetRawMagY(void* _this);
float AHRS_GetRawMagZ(void* _this);
float AHRS_GetPressure(void* _this);
float AHRS_GetTempC(void* _this);
int AHRS_GetActualUpdateRate(void* _this);
void AHRS_EnableLogging(void* _this, bool enable);
void AHRS_EnableBoardlevelYawReset(void* _this, bool enable);
bool AHRS_IsBoardlevelYawResetEnabled(void* _this);
int AHRS_GetGyroFullScaleRangeDPS(void* _this);
int AHRS_GetAccelFullScaleRangeG(void* _this);
void AHRS_Calibrate(void* _this);
bool RobotBase_IsEnabled(void* _this);
bool RobotBase_IsDisabled(void* _this);
bool RobotBase_IsAutonomous(void* _this);
bool RobotBase_IsAutonomousEnabled(void* _this);
bool RobotBase_IsTeleop(void* _this);
bool RobotBase_IsTeleopEnabled(void* _this);
bool RobotBase_IsTest(void* _this);
int GetRuntimeType();
bool IsReal();
bool IsSimulation();
bool ContainsKey(const char * key);
void SetPersistent(const char * key);
void ClearPersistent(const char * key);
bool IsPersistent(const char * key);
void PutBoolean(const char * keyName, bool value);
bool GetBoolean(const char * keyName, bool defaultValue);
void PutNumber(const char * keyName, double value);
double GetNumber(const char * keyName, double defaultValue);
void PutString(const char * keyName, const char * value);
const char * GetString(const char * keyName, const char * defaultValue);
void PutBooleanArray(const char * keyName, int * value, size_t size);
size_t GetBooleanArraySize(const char * keyName);
int * GetBooleanArray(const char * keyName, int * defaultValue, size_t defaultSize);
void PutNumberArray(const char * keyName, double * value, size_t size);
size_t GetNumberArraySize(const char * keyName);
double * GetNumberArray(const char * keyName, double * defaultValue, size_t defaultSize);
void PutStringArray(const char * keyName, const char ** value, size_t size);
void PutIntChooser(const char * key, void * data);
void PutField(void * field);
void* SendableChooser_new();
void SendableChooser_AddOption(void* _this, const char * name, int object);
int SendableChooser_GetSelected(void* _this);
void* Field2d_new();
void Field2d_SetRobotPose(void* _this, double x, double y, double rotation);
const char* GetDeployDirectory();
void* PhotonCamera_new(const char * cameraName);
void * PhotonCamera_GetLatestResult(void* _this);
void PhotonCamera_SetDriverMode(void* _this, bool driverMode);
bool PhotonCamera_GetDriverMode(void* _this);
void PhotonCamera_TakeInputSnapshot(void* _this);
void PhotonCamera_TakeOutputSnapshot(void* _this);
void PhotonCamera_SetPipelineIndex(void* _this, int index);
int PhotonCamera_GetPipelineIndex(void* _this);
void * PhotonPipelineResult_GetBestTarget(void* _this);
bool PhotonPipelineResult_HasTargets(void* _this);
typedef struct { double x, y, z; double rotx, roty, rotz; } Pose;
double PhotonTrackedTarget_GetYaw(void* _this);
double PhotonTrackedTarget_GetPitch(void* _this);
double PhotonTrackedTarget_GetArea(void* _this);
double PhotonTrackedTarget_GetSkew(void* _this);
int PhotonTrackedTarget_GetFiducialId(void* _this);
double PhotonTrackedTarget_GetPoseAmbiguity(void* _this);
Pose * PhotonTrackedTarget_GetBestCameraToTarget(void* _this);
typedef struct { Pose pose; double timestamp; } PoseEstimate;
void* PhotonPoseEstimator_newFromEnum(int field, int poseStrategy, void * camera, double x, double y, double z, double rotx, double roty, double rotz);
void* PhotonPoseEstimator_newFromPath(const char * fieldPath, int poseStrategy, void * camera, double x, double y, double z, double rotx, double roty, double rotz);
int PhotonPoseEstimator_GetPoseStrategy(void* _this);
void PhotonPoseEstimator_SetPoseStrategy(void* _this, int poseStrategy);
void PhotonPoseEstimator_SetReferencePose(void* _this, double x, double y, double z, double rotx, double roty, double rotz);
void PhotonPoseEstimator_SetLastPose(void* _this, double x, double y, double z, double rotx, double roty, double rotz);
PoseEstimate * PhotonPoseEstimator_Update(void* _this);
void liberate(void* ptr);
]]

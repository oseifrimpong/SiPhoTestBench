% � Copyright 2013-2015 Shon Schmidt, Jonas Flueckiger, and WenXuan Wu
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published by
% the Free Software Foundation, version 3 of the License.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU Lesser General Public License for more details.
% 
% You should have received a copy of the GNU Lesser General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.

function defaultStruct = applicationDefaults()
% ds = default defaultAppSettings struct

%% Instruments Defaults
% the strings should be the name of the instrumnet class
ds.instrDefaults.laser = {Laser, Laser_Agilent8164A, Laser_Agilent_FastIL,...
    Laser_Santur1550, Laser_SRS_LDC501, Laser_Tunable81689A};
ds.instrDefaults.detector = {Detector, Detector_Agilent8164A,...
    Detector_AgilentN7700A, Detector_Agilent8163A_81531A};
ds.instrDefaults.opticalStage = {OpticalStage, CorvusEco, NanoPZ,...
    ThorlabsBBD203, NewFocus8742PicoMotor};
% ds.instrDefaults.fluidicStage = {FluidicStage, VelmexXSlide};
% ds.instrDefaults.pump = {Pump, Nexus3000, Masterflex};
ds.instrDefaults.thermalControl = {TEC, TECNewport3040, TEC_SRS_LDC501};
ds.instrDefaults.camera = {Camera, LumeneraLw575C};
ds.instrDefaults.powerSupply = {PowerSupply, Power_Supply_AgilentE3634A};

%% Default Application Settings
%script settings are written directly to the AppSettings.
ds.AppSettings.MappingParams=struct(...
    'Detector', 1,...
    'Wvl', 1550,...
    'Power', 0, ...
    'LowSSE',0, ...
    'DataPoints', 0,...
    'PowerRange', -30,...
    'AvgTime', 500e-6,...  %convert to s %smallest number is 100um; [s]
    'width_x',200,... %in um
    'width_y',800,... %in um
    'step',5,...      %in um
    'Velocity',5,...   %in mm/s
    'Acceleration',500); %in mm/s/s
%coarse align settings
% ds.AppSettings.CAParams=struct(...
%     'Detector', 1,...
%     'Wvl', 1550,...
%     'Power', 0, ...
%     'LowSSE',0, ...e
%     'DataPoints', 0,...
%     'PowerRange', -30,...
%     'AvgTime', 500e-6,...  %convert to s %smallest number is 100um; [s]
%     'width_x',200,... %in um
%     'width_y',800,... %in um
%     'step_x',5,...      %in um
%     'step_y',2,...  %in um
%     'line', 60,... %in um coarse align line length
%     'Threshold',-40,... %in dBm
%     'Velocity',5,...   %in mm/s
%     'Acceleration',500); %in mm/s/s
%fine algin settings
ds.AppSettings.FAParams=struct(...
    'Detector', 1,...
    'AltDetector', 2, ...  %seondary detector to fine align to; in case Detector 0 doesn't work
    'Wvl', 1550,...
    'Power', 0, ...
    'LowSSE',0, ...
    'DataPoints', 0,...
    'PowerRange', -30,...
    'AvgTime', 10e-3,...  %convert to s %smallest number is 100um; [s]
    'WindowSize', 70,... % in um window size 
    'step_x', 3,... %in um
    'step_y', 3,... %in um
    'Threshold',-50,... %in dBm: minium power to be GC.
    'Velocity',5,...   %in mm/s
    'Acceleration',500); %in mm/s/s

%sweep settgins
ds.AppSettings.SweepParams=struct(...
    'SweepSpeed', 5,... %1=slow ... 5=fast (sometimes 4 depends on module)
    'NumberOfScans', 0,... %0=1 scan ... 2=3 scans
    'PowerLevel', 0,... %(in dB assuming that instr.laser.Param.PowerUnit=0)
    'LowSSE', 0,... % 0=no, 1=low-noise scan
    'StepWvl', 0.001, ... % step in [nm]
    'StartWvl', 1500, ...
    'StopWvl', 1550,...
    'StitchNum',0,... % stitch number for force stitching. 0= no stitching
    'Clipping', 1,...  % 0=no, 1=yes
    'ClipLimit', -200,...
    'InitRange', -20,...
    'RangeDecrement', 30); 
    
    

ds.AppSettings.TEC=struct(...
    'defaultTemp', 25,...% in degrees C
    'Autotune', 1, ... % 1: PID autotune; 0: uses P,I,D params manually
    'P', -0.64,... % in A/C
    'I', 0.15,... %/s
    'D', 1.85,... %s
    'SHH_A', 1.20836e-3,... %Steinhartt coeff
    'SHH_B', 2.41165e-4,... %
    'SHH_C', 1.48267e-7,... %
    'MaxCurrent', 1.4,... %in A
    'MaxVoltage', 8.5,... %in V
    'MaxResistance', 20e3,... %Ohms
    'MinResistance', 100,... %Ohms
    'MinTemperature', 10, ... %dgree
    'MaxTemperature', 10);

%% Test script defaults
%dryTest settings and wetTest settings
ds.AppSettings.dryTest=struct(...
    'Threshold', -30,...
    'SavePlots', 1,...
    'RateRealtime', 0,...
    'Iterations', 1);

%assay
% ds.AppSettings.AssayParams=struct(...
%     'SavePlots', false,...
%     'UseFastILEngine', false,...
%     'OptimizeSweepRange', false,...
%     'ZeroDetectors', false,...
%     'ZeroTSL', false,...
%     'TranslateRecipeTimeToSweeps', false,...
%     'WaitForTempStabilization', true,...
%     'WaitForTempTimeout_min', 5,...
%     'TempComparisonPrecision', 3,...
%     'TempComparisonTolerance', 0.005, ...
%     'TubeInID_um', 510,...
%     'TubeInLength_mm', 180,...,
%     'PrimeFluidicChannel', false,...
%     'PrimeFluidicChannelVelocity_uLpMin', 0,...
%     'SequenceReagentsManually', false,...
%     'StopPumpDuringScan', false,...
%     'RelaxPressureTime_sec', 0,...
% 	'ReversePumpTimeAtReagentChange', 0,...
%     'ScansUntilNextFineAlign', 10,...
%     'RecipeIterations', 1,...
%     'AssayIterations', 1,...
%     'DisableStageActiveFB', false);

ds.AppSettings.FinishTestSettings = struct(...
    'SendEmail', true, ...
    'MoveData', '');
%% fluidic tray
% 
% wells = [1:12]';
% 
% %PlateOptionsVals = {'96 Front 6 Back', '96 Front 96 Back', '6 Front 6 Back'};
% PlateOptionsVals = '96 Front 6 Back';
% 
% ds.AppSettings.fluidicTray = struct(...
%     'DefaultPlateConfiguration', PlateOptionsVals, ...
%     'PlateOptions', PlateOptionsVals, ... 
%     'WellOptions', {num2str(wells)}, ...
%     'DefaultWellNum', 1);

%% User Defaults --- Vince 2013

ds.AppSettings.infoParams = struct(...
    'School', 'UBC',...
    'Name','<Select User>',...
    'Email', '', ...
    'Task', '<Select Task>',...
    'CharacterizationTest', '-', ...
    'ChipArchitecture', '<Select Chip Architecture>',...
    'DieNumber', '-',...
    'FiberConfig', '<Select Fiber>');

ds.AppSettings.path = struct(...
    'root', 'C:\TestBench\',...  %not allowed to change root directory
    'userData', 'C:\TestBench\UserData\', ...
    'tempData', 'C:\TestBench\TempData\', ...
    'testData', 'Z:\', ...
    'testModeData', 'Z:\');

ds.AppSettings.LaserParams = struct(...
    'Laser', '<Select Laser>', ...
    'COMPort', '-', ...
    'StepSize', '-');

ds.AppSettings.DetectorParams = struct(...
    'Detector', '<Select Detectors>',...
    'COMPort', '-',...
    'Detectors', [],...
    'NumberOfChannels', 0,...
    'NumberOfDetectors', 0,...
    'NumberOfSlots', 0,...
    'BufferWvl', 100e-12,...
    'MaxPoints', 19800);

ds.AppSettings.OpticalStageParams = struct(...
    'OpticalStage', '<Select Optical Stage>',...
    'COMPort', '-',...
    'OpticalStageXStep', 127,...
    'OpticalStageYStep', 80,...
    'OpticalStageZStep', 10);

% ds.AppSettings.FluidicStageParams = struct(...
%     'FrontPlateConfig', 6, ...
%     'BackPlateConfig', 3, ...
%     'WellNum', 1, ...
%     'FluidicStage', '<Select Fluidic Stage>',...
%     'COMPort', '-');
% 
% ds.AppSettings.PumpParams = struct(...
%     'PumpSyringe', 'Select',...
%     'PumpVelocity', 10,...
%     'Pump', '<Select Fluidic Pump>',...
%     'COMPort', '-');

ds.AppSettings.TECParams = struct(...
    'DefaultTemp', 25, ...
    'TargetTemp', 37,...
    'TEC', '<Select Thermal Controller>',...
    'COMPort', '-', ...
    'SHH_A', 1.1318e-3, ... % SHH A, B, C are steinhart coefficients
    'SHH_B', 2.3358e-4, ...
    'SHH_C', 0.90965e-7, ...
    'PGain', -3.031296, ... % P, I, D are gain parameters obtain from autotune
    'IGain', 0.1723280, ...
    'DGain', 1.450723);

ds.AppSettings.PowerSupplyParams = struct(...
    'PowerSupply', '<Select Power Supply>',...
    'COMPort', '-');

ds.AppSettings.CameraParams = struct(...
    'Camera', '<Select Camera>',...
    'COMPort', '-', ...
    'CameraID', 0, ...
    'Resolution', [], ...
    'NumOfBands', 3);


%% GUI Defaults --- Vince 2013

% ----------- StartUp Panel ----------- %
ds.guiDefaults.userList = {...
    '<Select User>', ...
    '<New User>', ...
    '<Delete User>'};

ds.guiDefaults.benchList = {...
    '<Select Bench>', ...
    'UW biobench',...
    'UBC biobench'};

% ----------- Task Panel ----------- %
% ds.guiDefaults.taskList = {...
%     '<Select Task>', ...
%     'DryTest', ...
%     'WetTest', ...
%     'SaltSteps', ...
%     'TemperatureTest', ...
%     'BioAssay', ...
%     'ContinuePreviousBioAssay', ...
%     'VirtualTestMode',...
%     'TestBenchCharacterization'};

ds.guiDefaults.taskList = {...
    '<Select Task>', ...
    'DryTest', ...
    'TemperatureTest', ...
    'VirtualTestMode'};

%DEBUG: popup or needs to be in realation to root directory
ds.guiDefaults.chipFiles = dir('.\defaults\coordinateFiles\*.txt');
ds.guiDefaults.chipList = {...
    '<Select Chip Architecture>'};

ds.guiDefaults.fiberList = {...
    '<Select Fiber>', ...
    'UWTE#4 (4 port PM no axis rotation)', ...
    'S/N 070913-2 (6 port PM with axis rotation)', ...
    'UW1PM4', ...
    'UBC 8 port'};

% ----------- Instrument Panel ----------- %
% This panel's gui is generated by instr names and groups

% ----------- Mount Panel ----------- %


% ----------- Register Panel ----------- %


% ----------- Device Panel ----------- %


% ----------- Test Panel ----------- %

% ----------- Analyze Panel ----------- %



%% application default values (overriden by class and user defaults)

%% device defaults
ds.Device.RatingOptions = {'Unkown', 'Good', 'Fair', 'Poor', 'Unusable'};

defaultStruct = ds;

end

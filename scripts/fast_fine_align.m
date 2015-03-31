% © Copyright 2013-2015 Shon Schmidt, Jonas Flueckiger, and WenXuan Wu
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

function fast_fine_align(obj,parentStruct,panelIndex)
DEBUG=0;  %flag for debuggin plots cross hair pwr and displays variables to the terminal
waitbar_handle = waitbar(0.1,'Fine Align');

%pause timers (auto update detectors readings) to make sure 816x.mdd driver
%doesn't crash
active_timers = obj.manageTimer('pause');

opticalStage = obj.instr.opticalStage;

%Save the intial value : revert back at the end.
initial_vel = obj.instr.opticalStage.getParam('Velocity'); % for resetting to initial value
initial_accel = obj.instr.opticalStage.getParam('Acceleration'); % for resetting to initial value


%Prepare laser
obj.instr.laser.setWavelength(obj.AppSettings.FAParams.Wvl);
obj.instr.laser.setParam('PowerUnit',0);  %set to dBm
obj.instr.laser.setPower(obj.AppSettings.FAParams.Power);
%Switch laser on
obj.instr.laser.on();
% set laser indicator on
%set(obj.gui.(parentStruct)(panelIndex).laserUI.lasingIndicator, 'BackGroundColor', [0 1 0]);

opticalStage.setParam('Velocity', obj.AppSettings.FAParams.Velocity);
opticalStage.setParam('Acceleration', obj.AppSettings.FAParams.Acceleration);

%Prepare detector
obj.instr.detector.switchDetector(obj.AppSettings.FAParams.Detector);
powerUnit = obj.instr.detector.getPWMPowerUnit();
if powerUnit == 0  %Power unit needs to be in dB (option 1 is W)
    obj.instr.detector.setPWMPowerUnit(1);
end
obj.instr.detector.setPWMPowerUnit(0);
RangeMode = 1; %hard coded to auto range.
obj.instr.detector.setParam('PowerRange',obj.AppSettings.FAParams.PowerRange);
obj.instr.detector.setParam('RangeMode',RangeMode); %Set to auto range
obj.instr.detector.setParam('PWMWvl',obj.AppSettings.FAParams.Wvl);
obj.instr.detector.setParam('AveragingTime',obj.AppSettings.FAParams.AvgTime);

%get initial motor position
[init_x, init_y, ~] = opticalStage.getPosition();

%Read fine align parameters
delta_x = obj.AppSettings.FAParams.WindowSize; % window size for fine align; change to [mm]
%delta_y = obj.AppSettings.FAParams.delta_y; % window size for fine align
dx=obj.AppSettings.FAParams.step_x;  %step size is 1um
dy=obj.AppSettings.FAParams.step_y;
th = obj.AppSettings.FAParams.Threshold;

obj.msg('Start Fine Align');

waitbar(0.2, waitbar_handle);
num_of_iterations=40;
detectorNum = obj.AppSettings.FAParams.Detector;
abort_flag=0; %if set to 1 then abort button has been pressed


%Do cross hair fine aling: same as old on: now it is on GC for
%sure.
waitbar(0.3, waitbar_handle,'Fine Align: Crosshair method');
pwr = [];
obj.msg('Fine align: Crosshair method');
obj.instr.detector.setPWMPowerUnit(1);  %set to dBm
Nx=25;
Ny=25;
dy = 1;
dx = 1;
try
    opticalStage.move_y(-dy*ceil(Ny/2)); %go to start position
    [x, y, z] = opticalStage.getPosition();
catch ME
    rethrow(ME);
end
pause(0.2);
for ii=1:1:Ny  %fist line scan
    try
        pwr(ii) = obj.instr.detector.readPower(detectorNum);
    catch ME
        rethrow(ME);
    end
    opticalStage.move_y(dy);
    
    pause(0.05);
end

[pmax, pind] = max(pwr);
opticalStage.move_y(-(Ny-pind(1)+1)*dy);
if DEBUG
    disp(strcat('max power: ',num2str(pmax),' at index: ',num2str(pind)));
    figure; hold on
    plot(pwr);
    plot(pind,pmax, '-xr');
    hold off
end
pwr=[];

try
    opticalStage.move_x(-dx*ceil(Nx/2)); %go to start position
    [x, y, z] = opticalStage.getPosition();
catch ME
    rethrow(ME);
end
pause(0.1);
for ii=1:1:Nx %second line scan
    try
        pwr(ii) = obj.instr.detector.readPower(detectorNum);
    catch ME
        rethrow(ME);
    end
    opticalStage.move_x(dx);
    
    pause(0.05);
end
[pmax, pind] = max(pwr);
opticalStage.move_x(-(Nx-pind(1)+1)*dx);
if DEBUG
    disp(strcat('max power: ',num2str(pmax),' at index: ',num2str(pind)));
    figure;hold on
    plot(pwr);
    plot(pind,pmax, '-xr');
    hold off
end

obj.instr.laser.off();
%set(obj.gui.(parentStruct)(panelIndex).laserUI.lasingIndicator, 'BackGroundColor', [1 0 0]);

obj.instr.detector.setPWMPowerUnit(powerUnit);
obj.manageTimer('resume', active_timers);

delete(waitbar_handle);
end

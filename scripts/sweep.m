
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

function [wvlData, pwrData] = sweep(obj)
% Stiching functionality need to be added 
waitbar_handle = waitbar(0.1,'Sweeping', 'CreateCancelBtn', {@waitBarCancelButtonCallback, obj});

active_timers = obj.manageTimer('pause');

laserType = obj.instr.laser.Name;
stitchNum = obj.AppSettings.SweepParams.StitchNum; % get # of stitches specified by user through GUI
startWvl_init = obj.AppSettings.SweepParams.StartWvl;
stopWvl_init = obj.AppSettings.SweepParams.StopWvl;
stepWvl = obj.AppSettings.SweepParams.StepWvl;
speed = obj.AppSettings.SweepParams.SweepSpeed; 

if strcmp(laserType,'Santec TSL510')
    points = floor((stopWvl_init-startWvl_init)/stepWvl);
    obj.msg(['Number of data points: ', num2str(points)]);
    if points > obj.instr.detector.getProp('MaxDataPoints')
        obj.msg('Too many points required');
        obj.msg(['Limit is: ', num2str(obj.instr.detector.getProp('MaxDataPoints')), ' points']);
        obj.msg(['Requested: ', num2str(points), ' points']);
        obj.msg('Adjust step size'); 
        delete(waitbar_handle);
        return
    end
 
    %Stop any logging function; just in case:
    obj.instr.detector.pwm_func_stop(1); %probably not necessary
    
    %Calculate required detector averaging time based on speed and step:
    required_avg = stepWvl/speed; %time spend on one point  nm/s;
    %try to set it to detector
    try
        obj.instr.detector.setAvgTime(required_avg); 
    catch ME
        obj.msg(['required Averaging time not allowed']);
        obj.msg(['T_avg = ',num2str(required_avg),' out of range']); 
        delete(waitbar_handle);
        rethrow(ME)
    end
    obj.msg(['Detector Averaging time requested: ',num2str(required_avg)]);
    returned_avg = obj.instr.detector.getAvgTime(); %work around, can only set value out of list
    obj.instr.detector.setParam('AveragingTime', returned_avg); %work around to update class param
    
    required_speed = stepWvl/returned_avg; 
    
    obj.msg(['Detector Averaging time returned: ',num2str(returned_avg)]);
    obj.msg(['Laser speed requested: ',num2str(speed)]);
    obj.msg(['Laser speed adjusted: ',num2str(required_speed)]);
    if required_speed >100 || required_speed<1 %hard coded limits for Santec Laser should query what limit is
        obj.msg('Adjust sweep speed or step wvl; Averaging time for detector can only take certain values');
        delete(waitbar_handle);
        return
    end
  
    
elseif(strcmpi(laserType,'Virtual Laser'))
    points = floor((stopWvl_init-startWvl_init)/stepWvl);
    obj.msg(['Number of data points: ', num2str(points)]);
    if points > obj.instr.detector.getProp('MaxDataPoints')
        obj.msg('Too many points required');
        obj.msg(['Limit is: ', num2str(obj.instr.detector.getProp('MaxDataPoints')), ' points']);
        obj.msg(['Requested: ', num2str(points), ' points']);
        obj.msg('Adjust step size'); 
        delete(waitbar_handle);
        return
    end
 
    %Stop any logging function; just in case:
    obj.instr.detector.pwm_func_stop(1); %probably not necessary
    
    %Calculate required detector averaging time based on speed and step:
    required_avg = stepWvl/speed; %time spend on one point  nm/s;

    obj.msg(['Detector Averaging time requested: ',num2str(required_avg)]);
    returned_avg = required_avg;
    obj.instr.detector.setParam('AveragingTime', returned_avg); %work around to update class param
    
    required_speed = stepWvl/returned_avg; 
    
    obj.msg(['Detector Averaging time returned: ',num2str(returned_avg)]);
    obj.msg(['Laser speed requested: ',num2str(speed)]);
    obj.msg(['Laser speed adjusted: ',num2str(required_speed)]);
    if required_speed >100 || required_speed<1 %hard coded limits for Santec Laser should query what limit is
        obj.msg('Adjust sweep speed or step wvl; Averaging time for detector can only take certain levels');
        delete(waitbar_handle);
        return
    end
end



% set sweep properties valid for all segments
%Laser
obj.msg('Preparing Laser for sweep');
if(~strcmpi(laserType,'Virtual Laser'))

    %obj.instr.laser.setProp('NumberOfScans', obj.AppSettings.SweepParams.NumberOfScans);
    %obj.instr.laser.setProp('SweepSpeed', obj.AppSettings.SweepParams.SweepSpeed);
    obj.instr.laser.setSweepSpeed(required_speed);
    obj.instr.laser.setStartWvl( obj.AppSettings.SweepParams.StartWvl);
    obj.instr.laser.setStopWvl( obj.AppSettings.SweepParams.StopWvl);
    %obj.instr.laser.setParam('LowSSE', obj.AppSettings.SweepParams.LowSSE);
    obj.instr.laser.setParam('PowerUnit', 0 ); %set this to dB without being an option
    obj.instr.laser.setParam('PowerLevel', obj.AppSettings.SweepParams.PowerLevel);
    %Switch laser on
    obj.instr.laser.on();
    waitbar(0.2, waitbar_handle);
    %Detectors
    obj.msg('Preparing Detector for sweep');
    %obj.instr.detector.setParam('PWMWvl', 1310); %not sure if this is necessary,
    obj.instr.detector.setParam('RangeMode', 0); %not sure if necessary; make it manual.
    obj.instr.detector.setParam('PowerRange',obj.AppSettings.SweepParams.InitRange);
    obj.instr.detector.setProp('Clipping', obj.AppSettings.SweepParams.Clipping);
    obj.instr.detector.setProp('ClipLimit', obj.AppSettings.SweepParams.ClipLimit);
    %obj.instr.detector.setProp('RangeDecrement', obj.AppSettings.SweepParams.RangeDecrement);
end
waitbar(0.3, waitbar_handle);


% pre allocate memory for data arrays
pwrData = [];
wvlData = [];

% determine sweep range based on total wvl range and number of sweeps
if stitchNum == 0
    points = floor((stopWvl_init-startWvl_init)/stepWvl);
    if points > obj.instr.detector.getProp('MaxDataPoints')
        ex = MException('Sweep:TooManyPoint','Max points allowd exceeded');
        throw(ex);
    end
    startWvl = startWvl_init;
    stopWvl = stopWvl_init;
    wvlRange = 0;
elseif stitchNum > 0
    
    if strcmp(laserType,'Santec TSL510')
        obj.msg(['For laser ',laserType, 'stichting is not implemented']);
        delete(waitbar_handle);
        return
    end
    
    wvlRange = (stopWvl_init - startWvl_init)/(stitchNum+1);
    startWvl = startWvl_init;
    stopWvl = startWvl + wvlRange;
    points = floor((stopWvl-startWvl)/stepWvl);
    if points > obj.instr.detector.getProp('MaxDataPoints')
        ex = MException('Sweep:TooManyPoint','Max points allowd exceeded');
        throw(ex);
    end
end
% use for loop to set each section of the sweep range sequentially
for kk = 1:(stitchNum+1)
%    waitbar(0.2+kk/(stitchNum+1)/10*0.6, waitbar_handle);
    % set the wvl range of the section in the laser object

 if strcmp(laserType,'Santec TSL510')   
    obj.instr.laser.setStartWvl( obj.AppSettings.SweepParams.StartWvl);
    obj.instr.laser.setStopWvl( obj.AppSettings.SweepParams.StopWvl);
 else
     obj.instr.laser.setProp('StartWvl',startWvl);
    obj.instr.laser.setProp('StopWvl',stopWvl);    
 end
    
    % setupSweep uses the wvl range stored in the laser object
%    obj.msg('Setup Sweep.');
    [dataPoints, ~] = obj.instr.laser.setupSweep();
    current_length=length(pwrData);
    switch laserType
        case {'Agilent8164A Laser', 'Virtual Laser'}
            % ------ General Sweep Function ------
            obj.instr.detector.setupSweep(dataPoints);
            obj.msg('Sweeping.');
            selDet = obj.instr.detector.getProp('SelectedDetectors');
            obj.instr.laser.sweep();
%            obj.msg('Finish Sweep.');
            %read data from detectors.
            [pwr, wvl] = obj.instr.detector.getSweepData();
            
        case 'Agilent8164A Laser - FastIL'
            obj.msg('Start Sweep.');
            obj.instr.laser.sweep();
            obj.msg('Finish Sweep.');
            [pwr, wvl] = obj.instr.laser.getSweepData();
            
        case '8163A + 81689A TLS'
            % ------ Specific Sweep Function for Laser 81689A ------
            pwr = [];
            wvl = [];
            obj.instr.detector.setProp('ReadyForSweep', 1);
            obj.instr.laser.resetWvl();
            currentWvl = obj.instr.laser.Param.Wavelength;
            while currentWvl < obj.instr.laser.getProp('StopWvl')
                currentWvl = obj.instr.laser.sweepNextStep();
                wvl(end+1, 1:4) = currentWvl;
                pwr(end+1, :) = obj.instr.detector.readPowerAll();
                fprintf('\nwvl = %4.3f \tpwr = [%s]', currentWvl, num2str(pwr(end, :)));
            end
            
        case 'Santec TSL510'
            % Add code here
            obj.instr.detector.setProp('ReadyForSweep', 1);
            obj.msg('Santec TSL510 laser sweep init ...');
            %has to be done for each channel independently 
            selDet = obj.instr.detector.getProp('SelectedDetectors');
            for ii=1:obj.instr.detector.getProp('NumOfDetectors') 
                pwr(:,ii) = zeros(1, points);
                wvl(:,ii) = zeros(1, points);
                if selDet(ii)
                    %setup trigger for wavelength logging in detector
                    obj.instr.detector.setProp('DataPoints', points);
                    obj.instr.detector.setup_trigger(2,0, ii); %do it on detector 1
                    obj.instr.detector.pwm_func_stop(ii); %do it on detector 1
                    %arm the detector
                    EstimatedTimeout = obj.instr.detector.start_pwm_logging(ii);
                    obj.msg(['Estimated Timeout = ',num2str(EstimatedTimeout/1000),'[s]']);
                    obj.instr.laser.sweep();
                    obj.msg(['Laser sweep finish for detector ',num2str(ii)]);
                    obj.msg('Get data from detector');
                    tmp_wvl=startWvl:stepWvl:stopWvl;
                    wvl(:,ii)=tmp_wvl(1:end-1);
                    [LoggingStatus, pwr(:,ii)] = obj.instr.detector.get_pwm_logging(...
                        ii);
                    obj.msg(['Logging status (det ',num2str(ii),'): ',num2str(LoggingStatus)]);
                end
            end

            
            
    end
    pwrData(current_length+1:current_length+length(pwr), :) = pwr;
    wvlData(current_length+1:current_length+length(wvl), :) = wvl;
    
    % increment the wvl range
    startWvl = startWvl + wvlRange + stepWvl; % the +1 is to avoid overlap with endpoint of previous sweep
    stopWvl = startWvl + wvlRange;
end
if stitchNum == 0
    waitbar(0.5, waitbar_handle);
    waitbar(0.7, waitbar_handle);
    waitbar(0.9, waitbar_handle);
end

if ~strcmp(laserType,'Santec TSL510')
    
    wvlData = wvlData * 1e9; % Convert into nm and output
    pwrData(pwrData == -200) = -inf;
end
obj.instr.laser.off();
obj.instr.detector.setPWMPowerUnit(0);
obj.instr.detector.setParam('RangeMode', 1); %not sure if necessary; make it manual.

for ii=1:obj.instr.detector.getProp('NumOfDetectors')
    if selDet(ii)
        obj.instr.detector.setup_trigger(0,0, ii); %do it on detector 1
    end
end
obj.manageTimer('resume', active_timers);

waitbar(1, waitbar_handle);
delete(waitbar_handle);
end

function waitBarCancelButtonCallback(hObject, eventData, obj)
try
    if ~isempty(obj.assayCtl) && strcmpi(class(obj.assayCtl), 'AssayCtlClass')
    % if exist('obj.assayCtl', 'class') && strcmpi(class(obj.assayCtl), 'AssayCtlClass')
        % call a method in the testbench class to update the assay control state
        obj.assayCtl.ctlWinPopup()
    end
catch
    warndlg('Cancel button only works during assay', 'Warnning', 'modal');
end
end

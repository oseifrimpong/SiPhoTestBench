function map_gc(obj, parentStruct, panelIndex, heatMapHandle)

waitbar_handle = waitbar(0,'Mapping Grating Couplers');

% running_timers = timerfindall('Running', 'on');
% [numOfTimers n] = size(running_timers);
% for ii=1:numOfTimers
%    stop(running_timers(ii));
% end

active_timers = obj.manageTimer('pause');

%Save the intial value : revert back at the end.
initial_vel = obj.instr.opticalStage.getParam('Velocity'); % for resetting to initial value
initial_accel = obj.instr.opticalStage.getParam('Acceleration'); % for resetting to initial value

width_x = obj.AppSettings.MappingParams.width_x;
width_y = obj.AppSettings.MappingParams.width_y;
delta_x = obj.AppSettings.MappingParams.step;


obj.instr.opticalStage.setParam('Velocity', obj.AppSettings.MappingParams.Velocity);
obj.instr.opticalStage.setParam('Acceleration', obj.AppSettings.MappingParams.Acceleration);
obj.instr.opticalStage.set_trigger_config(1);

%Prepare detector
obj.instr.detector.switchDetector(obj.AppSettings.MappingParams.Detector);
obj.instr.detector.pwm_func_stop(obj.AppSettings.MappingParams.Detector);
powerUnit = obj.instr.detector.getPWMPowerUnit();
if powerUnit == 1
    obj.instr.detector.setPWMPowerUnit(0);
end
obj.instr.detector.setParam('RangeMode',0);
obj.instr.detector.setParam('AveragingTime',obj.AppSettings.MappingParams.AvgTime);
obj.instr.detector.setParam('PowerRange',obj.AppSettings.MappingParams.PowerRange);
obj.instr.detector.setParam('PWMWvl',obj.AppSettings.MappingParams.Wvl);
obj.instr.detector.setup_trigger(2,0, obj.AppSettings.MappingParams.Detector);



%Prepare laser
try
obj.instr.laser.setParam('Wavelength',obj.AppSettings.MappingParams.Wvl);
obj.instr.laser.setParam('PowerUnit',0);  %this won't probably work yet.
obj.instr.laser.setParam('PowerLevel',obj.AppSettings.MappingParams.Power);
catch ME
    rethrow(ME); 
end
%obj.instr.laser.setParam('LowSSE',obj.AppSettings.MappingParams.LowSSE);
% for n7744 detectors
if strcmp(obj.instr.detector.Name, 'Agilent Detector N7744A')
    % set the laser trigger to pass-thru
    disp('Setting up trigger for Agilent Detector N7744A.')
    obj.instr.laser.setTriggerPassThru(); % will print debug to console
end
if strcmp(obj.instr.laser.Name, 'Santec TSL510')
    disp('Switching Laser Trigger off (pass through)')
    obj.instr.laser.setTriggerPassThru(); % will print debug to console    
end
%Switch laser on
obj.instr.laser.on();
% set laser indicator on
%set(obj.gui.(parentStruct)(panelIndex).laserUI.lasingIndicator, 'BackGroundColor', [0 1 0]);

%Define scan window:
scan_line_length = width_y - 2*obj.instr.opticalStage.getProp('Overshoot');
%this calculation is for debug purposes
obj.AppSettings.MappingParams.DataPoints = ...
    ceil(scan_line_length/1000/obj.AppSettings.MappingParams.Velocity/obj.AppSettings.MappingParams.AvgTime);
if obj.AppSettings.MappingParams.DataPoints<10
    err = MException(strcat('MappGC:DataPoints','Not enough data points for scan (<)'));
    %Set the detector back to orig state
    obj.instr.detector.setup_trigger(0,0, obj.AppSettings.MappingParams.Detector); %Disable trigger
    obj.instr.detector.setParam('RangeMode',1);  %set to auto range
    obj.instr.opticalStage.set_trigger_config(0);
    obj.manageTimer('resume', active_timers);
    throw(err);
end
obj.instr.detector.setProp('DataPoints', obj.AppSettings.MappingParams.DataPoints);
num_scans = ceil(width_x/delta_x);
%Init output vector
%pwr = zeros(1,obj.AppSettings.MappingParams.DataPoints);
pwr = []; 

%Get init position
[init_x, init_y, init_z] = obj.instr.opticalStage.getPosition();
%position_str = strcat(['Init motor pos: ',num2str(init_x),' y= ',num2str(init_y),' z= ',num2str(init_z)]);
%disp(position_str);
obj.instr.opticalStage.move_x(1*width_x/2);
obj.instr.opticalStage.move_y(-1*width_y/2);

%DEBUG:
%disp(['Data points: ' num2str(obj.instr.detector.getProp('DataPoints'))]);
[cur_x, cur_y, cur_z] = obj.instr.opticalStage.getPosition();
%disp(['start motor pos: x=' num2str(cur_x) ' y= ' num2str(cur_y) ' z= ' num2str(cur_z)]);
left_trigger = cur_y + obj.instr.opticalStage.getProp('Overshoot');
%disp(['left trigger: ' num2str(left_trigger)]);
right_trigger = cur_y + obj.instr.opticalStage.getProp('Overshoot') + scan_line_length;
%disp(['right trigger: ' num2str(right_trigger)]);


current_pos_x = 0;
while current_pos_x <= width_x
    %check Abort button
    if (get(obj.gui.(parentStruct)(panelIndex).alignUI.mapGC_abort_button, 'UserData'))
        obj.msg('Abort mapping...');
        break;  %just break the loop and then move to init position and return
    end
    
    pause(0.01); % Try to fix the "logging still" active stuff - Vince
    %Arm the detector trigger
    EstimatedTimeout = obj.instr.detector.start_pwm_logging(obj.AppSettings.MappingParams.Detector);
    try
        obj.instr.opticalStage.triggered_move('right', width_y,left_trigger);
    catch ME
        rethrow(ME)
    end
    
    try
        [LoggingStatus, pwr(end+1,:)] = obj.instr.detector.get_pwm_logging(obj.AppSettings.MappingParams.Detector);
    catch ME
        error_message=cellstr(ME.message);
        error_val=length(error_message);
        if error_val
            for kk=1:error_val
                obj.msg(['     ' error_message{kk}]);
            end
        end
    end
    
    current_pos_x = current_pos_x + delta_x;
    percent_finished = current_pos_x/width_x;
    waitbar(percent_finished, waitbar_handle);
    %move back and down
    obj.instr.opticalStage.move_y(-width_y);
    obj.instr.opticalStage.move_x(-delta_x);
end

    if (get(obj.gui.(parentStruct)(panelIndex).alignUI.mapGC_abort_button, 'UserData'))
        obj.msg('Abort mapping: move back to original position');
        [cur_x, cur_y, cur_z] = obj.instr.opticalStage.getPosition();
        obj.instr.opticalStage.move_x(init_x-cur_x); 
        obj.instr.opticalStage.move_y(init_y-cur_y);
        
        obj.instr.detector.setup_trigger(0,0, obj.AppSettings.MappingParams.Detector); %Disable trigger
        obj.instr.detector.setParam('RangeMode',1);  %set to auto range
        %Active timers again
        obj.manageTimer('resume', active_timers);
        return;
    end


%[cur_x, cur_y, cur_z] = obj.instr.opticalStage.getPosition();
%%disp(['motor pos after back: ' num2str(cur_x) ' y= ' num2str(cur_y) ' z= ' num2str(cur_z)]);
obj.instr.opticalStage.move_x(1*width_x/2); %this needs to be changed as well to paramters.
obj.instr.opticalStage.move_y(1*width_y/2);
[cur_x, cur_y, cur_z] = obj.instr.opticalStage.getPosition();
%disp(['End motor pos: ' num2str(cur_x) ' y= ' num2str(cur_y) ' z= ' num2str(cur_z)]);


try
    obj.instr.detector.pwm_func_stop(obj.AppSettings.MappingParams.Detector);
catch ME
    error_message=cellstr(ME.message);
    error_val=length(error_message);
    if error_val
        for kk=1:error_val
            obj.msg(['     ' error_message{kk}]);
        end
    end
end

%Info of which bench is used woudl be stored here. Maybe how it is plotted
%needs to be adjusted based on where the stage is. 
%obj.AppSettings.infoParams.School = 'UBC';


%plot flipped in axes 1
cla(heatMapHandle,'reset');
axes(heatMapHandle);
set(heatMapHandle,'DataAspectRatio',[1 1 1]);
[m, n]=size(pwr);
surface([0:m-1]*delta_x,obj.AppSettings.MappingParams.AvgTime*1e3*obj.AppSettings.MappingParams.Velocity*[0:n-1],pwr');
set(heatMapHandle,'XDir','reverse');
%fliplr mirrors the matrix vertically becuase the transpose doesn't
%just rotes the matrix but also flips it.
xlabel('x [um]');
ylabel('y [um]');
shading interp;
delete(waitbar_handle);

%to plot heat map figure separately
% temp_fig=figure;
% [m, n]=size(pwr);
% temp_surf=surface([0:m-1]*delta_x,obj.AppSettings.MappingParams.AvgTime*1e3*obj.AppSettings.MappingParams.Velocity*[0:n-1],pwr');
% set(gca,'XDir','reverse');
% set(gca,'DataAspectRatio',[1 1 1]);
% xlabel('x [um]');
% ylabel('y [um]');
% shading interp;

% cla(heatMapHandle,'reset');
% axes(heatMapHandle)
% set(heatMapHandle,'DataAspectRatio',[1 1 1]);
% [m, n]=size(pwr);
% surface(obj.AppSettings.MappingParams.AvgTime*1e3*obj.AppSettings.MappingParams.Velocity*(0:n-1), delta_x*(0:m-1), pwr);
% y_size = obj.AppSettings.MappingParams.AvgTime*1e3*obj.AppSettings.MappingParams.Velocity*n;
% x_size = m*delta_x;
% xlabel('y [um]');
% ylabel('x [um]');
% shading interp;
% delete(waitbar_handle);


obj.instr.detector.setup_trigger(0,0, obj.AppSettings.MappingParams.Detector); %Disable trigger
obj.instr.detector.setParam('RangeMode',1);  %set to auto range
obj.instr.opticalStage.set_trigger_config(0);
obj.instr.laser.off();
% turn off laser indicator off
%set(obj.gui.(parentStruct)(panelIndex).laserUI.lasingIndicator, 'BackGroundColor', [1 0 0]);
%need to chagne params back to init values.
%     obj.instr.detector.setParam('RangeMode',1);  %set to auto range
%     [numOfTimers n] = size(running_timers);
%     for ii=1:numOfTimers
%         start(running_timers(ii));
%     end

obj.instr.detector.setPWMPowerUnit(powerUnit);
obj.manageTimer('resume', active_timers);
end


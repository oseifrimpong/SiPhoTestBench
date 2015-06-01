function success = fine_align(obj, parentStruct, panelIndex)
DEBUG=0;  %flag for debuggin plots cross hair pwr and displays variables to the terminal
waitbar_handle = waitbar(0.1,'Fine Align');
peakflag = 0;  %set to 1 if found peak (max output)
success = false;

%pause timers (auto update detectors readings) to make sure 816x.mdd driver
%doesn't crash
active_timers = obj.manageTimer('pause');

opticalStage = obj.instr.opticalStage;


% disable/enable active feedback for optical stage (if 1: enabled)
    [a,b] = obj.instr.opticalStage.set_closed_loop(1);
    obj.msg('Optical stage active feedback control:');
    obj.msg(strcat('response from Corvus: ',num2str(a),',',num2str(b)));

%Save the intial value : revert back at the end.
initial_vel = obj.instr.opticalStage.getParam('Velocity'); % for resetting to initial value
initial_accel = obj.instr.opticalStage.getParam('Acceleration'); % for resetting to initial value


%Prepare laser
obj.instr.laser.setWavelength(obj.AppSettings.FAParams.Wvl);
obj.instr.laser.setParam('PowerUnit',0);  %set to dBm
obj.instr.laser.setPower(obj.AppSettings.FAParams.Power);
obj.instr.laser.setParam('LowSSE',obj.AppSettings.FAParams.LowSSE);

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
%check if it is on GC
pwr = []; 
pwr = obj.instr.detector.readPower(detectorNum);
if DEBUG
    disp(strcat('Init power reading: ',num2str(pwr)));
end
abort_flag=0; %if set to 1 then abort button has been pressed
triedAltDetector = 0; % shon

if pwr < th && ~triedAltDetector && ~abort_flag
    %not on GC or wrong detector or wrong wavelength
    %DEBUG: could add algorithm to change detector and try again , or
    %chagne wavelength and try again.
    %     disp('currently not on GC; or wrong detector: searching... ');
    obj.msg('Fine align: currently not on GC; or wrong detector: searching...');
    N=ceil(delta_x/dx);  %this determins the window size
    kk=1;
    %do a spiral   
    while (pwr<=th && kk<N)
        %main loop for spiral
        if ~triedAltDetector 
            waitbar(0.2+(0.7*kk/N), waitbar_handle,'Fine Align: searching ...');
        else
            waitbar(0.2+(0.7*kk/N), waitbar_handle,'Fine Align: Alt detector searching ...');
        end
        %Check if Abort button has been pressed
%         if isstruct(parentStruct) && panelIndex  %this is hack for dry script; abort button for align_ui
          try
            if (get(obj.gui.(parentStruct)(panelIndex).alignUI.fine_align_abort_button,'UserData'))
                obj.msg('Abort fine align...');
                abort_flag=1;
                break;
            end
          end
%         end
        if mod(kk,2)
            s = 1;
        else
            s =-1;
        end
        for ll=1:1:kk
            opticalStage.move_x(s*dx);
            pwr=obj.instr.detector.readPower(detectorNum);
            if pwr>th
                break;
            end
        end
        for ll=1:1:kk
            opticalStage.move_y(s*dy);
            pwr=obj.instr.detector.readPower(detectorNum);
            if pwr>th
                break;
            end
        end
        kk=kk+1;
        
        %triedAltDetector=1;  %Jonas: temp fix to shut off alt detector for align
        
        % try alternate detector (if enabled)
        if kk==N && ~triedAltDetector
            detectorNum=obj.AppSettings.FAParams.AltDetector;
            triedAltDetector = 1; % set flag
            if detectorNum > 0 % if AltDetector feature is enabled
                obj.msg('Fine Align: No GC found: Switch to alternative detector');
                [curr_x, curr_y, init_z] = opticalStage.getPosition();
                opticalStage.move_y((init_y-curr_y));   %need to check if sings ar right
                opticalStage.move_x((init_x-curr_x));
                %Prepare detector
                obj.instr.detector.switchDetector(detectorNum);
                obj.instr.detector.setParam('PowerRange',obj.AppSettings.FAParams.PowerRange);
                obj.instr.detector.setParam('RangeMode',RangeMode);
                obj.instr.detector.setParam('PWMWvl',obj.AppSettings.FAParams.Wvl);
                obj.instr.detector.setParam('AveragingTime',obj.AppSettings.FAParams.AvgTime);
                
                %resatr loop
                kk=1;
            end
        end
        
    end
    
    if kk==N || abort_flag
        obj.msg('Fine Align: No GC found: moving to init position');
        [curr_x, curr_y, init_z] = opticalStage.getPosition();
        opticalStage.move_y((init_y-curr_y));
        opticalStage.move_x((init_x-curr_x));
        obj.instr.laser.off();
%        set(obj.gui.(parentStruct)(panelIndex).laserUI.lasingIndicator, 'BackGroundColor', [1 0 0]);        
        delete(waitbar_handle);
        return;
    else
        %disp('found GC...');
        obj.msg('Fine align: GC detected');
    end
    
end


if pwr > th;
    %sitting on GC
    %     disp('Fine align: Gradient method');
    obj.msg('Fine align: Gradient method');
    pwr = -100*ones(2*num_of_iterations+2);
    ii=num_of_iterations+1;
    jj=num_of_iterations+1;
    for pp=-1:1:1  %reading power of neighboring points
        for qq=-1:1:1
            opticalStage.move_y(dy); pause(2*obj.AppSettings.FAParams.AvgTime); %make sure the measurement is finished.
            pwr(ii+pp,jj+qq)=obj.instr.detector.readPower(detectorNum);
        end
        opticalStage.move_y(-3*dy); pause(2*obj.AppSettings.FAParams.AvgTime); %make sure the measurement is finished.
        opticalStage.move_x(dx); pause(2*obj.AppSettings.FAParams.AvgTime); %make sure the measurement is finished.
    end
    opticalStage.move_y(dy); pause(2*obj.AppSettings.FAParams.AvgTime); %make sure the measurement is finished.
    opticalStage.move_x(-2*dx); pause(2*obj.AppSettings.FAParams.AvgTime); %make sure the measurement is finished.
    uu=0;
    
%     disp('Debug gradient');
%     disp('pwr: ');
%     pwr(ii-1:1:ii+1,jj-1:1:jj+1)
    
    while (uu < num_of_iterations)
        waitbar(0.2+(0.7*uu/num_of_iterations), waitbar_handle,'Fine Align: Gradient method');
        if DEBUG
            disp(['iteration: ' num2str(uu)]);
            disp(['power: ' num2str(pwr(ii,jj))]);
            pwr(ii-1:1:ii+1,jj-1:1:jj+1)
        end
        %now decide what to do
        if (pwr(ii,jj) > pwr(ii-1,jj)) && (pwr(ii,jj) > pwr(ii+1,jj)) && (pwr(ii,jj) > pwr(ii,jj-1)) && (pwr(ii,jj) > pwr(ii,jj+1))
            %disp('found max');
            peakflag = peakflag+1;
            if peakflag==2 %set to 2 since there are sometimes false positives due to fibrations
                break; %peak is reached
            else
                %need to get power again
                pwr(ii,jj)=obj.instr.detector.readPower(detectorNum);
                opticalStage.move_x(dx);
                pwr(ii+1,jj)=obj.instr.detector.readPower(detectorNum);
                opticalStage.move_x(-2*dx);
                pwr(ii-1,jj)=obj.instr.detector.readPower(detectorNum);
                opticalStage.move_x(dx);
                opticalStage.move_y(-dy);
                pwr(ii,jj-1)=obj.instr.detector.readPower(detectorNum);
                opticalStage.move_y(2*dy);
                pwr(ii,jj+1)=obj.instr.detector.readPower(detectorNum);
                opticalStage.move_y(-dy);
            end
        elseif pwr(ii,jj)>pwr(ii,jj-1) && pwr(ii,jj)>pwr(ii,jj+1)  %max in y-direction (jj)
            %only move one direction
            %disp('max in y-direction');
            d=sign(pwr(ii+1,jj)-pwr(ii-1,jj));
            opticalStage.move_x(d*2*dx);
            pwr(ii+d*2,jj)=obj.instr.detector.readPower(detectorNum);
            opticalStage.move_x(-1*d*dx);
            opticalStage.move_y(-dy);
            pwr(ii+d,jj-1)=obj.instr.detector.readPower(detectorNum);
            opticalStage.move_y(dy);
            pwr(ii+d,jj)=obj.instr.detector.readPower(detectorNum);
            opticalStage.move_y(dy);
            pwr(ii+d,jj+1)=obj.instr.detector.readPower(detectorNum);
            opticalStage.move_y(-dy);
            ii=ii+d;
        elseif pwr(ii,jj)>pwr(ii-1,jj) && pwr(ii,jj)>pwr(ii+1,jj)
            %only move one direction
            %disp('max in x-direction');
            d=sign(pwr(ii,jj+1)-pwr(ii,jj-1));
            opticalStage.move_y(d*2*dy);
            pwr(ii,jj+d*2)=obj.instr.detector.readPower(detectorNum);
            opticalStage.move_y(-1*d*dy);
            opticalStage.move_x(-1*dx);
            pwr(ii-1,jj+d*1)=obj.instr.detector.readPower(detectorNum);
            opticalStage.move_x(dx);
            pwr(ii,jj+d*1)=obj.instr.detector.readPower(detectorNum);
            opticalStage.move_x(dx);
            pwr(ii+1,jj+d*1)=obj.instr.detector.readPower(detectorNum);
            opticalStage.move_x(-dx);
            jj=jj+d;
        else %on a slop with no maximums
            %disp('no max');
            d1=sign(pwr(ii+1,jj)-pwr(ii-1,jj));
            d2=sign(pwr(ii,jj+1)-pwr(ii,jj-1));
            opticalStage.move_y(d2*dy);
            pwr(ii,jj+d2)=obj.instr.detector.readPower(detectorNum);
            opticalStage.move_x(d1*dx);
            pwr(ii+d1,jj+d2)=obj.instr.detector.readPower(detectorNum);
            opticalStage.move_x(d1*dx);
            pwr(ii+2*d1,jj+d2)=obj.instr.detector.readPower(detectorNum);
            opticalStage.move_y(d2*dy);
            opticalStage.move_x(-d1*dx);
            pwr(ii+d1,jj+2*d2)=obj.instr.detector.readPower(detectorNum);
            opticalStage.move_y(-d2*dy);
            opticalStage.move_y(-d2*dy);
            pwr(ii+d1,jj)=obj.instr.detector.readPower(detectorNum);
            opticalStage.move_y(d2*dy);
            ii=ii+d1; jj=jj+d2;
        end
        uu=uu+1;
    end
    if peakflag==2 %set to 2 since there are sometimes false positives due to fibrations
        %Do cross hair fine aling: same as old on: now it is on GC for
        %sure.
        waitbar(0.9, waitbar_handle,'Fine Align: Crosshair method');
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
        for ii=1:1:Ny
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
        for ii=1:1:Nx
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
        
    end
end
%for saving motor position to file (Lukas request)
[dummy_x, dummy_y, ~] = opticalStage.getPosition();

obj.instr.laser.off();
%set(obj.gui.(parentStruct)(panelIndex).laserUI.lasingIndicator, 'BackGroundColor', [1 0 0]);

%set back intial values for stage
opticalStage.setParam('Velocity', initial_vel);
opticalStage.setParam('Acceleration', initial_accel);

obj.instr.detector.setPWMPowerUnit(powerUnit);
obj.manageTimer('resume', active_timers);

    [a,b] = obj.instr.opticalStage.set_closed_loop(1);
    obj.msg('Optical stage active feedback enabled.');
    obj.msg(strcat('response from Corvus: ',num2str(a),',',num2str(b)));

delete(waitbar_handle);

success = (peakflag == 2);
end


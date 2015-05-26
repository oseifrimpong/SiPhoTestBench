% © Copyright 2013-2015 Shon Schmidt, Jonas Flueckiger, and WenXuan Wu
% 
% self program is free software: you can redistribute it and/or modify
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

classdef Laser_SantecTSL510 < InstrClass
    properties
        % need to make GroupObj public so detector class can get it
        GroupObj; % handles to group objects
        PWMSlotInfo; % number of PWM modules installed in mainframe
        NumPWMChannels; % necessary for multiframe lambda scan setup, need to get from detector obj

    end
    
    properties (Access = protected)
        Password; % password to unlock the instrument
        Libname; % for trigger control?
        Session; % for trigger control?
        PauseTime; % so Matlab doesn't overrun the COM port
        
        Lasing; % 0=off, 1=laser output enabled
        ReadyForSweep; % flag
        
        % mainframe slot info
        NumberOfSlots; % number of laser/detector slots in mainframe
        NumDataPoints; % number of data points for this sweep
        MaxDataPoints; % detector depth for sweep
        
        StartWvl; % sweep wavelength (nm)
        StopWvl; % sweep wavelength (nm)
        StepWvl; % step (nm)
        SweepSpeed; % 1=slow ... 5=fast
        NumberOfScans; % number of scans for sweep
        StitchNum;
        
        %bounds
        wvlMin;  %Get wavelength range / get frequency range
        wvlMax;
        freqMin;
        freqMax;
        pwrMin;
        pwrMax;
       
        % bounds
        MinWavelength; % bounds read from instrument
        MaxWavelength; % bounds read from instrument
        MinPower; % bounds read from instrument
        MaxPower; % bounds read from instrument
        timeout; 
        
    end
    
    %% static methods
    methods (Static)
        %% convert nm wavelength to m
        function m = nm2m(nm)
            m = nm*1e-9;
        end
    end
    
    %% class methods
    methods
        
        %% constructor
        function self = Laser_SantecTSL510()
            % super class properties
            self.Name = 'Santec TSL510'; % name of the instrument
            self.Group = 'Laser'; % instrument group this one belongs to
            self.Model = 'TSL510';
            self.CalDate = '15-January-2015';
            self.Serial = 'SANTEC,TSL-510,14120007,0002.0090';
            self.Busy = 0; % not busy
            self.Connected = 0; % not connected
            
            
            self.wvlMin = 1270; %[nm]
            self.wvlMax = 1350; %[nm]
            self.freqMin = 230; %[THz]
            self.freqMax = 250; %[THz]
            self.pwrMin = -10; %[dBm]
            self.pwrMax = 10;  %[dBm]
            self.timeout = 5; 
            
            % other properties
            self.NumberOfSlots = 5;
            self.Lasing = 0;
            self.PauseTime = 0.01;  %
            self.ReadyForSweep = 0; % 0=no, 1=yes
            self.MaxDataPoints = 4000; % should be queried from instrument
            self.StitchNum = 0;
            self.StartWvl = 1480; % sweep wavelength (nm)
            self.StopWvl = 1580; % sweep wavelength (nm)
            self.StepWvl = 0.01; % step (nm)
            self.SweepSpeed = 5; % 1=slow ... 5=fast
            self.NumberOfScans = 0; % number of scans for sweep
            
            % instrument parameters
            self.Param.Wavelength = 1310; % wavelength (nm), needs to be set through a method so we know it changes
            
            self.Param.PowerLevel = 0; % initialize currenet power level
            self.Param.COMPort = 1; %  GPIB port #
            %self.Param.TunableLaserSlot = 0; % slot 0 in mainframe
            self.Param.PowerUnit = 0; % 0=dB, 1=W
            self.Param.PowerLevel = 0; % (dB if self.Param.PowerUnit=0)
            %self.Param.LowSSE = 0; % 0=no, 1=low-noise scan
            self.Param.Password = '0000';
            %self.Param.UseFastILEngine = 0;
            
            %self.TotalSlots = 0;
            %self.TotalNumOfDetectors = 0; %this is done now on the detector side. 
        end
        
        %% Connect
        function connect(self)
            if ~self.Connected
                self.Busy = 1;

                    try

                        BoardIndex = 0; 
                        instrf = instrfindall({'type','BoardIndex','PrimaryAddress'},...
                            {'gpib',BoardIndex, num2str(self.Param.COMPort)});
                        if isobject(instrf)
                            disp('Connection error in MLPLaser: com obj already exists');
                            disp('delete object and reconnect');
                            delete(instf); 
                            self.Connected = 0; 
                        end
                        
                        %create gpib object
                        try
                            self.Obj = gpib('ni',BoardIndex,...
                                self.Param.COMPort);
                        catch ME
                            rethrow(ME)
                        end
   
                 
                        %open gpib connection
                        try
                            fopen(self.Obj);
                            self.Connected = 1; 
                        catch ME
                            rethrow(ME); 
                        end

                        % preset
                        self.preset();
                        
                        % get instrument parameter bounds and current settings
                        
                        %get wavelength min and max
                        [self.wvlMin, self.wvlMax]=self.getWavelengthMinMax;
                        disp(['wvlMin = ',num2str(self.wvlMin),'nm']);
                        disp(['wvlMax = ',num2str(self.wvlMax),'nm']);
                        %disp(['freqMin = ',num2str(self.freqMin),'THz']);
                        %disp(['freqMax = ',num2str(self.freqMax),'THz']);
                        
                        [self.pwrMin, self.pwrMax] = self.queryPower();
                        
                        self.Connected = 1;
                        msg = strcat(self.Name, ': Successfully connected.');
                        disp(msg);
                    catch ME
                        msg = strcat(self.Name, ': Cannot connect and initialize.');
                        % disp(msg);
                        disp(ME.message)
                        self.Connected = 0;
                    end

            else
                msg = strcat(self.Name, ': Already connected.');
                % disp(msg);
            end
            self.Busy = 0;
        end
        
        %%send commands
        function sendCommand(self, command)
               
                %check if connection is open
                if strcmp(self.Obj.status, 'closed')
                    try
                        fopen(self.Obj);
                    catch ME
                        disp('Santec Laser COM error', ME);
                        rethrow(ME);
                        return
                    end
                end
                
                %Send command
                try
                    fprintf(self.Obj, command);
                catch ME
                    disp('Santec Laser COM error: fprintf fail', ME);

                    rethrow(ME);
                end


        end
        
        %%read response
        function response=readResponse(self)
            response = ''; %init

                %check if connection is open
                if strcmp(self.Obj.status, 'closed')
                    try
                        fopen(self.Obj);
                    catch ME
                        self.setReady;
                        disp('Santec Laser COM error');
                        rethrow(ME); 
                        return;
                    end
                end
                start_time = tic;
                while isempty(response) && (toc(start_time)<self.timeout)
                    self.Obj.TransferStatus;
                    response = fscanf(self.Obj); %expect it to read all at once.
                    pause(self.PauseTime);
                end
                if toc(start_time) >= self.timeout
                    err = MException(strcat(self.Name,':ReadTimeOut'),...
                        'Laser connection timed out');
                    disp('No response from Santec Laser');
                    throw(err); 
                end

        end
              
        %% wait for completion
        function waitForCompletion(self)
            ready = 0;
            self.sendCommand('*OPC?');
            if ~str2num(self.readResponse());  %in case operation is already completed by the time it gets here.
                return
            end
                
            start_time = tic;
            while ~ready  && toc(start_time)< self.timeout
                self.sendCommand('*OPC?');
                pause(0.05);
                ready= str2num(self.readResponse())
            end
            if toc(start_time) >= self.timeout
                disp('WaitforCompletion timed out ');
            end
            
        end
       
        

        
        %% Disconnect instrument
        function disconnect(self)
            self.Busy = 1;

                instrf = instrfindall({'type','BoardIndex','PrimaryAddress'},...
                    {'gpib',0,num2str(self.Param.COMPort)});
                delete(instrf);

            self.Busy = 0;
        end
        
        %% Preset laser to known state
        function preset(self)
            %password only needed if connected when laser is just switched
            %on
            self.sendCommand([':syst:pass ', self.Password]);
            % get identification
            self.sendCommand('*IDN?');
            self.Serial = self.readResponse;
            disp(['Laser ID: ',self.Serial]);
            %get firmware version
            self.sendCommand(':syst:vers?');
            firmwareVersion = self.readResponse;
            disp(['Laser Firmware Version: ',firmwareVersion]);
            %reset device / abort all standby operations
            self.sendCommand('*RST'); 
            self.sendCommand('*CLS'); 
            
            
            %set all the default values.

            %set the wavelength unit to [nm]
            defaultWvlUnit = 0; 
            self.setWavelengthUnit(defaultWvlUnit); % 0 - nm ; 1 - THz
            
            %set wavelength default
            defaultWvl = self.Param.Wavelength; %unit [nm]
            self.setWavelength(defaultWvl);
            
            
            %Disable fine tuning
            self.sendCommand(':WAV:FIN:DIS');
            
            
            %set power unit to [dBm]
            defaultPwrUnit = 0;
            self.setPowerUnit(defaultPwrUnit); % 0:dBm 1:mW
            
            %get power min and max (only for dBm)
            self.pwrMin= -40; 
            self.pwrMax= 10; 
            disp(['pwrMin = ',num2str(self.pwrMin),'dBm']);
            disp(['pwrMax = ',num2str(self.pwrMax),'dBm']);
            
            % setting attenuation to auoto -> output power is held at
            % constant level (with internal power monitor)
            self.sendCommand(':POW:ATT:AUT 1');
            
            
            
            %check the state of the laser -> LD current should not
            %switched on and off to much
            resp = laserIsOn(self);
            if resp==0 || resp==3
                %switch LD current on
                disp('Turning laser diode on');
                self.switchLDOn();
            else
                if resp ==1 || resp==2
                    disp('Laser Diode is already swichted on');
                    self.off(); %Close shutter
                end
            end
            self.on(); %opens shutter
            %set power to
            defaultPwr = 0;
            self.setPower(defaultPwr);
            
            self.off(); %close shutter
            disp('preset complete');

            
        end
        
        
                %% Switch laser diode current on
        function success = switchLDOn(self)
            % success=1: turned on 
            success = 0;
            self.sendCommand([':POW:STAT?']); %0:LD current OFF ; 1=LD current ON
            if ~str2num(self.readResponse());
                self.sendCommand(':POW:STAT 1'); 
                success = 1; 
                disp('Laser Diode Current is ON');
            else
                disp('Laser Diode Current is ON'); 
            end
        end
       
        
                %% Switch laser diode current off
        function success = switchLDOff(self)
            % success=1: turned on 
            success = 0;
            self.sendCommand([':POW:STAT?']); %0:LD current OFF ; 1=LD current ON
            if str2num(self.readResponse());
                self.sendCommand(':POW:STAT 0'); 
                success = 1; 
                disp('Laser Diode Current is OFF');
            else
               disp('Laser Diode Current is OFF'); 
            end
        end
        
        
        
        %% Turn laser off
        function msg = off(self)
            success = 0; 
            self.sendCommand([':POW:SHUT ',num2str(1)]);
            self.sendCommand([':POW:SHUT?']);
            
            if str2num(self.readResponse()) 
                disp('Shutter is closed');
                success = 1; 
            else
                err = MException('Laser:Shutter',...
                    'Laser Shutter did not close properly'); 
                disp('Laser:Shutter',err); 
            end
            self.Busy = 0;
        end
        
        %% Turn laser on
        function msg = on(self)
            success = 0; 
            self.sendCommand([':POW:SHUT ',num2str(0)]);
            self.sendCommand([':POW:SHUT?']);
            
            if ~str2num(self.readResponse()) 
                disp('Shutter is open');
                success = 1; 
            else
                err = MException('Laser:Shutter',...
                    'Laser Shutter did not close properly'); 
                disp('Laser:Shutter',err); 
            end 
            self.Busy = 0;
        end
        
        %% get laser state: needed in GC map
        function resp = laserIsOn(self)
            self.Busy = 1;
            resp = 0; %LD off ; shutter off
            %resp = 1; LD on ; shutter on; 
            %resp = 2; LD on ; shutter off;
            %resp = 3; LD off; shutter on; 
            self.sendCommand('POW:STAT?'); %0 LD current off ; 1: LD current on
            LD_current = str2num(self.readResponse());
            self.sendCommand([':POW:SHUT?']);  
            shutter = str2num(self.readResponse());
             if ~shutter && LD_current 
                resp = 1; 
             else
                 if shutter && LD_current
                     resp = 2; 
                 end
                 
                 if ~shutter && ~LD_current
                     resp = 3;
                 end
             end 
            self.Busy = 0;
        end
        
        %% set laser wavelength
        function setWavelength(self,wvl)
            self.Busy = 1;
                wvl = round(wvl*1000)/1000; %resolution limit to 1pm. 
                if (wvl<=self.wvlMax) && (wvl>=self.wvlMin)
                    self.sendCommand([':WAV ',num2str(wvl)]);
                    disp('setting wavelength....'); 
                else
                   warndlg(sprintf('Wavelength value out of range \n \t\t\t - nothing done'),...
                       'Value out of range', 'modal');
                end
                self.waitForCompletion(); %takes a while for wvl to settle
                pause(0.4);
                %check if set and get are the same;
                %disp(sprintf('Wavelength returned from Laser: %f nm',self.getWavelength()));
                if wvl ~= self.getWavelength
                    [errorNumber, errorMessage] = self.getError();
                    disp(sprintf('Error code %d and message from Laser: \n \t\t\t %s', errorNumber,errorMessage));
                    if ~errorNumber  %try again, wait time might not be long enough...
                        pause(0.4); 
                       if wvl~=self.getWavelength
                           self.Busy = 0;
                           disp(['Wavelength set to :',num2str(wvl)]);
                           return
                       else
                           ex = MException('Laser:setWvl',...
                               strcat('Wavelength mismatch: set wvl: ',num2str(wvl),'  get wvl: ', num2str(self.getWavelength)));
                           disp('setWavelength Error');
                           throw(ex);
                       end
                    else
                        ex = MException('Laser:setWvl',...
                            strcat('Wavelength mismatch: set wvl: ',num2str(wvl),'  get wvl: ', num2str(self.getWavelength)));
                        disp('setWavelength Error');
                        throw(ex);
                    end
                else
                    disp(['Wavelength set to :',num2str(wvl)]);
                end
                
            self.Busy = 0;
        end
        
        % get wavelength
        function wvl = getWavelength(self)
            wvl = 1; 
            self.sendCommand(':WAV?');
            wvl = str2num(self.readResponse());
            if (wvl>=self.wvlMax) || (wvl<=self.wvlMin)
                ex = MException('Laser:getWavelength',...
                    strcat('getWavelength returned wvl out of range'));
                disp('getWavelength Error');
                throw(ex);
            end
        end
        
                %% set wavelength unit
        function setWavelengthUnit(self,unit)
            % unit = 0 -> nm
            % unit = 1 -> THz
            in = self.getWavelengthUnit;
            if in~=unit
                self.sendCommand([':SOUR:WAV:UNIT ', num2str(unit)]);
            end
            in = self.getWavelengthUnit;
            if in == 0
                disp(['Wavelength unit set to: [nm]']);
            else if in ==1
                    disp(['Wavelength unit set to: [THz]']);
                end
            end
        end
        
                %% get wavelength unit
        function unit = getWavelengthUnit(self)
            % unit = 0 -> nm
            % unit = 1 -> THz
            self.sendCommand(':WAV:UNIT?');
            unit = str2num(self.readResponse());
           
        end
        %% setPower
        function setPower(self,pwr) %power in dBm
            self.Busy = 1;
                %power in dBm
                pwr = round(pwr*100)/100; %resolution limit to 0.01dB. 
                if (pwr<=self.pwrMax) && (pwr>=self.pwrMin); 
                    self.sendCommand([':POW ',num2str(pwr)]);
                else
                   warndlg(sprintf('Power value out of range \n \t\t\t - nothing done'),...
                       'Value out of range', 'modal');
                end
                self.waitForCompletion();
                in = self.getPower; 
                if pwr ~= in
                    ex = MException('Laser:setPwr',...
                        strcat('Power mismatch: set pwr: ',num2str(pwr),'get pwr: ', num2str(in)));
                    disp('setPower error', ex);
                    throw(ex);
                end
                
                actualPower = self.getPowerActual;
                if actualPower<in
                    disp(sprintf('Current output power (%f [dBm]) is lower than set power (%f [dBm])',actualPower,in)); 
                end
                disp(['Current output power: ', num2str(self.getPowerActual), 'dBm']);
            self.Busy = 0;
        end
        
        % getPower
        function pwr = getPower(self) %power in dBm
            self.Busy = 1;
                self.sendCommand(':POW?'); 
                pwr = str2num(self.readResponse()); 
            self.Busy = 0;
        end
        
                %% Returns the current laser power from the internal power meter
        function [pwr] = getPowerActual(self)

                self.sendCommand(':POW:ACT?');
                pwr = str2num(self.readResponse());

        end
        
        
        %% set power unit
        function setPowerUnit(self,unit)
            self.Busy = 1;
            % unit = 0 -> dBm
            % unit = 1 -> Watts
            in = self.getPowerUnit;
            if in~=unit
                self.sendCommand([':POW:UNIT ', num2str(unit)]);
            end
            in = self.getPowerUnit;
            if in == 0
                disp(['Power unit set to: [dBm]']);
            else if in ==1
                    disp(['Power unit set to: [mW]']);
                end
            end
            self.Busy = 0;
        end
        
        %% get power unit
        function unit = getPowerUnit(self)
            % unit = 0 -> dBm
            % unit = 1 -> mWatts
            
            self.sendCommand(':POW:UNIT?');
            unit = str2num(self.readResponse());
            
        end
        
        %% set sweep range
        function setStartWvl(self,wvl)
            self.Busy = 1;

                wvl = round(wvl*1000)/1000; %resolution limit to 1pm. 
                if (wvl<=self.wvlMax) && (wvl>=self.wvlMin)
                    self.sendCommand([':WAV:SWE:STAR ',num2str(wvl)]);
                else
                    err = MException('Sweep:setStartWvl',...
                        'Wavelength value out of range');
                    disp('LaserSweep:setStartWvl'); 
                    throw(err);
                end
                self.waitForCompletion(); 
                %check if set and get are the same;
                if wvl ~= self.getStartWvl
                    ex = MException('Laser:setWvl',...
                        strcat('Wavelength mismatch: set wvl: ',num2str(wvl),'get wvl: ', num2str(self.getWavelength)));
                    disp('setWavelength Error');
                    throw(ex); 
                else
                    disp(['Sweep: Start Wavelength set to :',num2str(wvl)]);
                end
            self.Busy = 0;
        end
        
                %% get sweep range: start wvl
        function wvl = getStartWvl(self)
            wvl = 1;
            self.sendCommand(':WAV:SWE:STAR?');
            wvl = str2num(self.readResponse());
            if (wvl>self.wvlMax) || (wvl<self.wvlMin)
                ex = MException('Laser:getStarWvl',...
                    strcat('getStartWvl returned wvl out of range'));
                disp('getWavelength Error');
                throw(ex);
            end
        end
        
        function setStopWvl(self,wvl)
            self.Busy = 1;
                wvl = round(wvl*1000)/1000; %resolution limit to 1pm. 
                if (wvl<=self.wvlMax) && (wvl>=self.wvlMin)
                    self.sendCommand([':WAV:SWE:STOP ',num2str(wvl)]);
                else
                    err = MException('Sweep:setStopWvl',...
                        'Wavelength value out of range');
                    disp('LaserSweep:setStopWvl'); 
                    throw(err);
                end

                %check if set and get are the same;
                if wvl ~= self.getStopWvl
                    ex = MException('Laser:setWvl',...
                        strcat('Wavelength mismatch: set wvl: ',num2str(wvl),'get wvl: ', num2str(self.getStopWvl)));
                    disp('LaserSweep:setStopWvlError');
                    throw(ex);
                else
                    disp(['Sweep: Stop Wavelength set to :',num2str(wvl)]);
                end
            self.Busy = 0;
        end

                %% get sweep range: stop wvl
        function wvl = getStopWvl(self)
            wvl = 1;
            self.sendCommand(':WAV:SWE:STOP?');
            wvl = str2num(self.readResponse());
            if (wvl>self.wvlMax) || (wvl<self.wvlMin)
                ex = MException('Laser:getStopError',...
                    strcat('getStopWvl returned wvl out of range'));
                disp('getWavelength Error');
                throw(ex);
            end
        end
        

        
        
        %% Sweep
        function [datapoints, channels] = setupSweep(self)
            self.Busy = 1;
            disp('Setting Sweep Parameters ...');
            
            %Fixed sweep parameters
            % numbers of sweep cycles
            self.sendCommand(':WAV:SWE:CYCL 1');
            %sets the delay between sweep cycles
            self.sendCommand(':WAV:SWE:DEL 0.1'); %range: 0-999.9 s; step 0.1
            self.sendCommand(':WAV:SWE:MOD 1');
            %0: Step operation one way
            %1: continuous operation, one way
            %2: step operation, two way
            %3: continuous operation, two way
            
            self.setStartWvl(start);
            self.setStopWvl(stop);
            self.setSweepSpeed(speed); 
            self.Busy = 0;
            self.ReadyForSweep = 1;
%             disp('laser.setupSweep complete');
        end
        
        % get sweep parameters
        function [start_wvl,end_wvl,sweep_speed] = getSweepParams(self)
            self.Busy = 1;

            self.Busy = 0;
        end
        
        % execute sweep
        function resp = sweep(self)
%             disp('starting laser.sweep');
            % returns array with wavelength value for each sample in (m)
            self.Busy = 1;
            if self.ReadyForSweep
                self.sendCommand(':WAV:SWE 1');
                self.waitForCompletion;
            end
            self.Busy = 0;
            self.ReadyForSweep = 0;
            %             disp('laser.sweep complete');
        end
        

        

        
        %% send params (overloads superclass method)
        function sendParams(self)
            Attenuation = 0;
            try
               
                self.setPower(self.Param.PowerLevel);
                self.setWavelength(self.Param.Wavelength); 
                
            catch ME
                rethrow(ME);
            end
        end
        
        
        % set property
        function self = setProp(self, prop, val)
            % if self.(prop)  %testing self way is not valid. prop can be 0
            self.(prop) = val;
            %else
            %   msg = strcat(self.Name, ' ', prop, ' does not exist.');
            %   err = MException(self.Name,msg);
            %   throw(err);
            %end
        end
        
        % get property
        function val = getProp(self, prop)
            %if self.(prop)
            val = self.(prop);
            %else
            %   msg = strcat(self.Name, ' ', prop, ' does not exist.');
            %   err = MException(self.Name,msg);
            %   throw(err);
            %end
        end
        
        function [triggerIn, triggerOut] = getTriggerSetup(self)
            [triggerIn, triggerOut] = invoke(...
                self.GroupObj.Tunablelasersources, ...
                'gettlstriggerconfiguration', ...
                self.Param.TunableLaserSlot);
            disp('trigger values from Laser_Agilent8164A.getTriggerSetup func:')
            disp(triggerIn);
            disp(triggerOut);
        end
        
        function [triggerIn, triggerOut] = setTriggerPassThru(self)
            triggerIn = 0;
            triggerOut= 0 ; 
        
            
            success = 0; 
            %0: None
            %1: Stop
            %2: Start
            %3: Step
            self.sendCommand([':TRIG:OUTP ',num2str(0)]);
        end
    end
    
    % Private methods
    methods (Access = private)
        
        %% Returns the current wavelength and the min and max wavelength bounds
        
        function [wvlMin, wvlMax] = getWavelengthMinMax(self)
                self.sendCommand(':WAV:MIN?');
                wvlMin = self.readResponse();
                wvlMin=str2num(wvlMin);
                self.sendCommand(':WAV:MAX?');
                wvlMax = self.readResponse(); 
                wvlMax=str2num(wvlMax) ;        
        end
        
        %% Returns the current laser power as well as the min and max power bounds
        function [pwrMin, pwrMax] = queryPower(self)
            
            self.sendCommand(':POW:MIN?');
            pwrMin=str2num(self.readResponse());
            self.sendCommand(':POW:MAX?');
            pwrMax=str2num(self.readResponse());
        end
        
        %% Returns details about a driver error
        function [errorNumber, errorMessage] = getError(self)
            errorNumber = -1; errorMessage = 'Nothing returned from laser';
                self.sendCommand(':SYST:ERR?');
                resp = self.readResponse();
                line=sscanf(resp,'%d,%s');
                switch line(1)
                    case 0
                        errorNumber=0; 
                        errorMessage = 'No error';
                    case -102
                        errorNumber = -102;
                        errorMessage = 'Syntax error';
                    case -103
                        errorNumber = -102;
                        errorMessage = 'Invalid separator';
                    case -108
                        errorNumber = -108;
                        errorMessage = 'Parameter not allowed';
                    case -109
                        errorNumber = -109;
                        errorMessage = 'Missing parameter';
                    case -113
                        errorNumber = -113;
                        errorMessage = 'Undefined header';
                    case -148
                        errorNumber = -148;
                        errorMessage = 'Character data not allowed';
                    case -200
                        errorNumber = -200;
                        errorMessage = 'Execution error';
                    case -222
                        errorNumber = -222;
                        errorMessage = 'Data out of range';
                    case -410
                        errorNumber = -410;
                        errorMessage = 'Query INTERRUPTED';
                    otherwise
                        errorNumber = 1000;
                        errorMessage = resp; 
                end
        end
        

        

        
    end
end

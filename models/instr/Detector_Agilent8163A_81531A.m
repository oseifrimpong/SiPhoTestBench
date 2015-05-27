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

classdef Detector_Agilent8163A_81531A < InstrClass
    properties
        GroupObj;
    end
    properties (Access = protected)
        EngineMgr; % Engine Manager for the

        
        
        PauseTime; % so Matlab doesn't overrun the COM port
        % Properties
        Slots;
        TotalSlots;
        NumOfSlots;
        NumOfDetectors;
        SelectedDetectors;
        TotalNumOfDetectors;
        SlotNumber; % Need to redefine
        ChannelNumber; % Need to redefine
        PWMSlotInfo;
        PWMSlots; %array with slot numbers used
        
        DetectorNumber; % Sofware label number of detector
        DetectorSwitchOffset;
        DetectorLabel; % Legend for figure
        Zeroed; % Flag for Zeroing detector bias
        Clipping; % 0=no, 1=yes
        ClipLimit;
        RangeDecrement; %for multiple scans with different range
        MaxDataPoints; % detector memory depth
        ReadyForSweep; % flag
        
        Libname;
        Session;
        
        % structs/storage variables
        DataPoints; % length of Pwr and Wvl arrays, should get from detector or calc by sweep range/step
        Pwr; % Preallocate for speed
        Wvl;% Preallocate for speed
        wvlMin;
        wvlMax;
        minAveragingTime;
        maxAveragingTime;
    end
    
    %% static methods
    methods (Static)
        %% convert nm wavelength to m
        function m = nm2m(nm)
            m = nm*1e-9;
        end
    end
    
    methods
        % Constructor
        function self = Detector_Agilent8163A_81531A()
            % Super Class - InstrClass properties
            self.Name = 'Agilent8163A + 81531A';
            self.Group = 'Detector';
            self.Model = 'Agilent 81531A';
            self.CalDate = date;
            self.Busy = 0;
            self.Connected = 0;
            
            self.Slots = [];
            self.TotalSlots = [];
            self.NumOfSlots = 2;
            self.NumOfDetectors = 0; % Hard-coded for now;
            self.PWMSlotInfo = 0;  %new
            self.PWMSlots = 0; %new %array with slot numbers used
            self.SelectedDetectors = 1;
            self.TotalNumOfDetectors = 0;
            self.MaxDataPoints = 4000; %hard coded for now, needs to be queried
            
            self.SlotNumber = 1; % channel # in slot
            self.ChannelNumber = 1;% Sofware label number of detecto
            self.Zeroed = 1 ; % 0=no, 1=yes, Flag for Zeroing detector bias
            self.DetectorNumber = -1;
            self.DetectorSwitchOffset = 0;
            
            self.minAveragingTime = 100e-6;  %from instrument
            self.maxAveragingTime = 1000; %arbitrary
            
            self.wvlMax = 1700;
            self.wvlMin = 700; 
            self.DataPoints = 1401;
            % Length of DataPoints Should Specified in congfid file from
            % Agilent Software and used in the future.
            
            
            % Parameters
            self.Param.COMPort = '20';
            self.Param.ClipLimit = -200; 
            self.Param.AveragingTime = .001; % s
            self.Param.RangeMode = 0; %1=auto, 0=manual, use Range val
            self.Param.PowerRange = -20; % dB
            self.Param.PowerUnit = 0; % dB=0, W=1
            self.Param.UpdatePeriod = 0.5; % update reading timer: 0.5s
            self.Param.PWMWvl = 1550;
            self.Param.WaitForCompletion = 0;
            self.Param.InternalTrigger = 1; % not sure what this does
            self.Param.Zeroing = 0; % Boolean to choose whether zero all detectors while connecting
            self.PauseTime = .01;
        end
        
        function self = connect(self, varargin)
            %             self.Obj = serial(strcat('COM', num2str(self.Param.COMPort)));
            %             fopen(self.Obj);
            %             set(self.Obj,'Timeout',self.Timeout);
            try
                %% open COM port and connect to physical instrument
                
                BoardIndex = 0; 
                instrf = instrfindall({'type','BoardIndex','PrimaryAddress'},...
                    {'visa-gpib',BoardIndex, self.Param.COMPort});
                
                if isobject(instrf)
                    disp(['Connection error', self.name, ': com obj to GPIB address ',...
                        num2str(self.Param.COMPort), ' and Board Index ', num2str(BoardIndex), ...
                        'already exists']);
                    disp('delete obj and connect');
                    delete(instrf);
                    return;
                end
                
                
                GPIB_address = strcat('GPIB',num2str(BoardIndex),'::', num2str(self.Param.COMPort), '::INSTR');
                self.Obj = icdevice('hp816x_v4p2', GPIB_address);
                %                    self.Obj = icdevice('C:\Users\LuckyStrike\uwbiobench\drivers\hp816x_v4p2.mdd', GPIB_address);
                
                connect(self.Obj);
                
                % create handles to group functions
                self.GroupObj.Multiframelambdascan = get(self.Obj, 'Applicationswavelengthscanfunctionsmultiframelambdascan');
                self.GroupObj.Tunablelasersources = get(self.Obj, 'Tunablelasersources');
                self.GroupObj.Mainframespecific = get(self.Obj, 'Mainframespecific');
                self.GroupObj.Pwmdataaquisition = get(self.Obj, 'Powermetermodulespwmdataacquisition');
                self.GroupObj.Powermetermodules = get(self.Obj, 'Powermetermodules');
                self.GroupObj.Utility = get(self.Obj, 'Utility'); 
                                self.GroupObj.Utilitypassthrough = get(self.Obj, 'Utilitypassthrough');
                disp('connection to detector established');
                
                self.Libname = get(self.Obj, 'DriverName');
                self.Session = get(self.Obj, 'Interface');
                
                %self.register();
                % get number of detectors installed in mainframe (for sweep)
                self.querySlotInfo();
                 % preset
                self.preset();               
                
                %set wavelength default
                defaultWvl = 1310; %unit [nm]
                self.setWavelength(defaultWvl);
                disp('Wavelength set');
                %set power unit to [dBm]
                defaultPwrUnit = 0;
                self.setPWMPowerUnit(defaultPwrUnit); % 0:dBm 1:mW
                disp('Power set');              

                

                %wvl = self.queryWavelength();
                pwr = self.readPowerAll()
                
                self.Connected = 1;
                msg = strcat(self.Name, ': Successfully connected.');
                disp(msg);
            catch ME
                msg = strcat(self.Name, ': Cannot connect and initialize.');
                disp(msg);
                disp(ME.message)
                self.Connected = 0;
            end
        end
        
        %% Preset laser to known state
        function preset(self)
            invoke(self.GroupObj.Mainframespecific, 'preset', self.Session)
        end
        
        function self = register(self)
            % register mainframe
            invoke(self.GroupObj.Multiframelambdascan,'registermainframe');
            %             self.querySlotInfo();
        end
        
        %         function self = disconnect(self)
        %             self.Engine.release;
        %             self.EngineMgr.release;
        %         end
        
        %% zero PWMs
        function zeroAllPWMs(self)
            disp('Zeroing PWMs')
            [SummaryOfZeroingAllPWMs] = invoke(self.GroupObj.Powermetermodules('pwmzeroingall'))
        end
        
        function [slot, channel, self] = switchDetector(self, DetectorNumber)
            % Calculate the slot and channel number for detector
            
            count = 1;
            [~, ll ] = size(self.PWMSlots);
            for ii=1:ll
                for jj = 1:self.PWMSlots(2,ii)
                    if count == DetectorNumber
                        slot = self.PWMSlots(1,ii);
                        channel = jj-1;
                        %this.logStatus(sprintf('slot number: %u', slot))
                        %this.logStatus(sprintf('channel number: %u', channel));
                        return
                    else
                        count = count + 1;
                    end
                end
            end
            
            
            %
            self.SlotNumber = slot;
            self.ChannelNumber = channel;
            self.DetectorNumber = DetectorNumber;
        end
        
        %%
        function setPWMPowerUnit(self, PowerUnit)
            % PowerUnit: 0 to dB, 1 to W
            for i = 1:self.NumOfDetectors
                [slot, channel] = self.switchDetector(i);
                invoke(self.GroupObj.Powermetermodules, 'setpwmpowerunit', ...
                    slot, channel, PowerUnit);
                self.Param.PowerUnit =PowerUnit; 
            end
        end
        %%
        function powerUnit = getPWMPowerUnit(self)
            powerUnit = self.Param.PowerUnit;
        end
 
        function setWavelength(self,wvl)
            
            wvl = round(wvl*1000)/1000; %resolution limit to 1pm.
            if (wvl<=self.wvlMax) && (wvl>=self.wvlMin)
                for dd = 1:self.NumOfDetectors
                    [slot, channel] = self.switchDetector(dd);
                    invoke(self.GroupObj.Powermetermodules, 'setpwmwavelength',...
                        slot,channel, wvl*1e-9); %The averaging time cannot be set for the slave channel
                end
                
            else
                warndlg(sprintf('Wavelength value out of range \n \t\t\t - nothing done'),...
                    'Value out of range', 'modal');
            end
            
            %check if set and get are the same;
            %.....
            %
        end
        
        
        
        
        
        %% Fetch single power value
        function powerVal = readPower(self, DetectorNumber)
            [slot, channel] = self.switchDetector(DetectorNumber);
            %             comparision to the "FETCH" command, the "READ"
            %             command implies triggering a measurement. Make sure the
            %             timeout set is greater than the adjusted averaging time, so that the
            %             READ command will not time out;
            try
                powerVal = invoke(self.GroupObj.Powermetermodules, 'pwmreadvalue', ...
                    slot, channel);
            catch ME
                %rethrow(ME)
                try
                    err=self.queryError();
                catch ME1
                    rethrow(ME1)
                end
                if err == -261
                    powerVal =self.Param.ClipLimit;
                    return
                elseif err == -231  %value questionable, doesn't necessarily mean saturated
                    powerVal = -self.Param.ClipLimit;
                else
                    ex = MException(strcat('Detector:readPower'),...
                        strcat('Error Query returned: ',num2str(err)));
                    throw(ex);
                end
            end
        end
        
        
        function PowerValues = readPowerAll(self)
            try
                %                 SlotsA = zeros(1,4); %%% ??? Not sure how many to use...
                %                 ChannelsA = zeros(1,4);%%% ??? Not sure how many to use...
                %                 ValuesA = zeros(1,4); %%% ??? Not sure how many to use...
                %
                %                 [~, ~, ~, PowerValues] = invoke( ...
                %                     self.GroupObj.Powermetermodules,'pwmreadall', ...
                %                     SlotsA, ChannelsA, ValuesA);
                PowerValues = zeros(1, self.NumOfDetectors);
                for dd = 1:self.NumOfDetectors
                    PowerValues(dd) = self.readPower(dd);
                end
            catch ME
                
                rethrow(ME);
                
            end
        end
        

        
        %Set up data logging if trigger set then the detectors waits for
        %trigger if not it starts recording right awy
        function [EstimatedTimeout]=start_pwm_logging(self, DetectorNumber)
            [slot, ~] = self.switchDetector(DetectorNumber);
            %channel number is always 0 ;
            [EstimatedTimeout] = invoke(self.GroupObj.Pwmdataaquisition,...
                'setpwmlogging',slot, 0, ...
                self.Param.AveragingTime, self.DataPoints);
        end
        
        function [LoggingStatus, LoggingResult] = get_pwm_logging(self,DetectorNumber)
            % Get data from scanning to the right
            [slot, channel ] = self.switchDetector(DetectorNumber);
            LoggingResult = zeros(1, self.DataPoints);
            self.Param.PowerUnit=0; %fixed to dBm
            [LoggingStatus, LoggingResult] = invoke(self.GroupObj.Pwmdataaquisition,...
                'getpwmloggingresultsq', slot, channel, self.Param.WaitForCompletion,...
                self.Param.PowerUnit, LoggingResult);
        end
        
        function setup_trigger(self, TriggerIn, TriggerOut, DetectorNumber)
            %TriggerIn=2; %0:ignore 1:single (sme), 2:complete (cme)
            %TriggerOut=0; %0:disabled, 1:at the end, 3:at the beginning
            [slot, channel ] = self.switchDetector(DetectorNumber);
            invoke(self.GroupObj.Powermetermodules, 'setpwmtriggerconfiguration', slot, ...
                TriggerIn, TriggerOut);
            [in, out] = invoke(self.GroupObj.Powermetermodules, 'getpwmtriggerconfiguration', slot);
        end
        
        % Returns details about a driver error
        function [errorNumber, errorMessage] = queryError(self)
            [errorNumber, errorMessage] = invoke(self.GroupObj.Utility, 'errorquery');
        end
        
        
        % Returns details about a driver error
        function AveragingTime = getAvgTime(self)
            [slot, channel ] = self.switchDetector(1); %all detectors have the same averaging time; hack;
            AveragingTime = invoke(self.GroupObj.Powermetermodules, 'getpwmaveragingtimeq',slot, channel);
        end
        % Returns details about a driver error
      function setAvgTime(self, AvgTime)
%             [slot, channel ] = self.switchDetector(1); %all detectors have the same averaging time; hack;
%             invoke(self.GroupObj.Powermetermodules, 'setpwmaveragingtime', slot, channel, AvgTime);
%             

            if AvgTime<self.minAveragingTime || AvgTime> self.maxAveragingTime
                errordlg(sprintf('Requested averaging time is out of range: \n Tmin = %f [s] and Tmax = %f [s]',...
                    self.minAveragingTime, self.maxAveragingTime), 'Entry Error', 'modal');
                AvgTime = self.minAveragingTime;
                disp(sprintf('Requested averaging time is out of range \n\t\t T_avg set to %f instead',self.minAveragingTime));
                %should also maybe put a uiwait....
            end
            
    
            try
                [~, ll] = size(self.PWMSlots);
                for ii = 1:ll
                    invoke(self.GroupObj.Utilitypassthrough, 'cmd',[':SENS',num2str(ii),':POW:ATIM ',num2str(AvgTime)]);
                    %there are only certain averaging times allowd. by
                    %using the SCPI commands it automatically sets it to
                    %the closest value.
%                     avgTime = invoke(self.GroupObj.Powermetermodules, 'getpwmaveragingtimeq',...
%                         self.PWMSlots(1,ii),1); %The averaging time cannot be set for the slave channel
                    disp(sprintf('Averaging time of Detectors in slot %u set to %f [ms]',ii,AvgTime*1000));
                end
                
            catch ME
                [InstrumentErrorCode, ErrorMessage]=invoke(this.GroupObj.Utility,'errorquery');
                disp(sprintf('Error returned from Mainframe:\n \t\t%s',ErrorMessage));
                rethrow(ME);
           end         
            
        
             
        end
        
        
                %maybe not necessary; stop logging functions
        function pwm_func_stop(self, DetectorNumber)
            [slot, channel]=self.switchDetector(DetectorNumber);
            invoke(self.GroupObj.Pwmdataaquisition,'pwmfunctionstop',...
                slot, channel);
        end
        
        
        %% Query slot info for sweep preparation
        function querySlotInfo(self)
     
       
            
            self.NumOfDetectors = 0; %reset the counter
            self.PWMSlotInfo = 0;
            self.PWMSlots = []; %array with slot numbers used
            slotInfo = zeros(1,3); %for 8163A should be 1x3 (for 8164 should be 1x5
            arraySize = 3; %from help file of driver : only valid for 8163A; for 8164 it should be 5.
            try
            slotInfo = invoke(self.GroupObj.Mainframespecific,...
                'getslotinformationq', arraySize, zeros(1,3));
            catch ME
                disp('Cannot query slot info of detector');
                rethrow(ME); 
                return
            end
            
            for ii=1:1:length(slotInfo)
                if slotInfo(ii)==2 || slotInfo(ii)==1
                    self.NumOfDetectors = self.NumOfDetectors + slotInfo(ii);
                    self.PWMSlotInfo = [self.PWMSlotInfo, slotInfo(ii)]; %not useful; legacy
                    self.PWMSlots(1,end+1) =  ii-1; %slot number
                    self.PWMSlots(2,end) = slotInfo(ii); %number of channels
                end
            end
            self.Slots=self.PWMSlots(2,:);  %legacy -> hack so it works
            
            self.SelectedDetectors = ones(1,self.NumOfDetectors); 
            
            disp(['Number of detectors found (# of channels): ', num2str(self.NumOfDetectors)]); 
            %As a return, Slot Information returns a one dimensional array.
            %Each component consists of the array component number and the
            %module type number. The array component number corresponds to
            %the slot number, starting at 0 and ending at the highest slot
            %numbe r. The following numbers define the module type number:
            %
            %             0  The slot is empty
            %             1  A single-channel Power Sensor
            %             2  A dual-channel Power Sensor
            %             3  A single Laser Source
            %             4  A dual-wavelength Laser Source
            %             5  A Tunable Laser module
            %             6  A Return Loss Module
            %             7  A Return Loss Combo Module
            
            
            
        end
 
        
        
        function val = getProp(self, prop)
            val = self.(prop);
        end
        
        function setProp(self, prop, val)
            self.(prop) = val;
        end
        
        function [triggerIn, triggerOut] = getTriggerConfiguration(self, slotNumber)
            [triggerIn, triggerOut] = invoke(...
                self.GroupObj.Powermetermodules, ...
                'getpwmtriggerconfiguration', ...
                slotNumber);
        end
        function sendParams(self)
            try
                for i = 1:self.NumOfDetectors
                    [slot, channel] = self.switchDetector(i);
                    % need to invoke all methods to write existing params
                    invoke(self.GroupObj.Powermetermodules, 'setpwmparameters', ...
                        slot,...
                        channel,...
                        self.Param.RangeMode,...
                        self.Param.PowerUnit,...
                        self.Param.InternalTrigger,...
                        self.nm2m(self.Param.PWMWvl),...
                        self.Param.AveragingTime,...
                        self.Param.PowerRange);
                    % these params are written when a sweep is setup
                    %   self.Param.Threshold = 0; %
                    %   self.Param.Clipping = 1; % 0=no, 1=yes
                    %   self.Param.ClipLimit = -100;
                end
            catch ME
                rethrow(ME);
            end
        end
        %         function [Pwr, Wvl] = getSweepData(self)
        %             % ------------------------------------------------------------
        %             % Start measurement
        %             % ------ This is the sweep in laser, need to be done separated
        %             % and obtain the data in detector only
        %             % Engine.StartMeasurement;
        %             % while (Engine.Busy)
        %             % pause(1)
        %             % end
        %             % ------------------------------------------------------------
        %             % Obtain sweep data measurement
        %             MeasurementResult = self.Engine.MeasurementResult;
        %             Graph = MeasurementResult.Graph('RXTXAvgIL');
        %             noChannels = Graph.noChannels;
        %             dataPerCurve = Graph.dataPerCurve;
        %             Pwr = reshape(Graph.YData, dataPerCurve, noChannels);
        %             Wvl = zeros(dataaPerCurve, self.NumOfDetectors);
        %             WvlStart = Graph.xStart;
        %             WvlStep = Graph.xStep;
        %             WvlStop = WvlStart + (dataPerCurve - 1)*WvlStep;
        %             for num = 1:self.NumOfDetectors
        %                 Wvl(:, num) = WvlStart:WvlStep:WvlStop;
        %             end
        %         end
        
        function  [Pwr, Wvl] = getSweepData(self)
            if self.ReadyForSweep
                % Data array is initialized
                for ii=1:self.NumOfDetectors
                    self.switchDetector(ii);
                    Pwr(:, ii) = zeros(1, self.DataPoints);
                    Wvl(:, ii) = zeros(1, self.DataPoints);
                    if (self.SelectedDetectors(ii))
                        [Pwr(:, ii), Wvl(:, ii)] = invoke(self.GroupObj.Multiframelambdascan, ...
                            'getlambdascanresult', ...
                            self.DetectorNumber, ...
                            self.Clipping, ...
                            self.ClipLimit, ...
                            zeros(1, self.DataPoints), ...
                            zeros(1, self.DataPoints));
                    end
                end
            else
                error('DetectorClass: Sweep not setup correctly.');
            end
            self.ReadyForSweep = 0; % reset flag
        end
    end
    
    methods (Access = private)
        
        function zeroDetectors(self)
            % Zeroing all detectors
            invoke(self.GroupObj.Powermetermodules, ...
                'pwmzeroingall', ...
                self.Obj);
        end
        

    end
end

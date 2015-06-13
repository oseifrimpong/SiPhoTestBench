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

classdef Detector_AgilentN7744A < InstrClass
    properties
        GroupObj;
    end
    properties (Access = protected)
        EngineMgr; % Engine Manager for the
        Engine;
        
        PauseTime; % so Matlab doesn't overrun the COM port
        % Properties
        laserObj;
        Slots;
        TotalSlots;
        NumOfSlots;
        NumOfDetectors;
        SelectedDetectors;
        TotalNumOfDetectors;
        SlotNumber; % Need to redefine
        ChannelNumber; % Need to redefine
        
        DetectorNumber; % Sofware label number of detector
        DetectorSwitchOffset;
        DetectorLabel; % Legend for figure
        Zeroed; % Flag for Zeroing detector bias
        Clipping; % 0=no, 1=yes
        ClipLimit;
        RangeDecrement; %for multiple scans with different range
        MaxDataPoints; % detector memory depth
        ReadyForSweep; % flag
        
        % structs/storage variables
        DataPoints; % length of Pwr and Wvl arrays, should get from detector or calc by sweep range/step
        Pwr; % Preallocate for speed
        Wvl;% Preallocate for speed
        MinWvl;
        MaxWvl;
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
        function self = Detector_AgilentN7744A()
            % Super Class - InstrClass properties
            self.Name = 'Agilent Detector N7744A';
            self.Group = 'Detector';
            self.Model = 'N7744A';
            self.CalDate = date;
            self.Busy = 0;
            self.Connected = 0;
            
            self.Slots = [];
            self.TotalSlots = [];
            self.NumOfSlots = 5;
            self.NumOfDetectors = 0; % Hard-coded for now;
            self.SelectedDetectors = [];
            self.TotalNumOfDetectors = 0;
            self.MaxDataPoints = 100000; %hard coded for now, needs to be queried
            
            self.SlotNumber = 0; % channel # in slot
            self.ChannelNumber = 0;% Sofware label number of detecto
            self.Zeroed = 0 ; % 0=no, 1=yes, Flag for Zeroing detector bias
            self.DetectorNumber = -1;
            self.DetectorSwitchOffset = 0;
            
            
            self.DataPoints = 1401;
            % Length of DataPoints Should Specified in congfid file from
            % Agilent Software and used in the future.
            
            
            % Parameters
            % self.Param.COMPort = 'USB0::2391::14104::my48101108::0::INSTR'; % UBC adress
            self.Param.COMPort = 'USB0::0x0957::0x3718::MY48102025::0::INSTR'; %UW address
            self.Param.AveragingTime = .0005; % s
            self.Param.RangeMode = 0; %1=auto, 0=manual, use Range val
            self.Param.PowerRange = -20; % dB
            self.Param.PowerUnit = 0; % dB=0, W=1
            self.Param.UpdatePeriod = 1; % update reading timer: 1s
            self.Param.PWMWvl = 1550;
            self.Param.WaitForCompletion = 0;
            self.Param.InternalTrigger = 1; % not sure what this does
            self.Param.Zeroing = 0; % Boolean to choose whether zero all detectors while connecting
            self.PauseTime = .01;
        end
        
        %         function self = connect(self)
        %             % Connect to Engine Manager
        %             self.EngineMgr = actxserver('AgServerFSIL.EngineMgr');
        %             % List all Engines currently running
        %             EngineIDs = self.EngineMgr.EngineIDs;
        %             % Always connect to first engine
        %             self.Engine = self.EngineMgr.OpenEngine(EngineIDs(1));
        %
        %         end
        
        %% connect method
        function self = connect(self, varargin)
            if nargin > 1 % check for existing HP laser and fast IL engine
                % get laser object handle and keep as class property
                
                % jonasf note: this if statment should not be here. This
                % way you are not able to connect to just the detector
                % withouth the laser.`
                self.laserObj = varargin{1};
                % check if fast IL engine is being used
%                 if ~self.laserObj.Param.UseFastILEngine
                    % register VXI P&P drivers
                    % open COM port and connect to physical instrument
                    USB_address = self.Param.COMPort;
                    % USB_address = 'USB0::0x0957::0x3718::my48101048::0::INSTR';  %UW address
                    % USB_address = 'USB0::2391::14104::my48101108::0::INSTR';  %UBC address
                    self.Obj = icdevice('hp816x_v4p2', USB_address);
                    try
                        connect(self.Obj);
                    catch ME
                        rethrow(ME);
                    end
                    % create handles to group functions
                    self.GroupObj.Multiframelambdascan = get(self.Obj, 'Applicationswavelengthscanfunctionsmultiframelambdascan');
                    self.GroupObj.Mainframespecific = get(self.Obj, 'Mainframespecific');
                    self.GroupObj.Pwmdataaquisition = get(self.Obj, 'Powermetermodulespwmdataacquisition');
                    self.GroupObj.Powermetermodules = get(self.Obj, 'Powermetermodules');
                    self.GroupObj.Utility = get(self.Obj, 'Utility');
                    % Zero all detectors
                    if self.Param.Zeroing
                        disp('Zeroing detectors');
                        self.zeroDetectors();
                    end
                    self.register();
                    self.querySlotInfo();
                    if nargin > 1
                        %Excludes the detectors plugged in the laser mainframe.
                        self.laserObj = varargin{1};
                        self.excludeDetectors();
                    end
%                 else % only create function handles needed for the fast IL
%                     self.GroupObj.Multiframelambdascan = get(self.Obj, 'Applicationswavelengthscanfunctionsmultiframelambdascan');
%                     self.GroupObj.Mainframespecific = get(self.Obj, 'Mainframespecific');
%                     self.GroupObj.Pwmdataaquisition = get(self.Obj, 'Powermetermodulespwmdataacquisition');
%                     self.GroupObj.Powermetermodules = get(self.Obj, 'Powermetermodules');
%                     self.GroupObj.Utility = get(self.Obj, 'Utility');
%                     self.querySlotInfo();
%                     if nargin > 1
%                         %Excludes the detectors plugged in the laser mainframe.
%                         self.laserObj = varargin{1};
%                         self.excludeDetectors();
%                     end                    
%                 end
            end
            
            %% code common to either method
            % Set Power Unit to dB
            self.setPWMPowerUnit(0);
            
            % self.queryPWMWvl();
            self.Pwr = zeros(self.DataPoints, 1);
            self.Wvl = zeros(self.DataPoints, 1);
            self.Connected = 1;
        end
        
        %% register method
        function self = register(self)
            % register mainframe
            invoke(self.GroupObj.Multiframelambdascan, 'registermainframe');
        end
        
        function reregisterPWMs(self)
            self.GroupObj.Powermetermodules = get(self.Obj, 'Powermetermodules');
        end
        
        %% zero PWMs
        function zeroAllPWMs(self)
            disp('Zeroing PWMs')
            [SummaryOfZeroingAllPWMs] = invoke(self.GroupObj.Powermetermodules('pwmzeroingall'))
        end
        
        function [slot, channel, self] = switchDetector(self, DetectorNumber)
            % Calculate the slot and channel number for detector
            slot = DetectorNumber;
            channel = 0;
            %
            self.SlotNumber = slot;
            self.ChannelNumber = channel;
            self.DetectorNumber = DetectorNumber + self.DetectorSwitchOffset;
        end
        
        function powerUnit = getPWMPowerUnit(self)
            powerUnit = self.Param.PowerUnit;
        end
        
        function setPWMPowerUnit(self, PowerUnit)
            % PowerUnit: 0 to dB, 1 to W
            for i = 1:self.NumOfDetectors
                [slot, channel] = self.switchDetector(i);
                invoke(self.GroupObj.Powermetermodules, 'setpwmpowerunit', ...
                    slot, channel, PowerUnit);
            end
            self.Param.PowerUnit = PowerUnit;
        end
        
        % Fetch single power value
        function powerVal = readPower(self, DetectorNumber)
            [slot, channel] = self.switchDetector(DetectorNumber);
            %             comparision to the "FETCH" command, the "READ"
            %             command implies triggering a measurement. Make sure the
            %             timeout set is greater than the adjusted averaging time, so that the
            %             READ command will not time out;
%             disp('<<<<<<<<<< in detector class >>>>>>>>>>');
%             disp('slot='); disp(num2str(slot));
%             disp('channel='); disp(num2str(channel));
            powerVal = invoke(self.GroupObj.Powermetermodules, 'pwmreadvalue', ...
                slot, channel);
%             disp('powerVal='); disp(num2str(powerVal));
                %disp('inside detector method');
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
                try
                    err = self.queryError();
                catch ME1
                    rethrow(ME1)
                end
                if err == -261
                    PowerValues(1:self.NumOfDetectors) = self.Param.ClipLimit;
                    return
                elseif err == -231
                    PowerValues(1:self.NumOfDetectors) = -self.Param.ClipLimit; %value questionable
                else
                    ex = MException(self.Name,...
                        strcat('Error Query returned: ',num2str(ex)));
                    throw(ex);
                end
            end
        end
        
        function self = setupSweep(self, numOfDataPoints)
            reset_to_default = 0;
            self.DataPoints = numOfDataPoints;
            self.GroupObj.Multiframelambdascan = get(self.Obj, 'Applicationswavelengthscanfunctionsmultiframelambdascan');
            for ii = 1:self.NumOfDetectors
                % Channel Number is always 0 for N7744A detector model
                current_channel = ii-1;
                invoke(self.GroupObj.Multiframelambdascan,'setinitialrangeparams', ...
                    current_channel,reset_to_default,self.Param.PowerRange, ...
                    self.RangeDecrement);
            end
            self.ReadyForSweep = 1;
        end
        
        
        %stop logging functions; gets called at beginning of mapping
        function pwm_func_stop(self, DetectorNumber)
            [slot, ~] = self.switchDetector(DetectorNumber);
            invoke(self.GroupObj.Pwmdataaquisition,'pwmfunctionstop',...
                slot, 0);
        end
        %Set up data logging if trigger set then the detectors waits for
        %trigger if not it starts recording right awy
        function [EstimatedTimeout] = start_pwm_logging(self, DetectorNumber)
            [slot, ~] = self.switchDetector(DetectorNumber);
            %channel number is always 0 ;
            [EstimatedTimeout] = invoke(self.GroupObj.Pwmdataaquisition,...
                'setpwmlogging',slot, 0, ...
                self.Param.AveragingTime, self.DataPoints);
        end
        
        function [LoggingConnected, LoggingResult] = get_pwm_logging(self,DetectorNumber)
            % Get data from scanning to the right
            self.switchDetector(DetectorNumber);
            LoggingResult = zeros(1, self.DataPoints);
            self.Param.PowerUnit = 0; %fixed to dBm
            [LoggingConnected, LoggingResult] = invoke(self.GroupObj.Pwmdataaquisition,...
                'getpwmloggingresultsq', self.SlotNumber, self.ChannelNumber, self.Param.WaitForCompletion,...
                self.Param.PowerUnit, LoggingResult);
        end
        
        function setup_trigger(self, TriggerIn, TriggerOut, DetectorNumber)
            %TriggerIn=2; %0:ignore 1:single (sme), 2:complete (cme)
            %TriggerOut=0; %0:disabled, 1:at the end, 3:at the beginning
            self.switchDetector(DetectorNumber);
            invoke(self.GroupObj.Powermetermodules, 'setpwmtriggerconfiguration', self.SlotNumber, ...
                TriggerIn, TriggerOut);
            [in, out] = invoke(self.GroupObj.Powermetermodules, 'getpwmtriggerconfiguration', self.SlotNumber);
        end
        
        % Returns details about a driver error
        function [errorNumber, errorMessage] = queryError(self)
            [errorNumber, errorMessage] = invoke(self.GroupObj.Utility, 'errorquery');
        end
        %% Query slot info for sweep preparation
        function querySlotInfo(self)
            try
                slotInfo = invoke(self.GroupObj.Mainframespecific, ...
                    'getslotinformationq', self.NumOfSlots, ...
                    zeros(1,self.NumOfSlots));
                self.NumOfDetectors = sum(slotInfo(2:end));
                self.Slots = slotInfo(2:end);
                self.SelectedDetectors = ones(1, self.NumOfDetectors);
            catch ME
                disp(ME.message);
                error('did not get slot info');
            end
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
        
        function excludeDetectors(self)
            laserMainFrameSlots = self.laserObj.getProp('PWMSlotInfo');
            laserMainFrameDetectors = self.laserObj.getProp('NumPWMChannels');
%             for detectorNum = 0:laserMainFrameDetectors - 1
%                 invoke(self.GroupObj.Multiframelambdascan, ...
%                     'excludechannel', ...
%                     detectorNum, ...
%                     1);
%             end
            self.TotalSlots = [laserMainFrameSlots, self.Slots];
            self.TotalNumOfDetectors = laserMainFrameDetectors + self.NumOfDetectors;
            self.laserObj.setProp('TotalSlots', self.TotalSlots);
            self.laserObj.setProp('TotalNumOfDetectors', self.TotalNumOfDetectors);
            self.DetectorSwitchOffset = laserMainFrameDetectors - 1;
        end
    end
end

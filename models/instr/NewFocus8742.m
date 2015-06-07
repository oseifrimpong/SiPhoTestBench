% © Copyright 2015 Shon Schmidt
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

classdef NewFocus8742 < InstrClass
    
%    properties (Access = protected)
    properties
        x;  % stage x position
        y;  % stage y position
        z;  % stage z position
        xRotation; % rotation about x axis
        zRotation; % rotation about z axis
        
%        fullDistance;
%        calibrated;  % stage calibrated
%        overshoot;
%        pauseTime;
%        timeout;
        
        % new stuff for 8742
        strDeviceKeys; % str all the connected device keys
        masterAddr; % str master device ID
        slaveDeviceKey; 
        slaveAddr; 
        masterDeviceKey; 
        CmdLib8742; % .NET object
    end
    
    methods
        % constructor
        function self = NewFocus8742()
            self.Name = 'NewFocus8742';
            self.Group = 'Fiber Stage';
            self.Connected = 0;  % 0=not connected, 1=connected
            self.Busy = 0;
%            self.calibrated = 0;
            self.CmdLib8742 = ' ';  % .NET assembly object
            % motor settings shared by Corvus Eco
            self.Param.Acceleration = 0;
            self.Param.Velocity = 0;
            self.Param.StepResolution = 0;            
%             self.pauseTime = 0.08;
%             self.timeout = 10; % s
%             self.overshoot = 0.02; % copied from Corvus Eco
            % stage positions
            self.x = nan;
            self.y = nan;
            self.z = nan;
            self.xRotation = nan;
            self.zRotation = nan;
            % Stage Params
%            self.fullDistance = 12.5*1000;
%            self.pauseTime = 0.5; % 0.5 sec     
        end
    end
    
    methods
        function self = connect(self)
            % checks is stage is already connected
            if self.Connected == 1
                msg = 'Fiber Stage is already connected';
                error(msg);
            end
            
            % load .NET assembly
            disp('Loading NewFocus8742 .NET assembly. Please wait.');
            try
                NET.addAssembly('C:\Program Files (x86)\New Focus\New Focus Picomotor Application\Samples\CmdLib.dll');
                disp('NewFocus8742 .NET assembly loaded.');
            catch ME
                error(ME.message);
            end
            % instantiate object (.NET assembly)
            self.strDeviceKeys = 'dummy';
            self.CmdLib8742 = NewFocus.Picomotor.CmdLib8742(true,10000,self.strDeviceKeys);
            % -> returns CmdLib8742 with no properties
            
            
            
            % Get device keys; returns System.String[]
            self.strDeviceKeys = self.CmdLib8742.GetDeviceKeys;
%            disp(self.strDeviceKeys);
            
            if isempty(self.strDeviceKeys)
                disp('8742 not connected. Aborting.');
                return
            end
            
            [~, sellf.masterAddr]= GetIdentification(self.CmdLib8742, self.strDeviceKeys(1),'dummy');
            %[logical scalar RetVal, System.String identificaiton] = ....
            % -> returns: New_Focus 8742 v2.2 08/01/13 12175
%            disp(self.masterAddr);
            
            %get key of master; 
            self.masterDeviceKey = self.CmdLib8742.GetFirstDeviceKey;
%            disp(self.masterDeviceKey);
            % -> returns: 8742 12175

            %get all the slave device addresses; saved in a System.int32[] structure
            deviceAddresses = GetDeviceAddresses(self.CmdLib8742, self.masterDeviceKey);
            self.slaveAddr = deviceAddresses(1);
%            disp(self.slaveAddr);
            
            %get identification of slave
            [~, self.slaveDeviceKey] = GetIdentification(self.CmdLib8742,...
                self.masterDeviceKey, self.slaveAddr, 'as');
            % -> returns: New_Focus 8742 v2.2 08/01/13 12167    
%            disp(self.slaveDeviceKey);
            
            % need to somehow very that we're connected
            self.Connected = 1;            

            % read instrument parameters into params
%clo            self.getInstrumentParameters();            
        end
        
        function self = disconnect(self)
            if self.Connected == 0
                msg = strcat(self.Name,':not connected');
                error(msg);
            end
            
            try
            % can't unload .NET CmdLib (read forums)
            catch ME
                error(ME.message);
            end
            
            self.Connected = 0;
        end
        
        % shon 24 May 2015
        function self = getInstrumentParameters(self)
            if self.Connected == 0
                msg = strcat(self.Name,':not connected');
                error(msg);
            end
            
            try
                % for now, set all motors to same parameter set
                % read from master device, motor 1 (C)
                stepsPerSec2 = 0;
                self.Param.Acceleration = self.CmdLib8742.GetAcceleration(...
                    self.masterDeviceKey, int32(1), int32(stepsPerSec2));
                
%                 stepResolution = 0;
%                 self.Param.StepResolution = self.CmdLib8742.GetCLStepResolution(...
%                     self.masterDeviceKey, int32(1), int32(stepResolution));
%                 
%                 threshold = 0;
%                 self.Param.Acceleration = self.CmdLib8742.GetCLThreshold(...
%                     self.masterDeviceKey, int32(1), int32(threshold));
%                 
%                 units = 0;
%                 self.Param.Acceleration = self.CmdLib8742.GetCLUnits(...
%                     self.masterDeviceKey, int32(1), int32(units));
                
            catch ME
                error(ME.message);
            end
            
            self.Connected = 0;
        end
        
        %% shon notes for myself based on current connections

        % master 1 = C
        % master 2 = B
        % master 3 = A
        % master 4 = n/a
        % slave 1 = n/a
        % slave 2 = B'
        % slave 3 = A'
        % slave 4 = n/a
        
        % z = +A' +B' or -A' -B'
        % zRotation = +A -B or +B -A
        % x = +A +B or -A -B
        % xRotation = +A -B or -A +B
        % y = +C or -C
        

        
        function abortMotion(self)
            % hack = send abort command to both master and slave
            self.CmdLib8742.AbortMotion(self.masterDeviceKey);
            self.CmdLib8742.AbortMotion(self.masterDeviceKey,self.slaveAddr);            
        end
        
        % shon: need to verify
        function velocityStepsPerSec = getVelocity(self, deviceKey, deviceAddress, motorNumber)
            stepsPerSec = 0;
            velocityStepsPerSec = self.CmdLib8742.GetVelocity(deviceKey, ...
                deviceAddress, motorNumber, int32(stepsPerSec));
        end
        
        % shon: need to verify
        function setVelocity(self, deviceKey, deviceAddress, motorNumber, stepsPerSec)
            try
                self.CmdLib8742.SetVelocity(deviceKey, ...
                    deviceAddress, motorNumber, int32(stepsPerSec));
            catch ME
                rethrow(ME);
            end
        end
        
        % shon: need to verify
        function velocityStepsPerSec = getAcceleration(self, deviceKey, deviceAddress, motorNumber)
            stepsPerSec2 = 0;
            velocityStepsPerSec = self.CmdLib8742.GetAcceleration(deviceKey, ...
                deviceAddress, motorNumber, int32(stepsPerSec2));
        end
        
        % shon: need to verify
        function setAcceleration(self, deviceKey, deviceAddress, motorNumber, stepsPerSec2)
            try
                self.CmdLib8742.SetAcceleration(deviceKey, ...
                    deviceAddress, motorNumber, int32(stepsPerSec2));
            catch ME
                rethrow(ME);
            end
        end
        
        %% move functions
        function self = move_y(self, distance)
            % to move + in y = +A and +B
            % to move - in y = -A and -B
            if self.Connected
                % disable button in GUI
                
                % convert distance to steps
%                accurateDistance = self.offsetDistance(distance);
                
                % move A (master device motor #3)
%                disp('moving motor A');
                self.CmdLib8742.RelativeMove(self.masterDeviceKey, ...
                    int32(3), distance);
                
                % wait for motor to finish moving before moving other motor
                isMotionDone = false; % to satisfy .NET function call only
                isDone = 0;
                while ~isDone
                    [~, isDone] = self.CmdLib8742.GetMotionDone(self.masterDeviceKey, ...
                    int32(3), isMotionDone);
                   pause(0.1);
                end
                
                % move B (master device motor #2)
%                disp('moving motor B');
                self.CmdLib8742.RelativeMove(self.masterDeviceKey, ...
                    int32(2), distance);

            else
                msg = strcat(self.Name, ' not connected.');
                error(msg);
            end
        end
        
        function self = move_x(self, distance)
            % to move + in x = C
            % to move - in x = -C
            if self.Connected
                % disable button in GUI
                
                % convert distance to steps
%                accurateDistance = self.offsetDistance(distance);
                
                % move A' (master device motor #1)
%                disp('moving motor Aprime');
                self.CmdLib8742.RelativeMove(self.masterDeviceKey, ...
                    int32(1), distance);

                % wait for motor to finish
                isMotionDone = false; % to satisfy .NET function call only
                isDone = 0;
                while ~isDone
                    [~, isDone] = self.CmdLib8742.GetMotionDone(self.masterDeviceKey, ...
                    int32(1), isMotionDone);
                   pause(0.1);
                end
                
            else
                msg = strcat(self.Name, ' not connected.');
                error(msg);
            end
        end
        
        function self = move_z(self, distance)
            % to move + in z = +A' and +B'
            % to move - in z = -A' and -B'
            if self.Connected
                % disable button in GUI
                
                % convert distance to steps
%                accurateDistance = self.offsetDistance(distance);
                
                % move A' (slave device motor #3)
%                disp('moving motor Aprime');
                self.CmdLib8742.RelativeMove(self.masterDeviceKey, ...
                    self.slaveAddr, int32(3), distance);

                % wait for motor to finish moving before moving other motor
                isMotionDone = false; % to satisfy .NET function call only
                isDone = 0;
                while ~isDone
                    [~, isDone] = self.CmdLib8742.GetMotionDone(self.masterDeviceKey, ...
                    self.slaveAddr, int32(3), isMotionDone);
                   pause(0.1);
                end
                
%                disp('moving motor Bprime');
                % move B' (slave device motor #2)
                self.CmdLib8742.RelativeMove(self.masterDeviceKey, ...
                    self.slaveAddr, int32(2), distance);
            else
                msg = strcat(self.Name, ' not connected.');
                error(msg);
            end
        end
        
        function self = move_xRotation(self, degrees)
            % to move + in xRotation = +A' and -B'
            % to move - in xRotation = -A' and +B'
            if self.Connected
                % disable button in GUI
                
                % convert distance to steps
%                accurateDistance = self.offsetDistance(distance);
                
                % move A' (slave device motor #3)
%                disp('moving motor Aprime');                
                self.CmdLib8742.RelativeMove(self.masterDeviceKey, ...
                    self.slaveAddr, int32(3), degrees);
                
                % wait for motor to finish moving before moving other motor
                isMotionDone = false; % to satisfy .NET function call only
                isDone = 0;
                while ~isDone
                    [~, isDone] = self.CmdLib8742.GetMotionDone(self.masterDeviceKey, ...
                    self.slaveAddr, int32(3), isMotionDone);
                   pause(0.1);
                end
                
                % move B (master device motor #2)
%                disp('moving motor Bprime');                
                % move B' (slave device motor #2)
                self.CmdLib8742.RelativeMove(self.masterDeviceKey, ...
                    self.slaveAddr, int32(2), -degrees);
            else
                msg = strcat(self.Name, ' not connected.');
                error(msg);
            end
        end
        
        function self = move_zRotation(self, degrees)
            % to move + in zRotation = +A and -B
            % to move - in zRotation = -A and +B
            if self.Connected
                % disable button in GUI
                
                % convert distance to steps
%                accurateDistance = self.offsetDistance(distance);
                
                % move A (master device motor #3)
%                disp('moving motor B');                
                self.CmdLib8742.RelativeMove(self.masterDeviceKey, ...
                    int32(3), degrees);
                
                % wait for motor to finish moving before moving other motor
                isMotionDone = false; % to satisfy .NET function call only
                isDone = 0;
                while ~isDone
                    [~, isDone] = self.CmdLib8742.GetMotionDone(self.masterDeviceKey, ...
                    int32(3), isMotionDone);
                   pause(0.1);
                end
                
                % move B (master device motor #2)
%                disp('moving motor B');                
                % move B (master device motor #2)
                self.CmdLib8742.RelativeMove(self.masterDeviceKey, ...
                    int32(2), -degrees);
            else
                msg = strcat(self.Name, ' not connected.');
                error(msg);
            end
        end
    end
end

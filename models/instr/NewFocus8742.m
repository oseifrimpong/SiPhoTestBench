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
        xPos;  % stage x position
        yPos;  % stage y position
        zPos;  % stage z position
        thetaPos; % stage angle position
        phiPos; % fiber angle position
        fullDistance;
        calibrated;  % stage calibrated
        overshoot;
        pauseTime;
        timeout;
        
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
            self.calibrated = 0;
            self.CmdLib8742 = ' ';  % .NET assembly object
            % motor settings shared by Corvus Eco
            self.Param.Acceleration = 0;
            self.Param.Velocity = 0;
            self.pauseTime = 0.08;
            self.timeout = 10; % s
            self.overshoot = 0.02; % copied from Corvus Eco
            % stage positions
            self.xPos = nan;
            self.yPos = nan;
            self.zPos = nan;
            self.thetaPos = nan;
            self.phiPos = nan;
            % Stage Params
            self.fullDistance = 12.5*1000;
            self.pauseTime = 0.5; % 0.5 sec
            
            % load .NET assembly
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
        end
    end
    
    methods
        function self = connect(self)
            % checks is stage is already connected
            if self.Connected == 1
                msg = 'Fiber Stage is already connected';
                error(msg);
            end
            
            % Get device keys; returns System.String[]
            self.strDeviceKeys = self.CmdLib8742.GetDeviceKeys;
            disp(self.strDeviceKeys);
            
            [~, sellf.masterAddr]= GetIdentification(self.CmdLib8742, self.strDeviceKeys(1),'dummy');
            %[logical scalar RetVal, System.String identificaiton] = ....
            % -> returns: New_Focus 8742 v2.2 08/01/13 12175
            disp(self.masterAddr);
            
            %get key of master; 
            self.masterDeviceKey = self.CmdLib8742.GetFirstDeviceKey;
            disp(self.masterDeviceKey);
            % -> returns: 8742 12175

            %get all the slave device addresses; saved in a System.int32[] structure
            self.slaveAddr = GetDeviceAddresses(self.CmdLib8742, self.masterDeviceKey);
            disp(self.slaveAddr);
            
            %get identification of slave
            [~, self.slaveDeviceKey] = GetIdentification(self.CmdLib8742,...
                self.masterDeviceKey, self.slaveAddr(1), 'as');
            % -> returns: New_Focus 8742 v2.2 08/01/13 12167    
            disp(self.slaveDeviceKey);
            
            % need to somehow very that we're connected
            self.Connected = 1;            
        end
        
        function self = disconnect(self)
            % check if stage is connected
            if self.Connected == 0
                msg = strcat(self.Name,':not connected');
                error(msg);
            end
            
            % try to close connection and delete CmdLib8742 object
            try
            catch ME
                error(ME.message);
            end
            
            self.Connected = 0;
        end
        
        function self = reset(self)
            if self.Connected
                msg = strcat(self.Name, ':reset method not implemented');
                error(msg);
            end
        end
        
        function self = send_command(self, command)
        end
        
        function response = read_response(self)
            response = '';
            if ~self.Connected
                err = MException(strcat(self.Name,':Read'),...
                    'optical stage status: closed');
                throw(err);
            end
            start_time = tic;
            while toc(start_time) < self.timeout
                if self.Obj.BytesAvailable > 0
                    response = fscanf(self.Obj);
                    break
                else
                    pause(self.pauseTime);
                end
            end
            if toc(start_time) >= self.timeout
                err = MException(strcat(self.Name,':Readtimeout'),...
                    'optical stage connection timed out');
                throw(err);
            end
        end
        
        function waitForCommand(self)
            startTime = tic;
            while (~self.Obj.BytesAvailable && toc(startTime) < self.timeout)
                pause(self.pauseTime);
            end
            
            if toc(startTime) >= self.timeout
                err = MException(strcat(self.Name,':WaitForCommand'),...
                    'optical stage connection timed out');
                throw(err);
            end
        end
        
        function self = calibrate(self)
            if self.Connected
                self.Busy = 1;
                self.calibrated = 1;
                self.xPos = 0;
                self.yPos = 0;
                self.zPos = 0;
                choose_x_motor = '1MX5'; % xxMX selects the switchbox channel for controler xx
                choose_y_motor = '1MX4';
                choose_z_motor = '1MX3';
                set_zero_position = '1OR'; % xxOR sets controller xx's motor position to 0
                self.send_command(choose_x_motor);
                self.send_command(set_zero_position);
                self.send_command(choose_y_motor);
                self.send_command(set_zero_position);
                self.send_command(choose_z_motor);
                self.send_command(set_zero_position);
                self.Busy = 0;
            else
                msg = strcat(self.Name, ' not connected.');
                error(msg);
            end
        end
        
        function [x,y,z] = getPosition(self)
            %             if self.calibrated
            x = self.xPos;
            y = self.yPos;
            z = self.zPos;
            %                 disp(strcat('Y position ', num2str(x)));
            %                 disp(strcat('X position ', num2str(y)));
            %                 disp(strcat('Z position ', num2str(z)));
            %             else
            %                 msg = strcat(self.Name, ' not calibrated. Cannot get position.');
            %                 error(msg);
            %             end
        end
        
        function motion = queryMotion(self)
            if self.Connected
                pause(self.pauseTime)
                %                queryMsg = '1TS?';
                %                self.send_command(queryMsg);
                %                response = self.read_response();
                %                response = strtrim(response);
                %                motion = response(end)
                self.send_command('1PH?'); pause(self.pauseTime);
                self.send_command('1TS?'); pause(self.pauseTime);
                self.send_command('1TP?'); pause(self.pauseTime);
                
            end
        end
        
        function motorQuery = queryMotionMotor(self)
            if self.Connected
                pause(self.pauseTime);
                self.send_command('1MX?'); pause(self.pauseTime);
                queryMsg = '1TP?';%'1MX?';%'1ID?';
                self.send_command(queryMsg);
                response = self.read_response();
                response = strtrim(response);
                motorQuery = response(end);
                %pause(self.pauseTime);
            end
        end
        
        function self = move_x(self, distance)
            if self.Connected
                accurateDistance = self.offsetDistance(distance);
                
                self.Busy = 1;
                motor_on = '1MO';  %turns on controller 1's motors
                choose_motor = '1MX5';  %selects controller 1, motor 1
                % NANO PC move in micro-step roughly equals to 10nm/step.
                % tranform distance (in um) into micro-step (X100)
                %                     move_cmd = ['1PR', num2str(distance*100)];  %moves selected motor the input number of micro steps
                % the *100 converts from ustep(default unit) to um
                motor_off = '1MF';  %turns off controller 1's motors
                
                clc
                self.send_command(motor_on); %Switch motor on
                pause(self.pauseTime);
                
                self.send_command(choose_motor);
                pause(self.pauseTime);
                if ~self.queryMotionMotor() == 5
                    pause(.5);
                else
                    pause(self.pauseTime);
                end
                
                % Vince edit here: move accurate distance
                for dd = 1:length(accurateDistance)
                    move_cmd = ['1PR', num2str(accurateDistance(dd))];
                    self.send_command(move_cmd);
                    pause(abs(accurateDistance(dd))/500+2.5*self.pauseTime);
                end
                
                self.send_command(motor_off);
                %self.queryMotion();
                
                disp('x move complete')
                self.xPos = self.xPos + distance*100;
                self.Busy = 0;
                %                     self.send_command(move_cmd);
                % %                     self.send_command(motor_off);  %recommended to avoid actuator drift while switching channels
                %                     self.xPos = self.xPos + distance*100;
                %                     self.Busy = 0;
                %                 else
                %                     msg = strcat(self.Name, ' not calibrated. Please calibrate before moving.');
                %                     error(msg);
                %                 end
%                     self.send_command(motor_off);  %recommended to avoid actuator drift while switching channels
                    self.xPos = self.xPos + distance*100;
                    self.Busy = 0;
%                 else
%                     msg = strcat(self.Name, ' not calibrated. Please calibrate before moving.');
%                     error(msg);
%                 end
            else
                msg = strcat(self.Name, ' not connected.');
                error(msg);
            end
        end
        
        function self = move_y(self, distance)
            if self.Connected
                
                %                 self.send_command('1TP2?');
                %                 while self.Obj.BytesAvailable <= 0
                %                     if self.Obj.BytesAvailable > 0
                %                         dd = fscanf(self.Obj, '%s', self.Obj.BytesAvailable)
                %                     end
                %                 end
                %
                
                %                 if self.calibrated
                accurateDistance = self.offsetDistance(distance);
                
                self.Busy = 1;
                motor_on = '1MO';
                choose_motor = '1MX4';  %selects controller 1, motor 2
                % NANO PC move in micro-step roughly equals to 10nm/step.
                % tranform distance (in um) into micro-step (X100)
                %                     move_cmd = ['1PR', num2str(-distance*100)];  % the *100 converts from ustep(default unit) to um
                %                    move_cmd = ['1PR', num2str(distance*100)]  % the *100 converts from ustep(default unit) to um
                motor_off = '1MF';
                
                clc
                self.send_command(motor_on); %Switch motor on
                pause(self.pauseTime);
                
                
                self.send_command(choose_motor);
                pause(self.pauseTime);
                if ~self.queryMotionMotor() == 6
                    pause(.5);
                else
                    pause(self.pauseTime);
                end
                
                % Vince edit here: move accurate distance
                for dd = 1:length(accurateDistance)
                    move_cmd = ['1PR', num2str(-accurateDistance(dd))];
                    self.send_command(move_cmd);
                    pause(abs(accurateDistance(dd))/500+2.5*self.pauseTime);
                end
                
                self.send_command(motor_off);
                %self.queryMotion();
                
                disp('y move complete')
                
                self.yPos = self.yPos + distance*100;
                self.Busy = 0;
                %                     self.send_command(move_cmd);
                % %                     self.send_command(motor_off);
                %                     self.yPos = self.yPos + distance*100;
                %                     self.Busy = 0;
                %                 else
                %                     msg = strcat(self.Name, ' not calibrated. Please calibrate before moving.');
                %                     error(msg);
                %                 end
                
                %                 self.send_command('1TP2?');
                %                 while self.Obj.BytesAvailable <= 0
                %                     if self.Obj.BytesAvailable > 0
                %                         dd = fscanf(self.Obj, '%s', self.Obj.BytesAvailable)
                %                     end
                %                 end
%                 self.send_command('1TP2?');
%                 while self.Obj.BytesAvailable <= 0
%                     if self.Obj.BytesAvailable > 0
%                         dd = fscanf(self.Obj, '%s', self.Obj.BytesAvailable)
%                     end
%                 end
%                 
                
%                 if self.calibrated
                    self.Busy = 1;
                    motor_on = '1MO';
                    choose_motor = '1MX2';  %selects controller 1, motor 2
                    move_cmd = ['1PR', num2str(distance*100)]  % the *100 converts from ustep(default unit) to um
                    motor_off = '1MF';
                    self.send_command(motor_on);
                    self.send_command(choose_motor);
                    self.send_command(move_cmd);
%                     self.send_command(motor_off);
                    self.yPos = self.yPos + distance*100;
                    self.Busy = 0;
%                 else
%                     msg = strcat(self.Name, ' not calibrated. Please calibrate before moving.');
%                     error(msg);
%                 end

%                 self.send_command('1TP2?');
%                 while self.Obj.BytesAvailable <= 0
%                     if self.Obj.BytesAvailable > 0
%                         dd = fscanf(self.Obj, '%s', self.Obj.BytesAvailable)
%                     end
%                 end
                
            else
                msg = strcat(self.Name, ' not connected.');
                error(msg);
            end
        end
        
        function self = move_z(self, distance)
            if self.Connected
                %                 if self.calibrated
                accurateDistance = self.offsetDistance(distance);
                
                self.Busy = 1;
                motor_on = '1MO';
                choose_motor = '1MX3';  %selects controller 1, motor 3
                % NANO PC move in micro-step roughly equals to 10nm/step.
                % tranform distance (in um) into micro-step (X100)
                %                     move_cmd = ['1PR', num2str(-distance*100)]; %jtk change to 'minus'
                % the *100 converts from ustep(default unit) to um
                motor_off = '1MF';
                %self.send_command(motor_on);
                
                clc
                self.send_command(motor_on); %Switch motor on
                pause(self.pauseTime);
                
                
                self.send_command(choose_motor);
                pause(self.pauseTime);
                if ~self.queryMotionMotor() == 3
                    pause(.5);
                else
                    pause(self.pauseTime);
                end
                
                % Vince edit here: move accurate distance
                for dd = 1:length(accurateDistance)
                    move_cmd = ['1PR', num2str(-accurateDistance(dd))];
                    self.send_command(move_cmd);
                    pause(abs(accurateDistance(dd))/500+2.5*self.pauseTime);
                end
                
                self.send_command(motor_off);
                %self.queryMotion();
                
                disp('z move complete')
                
                self.yPos = self.yPos + distance*100;
                self.Busy = 0;
                %                     self.send_command(move_cmd);
                % %                     self.send_command(motor_off);
                %                     self.zPos = self.zPos + distance*100;
                %                     self.Busy = 0;
                %                 else
                %                     msg = strcat(self.Name, ' not calibrated. Please calibrate before moving.');
                %                     error(msg);
                %                 end
            else
                msg = strcat(self.Name, ' not connected.');
                error(msg);
            end
        end
        
        function self = move_stgangle(self, degrees)
            if self.Connected
                %                 if self.calibrated
                self.Busy = 1;
                motor_on = '1MO';
                choose_motor = '1MX4';  %selects controller 1, motor 3
                % NANO PC move in micro-step roughly equals to 10nm/step.
                % tranform distance (in um) into micro-step (X100)
                move_cmd = ['1PR', num2str(degrees*5000)]; %jtk change to 'minus'
                % the *100 converts from ustep(default unit) to um
                motor_off = '1MF';
                %self.send_command(motor_on);
                
                self.send_command(motor_on); %Switch motor on
                pause(self.pauseTime);
                
                
                self.send_command(choose_motor);
                pause(self.pauseTime);
                if ~self.queryMotionMotor() == 4
                    pause(.5);
                else
                    pause(self.pauseTime);
                end
                
                self.send_command(move_cmd);
                pause(abs(degrees)+2.5*self.pauseTime);
                
                self.send_command(motor_off);
                %self.queryMotion();
                
                disp('stg angle move complete')
                
                self.thetaPos = self.thetaPos + degrees*5000;
                self.Busy = 0;
                %                 else
                %                     msg = strcat(self.Name, ' not calibrated. Please calibrate before moving.');
                %                     error(msg);
                %                 end

%                     self.send_command(motor_off);
                    self.zPos = self.zPos + distance*100;
                    self.Busy = 0;
%                 else
%                     msg = strcat(self.Name, ' not calibrated. Please calibrate before moving.');
%                     error(msg);
%                 end
            else
                msg = strcat(self.Name, ' not connected.');
                error(msg);
            end
        end
        
        function self = move_fbrangle(self, degrees)
            if self.Connected
                %                 if self.calibrated
                self.Busy = 1;
                motor_on = '1MO';
                choose_motor = '1MX5';  %selects controller 1, motor 3
                % NANO PC move in micro-step roughly equals to 10nm/step.
                % tranform distance (in um) into micro-step (X100)
                move_cmd = ['1PR', num2str(degrees*5000)]; %jtk change to 'minus'
                % the *100 converts from ustep(default unit) to um
                motor_off = '1MF';
                %self.send_command(motor_on);
                
                clc
                self.send_command(motor_on); %Switch motor on
                pause(self.pauseTime);
                
                
                self.send_command(choose_motor);
                pause(self.pauseTime);
                if ~self.queryMotionMotor() == 5
                    pause(.5);
                else
                    pause(self.pauseTime);
                end
                
                self.send_command(move_cmd);
                pause(abs(degrees)/5+2.5*self.pauseTime);
                
                self.send_command(motor_off);
                %self.queryMotion();
                
                disp('fiber angle move complete')
                
                self.phiPos = self.phiPos + degrees*100;
                self.Busy = 0;
                %                 else
                %                     msg = strcat(self.Name, ' not calibrated. Please calibrate before moving.');
                %                     error(msg);
                %                 end
            else
                msg = strcat(self.Name, ' not connected.');
                error(msg);
            end
        end
        
        function eject(self)
            self.move_z(-self.fullDistance);
            pause(self.pauseTime);
            self.move_x(self.fullDistance);
            pause(self.pauseTime);
            self.move_y(self.fullDistance);
            
            self.xPos = 0;
            self.yPos = 0;
            self.zPos = 0;
        end
        
        function load(self)
            self.move_x(-self.fullDistance/2);
            pause(self.pauseTime);
            self.move_y(-self.fullDistance/2);
            %             pause(self.pauseTime);
            %             self.move_z(self.fullDistance/2);
        end
        
        %         function position = currentPosition(self)
        %
        %         end
    end
    
    methods (Static)
        % Vince edit here: calculate accurate distance for
        % input distance >= 1.92um (system round up distance >= 192ustep)
        function accurateDistance = offsetDistance(distance)
            if distance >= 1.92 % 1.92 um = 192 ustep - System limitation
                fullSteps = floor(distance*100/16);
                offsetStep = mod(distance*100, 16);
                accurateDistance = [fullSteps*16, offsetStep];
            else
                accurateDistance = distance*100;
                % Transform into 1 ustep = 10nm
            end
        end
        function position = currentPosition(self)
            
        end
    end
end

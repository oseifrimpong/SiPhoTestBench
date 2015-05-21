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
    
    % NanoPZ linear actuator user manual available online at:
    % http://assets.newport.com/webDocuments-EN/images/20619.pdf
    % Victor Bass 2013
    
    properties (Access = protected)
        xPos;  % stage x position
        yPos;  % stage y position
        zPos;  % stage z position
        thetaPos; % stage angle position
        phiPos; % fiber angle position
        fullDistance;
        Calibrated;  % stage calibrated
        Overshoot;
        PauseTime;
        Timeout;
    end
    
    methods
        % constructor
        function self = NewFocus8742()
            self.Name = 'NewFocus8742';
            self.Group = 'Edge Coupled Fiber Stage';
            self.Connected = 0;  % 0=not connected, 1=connected
            self.Busy = 0;
            self.Calibrated = 0;
            self.Obj = ' ';  % serial port object
            % serial port connection properties
            self.Param.COMPort = 3;
            self.Param.BaudRate = 19200;
            % motor settings shared by Corvus Eco
            self.Param.Acceleration = 0;
            self.Param.Velocity = 0;
            self.PauseTime = 0.08;
            self.Timeout = 10; % s
            self.Overshoot = 0.02; % copied from Corvus Eco
            % stage positions
            self.xPos = nan;
            self.yPos = nan;
            self.zPos = nan;
            self.thetaPos = nan;
            self.phiPos = nan;
            % Stage Params
            self.fullDistance = 12.5*1000;
        end
    end
    
    methods
        function self = connect(self)
            % checks is stage is already connected
            if self.Connected == 1
                msg = 'Optical Stage is already connected';
                error(msg);
            end
            % set serial port properties
            self.Obj = serial(['COM', num2str(self.Param.COMPort)]);
            set(self.Obj,'BaudRate',self.Param.BaudRate);
            % try to open the connection
            try
                fopen(self.Obj);
            catch ME
                rethrow(ME);
            end
            % tell user optical stage is connected
            if strcmp(self.Obj.Status, 'open')
                self.Connected = 1;
                disp('NanoPZ connected');
            end
            
            %initialization commands
            self.send_command('0VE?'); pause(1);
            self.send_command('1VE?'); pause(1);
            self.send_command('1BX?'); pause(1);
            self.send_command('1BX'); %scan switchbox
            pause(3);
            
            %NanoPZ initialization query
            self.send_command('1TE?'); pause(self.PauseTime);
            self.send_command('1BX?'); pause(self.PauseTime);
            self.send_command('1MX?'); pause(self.PauseTime);
            self.send_command('1ID?'); pause(self.PauseTime);
            self.send_command('1PH?'); pause(self.PauseTime);
            self.send_command('1TS?'); pause(self.PauseTime);
            self.send_command('1TP?'); pause(self.PauseTime);
            self.send_command('1MX?'); pause(self.PauseTime);
            
        end
        
        function self = disconnect(self)
            % check if stage is connected
            if self.Connected == 0
                msg = strcat(self.Name,':not connected');
                error(msg);
            end
            
            % try to close connection and delete serial port object
            try
                fclose(self.Obj);
                delete(self.Obj);
            catch ME
                error(ME.message);
            end
            
            self.Connected = 0;
        end
        
        function self = reset(self)
            if self.Connected
                if self.Busy
                    self.stop;
                    self.Busy = 0;
                end
            else
                msg = strcat(self.Name, ':not connected');
                error(msg);
            end
        end
        
        function self = send_command(self, command)
            if self.Obj.BytesAvailable > 0
                m = fscanf(self.Obj, '%s', self.Obj.BytesAvailable);
            end
            
            if strcmp(self.Obj.Status, 'open')
                fprintf(self.Obj, command);
            else
                msg = strcat(self.Name, ':not connected');
                error(msg);
            end
        end
        
        function response = read_response(self)
            response = '';
            if ~self.Connected
                err = MException(strcat(self.Name,':Read'),...
                    'optical stage status: closed');
                throw(err);
            end
            start_time = tic;
            while toc(start_time) < self.Timeout
                if self.Obj.BytesAvailable > 0
                    response = fscanf(self.Obj);
                    break
                else
                    pause(self.PauseTime);
                end
            end
            if toc(start_time) >= self.Timeout
                err = MException(strcat(self.Name,':ReadTimeOut'),...
                    'optical stage connection timed out');
                throw(err);
            end
        end
        
        function waitForCommand(self)
            startTime = tic;
            while (~self.Obj.BytesAvailable && toc(startTime) < self.Timeout)
                pause(self.PauseTime);
            end
            
            if toc(startTime) >= self.Timeout
                err = MException(strcat(self.Name,':WaitForCommand'),...
                    'optical stage connection timed out');
                throw(err);
            end
        end
        
        function self = calibrate(self)
            if self.Connected
                self.Busy = 1;
                self.Calibrated = 1;
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
            %             if self.Calibrated
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
                pause(self.PauseTime)
                %                queryMsg = '1TS?';
                %                self.send_command(queryMsg);
                %                response = self.read_response();
                %                response = strtrim(response);
                %                motion = response(end)
                self.send_command('1PH?'); pause(self.PauseTime);
                self.send_command('1TS?'); pause(self.PauseTime);
                self.send_command('1TP?'); pause(self.PauseTime);
                
            end
        end
        
        function motorQuery = queryMotionMotor(self)
            if self.Connected
                pause(self.PauseTime);
                self.send_command('1MX?'); pause(self.PauseTime);
                queryMsg = '1TP?';%'1MX?';%'1ID?';
                self.send_command(queryMsg);
                response = self.read_response();
                response = strtrim(response);
                motorQuery = response(end);
                %pause(self.PauseTime);
            end
        end
        
        function self = move_x(self, distance)
            if self.Connected
                %                 if self.Calibrated
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
                pause(self.PauseTime);
                
                self.send_command(choose_motor);
                pause(self.PauseTime);
                if ~self.queryMotionMotor() == 5
                    pause(.5);
                else
                    pause(self.PauseTime);
                end
                
                % Vince edit here: move accurate distance
                for dd = 1:length(accurateDistance)
                    move_cmd = ['1PR', num2str(accurateDistance(dd))];
                    self.send_command(move_cmd);
                    pause(abs(accurateDistance(dd))/500+2.5*self.PauseTime);
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
                
                %                 if self.Calibrated
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
                pause(self.PauseTime);
                
                
                self.send_command(choose_motor);
                pause(self.PauseTime);
                if ~self.queryMotionMotor() == 6
                    pause(.5);
                else
                    pause(self.PauseTime);
                end
                
                % Vince edit here: move accurate distance
                for dd = 1:length(accurateDistance)
                    move_cmd = ['1PR', num2str(-accurateDistance(dd))];
                    self.send_command(move_cmd);
                    pause(abs(accurateDistance(dd))/500+2.5*self.PauseTime);
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
                
%                 if self.Calibrated
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
                %                 if self.Calibrated
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
                pause(self.PauseTime);
                
                
                self.send_command(choose_motor);
                pause(self.PauseTime);
                if ~self.queryMotionMotor() == 3
                    pause(.5);
                else
                    pause(self.PauseTime);
                end
                
                % Vince edit here: move accurate distance
                for dd = 1:length(accurateDistance)
                    move_cmd = ['1PR', num2str(-accurateDistance(dd))];
                    self.send_command(move_cmd);
                    pause(abs(accurateDistance(dd))/500+2.5*self.PauseTime);
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
                %                 if self.Calibrated
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
                pause(self.PauseTime);
                
                
                self.send_command(choose_motor);
                pause(self.PauseTime);
                if ~self.queryMotionMotor() == 4
                    pause(.5);
                else
                    pause(self.PauseTime);
                end
                
                self.send_command(move_cmd);
                pause(abs(degrees)+2.5*self.PauseTime);
                
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
                %                 if self.Calibrated
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
                pause(self.PauseTime);
                
                
                self.send_command(choose_motor);
                pause(self.PauseTime);
                if ~self.queryMotionMotor() == 5
                    pause(.5);
                else
                    pause(self.PauseTime);
                end
                
                self.send_command(move_cmd);
                pause(abs(degrees)/5+2.5*self.PauseTime);
                
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
            pause(self.PauseTime);
            self.move_x(self.fullDistance);
            pause(self.PauseTime);
            self.move_y(self.fullDistance);
            
            self.xPos = 0;
            self.yPos = 0;
            self.zPos = 0;
        end
        
        function load(self)
            self.move_x(-self.fullDistance/2);
            pause(self.PauseTime);
            self.move_y(-self.fullDistance/2);
            %             pause(self.PauseTime);
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

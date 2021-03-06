% � Copyright 2013-2015 Shon Schmidt, Jonas Flueckiger, and WenXuan Wu
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

classdef OpticalStage < InstrClass & CoordSysClass
    properties % public
        coordSysIsValid; % a bug w/ the coord class i don't feel like trying to figure out right now
    end
    
    properties (Access = protected)
        xPos; % stage x position
        yPos; % stage y position
        zPos; % stage z position
        Calibrated; % stage calibrated
        Overshoot;
    end
    
    methods
        % constructor
        function self = OpticalStage()
            self.Connected = 0;
            self.Busy = 0;
            self.Name = 'Virtual Optical Stage'; % name of the instrument
            self.Group = 'OpticalStage'; % instrument group this one belongs to
            self.Calibrated = 1; % stage calibrated
            self.Param.COMPort = 0;
            self.Param.BaudRate = 0;
            self.Param.StopBits = 0;
            self.Param.Parity = 0;
            self.Param.Acceleration = 500; % what are the units?
            self.Param.Velocity = 300; % what are the units?
            self.Param.xMoveThresholdWarning = 1000; % popup to ask if move is ok -> safety (used in optical_stage_ui.m)
            self.Param.yMoveThresholdWarning = 1000; % popup to ask if move is ok -> safety (used in optical_stage_ui.m)
            self.Param.zMoveThresholdWarning = 1000; % popup to ask if move is ok -> safety (used in optical_stage_ui.m)
            self.xPos = nan; % initialize to nan to ensure calibration
            self.yPos = nan; % initialize to nan to ensure calibration
            self.zPos = nan; % initialize to nan to ensure calibration
            self.Overshoot = 0;
            self.coordSysIsValid = 0;
        end
        
        % connect to instrument
        function self = connect(self)
            %            try
            self.Obj = 'VS';
            %             catch ME
            %                 self.MsgWin(ME.message);
            %                 return
            %             end
            self.Connected = 1;
        end
        
        % disconnect from instrument
        function self = disconnect(self)
            if self.Connected
                if self.Busy % is running, stop it first
                    self.stop();
                    self.Busy = 0;
                end
                self.Connected = 0;
            else
                msg = strcat(self.Name, ' not connected.');
                error(msg);
            end
        end
        
        % reset
        function self = reset(self)
            if self.Connected
                if self.Busy % is running, stop it first
                    self.stop();
                    self.Busy = 0;
                end
            else
                msg = strcat(self.Name, ' not connected.');
                error(msg);
            end
        end
        
        % calibrate stage
        function self = calibrate(self)
            if self.Connected
                self.Busy = 1;
                self.Calibrated = 1;
                self.xPos = 0;
                self.yPos = 0;
                self.zPos = 0;
                self.Busy = 0;
            else
                msg = strcat(self.Name, ' not connected.');
                error(msg);
            end
        end
        
        % set velocity
        function self = setVelocity(self, vel)
            self.Param.Velocity = vel;
        end
        
        % set acceleration
        function self = setAcceleration(self, accel)
            self.Param.Acceleration = accel;
        end
        
        % get position
        function [x,y,z] = getPosition(self)
            if self.Calibrated
                x = self.xPos;
                y = self.yPos;
                z = self.zPos;
            else
                msg = strcat(self.Name, ' not calibrated. Cannot get position.');
                error(msg);
            end
        end
        
        % move X
        function self = move_x(self, distance)
            if self.Calibrated
                self.Busy = 1;
%                pause(abs(distance) / self.Param.Velocity); % time to move distance
                self.xPos = self.xPos + distance;
                self.Busy = 0;
            else
                msg = strcat(self.Name, ' not calibrated. Cannot get position.');
                error(msg);
            end
        end
        
        % move Y
        function self = move_y(self, distance)
            if self.Calibrated
                self.Busy = 1;
%                pause(abs(distance) / self.Param.Velocity); % time to move distance
                self.yPos = self.yPos + distance;
                self.Busy = 0;
            else
                msg = strcat(self.Name, ' not calibrated. Cannot get position.');
                error(msg);
            end
        end
        
        % move Z
        function self = move_z(self, distance)
            if self.Calibrated
                self.Busy = 1;
%                pause(abs(distance) / self.Param.Velocity); % time to move distance
                self.zPos = self.zPos + distance;
                self.Busy = 0;
            else
                msg = strcat(self.Name, ' not calibrated. Cannot get position.');
                error(msg);
            end
        end
        
        % below are functions from Corvus Eco
        function self = triggered_move_y(self, direction, move_distance, trigger_pos)
            if strcmp(direction,'right')
                self.moveY(move_distance);
            elseif strcmp(direction, 'left')
                self.moveY(-move_distance);
            else
                err = MException('opicalStage:triggered_move_y',...
                    'invalid direction');
                throw(err);
            end
        end
        
        
                %% Closed loop configuration commands
        function [a1, a2] = set_closed_loop(self, enable)
           %enables the closed loop control for axis 1 and 2; 
           %if enable=1: enable closed loop if enable=0: disabled
           % returns setting in stage controller for axis 1 and 2; s

            if enable
                disp('enables closed loop');
                a1=1;
                a2=1; 
            else
                disp('disables closed loop');
                a1=0;
                a2=0;
            end
        end
        
        
        function self = setProp(self, prop, val)
            if self.(prop)
                self.(prop) = val;
            else
                msg = strcat(self.Name, ' ', prop, ' does not exist.');
                err = MException(msg);
                throw(err);
            end
        end
        
        function val = getProp(self, prop)
            if self.(prop)
                val = self.(prop);
            else
                msg = strcat(self.Name, ' ', prop, ' does not exist.');
                err = MException(msg);
                throw(err);
            end
        end
    end
end

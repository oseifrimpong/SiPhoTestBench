% © Copyright 2013-2015 Victor Bass, Shon Schmidt, Jonas Flueckiger,
% and WenXuan Wu
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

classdef TEC < InstrClass
    
    % generic thermoelectric controller
    
    properties
        CurrentTemp;  % degrees C
        % temperature limits given by manufacturer
        MIN_TEMP;  % degrees C
        MAX_TEMP;  % degrees C

    end
    
    methods
        % constructor
        function self = TEC()
            self.Name = 'Virtual TEC';
            self.Group = 'TEC';
            self.MsgH = ' ';
            self.CalDate = date;
            self.Connected = 0;  % 0 = not connected, 1 = connected
            self.Busy = 0;  % 0 = not busy, 1 = busy
            % serial port connection parameters
            self.Obj = ' ';  % becomes serial port object
            self.Param.COMPort = 0;
            self.Param.BaudRate = 9600;
            self.Param.DataBits = 8;
            self.Param.StopBits = 1;
            self.Param.Terminator = 'LF';
            self.Param.Parity = 'none';
            % temp controller parameters
            self.CurrentTemp = 25;
            self.Param.TargetTemp = 37;  % degrees C
        end
    end
    
    methods
        function self = connect(self)
            self.Obj = 'VP';
            self.Connected = 1;
        end
        
        function self = disconnect(self)
            if self.Connected
                if self.Busy
                    self.stop;
                    self.Busy = 0;
                end
                self.Connected = 0;
            else
                msg = (strcat(self.Name, ' not connected.'));
                error(msg);
            end
        end
        
        % set temp instrument aims for
        function setTargetTemp(self, temp)
            %set the temp the controller will try to maintain
            self.Param.TargetTemp = temp;
            self.CurrentTemp = temp;
        end
        
        % start controller
        function msg = start(self)
            if self.Connected
                if self.Busy
                    msg = strcat(self.Name, ' already started.');
                else
                    % commands to start the controller to target temp
                    self.Busy = 1;
                end
            else
                msg = strcat(self.Name, ' not connected.');
            end
        end
        
        % stop controller
        function self = stop(self)
            if self.Connected
                if self.Busy
                    % commands to stop the controller
                    self.Busy = 0;
                else
                    msg = strcat(self.Name, ' already stopped.');
                    error(msg);
                end
            else
                msg = strcat(self.Name, ' not connected.');
                error(msg);
            end
        end
        
        % show controller's current temperature
        function val = currentTemp(self)
            % read current temp from controller
            % store in variable CurrentTemp
            val = self.CurrentTemp;
        end
        
        % show controller's target temperature
        function val = showTargetTemp(self)
            val = self.Param.TargetTemp;
        end
        
        % show controller's temperature limits
        function self = showTempLimits(self)
            % commands to check current temp limits of machine
            % store those limits in MIN_TEMP and MAX_TEMP
            low_limit = self.MIN_TEMP;
            high_limit = self.MAX_TEMP;
            disp(strcat('Low temperature limit is ', num2str(low_limit), ' degrees C'))
            disp(strcat('High temperature limit is ', num2str(high_limit), ' degrees C'))
        end
    end
end

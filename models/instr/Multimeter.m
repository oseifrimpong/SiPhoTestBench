% © Copyright 2013-2015 Victor Bass
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

classdef Multimeter < InstrClass
   
    % generic multimeter
    
    properties
    end
    
    methods
        % constructor
        function self = Multimeter()
            self.Name = 'Virtual Multimeter';
            self.Group = 'Multimeter';
            self.Connected = 0;  % 0=not connected, 1=connected
            self.Busy = 0;  % 0=not busy, 1 = busy
            self.Obj = ' ';  % serial/GPIB object
            % multimeter parameters
            self.Param.VoltageRange = '100 mV'; % choices depend on instrument
            self.Param.CurrentRange = '100 uA'; % choices depend on instrument
        end
    end
    
    methods
        function self = connect(self)
            % connect to instrument
            if self.Connected
                msg = strcat(self.Name, ' already connected');
                disp(msg);
            else
                self.Obj = 'VPS';
                self.Connected = 1;
            end
        end
        
        function self = disconnect(self)
            % disconnect from instrument
            if self.Connected
                delete(self.Obj);
                self.Connected = 0;
            else
                msg = strcat(self.Name, ' not connected');
                disp(msg);
            end
        end
        
        function self = measure_DC_voltage(self)
            % set instrument to measure DC voltage
        end
        
        function self = measure_DC_current(self)
            % set instrument to measure DC current
        end
        
        function self = read_data(self)
            % save instrument readings in a text file
        end
    end
end

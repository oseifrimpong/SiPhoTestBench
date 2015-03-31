% © Copyright 2013-2015 Victor Bass, Shon Schmidt, Jonas Flueckiger, and WenXuan Wu
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

classdef TECNewport3040 < InstrClass
    
    % using peltier cooler module 56460-500, which has a max current of 3.9
    % amps and a max voltage of 14.4 volts
    % user manual available online at:
    % ftp://download.newport.com/Photonics/Laser%20Diode%20Control%20Instruments/Manuals/3040%20Temperature%20Controller%20Manual.pdf
    
    properties
        CurrentTemp;  % degrees C
        % temperature limits given by manufacturer
        MIN_TEMP;  % degrees C
        MAX_TEMP;  % degrees C
        
        MAX_CURRENT; % amps, given by peltier cooler manufacturer
    end
    
    methods
        % constructor
        function self = TECNewport3040()
            self.Name = 'Newport TEC 3040';
            self.Group = 'TEC';
            self.Model = '3040';
            self.Serial = '0301304040';
            self.MsgH = ' ';
            self.CalDate = date;
            self.Connected = 0;  % 0 = not connected, 1 = connected
            self.Busy = 0;  % 0 = not busy, 1 = busy
            %self.Steinhart.C1 = 1.0364e-3;
            %self.Steinhart.C2 = 2.5146e-4;
            %self.Steinhart.C3 = 1.8096e-8;
            % Range calculate from [20, 30, 40] degree
            self.Param.C1 = 1.1318; % e-3
            self.Param.C2 = 2.3358; % e-4
            self.Param.C3 = 0.90695; % e-7
            self.Param.R25 = 10; % k ohm
            
            % serial port connection parameters
            self.Obj = '';  % becomes serial port object
            self.Param.COMPort = 6; % GPIB address
            self.Param.BaudRate = 9600;
            self.Param.DataBits = 8;
            self.Param.StopBits = 1;
            self.Param.Terminator = 'LF';
            self.Param.Parity = 'none';
            self.Param.UpdatePeriod = 10; % (s) update reading timer
            % temp controller parameters
            self.Param.TargetTemp = 37;  % degrees C
            self.Param.LoopGain = '30'; % Default Value
            self.MAX_CURRENT = 3;
        end
    end
    
    methods
        function self = connect(self)
            %first check if connected already
            if self.Connected == 1 %1 means connected
                err = MException('ThermalController:Connection',...
                    'thermal controller is already connected');
                throw(err);
            end
            % connect to GPIB port
            try
                self.Obj = gpib('ni',0',self.Param.COMPort);
                fopen(self.Obj);
                constant_t_cmd = 'tec:mode:t';
                self.send_command(constant_t_cmd); % sets instrument to constant temperature mode
                self.setMaxCurrent;
            catch ME
                error(ME.message);
            end

                %create serial object to control instrument
%                 self.Obj = serial(['COM',num2str(self.Param.COMPort)]);
%                 set(self.Obj,'BaudRate',self.Param.BaudRate);
%                 set(self.Obj,'DataBits',self.Param.DataBits);
%                 set(self.Obj,'Parity',self.Param.Parity);
%                 set(self.Obj,'Terminator',self.Param.Terminator);
                %open the connection to the serial port
%                 try
%                     fopen(self.Obj);
%                 catch ME
%                     rethrow(ME);
%                 end
            %if connection successful, tell user and change self.Connected
            if strcmp(self.Obj.Status, 'open')
                self.Connected = 1;
                msg = strcat(self.Name, ' connected');
                disp(msg);
            end
            
            self.setSensor('Thermistor 100uA');
            self.setConstants(self.Param.R25, self.Param.C1, self.Param.C2, self.Param.C3);
            self.setLoopGain(self.Param.LoopGain);
        end
        
        function self = disconnect(self)
            % check if stage is connected
            if self.Connected == 0
                msg = strcat(self.Name,' is not connected');
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
            msg = strcat(self.Name, ' disconnected');
            disp(msg);
        end
        
        function self = send_command(self, command)
            if self.Obj.BytesAvailable > 0
                fscanf(self.Obj, '%s', self.Obj.BytesAvailable);
            end
            
            if strcmp(self.Obj.Status, 'open')  %if connection is open
                fprintf(self.Obj, command);
            else
                err = MException('ThermalController:Com',...
                    'thermal controller Connected: connection closed');
                throw(err);
            end
        end
        
        function setConstants(self, R, C1, C2, C3)
            % R in kohm
            self.send_command(['tec:r ', num2str(R)]);
            command = ['tec:const ' num2str(C1) ',' num2str(C2) ',' num2str(C3)];
            self.send_command(command);
        end
        
        function setSensor(self, sensorType)
            switch lower(sensorType)
                case 'thermistor 100ua'
                    sensor = 1;
                case 'thermistor 10ua'
                    sensor = 2;
                case 'lm335'
                    sensor = 3;
                case 'ad590'
                    sensor = 4;
                case 'rtd'
                    sensor = 5;
            end
            self.send_command(['tec:sensor ', num2str(sensor)]);
        end
        
        function setLoopGain(self, loopGain)
            self.Param.LoopGain = loopGain;
            self.send_command(['tec:gain ', loopGain]);
        end
        
        function setTargetTemp(self, temp)
            %set the temp the controller will try to maintain
            self.Param.TargetTemp = temp;
        end
        
        function self = start(self)
            set_temp = ['tec:t ',num2str(self.Param.TargetTemp)];
            %the space is required, so use [] to make strcat preserve it
            start_tec = strcat('tec:output 1');
            self.send_command(set_temp);
            self.send_command(start_tec);
        end
        
        function self = stop(self)
            stop_tec = ('tec:output 0');
            self.send_command(stop_tec);
        end
        
        function setMaxTemp(self, temp)
            %set the high temp limit of the controller
            self.MAX_TEMP = temp;
            set_hi_temp = strcat(['tec:lim:thi ',num2str(self.MAX_TEMP)]);
            self.send_command(set_hi_temp);
        end
        
        function setMinTemp(self, temp)
            %set the low temp limit of the controller
            self.MIN_TEMP = temp;
            set_lo_temp = strcat(['tec:lim:tlo ',num2str(self.MIN_TEMP)]);
            self.send_command(set_lo_temp);
        end
        
        function curretnTemp = currentTemp(self)
            check_temp = 'tec:t?';
            self.send_command(check_temp);
            curretnTemp = fscanf(self.Obj);
            %             disp(['Current temp is ', curretnTemp]);
        end
        
        function [minTemp, maxTemp] = checkTempLimit(self)
            check_low_limit = 'tec:lim:tlo?';
            check_high_limit = 'tec:lim:thi?';
            self.send_command(check_low_limit);
            minTemp = fscanf(self.Obj);
            %             disp(['Low temp limit is ', low_limit]);
            self.send_command(check_high_limit);
            maxTemp = fscanf(self.Obj);
            %             disp(['High temp limit is ', high_limit]);
        end
        
        function setMaxCurrent(self)
            current_limit_cmd = strcat(['tec:lim:ite ', num2str(self.MAX_CURRENT)]);
            self.send_command(current_limit_cmd); % sets the instrument's output current limit
        end
        
        function queryError(self)
            error = 'err?';
            self.send_command(error);
            error = fscanf(self.Obj);
            disp(error);
        end
    end
    
end

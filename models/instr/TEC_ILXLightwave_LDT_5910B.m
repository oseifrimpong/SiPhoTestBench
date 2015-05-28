% © Copyright 2015 - Vince Wu
% 

classdef TEC_ILXLightwave_LDT_5910B < InstrClass
    
    properties (Access = protected)
        
        AutotuneStepSize;   % set the temperature control autotune step size in Amm. The default value is 10% of TILM, up to 25%.
        ThermoSensorType;  % set the temperature sensor type, NTC10uA=0; NTC100uA=1, NTC1mA=2, NTCAUTO=3, RTD=4, LM355=5, AD590=6
        %        Control; %1: TEC temp control on ; 0: TEC control off
        
        TripOffThermometer;    % set the TEC trip off upon thermometer fault (No=1,Yes=1)
        TripOffMaxTemp;        % set the TEC trip off upon exceeding max temp (No=1,Yes=1)
        TripOffMinTemp;        % set the TEC trip off upon exceeding min temp (No=1,Yes=1)
        TripOffMaxCurrent;     % set the TEC trip off upon excedding max current (No=1,Yes=1)
        TripOffMaxVoltage;     % set the TEC trip off upon exceeding max voltage (No=1,Yes=1)
        
        NTC_Model;    % set the NTC calibration mode. Beta=0, SHH=1, NONE=2;
        %moved to AppSettings
        C1;       % A=1.20836e-3;
        C2;       % B=2.41165e-4;
        C3;       % C=1.48267e-7;
        PGain;       %set the temperature control loop proportional gain
        IGain;       % sett the temperature control loop integral gain
        DGain;       % set the temperature control loop derivative gain
        MinTemp;  % degrees C   10 degree
        MaxTemp;  % degrees C   120 degree
        MaxCurrent; % in amps, given by peltier cooler manufacturer  1.4 A
        MaxVolt;     % in volts  8.5V
        MaxR;     % upper resitance limit in kilo ohm
        MinR;     % lower resistance limit in kilo ohm
        
        Timeout;  %COM timeout
        PauseTime;
    end
    
    methods
        % constructor
        function self = TEC_ILXLightwave_LDT_5910B()
            self.Name = 'ILX_LDT5910B';
            self.Group = 'TEC';
            self.Model = 'LDT5910B';
            self.Serial = 'xx';
            self.CalDate = date;
            self.Connected = 0;  % 0 = not connected, 1 = connected
            self.Busy = 0;  % 0 = not busy, 1 = busy
            self.Timeout = 20; %com time out
            self.PauseTime = 0.1;
            
            
            self.AutotuneStepSize = 0.14;   % set the temperature control autotune step size in Amm. The default value is 10% of TILM, up to 25%.
            %            self.Control = 0;
            self.ThermoSensorType = 3;
            
            self.NTC_Model=1; % set the NTC calibration mode. Beta=0, SHH=1, NONE=2;
            
            self.TripOffThermometer = 1;    % set the TEC trip off upon thermometer fault (No=1,Yes=1)
            self.TripOffMaxTemp = 1;        % set the TEC trip off upon exceeding max temp (No=1,Yes=1)
            self.TripOffMinTemp = 1;        % set the TEC trip off upon exceeding min temp (No=1,Yes=1)
            self.TripOffMaxCurrent = 0;     % set the TEC trip off upon excedding max current (No=1,Yes=1)
            self.TripOffMaxVoltage = 0;     % set the TEC trip off upon exceeding max voltage (No=1,Yes=1)
            
            self.MinTemp = 10;  % degrees C   10 degree
            self.MaxTemp = 80;  % degrees C   120 degree
            self.MaxCurrent = 1.4; % in amps, given by peltier cooler manufacturer  1.4 A
            self.MaxVolt = 8.5;     % in volts  8.5V
            self.MaxR = 20e3;     % upper resitance limit in kilo ohm
            self.MinR = 100;     % lower resistance limit in kilo ohm
            
            % serial port connection parameters
            self.Obj = ' ';  % becomes serial port object
            self.Param.COMPort = 7; % GPIB address
            self.Param.BaudRate = 9600;
            self.Param.DataBits = 8;
            self.Param.StopBits = 1;
            self.Param.Terminator = 'LF';
            self.Param.Parity = 'none';
            self.Param.UpdatePeriod = 10; % (s) update reading timer
            self.Param.TargetTemp= 25;
            %The following are needed for current or resistance control
            %self.Param.TargetCurrent = 1; in Amperes
            %self.Param.TargetResistance = 10; in kOhms
            
% shons 24/5/2015 old values
%             self.C1 = 1;
%             self.C2 = 2.333;
%             self.C3 = 0.5;
            self.C1 = 1.280371619;
            self.C2 = 2.369620414;
            self.C3 = 0.897542961;
            self.PGain = -3.031296; % A/°C
            self.IGain = 0.1723280; % /s
            self.DGain = 1.450723;  % s
        end
    end
    
    
    % -----------------------------TEC connection-----------------------------
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
                self.Obj = visa('ni', ['GPIB0::', num2str(self.Param.COMPort), '::INSTR']);
                fopen(self.Obj);
            catch ME
                error (ME.message);
            end
            
            try
                constant_t_cmd = 'MODE:T';  % the default mode is constant temp (CT) mode
                self.send_command(constant_t_cmd); % sets instrument to constant temperature mode
                self.setMaxTemp(self.MaxTemp);
                self.setMinTemp(self.MinTemp);
                self.setMaxCurrent(self.MaxCurrent);
%                 self.setMaxVolt(self.MaxVolt);
%                 self.setMaxR(self.MaxR);
%                 self.setMinR(self.MinR);
                
                self.setThermoSensorType(self.ThermoSensorType);
                
                self.set_TripOffThermometer(self.TripOffThermometer);
                self.set_TripOffMaxTemp(self.TripOffMaxTemp);
                self.set_TripOffMinTemp(self.TripOffMinTemp);
                self.set_TripOffMaxCurrent(self.TripOffMaxCurrent);
                self.set_TripOffMaxVoltage(self.TripOffMaxVoltage);
                
                self.setThermistorModel(self.C1, self.C2, self.C3); % A, B, C
                % Vince will add it back
                %                 self.PID_calibration(0, self.PGain, self.IGain, self.DGain); % P, I, D
            catch ME
                rethrow(ME);
            end
            
            
            %  if connection successful, tell user and change self.Connected
            if strcmp(self.Obj.Status, 'open')
                self.Connected = 1;
                msg = strcat(self.Name, ' connected');
%                disp(msg);
            end
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
%            disp(msg);
        end
        
        function self = PID_calibration(self, Autotune, P, I, D)
            %checks if AppSettings.TEC.Autotune is set to 1
            if Autotune ==1
                self.autotune();
            else
                %if 0 then set PID manually
                %get PID values from AppSettings.TEC
                self.setPGain(P);
                self.setIGain(I);
                self.setDGain(D);
            end
        end
        
        function self = setThermistorModel(self, C1, C2, C3)
            self.setCalibrationMode(self.NTC_Model)
            % set the NTC calibration mode. Beta=0, SHH=1, NONE=2;
            
            set_const_cmd = sprintf('Const %.3f, %.3f, %.3f', C1, C2, C3);
            self.send_command(set_const_cmd);
        end
        
        
        %%%----------------------TEC limit setting--------------------------------
        
        
        function self = setMaxTemp(self, temp)
            %set the maximum temp of the controller
            self.MaxTemp = temp;
            set_temp = strcat(['LIM:THI ', num2str(self.MaxTemp)]);
            self.send_command(set_temp);
        end
        
        function self = setMinTemp(self, temp)
            %set the minimum temp of the controller
            self.MinTemp = temp;
            set_temp = strcat(['LIM:TLO ', num2str(self.MinTemp)]);
            self.send_command(set_temp);
        end
        
        function self = setMaxCurrent(self, current)
            % set the current limit of the controller
            self.MaxCurrent= current;
            set_current = strcat(['LIM:ITE ', num2str(self.MaxCurrent)]);
            self.send_command(set_current);
        end
        
%         function self = setMaxVolt(self, voltage)
%             % set the voltage limit of the controller
%             self.MaxVolt = voltage;
%             set_volt = strcat(['TVLM ', num2str(self.MaxVolt)]);
%             self.send_command(set_volt);
%         end
%         
%         function self = setMaxR(self, resistance)
%             % set the maximum resistance in kilo ohm
%             self.MaxR = resistance;
%             set_R = strcat(['TRMX ', num2str(self.MaxR)]);
%             self.send_command(set_R);
%         end
%         
%         function self = setMinR(self, resistance)
%             % set the minimum resisance in kilo ohm
%             self.MinR = resistance;
%             set_R = strcat(['TRMN ', num2str(self.MinR)]);
%             self.send_command(set_R);
%         end
        
        %%%-------------------------TEC setting commands---------------------------
        
        function msg = setTargetTemp(self, temp)
            %set the current temp of the controller
            self.Param.TargetTemp = temp;
            set_temp = strcat(['T ', num2str(self.Param.TargetTemp)]);
            self.send_command(set_temp);
            msg = strcat(self.Name, ': setting temp to ', num2str(self.Param.TargetTemp));
        end
        
        function msg = getSetTemp(self)
            get_set_temp = 'T?';
            self.send_command(get_set_temp);
            temp = self.read_response();
            msg = sprintf('Set temp is : %.1f', temp);
        end
        
        function msg = setTargetCurrent(self, current)
            %set the current of the controller
            self.Param.TargetCurrent = current;
            set_current = strcat(['ITE ', num2str(current)]);
            self.send_command(set_current);
            msg = strcat(self.Name, ': setting current to ', num2str(self.Param.TargetTemp));
        end
        
        function msg = setTargetR(self, resistance)
            %set the TEC resistance setpint in kilo ohm
            self.TargetResistance = resistance;
            set_R = strcat(['R ',num2str(resistance)]);
            self.send_command(set_R);
            msg = strcat(self.Name, ': setting resistance to ', num2str(self.Param.TargetTemp));
        end
        
        %%%---------------------TEC monitor ---------------------------------
        
        function temp = currentTemp(self)
            % query the sensor temperature in ï¿½C
            check_temp = 'T?';
            self.send_command(check_temp);
            temp = fscanf(self.Obj);
            %             temp = self.read_response();
            %disp(['Current temp is ', temp,'°C']);
        end
        
        function current = currentCurrent(self)
            % qurey the TEC operating current in ampere
            check_current = 'ITE?';
            self.send_command(check_current);
            current = self.read_response();
            disp(['Current current is ', current,'A']);
        end
        
        function voltage = currentVolt(self)
            % query the TEC voltage in volts
            check_voltage = 'TVRD?';
            self.send_command(check_voltage);
            voltage=self.read_response();
            disp(['Current voltage is ', voltage, 'V']);
        end
        
        function checkRawThermometer(self)
            %query the raw sensor value in kilo ohm,voltes or micro ampere
            check_thermometer = 'TRAW?';
            self.send_command(check_thermometer);
            thermometer=self.read_response;
            disp(['Current thermometer is ',thermometer]);
        end
        
        function checkTemSensorStatus(self)
            % query the sensor status. Return OK=1 or Fault=0, based on
            % whether the sensor reading is within hardware bounds
            check_status = 'TSNS?';
            self.send_command(check_status);
            temperature_SensorStatus=fscanf([self.Obj]);
            if temperature_SensorStatus==0
                disp('Currrent temperature sensor status is fault');
            else
                disp('Currrent temperature sensor status is OK');
            end
        end
        
        
        function status = checkAutoTune(self)
            autotune = 'TUNE?';
            self.send_command(autotune);
            % Status: 0 - Off; 1 - On; 2 - Unstable; 3 - Success; 4 - Failed;
            status = fscanf(self.Obj);
        end
        
        
        
        %%%-------------------TEC configuration setting----------------------
        % Proportional-integral-differential(PID). P: -0.62A/ï¿½C, I:0.131/s; D:1.90s
        
        function autotune(self)
            %Tunes the PID controller automatically
            set_Autotune=strcat('TUNE 1');
            self.send_command(set_Autotune);
        end
        
        function setAutotuneStepSize(self)
            % se the temperature control autotune step size in Amp
            setAutotuneStepSize = strcat(['TATS ',num2str(self.AutotuneStepSize)]);
            self.send_command(setAutotuneStepSize);
        end
        
        function setPGain(self, P)
            % set the temperature control loop proportional gain in A/ï¿½C
            setPGain=strcat(['TPGN ', num2str(P)]);
            self.send_command(setPGain);
            self.PGain = P;
        end
        
        function PGain = getPGain(self)
            command = 'TPGN?';
            self.send_command(command);
            PGain = fscanf(self.Obj);
        end
        
        function setIGain(self, I)
            % set the temperature control loop integral gain in /s
            setIGain=strcat(['TIGN ', num2str(I)]);
            self.send_command(setIGain);
            self.IGain = I;
        end
        
        function IGain = getIGain(self)
            command = 'TIGN?';
            self.send_command(command);
            IGain = fscanf(self.Obj);
        end
        
        function setDGain(self, D)
            % set the temperature control loop derivative gain in s
            setDGain=strcat(['TDGN ', num2str(D)]);
            self.send_command(setDGain);
            self.DGain = D;
        end
        
        function DGain = getDGain(self)
            command = 'TDGN?';
            self.send_command(command);
            DGain = fscanf(self.Obj);
        end
        %%%---------------------TEC  sensor commands---------------------------
        
        function setThermoSensorType(self, type)
            % set the temperature sensor type, NTC10uA=0; NTC100uA=1,
            % NTC1mA=2, NTCAUTO=3, RTD=4, LM355=5, AD590=6
            self.ThermoSensorType = type;
            set_ThermoSensorType=strcat(['TSNR ', num2str(self.ThermoSensorType)]);
            self.send_command(set_ThermoSensorType);
        end
        function setCalibrationMode(self,model)
            % set the NTC calibration mode. Beta=0, SHH=1, NONE=2;
            self.NTC_Model = model;
            set_mode = strcat(['TMDN ', num2str(self.NTC_Model)]);
            self.send_command(set_mode);
        end
        
        
        %%%-------------------TEC trip-off-----------------------------------
        
        function set_TripOffThermometer(self, status)
            % set the TEC trip off upon thermometer fault (No=0,Yes=1)
            self.TripOffThermometer = status;
            set_TripOffThermometer = strcat(['TTSF ', num2str(status)]);
            self.send_command(set_TripOffThermometer);
        end
        
        function set_TripOffMaxTemp(self, status)
            % set the TEC trip off upon exceeding max Temp (No=0,Yes=1)
            self.TripOffMaxTemp = status;
            set_TripOffMaxTemp = strcat(['TTMX ', num2str(self.TripOffMaxTemp)]);
            self.send_command(set_TripOffMaxTemp);
        end
        
        function set_TripOffMinTemp(self, status)
            % set the TEC trip off upon exceeding min Temp (No=0,Yes=1)
            self.TripOffMinTemp = status;
            set_TripOffMinTemp = strcat(['TTMN ', num2str(self.TripOffMinTemp)]);
            self.send_command(set_TripOffMinTemp);
        end
        
        function set_TripOffMaxCurrent(self, status)
            % set the TEC trip off upon exceeding current limit (No=0,Yes=1)
            self.TripOffMaxCurrent = status;
            set_TripOffMaxCurrent=strcat(['TTIL ', num2str(self.TripOffMaxCurrent)]);
            self.send_command(set_TripOffMaxCurrent);
        end
        
        function set_TripOffMaxVoltage(self, status)
            % set the TEC trip off upon exceeding voltage limit (No=0,Yes=1)
            self.TripOffMaxVoltage = status;
            set_TripOffMaxVoltage = strcat(['TTVL ', num2str(self.TripOffMaxVoltage)]);
            self.send_command(set_TripOffMaxVoltage);
        end
        
        
        
        %%%----------------------------------------------------------
        
        
        function self = send_command(self, command)
            if self.Obj.BytesAvailable > 0
                fscanf(self.Obj, '%s', self.Obj.BytesAvailable);
            end
            
            if strcmp(self.Obj.Status,'open')  %if connection is open
                fprintf(self.Obj, command);
            else
                err = MException('ThermalController:Com',...
                    'thermal controller Connected: connection closed');
                throw(err);
            end
        end
        
        function response = read_response(self)
            response = '0';
            if ~self.Connected
                error(strcat(self.Name,':Read'),...
                    'temperature controller status: closed');
            end
            start_time = tic;
            while toc(start_time) < self.Timeout
                if self.Obj.BytesAvailable >0
                    response = fscanf(self.Obj);
                    return
                else
                    pause(self.PauseTime);
                end
            end
            if toc(start_time) >= self.Timeout
                error(strcat(self.Name,':ReadTimeOut'),...
                    'temprature controller timed out');
            end
        end
        
        function msg = start(self)
            %Todo; error handling
            cmd=strcat('TEON 1');
            self.send_command(cmd);
            %      self.Control = 1; % (shons note) this is a protected property - need to write method to report on status or use busy
            self.Busy = 1;
            msg = strcat(self.Name, ': turning TEC on');
        end
        
        function msg = stop(self)
            %TODO: error handling
            cmd = ('TEON 0');
            self.send_command(cmd);
            %      self.Control = 0; % (shons note) this is a protected property - need to write method to report on status or use busy
            self.Busy = 0;
            msg = strcat(self.Name, ': turning TEC off');
        end
    end
end

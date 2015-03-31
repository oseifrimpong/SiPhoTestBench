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

function success = waitForThemperatureStabilization(obj, targetTemp, timeOut, precision, tolerance)
if obj.instr.thermalControl.isConnected
    if targetTemp ~= 0
        obj.instr.thermalControl.setTargetTemp(targetTemp);
        % turn the TEC on
        obj.instr.thermalControl.start();
        if obj.AppSettings.TBCParams.WaitForTempStabilization
            % start timer for timeout
            ticTempStart = tic;
            elapsedTempTime = toc(ticTempStart);
            % read temp and apply precision
            targetTemp = double(vpa(targetTemp, precision));
            TECTemp = obj.instr.thermalControl.currentTemp;
            currentTemp = double(vpa(TECTemp, precision));
            % wait until temp is reached or timeout occurs
            while (elapsedTempTime/60 < timeOut) && (abs(currentTemp - targetTemp) >= tolerance)
                pause(1); % this is arbitrary
                % read temp and apply precision
                TECTemp = obj.instr.thermalControl.currentTemp;
                currentTemp = double(vpa(TECTemp, precision));
                msg = strcat('Waiting for temperature to stabilize.',...
                    sprintf('\n\tCurrentTemp (C) = %s', num2str(currentTemp)),...
                    sprintf('\n\tTargetTemp (C) = %s', num2str(targetTemp)),...
                    sprintf('\n\tElapsedTime (min) = %s', num2str(round(elapsedTempTime/60))));
                obj.msg(msg);
                elapsedTempTime = toc(ticTempStart);
            end
            % error handling and user message
            if (elapsedTempTime/60 >= timeOut) || (abs(currentTemp - targetTemp) >= tolerance)
                % pop-up window for user
                % shons note: need to add stop functionality to this
                message = sprintf('Target temperature not reached.\nDo you want to continue?');
                response = questdlg(...
                    message, ...
                    'ERROR', ...
                    'Try Again', 'Yes', 'No', 'Try Again');
                if strcmpi(response, 'Try Again')
                    success = waitForThemperatureStabilization(obj, targetTemp, timeOut, precision, tolerance);
                elseif strcmpi(response, 'Yes')
                    success = true;
                else
                    success = false;
                    return;
                end
            else
                success = true;
                msg = strcat(...
                    sprintf('Temperature reached.\n\tCurrentTemp = %s', num2str(currentTemp)),...
                    sprintf('\n\tTargetTemp = %s', num2str(targetTemp)),...
                    sprintf('\n\tElapsedTime = %s', num2str(round(elapsedTempTime/60))));
                obj.msg(msg);
            end
        end
    else % Target Temp = 0
        % Turn the TEC off
        obj.instr.thermalControl.stop();
    end
else
    obj.msg('TEC not connected. Skipping thermal tuning.');
end
end

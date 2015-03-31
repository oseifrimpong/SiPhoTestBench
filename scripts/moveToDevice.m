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

function benchObj = moveToDevice(benchObj, currentDevice, targetDevice)
% Vince Wu 2013
if (strcmp(currentDevice.Name, targetDevice.Name))
    benchObj.msg(strcat('Already on device: ', currentDevice.Name));
elseif ~strcmpi(currentDevice.Name, '<Device>')
    currentName = strrep(currentDevice.Name, '_', '-');
    targetName = strrep(targetDevice.Name, '_', '-');
    if ~strcmp(currentName, targetName)
        wb_msg = ['Moving to device: ', targetName];
        wh = waitbar(0.3, wb_msg, ...
            'Name', 'Please Wait', ...
            'WindowStyle', 'modal');
        movegui(wh, 'center');
        
        waitbar(0.6, wh, wb_msg);
        if benchObj.instr.opticalStage.coordSysIsValid
            disp('coord system move');
            benchObj.instr.opticalStage.moveTo(targetDevice.X, targetDevice.Y);
        else
            disp('relative move');
            % Move in x direction
            benchObj.instr.opticalStage.move_x(-(targetDevice.X - currentDevice.X));
            % Move in y direction
            benchObj.instr.opticalStage.move_y(-(targetDevice.Y - currentDevice.Y));
        end
        
        wb_msg = 'Success!';
        waitbar(0.8, wh, wb_msg);
        waitbar(1, wh, wb_msg);
        delete(wh)

        % Update location information in chip
        benchObj.chip.CurrentLocation = targetDevice.Name;

        msg = [...
            'Move from device: ', ...
            currentName, ': (', num2str(currentDevice.X), ', ', num2str(currentDevice.Y), ')'...
            ' to ', ...
            targetName, ': (', num2str(targetDevice.X), ', ', num2str(targetDevice.Y), ')'];
        benchObj.msg(msg);
    end
end
end

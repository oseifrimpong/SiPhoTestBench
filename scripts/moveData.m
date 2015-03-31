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

% Move Tested Data to Network Drive
function moveData(obj)
obj.AppSettings.FinishTestSettings.MoveData = questdlg(...
    sprintf('Test finished.\nDo you want to move data to:\n%s', obj.AppSettings.path.testData), ...
    '<<< Test Finished >>>', ...
    'Yes', 'No', 'Yes');
if strcmp(obj.AppSettings.FinishTestSettings.MoveData, 'Yes')
    wh = waitbar(0, sprintf('Moving data from temporary directory to\n%s', [obj.AppSettings.path.testData, '\']));
    numOfDevices = length(obj.testedDevices);
    statusOption = {'FAIL', 'SUCCESS'};
    
    switch obj.AppSettings.infoParams.School;
        case 'UBC'
            tempDataPath = obj.devices.(obj.testedDevices{1}).FilePath;
            destination = strrep(...
                tempDataPath, ...
                obj.AppSettings.path.tempData, ...
                strcat(obj.AppSettings.path.testData,'\'));
            msg = sprintf(...
                'Moving device: %s data\nFrom:%s\nTo:%s\nStatus: ......', ...
                strrep(obj.testedDevices{1}, '_', '-'), ...
                strrep(strrep(tempDataPath, '\', '\\'), '_', '\_'), ...
                strrep(strrep(destination, '\', '\\'), '_', '\_'));
            waitbar(1/numOfDevices, wh, msg);
            
            % Move
            [success, message, ~] = movefile(tempDataPath, destination, 'f');
            try
                rmdir(tempDataPath, 's');
            catch ME
                disp(ME.message);
            end
            
            msg = strrep(msg, '......', statusOption{success+1});
            waitbar(1/numOfDevices, wh, msg);
            
            msg = sprintf('%s! Moved data for %s to %s', statusOption{success+1}, obj.testedDevices{1}, destination);
            obj.msg(msg);
            if ~success
                pause(1)
                obj.msg(message);
            end
            
        case 'UW'
            for d = 1:numOfDevices
                tempDataPath = obj.devices.(obj.testedDevices{d}).FilePath;
                destination = strrep(...
                    tempDataPath, ...
                    obj.AppSettings.path.tempData, ...
                    obj.AppSettings.path.testData);
                
                msg = sprintf(...
                    'Moving device: %s data\nFrom:%s\nTo:%s\nStatus: ......', ...
                    strrep(obj.testedDevices{d}, '_', '-'), ...
                    strrep(strrep(tempDataPath, '\', '\\'), '_', '\_'), ...
                    strrep(strrep(destination, '\', '\\'), '_', '\_'));
                waitbar(d/numOfDevices, wh, msg);
                
                % Move
                [success, message, ~] = movefile(tempDataPath, destination, 'f');
                
                % Delete soure directory
                % Temp Data Set Foramt:
                %   C:\TestBench\TempData\Foundry\Chip\Die\Device\TestType\Date\
                splitPath = strsplit(tempDataPath, '\');
                while length(splitPath) > 5 % Keep C:\TestBench\TempData\Chip\Die\
                    tempDataPath = strrep(tempDataPath, strcat(splitPath{end}, '\'), '');
                    if length(dir(tempDataPath)) - 2 == 0
                        try
                            rmdir(tempDataPath, 's');
                        catch ME
                            disp(ME.message);
                        end
%                         msg = sprintf('%s! Moved data for %s to %s', statusOption{success+1}, obj.testedDevices{d}, destination);
%                         obj.msg(msg);
%                         if ~success
%                             pause(1)
%                             obj.msg(message);
%                         end
                    else
                        break;
                    end
                    splitPath = splitPath(1:end-1);
                end
                
                msg = strrep(msg, '......', statusOption{success+1});
                waitbar(d/numOfDevices, wh, msg);
                
                msg = sprintf('%s! Moved data for %s to %s', statusOption{success+1}, obj.testedDevices{d}, destination);
                obj.msg(msg);
                if ~success
                    pause(1)
                    obj.msg(message);
                end
            end
        otherwise
            disp('nothing moved: No school selected');
    end
    
    % Further delete empty directory
    % Temp Data Set Foramt:
    % C:\TestBench\TempData\Foundry\Chip\Die\
    tempDataPath = createTempDataPath(obj);
    splitPath = strsplit(tempDataPath, '\');
    while length(splitPath) > 3 % Keep C:\TestBench\TempData\
        tempDataPath = strrep(tempDataPath, strcat(splitPath{end}, '\'), '');
        if length(dir(tempDataPath)) - 2 == 0
            try
                rmdir(tempDataPath, 's');
            catch ME
                disp(ME.message);
            end
        else
            break;
        end
        splitPath = splitPath(1:end-1);
    end
    
    waitbar(1, wh, 'Done');
    delete(wh);
else
    tempDataPath = createTempDataPath(obj);
    msg = sprintf('Data is stored in %s', tempDataPath);
    obj.msg(msg);
end
end

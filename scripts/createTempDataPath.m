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

function filePath = createTempDataPath(obj)
    % Create file path to store data
    % create directory path to save data = <dataDir>/<foundry>/<chip>/<die>/
    % Change coordinate file '_' into '\': i.e. <foundry>\<chip>\
    chipDir = strrep(obj.chip.Name, '_', '\');
    filePath = strcat(...
        obj.AppSettings.path.tempData,...
        chipDir,'\',...
        obj.AppSettings.infoParams.DieNumber,'\');
    if (exist(filePath, 'dir') ~= 7) % If the directory exist, it would return 7
        mkdir(filePath);
    end
end

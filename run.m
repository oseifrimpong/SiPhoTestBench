% Copyright 2013-2015 Shon Schmidt, Jonas Flueckiger, and WenXuan Wu
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

% SiPho Testbench

% License Agreement
agreement = sprintf(strcat(...
    'Copyright 2013-2015 Shon Schmidt, Jonas Flueckiger, and WenXuan Wu\n', ...
    '\nThis program is free software: you can redistribute it and/or modify\n', ...
    'it under the terms of the GNU Lesser General Public License as published by\n', ...
    'the Free Software Foundation, version 3 of the License.\n', ...
    '\nThis program is distributed in the hope that it will be useful,\n', ...
    'but WITHOUT ANY WARRANTY; without even the implied warranty of\n', ...
    'MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the\n', ...
    'GNU Lesser General Public License for more details.\n', ...
    '\nYou should have received a copy of the GNU Lesser General Public License\n', ...
    'along with this program.  If not, see <http://www.gnu.org/licenses/>.'));

agreeH = msgbox(agreement, 'SiPho Testbench License Agreement', 'modal');
pause(.25);
try
    delete(agreeH);
end

% Initialize SiPho Testbench
delete(timerfindall);
delete(instrfindall);
try
    delete(imaqfind);
catch
    disp('Image Aquisition Toolbox is not installed.');
end

debugMode = true;
rootPath = fileparts(fullfile(mfilename('fullpath')));
   
if(~debugMode)
    clear all;
    close all;
    clc;
    
    % Removed for debugging - don't want all .git directories
    addpath(genpath(rootPath));
end

testbench = TestBenchClass(rootPath);

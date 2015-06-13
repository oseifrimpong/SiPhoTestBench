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

function [ output ] = panel_index( input )
%Summary of this function goes here
%   Detailed explanation goes here
% shon: wrote this function to act as static globals since no concept
% like that exists in matlab
% goal is to make adding new tabs more seemless (this is the only file
% that should have to change)


% if you want to add a panel, you should just have to add it here...
% USER_PANEL = 1;
% TASK_PANEL = 2;
% INSTR_PANEL = 3;
% MOUNT_PANEL = 4;
% REGISTER_PANEL = 5;
% DEVICES_PANEL = 6;
% TEST_PANEL = 7;
% ANALYZE_PANEL = 8;

USER_PANEL = 1;
TASK_PANEL = 2;
INSTR_PANEL = 3;
REGISTER_PANEL = 4;
DEVICES_PANEL = 5;
TEST_PANEL = 6;

switch input
    case USER_PANEL  
        output = 'User';
    case 'user'  
        output = USER_PANEL;

    case TASK_PANEL 
        output = 'Task';
    case 'task' 
        output = TASK_PANEL;

    case INSTR_PANEL  
        output = 'Instr';
    case 'instr'  
        output = INSTR_PANEL;

%     case MOUNT_PANEL  
%         output = 'Mount';
%     case 'mount'  
%         output = MOUNT_PANEL;

    case REGISTER_PANEL  
        output = 'Register';
    case 'register' 
        output = REGISTER_PANEL;

    case DEVICES_PANEL
        output = 'Devices';
    case 'devices'
        output = DEVICES_PANEL;

    case TEST_PANEL
        output = 'Test';
    case 'test'
        output = TEST_PANEL;

%     case ANALYZE_PANEL
%         output = 'Analyze';
%     case 'analyze'
%         output = ANALYZE_PANEL;

%     case 'all'
%         output = {'User',...
%             'Task',...
%             'Instruments',...
%             'Mount chip',...
%             'Register',...
%             'Select Devices',...
%             'Run Test',...
%             'Analyze Data'};        

    case 'all'
        output = {'User',...
            'Task',...
            'Instruments',...
            'Register',...
            'Select Devices',...
            'Run Test'};        
end

end


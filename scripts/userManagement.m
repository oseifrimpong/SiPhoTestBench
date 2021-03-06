% � Copyright 2013-2015 Shon Schmidt, Jonas Flueckiger, and WenXuan Wu
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

function userID = userManagement(type, varargin)

switch type
    case 'new user'
        winTitle = 'Create New User';
        textString = 'New User Name :';
        buttonString = 'Create';
        inputStyle = 'edit';
    case 'delete user'
        winTitle = 'Delete User';
        textString = 'Choose Delete User :';
        buttonString = 'Delete';
        inputStyle = 'popup';
end
userManager = dialog(...
    'WindowStyle', 'modal', ...
    'Units', 'normalized', ...
    'Position', [0 0 .26 .16], ...
    'Name', winTitle);

uicontrol(...
    'Parent', userManager, ...
    'Style', 'text', ...
    'Units', 'normalized', ...
    'Position', [.23 .60 .41 .19], ...
    'HorizontalAlignment', 'left', ...
    'FontSize', 11, ...
    'String', textString, ...
    'ForegroundColor', [0.33, 0.12, 0.54]);

inputID = uicontrol(...
    'Parent', userManager, ...
    'Style', inputStyle, ...
    'Units', 'normalized', ...
    'Position', [.23 .41 .41 .21], ...
    'BackgroundColor', [1 1 1], ...
    'FontSize', 10, ...
    'Callback', {@inputID_cb, type});

if(strcmpi(type, 'delete user'))
    deleteList = varargin{1};
    deleteList(2:end+1) = deleteList;
    deleteList{1} = '';
    set(inputID, 'String', deleteList);
end

cancel_button = uicontrol(...
    'Parent', userManager, ...
    'Style', 'pushbutton', ...
    'Units', 'normalized', ...
    'Position', [.46 .20 .19 .19], ...
    'String', 'Cancel', ...
    'FontSize', 10, ...
    'Enable', 'on', ...
    'Callback', {@cancel_cb});

done_button = uicontrol(...
    'Parent', userManager, ...
    'Style', 'pushbutton', ...
    'Units', 'normalized', ...
    'Position', [.68 .20 .19 .19], ...
    'String', buttonString, ...
    'FontSize', 10, ...
    'Enable', 'off', ...
    'Callback', {@done_cb, type});

movegui(userManager, 'center')

uiwait;

% ------------------------- Callback Function ----------------------------

    function inputID_cb(hObject, eventData, type)
        switch type
            case 'new user'
                strName = get(hObject, 'String');
                if (~isempty(strName))
                    set(done_button, 'Enable', 'on')
                end
            case 'delete user'
                valName = get(hObject, 'Value');
                if (valName == 1)
                    set(done_button, 'Enable', 'off');
                else
                    set(done_button, 'Enable', 'on');
                end
        end
    end

    function cancel_cb(hObject, eventData)
        userID = '';
        uiresume;
        close(userManager);
    end

    function done_cb(hObject, eventData, type)
        switch type
            case 'new user'
                userID = get(inputID, 'String');
            case 'delete user'
                valName = get(inputID, 'Value');
                strName = get(inputID, 'String');
                userID = strName{valName};
        end
        uiresume;
        close(userManager);
    end
end

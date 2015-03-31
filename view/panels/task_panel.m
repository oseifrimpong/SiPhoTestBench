% ?Copyright 2014-2015 WenXuan Wu, Shon Schmidt, and Jonas Flueckiger
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

function obj = task_panel(obj)

thisPanel = panel_index('task');

obj.gui.panel(thisPanel).titleText = uicontrol(...
    'Parent', obj.gui.panelFrame(thisPanel), ...
    'Style', 'text', ...
    'BackgroundColor', [0.9, 0.9, 0.9], ...
    'String', 'Session Task', ...
    'FontSize', 26, ...
    'ForegroundColor', [0.33, 0.12, 0.54], ...
    'Units', 'normalized', ...
    'Position', [.35, .66, .30, .10]);

% ----------------------------- Task Popup -------------------------------
taskList = obj.guiDefaults.taskList;

% Obtain the index of user default task in pupup
default_user_task = find(strcmp(obj.AppSettings.infoParams.Task, taskList));
if isempty(default_user_task)
    default_user_task = 1;
end

obj.gui.panel(thisPanel).taskPopup = uicontrol(...
    'Parent', obj.gui.panelFrame(thisPanel), ...
    'Style', 'popupmenu', ...
    'String', taskList, ...
    'Value', default_user_task, ...
    'Enable', 'on', ...
    'FontSize', 12, ...
    'Units', 'normalized', ...
    'Position', [.375, .54, .26, .05], ...
    'Callback', @task_popup_cb);

obj.gui.panel(thisPanel).taskString = uicontrol(...
    'Parent', obj.gui.panelFrame(thisPanel), ...
    'Style', 'text', ...
    'String', 'Task: ', ...
    'FontSize', 12, ...
    'FontWeight', 'bold', ...
    'Units', 'normalized', ...
    'Position', [.315, .545, .06, .04], ...
    'BackgroundColor', [0.9, 0.9, 0.9] );

if default_user_task == 1
    enableSet = 'off';
else
    enableSet = 'on';
end

% --------------------------- Path Selection -----------------------------
obj.gui.panel(thisPanel).pathString = uicontrol(...
    'Parent', obj.gui.panelFrame(thisPanel), ...
    'Style', 'text', ...
    'String', 'TestData Path: ', ...
    'FontSize', 12, ...
    'FontWeight', 'bold', ...
    'Units', 'normalized', ...
    'Position', [.270, .467, .10, .04], ...
    'BackgroundColor', [0.9, 0.9, 0.9] );

obj.gui.panel(thisPanel).pathDir = uicontrol(...
    'Parent', obj.gui.panelFrame(thisPanel), ...
    'Style', 'edit', ...
    'String', obj.AppSettings.path.testData, ...
    'FontSize', 12, ...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [.375, .480, .26, .03], ...
    'BackgroundColor', [0.8, 0.8, 0.8]);

obj.gui.panel(thisPanel).pathButton = uicontrol(...
    'Parent', obj.gui.panelFrame(thisPanel), ...
    'Style', 'pushbutton', ...
    'CData',  iconRead(fullfile('icons', 'file_open.png')),...
    'FontSize', 10, ...
    'Units', 'normalized', ...
    'Position', [.635, .478, .035, .035], ...
    'Callback', @path_select_cb);

%------------------------------ Coordinate File Popup -------------------------------
[chipList, default_user_chip, coordinateFilesDir] = updateChipMenu();

% foundry
obj.gui.panel(thisPanel).foundryPopup = uicontrol(...
    'Parent', obj.gui.panelFrame(thisPanel), ...
    'Style', 'popupmenu', ...
    'String', chipList, ...
    'Value', default_user_chip, ...
    'Enable', enableSet, ...
    'FontSize', 12, ...
    'Units', 'normalized', ...
    'Position', [.375, .38, .26, .05], ...
    'Callback', {@chip_popup_cb, coordinateFilesDir});

obj.gui.panel(thisPanel).chipString = uicontrol(...
    'Parent', obj.gui.panelFrame(thisPanel), ...
    'Style', 'text', ...
    'String', 'Chip: ', ...
    'FontSize', 12, ...
    'FontWeight', 'bold', ...
    'Units', 'normalized', ...
    'Position', [.315, .385, .06, .04], ...
    'BackgroundColor', [0.9, 0.9, 0.9] );

obj.gui.panel(thisPanel).loadNewChipButton = uicontrol(...
    'Parent', obj.gui.panelFrame(thisPanel), ...
    'Style', 'pushbutton', ...
    'CData',  iconRead(fullfile('icons', 'file_open.png')),...
    'FontSize', 10, ...
    'Units', 'normalized', ...
    'Position', [.635, .385, .035, .035], ...
    'Callback', @loadNewChip_cb);

% die number
obj.gui.panel(thisPanel).dieString = uicontrol(...
    'Parent', obj.gui.panelFrame(thisPanel), ...
    'Style', 'text', ...
    'BackgroundColor', [0.9, 0.9, 0.9], ...
    'String', 'Die#:', ...
    'FontSize', 12, ...
    'ForegroundColor', [0, 0, 0], ...
    'Units', 'normalized', ...
    'Position', [.67, .37, .05, .05]);

obj.gui.panel(thisPanel).dieEdit = uicontrol(...
    'Parent', obj.gui.panelFrame(thisPanel), ...
    'Style', 'edit', ...
    'String', obj.AppSettings.infoParams.DieNumber, ...
    'Enable', enableSet, ...
    'FontSize', 12, ...
    'Units', 'normalized', ...
    'Position', [.72, .385, .06, .035], ...
    'Callback', @die_edit_cb);

if default_user_chip == 1
    % enableSet = 'off';
else
    % enableSet = 'on';
    set(obj.gui.nextButton, 'Enable', 'on');
end

%------------------------- Fiber Popup -----------------------------------
% fiberList = obj.guiDefaults.fiberList;
% 
% % Obtain the index of the user default fiber in the popup
% default_user_fiber = find(strcmp(obj.AppSettings.infoParams.FiberConfig, fiberList));
% if isempty(default_user_fiber)
%     default_user_fiber = 1;
% end
% 
% obj.gui.panel(thisPanel).fiberPopup = uicontrol(...
%     'Parent', obj.gui.panelFrame(thisPanel), ...
%     'Style', 'popupmenu', ...
%     'String', fiberList, ...
%     'Value', default_user_fiber, ...
%     'Enable', enableSet, ...
%     'FontSize', 12, ...
%     'Units', 'normalized', ...
%     'Position', [.375, .20, .26, .05], ...
%     'Callback', @fiber_popup_cb);
% 
% obj.gui.panel(thisPanel).fiberString = uicontrol(...
%     'Parent', obj.gui.panelFrame(thisPanel), ...
%     'Style', 'text', ...
%     'String', 'Fiber: ', ...
%     'FontSize', 12, ...
%     'FontWeight', 'bold', ...
%     'Units', 'normalized', ...
%     'Position', [.313, .205, .06, .04], ...
%     'BackgroundColor', [0.9, 0.9, 0.9] );
% 
% if default_user_fiber ~= 1
%     set(obj.gui.nextButton, 'Enable', 'on');
% end

%% Callbacks function

    function task_popup_cb(hObject, eventdata)
        valTask = get(hObject, 'Value');
        if valTask ~=1
            set(obj.gui.panel(thisPanel).foundryPopup, 'Enable', 'on');
        else
            set(obj.gui.panel(thisPanel).foundryPopup, 'Value', 1);
            set(obj.gui.panel(thisPanel).foundryPopup, 'Enable', 'off');
            set(obj.gui.panel(thisPanel).dieEdit, 'String', '-');
            set(obj.gui.panel(thisPanel).dieEdit, 'Enable', 'off');
            % set(obj.gui.panel(thisPanel).fiberPopup, 'Value', 1);
            % set(obj.gui.panel(thisPanel).fiberPopup, 'Enable', 'off');
            set(obj.gui.nextButton, 'Enable', 'off');
        end
        strTask = get(hObject, 'String');
        strTask = strTask{valTask};
        % Update current user setting
        obj.AppSettings.infoParams.Task = strTask;
    end

    function path_select_cb(hObject, eventdata)
        dirName = uigetdir(obj.AppSettings.path.testData, 'Select Test Data Path');
        if dirName ~= 0
            set(obj.gui.panel(thisPanel).pathDir, 'String', dirName);
            % Update current user setting
            obj.AppSettings.path.testData = dirName;
        end
    end

    function [chipList, default_user_chip, coordinateFilesDir] = updateChipMenu()
        coordinateFilesDir = strcat(obj.AppSettings.path.userData, obj.AppSettings.infoParams.Name, '\coordinateFiles\');
        coordinateFiles = dir(strcat(coordinateFilesDir, '*.txt'));
        if isempty(coordinateFiles)
            coordinateFilesDir = '.\defaults\coordinateFiles\';
            coordinateFiles = obj.guiDefaults.chipFiles; % Use default
        end
        
        chipList = obj.guiDefaults.chipList;
        % Query directory to get a list of coordinate files
        % format = <foundry>_<chipArchitecture>, <dieName> (specified by user)
        % examples: IME_A1, EB_400Q2R, etc.
        for ii = 1:length(coordinateFiles)
            chipName = coordinateFiles(ii).name;
            chipList{end+1} = chipName(1:end-4);
        end
        
        default_user_chip = find(strcmp(obj.AppSettings.infoParams.ChipArchitecture, chipList));
        if isempty(default_user_chip)
            default_user_chip = 1;
        elseif default_user_chip ~= 1
            strChip = chipList{default_user_chip};
            obj.chip = ChipClass(obj, strChip, coordinateFilesDir);
        end
    end

    function chip_popup_cb(hObject, eventdata, coordinateFilesDir)
        valChip = get(hObject, 'Value');
        strChip = get(hObject, 'String');
        strChip = strChip{valChip};
        if valChip ~=1
            obj.chip = [];
            set(obj.gui.panel(thisPanel).dieEdit, 'String', num2str(valChip - 1));
            set(obj.gui.panel(thisPanel).dieEdit, 'Enable', 'on');
            % set(obj.gui.panel(thisPanel).fiberPopup, 'Enable', 'on');
            % Update current user setting
            obj.AppSettings.infoParams.ChipArchitecture = strChip;
            
            strDie = get(obj.gui.panel(thisPanel).dieEdit, 'String');
            
            % Instantiate chip class and load devices into object
            obj.chip = ChipClass(obj, strChip, coordinateFilesDir);
        else
            set(obj.gui.panel(thisPanel).dieEdit, 'String', '-');
            set(obj.gui.panel(thisPanel).dieEdit, 'Enable', 'off');
            % set(obj.gui.panel(thisPanel).fiberPopup, 'Value', 1);
            % set(obj.gui.panel(thisPanel).fiberPopup, 'Enable', 'off');
            set(obj.gui.nextButton, 'Enable', 'off');
            % Added by Pavel to fix die# saving bug
            strDie = get(obj.gui.panel(thisPanel).dieEdit, 'String');
        end
        % Update current user setting
        obj.AppSettings.infoParams.DieNumber = strDie;
        if valChip ~=1 && ~(isempty(strDie) || strcmp(strDie, '-'))
            set(obj.gui.nextButton, 'Enable', 'on');
        end
    end

    function loadNewChip_cb(hObject, eventdata)
        msg = sprintf('Selected coordinates file will be copied to your user folder:\n%s\nand you can select them from the menu next time.', ...
            strcat(obj.AppSettings.path.userData, obj.AppSettings.infoParams.Name, '\coordinateFiles\'));
        uiwait(msgbox(msg, 'Add New Chip', 'modal'));
        [fileName, pathName] = uigetfile('.\defaults\coordinateFiles\*.txt', 'Select Test Data Path');
        if ~isequal(fileName, 0) && ~isequal(pathName, 0)
            sourceFileName = strcat(pathName, fileName);
            destinationFileName = strcat(obj.AppSettings.path.userData, obj.AppSettings.infoParams.Name, '\coordinateFiles\', fileName);
            updateChipMenu = true;
            if exist(destinationFileName, 'file') ~= 2 
                % File does not exist in user folder. Copy selected file into user folder
                [success, ~, ~] = copyfile(sourceFileName, destinationFileName, 'f');
            else % File already exist in user folder. Ask user for overwritten permission
                ButtonName = questdlg('Selected file already exist in your user folder. Do you want to overwrite it?', ...
                    'Warning!', ...
                    'Overwrite', 'Cancel', 'Cancel');
                if strcmpi(ButtonName, 'Overwrite')
                    [success, ~, ~] = copyfile(sourceFileName, destinationFileName, 'f');
                else
                    updateChipMenu = false;
                end
            end
            if updateChipMenu
                [newChipList, ~, newCoordinateFilesDir] = updateChipMenu();
                set(obj.gui.panel(thisPanel).foundryPopup, 'String', newChipList);
                valChip = find(strcmp(fileName(1:end-4), newChipList));
                if ~isempty(valChip) && valChip ~= 1
                    set(obj.gui.panel(thisPanel).foundryPopup, 'Value', valChip);
                    chip_popup_cb(obj.gui.panel(thisPanel).foundryPopup, [], newCoordinateFilesDir)
                end
            end
        end
    end

    function die_edit_cb(hObject, eventdata)
        strDie = get(hObject, 'String');
        if (isempty(strDie) || strcmp(strDie, '-'))
            % set(obj.gui.panel(thisPanel).fiberPopup, 'Value', 1);
            % set(obj.gui.panel(thisPanel).fiberPopup, 'Enable', 'off');
            set(obj.gui.nextButton, 'Enable', 'off');
        else
            % set(obj.gui.panel(thisPanel).fiberPopup, 'Enable', 'on');
            % Update current user setting
            obj.AppSettings.infoParams.DieNumber = strDie;
            set(obj.gui.nextButton, 'Enable', 'on');
        end
    end

%     function fiber_popup_cb(hObject, eventdata)
%         valFiber = get(hObject, 'Value');
%         strFiber = get(hObject, 'String');
%         strFiber = strFiber{valFiber};
%         if valFiber ~= 1
%             set(obj.gui.nextButton, 'Enable', 'on');
%             % Update current user setting
%             obj.AppSettings.infoParams.FiberConfig = strFiber;
%         else
%             set(obj.gui.nextButton, 'Enable', 'off');
%         end
%     end
end
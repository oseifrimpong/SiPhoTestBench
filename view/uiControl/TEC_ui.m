% � Copyright 2014-2015 WenXuan Wu, Shon Schmidt, and Jonas Flueckiger
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


% obj is the main testbench object
% --- build up a thermal control ui in the assigned panel (or popup)
% parentName is a string describing of the parent panel (or popup)
% --- 1. For popup: should be like 'manual', 'selectPeaks' ...
% --- 2. For panel: should be the same as in panel_index function
% parentObj is the parent object for the ui (type: double)
% Victor Bass 2013;
% Modified by Vince Wu - Nov 2013
% Modified by Pavel Kulik - Nov 2013

function obj = TEC_ui(obj, parentName, parentObj, position)

parentStruct = getParentStruct(parentName);
if (~isempty(strfind(parentStruct, 'panel')))
    panelIndex = str2double(parentStruct(end - 1));
    parentStruct = parentStruct(1:end - 3);
else
    panelIndex = 1;
end

% panel element size variables
stringBoxSize = [0.2, 0.2];
pushButtonSize = [0.2, 0.2];
editBoxSize = [0.1, 0.2];

% TEC panel
obj.gui.(parentStruct)(panelIndex).thermalControlUI.mainPanel = uipanel(...
    'parent', parentObj, ...
    'Unit','Pixels', ...
    'BackgroundColor', [0.9, 0.9, 0.9 ], ...
    'Visible','on', ...
    'units','normalized', ...
    'Title','Stage Thermal Control:', ...
    'FontWeight', 'bold', ...
    'FontSize', 9, ...
    'Position', position);

x_start = 0.03;
y_start = 0.7;

% target temp string
obj.gui.(parentStruct)(panelIndex).thermalControlUI.targetTempString = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).thermalControlUI.mainPanel, ...
    'Style','text', ...
    'HorizontalAlignment','left', ...
    'BackGroundColor', [0.9, 0.9, 0.9], ...
    'Units', 'normalized', ...
    'FontSize', 9, ...
    'Position', [x_start, y_start, stringBoxSize], ...
    'String', 'TargetT (C):');

x_align = x_start + 0.22;
y_align = y_start;

% target temp entry box
obj.gui.(parentStruct)(panelIndex).thermalControlUI.targetTempEdit = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).thermalControlUI.mainPanel, ...
    'Style', 'edit', ...
    'Enable', 'on', ...
    'Units', 'normalized', ...
    'Position', [x_align, y_align, editBoxSize], ...
    'FontSize', 8, ...
    'Visible', 'on', ...
    'String', 37, ...
    'Callback', {@target_temp_edit_cb, obj});

x_align = x_align + 0.125;

% target temp set button
obj.gui.(parentStruct)(panelIndex).thermalControlUI.tempSetButton =  uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).thermalControlUI.mainPanel, ...
    'Style', 'pushbutton', ...
    'Enable', 'on', ...
    'String', 'Set', ...
    'Visible', 'on', ...
    'FontSize', 9, ...
    'Units', 'normalized', ...
    'Position', [x_align, y_align, pushButtonSize], ...
    'Callback', {@temp_set_button_cb, obj, parentStruct, panelIndex});

x_align = x_align + 0.2;

% off button
obj.gui.(parentStruct)(panelIndex).thermalControlUI.OFFButton = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).thermalControlUI.mainPanel, ...
    'Style', 'pushbutton', ...
    'Enable', 'on', ...
    'String', 'Off', ...
    'Visible', 'on', ...
    'FontSize', 9, ...
    'Units', 'normalized', ...
    'Position', [x_align, y_align, pushButtonSize], ...
    'Callback', {@TEC_off_button_cb, obj, parentStruct, panelIndex});

x_align = x_align + 0.2;

% settings button
obj.gui.(parentStruct)(panelIndex).thermalControlUI.settingsButton = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).thermalControlUI.mainPanel, ...
    'Style', 'pushbutton', ...
    'Enable', 'on', ...
    'String', 'Settings', ...
    'Visible', 'on', ...
    'FontSize', 9, ...
    'Units', 'normalized', ...
    'Position', [x_align, y_align, pushButtonSize], ...
    'Callback', {@TEC_settings_button_cb, obj, parentStruct, panelIndex});

x_align = x_start;
y_align = y_start - 0.5;

% current temp string
obj.gui.(parentStruct)(panelIndex).thermalControlUI.currentTempString = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).thermalControlUI.mainPanel, ...
    'Style','text', ...
    'HorizontalAlignment','left', ...
    'BackGroundColor', [0.9, 0.9, 0.9], ...
    'Units', 'normalized', ...
    'FontSize', 9, ...
    'Position', [x_align, y_align, stringBoxSize], ...
    'String', 'CurrentT (C):');

% current temp display
try
    currentTemp = str2double(obj.instr.thermalControl.currentTemp());
catch ME
    disp(ME.message);
    currentTemp = obj.AppSettings.TECParams.DefaultTemp;
end
currentTemp = round(currentTemp*10) / 10;

x_align = x_start + 0.25;

obj.gui.(parentStruct)(panelIndex).thermalControlUI.currentTempEdit = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).thermalControlUI.mainPanel, ...
    'Style', 'edit', ...
    'Enable', 'on', ...
    'Units', 'normalized', ...
    'Position', [x_align, y_align, editBoxSize], ...
    'FontSize', 8, ...
    'Visible', 'on', ...
    'String', currentTemp);

x_align = x_align + 0.15;

% % update temp checkbox string
% obj.gui.(parentStruct)(panelIndex).thermalControlUI.updateTempString = uicontrol(...
%     'Parent', obj.gui.(parentStruct)(panelIndex).thermalControlUI.mainPanel, ...
%     'Style', 'text', ...
%     'Enable', 'on', ...
%     'String', 'Update:', ...
%     'Visible', 'on', ...
%     'Units', 'normalized', ...
%     'FontSize', 9, ...
%     'Position', [x_align, y_align, stringBoxSize]);
% 
% x_align = x_align + 0.2;

% % update temp checkbox
% obj.gui.(parentStruct)(panelIndex).thermalControlUI.updateTempCheck = uicontrol(...
%     'Parent', obj.gui.(parentStruct)(panelIndex).thermalControlUI.mainPanel, ...
%     'Style', 'checkbox', ...
%     'Enable', 'on', ...
%     'Visible', 'on', ...
%     'Units', 'normalized', ...
%     'Position', [x_align, y_align, .075, .2], ...
%     'Callback', {@TEC_update_temp_checkbox_cb, obj, parentStruct, panelIndex});

% update temp push button
obj.gui.(parentStruct)(panelIndex).thermalControlUI.updateTempButton = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).thermalControlUI.mainPanel, ...
    'Style', 'pushbutton', ...
    'Enable', 'on', ...
    'String', 'Read Temp',...
    'Visible', 'on', ...
    'Units', 'normalized', ...
    'Position', [x_align, y_align, .2, .2], ...
    'Callback', {@TEC_update_temp_button_cb, obj, parentStruct, panelIndex});

x_align = x_align + 0.25;

% temp set display string
obj.gui.(parentStruct)(panelIndex).thermalControlUI.tempSetString = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).thermalControlUI.mainPanel, ...
    'Style','text', ...
    'HorizontalAlignment','left', ...
    'BackGroundColor', [0.9, 0.9, 0.9], ...
    'Units', 'normalized', ...
    'FontSize', 9, ...
    'Position', [x_align, y_align, stringBoxSize], ...
    'String', 'Heating:');

x_align = x_align + 0.15;

% temp set color display
obj.gui.(parentStruct)(panelIndex).thermalControlUI.TECIndicator = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).thermalControlUI.mainPanel, ...
    'Style','text', ...
    'BackGroundColor', [1, 0, 0], ...
    'Visible', 'on', ...
    'Enable', 'off', ...
    'Units', 'normalized', ...
    'Position', [x_align, y_align, .05, .175]);

% set color indicator if already on...
if obj.instr.thermalControl.Busy % is already on
        set(obj.gui.(parentStruct)(panelIndex).thermalControlUI.TECIndicator, ...
            'BackgroundColor', [0, 1, 0]); % make display box green
end

end

%% Callbacks
    function target_temp_edit_cb(hObject, ~, obj)
        targetTemp = str2double(get(hObject, 'String'));
        obj.instr.thermalControl.setTargetTemp(targetTemp);
    end

    function temp_set_button_cb(~, ~, obj, parentStruct, panelIndex)
        target_temp_edit_cb(obj.gui.(parentStruct)(panelIndex).thermalControlUI.targetTempEdit, [], obj);
        obj.instr.thermalControl.start();
        set(obj.gui.(parentStruct)(panelIndex).thermalControlUI.TECIndicator, ...
            'BackgroundColor', [0, 1, 0]); % make display box green
    end

%     function TEC_update_temp_checkbox_cb(hObject, ~, obj, parentStruct, panelIndex)
%         isChecked = get(hObject, 'Value');
%         if isChecked
%             obj.timer.TECTempReadTimer = timer(...
%                 'Name', 'TEC Temp Read Timer', ...
%                 'ExecutionMode', 'fixedRate', ...
%                 'BusyMode', 'drop', ...
%                 'Period', obj.instr.thermalControl.Param.UpdatePeriod, ...
%                 'TimerFcn', {@updateValues, obj, parentStruct, panelIndex});
%             start(obj.timer.TECTempReadTimer);
%         else
%             stop(obj.timer.TECTempReadTimer);
%             delete(obj.timer.TECTempReadTimer);
%         end
%     end

%     function updateValues(~, ~, obj, parentStruct, panelIndex)
%         temp = str2double(obj.instr.thermalControl.currentTemp());
%         temp = num2str(round(temp*10)/10);
%         set(obj.gui.(parentStruct)(panelIndex).thermalControlUI.currentTempEdit, 'String', temp);
%     end

    function TEC_update_temp_button_cb(~, ~, obj, parentStruct, panelIndex)
        temp = str2double(obj.instr.thermalControl.currentTemp());
        temp = num2str(round(temp*10)/10);
        set(obj.gui.(parentStruct)(panelIndex).thermalControlUI.currentTempEdit, 'String', temp);
    end

    function TEC_off_button_cb(~, ~, obj, parentStruct, panelIndex)
        obj.instr.thermalControl.stop;
        % delete timer and uncheck box
%         stop(obj.timer.TECTempReadTimer);
%         delete(obj.timer.TECTempReadTimer);
        set(obj.gui.(parentStruct)(panelIndex).thermalControlUI.currentTempEdit, 'String', '-');
%        set(obj.gui.(parentStruct)(panelIndex).thermalControlUI.updateTempCheck, 'Value', false)
        set(obj.gui.(parentStruct)(panelIndex).thermalControlUI.TECIndicator, 'BackgroundColor', [1, 0, 0]); % make display box red
    end

    function TEC_settings_button_cb(~, ~, obj,parentStruct, panelIndex)
         obj.settingsWin('TEC');
    end

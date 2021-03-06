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
% --- build up a alignment control ui in the assigned panel (or popup)
% parentName is a string describing of the parent panel (or popup)
% --- 1. For popup: should be like 'manual', 'selectPeaks' ...
% --- 2. For panel: should be the same as in panel_index function
% parentObj is the parent object for the ui (type: double)
% heatMapDispHandle is the heat map axe handle for MAP GC results
% Victor Bass 2013;
% Modified by Vince Wu - Nov 2013

function [obj, panelH] = align_ui(obj, parentName, parentObj, position, heatMapDispHandle)

parentStruct = getParentStruct(parentName);
if (~isempty(strfind(parentStruct, 'panel')))
    panelIndex = str2double(parentStruct(end - 1));
    parentStruct = parentStruct(1:end - 3);
else
    panelIndex = 1;
end

%% Align Panel
% panel element size variables
buttonSize = [0.3, 0.25];

% align parent panel
obj.gui.(parentStruct)(panelIndex).alignUI.mainPanel = uipanel(...
    'Parent', parentObj, ...
    'Units', 'normalized', ...
    'Visible', 'on', ...
    'BackgroundColor', [0.9, 0.9, 0.9], ...
    'Title', 'Align', ...
    'FontSize', 10, ...
    'FontWeight', 'Bold', ...
    'Position', position);

panelH = obj.gui.(parentStruct)(panelIndex).alignUI.mainPanel;

% fine align button
obj.gui.(parentStruct)(panelIndex).alignUI.fine_align_button = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).alignUI.mainPanel, ...
    'Style', 'pushbutton', ...
    'Enable', 'on', ...
    'Units', 'normalized', ...
    'String', 'Fine Align', ...
    'FontSize', 8, ...
    'Position', [0.01, 0.7, buttonSize], ...
    'Callback', {@fine_align_cb, obj, parentStruct, panelIndex});

% % course align button
% obj.gui.(parentStruct)(panelIndex).alignUI.course_align_button = uicontrol(...
%     'Parent', obj.gui.(parentStruct)(panelIndex).alignUI.mainPanel, ...
%     'Style', 'pushbutton', ...
%     'Enable', 'on', ...
%     'Units', 'normalized', ...
%     'String', 'Course Align', ...
%     'FontSize', 8, ...
%     'Position', [0.01, 0.55, buttonSize], ...
%     'Callback', {@course_align_cb, obj, parentStruct, panelIndex});

% map GC button
obj.gui.(parentStruct)(panelIndex).alignUI.mapGC_button = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).alignUI.mainPanel, ...
    'Style', 'pushbutton', ...
    'Enable', 'on', ...
    'Units', 'normalized', ...
    'String', 'Map GC', ...
    'FontSize', 8, ...
    'Position', [0.01, 0.4, buttonSize], ...
    'Callback', {@mapGC_cb, obj, parentStruct, panelIndex, heatMapDispHandle});

% snap to GC button
obj.gui.(parentStruct)(panelIndex).alignUI.snapGC_button = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).alignUI.mainPanel, ...
    'Style', 'pushbutton', ...
    'Enable', 'on', ...
    'Units', 'normalized', ...
    'String', 'Snap to GC', ...
    'FontSize', 8, ...
    'Position', [0.01, 0.1, buttonSize], ...
    'Callback', {@snap_gc_cb, obj, heatMapDispHandle});

%% Abort Buttons
% fine align abort
obj.gui.(parentStruct)(panelIndex).alignUI.fine_align_abort_button = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).alignUI.mainPanel, ...
    'Style', 'pushbutton', ...
    'Enable', 'on', ...
    'Units', 'normalized', ...
    'String', 'Abort', ...
    'FontSize', 8, ...
    'Position', [0.35, 0.7, buttonSize], ...
    'Callback', @abort_fine_align_cb);

% % course align abort
% obj.gui.(parentStruct)(panelIndex).alignUI.course_align_abort_button = uicontrol(...
%     'Parent', obj.gui.(parentStruct)(panelIndex).alignUI.mainPanel, ...
%     'Style', 'pushbutton', ...
%     'Enable', 'on', ...
%     'Units', 'normalized', ...
%     'String', 'Abort', ...
%     'FontSize', 8, ...
%     'Position', [0.35, 0.55, buttonSize], ...
%     'Callback', @abort_course_align_cb);

% map gc abort
obj.gui.(parentStruct)(panelIndex).alignUI.mapGC_abort_button = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).alignUI.mainPanel, ...
    'Style', 'pushbutton', ...
    'Enable', 'on', ...
    'Units', 'normalized', ...
    'String', 'Abort', ...
    'FontSize', 8, ...
    'Position', [0.35, 0.4, buttonSize], ...
    'Callback', @abort_map_gc_cb);

%% Settings Buttons
% fine align settings
obj.gui.(parentStruct)(panelIndex).alignUI.fine_settings_button = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).alignUI.mainPanel, ...
    'Style', 'pushbutton', ...
    'Enable', 'on', ...
    'Units', 'normalized', ...
    'String', 'Settings', ...
    'FontSize', 8, ...
    'Position', [0.69, 0.7, buttonSize], ...
    'Callback', {@settings_fine_align_cb, obj});

% % course align settings
% obj.gui.(parentStruct)(panelIndex).alignUI.course_settings_button = uicontrol(...
%     'Parent', obj.gui.(parentStruct)(panelIndex).alignUI.mainPanel, ...
%     'Style', 'pushbutton', ...
%     'Enable', 'on', ...
%     'Units', 'normalized', ...
%     'String', 'Settings', ...
%     'FontSize', 8, ...
%     'Position', [0.69, 0.55, buttonSize], ...
%     'Callback', {@settings_course_align_cb, obj});

% map gc settings
obj.gui.(parentStruct)(panelIndex).alignUI.mapGC_settings_button = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).alignUI.mainPanel, ...
    'Style', 'pushbutton', ...
    'Enable', 'on', ...
    'Units', 'normalized', ...
    'String', 'Settings', ...
    'FontSize', 8, ...
    'Position', [0.69, 0.4, buttonSize], ...
    'Callback', {@settings_map_gc_cb, obj});

end

%% Callback Functions
    function fine_align_cb(hObject, ~, obj, parentStruct, panelIndex)
        set(hObject, 'Enable', 'off');
        set(obj.gui.(parentStruct)(panelIndex).alignUI.fine_align_abort_button, 'UserData', 0);
        set(obj.gui.(parentStruct)(panelIndex).alignUI.fine_align_abort_button, 'Enable', 'on');
        try
            fine_align(obj, parentStruct,panelIndex);
        catch ME
            set(obj.gui.(parentStruct)(panelIndex).alignUI.fine_align_button, 'Enable', 'on');
            rethrow(ME);
        end
        set(hObject, 'Enable', 'on');
    end

%     function course_align_cb(hObject, ~, obj, parentStruct, panelIndex)
%         set(hObject, 'Enable', 'off');
%         set(obj.gui.(parentStruct)(panelIndex).alignUI.course_align_abort_button, 'UserData', 0);
%         set(obj.gui.(parentStruct)(panelIndex).alignUI.course_align_abort_button, 'Enable', 'on');
%         try
%             coarse_align(obj,parentStruct,panelIndex);
%         catch ME
%             set(obj.gui.(parentStruct)(panelIndex).alignUI.course_align_button, 'Enable', 'on');
%             rethrow(ME);
%         end
%         set(hObject, 'Enable', 'on');
%     end

    function mapGC_cb(hObject, ~, obj, parentStruct, panelIndex, heatMapDispHandle)
        set(hObject, 'Enable', 'off');
        set(obj.gui.(parentStruct)(panelIndex).alignUI.mapGC_abort_button, 'UserData', 0);
        set(obj.gui.(parentStruct)(panelIndex).alignUI.mapGC_abort_button, 'Enable', 'on');
        try
            map_gc(obj, parentStruct, panelIndex, heatMapDispHandle);
        catch ME
            set(obj.gui.(parentStruct)(panelIndex).alignUI.mapGC_button, 'Enable', 'on');
            rethrow(ME);
        end
        set(hObject, 'Enable', 'on');
    end

    function snap_gc_cb(~, ~, obj, heatMapDispHandle)
        get_gc(obj, heatMapDispHandle);
    end

    function abort_fine_align_cb(hObject, ~)
        % abort fine align
        set(hObject, 'UserData', 1);
        % disable button once set
        set(hObject, 'Enable', 'off');
    end

%     function abort_course_align_cb(hObject, ~)
%         % abort course align
%         set(hObject, 'UserData', 1);
%         % disable button once set
%         set(hObject, 'Enable', 'off');
%     end

    function abort_map_gc_cb(hObject, ~)
        % abort map gc
        set(hObject, 'UserData', 1);
        % disable button once set
        set(hObject, 'Enable', 'off');
    end

    function settings_fine_align_cb(~, ~, obj)
        % settings fine align
        obj.settingsWin('FAParams');
    end

%     function settings_course_align_cb(~, ~, obj)
%         % settings course align
%         obj.settingsWin('CAParams');
%     end

    function settings_map_gc_cb(~, ~, obj)
        % settings map gc
        obj.settingsWin('MappingParams');
    end

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
% --- build up a drt test control ui in the assigned panel (or popup)
% parentName is a string describing of the parent panel (or popup)
% --- 1. For popup: should be like 'manual', 'selectPeaks' ...
% --- 2. For panel: should be the same as in panel_index function
% parentObj is the parent object for the ui (type: double)
% Victor Bass 2013;
% Modified by Vince Wu - Nov 2013

function obj = dry_test_ui(obj, parentName, parentObj, position)

parentStruct = getParentStruct(parentName);
if (~isempty(strfind(parentStruct, 'panel')))
    panelIndex = str2double(parentStruct(end - 1));
    parentStruct = parentStruct(1:end - 3);
else
    panelIndex = 1;
end

%% Dry Test Panel
% panel element size variables
pushButtonSize = [0.25, 0.05];
stringBoxSize = [0.5, 0.05];

testType = obj.AppSettings.infoParams.Task;
if strfind(lower(testType), 'wet')
    testType = 'Wet';
else
    testType = 'Dry';
end
% parent panel
obj.gui.(parentStruct)(panelIndex).dryTestUI.mainPaenl = uipanel(...
    'Parent', parentObj, ...
    'Unit', 'Pixels', ...
    'Units', 'normalized', ...
    'Visible', 'on', ...
    'BackgroundColor', [0.9, 0.9, 0.9], ...
    'Title', [testType, ' Test'], ...
    'FontSize', 10, ...
    'FontWeight', 'Bold', ...
    'Position', position);

% shon - moved realtime rating and save plot options to settings 8/24/2013
% % real time rating string
% obj.gui.(parentStruct)(panelIndex).dryTestUI.control_ui.dry_test.real_time_rating_string = uicontrol(...
%     'Parent', obj.gui.(parentStruct)(panelIndex).dryTestUI.mainPaenl, ...
%     'Style', 'text', ...
%     'HorizontalAlignment','left', ...
%     'BackgroundColor', [0.9, 0.9, 0.9], ...
%     'Units', 'normalized', ...
%     'String', 'Rate RT:', ...
%     'FontSize', 9, ...
%     'Position', [0.05, 0.94, stringBoxSize]);
%
% % real time rating checkbox
% obj.gui.(parentStruct)(panelIndex).dryTestUI.control_ui.dry_test.real_time_rating_checkbox = uicontrol(...
%     'Parent', obj.gui.(parentStruct)(panelIndex).dryTestUI.mainPaenl, ...
%     'Style', 'checkbox', ...
%     'BackgroundColor', [0.9, 0.9, 0.9], ...
%     'Enable', 'on', ...
%     'Units', 'normalized', ...
%     'Position', [0.25, 0.95, pushButtonSize], ...
%     'Callback', {@real_time_rating_checkbox_cb, obj});
%
%
% % save plot string
% obj.gui.(parentStruct)(panelIndex).dryTestUI.control_ui.dry_test.save_plot_string = uicontrol(...
%     'Parent', obj.gui.(parentStruct)(panelIndex).dryTestUI.mainPaenl, ...
%     'Style', 'text', ...
%     'HorizontalAlignment','left', ...
%     'BackgroundColor', [0.9, 0.9, 0.9], ...
%     'Units', 'normalized', ...
%     'String', 'Save plot:', ...
%     'FontSize', 9, ...
%     'Position', [0.05, 0.9, stringBoxSize]);
%
% % save plot checkbox
% obj.gui.(parentStruct)(panelIndex).dryTestUI.control_ui.dry_test.save_plot_checkbox = uicontrol(...
%     'Parent', obj.gui.(parentStruct)(panelIndex).dryTestUI.mainPaenl, ...
%     'Style', 'checkbox', ...
%     'BackgroundColor', [0.9, 0.9, 0.9], ...
%     'Enable', 'on', ...
%     'Units', 'normalized', ...
%     'Position', [0.25, 0.9, pushButtonSize], ...
%     'Callback', {@save_plot_checkbox_cb, obj});

% test summary string
obj.gui.(parentStruct)(panelIndex).dryTestUI.summaryString = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).dryTestUI.mainPaenl, ...
    'Style', 'text', ...
    'HorizontalAlignment','left', ...
    'BackgroundColor', [0.9, 0.9, 0.9], ...
    'Units', 'normalized', ...
    'FontWeight', 'Bold', ...
    'String', 'Test summary:', ...
    'FontSize', 9, ...
    'Position', [0.05, 0.85, stringBoxSize]);

% reset button
obj.gui.(parentStruct)(panelIndex).dryTestUI.settingsButton = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).dryTestUI.mainPaenl, ...
    'Style', 'pushbutton', ...
    'Enable', 'on', ...
    'Units', 'normalized', ...
    'String', 'Reset', ...
    'FontSize', 9, ...
    'Position', [0.15, 0.95, pushButtonSize], ...
    'Callback', {@reset_button_cb, obj, parentStruct, panelIndex});

% settings button
obj.gui.(parentStruct)(panelIndex).dryTestUI.settingsButton = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).dryTestUI.mainPaenl, ...
    'Style', 'pushbutton', ...
    'Enable', 'on', ...
    'Units', 'normalized', ...
    'String', 'Settings', ...
    'FontSize', 9, ...
    'Position', [0.65, 0.95, pushButtonSize], ...
    'Callback', {@settings_button_cb, obj});

%% summary table

numSelectedDetectors=sum(obj.instr.detector.getProp('SelectedDetectors'));
cnames = cell(1,numSelectedDetectors+2);

cformat = repmat({'char'},1,numSelectedDetectors+2);
ceditable = false(1,numSelectedDetectors+2);
ccolumnwidth = cell(1,numSelectedDetectors+2);
ccolumnwidth{1} = 115;
ccolumnwidth(end)={7200};
for d=1:numSelectedDetectors
    ccolumnwidth{d+1}=35;
    cnames{d+1}=sprintf('Ch#%d',d);
end
cnames{1}=  'Device ID';
cnames{end} = 'Comment';

deviceName = fieldnames(obj.devices);


% Preallocate data cell for the table.  
numDevices = 0;
for j = 1:obj.AppSettings.dryTest.Iterations % this will be a bug, if the user changes after table is built
    for i = 1:length(deviceName)
        if obj.devices.(deviceName{i}).getProp('Selected')
            numDevices = numDevices + 1;
        end
    end
end
obj.gui.(parentStruct)(panelIndex).dryTestUI.deviceTable = cell(numDevices,numSelectedDetectors+2);


% need to make summary table accessable to scripts to update status column from scripts
table_index = 0;

% get a list of devices to be tested
for j = 1:obj.AppSettings.dryTest.Iterations % this will be a bug, if the user changes after table is built
    for i = 1:length(deviceName)
        if obj.devices.(deviceName{i}).getProp('Selected')
            table_index = table_index + 1;
            dataRow=cell(1,numSelectedDetectors+2);
            dataRow{1}=obj.devices.(deviceName{i}).Name;
            dataRow(2:end-1)=repmat({getCellColor(obj.devices.(deviceName{i}).getProp('Rating'))},1,numSelectedDetectors);
            dataRow{end} = obj.devices.(deviceName{i}).Comment;
            obj.gui.(parentStruct)(panelIndex).dryTestUI.deviceTable(table_index,:)=dataRow;            
        end
    end
end

obj.gui.(parentStruct)(panelIndex).dryTestUI.resultTable = uitable(...
    'Parent', obj.gui.(parentStruct)(panelIndex).dryTestUI.mainPaenl, ...
    'ColumnName', cnames, ...
    'ColumnFormat', cformat, ...
    'ColumnEditable', ceditable, ...
    'Units','normalized', ...
    'Position', [0.01,0.01,0.98,0.92], ...
    'Data', obj.gui.(parentStruct)(panelIndex).dryTestUI.deviceTable, ...
    'FontSize', 9, ...
    'ColumnWidth',ccolumnwidth, ...
    'Enable','on', ...
    'Visible', 'on');

end

%% Callbacks
function settings_button_cb(~, ~, obj)
obj.settingsWin('dryTest');
end

function reset_button_cb(~, ~, obj, parentStruct, panelIndex)
% reset device scan number back to 1
% reset rate device result in panel

% Preallocate data cell for the table.  
numSelectedDetectors=sum(obj.instr.detector.getProp('SelectedDetectors'));

numDevices = 0;

deviceNames = fieldnames(obj.devices);
for j = 1:obj.AppSettings.dryTest.Iterations % this will be a bug, if the user changes after table is built
    for i = 1:length(deviceNames)
        if obj.devices.(deviceNames{i}).getProp('Selected')
            numDevices = numDevices + 1;
        end
    end
end
obj.gui.(parentStruct)(panelIndex).dryTestUI.deviceTable = cell(numDevices,numSelectedDetectors+2);


for ii = 1:length(deviceNames)
    if obj.devices.(deviceNames{ii}).getProp('Selected')
        obj.devices.(deviceNames{ii}).resetScanNumber();
        obj.devices.(deviceNames{ii}).resetRating();
    end
end

% redraw table
table_index = 0;
deviceNames = fieldnames(obj.devices);
for j = 1:obj.AppSettings.dryTest.Iterations % this will be a bug, if the user changes after table is built
    for i = 1:length(deviceNames)
        if obj.devices.(deviceNames{i}).getProp('Selected')
            table_index = table_index + 1;
            dataRow=cell(1,numSelectedDetectors+2);
            dataRow{1}=obj.devices.(deviceNames{i}).Name;
            dataRow(2:end-1)=repmat({getCellColor(obj.devices.(deviceNames{i}).getProp('Rating'))},1,numSelectedDetectors);
            dataRow{end} = obj.devices.(deviceNames{i}).Comment;
            obj.gui.(parentStruct)(panelIndex).dryTestUI.deviceTable(table_index,:)=dataRow;            
            
%             obj.gui.(parentStruct)(panelIndex).dryTestUI.deviceTable{table_index, 1} = ...
%                 obj.devices.(deviceNames{i}).Name;
%             obj.gui.(parentStruct)(panelIndex).dryTestUI.deviceTable{table_index, 2:     numSelectedDetectors} = ...
%                 repmat( {getCellColor(obj.devices.(deviceNames{i}).getProp('Rating'))},1,numSelectedDetectors);
%             obj.gui.(parentStruct)(panelIndex).dryTestUI.deviceTable{table_index, end} = ...
%                 obj.devices.(deviceNames{i}).Comment;
        end
    end
end
set(obj.gui.(parentStruct)(panelIndex).dryTestUI.resultTable, ...
    'Data', ...
    obj.gui.(parentStruct)(panelIndex).dryTestUI.deviceTable);
end

% function real_time_rating_checkbox_cb(hObject, eventdata, obj, parentStruct)
% %    isChecked = get(obj.gui.(parentStruct)(panelIndex).dryTestUI.control_ui.dry_test.real_time_rating_checkbox, 'Value');
% end
%
% function save_plot_checkbox_cb(hObject, eventdata, obj)
% %    isChecked = get(obj.gui.(parentStruct)(panelIndex).dryTestUI.control_ui.dry_test.real_time_rating_checkbox, 'Value');
% end

%Input device test result, return cell color in HEX for table.
function color = getCellColor(result)
%Untested
color = '<html><table border=0 width=400 bgcolor=#404040><TR height=100><TD>&nbsp;</TD></TR> </table></html>'; %gray
%Pass
if strcmpi(result, 'Pass')
    color = '<html><table border=0 width=400 bgcolor=#7CFC00><TR height=100><TD>&nbsp;</TD></TR> </table></html>'; %green
end
%Fail
if strcmpi(result, 'Fail')
    color = '<html><table border=0 width=400 bgcolor=#FF0000><TR height=100><TD>&nbsp;</TD></TR> </table></html>'; %red
end
end

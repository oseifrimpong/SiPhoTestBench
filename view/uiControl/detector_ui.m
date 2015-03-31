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
% --- build up a detector control ui in the assigned panel (or popup)
% parentName is a string describing of the parent panel (or popup)
% --- 1. For popup: should be like 'manual', 'selectPeaks' ...
% --- 2. For panel: should be the same as in panel_index function
% parentObj is the parent object for the ui (type: double)
% Victor Bass 2013;
% Modified by Vince Wu - Nov 2013

function obj = detector_ui(obj, parentName, parentObj, position)

parentStruct = getParentStruct(parentName);
if (~isempty(strfind(parentStruct, 'panel')))
    % e.g. panel(3)
    panelIndex = str2double(parentStruct(end - 1));
    parentStruct = parentStruct(1:end - 3);
else
    panelIndex = 1;
end

% panel element size variables
stringBoxSize = [0.21, 0.12];
pushButtonSize = [0.275, 0.15];

% detector panel
obj.gui.(parentStruct)(panelIndex).detectorUI.mainPanel = uipanel(...
    'Parent', parentObj, ...
    'BackgroundColor', [0.9, 0.9 0.9], ...
    'Visible','on', ...
    'Units','normalized', ...
    'Title','Detector', ...
    'FontSize', 9, ...
    'FontWeight','bold', ...
    'Position', position);

% auto update string
obj.gui.(parentStruct)(panelIndex).detectorUI.detectorUpdateString = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).detectorUI.mainPanel, ...
    'Style', 'text', ...
    'BackgroundColor', [0.9, 0.9, 0.9], ...
    'Units', 'normalized', ...
    'String', 'Auto-update', ...
    'HorizontalAlignment', 'left', ...
    'FontSize', 9, ...
    'Position', [.025, .84, stringBoxSize]);

% auto update checkbox
obj.gui.(parentStruct)(panelIndex).detectorUI.detectorUpdateCheckbox = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).detectorUI.mainPanel, ...
    'Style', 'checkbox', ...
    'BackgroundColor', [0.9, 0.9, 0.9], ...
    'Enable', 'on', ...
    'Units', 'normalized', ...
    'Position', [0.196, 0.84, 0.06, 0.12], ...
    'Callback', {@detector_auto_update_cb, obj, parentStruct, panelIndex});

% settings button
obj.gui.(parentStruct)(panelIndex).detectorUI.detectorSettingButton = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).detectorUI.mainPanel, ...
    'Style', 'pushbutton', ...
    'Enable', 'on', ...
    'Units', 'normalized', ...
    'Position', [.7, .85, pushButtonSize], ...
    'String', 'Settings', ...
    'Callback', {@detector_settings_cb, obj});

% detector string
obj.gui.(parentStruct)(panelIndex).detectorUI.detectorString = uicontrol(...
    'parent', obj.gui.(parentStruct)(panelIndex).detectorUI.mainPanel, ...
    'Style','text', ...
    'BackgroundColor',[0.9 0.9 0.9 ], ...
    'HorizontalAlignment','left', ...
    'Units', 'normalized', ...
    'Position', [.025, .675, stringBoxSize], ...
    'String', 'Detector', ...
    'FontSize', 9);

% slot string
obj.gui.(parentStruct)(panelIndex).detectorUI.slotString = uicontrol(...
    'parent', obj.gui.(parentStruct)(panelIndex).detectorUI.mainPanel, ...
    'Style','text', ...
    'BackgroundColor',[0.9 0.9 0.9 ], ...
    'HorizontalAlignment','left', ...
    'Units', 'normalized', ...
    'Position', [.21, .675, stringBoxSize], ...
    'String', 'Slot', ...
    'FontSize', 9);

% channel string
obj.gui.(parentStruct)(panelIndex).detectorUI.channelString = uicontrol(...
    'parent', obj.gui.(parentStruct)(panelIndex).detectorUI.mainPanel, ...
    'Style','text', ...
    'BackgroundColor',[0.9 0.9 0.9 ], ...
    'HorizontalAlignment','left', ...
    'Units', 'normalized', ...
    'Position', [.34, .675, stringBoxSize], ...
    'String', 'Channel', ...
    'FontSize', 9);

% power string
try
    if obj.instr.laser.getParam('PowerUnit') == 0
        unit_str = 'dB';
    elseif obj.instr.laser.getParam('PowerUnit') == 1
        unit_str = 'W';
    end
catch ME
    msg = [obj.instr.laser.Name, ': Could not set laser power unit!'];
    obj.msg(msg);
    disp(ME.Message);
    unit_str = '??';
end

obj.gui.(parentStruct)(panelIndex).detectorUI.powerUnit = uicontrol(...
    'parent', obj.gui.(parentStruct)(panelIndex).detectorUI.mainPanel, ...
    'Style','text', ...
    'BackgroundColor',[0.9 0.9 0.9 ], ...
    'HorizontalAlignment','left', ...
    'Units', 'normalized', ...
    'Position', [.514, .675, stringBoxSize], ...
    'String', ['Power ','(',unit_str,')'], ...
    'FontSize', 9);

% include detector string
obj.gui.(parentStruct)(panelIndex).detectorUI.includeDetectorString = uicontrol(...
    'parent', obj.gui.(parentStruct)(panelIndex).detectorUI.mainPanel, ...
    'Style','text', ...
    'BackgroundColor',[0.9 0.9 0.9 ], ...
    'HorizontalAlignment','left', ...
    'Units', 'normalized', ...
    'Position', [.746, .675, stringBoxSize], ...
    'String', 'Include:', ...
    'FontSize', 9);


% for loop to draw ui's for each detector
numOfDetectors = obj.instr.detector.getProp('NumOfDetectors');
detectorBoxSize = [.1, min(.45/numOfDetectors, 0.16)];
selectedDetectors = obj.instr.detector.getProp('SelectedDetectors');
for i = 1:numOfDetectors
    [slot, channel] = obj.instr.detector.switchDetector(i);
    % loop position offset variable
    yVal = 0.49 - (i-1)*(detectorBoxSize(2) + 0.02);
    % detector number string
    obj.gui.(parentStruct)(panelIndex).detectorUI.detectorNums(i) = uicontrol(...
        'Parent', obj.gui.(parentStruct)(panelIndex).detectorUI.mainPanel, ...
        'Style', 'text', ...
        'BackgroundColor', [0.9, 0.9 0.9], ...
        'Units', 'normalized', ...
        'String', i, ...
        'FontSize', 8, ...
        'Position', [.0354, yVal, detectorBoxSize]);
    
    % detector slot number
    obj.gui.(parentStruct)(panelIndex).detectorUI.slotNums(i) = uicontrol(...
        'Parent', obj.gui.(parentStruct)(panelIndex).detectorUI.mainPanel, ...
        'Style', 'text', ...
        'BackgroundColor', [0.9, 0.9 0.9], ...
        'Units', 'normalized', ...
        'String', slot, ...
        'FontSize', 8, ...
        'Position', [.19, yVal, detectorBoxSize]);
    
    % detector channel number
    obj.gui.(parentStruct)(panelIndex).detectorUI.channelNum(i) = uicontrol(...
        'Parent', obj.gui.(parentStruct)(panelIndex).detectorUI.mainPanel, ...
        'Style', 'text', ...
        'BackgroundColor', [0.9, 0.9 0.9], ...
        'Units', 'normalized', ...
        'String', channel, ...
        'FontSize', 8, ...
        'Position', [.346, yVal, detectorBoxSize]);
    
    % detector power value
    power = obj.instr.detector.readPower(i);
    powerStr = sprintf('%0.1f', power);
    obj.gui.(parentStruct)(panelIndex).detectorUI.detectorPower(i) = uicontrol(...
        'Parent', obj.gui.(parentStruct)(panelIndex).detectorUI.mainPanel, ...
        'Style', 'text', ...
        'BackgroundColor', [0.9, 0.9 0.9], ...
        'Units', 'normalized', ...
        'String', powerStr, ...
        'FontSize', 8, ...
        'Position', [.49, yVal, .2, detectorBoxSize(2)]);
    
    % include detector
    % enable by default (Value = true)
    obj.gui.(parentStruct)(panelIndex).detectorUI.includeDetector(i) = uicontrol(...
        'Parent', obj.gui.(parentStruct)(panelIndex).detectorUI.mainPanel, ...
        'Style', 'checkbox', ...
        'BackgroundColor', [0.9, 0.9, 0.9], ...
        'Enable', 'on', ...
        'Value', selectedDetectors(i),...
        'Units', 'normalized', ...
        'Position', [0.784, yVal + 0.03 , 0.06, 0.12], ...
        'Callback', {@include_detector_checkbox_cb, obj, i, parentStruct, panelIndex});
end

end

%% Callback Functions
function detector_settings_cb(~, ~, obj)
obj.instr.detector.settingsWin;
end

function updatePowerValues(~,~,obj, parentStruct, panelIndex)
numOfDetectors = obj.instr.detector.getProp('NumOfDetectors');
selectedDetectors = obj.instr.detector.getProp('SelectedDetectors');
for j = 1:numOfDetectors
    selected = selectedDetectors(j);
    if selected
        powerValues = obj.instr.detector.readPower(j);
        powerStr = sprintf('%0.1f', powerValues);
        set(obj.gui.(parentStruct)(panelIndex).detectorUI.detectorPower(j), 'String', powerStr);
    end
end
end

function detector_auto_update_cb(hObject, ~, obj, parentStruct, panelIndex)
% shons quick and dirty fix for n7744a issue
% update period must be LARGER than the averaging time * num detectors
% 0.5 sec is not enough. fail if not 1 sec. should fix this in a more
% proper way later...like calculating what the min time should be and
% then overriding the user's value if it's more
if obj.instr.detector.Param.UpdatePeriod < 1
    error('update period for read detector timer cannot be less than 1 sec')
    return
end

isChecked = get(hObject, 'Value');
powerUnit = obj.instr.detector.getPWMPowerUnit();
if isChecked
    if powerUnit == 1
        obj.instr.detector.setPWMPowerUnit(0);
    end
    % check to see if laser is on
    if ~obj.instr.laser.laserIsOn
        obj.instr.laser.on;
    end
    obj.timer.detectorReadTimer = timer(...
        'Name', 'Detector-Update-Timer', ...
        'ExecutionMode', 'fixedRate', ...
        'BusyMode', 'drop', ...
        'Period', obj.instr.detector.Param.UpdatePeriod, ...
        'TimerFcn', {@updatePowerValues, obj, parentStruct, panelIndex});
    start(obj.timer.detectorReadTimer);
else
    % turn laser off
    if obj.instr.laser.laserIsOn
        obj.instr.laser.off;
    end
    stop(obj.timer.detectorReadTimer);
    delete(obj.timer.detectorReadTimer);
    obj.instr.detector.setPWMPowerUnit(powerUnit);
end
end

% include detector callback
% if box is unchecked, deselect detector in class
function include_detector_checkbox_cb(hObject, ~, obj, index, parentStruct, panelIndex)
selected = get(hObject, 'Value');
selectedDetectors = obj.instr.detector.getProp('SelectedDetectors');
selectedDetectors(index) = selected;
obj.instr.detector.setProp('SelectedDetectors', selectedDetectors);
if selected
    powerValues = obj.instr.detector.readPower(index);
    powerStr = sprintf('%0.1f', powerValues);
    disp(powerStr); % shon added this 12/16/1013
    set(obj.gui.(parentStruct)(panelIndex).detectorUI.detectorPower(index), 'String', powerStr);
else
    set(obj.gui.(parentStruct)(panelIndex).detectorUI.detectorPower(index), 'String', 'N/A');
end
end


% ?Copyright 2015 Shon Schmidt
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
% --- build up a optical stage control ui in the assigned panel (or popup)
% parentName is a string describing of the parent panel (or popup)
% --- 1. For popup: should be like 'manual', 'selectPeaks' ...
% --- 2. For panel: should be the same as in panel_index function
% parentObj is the parent object for the ui (type: double)
% Victor Bass 2013;
% Modified by Vince Wu - Nov 2013

function obj = edge_coupled_stage_ui(obj, parentName, parentObj, position)

parentStruct = getParentStruct(parentName);
if (~isempty(strfind(parentStruct, 'panel')))
    panelIndex = str2double(parentStruct(end - 1));
    parentStruct = parentStruct(1:end - 3);
else
    panelIndex = 1;
end

% panel element size variables
move_button_x = 0.065;
move_button_y = 0.12;

control_button_x = 0.2;
control_button_y = 0.12;

edit_x = 0.185;
edit_y = 0.12;

% optical stage parent panel
obj.gui.(parentStruct)(panelIndex).opticalStageUI.mainpanel = uipanel(...
    'Parent', parentObj, ...
    'Unit','Pixels', ...
    'BackgroundColor', [0.9, 0.9 0.9], ...
    'Visible','on', ...
    'Units','normalized', ...
    'Title','Edge coupled fiber stage', ...
    'FontSize', 9, ...
    'FontWeight','bold', ...
    'Position', position);

%% Movement Buttons section

% X Step Size OC
obj.gui.(parentStruct)(panelIndex).opticalStageUI.dStaticXStepOC = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).opticalStageUI.mainpanel, ...
    'Style','text', ...
    'BackgroundColor',[0.9 0.9 0.9 ], ...
    'HorizontalAlignment','left', ...
    'Units', 'normalized', ...
    'Position', [.085, .85, .2, .12], ...
    'String','X (um)', ...
    'FontSize', 9);

% X Left Button OC
obj.gui.(parentStruct)(panelIndex).opticalStageUI.dXLeftButtonOC = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).opticalStageUI.mainpanel, ...
    'Style','pushbutton', ...
    'Enable', 'on', ...
    'Units', 'normalized', ...
    'Position', [.25, .87, move_button_x, move_button_y], ...
    'String','<', ...
    'Callback', {@dXLeftButtonOC_cb, obj, parentStruct, panelIndex});

% X Step Size OC
obj.gui.(parentStruct)(panelIndex).opticalStageUI.dXStepSizeOC = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).opticalStageUI.mainpanel, ...
    'Style','edit', ...
    'Enable', 'on', ...
    'Units', 'normalized', ...
    'Position', [.34, .87, edit_x, edit_y], ...
    'String',100);

% X Right Button OC
obj.gui.(parentStruct)(panelIndex).opticalStageUI.dXRightButtonOC = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).opticalStageUI.mainpanel, ...
    'Style','pushbutton', ...
    'Enable', 'on', ...
    'Units', 'normalized', ...
    'Position', [.55, .87, move_button_x, move_button_y], ...
    'String','>', ...
    'Callback', {@dXRightButtonOC_cb, obj, parentStruct, panelIndex});

% Y Step Size Static OC
obj.gui.(parentStruct)(panelIndex).opticalStageUI.dStaticYStepOC = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).opticalStageUI.mainpanel, ...
    'Style','text', ...
    'BackgroundColor',[0.9 0.9 0.9 ], ...
    'HorizontalAlignment','left', ...
    'Units', 'normalized', ...
    'Position', [.085, .71, .2, .12], ...
    'String','Y (um)', ...
    'FontSize', 9);

% Y Left Button OC
obj.gui.(parentStruct)(panelIndex).opticalStageUI.dYLeftButtonOC = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).opticalStageUI.mainpanel, ...
    'Style','pushbutton', ...
    'Enable', 'on', ...
    'Units', 'normalized', ...
    'Position', [.25, .73, move_button_x, move_button_y], ...
    'String','^', ...
    'Callback', {@dYLeftButtonOC_cb, obj, parentStruct, panelIndex});

% Y Step Size OC
obj.gui.(parentStruct)(panelIndex).opticalStageUI.dYStepSizeOC = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).opticalStageUI.mainpanel, ...
    'Style','edit', ...
    'Enable', 'on', ...
    'Units', 'normalized', ...
    'Position', [.34, .73, edit_x, edit_y], ...
    'String',100);

%Y Right Button OC
obj.gui.(parentStruct)(panelIndex).opticalStageUI.dYRightButtonOC = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).opticalStageUI.mainpanel, ...
    'Style','pushbutton', ...
    'Enable', 'on', ...
    'Units', 'normalized', ...
    'Position', [.55, .73, move_button_x, move_button_y], ...
    'String','v', ...
    'Callback', {@dYRightButtonOC_cb, obj, parentStruct, panelIndex});

% Z Step Size Static OC
obj.gui.(parentStruct)(panelIndex).opticalStageUI.dStaticZStepOC = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).opticalStageUI.mainpanel, ...
    'Style','text', ...
    'BackgroundColor',[0.9 0.9 0.9 ], ...
    'HorizontalAlignment','left', ...
    'Units', 'normalized', ...
    'Position', [.085, .57, .2, .12], ...
    'String','Z (um)', ...
    'FontSize', 9);

% Z Left Button OC
obj.gui.(parentStruct)(panelIndex).opticalStageUI.dZLeftButtonOC = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).opticalStageUI.mainpanel, ...
    'Style','pushbutton', ...
    'Enable', 'on', ...
    'Units', 'normalized', ...
    'Position', [.25, .59, move_button_x, move_button_y], ...
    'String','^', ...
    'Callback', {@dZLeftButtonOC_cb, obj, parentStruct, panelIndex});

% Z Step Size OC
obj.gui.(parentStruct)(panelIndex).opticalStageUI.dZStepSizeOC = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).opticalStageUI.mainpanel, ...
    'Style','edit', ...
    'Enable', 'on', ...
    'Units', 'normalized', ...
    'Position', [.34, .59, edit_x, edit_y], ...
    'String',100);

% Z Right Button OC
obj.gui.(parentStruct)(panelIndex).opticalStageUI.dZRightButtonOC = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).opticalStageUI.mainpanel, ...
    'Style','pushbutton', ...
    'Enable', 'on', ...
    'Units', 'normalized', ...
    'Position', [.55, .59, move_button_x, move_button_y], ...
    'String','v', ...
    'Callback', {@dZRightButtonOC_cb, obj, parentStruct, panelIndex});

% Theta Step Size Static OC
obj.gui.(parentStruct)(panelIndex).opticalStageUI.dThetaStepOC = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).opticalStageUI.mainpanel, ...
    'Style','text', ...
    'BackgroundColor',[0.9 0.9 0.9 ], ...
    'HorizontalAlignment','left', ...
    'Units', 'normalized', ...
    'Position', [.04, .39, .2, .16], ...
    'String', sprintf('Theta(%c)', char(176)), ...
    'FontSize', 9);

% Theta Left Button OC
obj.gui.(parentStruct)(panelIndex).opticalStageUI.dThetaLeftOC = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).opticalStageUI.mainpanel, ...
    'Style','pushbutton', ...
    'Enable', 'on', ...
    'Units', 'normalized', ...
    'Position', [.25, .45, move_button_x, move_button_y], ...
    'String','<', ...
    'Callback', {@dThetaLeftOC_cb, obj, parentStruct, panelIndex});

% Theta Step Size OC
obj.gui.(parentStruct)(panelIndex).opticalStageUI.dThetaStepSizeOC = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).opticalStageUI.mainpanel, ...
    'Style','edit', ...
    'Enable', 'on', ...
    'Units', 'normalized', ...
    'Position', [.34, .45, edit_x, edit_y], ...
    'String',5);

% Theta Right Button OC
obj.gui.(parentStruct)(panelIndex).opticalStageUI.dThetaRightOC = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).opticalStageUI.mainpanel, ...
    'Style','pushbutton', ...
    'Enable', 'on', ...
    'Units', 'normalized', ...
    'Position', [.55, .45, move_button_x, move_button_y], ...
    'String','>', ...
    'Callback', {@dThetaRightOC_cb, obj, parentStruct, panelIndex});

% Phi Step Size Static OC
obj.gui.(parentStruct)(panelIndex).opticalStageUI.dStaticPhiStepOC = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).opticalStageUI.mainpanel, ...
    'Style','text', ...
    'BackgroundColor',[0.9 0.9 0.9 ], ...
    'HorizontalAlignment','left', ...
    'Units', 'normalized', ...
    'Position', [.043, .25, .2, .16], ...
    'String', sprintf('Phi(%c)', char(176)), ...
    'FontSize', 9);

% Phi Left Button OC
obj.gui.(parentStruct)(panelIndex).opticalStageUI.dPhiLeftOC = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).opticalStageUI.mainpanel, ...
    'Style','pushbutton', ...
    'Enable', 'on', ...
    'Units', 'normalized', ...
    'Position', [.25, .31, move_button_x, move_button_y], ...
    'String','<', ...
    'Callback', {@dPhiLeftOC_cb, obj, parentStruct, panelIndex});

% Phi Step Size OC
obj.gui.(parentStruct)(panelIndex).opticalStageUI.dPhiStepSizeOC = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).opticalStageUI.mainpanel, ...
    'Style','edit', ...
    'Enable', 'on', ...
    'Units', 'normalized', ...
    'Position', [.34, .31, edit_x, edit_y], ...
    'String',5);

% Phi Right Button OC
obj.gui.(parentStruct)(panelIndex).opticalStageUI.dPhiRightOC = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).opticalStageUI.mainpanel, ...
    'Style','pushbutton', ...
    'Enable', 'on', ...
    'Units', 'normalized', ...
    'Position', [.55, .31, move_button_x, move_button_y], ...
    'String','>', ...
    'Callback', {@dPhiRightOC_cb, obj, parentStruct, panelIndex});


% Optical Settings Button
obj.gui.(parentStruct)(panelIndex).opticalStageUI.dSettingsOptical = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).opticalStageUI.mainpanel, ...
    'Style','pushbutton', ...
    'Enable', 'on', ...
    'Units', 'normalized', ...
    'Position', [.7, .87, control_button_x, control_button_y], ...
    'String','Settings', ...
    'Callback',{@dSettingsOptical_cb, obj});

% % Calibrate Button
% obj.gui.(parentStruct)(panelIndex).opticalStageUI.dCalibrateOpticalStage = uicontrol(...
%     'Parent', obj.gui.(parentStruct)(panelIndex).opticalStageUI.mainpanel, ...
%     'Style','pushbutton', ...
%     'Enable', 'off', ...
%     'Units', 'normalized', ...
%     'Position', [.7, .73, control_button_x, control_button_y], ...
%     'String','Calibrate', ...
%     'Callback',{@CalibrateOpticalStage_cb, obj});

% % Lock Button
% obj.gui.(parentStruct)(panelIndex).opticalStageUI.dLockOpticalStage = uicontrol(...
%     'Parent', obj.gui.(parentStruct)(panelIndex).opticalStageUI.mainpanel, ...
%     'Style','pushbutton', ...
%     'Enable', 'on', ...
%     'Units', 'normalized', ...
%     'Position', [.7, .59, control_button_x, control_button_y], ...
%     'String','Lock Z', ...
%     'Callback',{@LockOpticalStage_cb, obj, parentStruct, panelIndex});

% % Eject Button
% obj.gui.(parentStruct)(panelIndex).opticalStageUI.ejectButton = uicontrol(...
%     'Parent', obj.gui.(parentStruct)(panelIndex).opticalStageUI.mainpanel, ...
%     'Style','pushbutton', ...
%     'Enable','on', ...
%     'Units', 'normalized', ...
%     'Position', [.7, .45, control_button_x, control_button_y], ...
%     'String','Eject', ...
%     'Callback',{@eject_button_cb, obj, parentStruct, panelIndex});
% 
% % Load Button
% obj.gui.(parentStruct)(panelIndex).opticalStageUI.loadButton = uicontrol(...
%     'Parent', obj.gui.(parentStruct)(panelIndex).opticalStageUI.mainpanel, ...
%     'Style','pushbutton', ...
%     'Enable','on', ...
%     'Units', 'normalized', ...
%     'Position', [.7, .31, control_button_x, control_button_y], ...
%     'String','Load', ...
%     'Callback',{@load_button_cb, obj, parentStruct, panelIndex});

% %% Select devices section
% 
% deviceName = fieldnames(obj.devices);
% devicePD = cell(length(deviceName)+1, 1);
% devicePD{1} = '<Device>';
% for i = 1:length(deviceName)
%     devicePD{i+1} = obj.devices.(deviceName{i}).Name;
% end
% 
% % Current string
% obj.gui.(parentStruct)(panelIndex).opticalStageUI.currentDeviceString = uicontrol(...
%     'Parent', obj.gui.(parentStruct)(panelIndex).opticalStageUI.mainpanel, ...
%     'Style','text', ...
%     'BackgroundColor',[0.9 0.9 0.9 ], ...
%     'HorizontalAlignment','left', ...
%     'Units', 'normalized', ...
%     'Position', [0.04, .17, .2, .1], ...
%     'String','Current device:', ...
%     'FontSize', 9);
% 
% currentDeviceVal = find(strcmp(obj.chip.CurrentLocation, devicePD));
% if(isempty(currentDeviceVal))
%     currentDeviceVal = 1;
% end
% % Current device popup menu
% obj.gui.(parentStruct)(panelIndex).opticalStageUI.currentDevicePD = uicontrol(...
%     'Parent', obj.gui.(parentStruct)(panelIndex).opticalStageUI.mainpanel, ...
%     'Style', 'popup', ...
%     'Enable', 'on', ...
%     'Units', 'normalized', ...
%     'String', devicePD, ...
%     'Value', currentDeviceVal, ...
%     'Position', [0.26, 0.23, 0.35, 0.05], ...
%     'CallBack', {@current_device_assign_cb, obj, parentStruct, panelIndex});
% 
% % Move to string
% obj.gui.(parentStruct)(panelIndex).opticalStageUI.moveToString = uicontrol(...
%     'Parent', obj.gui.(parentStruct)(panelIndex).opticalStageUI.mainpanel, ...
%     'Style','text', ...
%     'BackgroundColor',[0.9 0.9 0.9 ], ...
%     'HorizontalAlignment','left', ...
%     'Units', 'normalized', ...
%     'Position', [0.04, .03, .2, .1], ...
%     'String','Move to device:', ...
%     'FontSize', 9);
% 
% % Move to device popup menu
% obj.gui.(parentStruct)(panelIndex).opticalStageUI.targetDevicePD = uicontrol(...
%     'Parent', obj.gui.(parentStruct)(panelIndex).opticalStageUI.mainpanel, ...
%     'Style', 'popup', ...
%     'Enable', 'on', ...
%     'Units', 'normalized', ...
%     'String', devicePD, ...
%     'Position', [0.26, 0.09, 0.35, 0.05]);

% Move button
obj.gui.(parentStruct)(panelIndex).opticalStageUI.fineAlign = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).opticalStageUI.mainpanel, ...
    'Style','pushbutton', ...
    'Enable','on', ...
    'Units', 'normalized', ...
    'Position', [.68, .35, control_button_x*1.2, control_button_y*1.2], ...
    'String','Fine Align', ...
    'FontWeight', 'bold', ...
    'Callback',{@fine_align_button_cb, obj, parentStruct, panelIndex});

end

%% Callback Functions
function dXLeftButtonOC_cb(~, ~, obj, parentStruct, panelIndex)
distance = str2double(get(obj.gui.(parentStruct)(panelIndex).opticalStageUI.dXStepSizeOC, 'String'));
obj.instr.opticalStage.move_x(distance);
msg = strcat([obj.instr.opticalStage.Name,':moved ',num2str(distance),' um to the left']);
obj.msg(msg);
end

function dXRightButtonOC_cb(~, ~, obj, parentStruct, panelIndex)
distance = str2double(get(obj.gui.(parentStruct)(panelIndex).opticalStageUI.dXStepSizeOC, 'String'));
obj.instr.opticalStage.move_x(-distance);
msg = strcat([obj.instr.opticalStage.Name,':moved ',num2str(distance),' um to the right']);
obj.msg(msg);
end

function dSettingsOptical_cb(~, ~, obj)
obj.instr.opticalStage.settingsWin;
end

function dYLeftButtonOC_cb(~, ~, obj, parentStruct, panelIndex)
distance = str2double(get(obj.gui.(parentStruct)(panelIndex).opticalStageUI.dYStepSizeOC, 'String'));
obj.instr.opticalStage.move_y(-distance);
msg = strcat([obj.instr.opticalStage.Name,':moved ',num2str(distance),' um forward']);
obj.msg(msg);
end

function dYRightButtonOC_cb(~, ~, obj, parentStruct, panelIndex)
distance = str2double(get(obj.gui.(parentStruct)(panelIndex).opticalStageUI.dYStepSizeOC, 'String'));
obj.instr.opticalStage.move_y(distance);
msg = strcat([obj.instr.opticalStage.Name,':moved ',num2str(distance),' um backward']);
obj.msg(msg);
end

% function CalibrateOpticalStage_cb(~, ~, obj)
% obj.instr.opticalStage.calibrate;
% msg = strcat(obj.instr.opticalStage.Name, ': successfully calibrated.');
% obj.msg(msg);
% end
% 
function dZLeftButtonOC_cb(~, ~, obj, parentStruct, panelIndex)
distance = str2double(get(obj.gui.(parentStruct)(panelIndex).opticalStageUI.dZStepSizeOC, 'String'));
obj.instr.opticalStage.move_z(-distance);
msg = strcat([obj.instr.opticalStage.Name,':moved ',num2str(distance),' um up']);
obj.msg(msg);
end

function dZRightButtonOC_cb(~, ~, obj, parentStruct, panelIndex)
distance = str2double(get(obj.gui.(parentStruct)(panelIndex).opticalStageUI.dZStepSizeOC, 'String'));
obj.instr.opticalStage.move_z(distance);
msg = strcat([obj.instr.opticalStage.Name,':moved ',num2str(distance),' um down']);
obj.msg(msg);
end

function dThetaLeftOC_cb(~, ~, obj, parentStruct, panelIndex)
degree = str2double(get(obj.gui.(parentStruct)(panelIndex).opticalStageUI.dStgAngStepSizeOC, 'String'));
obj.instr.opticalStage.move_stgangle(-degree);
msg = sprintf('%s: moved %.1f%c clockwise', obj.instr.opticalStage.Name, degree, char(176));
obj.msg(msg);
end

function dThetaRightOC_cb(~, ~, obj, parentStruct, panelIndex)
degree = str2double(get(obj.gui.(parentStruct)(panelIndex).opticalStageUI.dStgAngStepSizeOC, 'String'));
obj.instr.opticalStage.move_stgangle(degree);
msg = sprintf('%s: moved %.1f%c counter-clockwise', obj.instr.opticalStage.Name, degree, char(176));
obj.msg(msg);
end

function dPhiLeftOC_cb(~, ~, obj, parentStruct, panelIndex)
% degree = str2double(get(obj.gui.(parentStruct)(panelIndex).opticalStageUI.dStgAngStepSizeOC, 'String'));
% obj.instr.opticalStage.move_fbrangle(-degree);
% msg = sprintf('%s: moved %.1f%c clockwise', obj.instr.opticalStage.Name, degree, char(176));
% obj.msg(msg);
end

function dPhiRightOC_cb(~, ~, obj, parentStruct, panelIndex)
% degree = str2double(get(obj.gui.(parentStruct)(panelIndex).opticalStageUI.dStgAngStepSizeOC, 'String'));
% obj.instr.opticalStage.move_fbrangle(degree);
% msg = sprintf('%s: moved %.1f%c counter-clockwise', obj.instr.opticalStage.Name, degree, char(176));
% obj.msg(msg);
end

% function LockOpticalStage_cb(hObject, ~, obj, parentStruct, panelIndex)
% if strcmp('Lock Z', get(obj.gui.(parentStruct)(panelIndex).opticalStageUI.dLockOpticalStage, 'String'))
%     set(obj.gui.(parentStruct)(panelIndex).opticalStageUI.dZLeftButtonOC, 'Enable', 'off')
%     set(obj.gui.(parentStruct)(panelIndex).opticalStageUI.dZRightButtonOC, 'Enable', 'off')
%     set(hObject, 'String', 'Unlock Z');
% elseif strcmp('Unlock Z', get(obj.gui.(parentStruct)(panelIndex).opticalStageUI.dLockOpticalStage, 'String'))
%     set(obj.gui.(parentStruct)(panelIndex).opticalStageUI.dZLeftButtonOC, 'Enable', 'on')
%     set(obj.gui.(parentStruct)(panelIndex).opticalStageUI.dZRightButtonOC, 'Enable', 'on')
%     set(hObject, 'String', 'Lock Z');
% end
% end
% 
% function current_device_assign_cb(hObject, ~, obj, parentStruct, panelIndex)
% currentDeviceIndex = get(hObject, 'Value');
% if currentDeviceIndex ~= 1
%     devicePD = get(obj.gui.(parentStruct)(panelIndex).opticalStageUI.currentDevicePD, 'String');
%     % Get the current Device
%     % and send the location to chip object
%     currentDevice = obj.devices.(devicePD{currentDeviceIndex});
%     obj.chip.CurrentLocation = currentDevice.Name;
% end
% end

function fine_align_button_cb(~, ~, obj, parentStruct, panelIndex)
devicePD = get(obj.gui.(parentStruct)(panelIndex).opticalStageUI.currentDevicePD, 'String'); % It doesn't matter which one to use
% Get the current Device Name
currentDeviceIndex = get(obj.gui.(parentStruct)(panelIndex).opticalStageUI.currentDevicePD, 'Value');
currentDeviceName = devicePD{currentDeviceIndex};
% Get the target Device Name
targetDeviceIndex = get(obj.gui.(parentStruct)(panelIndex).opticalStageUI.targetDevicePD, 'Value');
targetDeviceName = devicePD{targetDeviceIndex};

if (currentDeviceIndex ~= 1 && targetDeviceIndex ~= 1)
    % Get Current and Target Devices
    currentDevice = obj.devices.(currentDeviceName);
    targetDevice = obj.devices.(targetDeviceName);
    % Move to Target Device
    moveToDevice(obj, currentDevice, targetDevice);
    newDeviceIndex = get(obj.gui.(parentStruct)(panelIndex).opticalStageUI.targetDevicePD, 'Value');
    set(obj.gui.(parentStruct)(panelIndex).opticalStageUI.currentDevicePD, 'Value', newDeviceIndex);
elseif (currentDeviceIndex == 1 && targetDeviceIndex ~=1)
    %get target device
    targetDevice = obj.devices.(targetDeviceName);
    try
        obj.instr.opticalStage.moveTo(targetDevice.X, targetDevice.Y);
    catch ME
        obj.msg(ME.message)
        rethrow(ME)
    end
else
    obj.msg('Please choose proper devices.');
end
end

% function eject_button_cb(hObject, ~, obj, parentStruct, panelIndex)
% obj.instr.opticalStage.eject();
% % set(hObject, 'Enable', 'off');
% % set(obj.gui.(parentStruct)(panelIndex).opticalStageUI.loadButton, 'Enable', 'on')
% end
% 
% function load_button_cb(hObject, ~, obj, parentStruct, panelIndex)
% obj.instr.opticalStage.load();
% % set(hObject, 'Enable', 'off');
% % set(obj.gui.(parentStruct)(panelIndex).opticalStageUI.ejectButton, 'Enable', 'on')
% end

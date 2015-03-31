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
% --- build up a laser control ui in the assigned panel (or popup)
% parentName is a string describing of the parent panel (or popup)
% --- 1. For popup: should be like 'manual', 'selectPeaks' ...
% --- 2. For panel: should be the same as in panel_index function
% parentObj is the parent object for the ui (type: double)
% varargin input should contain only the axe handle for sweep data plotting
% --- 1. if varargin is empty: plot data in new figure
% --- 2. if an axe handle is passed in, plot the data in the axes
% Victor Bass 2013;
% Modified by Vince Wu - Nov 2013
% Modified by Pavel Kulik - Nov 2013

function obj = laser_ui(obj, parentName, parentObj, position, varargin)

parentStruct = getParentStruct(parentName);
if (~isempty(strfind(parentStruct, 'panel')))
    panelIndex = str2double(parentStruct(end - 1));
    parentStruct = parentStruct(1:end - 3);
else
    panelIndex = 1;
end
% panel element size variables
stringBoxSize = [0.275, 0.125];
pushButtonSize = [0.2, 0.15];
editBoxSize = [0.1, 0.125];
popupSize = [0.1, 0.1];
move_button_x = 0.065;
move_button_y = 0.15;

% laser and sweeps panel
obj.gui.(parentStruct)(panelIndex).laserUI.mainPanel = uipanel(...
    'Parent', parentObj, ...
    'Unit','Pixels', ...
    'BackgroundColor', [0.9, 0.9 0.9], ...
    'Visible','on', ...
    'Units','normalized', ...
    'Title','Laser', ...
    'FontSize', 9, ...
    'FontWeight','bold', ...
    'Position', position);

%% Laser Section

x_start = 0.08;
y_start = 0.85;

% lasing display string
obj.gui.(parentStruct)(panelIndex).laserUI.lasingString = uicontrol(...
    'parent', obj.gui.(parentStruct)(panelIndex).laserUI.mainPanel, ...
    'Style','text', ...
    'BackgroundColor',[0.9 0.9 0.9 ], ...
    'HorizontalAlignment','left', ...
    'Units', 'normalized', ...
    'Position', [x_start, y_start, stringBoxSize], ...
    'String','Lasing', ...
    'FontSize', 9);

x_align = x_start + 0.15;
y_align = y_start;

% on button
obj.gui.(parentStruct)(panelIndex).laserUI.laserONButton = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).laserUI.mainPanel, ...
    'Style', 'pushbutton', ...
    'Enable', 'on', ...
    'Units', 'normalized', ...
    'Position', [x_align, y_align, pushButtonSize], ...
    'String', 'On', ...
    'Callback', {@laser_on_cb, obj, parentStruct, panelIndex});

x_align = x_align + 0.25;

% off button
obj.gui.(parentStruct)(panelIndex).laserUI.laserOFFButton = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).laserUI.mainPanel, ...
    'Style', 'pushbutton', ...
    'Enable', 'off', ...
    'Units', 'normalized', ...
    'Position', [x_align, y_align, pushButtonSize], ...
    'String', 'Off', ...
    'Callback', {@laser_off_cb, obj, parentStruct, panelIndex});

x_align = x_align + 0.25;

% laser settings button
obj.gui.(parentStruct)(panelIndex).laserUI.laserSettingsButton = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).laserUI.mainPanel, ...
    'Style', 'pushbutton', ...
    'Enable', 'on', ...
    'Units', 'normalized', ...
    'Position', [x_align, y_align, pushButtonSize], ...
    'String', 'Settings', ...
    'Callback', {@laser_settings_cb, obj});

x_align = x_start;
y_align = y_align - 0.2;

% lasing color display
obj.gui.(parentStruct)(panelIndex).laserUI.lasingIndicator = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).laserUI.mainPanel, ...
    'Style','text', ...
    'BackGroundColor', [1, 0, 0], ...
    'Visible', 'on', ...
    'Enable', 'off', ...
    'Units', 'normalized', ...
    'Position', [x_align+0.02, y_align+0.05, 0.05, .1]);

x_align = x_align + 0.15;

% power string
obj.gui.(parentStruct)(panelIndex).laserUI.powerString = uicontrol(...
    'parent', obj.gui.(parentStruct)(panelIndex).laserUI.mainPanel, ...
    'Style','text', ...
    'BackgroundColor',[0.9 0.9 0.9 ], ...
    'HorizontalAlignment','left', ...
    'Units', 'normalized', ...
    'Position', [x_align, y_align, stringBoxSize], ...
    'String','Pwr (dBm):', ...
    'FontSize', 9);

x_align = x_align + 0.14;

% power edit
obj.gui.(parentStruct)(panelIndex).laserUI.powerEdit = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).laserUI.mainPanel, ...
    'Style','text', ...
    'Enable', 'on', ...
    'Units', 'normalized', ...
    'Position', [x_align, y_align, 0.5*editBoxSize(1), editBoxSize(2)], ...
    'String', 0, ...
    'Callback', {@power_edit_cb, obj});

x_align = x_align + 0.115;

% wavelength string
obj.gui.(parentStruct)(panelIndex).laserUI.wvlString = uicontrol(...
    'parent', obj.gui.(parentStruct)(panelIndex).laserUI.mainPanel, ...
    'Style','text', ...
    'BackgroundColor',[0.9 0.9 0.9 ], ...
    'HorizontalAlignment','left', ...
    'Units', 'normalized', ...
    'Position', [x_align, y_align, stringBoxSize], ...
    'String','Wvl (nm):', ...
    'FontSize', 9);

x_align = x_align + 0.185;

% Wavelength Step Down Button
obj.gui.(parentStruct)(panelIndex).laserUI.wvlStepDown = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).laserUI.mainPanel, ...
    'Style','pushbutton', ...
    'Enable', 'on', ...
    'Units', 'normalized', ...
    'Position', [x_align, y_align, move_button_x, move_button_y], ...
    'String','<', ...
    'Callback', {@wavelengthStepDownCB, obj, parentStruct, panelIndex});

x_align = x_align + 1.25*move_button_x;
%y_align = y_align + 0.01;

% Wavelength Display
obj.gui.(parentStruct)(panelIndex).laserUI.wvlEdit = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).laserUI.mainPanel, ...
    'Style','text', ...
    'Enable', 'on', ...
    'Units', 'normalized', ...
    'Position', [x_align, y_align, editBoxSize], ...
    'String', obj.instr.laser.getWavelength(), ...
    'Callback', {@wvl_edit_cb, obj});

x_align = x_align + 1.1*editBoxSize(1);
%y_align = y_align - 0.01;

% Wavelength Step Up Button
obj.gui.(parentStruct)(panelIndex).laserUI.wvlStepUp = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).laserUI.mainPanel, ...
    'Style','pushbutton', ...
    'Enable', 'on', ...
    'Units', 'normalized', ...
    'Position', [x_align, y_align, move_button_x, move_button_y], ...
    'String','>', ...
    'Callback', {@wavelengthStepUpCB, obj, parentStruct, panelIndex});


%% Line Separating Laser and Sweep Sections
% axes to draw line on
obj.gui.(parentStruct)(panelIndex).laserUI.separating_line_axes = axes(...
    'parent', obj.gui.(parentStruct)(panelIndex).laserUI.mainPanel, ...
    'Visible', 'off', ...
    'Position', [0, 0, 1, 1], ...
    'Xlim', [0, 1], ...
    'Ylim', [0, 1]);
% line across ui panel
line([0, 1], [.6, .6], 'parent', obj.gui.(parentStruct)(panelIndex).laserUI.separating_line_axes, 'color', 'black');

%% Sweeps Section

x_align = x_start;
y_align = y_align - 0.2;

% sweep string
obj.gui.(parentStruct)(panelIndex).laserUI.rangeString = uicontrol(...
    'parent', obj.gui.(parentStruct)(panelIndex).laserUI.mainPanel, ...
    'Style','text', ...
    'BackgroundColor',[0.9 0.9 0.9 ], ...
    'HorizontalAlignment','left', ...
    'Units', 'normalized', ...
    'Position', [x_align, y_align, stringBoxSize], ...
    'String','Sweep:', ...
    'FontSize', 9);

x_align = x_align + 0.15;

% range minimum
obj.gui.(parentStruct)(panelIndex).laserUI.rangeMINEdit = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).laserUI.mainPanel, ...
    'Style','text', ...
    'Enable', 'on', ...
    'Units', 'normalized', ...
    'String', num2str(obj.AppSettings.SweepParams.StartWvl), ...
    'Position', [x_align, y_align, 2*editBoxSize(1)/3, editBoxSize(2)], ...
    'Callback', {@range_min_cb, obj});

x_align = x_align + 0.15;

% range to string
obj.gui.(parentStruct)(panelIndex).laserUI.toString = uicontrol(...
    'parent', obj.gui.(parentStruct)(panelIndex).laserUI.mainPanel, ...
    'Style','text', ...
    'BackgroundColor',[0.9 0.9 0.9 ], ...
    'HorizontalAlignment','left', ...
    'Units', 'normalized', ...
    'Position', [x_align, y_align, stringBoxSize], ...
    'String','to', ...
    'FontSize', 9);

x_align = x_align + 0.09;

% range maximum
obj.gui.(parentStruct)(panelIndex).laserUI.rangeMAXEdit = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).laserUI.mainPanel, ...
    'Style','text', ...
    'Enable', 'on', ...
    'Units', 'normalized', ...
    'String', num2str(obj.AppSettings.SweepParams.StopWvl), ...
    'Position', [x_align, y_align, 2*editBoxSize(1)/3, editBoxSize(2)], ...
    'Callback', {@range_max_cb, obj});

x_align = x_align + 0.265;

% sweep button
% Performing laser sweep: Need to pass axes handle for plotting
% 	power data.
% Plotting handle could be:
%   1. empty ------ create new figure to plot.
%   2. axes in seleckPeaks Popup.
%   3. axes in dry/wet testing panel.
axesHandle = [];
if nargin >= 5
    axesHandle = varargin{1};
end

% sweep settings button
obj.gui.(parentStruct)(panelIndex).laserUI.sweepSettingsButton = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).laserUI.mainPanel, ...
    'Style', 'pushbutton', ...
    'Enable', 'on', ...
    'Units', 'normalized', ...
    'Position', [x_align, y_align, pushButtonSize], ...
    'String', 'Settings', ...
    'Callback', {@sweep_settings_cb, obj, parentStruct, panelIndex});

x_align = x_start;
y_align = y_align - 0.2;

% sweep speed string
obj.gui.(parentStruct)(panelIndex).laserUI.sweepSpeedString = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).laserUI.mainPanel, ...
    'Style','text', ...
    'BackgroundColor',[0.9 0.9 0.9 ], ...
    'HorizontalAlignment','left', ...
    'Units', 'normalized', ...
    'Position', [x_align, y_align, stringBoxSize], ...
    'String', 'Speed:', ...
    'FontSize', 9);

x_align = x_align + 0.15;

% speed display box
obj.gui.(parentStruct)(panelIndex).laserUI.sweepSpeedDisplay = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).laserUI.mainPanel, ...
    'Style', 'text', ...
    'Enable', 'on', ...
    'Units', 'normalized', ...
    'String', num2str(obj.AppSettings.SweepParams.SweepSpeed), ...
    'Position', [x_align, y_align, editBoxSize(1)/2, editBoxSize(2)], ...
    'Callback', {@sweep_speed_display_cb, obj});

x_align = x_align + 0.15;

% sweep step string
obj.gui.(parentStruct)(panelIndex).laserUI.sweepStepString = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).laserUI.mainPanel, ...
    'Style','text', ...
    'BackgroundColor',[0.9 0.9 0.9 ], ...
    'HorizontalAlignment','left', ...
    'Units', 'normalized', ...
    'Position', [x_align, y_align, stringBoxSize], ...
    'String', 'Step:', ...
    'FontSize', 9);

x_align = x_align + 0.1;

% step display box
obj.gui.(parentStruct)(panelIndex).laserUI.sweepStepDisplay = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).laserUI.mainPanel, ...
    'Style', 'text', ...
    'Enable', 'on', ...
    'Units', 'normalized', ...
    'String', num2str(obj.AppSettings.SweepParams.StepWvl), ...
    'Position', [x_align, y_align, editBoxSize(1)/2, editBoxSize(2)], ...
    'Callback', {@sweep_step_display_cb, obj});

x_align = x_align + 0.255;

% abort button
obj.gui.(parentStruct)(panelIndex).laserUI.abortButton = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).laserUI.mainPanel, ...
    'Style', 'pushbutton', ...
    'Enable', 'off', ...
    'Units', 'normalized', ...
    'Position', [x_align, y_align, pushButtonSize], ...
    'String', 'Abort', ...
    'Callback', {@laser_abort_cb});

x_align = x_start;
y_align = y_align - 0.2;

% sweep range string
obj.gui.(parentStruct)(panelIndex).laserUI.sweepRangeString = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).laserUI.mainPanel, ...
    'Style','text', ...
    'BackgroundColor',[0.9 0.9 0.9 ], ...
    'HorizontalAlignment','left', ...
    'Units', 'normalized', ...
    'Position', [x_align, y_align, stringBoxSize], ...
    'String', 'Range:', ...
    'FontSize', 9);

x_align = x_align + 0.15;

% range display box
obj.gui.(parentStruct)(panelIndex).laserUI.sweepRangeDisplay = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).laserUI.mainPanel, ...
    'Style', 'text', ...
    'Enable', 'on', ...
    'Units', 'normalized', ...
    'String', obj.instr.detector.getParam('PowerRange'), ...
    'Position', [x_align, y_align, editBoxSize(1)/2, editBoxSize(2)], ...
    'Callback',{@sweep_range_display_cb, obj});

x_align = x_align + 0.15;

% stitch string
obj.gui.(parentStruct)(panelIndex).laserUI.laserStitchString = uicontrol(...
    'parent', obj.gui.(parentStruct)(panelIndex).laserUI.mainPanel, ...
    'Style','text', ...
    'BackgroundColor',[0.9 0.9 0.9 ], ...
    'HorizontalAlignment','left', ...
    'Units', 'normalized', ...
    'Position', [x_align, y_align, stringBoxSize], ...
    'String','Stitch:', ...
    'FontSize', 9);

x_align = x_align + 0.1;
y_align = y_align + 0.05;

% stitch popup menu
obj.gui.(parentStruct)(panelIndex).laserUI.laserStitchPopup = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).laserUI.mainPanel, ...
    'Style', 'popupmenu', ...
    'Enable', 'on', ...
    'Units', 'normalized', ...
    'Position', [x_align, y_align, popupSize], ...
    'String', {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 15, 20}, ...
    'FontSize', 8, ...
    'Callback', {@laser_stitch_popup_cb, obj});


x_align = x_align + 0.255;
y_align = y_align - 0.05;

% sweep button
obj.gui.(parentStruct)(panelIndex).laserUI.sweepButton = uicontrol(...
    'Parent', obj.gui.(parentStruct)(panelIndex).laserUI.mainPanel, ...
    'Style', 'pushbutton', ...
    'Enable', 'on', ...
    'Units', 'normalized', ...
    'Position', [x_align, y_align, pushButtonSize], ...
    'String', 'Sweep', ...
    'Callback', {@laser_sweep_cb, obj, parentName, axesHandle});


%Doesnt' work: Need to select the right value
%set(obj.gui.(parentStruct)(panelIndex).laserUI.laserStitchPopup, 'Value',int16(obj.AppSettings.SweepParams.StitchNum));

obj.gui.sweepScanH = [];
obj.gui.sweepScan = {};
end
%% Callback Functions
    function laser_on_cb(~, ~, obj, parentStruct, panelIndex)
        obj.instr.laser.on;
        if obj.instr.laser.getProp('Lasing');
            set(obj.gui.(parentStruct)(panelIndex).laserUI.lasingIndicator, 'BackGroundColor', [0 1 0]);
            set(obj.gui.(parentStruct)(panelIndex).laserUI.laserONButton, 'Enable', 'off');
            set(obj.gui.(parentStruct)(panelIndex).laserUI.laserOFFButton, 'Enable', 'on');
            set(obj.gui.(parentStruct)(panelIndex).laserUI.sweepButton, 'Enable', 'on');
            set(obj.gui.(parentStruct)(panelIndex).laserUI.abortButton, 'Enable', 'on');
        end
    end

    function laser_off_cb(~, ~, obj, parentStruct, panelIndex)
        obj.instr.laser.off;
        set(obj.gui.(parentStruct)(panelIndex).laserUI.lasingIndicator, 'BackGroundColor', [1 0 0]);
        set(obj.gui.(parentStruct)(panelIndex).laserUI.laserONButton, 'Enable', 'on');
        set(obj.gui.(parentStruct)(panelIndex).laserUI.laserOFFButton, 'Enable', 'off');
    end

    function wvl_edit_cb(hObject, ~, obj)
        newWvl = str2double(get(hObject, 'String'));
        obj.instr.laser.setWavelength(newWvl);
    end

    function laser_settings_cb(~, ~, obj)
        obj.instr.laser.settingsWin;
    end

    function power_edit_cb(hObject, ~, obj)
        newPwr = str2double(get(hObject, 'String'));
        obj.instr.laser.setPower(newPwr);
        obj.AppSettings.SweepParams.PowerLevel = newPwr;
    end

    function range_min_cb(hObject, ~, obj)
        newMinWvl = str2double(get(hObject, 'String'));
        obj.AppSettings.SweepParams.StartWvl = newMinWvl;
    end

    function range_max_cb(hObject, ~, obj)
        newMaxWvl = str2double(get(hObject, 'String'));
        obj.AppSettings.SweepParams.StopWvl=newMaxWvl;
    end

    function sweep_step_display_cb(hObject, ~, obj)
        newStep = str2double(get(hObject, 'String'));
        obj.AppSettings.SweepParams.StepWvl = newStep;
        obj.AppSettings.LaserParams.StepSize = newStep;
    end

    function sweep_speed_display_cb(hObject, ~, obj)
        newSpeed = str2double(get(hObject, 'String'));
        obj.AppSettings.SweepParams.SweepSpeed = newSpeed;
    end

    function sweep_range_display_cb(hObject, ~, obj)
        newRange = str2double(get(hObject, 'String'));
        obj.instr.detector.setParam('PowerRange', newRange);
    end

    function laser_stitch_popup_cb(hObject, ~, obj)
        %DEBUG: this needs to be validated with DataPoints
        popupStringList = get(hObject, 'String');
        popupStringValue = get(hObject, 'Value');
        stitchNum = str2double(popupStringList(popupStringValue));
        obj.AppSettings.SweepParams.StitchNum = stitchNum;
    end

    function laser_sweep_cb(~, ~, obj, parentName, axesHandle)
        selectedDetectors = obj.instr.detector.getProp('SelectedDetectors');
        numOfSelected = sum(selectedDetectors);
        [wvlVals, pwrVals] = sweep(obj); % calls control script sweep
        obj.gui.sweepScan{end+1} = [wvlVals, pwrVals];
        [~, numDetectors] = size(pwrVals);
        colors = {'r', 'g', 'b', 'c', 'm', 'k'};
        plotIndex = 0;
        if ~isempty(axesHandle);
            for kk = 1: numDetectors
                ThisSweep(kk).pwr = pwrVals(:, kk);
                ThisSweep(kk).wvl = wvlVals(:, kk);
                if strcmpi(parentName, 'selectPeaks')
                    % Select Peaks panel always have four subplots
%                     subplot(axesHandle(kk));
                    plot(axesHandle(kk), wvlVals(:, kk), pwrVals(:, kk), colors{kk});
                    obj.devices.(obj.chip.CurrentLocation).setProp('ScanNumber', 0);
                elseif selectedDetectors(kk)
                    plotIndex = plotIndex + 1;
%                     subplot(axesHandle(plotIndex));
                    plot(axesHandle(plotIndex), wvlVals(:, kk), pwrVals(:, kk), colors{plotIndex});
                end
                title(['Detector ', num2str(kk)]);
                xlabel('Wavelength [nm]');
                ylabel('Power [dBm]');
            end
            obj.devices.(obj.chip.CurrentLocation).setProp('ThisSweep', ThisSweep);
%             params = scanParams(obj);
%             obj.devices.(obj.chip.CurrentLocation).saveData(wvlVals, pwrVals, params);
            % Check if data is the correct size
            if length(wvlVals) ~= length(pwrVals)
                err = MException('SelectPeak:DataFormat','xdata and ydata are not the same length');
                throw(err);
            end
        else
            if isempty(obj.gui.sweepScanH)
                obj.gui.sweepScanH = figure(...
                    'Name', 'Sweep Scan Data', ...
                    'NumberTitle', 'off', ...
                    'Units', 'normalized', ...
                    'Position', [0, 0, 0.66, 0.66], ...
                    'DeleteFcn', {@sweepScanDelete, obj});
                movegui(obj.gui.sweepScanH, 'center');
            else
                figure(obj.gui.sweepScanH);
            end
            thisColor = colors{mod(length(obj.gui.sweepScan), length(colors))+1};
            for ii = 1:numDetectors
                if selectedDetectors(ii)
                    plotIndex = plotIndex + 1;
                    sp = subplot(numOfSelected, 1, plotIndex);
                    hold(sp, 'on');
                    plot(sp, wvlVals(:,ii), pwrVals(:,ii), thisColor);
                    title(sp, ['Detector ', num2str(ii)]);
                    xlabel(sp, 'Wavelength [nm]');
                    ylabel(sp, 'Power [dBm]');
                    hold(sp, 'off');
                end
            end
        end
    end

    function sweepScanDelete(~, ~, obj)
        close(obj.gui.sweepScanH);
        obj.gui.sweepScanH = [];
        obj.gui.sweepScan = {};
    end
    
    function wavelengthStepDownCB(~, ~, obj, parentStruct, panelIndex)
        %New wavelength = currentWvl - stepWvl
        obj.instr.laser.setWavelength(...
            obj.instr.laser.getWavelength() - obj.AppSettings.SweepParams.StepWvl);
        set(obj.gui.(parentStruct)(panelIndex).laserUI.wvlEdit,...
            'String',  obj.instr.laser.getWavelength);
    end
    
    function wavelengthStepUpCB(~, ~, obj, parentStruct, panelIndex)
        %New wavelength = currentWvl + stepWvl
        obj.instr.laser.setWavelength(...
            obj.instr.laser.getWavelength() + obj.AppSettings.SweepParams.StepWvl);   
        set(obj.gui.(parentStruct)(panelIndex).laserUI.wvlEdit,...
            'String', obj.instr.laser.getWavelength);
    end
    
    function laser_abort_cb(~, ~)
    end

    function sweep_settings_cb(~, ~, obj, parentStruct, panelIndex)
        obj = obj.settingsWin('SweepParams');
        uiwait(obj.gui.PopupWinH);
        updatePanel(obj, parentStruct, panelIndex);
    end
    
    function updatePanel(obj, parentStruct, panelIndex)
        set(obj.gui.(parentStruct)(panelIndex).laserUI.powerEdit,...
            'String', obj.AppSettings.SweepParams.PowerLevel);
        set(obj.gui.(parentStruct)(panelIndex).laserUI.rangeMINEdit,...
            'String', obj.AppSettings.SweepParams.StartWvl);
        set(obj.gui.(parentStruct)(panelIndex).laserUI.rangeMAXEdit,...
            'String', obj.AppSettings.SweepParams.StopWvl);
        set(obj.gui.(parentStruct)(panelIndex).laserUI.rangeMAXEdit,...
            'String', obj.AppSettings.SweepParams.StopWvl);
        set(obj.gui.(parentStruct)(panelIndex).laserUI.sweepSpeedDisplay,...
            'String', obj.AppSettings.SweepParams.SweepSpeed);
        set(obj.gui.(parentStruct)(panelIndex).laserUI.sweepStepDisplay,...
            'String', obj.AppSettings.SweepParams.StepWvl);
        set(obj.gui.(parentStruct)(panelIndex).laserUI.sweepRangeDisplay,...
            'String', obj.AppSettings.SweepParams.InitRange);
    end

    

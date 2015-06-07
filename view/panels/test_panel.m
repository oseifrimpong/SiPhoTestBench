function obj = test_panel(obj)

% Obtain List of Tested Devices
obj.testedDevices = {};
deviceNames = fieldnames(obj.devices);
for d = 1:length(deviceNames)
    if obj.devices.(deviceNames{d}).getProp('Selected')
        obj.testedDevices{end+1, 1} = deviceNames{d};
    end
end

set(obj.gui.nextButton, 'Enable', 'on'); % Temporary

% panel that will combine wet and dry test panel and will display elements
% based on which type of assay was selected
% Victor Bass 2013

%% SET CONSTANT PARAMETERS
thisPanel = panel_index('test');

%% DETERMINE IF WET OR DRY TEST
% get the type of test (wet or dry) from the user settings
%test_type = lower(obj.AppSettings.infoParams.Task);
test_type = obj.AppSettings.infoParams.Task;

%% DETECTOR PLOTS (WITH TABLES FOR WET TEST)
plotPanel_w = 0.7;
plotPanel_h = 0.93;

% Plotting panel for sweep scan data and/or peak tracking plot
obj.gui.panel(thisPanel).plotPanel = uipanel(...
    'Parent', obj.gui.panelFrame(thisPanel), ...
    'Title', 'Sweep Scan Data', ...
    'FontSize', 9, ...
    'FontWeight', 'bold', ...
    'Unit', 'normalized', ...
    'BackgroundColor', [0.9, 0.9, 0.9], ...
    'Visible', 'on', ...
    'Position', [0.01, 0.01, plotPanel_w, plotPanel_h]);

% for loop to draw axes and table for each detector
numDetectors = obj.instr.detector.getProp('NumOfDetectors');
selectedDetectors = obj.instr.detector.getProp('SelectedDetectors');
numOfSelected = sum(selectedDetectors);
if strcmpi(test_type, 'SaltSteps') || strcmpi(test_type, 'TemperatureTest')|| ...
        strcmpi(test_type, 'BioAssay') || strcmpi(test_type, 'VirtualTestMode') ...
        || strcmpi(test_type, 'TestBenchCharacterization')
    % for loop to draw wvl Vs. pwr plots for each detector
    plotIndex = 0;
    for i = 1:numDetectors
        if (selectedDetectors(i))
            plotIndex = plotIndex + 1;
            % Real-Time Scan Plotting: Power vs. Wavelength
            if numOfSelected == 1
                obj.gui.panel(thisPanel).sweepScanPlots(plotIndex) = ...
                    subplot(3, numOfSelected, plotIndex*3-2, 'Parent', obj.gui.panel(thisPanel).plotPanel);
            else
                obj.gui.panel(thisPanel).sweepScanPlots(plotIndex) = ...
                    subplot(numOfSelected, 3, plotIndex*3-2, 'Parent', obj.gui.panel(thisPanel).plotPanel);
            end
            title(['Detector ',num2str(i),' real-time scan'], 'FontSize', 8);
            xlabel('Wavelength (nm)', 'FontSize', 8);
            ylabel('Power (dBW)', 'FontSize', 8);
            axePosition = get(obj.gui.panel(thisPanel).sweepScanPlots(plotIndex), 'Position');
            xOffset = axePosition(1) - 0.1;
            axePosition(1) = 0.09;
            set(obj.gui.panel(thisPanel).sweepScanPlots(plotIndex), 'Position', axePosition);
            
            % Peak Tracking Windows
            if numOfSelected == 1
                obj.gui.panel(thisPanel).PeakWindowPlots(plotIndex) = ...
                    subplot(3, numOfSelected, plotIndex*3-1, 'Parent', obj.gui.panel(thisPanel).plotPanel);
            else
                obj.gui.panel(thisPanel).PeakWindowPlots(plotIndex) = ...
                    subplot(numOfSelected, 3, plotIndex*3-1, 'Parent', obj.gui.panel(thisPanel).plotPanel); 
            end
            title(['Detector ',num2str(i),' Peak Window'], 'FontSize', 8);
            xlabel('Wavelength (nm)', 'FontSize', 8);
            ylabel('Power (dBW)', 'FontSize', 8);
            axePosition = get(obj.gui.panel(thisPanel).PeakWindowPlots(plotIndex), 'Position');
            axePosition(1) = axePosition(1) - xOffset;
            set(obj.gui.panel(thisPanel).PeakWindowPlots(plotIndex), 'Position', axePosition);
            
            % Peak Tracking: Wavelength Shift vs. Scan Numbers
            if numOfSelected == 1
                obj.gui.panel(thisPanel).peakTrackPlots(plotIndex) = ...
                    subplot(3, numOfSelected, plotIndex*3, 'Parent', obj.gui.panel(thisPanel).plotPanel);
            else
                obj.gui.panel(thisPanel).peakTrackPlots(plotIndex) = ...
                    subplot(numOfSelected, 3, plotIndex*3, 'Parent', obj.gui.panel(thisPanel).plotPanel);
            end
            title(['Detector ',num2str(i),' peak tracking'], 'FontSize', 8);
            xlabel('Scan number', 'FontSize', 8);
            ylabel('Wavelength shift (pm)', 'FontSize', 8);
            axePosition = get(obj.gui.panel(thisPanel).peakTrackPlots(plotIndex), 'Position');
            axePosition(1) = axePosition(1) - xOffset;
            set(obj.gui.panel(thisPanel).peakTrackPlots(plotIndex), 'Position', axePosition);
            
            axePosition(1) = axePosition(1) + axePosition(3) + 0.01;
            axePosition(3) = 0.98 - axePosition(1);
            axePosition(2) = axePosition(2) + axePosition(4)/3;
            axePosition(4) = axePosition(4)/3;
            
            obj.gui.panel(thisPanel).peakTrackSaveBut(plotIndex) = uicontrol(...
                'Parent', obj.gui.panel(thisPanel).plotPanel,...
                'Style', 'pushbutton',...
                'Units', 'normalized',...
                'Position', axePosition,...
                'String', 'Save',...
                'Enable', 'on',...
                'Callback', {@saveRealTimePeakTracking, obj, i});
        end
    end
elseif strcmpi(test_type, 'DryTest') || strcmpi(test_type, 'WetTest')
    % Draw only wvl Vs. pwr plots
    plotIndex = 0;
    for i = 1:numDetectors
        if (selectedDetectors(i))
            plotIndex = plotIndex + 1;
            % draw wvl Vs. pwr plots
            obj.gui.panel(thisPanel).sweepScanPlots(plotIndex) = ...
                subplot(numOfSelected, 1, plotIndex);
            set(obj.gui.panel(thisPanel).sweepScanPlots(plotIndex), 'Parent', obj.gui.panel(thisPanel).plotPanel);
            title(strcat(['Detector ',num2str(i),' real-time scan']));
            xlabel('Wavelength (nm)');
            ylabel('Power (dB)');
        end
    end
else
    error('Cannot create plot windows. Unsure of test type.');
end
%% Test UI Panels
ui_x = plotPanel_w + 0.015;
ui_y = 0.01;
ui_width = 0.99 - ui_x;
ui_height = 0;
ui_position = [ui_x, ui_y, ui_width, ui_height];

% Wet or Dry test ui
% use if/else to tell which panel to draw
ui_position(4) = 0.75;
if strcmpi(test_type, 'SaltSteps') || strcmpi(test_type, 'TemperatureTest') || ...
        strcmpi(test_type, 'BioAssay')
    obj = assay_ui(...
        obj, ...
        'test', ...
        obj.gui.panelFrame(thisPanel), ...
        ui_position);
elseif strcmpi(test_type,'DryTest') || strcmp(test_type,'WetTest') || strcmpi(test_type, 'VirtualTestMode')
    obj = dry_test_ui(...
        obj, ...
        'test', ...
        obj.gui.panelFrame(thisPanel), ...
        ui_position);
elseif strcmpi(test_type, 'TestBenchCharacterization')
    [characterizationTest, path] = uigetfile('*.m', 'Select the test file.', fullfile(obj.AppSettings.path.root,'testSetupCharacterizationScripts'));
    if ~isequal(characterizationTest, 0) && ~isequal(path, 0)
        [~, characterizationTest, ~] = fileparts(characterizationTest);
    end
    obj.AppSettings.infoParams.CharacterizationTest = characterizationTest;
    
    obj = characterization_ui(...
        obj, ...
        'test', ...
        obj.gui.panelFrame(thisPanel), ...
        ui_position);
else
    error('Selected test type not currently supported');
end

% Status and control panel
ui_position(2) = ui_position(2) + ui_position(4);
ui_position(4) = 0.94 - ui_position(2);
obj = test_control_ui(...
    obj, ...
    'test', ...
    obj.gui.panelFrame(thisPanel), ...
    ui_position);

% Laser ui
% if (obj.instr.laser.Connected)
%     ui_position(2) = ui_position(2) + ui_position(4);
%     ui_position(4) = 0.94 - ui_position(2);
%     obj = laser_ui(...
%         obj, ...
%         'test', ...
%         obj.gui.panelFrame(thisPanel), ...
%         ui_position, ...
%         obj.gui.panel(thisPanel).sweepScanPlots);
% end
end

function saveRealTimePeakTracking(~, ~, obj, detectorIndex)

end

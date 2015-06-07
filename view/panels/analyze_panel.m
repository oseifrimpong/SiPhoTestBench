% © Copyright 2014-2015 WenXuan Wu, Shon Schmidt, and Jonas Flueckiger
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

function obj = analyze_panel(obj)

thisPanel = panel_index('analyze');
testType = obj.AppSettings.infoParams.Task;

numOfDevices = length(obj.testedDevices);
devicesList = cell(numOfDevices+1, 1);
devicesList{1} = '<Select Device>';
for d = 1:numOfDevices
    devicesList{d+1} = obj.testedDevices{d};
end

numDetectors = obj.instr.detector.getProp('NumOfDetectors');
detectorList = cell(numDetectors+1, 1);
detectorList{1} = '<Select Detector>';
for d = 1:numDetectors
    detectorList{d+1} = ['Detector No.', num2str(d)];
end
%% Quick Analysis Panel
quickAna_w = 0.98;
quickAna_h = 0.08;
x = 0.10;
y = 0.94 - quickAna_h;
button_w = 0.16;

obj.gui.panel(thisPanel).quickAnalysisPanel = uipanel(...
    'Parent', obj.gui.panelFrame(thisPanel), ...
    'Title', 'Quick Analysis', ...
    'FontSize', 9, ...
    'FontWeight', 'bold', ...
    'Unit', 'normalized', ...
    'BackgroundColor', [0.9, 0.9, 0.9], ...
    'Visible', 'on', ...
    'Position', [0.01, y, quickAna_w, quickAna_h]);

if (strcmpi(testType, 'SaltSteps') || strcmpi(testType, 'BioAssay'))
    deviceSelectionEnable = 'on';
elseif (strcmpi(testType, 'DryTest') || strcmpi(testType, 'WetTest'))
    deviceSelectionEnable = 'off';
end

obj.gui.panel(thisPanel).deviceSelection = uicontrol(...
    'Parent', obj.gui.panel(thisPanel).quickAnalysisPanel, ...
    'Style', 'popupmenu', ...
    'Enable', deviceSelectionEnable, ...
    'String', devicesList, ...
    'Unit', 'normalized', ...
    'Position', [x, 0.10, 0.16, 0.80], ...
    'Callback', {@deviceSelect_cb, obj});

x = x + button_w + 0.01;
obj.gui.panel(thisPanel).detectorSelection = uicontrol(...
    'Parent', obj.gui.panel(thisPanel).quickAnalysisPanel, ...
    'Style', 'popupmenu', ...
    'Enable', 'off', ...
    'String', detectorList, ...
    'Unit', 'normalized', ...
    'Position', [x, 0.10, 0.16, 0.80], ...
    'Callback', {@viewResult_cb, obj});

if (strcmpi(testType, 'SaltSteps') || strcmpi(testType, 'BioAssay'))
    analysisEnable = 'off';
    analysisName = 'Analyze';
    viewResultStr = 'View Analysis';
elseif (strcmpi(testType, 'DryTest') || strcmpi(testType, 'WetTest'))
    analysisEnable = 'on';
    analysisName = 'Publish Report';
    viewResultStr = 'View Report';
end

x = x + button_w + 0.01;
obj.gui.panel(thisPanel).analyzeButton = uicontrol(...
    'Parent', obj.gui.panel(thisPanel).quickAnalysisPanel, ...
    'Style', 'pushbutton', ...
    'Enable', analysisEnable, ...
    'String', analysisName, ...
    'Unit', 'normalized', ...
    'Position', [x, 0.02, 0.16, 0.96], ...
    'Callback', {@quickAnalysis_cb, obj});

x = x + button_w + 0.01;
obj.gui.panel(thisPanel).viewAnalysisButton = uicontrol(...
    'Parent', obj.gui.panel(thisPanel).quickAnalysisPanel, ...
    'Style', 'togglebutton', ...
    'Enable', 'off', ...
    'String', viewResultStr, ...
    'Value', 0, ...
    'Unit', 'normalized', ...
    'Position', [x, 0.02, 0.16, 0.96], ...
    'Callback', {@viewAnalysis_cb, obj});

x = x + button_w + 0.01;
obj.gui.panel(thisPanel).saveButton = uicontrol(...
    'Parent', obj.gui.panel(thisPanel).quickAnalysisPanel, ...
    'Style', 'togglebutton', ...
    'Enable', 'off', ...
    'String', 'Save Analysis', ...
    'Value', 0, ...
    'Unit', 'normalized', ...
    'Position', [x, 0.02, 0.12, 0.96], ...
    'Callback', {@saveAnalysis_cb, obj});

%% Result Panel
resultP_w = 0.98;
resultP_h = 0.94 - quickAna_h;
y = 0.01;

obj.gui.panel(thisPanel).trackingResultPanel = uipanel(...
    'Parent', obj.gui.panelFrame(thisPanel), ...
    'Title', 'Test Results', ...
    'FontSize', 9, ...
    'FontWeight', 'bold', ...
    'Unit', 'normalized', ...
    'BackgroundColor', [0.9, 0.9, 0.9], ...
    'Visible', 'on', ...
    'Position', [0.01, y, resultP_w, resultP_h]);
end

function deviceSelect_cb(hObject, ~, obj)
thisPanel = panel_index('analyze');
deviceIndex = get(hObject, 'Value');
if deviceIndex > 1
    set(obj.gui.panel(thisPanel).detectorSelection, 'Enable', 'on');
else
    set(obj.gui.panel(thisPanel).detectorSelection, 'Enable', 'off');
end
end

function viewResult_cb(~, ~, obj)
thisPanel = panel_index('analyze');
% Obtain the interested devices name and detector number
[deviceName, detectorNumber] = getDeviceSelection(obj);

if detectorNumber >= 1 && strcmpi(obj.AppSettings.infoParams.Task, 'SaltSteps')
    % Obtain the peak tracking result from the interested devices
    [peaks, peaksN, numOfPeaks] = getPeakInfo(obj, deviceName, detectorNumber);
    
    % Obtain the recipe file
    scanSet = obj.recipe.time;
    cumScan = [0;cumsum(scanSet)];
    reagent = obj.recipe.reagent;
    
    % Plot the every peak tracking result separately
    [subplotNum_r, subplotNum_c] = getPlotSize(numOfPeaks);
    
    for p = 1:numOfPeaks
        obj.gui.panel(thisPanel).peakTrackPlots(p) = ...
            subplot(subplotNum_r, subplotNum_c, p, 'Parent', obj.gui.panel(thisPanel).trackingResultPanel);
        plot(obj.gui.panel(thisPanel).peakTrackPlots(p), ...
            1:length(peaksN{p}), peaksN{p}, 'r')
        hold on
        grid on
        xlim([1 length(peaksN{p})]);
        legend(sprintf('Peak: %4.4fnm', peaks{p}(1)));
        axeRange = ylim(obj.gui.panel(thisPanel).peakTrackPlots(p));
        for r = 1:length(reagent)
            y = linspace(axeRange(1), axeRange(2), 20);
            plot(obj.gui.panel(thisPanel).peakTrackPlots(p), cumScan(r+1)*ones(1, 20), y, 'b--', 'LineWidth', 2);
            rs = sprintf(strrep(reagent{r}, ' ', '\n'));
            text(cumScan(r) + scanSet(r)/3, axeRange(2)*0.9, ...
                rs, 'FontSize', 10, 'FontWeight', 'bold', 'Color', [0 0 1])
        end
        title(sprintf('Real-Time Peak Tracking \nDevice: %s \nDetector No.%d Peak: %4.4f', ...
            strrep(deviceName, '_', '-'), detectorNumber, peaks{p}(1)));
        xlabel('Scan Numbers');
        ylabel('Peak Wavelength Shift (pm)');
        hold off
    end   
end
% set(obj.gui.panel(thisPanel).trackingResultPanel, 'Visible');
% Enable Quick Analysis
set(obj.gui.panel(thisPanel).analyzeButton, 'Enable', 'on');
end

function quickAnalysis_cb(hObject, ~, obj)
thisPanel = panel_index('analyze');
% Obtain the interested devices name and detector number
[deviceName, detectorNumber] = getDeviceSelection(obj);

% Create and new panel object to put the analysis results
obj.gui.panel(thisPanel).analysisResultPanel = uipanel(...
    'Parent', obj.gui.panelFrame(thisPanel), ...
    'Title', 'Analysis Results', ...
    'FontSize', 9, ...
    'FontWeight', 'bold', ...
    'Unit', 'normalized', ...
    'BackgroundColor', [0.9, 0.9, 0.9], ...
    'Visible', 'off', ...
    'Position', [0.01, 0.01, 0.98, 0.86]);

if strcmpi(obj.AppSettings.infoParams.Task, 'SaltSteps') && detectorNumber >= 1
    % Obtain the peak tracking result from the interested devices
    [peaks, peaksN, numOfPeaks] = getPeakInfo(obj, deviceName, detectorNumber);
    
    % Obtain recipe file
    scanSet = obj.recipe.time;
    cumScan = [0;cumsum(scanSet)];
    ri = obj.recipe.ri;
    uniqueRI = sort(unique(ri));
    
    % Plot the every peak tracking result separately
    [subplotNum_r, subplotNum_c] = getPlotSize(numOfPeaks);
    
    for p = 1:numOfPeaks
        shiftArray = cell(length(uniqueRI), 1);
        meanShiftArray = zeros(length(uniqueRI), 1);
        errShiftArray = zeros(length(uniqueRI), 1);
        
        for r = 1:length(ri)
            riIndex = find(ri(r) == uniqueRI);
            shiftArray{riIndex} = [shiftArray{riIndex}, peaksN{p}(cumScan(r)+1:cumScan(r+1))];
        end
        
        for r = 1:length(uniqueRI)
            meanShiftArray(r) = mean(shiftArray{r});
            errShiftArray(r) = std(shiftArray{r});
        end
        
        fitP = polyfit(uniqueRI(2:end), meanShiftArray(2:end), 1); % Ignore the water RI (1.333)
        fitShiftArray = polyval(fitP, uniqueRI(2:end));
        sensitivity = fitP(1)/1000; % Transform from pm/RIU to nm/RIU
        
        obj.gui.panel(thisPanel).analysisPlots(p) = ...
            subplot(subplotNum_r, subplotNum_c, p, 'Parent', obj.gui.panel(thisPanel).analysisResultPanel);
        
        plot(obj.gui.panel(thisPanel).analysisPlots(p), ...
            uniqueRI, meanShiftArray, 'ko')
        hold on
        grid on
        plot(obj.gui.panel(thisPanel).analysisPlots(p), uniqueRI(2:end), fitShiftArray, 'b--', 'LineWidth', 2)
        legend('Mean Shifts', 'Fitting');
        errorbar(obj.gui.panel(thisPanel).analysisPlots(p), ...
            uniqueRI, meanShiftArray, errShiftArray, 'r--');
        title(sprintf('Sensitivity Analysis \nDevice: %s Detector No.%d Peak: %4.4fnm\nSensitivity = %.1fnm/RIU', ...
            strrep(deviceName, '_', '-'), detectorNumber, peaks{p}(1), sensitivity));
        xlabel('Refractive Index');
        ylabel('Peak Wavelength Shift (pm)');
        hold off
    end
    set(obj.gui.panel(thisPanel).viewAnalysisButton, 'Enable', 'on');
    
elseif strcmpi(obj.AppSettings.infoParams.Task, 'DryTest') || strcmpi(obj.AppSettings.infoParams.Task, 'WetTest')
    if strcmpi(obj.AppSettings.FinishTestSettings.MoveData, 'Yes')
        chipDir = strrep(obj.chip.Name, '_', filesep);
        filePath = fullfile(...
            obj.AppSettings.path.testData,...
            chipDir,...
            obj.AppSettings.infoParams.DieNumber);
    else
        filePath = obj.AppSettings.path.tempData;
    end
    outputFormat = 'pdf';
    options = struct(...
        'format', outputFormat, ...
        'outputDir', filePath, ...
        'showCode', false, ...
        'codeToEvaluate', 'viewTestResults(testbench)');
    publish('viewTestResults', options);
    
    outputFile = fullfile(filePath, 'viewTestResults.', outputFormat);
    renameFile = fullfile(filePath, 'AUTO_TestReport_', obj.chip.Name, '_', obj.AppSettings.infoParams.DieNumber, '_', obj.AppSettings.infoParams.Task, '_', obj.lastTestTime, '.', outputFormat);
    movefile(outputFile, renameFile, 'f');
    
    try
        open(renameFile);
    end
end

set(hObject, 'Enable', 'off');
% set(obj.gui.panel(thisPanel).saveButton, 'Enable', 'on');
end

function viewAnalysis_cb(hObject, ~, obj)
thisPanel = panel_index('analyze');
isPressed = get(hObject, 'Value');

if strcmpi(obj.AppSettings.infoParams.Task, 'SaltSteps') || strcmpi(obj.AppSettings.infoParams.Task, 'BioAssay')
    if isPressed
        set(hObject, 'String', 'Hide Analysis');
        set(obj.gui.panel(thisPanel).analysisResultPanel, 'Visible', 'on');
        set(obj.gui.panel(thisPanel).trackingResultPanel, 'Visible', 'off');
    else
        set(hObject, 'String', 'View Analysis');
        set(obj.gui.panel(thisPanel).analysisResultPanel, 'Visible', 'off');
        set(obj.gui.panel(thisPanel).trackingResultPanel, 'Visible', 'on');
    end
elseif strcmpi(obj.AppSettings.infoParams.Task, 'DryTest') || strcmpi(obj.AppSettings.infoParams.Task, 'WetTest')
    
end
end

function saveAnalysis_cb(~, ~, obj)

end

function [deviceName, detectorNumber] = getDeviceSelection(obj)
thisPanel = panel_index('analyze');
deviceName = get(obj.gui.panel(thisPanel).deviceSelection, 'String');
deviceIndex = get(obj.gui.panel(thisPanel).deviceSelection, 'Value');
deviceName = deviceName{deviceIndex};
detectorNumber = get(obj.gui.panel(thisPanel).detectorSelection, 'Value') - 1;
end

function [peaks, peaksN, numOfPeaks] = getPeakInfo(obj, deviceName, detectorNumber)
peaks = obj.devices.(deviceName).PeakLocations{detectorNumber};
peaksN = obj.devices.(deviceName).PeakLocationsN{detectorNumber};
numOfPeaks = length(peaksN);
end

function [subplotNum_r, subplotNum_c] = getPlotSize(numOfPeaks)
subplotNum_r = round(sqrt(numOfPeaks));
subplotNum_c = subplotNum_r;
while subplotNum_r * subplotNum_c < numOfPeaks
    subplotNum_c = subplotNum_c + 1;
end
end

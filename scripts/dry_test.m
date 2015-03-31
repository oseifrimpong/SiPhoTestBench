% © Copyright 2013-2015 Shon Schmidt, Jonas Flueckiger, and WenXuan Wu
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

function dry_test(obj)

% Get testPanel index so that sript can acess the GUI components
testPanel = panel_index('test');
% start the test timer
ticID = tic;
% get number of detectors to loop on figure plots
numDetectors = obj.instr.detector.getProp('NumOfDetectors');
selectedDetectors = obj.instr.detector.getProp('SelectedDetectors');
% get list of all chip's devices
deviceNames = fieldnames(obj.devices);
% create index for selected devices
selectedDeviceIndex = 0;
% flags for button presses in the middle of sweeps/moves/aligns
pauseReq = 0; % flag 0=no, 1=yes
stopReq = 0; % flag 0=no, 1=yes

% determine total number of steps (devices * iterations)
totalNumberOfSteps = 0;
for ii = 1:length(deviceNames)
    if obj.devices.(deviceNames{ii}).getProp('Selected')
        totalNumberOfSteps = totalNumberOfSteps + 1;
    end
end
totalNumberOfSteps = totalNumberOfSteps * obj.AppSettings.dryTest.Iterations;

%% Do test
obj.msg('<<<<<<<<<<  Start test  >>>>>>>>>>')
% loop through iterations
for iteration = 1:obj.AppSettings.dryTest.Iterations
    % data store path
    generalFilePath = createTempDataPath(obj);
    % create <dateTag> for device directories
    %   format = c:\TestBench\TempData\<chipArch>\<dieNum>\<device>\<testType>\<dateTag>\*
    dateTag = datestr(now,'yyyy.mm.dd@HH.MM'); % time stamp
    obj.lastTestTime = dateTag;
    % loop through selected devices
    schoolTag = obj.AppSettings.infoParams.School;
    %Tag to setup different folder structure; 
    
    for k = 1:length(deviceNames)
        if obj.devices.(deviceNames{k}).getProp('Selected')
            %% check for stop. If true, abort
            if  stopReq
%                 obj.msg('<<<<<<<<<<  Test canceled.  >>>>>>>>>>')
%                 % popup UI window for the user
%                 message = sprintf('Test canceled.\nDeleting dataset.\nClick OK to continue');
%                 uiwait(msgbox(message));
%                 % delete data set
%                 % loop through all device dirs and delete dirs with <dateTag>
%                 for ii = 1:length(deviceNames)
%                     specificFilePath = strcat(...
%                         generalFilePath,...
%                         obj.devices.(deviceNames{ii}).Name,'\',...
%                         obj.AppSettings.infoParams.Task,'\',...
%                         dateTag,'\');
%                     if (exist(specificFilePath, 'dir') == 7) % If the directory exist, it would return 7
%                         try
% %                            disp(specificFilePath)
%                             rmdir(specificFilePath, 's'); % remove directory and all subdirectories
%                             msg = strcat('Deleted ',specificFilePath);
%                             obj.msg(msg);
%                         catch ME
%                             obj.msg(ME.message);
%                         end
%                     end
%                 end
%                 % reset flags and re-enable buttons
%                 set(obj.gui.panel(testPanel).testControlUI.stopButton, 'UserData', 0); % stop
%                 set(obj.gui.panel(testPanel).testControlUI.stopButton, 'Enable', 'off');
%                 set(obj.gui.panel(testPanel).testControlUI.pauseButton, 'Enable', 'off');
%                 set(obj.gui.panel(testPanel).testControlUI.startButton, 'Enable', 'on');
                stopTest(obj, generalFilePath, dateTag);
                return
            end
            
            %% check for pause. If true, pause the test
            if pauseReq
%                 msg='<<<<<  Pausing test. Please wait.  >>>>>'; obj.msg(msg);
%                 message = sprintf('Test paused.\nClick OK to continue');
%                 uiwait(msgbox(message));
%                 msg='<<<<<  Resuming test.  >>>>>'; obj.msg(msg);
%                 set(obj.gui.panel(testPanel).testControlUI.pauseButton, 'UserData', 0); % reset pause flag
%                 set(obj.gui.panel(testPanel).testControlUI.pauseButton, 'Enable', 'on');
%                 set(obj.gui.panel(testPanel).testControlUI.startButton, 'Enable', 'off');
                pauseTest(obj);
            end
            
            %% update status
            selectedDeviceIndex = selectedDeviceIndex + 1; % index to status table
            msg = strcat(num2str(selectedDeviceIndex), '/', num2str(totalNumberOfSteps));
            set(obj.gui.panel(testPanel).testControlUI.progressDisplay, 'String', msg);
            
            try %Jonas: enclose everything in a try in case something goes wrong it woudl still go to the next device and try
                
                %% move to next device
                currentDevice = obj.devices.(obj.chip.CurrentLocation);
                targetDevice = obj.devices.(deviceNames{k});
                moveToDevice(obj, currentDevice, targetDevice);  %scripted move function
                set(obj.gui.panel(testPanel).testControlUI.currentDeviceDisplay, 'String', obj.devices.(deviceNames{k}).Name);
                %% fine align
                
                fine_align(obj, 'panel', testPanel);
                % shon 3/27/2014 do it twice until we figure out the bug
                %fine_align(obj, 'panel', testPanel);
                
                %% sweep
                [wvlData, pwrData] = sweep(obj);
                % plot sweep data in subplot window
                %   wvlData and pwrData are returned as n x m arrays
                %   n=datapoints and m=number of detectors
            catch ME %This means that something went wrong for that device: move, align, or sweep
                val = 'SweepFail';
                obj.msg(ME.message);
                rethrow(ME);
            end
                plotIndex = 0;
                for ii=1:numDetectors
                    if (selectedDetectors(ii))
                        plotIndex = plotIndex + 1;
                        axes(obj.gui.panel(testPanel).sweepScanPlots(plotIndex)); %#ok<*LAXES>
                        plot(wvlData(1:end-1,ii), pwrData(1:end-1,ii));
                    end
                end
                
                %% save data to object and disk
            try    
                % params to save with each scan
                params = scanParams(obj); % testbench equipment params to save with data
                % Check to see if temp data dir exists. If not, create
                targetDevice.checkDirectory(generalFilePath,...
                    obj.AppSettings.infoParams.Task,...
                    dateTag,schoolTag);
                % save data
                targetDevice.saveData(wvlData, pwrData, params,schoolTag);
                % save plots
                if obj.AppSettings.dryTest.SavePlots
                    targetDevice.savePlot(wvlData, pwrData,schoolTag);
                end

                
                %% rate test result
                val = {'Unknown', 'Unknown', 'Unknown', 'Unknown'}; % initialize
                if obj.AppSettings.dryTest.RateRealtime
                    msg = 'Rate device';
                    %        list = obj.AppSettings.Device.RatingOptions;
                    list = {'Unknown', 'Unusable', 'Poor', 'Good'};
                    [~, val] = popup_dialog(msg,list);
                else % do automated threshold rating
                    rtn = obj.devices.(deviceNames{k}).passFailCheck(obj.AppSettings.dryTest.Threshold);
                    for r = 1:length(rtn)
                        if selectedDetectors(r)
                            if rtn(r) == 1
                                val{r} = 'Pass';
                            else
                                val{r} = 'Fail';
                            end
                        end % Otherwise keep as "unknown"
                    end
                end
                
            catch ME %This means that something went wrong for that device: move, align, or sweep
                val = 'ComFail';
                obj.msg(ME.message);
            end
            
            if ~isempty(strfind(val, 'Pass')) || ~isempty(strfind(val, 'Good'))
                obj.devices.(deviceNames{k}).setProp('Rating', 'Pass');
            else
                obj.devices.(deviceNames{k}).setProp('Rating', 'Fail');
            end
            
            %        msg=obj.devices.(deviceNames{k}).getProp('Rating'); msg
            % color code the test result for the table
            % gray 69 - http://www.color-hex.com/color-names.html
            %        ratingColor = '<html><table border=0 width=400 bgcolor=#b0b0b0><TR height=100><TD>&nbsp;</TD></TR> </table></html>';
%             if strcmp(val, 'Good') || strcmp(val, 'Pass') % pass=auto
%                 ratingColor = '<html><table border=0 width=400 bgcolor=#7CFC00><TR height=100><TD>&nbsp;</TD></TR> </table></html>';
%             elseif strcmp(val, 'Poor')
%                 ratingColor = '<html><table border=0 width=400 bgcolor=#FF6600><TR height=100><TD>&nbsp;</TD></TR> </table></html>'; % orange
%             else % strcmp(val, 'Unusable') || strcmp(val, 'Fail')
%                 ratingColor = '<html><table border=0 width=400 bgcolor=#FF0000><TR height=100><TD>&nbsp;</TD></TR> </table></html>'; %red
%             end
            ratingColor = cell(size(val));
            for r = 1:length(val)
                switch val{r}
                    case 'Good'
                        ratingColor{r} = '<html><table border=0 width=400 bgcolor=#7CFC00><TR height=100><TD>&nbsp;</TD></TR> </table></html>'; %green
                    case 'Pass'
                        ratingColor{r} = '<html><table border=0 width=400 bgcolor=#7CFC00><TR height=100><TD>&nbsp;</TD></TR> </table></html>'; %green
                    case 'Poor'
                        ratingColor{r} = '<html><table border=0 width=400 bgcolor=#FF6600><TR height=100><TD>&nbsp;</TD></TR> </table></html>'; %orange
                    case 'Fail'
                        ratingColor{r} = '<html><table border=0 width=400 bgcolor=#FF0000><TR height=100><TD>&nbsp;</TD></TR> </table></html>'; %red
                    case 'SweepFail'
                        ratingColor{r} = '<html><table border=0 width=400 bgcolor=#FFFF00><TR height=100><TD>&nbsp;</TD></TR> </table></html>'; %red
                    case 'ComFail'
                        ratingColor{r} = '<html><table border=0 width=400 bgcolor=#000000><TR height=100><TD>&nbsp;</TD></TR> </table></html>'; %black
                    case 'Unknown'
                        ratingColor{r} = '<html><table border=0 width=400 bgcolor=#404040><TR height=100><TD>&nbsp;</TD></TR> </table></html>'; %Gray
                end
                obj.gui.panel(testPanel).dryTestUI.deviceTable{selectedDeviceIndex, 1+r} = ratingColor{r};
            end
            %Note jonasf: Quick fix so matlab doesn't slow down with large number of
            %devices. needs to be changed for wet test (peak tracking)
            if strcmp(schoolTag,'UBC')
                targetDevice.setProp('PreviousSweep',[]);
                targetDevice.setProp('ThisSweep',[]);
            end
            %% update status table in test panel
%             obj.gui.panel(testPanel).dryTestUI.deviceTable{selectedDeviceIndex, 2} = ratingColor;
%             obj.gui.panel(testPanel).dryTestUI.deviceTable{selectedDeviceIndex, 3} = (obj.devices.(deviceNames{k}).getProp('Rating'));
            set(obj.gui.panel(testPanel).dryTestUI.resultTable, 'Data', obj.gui.panel(testPanel).dryTestUI.deviceTable);
            
            %% prep for next
            % update scan #
            currentScanNumber = targetDevice.getScanNumber();
            set(obj.gui.panel(testPanel).testControlUI.scanNumberDisplay, 'String', num2str(currentScanNumber));
            % update elapsed time
            elapsedTimeSec = toc(ticID); % sec
            set(obj.gui.panel(testPanel).testControlUI.elapsedTimeDisplay, 'String', num2str(round(elapsedTimeSec/60)));
            
            % check for 'pause' or 'stop' by user
            pauseReq = get(obj.gui.panel(testPanel).testControlUI.pauseButton, 'UserData'); % pause
            stopReq = get(obj.gui.panel(testPanel).testControlUI.stopButton, 'UserData'); % stop
        end
    end
end % iterations

% shons note-call finish script here
%finishDryTest(obj);

%% Send Email
if obj.AppSettings.FinishTestSettings.SendEmail
    sendEmail(obj.AppSettings.infoParams.Email, sprintf('%s Finish!', obj.AppSettings.infoParams.Task), 'The result is available now.')
end

%% Move Data
moveData(obj);

% re-enable buttons
set(obj.gui.panel(testPanel).testControlUI.stopButton, 'UserData', 0); % stop
set(obj.gui.panel(testPanel).testControlUI.stopButton, 'Enable', 'off');
set(obj.gui.panel(testPanel).testControlUI.pauseButton, 'Enable', 'off');
set(obj.gui.panel(testPanel).testControlUI.startButton, 'Enable', 'on');
% pop-up window for user
% message = sprintf('Test finished.\nClick OK to continue');
% uiwait(msgbox(message));

obj.msg('<<<<<  Test finished.  >>>>>');

end

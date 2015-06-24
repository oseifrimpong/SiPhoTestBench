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

classdef DeviceClass < handle
    
    properties
        % from coordinates file
        Name; % string
        X; % x-coordinate
        Y; % y-coordinate
        Mode; % 'TE' or 'TM'
        Wvl; % designed-for wavelength (ex: 1220, 1310, 1550, etc.)
        Type; % device type (align, bio, device, test struct, etc.)
        Comment; % comment
        Rating; % tested quality of the device
        
        % for testing
        FilePath;
        Selected; % for testing 0=no, 1=yes
        hasPeakSelected; % boolean
        PeakLocations; % (m) array of wavelength values for selected peaks
        PeakLocationsN; % Normalized PeakLocations
        PeakTrackWindows; % (m) window around peak location for tracking
        isPeak; % positive peak vs. resonant null for peak tracking
    end
    
    properties (Access = protected)
        BenchObj;
        % sweep range determined by min/max values of PeakLocations
        StartWvl; % for sweep (m)
        StopWvl; % for sweep (m)
        Resolution; %sweep resolution (m) or step size
        NumOfDetectors; %number of channels recorded
        PreviousSweep; %Stores wvl and pwr values for last sweep
        PreviousQ;
        ThisSweep; %Stores wvl and pwr values for the current sweep
        ThisQ;
        DetectorMemorySize; % number of points, should query for this
        StartPeakTrackWindows;
        
        % for testing
        TestStatus; % untested = 0, tested = 1
        UserDataDir; % path to user's data directory
        TestHistoryFile; % to be implemented
        ScanNumber;
        
        BioAssayNoteAdded;
    end
    
    methods
        % constructor
        function self = DeviceClass(varargin)
            
            % from obj
            %             self.UserDataDir = obj.settings.path.UserDataDir;
            self.BenchObj = varargin{1}; % bench object
            deviceInfo = varargin{2}; % device parameters
            
            % assume device info from coord file passed in struct
            self.X = deviceInfo.x;
            self.Y = deviceInfo.y;
            self.Mode = deviceInfo.mode;
            self.Name = deviceInfo.name;
            self.Comment = deviceInfo.comment;
            self.Wvl = deviceInfo.wvl;
            self.Type = deviceInfo.type;
            self.Rating = 'unknown'; % good, fair, bad, unusuable
            
            self.FilePath = '';
            self.PeakTrackWindows = {}; % in m
            self.Resolution = [];
            self.hasPeakSelected = 0;
            self.PeakLocations = {}; %field names will be nubmer (as detector)
            self.PeakLocationsN = {};
            self.PeakTrackWindows = {};
            self.NumOfDetectors = [];  %could be different than actual hardware detectors
            self.isPeak = []; % 1=positive going peak, 0=resonant null

            % default values
            self.Selected = 0; % selected for testing
            
            % pre-allocate for speed
            self.DetectorMemorySize = self.BenchObj.instr.detector.getProp('DataPoints');
            %             self.PreviousSweep.wvl = zeros(self.DetectorMemorySize,1);
            %             self.PreviousSweep.pwr = zeros(self.DetectorMemorySize,1);
            %             self.ThisSweep.wvl = zeros(self.DetectorMemorySize,1);
            %             self.ThisSweep.pwr = zeros(self.DetectorMemorySize,1);
            self.PreviousSweep = [];
            self.PreviousQ = [];
            self.ThisSweep = [];
            self.ThisQ = [];
            self.ScanNumber = 0;
            self.TestStatus = 0;
            
            self.BioAssayNoteAdded = false;
        end
        
        %% get device history
        function getDeviceHistory(self)
        end
        
        %% determine pass/fail using threshold
        function rtn = passFailCheck(self, threshold)
            % initialize rtn
            rtn = zeros(1,self.NumOfDetectors);
            for ii = 1:self.NumOfDetectors
                if (threshold < max(self.ThisSweep(ii).pwr))
                    rtn(ii) = 1; % pass
                else
                    rtn(ii) = 0; % fail
                end
            end
        end
        
        % create test directory
        function testDir(self)
        end
        
%         function [self, output] = validateDataSet(self)
%             self.NumOfDetectors = length(self.ThisSweep);
%             for ii = 1:self.NumOfDetectors
%                 self.Resolution(ii) = self.ThisSweep(ii).wvl(2)-self.ThisSweep(ii).wvl(1);
%                 %no data
%             end
%             %             %comput extinction ratio or some other performance metrix
%             %             if max > extinction ratio
%             %                 self.Rating = 'excellent'
%             %             end
%             %
%             %            output = self.Rating;
%             output = 'good';
%             %             self.ScanNumber = self.ScanNumber + 1;
%             % update previous/current arrays
%         end
        
%         function trackPeak(self)
%             %Assumes data data is saved in self.ThisSweep and Self.PreviousSweep
%             %assumes that self.PeakLocations is not empty
%             
%             self.validateDataSet();
%             
%             %peakfinder(x0, thresh, extrema); extrema: valley or peak
%             %self.PeakLocations={[det1 at t=0], [det2 at t=0], [det3 at t=0]
%             %[det1 at t=1], [det2 at t=1], [det3 at t=1]}
%             %{scanNumber, detector}
%             
%             for ii=1:self.NumOfDetectors
%                 ind_range = self.PeakTrackWindows / self.Resolution(ii);
%                 if self.ScanNumber > 1
%                     [m, n] = size(self.PeakLocations{self.ScanNumber-1,ii});
%                 else
%                     [m, n] = size(self.PeakLocations{1,ii});
%                 end
%                 for jj=1:m
%                     if (self.ScanNumber>1)
%                         init_guess=self.PeakLocations{self.ScanNumber-1,ii}(jj);
%                     else
%                         init_guess=self.PeakLocations{1,ii}(jj);
%                     end
%                     ind=find(self.ThisSweep.wvl==init_guess);
%                     if ind
%                         x = self.ThisSweep(ii).wvl(ind-ind_range/2:ind+ind_range/2);
%                         y = self.ThisSweep(ii).pwr(ind-ind_range/2:ind+ind_range/2);
%                         [ind_PeakLoc, PeakMag] = peakfinder(y, 4, -1);
%                         self.PeakLocations{self.ScanNumber,ii}(jj)=x(ind_PeakLoc);
%                     else
%                         disp('no index found for init_guess');
%                     end
%                 end
%             end
%         end
        

        %% reset scan number
        function resetScanNumber(self)
            self.ScanNumber = 0;
            if ~isempty(self.PeakLocations)
                for d = 1:self.NumOfDetectors
                    for p = 1:length(self.PeakLocations{d})
                        self.PeakLocations{d}{p} = self.PeakLocations{d}{p}(1);
                        self.PeakLocationsN{d}{p} = self.PeakLocationsN{d}{p}(1);
                        self.PeakTrackWindows{d}{p} = self.StartPeakTrackWindows{d}{p};
                    end
                end
            else
                self.PeakLocations = cell(1, self.NumOfDetectors);
                self.PeakLocationsN = cell(1, self.NumOfDetectors);
                self.PeakTrackWindows = cell(1, self.NumOfDetectors);
                self.StartPeakTrackWindows = self.PeakTrackWindows;
            end
        end
        
        %% get scan number
        function value = getScanNumber(self)
            value = self.ScanNumber;
        end
        
        %% reset rating
        function resetRating(self)
            self.Rating = {'Unknown'};
        end
        
        %% save data
        function saveData(self, wvlData, pwrData, params, varargin)
            % Increase the ScanNumber
            self.ScanNumber = self.ScanNumber + 1;
            % Generate Time Stamp
            timeStamp = datestr(now,'yyyy.mm.dd@HH.MM.SS');
            
            % for now, just save off the data to a file
            %NumOfDetectors = self.BenchObj.instr.detector.getProp('NumOfDetectors');
            %pwrData: col = detector number
            %write the incoming wvlData and pwrData to the device class.
            [DataPoints, self.NumOfDetectors] = size(pwrData);
            
            %             %old data saved put into separate structure for peak tracking
            %             self.PreviousSweep = self.ThisSweep;
            %update device with current data
            self.PreviousSweep = self.ThisSweep;
            for ii = 1:self.NumOfDetectors  %loop through all the detectors
                self.ThisSweep(ii).wvl = wvlData(:,ii);
                self.ThisSweep(ii).pwr = pwrData(:,ii);
            end
            
            for i = 1:self.NumOfDetectors
                %            subplot(NumOfDetectors, 1, i)
                %            plot(wvlData(:,i), pwrData(:,i), color(i));
                scanResults(i) = struct(...
                    'Data', [wvlData(:,i), pwrData(:,i)]);
                %            legend(strcat('Detector No.', num2str(i - 1)));
            end
            
            deviceInfo = struct(...
                'Name', self.Name, ...
                'Mode', self.Mode, ...
                'Comment', self.Comment, ...
                'X', self.X, ...
                'Y', self.Y, ...
                'Wvl', self.Wvl, ...
                'Type', self.Type, ...
                'Rating', self.Rating);
            switch varargin{1}
                case 'UBC'
                    file = strcat(self.FilePath, self.Name, '_Scan',num2str(self.ScanNumber),'.mat');
                case 'UW'
                    file = strcat(self.FilePath, 'Scan', num2str(self.ScanNumber), '.mat');
                otherwise
                    file = strcat(self.FilePath, 'Scan', num2str(self.ScanNumber), '.mat');
            end
                    
            save(file, 'scanResults', 'timeStamp', 'deviceInfo', 'params');
        end
        
        %% save plots

        function savePlot(self, wvlData, pwrData, varargin)
            %pwrData: col = detector number
            [~, self.NumOfDetectors] = size(pwrData);
            excludedChannel = [];
            for i = 1:self.NumOfDetectors
                if all(pwrData(:, i) == 0)
                    excludedChannel(end + 1) = i;
                end
            end
            includedNumOfDetectors = self.NumOfDetectors - length(excludedChannel);
            f = figure(...
                'Name', ['Sweep Results: ', 'Scan No.', num2str(self.ScanNumber)], ...
                'Units', 'normalized', ...
                'Position', [0 0 .84 .76], ...
                'NumberTitle', 'off', ...
                'Visible', 'on');
            movegui(f, 'center');
            color = ['r', 'g', 'b','r','g','b'];
            for i = 1:self.NumOfDetectors
                if any(i ~= excludedChannel)
                    NegInf = find(pwrData(:,i)==-200);
                    PosInf = find(pwrData(:,i)==400);
                    pwrData(NegInf, i) = -Inf;
                    pwrData(PosInf, i) = Inf;
                    subplot(includedNumOfDetectors, 1, i)
                    plot(wvlData(:,i), pwrData(:,i), color(i));
                    legend(strcat('Detector No.', num2str(i - 1)));
                end
            end
            switch varargin{1}
                case 'UBC'
                    file = strcat(self.FilePath, self.Name, '_Scan',num2str(self.ScanNumber));
                    print(f,'-dpdf',strcat(file,'.pdf'));
                    saveas(f,strcat(file,'.fig'));
                case 'UW'
                    file = strcat(self.FilePath, 'Scan', num2str(self.ScanNumber));
                    print(f,'-dpdf',strcat(file,'.pdf'));
                    saveas(f,strcat(file,'.fig'));
                otherwise
                    file = strcat(self.FilePath, 'Scan', num2str(self.ScanNumber));
                    print(f,'-dpdf',strcat(file,'.pdf'));
                    saveas(f,strcat(file,'.fig'));
            end
            %print(f,'-dpdf',strcat(self.FilePath, 'Scan', num2str(self.ScanNumber),'.pdf'));
            %saveas(f,strcat(self.FilePath, 'Scan', num2str(self.ScanNumber),'.fig'));
            delete(f);
        end
        
        function addBioAssayNote(self, BioAssayNote)
            if ~self.BioAssayNoteAdded
                fileName = strcat(self.FilePath, BioAssayNote, '.txt');
                fclose(fopen(fileName, 'w+'));
                self.BioAssayNoteAdded = true;
            end
        end
        
% Vince, not sure why you need this method. Shon        
        function hasDir = hasDirectory(self)
            hasDir = ~isempty(strtrim(self.FilePath));
        end
        
        function checkDirectory(self, filePath, taskType, dateTag, varargin)
            %different for UBC and UW
            %assumes that varargin{1} = obj.AppSettings.infoParams.School
            switch varargin{1}
                case 'UBC'
                    self.FilePath = strcat(...
                        filePath, ...
                        dateTag,'\');
                    
                case 'UW'
                    self.FilePath = strcat(...
                        filePath, ...
                        self.Name, '\', ...
                        taskType, '\', ...
                        dateTag, '\');
                otherwise
                    self.FilePath = strcat(...
                        filePath, ...
                        self.Name, '\', ...
                        taskType, '\', ...
                        dateTag, '\');
            end
            if (exist(self.FilePath, 'dir') ~= 7) % If the directory exist, it would return 7
                mkdir(self.FilePath);
            end
            
        end
        
        function extendDirectory(self, subDirectoryName)
            self.FilePath = [self.FilePath, subDirectoryName];
            if (exist(self.FilePath, 'dir') ~= 7) % If the directory exist, it would return 7
                mkdir(self.FilePath);
            end
        end
        
        function truncateDirectory(self, subDirectoryName)
            self.FilePath = self.FilePath(1:end - length(subDirectoryName));
        end
        
        function val = getProp(self, prop)
            try
                val = self.(prop);
            catch ME
                msg = strcat(self.Name, ' ', prop, ' does not exist.');
                disp(msg);
            end
        end
        
        function setProp(self, prop, val)
            try
                self.(prop) = val;
            catch ME
                msg = strcat(self.Name, ' ', prop, ' does not exist.');
                disp(msg);
            end
        end
        
        function resultMsg = checkPeakSelection(self)
            self.hasPeakSelected = 0;
            for d = 1:self.NumOfDetectors
                if ~isempty(self.PeakLocations{d})
                    self.hasPeakSelected = 1;
                    break
                end
            end
            if self.hasPeakSelected
                resultMsg = sprintf('Peak(s) Selection for device: %s', self.Name);
                for d = 1:self.NumOfDetectors
                   resultMsg = sprintf('%s\n\tNumber of Peak(s) for detector %d: %d', resultMsg, d, length(self.PeakLocations{d})) ;
                end
            else % Is not empty but not consistent with number of detectors - ERROR!
                resultMsg = sprintf('No peaks are selected for device: \n\t%s', self.Name);
            end
        end
        
        function trackPeaks(self)
            % if self.ScanNumber <= 1 % First Scan
                % For the first Scan, we only need to determine the
                % tracking windows for each peak selected
                % self.setPeakWindow(0.5, 1.0);
            % else % After the first Scan: i.e. self.ScanNumber >= 2
                % After the first Scan, we need to relocate the peaks for
                % each wet test sweep 
                self.peaksTracking();
                self.setPeakWindow();
            % end
        end
        
        function results = getNormalizedTrackedPeakLocations(self)
            results = self.PeakLocationsN;
        end
        
        function results = getTrackedPeakLocations(self)
            results = self.PeakLocations;
        end
        
        function results = getPeakTrackWindows(self)
            results = self.PeakTrackWindows;
        end
        
        function savePeaksTrackData(self)
            peaksTrackData = self.PeakLocations;
            peaksTrackDataN = self.PeakLocationsN;
            isPeakInfo = self.isPeak;
            fileName = strcat(self.FilePath, 'PeakTracking.mat');
            save(fileName, 'peaksTrackData', 'peaksTrackDataN', 'isPeakInfo');
            
            % Rewrite Scan File: add in peak info
            scanFileName = sprintf('%sScan%d.mat', self.FilePath, self.ScanNumber);
            scanFile = load(scanFileName);
            peakResults = struct(...
                'isPeak', 0, ...
                'peakWvl', 0, ...
                'wvlWindow', 0);
            peakResults.isPeak = self.isPeak;
            peakResults.peakWvl = cell(size(self.PeakLocations));
            peakResults.wvlWindow = cell(size(self.PeakTrackWindows));
            for d = 1:self.NumOfDetectors
                for p = 1:length(self.PeakLocations{d})
                    peakResults.peakWvl{d}{p} = self.PeakLocations{d}{p}(self.ScanNumber);
                    peakResults.wvlWindow{d}{p} = self.ThisSweep(d).wvl(self.PeakTrackWindows{d}{p}(end)) - self.ThisSweep(d).wvl(self.PeakTrackWindows{d}{p}(1));
                end
            end
            scanFile.peakResults = peakResults;
            save(scanFileName, '-struct', 'scanFile');
        end
        
        function clearPeakSelection(self, channel)
            self.PeakLocations{channel} = {};
            self.PeakLocationsN{channel} = {};
            self.PeakTrackWindows{channel} = {};
            self.StartPeakTrackWindows{channel} = {};
        end
        
        function setPeakSelection(self, channel, peakWvl, peakWindow)
            for ii = 1:length(peakWvl)
                self.PeakLocations{channel}{ii} = peakWvl(ii);
                self.PeakLocationsN{channel}{ii} = 0;
                self.PeakTrackWindows{channel}{ii} = peakWindow(ii, 1):peakWindow(ii, 2);
            end
            self.StartPeakTrackWindows{channel} = self.PeakTrackWindows{channel};
        end
    end
    
    methods (Access = private)
        function peaksTracking(self)
            for d = 1:self.NumOfDetectors
                tempSweepWvl = self.ThisSweep(d).wvl;
                tempSweepPwr = self.ThisSweep(d).pwr;
                for p = 1:length(self.PeakLocations{d})
                    % Get the wavelength window from the last test
                    wvlWindow = tempSweepWvl(self.PeakTrackWindows{d}{p});
                    pwrWindow = tempSweepPwr(self.PeakTrackWindows{d}{p});
                    % Assuming the peak is still in the tracking window,
                    % then it should has the minimum power
                    if self.isPeak(d) % positive going peak
                        [~, peakInd] = max(pwrWindow);
                    else % resonant null (negative going peak)
                        [~, peakInd] = min(pwrWindow);
                    end
                    if length(peakInd) > 1
                        peakInd = round(mean(peakInd));
                    end
                    peakWvl = wvlWindow(peakInd);
%                     self.PeakLocations{d}{p}(end + 1) = peakWvl;
%                     self.PeakLocationsN{d}{p}(end + 1) = (peakWvl - self.PeakLocations{d}{p}(1))*1000; % in pm
                    self.PeakLocations{d}{p}(self.ScanNumber) = peakWvl;
                    self.PeakLocationsN{d}{p}(self.ScanNumber) = (peakWvl - self.PeakLocations{d}{p}(1))*1000; % in pm
                end
            end
        end
        
        function setPeakWindow(self) % range in nm
            for d = 1:self.NumOfDetectors
%                 previousSweepWvl = self.PreviousSweep(d).wvl;
                thisSweepWvl = self.ThisSweep(d).wvl;
                for p = 1:length(self.PeakLocations{d})
                    % Get the latest peak location
                    peakWvl = self.PeakLocations{d}{p}(end);
                    peakIndArray = find(thisSweepWvl - peakWvl <= 0);
                    peakInd = peakIndArray(end);
                    
                    windowSize = floor(length(self.PeakTrackWindows{d}{p})/2);
                    
                    % Store the window into property
                    self.PeakTrackWindows{d}{p} = max(peakInd - windowSize, 1):min(peakInd + windowSize, length(thisSweepWvl));
                end
                if length(self.PeakLocations{d}) <= 0
                    self.PeakTrackWindows{d} = {};
                end
            end
            % Calculate Q for all the peaks
            % self.Qestimation();
        end
        
%         function Qestimation(self)
%             self.PreviousQ = self.ThisQ;
%             for d = 1:self.NumOfDetectors
%                 for p = 1:length(self.PeakLocations{d})
%                     pwrWindow = self.ThisSweep(d).pwr(self.PeakTrackWindows{d}{p});
%                     wvlWindow = self.ThisSweep(d).wvl(self.PeakTrackWindows{d}{p});
%                     if ~self.isPeak
%                         % look for the minima in the window
%                         baseline = mean([pwrWindow(1:round(length(pwrWindow)/10)), pwrWindow(end-round(length(pwrWindow)/10)):end]);
%                         [~, index] = min(pwrWindow);
%                         wvlAtMinPwr = wvlWindow(index); % in nm's
%                         % report
%                         % from the min, walk up each side until you reach baseline - 3dB
%                         pwrLeft = pwrWindow(index); % initial power val going left and up
%                         pwrLeftIndex = index; % initial index val going left and up
%                         pwrRight = pwrWindow(index); % initial power val going right and up
%                         pwrRightIndex = index; % initial index val going right and up
%                         % start at the top and go left
%                         while (pwrLeft < baseline - 3) && pwrLeftIndex > 1 % 3dB down
%                             % decrement index and check power val
%                             pwrLeftIndex = pwrLeftIndex - 1;
%                             pwrLeft = pwrWindow(pwrLeftIndex);
%                         end
%                         % go right
%                         while (pwrRight < baseline - 3) && pwrRightIndex < length(pwrWindow) % 3dB down
%                             % increment index and check power val
%                             pwrRightIndex = pwrRightIndex + 1;
%                             pwrRight = pwrWindow(pwrRightIndex);
%                         end
%                         % find wavelengths at pwrFitLeftIndex and pwrFitRightIndex
%                         min3dBWvl = wvlWindow(pwrLeftIndex); % in nm's
%                         max3dBWvl = wvlWindow(pwrRightIndex); % in nm's
%                         self.ThisQ{d}{p} = wvlAtMinPwr /(max3dBWvl-min3dBWvl);
%                         
%                     else % is a peak
%                         % look for the maxima in the window
%                         [maxPwr, index] = max(pwrWindow);
%                         wvlAtMaxPwr = wvlWindow(index); % in nm's
%                         % from the min, walk up each side until you reach baseline - 3dB
%                         pwrLeft = pwrWindow(index); % initial power val going left and up
%                         pwrLeftIndex = index; % initial index val going left and up
%                         pwrRight = pwrWindow(index); % initial power val going right and up
%                         pwrRightIndex = index; % initial index val going right and up
%                         % start at the top and go left
%                         while (pwrLeft > maxPwr - 3) && pwrLeftIndex > 1 % 3dB down
%                             % decrement index and check power val
%                             pwrLeftIndex = pwrLeftIndex - 1;
%                             pwrLeft = pwrWindow(pwrLeftIndex);
%                         end
%                         % go right
%                         while (pwrRight > maxPwr - 3) && pwrRightIndex < length(pwrWindow) % 3dB down
%                             % increment index and check power val
%                             pwrRightIndex = pwrRightIndex + 1;
%                             pwrRight = pwrWindow(pwrRightIndex);
%                         end
%                         % find wavelengths at pwrFitLeftIndex and pwrFitRightIndex
%                         min3dBWvl = wvlWindow(pwrLeftIndex); % in nm's
%                         max3dBWvl = wvlWindow(pwrRightIndex); % in nm's
%                         self.ThisQ{d}{p} = wvlAtMaxPwr /(max3dBWvl-min3dBWvl);
%                     end
%                 end
%             end
%         end
        
        %% methods for air bubble detection - shon January 2015
        function msg = scanToScanCorrelation(self, threshold)
            % clear msg, the parent function relies on this to error out
            msg = '';
            % loop through channels
            for d = 1:self.NumOfDetectors
                % need to check if channel is selected, local copies
                %thisSweepWvl = self.ThisSweep(d).wvl;
                thisSweepPwr = self.ThisSweep(d).pwr;
                %previousSweepWvl = self.PreviousSweep(d).wvl;
                previousSweepPwr = self.PreviousSweep(d).pwr;
                for p = 1:length(self.PeakLocations{d})
                    % Get window
                    %wvlWindow = thisSweepWvl(self.PeakTrackWindows{d}{p});
                    thisPwrWindow = thisSweepPwr(self.PeakTrackWindows{d}{p});
                    previousPwrWindow = previousSweepPwr(self.PeakTrackWindows{d}{p});
                    % Assuming the peak is still in the tracking window,
                    % then it should has the minimum power
                    if self.isPeak(d) % positive going peak
                        [~, thisPeakInd] = max(thisPwrWindow);
                        [~, previousPeakInd] = max(previousPwrWindow);
                    else % resonant null (negative going peak)
                        [~, thisPeakInd] = min(thisPwrWindow);
                        [~, previousPeakInd] = min(previousPwrWindow);
                    end
                    if length(peakInd) > 1
                        peakInd = round(mean(peakInd));
                    end
                    peakWvl = wvlWindow(peakInd);
                    %                     self.PeakLocations{d}{p}(end + 1) = peakWvl;
                    %                     self.PeakLocationsN{d}{p}(end + 1) = (peakWvl - self.PeakLocations{d}{p}(1))*1000; % in pm
                    self.PeakLocations{d}{p}(self.ScanNumber) = peakWvl;
                    self.PeakLocationsN{d}{p}(self.ScanNumber) = (peakWvl - self.PeakLocations{d}{p}(1))*1000; % in pm
                end
                
                % loop through peaks
                % recenter waveform in window to avoid false detection due to molecular binding
                % normalize to avoid false detection due to fine_align/drift power issues
                % do correlation and check against threshold, create msg
                
            end
        end
        
        % correlation function
        function correlation(self, previousPeakWvl, previousPeakPwr)
            % the previous peak is passed in
            if self.fit.menuBarPeak.normalizeCorrelation
                thisPeakPwr = self.raw.pwrs - max(self.raw.pwrs);
                previousPeakPwr = previousPeakPwr - max(previousPeakPwr);
            else
                thisPeakPwr = self.raw.wvls;
            end
            
            % create wvl/pwr arrays for comparison
            thisPeak = [self.raw.wvls*e9 thisPeakPwr]; % create matrix
            previousPeak = [previousPeakWvl*e9 previousPeakPwr]; % create matrix
            
            [self.fit.rho, self.fit.pval] = corr(previousPeak, thisPeak, 'type', 'Pearson');
        end

    end
end


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

function viewTestResults(obj)
numOfDevices = length(obj.testedDevices);
%%
selectedDetectors = obj.instr.detector.getProp('SelectedDetectors');
selectedDetectors = find(selectedDetectors ~= 0);
for d = 1:numOfDevices
        thisSweep = obj.devices.(obj.testedDevices{d}).getProp('ThisSweep');

    %% Plot Test results for all selected devices
    
    for dd = 1:length(selectedDetectors)
        thisDetector = selectedDetectors(dd);
        subplot(length(selectedDetectors), 1, dd)
        plot(thisSweep(thisDetector).wvl, thisSweep(thisDetector).pwr, 'b');
        title(sprintf('Device: %s Detector: %d', strrep(obj.testedDevices{d}, '_', '-'), thisDetector))
        xlabel('Wavelength (nm)')
        ylabel('Power (dB)')
    end
end
end

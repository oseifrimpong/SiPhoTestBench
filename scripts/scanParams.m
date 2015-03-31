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

function params = scanParams(benchObj)
    laserParam = benchObj.instr.laser.getAllParams();
    detectorParam = benchObj.instr.detector.getAllParams();
    opticalStageParam = benchObj.instr.opticalStage.getAllParams();
    TECParam = benchObj.instr.thermalControl.getAllParams();
    PumpParam = [];
    AssayParams = [];
    if benchObj.activateBioFeature()
        PumpParam = benchObj.instr.pump.getAllParams();
        AssayParams = benchObj.AppSettings.AssayParams;
    end
    params = struct(...
        'laserParams', laserParam, ...
        'detectorParams', detectorParam, ...
        'opticalStageParams', opticalStageParam, ...
        'TECParams', TECParam,...
        'PumpParams', PumpParam,...
        'SweepParams', benchObj.AppSettings.SweepParams,...
        'AssayParams', AssayParams);
end

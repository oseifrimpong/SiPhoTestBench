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

function obj = initialize_panels(obj)

list = panel_index('all');
numOfPanels = length(list);

obj.gui.panelFrame = zeros(1, numOfPanels);

for ii = 1:numOfPanels
    obj.gui.panelFrame(ii) = uipanel(...
        'Parent', obj.gui.benchMainWindow, ...
        'BackGroundColor', [0.9, 0.9, 0.9], ...
        'Units', 'normalized', ...
        'Visible', 'off', ...
        'Position', [.01, .065, 0.75, 0.925]);
    obj.gui.panel(ii) = struct();
end
end

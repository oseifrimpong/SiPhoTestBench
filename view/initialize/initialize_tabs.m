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

function obj = initialize_tabs(obj)

list = panel_index('all');
numOfPanels = length(list);

obj.gui.tab = zeros(1, numOfPanels);

    for ii = 1:numOfPanels
        obj.gui.tabFrame(ii) = uipanel('Parent', obj.gui.benchMainWindow, ...
            'BackgroundColor', [0.8 0.8 0.8], ...
            'Units', 'normalized', ...
            'Position', ...
            [.0111 + (ii-1)*0.7468/numOfPanels 0.94 0.7468/numOfPanels 0.05]);

        obj.gui.tab(ii) = uicontrol('Parent', obj.gui.tabFrame(ii), ...
            'Style', 'text', ...
            'FontSize', 11, ...
            'String', panel_index(ii), ...
            'BackgroundColor', [0.8 0.8 0.8], ...
            'Units', 'normalized', ...
            'Position', [0 0 1 1]);
    end
end

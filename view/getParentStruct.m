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

%   getParentStruct function is used to determine the parent struct (string) 
% under which the instrument UIs should be built.
%   It takes the parent panel name (string) as input and return the parent
% structure name (string).
function parentStruct = getParentStruct(parentName)
% New popup should be added here in a elseif statement
% adding new main panels are not required here because it is obtain the
% panel_index function.
if strcmpi(parentName, 'manual')
    parentStruct = 'manualCoordPopup';
elseif strcmpi(parentName, 'selectPeaks')
    parentStruct = 'selectPeaksPopup';
else % Should belong to one of the panels
    thisPanel = num2str(panel_index(parentName));
    parentStruct = strcat('panel(', thisPanel, ')');
end
end

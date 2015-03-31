% © Copyright 2013-2015 WenXuan Wu
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

classdef Camera < InstrClass
    properties
        PreviewAxes = 0;
        CameraObj = '';
        CameraFound = [];
        CameraID = 0;
        Resolution = [0 0];
        NumOfBands = 3;
        PreviewImage = zeros(0, 0, 3);
        Capture = zeros(0, 0, 3);
    end
    
    methods
        function self = Camera()
            self.Name = 'Virtual Camera';
            self.Group = 'Camera';
        end
        
        function [self, msg] = connect(self)
            self.Connected = 1;
            msg = 'Virtual Camera Connected!';
        end
        
        function [self, msg] = start(self)
            if self.Connected == 1
                self.Resolution = [1024 768];
                self.NumOfBands = 3;
                self.PreviewImage = image(zeros(self.Resolution(2)*2, ...
                    self.Resolution(1)*2, ...
                    self.NumOfBands), ...
                    'Parent', self.PreviewAxes);
                msg = 'Camera ON';
            else
                msg = 'Virtual Camera is not connected!';
            end
        end
        
        function [self, msg] = capture(self)
            if self.Connected == 1
                self.Capture = zeros(1024, 768);
                f = figure('NumberTitle', 'off', ...
                    'Name', 'Captured Image', ...
                    'MenuBar', 'none', ...
                    'ToolBar', 'figure', ...
                    'Units', 'normalized', ...
                    'Position', [0 0 0.66, 0.66]);
                movegui(f, 'center');
                set(findall(f, 'Tag', 'Standard.NewFigure'), 'Visible', 'off');
                set(findall(f, 'Tag', 'Standard.FileOpen'), 'Visible', 'off');
                imshow(self.Capture);
            else
                msg = 'Camera is not connected!';
            end
        end
        
        function [self, msg] = close(self)
            if self.Connected == 1
                try
                    delete(self.PreviewImage);
                    msg = 'Camera OFF';
                catch ME
                    msg = 'Error turning off camera!';
                    disp(ME.message);
                end
            else
                msg = 'Camera is not connected!';
            end
        end
        
        function [self, msg] = disconnect(self)
            try
                self.Connected = 0;
                msg = 'Camera disconnected!';
            catch ME
                msg = 'Error disconnecting camera!';
                disp(ME.message);
            end
        end
    end
end

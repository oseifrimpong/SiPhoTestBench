% ?Copyright 2013-2015 Shon Schmidt, Jonas Flueckiger, and WenXuan Wu
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

classdef TestBenchClass < handle
    properties
        
        %% object handles
        gui; % all UI elements
        instr; % all instruments
        timer;
        chip; % chip under test
        devices; % all devices on a chip
        testedDevices; % Selected devices for the latest test
        lastTestTime;
        coordsys;  %coordinate system transform
        assayCtl; % assay control class
        
        %% program settings
        
        %Defautls to populate defaults
        guiDefaults;    %
        instrDefaults;  %list of intruments available
        
        %recipe file
        %  recipe.well
        %  recipe.time
        %  recipe.velocity
        %  recipe.reagent
        %  recipe.temp
        %  recipe.comment
        recipe;
        recipeFile;
        
        AppSettings; % active settings in the application
        
    end
    
    properties (Access = private)
        includeBioFeature;
    end
    
    methods
        
        %% constructor
        function self = TestBenchClass
            addpath(genpath('./'));
            
            % Load Application Defaults
            self.includeBioFeature = false;
            ds = applicationDefaults();
            self.AppSettings.infoParams.School = 'UBC'; % *Note*
            if exist('..\siphotestbenchbio\', 'dir') == 7 % 7 - directory exist
                addpath(genpath('..\siphotestbenchbio\'));
                ds = applicationDefaultsBio(ds);
                self.includeBioFeature = true;
                self.AppSettings.infoParams.School = 'UW'; % *Note*
            end
            
            % *Note*
            % The school information ('UBC' or 'UW') used above is an
            % switch for different saving methods utilized by the two
            % software contributor universities: The University of British
            % Columbia (UBC) and The University of Washington (UW).
            % If bio feature is not downloaded in the computer, the UBC
            % saving method will be used. UW saving method will be deployed
            % in any other situations.
            % *Note*
            
            self.AppSettings = ds.AppSettings;
            self.guiDefaults = ds.guiDefaults;
            self.instrDefaults = ds.instrDefaults;
            
            %the saved user settings will be loaded after the startup panel
            
            % Instantiate the coordinate system class.
            %self.coordsys = CoordSysClass;  %by Jonas: is in the corvus
            %class now.
            % Initialize the main GUI window
            self.init;
            
            self.recipe = [];
            self.recipeFile = '';
            
            self.AppSettings.Device.RatingOptions = ds.Device.RatingOptions;
            self.AppSettings.Device.ActiveDeviceList = []; % initialize?
            %DEBUG: the above settings need to be added to the update_user
            %method
        end
    end
    
    
    methods % public
        
        function self = load_user(self, userID)
            try
                % Load the existing user file
                userfile = strcat(self.AppSettings.path.userData, userID, '\AppSettings.mat');
                
                % Load all the settings for the instruments
                userobj = load(userfile);
                fn = fieldnames(userobj);
                for k = 1:length(fn)
                    self.AppSettings.(fn{k}) = userobj.(fn{k});
                end
                
                msg = sprintf('User: %s loaded!', userID);
                self.msg(msg);
                msg = sprintf('Current User: %s', userID);
                self.msg(msg);
            catch ME
                msg = strcat('ERROR: Unable to load user file: ', userID);
                self.msg(msg);
                disp(ME.message);
            end
        end
        
        function self = new_user(self, userID)
            try
                userfile = strcat(self.AppSettings.path.userData, userID, '\AppSettings.mat');
                
                try
                    if (exist(self.AppSettings.path.userData, 'dir')) ~= 7 % 7 is check for directory
                        mkdir(self.AppSettings.path.userData);
                    end
                    mkdir(strcat(self.AppSettings.path.userData, userID, '\')); % Under folder of User Name
                    mkdir(strcat(self.AppSettings.path.userData, userID, '\coordinateFiles\'));
                    mkdir(strcat(self.AppSettings.path.userData, userID, '\recipeFiles\'));
                    
                    addpath(genpath(self.AppSettings.path.userData));
                catch ME
                    msg = 'Cannot generate user directory!';
                    self.msg(msg);
                    disp(ME.message);
                end
                self.AppSettings.infoParams.Name = userID;
                
                % Pass all parameters to the new user mat-file
                userobj = self.AppSettings;
                save(userfile, '-struct', 'userobj');
                
                msg = sprintf('New User: %s created!', userID);
                self.msg(msg);
                msg = sprintf('Current User: %s', userID);
                self.msg(msg);
            catch ME
                msg = sprintf('ERROR: Unable to create new user: %s', userID);
                self.msg(msg);
                disp(ME.message);
            end
        end
        
        function self = update_user(self, userID)
            try
                % Load the existing user file
                userfile = strcat(self.AppSettings.path.userData, userID, '\AppSettings.mat');
                
                % Update all parameters to the current user mat-file
                userobj = self.AppSettings;
                save(userfile, '-struct', 'userobj');
            catch ME
                msg = sprintf('ERROR: Unable to update user: %s', userID);
                self.msg(msg);
                disp(ME.message);
            end
        end
        
        function userList = getUsers(self)
            userList = self.guiDefaults.userList;
            % users = dir(fullfile(self.AppSettings.path.userData, '*.mat'));
            users = dir(self.AppSettings.path.userData);
            users = users(3:end);
            for i = 1:length(users)
                if users(i, 1).isdir
%                     fn = users(i,1).name; %load (username).mat
%                     username = fn(1:end-4); %get rid of .mat extension
                    username = users(i, 1).name;
                    userList{end+1} = username;
                end
            end
        end
        
        function WriteToDisk(varargin)
            
        end
        
        function msg(self, message)
            
            % Modify debug message
            clk = clock;
            clkstr = sprintf('%.2d:%.2d:%.2d', clk(4), clk(5), fix(clk(6)));
            msg = sprintf('%s -  %s ', clkstr, message);
            
            % Obtain current string on the debug window
            string = get(self.gui.debugConsole, 'String');
            if(isempty(string))
                string = cell(1, 1);
                string{1} = msg;
            else
                %jonasf: the ever increasing msg string seems to slow down the auto
                %measurement; has to load from GUI and write to GUI everytime.
                max_length = 100;
                if length(string)>max_length
                    string(2:max_length+1) = string(1:max_length);
                    string{1} = msg;
                else
                    % Add new message to debug window
                    string(2:end+1) = string;
                    string{1} = msg;
                end
            end
            
            set(self.gui.debugConsole, 'String', string);
            
        end
        
        function isActive = activateBioFeature(self)
            isActive = self.includeBioFeature;
        end
        
        %% pop-up window for setting object parameters
        function obj = settingsWin(obj, paramStruct)
            numParams = length(fieldnames(obj.AppSettings.(paramStruct)));
            obj.gui.PopupWinH = dialog('WindowStyle', 'modal', ...
                'Units', 'normalized', ...
                'Resize', 'on', ...
                'Position', [.45 .75-.05*numParams .3 .03*numParams]); % need to check this
            
            % 'Position', [.45 .45 .15 .05*numParams/1.5]); % need to check this
            
            % get list of all the indices in struct
            fields = fieldnames(obj.AppSettings.(paramStruct));
            % convert struct to cell array
            cellA = struct2cell(obj.AppSettings.(paramStruct));
            
            % loop through params and create gui elements
            for ii = 1:length(fieldnames(obj.AppSettings.(paramStruct)))
                size = length(fieldnames(obj.AppSettings.(paramStruct)));
                % create field name
                obj.gui.paramName(ii) = uicontrol('Parent', obj.gui.PopupWinH, ...
                    'Style', 'text', ...
                    'Units', 'normalized', ...
                    'Position', [.005 .95- 0.9*ii/size .49 1/(2*numParams)], ...
                    'HorizontalAlignment', 'right', ...
                    'FontSize', 10, ...
                    'String', fields(ii));
                
                % field value (typed)
                if (isnumeric(cellA{ii}))
                    paramType = 'numeric';
                elseif (ischar(cellA{ii}))
                    paramType = 'string';
                elseif (islogical(cellA{ii}))
                    paramType = 'logical';
                end
                
                if strcmp(paramType, 'logical')
                    % create a checkbox
                    obj.gui.paramVal(ii) = uicontrol('Parent', obj.gui.PopupWinH, ...
                        'Style', 'checkbox', ...
                        'Value', obj.AppSettings.(paramStruct).(fields{ii}),...
                        'Units', 'normalized', ...
                        'Position', [.51 .95- 0.9*ii/size .15 1/(2*numParams)], ...
                        'Callback', {@obj.settingsWinVal, ii, paramStruct});
                else % create a string box for everything else
                    obj.gui.paramVal(ii) = uicontrol('Parent', obj.gui.PopupWinH, ...
                        'Style', 'edit', ...
                        'Units', 'normalized', ...
                        'Position', [.51 .95- 0.9*ii/size .15 1/(2*numParams)], ... %'Position', [.45 .95-ii/10 .3 .08], ...
                        'HorizontalAlignment', 'left', ...
                        'FontSize', 10, ...
                        'String', cellA{ii},...
                        'Callback', {@obj.settingsWinVal, ii, paramStruct});
                end
            end
            
            % done button
            obj.gui.doneButton = uicontrol('Parent', obj.gui.PopupWinH, ...
                'Style', 'pushbutton', ...
                'Units', 'normalized', ...
                'Position', [.8 .05 .1 1/(1.5*numParams)], ...
                'HorizontalAlignment', 'center', ...
                'FontSize', 10, ...
                'String', 'Done',...
                'Callback', @obj.settingsWinDone);
            
            movegui(obj.gui.PopupWinH, 'center');
        end
        
        % settingsWinVal callback
        function obj = settingsWinVal(obj, hObject, eventData, ii, paramStruct)
            % Need to do some type checking here...
            % get list of struct fields
            fields = fieldnames(obj.AppSettings.(paramStruct));
            
            % field value (typed)
            if islogical(obj.AppSettings.(paramStruct).(fields{ii}))
                % get value
                newVal = get(hObject, 'Value');
                obj.AppSettings.(paramStruct).(fields{ii}) = logical(newVal);
            elseif isnumeric(obj.AppSettings.(paramStruct).(fields{ii}))
                % get value
                newVal = get(hObject, 'String');
                obj.AppSettings.(paramStruct).(fields{ii}) = str2num(newVal);
            else % assume string
                % get value
                newVal = get(hObject, 'String');
                obj.AppSettings.(paramStruct).(fields{ii}) = newVal;
            end
        end
    end
    
    methods (Static)
        function settingsWinDone(hObject, eventData)
            uiresume;
            delete(get(hObject, 'parent'));
            %            delete(obj.gui.PopupWinH);
        end
        
        function varargout = manageTimer(action, varargin)
            switch lower(action)
                case 'pause'
                    active_timers = timerfindall('Running', 'on');
                    numOfTimers = length(active_timers);
                    for ii=1:numOfTimers
                        stop(active_timers(ii));
                    end
                    varargout{1} = active_timers;
                case 'resume'
                    active_timers = varargin{1};
                    numOfTimers = length(active_timers);
                    for ii=1:numOfTimers
                        start(active_timers(ii));
                    end
            end
        end
        
        function varargout = callFunctionHandle(UIhandle, varargin)
            callbackHandle = get(UIhandle, 'Callback');
            callbackF = callbackHandle{1}
            nargin(callbackF)
            subInput = varargin
            nargout(callbackF)
            if nargout(callbackF) >= 1
                varargout = callbackF(subInput);
            else
                callbackF(subInput);
            end
        end
    end
    
    methods (Access = private)
        function self = init(self)
            self.initialize_instr();
            self = initialize_main(self);  % init main gui window and panels
            self.assayCtl = [];
        end
        
        function self = initialize_instr(self)
            % Initiate and store user and instrument information
            instrNames = fieldnames(self.instrDefaults);
            for i = 1:length(instrNames)
                self.instr.(instrNames{i}) = self.instrDefaults.(instrNames{i}){1};
            end
        end
    end
    
    methods (Static, Access = private)
        defaultStructs = applicationDefaults();
    end
end

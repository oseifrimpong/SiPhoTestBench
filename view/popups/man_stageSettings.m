function man_stageSettings(gui)

user = get(gui.next_button, 'UserData');
instr = get(gui.back_button, 'UserData');

fstageSettings = figure(...
    'Units', 'Pixels', 'Position', [700, 300, 340, 580],...
    'Menu', 'None',...
    'Name', 'Corvus Stage Control Settings',...
    'WindowStyle', 'modal',...  %normal , modal, docked.
    'Visible', 'on',...
    'NumberTitle', 'off',...
    'CloseRequestFcn',{@close_stageSetting});

set(fstageSettings, 'Units', 'normalized')

%Panels
hScanArea = uipanel(...
    'parent',fstageSettings,...
    'Unit','Pixels',...
    'BackgroundColor',[0.9 0.9 0.9 ],...
    'Visible','on',...
    'units', 'normalized', 'Position',[0, 0, 1, 1]);
hCoarseAlignParam = uipanel(...
    'parent',hScanArea,...
    'Title','coarse align settings',...
    'FontWeight', 'bold',...
    'Unit','Pixels',...
    'BackgroundColor',[0.9 0.9 0.9 ],...
    'Visible','on',...
    'units', 'normalized', 'Position',[0, 0.45, 1, 0.55]);
hFineAlignParam = uipanel(...
    'parent',hScanArea,...
    'Title','fine align settings',...
    'FontWeight', 'bold',...
    'Unit','Pixels',...
    'BackgroundColor',[0.9 0.9 0.9 ],...
    'Visible','on',...
    'Units', 'normalized', 'Position',[0, 0.175, 1, 0.275]);
%Panel stage setting
hStageSettings = uipanel(...
    'parent',hScanArea,...
    'Title','Stage settings',...
    'Unit','Pixels',...
    'BackgroundColor',[0.9 0.9 0.9 ],...
    'FontWeight', 'bold',...
    'Visible','on',...
    'Units', 'normalized', 'Position',[0, 0.075, 1, 0.1]);

%Panel Scan window param
hScanWindowCoarseAlign = uipanel(...
    'parent',hCoarseAlignParam,...
    'Title','ScanWindow',...
    'FontWeight', 'bold',...
    'Unit','Pixels',...
    'BackgroundColor',[0.9 0.9 0.9 ],...
    'Visible','on',...
    'Units', 'normalized', 'Position',[0.05, 0.25, 0.90, 0.3]);
hLaserCoarseAlign = uipanel(...
    'parent',hCoarseAlignParam,...
    'Title','Laser Settings',...
    'FontWeight', 'bold',...
    'Unit','Pixels',...
    'BackgroundColor',[0.9 0.9 0.9 ],...
    'Visible','on',...
    'Units', 'normalized', 'Position',[0.05, 0.05, .9, 0.2]);
%Panel scan widnow fine align
hScanWindowFineAlign = uipanel(...
    'parent',hFineAlignParam,...
    'Title','ScanWindow',...
    'Unit','Pixels',...
    'BackgroundColor',[0.9 0.9 0.9 ],...
    'FontWeight', 'bold',...
    'Visible','on',...
    'Units', 'normalized', 'Position',[0.05, 0.5, 0.9, 0.45]);
hLaserFineAlign = uipanel(...
    'parent',hFineAlignParam,...
    'Title','Laser Settings',...
    'Unit','Pixels',...
    'FontWeight', 'bold',...
    'BackgroundColor',[0.9 0.9 0.9 ],...
    'Visible','on',...
    'Units', 'normalized', 'Position',[0.05, 0.05, 0.9, 0.45]);
%Panel stage settings
hStageSettingsParam = uipanel(...
    'parent',hStageSettings,...
    'Unit','Pixels',...
    'FontWeight', 'bold',...
    'BackgroundColor',[0.9 0.9 0.9 ],...
    'Visible','on',...
    'Units', 'normalized', 'Position',[0.05, 0.05, 0.9, 0.9]);




bg=[0.9 0.9 0.9];
image1 = imread('./gui/icons/ScanWindow2.png','BackgroundColor',bg);
hImageAxes=axes(...
    'parent', hCoarseAlignParam,...
    'Units','normalized','Position',[0.00 0.55 0.9 0.45],...
    'XGrid','off',...
    'YGrid','off');
image(image1);
axis off;
axis image;

hTextDeltaXScanCA = uicontrol(...
    'parent', hScanWindowCoarseAlign,...
    'Style','text',...
    'String','delta X [um]',...
    'HorizontalAlignment','right',...
    'Position',[140,50,75,15]);
hDeltaXScanCA = uicontrol(...
    'parent',hScanWindowCoarseAlign,...
    'Style','edit',...
    'Position', [220,50,45,15],...
    'String',num2str(instr.opticalStage.CAParams.DeltaXScan),...
    'Callback', {@updateDataPoint_callback});
hTextDeltaYScanCA = uicontrol(...
    'parent',hScanWindowCoarseAlign,...
    'Style','text',...
    'String','delta Y [um]',...
    'HorizontalAlignment','right',...
    'Position',[140,30,75,15]);
hDeltaYScanCA = uicontrol(...
    'parent',hScanWindowCoarseAlign,...
    'Style','edit',...
    'Position', [220,30,45,15],...
    'String',num2str(instr.opticalStage.CAParams.DeltaYScan));
hTextXOffsetScanCA = uicontrol(...
    'parent', hScanWindowCoarseAlign,...
    'Style','text',...
    'String','X-Offset [um]',...
    'HorizontalAlignment','right',...
    'Position',[10, 50,75, 15]);
hXOffsetScanCA = uicontrol(...
    'parent',hScanWindowCoarseAlign,...
    'Style','edit',...
    'Position', [90,50,45,15],...
    'String',num2str(instr.opticalStage.CAParams.XOffsetScan));
hTextYOffsetScanCA = uicontrol(...
    'parent', hScanWindowCoarseAlign,...
    'Style','text',...
    'String','Y-Offset [um]',...
    'HorizontalAlignment','right',...
    'Position',[10,30,75,15]);
hYOffsetScanCA = uicontrol(...
    'parent',hScanWindowCoarseAlign,...
    'Style','edit',...
    'Position', [90,30,45,15],...
    'String',num2str(instr.opticalStage.CAParams.YOffsetScan));
hTextdYScanCA = uicontrol(...
    'parent',hScanWindowCoarseAlign,...
    'Style','text',...
    'String','dy [um]',...
    'HorizontalAlignment','right',...
    'Position',[140, 10, 75, 15]);
hdYScanCA = uicontrol(...
    'parent',hScanWindowCoarseAlign,...
    'Style','edit',...
    'Position', [220, 10, 45, 15],...
    'String',num2str(instr.opticalStage.CAParams.dXScan));
hTextSpeedCA = uicontrol(...
    'parent', hScanWindowCoarseAlign,...
    'Style','text',...
    'String', 'v [mm/s]',...
    'HorizontalAlignment','right',...
    'Position',[10,10,75,15]);
hSpeedCA = uicontrol(...
    'parent',hScanWindowCoarseAlign,...
    'Style','edit',...
    'Position', [90,10,45,15],...
    'String',num2str(instr.opticalStage.CAParams.Velocity),...
    'Callback', {@updateDataPoint_callback});

hTextPwrRangeCA = uicontrol(...
    'parent', hLaserCoarseAlign,...
    'Style','text',...
    'String', 'Range [dBm]',...
    'HorizontalAlignment','right',...
    'Position',[10,30,75,15]);
hPwrRangeCA = uicontrol(...
    'parent',hLaserCoarseAlign,...
    'Style','edit',...
    'Position', [90,30,45,15],...
    'String',num2str(instr.laser.CAParams.PwrRange));
hTextThresholdCA = uicontrol(...
    'parent', hLaserCoarseAlign,...
    'Style','text',...
    'String', 'Th [dBm]',...
    'HorizontalAlignment','right',...
    'Position',[140,30,75,15]);
hThresholdCA = uicontrol(...
    'parent',hLaserCoarseAlign,...
    'Style','edit',...
    'Position', [220,30,45,15],...
    'String',num2str(instr.laser.CAParams.Threshold));
hTextAveragingTimeCA = uicontrol(...
    'parent', hLaserCoarseAlign,...
    'Style','text',...
    'String', 'Avg T [ms]',...
    'HorizontalAlignment','right',...
    'Position',[10,10,75,15]);
hAveragingTimeCA = uicontrol(...
    'parent',hLaserCoarseAlign,...
    'Style','edit',...
    'Position', [90,10,45,15],...
    'String',num2str(instr.laser.CAParams.AvgTime),...
    'Callback', {@updateDataPoint_callback});
hTextnoSamplesCA = uicontrol(...
    'parent', hLaserCoarseAlign,...
    'Style','text',...
    'String', '# of points',...
    'HorizontalAlignment','right',...
    'Position',[140,10,75,15]);
hnoSamplesCA = uicontrol(...
    'parent',hLaserCoarseAlign,...
    'Enable','on',...
    'Style','edit',...
    'Position', [220,10,45,15],...
    'String','');

%Fine align panel
hTextDeltaXScanFA = uicontrol(...
    'parent', hScanWindowFineAlign,...
    'Style','text',...
    'String','delta X [um]',...
    'HorizontalAlignment','right',...
    'Position',[140,30,75,15]);
hDeltaXScanFA = uicontrol(...
    'parent',hScanWindowFineAlign,...
    'Style','edit',...
    'Position', [220,30,45,15],...
    'String',num2str(instr.opticalStage.FAParams.DeltaXScan));
hTextDeltaYScanFA = uicontrol(...
    'parent',hScanWindowFineAlign,...
    'Style','text',...
    'String','delta Y [um]',...
    'HorizontalAlignment','right',...
    'Position',[140,10,75,15]);
hDeltaYScanFA = uicontrol(...
    'parent',hScanWindowFineAlign,...
    'Style','edit',...
    'Position', [220,10,45,15],...
    'String',num2str(instr.opticalStage.FAParams.DeltaYScan));
hTextdXScanScanFA = uicontrol(...
    'parent', hScanWindowFineAlign,...
    'Style','text',...
    'String','dx [um]',...
    'HorizontalAlignment','right',...
    'Position',[10, 30,75, 15]);
hdXScanScanFA = uicontrol(...
    'parent',hScanWindowFineAlign,...
    'Style','edit',...
    'Position', [90,30,45,15],...
    'String',num2str(instr.opticalStage.FAParams.dXScan));
hTextdYScanScanFA = uicontrol(...
    'parent', hScanWindowFineAlign,...
    'Style','text',...
    'String','dy [um]',...
    'HorizontalAlignment','right',...
    'Position',[10,10,75,15]);
hdYScanScanFA = uicontrol(...
    'parent',hScanWindowFineAlign,...
    'Style','edit',...
    'Position', [90,10,45,15],...
    'String',num2str(instr.opticalStage.FAParams.dYScan));
hTextPwrRangeFA = uicontrol(...
    'parent', hLaserFineAlign,...
    'Style','text',...
    'String', 'Range [dBm]',...
    'HorizontalAlignment','right',...
     'Position',[10,30,75,15]);
hPwrRangeFA = uicontrol(...
    'parent',hLaserFineAlign,...
    'Style','edit',...
    'Position', [90,30,45,15],...
    'String',num2str(instr.laser.FAParams.PwrRange));
hTextThresholdFA = uicontrol(...
    'parent', hLaserFineAlign,...
    'Style','text',...
    'String', 'Th [dBm]',...
    'HorizontalAlignment','right',...
    'Position',[140,30,75,15]);
hThresholdFA = uicontrol(...
    'parent',hLaserFineAlign,...
    'Style','edit',...
    'Position', [220,30,45,15],...
    'String',num2str(instr.laser.FAParams.Threshold));
hTextAveragingTimeFA = uicontrol(...
    'parent', hLaserFineAlign,...
    'Style','text',...
    'String', 'Avg T [ms]',...
    'HorizontalAlignment','right',...
    'Position',[10,10,75,15]);
hAveragingTimeFA = uicontrol(...
    'parent',hLaserFineAlign,...
    'Style','edit',...
    'Position', [90,10,45,15],...
    'String',num2str(instr.laser.FAParams.AvgTime));
hTextnoSamplesFA = uicontrol(...
    'parent', hLaserFineAlign,...
    'Style','text',...
    'String', '# of Samples',...
    'HorizontalAlignment','right',...
    'Position',[140,10,75,15]);
hnoSamplesFA = uicontrol(...
    'parent',hLaserFineAlign,...
    'Style','edit',...
    'Position', [220,10,45,15],...
    'String','');


hTextSpeedStage = uicontrol(...
    'parent', hStageSettingsParam,...
    'Style','text',...
    'String', 'v [mm/s]',...
    'HorizontalAlignment','right',...
    'Position',[10,10,75,15]);
hSpeedStage = uicontrol(...
    'parent',hStageSettingsParam,...
    'Style','edit',...
    'Position', [90,10,45,15],...
    'String',num2str(instr.opticalStage.CAParams.Velocity));
hTextAccelStage = uicontrol(...
    'parent', hStageSettingsParam,...
    'Style','text',...
    'String', 'a [mm/s2]',...
    'HorizontalAlignment','right',...
    'Position',[140,10,75,15]);
hAccelStage = uicontrol(...
    'parent',hStageSettingsParam,...
    'Style','edit',...
    'Position', [220,10,45,15],...
    'String',num2str(instr.opticalStage.CAParams.Accel));


%Exit button
hExit = uicontrol(...
    'parent',hScanArea,...
    'Style','pushbutton',...
    'Units', 'normalized', 'Position', [.7, .01, .25, .05],...
    'String','done',...
    'Callback',{@Exit_Callback});
%Save button
hSave = uicontrol(...
    'parent',hScanArea,...
    'Style','pushbutton',...
    'Units', 'normalized', 'Position', [.375, .01, .25, .05],...
    'String','save',...
    'Callback',{@Save_Callback});
%Load button
hLoad = uicontrol(...
    'parent',hScanArea,...
    'Style','pushbutton',...
    'Units', 'normalized', 'Position', [.05, .01, .25, .05],...
    'String','load',...
    'Callback',{@Load_Callback});


movegui(fstageSettings, 'center')

%% Callback definitions
    function updateDataPoint_callback(hObject,eventdata)
        
        line=str2double(get(hDeltaXScanCA,'String'))/1000;
        speed=str2double(get(hSpeedCA,'String'));
        AveragingTime=str2double(get(hAveragingTimeCA,'String'))/1000;
        
        set(hnoSamplesCA,'String',num2str(ceil(line/speed/AveragingTime)));
    end


function Save_Callback(hObject,eventdata)
% saves parameters to file .mat
DeltaXScanCA=str2double(get(hDeltaXScanCA,'String'));
DeltaYScanCA=str2double(get(hDeltaYScanCA,'String'));
XOffsetScanCA=str2double(get(hXOffsetScanCA,'String'));
YOffsetScanCA=str2double(get(hYOffsetScanCA,'String'));
dYScanCA=str2double(get(hdYScanCA,'String'));
SpeedCA=str2double(get(hSpeedCA,'String'));
PwrRangeCA=str2double(get(hPwrRangeCA,'String'));
ThresholdCA=str2double(get(hThresholdCA,'String'));
AveragingTimeCA=str2double(get(hAveragingTimeCA,'String'));

DeltaXScanFA=str2double(get(hDeltaXScanFA,'String'));
DeltaYScanFA=str2double(get(hDeltaYScanFA,'String'));
dXScanScanFA=str2double(get(hdXScanScanFA,'String'));
dYScanScanFA=str2double(get(hdYScanScanFA,'String'));
PwrRangeFA =str2double(get(hPwrRangeFA ,'String'));
ThresholdFA=str2double(get(hThresholdFA,'String'));
AveragingTimeFA=str2double(get(hAveragingTimeFA,'String'));

SpeedStage=str2double(get(hSpeedStage,'String'));
AccelStage=str2double(get(hAccelStage,'String'));
% 
% uisave({...
% 'DeltaXScanCA',...
% 'DeltaYScanCA',...
% 'XOffsetScanCA',...
% 'YOffsetScanCA',...
% 'dYScanCA',...
% 'SpeedCA',...
% 'PwrRangeCA',...
% 'ThresholdCA',...
% 'AveragingTimeCA',...
% 'noSamplesCA',...
% 'DeltaXScanFA',...
% 'DeltaYScanFA',...
% 'dXScanScanFA',...
% 'dYScanScanFA',...
% 'PwrRangeFA',...
% 'ThresholdFA',...
% 'AveragingTimeFA',...
% 'noSamplesFA',...
% 'SpeedStage',...
% 'AccelStage'},'../stageCorvus/my_parameters');
%        % saveParam();
%         %debugStr('stage parameters saved');
%         disp 'parameter file saved';
end
function Load_Callback(hObject,eventdata)
% %Loads paramters from file .mat
% [filename, pathname]=uigetfile('../stageCorvus/*.mat','Open parameter file');
% if isequal(filename,0)
%    disp('User selected Cancel')
% else
%    disp(['User selected ', fullfile(pathname, filename)])
%     load(filename,...
% 'DeltaXScanCA',...
% 'DeltaYScanCA',...
% 'XOffsetScanCA',...
% 'YOffsetScanCA',...
% 'dYScanCA',...
% 'SpeedCA',...
% 'PwrRangeCA',...
% 'ThresholdCA',...
% 'AveragingTimeCA',...
% 'noSamplesCA',...
% 'DeltaXScanFA',...
% 'DeltaYScanFA',...
% 'dXScanScanFA',...
% 'dYScanScanFA',...
% 'PwrRangeFA',...
% 'ThresholdFA',...
% 'AveragingTimeFA',...
% 'noSamplesFA',...
% 'SpeedStage',...
% 'AccelStage');
% end
% %load ../stageThorlabs/default.mat
% set(hDeltaXScanCA,'String',num2str(DeltaXScanCA));
% set(hDeltaYScanCA,'String',num2str(DeltaYScanCA));
% set(hXOffsetScanCA,'String',num2str(XOffsetScanCA));
% set(hYOffsetScanCA,'String',num2str(YOffsetScanCA));
% set(hdYScanCA,'String',num2str(dYScanCA));
% set(hSpeedCA,'String',num2str(SpeedCA));
% set(hPwrRangeCA,'String',num2str(PwrRangeCA));
% set(hThresholdCA,'String',num2str(ThresholdCA));
% set(hAveragingTimeCA,'String',num2str(AveragingTimeCA));
% set(hnoSamplesCA,'String',num2str(noSamplesCA));
% 
% set(hDeltaXScanFA,'String',num2str(DeltaXScanFA));
% set(hDeltaYScanFA,'String',num2str(DeltaYScanFA));
% set(hdXScanScanFA,'String',num2str(dXScanScanFA));
% set(hdYScanScanFA,'String',num2str(dYScanScanFA));
% set(hPwrRangeFA,'String',num2str(PwrRangeFA));
% set(hThresholdFA,'String',num2str(ThresholdFA));
% set(hAveragingTimeFA,'String',num2str(AveragingTimeFA));
% set(hnoSamplesFA,'String',num2str(noSamplesFA));
% 
% set(hSpeedStage,'String',num2str(SpeedStage));
% set(hAccelStage,'String',num2str(AccelStage));
% 
% disp 'parameter file loaded';
%         %loadParam();
end
function Exit_Callback(hObject,eventdata)
        %closees figure and goes back to mainGUI;
        %save the bounds values in global variable
    
instr.opticalStage.CAParams.DeltaXScan=str2double(get(hDeltaXScanCA,'String'));
instr.opticalStage.CAParams.DeltaYScan=str2double(get(hDeltaYScanCA,'String'));
instr.opticalStage.CAParams.XOffsetScan=str2double(get(hXOffsetScanCA,'String'));
instr.opticalStage.CAParams.YOffsetScan=str2double(get(hYOffsetScanCA,'String'));
instr.opticalStage.CAParams.dYScan=str2double(get(hdYScanCA,'String'));
instr.opticalStage.CAParams.Velocity=str2double(get(hSpeedCA,'String'));
instr.laser.CAParams.PwrRange=str2double(get(hPwrRangeCA,'String'));
instr.laser.CAParams.Threshold=str2double(get(hThresholdCA,'String'));
instr.laser.CAParams.AvgTime=str2double(get(hAveragingTimeCA,'String'));

instr.opticalStage.FAParams.DeltaXScan=str2double(get(hDeltaXScanFA,'String'));
instr.opticalStage.FAParams.DeltaYScan=str2double(get(hDeltaYScanFA,'String'));
instr.opticalStage.FAParams.dXScanScan=str2double(get(hdXScanScanFA,'String'));
instr.opticalStage.FAParams.dYScanScan=str2double(get(hdYScanScanFA,'String'));
instr.laser.FAParams.PwrRange =str2double(get(hPwrRangeFA ,'String'));
instr.laser.FAParams.Threshold=str2double(get(hThresholdFA,'String'));
instr.laser.FAParams.AvgTime=str2double(get(hAveragingTimeFA,'String'));

instr.opticalStage.CAParams.Velocity=str2double(get(hSpeedStage,'String'));
instr.opticalStage.CAParams.Accel=str2double(get(hAccelStage,'String'));

% set(gui.next_button, 'UserData', user);
set(gui.back_button, 'UserData', instr);
        
disp 'paramters saved before exit';

        close(fstageSettings);
end
function close_stageSetting(hObject,eventdata)
        %display warning if coordiante system not properly set up; e.g.
        %when closing window instead of exit button
         
        delete(gcbf)
end



end

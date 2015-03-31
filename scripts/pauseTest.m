% Vince Wu
function pauseTime = pauseTest(obj)
pauseStart = tic;
%% stop the pump
if obj.instr.pump.Connected
    obj.instr.pump.stop();
    obj.instr.pump.stop();
    obj.msg('Stopping pump');
end

obj.msg('<<<<<<<<<<  Test Pause.  >>>>>>>>>>');

testPanel = panel_index('test');
test = obj.AppSettings.infoParams.Task;
% message = sprintf('Test: %s paused.\nClick OK to continue', test);
% uiwait(msgbox(message, 'Pause Test', 'modal'));

message = sprintf('Test: %s paused.\nChange recipe content or \nClick Resume to continue %s', test, test);
response = questdlg(message, 'Pause Test', ...
    'Resume', 'Change Recipe', 'Resume');

if strcmp(response, 'Change Recipe')
    changeRecipePopup(obj);
end

set(obj.gui.panel(testPanel).testControlUI.pauseButton, 'UserData', false); % reset pause flag
set(obj.gui.panel(testPanel).testControlUI.pauseButton, 'Enable', 'on');
set(obj.gui.panel(testPanel).testControlUI.startButton, 'Enable', 'off');

obj.msg('<<<<<<<<<<  Test Resume.  >>>>>>>>>>');
%% start pump
if obj.instr.pump.Connected
    obj.instr.pump.start();
    obj.instr.pump.start();
    obj.msg('Re-starting pump');
end

pauseTime = toc(pauseStart);
end
function get_gc(obj,hmap)
%gets mouse coordinates and moves to GC location

opticalStage = obj.instr.opticalStage;
os = obj.instr.opticalStage.getProp('Overshoot');
axes(hmap); %make active

dataObjs = get(hmap, 'Children'); %handles to low-level graphics 
xdata = get(dataObjs, 'XData'); %data from low-level grahics objects
ydata = get(dataObjs, 'YData');
zdata = get(dataObjs, 'ZData');


%get the offset from the graph
[x, y, button]=ginput(1); %get mouse courser input

msg = strcat('get_gc: mouse x:', num2str(x));
obj.msg(msg);
msg = strcat('get_gc: mouse y:', num2str(y));
obj.msg(msg);
% disp(x);
% disp(y);

if button == 1 % left
    %move in y-direction
    %below if heat map is not rotated
    %opticalStage.move_y(x-xdata(ceil(length(xdata)/2))-20); %not sure where the 20um offset is coming from
    opticalStage.move_y(y-ydata(ceil(length(ydata)/2))-20); %not sure where the 20um offset is coming from
   
    %move in x-direction
    %opticalStage.move_x(ydata(ceil(length(ydata)/2))-(y)+10); %not sure where the 10um offset is coming from
    opticalStage.move_x(xdata(ceil(length(xdata)/2))-x+10); %not sure where the 10um offset is coming from


    %replotting the heat map: for later so, you can use snap GC again.
    % cla(hmap,'reset');
    % axes(hmap)
    % set(hmap,'DataAspectRatio',[1 1 1]);
    % 
    % surface(xdata-(x-xdata(ceil(length(xdata)/2))), ydata-(ydata(ceil(length(ydata)/2))-(y)), zdata);
    % xlabel('y [um]');
    % ylabel('x [um]');
    % shading interp;
end
end
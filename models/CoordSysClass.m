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

classdef CoordSysClass < handle
    %This class is inherited by the optical stage class. It's methods allow
    %mapping of gds coordinates to motor positions. Non linear
    %least square fitting is used to compute a transformation matrix (with three points or more). 
    %   Detailed explanation goes here
    
    properties (Access = private)
        Name; % Name of object for debug messages
        ValidCoordinateSystem; % 0=no, 1=yes
        CoordSysError; % error in um's
        
        % data for coordinate system
        GDSCoordPairs; % struct of the gds coord pairs in the coord system
        MotorPosPairs; % struct of the motor's x,y position pairs in the coord system
        CoordNum; % number of coordinate pairs to create coordinate system
        DeviceNames ;  %index of device used for coorindate system (number out of the pull down list)
        
        %Transformation matrix
        rot_angle;
        scaling;
        offset;
        lambda; 
        
        debug; 
        Param; % parameters for settings window
    end
    
    methods
        %% constructor
        % configures object, assigns default values
        function self = CoordSysClass(varargin)
            self.Name = 'Coordinate System';
            self.CoordNum = 0;
            self.ValidCoordinateSystem = 0;  %coordiante system is not valid
            self.CoordSysError = 0 ; 
            self.Param.MinNumOfCoordPairs = 3;  %needs to be a Param for settings window
            self.Param.MinAcceptableError = 3; %min acceptable error for norm residuals
            
           self.CoordNum = 0;
           self.GDSCoordPairs.coord = [];
           self.GDSCoordPairs.index = [];
           self.MotorPosPairs.coord = [];
           self.MotorPosPairs.index = []; 
           self.DeviceNames.name = {};
           self.DeviceNames.index = [];
            
            self.rot_angle = 0;
            self.scaling = 0;
            self.offset = 0;
            self.lambda = 0; %shearing
            
            self.debug = 0; 
        end
                
        %% coordSysIsValid
        function val = coordSysIsValid(self)
            val = self.ValidCoordinateSystem; % 0=no, 1=yes
        end
        
        %% coordSysError
        function val = coordSysError(self)
            val = self.CoordSysError; % um
        end
        
        %% get coord pairs (i.e. to populate table)
        function [NumOfPoints,GDS,Motor, DeviceNames] = getCoordPairs(self)
            NumOfPoints = self.CoordNum;
            GDS = self.GDSCoordPairs;
            Motor = self.MotorPosPairs; 
            DeviceNames = self.DeviceNames; 
        end
        
        
        %% clearCoordSys
        function self = clearCoordSys(self)
            self.ValidCoordinateSystem = 0; % 0=no, 1=yes
            self.CoordNum = 0; % number of coordinate pairs to create coordinate system
            clear self.GDSCoordPairs; % struct of the gds coord pairs in the coord system
            clear self.MotorPosPairs; % struct of the motor's x,y position pairs in the coord system
        end
  
        function self = addCoordPair(self, GDSCoordPair, MotorCoordPair, DeviceName, index)
            
            disp('find existing index');
            find(self.GDSCoordPairs.index==index)
            
            if find(self.GDSCoordPairs.index==index);
                %the pair has already been set previously
                %DEBUG: add some message here.
                return
            end
            
            self.CoordNum = self.CoordNum + 1;
            self.GDSCoordPairs.coord(self.CoordNum,1:2) = GDSCoordPair;
            self.GDSCoordPairs.index(self.CoordNum) = index;  %location in the table: not necessarily in order
            self.MotorPosPairs.coord(self.CoordNum,1:2) = MotorCoordPair ;
            self.MotorPosPairs.index(self.CoordNum) = index; %location in the table: not necessarily in order
            self.DeviceNames.name{self.CoordNum} = DeviceName;
            self.DeviceNames.index(self.CoordNum) = index;
            
            if self.CoordNum >= self.Param.MinNumOfCoordPairs % try for a coordinate system
                self.computeTransferMatrix();
                disp('compute Transformation matrix');
            end
            disp(strcat('number of coord pairs (after adding): ', num2str(self.CoordNum)));
            if self.debug==1
                self.MotorPosPairs.coord
                self.MotorPosPairs.index
                self.GDSCoordPairs.coord
                self.GDSCoordPairs.index
                self.DeviceNames.name
                self.DeviceNames.index
            end
        end
        
        function self = removeCoordPair(self,index)  %index location in the table: not necessarily in order
            
%             ind = find(self.GDSCoordPairs.index==index);
%             self.GDSCoordPairs.coord(ind)=[NaN, NaN];
%             self.MotorCoordPairs.coord(ind)=[NaN, NaN];
%             self.MotorPosPairs.index(ind) = NaN;
%             self.GDSCoordPairs.index(ind) = NaN;
            %delete the NaN row. 
            %ind = find(~isnan(self.GDSCoordPairs.index));
            ind = find(self.GDSCoordPairs.index~=index);
            self.GDSCoordPairs.coord=self.GDSCoordPairs.coord(ind);
            self.GDSCoordPairs.index=self.GDSCoordPairs.index(ind);
            self.MotorPosPairs.coord=self.MotorPosPairs.coord(ind);
            self.MotorPosPairs.index=self.MotorPosPairs.index(ind);
            self.DeviceNames.name=self.DeviceNames.name(ind);
            self.DeviceNames.index=self.DeviceNames.index(ind);
            
            self.CoordNum = self.CoordNum - 1;
            disp(strcat('number of coord pairs (after removing): ', num2str(self.CoordNum)));
            if self.debug == 1
                self.MotorPosPairs.coord
                self.MotorPosPairs.index
                self.GDSCoordPairs.coord
                self.GDSCoordPairs.index
                self.DeviceNames.name
                self.DeviceNames.index
            end
            if self.CoordNum >= self.Param.MinNumOfCoordPairs % try for a coordinate system
                self.computeTransferMatrix();
                disp('compute Transformation matrix');

            end
        end
        
        function self = removeAllCoordPair(self)
           self.CoordNum = 0;
           self.GDSCoordPairs.coord = [];
           self.GDSCoordPairs.index = [];
           self.MotorPosPairs.coord = [];
           self.MotorPosPairs.index = []; 
           
           self.ValidCoordinateSystem = 0;
           self.CoordSysError = NaN; 
           
            
        end
        
        function self = computeTransferMatrix(self)
            %optimized the privat function opt_fun
            %init paratmers;
            %param0 = [sx sy theta d1 d2];
            
            self.ValidCoordinateSystem =0;
            
            disp('vectors for angle calculation');
            %Try to predict angle 
            %DEBUG: mirroring is not taking into account (only for
            %prediction)
            a=self.GDSCoordPairs.coord(2,:)-self.GDSCoordPairs.coord(1,:);
            b=self.MotorPosPairs.coord(2,:)-self.MotorPosPairs.coord(1,:);
            e=[-1,0];
            angle1 = sign(a(2))*acos(dot(a,e)/norm(a)/norm(e));
            angle2 = sign(b(2))*acos(dot(b,e)/norm(b)/norm(e));
            angle = angle1 - angle2;
            %define input params : educated guess
            param0 = [1,1, angle,self.MotorPosPairs.coord(1,1)/1000,self.MotorPosPairs.coord(1,2)/1000,0,0]; %/1000: to on the same order of magnitude 
            options = optimset('Diagnostics', 'on', 'MaxFunEvals', 10000,...
                'TolFun',1e-8,'PlotFcns',@optimplotresnorm);
            %Diagnostics shoudl be 'off', 'on' for debug
            lb = [-2000, -2000, -10, -10000, -10000,-0.1, -0.1];
            ub = [2000, 2000, 10, 10000,10000,0.1,0.1];
            [param,resnorm, residual]  = lsqnonlin(@self.opt_fun, param0, [],[],options);
            
            disp('transformation matrix:');
            disp(strcat('angle: ',num2str(param(3))));
            disp(strcat('offset: ',num2str(param(4)),',',num2str(param(5))));
            disp(strcat('scaling: ',num2str(param(1)),',',num2str(param(2))));
            disp(strcat('shearing: ',num2str(param(6)),',',num2str(param(7))));
            
            self.rot_angle=param(3);
            self.offset = param(4:5)*1000; %convert back to microns
            self.scaling = param(1:2); %since in software everthing is in [um] shoudl be 1 or -1
            self.lambda = param(6:7); %if no shearing they should be 0; 
            self.CoordSysError = resnorm;

            
            if self.CoordSysError <= self.Param.MinAcceptableError
                disp('ValidCoordinateSystem set to 1');
                self.ValidCoordinateSystem = 1;
            end
            
        end
        
        function [motor_pos] = transform(self,GDS_coords)
            if self.ValidCoordinateSystem
                T1 = [self.scaling(1)*cos(self.rot_angle), -self.scaling(2)*sin(self.rot_angle);
                    self.scaling(1)*sin(self.rot_angle), self.scaling(2)*cos(self.rot_angle)];
                T2 = [1, self.lambda(1);...
                    self.lambda(2), 1];
                D = [self.offset(1);self.offset(2)];  %offset
                
                motor_pos = T2*T1*GDS_coords + D;
            else
                warning('CoordSys: no coordinate system set up');
            end
            
        end
        

    end
    
    methods (Access = private)
        function F = opt_fun(self,param0)
            F=[];
            %disp(strcat('self.CoordNum: ',num2str(self.CoordNum)));
            sx=param0(1);
            sy=param0(2);
            %s=param0(1);
            disp(strcat('scaling factor x: ',num2str(sx)));
            disp(strcat('scaling factor y: ',num2str(sy)));
            %sx=sy;
            theta=param0(3);
            disp(strcat('angle: ',num2str(theta)));
            d1 = param0(4);
            d2 = param0(5);
            disp(strcat('offset 1: ',num2str(d1)));
            disp(strcat('offset 2: ',num2str(d2)));
            l1 = param0(6);
            l2 = param0(7);
            
            %Transform matrix 
            T1 = [sx*cos(theta), -sy*sin(theta);
                sx*sin(theta), sy*cos(theta)];
            T2 = [1, l1; l2, 1];
            D = [d1;d2];  %offset
            for (ii=1:1:self.CoordNum)
                F(end+1:end+2)=T2*T1*self.GDSCoordPairs.coord(ii,:)'/1000 + D - self.MotorPosPairs.coord(ii,:)'/1000;
            end
            %division by 1000 is for numerical reasons, paramters should be
            %same order of magnitud
            
            %A=[sx*cos(theta), -sx*sin(theta), -1 0; sy*sin(theta), sy*cos(theta), 0, -1];
            %d=[d1; d2];
            
        end
    end
    
  
end


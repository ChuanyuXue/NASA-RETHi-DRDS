function fval=SVR_hv(x)
%% Documentation
% Purpose: Find saturated vapor enthalpy of refrigerant R11 at a given pressure
%           It uses pre-generated regression fit. 
% Date Created: 20 June 2020
% Date Last Modified: 29 Aug 2021
% Modeler Name: Jaewon Park, CJ Pan (Purdue)
% Funding Acknowledgement: Funded by the NASA RETHi Project (80NSSC19K1076)

% Version Number: MCVT v1.4

% Subsystem Connections: No connection.

%%% All inputs and outputs to this function are 1 dimensional %%%
% INPUTS %
%   - x: pressure, unit: bar, type: float
    
% OUTPUTS %
%   - fval: saturated vapor enthalpy, unit: kJ/kg, type: float

% Function Dependencies: This function is called by following .m file 
% Sys5_eclss.m
% This function calls following subfunction
% RBF_kernel_hv

% No Data Depenencies
%% Data for fitting
% data obtained from https://webbook.nist.gov/chemistry/ for R11
b0=406.9401;                                                               % bias term for regression
U=[-59.1664605345725,61.4151673505694,-2.53510006123709,-32.9322991064999,...
    16.2102446110439,19.5899976420660,-12.4070227816820,-1.51307142839688,...
    16.3243852709874,2.99393163217645,-2.71617153558540,9.06708822927507,...
    8.84669966245002,1.72920458458301,5.22701755294666,9.25366734395202,...
    5.83457844749294,4.68902650780326,8.09478534590068,8.30367416658945,...
    5.74354750793866,6.78334127079808,9.54607126681098,7.78266160908100,...
    5.44060608326463,9.26535411507298,11.1096856953855,5.03082646230245,...
    6.04140412356553,14.9408311287604,8.62169086293023,-0.792482896447570,...
    14.7024879605220,20.2714326941287,-6.32495765229310,0.528524651688997,...
    38.5685954117440,6.92589111469550,-42.1957757781872,67.8755931472813]; % stored training output of regression model
XX=[0.500000000000000;1;1.50000000000000;2;2.50000000000000;3;...
    3.50000000000000;4;4.50000000000000;5;5.50000000000000;6;...
    6.50000000000000;7;7.50000000000000;8;8.50000000000000;9;...
    9.50000000000000;10;10.5000000000000;11;11.5000000000000;...
    12;12.5000000000000;13;13.5000000000000;14;14.5000000000000;...
    15;15.5000000000000;16;16.5000000000000;17;17.5000000000000;...
    18;18.5000000000000;19;19.5000000000000;20];                           % stored training input of regression model 

%% Calculate Saturated vapor enthalpy
K=RBF_kernel_hv(x,XX');                 % get kernal value based on radial basis function
fval=K*U'+b0;                           % evaluate the enthalpy 
end

function K=RBF_kernel_hv(A,B)
%% Documentation
% Purpose: Calculate Gaussian Kernel based on Radial Basis Function (RBF) 
% Date Created: 20 June 2020
% Date Last Modified: 29 Aug 2021
% Modeler Name: Jaewon Park, CJ Pan (Purdue)

% Version Number: MCVT v1.4

% Subsystem Connections: No connection.

% INPUTS %
%   - A: query point, unit: unitless, type: float, 1-D
%   - B: training data input, unit: unitless, type: float, 2-D vector (length of the vector does not matter)  

% OUTPUTS %
%   - K: Kernal value, unit: C, type: float, 2-D vector of same size as the
%   input B

% Function Dependencies: This function is called by SVR_hv

    delta=1.0;                                % length scale for kernel smoother. This is manually set so that the regression works well.                          
    r=abs(A'-B);                              % following the formula for Gaussian Kernel Smoother
    K=exp(-r.^2./(2*delta^2));
end


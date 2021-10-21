function fval=SVR_rou_v(x)
%% Documentation
% Purpose: Find saturated vapor density of refrigerant R11 at a given pressure
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
%   - fval: saturated vapor density, unit: kg/m^3, type: float

% Function Dependencies: This function is called by following .m file 
% Sys5_eclss.m
% This function calls following subfunction
% RBF_kernel_rou_v

% No Data Depenencies
%% Data for fitting
% data obtained from https://webbook.nist.gov/chemistry/ for R11 
 b0=61.0019;                                                                % bias term for regression
 U=[-110.010405464022,-60.0176416768082,-19.1832735051432,11.8107665788528,...
     32.8589180260900,44.4181700524238,47.4557695927075,43.3628006137010,...
     33.8406248120022,20.7691748472074,6.06728782801554,-8.44441016549827,...
     -21.1680879484563,-30.8320650845715,-36.5661221193007,-37.9442260006044,...
     -34.9926043328899,-28.1635764959692,-18.2778614843816,-6.44010491596116,...
     6.06598728539356,17.8953087541584,27.7634578231486,34.5646708654101,...
     37.4771850454806,36.0483378885541,30.2528961883220,20.5197442646310,...
     7.72409753278001,-6.85524855284618,-21.6116035127525,-34.7144442780600,...
     -44.2349683859507,-48.2843299256177,-45.1544390053976,-33.4506676732067,...
     -12.2061410299929,19.0314800943630,60.1477726661629,110.448228174211]; % stored training output of regression model
 XX=[0.500000000000000;1;1.50000000000000;2;2.50000000000000;3;...
     3.50000000000000;4;4.50000000000000;5;5.50000000000000;6;...
     6.50000000000000;7;7.50000000000000;8;8.50000000000000;9;...
     9.50000000000000;10;10.5000000000000;11;11.5000000000000;...
     12;12.5000000000000;13;13.5000000000000;14;14.5000000000000;...
     15;15.5000000000000;16;16.5000000000000;17;17.5000000000000;...
     18;18.5000000000000;19;19.5000000000000;20];                           % stored training input of regression model 

%% Calculate saturated vapor density 
K=RBF_kernel_rou_v(x,XX');                  % get kernal value based on radial basis function
fval=K*U'+b0;                               % evaluate the density 
end

function K=RBF_kernel_rou_v(A,B)
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

% Function Dependencies: This function is called by SVR_rou_v

    delta=5.5;                               % length scale for kernel smoother. This is manually set so that the regression works well.                          
    r=abs(A'-B);                             % following the formula for Gaussian Kernel Smoother
    K=exp(-r.^2./(2*delta^2));
end




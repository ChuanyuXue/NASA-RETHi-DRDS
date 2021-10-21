function fval=SVR_hl(x)
%% Documentation
% Purpose: Find saturated liquid enthalpy of refrigerant R11 at a given pressure
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
%   - fval: saturated enthalpy, unit: kJ/kg, type: float

% Function Dependencies: This function is called by following .m file 
% Sys5_eclss.m
% This function calls following subfunction
% RBF_kernel_hl

% No Data Depenencies
%% Data for fitting
% data obtained from https://webbook.nist.gov/chemistry/ for R11
b0=216.9047;                                                               % bias term for regression
U=[-147.011537341731,91.2095458143568,100.377528506695,-2.94070733693279,...
    -68.6277243647794,-38.8388153707651,30.4433500569375,56.7488272175872,...
    22.5221002860706,-21.5822292836131,-25.6571946012934,6.58380204955175,...
    33.5378280620784,28.0436179185491,2.76321423232039,-11.6086109396015,...
    -1.64829070742468,18.8165138435085,27.6234884761579,17.2211936938004,...
    -0.0624548045987238,-5.53598624617724,7.47250615630266,26.2610290879764,...
    30.0497524253377,12.0539468970891,-9.38927946635403,-7.34194561515610,...
    21.5572599976047,46.2097526452955,32.7175601179956,-10.8811238732925,...
    -33.3975721468835,2.74982129193261,66.4364881063497,78.2028454331051,...
    1.12984625475030,-91.6666759199630,-56.6473719284788,198.123547154558]; % stored training output of regression model
XX=[0.500000000000000;1;1.50000000000000;2;2.50000000000000;3;...
    3.50000000000000;4;4.50000000000000;5;5.50000000000000;6;...
    6.50000000000000;7;7.50000000000000;8;8.50000000000000;9;...
    9.50000000000000;10;10.5000000000000;11;11.5000000000000;...
    12;12.5000000000000;13;13.5000000000000;14;14.5000000000000;...
    15;15.5000000000000;16;16.5000000000000;17;17.5000000000000;...
    18;18.5000000000000;19;19.5000000000000;20];                            % stored training input of regression model 

%% Calculate Saturated liquid enthalpy
K=RBF_kernel_hl(x,XX');                 % get kernal value based on radial basis function
fval=K*U'+b0;                           % evaluate the enthalpy 
end

function K=RBF_kernel_hl(A,B)
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

% Function Dependencies: This function is called by SVR_hl

    delta=1.6;                          % length scale for kernel smoother. This is manually set so that the regression works well.                          
    r=abs(A'-B);                        % following the formula for Gaussian Kernel Smoother
    K=exp(-r.^2./(2*delta^2));
end


function fval=SVR_Ts(x)
%% Documentation
% Purpose: Find saturation temperature of refrigerant R11 at a given pressure
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
%   - fval: saturation temperature, unit: C, type: float

% Function Dependencies: This function is called by following .m file 
% Sys5_eclss.m
% This function calls following subfunction
% RBF_kernel_Ts

% No Data Depenencies
%% Data for fitting
% data obtained from https://webbook.nist.gov/chemistry/ for R11
b0=-17.3377160329879;                                                           % bias term for regression
U=[-83.5588090591053,-39.5349163520128,-4.42322132162465,20.8906905874919,...
    36.2508282107436,42.2274996033668,40.0493785005812,31.4767348933012,...
    18.6279276615444,-10.8618137275603,-32.0863399797709,-35.1275504499911,...
    8.17487216632950,54.7910052220241,18.6122759267098,-12.1113853250976,...
    18.4708737161559,40.3331418121612,15.1464147112551,0.184594095092861,...
    27.8909348607504,42.6467518540924,9.35285437588132,-3.97396383716234,...
    45.5910118193790,60.6056251010551,-16.8612070725385,-35.1411517759882,...
    140.725541833844];                                                          % stored training output of regression model 
XX=[0.200000000000000;0.300000000000000;0.400000000000000;0.500000000000000;...
    0.600000000000000;0.700000000000000;0.800000000000000;0.900000000000000;...
    1;1.20000000000000;1.40000000000000;1.60000000000000;2;2.50000000000000;...
    3;3.50000000000000;4;4.50000000000000;5;5.50000000000000;6;6.50000000000000;...
    7;7.50000000000000;8;8.50000000000000;9;9.50000000000000;10];               % stored training input of regression model 

%% Calculate Saturation Temperature 
K=RBF_kernel_Ts(x,XX');                 % get kernal value based on radial basis function                  
fval=K*U'+b0;                           % evaluate the temperature 
end

function K=RBF_kernel_Ts(A,B)
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

% Function Dependencies: This function is called by SVR_Ts

    delta=1.0;                              % length scale for kernel smoother. This is manually set so that the regression works well.                          
    r=abs(A'-B);                            % following the formula for Gaussian Kernel Smoother
    K=exp(-r.^2./(2*delta^2));
end

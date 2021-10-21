%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                MCVT.v1.5 Simulation Settings File                          
%                        Date: 9/2/2021                                
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MCVT - version 1.5: Integrated Simulation
% MCVT Systems: Structural, Power, ECLSS, Agent, Interior Env., Exterior Env.
% NOTE: This portion of the file should NOT be modified.


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%               GENERAL EXECUTION SIMULATION PARAMETERS                   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tic
fs = 1000;                  % Integrated Sampling Frequency [Hz]
dt = 1/fs;                  % Integrated Sampling Rate [sec]
t = 0:dt:T_end;             % Simulation time vector [sec]

% Individual System Sampling Frequencies [Hz]
fs_2 = 1000;                % Structural System
fs_3 = 1000;                % Power System 
fs_5 = 200;                % ECLSS System
fs_6 = 1000;                % Agent System (Note: CANNOT be different to baseline dt.)
fs_8 = 20;                  % Interior Environment 
fs_9 = 1000;                % Exterior Environment 

% Individual System Sampling Rates [sec]
dt_2 = 1/fs_2;              % Structural System
dt_3 = 1/fs_3;              % Power System
dt_5 = 1/fs_5;              % ECLSS System
dt_6 = 1/fs_6;              % Agent System
dt_8 = 1/fs_8;              % Interior Environment
dt_9 = 1/fs_9;              % Exterior Environment
% Simulink Settings
elapsedTime(2) = toc;
disp(['-[3/6] Simulation Parameters Loaded (' num2str(elapsedTime(2)) ' sec)']);
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                             MCVT Subsystems                             
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Note: Here we are calling on the individual system simulation scripts.
tic
Sys2_structure_3D;          % Structural System
Sys3_power;                 % Power System
Sys5_eclss;                 % ECLSS System
Sys6_agent;                 % Agent System
Sys8_in_env;                % Interior Environment
Sys9_ex_env;                % Exterior Environment
Comms_Config;               % Socket Configurations for HMS
SimFDD;                     % Settings for the Simulated FDDs

elapsedTime(3) = toc;
disp(['-[4/6] Subsystems Parameters Loaded (' num2str(elapsedTime(3)) ' sec)']);


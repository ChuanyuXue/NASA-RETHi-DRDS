
%% Dust Model 
% Dust deposition by engine exhaust (landings/launches)*****************
% model parameters
Sys9_int_G = 1.63;                % Gravitational acceleration, unit: m/s^2
Sys9_int_V0L = 15.56;              % initial dust particle velocity, m/s
Sys9_int_CL = 6.3724/(launch_dust_accum_stop_time-launch_dust_accum_start_time);    % Dust intensity parameter for engine exhaust, unit: mg/cm^2-engine exhaust       
Sys9_int_BetaL = 1.8433;           % Parameter to control a dust particle's flying trajectory
% Sys9_int_D = dust_distance;                    % Distance away from a landing or launch site, unit:m
Sys9_int_L = [Sys9_int_G Sys9_int_V0L Sys9_int_CL Sys9_int_BetaL]; 

%% User Modifiable Parameter
% id 1: Nuclear Dist
Sys9_int_D = launch_site_dust_distance;      % Distance away from a landing or launch site, unit:m
nominalDustDep = norminal_dust_accum_rate;        % Nominal dust deposition rate at location unit: mg/cm^2-s
meteoroidDustDep = met_dust_accum_rate;        % meteoroid-induced dust deposition rate at location unit: mg/cm^2-s

% start_time_ex = 2; %Start of Exhaust Activity, unit of time
% end_time_ex = 8; % End of Exhaust Activity, unit of time
% 
% start_time_mt = 10; %Start of Exhaust Activity, unit of time
% end_time_mt = 15; % End of Exhaust Activity, unit of time

%% Solar Irradiation Model
Sys9_int_SPAngle = 180; %degree
%% EQ
Sys9_int_EqStart = 60; %initiation of the quake (sec)
Sys9_int_EqMag = 5;
%% Impact ; 
load Sys9_int_ImpactData   %time xloc yloc mass V_x V_y V_z
Sys9_int_ImpStart = 60; %Impact time
Sys9_int_Imp_indx = randi([1 29205]);
Sys9_int_MetDensity = 3.4; %unit = g/cm^3

% dust density is 0.7g/cm^3




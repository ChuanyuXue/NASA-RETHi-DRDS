%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MCVT - version 1.5: Integrated Simulation
% MCVT Systems: 
% Structural, Power, ECLSS, Interior Env., Exterior Env., Agent & HMS
% Collaborators: Purdue Univ., UConn, UTSA, Harvard Univ.

%%% NOTE: For model description and further details, refer to the User Manual.  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Requirements: 
% 1) MATLAB R2020a 
% 2)Compiler: 
%     In Command Window run: mex -setup
%     If no compiler found, install a compiler as follows:
%     On the MATLAB Home tab, in the Environment section, click Add-Ons > Get Add-Ons.
%     Search for MinGW
%     Install MinGW

clear all; close all; clc; warning off;
addpath(genpath(pwd)); % Add Folder to Search Path

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                             MCVT SCENARIOS                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Note: Here specify Input Parameters for MCVT scenarios.

% Total Simulation time
T_end  = 5;                                         % time in s;

% Meteoroite impact input
meteorite_impact_time = 1;                             % time in s;
meteorite_impact_location_xyz=[1.0631 2.4778 1.0679];% meteoroite impact location x,y,z coordinates, the available options are: 
                                                         %  No.1:  1.0631    2.4778    1.0679 
                                                         %  No.2:  2.4779    1.0628    1.0679
                                                         %  No.3:  1.0622    1.0619    2.4807
                                                         %  No.4: -1.0679    2.4778    1.0631
                                                         %  No.5: -1.0679    1.0628    2.4779
                                                         %  No.6: -2.4807    1.0619    1.0622
                                                         %  No.7: -1.0631    2.4778   -1.0679
                                                         %  No.8: -2.4779    1.0628   -1.0679
                                                         %  No.9: -1.0622    1.0619   -2.4807
                                                         %  No.10: 1.0679    2.4778   -1.0631
                                                         %  No.11: 1.0679    1.0628   -2.4779
                                                         %  No.12: 2.4808    1.0619   -1.0622 

% Dust accumulation input
launch_site_dust_distance = [100, 150, 200];         % distance between launch/landing site and the habitat system for solver PV, nuclear power, and ECLSS radiator panels in m;
norminal_dust_accum_rate = [0.1, 0.3, 0.2];            % norminal dust accumualtion rate without events in 
met_dust_accum_rate = [10, 30, 20];                    % typical dust accumualtion rate with meteoroite event
launch_dust_accum_start_time = 2;                    % dust accumulation due to lanch/landing events start time in s;
launch_dust_accum_stop_time = 3;                     % dust accumulation due to lanch/landing events stop time in s;
dust_met_duration = 2;                               % dust accumulation due to meteoroid impact duration time in s;

% Solar radiation start angle
Start_angle = 90;                                    % Provide the start angle of solar radiation. 

%%% STRUCTURAL SYSTEM INPUT PARAMETERS
damage_case_id = 1;                                 % Structural system damage case, can be selected between 1 and 4
                                                     % 1: (minor) damage in the protective layer
                                                     % 2: major damage in the protective layer
                                                     % 3: damage in protective layer & structure
                                                     % 4: damage in protective layer & structure.& with pressure leakage
                                                     
%%% POWER SYSTEM INPUT PARAMETERS
nuclear_power_toggle = 1;                           % Set to 1 to enable and 0 to disable nuclear power supply
solar_power_toggle = 1;                             % Set to 1 to enable and 0 to disable solar power supply
battery_power_toggle = 1;                           % Set to 1 to enable and 0 to disable battery energy
energy_store_o = 120;                               % Initial energy storage in batery [kWh] 
energy_store_max_o = 150;                           % Maximum amount of energy that can be stored [kWh]
energy_store_min_o = 0;                             % Minimum amount of energy that can be stored [kWh]
initial_power_level = 6.9e5;                        % Initial power level [W]
assumed_power_voltage = 1.25e2;                     % Assumed voltage for the power system [V]
SOC_upper_thres = 0.9;                              % SOC value above (>=) which the battery will stop charging
SOC_lower_thres = 0.5;                              % SOC value below (<) which the battery will significantly charge
gain_charge_param = 1;                              % Gain determining how much the battery is charged below SOC lower threshold
battery_trickle_leakage_param = 0.01;               % Trickle discharge of the battery [/h]
battery_trickle_charge_param = 0.1;                 % Trickle charge of the battery [/h]
I_max_charge = 800;                                 % Maximum amount of current that can be sent to the battery [A]
I_max_discharge = 800;                              % Maximum amount of current that can be drawn from the battery [A]
solar_PV_capacity = 20;                             % Solar PV array power generation capacity [kW]
solar_Tmodule_ini = 350*ones(1,5);                  % Initial PV module temperature [K]
solar_P_ini = 0;                                    % Initial single PV module power generation [kW]
solar_DRatio_ini = 0;                               % Initial dust cover ratio [-] [0-1]
solar_module_num = nan;                             % Number of PV panels [-]
solar_FDD_Ts = 2;                                   % Simulated solar PV FDD settling time
solar_FDD_zeta = 0.707;                             % Simulated solar PV FDD damping ratio
solar_FDD_noise = 1e-2;                             % Simulated solar PV FDD additive noise

%%% INTERIOR ENVIRONMENT INPUT PARAMETERS
initial_temperature = 295;                          % Initial temperature in the interior environment [K]
initial_pressure = 1e5;                             % Initial pressure in the interior environment [Pa]
ref_temperature = 253.15;                           % Reference Temperature for Heat Transfer through leak [K]
interior_leak_rate = 0.00415;                       % Damage scenario leak rate modifier [-]

%%% ECLSS PARAMETERS
AirStorageTank_volume = 0.001;                      % Air storage tank limit for pressure control [m^3] [1L = 0.001 m^3].
HeaterHeat_capacity = 20;                           % Heater heating capacity [kW]  
ECLSS_indoor_set_temperature = 298.15;              % Indoor temperature setpoint [K]
ECLSS_pressure_set_point = 1.01325e5;               % Indoor pressure setpoint [Pa]  

%%% AGENT  SYSTEM INPUT PARAMETERS
agent_operational_mode = 'deterministic';           % Set the spread of agent action time estimation ['deterministic'/'stochastic']
                                                    % 'deterministic' sets any spread of agent behavior to 0
                                                    % 'stochastic' sets any spread of agent behavior to 1
                                                    
T_Home_ISRU = 2;                                    % Expected time to move Home <-> ISRU
T_Home_Str = 2;                                     % Expected time to move Home <-> Structure
T_Home_NPG = 2;                                     % Expected time to move Home <-> NPG
T_Home_SPG = 2;                                     % Expected time to move Home <-> SPG
T_Home_ECLSS = 2;                                   % Expected time to move Home <-> ECLSS
RepairStruct_Activity_Active = 1;                   % Set to 1 to enable and 0 to disable "Repair Struct" activity
RepairStruct_Action_Active = 1;                     % Set to 1 to enable and 0 to disable "Repair Struct" action
Exp_RepairTime_Structure = 5;                       % Expected repair time for structural system (to repair damage) [sec]
Exp_RepairRate_Structure = 6e-5;                    % Exp. repair rate for structure system (to repair damage), in m^3/0.001-s
RepairNPG_Activity_Active = 1;                      % Set to 1 to enable and 0 to disable "Repair NPG" activity
RepairNPG_Action_Active = 1;                        % Set to 1 to enable and 0 to disable "Repair NPG" action
Exp_RepairTime_NPG = 4;                             % Expected repair time for nuclear power system (to remove dust) [sec]
Exp_RepairRate_NPG = 10;                            % Exp. repair rate for nuclear power system (to remove dust), in mg/cm^2-s
RepairSPG_Activity_Active = 1;                      % Set to 1 to enable and 0 to disable "Repair SPG" activity
RepairSPG_Action_Active = 1;                        % Set to 1 to enable and 0 to disable "Repair SPG" action
Exp_RepairTime_SPG = 3;                             % Expected repair time for solar power system (to remove dust) [sec]
Exp_RepairRate_SPG = 100;                           % Exp. repair rate for solar power system (to remove dust), in mg/cm^2-s
Exp_RepairTime_ECLSS_Dust = 10;                     % Expected cleaning rate for dust damage per ECLSS panel [hrs/panel] * not established yet
Exp_RepairRate_ECLSS_Dust = 10;                     % ECLSS dust cleaning rate
Exp_RepairTime_ECLSS_Paint = 10;                    % Expected cleaning rate for pait damage per ECLSS panel [hrs/panel] * not established yet
Exp_RepairRate_ECLSS_Paint = 10;                    % ECLSS paint cleaning rate

%%% Lunar Environment Parameters for Habitat Design
space_temperature = 4;                          % Cosmic background space temperature [K]
ground_temperature = 373;                       % Lunar ground temperature [K]

air.density = 1.777;                            % Density of air [kg/m^3]
air.natural_convective_coefficient = 1000;      % Interior habitat air convective coefficient [W/(m.K)]
air.specific_heat = 1000;                       % Specific heat of air [J/(kg.K)]
air.viscosity = 18.37e-6;                       % Dynamic viscosity of air [Pa.sec]

dust.absorptivity = 0.76;                       % Absorptivity of lunar dust [-]
dust.conductivity = 0.0001;                     % Conductivity of lunar dust [W/(m.K)]
dust.density = 0.7;                             % Density of lunar dust [g/cm^3]
dust.emissivity = 0.93;                         % Emissivity of lunar dust [-]

%%% Habitat Design Variables
repair_temperature = 293.15;                % Initial temperature of the habitat when STM element is repaired [K]

%%% Habitat Design Constants
% Important Design Parameters
sb_sigma = 5.67e-08;                        % Stefan-Boltzmann constant [W/(m^2.K^4)]
foundation_temperature = 254.80;            % Lunar foundation temperature (boundary conditions) [K]

% Habitat Design Specs
habitat.volume = 32.725;                    % Volume of habitat interior [m^3]
habitat.inner_radius = 2.5;                 % Inner radius of the dome habitat [m]
habitat.dome_thickness = 0.4;               % Dome habitat thickness [m]
habitat.spl_thickness = 0.2;                % Structural protective layer thickness [m]

% Regolith Material Properties
regolith.emissivity = 0.97;                 % Emissivity of lunar regolith [-]
regolith.absorptivity = 0.87;               % Absorptance of lunar regolith [-]
regolith.density = 2000;                    % Density of lunar regolith [kg/m^3]
regolith.thermal_conductivity = 0.014;      % Thermal conductivity of lunar regolith [W/(m.K)]
regolith.specific_heat = 1053;              % Specific heat of lunar regolith [J/(kg.K)]

% Concrete Material Properties
concrete.emissivity = 0.85;                 % Emissivity of concrete [-]
concrete.absorptivity = 0.60;               % Absorptance of concrete [-]
concrete.density = 2400;                    % Density of concrete [kg/m^3]
concrete.thermal_conductivity = 1.000;      % Thermal conductivity of concrete [W/(m.K)]
concrete.specific_heat = 1000;              % Specific heat of concrete [J/(kg.K)]

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%               GENERAL EXECUTION SIMULATION PARAMETERS                   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  NOTE: This portion of the file should NOT be modified.

fs = 1000;                  % Integrated Sampling Frequency [Hz]
dt = 1/fs;                  % Integrated Sampling Rate [sec]
t = 0:dt:T_end;             % Simulation time vector [sec]

% Individual System Sampling Frequencies [Hz]
fs_2 = 1000;                % Structural System
fs_3 = 1000;                % Power System (Note: CANNOT be different to baseline dt.)
fs_5 = 200;                 % ECLSS System
fs_6 = 1000;                 % Agent System
fs_8 = 20;                  % Interior Environment 
fs_9 = 1000;                % Exterior Environment 

% Individual System Sampling Rates [sec]
dt_2 = 1/fs_2;              % Structural System
dt_3 = 1/fs_3;              % Power System
dt_5 = 1/fs_5;              % ECLSS System
dt_6 = 1/fs_6;              % Agent System
dt_8 = 1/fs_8;              % Interior Environment
dt_9 = 1/fs_9;              % Exterior Environment

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                             MCVT SIMULATION                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Note: Here we are calling on the individual system simulation scripts.

% Structural System
Sys2_structure_3D;

% Power System
Sys3_power;

% ECLSS System
Sys5_eclss;

% Agnet System
Sys6_agent;

% Interior Environment
Sys8_in_env;

% Exterior Environment
Sys9_ex_env;

%% RUN SIMULINK INTEGRATED MODEL
tic
disp('Execution Starts');
simOut = sim('MCVT_Integration','SimulationMode','normal');
elapsedTime(1) = toc;
disp('Execution Completes');
disp(['Execution time is ' num2str(elapsedTime(1)) ' sec']);

%% Save Time History Response 
load Sys2_out 
load Sys3_out 
load Sys5_out 
load Sys6_out 
load Sys8_out 
load Sys9_out;
save('testdata_Quickcheck_user.mat','sys2_out','sys3_out','sys5_out','sys6_out','sys8_out','sys9_out'); 
clearvars -except testdata_Quickcheck_user 
load testdata_Quickcheck_user




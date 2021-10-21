%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                      MCVT v1.5 Input File                                 
%                        Date: 9/7/2021                                  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MCVT - version 1.5: Integrated Simulation
% MCVT Systems: 
% Structural, Power, ECLSS, Interior Env., Exterior Env., Agent & HMS

run_mode = "developer";                     % `developer` or `user` mode for running the code

if run_mode == "user"
    %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %              Specify Simulation Output File Name                           
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    Output_Folder = ['MCVT_run1_' date];        % Set output file name
    mkdir(Output_Folder);
end
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            MCVT SCENARIOS                             
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Note: Here specify the input parameters for the MCVT scenario that you
% wish to run.

tic

%%% ADD FOLDER TO SEARCH PATH
addpath(genpath(pwd)); 

%%% TOTAL SIMULATION TIME
T_end = 120;                                         % Total simulation time [sec];
print_interval = 30;                                % Print Interval for Simulation Time [sec]


%%% EXTERIOR ENVIRONMENT INPUT PARAMETERS
% Meteorite impact input
meteorite_impact_time = 2;                                  % Meteorite time [sec];
meteorite_impact_location_xyz = [1.0631 2.4778 1.0679];     % Meteorite impact location x,y,z coordinates, the available options are: 
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
launch_site_dust_distance = [100, 150, 200];            % Distance between launch/landing site and the nuclear power system, solar PV system, and ECLSS radiator panels [m], respectively;
norminal_dust_accum_rate = [0.1, 0.3, 0.2];             % Nominal dust accumualtion rate without meteorite impact events 
met_dust_accum_rate = [10, 30, 20];                     % Typical dust accumualtion rate with meteoroite impact event
launch_dust_accum_start_time = 10;                      % Dust accumulation due to lanch/landing events start time [sec];
launch_dust_accum_stop_time = 12;                       % Dust accumulation due to lanch/landing events stop time [sec];
dust_met_duration = 3;                                  % Dust accumulation due to meteoroid impact duration time [sec];

% Solar radiation start angle
Start_angle = 90;                                   % Specify the start angle of radiation

%%% STRUCTURAL SYSTEM INPUT PARAMETERS
damage_case_id = 3;                                 % Structural system damage case, can be selected between 1 and 4
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

ECLSS_Dust_Panel_Repair_Threshold = 15;             % Number of panels damaged for HMS to trigger repair activity
Exp_RepairTime_ECLSS_Dust_pp = 0.9;                 % Expected cleaning time for dust damage per ECLSS panel [secs/panel]
% Expected cleaning time for dust damage for ECLSS Radiator Panels [secs]
Exp_RepairTime_ECLSS_Dust = round(ECLSS_Dust_Panel_Repair_Threshold*Exp_RepairTime_ECLSS_Dust_pp);                     
Exp_RepairRate_ECLSS_Dust = 10;                     % ECLSS dust cleaning rate

ECLSS_Paint_Panel_Repair_Threshold = 15;            % Number of panels damaged for HMS to trigger repair activity
Exp_RepairTime_ECLSS_paint_pp = 0.9;                % Expected cleaning time for paint damage per ECLSS panel [secs/panel]
% Expected cleaning time for paint damage for ECLSS Radiator Panels [secs]
Exp_RepairTime_ECLSS_Paint = round(ECLSS_Paint_Panel_Repair_Threshold*Exp_RepairTime_ECLSS_paint_pp);                   
Exp_RepairRate_ECLSS_Paint = 10;                    % ECLSS paint cleaning rate


elapsedTime(1) = toc;

disp(['-[1/6] Input File Loaded (' num2str(elapsedTime(1)) ' sec)']);

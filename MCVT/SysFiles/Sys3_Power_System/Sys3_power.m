%% Documentation
% Purpose: To call the functions required to run the nuclear power and
%          power distribution models, create constants based on the input
%          file, and define constants for the simulated solar FDD.
% Date Created: 8 July 2021
% Date Last Modified: 28 July 2021
% Modeler Names: Yuguang Fu (Purdue), Ryan Tomastik (UConn), Kairui Hao
    % (Purdue)
% Funding Acknowledgement: Funded by the NASA RETHi Project
%                          (grant #80NSSC19K1076)

% Version Number: MCVT v4

% Subsystem Connections: This code does not connect to other subsystems.

% Function Dependencies:
%   - init_sim_v8.m
%   - Solar_simu_FDD_pp.m
%   - MCVT_Input_File.m

% No Data Depenencies

%% Calling the required functions
init_sim_v8;

%% Check that variables are in acceptable range
nuclear_input_variable_check;

%% Constants
nuclear_power = 1-nuclear_power_toggle;
    % setting to 0 has no change, 1 forces nuclear power to zero, chosen in
    % input file
solar_power = 1-solar_power_toggle;
    % setting to 0 has no change, 1 forces solar power to zero, chosen in
    % input file
e_store_max_o = energy_store_max_o;     
    % maximum amount of energy that can be stored (kWh), define in input
    % file
e_store_min_o = energy_store_min_o;
    % minimum amount of energy that can be stored (kWh), defined in input
    % file
solar_FDD_K = Solar_simu_FDD_pp(solar_FDD_Ts, solar_FDD_zeta); 
    % Precompute feedback gain for the simulated solar PV FDD.

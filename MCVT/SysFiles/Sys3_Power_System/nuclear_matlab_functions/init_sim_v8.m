%% Documentation
% Purpose: To define constants and initilize values for the reduced order
%          model and dust surrogate models.
% Date Created: 24 July 2020
% Date Last Modified: 24 July 2020
% Modeler Name: Donald McMenemy (UConn) and Ryan Tomastik (UConn)
% Funding Acknowledgement: Funded by the NASA RETHi Project
%                          (grant #80NSSC19K1076)

% Version Number: MCVT v4

% Subsystem Connections: This code does not connect to other subsystems.

% No Function Dependencies
%   - MCVT_Input_File.m

% Data Dependencies:
%   - dependent on the files within the folder "mat_files"

%% 1st Loop/Stirling init %%
% Lines 22-44 load in data for discrete-time state space models of the 5
% main temperatures of the nuclear model. For each temperature this file
% loads in the associated A, B, C, and D matrices for that model as well as
% its initial condititions.

load sldemo_tc_blocks_data.mat

%%% FDD Surrogate Model %%%

%Tf_hat from Tc2 and Tc1 measurements
load('ss_coeffs_TF_from_Tc2_Tc1.mat');
load('ss_initial_condition_TF_from_Tc2_Tc1.mat')

%Tb1_hat from Tc2, Tc1, TF measurements
load('ss_coeffs_Tb1_from_Tc2_Tc1_TF.mat');
load('ss_initial_condition_Tb1_from_Tc2_Tc1_TF.mat')

%Tb2_hat from Tc2, Tc1, TF measurements
load('ss_coeffs_Tb2_from_Tc2_Tc1_TF.mat');
load('ss_initial_condition_Tb2_from_Tc2_Tc1_TF.mat')

%Tc1_hat from Tb1 Tb2 measurements
load('ss_coeffs_Tc1_from_Tb1_Tb2.mat');
load('ss_initial_condition_Tc1_from_Tb1_Tb2.mat')

%Tc2_hat from Tb1 Tb2 measurements
load('ss_coeffs_Tc2_from_Tb1_Tb2.mat');
load('ss_initial_condition_Tc2_from_Tb1_Tb2.mat')

%%% Constants %%%

sub3_spec_heat_2nd_loop = 875; 
    %specific heat of secondary loop coolant loop (cps)
sub3_flowrate_2nd_coolant = initial_power_level/(2*...
    sub3_spec_heat_2nd_loop*25); 
    % flowrate of secondary coolant (kg/s) (mdots)
sub3_cyceff = 0.316; 
    % expected cycle efficiency

expected_power=53.6*10^3; 
    % expected Stirling cycle PV power (W) (Wpv)
cyceff=sub3_cyceff; 
    % expected cycle efficiency
expected_heat_add=expected_power/cyceff; 
    % expected cycle avg. heat addition (W) (dQhss)


%% Nominal cases for SP-100 model data generation %%

nuclear_internal_disturb = [ 0, 0, 1, 1 ]; 
    %defines initial inputs
                     
%inital inputs
u_i = nuclear_internal_disturb(1,:);
u_i_0 = u_i;
sec_loop_fluct0 = u_i(1); 
    % secondary loop fluctuation (unitless)
row_gain0 = u_i(2);   
    % radioactivity gain (unitless)
prim_flowrate0 = u_i(3); 
    % primary loop flow rate gain (unitless)
sec_flowrate0 = u_i(4); 
    % secondary loop flow rate gain (unitless)


% output_names: 'fuel_temp','primary_loop_inlet_temp',
%     'primary_loop_outlet_temp','sec_loop_inlet_temp',
%     'sec_loop_outlet_temp','power_out'
 output_limits = [ 1100, 1400; 900, 1400; 800, 1400; 800, 1200; ...
     900, 1100; 200, 220]; 
    % used for scaling functions


%% FIR LPF for Secondary Loop Drop %% 

nuclear_sampling_freq = 1; 
    %Simulation sampling frequency
cutoff_freq = 2*pi*(0.1); 
    %1/10Hz cutoff frequency since Temperature is low frequency (B_LPF)
order_of_FIR = 59; 
    %59 order FIR 


m = (order_of_FIR-1)/2;
FIR_LPF = zeros(1,order_of_FIR); 
for i=1:order_of_FIR
    k=i-1;
    FIR_LPF(i)=(cutoff_freq*nuclear_sampling_freq/pi)*sinc(cutoff_freq*...
        (k-m)*nuclear_sampling_freq/pi)*(0.54+0.46*cos(2*pi*(k-m)/...
        (order_of_FIR-1)));
end


%% Dust Surrogates %%

all_dust_levels = 1:-0.05:0; 
    % vector of 21 discrete dust levels
for k = 1:21
    load(strcat('sys_n4sid_Tc1_to_variables_',num2str(k),'.mat'))
    load(strcat('sys_n4sid_initial_conditions_',num2str(k),'.mat'))
end

%% Nuclear Simulink Gains and Constants
nuclear_toggle_gain = (1e-4)*nuclear_power_toggle;
    % reduces nuclear output and toggles on/off
sub3_nuc_FDD_gain = 2;
    % gain for FDD signal for purposes of cleaning
sub3_num_converters = 4;
    % number of converters
sub3_nuc_dust_convert = 0.001;
    % converts dust accum. from mg/cm^2 to g/cm^2
sub3_init_tc2 = 970.2301;  
    % initial condition for tc2
sub3_cusum_sigma = 1000;
    % cusum parameter sigma
sub3_sigma_n = 25;
    % cusum paramter sigma_n
sub3_sigma_c = 5;
    % cusum parameter sigma_c
sub3_voltage = 125;
    % voltage assumed for the power system (V)
kW_to_W = 1000;
W_to_kW = 0.001;

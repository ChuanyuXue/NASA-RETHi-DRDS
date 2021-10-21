function FDD_signal_sent = FDD_toggle(FDD_signal, nuclear_power_toggle,...
    battery_power_toggle)
%% Documentation
% Purpose: To ensure nuclear FDD behaves as expected when nuclear power is 
%          toggled off in the input file.
% Date Created: 30 April 2021
% Date Last Modified: 2 May 2021
% Modeler Name: Ryan Tomastik (UConn)
% Funding Acknowledgement: Funded by the NASA RETHi Project
%                          (grant #80NSSC19K1076)

% Version Number: MCVT v4

% Subsystem Connections: This code sends its output to the Agent Subsystem

%%% All inputs and outputs to this function are 1 dimensional %%%
% INPUTS %
%   - FDD_signal: Int; The nuclear FDD signal relating to dust
%   accumulation, equals 0 if not detecting a fault, equals 1 otherwise
%   (unitless)
%   - nuclear_power_toggle: Int; equals 1 if nuclear power supply is
%   enabled and 0 if it is disabled (unitless)
    
% OUTPUTS %
%   - FDD_signal_sent: Int; The nuclear FDD signal that is sent to the
%   Agent Subsystem (unitless)

% Function Dependencies:
%   - MCVT_Input_File.m

% No Data Dependencies

%% Code
FDD_signal_sent = FDD_signal;
    % initialize the variable
if nuclear_power_toggle == 1
    % nuclear is enabled
    FDD_signal_sent = FDD_signal;
    % we do not want to change the FDD
elseif nuclear_power_toggle == 0 && battery_power_toggle == 1 
    % nuclear is disabled, battery is enabled
    FDD_signal_sent = FDD_signal; 
    % we do not want to change the FDD
elseif nuclear_power_toggle == 0 && battery_power_toggle == 0 
    % nuclear and batter are disabled
    FDD_signal_sent = false; 
    % make sure FDD is always false
end
end
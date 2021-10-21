function [cusum_stat1,intervention_previous]  = cusum(intervention,...
    time,time_step,cusum_stat1,intervention_previous)
%% Documentation
% Purpose: To reset the CUSUM statistic used for FDD once intervention
%          ends. For more details see Chapter 8 of the documentation
%          report, henceforth referred to as "report".
% Date Created: 15 April 2021
% Date Last Modified: 23 May 2021
% Modeler Name: Ryan Tomastik (UConn)
% Funding Acknowledgement: Funded by the NASA RETHi Project
%                          (grant #80NSSC19K1076)

% Version Number: MCVT v4

% Subsystem Connections: This code receives inputs from the Agent
%   Subsystem and sends output to the same subsystem.

%%% All inputs and outputs to this function are 1 dimensional %%%
% INPUTS %
%   - intervention: Int; equals 1 if intervention is happening, equals 0 if
%   not (unitless)
%   - time: Float; the current time of the simulation (s)
%   - time_step: Float; the time step used for the model, a constant (s)
%   - cusum_stat1: Float; the cusum statistic used for FDD (unitless)
%   - intervention_previous: Int; the value of "intervention" at the
%   previous time step (unitless)
    
% OUTPUTS %
%   - cusum_stat1: Float; the cusum statistic used for FDD (unitless)
%   - intervention_previous: Int; the value of "intervention" at the
%   previous time step (unitless)

% No Function Dependencies

% No Data Dependencies


%% Beginning of Simulation
if time == 0;
    cusum_stat1 = 0; 
    % need to define cusum_stat1 at the start
    intervention_previous = 0; 
    % there is no previous time step so explicitly define it here
else
    cusum_stat1 = cusum_stat1; 
    % otherwise pass through
end

%% Remainder of Simulation
sim_time = floor(time/time_step);
    % simulation time (s)
if sim_time >= 2 
    % when simulation has ran for 2 steps or more
    if intervention - intervention_previous == -1 
    % will happen the moment intervention stops
        cusum_stat1 = 0;
    % need to reset the CUSUM stat
    end
end
intervention_previous = intervention; 
    % store intervention for next run
end
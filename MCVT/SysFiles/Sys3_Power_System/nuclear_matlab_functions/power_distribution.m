function [power_demands, status_data]  = power_distribution(...
    total_power_avail,power_demands)
%% Documentation
% Purpose: To distribute the power to structural, ECLSS, and interior
%          subsystems.
% Date Created: 5 Sept 2020
% Date Last Modified: 19 May 2020
% Modeler Name: Donald McMemeny (UConn)
% Funding Acknowledgement: Funded by the NASA RETHi Project
%                          (grant #80NSSC19K1076)

% Version Number: MCVT v4

% Subsystem Connections: This code receives inputs from Subsystems 2, 5,
    % and 8. This code ultimately sends outputs to the same subsystems.

% INPUTS %
%   - total_power_avail: Float; the total power available to send to
%   other subsystems (kW)
%   - power_demands: Float; the power that is requested by subsystems 2, 5,
%   and 8 (kW); is a 3-D vector
    
% OUTPUTS %
%   - power_demands: Float; the power that is requested by subsystems 2, 5,
%   and 8 (kW); is a 3-D vector
%   - status_data: Int; Equals 0 if power demand is met, equals 1 if not
%   (unitless)

% Function Dependencies: (stored in ...)
%   - power_gen_allocation.m

% No Data Dependencies

%% Calculate power to send to subsystems
allocated_power = 0; 
    % so variable is defined on all paths

for index = 1:length(power_demands)
    %for loop calculates the power sent to each of 3 subsystems
    if total_power_avail >= allocated_power + power_demands(index)
    % power demand is met for system at present index
        allocated_power = allocated_power + power_demands(index); 
        status_data = 0; 
    % the power demand is met (unitless)
    else
    % power demands cannot be met for all systems
        status_data = 1;
        if (total_power_avail > allocated_power)
    % Allocate the remaining power to load at present index           
            power_demands(index)= total_power_avail - allocated_power;
            allocated_power = total_power_avail;
        else
    % Allocate zero power to load at present index
            power_demands(index) = 0;
        end
    end
end
    
end
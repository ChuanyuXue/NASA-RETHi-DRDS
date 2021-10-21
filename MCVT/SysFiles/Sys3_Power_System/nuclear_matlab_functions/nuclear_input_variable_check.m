%% Documentation
% Purpose: To check the nuclear parameters set within the input file. Will
%          give a warning if a parameter was set outside of the acceptable
%          range, but will not stop the simulation.
% Date Created: 17 August 2021
% Date Last Modified: 20 August 2021
% Modeler Name: Ethan Rathbun and Ryan Tomastik (UConn)
% Funding Acknowledgement: Funded by the NASA RETHi Project
%                          (grant #80NSSC19K1076)

% Version Number: MCVT v5

% Subsystem Connections: This code checks the parameters of the nuclear
%   subsystem.

% Function Dependencies:
%   - MCVT_Input_File.m
%   - Sys3_power.m

% No Data Dependencies

%% Define parameters, ranges, and names
params = [energy_store_o,initial_power_level,SOC_upper_thres,...
    SOC_lower_thres,battery_trickle_leakage_param,...
    battery_trickle_charge_param,gain_charge_param,I_max_charge,...
    I_max_discharge,energy_store_max_o,energy_store_min_o,...
    nuclear_power_toggle,solar_power_toggle,battery_power_toggle];
    % Array containing all parameters for the subsystem that can be set by
    % the user in the input file

ranges = [0 150; 2.5e5  8e5; 0 1; 0 1; 0 1; 0 1; 1 5; 0 1000;...
    0 1000; 0 150; 0 150];
    % array containing all parameter acceptable ranges, order must agree
    % with that of "params"

open = [false,false,false,false,true,true,false,false,false,...
    false,false];
    % array containing truth values denoting if the parameter bounds are
    % open or not; for example, the acceptable range (0, 1) is open

names = ["energy_store_o","initial_power_level","SOC_upper_thres",...
    "SOC_lower_thres","battery_trickle_leakage_param",...
    "battery_trickle_charge_param","gain_charge_param",...
    "I_max_charge","I_max_discharge","energy_store_max_o",...
    "energy_store_min_o","nuclear_power_toggle","solar_power_toggle",...
    "battery_power_toggle"];
    % array containing all parameter names, the order must agree with that
    % of "params" and "ranges"; exception: in this case the ranges of
    % nuclear_power_toggle, solar_power_toggle, and battery_power_toggle
    % are either 0 or 1, so it is easier to check their ranges separately,
    % but they still must be included in params and names

%% For loop to check each of the parameters
for i = 1:length(params)-3
    % -3 here because the "toggle" parameters are checked separately
    if open(i)
    % check if open, need to use "()" instead of "[]"
        if params(i) <= ranges(i,1) || params(i) >= ranges(i,2) 
    % check if parameter is within range
            string1 = strcat("****Parameter ", string(names(i)), ...
                " was set to ", num2str(params(i)), ...
                " which is outside of the reasonable range (", ...
                string(ranges(i,1)), ", ", string(ranges(i,2)), ")****");
            disp(string1)
    % print the string message warning a parameter is outside the
    % acceptable range
        end
    else
    % if not open, need to use "[]" instead of "()"
        if params(i) < ranges(i,1) || params(i) > ranges(i,2)  
    % check if parameter is within range
            string2 = strcat("****Parameter ", string(names(i)), ....
                " was set to ", num2str(params(i)), ...
                " which is outside of the reasonable range [", ...
                string(ranges(i,1)), ", ", string(ranges(i,2)), "]****");
            disp(string2) 
    % print the string message warning a parameter is outside the 
    % acceptable range
        end
    end
end

for k = 12:14 
    % have a separate check for toggle parameters
    if params(k) ~= 0 && params(k) ~= 1 
    % check if the toggle parameter is a value other than 0 or 1
        string3 = strcat("****Parameter ", string(names(k)), ...
            " was set to ", num2str(params(i)), ...
            " which is outside of reasonable range 0 or 1****");
        disp(string3) 
    % print the string message warning a parameter is outside the 
    % acceptable range
    end
end

%% Documentation
% Purpose: To initialize the scripts corresponding to System 8 that must be
% executed during compilation. These scripts provide system variables that are
% fixed and do not need to be recalculated during simulation.

% Date Created: 3 June 2021
% Date Last Modified: 7 September 2021
% Modeler Name: Jeffrey Steiner (UConn)
% Funding Acknowledgement: Funded by the NASA RETHi Project (Grant #80NSSC19K1076)

% Version Number: MCVT v5

% Subsystem Connections: This code executes scripts during compilation and
% does not connect during simulation.
    
% OUTPUTS %
%   - reference_temperature: User-Defined Reference Temperature for the
%   Lunar environment just outside of the habitat
%   - [HIEMDamageNodes, HIEMDamageElements]: Coordinates and predetermined
%   elements corresponding to potential Sys2 damage locations
%   - [Bmap, Temp2HIEM]: Coordinates and predetermined
%   elements corresponding to mapping temperature to Sys8
%   - [Bmap2, HIEM2SMM]: Coordinates and predetermined
%   elements corresponding to mapping values to Sys2
%   - [HIEM2STM, Bmap3]: Coordinates and predetermined
%   elements corresponding to mapping temperature to Sys2

% No Function Dependencies

% No Data Dependencies

reference_temperature=ref_temperature;  % in K
[HIEMDamageNodes, HIEMDamageElements] = SMM2HIEM_mapping_Init;
[Bmap, Temp2HIEM]=STM2HIEM_mapping_Init;
[Bmap2, HIEM2SMM]=HIEM2SMM_mapping_Init;
[HIEM2STM, Bmap3] = HIEM2STM_mapping_Init;
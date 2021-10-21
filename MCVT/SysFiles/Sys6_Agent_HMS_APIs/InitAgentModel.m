%         #=================================================#
%         #    Code developed for the RETH-Institute        #
%         #    By: Murali Krishnan Rajasekharan Pillai      #
%         #    PhD Student @ Purdue University              #
%         #    Funded by: NASA                              #
%         #    Last Modified: July 29, 2021                 #
%         #=================================================#
%         Purpose: Initializations for the agent model
%         In this file, user specified information in `MCVT_Input_File.m`
%         is converted into the format specific to the agent format
%
%         MCVT Report Section: Section 5
%
%         Version details:
%           - Previuos versions: Prototype modules
%           - Version 5:
%               - Adhere to MATLAB System Block definitions
%               - Supports interaction with
%                   - Structural Mechanical System for repair
%                   - Solar PG for repair (removal of dust on panels)
%                   - Nuclear PG for repair (removal of dust ono radiator panels)
%               - Supports the definition of the following health states
%                   - State of charge of the agent
%                   - Mobility health states of the agent
%% Agent Properties
EMPTY = -9999;                            % Pre-defined variable indicating `EMPTY` information

AgentMemorySize_CB = agent_memory_size + 1; % Accomodation for a Circular Buffer %% FUTURE release!

R_batteryDischarge = -1/agent_life;      % Rate of SOC degradation for the agent [s^-1]
R_mobDamage = -1/agent_life;             % Rate of moobility health state degradation [s^-1]

%% Assumed layout of the habitat for agent mobility (Section 5.2.1)
%---------------------------------
% Position       |  Position-ID  |
%--------------------------------|
% Home           |        1      |
% ISRU/Inventory |        2      |
% Structure      |        3      |
% Nucl. PG       |        4      |
% Sol. PG        |        5      |
% ECLSS Radiator |        6      |
%--------------------------------|

loc_AgentHome = 1;
loc_Inventory = 2;
loc_Structure = 3;
loc_NuclearPG = 4;
loc_SolarPG = 5;
loc_ECLSS = 6;
% Expected time for an agent to move betweenn afore-mentioned locations [s]
% (Ref Section 5.2.1)
% Time taken to travel
T_12 = T_Home_ISRU;         % Time to travel from Home (1) - ISRU (2) [s]
T_13 = T_Home_Str;          % Time to travel from Home (1) - Structure (3) [s]
T_14 = T_Home_NPG;          % Time to travel from Home (1) - NPG (4) [s]
T_15 = T_Home_SPG;          % Time to travel from Home (1) - SPG (5) [s]
T_16 = T_Home_ECLSS;        % Time to travel from Home (1) - ECLSS Radiator (6) [s]
% Assuming symmetric time for mobility
T_21 = T_12;
T_31 = T_13;
T_41 = T_14;
T_51 = T_15;
T_61 = T_16;

% Composing an Distance-Time Matrix for fast look-up
dTimeMatrix = ...
[
    0,  T_12,  T_13,  T_14,  T_15,  T_16; % Home Location
    T_21,  0,  0,  0,  0,  0; % ISRU / Inventory
    T_31,  0,  0,  0,  0,  0; % Structureu
    T_41,  0,  0,  0,  0,  0; % Nuclear PG
    T_51,  0,  0,  0,  0,  0; % Solar PG
    T_61,  0,  0,  0,  0,  0; % ECLSS

];

%% Activity Command Definitions

% Action Templates used to compose activity
% pickItem (to Agent Inventory)    = [actionID = 1, muT, spreadT, itemID, itemNum]
% putItem (from Agent Inventory)   = [actionID = 2, muT, spreadT, itemID, itemNum]
% moveAgent                        = [actionID = 3, muT, spreadT, toLoc ]
% repairNuclearPowerGen            = [actionID = 4, Exp_RepairTime, spreadT, failMode, Exp_RepairRate]
% repairSolarPowerGen              = [actionID = 5, Exp_RepairTime, spreadT, failMode, Exp_RepairRate]
% repairStructure                  = [actionID = 6, Exp_RepairTime, spreadT, failMode, Exp_RepairRate]
% repairECLSS                      = [actionID = 7, Exp_RepairTime, spreadT, failMode, Exp_RepairRate] 

%% Activity Template for Nuclear PG Repair
fMode_NPG = 1;
repair_NPG_Activity_ID = 5;
repairNPGActivity = ...
[
    repair_NPG_Activity_ID, EMPTY, EMPTY, EMPTY, EMPTY;                                                                                      % Unique Identifier for the command
    3, dTimeMatrix(loc_AgentHome,loc_NuclearPG), Exp_spread_for_mobilityAction, loc_NuclearPG, EMPTY;                   % Move to location 31
    4, Exp_RepairTime_NPG, Exp_spread_for_interventionAction, fMode_NPG, Exp_RepairRate_NPG;                            % Repair for some time
    3, dTimeMatrix(loc_NuclearPG,loc_AgentHome), Exp_spread_for_mobilityAction, loc_AgentHome, EMPTY;                   % Move back to `home` location
    EMPTY, EMPTY, EMPTY, EMPTY, EMPTY;                                                                                  % EMPTY
    EMPTY, EMPTY, EMPTY, EMPTY, EMPTY;                                                                                  % EMPTY
];

%% Activity Template for Solar PG Repair
fMode_SPG = 1;
repair_SPG_Activity_ID = 1;
repairSPGActivity = ...
[
    repair_SPG_Activity_ID, EMPTY, EMPTY, EMPTY, EMPTY;                                                                                      % Unique Identifier for the command
    3, dTimeMatrix(loc_AgentHome,loc_SolarPG), Exp_spread_for_mobilityAction, loc_SolarPG, EMPTY;                       % Move to PV arrays
    5, Exp_RepairTime_SPG, Exp_spread_for_interventionAction, fMode_SPG, Exp_RepairRate_SPG;                            % Repair for some time
    3, dTimeMatrix(loc_SolarPG, loc_AgentHome), Exp_spread_for_mobilityAction, loc_AgentHome, EMPTY;                    % Move back to `home` location
    EMPTY, EMPTY, EMPTY, EMPTY, EMPTY;                                                                                  % EMPTY
    EMPTY, EMPTY, EMPTY, EMPTY, EMPTY;                                                                                  % EMPTY
];

%% Activity Template for Structure Repair
fMode_Structure = 1;
repair_Structure_Activity_ID = 4;
repairStructure = ...
[
    repair_Structure_Activity_ID, EMPTY, EMPTY, EMPTY, EMPTY;                                                                                      % Unique Identifier for the command
    3, dTimeMatrix(loc_AgentHome,loc_Structure), Exp_spread_for_mobilityAction, loc_Structure, EMPTY;                   % Move to Structure
    6, Exp_RepairTime_Structure, Exp_spread_for_interventionAction, fMode_Structure, Exp_RepairRate_Structure;          % Repair for some time
    3, dTimeMatrix(loc_Structure,loc_AgentHome), Exp_spread_for_mobilityAction, loc_AgentHome, EMPTY;                   % Move back to `home` location
    EMPTY, EMPTY, EMPTY, EMPTY, EMPTY;
    EMPTY, EMPTY, EMPTY, EMPTY, EMPTY;
];

%% Activity Template for ECLSS Dust Repair
fMode_ECLSS_Dust = 1;
repair_ECLSS_Dust_Activity_ID = 2;
repairECLSSDust = ...
[
    repair_ECLSS_Dust_Activity_ID, EMPTY, EMPTY, EMPTY, EMPTY;                                                                                      % Unique Identifier for the command
    3, dTimeMatrix(loc_AgentHome,loc_ECLSS), Exp_spread_for_mobilityAction, loc_ECLSS, EMPTY;                           % Move to Structure
    7, Exp_RepairTime_ECLSS_Dust, Exp_spread_for_interventionAction, fMode_ECLSS_Dust, Exp_RepairRate_ECLSS_Dust;            % Repair for some time
    3, dTimeMatrix(loc_ECLSS,loc_AgentHome), Exp_spread_for_mobilityAction, loc_AgentHome, EMPTY;                       % Move back to `home` location
    EMPTY, EMPTY, EMPTY, EMPTY, EMPTY;
    EMPTY, EMPTY, EMPTY, EMPTY, EMPTY;
];

%% Activity Template for ECLSS Paint Repair
fMode_ECLSS_Paint = 2;
repair_ECLSS_Paint_Activity_ID = 3;
repairECLSSPaint = ...
[
    repair_ECLSS_Paint_Activity_ID, EMPTY, EMPTY, EMPTY, EMPTY;                                                                                        % Unique Identifier for the command
    3, dTimeMatrix(loc_AgentHome,loc_ECLSS), Exp_spread_for_mobilityAction, loc_ECLSS, EMPTY;                             % Move to Structure
    7, Exp_RepairTime_ECLSS_Paint, Exp_spread_for_interventionAction, fMode_ECLSS_Paint, Exp_RepairRate_ECLSS_Paint;            % Repair for some time
    3, dTimeMatrix(loc_ECLSS,loc_AgentHome), Exp_spread_for_mobilityAction, loc_AgentHome, EMPTY;                         % Move back to `home` location
    EMPTY, EMPTY, EMPTY, EMPTY, EMPTY;
    EMPTY, EMPTY, EMPTY, EMPTY, EMPTY;
];
%% Activity template for emptyActivity
emptyActivity = ...
[
    EMPTY, EMPTY, EMPTY, EMPTY, EMPTY;                                                                                     % Unique Identifier for the command
    EMPTY, EMPTY, EMPTY, EMPTY, EMPTY;
    EMPTY, EMPTY, EMPTY, EMPTY, EMPTY;
    EMPTY, EMPTY, EMPTY, EMPTY, EMPTY;
    EMPTY, EMPTY, EMPTY, EMPTY, EMPTY;
    EMPTY, EMPTY, EMPTY, EMPTY, EMPTY;
];

%% Activity Template parameters derived from inputs
numMaxActions = size(emptyActivity,1)-1;                                    % Excluding the meta-data
numMaxActionParams = size(emptyActivity,2);                                 % max number of parameters
numActivities = 6;                                                          % Number of activities in the look-up table
paramStartIndex = 4;
%% Creating the Activity Lookup table
ACTIVITY_LOOKUP_TABLE = EMPTY * ones(numActivities, numMaxActions+1, numMaxActionParams);
ACTIVITY_LOOKUP_TABLE(repair_NPG_Activity_ID,:,:) = repairNPGActivity(:,:);
ACTIVITY_LOOKUP_TABLE(repair_SPG_Activity_ID,:,:) = repairSPGActivity(:,:);
ACTIVITY_LOOKUP_TABLE(repair_Structure_Activity_ID,:,:) = repairStructure(:,:);
ACTIVITY_LOOKUP_TABLE(repair_ECLSS_Dust_Activity_ID,:,:) = repairECLSSDust(:,:);
ACTIVITY_LOOKUP_TABLE(repair_ECLSS_Paint_Activity_ID,:,:) = repairECLSSPaint(:,:);
ACTIVITY_LOOKUP_TABLE(6,:,:) = emptyActivity(:,:);

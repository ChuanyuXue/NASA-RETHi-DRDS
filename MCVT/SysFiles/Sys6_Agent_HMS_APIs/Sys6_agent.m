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
%         MCVT Report Section: Section 5 : Intervention Agents

%% Agent Life and Memory Size
agent_life = T_end + 1;                             % Life-time of the agent in operation [sec]
                                                    % WARNING: agent_life should be greater than `T_end` (will throw assertion error)

agent_memory_size = 10;                             % Size of the agent memory module [-]
RepairTime_ECLSS_factor = 1/3600;                   % Conversion Factor to hrs
%% Setting the random number generator
rng('default');

%% Verification of all User Inputs
assert(agent_memory_size >= 1, "Invalid Agent Memory Size (at-least 1)");
% NOTE: Need to checl if active actiivity/action matches!!
assert(agent_life > T_end, "`lifeOfAgent` should be greater than `T_end`");

% Agent - System Interdependency mapping
% [failure mode, repair action completion flag, repair time, repair rate ]
idx_failure_mode = 1;
idx_Activity_Completion_Flag = 2;
idx_repair_action_time = 3;
idx_repair_action_rate = 4;

% Setting the spread of agent behavior from user input
switch agent_operational_mode
    case "deterministic"
        Exp_spread_for_interventionAction = 0;               % The expected variation of agent intervention action time
        Exp_spread_for_mobilityAction = 0;                   % The expected spread of agent mobility action time
    case "stochastic"
        Exp_spread_for_interventionAction = 1;
        Exp_spread_for_mobilityAction = 1;
    otherwise
        error('Invalid `agent_operational_mode` (deterministic/stochastic)');
end

%% Wrapper for Agent Model parameter initializations
InitAgentModel;
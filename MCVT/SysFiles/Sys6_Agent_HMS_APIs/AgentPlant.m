classdef AgentPlant < matlab.System
%         Plant model of the health-states of the agent
%         #=================================================#
%         #    Code developed for the RETH-Institute        #
%         #    By: Murali Krishnan Rajasekharan Pillai      #
%         #    PhD Student @ Purdue University              #
%         #    Funded by: NASA                              #
%         #    Last Modified: July 29, 2021                 #
%         #=================================================#
%         Purpose: Defines the dynamics of the agent health states as the
%         agent executes activities preseent in it's memory.
%
%         MCVT Report Section: Section 5.2.4
%
%         Version details:
%           - Previuos versions: Prototype modules
%           - Version 5:
%               - Adhere to MATLAB System Block definitions
%               - Supports interaction with
%                   - Structural Mechanical System for repair
%                   - Solar PG for repair (removal of dust on panels)
%                   - Nuclear PG for repair (removal of radiator panel dust)
%               - Supports the definition of the following health states
%                   - State of charge of the agent
%                   - Mobility health states of the agent
% 
%               Updated on Aug 21, 2021
%               - 
%
%         Input Arguments:
%         ----------------
%         actionID          :   float
%                               The actionID of the current action
%         actionParams      :   2-d float array
%                               The parameters of the current action
%         actionDone        :   float
%                               Flag indicating the final step of action 
%                               (to update discrete agent states)
%         actSampleTime     :   float
%                               Time the particular agent action will be
%                               active for when performing the intervention
%                               activity
%     
%     
%         Output Arguments:
%         -----------------
%         States                :   1-d float array
%                                   Array consisting of all agent plant states
%                                   order = [soc, mobiliityHS, position]
%         CommsSubSys_Combined  :   2-d float array
%                                   Array packaging all interaction between
%                                   the agent and the electro-mechanical
%                                   systems
%         doneFLAGS             :   1-d float array
%                                   Array informing the completion of the
%                                   agennt interrvention actions
%
%         Attributes:
%         ----------
%         dt                :   float
%                               Time step used in the simulation for scaling [s]
%         chargeRate        :   float
%                               The charging rate for soc [s^-1]
%         dischargeRate     :   float
%                               The discharge rate for soc [s^-1]
%         dischargeRateIdle :   float
%                               The discharge rate for soc when idle [s^-1]
%         mobDamageRate     :   float
%                               The damage rate for mobility components during [s^-1]
%         
%         EMPTY             :   float
%                               Pre-defined constant to denote invalid commands
    
    properties (Nontunable)
        dt=0.1              % Agent System step-time
        dischargeRate=-1e-4 % soc Health State degradation rate (sec^-1)
        mobDamageRate=-1e-4 % Mobility component degradation Rate (sec^-1)
        lifeOfAgent=1e4     % Total life of agent
    end
    
    properties (Access = protected)
        % Trackable states of the agent plant
        soc
        mobilityHS
        Inventory
        doneFLAGS
        position
        actSampleTime
        
        % Communication Structures for the Agent Model
        Comms_Inventory
        Comms_NPG
        Comms_SPG
        Comms_Structure
        Comms_ECLSS
        
    end
    
    
    properties (Nontunable, Access=protected)
        mobRepairRate=1e-3          % FUTURE functionality!
        chargeRate=2                % FUTURE functionality!
        dischargeRateIdle=0         % FUTURE functionality!
        EMPTY = -9999
        
        % Inventory Attributes
        maxInvSlots=10              % Max Inventory Slots in the agent
        numCapabilities=7           % Number of actions agents are programmed to do
        loc_Inventory=2             % Location of the inventory
        
        
        % Dimensionality of Interdependencies
        dimSignal_Inventory=3
        dimSignal_SubSystem=4
        num_subsys_comms=4
        
        % Misc. Constants
        fltPntErrLimit = 1e-5            % Defined floating point error limit for equality
         
    end

    methods(Access = protected)
        %% ================================================================
        %  MATLAB System Object Impl() Methods
        %  ================================================================
        %% setupImpl() Method
        function setupImpl(obj)
            obj.actSampleTime = 0;
            obj.soc = obj.lifeOfAgent;
            obj.position = 1; % Starting position at Home
            obj.mobilityHS = obj.lifeOfAgent;
            obj.Inventory = zeros(obj.maxInvSlots, 2);
        end
        %% stepImpl() Method
        function [States, CommsSubSys_Combined,doneFLAGS] = ...
                stepImpl(obj, actionID, actionParams, actionDone, actSampleTime)
            
            obj.doneFLAGS = zeros(obj.numCapabilities,1);
            obj.Comms_Inventory = zeros(obj.dimSignal_Inventory,1);
            obj.Comms_Structure = zeros(obj.dimSignal_SubSystem,1);
            obj.Comms_NPG = zeros(obj.dimSignal_SubSystem,1);
            obj.Comms_SPG = zeros(obj.dimSignal_SubSystem,1);
            obj.Comms_ECLSS = zeros(obj.dimSignal_SubSystem, 1);
            obj.actSampleTime = actSampleTime;
            
            if ~(abs(actionID-obj.EMPTY) < obj.fltPntErrLimit) ...
                    &&  ~(abs(actionID) < obj.fltPntErrLimit)
                obj.doAction(actionID, actionDone, actionParams);
            end
            
            % Output Signals from the Agent Plant
            % Agent Scalar States
            
            States = [obj.soc, obj.mobilityHS, obj.position];
            % Special Interface with Inventory
            doneFLAGS = obj.doneFLAGS;
            CommsSubSys_Combined = cat(2, ...
                                           obj.Comms_NPG, obj.Comms_SPG, ...
                                           obj.Comms_Structure, obj.Comms_ECLSS);
            
        end
        %% resetImpl() Method
        function resetImpl(~)
            % Initialize / reset discrete-state properties
        end
        %% isOutputFixedSizeImpl()
        function [f1,f2,f3] = isOutputFixedSizeImpl(~)
            f1=true;
            f2=true;
            f3=true;
        end
        %% getOutputSizeImpl()
        function [s1,s2,s3] = getOutputSizeImpl(obj)
            s1 = [1 3];
            s2 = [obj.dimSignal_SubSystem obj.num_subsys_comms];
            s3 = [obj.numCapabilities 1];
        end
        %% getOutputDataTypeImpl()
        function [d1,d2,d3] = getOutputDataTypeImpl(~)
            d1 = 'double';
            d2 = 'double';
            d3 = 'double';
        end
        %% isOutputComplexImpl()
        function [c1,c2,c3] = isOutputComplexImpl(~)
            c1 = false;
            c2 = false;
            c3 = false;
        end
        %% ================================================================
        %  Ability Methods of the Agent
        %  ================================================================
        %% doAction() Ability
        function doAction(obj, actionID, actionDone, actionParams)
            % Switch cases for all Agent abilities
            actID = cast(actionID, 'int32');
            switch actID
                case {1, 2} % interactWithInventory
                    obj.interactWithInventory(actID, actionDone, actionParams);
                case 3      % mobility ability
                    obj.moveAgent(actionDone, actionParams);
                case {4, 5, 6, 7, 8} % Repair Intervention Actions
                    obj.doInterventiveActions(actID, actionDone, actionParams);
                otherwise
                    disp("Agent Action not found in doAction() switch-cases!\n");
                    disp(actID);
            end
        end
        %% Switch cases for interacting with inventory
        function interactWithInventory(obj, invActId, actionDone, actionParams)
            % Defined behavior for interacting with Inventory
            switch invActId
                case 1 % pickItem
                    obj.pickItem(actionDone, actionParams);
                case 2 % putItem
                    obj.putItem(actionDone, actionParams);
            end
        end
        %% Abilities to interact with Inventory :: pickItem() (Action ID 1)
        function pickItem(obj, actionDone, actionParams)
            % Update continuous states
            obj.updateSOC(1);
            if actionDone % assuming that agent is always successful
                % Update discrete states
                itemID = actionParams(1);
                numItem = actionParams(2);
                obj.updateAgentInventory(1, itemID, numItem);
                obj.doneFLAGS(1) = 1;
            end      
        end
        %% Abilities to interact with Inventory :: putItem() (Action ID 2)
        function putItem(obj, actionDone, actionParams)
            % Update continuous states
            obj.updateSOC(1);
            if actionDone % assuming that agent is always successful
                % Update discrete states
                itemID = actionParams(1);
                numItem = actionParams(2);
                obj.updateAgentInventory(2, itemID, numItem);
                obj.doneFLAGS(2) = 1;
            end
        end
        %% Switch cases for Repair Interventive actions for the agents
        function doInterventiveActions(obj, intActId, actionDone, actionParams)
           % Defined interventive actions for thee agent
           switch intActId
               case 4 % repair NuclearPowerGenerator
                   obj.repairNuclearPowerGen(actionDone, actionParams);
               case 5 % repairSolarPoweGenerator
                   obj.repairSolarPowerGen(actionDone, actionParams);
               case 6 % repairStructure
                   obj.repairStructure(actionDone, actionParams);
               case 7 % repairECLSS
                   obj.repairECLSS(actionDone, actionParams);
           end
        end
        %% ActionID 3 :: moveAgent() Ability
        function moveAgent(obj, actionDone, actionParams)
            % Update continuous states
            obj.updateSOC(1);
            obj.updateMobilityHS(1);
            if actionDone % assuming that agent is always successful
                % Update discrete states
                % change the position of the robot
                obj.position = actionParams(1);
                obj.doneFLAGS(3)=1;
            end
        end
        %% ActionID 4 :: repairNuclearPowerGen()
        function repairNuclearPowerGen(obj, actionDone, actionParams)
            % Update Continuous States
            % State Parameterization            
            obj.updateSOC(1);
            % obj.updateMobilityHS(1);
            failure_mode = actionParams(1);
            repairRate = actionParams(2);
            
            obj.Comms_NPG = [failure_mode, 0, obj.actSampleTime, repairRate]';
            if actionDone
                % Update Discrete States
                obj.Comms_NPG(2) = 1;
                obj.doneFLAGS(4)=1;
            end
        end
        %% ActionID 5 :: repairSolarPowerGen()
        function repairSolarPowerGen(obj, actionDone, actionParams)
            % Update Continuous States
            % State Parameterization
            obj.updateSOC(1);
            % obj.updateMobilityHS(1);
            failure_mode = actionParams(1);
            repairRate = actionParams(2);
            obj.Comms_SPG = [failure_mode, 0, obj.actSampleTime, repairRate]'; % sending out `1`
            if actionDone
                % Update Discrete States
                obj.Comms_SPG(2) = 1;
                obj.doneFLAGS(5)=1;
            end 
        end
        %% ActionID 6 :: repairStructurePanel()
        function repairStructure(obj, actionDone, actionParams)
           % Update continuous states
           % State parameterization
           obj.updateSOC(1);
           % obj.updateMobilityHS(1);
           failure_mode = actionParams(1);
           repairRate = actionParams(2);
           obj.Comms_Structure = [failure_mode, 0, obj.actSampleTime, repairRate]';
           if actionDone
               % Update discrete states
               obj.Comms_Structure(2) = 1;
               obj.doneFLAGS(6)=1;
           end
        end
        %% Action ID 7 :: repairECLSS()
        function repairECLSS(obj, actionDone, actionParams)
           % Update continuous states
           % State parameterization
           obj.updateSOC(1);
           % obj.updateMobilityHS(1);
           failure_mode = actionParams(1);
           repairRate = actionParams(2);
           obj.Comms_ECLSS = [failure_mode, 0, obj.actSampleTime, repairRate]';
           if actionDone
               % Update discrete states
               obj.Comms_ECLSS(2) = 1;
               obj.doneFLAGS(7)=1;
           end
        end
    end
    
    methods (Access = protected)
        %% ================================================================
        %  State Update Methods of the Agent
        %  ================================================================
        %% updateSOC() method of the Agent
        function updateSOC(obj, SOCMode)
            SOCMode = cast(SOCMode, 'int32');
            switch SOCMode
                case 1 % Discharge
                    obj.soc = obj.soc + obj.dischargeRate * obj.dt;
                case 2 % Charge Rate
                    obj.soc = obj.soc + obj.chargeRate * obj.dt;
                otherwise % IDLE Discharge
                    obj.soc = obj.soc + obj.dischargeRateIdle * obj.dt;
            end
        end
        %% updateMobilityHS() method of the Agent
        function updateMobilityHS(obj, MobHSMode)
            MobHSMode = cast(MobHSMode, 'int32');
            switch MobHSMode
                case 1 % Deterioration
                    obj.mobilityHS = obj.mobilityHS + obj.mobDamageRate * obj.dt;
                case 2 % Reparation
                    obj.mobilityHS = obj.mobilityHS + obj.mobRepairRate * obj.dt;
                otherwise
                    obj.mobilityHS = obj.mobilityHS;
            end
        end
        %% updateAgentInventory() method of the Agent
        function invChange = updateAgentInventory(obj, invMode, itemID, numItem)
            % Updating Agent Inventory depends on atLoc
            invChange=0;
            if obj.inPosition(obj.loc_Inventory) % Checking if Agent is in position
                switch invMode % Change Agent Inventory according to `invMode`
                    case 1 % Add to Agent Inventory
                        obj.addToAgentInventory(itemID, numItem);
                        invChange=1;
                    case 2 % Remove from Agent Inventory
                        obj.removeFromAgentInventory(itemID, numItem);
                        invChange=1;
                    otherwise
                        fprintf("updateAgentInventory(): Invalid Inventory Action!\n");
                end
            else % not in position
                fprintf("updateAgentInventory(): Not in the right `atLoc`!\n");
            end
        end
        %% addToAgentInventory()
        function addToAgentInventory(obj, itemID, numItem)
            % Agent Inventory Addition Operation
            % Check if inventory has the item ID
            itemIdx = find(obj.Inventory(:,1)==itemID,1,'first');
            % sum(itemIdx) is zero or non-zero
            % if zero -> item not in obj.inventory
            % if !zero -> item in obj.inventory
            if ~sum(itemIdx)
                % Agent Inventory does not have Item
                emptyIdx = find(obj.Inventory(:,1)==0,1,'first');
                % sum(emptyIdx) is zero or non-zero
                % if zero -> no empty space in inventory obj.inventory
                % if !zero -> empty space in obj.inventory
                if sum(emptyIdx)
                    % There is space in Agent Inventory
%                     obj.Inventory(emptyIdx,:)= [itemID, numItem];
                    obj.Inventory(emptyIdx,1)= itemID; obj.Inventory(emptyIdx,2)= itemID;
                    fprintf("addToAgentInventory(): Successfully added `new` item to Agent Inventory!\n");
                    fprintf("Item Added: %g, NumItem Added: %g\n", itemID, numItem);
                    obj.Comms_Inventory = [1, itemID, numItem]';
                else
                    % There is no space in Agent Inventory
                    fprintf("addToAgentInventory(): Agent Inventory is full!\n");
                end
            else
                % Agent Inventory already has the Item ID
                obj.Inventory(itemIdx,2) = obj.Inventory(itemIdx,2) + numItem;
                fprintf("addToAgentInventory(): Successfully updated item to Agent Inventory!\n");
                fprintf("Item Added: %g, NumItem Added: %g\n", itemID, numItem);
                obj.Comms_Inventory = [1, itemID, numItem]';
            end
        end
        %% removeFromAgentInventory()
        function removeFromAgentInventory(obj, itemID, numItem)
            itemIdx = find(obj.Inventory(:,1)==itemID,1,'first');
            % sum(itemIdx) is zero or non-zero
            % if zero -> itemIdx found in obj.Inventory
            % if non-zero -> itemIdx not found in obj.Inventory
            
            if sum(itemIdx) % Checking if itemIdx is there in Agetn Inventory
                obj.Inventory(itemIdx,2)= obj.Inventory(itemIdx,2) - numItem;
                if obj.Inventory(itemIdx,2) == 0 % If all removed, empty inventory
                   obj.Inventory(itemIdx,1) = 0;
                end
                fprintf("removeFromAgentInventory(): Successfully remove from Agent Inventory!\n");
                obj.Comms_Inventory = [2, itemID, numItem]';
            else
                fprintf("removeFromAgentInventory(): ItemID not found in Agent Inventory!\n");
            end
        end
        %% ================================================================
        %  State Check Methods of the Agent
        %  ================================================================
        %% inPosition() method of the Agent
        function ch = inPosition(obj, location)
            ch = (obj.position == location);
            if ch
                fprintf("inPosition(): Agent is in Position %g!\n", obj.position);
            else
                fprintf("inPosition(): Agent is not in Position!\n");
                fprintf("Agent Position: %g, Requested Location: %g\n", obj.position, location);
            end
        end
    end
end

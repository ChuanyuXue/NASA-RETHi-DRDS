classdef NewPlantModel < matlab.System
%         Plant model of the health-states and interdependenncies of the
%         agent model
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
%                   - Nuclear PG for repair (removal of dust ono radiator panels)
%               - Supports the definition of the following health states
%                   - State of charge of the agent
%                   - Mobility health states of the agent

    properties (Nontunable)
        dt=0.1
        dischargeRate=-1e-4
        mobDmgRate=-1e-4
        lifeOfAgent=1e4
    end
    
    properties (Access=protected)
       soc
       mobilityHS
       position = 1
       
       comms_inventory;
       comms_structure;
       comms_eclss;
       comms_power;
       comms_pwr_spg;
       comms_pwr_npg; % ?? Check if we actually need this
       
       % EMPTY Definitions
       EMPTY_META
       EMPTY_TODO
    end

    % Pre-computed constants
    properties(Nontunable, Access = protected)
        EMPTY = -9999
        
        dim_comms_subSystem = 4;        % [active, failureMode, repairTime, repairRate]
        dim_comms_Inventory = 3;
        fltPntErrLimit = 1e-5;          % Floating point error limit for equality
        
    end

    methods(Access = protected)
    %% ================================================================
    %  MATLAB System Object Impl() Methods
    %  ================================================================
        function setupImpl(obj)
            % Perform one-time calculations, such as computing constants
            obj.soc = obj.lifeOfAgent;
            obj.mobilityHS = obj.lifeOfAgent;
        end

        function y = stepImpl(obj,u)
            % Implement algorithm. Calculate y as a function of input u and
            % discrete states.
            y = u;
            obj.comms_structure = zeros(obj.dim_comms_subSystem, 1);
            obj.comms_eclss = zeros(obj.dim_comms_subSystem, 1);
            obj.comms_power = zeros(obj.dim_comms_subSystem, 1);
            
            if ~(abs(actionID-self.EMPTY) < self.fltPntErrLimit) ...
                    &&  ~(abs(actionID) <= 0)
                self.doAction(actionID, actionDone, actionParams);
            end
        end

        function resetImpl(obj)
            % Initialize / reset discrete-state properties
        end
    end
end

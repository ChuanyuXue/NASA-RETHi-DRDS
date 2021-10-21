classdef LinearMemoryModule < matlab.System ...
        & matlab.system.mixin.Propagates
%         Linear Memory Buffer of the Agent
%         #=================================================#
%         #    Code developed for the RETH-Institute        #
%         #    By: Murali Krishnan Rajasekharan Pillai      #
%         #    PhD Student @ Purdue University              #
%         #    Funded by: NASA                              #
%         #    Last Modified: July 29, 2021                 #
%         #=================================================#
%         Purpose: Enables the agent model to store multiple
%         intervention commands in the memory. This implementation is that 
%         of a linear memory buffer. 
%
%         MCVT Report Section: Section 5.2.1
%
%         Version details:
%           - Previuos versions: Prototype modules
%           - Version 5:
%               - Modularized code using MATLAB System Block
%               - Linear memory buffer implementation
%                    - Search complexity - O(n)
%                    - Insertion complexity - O(n)
%                    - Push/Pop comoplexity - O(1)
%     
%         Input Arguments:
%         ----------------
%         C2Signal          :   2-d float array 
%                               The C2 Signal from the communication network
%         currAcvtDone      :   float
%                               Flag confirming the completion of first
%                               command in memory (todoList(1,:))
%         
%         Output Arguments:
%         -----------------
%         currPgm               :   2-d float array
%                               todoList(1,:,:) First element of the todoList
%         filledMemSlots        :   float
%                               Number of valid scheduled activities in the
%                               agent memory
%         activityIDs           : 1-d float array
%                               All activity IDs present in the agent
%                               memory
%         currAcvtID            : float
%                               Activity ID being currently performed by
%                               the agent
%         Attributes:
%         -----------
%         maxMemorySlots    :   float
%                               Max. number of activity commands stored
%                               in agent memory
%         numMaxActions     :   float
%                               Max. number of actions in a valid activity
%                               command
%         numMaxActionParams:   float
%                               Max. number of action parameters
%         todoList          :   2-d float array       
%                               The activities to be performed in sequence
%         nTodoList         :   float
%                               The number of valid activities in `todoList`
%         
%         EMPTY             :   float
%                               Pre-defined constant to denote invalid
%                               commands
    
    properties (Nontunable)
        maxMemorySlots=5;         % Max size of the memory buffer
        numMaxActions=3;          % Max Actions in the coded commands
        numMaxActionParams=4;    % Max Action Params in coded commands
    end
    
    properties (Access = protected)
        todoList
        nTodoList=0;
        ActivityIDs;
    end

    % Pre-computed constants
    properties(Access = private)
        EMPTY = -9999
    end

    methods(Access = protected)
        %% ================================================================
        %  MATLAB System Object Impl() Methods
        %  ================================================================
        %% setupImpl()
        function setupImpl(obj)
            % Perform one-time calculations, such as computing constants
            obj.todoList = obj.EMPTY * ones(obj.maxMemorySlots,...
                obj.numMaxActions+1, obj.numMaxActionParams);
            obj.ActivityIDs = -1 * ones(obj.maxMemorySlots, 1);
        end 
        %% stepImpl()
        function [currPgm, filledMemSlots, activityIDs, currAcvtID] = stepImpl(obj, C2Signal, currAcvtDone)
            % stepImpl() method for MATLAB System Object 
            % Check for Adding Signal to Memory
            if (C2Signal(1) ~= obj.EMPTY) && (C2Signal(1) > 0)
                [FLAG_MemoryFull] = obj.isMemoryFull();
                if (~FLAG_MemoryFull)
                    fprintf("        MemModule: A valid command, entering to MEMORY!\n");
                    obj.pushToMemory(C2Signal);
                    obj.nTodoList = obj.nTodoList + 1;
                elseif (FLAG_MemoryFull)
                    fprintf("        MemModule: Memory is full, activity is IGNORED!\n");
                end      
            end
            
            % If Activity is done, Pop 1st element of todoList
            if (currAcvtDone)
                obj.popFromMemory();
                obj.nTodoList = obj.nTodoList - 1;
            end
            
            % CURR_TODO is first element of MEMORY
            currPgm = squeeze(obj.todoList(1,:,:));
            filledMemSlots = obj.nTodoList;
            for i=1:obj.maxMemorySlots
                entry = max(obj.todoList(i,1,1), -1); % Activity IDs
                obj.ActivityIDs(i,1) = entry;
            end
            activityIDs = obj.ActivityIDs;
            currAcvtID = obj.ActivityIDs(1);
        end
        %% resetImpl()
        function resetImpl(~)
            % Initialize / reset discrete-state properties
        end
        %% isOutputFixedSizeImpl()
        function [f1, f2, f3, f4] = isOutputFixedSizeImpl(~)
            f1=true;
            f2=true;
            f3=true;
            f4=true;
        end
        %% getOutputSizeImpl()
        function [s1, s2, s3, s4] = getOutputSizeImpl(obj)
            s1 = [obj.numMaxActions+1 obj.numMaxActionParams];
            s2 = [1 1];
            s3 = [obj.maxMemorySlots, 1];
            s4 = [1 1];
        end
        %% getOutputDataTypeImpl()
        function [d1, d2, d3, d4] = getOutputDataTypeImpl(~)
            d1 = 'double';
            d2 = 'double';
            d3 = 'double';
            d4 = 'double';
        end
        %% isOutputComplexImpl()
        function [c1, c2, c3, c4] = isOutputComplexImpl(~)
            c1=false;
            c2=false;
            c3=false;
            c4=false;
        end
    end
    
    methods (Access=private)
        %% ================================================================
        %  Memory manipulation Operations
        %  ================================================================
        %% isMemoryFull()
        function [FLAG_MemoryFull] = isMemoryFull(obj)
            % Check if the Agent Memory is Full
            numActivityInMemory = 0;
            
            for i=1:obj.maxMemorySlots
                if obj.todoList(i) ~= obj.EMPTY
                    numActivityInMemory = numActivityInMemory + 1;
                end
            end
            FLAG_MemoryFull = (numActivityInMemory == obj.maxMemorySlots);
        end
        %% pushToMemory()
        function pushToMemory(obj, TODO_VECTOR)
            % Add TODO_COMMAND to Memory

            TODO_MATRIX = reshape(TODO_VECTOR, ...
                1,obj.numMaxActions+1, obj.numMaxActionParams);            
            
            % find the first non `EMPTY` field and add valid activity
            % command
            idx = find(obj.todoList(:,1,1)==obj.EMPTY, 1, 'first');
            for i=1:obj.numMaxActions+1
                for j=1:obj.numMaxActionParams
                    obj.todoList(idx,i,j) = TODO_MATRIX(1,i,j);
                end
            end
        end
        %% popFromMemory()
        function popFromMemory(obj)
            % Pop the first activity from TODO List
            obj.todoList(1:end-1,:,:) = obj.todoList(2:end,:,:);
            obj.todoList(end,:,:) = obj.EMPTY * ones(1,...
                obj.numMaxActions+1, obj.numMaxActionParams);
        end
    end
end

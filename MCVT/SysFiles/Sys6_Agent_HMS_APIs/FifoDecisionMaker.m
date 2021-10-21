classdef FifoDecisionMaker < matlab.System
%         FIFO Decision Maker to replace the HMS applications
%         #=================================================#
%         #    Code developed for the RETH-Institute        #
%         #    By: Murali Krishnan Rajasekharan Pillai      #
%         #    PhD Student @ Purdue University              #
%         #    Funded by: NASA                              #
%         #    Last Modified: August 19, 2021               #
%         #=================================================#
%         Purpose: Defines the dynamics of the agent health states as the
%         agent executes activities preseent in it's memory.
%
%

    % Public, tunable properties
    properties (Nontunable)
        acvtLookupTable
        isAcvtActive
        test_thresholds
        test_modes
    end

    % Pre-computed constants
    properties(Access = protected)
        dMatrix
        test_results
        scheduledAcvtsArray

    end
    
    properties(Constant, Access=protected)

        numTests = 3;
        
        
        size_scheduledAcvtsArray = 10;
        maxConcurrentFaults = 5;
        
        % Definitions of various tests
        LT      = 1;                    % Less-than operator
        LEQ     = 2;                    % Less-than-equal-to operator
        GT      = 3;                    % Greater-than operator
        GEQ     = 4;                    % Greater-than-equal-to operator
        EQ      = 5;                    % Equal-to operator
        NEQ     = 6;                    % Not-equal-to operator
        STR     = 7;                    % Structure Check operator
        
        % Intervention Activity IDs Mappings
        Empty               = -9999;    % Empty Program ID
        Repair_NPG          = 1;        % Repair NPG Activity ID
        Repair_SPG          = 2;        % Repair SPG Activity ID
        Repair_Structure    = 3;        % Repair Structure Activiity ID
        Repair_ECLSS_Dust   = 4;        % Repair ECLSS Dust Activity ID
        Repair_ECLSS_Paint  = 5;        % Repair ECLSS Paint Activity ID
        
        % Compute specific constant
        fltPntError = 1e-5;
        TRUE = 1;
        FALSE = 0;
    end

    methods(Access = protected)
        function setupImpl(obj)
            obj.dMatrix =   eye(5, 1);
            obj.test_results = zeros(5, 1);
            obj.scheduledAcvtsArray = obj.Empty * ones(obj.size_scheduledAcvtsArray, 1);
        end

        function [test_results, scheduled, suggested] = stepImpl(obj, acvtIds_inMemory, test_inputs)
            % Perform tests with the `test_inputs`
            obj.checkIfUnhealthyTests(test_inputs);
            
            % Update the todoList
            obj.updateTodoList(acvtIds_inMemory);
            
            % get currrent suggested activity
            suggested = obj.getSuggestedActivity();
            
            scheduled = obj.scheduledAcvtsArray;
            test_results = obj.test_results;
            
            % Need a sanity check post all schedule
        end

        function resetImpl(obj)
            % Initialize / reset discrete-state properties
        end
    end
    
    methods(Access = private)
        function suggested = getSuggestedActivity(obj)
           suggested = obj.scheduledAcvtsArray(1);
           if suggested ~= obj.Empty
               obj.scheduledAcvtsArray(1:end-1) = obj.scheduledAcvtsArray(2:end);
           end
           
        end
        %% areAcvtsScheduled()
        function updateTodoList(obj, acvtIds_inMemory)
           %  Add the activity ID to `todoList`, if:
           % 1. The mode is `unhealthy` or the `UnhealthyChecks` passes
           % 2. `activityId` is not in memory
           for i=1:obj.numTests
               if abs(obj.test_results(i)-obj.TRUE) < obj.fltPntError
                   % Test implies "Unhealthy"
                   
                   inMem = ismember(i, acvtIds_inMemory);
                   inSchedule = ismember(i, obj.scheduledAcvtsArray);
                   isActive = abs(obj.isAcvtActive(i) - 1) < obj.fltPntError;  
                   if ~inMem && ~inSchedule && isActive
                       % particular Global failure mode is not in memory or
                       % in the current scheduled activity array and the
                       % intervention is active
                       obj.addToSchedule(i);
                   end
               end
           end
        end
        %% addTodo()
        function addToSchedule(obj, acvtId)
            
            idx = find(obj.scheduledAcvtsArray==obj.Empty, 1, 'first');
            obj.scheduledAcvtsArray(idx) = acvtId;
            
        end
        %% doTests()
        function checkIfUnhealthyTests(obj, test_inputs)
            % Perform pre-defined tests to check if Unhealthy or not
            % Assumption: Activity Lookup ID's corresponnd to the test
            % numbers
            % Which tests are flagged or not?
            % Test 1 : Is Nuclear PG radiator filled with dust? [input > threshold]
            % Test 2 : Is Solar PG panel filled with dust? [input > threshold]
            % Test 3 : Is the Structure damaged? [input ~= threshold]
            % Test 4 : Is the ECLSS radiator panel filled with dust? [input > threshold]
            % Test 5 : Is there paint damage on the ECLSS radiator panel? [input > threshold]
            for ii=1:obj.numTests
                obj.doTest(ii, test_inputs(ii), obj.test_modes(ii));
            end
            
        end
        %% quickTest()
        function doTest(obj, idx, input, mode)
            %   Method for checking which failure modes have been triggered
            %   Modified FDD outputs are compared using pre-defined rules 
            %   against user-specified thresholds to determine if a failure
            %   mode is active or not (un-healthy / healthy)
            %   thresholds to 
           threshold = obj.test_thresholds(idx);           
           switch mode
               case obj.LT
                   obj.test_results(idx) = input < threshold;
               case obj.LEQ
                   obj.test_results(idx) = input <= threshold;
               case obj.GT
                   obj.test_results(idx) = input > threshold;
               case obj.GEQ
                   obj.test_results(idx) = input >= threshold;
               case obj.EQ
                   obj.test_results(idx) = input == threshold;
               case obj.NEQ
                   obj.test_results(idx) = input ~= threshold;
               case obj.STR
                   obj.test_results(idx) = ((input ~= threshold) && (input > 0));
               otherwise
                   error("Invalid test option in `perform_tests`!!");
           end
        end
    end
end
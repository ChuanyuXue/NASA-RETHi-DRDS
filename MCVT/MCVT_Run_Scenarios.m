%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                  MCVT v1.5 Run Scenarios File
%                        Date: 9/7/2021
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MCVT - version 1.5: Integrated Simulation
% MCVT Systems: 
% Structural, Power, ECLSS, Inter ior Env., Exterior Env., Agent & HMS
% Collaborators: Purdue Univ., UConn, UTSA, Harvard Univ.

%%% NOTE: For model description and further details, refer to the User Manual.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Requirements:
% 1) MATLAB R2020a or newer version
% 2)Compiler:
%     In Command Window run: mex -setup
%     If no compiler found, install a compiler as follows:
%     On the MATLAB Home tab, in the Environment section, click Add-Ons > Get Add-Ons.
%     Search for MinGW
%     Install MinGW

clear all; close all; clc; warning off;

%% LOAD INPUT FILES AND SIMULATION PARAMETERS

MCVT_Input_File                             % Run Input File
MCVT_Habitat_Design_Input_File              % Run Habitat Design Input File
MCVT_Sim_Set                                % Run Simulation Settings File

if run_mode == "user"
    %% RUN MCVT
    fprintf('-[5/6] MCVT Simulation in Progress...\n');
    tic
    simout = sim('MCVT_Integration','SimulationMode','normal');
    elapsedTime(4) = toc;
    disp(['        ### MCVT Simulation Completed (' num2str(elapsedTime(4)) ' sec)']);

    %% Save Data and Plot Results
    MCVT_Plot_Data % save data in output folder and plot data
    disp(['-[6/6] Output Files Saved in ' Output_Folder])
end


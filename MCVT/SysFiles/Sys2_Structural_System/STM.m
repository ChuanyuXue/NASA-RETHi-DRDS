classdef STM < matlab.System
        
        
%% Documentation
% Purpose: To determine the temperatures at different points of the
%          Structural Habitat Structures. For more details, please look
%          into the Chapter 2.2 of the documentation report.
%         
% Date Created: 20 September 2020
% Date Last Modified: 23 July 2021
% Modeler Name: Sachin Tripathi (UConn)
% Funding Acknowledgement: Funded by the NASA RETHi Project

% Version Number: MCVT v4

% Subsystem Connections: 
    %Inputs: Subsystems 2 (2.1: SMM), 8 (HIEM), 9(External Environment) ;
    %Outputs: Subsystems 2 (2.1: SMM), and 8 (HIEM);

% Function Dependencies: (stored in SysFiles>Subs2)
%   - T_STM_initialize.m

% No Data Dependencies

 %% Property Attributes
% Specifying attributes in the class definition enables you to customize the
% behavior of properties for specific purposes. Control characteristics like
% access, data storage, and visibility of properties by setting attributes.
% Subclasses do not inherit superclass member attributes.%

    %Default attribute is: Public which means public can read and write
    %acess. 
    
    properties 
%The properties mentioned inside it are public and they read the
%corresponding values from the base workspace. 


        %Regolith Material Properties%
        
            emis_reg;    %Emissivity of regolith, unitless
            abs_reg;     %Absorptivity of regolith, unitless
            sigma;       %Stefan-Boltzmann Constant, W/(m^2.K^4)
            rho_reg;     %Density of regolith, kg/(m^3)
            k_reg;       %Thermal conductivity of regolith, W/(m.K)
            c_reg;       %Specific Heat of regolith, J/(kg.K)

            Tspace;       %Cosmic Background Temperature, K
            
            initial_temperature; %Initial Temperature of the HIEM system, K
    
            
       % Set Material Properties, Concrete  
                            
             emis_con;     %Emissivity of concrete, unitless
             abs_con;      %Absorptivity of concrete, unitless  
             rho_con;      %Density of concrete, kg/m^3
             k_con;        %Thermal conductivity of concrete, W/(m.K)
             c_con;        %Specific Heat of concrete, J/(kg.K)
                
             h;            %Convective Coefficient, W/(m^2.K)
             
            %Habitat Design Parameters% 
             
            R;        %Inner radius of the structural dome, m
            d;        %Thickness of the dome, m
            d_SPL;    %Thickness of the SPL, m
             
           %Initial Conditions and Boundary Conditions%
           
            Trepair;        %Initial Temperature of the habitat when the element has been repaired, K            
            Tfoundation;    %Temperature of the lunar foundation which acts as a boundary condition, K
            
        
        
    end

    properties(DiscreteState)
    end

    
 % Pre-computed constants
    properties(Nontunable,Access=private) %Adding properties and (Nontunable) attribute allows users not to access those properties%

%Access Modifier,"Private", allows access from class methods only (not from
%subclass). Since we are not using any subclasses here, we can use it.
%In case, we have subclasses, our access modifier should be "protected"
%"Nontunable" attribute to the property when the algorithm depends on the
%value being constant once the data processing starts. 
        
        %Model Specific Variables: These Parameters
        %variables specific to model 
        % Model Parameters
            nph=10;       % Number of elements in Φ direction
            nth=6;        % Number of elements in Θ direction
            nnp=60;       %Total number of elements in one layer%
            totelem=180;  %Total number of elements%

            n_d=3;        %Division number of the thickness% 
            total_azimuth_angle=360; %Total azimuthal angle of the dome habitat, °%
            total_polar_angle=90; %Total polar angle of the dome habitat, °%
            
    end
    
    % Pre-computed constants
    properties(Access = private) %Adding properties and (Access=Private) attribute allows users not to access those properties%

        
          
            dphi;           %Circumferential angle of one differential element, degrees(°)%
            dtheta;         %Differential angle in the theta direction, degrees(°)%
            dphi_r;         %Circumferential angle of one differential element, radian%
            dtheta_r;       %Differential angle in the theta direction,, radian%
            m;              %Thickness of the Boundary elements, m%
            m1;             %Half the Thickness of each layer of the Regolith, m% 
            n;              %Distance between the nodes or thickness of interior elements(=2m), m%
            dr;             %Thickness Division vector, m%
            r1;             %Distance from the orign to the  first (innermost/interface) node, m%
            r2;             %Distance from the orign to the  second node, m%
            r3;             %Distance from the orign to the  third node, m%
            r;              %Distance vector of the nodes from the center, m%
            tot_cells;      %Total number of cells in one layer%
            position_info;  %Matrix of size (:,3)in which each column are r,Θ, and Φ values of elements respectively%
            x_par;          %Vector of X-coordinate of the differential elements in parent coordinate system%
            y_par;          %Vector of Y-coordinate of the differential elements in parent coordinate system%
            z_par;          %Vector of Z-coordinate of the differential elements in parent coordinate system%
            xyz_par_r1;     %Matrix of first (innermost) layer with the global s/s based upon the parent axes%
            xyz_par_r2;     %Matrix of second layer with the global s/s based upon the parent axes%
            xyz_par_r3;     %Matrix of third (top) layer with the global s/s based upon the parent axes%
            xyz_par;        %XYZ-coordinates of the differential elements in parent coordinate system%
            x_STM;          %Matrix of X coordinates of all three layers in Global s/s, size of 10×6×3%
            y_STM;          %Matrix of Y coordinates of all three layers in Global s/s, size of 10×6×3%
            z_STM;          %Matrix of Z coordinates of all three layers in Global s/s, size of 10×6×3%
            xyz_STM_r1;     %Matrix (XYZ coordinates)of innermost (first) layer Global s/s, size 60×3%
            xyz_STM_r2;     %Matrix (XYZ coordinates)of second layer in Global s/s, size 60×3%
            xyz_STM_r3;     %Matrix (XYZ coordinates)of third (interface with SPL) layer Global s/s, size 60×3%
            xyz_STM;        %Matrix (XYZ coordinates)of all three layers in Global s/s, size 60×3×3%
            STMxyz;         %Matrix (XYZ coordinates)of all nodes in Global s/s, size 180×3%
            STMregxyz;      %Universal Cartesian Coordinates of SPL outer layer %
            theta_cell_tot; %Three Dimensional Matrix with the Θ values of all elements%
            phi_cell_tot;   %Three Dimensional Matrix with the Φ values of all elements%
            rad_cell_1;     %Two Dimensional Matrix with the radius values of elements from innermost (third) layer%
            rad_cell_2;     %Two Dimensional Matrix with the radius values of elements from second layer%
            rad_cell_3;     %Two Dimensional Matrix with the radius values of elements from third (top) layer%
            rad_cell_tot;   %Three Dimensional Matrix with the radius values of all elements%
            theta_mat;      %Vector of Θ's corresponding to one layer%
            phi_mat;        %Vector of Φ's corresponding to one layer%
            rad_mat;        %Vector of radius of nodes of all three layers%
            dr_interface;   %Distance between nodes of STM and SPL bottom layer node, m%
            phi;            %Vector of Φ angles of differential elements, degrees (°)%
            theta;          %Vector of Θ angles of differential elements, degrees (°)%
            dAn;            %Surface area of the differential element normal to radius, m^2%
            dAn_interface;  %Surface area normal to radius for the interface between SPL and STM, m^2%
            dAth;           %Surface area of differential elements normal to the Θ, m^2%
            dAphi;          %Surface area of differential elements normal to the Φ, m^2%
            theta_cell;     %Matrix of Θ's corresponding to one layer, size 10×6%
            dc_phi_cell;    %Matrix of Φ's corresponding to one layer%
            phi_cell;       %Matrix of Φ's corresponding to one layer%
            tot_cell;       %Total number of cells in one layer%
            dAth_comp1;     %First component of dAth%
            dAth_comp2;     %Second component of dAth%
            dAth_r1;        %Differential area normal to the 'Θ' direction of the third layer elements, m^2%
            dAth_r2;        %Differential area normal to the 'Θ' direction of the second layer elements, m^2%
            dAth_r3;        %Differential area normal to the 'Θ' direction of the first layer elements, m^2%
            mapST2SM;       %Variable used to map from STM to SMM%

            SMMxyz;         %XYZ coordinates, size (:,3), of Gauss Points (GP) from SMM%
            SMM_Nodexyz;    %XYZ coordinates, size (:,3), of nodes from SMM%
    

            SRxyz;          %Cartesian coordinates of SR nodes SR of  size (:,3)%
            
            Num;            %Vector of numbering of STM differential elements, size 1×180%
            NumSTMmat;      %Matrix of numbering of SPL differential elements, size 10×6%
                        
            dAn_outer;      %Surface area of the differential element normal to the interface with SPL, m^2%
            
                        
            
        % State Variables
            T;              %Temperature matrix in each time step, K%

    end

    methods(Access = protected) 
        %Methods takes the values of the properties of one-time calculation
        %that we mentioned in the properties() aforementioned
        %Syntax%
        %methods
%       function obj = ClassName(arg1,...)
%          obj.PropertyName = arg1;
%          ...
%       end
%       function ordinaryMethod(obj,arg1,...)
%          ...
%       end
%    end

%The setupImpl method sets up the object and implements one-time initialization tasks%

% For setupImpl and all Impl methods, you must set the method attribute Access = protected because users of the System object do not call these methods directly. Instead the back-end of the System object calls these methods through other user-facing functions.
% 

        %% ================================================================
        %  MATLAB System Object Impl() Methods
        %  ================================================================
        
        function setupImpl(ST) %%%The setupImpl method sets up the object and implements one-time initialization tasks%
            %The setupImpl method is used to perform the set up and the initialization tasks. You should include codes in the setupImpl method you 
            %want to execute one time only. The sehe setupImpl method is called once the first time you run the object.
            % Perform one-time calculations, such as computing constants
            %Use object.propertyname (i.e. ST.propertyname)while referencing class property%
            % Input File callling from the function that is present below.
            % However, we need to add the system name ie. ST in this case
            % in front of them
                [ST.SMMxyz,ST.SMM_Nodexyz]=Data; %Calling function named Data%

                    

            % Define # of points to be used
             
                ST.dphi=ST.total_azimuth_angle/ST.nph;       %Circumferential angle of one differential element, degrees(°)%
                ST.dtheta=ST.total_polar_angle/ST.nth;  %Differential angle in the theta direction, degrees(°)%
                ST.dphi_r=(pi/180)*ST.dphi; %Circumferential angle of one differential element, radian%
                ST.dtheta_r=(pi/180)*ST.dtheta; %Differential angle in the theta direction,, radian%
                

                
                
                                %% Division of the thickness
                % In this case we have decided to divide the whole thickness into 4 elements and four nodes, 2 of them being on the edges
                % and r1,r2,r3, and r4 is the distance from the origin to the center of
                % each element
                ST.m=ST.d/(2*ST.n_d-1);         %Thickness of boundary elements, m%
                ST.n=2*ST.m;                    %Distance between the nodes or thickness of interior elements, m%
                ST.dr=[ST.n;ST.n;ST.m];         %Element division, Thickness vector, m%
                ST.m1=ST.d_SPL/(2*ST.n_d-1);    %Half the Thickness of each layer of the Regolith, m%              

                
                %Creation of the distance vector from the origin to the nodes of SPL-Thermal%
                ST.r1=ST.R;                 %Distance from the orign to the  first node, m%
                ST.r2=ST.r1+ST.n;           %Distance from the orign to the second node, m%
                ST.r3=ST.r2+ST.n;           %Distance from the orign to the third node, m%
                ST.r=[ST.r1;ST.r2;ST.r3];   %Creating the distance vector, m%
                ST.dr_interface=ST.m+ST.m1;       %Distance between nodes of STM top node and SPL bottom node i.e. m+m1, m%
                

                %Determination of the coordinates of the each cells%
                ST.phi=ST.dphi/2:ST.dphi:ST.total_azimuth_angle-ST.dphi/2; %Creating a vector of phi, central point, °%
                ST.theta=ST.dtheta/2:ST.dtheta:ST.total_polar_angle-ST.dtheta/2; %Creating a vector of theta, central point, °%

                ST.theta_cell=repmat(ST.theta,length(ST.phi),1);%Creation of the theta_cell,°%
                ST.phi_cell=repmat(ST.phi',1,length(ST.theta));  %Creation of the phi_cell, °%
                
                                
                %% Create the total three dimensional matrix of theta, phi, radius for the cell
                %Theta, phi of all nodes in each layer are same and radius of all nodes for one layer is same%
                ST.theta_cell_tot=repmat(ST.theta_cell,1,1,3); %Here, this means that repeat matrix theta_cell once in dimension 1, once in dimension 2, and 4 in dimension 3, °%%
                ST.phi_cell_tot=repmat(ST.phi_cell,1,1,3); %Here, this means that repeat matrix theta_cell once in dimension 1, once in dimension 2, and 4 in dimension 3, °%%
                ST.rad_cell_1=ST.r1.*ones(length(ST.phi),length(ST.theta)); %Radius matrix for the 1st layer, interior nodes, m%
                ST.rad_cell_2=ST.r2.*ones(length(ST.phi),length(ST.theta)); %Radius matrix for the 2nd layer, m%
                ST.rad_cell_3=ST.r3.*ones(length(ST.phi),length(ST.theta)); %Radius matrix for the 3rd layer, m%
                ST.rad_cell_tot=cat(3,ST.rad_cell_1,ST.rad_cell_2,ST.rad_cell_3); %Concatenates rad_cell_1, rad_cell_2....along the dimension 3, m%

                
                %Determination of areas and relevant distances%
                %% Determination of the surface area of the differential element (correct, confirmed on 04/13/2021)
                ST.dAn=(ST.r.^2)*sind(ST.theta)*ST.dtheta_r*ST.dphi_r; %Surface area of the differential element normal to r (for the same 'Θ', this area will be same), m^2%
                ST.dAn_interface=(ST.R^2)*sind(ST.theta)*ST.dtheta_r*ST.dphi_r; %Surface area normal to radius for the interface between SPL and STM, m^2%
                ST.dAn_outer=(ST.R^2)*sind(ST.theta)*ST.dtheta_r*ST.dphi_r; %Surface area normal to outer radius, m^2%
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%for STS.dAth,edited%%%%%%
                ST.dAth_comp1=ST.r*sind(ST.theta);%First component to determine dAth%
                ST.dAth_comp2=ST.dr.*ST.dphi_r;  %Second component to determine dAth%
                ST.dAth_r1=ST.dAth_comp1(1,1:6).*ST.dAth_comp2(1); %Differential area normal to the 'Θ' direction of the first (interface) layer elements, m^2%
                ST.dAth_r2=ST.dAth_comp1(2,1:6).*ST.dAth_comp2(2); %Differential area normal to the 'Θ' direction of the second layer elements, m^2%
                ST.dAth_r3=ST.dAth_comp1(3,1:6).*ST.dAth_comp2(3); %Differential area normal to the 'Θ' direction of the third (outer) layer elements, m^2%

                ST.dAth=[ST.dAth_r1;ST.dAth_r2;ST.dAth_r3]; %3D matrix with the differential area normal to 'Θ' direction for all three layers, m^2%
%                 ST.dAth=(ST.r*sind(ST.theta)).*ST.dr.*ST.dphi_r; %Surface area of the differential element normal to theta%
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                ST.dAphi=ST.r.*ST.dr.*ST.dtheta_r; %Surface area of the differential element normal to phi, m^2%
                ST.dc_phi_cell=(ST.r*sind(ST.theta)).*ST.dphi_r; %Distance between two cells in circumference, m%

                   
             %Determination of the universal cartesian coordinates of all three layers of STM, 0716/2021%
             %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                %% Conversion of the spherical coordinates to the cartesian coordinates, r1 is the innermost layer, r2, and r3%
                %******Data arrangement*********%
%                 ST.theta_mat=reshape(ST.theta_cell,[],1); %Converting matrix to column vector%
%                 ST.phi_mat=reshape(ST.phi_cell,[],1);
%                 ST.rad_mat= ST.r3.*ones(ST.tot_cells,1); %Creating the matrix of outer cell%
%                 ST.position_info=[ST.rad_mat ST.theta_mat ST.phi_mat ]; %Creating 60by 3 matrix in which each column are radius, theta and phi value%
% 

                %% Conversion into the universal cartesian coordinates%
                %Step 1: Conversion into cartesian coordinates for the given parent coordinate i.e. SOuth=+X, and West=+Y, Height=+Z%
                ST.x_par=ST.rad_cell_tot.*sind(ST.theta_cell_tot).*cosd(ST.phi_cell_tot); %X-coordinate, parent axes, m%
                ST.y_par=ST.rad_cell_tot.*sind(ST.theta_cell_tot).*sind(ST.phi_cell_tot);  %Y-coordinate, parent axes, m%
                ST.z_par=ST.rad_cell_tot.*cosd(ST.theta_cell_tot); %Z-coordinate, parent axes, m%
                ST.xyz_par_r1=[reshape(ST.x_par(:,:,1),[],1) reshape(ST.y_par(:,:,1),[],1) reshape(ST.z_par(:,:,1),[],1) ]; %Matrix of innermost layer with the parent cartesian coordinates, size (:,3)%
                ST.xyz_par_r2=[reshape(ST.x_par(:,:,2),[],1) reshape(ST.y_par(:,:,2),[],1) reshape(ST.z_par(:,:,2),[],1) ]; %Matrix of second layer with the parent cartesian coordinates, size (:,3)%
                ST.xyz_par_r3=[reshape(ST.x_par(:,:,3),[],1) reshape(ST.y_par(:,:,3),[],1) reshape(ST.z_par(:,:,3),[],1) ]; %Matrix of third layer with the parent cartesian coordinates, size (:,3)%
                ST.xyz_par=cat(3,ST.xyz_par_r1,ST.xyz_par_r2,ST.xyz_par_r3); %Concatenates, xyz_par_r1, r2 and r3 in the third dimension, size(:,:,3)%
                
                
                % %Step 2: Conversion of cartesian coordinates from the given parent
                % %axes to the universal axes using rotation matrix, R%
                %Converting the XYZ coordinates to be consistent with SMM, updated 07/12/2021%
                ST.x_STM=-ST.y_par;
                ST.y_STM=ST.z_par;
                ST.z_STM=ST.x_par;
                ST.xyz_STM_r1=[reshape(ST.x_STM(:,:,1),[],1) reshape(ST.y_STM(:,:,1),[],1) reshape(ST.z_STM(:,:,1),[],1) ]; %Matrix of innermost layer with the universal cartesian coordinate s/s, size(:,3)%
                ST.xyz_STM_r2=[reshape(ST.x_STM(:,:,2),[],1) reshape(ST.y_STM(:,:,2),[],1) reshape(ST.z_STM(:,:,2),[],1) ]; %Matrix of second layer with the universal cartesian coordinate s/s, size(:,3)%
                ST.xyz_STM_r3=[reshape(ST.x_STM(:,:,3),[],1) reshape(ST.y_STM(:,:,3),[],1) reshape(ST.z_STM(:,:,3),[],1) ]; %Matrix of third layer with the universal cartesian coordinate s/s, size(:,3)%
                ST.STMxyz=[ST.xyz_STM_r1;ST.xyz_STM_r2;ST.xyz_STM_r3]; %Creating the single array in the third dimension, such that first 60 elements relates to the innermost layer, followed by outer respectively%        
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %Setting up the numbering of the nodes in the STM%
                ST.Num=linspace(1,size(ST.STMxyz,1),size(ST.STMxyz,1)); %Numbering the STM differential elements%
                ST.NumSTMmat=reshape(ST.Num,length(ST.phi),length(ST.theta),ST.n_d); %Converting the STM element numbering to the matrix form%

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % mapping from STM to SMM
                %Mapping should be done to send the temperature values from
                %the STM elements to the SMM elements because the mesh
                %sizes are different among each other
                ST.mapST2SM=zeros(size(ST.SMM_Nodexyz,1),1); %Initialization%    
                
                for i=1:size(ST.SMM_Nodexyz,1)
                    dxyz = ones(size(ST.STMxyz,1),1)*1e5; % initialization
                    for j=1:size(ST.STMxyz,1)
                        dxyz_ma = [ST.STMxyz(j,1:3) ; ST.SMM_Nodexyz(i,1:3)];
                        dxyz(j,1) = pdist(dxyz_ma,'euclidean');
                    end
                    [~,dd] = min(dxyz); %dd gives the index%
                    ST.mapST2SM(i,1)=ST.Num(1,dd);
                end 
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            % Intialize the state variables, initialization and the set up
            % work in done under this setupImpl() function
                    
            ST.T=ones(length(ST.phi),length(ST.theta),length(ST.r)); %Initialization of the temperature values, K%
        end

        
        %stepImpl() specifies the algorithm to execute when you run the
        %system object. The syntax is as follows: 
        %function[output1,output2,...] =stepImpl(obj,input1,input2,...)
        %end
        %TstepImpl() is called when you run the System Object. For this, 
        %you must set Access=protected in the methods
        
  function [STM2SPL,STM2HIEM,STM2SMM,T_Fir1,T_Sec2,T_Thi3,STM_Sec,Fir_STM,Sec_STM,Thi_STM,Num_Dam] = stepImpl(ST,SPL2STM1,TempHIEM2ST,Dam_SMM,Dam_SPL,Sb_tot,Index_Damage,t,dt_2, Start_angle,T_STM_initialize,Num_Dam_Prev)
            
            
             %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%            
        %%% All inputs and outputs to this function and their dimensionality are as
        %%% follows:
        %%     INPUTS        Description        Data Type     Unit       Dimension%
        %
        %  - SPL2STM1:   Temperature from         Float        (K)          10×6
        %                third layer of SPL 
        % - TempHIEM2ST: Interior Temperature   Float          (K)          10×6
        %                from HIEM model  
        %  - Dam_SMM:   Gauss Points Damage      Float      (unitless)      324×1
        %                values from SMM 
        % - Dam_SPL:   Meteorite Impact Infor-    Float      (unitless)      1×1
        %              mation from Impact Model  
        %  - Sb_tot:    Solar Radiation Values    Float      (W/m^2)        10×6
        %                from SR model    
        % - Index_Damage:  Local Element number       Integer   (unitless)      1×1
        %               damaged due to impact  
        %  - t:         Current Simulation Time   Float        (s)           1×1
        %- dt_2:      Time Step for the         Float        (s)             1×1
        %               Structural System 
        %  - Start_angle: Simulation Start Time  Integer       (°)           1×1
        %               in one lunar cycle  
        %- T_STM_initialize:Initial Temperature val- Float     (K)           10×6
        %              ues at different nodes of the
        %              STM when simulation starts
        %- Num_Dam_Prev:Number of Damaged Elem-     Integer     (unitless)    1×1
        %              from previous time step
        %              


        %%     OUTPUTS        Description        Data Type     Unit       Dimension%
        %
        % - STM2SPL:   Temperature from            Float        (K)          10×6
        %              first (interface) 
        %              layer of STM 
        % - STM2HIEM: Temperature of inner         Float        (K)        10×6
        %                wall
        % - STM2SMM: Habitat Wall Temperature      Float        (K)          10×6
        %                to SMM model
        % - T_Fir1:   Temperature Value of first   Float        (K)           1×1
        %              Layer node adjacent to 
        %              damaged element 
        % - T_Sec1:   Temperature Value of Second  Float     (K)             1×1
        %              Layer node adjacent to 
        %              damaged element   
        % - T_Thi1:   Temperature Value of third   Float       (K)           1×1
        %              Layer node adjacent to 
        %              damaged element 
        %- STM_Sec:   Temperature from            Float         (K)          10×6
        %              Second layer of STM 
        %- Fir_STM:   Temperature from            Float        (K)          60×1
        %              first layer 
        %             (interface)of STM 
        %- Sec_STM:   Temperature from            Float        (K)          60×1
        %              Second layer of STM 
        %- Thi_STM:   Temperature from            Float        (K)          60×1
        %             Third layer of STM
        %             (Inner layer) 
        %- Num_Dam: Number of Damaged Elem     Integer     (unitless)    1×1
        %              
        %                 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%       
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
          %Based upon the user input, one can start with the given provided
          %simulation start angle: 0°,45°,90°, and 135°
          %The temperature initialization is done based upon the start of
          %the second lunar cycle (as suggested by Dr. Maghareh) so the
          %we can have the thermal gradient on even at the start of the
          %simulation to make it more realistic
            %%%%Temperature Initialization%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
           if Start_angle==0 && t==0 %if the Simulation sun start angle is 0°%

               ST.T = T_STM_initialize(:,:,:,1); %From workspace%

           elseif Start_angle==45 && t==0 %if the Simulation sun start angle is 45°%


                    ST.T = T_STM_initialize(:,:,:,2); %From workspace%


               elseif Start_angle==90 && t==0 %if the Simulation sun start angle is 90°%


                    ST.T = T_STM_initialize(:,:,:,3); %From workspace%


               elseif Start_angle==135 && t==0  %if the Simulation sun start angle is 135°%



                    ST.T = T_STM_initialize(:,:,:,4); %From workspace%


           end

          %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%             
            
        %Converting the SR to the matrix form SR(l,k)%
        SR_tot=reshape(Sb_tot, length(ST.phi), length(ST.theta));  %Converting the Solar Radiation vectors values to the matrix form, °%

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        Num_Dam=length(find(Dam_SMM>0)); %Finds the length of number of damaged Gauss points%

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
          
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %Finding the row(phi) and column(theta) on the first layer (r=1) of matrix ST.NumSTMmat to find which STM element is to be damaged%
        [Row_DamElem, Col_DamElem]=find(ST.NumSTMmat(:,:,3)==Index_Damage); %Row_DamElem=Row number corresponding to the Damaged Element,Col_DamElem=Column number corresponding to the Damaged Element% 

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %Initialization%
        T2=zeros(ST.nph,ST.nth,length(ST.r)); %Initialization of temperature in matrix form, K%
        T3=zeros(ST.totelem,1); %Initialization of temperature values in vector form, K%

        T1=ST.T; %The results from the previous time step%


        %Converting the TempHIEM2ST from the vector form to the matrix form%
        TempHIEM2ST=reshape(TempHIEM2ST,length(ST.phi),length(ST.theta)); %Vector to the matrix form, K%
        % TempHIEM2ST=293.15.*ones(length(ST.phi),length(ST.theta)); %Vector to the matrix form%


        %Initialization of the components used in the calculation to determine the temperatures%
        %Each three-dimensional differential element has six sides and the the
        %energy flow per second from each of the six sides are labeled as: q1(North),
        %q2(South), q3(West),q4(East),q5(Top),q6(Bottom)

        q1=zeros(length(ST.phi),length(ST.theta),length(ST.r)); %First component of heat to the differential element, north side, W%
        q2=zeros(length(ST.phi),length(ST.theta),length(ST.r)); %Second component of heat to the differential element, south side, W%
        q3=zeros(length(ST.phi),length(ST.theta),length(ST.r)); %Third component of heat to the differential element, west side, W%
        q4=zeros(length(ST.phi),length(ST.theta),length(ST.r)); %Fourth component of heat to the differential element, east side, W%
        q5=zeros(length(ST.phi),length(ST.theta),length(ST.r)); %Fifth component of heat to the differential element, top side, W%
        q6=zeros(length(ST.phi),length(ST.theta),length(ST.r));  %Sixth component of heat to the differential element, bottom side, W%


                             %%%In this damage and repariability scenario, the damage from the
        %%%meteorite impact is considered such that the damage starts from the top
        %%%of the element
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %After repairing, resetting the temperature of the STM elements to start from 
        %Trepair with the assumption that the elements will be placed at 293.15 K


        if Num_Dam_Prev==3 && Num_Dam==2 

                T1(Row_DamElem,Col_DamElem,1)=ST.Trepair; %When one layer is repaired, it is assumed that the temperature of that element is ST.T0 or 293.15K%

        elseif Num_Dam_Prev==2 && Num_Dam==1 

                    T1(Row_DamElem,Col_DamElem,2)=ST.Trepair; %When one layer is repaired, it is assumed that the temperature of that element is ST.T0 or 293.15K%

        elseif Num_Dam_Prev==1 && Num_Dam==0 

                    T1(Row_DamElem,Col_DamElem,length(ST.r))=ST.Trepair; %When one layer is repaired, it is assumed that the temperature of that element is ST.T0 or 293.15K%


        end

       %Starting of the loop%
       %There are three loops inside it corresponding to j, k, and l:
       %j=radius part; k=theta part; l=phi part. So, these three nested loops
       %will take into each SPLT elements and determine the heat energy per
       %second (Watts) from all six sides and are named as: q1,q2,q3,q4,q5,q6
       %So, basically, this loop is determining the heat flux of all
       %elements from all sides and finally based upon that determining the
       %temperatures of all elements using the explicit-finite difference
       %elements
       for j=1:length(ST.r) %1 to number of layers (3)%

              for k=1:length(ST.theta) %1 to length of the Θ%

                     for l=1:length(ST.phi) %1 to length of Φ%



                           %Condition for the q1 part, North Side%
                           if l==length(ST.phi) %Last element in the phi direction%

                               q1(l,k,j)=ST.k_con*ST.dAphi(j)/ST.dc_phi_cell(j,k)*(T1(1,k,j)-T1(l,k,j)); %Heat energy towards the differential element from north side, W%

                           else

                               q1(l,k,j)=ST.k_con*ST.dAphi(j)/ST.dc_phi_cell(j,k)*(T1(l+1,k,j)-T1(l,k,j));%Heat energy towards the differential element from north side, W%


                           end

                            %Condition for the q2 part, South Side%
                           if l==1 %The first differential element in the phi direction%

                               q2(l,k,j)=ST.k_con*ST.dAphi(j)/ST.dc_phi_cell(j,k)*(T1(length(ST.phi),k,j)-T1(l,k,j)); %Heat energy towards the differential element from south side, W%

                           else

                               q2(l,k,j)=ST.k_con*ST.dAphi(j)/ST.dc_phi_cell(j,k)*(T1(l-1,k,j)-T1(l,k,j)); %Heat energy towards the differential element from south side, W%


                           end

                             %Condition for the q3 part, West Side%
                           if k==length(ST.theta) %The nodes touching the base of the dome%

                               q3(l,k,j)=ST.k_con*1.10*ST.dAth(j,k)/(ST.dtheta_r/2)*(ST.Tfoundation-T1(l,k,j)); %Heat energy towards the differential element from west side, W%

                           else

                               q3(l,k,j)=ST.k_con*mean([ST.dAth(j,k),ST.dAth(j,k+1)])/ST.dtheta_r*(T1(l,k+1,j)-T1(l,k,j)); %Heat energy towards the differential element from west side, W%


                           end

                           %Condition for the q4 part, East Side%
                           if k==1 %the nodes near to the dome top%

                               q4(l,k,j)=0; %Heat energy towards the differential element from east side, W%

                           else

                               q4(l,k,j)=ST.k_con*mean([ST.dAth(j,k),ST.dAth(j,k-1)])/ST.dtheta_r*(T1(l,k-1,j)-T1(l,k,j));%Heat energy towards the differential element from east side, W%


                           end

                           %Condition for the q5 part, Top Side%
                           if j==length(ST.r) %Outer nodes connected to the SPL%

                               q5(l,k,j)=(SPL2STM1(l,k)-T1(l,k,j))/(ST.m1/(ST.k_reg*ST.dAn_interface(k))+ST.m/(ST.k_con*ST.dAn_interface(k))); %Heat energy towards the differential element from Top side, W%

                           else

                               q5(l,k,j)=ST.k_con*mean([ST.dAn(j,k),ST.dAn(j+1,k)])/ST.n*(T1(l,k,j+1)-T1(l,k,j)); %Heat energy towards the differential element from Top side, W%


                           end

                           %Condition for the q6 part, Bottom Side%
                           if j==1 %meaning the nodes of the interior part in contact to the HIEM%
                           %Check from the HIEM environment%
                           if isnan(TempHIEM2ST(l,k))
                               TempHIEM2ST(l,k)=ST.initial_temperature; %Check for the HIEM2ST, if HIEM provides nan,sets to initial_temperature%
                           end

                               q6(l,k,j)=ST.h*ST.dAn(j,k)*(TempHIEM2ST(l,k)-T1(l,k,j)); %Heat energy towards the differential element from Bottom side, W%

                           else

                               q6(l,k,j)=ST.k_con*mean([ST.dAn(j,k),ST.dAn(j-1,k)])/ST.n*(T1(l,k,j-1)-T1(l,k,j)); %Heat energy towards the differential element from Bottom side, W%


                           end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Incorporation of the damage and Repairibility scenario%
    %Damage Scenario can be incorporated by providing the outer B.C. which is
    %the solar radiation and the emissivity on the top/ sides/ bottom of the element 
    %so in this step, we will replace the q1/q2/....q6 portion considering
    %that specific STM element is exposed to the surface. 

    %Case A: Damageability and Repairability scenario applied to the STM
    %element whose north side element is subjected to the damage and repair
    %scenario by imposing the exposed outer B.C
    if Row_DamElem(1)~=1 %if the 'Φ'angle of the damaged SPLT element is not 1%
        if (l+1)==Row_DamElem(1) && k==Col_DamElem(1)

            if Dam_SPL>0.60 && Num_Dam==1 && j==3   %Only the top layer is damaged%
                 q1(l,k,j)=(ST.abs_con*SR_tot(l+1,k)+ST.emis_con*ST.sigma*(ST.Tspace^4-T1(l,k,j)^4))*ST.dAphi(j); %Providing the S.R. B.C. to the exposed north side surface, W%

            elseif Dam_SPL>0.60 && Num_Dam==2 && (j==3 || j==2) %Top two layers are damaged%
                 q1(l,k,j)=(ST.abs_con*SR_tot(l+1,k)+ST.emis_con*ST.sigma*(ST.Tspace^4-T1(l,k,j)^4))*ST.dAphi(j); %Providing the S.R. B.C. to the exposed north side surface, W%
            elseif Dam_SPL>0.60 && Num_Dam==3 && (j==3 || j==2 || j==1) %All three layers are damaged%
                 q1(l,k,j)=(ST.abs_con*SR_tot(l+1,k)+ST.emis_con*ST.sigma*(ST.Tspace^4-T1(l,k,j)^4))*ST.dAphi(j); %Providing the S.R. B.C. to the exposed north side surface, W%

            end

        end
    else %meaning when Row_DamElem(1)==1 %

         if l==length(ST.phi) && k==Col_DamElem(1)

            if Dam_SPL>0.60 && Num_Dam==1 && j==3 %Only the top layer is damaged%
                 q1(l,k,j)=(ST.abs_con*SR_tot(1,k)+ST.emis_con*ST.sigma*(ST.Tspace^4-T1(l,k,j)^4))*ST.dAphi(j); %Providing the S.R. B.C. to the exposed north side surface, W%

            elseif Dam_SPL>0.60 && Num_Dam==2 && (j==3 || j==2) %Top two layers are damaged%
                 q1(l,k,j)=(ST.abs_con*SR_tot(1,k)+ST.emis_con*ST.sigma*(ST.Tspace^4-T1(l,k,j)^4))*ST.dAphi(j); %Providing the S.R. B.C. to the exposed north side surface, W%
            elseif Dam_SPL>0.60 && Num_Dam==3 && (j==3 || j==2 || j==1) %All three layers are damaged%
                 q1(l,k,j)=(ST.abs_con*SR_tot(1,k)+ST.emis_con*ST.sigma*(ST.Tspace^4-T1(l,k,j)^4))*ST.dAphi(j); %Providing the S.R. B.C. to the exposed north side surface, W%

            end

        end
    end

    %Case B: Damageability and Repairability scenario applied to the STM
    %element whose south side element is subjected to the damage and repair scenario
    if Row_DamElem(1)~=length(ST.phi) %if the damaged element is not the last element in the 'Φ' angle%
        if (l-1)==Row_DamElem(1) && k==Col_DamElem(1)

            if Dam_SPL>0.60 && Num_Dam==1 && j==3 %Only the top layer is damaged%
                 q2(l,k,j)=(ST.abs_con*SR_tot(l-1,k)+ST.emis_con*ST.sigma*(ST.Tspace^4-T1(l,k,j)^4))*ST.dAphi(j); %Providing the S.R. B.C. to the exposed south side surface, W%

            elseif Dam_SPL>0.60 && Num_Dam==2 && (j==3 || j==2) %Top two layers are damaged%
                 q2(l,k,j)=(ST.abs_con*SR_tot(l-1,k)+ST.emis_con*ST.sigma*(ST.Tspace^4-T1(l,k,j)^4))*ST.dAphi(j); %Providing the S.R. B.C. to the exposed south side surface, W%
            elseif Dam_SPL>0.60 && Num_Dam==3 && (j==3 || j==2 || j==1) %All three layers are damaged%
                 q2(l,k,j)=(ST.abs_con*SR_tot(l-1,k)+ST.emis_con*ST.sigma*(ST.Tspace^4-T1(l,k,j)^4))*ST.dAphi(j); %Providing the S.R. B.C. to the exposed south side surface, W%

            end

        end

    else %meaning when Row_DamElem(1)==length(ST.phi) %

        if l==1 && k==Col_DamElem(1)

            if Dam_SPL>0.60 && Num_Dam==1 && j==3 %Only the top layer is damaged%
                 q2(l,k,j)=(ST.abs_con*SR_tot(length(ST.phi),k)+ST.emis_con*ST.sigma*(ST.Tspace^4-T1(l,k,j)^4))*ST.dAphi(j); %Providing the S.R. B.C. to the exposed south side surface, W%

            elseif Dam_SPL>0.60 && Num_Dam==2 && (j==3 || j==2)  %Top two layers are damaged%
                 q2(l,k,j)=(ST.abs_con*SR_tot(length(ST.phi),k)+ST.emis_con*ST.sigma*(ST.Tspace^4-T1(l,k,j)^4))*ST.dAphi(j);%Providing the S.R. B.C. to the exposed south side surface, W%
            elseif Dam_SPL>0.60 && Num_Dam==3 && (j==3 || j==2 || j==1) %All three layers are damaged%
                 q2(l,k,j)=(ST.abs_con*SR_tot(length(ST.phi),k)+ST.emis_con*ST.sigma*(ST.Tspace^4-T1(l,k,j)^4))*ST.dAphi(j); %Providing the S.R. B.C. to the exposed south side surface, W%

            end

        end

    end
    %Case C: Damageability and Repairability scenario applied to the STM
    %element whose west side element is subjected to the damage and repair scenario

    if l==Row_DamElem(1) && (k+1)==Col_DamElem(1)

        if Dam_SPL>0.60 && Num_Dam==1 && j==3 %Only the top layer is damaged%
             q3(l,k,j)=(ST.abs_con*SR_tot(l,k+1)+ST.emis_con*ST.sigma*(ST.Tspace^4-T1(l,k,j)^4))*mean([ST.dAth(j,k),ST.dAth(j,k+1)]);  %Providing the S.R. B.C. to the exposed west side surface, K%

        elseif Dam_SPL>0.60 && Num_Dam==2 && (j==3 || j==2)  %Top two layers are damaged%
             q3(l,k,j)=(ST.abs_con*SR_tot(l,k+1)+ST.emis_con*ST.sigma*(ST.Tspace^4-T1(l,k,j)^4))*mean([ST.dAth(j,k),ST.dAth(j,k+1)]);  %Providing the S.R. B.C. to the exposed west side surface, K%
        elseif Dam_SPL>0.60 && Num_Dam==3 && (j==3 || j==2 || j==1) %All three layers are damaged%
             q3(l,k,j)=(ST.abs_con*SR_tot(l,k+1)+ST.emis_con*ST.sigma*(ST.Tspace^4-T1(l,k,j)^4))*mean([ST.dAth(j,k),ST.dAth(j,k+1)]);  %Providing the S.R. B.C. to the exposed west side surface, K%

        end

    end

    %Case D: Damageability and Repairability scenario applied to the STM
    %element whose east side element is subjected to the damage and repair scenario

    if l==Row_DamElem(1) && (k-1)==Col_DamElem(1)

        if Dam_SPL>0.60 && Num_Dam==1 && j==3 %Only the top layer is damaged%
             q4(l,k,j)=(ST.abs_con*SR_tot(l,k-1)+ST.emis_con*ST.sigma*(ST.Tspace^4-T1(l,k,j)^4))*mean([ST.dAth(j,k),ST.dAth(j,k-1)]);%Providing the S.R. B.C. to the exposed east side surface, K%

        elseif Dam_SPL>0.60 && Num_Dam==2 && (j==3 || j==2) %Top two layers are damaged%
             q4(l,k,j)=(ST.abs_con*SR_tot(l,k-1)+ST.emis_con*ST.sigma*(ST.Tspace^4-T1(l,k,j)^4))*mean([ST.dAth(j,k),ST.dAth(j,k-1)]); %Providing the S.R. B.C. to the exposed east side surface, K%
        elseif Dam_SPL>0.60 && Num_Dam==3 && (j==3 || j==2 || j==1) %All three layers are damaged%
             q4(l,k,j)=(ST.abs_con*SR_tot(l,k-1)+ST.emis_con*ST.sigma*(ST.Tspace^4-T1(l,k,j)^4))*mean([ST.dAth(j,k),ST.dAth(j,k-1)]); %Providing the S.R. B.C. to the exposed east side surface, K%

        end

    end

    %Case E: Damageability and Repairability scenario applied to the STM
    %element top side element is subjected to the damage and repair scenario

    if l==Row_DamElem(1) && k==Col_DamElem(1)

        if Dam_SPL>0.60 && Num_Dam==1 && j==2  %Only the top layer is damaged%
             q5(l,k,j)=(ST.abs_con*SR_tot(l,k)+ST.emis_con*ST.sigma*(ST.Tspace^4-T1(l,k,j)^4))*ST.dAn(j,k);%Providing the S.R. B.C. to the exposed top side surface, K%

        elseif Dam_SPL>0.60 && Num_Dam==2 && j==1 %Top two layers are damaged%
             q5(l,k,j)=(ST.abs_con*SR_tot(l,k)+ST.emis_con*ST.sigma*(ST.Tspace^4-T1(l,k,j)^4))*ST.dAn(j,k); %Providing the S.R. B.C. to the exposed top side surface, K%
        elseif Dam_SPL>0.60 && Num_Dam==0 && j==3 %Top two layers are damaged%
             q5(l,k,j)=(ST.abs_con*SR_tot(l,k)+ST.emis_con*ST.sigma*(ST.Tspace^4-T1(l,k,j)^4))*ST.dAn(j,k); %Providing the S.R. B.C. to the exposed top side surface, K%


        end

    end



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      %Calculation of the temperatures at all nodes, matrix form%
      T2(l,k,j)=T1(l,k,j)+(dt_2/(ST.rho_con*ST.dAth(j,k)*ST.r(j)*ST.dtheta_r*ST.c_con))*(q1(l,k,j)+q2(l,k,j)+q3(l,k,j)+q4(l,k,j)+q5(l,k,j)+q6(l,k,j)); %Temperature calculation, matrix form, K%


        %Checking, for damaged elements, the program returns "NaN" temperature
    %results because there will be no elements
        if Dam_SPL>0.60 && Num_Dam==1 && j==length(ST.r) &&  l==Row_DamElem(1) && k==Col_DamElem(1) %Only the top layer is damaged%
             T2(l,k,j)=NaN; %Providing "NaN" for the damaged element i.e. top layer element%

         elseif Dam_SPL>0.60 && Num_Dam==2 && j==2 &&  l==Row_DamElem(1) && k==Col_DamElem(1)%Top two layers are damaged%
             T2(l,k,j)=NaN; %Providing "NaN" for the damaged element i.e. top and 2nd layer element%      

         elseif Dam_SPL>0.60 && Num_Dam==3 && j==1 &&  l==Row_DamElem(1) && k==Col_DamElem(1) %All three layers are damaged%     
             T2(l,k,j)=NaN; %Providing "NaN" for the damaged element i.e. all three elements of STM% 

        end

         T3=[reshape(T2(:,:,1),[],1);reshape(T2(:,:,2),[],1);reshape(T2(:,:,3),[],1)]; %Making the vector form from the matrix form, 1:60 innermost layer, 61:120 second last layer and so on, T3 must be 180*1, K%

                     end
              end
       end
   
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %Outputs%
        %To SPL%
        STM2SPL=zeros(ST.nph,ST.nth); %Initialization%
        STM2SPL(:,:)=T2(:,:,3); %Transfering the temperature results of third layer, in matrix form%
        Fir_STM=zeros(ST.nnp,1); %Initialization%
        Fir_STM(:)=reshape(STM2SPL,ST.nnp,1); %Reshaping the STM2SPL from matrix form to the vector form, size of 60×1%


        %To HIEM%
        STM2HIEM=zeros(ST.nnp,1); %Initialization%
        STM2HIEM(:)=T3(1:ST.nnp,1); %Transfering the temperature results of innermost layer i.e. r=1%
        Thi_STM=zeros(ST.nnp,1); %Initialization%
        Thi_STM(:)=STM2HIEM(:);   %Transfering the temperature results of innermost layer i.e. r=1%

        %Second Layer Results%
        Sec_STM_mat=zeros(ST.nph,ST.nth); %Initialization%
        Sec_STM_mat(:,:)=T2(:,:,2); %Transfering the temperature results of third layer, in matrix form of size 10×6%
        Sec_STM=zeros(ST.nnp,1); %Initialization%
        Sec_STM(:)=reshape(Sec_STM_mat,ST.nnp,1); %Reshaping the STM2SPL from matrix form to the vector form, size of 60×1%


        %To SMM%  %Transfering the temperature results of all three layers to SMM%
        % Temp. to SMM%
        STM2SMM = zeros(size(ST.SMM_Nodexyz,1),1);
        %Mapping function%
        for i=1:size(ST.SMM_Nodexyz,1)
            STM2SMM(i,1)=T3(ST.mapST2SM(i));
        end



        %T_Fir is the temperature values at the adjacent element of the damaged
        %element in the top layer of the habitat
        T_Fir1=0; %Initialization%
        T_Fir1(:)=T2(Row_DamElem(1)+1,Col_DamElem(1),3); %Temperature Value of the adjacent element to the damaged STM element on topmost(first) layer of the STM, K%

        %T_Sec is the temperature values at the adjacent element of the damaged
        %element in the second layer of the habitat
        T_Sec2=0; %Initialization%
        T_Sec2 (:)=T2(Row_DamElem(1)+1,Col_DamElem(1),2); %Temperature Value of the adjacent element to damaged STM element on second layer of the STM, K%

        %T_Thi is the temperature values at the adjacent element of the damaged
        %element in the third(innermost) layer of the habitat
        T_Thi3=0; %Initialization%
        T_Thi3(:)=T2(Row_DamElem(1)+1,Col_DamElem(1),1); %Temperature Value of the adjacent element to damaged STM element on third layer of the STM, K%

        %STM_Sec=Temperature from second layer of the STM, K %
        STM_Sec=zeros(ST.nph,ST.nth); %Initialization%
        STM_Sec(:,:)=T2(:,:,2); %Transfering the temperature results of third layer but r=1 here%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


            %% Update state variables for next timestep
            ST.T=T2; %updating the state variable for the next time step, K%
            
        end
        
         
        
    end
end


function [SMMxyz,SMM_Nodexyz]=Data

% xyz coordinates of the Gauss points of the SMM (pristine) elements
% XYZ_SMM=[1.89090000000000,1.62650000000000,0.376400000000000;0.376400000000000,1.62650000000000,1.89090000000000;2.45110000000000,0.232500000000000,0.489300000000000;0.489300000000000,0.232500000000000,2.45110000000000;2.12110000000000,1.82450000000000,0.422200000000000;0.422200000000000,1.82450000000000,2.12110000000000;2.74950000000000,0.260800000000000,0.548900000000000;0.548900000000000,0.260800000000000,2.74950000000000;1.36770000000000,1.62650000000000,1.36770000000000;2.26630000000000,0.974000000000000,0.445000000000000;0.445000000000000,0.974000000000000,2.26630000000000;1.77600000000000,0.232500000000000,1.77600000000000;2.00600000000000,1.72550000000000,0.399300000000000;0.399300000000000,1.72550000000000,2.00600000000000;2.60030000000000,0.246600000000000,0.519100000000000;0.519100000000000,0.246600000000000,2.60030000000000;1.53430000000000,1.82450000000000,1.53430000000000;2.54220000000000,1.09250000000000,0.499100000000000;0.499100000000000,1.09250000000000,2.54220000000000;1.99230000000000,0.260800000000000,1.99230000000000;1.62560000000000,0.974000000000000,1.62560000000000;1.45100000000000,1.72550000000000,1.45100000000000;2.40430000000000,1.03320000000000,0.472000000000000;0.472000000000000,1.03320000000000,2.40430000000000;1.88410000000000,0.246600000000000,1.88410000000000;1.82350000000000,1.09250000000000,1.82350000000000;1.72450000000000,1.03320000000000,1.72450000000000;-0.376400000000000,1.62650000000000,1.89090000000000;-1.89090000000000,1.62650000000000,0.376400000000000;-0.489300000000000,0.232500000000000,2.45110000000000;-2.45110000000000,0.232500000000000,0.489300000000000;-0.422200000000000,1.82450000000000,2.12110000000000;-2.12110000000000,1.82450000000000,0.422200000000000;-0.548900000000000,0.260800000000000,2.74950000000000;-2.74950000000000,0.260800000000000,0.548900000000000;-1.36770000000000,1.62650000000000,1.36770000000000;-0.445000000000000,0.974000000000000,2.26630000000000;-2.26630000000000,0.974000000000000,0.445000000000000;-1.77600000000000,0.232500000000000,1.77600000000000;-0.399300000000000,1.72550000000000,2.00600000000000;-2.00600000000000,1.72550000000000,0.399300000000000;-0.519100000000000,0.246600000000000,2.60030000000000;-2.60030000000000,0.246600000000000,0.519100000000000;-1.53430000000000,1.82450000000000,1.53430000000000;-0.499100000000000,1.09250000000000,2.54220000000000;-2.54220000000000,1.09250000000000,0.499100000000000;-1.99230000000000,0.260800000000000,1.99230000000000;-1.62560000000000,0.974000000000000,1.62560000000000;-1.45100000000000,1.72550000000000,1.45100000000000;-0.472000000000000,1.03320000000000,2.40430000000000;-2.40430000000000,1.03320000000000,0.472000000000000;-1.88410000000000,0.246600000000000,1.88410000000000;-1.82350000000000,1.09250000000000,1.82350000000000;-1.72450000000000,1.03320000000000,1.72450000000000;-1.89090000000000,1.62650000000000,-0.376400000000000;-0.376400000000000,1.62650000000000,-1.89090000000000;-2.45110000000000,0.232500000000000,-0.489300000000000;-0.489300000000000,0.232500000000000,-2.45110000000000;-2.12110000000000,1.82450000000000,-0.422200000000000;-0.422200000000000,1.82450000000000,-2.12110000000000;-2.74950000000000,0.260800000000000,-0.548900000000000;-0.548900000000000,0.260800000000000,-2.74950000000000;-1.36770000000000,1.62650000000000,-1.36770000000000;-2.26630000000000,0.974000000000000,-0.445000000000000;-0.445000000000000,0.974000000000000,-2.26630000000000;-1.77600000000000,0.232500000000000,-1.77600000000000;-2.00600000000000,1.72550000000000,-0.399300000000000;-0.399300000000000,1.72550000000000,-2.00600000000000;-2.60030000000000,0.246600000000000,-0.519100000000000;-0.519100000000000,0.246600000000000,-2.60030000000000;-1.53430000000000,1.82450000000000,-1.53430000000000;-2.54220000000000,1.09250000000000,-0.499100000000000;-0.499100000000000,1.09250000000000,-2.54220000000000;-1.99230000000000,0.260800000000000,-1.99230000000000;-1.62560000000000,0.974000000000000,-1.62560000000000;-1.45100000000000,1.72550000000000,-1.45100000000000;-2.40430000000000,1.03320000000000,-0.472000000000000;-0.472000000000000,1.03320000000000,-2.40430000000000;-1.88410000000000,0.246600000000000,-1.88410000000000;-1.82350000000000,1.09250000000000,-1.82350000000000;-1.72450000000000,1.03320000000000,-1.72450000000000;0.376400000000000,1.62650000000000,-1.89090000000000;1.89090000000000,1.62650000000000,-0.376400000000000;0.489300000000000,0.232500000000000,-2.45110000000000;2.45110000000000,0.232500000000000,-0.489300000000000;0.422200000000000,1.82450000000000,-2.12110000000000;2.12110000000000,1.82450000000000,-0.422200000000000;0.548900000000000,0.260800000000000,-2.74950000000000;2.74950000000000,0.260800000000000,-0.548900000000000;1.36770000000000,1.62650000000000,-1.36770000000000;0.445000000000000,0.974000000000000,-2.26630000000000;2.26630000000000,0.974000000000000,-0.445000000000000;1.77600000000000,0.232500000000000,-1.77600000000000;0.399300000000000,1.72550000000000,-2.00600000000000;2.00600000000000,1.72550000000000,-0.399300000000000;0.519100000000000,0.246600000000000,-2.60030000000000;2.60030000000000,0.246600000000000,-0.519100000000000;1.53430000000000,1.82450000000000,-1.53430000000000;0.499100000000000,1.09250000000000,-2.54220000000000;2.54220000000000,1.09250000000000,-0.499100000000000;1.99230000000000,0.260800000000000,-1.99230000000000;1.62560000000000,0.974000000000000,-1.62560000000000;1.45100000000000,1.72550000000000,-1.45100000000000;0.472000000000000,1.03320000000000,-2.40430000000000;2.40430000000000,1.03320000000000,-0.472000000000000;1.88410000000000,0.246600000000000,-1.88410000000000;1.82350000000000,1.09250000000000,-1.82350000000000;1.72450000000000,1.03320000000000,-1.72450000000000;0.895600000000000,2.47600000000000,0.895600000000000;0.176800000000000,2.61200000000000,1.06950000000000;1.06950000000000,2.61200000000000,0.176800000000000;1.32790000000000,2.11390000000000,1.32790000000000;1.77170000000000,2.17660000000000,0.343000000000000;0.343000000000000,2.17660000000000,1.77170000000000;0.248500000000000,2.81530000000000,0.248500000000000;0.167200000000000,2.47020000000000,1.01140000000000;1.01140000000000,2.47020000000000,0.167200000000000;1.25590000000000,1.99920000000000,1.25590000000000;1.67560000000000,2.05840000000000,0.324400000000000;0.324400000000000,2.05840000000000,1.67560000000000;0.235000000000000,2.66250000000000,0.235000000000000;0.798400000000000,2.20730000000000,0.798400000000000;0.157600000000000,2.32850000000000,0.953400000000000;0.953400000000000,2.32850000000000,0.157600000000000;1.18380000000000,1.88450000000000,1.18380000000000;1.57940000000000,1.94030000000000,0.305800000000000;0.305800000000000,1.94030000000000,1.57940000000000;0.221600000000000,2.50970000000000,0.221600000000000;0.847000000000000,2.34160000000000,0.847000000000000;-0.895600000000000,2.47600000000000,0.895600000000000;-1.06950000000000,2.61200000000000,0.176800000000000;-0.176800000000000,2.61200000000000,1.06950000000000;-1.32790000000000,2.11390000000000,1.32790000000000;-0.343000000000000,2.17660000000000,1.77170000000000;-1.77170000000000,2.17660000000000,0.343000000000000;-0.248500000000000,2.81530000000000,0.248500000000000;-1.01140000000000,2.47020000000000,0.167200000000000;-0.167200000000000,2.47020000000000,1.01140000000000;-1.25590000000000,1.99920000000000,1.25590000000000;-0.324400000000000,2.05840000000000,1.67560000000000;-1.67560000000000,2.05840000000000,0.324400000000000;-0.235000000000000,2.66250000000000,0.235000000000000;-0.798400000000000,2.20730000000000,0.798400000000000;-0.953400000000000,2.32850000000000,0.157600000000000;-0.157600000000000,2.32850000000000,0.953400000000000;-1.18380000000000,1.88450000000000,1.18380000000000;-0.305800000000000,1.94030000000000,1.57940000000000;-1.57940000000000,1.94030000000000,0.305800000000000;-0.221600000000000,2.50970000000000,0.221600000000000;-0.847000000000000,2.34160000000000,0.847000000000000;-0.895600000000000,2.47600000000000,-0.895600000000000;-0.176800000000000,2.61200000000000,-1.06950000000000;-1.06950000000000,2.61200000000000,-0.176800000000000;-1.32790000000000,2.11390000000000,-1.32790000000000;-1.77170000000000,2.17660000000000,-0.343000000000000;-0.343000000000000,2.17660000000000,-1.77170000000000;-0.248500000000000,2.81530000000000,-0.248500000000000;-0.167200000000000,2.47020000000000,-1.01140000000000;-1.01140000000000,2.47020000000000,-0.167200000000000;-1.25590000000000,1.99920000000000,-1.25590000000000;-1.67560000000000,2.05840000000000,-0.324400000000000;-0.324400000000000,2.05840000000000,-1.67560000000000;-0.235000000000000,2.66250000000000,-0.235000000000000;-0.798400000000000,2.20730000000000,-0.798400000000000;-0.157600000000000,2.32850000000000,-0.953400000000000;-0.953400000000000,2.32850000000000,-0.157600000000000;-1.18380000000000,1.88450000000000,-1.18380000000000;-1.57940000000000,1.94030000000000,-0.305800000000000;-0.305800000000000,1.94030000000000,-1.57940000000000;-0.221600000000000,2.50970000000000,-0.221600000000000;-0.847000000000000,2.34160000000000,-0.847000000000000;0.895600000000000,2.47600000000000,-0.895600000000000;1.06950000000000,2.61200000000000,-0.176800000000000;0.176800000000000,2.61200000000000,-1.06950000000000;1.32790000000000,2.11390000000000,-1.32790000000000;0.343000000000000,2.17660000000000,-1.77170000000000;1.77170000000000,2.17660000000000,-0.343000000000000;0.248500000000000,2.81530000000000,-0.248500000000000;1.01140000000000,2.47020000000000,-0.167200000000000;0.167200000000000,2.47020000000000,-1.01140000000000;1.25590000000000,1.99920000000000,-1.25590000000000;0.324400000000000,2.05840000000000,-1.67560000000000;1.67560000000000,2.05840000000000,-0.324400000000000;0.235000000000000,2.66250000000000,-0.235000000000000;0.798400000000000,2.20730000000000,-0.798400000000000;0.953400000000000,2.32850000000000,-0.157600000000000;0.157600000000000,2.32850000000000,-0.953400000000000;1.18380000000000,1.88450000000000,-1.18380000000000;0.305800000000000,1.94030000000000,-1.57940000000000;1.57940000000000,1.94030000000000,-0.305800000000000;0.221600000000000,2.50970000000000,-0.221600000000000;0.847000000000000,2.34160000000000,-0.847000000000000];
SMMxyz=[1.57773796336167,1.87418493207300,0.185270642439453;0.212969190614532,2.41583168045418,0.213221548461420;1.34756793866235,1.57837928930395,1.35921367218701;0.183734251153680,1.87418493207300,1.57927435464744;1.83408894502092,2.25216347162989,0.272408561799612;0.303176204659551,2.85975549573877,0.303753617319613;1.57586641628374,1.92030925944900,1.58933610751203;0.270378189344910,2.25216347162989,1.83611931747562;0.895962653807759,2.14642788654225,0.199857943775460;1.46326202783167,1.72770169096713,0.772854005638253;0.198960797703765,2.14642788654225,0.896859799879454;0.766260171727671,1.72770169096713,1.46985586174225;1.71310660611980,2.07993933933409,0.236065485320204;0.265265849565542,2.65455872557912,0.265713466091189;1.46891032940154,1.76610941185912,1.48150077305019;0.234249372177796,2.07993933933409,1.71492271926220;1.10638676877067,2.64395348938332,0.326007077831304;1.74273187458276,2.17423037123844,0.968798322927511;0.324531390932660,2.64395348938332,1.10786245566931;0.960876496744753,2.17423037123844,1.75065370076552;0.831111412767715,1.93706478875469,0.834856902758854;1.00117471128921,2.39519068796279,0.262932510803382;1.60299695120721,1.95096603110279,0.870826164282882;0.261746094318212,2.39519068796279,1.00236112777438;0.863568334236212,1.95096603110279,1.61025478125388;1.03363163275771,2.40909193031088,1.03833038929841;0.932371522762712,2.17307835953279,0.936593646028632;2.41583358331095,0.212949999013160,0.213216334130503;1.87425807963995,1.57764752705012,0.185265428108537;1.87425807963995,0.183643814842130,1.57926914031653;1.57901335462903,1.34691658459266,1.35920845785609;2.85971996238396,0.303115184402876,0.303724496496036;2.25220855790269,1.83394730513664,0.272379440976034;2.25220855790269,0.270236549460633,1.83609019665204;1.92098907327789,1.57509004884337,1.58930698668845;2.14646505387313,0.895907466617985,0.199852508938548;2.14646505387313,0.198905610513991,0.896854365042542;1.72805493953217,1.46289075940774,0.772848570801341;1.72805493953217,0.765888903303743,1.46985042690534;2.65453768378239,0.265221335778858,0.265693694354535;2.07999422970625,1.71298616016422,0.236045713583551;2.07999422970625,0.234128926222222,1.71490294752555;1.76676212488839,1.46819206078886,1.48148100131353;2.64393608225665,1.10626230348567,0.325964288738205;2.64393608225665,0.324406925647667,1.10781966657621;2.17457063770361,1.74224973570592,0.968755533834412;2.17457063770361,0.960394357867914,1.75061091167242;1.93725999670265,0.830898184960864,0.834851467921941;2.39520056806489,1.00108488505183,0.262908398838376;2.39520056806489,0.261656268080829,1.00233701580938;1.95131278861789,1.60257024755683,0.870802052317876;1.95131278861789,0.863141630585829,1.61023066928888;2.40925335998013,1.03332833067679,1.03828760020531;2.17325667834139,0.932113257818829,0.936569534063626;1.34746931949993,1.34682317973077,1.59044086136633;0.183635631991262,1.57755412218823,1.87557624413837;1.57763934419925,0.183550409980237,1.87557624413837;0.212870571452114,0.212856594151267,2.41586771437049;1.57531565123331,1.57456840444679,1.93324001873107;0.269827424294482,1.83342566074007,2.25302018458228;1.83353817997049,0.269714905064055,2.25302018458228;0.302625439609123,0.302593540006297,2.85907862926891;0.766157382113288,1.46279340459859,1.73442131818182;1.46315923821728,0.765791548494595,1.73442131818182;0.198858008089381,0.895810111808837,2.14713474468390;0.895859864193376,0.198808255704843,2.14713474468390;1.46853638456766,1.46783788757639,1.77852509466944;0.233875427343916,1.71263198695176,2.08098286898106;1.71273266128592,0.233774753009758,2.08098286898106;0.264891904731662,0.264867162566394,2.65415782644044;0.960067222345085,1.74148325014996,2.18070168258183;1.74192260018309,0.959627872311953,2.18070168258183;0.323722116532991,1.10549581792971,2.64362098785075;1.10557749437100,0.323640440091705,2.64362098785075;0.831008623153332,0.830800830151716,1.94077803143286;0.863112302229186,1.60213832737427,1.95756150038182;1.60254091920019,0.862709710403274,1.95756150038182;0.261290062311186,1.00065296486927,2.39537786626732;1.00071867928219,0.261224347898274,2.39537786626732;1.03282235835804,1.03256184512083,2.41216133521629;0.931915490755686,0.931681337636274,2.17646968332457;-0.185273182696771,1.87418153380073,1.57773985463069;-0.213222168438263,2.41583159290697,0.212969702996883;-1.35923133103230,1.57834982531432,1.34758068606394;-1.57927689490476,1.87418153380073,0.183736142422700;-0.272412950165893,2.25216138235882,1.83409246858865;-0.303755835209268,2.85975715199310,0.303178172174690;-1.58935758428923,1.92027768122775,1.57588219083164;-1.83612370584190,2.25216138235882,0.270381712912641;-0.199859538295426,2.14642616030029,0.895963868817378;-0.772864119592446,1.72768527650396,1.46326936035090;-0.896861394399420,2.14642616030029,0.198962012713383;-1.46986597569644,1.72768527650396,0.766267504246910;-0.236069119729004,2.07993679240765,1.71310946923944;-0.265715055121437,2.65455970677791,0.265267245215555;-1.48152051095844,1.76607908759891,1.46892474607755;-1.71492635367100,2.07993679240765,0.234252235297439;-0.326011273735509,2.64395430604275,1.10639033153046;-0.968812148275489,2.17421457066008,1.74274234085894;-1.10786665157351,2.64395430604275,0.324534953692459;-1.75066752611349,2.17421457066008,0.960886963020932;-0.834862756995933,1.93705571840212,0.831115686532144;-0.262935406015467,2.39519023317152,1.00117710017392;-0.870838133933967,1.95094992358202,1.60300585060492;-1.00236402298647,2.39519023317152,0.261748483202921;-1.61026675090497,1.95094992358202,0.863577233633921;-1.03833939992450,2.40908443835141,1.03363864727570;-0.936601078460217,2.17307007837677,0.932377166903921;-0.213216611204974,0.212949248749611,2.41583362163797;-0.185267625463482,1.57764346606151,1.87425949685363;-1.57927133767147,0.183639753853521,1.87425949685363;-1.35922577379901,1.34688645788670,1.57902562797528;-0.303724799355809,0.303113139540838,2.85971928241045;-0.272381914312434,1.83394151474921,2.25220943398177;-1.83609266998845,0.270230759073196,2.25220943398177;-1.58932654843577,1.57505476950574,1.92100220033714;-0.199853746055329,0.895905049634436,2.14646577478034;-0.896855602159323,0.198903193530441,2.14646577478034;-0.772858327352349,1.46287365420298,1.72806177794900;-1.46986018345634,0.765871798098988,1.72806177794900;-0.265693983165153,0.265219804085180,2.65453728190603;-0.236048047772719,1.71298110034531,2.07999529529953;-1.71490528171472,0.234123866403314,2.07999529529953;-1.48149943900215,1.46815922363618,1.76677474403803;-0.325965670766228,1.10625768185753,2.64393575489164;-1.10782104860423,0.324402304019526,2.64393575489164;-0.968766545306208,1.74222849683998,2.17457721385499;-1.75062192314421,0.960373119001979,2.17457721385499;-0.834856964755836,0.830888423866712,1.93726377636467;-0.262909708410779,1.00108136574598,2.39520076483599;-1.00233832538178,0.261652748774983,2.39520076483599;-0.870812436329278,1.60255107552148,1.95131949590199;-1.61024105330028,0.863122458550483,1.95131949590199;-1.03829379695522,1.03331540042976,2.40925648437331;-0.936575380855529,0.932101912148233,2.17326013036899;-2.41586776646573,0.212855805761765,0.212870702808276;-1.87557821651409,0.183546310865676,1.57764085444208;-1.87557821651409,1.57755002307366,0.183637142234093;-1.59045795233003,1.34679301489886,1.34748168587533;-2.85907767567213,0.302591282219695,0.302625279181752;-2.25302140146212,0.269708901752053,1.83353957559571;-2.25302140146212,1.83341965742806,0.269828819919703;-1.93325832402183,1.57453291218460,1.57532929783870;-2.14713574730743,0.198805798983053,0.895860682063797;-2.14713574730743,0.895807655087048,0.198858825959802;-1.73443084023958,0.765774403551600,1.46316617359732;-1.73443084023958,1.46277625965559,0.766164317493329;-2.65415726217326,0.264865486306460,0.264891855603891;-2.08098435009243,0.233769548624595,1.71273407962778;-2.08098435009243,1.71262678256659,0.233876845685775;-1.77854267928026,1.46780490585746,1.46854935646589;-2.64362052368660,0.323635505599851,1.10557793040844;-2.64362052368660,1.10549088343786,0.323722552570432;-2.18071084786145,0.959606320582304,1.74192993973691;-2.18071084786145,1.74146169842031,0.960074561898905;-1.94078329377351,0.830791029319324,0.831012499778563;-2.39537813549702,0.261220652291452,1.00071930623612;-2.39537813549702,1.00064926926245,0.261290689265117;-1.95757084405052,0.862690362066952,1.60254805666712;-1.95757084405052,1.60211897903795,0.863119439696117;-2.41216568577403,1.03254860201008,1.03282624615367;-2.17647448977377,0.931669815664702,0.931919372966117;-1.57773907192448,1.87418252448993,-0.185272679965504;-0.212969515145159,2.41583161772617,-0.213222026345209;-1.34757522000028,1.57835842040862,-1.35922798895511;-0.183735359716491,1.87418252448993,-1.57927639217349;-1.83409112925237,2.25216198971892,-0.272411980767252;-0.303177508161385,2.85975666500408,-0.303755275135659;-1.57587553460026,1.92028690452363,-1.58935339222776;-0.270380373576360,2.25216198971892,-1.83612273644326;-0.895963379254435,2.14642666316131,-0.199859212093281;-1.46326623168200,1.72769006450254,-0.772862193398230;-0.198961523150440,2.14642666316131,-0.896861068197276;-0.766264375578002,1.72769006450254,-1.46986404950222;-1.71310835762475,2.07993753364425,-0.236068338904619;-0.265266768689592,2.65455941790495,-0.265714659278675;-1.46891863433659,1.76608793900595,-1.48151669912967;-0.234251123682746,2.07993753364425,-1.71492557284662;-1.10638906430938,2.64395406292017,-0.326010274073686;-1.74273807752881,2.17421918267994,-0.968809332619737;-0.324533686471371,2.64395406292017,-1.10786565191169;-0.960882699690809,2.17421918267994,-1.75066471045774;-0.831113877416218,1.93705836383192,-0.834861630797753;-1.00117622178191,2.39519036304074,-0.262934743083484;-1.60300215460541,1.95095462359124,-0.870835763008984;-0.261747604810905,2.39519036304074,-1.00236336005448;-0.863573537634405,1.95095462359124,-1.61026437997998;-1.03363588200009,2.40908662280005,-1.03833749226571;-0.932374879708155,2.17307249331599,-0.936599561531734;-2.41583360519205,0.212949481762514,-0.213216583610234;-1.87425888555323,1.57764466494442,-0.185267237230529;-1.87425888555323,0.183640952736428,-1.57927094943852;-1.57902033331743,1.34689526117471,-1.35922254622013;-2.85971957565865,0.303113815265157,-0.303724878728614;-2.25220905190699,1.83394328482264,-0.272381584360207;-2.25220905190699,0.270232529146624,-1.83609234003622;-1.92099650136726,1.57506515551496,-1.58932299582072;-2.14646546387169,0.895905769493354,-0.199853539193455;-2.14646546387169,0.198903913389359,-0.896855395297449;-1.72805882793438,1.46287865919945,-0.772856520498404;-1.72805882793438,0.765876803095455,-1.46985837660240;-2.65453745531781,0.265220304642564,-0.265694021477903;-2.07999483362257,1.71298263101225,-0.236047701103847;-2.07999483362257,0.234125397070254,-1.71490493504585;-1.76676928223481,1.46816886447356,-1.48149606132890;-2.64393589423624,1.10625914718419,-0.325965610684017;-2.64393589423624,0.324403769346184,-1.10782098852202;-2.17457435709055,1.74223481730909,-0.968764669230068;-2.17457435709055,0.960379439471088,-1.75062004706807;-1.93726214590304,0.830891286294404,-0.834855957897927;-2.39520067905397,1.00108245833877,-0.262909574938736;-2.39520067905397,0.261653841367772,-1.00233819190974;-1.95131659251247,1.60255673825427,-0.870810594864236;-1.95131659251247,0.863128121283271,-1.61023921183524;-2.40925512566340,1.03331929332764,-1.03829282887605;-2.17325863578322,0.932105289811021,-0.936574393386986;-1.34747631679702,1.34680180067458,-1.59045474213041;-0.183636456513227,1.57755120444429,-1.87557784566040;-1.57764016872122,0.183547492236306,-1.87557784566040;-0.212870611941895,0.212856021262392,-2.41586775625026;-1.57532318324787,1.57454320039184,-1.93325486846591;-0.269828022223968,1.83342132969951,-2.25302116856902;-1.83353877789998,0.269710574023498,-2.25302116856902;-0.302625156808993,0.302591860142031,-2.85907785210406;-0.766161289911123,1.46278124639922,-1.73442905149984;-1.46316314601512,0.765779390295224,-1.73442905149984;-0.198858437483562,0.895808356693122,-2.14713555855976;-0.895860293587556,0.198806500589128,-2.14713555855976;-1.46854361247463,1.46781448029167,-1.77853936750581;-0.233876101820786,1.71262824683036,-2.08098406932236;-1.71273333576279,0.233771012888363,-2.08098406932236;-0.264891746827633,0.264865920460673,-2.65415736638481;-0.960071094435962,1.74146787518269,-2.18070911440051;-1.74192647227397,0.959612497344688,-2.18070911440051;-0.323722081216524,1.10549220505779,-2.64362060621959;-1.10557745905453,0.323636827219784,-2.64362060621959;-0.831010791749340,0.830793873494173,-1.94078230502980;-0.863116192173543,1.60212456079096,-1.95756908295018;-1.60254480914454,0.862695943819956,-1.95756908295018;-0.261290259350043,1.00065028087546,-2.39537808238968;-1.00071887632104,0.261221663904456,-2.39537808238968;-1.03282427674525,1.03255235120124,-2.41216486031005;-0.931917534247293,0.931673112347706,-2.17647358266993;0.185273735680099,1.87418163204594,-1.57773917527037;0.213222253763638,2.41583159578875,-0.212969585883371;1.35923556594023,1.57835067436681,-1.34757558007019;1.57927744788809,1.87418163204594,-0.183735463062385;0.272413655977186,2.25216143872384,-1.83409154446035;0.303756009123055,2.85975710555641,-0.303177882647214;1.58936247779047,1.92027854696234,-1.57587627041840;1.83612441165320,2.25216143872384,-0.270380788784340;0.199859858180680,2.14642621039890,-0.895963469087271;0.772866514268974,1.72768574968793,-1.46326646618068;0.896861714284674,2.14642621039890,-0.198961612983276;1.46986837037297,1.72768574968793,-0.766264610076684;0.236069757758220,2.07993686422257,-1.71310864986063;0.265715193372924,2.65455967951025,-0.265267024260556;1.48152508379492,1.76607993950225,-1.46891921523956;1.71492699170022,2.07993686422257,-0.234251415918625;0.326011758903727,2.64395428219088,-1.10638963214558;0.968814993237433,2.17421500289385,-1.74273882603117;1.10786713674173,2.64395428219088,-0.324534254307574;1.75067037107544,2.17421500289385,-0.960883448193166;0.834864114276824,1.93705598004342,-0.831114039581977;0.262935808542203,2.39519024629489,-1.00117655061643;0.870840753753204,1.95095037629089,-1.60300264610593;1.00236442551320,2.39519024629489,-0.261747933645425;1.61026937072420,1.95095037629089,-0.863574029134925;1.03834106498958,2.40908464254236,-1.03363654016937;0.936602589633203,2.17307031129289,-0.932375289875675;0.213216744157898,0.212949307946787,-2.41583360616201;0.185268226074360,1.57764362062213,-1.87425891913088;1.57927193828235,0.183639908414136,-1.87425891913088;1.35923005633449,1.34688736325460,-1.57902062361909;0.303725239258371,0.303113407612541,-2.85971956050508;0.272382886112502,1.83394188562261,-2.25220907747557;1.83609364178851,0.270231129946603,-2.25220907747557;1.58933170792578,1.57505594974873,-1.92099684754600;0.199854115582228,0.895905158429942,-2.14646548098589;0.896855971686223,0.198903302325948,-2.14646548098589;0.772860771670523,1.46287418608385,-1.72805898971443;1.46986262777452,0.765872329979853,-1.72805898971443;0.265694302011119,0.265219990354653,-2.65453744634105;0.236048866396415,1.71298138569736,-2.07999486131073;1.71490610033841,0.234124151755359,-2.07999486131073;1.48150419243312,1.46816028907665,-1.76676959859005;0.325966546768805,1.10625812013301,-2.64393588955030;1.10782192460681,0.324402742295003,-2.64393588955030;0.968769781102510,1.74222939120110,-2.17457453307076;1.75062515894052,0.960374013363098,-2.17457453307076;0.834858371678373,0.830888744204897,-1.93726223535016;0.262910331175517,1.00108163928148,-2.39520068526809;1.00233894814652,0.261653022310475,-2.39520068526809;0.870815276386517,1.60255178864248,-1.95131676139259;1.61024389335752,0.863123171671475,-1.95131676139259;1.03829585285466,1.03331606674805,-2.40925521131053;0.936577112266517,0.932102405476475,-2.17325872333034;1.59046211369351,1.34679384523177,-1.34747655247391;1.87557869595297,1.57755010259930,-0.183636435466107;1.87557869595297,0.183546390391314,-1.57764014767410;2.41586777824666,0.212855789923964,-0.212870558287093;1.93326280679445,1.57453367337472,-1.57532322436000;2.25302169654479,1.83341960924860,-0.269827742725943;2.25302169654479,0.269708853572590,-1.83353849840195;2.85907743885730,0.302591131238528,-0.302624836588817;1.73443315826158,1.46277671332837,-0.766161394756403;1.73443315826158,0.765774857224374,-1.46316325086040;2.14713599053816,0.895807685674464,-0.198858397662996;2.14713599053816,0.198805829570469,-0.895860253766991;1.77854697325038,1.46780568677978,-1.46854372170329;2.08098470925528,1.71262678340048,-0.233875922382362;2.08098470925528,0.233769549458485,-1.71273315632436;2.65415712155838,0.264865388057779,-0.264891530724292;2.18071308931350,1.74146197704018,-0.960070822162247;2.18071308931350,0.959606599202174,-1.74192620000025;2.64362040534492,1.10549070597208,-0.323721628276654;2.64362040534492,0.323635328134079,-1.10557700611466;1.94078457439987,0.830791271449419,-0.831010824261697;1.95757312378754,1.60211934518427,-0.863116108459325;1.95757312378754,0.862690728213274,-1.60254472543033;2.39537819794154,1.00064919582327,-0.261290012969825;2.39537819794154,0.261220578852274,-1.00071862994082;2.41216674732921,1.03254865258713,-1.03282391413845;2.17647566086454,0.931669962018274,-0.931917369200075];
SMM_Nodexyz=[-1.76780000000000,1.76780000000000,0;-2.05060000000000,2.05060000000000,0;0,1.76780000000000,-1.76780000000000;0,2.05060000000000,-2.05060000000000;-1.45330000000000,1.43800000000000,1.43880000000000;-1.68590000000000,1.66800000000000,1.66900000000000;-1.43880000000000,1.43800000000000,-1.45330000000000;-1.66900000000000,1.66800000000000,-1.68590000000000;1.45330000000000,1.43800000000000,-1.43880000000000;1.68590000000000,1.66800000000000,-1.66900000000000;2.47790000000000,1.06280000000000,1.06790000000000;1.06220000000000,1.06190000000000,2.48070000000000;-1.06790000000000,2.47780000000000,1.06310000000000;-1.06790000000000,1.06280000000000,2.47790000000000;-2.48070000000000,1.06190000000000,1.06220000000000;-1.06310000000000,2.47780000000000,-1.06790000000000;-2.47790000000000,1.06280000000000,-1.06790000000000;-1.06220000000000,1.06190000000000,-2.48070000000000;1.06790000000000,2.47780000000000,-1.06310000000000;1.06790000000000,1.06280000000000,-2.47790000000000;2.48080000000000,1.06190000000000,-1.06220000000000;0,2.50000000000000,0;0,2.90000000000000,0;0,1.76780000000000,1.76780000000000;1.76780000000000,1.76780000000000,0;2.05060000000000,2.05060000000000,0;0,2.05060000000000,2.05060000000000;1.43880000000000,1.43800000000000,1.45320000000000;1.66900000000000,1.66800000000000,1.68590000000000;1.06310000000000,2.47780000000000,1.06790000000000;0,0,2.50000000000000;2.50000000000000,0,0;2.90000000000000,0,0;0,0,2.90000000000000;-2.50000000000000,0,0;-2.90000000000000,0,0;0,0,-2.50000000000000;0,0,-2.90000000000000;1.76780000000000,0,1.76780000000000;2.05060000000000,0,2.05060000000000;-1.76780000000000,0,1.76780000000000;-2.05060000000000,0,2.05060000000000;-1.76780000000000,0,-1.76780000000000;-2.05060000000000,0,-2.05060000000000;1.76780000000000,0,-1.76780000000000;2.05060000000000,0,-2.05060000000000];
% STMxyz=[-0.100837029017617,2.47861215343453,0.310344464145185;-0.263994769292682,2.47861215343453,0.191803427062097;-0.326315480550129,2.47861215343453,0;-0.263994769292682,2.47861215343453,-0.191803427062097;-0.100837029017617,2.47861215343453,-0.310344464145185;0.100837029017617,2.47861215343453,-0.310344464145185;0.263994769292682,2.47861215343453,-0.191803427062097;0.326315480550129,2.47861215343453,0;0.263994769292682,2.47861215343453,0.191803427062097;0.100837029017617,2.47861215343453,0.310344464145185;-0.295639210166371,2.30969883127822,0.909883930072536;-0.773993500622734,2.30969883127822,0.562339194602160;-0.956708580912725,2.30969883127822,0;-0.773993500622734,2.30969883127822,-0.562339194602160;-0.295639210166371,2.30969883127822,-0.909883930072536;0.295639210166371,2.30969883127822,-0.909883930072536;0.773993500622734,2.30969883127822,-0.562339194602160;0.956708580912725,2.30969883127822,0;0.773993500622734,2.30969883127822,0.562339194602160;0.295639210166371,2.30969883127822,0.909883930072536;-0.470294067709182,1.98338335072809,1.44741630981973;-1.23124585397008,1.98338335072809,0.894552475339543;-1.52190357252180,1.98338335072809,0;-1.23124585397008,1.98338335072809,-0.894552475339543;-0.470294067709182,1.98338335072809,-1.44741630981973;0.470294067709182,1.98338335072809,-1.44741630981973;1.23124585397008,1.98338335072809,-0.894552475339543;1.52190357252180,1.98338335072809,0;1.23124585397008,1.98338335072809,0.894552475339543;0.470294067709182,1.98338335072809,1.44741630981973;-0.612899161735306,1.52190357252180,1.88630966002126;-1.60459083709935,1.52190357252180,1.16580348320040;-1.98338335072809,1.52190357252180,0;-1.60459083709935,1.52190357252180,-1.16580348320040;-0.612899161735306,1.52190357252180,-1.88630966002126;0.612899161735306,1.52190357252180,-1.88630966002126;1.60459083709935,1.52190357252180,-1.16580348320040;1.98338335072809,1.52190357252180,0;1.60459083709935,1.52190357252180,1.16580348320040;0.612899161735306,1.52190357252180,1.88630966002126;-0.713736190752923,0.956708580912725,2.19665412416645;-1.86858560639203,0.956708580912725,1.35760691026250;-2.30969883127822,0.956708580912725,0;-1.86858560639203,0.956708580912725,-1.35760691026250;-0.713736190752923,0.956708580912725,-2.19665412416645;0.713736190752923,0.956708580912725,-2.19665412416645;1.86858560639203,0.956708580912725,-1.35760691026250;2.30969883127822,0.956708580912725,0;1.86858560639203,0.956708580912725,1.35760691026250;0.713736190752923,0.956708580912725,2.19665412416645;-0.765933277875553,0.326315480550129,2.35730023989227;-2.00523935459282,0.326315480550129,1.45689166994170;-2.47861215343453,0.326315480550129,0;-2.00523935459282,0.326315480550129,-1.45689166994170;-0.765933277875553,0.326315480550129,-2.35730023989227;0.765933277875553,0.326315480550129,-2.35730023989227;2.00523935459282,0.326315480550129,-1.45689166994170;2.47861215343453,0.326315480550129,0;2.00523935459282,0.326315480550129,1.45689166994170;0.765933277875553,0.326315480550129,2.35730023989227;-0.107290598874745,2.63724333125434,0.330206509850476;-0.280890434527414,2.63724333125434,0.204078846394071;-0.347199671305337,2.63724333125434,0;-0.280890434527414,2.63724333125434,-0.204078846394071;-0.107290598874745,2.63724333125434,-0.330206509850476;0.107290598874745,2.63724333125434,-0.330206509850476;0.280890434527414,2.63724333125434,-0.204078846394071;0.347199671305337,2.63724333125434,0;0.280890434527414,2.63724333125434,0.204078846394071;0.107290598874745,2.63724333125434,0.330206509850476;-0.314560119617019,2.45751955648002,0.968116501597178;-0.823529084662589,2.45751955648002,0.598328903056698;-1.01793793009114,2.45751955648002,0;-0.823529084662589,2.45751955648002,-0.598328903056698;-0.314560119617019,2.45751955648002,-0.968116501597178;0.314560119617019,2.45751955648002,-0.968116501597178;0.823529084662589,2.45751955648002,-0.598328903056698;1.01793793009114,2.45751955648002,0;0.823529084662589,2.45751955648002,0.598328903056698;0.314560119617019,2.45751955648002,0.968116501597178;-0.500392888042570,2.11031988517469,1.54005095364820;-1.31004558862417,2.11031988517469,0.951803833761274;-1.61930540116320,2.11031988517469,0;-1.31004558862417,2.11031988517469,-0.951803833761274;-0.500392888042570,2.11031988517469,-1.54005095364820;0.500392888042570,2.11031988517469,-1.54005095364820;1.31004558862417,2.11031988517469,-0.951803833761274;1.61930540116320,2.11031988517469,0;1.31004558862417,2.11031988517469,0.951803833761274;0.500392888042570,2.11031988517469,1.54005095364820;-0.652124708086366,1.61930540116320,2.00703347826263;-1.70728465067371,1.61930540116320,1.24041490612523;-2.11031988517469,1.61930540116320,0;-1.70728465067371,1.61930540116320,-1.24041490612523;-0.652124708086366,1.61930540116320,-2.00703347826263;0.652124708086366,1.61930540116320,-2.00703347826263;1.70728465067371,1.61930540116320,-1.24041490612523;2.11031988517469,1.61930540116320,0;1.70728465067371,1.61930540116320,1.24041490612523;0.652124708086366,1.61930540116320,2.00703347826263;-0.759415306961111,1.01793793009114,2.33723998811310;-1.98817508520112,1.01793793009114,1.44449375251930;-2.45751955648002,1.01793793009114,0;-1.98817508520112,1.01793793009114,-1.44449375251930;-0.759415306961111,1.01793793009114,-2.33723998811310;0.759415306961111,1.01793793009114,-2.33723998811310;1.98817508520112,1.01793793009114,-1.44449375251930;2.45751955648002,1.01793793009114,0;1.98817508520112,1.01793793009114,1.44449375251930;0.759415306961111,1.01793793009114,2.33723998811310;-0.814953007659589,0.347199671305337,2.50816745524537;-2.13357467328676,0.347199671305337,1.55013273681797;-2.63724333125434,0.347199671305337,0;-2.13357467328676,0.347199671305337,-1.55013273681797;-0.814953007659589,0.347199671305337,-2.50816745524537;0.814953007659589,0.347199671305337,-2.50816745524537;2.13357467328676,0.347199671305337,-1.55013273681797;2.63724333125434,0.347199671305337,0;2.13357467328676,0.347199671305337,1.55013273681797;0.814953007659589,0.347199671305337,2.50816745524537;-0.113744168731873,2.79587450907415,0.350068555555768;-0.297786099762145,2.79587450907415,0.216354265726046;-0.368083862060546,2.79587450907415,0;-0.297786099762145,2.79587450907415,-0.216354265726046;-0.113744168731873,2.79587450907415,-0.350068555555768;0.113744168731873,2.79587450907415,-0.350068555555768;0.297786099762145,2.79587450907415,-0.216354265726046;0.368083862060546,2.79587450907415,0;0.297786099762145,2.79587450907415,0.216354265726046;0.113744168731873,2.79587450907415,0.350068555555768;-0.333481029067667,2.60534028168183,1.02634907312182;-0.873064668702444,2.60534028168183,0.634318611511236;-1.07916727926955,2.60534028168183,0;-0.873064668702444,2.60534028168183,-0.634318611511236;-0.333481029067667,2.60534028168183,-1.02634907312182;0.333481029067667,2.60534028168183,-1.02634907312182;0.873064668702444,2.60534028168183,-0.634318611511236;1.07916727926955,2.60534028168183,0;0.873064668702444,2.60534028168183,0.634318611511236;0.333481029067667,2.60534028168183,1.02634907312182;-0.530491708375957,2.23725641962128,1.63268559747666;-1.38884532327825,2.23725641962128,1.00905519218301;-1.71670722980459,2.23725641962128,0;-1.38884532327825,2.23725641962128,-1.00905519218301;-0.530491708375957,2.23725641962128,-1.63268559747666;0.530491708375957,2.23725641962128,-1.63268559747666;1.38884532327825,2.23725641962128,-1.00905519218301;1.71670722980459,2.23725641962128,0;1.38884532327825,2.23725641962128,1.00905519218301;0.530491708375957,2.23725641962128,1.63268559747666;-0.691350254437425,1.71670722980459,2.12775729650399;-1.80997846424807,1.71670722980459,1.31502632905005;-2.23725641962128,1.71670722980459,0;-1.80997846424807,1.71670722980459,-1.31502632905005;-0.691350254437425,1.71670722980459,-2.12775729650399;0.691350254437425,1.71670722980459,-2.12775729650399;1.80997846424807,1.71670722980459,-1.31502632905005;2.23725641962128,1.71670722980459,0;1.80997846424807,1.71670722980459,1.31502632905005;0.691350254437425,1.71670722980459,2.12775729650399;-0.805094423169298,1.07916727926955,2.47782585205975;-2.10776456401021,1.07916727926955,1.53138059477610;-2.60534028168183,1.07916727926955,0;-2.10776456401021,1.07916727926955,-1.53138059477610;-0.805094423169298,1.07916727926955,-2.47782585205975;0.805094423169298,1.07916727926955,-2.47782585205975;2.10776456401021,1.07916727926955,-1.53138059477610;2.60534028168183,1.07916727926955,0;2.10776456401021,1.07916727926955,1.53138059477610;0.805094423169298,1.07916727926955,2.47782585205975;-0.863972737443624,0.368083862060546,2.65903467059848;-2.26190999198070,0.368083862060546,1.64337380369424;-2.79587450907415,0.368083862060546,0;-2.26190999198070,0.368083862060546,-1.64337380369424;-0.863972737443624,0.368083862060546,-2.65903467059848;0.863972737443624,0.368083862060546,-2.65903467059848;2.26190999198070,0.368083862060546,-1.64337380369424;2.79587450907415,0.368083862060546,0;2.26190999198070,0.368083862060546,1.64337380369424;0.863972737443624,0.368083862060546,2.65903467059848];

end


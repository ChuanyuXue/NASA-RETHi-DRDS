classdef SPLT < matlab.System ... %SPLT-Structural Protective Layer-Thermal%
        & matlab.system.mixin.Propagates
 
%% Documentation
% Purpose: To determine the temperatures at different points of the
%          Structural Protective Layer (SPL)that covers the Structural 
%          Habitat Structure. For more details, please look into the
%          Chapter 2.2 of the documentation report. 
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
%   - T_SPL_initialize.m

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

            emis_reg;       %Emissivity of regolith, unitless
            abs_reg;        %Absorptivity of regolith, unitless
            sigma;          %Stefan-Boltzmann Constant, W/(m^2.K^4)
            rho_reg;        %Density of regolith, kg/(m^3)
            k_reg;          %Thermal conductivity of regolith, W/(m.K)
            c_reg;          %Specific Heat of regolith, J/(kg.K)
            k_con;          %Thermal conductivity of Concrete, W/(m.K)
            Tspace;         %Cosmic Background Temperature, K
            
            %Habitat Design Parameters%
            
            R;       %Inner radius of the SPL layer, m
            d;       %Thickness of the SPL, m
            d_STM;   %Thickness of the Structural wall, m
            
            %Initial Conditions and Boundary Conditions%
            
            Trepair;        %Initial Temperature of the habitat when the element has been repaired, K
            Tfoundation;    %Temperature of the lunar foundation which acts as a boundary condition, K
    
    end

    properties(DiscreteState)
    end

    % Pre-computed constants
    properties(Nontunable,Access=private) %Adding properties and (Nontunable) attribute allows users not to access those properties%

    %Access Modifier:"Private", allows access from class methods only (not from
    %subclass). Since we are not using any subclasses here, we can use it.
    %In case, we have subclasses, our access modifier should be "protected"
    %"Nontunable" attribute to the property when the algorithm depends on the
    %value being constant once the data processing starts. 
        
        %Model Specific Variables: These Parameters
        %variables specific to model 
            nph=10;      % Number of elements in Φ direction, unitless
            nth=6;       % Number of elements in Θ direction, unitless
            nnp=60;      %Total number of elements in one layer, unitless%
            totelem=180; %Total number of elements in three SPL layers, unitless%
            n_d=3;       %Division number of the thickness%
            total_azimuth_angle=360; %Total azimuthal angle of the dome habitat, °%
            total_polar_angle=90; %Total polar angle of the dome habitat, °%
           
            
    end
       
    
      % Pre-computed constants
    properties(Access=private)

    %Access Modifier,"Private", allows access from class methods only (not from
    %subclass). Since we are not using any subclasses here, we can use it.
    %In case, we have subclasses, our access modifier should be "protected"
        
 
            dphi;           %Circumferential angle of one differential element, degrees(°)%
            dtheta;         %Differential angle in the theta direction, degrees(°)%
            dphi_r;         %Circumferential angle of one differential element, radian%
            dtheta_r;       %Differential angle in the theta direction,, radian%
            m;              %Thickness of the Boundary elements, m%
            m2;             %Half the Thickness of each layer of the STM, m%
 
            n;              %Distance between the nodes or thickness of interior elements, m% 
            dr;             %Thickness Division vector, m%
            r1;             %Distance from the orign to the  first (innermost/interface) node, m%
            r2;             %Distance from the orign to the  second node, m%
            r3;             %Distance from the orign to the  third node, m%
            r;              %Distance vector of the nodes from the center, m%
            tot_cells;      %Total number of cells in one layer%
           position_info;   %Matrix of size (:,3)in which each column are r,Θ, and Φ values of elements respectively%
            x_par;          %Vector of X-coordinate of the differential elements in parent coordinate system%
            y_par;          %Vector of Y-coordinate of the differential elements in parent coordinate system%
            z_par;          %Vector of Z-coordinate of the differential elements in parent coordinate system%
            xyz_par_r1;     %Matrix of first (innermost) layer with the global s/s based upon the parent axes%
            xyz_par_r2;     %Matrix of second layer with the global s/s based upon the parent axes%
            xyz_par_r3;     %Matrix of third (top) layer with the global s/s based upon the parent axes%
            xyz_par;        %XYZ-coordinates of the differential elements in parent coordinate system%
            xyz_ch2;        %XYZ-coordinates of the differential elements in child coordinate system%
            xyz_global;     %XYZ-coordinates of the differential elements in global coordinate system%
            x_Reg;          %Matrix of X coordinates of all three layers in Global s/s, size of 10×6×3%
            y_Reg;          %Matrix of Y coordinates of all three layers in Global s/s, size of 10×6×3%
            z_Reg;          %Matrix of Z coordinates of all three layers in Global s/s, size of 10×6×3%
            xyz_Reg_r1;     %Matrix (XYZ coordinates)of innermost (first) layer Global s/s, size 60×3%
            xyz_Reg_r2;     %Matrix (XYZ coordinates)of second layer in Global s/s, size 60×3%
            xyz_Reg_r3;     %Matrix (XYZ coordinates)of third (interface with SPL) layer Global s/s, size 60×3%
            xyz_STM;        %Matrix (XYZ coordinates)of all three layers in Global s/s, size 60×3×3%
            Regxyz;         %Matrix (XYZ coordinates)of all nodes in Global s/s, size 180×3%
            
            x_gl;           %Vector of X-coordinate of the differential elements in global coordinate system%
            y_gl;           %Vector of Y-coordinate of the differential elements in global coordinate system%
            z_gl;           %Vector of Z-coordinate of the differential elements in global coordinate system%
            STMregxyz;      %Cartesian coordinates of SPLT elements in the Global Coordinate S/s%
            theta_cell_tot; %Three Dimensional Matrix with the Θ values of all elements%
            phi_cell_tot;   %Three Dimensional Matrix with the Φ values of all elements%
            rad_cell_1;     %Two Dimensional Matrix with the radius values of elements from innermost (third) layer%
            rad_cell_2;     %Two Dimensional Matrix with the radius values of elements from second layer%
            rad_cell_3;     %Two Dimensional Matrix with the radius values of elements from third (top) layer%
            rad_cell_tot;   %Three Dimensional Matrix with the radius values of all elements%
            dr_interface;   %Distance between nodes of STM and SPL bottom layer node, m%
            phi;            %Vector of Φ angles of differential elements, degrees (°)%
            theta;          %Vector of Θ angles of differential elements, degrees (°)%
            dAn;            %Surface area of the differential element normal to radius, m^2%
            dAn_interface;  %Surface area normal to radius for the interface between SPL and STM, m^2%
            dAn_outer;      %Surface area normal to outer radius of SPL, m^2%
            dAth;           %Surface area of differential elements normal to the Θ, m^2%
            dAphi;          %Surface area of differential elements normal to the Φ, m^2%
            theta_cell;     %Matrix of Θ's corresponding to one layer, size 10×6%
            dc_phi_cell;    %Matrix of Φ's corresponding to one layer%
            theta_mat;      %Vector of Θ's corresponding to one layer%
            phi_mat;        %Vector of Φ's corresponding to one layer%
            rad_mat;        %Vector of radius of nodes of all three layers%
            phi_cell;       %Matrix of Φ's corresponding to one layer%
            tot_cell;       %Total number of cells in one layer%
            Num;            %Vector of numbering of SPL differential elements%
            NumSTMmat;      %Matrix of numbering of SPL differential elements%
            dAth_comp1;        %First component of dAth%
            dAth_comp2;        %Second component of dAth%
            dAth_r1;           %Differential area normal to the 'Θ' direction of the third layer elements, m^2%
            dAth_r2;           %Differential area normal to the 'Θ' direction of the second layer elements, m^2%
            dAth_r3;           %Differential area normal to the 'Θ' direction of the first layer elements, m^2%
            
        % State Variables
            T;  %Temperature matrix in each time step, K%
            
    end
       

    

    methods(Access = protected) 
       %Methods takes the values of the properties of one-time calculation
       %that we mentioned in the properties() aforementioned
       %Syntax%
       %methods
       %function obj = ClassName(arg1,...)
       %obj.PropertyName = arg1;
       %  ...
       %end
       %function ordinaryMethod(obj,arg1,...)
       %...
       % end
       %end

%The setupImpl method sets up the object and implements one-time initialization tasks%

% For setupImpl and all Impl methods, you must set the method attribute Access = protected because users of the System object do not call these methods directly. Instead the back-end of the System object calls these methods through other user-facing functions.
        
        %% ================================================================
        %  MATLAB System Object Impl() Methods
        %  ================================================================
        
        function setupImpl(STS) %%%The setupImpl method sets up the object and implements one-time initialization tasks%
      
      %The setupImpl method is used to perform the set up and the initialization tasks. You should include codes in the setupImpl method you 
      %want to execute one time only. The sehe setupImpl method is called once the first time you run the object.
      % Perform one-time calculations, such as computing constants
      %Use object.propertyname (i.e. STS.propertyname)while referencing class property%
          
            % Define # of points to be used
               STS.nnp=STS.nph*STS.nth;           % # Total no. of nodal points
               STS.dphi=STS.total_azimuth_angle/STS.nph; %Differential circumferential angle, degree(°)%
               STS.dtheta=STS.total_polar_angle/STS.nth;             %differential theta angle, degree(°)%
               STS.dphi_r=(pi/180)*STS.dphi;      %Differential azimuthal angle considered (radian)%
               STS.dtheta_r=(pi/180)*STS.dtheta;  %Differential theta angle considered (radian)%
                
                 
                
                                %% Division of the thickness
        % In this case we have decided to divide the whole thickness into 3 elements and 
        %four nodes, 2 of them being on the edges. r1,r2,r3 is the distance from 
        %the origin to the center of each element
                
                STS.m=STS.d/(2*STS.n_d-1);              %Thickness of boundary elements, m%
                STS.n=2*STS.m;              %Distance between the nodes or thickness of interior elements, m%
                STS.dr=[STS.n;STS.n;STS.m]; %Element division Thickness vector, m%
                STS.m2=STS.d_STM/(2*STS.n_d-1);         %Half the Thickness of each layer of the STM, m%
               
                %Creation of the distance vector from the origin to the nodes of SPL-Thermal%
                STS.r1=STS.R+STS.n/2;         %Distance from the orign to the  first node, m%
                STS.r2=STS.r1+STS.n;          %Distance from the orign to the second node, m%
                STS.r3=STS.r2+STS.n;          %Distance from the orign to the third node, m%
                STS.r=[STS.r1;STS.r2;STS.r3]; %Creating the distance vector, m%
                STS.dr_interface=STS.m+STS.m2;        %Distance between nodes of STM and SPL bottom layer node, m%
                

                %Determination of the coordinates of the each cells%
                STS.phi=STS.dphi/2:STS.dphi:STS.total_azimuth_angle-STS.dphi/2;            %Creating a vector of phi, central point, °%
                STS.theta=(STS.dtheta/2):STS.dtheta:(STS.total_polar_angle-STS.dtheta/2); %Creating a vector of theta, central point, °%

                STS.theta_cell=repmat(STS.theta,length(STS.phi),1);    %Creation of the theta_cell,°%
                STS.phi_cell=repmat(STS.phi',1,length(STS.theta));     %Creation of the phi_cell, °%
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                %% Conversion of the spherical coordinates to the cartesian coordinates
                %For mapping since, only outer radius is enough as SR is applied only on the outer coordinates, conversion of the coordinates is done only for the outer coordinates%
                %******Data arrangement*********%
                STS.tot_cells=length(STS.theta)*length(STS.phi);    %Total number of cells in one layer%
                STS.theta_mat=reshape(STS.theta_cell,[],1);         %Converting matrix to column vector, °%
                STS.phi_mat=reshape(STS.phi_cell,[],1);             %Converting phi matrix to column vector, °%
                STS.rad_mat= STS.r3.*ones(STS.tot_cells,1);         %Creating the matrix of outer cell, m%
                STS.position_info=[STS.rad_mat STS.theta_mat STS.phi_mat ]; %Creating 60by 3 matrix in which each column are radius, theta and phi value%



                            
                
                %% Create the total three dimensional matrix of theta, phi, radius for the cell
                %Theta, phi of all nodes in each layer are same and radius of all nodes for one layer is same%
                STS.theta_cell_tot=repmat(STS.theta_cell,1,1,3);                    %Here, this means that repeat matrix theta_cell once in dimension 1, once in dimension 2, and 4 in dimension 3, °%
                STS.phi_cell_tot=repmat(STS.phi_cell,1,1,3);                        %Here, this means that repeat matrix theta_cell once in dimension 1, once in dimension 2, and 4 in dimension 3, °%
                STS.rad_cell_1=STS.r1.*ones(length(STS.phi),length(STS.theta));     %Radius matrix for the 1st layer, interior nodes, m%
                STS.rad_cell_2=STS.r2.*ones(length(STS.phi),length(STS.theta));     %Radius matrix for the 2nd layer, m%
                STS.rad_cell_3=STS.r3.*ones(length(STS.phi),length(STS.theta));     %Radius matrix for the 3rd layer, m%
                STS.rad_cell_tot=cat(3,STS.rad_cell_1,STS.rad_cell_2,STS.rad_cell_3); %Concatenates rad_cell_1, rad_cell_2....along the dimension 3, m%

                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %% Conversion into the universal cartesian coordinates%
                %Step 1: Conversion into cartesian coordinates for the given parent coordinate i.e. SOuth=+X, and West=+Y, Height=+Z%
                STS.x_par=STS.rad_cell_tot.*sind(STS.theta_cell_tot).*cosd(STS.phi_cell_tot);   %X-coordinate, parent axes, m%
                STS.y_par=STS.rad_cell_tot.*sind(STS.theta_cell_tot).*sind(STS.phi_cell_tot);   %Y-coordinate, parent axes, m%
                STS.z_par=STS.rad_cell_tot.*cosd(STS.theta_cell_tot);                           %Z-coordinate, parent axes, m%
                STS.xyz_par_r1=[reshape(STS.x_par(:,:,1),[],1) reshape(STS.y_par(:,:,1),[],1) reshape(STS.z_par(:,:,1),[],1) ]; %Matrix of innermost layer with the parent cartesian coordinates, size (:,3)%
                STS.xyz_par_r2=[reshape(STS.x_par(:,:,2),[],1) reshape(STS.y_par(:,:,2),[],1) reshape(STS.z_par(:,:,2),[],1) ]; %Matrix of second layer with the parent cartesian coordinates, size (:,3)%
                STS.xyz_par_r3=[reshape(STS.x_par(:,:,3),[],1) reshape(STS.y_par(:,:,3),[],1) reshape(STS.z_par(:,:,3),[],1) ]; %Matrix of third layer with the parent cartesian coordinates, size (:,3)%
                STS.xyz_par=cat(3,STS.xyz_par_r1,STS.xyz_par_r2,STS.xyz_par_r3); %Concatenates, xyz_par_r1, r2 and r3 in the third dimension, size(:,:,3)%
                
                
                % %Step 2: Conversion of cartesian coordinates from the given parent
                % %axes to the universal axes using rotation matrix, R%
                %Converting the XYZ coordinates to be consistent with SMM, updated 07/12/2021%
                STS.x_Reg=-STS.y_par;
                STS.y_Reg=STS.z_par;
                STS.z_Reg=STS.x_par;
                STS.xyz_Reg_r1=[reshape(STS.x_Reg(:,:,1),[],1) reshape(STS.y_Reg(:,:,1),[],1) reshape(STS.z_Reg(:,:,1),[],1) ]; %Matrix of innermost layer with the universal cartesian coordinate s/s, size(:,3)%
                STS.xyz_Reg_r2=[reshape(STS.x_Reg(:,:,2),[],1) reshape(STS.y_Reg(:,:,2),[],1) reshape(STS.z_Reg(:,:,2),[],1) ]; %Matrix of second layer with the universal cartesian coordinate s/s, size(:,3)%
                STS.xyz_Reg_r3=[reshape(STS.x_Reg(:,:,3),[],1) reshape(STS.y_Reg(:,:,3),[],1) reshape(STS.z_Reg(:,:,3),[],1) ]; %Matrix of third layer with the universal cartesian coordinate s/s, size(:,3)%
                STS.Regxyz=[STS.xyz_Reg_r1;STS.xyz_Reg_r2;STS.xyz_Reg_r3]; %Creating the single array in the third dimension, such that first 60 elements relates to the innermost layer, followed by outer respectively%        
                
        %For the mapping of the solar radiation values, only the outer coordinates is enough, so doing that%
              STS.STMregxyz=STS.Regxyz(2*STS.nnp+1:end,:); % STMxyz is the global coordinates of the outer nodes only size of (size(outernodes,1),3)%

                
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                
                %Determination of areas and relevant distances%
                %% Determination of the surface area of the differential element (correct, confirmed on 04/13/2021)
                STS.dAn=(STS.r.^2)*sind(STS.theta)*STS.dtheta_r*STS.dphi_r; %Surface area of the differential element normal to r (for the same 'Θ', this area will be same), m^2%
                STS.dAn_interface=(STS.R^2)*sind(STS.theta)*STS.dtheta_r*STS.dphi_r; %Surface area normal to radius for the interface between SPL and STM, m^2%
                STS.dAn_outer=((STS.R+STS.d)^2)*sind(STS.theta)*STS.dtheta_r*STS.dphi_r;%Surface area normal to outer radius, m^2%
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%for STS.dAth%%%%%%
                STS.dAth_comp1=STS.r*sind(STS.theta); %First component to determine dAth%
                STS.dAth_comp2=STS.dr.*STS.dphi_r;    %Second component to determine dAth%
                STS.dAth_r1=STS.dAth_comp1(1,1:6).*STS.dAth_comp2(1); %Differential area normal to the 'Θ' direction of the first (interface) layer elements, m^2%
                STS.dAth_r2=STS.dAth_comp1(2,1:6).*STS.dAth_comp2(2); %Differential area normal to the 'Θ' direction of the second layer elements, m^2%
                STS.dAth_r3=STS.dAth_comp1(3,1:6).*STS.dAth_comp2(3); %Differential area normal to the 'Θ' direction of the third (outer) layer elements, m^2%

                STS.dAth=[STS.dAth_r1;STS.dAth_r2;STS.dAth_r3]; %3D matrix with the differential area normal to 'Θ' direction for all three layers, m^2%
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                STS.dAphi=STS.r.*STS.dr.*STS.dtheta_r; %Surface area of the differential element normal to phi, m^2%
                STS.dc_phi_cell=(STS.r*sind(STS.theta)).*STS.dphi_r; %Distance between two cells in circumference, m%

                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %Setting up the numbering of the nodes in the STM%
                STS.Num=linspace(1,STS.totelem,STS.totelem); %Numbering the SPLT differential elements%
                STS.NumSTMmat=reshape(STS.Num,length(STS.phi),length(STS.theta),STS.n_d); %Converting the SPLT element numbering to the matrix form%
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        
                
            % Intialize the state variables, initialization and the set up
            % work in done under this setupImpl() function
                    
            STS.T=ones(length(STS.phi),length(STS.theta),length(STS.r)); %Initialization of the temperature values%
        end

        %% ================================================================
        %  MATLAB System Object stepImpl() Methods
        %  ================================================================
       
        %stepImpl() specifies the algorithm to execute when you run the
        %system object. The syntax is as follows: 
        %function[output1,output2,...] =stepImpl(obj,input1,input2,...)
        %end
        %TstepImpl() is called when you run the System Object. For this, 
        %you must set Access=protected in the methods
        
    function [SPL2STM,Index_Damage,T_SPL_Ext,T_Fir,T_Sec,T_Thi,SPL_Sec,Fir_SPL,Sec_SPL,Thi_SPL] = stepImpl(STS,STM2SPL1,Sb_tot,t,dt_2,Dam_SPL,ImpLoc, Start_angle,T_SPL_initialize)
  
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%            
        %%% All inputs and outputs to this function and their dimensionality are as
        %%% follows:
        %%     INPUTS        Description        Data Type     Unit       Dimension%
        %
        %  - STM2SPL1:   Temperature from         Float        (K)          10×6
        %                first layer of STM 
        %  - Sb_tot:    Solar Radiation Values    Float      (W/m^2)        10×6
        %                from SR model  
        %  - t:         Current Simulation Time   Float        (s)           1×1
        %  - dt_2:      Time Step for the         Float        (s)           1×1
        %               Structural System 
        %  - DamSPL:   Meteorite Impact Infor-    Float      (unitless)      1×1
        %              mation from Impact Model  
        %  - ImpLoc:   User Defined Impact        Float      (unitless)      1×3
        %              Location  
        %  - Start_angle: Simulation Start Time  Integer       (°)           1×1
        %               in one lunar cycle  
        %- T_SPL_initialize:Initial Temperature val- Float     (K)           10×6
        %              ues at different nodes of the
        %              SPL when simulation starts

        %%     OUTPUTS        Description        Data Type     Unit       Dimension%
        %
        % - SPL2STM:   Temperature from            Float        (K)          10×6
        %              third (inner/interface) 
        %              layer of SPL 
        % - Index_Damage:  Local Element number       Integer   (unitless)      1×1
        %               damaged due to impact  
        % - T_SPL_Ext: Exterior Layer Temperature   Float      (K)          60×1
        %              Values
        % - T_Fir:     Temperature Value of first   Float      (K)           1×1
        %              Layer node adjacent to 
        %              damaged element 
        % - T_Sec:     Temperature Value of Second   Float      (K)           1×1
        %              Layer node adjacent to 
        %              damaged element   
        % - T_Thi:     Temperature Value of third   Float      (K)           1×1
        %              Layer node adjacent to 
        %              damaged element 
        %- SPL_Sec:   Temperature from            Float        (K)          10×6
        %              Second layer of SPL 
        %- Fir_SPL:   Temperature from            Float        (K)          60×1
        %              first layer of SPL 
        %- Sec_SPL:   Temperature from            Float        (K)          60×1
        %              Second layer of SPL 
        %- Thi_SPL:   Temperature from            Float        (K)          60×1
        %             Third layer of SPL
        %             (Interface layer) 
        %              
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         %Based upon the user input, one can start with the given provided
         %simulation start angle: 0°,45°,90°, and 135°
         %The temperature initialization is done based upon the start of
         %the second lunar cycle so that we can have the thermal gradient 
         %on even at the start of the simulation to make it more realistic
         %%%%%%%Temperature Initialization%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

         if Start_angle==0 && t==0 %if the Simulation sun start angle is 0°%

              STS.T= T_SPL_initialize(:,:,:,1); %From workspace%

         elseif Start_angle==45 && t==0 %if the Simulation sun start angle is 45°%


                STS.T= T_SPL_initialize(:,:,:,2); %From workspace%


         elseif Start_angle==90 && t==0 %if the Simulation sun start angle is 90°%


                STS.T = T_SPL_initialize(:,:,:,3); %From workspace%


         elseif Start_angle==135 && t==0 %if the Simulation sun start angle is 135°%


                STS.T = T_SPL_initialize(:,:,:,4); %From workspace%


         end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        



        %Converting the SR to the matrix form SR(l,k)%
        SR_tot=reshape(Sb_tot, length(STS.phi), length(STS.theta)); %Converting the Solar Radiation vectors values to the matrix form, °%


       %% Mapping user-defined impact location to the specific STM element (outer layer)
       dxyz_US=ones(size(STS.STMregxyz,1),1)*1e5; % initialization 

       ImpLoc=ImpLoc'; %Converting the impact location 3by1 vector to 1by3%

       %Mapping function starts%
         for i=1:size(STS.STMregxyz,1)

            dxyz_Tmp_US = [STS.STMregxyz(i,:); 
                           ImpLoc];
            dxyz_US(i) = pdist(dxyz_Tmp_US); %Returns the euclidean distance between two pair of observations%
        end

        [~,Imp_Index] = min(dxyz_US); %a=minimum value of the vector dxyz, and Imp_Index=index corresponding to it (1 through 60)%

          %Each layer has 60 elements so total elements=180; 
          %The numbering of the elements are done such that out of three
          %layers,such that First Layer:1 through 60;
          %                 Second Layer: 60 through 120;
          %                 Third Layer: 120 through 180;
          %Imp_Index provides the numbering from the 1 through 60 so, in order to
          %map it to the outer layer node, 120 is added to the Imp_Index
          Index_Damage=Imp_Index+120; %Reads the index of the node that is closest to the required nodes,which is also the closed STM element to be damaged. 120 is added because we are trying to find the outermost STM element and we have 60 elements in each of those three layers%


         %The Index_Damage here provides the numbering/ index of the outer layer regolith layer, we need to convert into
         %the corresponding double 2D matrix to be able to solve using
         %the given formula

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %Finding the row(phi) and column(theta) on the third dimenstion of matrix STS.NumSTMmat to find which STM element is to be damaged%
        [Row_DamElem, Col_DamElem]=find(STS.NumSTMmat(:,:,3)==Index_Damage); %Row_DamElem=Row number corresponding to the Damaged Element,Col_DamElem=Column number corresponding to the Damaged Element% 
        %Row_DamElem= 'Φ' of damaged element;
        %Col_DamElem= 'Θ' of damaged element;

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %Initialization%
        T2=zeros(STS.nph,STS.nth,length(STS.r)); %Initialization%

        T1=STS.T; %The results from the previous time step%

        %Initialization of the components used in the calculation to determine the temperatures%
        %Each three-dimensional differential element has six sides and the the
        %energy flow per second from each of the six sides are labeled as: q1(North),
        %q2(South), q3(West),q4(East),q5(Top),q6(Bottom)

        q1=zeros(STS.nph,STS.nth,length(STS.r)); %First component of heat to the differential element, north side, W%
        q2=zeros(STS.nph,STS.nth,length(STS.r)); %Second component of heat to the differential element, south side, W%
        q3=zeros(STS.nph,STS.nth,length(STS.r)); %Third component of heat to the differential element, west side, W%
        q4=zeros(STS.nph,STS.nth,length(STS.r)); %Fourth component of heat to the differential element, east side, W%
        q5=zeros(STS.nph,STS.nth,length(STS.r)); %Fifth component of heat to the differential element, top side, W%
        q6=zeros(STS.nph,STS.nth,length(STS.r)); %Sixth component of heat to the differential element, bottom side, W%


    %Starting of the loop%
    %There are three loops inside it corresponding to j, k, and l:
    %j=radius part; k=theta part; l=phi part. So, these three nested loops
    %will take into each SPLT elements and determine the heat energy per
    %second (Watts) from all six sides and are named as: q1,q2,q3,q4,q5,q6
    %So, basically, this loop is determining the heat flux of all
    %elements from all sides and finally based upon that determining the
    %temperatures of all elements using the explicit-finite difference
    %elements
       for j=1:length(STS.r) %1 to number of layers (3)%

              for k=1:length(STS.theta) %1 to length of the Θ%

                     for l=1:length(STS.phi) %1 to length of Φ%

                            %Condition for the q1 part, North Side%
                           if l==length(STS.phi) %Last element in the phi direction%

                               q1(l,k,j)=STS.k_reg*STS.dAphi(j)/STS.dc_phi_cell(j,k)*(T1(1,k,j)-T1(l,k,j)); %Heat energy towards the differential element from north side, W%

                           else

                               q1(l,k,j)=STS.k_reg*STS.dAphi(j)/STS.dc_phi_cell(j,k)*(T1(l+1,k,j)-T1(l,k,j)); %Heat energy towards the differential element from north side, W%


                           end

                            %Condition for the q2 part, South Side%
                           if l==1 %The first differential element in the phi direction%

                               q2(l,k,j)=STS.k_reg*STS.dAphi(j)/STS.dc_phi_cell(j,k)*(T1(length(STS.phi),k,j)-T1(l,k,j)); %Heat energy towards the differential element from south side, W%

                           else

                               q2(l,k,j)=STS.k_reg*STS.dAphi(j)/STS.dc_phi_cell(j,k)*(T1(l-1,k,j)-T1(l,k,j));   %Heat energy towards the differential element from south side, W%


                           end

                             %Condition for the q3 part, West Side%
                           if k==length(STS.theta) %The nodes touching the base of the dome%

                               q3(l,k,j)=STS.k_reg*1.10*STS.dAth(j,k)/(STS.dtheta_r/2)*(STS.Tfoundation-T1(l,k,j)); %Heat energy towards the differential element from west side, W%

                           else

                               q3(l,k,j)=STS.k_reg*mean([STS.dAth(j,k),STS.dAth(j,k+1)])/STS.dtheta_r*(T1(l,k+1,j)-T1(l,k,j)); %Heat energy towards the differential element from east side, W%


                           end

                           %Condition for the q4 part, East Side%
                           if k==1 %the nodes near to the dome top%

                               q4(l,k,j)=0;  %Heat energy towards the differential element from east side, W%

                           else

                               q4(l,k,j)=STS.k_reg*mean([STS.dAth(j,k),STS.dAth(j,k-1)])/STS.dtheta_r*(T1(l,k-1,j)-T1(l,k,j)); %Heat energy towards the differential element from east side, W%


                           end

                           %Condition for the q5 part, Top Side%
                           if j==length(STS.r) %outer nodes exposed to the external environment%

                               q5(l,k,j)=(STS.abs_reg*SR_tot(l,k)+STS.emis_reg*STS.sigma*(STS.Tspace^4-T1(l,k,j)^4))*STS.dAn(j,k); %Heat energy towards the differential element from Top side, W%

                           else

                               q5(l,k,j)=STS.k_reg*mean([STS.dAn(j,k),STS.dAn(j+1,k)])/STS.n*(T1(l,k,j+1)-T1(l,k,j));   %Heat energy towards the differential element from Top side, W%


                           end

                           %Condition for the q6 part, Bottom Side%
                           if j==1 %meaning the nodes of the interior part in contact to the STM%

                               q6(l,k,j)=(STM2SPL1(l,k)-T1(l,k,j))/(STS.m2/(STS.k_con*STS.dAn_interface(k))+STS.m/(STS.k_reg*STS.dAn_interface(k))); %Heat energy towards the differential element from Bottom side, W%

                           else

                               q6(l,k,j)=STS.k_reg*mean([STS.dAn(j,k),STS.dAn(j-1,k)])/STS.n*(T1(l,k,j-1)-T1(l,k,j));  %Heat energy towards the differential element from Bottom side, W%


                           end



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Incorporation of the damage and Repairibility scenario%
    %Damage Scenario can be incorporated by providing the outer B.C. which is
    %the solar radiation and the emissivity on the top/ sides/ bottom of the element 
    %so in this step, we will replace the q1/q2/....q6 portion considering
    %that specific STM element is exposed to the surface. 

    %Case A: Damageability and Repairability scenario applied to the SPLT
    %element whose north side element is subjected to the damage and repair scenario
    %Dam_SPL is a scalar value that provides the intensity of the damage in
    %the Structural Protective Layer (SPL). The value ranges from 0-1 with
    %0=Sound SPL health;
    %1=complete damage of the STM element. 
    %Following assumptions were made for the damageability scenario:
    %%      SPL_Dam                      Layer Damaged
    %        <0.10                      No damage at all
    %      0.10-0.30                    Top SPL Layer Damaged
    %      0.30-0.60                    Second SPL Layer Damaged
    %        >0.60                      Third (All) SPL Layers Damaged 
    
    
    if Row_DamElem(1)~=1 %if the 'Φ'angle of the damaged SPLT element is not 1%
        if (l+1)==Row_DamElem(1) && k==Col_DamElem(1)

            if Dam_SPL>0.10 && Dam_SPL<=0.30 && j==3 %Only the top layer is damaged%
                 q1(l,k,j)=(STS.abs_reg*SR_tot(l+1,k)+STS.emis_reg*STS.sigma*(STS.Tspace^4-T1(l,k,j)^4))*STS.dAphi(j); %Providing the S.R. B.C. to the exposed north side surface, W%

            elseif Dam_SPL>0.30 && Dam_SPL<=0.60 && (j==3 || j==2) %Top two layers are damaged%
                 q1(l,k,j)=(STS.abs_reg*SR_tot(l+1,k)+STS.emis_reg*STS.sigma*(STS.Tspace^4-T1(l,k,j)^4))*STS.dAphi(j); %Providing the S.R. B.C. to the exposed north side surface, W%
            elseif Dam_SPL>0.60 && (j==3 || j==2 || j==1) %All three layers are damaged%
                 q1(l,k,j)=(STS.abs_reg*SR_tot(l+1,k)+STS.emis_reg*STS.sigma*(STS.Tspace^4-T1(l,k,j)^4))*STS.dAphi(j); %Providing the S.R. B.C. to the exposed north side surface, W%

            end

        end
    else  %if the 'Φ'angle of the damaged SPLT element is not equal to 1%

       if l==length(STS.phi) && k==Col_DamElem(1)

            if Dam_SPL>0.10 && Dam_SPL<=0.30 && j==3  %Only the top layer is damaged%
                 q1(l,k,j)=(STS.abs_reg*SR_tot(1,k)+STS.emis_reg*STS.sigma*(STS.Tspace^4-T1(l,k,j)^4))*STS.dAphi(j); %Providing the S.R. B.C. to the exposed north side surface, W%

            elseif Dam_SPL>0.30 && Dam_SPL<=0.60 && (j==3 || j==2)%Top two layers are damaged%
                 q1(l,k,j)=(STS.abs_reg*SR_tot(1,k)+STS.emis_reg*STS.sigma*(STS.Tspace^4-T1(l,k,j)^4))*STS.dAphi(j); %Providing the S.R. B.C. to the exposed north side surface, W%
            elseif Dam_SPL>0.60 && (j==3 || j==2 || j==1)%All three layers are damaged%
                 q1(l,k,j)=(STS.abs_reg*SR_tot(1,k)+STS.emis_reg*STS.sigma*(STS.Tspace^4-T1(l,k,j)^4))*STS.dAphi(j); %Providing the S.R. B.C. to the exposed north side surface, W%

            end

        end 

    end
    %Case B: Damageability and Repairability scenario applied to the SPLT
    %element whose south side element is subjected to the damage and repair scenario
    if Row_DamElem(1)~=length(STS.phi) %if the damaged element is not the last element in the 'Φ' angle%

        if (l-1)==Row_DamElem(1) && k==Col_DamElem(1)

            if Dam_SPL>0.10 && Dam_SPL<=0.30 && j==3   %Only the top layer is damaged%
                 q2(l,k,j)=(STS.abs_reg*SR_tot(l-1,k)+STS.emis_reg*STS.sigma*(STS.Tspace^4-T1(l,k,j)^4))*STS.dAphi(j); %Providing the S.R. B.C. to the exposed south side surface, W%

            elseif Dam_SPL>0.30 && Dam_SPL<=0.60 && (j==3 || j==2) %Top two layers are damaged%
                 q2(l,k,j)=(STS.abs_reg*SR_tot(l-1,k)+STS.emis_reg*STS.sigma*(STS.Tspace^4-T1(l,k,j)^4))*STS.dAphi(j); %Providing the S.R. B.C. to the exposed south side surface, W%
            elseif Dam_SPL>0.60 && (j==3 || j==2 || j==1) %All three layers are damaged%
                 q2(l,k,j)=(STS.abs_reg*SR_tot(l-1,k)+STS.emis_reg*STS.sigma*(STS.Tspace^4-T1(l,k,j)^4))*STS.dAphi(j); %Providing the S.R. B.C. to the exposed south side surface, W%

            end

        end

    else   %if the damaged element is the last element in the 'Φ' angle%

        if l==1 && k==Col_DamElem(1)

            if Dam_SPL>0.10 && Dam_SPL<=0.30 && j==3 %Only the top layer is damaged%
                 q2(l,k,j)=(STS.abs_reg*SR_tot(length(STS.phi),k)+STS.emis_reg*STS.sigma*(STS.Tspace^4-T1(l,k,j)^4))*STS.dAphi(j);%Providing the S.R. B.C. to the exposed south side surface, W%

            elseif Dam_SPL>0.30 && Dam_SPL<=0.60 && (j==3 || j==2) %Top two layers are damaged%
                 q2(l,k,j)=(STS.abs_reg*SR_tot(length(STS.phi),k)+STS.emis_reg*STS.sigma*(STS.Tspace^4-T1(l,k,j)^4))*STS.dAphi(j); %Providing the S.R. B.C. to the exposed south side surface, W%
            elseif Dam_SPL>0.60 && (j==3 || j==2 || j==1) %All three layers are damaged%
                 q2(l,k,j)=(STS.abs_reg*SR_tot(length(STS.phi),k)+STS.emis_reg*STS.sigma*(STS.Tspace^4-T1(l,k,j)^4))*STS.dAphi(j);%Providing the S.R. B.C. to the exposed south side surface, W%

            end

        end

    end
    %Case C: Damageability and Repairability scenario applied to the SPLT
    %element whose west side element is subjected to the damage and repair scenario

    if l==Row_DamElem(1) && (k+1)==Col_DamElem(1)

        if Dam_SPL>0.10 && Dam_SPL<=0.30 && j==3 %Only the top layer is damaged%
             q3(l,k,j)=(STS.abs_reg*SR_tot(l,k+1)+STS.emis_reg*STS.sigma*(STS.Tspace^4-T1(l,k,j)^4))*mean([STS.dAth(j,k),STS.dAth(j,k+1)]); %Providing the S.R. B.C. to the exposed west side surface, K%

        elseif Dam_SPL>0.30 && Dam_SPL<=0.60 && (j==3 || j==2) %Top two layers are damaged%
             q3(l,k,j)=(STS.abs_reg*SR_tot(l,k+1)+STS.emis_reg*STS.sigma*(STS.Tspace^4-T1(l,k,j)^4))*mean([STS.dAth(j,k),STS.dAth(j,k+1)]); %Providing the S.R. B.C. to the exposed west side surface, K%
        elseif Dam_SPL>0.60 && (j==3 || j==2 || j==1) %All three layers are damaged%
             q3(l,k,j)=(STS.abs_reg*SR_tot(l,k+1)+STS.emis_reg*STS.sigma*(STS.Tspace^4-T1(l,k,j)^4))*mean([STS.dAth(j,k),STS.dAth(j,k+1)]); %Providing the S.R. B.C. to the exposed west side surface, K%

        end

    end

    %Case D: Damageability and Repairability scenario applied to the SPLT
    %element whose east side element is subjected to the damage and repair scenario

    if l==Row_DamElem(1) && (k-1)==Col_DamElem(1)

        if Dam_SPL>0.10 && Dam_SPL<=0.30 && j==3 %Only the top layer is damaged%
             q4(l,k,j)=(STS.abs_reg*SR_tot(l,k-1)+STS.emis_reg*STS.sigma*(STS.Tspace^4-T1(l,k,j)^4))*mean([STS.dAth(j,k),STS.dAth(j,k-1)]); %Providing the S.R. B.C. to the exposed east side surface, K%

        elseif Dam_SPL>0.30 && Dam_SPL<=0.60 && (j==3 || j==2) %Top two layers are damaged%
             q4(l,k,j)=(STS.abs_reg*SR_tot(l,k-1)+STS.emis_reg*STS.sigma*(STS.Tspace^4-T1(l,k,j)^4))*mean([STS.dAth(j,k),STS.dAth(j,k-1)]); %Providing the S.R. B.C. to the exposed east side surface, K%
        elseif Dam_SPL>0.60 && (j==3 || j==2 || j==1) %All three layers are damaged%
             q4(l,k,j)=(STS.abs_reg*SR_tot(l,k-1)+STS.emis_reg*STS.sigma*(STS.Tspace^4-T1(l,k,j)^4))*mean([STS.dAth(j,k),STS.dAth(j,k-1)]); %Providing the S.R. B.C. to the exposed east side surface, K%

        end

    end

    %Case E: Damageability and Repairability scenario applied to the SPLT
    %element top side element is subjected to the damage and repair scenario

    if l==Row_DamElem(1) && k==Col_DamElem(1)

        if Dam_SPL>0.10 && Dam_SPL<=0.30 && j==2 %Only the top layer is damaged%
             q5(l,k,j)=(STS.abs_reg*SR_tot(l,k)+STS.emis_reg*STS.sigma*(STS.Tspace^4-T1(l,k,j)^4))*STS.dAn(j,k); %Providing the S.R. B.C. to the exposed top side surface, K%

        elseif Dam_SPL>0.30 && Dam_SPL<=0.60 && j==1  %Top two layers are damaged%
             q5(l,k,j)=(STS.abs_reg*SR_tot(l,k)+STS.emis_reg*STS.sigma*(STS.Tspace^4-T1(l,k,j)^4))*STS.dAn(j,k); %Providing the S.R. B.C. to the exposed top side surface, K%


        end

    end

    %%%In this damage and repariability scenario, the damage from the
    %%%meteorite impact is considered such that the damage starts from the top
    %%%of the element

     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                      
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Calculation of the temperatures at all nodes%
      T2(l,k,j)=T1(l,k,j)+(dt_2/(STS.rho_reg*STS.dAth(j,k)*STS.r(j)*STS.dtheta_r*STS.c_reg))*(q1(l,k,j)+q2(l,k,j)+q3(l,k,j)+q4(l,k,j)+q5(l,k,j)+q6(l,k,j)); %Temperature calculation for new time step, K%



    %Checking, for damaged elements, the program returns "NaN" temperature
    %results because there will be no elements
        if Dam_SPL>0.10 && Dam_SPL<=0.30 && j==length(STS.r) && l==Row_DamElem(1) && k==Col_DamElem(1) %Only the top layer is damaged%
             T2(l,k,j)=NaN; %Providing "NaN" for the damaged element i.e. top layer element%

         elseif Dam_SPL>0.30 && Dam_SPL<=0.60 && j==2 && l==Row_DamElem(1) && k==Col_DamElem(1) %Top two layers are damaged%
             T2(l,k,j)=NaN; %Providing "NaN" for the damaged element i.e. top and 2nd layer element%      

         elseif Dam_SPL>0.60 && l==Row_DamElem(1) && k==Col_DamElem(1) %All three layers are damaged%     
             T2(l,k,j)=NaN; %Providing "NaN" for the damaged element i.e. all three elements of SPL% 
        end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



                end




             end


       end
      
  
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Outputs%
    %SPL2STM=Temperature from third (inner/interface) layer of the SPL, K %
    % SPL2STM=zeros(10,6); %Initialization%
    T2Temp=T2(:,:,1);
    SPL2STM=T2Temp; %Transfering the temperature results of third layer but r=1 here%
    Thi_SPL=reshape(SPL2STM,STS.nnp,1); %Reshaping the SPL2STM from matrix form to the vector form, size of 60×1%


    %T_SPL_Ext=Exterior (Top) Layer Temperature Values, K%
    % T_SPL_Ext=zeros(60,1); %Initialization%
    T_SPL_Ext=reshape(T2(:,:,3),[],1); %Transfering the external surface temperature%
    Fir_SPL=T_SPL_Ext; %Temperature values of the external surface elements, size of 60×1%

    %T_Fir is the temperature values at the adjacent element of the damaged
    %element in the top layer of SPL
    % T_Fir=0; %Initialization%
    T_Fir =T2(Row_DamElem(1)+1,Col_DamElem(1),3); %Temperature Value at the adjacent damaged STM element on topmost(first) layer of the SPL, K%

    %T_Sec is the temperature values at the adjacent element of the damaged
    %element in the Second layer 
    % T_Sec=0; %Initialization%
    T_Sec =T2(Row_DamElem(1)+1,Col_DamElem(1),2); %Temperature Value of the adjacent element to the damaged STM element on second layer of the SPL, K%

    %T_Thi is the temperature values at the adjacent element of the damaged
    %element in the Second layer
    % T_Thi=0; %Initialization%
    T_Thi =T2(Row_DamElem(1)+1,Col_DamElem(1),1); %Temperature Value of the adjacent element to the damaged STM element on third layer of the SPL, K%

    %SPL_Sec=Temperature from second layer of the SPL, K %
    % SPL_Sec=zeros(10,6); %Initialization%
    SPL_Sec=T2(:,:,2); %Transfering the temperature results of second layer but r=2 here%
    Sec_SPL=reshape(SPL_Sec,STS.nnp,1); %Reshaping the SPL_Sec matrix from %

  
    %% Update state variables for next timestep
    STS.T=T2; %updating the state variable for the next time step%
         
        end
        
        
         %% isOutputFixedSizeImpl()
         
        %This isOutputFixedSizeImpl() accepts the system object handle and
        %returns an array of flags. Array size is equal to the size of the
        %output ports. The value of their flags and their meanings are:
        %true=the output size is fixed (the output port on MATLAB System block)
        %creates the fixed-size signal;
        %false: Variable output size;
       
        function [f1, f2, f3,f4,f5,f6,f7,f8,f9,f10] = isOutputFixedSizeImpl(~) %Since any parameters are not used related to STS, so "~" was used as input%
            
            %We have 10 output ports in this system and each
            %f1,f2,f3.... represents the corresponding output ports and "true"
            %or "false" tells if they have variable or fixed output size
            
            f1=true; %Have fixed output size, SPL2STM%
            f2=true; %Have fixed output size, Index_Damage%
            f3=true; %Have fixed output size, T_SPL_Ext%
            f4=true; %Have fixed output size, T_Fir%
            f5=true; %Have fixed output size, T_Sec%
            f6=true; %Have fixed output size, T_Thi%
            f7=true; %Have fixed output size, SPL_Sec%
            f8=true; %Have fixed output size, Fir_SPL%
            f9=true; %Have fixed output size, Sec_SPL%
            f10=true; %Have fixed output size, Thi_SPL%            
        end
        
        
     %% getOutputSizeImpl()
     %[sz_1,sz_2,...,sz_n] = getOutputSizeImpl(obj) returns the size of 
     %each output port. The number of outputs must match the value returned
     %from the getNumOutputs method or the number of output arguments 
     %listed in the stepImpl() method.
     
        function [s1, s2, s3,s4,s5,s6,s7,s8,s9,s10] = getOutputSizeImpl(STS)
           
            %We have 10 output ports in this system and each
            %s1,s2,s3.... represents the corresponding output ports and
            %values on the right provides the size of each of the output
            %port
            
            s1 = [STS.nph STS.nth];                    %Size of s1=SPL2STM%
            s2 = [1 1];                                %Size of s2=Index_Damage%
            s3 = [STS.nnp 1];                          %Size of s3=T_SPL_Ext%
            s4 = [1 1];                                %Size of s4=T_Fir%
            s5 = [1 1];                                %Size of s5=T_Sec%
            s6 = [1 1];                                %Size of s6=T_Thi%
            s7 = [STS.nph STS.nth];                    %Size of s7=SPL_Sec%
            s8 = [STS.nnp 1];                          %Size of s8=Fir_SPL%
            s9 = [STS.nnp 1];                          %Size of s9=Sec_SPL%            
            s10 = [STS.nnp 1];                          %Size of s10=Thi_SPL%            
  
        end   
        
         %% getOutputDataTypeImpl()
         %[dt_1,dt_2,...,dt_n] = getOutputDataTypeImpl(obj) returns the 
         %data type of each output port as a character vector for built-in
         %data types or as a numeric object for fixed-point data types.
         %The number of outputs must match the value returned from the 
         %getNumOutputsImpl method or the number of output arguments listed
         %in the stepImpl method.
         
        function [d1, d2, d3,d4,d5,d6,d7,d8,d9,d10] = getOutputDataTypeImpl(~)
       
            %We have 10 output ports in this system and each
            %d1,d2,d3.... represents the corresponding output ports and
            %values on the right provides the data type of each of the output
            %port
            
            d1 = 'double'; %Data Type of first output, SPL2STM%
            d2 = 'double'; %Data Type of 2nd output, Index_Damage%
            d3 = 'double'; %Data Type of 3rd output, T_SPL_Ext%
            d4 = 'double'; %Data Type of 4th output, T_Fir%
            d5 = 'double'; %Data Type of 5th output, T_Sec%
            d6 = 'double'; %Data Type of 6th output, T_Thi%
            d7 = 'double'; %Data Type of 7th output, SPL_Sec%
            d8 = 'double'; %Data Type of 8th output, Fir_SPL%
            d9 = 'double'; %Data Type of 7th output, Sec_SPL%
            d10 = 'double'; %Data Type of 8th output, Thi_SPL%
        end
        
        %% isOutputComplexImpl()
        %[cp_1,cp_2,...,cp_n] = isOutputComplexImpl(obj) returns whether 
        %each output port has complex data. The number of outputs must
        %match the value returned from the getNumOutputs method or the 
        %number of output arguments listed in the stepImpl method.
        
        function [c1, c2, c3,c4,c5,c6,c7,c8,c9,c10] = isOutputComplexImpl(~)
           
            %We have 10 output ports in this system and each
            %c1,c2,c3.... represents the corresponding output ports and
            %values on the right provides the if the output data type is
            %a complex number or not
            
            c1=false; %Not a complex number%
            c2=false; %Not a complex number%
            c3=false; %Not a complex number%
            c4=false; %Not a complex number%
            c5=false; %Not a complex number%
            c6=false; %Not a complex number%
            c7=false; %Not a complex number%
            c8=false; %Not a complex number%
            c9=false; %Not a complex number%
            c10=false; %Not a complex number%
        end
       
        

        
    end
    
    
end



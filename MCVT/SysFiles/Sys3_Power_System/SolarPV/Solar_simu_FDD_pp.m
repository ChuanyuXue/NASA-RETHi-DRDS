function K=Solar_simu_FDD_pp(Ts,zita)
    % Purpose: Compute poles of the simulated solar PV dust FDD which is
    %          modeled by a second order linear dynamical system.
    
    % Inputs:  1) Ts (float): settling time of the simulated solar PV dust FDD.
    %          2) zita (float): damping ratio.
    % Outputs: 1) K (float): feedback gain.
    
    % Date Created: 1 March 2021
    % Date Last Modified: 1 September 2021
    % Modeler Name: Kairui Hao (Purdue)
    % Funding Acknowledgement: Space Technology Research Institutes Grant 
    %                          80NSSC19K1076 from NASA's Space Technology 
    %                          Research Grants Program.
    % Version Number: MCVT v5   

    % construct the controllable canonical form of A
    CatNum = 4;
    A=zeros(2*CatNum,2*CatNum);
    Ablock1=[0 1;-1,-1];
    Ablock2=[0,0;-1,-1];
    A1=kron(eye(CatNum),Ablock1);
    A2=kron(ones(CatNum)-eye(CatNum),Ablock2);
    A=A1+A2;

    % construct the controllable canonical form of B
    Bblock1=eye(CatNum)+triu(-1*ones(CatNum),1);
    Bblock2=[0;1];
    B=kron(Bblock1,Bblock2);

    % Pole placement
    wn=4/(Ts*zita);
    y=wn*sqrt(1-zita^2);
    x=4/Ts;
    poles=repmat([-x+y*1i,-x-y*1i],1,CatNum);
    K=place(A,B,poles);
    
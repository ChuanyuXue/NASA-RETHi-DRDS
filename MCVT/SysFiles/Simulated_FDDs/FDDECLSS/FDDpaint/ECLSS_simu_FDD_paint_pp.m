function K=ECLSS_simu_FDD_paint_pp(Ts,zita)
A=[0, 1; -1, -1];   % controllable canonical form of the second order system
B=[0 ; 1];
wd=1/10;            % default imaginary coordinate when zita is 0
% specify poles location
if zita==0
    % handle zita = 0 case
    x=0;
    y=wd;
else
    wn=4/(Ts*zita);
    x=4/Ts;
    y=wn*sqrt(1-zita^2);
end

poles=[-x+y*1i,-x-y*1i];
% closed loop pole placement
K=place(A,B,poles);
%% Initialize ECLSS system FDD
% 1) dust accumulation
Ts_ECLSS_dust = 20;% * dt/dt_5;% * ration = dt/dt_5 Settling time of ECLSS Dust FDD
zita_ECLSS_dust = 0.707;
K_ECLSS_dust_single = ECLSS_simu_FDD_dust_pp(Ts_ECLSS_dust,zita_ECLSS_dust);
% 2) paint damage
Ts_ECLSS_paint = 20;% * dt/dt_5; %5; % Settling Time of ECLSS Paint FDD
zita_ECLSS_paint = 0.707;
K_ECLSS_paint_single = ECLSS_simu_FDD_paint_pp(Ts_ECLSS_paint,zita_ECLSS_paint);
%% Initialize Structure Sim FDD
% Damage Detection
Ts_Structure_damage = 5; % Settling time of Structure Damage FDD
zita_Structure_damage = 0.707; % Damping ratio of the 2nd order system
K_Structure_damage_single = Structure_simu_FDD_damage_pp(Ts_Structure_damage,zita_Structure_damage);
function [damage_index] = splt_damage_index(met_location)

location_1 = [1.0631    2.4778    1.0679];
location_2 = [2.4779    1.0628    1.0679];
location_3 = [1.0622    1.0619    2.4807];
location_4 = [-1.0679    2.4778    1.0631];
location_5 = [-1.0679    1.0628    2.4779];
location_6 = [-2.4807    1.0619    1.0622];
location_7 = [-1.0631    2.4778   -1.0679];
location_8 = [-2.4779    1.0628   -1.0679];
location_9 = [-1.0622    1.0619   -2.4807];
location_10 = [1.0679    2.4778   -1.0631];
location_11 = [1.0679    1.0628   -2.4779];
location_12 = [2.4808    1.0619   -1.0622];

if met_location == location_1
    damage_index = 149;
elseif met_location == location_2
    damage_index = 169;
elseif met_location == location_3
    damage_index = 170;
elseif met_location == location_4
    damage_index = 142;
elseif met_location == location_5
    damage_index = 161;    
elseif met_location == location_6
    damage_index = 162;
elseif met_location == location_7
    damage_index = 144;
elseif met_location == location_8
    damage_index = 164;
elseif met_location == location_9
    damage_index = 165;
elseif met_location == location_10
    damage_index = 147;
elseif met_location == location_11
    damage_index = 166;    
elseif met_location == location_12
    damage_index = 167;  
end

end


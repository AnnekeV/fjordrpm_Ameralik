function b = compute_budget2(s, p, z_bnd, Sref)
%% compute_budget: builds freshwater, salt, heat budget terms into structure b
% Inputs:
%   s      - structure with ocean state variables (S, T, QVsurf, etc.)
%   p      - structure with parameters (W, L, H, N, sid, etc.)
%   z_bnd  - two-element vector [top_depth, bottom_depth] defining budget box
%   Sref   - reference salinity


layers = find(abs(s.z) >= z_bnd(1) & abs(s.z) < z_bnd(2));
Tf = min(s.T, [], 'all');


%% tendencies
FW_layer = p.W*p.L*((Sref-s.S)/Sref).*s.H;
FW_box = sum(FW_layer(layers,:),1);
FW_tendency = [diff(FW_box)./(p.sid*diff(s.t)),NaN]; % m3/s
salt_layer = p.W*p.L*s.S.*s.H;
salt_box = sum(salt_layer(layers,:),1);
salt_tendency = [diff(salt_box)./(p.sid*diff(s.t)),NaN]; % m3/s

s.rho = calculateDensity(s.S, s.T);
heat_layer = p.W*p.L.*s.H.*(s.T-Tf).*s.rho;
b.heat_box = sum(heat_layer(layers,:),1);
b.heat_tendency = [diff(b.heat_box)./(p.sid*diff(s.t)),NaN]; % m3/s

%% river fluxes (assumes river input has salinity 0)
Q_river = sum(s.QVsurf(layers,:),1);
FW_river = Q_river;
salt_river = 0*s.t;
b.heat_river =  p.W*p.L.*s.H.*(0-Tf).*s.rho;


%% vertical advective fluxes
% base of selected box
if layers(end)==p.N % if budget box extends to fjord bottom
    Q_vert_base = 0*s.t;
    FW_vert_base = 0*s.t;
    salt_vert_base = 0*s.t;
else
    Q_vert_base = sum(s.QVv(1:layers(end),:),1);
    % nb relevant salinity depends on whether flux is directed up or down
    S_vert_base = NaN*s.t;
    S_vert_base(Q_vert_base>=0) = s.S(layers(end)+1,Q_vert_base>=0);
    S_vert_base(Q_vert_base<0) = s.S(layers(end),Q_vert_base<0);
    FW_vert_base = Q_vert_base.*(Sref-S_vert_base)/Sref;
    salt_vert_base = sum(s.QSv(1:layers(end),:),1);
end
% top of selected box
if layers(1)==1 % if budget box extends to fjord surface
    Q_vert_top = 0*s.t;
    FW_vert_top = 0*s.t;
    salt_vert_top = 0*s.t;
else
    Q_vert_top = sum(s.QVv(1:layers(1)-1,:),1);
    S_vert_top = NaN*s.t;
    S_vert_top(Q_vert_top>=0) = s.S(layers(1),Q_vert_top>=0);
    S_vert_top(Q_vert_top<0) = s.S(layers(1)-1,Q_vert_top<0);
    FW_vert_top = Q_vert_top.*(Sref-S_vert_top)/Sref;
    salt_vert_top = sum(s.QSv(1:layers(1)-1,:),1);
    % Q_vert_top is positive if leaving the box, so need extra minus
    Q_vert_top = -Q_vert_top;
    FW_vert_top = -FW_vert_top;
    salt_vert_top = -salt_vert_top;
end

%% shelf fluxes
Q_shelf = sum(s.QVs(layers,:),1);
S_fw = NaN*s.S;
S_fw(s.QVs>=0) = s.Ss(s.QVs>=0);
S_fw(s.QVs<0) = s.S(s.QVs<0);
FW_shelf_layer = s.QVs.*(Sref-S_fw)/Sref;
FW_shelf = sum(FW_shelf_layer(layers,:),1);
salt_shelf = sum(s.QSs(layers,:),1);


FW_shelf_layer_profile = FW_shelf_layer ./s.H; 

FW_shelf = sum(FW_shelf_layer(layers,:),1);
salt_shelf = sum(s.QSs(layers,:),1);

FW_to_shelf = sum(max(0, -FW_shelf_layer(layers,:)),1);
FW_to_fjord = sum(max(0, FW_shelf_layer(layers,:)),1);

%% vertical mixing fluxes
% no volume exchange
Q_mix_base = 0*s.t;
Q_mix_top = 0*s.t;
% base of selected box
if layers(end)==p.N % if budget box extends to fjord bottom
    FW_mix_base = 0*s.t;
    salt_mix_base = 0*s.t;
else
    salt_mix_base = sum(s.QSk(1:layers(end),:),1);
    FW_mix_base = -salt_mix_base/Sref;
end
% top of selected box
if layers(1)==1 % if budget box extends to fjord surface
    FW_mix_top = 0*s.t;
    salt_mix_top = 0*s.t;
else
    salt_mix_top = -sum(s.QSk(1:layers(1)-1,:),1);
    FW_mix_top = -salt_mix_top/Sref;
end

%% vertical convective fluxes
% no volume exchange
Q_con_base = 0*s.t;
Q_con_top = 0*s.t;
% base of selected box
if layers(end)==p.N % if budget box extends to fjord bottom
    FW_con_base = 0*s.t;
    salt_con_base = 0*s.t;
else
    salt_con_base = sum(s.QSc(1:layers(end),:),1);
    FW_con_base = -salt_con_base/Sref;
end
% top of selected box
if layers(1)==1 % if budget box extends to fjord surface
    FW_con_top = 0*s.t;
    salt_con_top = 0*s.t;
else
    salt_con_top = -sum(s.QSc(1:layers(1)-1,:),1);
    FW_con_top = -salt_con_top/Sref;
end
% convective fluxes are offset by 1 timestep compared to other fluxes
FW_con_base = [FW_con_base(2:end),NaN];
salt_con_base = [salt_con_base(2:end),NaN];
FW_con_top = [FW_con_top(2:end),NaN];
salt_con_top = [salt_con_top(2:end),NaN];

%% sum of terms to check we've got it right
% (volume fluxes should sum to 0)
% (freshwater fluxes should sum to FW_tendency)
% (salt fluxes should sum to sal_tendency)
Q_sum = Q_river+Q_vert_top+Q_vert_base+Q_shelf;
FW_sum = FW_river+FW_vert_top+FW_vert_base+FW_shelf+FW_mix_top+FW_mix_base+FW_con_top+FW_con_base;
salt_sum = salt_river+salt_vert_top+salt_vert_base+salt_shelf+salt_mix_top+salt_mix_base+salt_con_top+salt_con_base;

FW_top = FW_vert_top+FW_mix_top+FW_con_top;
FW_base = FW_vert_base+FW_mix_base+FW_con_base;




%% assemble output structure
b.layers = layers;
b.FW_layer = FW_layer;
b.FW_box = FW_box;
b.FW_tendency = FW_tendency;
b.salt_box = salt_box;
b.salt_tendency = salt_tendency;

b.Q_river = Q_river;
b.FW_river = FW_river;
b.salt_river = salt_river;

b.Q_vert_top = Q_vert_top;
b.FW_vert_top = FW_vert_top;
b.salt_vert_top = salt_vert_top;

b.Q_vert_base = Q_vert_base;
b.FW_vert_base = FW_vert_base;
b.salt_vert_base = salt_vert_base;

b.Q_shelf = Q_shelf;
b.FW_shelf = FW_shelf;
b.FW_shelf_layer = FW_shelf_layer;
b.salt_shelf = salt_shelf;

b.Q_mix_top = Q_mix_top;
b.FW_mix_top = FW_mix_top;
b.salt_mix_top = salt_mix_top;

b.Q_mix_base = Q_mix_base;
b.FW_mix_base = FW_mix_base;
b.salt_mix_base = salt_mix_base;

b.Q_con_top = Q_con_top;
b.FW_con_top = FW_con_top;
b.salt_con_top = salt_con_top;

b.Q_con_base = Q_con_base;
b.FW_con_base = FW_con_base;
b.salt_con_base = salt_con_base;

b.Q_sum = Q_sum;
b.FW_sum = FW_sum;
b.salt_sum = salt_sum;

b.FW_top = FW_top;
b.FW_base = FW_base;

b.FW_to_shelf = FW_to_shelf;
b.FW_to_fjord = FW_to_fjord;
b.FW_shelf_layer_profile = FW_shelf_layer_profile;
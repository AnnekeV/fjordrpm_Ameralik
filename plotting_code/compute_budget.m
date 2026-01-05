function b = compute_budget(s, p, z_bnd, Sref)
%% compute_budget: builds freshwater, salt, heat budget terms into structure b
% Inputs:
%   s      - structure with ocean state variables (S, T, QVsurf, etc.)
%   p      - structure with parameters (W, L, H, N, sid, etc.)
%   z_bnd  - two-element vector [top_depth, bottom_depth] defining budget box
%   Sref   - reference salinity

layers = find(abs(s.z) >= z_bnd(1) & abs(s.z) < z_bnd(2));
Tf = min(s.T, [], 'all');

%% tendencies
b.FW_layer = p.W*p.L*((Sref-s.S)/Sref).*s.H;
b.FW_box = sum(b.FW_layer(layers,:),1);
b.FW_tendency = gradient(b.FW_box, s.t)/p.sid;

salt_layer = p.W*p.L*s.S.*s.H;
b.salt_box = sum(salt_layer(layers,:),1);
b.salt_tendency = gradient(b.salt_box,s.t)/p.sid;

s.rho = calculateDensity(s.S, s.T);
heat_layer = p.W*p.L.*s.H.*(s.T-Tf).*s.rho;
b.heat_box = sum(heat_layer(layers,:),1);
b.heat_tendency = gradient(b.heat_box, s.t)/p.sid;

%% river fluxes
b.Q_river = sum(s.QVsurf(layers,:),1);
b.FW_river = b.Q_river;
b.salt_river = 0*s.t;
b.heat_river =  p.W*p.L.*s.H.*(0-Tf).*s.rho;

%% vertical advective fluxes
if layers(end) == p.N
    b.Q_vert_base = 0*s.t;
    b.FW_vert_base = 0*s.t;
    b.salt_vert_base = 0*s.t;
else
    b.Q_vert_base = sum(s.QVv(1:layers(end),:),1);
    S_vert_base = NaN*s.t;
    S_vert_base(b.Q_vert_base>=0) = s.S(layers(end)+1, b.Q_vert_base>=0);
    S_vert_base(b.Q_vert_base<0) = s.S(layers(end), b.Q_vert_base<0);
    b.FW_vert_base = b.Q_vert_base.*(Sref-S_vert_base)/Sref;
    b.salt_vert_base = sum(s.QSv(1:layers(end),:),1);
end

if layers(1) == 1
    b.Q_vert_top = 0*s.t;
    b.FW_vert_top = 0*s.t;
    b.salt_vert_top = 0*s.t;
else
    b.Q_vert_top = sum(s.QVv(1:layers(1)-1,:),1);
    S_vert_top = NaN*s.t;
    S_vert_top(b.Q_vert_top>=0) = s.S(layers(1), b.Q_vert_top>=0);
    S_vert_top(b.Q_vert_top<0) = s.S(layers(1)-1, b.Q_vert_top<0);
    b.FW_vert_top = b.Q_vert_top.*(Sref-S_vert_top)/Sref;
    b.salt_vert_top = sum(s.QSv(1:layers(1)-1,:),1);
    b.Q_vert_top = -b.Q_vert_top;
    b.FW_vert_top = -b.FW_vert_top;
    b.salt_vert_top = -b.salt_vert_top;
end

%% shelf fluxes
b.Q_shelf = sum(s.QVs(layers,:),1);
S_fw = NaN*s.S;
S_fw(s.QVs>=0) = s.Ss(s.QVs>=0);
S_fw(s.QVs<0) = s.S(s.QVs<0);
b.FW_shelf_layer = s.QVs.*(Sref-S_fw)/Sref;

b.FW_shelf_layer_profile = b.FW_shelf_layer ./s.H; 

b.FW_shelf = sum(b.FW_shelf_layer(layers,:),1);
b.salt_shelf = sum(s.QSs(layers,:),1);

b.FW_to_shelf = sum(max(0, -b.FW_shelf_layer(layers,:)),1);
b.FW_to_fjord = sum(max(0, b.FW_shelf_layer(layers,:)),1);

%% vertical mixing
b.Q_mix_base = 0*s.t;
b.Q_mix_top = 0*s.t;

if layers(end)==p.N
    b.FW_mix_base = 0*s.t;
    b.salt_mix_base = 0*s.t;
else
    b.salt_mix_base = sum(s.QSk(1:layers(end),:),1);
    b.FW_mix_base = -b.salt_mix_base/Sref;
end

if layers(1)==1
    b.FW_mix_top = 0*s.t;
    b.salt_mix_top = 0*s.t;
else
    b.salt_mix_top = -sum(s.QSk(1:layers(1)-1,:),1);
    b.FW_mix_top = -b.salt_mix_top/Sref;
end

%% net vertical
b.Q_top = b.Q_mix_top + b.Q_vert_top;
b.Q_base = b.Q_mix_base + b.Q_vert_base;
b.FW_top = b.FW_mix_top + b.FW_vert_top;
b.FW_base = b.FW_mix_base + b.FW_vert_base;
b.salt_top = b.salt_mix_top + b.salt_vert_top;
b.salt_base = b.salt_mix_base + b.salt_mix_base;

%% checking sums
b.Q_sum = b.Q_river + b.Q_vert_top + b.Q_vert_base + b.Q_shelf;
b.FW_sum = b.FW_river + b.FW_vert_top + b.FW_vert_base + b.FW_shelf + b.FW_mix_top + b.FW_mix_base;
b.salt_sum = b.salt_river + b.salt_vert_top + b.salt_vert_base + b.salt_shelf + b.salt_mix_top + b.salt_mix_base;

end

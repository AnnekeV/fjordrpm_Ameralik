% code to calculate and plot a freshwater budget for a given set of
% layers
clear; close all;

% load model output
% load ../examples/example5_riverine_input.mat
load ameralik_combined_Kb1e-03_C01e+05.mat

% define layers for budget (defining our box)
layers = [20:20]; % [top layer:bottom layer]
layers = find(abs(s.z) >= 50 & abs(s.z) < 110);
% reference salinity
Sref = 34;

%% tendencies
FW_layer = p.W*p.L*((Sref-s.S)/Sref).*s.H;
FW_box = sum(FW_layer(layers,:),1);
FW_tendency = [diff(FW_box)./(p.sid*diff(s.t)),NaN]; % m3/s
salt_layer = p.W*p.L*s.S.*s.H;
salt_box = sum(salt_layer(layers,:),1);
salt_tendency = [diff(salt_box)./(p.sid*diff(s.t)),NaN]; % m3/s

%% river fluxes (assumes river input has salinity 0)
Q_river = sum(s.QVsurf(layers,:),1);
FW_river = Q_river;
salt_river = 0*s.t;

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

%% plots
figure();
subplot(3,1,1); hold on;
plot(s.t,Q_river,'linewidth',2);
plot(s.t,Q_shelf,'linewidth',2);
plot(s.t,Q_vert_top,'linewidth',2);
plot(s.t,Q_vert_base,'linewidth',2);
plot(s.t,Q_mix_top,'linewidth',2);
plot(s.t,Q_mix_base,'linewidth',2);
plot(s.t,Q_con_top,'linewidth',2);
plot(s.t,Q_con_base,'m','linewidth',2);
plot(s.t,Q_sum,'k--','linewidth',2);
legend('river','shelf','vert top','vert base','mix top','mix base','con top','con base','SUM');
ylabel('volume flux term (m^3/s)');
xlabel('day');

subplot(3,1,2); hold on;
plot(s.t,FW_river,'linewidth',2);
plot(s.t,FW_shelf,'linewidth',2);
plot(s.t,FW_vert_top,'linewidth',2);
plot(s.t,FW_vert_base,'linewidth',2);
plot(s.t,FW_mix_top,'linewidth',2);
plot(s.t,FW_mix_base,'linewidth',2);
plot(s.t,FW_con_top,'linewidth',2);
plot(s.t,FW_con_base,'m','linewidth',2);
plot(s.t,FW_sum,'k--','linewidth',2);
plot(s.t,FW_tendency,'r:','linewidth',2);
legend('river','shelf','vert top','vert base','mix top','mix base','con top','con base','SUM','tendency');
ylabel('FW flux term (m^3/s)');
xlabel('day');

subplot(3,1,3); hold on;
plot(s.t,salt_river,'linewidth',2);
plot(s.t,salt_shelf,'linewidth',2);
plot(s.t,salt_vert_top,'linewidth',2);
plot(s.t,salt_vert_base,'linewidth',2);
plot(s.t,salt_mix_top,'linewidth',2);
plot(s.t,salt_mix_base,'linewidth',2);
plot(s.t,salt_con_top,'linewidth',2);
plot(s.t,salt_con_base,'m','linewidth',2);
plot(s.t,salt_sum,'k--','linewidth',2);
plot(s.t,salt_tendency,'r:','linewidth',2);
legend('river','shelf','vert top','vert base','mix top','mix base','con top','con base','SUM','tendency');
ylabel('salt flux term');
xlabel('day');

figure();
subplot(3,1,1); hold on;
plot(s.t,Q_sum,'k','linewidth',2);
ylabel('volume closure');
subplot(3,1,2); hold on;
plot(s.t,FW_sum-FW_tendency,'k','linewidth',2);
ylabel('FW closure');
subplot(3,1,3); hold on;
plot(s.t,salt_sum-salt_tendency,'k','linewidth',2);
ylabel('salt closure');


%% plots2


load ameralik_combined_Kb1e-03_C01e+05.mat

compute_budget(s, p, [50,110],34)


figure();
subplot(3,1,1); hold on;
plot(s.t,Q_river,'linewidth',2);
plot(s.t,Q_shelf,'linewidth',2);
plot(s.t,Q_vert_top,'linewidth',2);
plot(s.t,Q_vert_base,'linewidth',2);
plot(s.t,Q_mix_top,'linewidth',2);
plot(s.t,Q_mix_base,'linewidth',2);
plot(s.t,Q_con_top,'linewidth',2);
plot(s.t,Q_con_base,'m','linewidth',2);
plot(s.t,Q_sum,'k--','linewidth',2);
legend('river','shelf','vert top','vert base','mix top','mix base','con top','con base','SUM');
ylabel('volume flux term (m^3/s)');
xlabel('day');

subplot(3,1,2); hold on;
plot(s.t,FW_river,'linewidth',2);
plot(s.t,FW_shelf,'linewidth',2);
plot(s.t,FW_vert_top,'linewidth',2);
plot(s.t,FW_vert_base,'linewidth',2);
plot(s.t,FW_mix_top,'linewidth',2);
plot(s.t,FW_mix_base,'linewidth',2);
plot(s.t,FW_con_top,'linewidth',2);
plot(s.t,FW_con_base,'m','linewidth',2);
plot(s.t,FW_sum,'k--','linewidth',2);
plot(s.t,FW_tendency,'r:','linewidth',2);
legend('river','shelf','vert top','vert base','mix top','mix base','con top','con base','SUM','tendency');
ylabel('FW flux term (m^3/s)');
xlabel('day');

subplot(3,1,3); hold on;
plot(s.t,salt_river,'linewidth',2);
plot(s.t,salt_shelf,'linewidth',2);
plot(s.t,salt_vert_top,'linewidth',2);
plot(s.t,salt_vert_base,'linewidth',2);
plot(s.t,salt_mix_top,'linewidth',2);
plot(s.t,salt_mix_base,'linewidth',2);
plot(s.t,salt_con_top,'linewidth',2);
plot(s.t,salt_con_base,'m','linewidth',2);
plot(s.t,salt_sum,'k--','linewidth',2);
plot(s.t,salt_tendency,'r:','linewidth',2);
legend('river','shelf','vert top','vert base','mix top','mix base','con top','con base','SUM','tendency');
ylabel('salt flux term');
xlabel('day');

figure();
subplot(3,1,1); hold on;
plot(s.t,Q_sum,'k','linewidth',2);
ylabel('volume closure');
subplot(3,1,2); hold on;
plot(s.t,FW_sum-FW_tendency,'k','linewidth',2);
ylabel('FW closure');
subplot(3,1,3); hold on;
plot(s.t,salt_sum-salt_tendency,'k','linewidth',2);
ylabel('salt closure');


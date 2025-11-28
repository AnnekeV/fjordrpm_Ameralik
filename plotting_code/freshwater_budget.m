% code to calculate and plot a freshwater budget for a given set of
% layers
% clear; close all;

% load model output
load ../ameralik_nuup_kangerlua/ameralik_combined_Kb1e-04_C01e+04.mat

% define layers for budget (defining our box)
z_bnd = [0, 56];
layers = find(abs(s.z)>z_bnd(1)&abs(s.z)<z_bnd(2)); % [top layer:bottom layer]
% reference salinity
Sref = 34;


%% tendencies
FW_layer = p.W*p.L*((Sref-s.S)/Sref).*s.H;
FW_box = sum(FW_layer(layers,:),1);
FW_tendency = gradient(FW_box,s.t)/p.sid; % m3/s
salt_layer = p.W*p.L*s.S.*s.H;
salt_box = sum(salt_layer(layers,:),1);
salt_tendency = gradient(salt_box,s.t)/p.sid; % m3/s

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

%% sum of terms to check we've got it right
% (volume fluxes should sum to 0)
% (freshwater fluxes should sum to FW_tendency)
% (salt fluxes should sum to sal_tendency)
Q_sum = Q_river+Q_vert_top+Q_vert_base+Q_shelf;
FW_sum = FW_river+FW_vert_top+FW_vert_base+FW_shelf+FW_mix_top+FW_mix_base;
salt_sum = salt_river+salt_vert_top+salt_vert_base+salt_shelf+salt_mix_top+salt_mix_base;

%% plots
figure('Name','Volume-Freshwater-Salt-budget')
subplot(3,1,1); hold on;
s.date = datetime(s.t, 'ConvertFrom', 'datenum');

nFluxes = 6; % river, shelf, vert top, vert base, mix top, mix base

% Get colors from a colormap (e.g., parula, jet, lines, etc.)
fluxColors = parula(nFluxes); % you can also use jet(nFluxes), lines(nFluxes), etc.

figure;
nFluxes = 6; % river, shelf, vert top, vert base, mix top, mix base
fluxColors = parula(nFluxes); % consistent colormap for flux terms

% Volume flux subplot
subplot(3,1,1); hold on;
plot(s.date, Q_river,      'Color', fluxColors(1,:), 'LineWidth',2);
plot(s.date, Q_shelf,      'Color', fluxColors(2,:), 'LineWidth',2);
plot(s.date, Q_vert_top,   'Color', fluxColors(3,:), 'LineWidth',2);
plot(s.date, Q_vert_base,  'Color', fluxColors(4,:), 'LineWidth',2);
plot(s.date, Q_mix_top,    'Color', fluxColors(5,:), 'LineWidth',2);
plot(s.date, Q_mix_base,   'Color', fluxColors(6,:), 'LineWidth',2);
plot(s.date, Q_sum,        'k--','LineWidth',2); % total
legend('river','shelf','vert top','vert base','mix top','mix base','SUM');
ylabel('Volume flux (m^3/s)');
title('Volume Flux Terms');

% Freshwater flux subplot
subplot(3,1,2); hold on;
plot(s.date, FW_river,      'Color', fluxColors(1,:), 'LineWidth',2);
plot(s.date, FW_shelf,      'Color', fluxColors(2,:), 'LineWidth',2);
plot(s.date, FW_vert_top,   'Color', fluxColors(3,:), 'LineWidth',2);
plot(s.date, FW_vert_base,  'Color', fluxColors(4,:), 'LineWidth',2);
plot(s.date, FW_mix_top,    'Color', fluxColors(5,:), 'LineWidth',2);
plot(s.date, FW_mix_base,   'Color', fluxColors(6,:), 'LineWidth',2);
plot(s.date, FW_sum,        'k--','LineWidth',2); % total
plot(s.date, FW_tendency,   'r:','LineWidth',2);  % tendency
legend('river','shelf','vert top','vert base','mix top','mix base','SUM','tendency');
ylabel('Freshwater flux (m^3/s)');
title('Freshwater Flux Terms');

% Salt flux subplot
subplot(3,1,3); hold on;
plot(s.date, salt_river,      'Color', fluxColors(1,:), 'LineWidth',2);
plot(s.date, salt_shelf,      'Color', fluxColors(2,:), 'LineWidth',2);
plot(s.date, salt_vert_top,   'Color', fluxColors(3,:), 'LineWidth',2);
plot(s.date, salt_vert_base,  'Color', fluxColors(4,:), 'LineWidth',2);
plot(s.date, salt_mix_top,    'Color', fluxColors(5,:), 'LineWidth',2);
plot(s.date, salt_mix_base,   'Color', fluxColors(6,:), 'LineWidth',2);
plot(s.date, salt_sum,        'k--','LineWidth',2); % total
plot(s.date, salt_tendency,   'r:','LineWidth',2);  % tendency
legend('river','shelf','vert top','vert base','mix top','mix base','SUM','tendency');
ylabel('Salt flux (PSU·m^3/s)');




%% plots cumulative
figCum = figure('Name','cumulative')

% Extract year info
years = year(s.date);
uniqueYears = unique(years);




for iy = 1:length(uniqueYears)
    % Indices for this year
    idx = years == uniqueYears(iy);

    subplot(1,1,1); hold on;
    plot(s.date(idx), cumsum(FW_river(idx)), 'Color', fluxColors(1,:), 'LineWidth',2);
    plot(s.date(idx), cumsum(FW_shelf(idx)), 'Color', fluxColors(2,:), 'LineWidth',2);
    plot(s.date(idx), cumsum(FW_vert_top(idx)), 'Color', fluxColors(3,:), 'LineWidth',2);
    plot(s.date(idx), cumsum(FW_vert_base(idx)), 'Color', fluxColors(4,:), 'LineWidth',2);
    plot(s.date(idx), cumsum(FW_mix_top(idx)), 'Color', fluxColors(5,:), 'LineWidth',2);
    plot(s.date(idx), cumsum(FW_mix_base(idx)), 'Color', fluxColors(6,:), 'LineWidth',2);
    plot(s.date(idx), cumsum(FW_sum(idx)), 'k--','LineWidth',2);
    plot(s.date(idx), cumsum(FW_tendency(idx)), 'r:','LineWidth',2);
    legend('river','shelf','vert top','vert base','mix top','mix base','SUM','tendency', 'Location','northwest')
    ylabel('Freshwater transport (m^3/s)');
    xlabel('day');
    title(['Cumulative freshwater transport ' num2str(z_bnd(1)), '-', num2str(z_bnd(2)), ' m']);
    % 
    % subplot(2,1,2); hold on;
    % plot(s.date(idx), cumsum(salt_river(idx)), 'Color', fluxColors(1,:), 'LineWidth',2);
    % plot(s.date(idx), cumsum(salt_shelf(idx)), 'Color', fluxColors(2,:), 'LineWidth',2);
    % plot(s.date(idx), cumsum(salt_vert_top(idx)), 'Color', fluxColors(3,:), 'LineWidth',2);
    % plot(s.date(idx), cumsum(salt_vert_base(idx)), 'Color', fluxColors(4,:), 'LineWidth',2);
    % plot(s.date(idx), cumsum(salt_mix_top(idx)), 'Color', fluxColors(5,:), 'LineWidth',2);
    % plot(s.date(idx), cumsum(salt_mix_base(idx)), 'Color', fluxColors(6,:), 'LineWidth',2);
    % plot(s.date(idx), cumsum(salt_sum(idx)), 'k--','LineWidth',2);
    % plot(s.date(idx), cumsum(salt_tendency(idx)), 'r:','LineWidth',2);
    % legend('river','shelf','vert top','vert base','mix top','mix base','SUM','tendency');
    % ylabel('Salt flux term');
    % xlabel('day');
    % title(['Salt flux year ' num2str(uniqueYears(iy))]);
end

grid on;

folder_fig = '/Users/annek/Library/CloudStorage/OneDrive-SharedLibraries-NIOZ/PhD Anneke Vries - General/fjord_modelling_ameralik/figures/';
figName = ['Cumulative_freshwater_transport_' num2str(z_bnd(1)), '-', num2str(z_bnd(2)), 'm']
exportgraphics(figCum, [figName '.pdf'], 'ContentType', 'vector');
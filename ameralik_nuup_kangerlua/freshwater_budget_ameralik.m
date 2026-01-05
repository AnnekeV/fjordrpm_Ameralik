%% Freshwater Budget Script Using compute_budget
clear; close all;

% Load model output
load ../ameralik_nuup_kangerlua/ameralik_combined_Kb1e-03_C01e+05.mat
s_vhigh = s;
load ../ameralik_nuup_kangerlua/ameralik_combined_Kb1e-04_C01e+05.mat
s_high = s;

colors_ameralik;
folder_paths; % folder_fig

% Define budget box and reference salinity
z_bnd = [0, 110];
Sref = 33.4;

% Compute budget using the function
b_0_50_high = compute_budget(s_high, p, [0, 50], Sref);
b_50_110_high = compute_budget(s_high, p, [50, 110], Sref);
b_0_110_high = compute_budget(s_high, p, [0, 110], Sref);

b_0_50_vhigh = compute_budget(s_vhigh, p, [0, 50], Sref);
b_50_110_vhigh = compute_budget(s_vhigh, p, [50, 110], Sref);
b_0_110_vhigh = compute_budget(s_vhigh, p, [0, 110], Sref);



% Convert time to datetime
s.date = datetime(s.t, 'ConvertFrom', 'datenum');

%% Plot instantaneous Volume, Freshwater, Salt fluxes
figure('Name','Volume-Freshwater-Salt-budget');
% 
% % Volume
% subplot(3,1,1); hold on;
% plot(s.date, b_0_50_vhigh.Q_river, 'Color', fluxColors(1,:), 'LineWidth',2);
% plot(s.date, b_0_50_vhigh.Q_shelf, 'Color', fluxColors(2,:), 'LineWidth',2);
% plot(s.date, b_0_50_vhigh.Q_top,   'Color', fluxColors(3,:), 'LineWidth',2);
% plot(s.date, b_0_50_vhigh.Q_base,  'Color', fluxColors(4,:), 'LineWidth',2);
% plot(s.date, b_0_50_vhigh.Q_sum,   'k--','LineWidth',2);
% legend('River','Shelf','Top','Base','SUM'); ylabel('Volume flux (m^3/s)');

% Freshwater
subplot(2,1,1); hold on;
plot(s.date, b_0_50_vhigh.FW_river, 'Color', fluxColors(1,:), 'LineWidth',2);
plot(s.date, b_0_50_vhigh.FW_shelf, 'Color', fluxColors(2,:), 'LineWidth',2);
plot(s.date, b_0_50_vhigh.FW_top,   'Color', fluxColors(3,:), 'LineWidth',2);
plot(s.date, b_0_50_vhigh.FW_base,  'Color', fluxColors(4,:), 'LineWidth',2);
plot(s.date, b_0_50_vhigh.FW_sum,   'k--','LineWidth',2);
plot(s.date, b_0_50_vhigh.FW_tendency,'r:','LineWidth',2);
legend('River','Shelf','Top','Base','SUM','Tendency'); ylabel('Freshwater flux (m^3/s)');
title("0-50 m")

subplot(2,1,2); hold on;
plot(s.date, b_50_110_vhigh.FW_river, 'Color', fluxColors(1,:), 'LineWidth',2);
plot(s.date, b_50_110_vhigh.FW_shelf, 'Color', fluxColors(2,:), 'LineWidth',2);
plot(s.date, b_50_110_vhigh.FW_top,   'Color', fluxColors(3,:), 'LineWidth',2);
plot(s.date, b_50_110_vhigh.FW_base,  'Color', fluxColors(4,:), 'LineWidth',2);
plot(s.date, b_50_110_vhigh.FW_sum,   'k--','LineWidth',2);
plot(s.date, b_50_110_vhigh.FW_tendency,'r:','LineWidth',2);
legend('River','Shelf','Top','Base','SUM','Tendency'); ylabel('Freshwater flux (m^3/s)');
title("50-110 m")


saveFolder = fullfile(folder_fig, 'Freshwater_budget_flux');
if ~exist(saveFolder, 'dir')
    mkdir(saveFolder);
end
filename = fullfile(saveFolder, 'Freshwater_budget_vhigh_mixing.png');
exportgraphics(gcf, filename, 'Resolution',300);



% 
% % Salt
% subplot(3,1,3); hold on;
% plot(s.date, b_0_50_vhigh.salt_river, 'Color', fluxColors(1,:), 'LineWidth',2);
% plot(s.date, b_0_50_vhigh.salt_shelf, 'Color', fluxColors(2,:), 'LineWidth',2);
% plot(s.date, b_0_50_vhigh.salt_top,   'Color', fluxColors(3,:), 'LineWidth',2);
% plot(s.date, b_0_50_vhigh.salt_base,  'Color', fluxColors(4,:), 'LineWidth',2);
% plot(s.date, b_0_50_vhigh.salt_sum,   'k--','LineWidth',2);
% plot(s.date, b_0_50_vhigh.salt_tendency,'r:','LineWidth',2);
% legend('River','Shelf','Top','Base','SUM','Tendency'); ylabel('Salt flux (PSU·m^3/s)');

%% Plot cumulative freshwater transport per year
figCum = figure('Name','Cumulative Freshwater Transport');
dt_sec = mean(diff(s.t))*24*60*60;
years = year(s.date);
uniqueYears = unique(years);

%% Plot cumulative freshwater transport per year
figCum = figure('Name','Cumulative Freshwater Transport','Position',[100 100 1200 1200]);
dt_sec = mean(diff(s.t))*24*60*60;
years = year(s.date);
uniqueYears = unique(years);

subplot(2,1,1);
for iy = 1:length(uniqueYears)
    idx = years == uniqueYears(iy);
    hold on;
    
    plot(s.date(idx), cumsum(b_0_50_vhigh.FW_river(idx))*dt_sec/1e9, ...
        'Color', fluxColors(1,:), 'LineWidth',2, 'DisplayName','River');
    plot(s.date(idx), cumsum(b_0_50_vhigh.FW_shelf(idx))*dt_sec/1e9, ...
        'Color', fluxColors(2,:), 'LineWidth',2, 'DisplayName','Shelf - Very high mixing', ...
        'Marker','o', 'MarkerSize',6, 'MarkerIndices',1:20:length(idx), ...
        'MarkerEdgeColor', simColors('Very high mix - High ShelfX'));
    plot(s.date(idx), cumsum(b_0_50_high.FW_shelf(idx))*dt_sec/1e9, ...
        'Color', fluxColors(2,:), 'LineWidth',2, 'DisplayName','Shelf - High mixing',  ...
        'Marker','s', 'MarkerSize',6, 'MarkerIndices',1:20:length(idx), ...
        'MarkerEdgeColor', simColors('High mix - High shelfX'));
    plot(s.date(idx), cumsum(b_0_50_vhigh.FW_top(idx))*dt_sec/1e9, ...
        'Color', fluxColors(3,:), 'LineWidth',2, 'DisplayName','Top');
    plot(s.date(idx), cumsum(b_0_50_vhigh.FW_base(idx))*dt_sec/1e9, ...
        'Color', fluxColors(4,:), 'LineWidth',2, 'DisplayName','Base - Very high mixing',  ...
        'Marker','o', 'MarkerSize',6, 'MarkerIndices',1:20:length(idx), ...
        'MarkerEdgeColor', simColors('Very high mix - High ShelfX'));
    plot(s.date(idx), cumsum(b_0_50_high.FW_base(idx))*dt_sec/1e9, ...
        'Color', fluxColors(4,:), 'LineWidth',2, 'DisplayName','Base - High mixing', ...
        'Marker','s', 'MarkerSize',6, 'MarkerIndices',1:20:length(idx), ...
        'MarkerEdgeColor', simColors('High mix - High shelfX'));

    plot(s.date(idx), cumsum(b_0_50_vhigh.FW_sum(idx))*dt_sec/1e9, ...
        'k--','LineWidth',2, 'DisplayName','SUM');
    plot(s.date(idx), cumsum(b_0_50_vhigh.FW_tendency(idx))*dt_sec/1e9, ...
        'r:','LineWidth',2, 'DisplayName','Tendency');
end

ylabel('Freshwater transport (km^3)');
xlabel('Date');
title('Cumulative Freshwater Transport 0-50 m');
grid on;

subplot(2,1,2);
for iy = 1:length(uniqueYears)
    idx = years == uniqueYears(iy);
    hold on;
    
    plot(s.date(idx), cumsum(b_50_110_vhigh.FW_river(idx))*dt_sec/1e9, ...
        'Color', fluxColors(1,:), 'LineWidth',2, 'DisplayName','River');
    plot(s.date(idx), cumsum(b_50_110_vhigh.FW_shelf(idx))*dt_sec/1e9, ...
        'Color', fluxColors(2,:), 'LineWidth',2, 'DisplayName','Shelf - Very high mixing', ...
        'Marker','o', 'MarkerSize',6, 'MarkerIndices',1:20:length(idx), ...
        'MarkerEdgeColor', simColors('Very high mix - High ShelfX'));
    plot(s.date(idx), cumsum(b_50_110_high.FW_shelf(idx))*dt_sec/1e9, ...
        'Color', fluxColors(2,:), 'LineWidth',2, 'DisplayName','Shelf - High mixing',  ...
        'Marker','s', 'MarkerSize',6, 'MarkerIndices',1:20:length(idx), ...
        'MarkerEdgeColor', simColors('High mix - High shelfX'));
    plot(s.date(idx), cumsum(b_50_110_vhigh.FW_top(idx))*dt_sec/1e9, ...
        'Color', fluxColors(3,:), 'LineWidth',2, 'DisplayName','Top');
    plot(s.date(idx), cumsum(b_50_110_vhigh.FW_base(idx))*dt_sec/1e9, ...
        'Color', fluxColors(4,:), 'LineWidth',2, 'DisplayName','Base - Very high mixing',  ...
        'Marker','o', 'MarkerSize',6, 'MarkerIndices',1:20:length(idx), ...
        'MarkerEdgeColor', simColors('Very high mix - High ShelfX'));
    plot(s.date(idx), cumsum(b_50_110_high.FW_base(idx))*dt_sec/1e9, ...
        'Color', fluxColors(4,:), 'LineWidth',2, 'DisplayName','Base - High mixing', ...
        'Marker','s', 'MarkerSize',6, 'MarkerIndices',1:20:length(idx), ...
        'MarkerEdgeColor', simColors('High mix - High shelfX'));

    plot(s.date(idx), cumsum(b_50_110_vhigh.FW_sum(idx))*dt_sec/1e9, ...
        'k--','LineWidth',2, 'DisplayName','SUM');
    plot(s.date(idx), cumsum(b_50_110_vhigh.FW_tendency(idx))*dt_sec/1e9, ...
        'r:','LineWidth',2, 'DisplayName','Tendency');
end

h = findall(gca, 'Type', 'Line');               % get all plotted lines
[~, idxUnique] = unique({h.DisplayName}, 'stable'); % keep first occurrence
legend(h(idxUnique), 'Location','northwest');

ylim([-2.5, 2.5])

ylabel('Freshwater transport (km^3)');
xlabel('Date');

title('Cumulative Freshwater Transport 50-110 m');
grid on;

filename = fullfile(saveFolder, 'Cumulative_FW_budget_high_vhigh_mixing.png');
exportgraphics(gcf, filename, 'Resolution',300);

%% Monthly mean freshwater export
tt = timetable(s.date.', b_0_110_vhigh.FW_river.', b_0_110_vhigh.FW_shelf.', 'VariableNames', {'FW_river','FW_shelf'});
tt.FW_to_shelf = b_0_110_vhigh.FW_to_shelf.'; 
tt.FW_to_fjord = b_0_110_vhigh.FW_to_fjord.';
monthlyTT = retime(tt, 'monthly', @(x) mean(x,'omitnan'));

tt_high = timetable(s.date.', b_0_110_high.FW_river.', b_0_110_high.FW_shelf.', 'VariableNames', {'FW_river','FW_shelf'});
tt_high.FW_to_shelf = b_0_110_high.FW_to_shelf.'; 
tt_high.FW_to_fjord = b_0_110_high.FW_to_fjord.';
monthlyTT_high = retime(tt_high, 'monthly', @(x) mean(x,'omitnan'));

figExport = figure; 
t = tiledlayout(2,1); t.TileSpacing = 'compact';
t.Padding = 'compact';
hold on;

nexttile; hold on;
plot(monthlyTT.Time, monthlyTT.FW_river, '--', 'Color', fluxColors(1,:), 'LineWidth',2, 'DisplayName', 'River input');
plot(monthlyTT.Time, -monthlyTT.FW_shelf, '-o', 'Color', c_shelf_net, 'LineWidth',2, 'DisplayName', 'Net Shelf Export - vHigh');
plot(monthlyTT_high.Time, -monthlyTT_high.FW_shelf, '-s', 'Color', c_shelf_net, 'LineWidth',2, 'DisplayName', 'Net Shelf Export - High');
legend()

nexttile; hold on;
plot(monthlyTT.Time, monthlyTT.FW_to_shelf, '-^','LineWidth',2,'DisplayName','Shelf Export - vHigh', 'Color', c_shelf_out);
plot(monthlyTT.Time, monthlyTT.FW_to_fjord, '-v','LineWidth',2,'DisplayName','Shelf Import - vHigh', 'Color', c_shelf_in);
ylabel('Transport (m^3/s)'); xlabel('Time'); grid on;
title('Very high mixing')
legend('show');

nexttile; hold on ;
plot(monthlyTT_high.Time, monthlyTT_high.FW_to_shelf, '-^','LineWidth',2,'DisplayName','Shelf Export - High', 'Color', c_shelf_out);
plot(monthlyTT_high.Time, monthlyTT_high.FW_to_fjord, '-v','LineWidth',2,'DisplayName','Shelf Import - High', 'Color', c_shelf_in);
title('High mixing')
ylabel('Transport (m^3/s)'); xlabel('Time'); grid on;
legend('show');

linkaxes(findall(figExport,'Type','axes'),'y');

filename = fullfile(saveFolder, 'Cumulative_Shelf_export.png');
exportgraphics(gcf, filename, 'Resolution',300);




%% Mean profiles
% Define periods of interest
periodFuncs = {
    @(t) year(t) >= 2018 & year(t) <= 2019;
    @(t) ismember(month(t), 4:6) & year(t)>=2018 & year(t)<=2019;
    @(t) ismember(month(t), 5:9) & year(t)>=2018 & year(t)<=2019;
    @(t) ismember(month(t), 5:9) & year(t)==2018;
    @(t) ismember(month(t), 5:9) & year(t)==2019;
    @(t) ismember(month(t), 9:11) & year(t)>=2018 & year(t)<=2019;
    @(t) ismember(month(t), 1:3) & year(t)==2018;
    @(t) ismember(month(t), 1:3) & year(t)==2019;
};

periodLabels = {
    'Mean 2018–2019';
    'Apr–Jun 2018–2019';
    'May–Sep 2018–2019';
    'May–Sep 2018';
    'May–Sep 2019';
    'Sep–Nov 2018–2019';
    'Jan–Mar 2018';
    'Jan–Mar 2019';
};

% Plot
figure; hold on;
for k = 1:length(periodFuncs)
    idx = periodFuncs{k}(s.date);  % logical indexing
    avgProfile = mean(b_0_110_vhigh.FW_shelf_layer_profile(:, idx), 2, 'omitnan');
    plot(avgProfile, s.z, 'LineWidth',2,'DisplayName', periodLabels{k});
end

xlabel('Freshwater transport per unit depth (m^3/s/m)');
ylabel('Depth (m)');
ylim([-110 0]);
grid on;
legend('Location','best');
title(['Freshwater Shelf Flux Profiles, ' num2str(z_bnd(1)) '-' num2str(z_bnd(2)) ' m']);


filename = fullfile(saveFolder, 'FW_export_profile_very_high.png');
exportgraphics(gcf, filename, 'Resolution',300);


% Plot
figure; hold on;
for k = 1:length(periodFuncs)
    idx = periodFuncs{k}(s.date);  % logical indexing
    avgProfile = mean(b_0_110_high.FW_shelf_layer_profile(:, idx), 2, 'omitnan');
    plot(avgProfile, s.z, 'LineWidth',2,'DisplayName', periodLabels{k});
end

xlabel('Freshwater transport per unit depth (m^3/s/m)');
ylabel('Depth (m)');
ylim([-110 0]);
grid on;
legend('Location','best');
title(['Freshwater Shelf Flux Profiles, ' num2str(z_bnd(1)) '-' num2str(z_bnd(2)) ' m']);


filename = fullfile(saveFolder, 'FW_export_profile_high.png');
exportgraphics(gcf, filename, 'Resolution',300);

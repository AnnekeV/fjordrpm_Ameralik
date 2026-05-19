%% This script computes the freshwater budget and makes figures
%% Freshwater Budget Script Using compute_budget
clear; close all;

% Load model output
load ../ameralik_nuup_kangerlua/ameralik_combined_Kb1e-03_C01e+05.mat
s_vhigh = s;
load ../ameralik_nuup_kangerlua/ameralik_combined_Kb1e-04_C01e+05.mat
s_high = s;

colors     = colors_ameralik();
fluxColors = colors.fluxColors;
lsVHIGH    = colors.ls.VHIGH;
lsHIGH     = colors.ls.HIGH;
simColors = colors.simColors;

folder_paths; % folder_fig

z_bnd = [0, 110];
Sref = 33.4;

% Compute budget using the function
b_0_50_high = compute_budget(s_high, p, [0, 50], Sref);
b_50_110_high = compute_budget(s_high, p, [50, 110], Sref);
b_0_110_high = compute_budget(s_high, p, [0, 110], Sref);
b_110_200_high = compute_budget(s_high, p, [110, 200], Sref);
b_50_200_high = compute_budget(s_high, p, [50, 200], Sref);


b_0_50_vhigh = compute_budget(s_vhigh, p, [0, 50], Sref);
b_50_110_vhigh = compute_budget(s_vhigh, p, [50, 110], Sref);
b_0_110_vhigh = compute_budget(s_vhigh, p, [0, 110], Sref);
b_110_200_vhigh = compute_budget(s_vhigh, p, [110, 200], Sref);
b_50_200_vhigh = compute_budget(s_vhigh, p, [50, 200], Sref);





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
% exportgraphics(gcf, filename, 'Resolution',300);



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
        'k--','LineWidth',2, 'DisplayName','Sum');
    % plot(s.date(idx), cumsum(b_0_50_vhigh.FW_tendency(idx))*dt_sec/1e9, ...
        % 'r:','LineWidth',2, 'DisplayName','Tendency');
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
    % plot(s.date(idx), cumsum(b_50_110_vhigh.FW_tendency(idx))*dt_sec/1e9, ...
    %     'r:','LineWidth',2, 'DisplayName','Tendency');
end

h = findall(gca, 'Type', 'Line');               % get all plotted lines
[~, idxUnique] = unique({h.DisplayName}, 'stable'); % keep first occurrence
legend(h(idxUnique), 'Location','best', 'Box', 'off');

ylim([-2.5, 2.5])

ylabel('Freshwater transport (km^3)');
xlabel('Date');

title('Cumulative Freshwater Transport 50-110 m');
grid on;

filename = fullfile(saveFolder, 'Cumulative_FW_budget_high_vhigh_mixing.png');
exportgraphics(gcf, filename, 'Resolution',300);


%% Plot cumulative freshwater transport per year — journal-ready 
figCum = figure('Name','Cumulative Freshwater Transport','Units','centimeters','Position',[2 2 18 18]);

dt_sec = mean(diff(s.t))*24*3600;  years = year(s.date);  uniqueYears = unique(years);

% Style
lw = 1.5;  fsAx = 8;  fsPL = 9;  axCol = [0.15 0.15 0.15];
% lsVHIGH = '-';  lsHIGH = '--'; %import from colors_ameralik

% Axes layout [left bottom width height]
mL=0.11; mR=0.02; mB=0.11; mT=0.03; gap=0.03;
axW = 1-mL-mR;  axH = (1-mB-mT-gap)/2;
ax1 = axes('Position',[mL, mB+1*(axH+gap), axW, axH]);  hold on;
ax2 = axes('Position',[mL, mB+0*(axH+gap)  axW, axH]);  hold on;

% ── Plot loop ─────────────────────────────────────────────────────────────
for iy = 1:length(uniqueYears)
    idx = years == uniqueYears(iy);
    d   = s.date(idx);
    k   = dt_sec/1e9;
    cfw = @(x) cumsum(x(idx))*k;

    % --- Panel a: 0-50 m ---
    axes(ax1);
    plot(d, cfw(b_0_50_vhigh.FW_river), 'Color',fluxColors(1,:), 'LineStyle',lsVHIGH, 'LineWidth',lw, 'DisplayName','River');
    plot(d, cfw(b_0_50_vhigh.FW_shelf), 'Color',fluxColors(2,:), 'LineStyle',lsVHIGH, 'LineWidth',lw, 'DisplayName','Shelf – very high mix');
    plot(d, cfw(b_0_50_high.FW_shelf),  'Color',fluxColors(2,:), 'LineStyle',lsHIGH,  'LineWidth',lw, 'DisplayName','Shelf – high mix');
    plot(d, cfw(b_0_50_vhigh.FW_top),   'Color',fluxColors(3,:), 'LineStyle',lsVHIGH, 'LineWidth',lw, 'DisplayName','Top');
    plot(d, cfw(b_0_50_vhigh.FW_base),  'Color',fluxColors(4,:), 'LineStyle',lsVHIGH, 'LineWidth',lw, 'DisplayName','Base – very high mix');
    plot(d, cfw(b_0_50_high.FW_base),   'Color',fluxColors(4,:), 'LineStyle',lsHIGH,  'LineWidth',lw, 'DisplayName','Base – high mix');
    plot(d, cfw(b_0_50_vhigh.FW_sum),   'Color','k', 'LineStyle',lsVHIGH, 'LineWidth',lw, 'DisplayName','Net – very high mix');
    plot(d, cfw(b_0_50_high.FW_sum),    'Color','k', 'LineStyle',lsHIGH,  'LineWidth',lw, 'DisplayName','Net – high mix');

    % --- Panel b: 50-200 m ---
    axes(ax2);
    plot(d, cfw(b_50_200_vhigh.FW_river), 'Color',fluxColors(1,:), 'LineStyle',lsVHIGH, 'LineWidth',lw, 'DisplayName','River');
    plot(d, cfw(b_50_200_vhigh.FW_shelf), 'Color',fluxColors(2,:), 'LineStyle',lsVHIGH, 'LineWidth',lw, 'DisplayName','Shelf – very high mix');
    plot(d, cfw(b_50_200_high.FW_shelf),  'Color',fluxColors(2,:), 'LineStyle',lsHIGH,  'LineWidth',lw, 'DisplayName','Shelf – high mix');
    plot(d, cfw(b_50_200_vhigh.FW_top),   'Color',fluxColors(3,:), 'LineStyle',lsVHIGH, 'LineWidth',lw, 'DisplayName','Top');
    plot(d, cfw(b_50_200_high.FW_top),    'Color',fluxColors(3,:), 'LineStyle',lsHIGH,  'LineWidth',lw, 'DisplayName','Top – high mix');
    plot(d, cfw(b_50_200_vhigh.FW_base),  'Color',fluxColors(4,:), 'LineStyle',lsVHIGH, 'LineWidth',lw, 'DisplayName','Base – very high mix');
    plot(d, cfw(b_50_200_high.FW_base),   'Color',fluxColors(4,:), 'LineStyle',lsHIGH,  'LineWidth',lw, 'DisplayName','Base – high mix');
    plot(d, cfw(b_50_200_vhigh.FW_sum),   'Color','k', 'LineStyle',lsVHIGH, 'LineWidth',lw, 'DisplayName','Net – very high mix');
    plot(d, cfw(b_50_200_high.FW_sum),    'Color','k', 'LineStyle',lsHIGH,  'LineWidth',lw, 'DisplayName','Net – high mix');
end

% ── Dress axes ────────────────────────────────────────────────────────────
axStyle = {'FontSize',fsAx,'TickDir','out','TickLength',[0.012 0.025],'Box','off','XColor',axCol,'YColor',axCol,'LineWidth',0.8};

set(ax1, axStyle{:}, 'XTickLabel',[]);
set(ax2, axStyle{:});  ylim(ax2,[-2 2]);

for ax = [ax1 ax2];  grid(ax,'on');  ax.GridAlpha=0.18;  ax.GridLineStyle=':';  end

ylabel(ax1,'FW transport (km^3)','FontSize',fsAx,'Color',axCol);
ylabel(ax2,'FW transport (km^3)','FontSize',fsAx,'Color',axCol);

text(ax1,0.01,0.97,'a) 0-50 m',   'Units','normalized','FontSize',fsPL,'FontWeight','bold','VerticalAlignment','top','Color',axCol);
text(ax2,0.01,0.97,'b) 50-200 m', 'Units','normalized','FontSize',fsPL,'FontWeight','bold','VerticalAlignment','top','Color',axCol);

linkaxes([ax1 ax2],'x');

greyish = [0.5 0.5 0.5];

% ── Manual legend (one entry per concept) ─────────────────────────────────
hDummy = line(nan,nan, 'Color','none', 'LineStyle','none');
hLeg = [
    line(nan,nan, 'Color',fluxColors(1,:),  'LineWidth',lw+0.5);
    line(nan,nan, 'Color',fluxColors(2,:),  'LineWidth',lw+0.5);
    line(nan,nan, 'Color',fluxColors(3,:), 'LineWidth',lw+0.5);
    line(nan,nan, 'Color',fluxColors(4,:), 'LineWidth',lw+0.5);
    line(nan,nan, 'Color','k',             'LineWidth',lw+0.5);
    line(nan,nan, 'Color',greyish,   'LineStyle',lsVHIGH, 'LineWidth',lw+0.5);
    line(nan,nan, 'Color',greyish,   'LineStyle',lsHIGH,  'LineWidth',lw+0.5);
        hDummy; hDummy; hDummy;                                                        % padding
];

legLabels = {'River','Shelf','Top','Base','Net','Very high mixing','High mixing','','',''};

legend(ax2, hLeg, legLabels, 'Location','best','Box','off','FontSize',fsAx-1,'TextColor',axCol,'NumColumns',2);

% ── Export ────────────────────────────────────────────────────────────────
exportgraphics(figCum, fullfile(saveFolder,'Cumulative_FW_budget_high_vhigh_mixing.png'), 'Resolution',300);
exportgraphics(figCum, fullfile(saveFolder,'Fig8_Cumulative_FW_budget.pdf'), 'ContentType','vector');


%% Monthly mean freshwater export — publication-ready
% Build timetables
tt      = timetable(s.date.', b_0_110_vhigh.FW_river.', b_0_110_vhigh.FW_shelf.', 'VariableNames',{'FW_river','FW_shelf'});
tt.FW_to_shelf = b_0_110_vhigh.FW_to_shelf.';  tt.FW_to_fjord = b_0_110_vhigh.FW_to_fjord.';
monthlyTT = retime(tt,'monthly',@(x) mean(x,'omitnan'));

tt_high = timetable(s.date.', b_0_110_high.FW_river.', b_0_110_high.FW_shelf.', 'VariableNames',{'FW_river','FW_shelf'});
tt_high.FW_to_shelf = b_0_110_high.FW_to_shelf.';  tt_high.FW_to_fjord = b_0_110_high.FW_to_fjord.';
monthlyTT_high = retime(tt_high,'monthly',@(x) mean(x,'omitnan'));

% Style
lw=1.25; mksz=4; fsAx=8; fsPL=9; axCol=[0.15 0.15 0.15];
axStyle = {'FontSize',fsAx,'TickDir','out','TickLength',[0.015 0.025],'Box','off','XColor',axCol,'YColor',axCol,'LineWidth',0.8};

% Figure: ~half page width (86 mm single column)
figExport = figure('Units','centimeters','Position',[2 2 9 14]);

% Manual 3-panel layout
mL=0.16; mR=0.03; mB=0.09; mT=0.03; gap=0.025;
axH=(1-mB-mT-2*gap)/3;  axW=1-mL-mR;
ax = gobjects(3,1);
for k=1:3;  ax(k)=axes('Position',[mL, mB+(3-k)*(axH+gap), axW, axH]);  hold(ax(k),'on');  end

% Panel a — net shelf export
plot(ax(1), monthlyTT.Time,      monthlyTT.FW_river,       '--',  'Color',fluxColors(1,:), 'LineWidth',lw, 'DisplayName','River input');
plot(ax(1), monthlyTT.Time,     -monthlyTT.FW_shelf,       '-o',  'Color',colors.c_shelf_net,     'LineWidth',lw, 'MarkerSize',mksz, 'MarkerFaceColor','none', 'DisplayName','Net shelf export – very high');
plot(ax(1), monthlyTT_high.Time,-monthlyTT_high.FW_shelf,  '-s',  'Color',colors.c_shelf_net,     'LineWidth',lw, 'MarkerSize',mksz, 'MarkerFaceColor','none', 'DisplayName','Net shelf export – high');

% Panel b — very high mixing components
plot(ax(2), monthlyTT.Time, monthlyTT.FW_to_shelf, '-^', 'Color',colors.c_shelf_out, 'LineWidth',lw, 'MarkerSize',mksz, 'MarkerFaceColor','none', 'DisplayName','Shelf export');
plot(ax(2), monthlyTT.Time, monthlyTT.FW_to_fjord, '-v', 'Color',colors.c_shelf_in,  'LineWidth',lw, 'MarkerSize',mksz, 'MarkerFaceColor','none', 'DisplayName','Shelf import');

% Panel c — high mixing components
plot(ax(3), monthlyTT_high.Time, monthlyTT_high.FW_to_shelf, '-^', 'Color',colors.c_shelf_out, 'LineWidth',lw, 'MarkerSize',mksz, 'MarkerFaceColor','none', 'DisplayName','Shelf export');
plot(ax(3), monthlyTT_high.Time, monthlyTT_high.FW_to_fjord, '-v', 'Color',colors.c_shelf_in,  'LineWidth',lw, 'MarkerSize',mksz, 'MarkerFaceColor','none', 'DisplayName','Shelf import');

% Dress all axes
panelLetters = {'a)','b)','c)'};

linkaxes(ax,'xy');
ylim(ax, [-50 500]);

for k=1:3
    set(ax(k), axStyle{:});
    grid(ax(k),'on');  ax(k).GridAlpha=0.18;  ax(k).GridLineStyle=':';
    ylabel(ax(k),'Transport (m^3 s^{-1})','FontSize',fsAx,'Color',axCol);
    text(ax(k),0.01,0.97,panelLetters{k},'Units','normalized','FontSize',fsPL,'FontWeight','bold','VerticalAlignment','top','Color',axCol);
    h=findall(ax(k),'Type','Line');  [~,iu]=unique({h.DisplayName},'stable');
    if k ~= 2
        legend(ax(k),h(iu),'Location','best','Box','off','FontSize',fsAx-1,'TextColor',axCol);
    end
    if k<3;  set(ax(k),'XTickLabel',[]);  end   % shared x-ticks: only bottom panel shows labels
end



% Export
exportgraphics(figExport, fullfile(saveFolder,'Monthly_FW_shelf_export.png'), 'Resolution',300);
exportgraphics(figExport, fullfile(saveFolder,'Monthly_FW_shelf_export.pdf'), 'ContentType','vector');



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
title(['Freshwater Shelf Flux Profiles Not tidal, ' num2str(z_bnd(1)) '-' num2str(z_bnd(2)) ' m']);


% % filename = fullfile(saveFolder, 'FW_export_profile_very_high.png');
% exportgraphics(gcf, filename, 'Resolution',300);


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
title(['Freshwater Shelf Flux Profiles Tidal, ' num2str(z_bnd(1)) '-' num2str(z_bnd(2)) ' m']);


filename = fullfile(saveFolder, 'FW_export_profile_high.png');
% exportgraphics(gcf, filename, 'Resolution',300);

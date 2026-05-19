%% FW Export Profile Script
%  Plots freshwater shelf flux profiles for:
%    1. Very high mixing
%    2. High mixing
%    3. Average of both
%  Plus a summary figure: April–June vs. all other months

clear; close all;

% ── Load data ────────────────────────────────────────────────────────────
load ../ameralik_nuup_kangerlua/ameralik_combined_Kb1e-03_C01e+05.mat
s_vhigh = s;
load ../ameralik_nuup_kangerlua/ameralik_combined_Kb1e-04_C01e+05.mat
s_high = s;

colors     = colors_ameralik();
fluxColors = colors.fluxColors;
lsVHIGH    = colors.ls.VHIGH;
lsHIGH     = colors.ls.HIGH;

folder_paths;   % defines folder_fig

Sref = 33.4;

% ── Compute budgets (full water column used for profiles) ─────────────────
b_0_110_vhigh = compute_budget(s_vhigh, p, [0, 110], Sref);
b_0_110_high  = compute_budget(s_high,  p, [0, 110], Sref);

% Convert time
s.date = datetime(s.t, 'ConvertFrom', 'datenum');

% ── Output folder ─────────────────────────────────────────────────────────
saveFolder = fullfile(folder_fig, 'Freshwater_budget_flux');
if ~exist(saveFolder, 'dir');  mkdir(saveFolder);  end

% ── Period definitions ────────────────────────────────────────────────────
periodFuncs = {
    @(t) year(t) >= 2018 & year(t) <= 2019;
    @(t) ismember(month(t), 4:6)  & year(t) >= 2018 & year(t) <= 2019;
    @(t) ismember(month(t), 5:9)  & year(t) >= 2018 & year(t) <= 2019;
    @(t) ismember(month(t), 5:9)  & year(t) == 2018;
    @(t) ismember(month(t), 5:9)  & year(t) == 2019;
    @(t) ismember(month(t), 9:11) & year(t) >= 2018 & year(t) <= 2019;
    @(t) ismember(month(t), 1:3)  & year(t) == 2018;
    @(t) ismember(month(t), 1:3)  & year(t) == 2019;
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

% ── Common axis style ─────────────────────────────────────────────────────
fsAx   = 8;
fsPL   = 9;
lw     = 1.5;
axCol  = [0.15 0.15 0.15];
axStyle = {'FontSize',fsAx,'TickDir','out','TickLength',[0.012 0.025], ...
           'Box','off','XColor',axCol,'YColor',axCol,'LineWidth',0.8};

%% =========================================================================
%  FIGURE 1 — Three-panel profile comparison (very high / high / average)
% ==========================================================================
figProf = figure('Name','FW Export Profiles', ...
                 'Units','centimeters','Position',[2 2 18 12]);

mL=0.09; mR=0.02; mB=0.12; mT=0.04; gap=0.04;
axW = (1 - mL - mR - 2*gap) / 3;
axH = 1 - mB - mT;

axVH  = axes('Position',[mL + 0*(axW+gap), mB, axW, axH]);  hold on;
axH_  = axes('Position',[mL + 1*(axW+gap), mB, axW, axH]);  hold on;
axAVG = axes('Position',[mL + 2*(axW+gap), mB, axW, axH]);  hold on;

cmap = lines(length(periodFuncs));

for k = 1:length(periodFuncs)
    idx = periodFuncs{k}(s.date);

    prof_vhigh = mean(b_0_110_vhigh.FW_shelf_layer_profile(:, idx), 2, 'omitnan');
    prof_high  = mean(b_0_110_high.FW_shelf_layer_profile(:,  idx), 2, 'omitnan');
    prof_avg   = (prof_vhigh + prof_high) / 2;

    plot(axVH,  prof_vhigh, s.z, 'Color',cmap(k,:), 'LineWidth',lw, 'DisplayName',periodLabels{k});
    plot(axH_,  prof_high,  s.z, 'Color',cmap(k,:), 'LineWidth',lw, 'DisplayName',periodLabels{k});
    plot(axAVG, prof_avg,   s.z, 'Color',cmap(k,:), 'LineWidth',lw, 'DisplayName',periodLabels{k});
end

% Dress panels
panelTitles  = {'Very high mixing', 'High mixing', 'Average'};
panelLetters = {'a)', 'b)', 'c)'};
axAll = [axVH, axH_, axAVG];

for j = 1:3
    set(axAll(j), axStyle{:});
    ylim(axAll(j), [-110 0]);
    grid(axAll(j), 'on');
    axAll(j).GridAlpha = 0.18;
    axAll(j).GridLineStyle = ':';
    xlabel(axAll(j), 'FW transport (m^3 s^{-1} m^{-1})', 'FontSize',fsAx, 'Color',axCol);
    title(axAll(j), panelTitles{j}, 'FontSize',fsAx, 'Color',axCol, 'FontWeight','normal');
    text(axAll(j), 0.03, 0.98, panelLetters{j}, 'Units','normalized', ...
        'FontSize',fsPL, 'FontWeight','bold', 'VerticalAlignment','top', 'Color',axCol);
end

ylabel(axVH, 'Depth (m)', 'FontSize',fsAx, 'Color',axCol);
set(axH_,  'YTickLabel',[]);
set(axAVG, 'YTickLabel',[]);

linkaxes(axAll, 'xy');

legend(axAVG, 'Location','best', 'Box','off', 'FontSize',fsAx-1, 'TextColor',axCol);

% exportgraphics(figProf, fullfile(saveFolder,'FW_export_profiles_high_vhigh_avg.png'), 'Resolution',300);
% exportgraphics(figProf, fullfile(saveFolder,'FW_export_profiles_high_vhigh_avg.pdf'), 'ContentType','vector');


%% =========================================================================
%  FIGURE 2 — Apr–Jun vs. all other months, across both simulations
% ==========================================================================

% Masks (2018–2019)
mask_aprjun = ismember(month(s.date), 4:6)  & year(s.date) >= 2018 & year(s.date) <= 2019;
mask_rest   = ~ismember(month(s.date), 4:6) & year(s.date) >= 2018 & year(s.date) <= 2019;

% Helper: profile mean ± std across time
profStats = @(prof, mask) deal( ...
    mean(prof(:, mask), 2, 'omitnan'), ...
    std( prof(:, mask), 0, 2, 'omitnan') );

[mu_vhigh_apr, sd_vhigh_apr] = profStats(b_0_110_vhigh.FW_shelf_layer_profile, mask_aprjun);
[mu_vhigh_rst, sd_vhigh_rst] = profStats(b_0_110_vhigh.FW_shelf_layer_profile, mask_rest);
[mu_high_apr,  sd_high_apr]  = profStats(b_0_110_high.FW_shelf_layer_profile,  mask_aprjun);
[mu_high_rst,  sd_high_rst]  = profStats(b_0_110_high.FW_shelf_layer_profile,  mask_rest);

mu_avg_apr = (mu_vhigh_apr + mu_high_apr) / 2;
mu_avg_rst = (mu_vhigh_rst + mu_high_rst) / 2;

% Shaded envelope helper (patch around a profile)
shadeProfile = @(ax, prof, sd, z, col, alpha) ...
    patch(ax, [prof+sd; flipud(prof-sd)], [z; flipud(z)], col, ...
          'FaceAlpha',alpha, 'EdgeColor','none');

figSummary = figure('Name','FW Profiles Apr-Jun vs Rest', ...
                    'Units','centimeters','Position',[2 2 18 10]);

mL=0.10; mR=0.02; mB=0.13; mT=0.04; gap=0.04;
axW = (1 - mL - mR - 2*gap) / 3;
axH = 1 - mB - mT;

axS1 = axes('Position',[mL + 0*(axW+gap), mB, axW, axH]);  hold on;
axS2 = axes('Position',[mL + 1*(axW+gap), mB, axW, axH]);  hold on;
axS3 = axes('Position',[mL + 2*(axW+gap), mB, axW, axH]);  hold on;

% Colours for the two periods
cApr = [0.20 0.55 0.85];   % blue  → spring
cRst = [0.85 0.45 0.10];   % orange → rest of year

% --- Panel a: Very high mixing ---
shadeProfile(axS1, mu_vhigh_apr, sd_vhigh_apr, s.z, cApr, 0.15);
shadeProfile(axS1, mu_vhigh_rst, sd_vhigh_rst, s.z, cRst, 0.15);
plot(axS1, mu_vhigh_apr, s.z, 'Color',cApr, 'LineStyle',lsVHIGH, 'LineWidth',lw, 'DisplayName','Apr–Jun');
plot(axS1, mu_vhigh_rst, s.z, 'Color',cRst, 'LineStyle',lsVHIGH, 'LineWidth',lw, 'DisplayName','Other months');

% --- Panel b: High mixing ---
shadeProfile(axS2, mu_high_apr, sd_high_apr, s.z, cApr, 0.15);
shadeProfile(axS2, mu_high_rst, sd_high_rst, s.z, cRst, 0.15);
plot(axS2, mu_high_apr, s.z, 'Color',cApr, 'LineStyle',lsHIGH, 'LineWidth',lw, 'DisplayName','Apr–Jun');
plot(axS2, mu_high_rst, s.z, 'Color',cRst, 'LineStyle',lsHIGH, 'LineWidth',lw, 'DisplayName','Other months');

% --- Panel c: Average of both simulations ---
shadeProfile(axS3, mu_avg_apr, (sd_vhigh_apr+sd_high_apr)/2, s.z, cApr, 0.15);
shadeProfile(axS3, mu_avg_rst, (sd_vhigh_rst+sd_high_rst)/2, s.z, cRst, 0.15);
plot(axS3, mu_avg_apr, s.z, 'Color',cApr, 'LineWidth',lw+0.5, 'DisplayName','Apr–Jun');
plot(axS3, mu_avg_rst, s.z, 'Color',cRst, 'LineWidth',lw+0.5, 'DisplayName','Other months');

% Dress
panelTitles2  = {'Very high mixing', 'High mixing', 'Average'};
panelLetters2 = {'a)', 'b)', 'c)'};
axAll2 = [axS1, axS2, axS3];

for j = 1:3
    set(axAll2(j), axStyle{:});
    ylim(axAll2(j), [-110 0]);
    grid(axAll2(j), 'on');
    axAll2(j).GridAlpha = 0.18;
    axAll2(j).GridLineStyle = ':';
    xlabel(axAll2(j), 'FW transport (m^3 s^{-1} m^{-1})', 'FontSize',fsAx, 'Color',axCol);
    title(axAll2(j), panelTitles2{j}, 'FontSize',fsAx, 'Color',axCol, 'FontWeight','normal');
    text(axAll2(j), 0.03, 0.98, panelLetters2{j}, 'Units','normalized', ...
        'FontSize',fsPL, 'FontWeight','bold', 'VerticalAlignment','top', 'Color',axCol);
end

ylabel(axS1, 'Depth (m)', 'FontSize',fsAx, 'Color',axCol);
set(axS2, 'YTickLabel',[]);
set(axS3, 'YTickLabel',[]);

linkaxes(axAll2, 'xy');

% Single legend on panel c with line style explanation
hLeg = [
    line(axS3, nan,nan, 'Color',cApr, 'LineWidth',lw+0.5);
    line(axS3, nan,nan, 'Color',cRst, 'LineWidth',lw+0.5);
    line(axS3, nan,nan, 'Color',[0.5 0.5 0.5], 'LineStyle',lsVHIGH, 'LineWidth',lw);
    line(axS3, nan,nan, 'Color',[0.5 0.5 0.5], 'LineStyle',lsHIGH,  'LineWidth',lw);
];
legend(axS3, hLeg, {'Apr–Jun','Other months','Very high mix','High mix'}, ...
    'Location','best','Box','off','FontSize',fsAx-1,'TextColor',axCol);
% 
% exportgraphics(figSummary, fullfile(saveFolder,'FW_profiles_AprJun_vs_rest.png'), 'Resolution',300);
% exportgraphics(figSummary, fullfile(saveFolder,'FW_profiles_AprJun_vs_rest.pdf'), 'ContentType','vector');


%% =========================================================================
%  FIGURE 3 — Apr–Jun vs. all other months, across both simulations
% ==========================================================================

% Masks (2018–2019)
mask_aprjun = ismember(month(s.date), 4:6)  & year(s.date) >= 2018 & year(s.date) <= 2019;
mask_rest   = ~ismember(month(s.date), 4:6) & year(s.date) >= 2018 & year(s.date) <= 2019;

% Helper: profile mean ± std across time
profStats = @(prof, mask) deal( ...
    mean(prof(:, mask), 2, 'omitnan'), ...
    std( prof(:, mask), 0, 2, 'omitnan') );

[mu_vhigh_apr, sd_vhigh_apr] = profStats(b_0_110_vhigh.FW_shelf_layer_profile, mask_aprjun);
[mu_vhigh_rst, sd_vhigh_rst] = profStats(b_0_110_vhigh.FW_shelf_layer_profile, mask_rest);
[mu_high_apr,  sd_high_apr]  = profStats(b_0_110_high.FW_shelf_layer_profile,  mask_aprjun);
[mu_high_rst,  sd_high_rst]  = profStats(b_0_110_high.FW_shelf_layer_profile,  mask_rest);

mu_avg_apr = (mu_vhigh_apr + mu_high_apr) / 2;
mu_avg_rst = (mu_vhigh_rst + mu_high_rst) / 2;

% Shaded envelope helper (patch around a profile)
shadeProfile = @(ax, prof, sd, z, col, alpha) ...
    patch(ax, [prof+sd; flipud(prof-sd)], [z; flipud(z)], col, ...
          'FaceAlpha',alpha, 'EdgeColor','none');

figSummary = figure('Name','FW Profiles Apr-Jun vs Rest', ...
                    'Units','centimeters','Position',[2 2 18 10]);

mL=0.10; mR=0.02; mB=0.13; mT=0.04; gap=0.04;
axW = (1 - mL - mR - 2*gap) / 3;
axH = 1 - mB - mT;

axS1 = axes('Position',[mL + 0*(axW+gap), mB, axW, axH]);  hold on;
axS2 = axes('Position',[mL + 1*(axW+gap), mB, axW, axH]);  hold on;
axS3 = axes('Position',[mL + 2*(axW+gap), mB, axW, axH]);  hold on;

% Colours for the two periods
cApr = [0.20 0.55 0.85];   % blue  → spring
cRst = [0.85 0.45 0.10];   % orange → rest of year

% --- Panel a: Very high mixing ---
shadeProfile(axS1, mu_vhigh_apr, sd_vhigh_apr, s.z, cApr, 0.15);
shadeProfile(axS1, mu_vhigh_rst, sd_vhigh_rst, s.z, cRst, 0.15);
plot(axS1, mu_vhigh_apr, s.z, 'Color',cApr, 'LineStyle',lsVHIGH, 'LineWidth',lw, 'DisplayName','Apr–Jun');
plot(axS1, mu_vhigh_rst, s.z, 'Color',cRst, 'LineStyle',lsVHIGH, 'LineWidth',lw, 'DisplayName','Other months');

% --- Panel b: High mixing ---
shadeProfile(axS2, mu_high_apr, sd_high_apr, s.z, cApr, 0.15);
shadeProfile(axS2, mu_high_rst, sd_high_rst, s.z, cRst, 0.15);
plot(axS2, mu_high_apr, s.z, 'Color',cApr, 'LineStyle',lsHIGH, 'LineWidth',lw, 'DisplayName','Apr–Jun');
plot(axS2, mu_high_rst, s.z, 'Color',cRst, 'LineStyle',lsHIGH, 'LineWidth',lw, 'DisplayName','Other months');

% --- Panel c: Average of both simulations ---
shadeProfile(axS3, mu_avg_apr, (sd_vhigh_apr+sd_high_apr)/2, s.z, cApr, 0.15);
shadeProfile(axS3, mu_avg_rst, (sd_vhigh_rst+sd_high_rst)/2, s.z, cRst, 0.15);
plot(axS3, mu_avg_apr, s.z, 'Color',cApr, 'LineWidth',lw+0.5, 'DisplayName','Apr–Jun');
plot(axS3, mu_avg_rst, s.z, 'Color',cRst, 'LineWidth',lw+0.5, 'DisplayName','Other months');

% Dress
panelTitles2  = {'Very high mixing', 'High mixing', 'Average'};
panelLetters2 = {'a)', 'b)', 'c)'};
axAll2 = [axS1, axS2, axS3];

for j = 1:3
    set(axAll2(j), axStyle{:});
    ylim(axAll2(j), [-110 0]);
    grid(axAll2(j), 'on');
    axAll2(j).GridAlpha = 0.18;
    axAll2(j).GridLineStyle = ':';
    xlabel(axAll2(j), 'FW transport (m^3 s^{-1} m^{-1})', 'FontSize',fsAx, 'Color',axCol);
    title(axAll2(j), panelTitles2{j}, 'FontSize',fsAx, 'Color',axCol, 'FontWeight','normal');
    text(axAll2(j), 0.03, 0.98, panelLetters2{j}, 'Units','normalized', ...
        'FontSize',fsPL, 'FontWeight','bold', 'VerticalAlignment','top', 'Color',axCol);
end

ylabel(axS1, 'Depth (m)', 'FontSize',fsAx, 'Color',axCol);
set(axS2, 'YTickLabel',[]);
set(axS3, 'YTickLabel',[]);

linkaxes(axAll2, 'xy');

% Single legend on panel c with line style explanation
hLeg = [
    line(axS3, nan,nan, 'Color',cApr, 'LineWidth',lw+0.5);
    line(axS3, nan,nan, 'Color',cRst, 'LineWidth',lw+0.5);
    line(axS3, nan,nan, 'Color',[0.5 0.5 0.5], 'LineStyle',lsVHIGH, 'LineWidth',lw);
    line(axS3, nan,nan, 'Color',[0.5 0.5 0.5], 'LineStyle',lsHIGH,  'LineWidth',lw);
];
legend(axS3, hLeg, {'Apr–Jun','Other months','Very high mix','High mix'}, ...
    'Location','best','Box','off','FontSize',fsAx-1,'TextColor',axCol);
% 
exportgraphics(figSummary, fullfile(saveFolder,'FW_profiles_AprJun_vs_rest.png'), 'Resolution',300);
exportgraphics(figSummary, fullfile(saveFolder,'FW_profiles_AprJun_vs_rest.pdf'), 'ContentType','vector');

function fig = plotCompareObsModelProfilesMultiple(Ameralik_mean, sims, simNames, tileShape, xlimT, xlimS, timespan)
% PLOTCOMPAREOBSMODELPROFILES Compare obs and multiple model runs per date.
%
% Each tile corresponds to one observation date (2 panels: T & S).
%
% INPUTS:
%   Ameralik_mean - struct with fields: T, S, depths, dates, nProfilesperdate
%   sims          - cell array of model structs with fields T, S, z, t
%   simNames      - cell array of names for each model run
%   tileShape     - optional [nRows nCols] for tiled layout
%   xlimT         - optional [min max] limits for Temperature axis
%   xlimS         - optional [min max] limits for Salinity axis
%   timespan      - [datetime_start datetime_end]
%
% OUTPUT:
%   fig           - figure handle
colors_ameralik;

if nargin < 3 || isempty(simNames)
    simNames = arrayfun(@(k) sprintf('Sim%d', k), 1:numel(sims), 'UniformOutput', false);
end

% Optional xlim calculation if not provided
if nargin < 5 || isempty(xlimT)
    xlimT = [min(Ameralik_mean.T(~isnan(Ameralik_mean.T)))-1, ...
             max(Ameralik_mean.T(~isnan(Ameralik_mean.T)))+1];
end
if nargin < 6 || isempty(xlimS)
    xlimS = [min(Ameralik_mean.S(~isnan(Ameralik_mean.S)))-0.5, ...
             max(Ameralik_mean.S(~isnan(Ameralik_mean.S)))+0.5];
end

% Convert model times to datetime
for k = 1:numel(sims)
    sims{k}.date = datetime(sims{k}.t,'ConvertFrom','datenum');
end

obs_dates = Ameralik_mean.dates;
obs_dates_in_timespan = (obs_dates > timespan(1)) & (obs_dates < timespan(2));

% Valid observation dates
obsIdx = find(obs_dates_in_timespan);
nDates = numel(obsIdx);

% Default tile layout
if nargin < 4 || isempty(tileShape)
    tileShape = [2, nDates];
end

% Panel labels (a), (b), (c), ...
panelLabels = arrayfun(@(n) sprintf('(%s)', char('a'+n-1)), 1:tileShape(1)*tileShape(2), 'UniformOutput', false);

% --- Set figure size upfront ---
width_in  = 7;
height_in = 5.5;

fig = figure('Name','Obs vs Model Comparison', ...
             'Units','inches', ...
             'Position',[1 1 width_in height_in]);

tlo = tiledlayout(tileShape(1), tileShape(2), 'TileSpacing','compact','Padding','compact');

for i = 1:nDates
    idx = obsIdx(i);

    % Find closest model time index (compute once per date)
    s_idx_date = findClosestDate(sims{1}.date, obs_dates(idx));

    % -----------------------------
    % Temperature tile
    % -----------------------------
    axT = nexttile(i); hold(axT,'on');

    plot(axT, Ameralik_mean.T(:,idx), Ameralik_mean.depths, 'k','LineWidth',1.5,'DisplayName','Obs');

    % Shelf profile (use last sim's shelf fields — same for all)
    s_idx_shelf = findClosestDate(sims{1}.date, obs_dates(idx));
    plot(axT, sims{1}.Ts(:, s_idx_shelf), -sims{1}.z, 'k:', 'LineWidth', 1.5, 'DisplayName', 'Shelf');

    % All fjord model runs
    for k = 1:numel(sims)
        s_idx_date = findClosestDate(sims{k}.date, obs_dates(idx));
        plot(axT, sims{k}.T(:, s_idx_date), -sims{k}.z, '--', 'LineWidth', 1.5, 'Color', simColors(simNames{k}));
    end

    grid(axT,'on');
    xlabel(axT,'Temperature (°C)');
    xlim(axT, xlimT);
    title(axT, datestr(obs_dates(idx),'dd mmm YY'));

    % Panel label top-left
    text(axT, 0.04, 0.97, panelLabels{i}, ...
        'Units','normalized','FontWeight','bold', ...
        'VerticalAlignment','top','FontSize',9);

    if i == 1
        ylabel(axT,'Depth (m)');
    end

    % -----------------------------
    % Salinity tile
    % -----------------------------
    axS = nexttile(i + nDates); hold(axS,'on');

    plot(axS, Ameralik_mean.S(:,idx), Ameralik_mean.depths, 'k','LineWidth',1.5,'DisplayName','Observations');
    plot(axS, sims{1}.Ss(:, s_idx_shelf), -sims{1}.z, 'k:', 'LineWidth', 1.5, 'DisplayName', 'Shelf');

    for k = 1:numel(sims)
        s_idx_date = findClosestDate(sims{k}.date, obs_dates(idx));
        plot(axS, sims{k}.S(:, s_idx_date), -sims{k}.z, '--', 'LineWidth', 1.5, ...
            'DisplayName', sprintf(simNames{k}), 'Color', simColors(simNames{k}));
    end

    grid(axS,'on');
    xlabel(axS,'Salinity (PSU)');
    xlim(axS, xlimS);
    linkaxes([axS axT],'y');
    ylim(axS, [0 50]);

    % Panel label top-left (offset into second row)
    text(axS, 0.04, 0.9, panelLabels{i + nDates}, ...
        'Units','normalized','FontWeight','bold', ...
        'VerticalAlignment','top','FontSize',9);

    if i == 1
        ylabel(axS,'Depth (m)');
        legend(axS,'Location','SouthWest','Box','off','Color','none');
    end

    if isfield(Ameralik_mean,'nProfilesperdate') && length(Ameralik_mean.nProfilesperdate) >= idx
        n_profiles = Ameralik_mean.nProfilesperdate(idx);
        title(axS, sprintf('N = %d', n_profiles));
    end
end

% Reverse y-direction for all axes
allAxes = findall(gcf, 'Type', 'axes');
set(allAxes, 'YDir', 'reverse');

end

%% ------------------ Helper function ------------------
function idx = findClosestDate(dates, target)
[~, idx] = min(abs(dates - target));
end


%% ============================================================
%  MAIN SCRIPT
%% ============================================================
colors_ameralik;

%% ----------------- Load simulations -----------------
sims = {
    load('ameralik_combined_Kb1e-04_C01e+05.mat', 's').s,
    load('ameralik_combined_Kb1e-03_C01e+05.mat', 's').s,
};
simNames = {
    'High mix -\nHigh shelfX',
    'Very high mix -\nHigh ShelfX',
};

%% ----------------- Load observations -----------------
saveFolder = '/Users/annek/Library/CloudStorage/OneDrive-SharedLibraries-NIOZ/PhD Anneke Vries - General/fjord_modelling_ameralik/data/interim';
load(fullfile(saveFolder,'Ameralik_AM5.mat'));
load(fullfile(saveFolder,'Ameralik_mean_daily.mat'));

%% ----------------- Plot 2018 (15 Jun – 15 Sep) -----------------
tileShape = [2, 3];

fig18 = plotCompareObsModelProfilesMultiple( ...
    AM5, sims, simNames, tileShape, [0, 7], [25, 34], ...
    [datetime(2018, 6, 15), datetime(2018, 9, 15)]);

folder_fig     = '/Users/annek/Library/CloudStorage/OneDrive-SharedLibraries-NIOZ/PhD Anneke Vries - General/fjord_modelling_ameralik/figures/';
saveFolder_ts  = fullfile(folder_fig, 'comparison_obs_model_CTD_all');
savename18     = fullfile(saveFolder_ts, 'ObsModelShelfProfiles_comparison18_summer.png');
exportgraphics(fig18, savename18, 'Resolution', 300);

%% ----------------- Plot 2019 (10 Jul – 10 Sep) -----------------
fig19 = plotCompareObsModelProfilesMultiple( ...
    AM5, sims, simNames, tileShape, [0, 7], [25, 34], ...
    [datetime(2019, 7, 10), datetime(2019, 9, 10)]);

savename19 = fullfile(saveFolder_ts, 'ObsModelShelfProfiles_comparison19_summer.png');
exportgraphics(fig19, savename19, 'Resolution', 300);
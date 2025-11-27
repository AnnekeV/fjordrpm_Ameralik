function fig = plotCompareObsModelProfilesMultiple(Ameralik_mean, sims, simNames, tileShape, xlimT, xlimS)
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
%
% OUTPUT:
%   fig           - figure handle

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

% Valid observation dates
validMask = ~all(isnan(Ameralik_mean.T)) | ~all(isnan(Ameralik_mean.S));
obsIdx = find(validMask);
nDates = numel(obsIdx);

% Default tile layout = one column
if nargin < 4 || isempty(tileShape)
    tileShape = [nDates 1];
end

fig = figure('Name','Obs vs Model Comparison','Units','normalized','Position',[0.1 0.1 0.8 0.8]);
tlo = tiledlayout(tileShape(1), tileShape(2), 'TileSpacing','compact','Padding','compact');

for i = 1:nDates
    idx = obsIdx(i);

    % -----------------------------
    % Temperature tile
    % -----------------------------
    % Temperature tile
    axT = nexttile; hold(axT,'on');

    plot(axT, Ameralik_mean.T(:,idx), -Ameralik_mean.depths, 'k','LineWidth',1.5,'DisplayName','Obs');

    % Plot all model runs
    for k = 1:numel(sims)
        plot(axT, sims{k}.T(:, findClosestDate(sims{k}.date, obs_dates(idx))), ...
             sims{k}.z, '--', 'LineWidth', 1.5, 'DisplayName', simNames{k});
    end

    grid(axT,'on'); xlabel(axT,'Temperature (°C)'); ylabel(axT,'Depth (m)');
    xlim(axT, xlimT);
    title(axT, datestr(obs_dates(idx)));
    if i == 1
        legend(axT,'Location','best');
    end

    % -----------------------------
    % Salinity tile
    % -----------------------------

    % Salinity tile
    axS = nexttile; hold(axS,'on');
    plot(axS, Ameralik_mean.S(:,idx), -Ameralik_mean.depths, 'k','LineWidth',1.5,'DisplayName','Obs');

    % All model runs
    for k = 1:numel(sims)
        plot(axS, sims{k}.S(:, findClosestDate(sims{k}.date, obs_dates(idx))), ...
             sims{k}.z, '--', 'LineWidth', 1.5, 'DisplayName', simNames{k});
    end

    grid(axS,'on'); xlabel(axS,'Salinity (PSU)'); yticklabels(axS, {});
    xlim(axS, xlimS);

    % Optional: number of observations
    if isfield(Ameralik_mean,'nProfilesperdate') && length(Ameralik_mean.nProfilesperdate) >= idx
        n_profiles = Ameralik_mean.nProfilesperdate(idx);
        title(axS, sprintf('N obs = %d', n_profiles));
    end
end

end

%% ------------------ Helper function ------------------
function idx = findClosestDate(dates, target)
[~, idx] = min(abs(dates - target));
end


%% ----------------- Load simulations and observations -----------------
sims = {
    load('ameralik_combined_Kb1e-04_C01e+04.mat','s').s, 
    load('ameralik_combined_Kb1e-05_C01e+04.mat','s').s, 
    load('ameralik_combined_Kb1e-05_C01e+05.mat','s').s, 
    load('ameralik_combined_Kb1e-04_C01e+05.mat','s').s, 
    load('ameralik_combined_Kb1e-03_C01e+05.mat','s').s, 
    load('ameralik_combined_Kb1e-03_C01e+04.mat','s').s
    };

simNames = {'High mix - Low shelfX', 
    'Low mix - Low shelfX',
    'Low mix - High shelfX',
    'High mix - High shelfX',
    'Very high mix - High ShelfX',
    'Very high mix - Low ShelfX'
    };

% Load Ameralik observation structures
saveFolder = '/Users/annek/Library/CloudStorage/OneDrive-SharedLibraries-NIOZ/PhD Anneke Vries - General/fjord_modelling_ameralik/data/interim';
load(fullfile(saveFolder,'Ameralik_AM5.mat'));
load(fullfile(saveFolder,'Ameralik_mean_daily.mat'));

%% ----------------- Plot: Compare obs vs multiple model runs -----------------
close all;

% Optional: define tile layout [nRows nCols]
tileShape = [3 8]; % adjust based on number of observation dates

fig = plotCompareObsModelProfilesMultiple(Ameralik_mean, sims, simNames, tileShape,[-0.5,5],[ 31 33.5]);

% Save figure
folder_fig = '/Users/annek/Library/CloudStorage/OneDrive-SharedLibraries-NIOZ/PhD Anneke Vries - General/fjord_modelling_ameralik/figures/';
saveFolder_ts = fullfile(folder_fig,'comparison_obs_model_CTD_all');
base = fullfile(saveFolder_ts,'ObsModelProfiles_comparison');
savenameS = sprintf('%s.png', base);
saveFigure(fig, savenameS, 12, 7);

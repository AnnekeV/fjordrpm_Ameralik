

%% Load data
load('/Users/annek/Library/CloudStorage/OneDrive-SharedLibraries-NIOZ/PhD Anneke Vries - General/fjord_modelling_ameralik/data/interim/Ameralik_mean_daily.mat'); 
load('ameralik_combined_with_spinup_strong_mixing.mat'); 
savename = 'withSpinupStrongMixing';

%%

% Convert model times to datetime
model_dates = datetime(s.t,'ConvertFrom','datenum');
model_depths = s.z;

% Observation dates
% onlykeep  columns that are  notall NaN
validMask = ~all(isnan(Ameralik_mean.T), 1);
% to keep only those columns
obs_dates = Ameralik_mean.dates(validMask);
obs_depths = Ameralik_mean.depths;
obs_T = Ameralik_mean.T(:,validMask);
obs_S = Ameralik_mean.S(:,validMask);




%% Find closest model depth for target epth

target_depths = [50, 100, 200, 400];

closest_idx_obs = zeros(length(target_depths),1);
closest_idx_mmod = zeros(length(target_depths),1);

for i = 1:length(target_depths)
    [z_target, idx_mod] = min(abs(model_depths - target_depths(i)*-1));
    closest_idx_mod(i) = idx_mod;
    z_target
    [~, idx_obs] = min(abs(obs_depths - target_depths(i)));
    closest_idx_obs(i) = idx_obs;
end




%% TEMPARTURE PLOT
function fig = plotTemperatureByDepth(Am, sims, simNames, target_depths, titleStr, tileShape)
% Plot Temperature comparison per target depth
% - Multiple simulations dashed colored lines
% - Observations solid black
% - Shared x/y limits via linkaxes
% - Only bottom row has x-labels
% - Legend in last subplot

    if nargin < 5 || isempty(titleStr)
        titleStr = 'Temperature Comparison';
    end
    if nargin < 6 || isempty(tileShape)
        tileShape = [numel(target_depths) 1];
    end

    nSims = numel(sims);
    if nargin < 3 || isempty(simNames)
        simNames = arrayfun(@(k) sprintf('Sim%d', k), 1:nSims, 'UniformOutput', false);
    end

    % Colors
    if exist('brewermap','file')
        colors = brewermap(nSims,'Set1');
    else
        colors = lines(nSims);
    end

    fig = figure('Name', titleStr, 'Units','normalized','Position',[0.1 0.1 0.75 0.8]);
    tiledlayout(tileShape(1), tileShape(2), 'TileSpacing','compact','Padding','compact');

    % Preprocess observations
    validMask = ~all(isnan(Am.T),1);
    obs_dates = Am.dates(validMask);
    obs_T = Am.T(:,validMask);
    obs_depths = Am.depths;

    axList = gobjects(numel(target_depths),1);

    for k = 1:numel(target_depths)
        ax = nexttile; hold on;
        axList(k) = ax;

        td = target_depths(k);
        [~, idx_obs] = min(abs(obs_depths - td));

        % Plot each simulation
        for sIdx = 1:nSims
            s = sims{sIdx};
            s.date = datetime(s.t,'ConvertFrom','datenum');
            [~, idx_mod] = min(abs(s.z - td*-1));
            plot(s.date, s.T(idx_mod,:), '--', 'Color', colors(sIdx,:), 'LineWidth',1.5, ...
                 'DisplayName', simNames{sIdx});
        end

        % Observations
        plot(obs_dates, obs_T(idx_obs,:), '-k', 'LineWidth',1.3, 'DisplayName','Obs');

        title(sprintf('%d m', td));
        grid on; box on;
        ylabel('Temp (°C)');
    end

    linkaxes(axList,'xy'); % shared limits

    % Only bottom row has x-labels
    nCols = tileShape(2);
    nAx = numel(axList);
    bottomAxes = axList(nAx-nCols+1 : nAx);
    for jj = 1:nAx
        if ismember(axList(jj), bottomAxes)
            xlabel(axList(jj), 'Date');
        else
            axList(jj).XTickLabel = [];
        end
    end

    legend(axList(end), 'Location','best','box','off');
    xlim([datetime(2018,1,1)  datetime(2020,1,1)] )
end


function fig = plotSalinityByDepth(Am, sims, simNames, target_depths, titleStr, tileShape)
% Plot Salinity comparison per target depth
% Same structure as Temperature

    if nargin < 5 || isempty(titleStr)
        titleStr = 'Salinity Comparison';
    end
    if nargin < 6 || isempty(tileShape)
        tileShape = [numel(target_depths) 1];
    end

    nSims = numel(sims);
    if nargin < 3 || isempty(simNames)
        simNames = arrayfun(@(k) sprintf('Sim%d', k), 1:nSims, 'UniformOutput', false);
    end

    if exist('brewermap','file')
        colors = brewermap(nSims,'Set1');
    else
        colors = lines(nSims);
    end

    fig = figure('Name', titleStr, 'Units','normalized','Position',[0.1 0.1 0.75 0.8]);
    tiledlayout(tileShape(1), tileShape(2), 'TileSpacing','compact','Padding','compact');

    validMask = ~all(isnan(Am.S),1);
    obs_dates = Am.dates(validMask);
    obs_S = Am.S(:,validMask);
    obs_depths = Am.depths;

    axList = gobjects(numel(target_depths),1);

    for k = 1:numel(target_depths)
        ax = nexttile; hold on;
        axList(k) = ax;

        td = target_depths(k);
        [~, idx_obs] = min(abs(obs_depths - td));

        for sIdx = 1:nSims
            s = sims{sIdx};
            s.date = datetime(s.t,'ConvertFrom','datenum');
            [~, idx_mod] = min(abs(s.z - td*-1));
            plot(s.date, s.S(idx_mod,:), '--', 'Color', colors(sIdx,:), 'LineWidth',1.5, ...
                 'DisplayName', simNames{sIdx});
        end

        plot(obs_dates, obs_S(idx_obs,:), '-k', 'LineWidth',1.3, 'DisplayName','Obs');

        title(sprintf('%d m', td));
        grid on; box on;
        ylabel('Salinity (PSU)');
    end

    linkaxes(axList,'xy');

    nCols = tileShape(2);
    nAx = numel(axList);
    bottomAxes = axList(nAx-nCols+1 : nAx);
    for jj = 1:nAx
        if ismember(axList(jj), bottomAxes)
            xlabel(axList(jj), 'Date');
        else
            axList(jj).XTickLabel = [];
        end
    end

    legend(axList(end), 'Location','best','box','off');
    xlim([datetime(2018,1,1)  datetime(2020,1,1)] )

end
target_depths = [ 50 100 200];



% Save the structure to a MAT-file
saveFolder = '/Users/annek/Library/CloudStorage/OneDrive-SharedLibraries-NIOZ/PhD Anneke Vries - General/fjord_modelling_ameralik/data/interim';
load(fullfile(saveFolder,'Ameralik_AM5.mat'));
load(fullfile(saveFolder,'Ameralik_mean_daily.mat'));


sims = {
    load('ameralik_combined_Kb1e-05_C01e+04.mat', 's').s, 
    load('ameralik_combined_Kb1e-05_C01e+05.mat', 's').s, 
    load('ameralik_combined_Kb1e-04_C01e+04.mat', 's').s, 
    load('ameralik_combined_Kb1e-04_C01e+05.mat', 's').s, 
    load('ameralik_combined_Kb1e-03_C01e+04.mat', 's').s, 
    load('ameralik_combined_Kb1e-03_C01e+05.mat', 's').s,
     % load('ameralik_combined_Kb1e-03_C01e+05_2019_only.mat', 's').s,
     % load('ameralik_combined_Kb1e-03_C01e+05_2019_FW_for_2018_shelf').s,
     % load('ameralik_combined_Kb1e-03_C01e+05_2018_shelf_for_2019').s,    
     % load('ameralik_combined_Kb1e-03_C01e+05_double_runoff').s,  
     % load('ameralik_combined_Kb1e-03_C01e+04_double_runoff').s,  

    };
simNames = {
    'Low mix - Low shelfX',
    'Low mix - High shelfX',
    'High mix - High shelfX',
    'High mix - Low shelfX', 
      'Very high mix - Low ShelfX',
    'Very high mix - High ShelfX',
    % 'Very high mix - High ShelfX - 2019 only',
    % '2019 FW 2018 Shelf and rest',
    % '2018 Shelf for 2019',
    % 'Double runoff - Very high mix - High ShelfX',
    %  'Double runoff - Very high mix - Low shelfX',

    };

figT = plotTemperatureByDepth(AM5, sims, simNames, target_depths, ...
    'Temperature Comparison', [2 2]);
% saveas(figT, fullfile(saveFolder_ts,'Temperature_comparison_multiSim.png'));

figS = plotSalinityByDepth(AM5, sims, simNames, target_depths, ...
    'Salinity Comparison', [2 2]);
% saveas(figS, fullfile(saveFolder_ts,'Salinity_comparison_multiSim.png'));



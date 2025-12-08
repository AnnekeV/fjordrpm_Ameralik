
folder_paths; % for saveFolderTS

%% Load data
load('/Users/annek/Library/CloudStorage/OneDrive-SharedLibraries-NIOZ/PhD Anneke Vries - General/fjord_modelling_ameralik/data/interim/Ameralik_mean_daily.mat'); 
load(fullfile(saveFolder,'Ameralik_AM5.mat'));
% Load first model (already loaded)
load('ameralik_combined_Kb1e-03_C01e+05.mat')  % strong mixing
s_very_high_mix = s;  % store as s1

% Load second model
load('ameralik_combined_Kb1e-05_C01e+05.mat')  % weak mixing
s_high_mix = s;  % store as s2
savename = 'very_high_mixing';



%%

% Convert model times to datetime
model_dates = datetime(s.t,'ConvertFrom','datenum');
model_depths = s.z;

% Observation dates
Ameralik_obs = AM5;

validMask = ~all(isnan(Ameralik_obs.T), 1);
obs_dates = Ameralik_obs.dates(validMask);
obs_depths = Ameralik_obs.depths;
obs_T = Ameralik_obs.T(:,validMask);
obs_S = Ameralik_obs.S(:,validMask);
obs_rho =  Ameralik_obs.rho(:,validMask);




%% Find closest model depth for target epth

target_depths = [50, 100, 200, 400];

target_depths = [50, 100, 200];


closest_idx_obs = zeros(length(target_depths),1);
closest_idx_mmod = zeros(length(target_depths),1);

for i = 1:length(target_depths)
    [z_target, idx_mod] = min(abs(model_depths - target_depths(i)*-1));
    closest_idx_mod(i) = idx_mod;
    z_target
    [~, idx_obs] = min(abs(obs_depths - target_depths(i)));
    closest_idx_obs(i) = idx_obs;
end


%% ONE FIGURE WITH THREE TILES: TEMPERATURE, SALINITY, DENSITY
fig = figure;
tiledlayout(2,1, 'TileSpacing','compact'); % three tiles stacked vertically
colors = lines(length(target_depths));
xlims = [datetime(2018,1,1) datetime(2019,12,31)];

%% TEMPERATURE TILE
ax1 = nexttile; hold on;

for i = 1:length(target_depths)
    plot(model_dates, s_very_high_mix.T(closest_idx_mod(i), :), '--', 'LineWidth', 1.5, 'Color', colors(i,:));
    % plot(model_dates, s_high_mix.T(closest_idx_mod(i), :), ':', 'LineWidth', 1.5, 'Color', colors(i,:));
    plot(obs_dates, obs_T(closest_idx_obs(i), :), '-', 'LineWidth', 1.5, 'Color', colors(i,:));
end
ylabel('Potential temperature (°C)');
grid off; box off;

%% SALINITY TILE
ax2 = nexttile; hold on;

for i = 1:length(target_depths)
    plot(model_dates, s_very_high_mix.S(closest_idx_mod(i), :), '--', 'LineWidth', 1.5, 'Color', colors(i,:));
    % plot(model_dates, s_high_mix.S(closest_idx_mod(i), :), ':', 'LineWidth', 1.5, 'Color', colors(i,:));
    plot(obs_dates, obs_S(closest_idx_obs(i), :), '-', 'LineWidth', 1.5, 'Color', colors(i,:));
end
ylabel('Salinity (PSU)');

%% DENSITY TILE
% ax3 = nexttile; hold on;
% 
% for i = 1:length(target_depths)
%     plot(model_dates, s.rho(closest_idx_mod(i), :), '--', 'LineWidth', 1.5, 'Color', colors(i,:));
%     plot(obs_dates, obs_rho(closest_idx_obs(i), :), '-', 'LineWidth', 1.5, 'Color', colors(i,:));
% end
% ylabel('Density (kg/m^3)');
% 
% % %% LEGEND (bottom tile)
% legendStrings = [];
% for i = 1:length(target_depths)
%     legendStrings{end+1} = sprintf('Model %d m', target_depths(i));
%     legendStrings{end+1} = sprintf('Obs %d m', target_depths(i));
% end
% % legend(ax3, legendStrings, 'Location', 'best'); % put legend in bottom tile


%% Formatting

% Array of axes
axAll = [ax1, ax2];

% Set x-limits and monthly ticks for all axes
startDate = datetime(2018,1,1);
endDate   = datetime(2019,12,31);
for k = 1:length(axAll)
    axAll(k).XLim = [startDate endDate];                     % x-limits
    axAll(k).XTick = startDate:calmonths(1):endDate;        % monthly ticks
end
xtickformat('MMM');        % Format: Jan, Feb, Mar...
% Remove x-axis labels for top tiles
for k = 1:length(axAll)-1
    axAll(k).XTickLabel = [];
end

% % Rotate labels only for bottom tile
% axAll(end).XTickLabelRotation = 45;



%% Create dummy lines for general legend
% General legend handles
hModel1 = plot(nan, nan, '--k', 'LineWidth', 1.5);   % Model Kb=1e-3
hModel2 = plot(nan, nan, ':k', 'LineWidth', 1.5);    % Model Kb=1e-4
hObs    = plot(nan, nan, '-k', 'LineWidth', 1.5);    % Observations

% Depth colors
hDepth = gobjects(length(target_depths),1);
for i = 1:length(target_depths)
    hDepth(i) = plot(nan, nan, '-', 'Color', colors(i,:), 'LineWidth', 1.5);
end


legendStrings = [      arrayfun(@(d) sprintf('%d m', d), target_depths, 'UniformOutput', false),  {'Observations', 'Model K_b=1e-3, C_0=1e5', }
];
legend(axAll(end), [hDepth', hObs, hModel1 ], legendStrings, 'Location', 'best', 'Box', false, 'NumColumns', 2);

%% SAVE FIGURE
saveas(fig, fullfile(saveFolder_ts, ['Timeseries_comparison_T_S' savename '.png']));

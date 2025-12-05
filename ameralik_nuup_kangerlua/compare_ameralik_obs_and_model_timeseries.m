

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

%% TEMPERATURE PLOT (shared limits, compact layout)

fig = figure;
tiledlayout(length(target_depths),1, 'TileSpacing','compact'); % tighter spacing

colors = lines(length(target_depths));

% Precompute shared limits
xlims = [datetime(2019,1,1) datetime(2019,12,31)];
ylims_T = [min(obs_T(:),[],'omitnan') min(s.T(:),[],'omitnan'); ...
           max(obs_T(:),[],'omitnan') max(s.T(:),[],'omitnan')];
ylims_T = [min(ylims_T(:)) max(ylims_T(:))];

for i = 1:length(target_depths)
    ax = nexttile; hold on;
    plot(model_dates, s.T(closest_idx_mod(i), :),'--','LineWidth',1.5, 'Color', colors(i,:))
    plot(obs_dates, obs_T(closest_idx_obs(i), :), '-','LineWidth',1.5, 'Color', colors(i,:))

    legend({sprintf('Model %d m', target_depths(i)), ...
            sprintf('Observations %d m', target_depths(i))}, 'Location','best');
    xlim(xlims); ylim(ylims_T);
    grid on; box on;
    ylabel('Temp (°C)');
    title(sprintf('%d m', target_depths(i)));

    % Remove xlabels and xticks for all but bottom tile
    if i < length(target_depths)
        ax.XTickLabel = [];
        xlabel('');
    else
        xlabel('Date');
    end
end

saveas(fig, fullfile(saveFolder, ['Timeseries_comparison_T_' savename '.png']));


%% SALINITY PLOT (shared limits, compact layout)

fig = figure;
tiledlayout(length(target_depths),1, 'TileSpacing','compact');

colors = lines(length(target_depths));

% Precompute shared limits
ylims_S = [min(obs_S(:),[],'omitnan') min(s.S(:),[],'omitnan'); ...
           max(obs_S(:),[],'omitnan') max(s.S(:),[],'omitnan')];
ylims_S = [min(ylims_S(:)) max(ylims_S(:))];

for i = 1:length(target_depths)
    ax = nexttile; hold on;
    plot(model_dates, s.S(closest_idx_mod(i), :),'--','LineWidth',1.5, 'Color', colors(i,:))
    plot(obs_dates, obs_S(closest_idx_obs(i), :), '-','LineWidth',1.5, 'Color', colors(i,:))

    legend({sprintf('Model %d m', target_depths(i)), ...
            sprintf('Observations %d m', target_depths(i))}, 'Location','best');
    xlim(xlims); ylim(ylims_S);
    grid on; box on;
    ylabel('Salinity (PSU)');
    title(sprintf('%d m', target_depths(i)));

    if i < length(target_depths)
        ax.XTickLabel = [];
        xlabel('');
    else
        xlabel('Date');
    end
end

saveas(fig, fullfile(saveFolder, ['Timeseries_comparison_S_' savename '.png']));

% 
% 
% legend(legend_strings, 'Location', 'best');
% xlim([datetime(2019,1,1) datetime(2019,12,31)]);
% grid on; box on;
% xlabel('Date'); ylabel('Salinity (PSU)')
% filename = fullfile(saveFolder, ['Timeseries_comparison_S_' savename '.png']);
% saveas(fig, filename); 
% 


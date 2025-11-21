

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


fig = figure; hold on;
colors = lines(length(target_depths));  % distinct colors

% give every target depth another color
for i = 1:length(target_depths)
    plot(model_dates, s.T(closest_idx_mod(i), :),'--','LineWidth',1.5, 'Color', colors(i,:))
    plot(obs_dates, obs_T(closest_idx_obs(i), :), '-','LineWidth',1.5, 'Color', colors(i,:))
    
end


legend_strings = strings(1, 2*length(target_depths));

for i = 1:length(target_depths)
    legend_strings(2*i-1) = sprintf('Model %d m', target_depths(i));
    legend_strings(2*i)   = sprintf('Observations %d m', target_depths(i));
end

legend(legend_strings, 'Location', 'best');
xlim([datetime(2019,1,1) datetime(2019,12,31)]);
grid on; box on;
xlabel('Date'); ylabel('Temperature (°C)');
saveFolder = '/Users/annek/Library/CloudStorage/OneDrive-SharedLibraries-NIOZ/PhD Anneke Vries - General/fjord_modelling_ameralik/figures/comparison_obs_model_timeseries';
filename = fullfile(saveFolder, ['Timeseries_comparison_T_' savename '.png']);
saveas(fig, filename); 


%% SALINITY PLOT

fig = figure; hold on;
colors = lines(length(target_depths));  % distinct colors

% plot for everytargetdepth
for i = 1:length(target_depths)
    plot(model_dates, s.S(closest_idx_mod(i), :),'--','LineWidth',1.5, 'Color', colors(i,:))
    plot(obs_dates, obs_S(closest_idx_obs(i), :), '-','LineWidth',1.5, 'Color', colors(i,:))
    
end


legend(legend_strings, 'Location', 'best');
xlim([datetime(2019,1,1) datetime(2019,12,31)]);
grid on; box on;
xlabel('Date'); ylabel('Salinity (PSU)')
filename = fullfile(saveFolder, ['Timeseries_comparison_S_' savename '.png']);
saveas(fig, filename); 



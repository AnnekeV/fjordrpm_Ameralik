close all;
clear all;
folder_paths; % for saveFolderTS
saveFolder = '/Users/annek/Library/CloudStorage/OneDrive-SharedLibraries-NIOZ/PhD Anneke Vries - General/fjord_modelling_ameralik/data/interim';

%% Load data
load('/Users/annek/Library/CloudStorage/OneDrive-SharedLibraries-NIOZ/PhD Anneke Vries - General/fjord_modelling_ameralik/data/interim/Ameralik_mean_daily.mat'); 
load(fullfile(saveFolder,'Ameralik_AM5.mat'));
% Load first model (already loaded)
load(    'ameralik_combined_Kb1e-03_C01e+05.mat')  % strong mixing
s1 = s;  % store as s1
s1.rhos = calculateDensity(s1.Ss, s1.Ts);

colors_general = colors_ameralik;
ls_model = colors_general.ls.VHIGH ;
savename = '';



%%

% Convert model times to datetime
model_dates = datetime(s1.t,'ConvertFrom','datenum');
model_depths = s1.z;

% Observation dates
Ameralik_obs = AM5;

validMask = ~all(isnan(Ameralik_obs.T), 1);
obs_dates = Ameralik_obs.dates(validMask);
obs_depths = Ameralik_obs.depths;
obs_T = Ameralik_obs.T(:,validMask);
obs_S = Ameralik_obs.S(:,validMask);
obs_rho =  Ameralik_obs.rho(:,validMask);




%% Find closest model depth for target epth

target_depths = [50, 100, 200];
% target_depths = [1, 5];
% 
% target_depths = [50, 100, 200, 5, 2];

Tlims = [-2,5];
Slims = [31.5, 33.5];


closest_idx_obs = zeros(length(target_depths),1);
closest_idx_mmod = zeros(length(target_depths),1);

for i = 1:length(target_depths)
    [z_target, idx_mod] = min(abs(model_depths - target_depths(i)*-1));
    closest_idx_mod(i) = idx_mod;
    z_target
    [~, idx_obs] = min(abs(obs_depths - target_depths(i)));
    closest_idx_obs(i) = idx_obs;
end



%% Print min and max sal/T for 2018–2019

% Create mask for obs dates in 2018 and 2019
mask = obs_dates.Year >= 2018 & obs_dates.Year <= 2019;

% Apply mask to obs arrays
obs_dates_filtered = obs_dates(mask);
obs_T_filtered     = obs_T(:, mask);
obs_S_filtered     = obs_S(:, mask);

for i = 1:length(target_depths)
    % Observations (2018–2019 only)
    Tmin = min(obs_T_filtered(closest_idx_obs(i), :), [], 'omitnan');
    Tmax = max(obs_T_filtered(closest_idx_obs(i), :), [], 'omitnan');

    Smin = min(obs_S_filtered(closest_idx_obs(i), :), [], 'omitnan');
    Smax = max(obs_S_filtered(closest_idx_obs(i), :), [], 'omitnan');

    fprintf('Obser: Depth %.1f m | T: %.1f–%.1f °C | S: %.2f–%.2f PSU\n', ...
        target_depths(i), Tmin, Tmax, Smin, Smax);

    % Model (exclude first 10 points for spin-up)
    Tmin = min(s1.T(closest_idx_mod(i), 10:end), [], 'omitnan');
    Tmax = max(s1.T(closest_idx_mod(i), 10:end), [], 'omitnan');

    Smin = min(s1.S(closest_idx_mod(i), 10:end), [], 'omitnan');
    Smax = max(s1.S(closest_idx_mod(i), 10:end), [], 'omitnan');

    fprintf('Model: Depth %.1f m | T: %.1f–%.1f °C | S: %.2f–%.2f PSU\n', ...
        target_depths(i), Tmin, Tmax, Smin, Smax);
end
%% ONE FIGURE WITH THREE TILES: TEMPERATURE, SALINITY, DENSITY
fig = figure('Position',[100 100 900 400]);
t = tiledlayout(2,1, 'TileSpacing','compact'); % three tiles stacked vertically
colors = lines(length(target_depths));

n = length(target_depths);
cmap = cmocean('dense', n+1);  % one extra color
colors = cmap(2:end, :);       % skip lightest color

colors = [
    hex2rgb('212121');   % dark charcoal
    % hex2rgb('4e418f');   % purple
    hex2rgb('2bc1b4');   % teal
    hex2rgb('c6c052');   % yellow-green
];
function rgb = hex2rgb(h)
    h = strrep(h, '#', '');
    rgb = [hex2dec(h(1:2)), hex2dec(h(3:4)), hex2dec(h(5:6))] / 255;
end


xlims = [datetime(2018,1,1) datetime(2020,01,02)];


%% TEMPERATURE TILE
ax1 = nexttile; hold on;

for i = 1:length(target_depths)
    plot(model_dates, s1.T(closest_idx_mod(i), :), ls_model, 'LineWidth', 1.5, 'Color', colors(i,:));
    plot(obs_dates, obs_T(closest_idx_obs(i), :), '-', 'LineWidth', 1.5, 'Color', colors(i,:));
    % plot(model_dates, s1.Ts(closest_idx_mod(i), :), ':', 'LineWidth', 1.5, 'Color', colors(i,:));

    % ylim(ax1, Tlims)
end
ylabel('Potential temperature (°C)');

% Add panel label

% Panel label
text(ax1, 0.01, 0.95, '(a)', 'Units','normalized', ...
    'FontWeight','bold','FontSize',12,'Color','black');

grid off; box off;

%% SALINITY TILE
ax2 = nexttile; hold on;

for i = 1:length(target_depths)
    plot(model_dates, s1.S(closest_idx_mod(i), :), ls_model, 'LineWidth', 1.5, 'Color', colors(i,:));
    plot(obs_dates, obs_S(closest_idx_obs(i), :), '-', 'LineWidth', 1.5, 'Color', colors(i,:));
    % plot(model_dates, s1.Ss(closest_idx_mod(i), :), ':', 'LineWidth', 1.5, 'Color', colors(i,:));

    % ylim(ax2, Slims)
end
ylabel('Salinity (PSU)');

% Add panel label


% Panel label
text(ax2, 0.01, 0.95, '(b)', 'Units','normalized', ...
    'FontWeight','bold','FontSize',12,'Color','black');

% %% DENSITY TILE
% ax3 = nexttile; hold on;
% 
% for i = 1:length(target_depths)
%     plot(model_dates, s1.rho(closest_idx_mod(i), :), '--', 'LineWidth', 1.5, 'Color', colors(i,:));
%     plot(model_dates, s1.rhos(closest_idx_mod(i), :), ':', 'LineWidth', 1.5, 'Color', colors(i,:));
% 
%     plot(obs_dates, obs_rho(closest_idx_obs(i), :), '-', 'LineWidth', 1.5, 'Color', colors(i,:));
% end
% ylabel('Density (kg m^{-3})');
% 
% 
% % Panel label
% text(ax1, 0.01, 0.95, '(c)', 'Units','normalized', ...
%     'FontWeight','bold','FontSize',12,'Color','black');


%% LEGEND (bottom tile)
legendStrings = [];
% for i = 1:length(target_depths)
%     legendStrings{end+1} = sprintf('Model %d m', target_depths(i));
%     legendStrings{end+1} = sprintf('Obs %d m', target_depths(i));
% end
legend(ax2, legendStrings, 'Location', 'best'); % put legend in bottom tile


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
hModel1 = plot(nan, nan, 'k', 'LineWidth', 1.5, 'LineStyle',ls_model);   % Model Kb=1e-3
% hShelf = plot(nan, nan, ':k', 'LineWidth', 1.5);    % Shelf Kb=1e-4

hObs    = plot(nan, nan, '-k', 'LineWidth', 1.5);    % Observations

% Depth colors
hDepth = gobjects(length(target_depths),1);
for i = 1:length(target_depths)
    hDepth(i) = plot(nan, nan, '-', 'Color', colors(i,:), 'LineWidth', 1.5);
end

% 
% legendStrings = [      arrayfun(@(d) sprintf('%d m', d), target_depths, 'UniformOutput', false),  {'Observations', 'Model', ' Shelf' }
% ];
% legend(axAll(end), [hDepth', hObs, hModel1 , hShelf], legendStrings, 'Location', 'best', 'Box', false, 'NumColumns', 2);

legendStrings = [      arrayfun(@(d) sprintf('%d m', d), target_depths, 'UniformOutput', false),  {'Observations', 'Model', }
];
legend(axAll(end), [hDepth', hObs, hModel1], legendStrings, 'Location', 'best', 'Box', false, 'NumColumns', 2);

%% SAVE FIGURE
% saveas(fig, fullfile(saveFolder_ts, ['Timeseries_comparison_T_S' savename '.png']));
% saveas(fig, fullfile(saveFolder_ts, ['Timeseries_comparison_T_S' savename '.pdf']));% Save PNG with controlled resolution
exportgraphics(fig, fullfile(saveFolder_ts, ...
    ['Timeseries_comparison_T_S' savename '.pdf']));
t.Padding = 'compact';
t.TileSpacing = 'compact';
% Save PDF tightly cropped to the figure area
% exportgraphics(fig, fullfile(saveFolder_ts, ...
%     ['Timeseries_comparison_T_S' savename '.pdf']), ...
%     'ContentType','vector', ...
%     'BackgroundColor','none');

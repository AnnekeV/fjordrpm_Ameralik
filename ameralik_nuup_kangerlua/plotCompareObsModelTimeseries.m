function fig = plotCompareObsModelTimeseries(Ameralik_mean, s, target_depths, varname, titleStr)
% PLOT_OBS_MODEL_TIMESERIES Plot model vs observation timeseries for temperature, salinity, or density.
%
% INPUTS:
%   Ameralik_mean - observational struct with fields: T, S, rho, depths, dates
%   s             - model struct with fields: T, S, rho, z, t
%   target_depths - vector of depths to plot [m], e.g., [50 100 200 400]
%   varname       - 'T' for temperature, 'S' for salinity, 'rho' for density

% OUTPUT:
%   fig           - figure handle

    %% Convert model times to datetime
    model_dates = datetime(s.t,'ConvertFrom','datenum');
    model_depths = s.z;

    %% Observation dates: only keep columns not all NaN
    switch varname
        case 'T'
            obs_data = Ameralik_mean.T;
        case 'S'
            obs_data = Ameralik_mean.S;
        case 'rho'
            obs_data = Ameralik_mean.rho;
        otherwise
            error('varname must be "T", "S", or "rho".');
    end

    validMask = ~all(isnan(obs_data), 1);
    obs_dates = Ameralik_mean.dates(validMask);
    obs_depths = Ameralik_mean.depths;
    obs_data = obs_data(:, validMask);

    %% Find closest model and observation depth indices
    closest_idx_obs = zeros(length(target_depths),1);
    closest_idx_mod = zeros(length(target_depths),1);

    for i = 1:length(target_depths)
        [~, idx_mod] = min(abs(model_depths - target_depths(i)*-1)); % model depths negative
        closest_idx_mod(i) = idx_mod;

        [~, idx_obs] = min(abs(obs_depths - target_depths(i)));
        closest_idx_obs(i) = idx_obs;
    end

    %% Create figure
    fig = figure; hold on;
    title(titleStr);

    colors = lines(length(target_depths));

    %% Plot each depth
    for i = 1:length(target_depths)
        % Model dashed line
        plot(model_dates, s.(varname)(closest_idx_mod(i), :), '--', ...
            'LineWidth', 1.5, 'Color', colors(i,:));

        % Observations solid line
        plot(obs_dates, obs_data(closest_idx_obs(i), :), '-', ...
            'LineWidth', 1.5, 'Color', colors(i,:));
    end

    %% Legend
    legend_strings = strings(1, 2*length(target_depths));
    for i = 1:length(target_depths)
        legend_strings(2*i-1) = sprintf('Model %d m', target_depths(i));
        legend_strings(2*i)   = sprintf('Observations %d m', target_depths(i));
    end
    legend(legend_strings, 'Location', 'best');

    %% Formatting
    xlim([datetime(2018,1,1) datetime(2019,12,31)]);
    grid on; box on;

    switch varname
        case 'T'
            ylabel('Temperature (°C)');
        case 'S'
            ylabel('Salinity (PSU)');
        case 'rho'
            ylabel('Density (kg/m³)');
    end

end

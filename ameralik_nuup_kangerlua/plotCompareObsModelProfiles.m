function plotCompareObsModelProfiles(Ameralik_mean, s)
% COMPAREOBSMODELPROFILES Compare observations and model profiles for temperature and salinity
% Each figure is for a single observation date, with two panels (T & S).
%
% INPUTS:
%   Ameralik_mean - struct with fields: T, S, depths, dates, nProfilesperdate
%   s             - model struct with fields: T, S, z, t

    % Convert model times to datetime
    model_dates = datetime(s.t,'ConvertFrom','datenum');

    % Observation dates
    obs_dates = Ameralik_mean.dates;

    % Find closest model date for each observation date
    closest_model_idx = arrayfun(@(d) findClosestDate(model_dates, d), obs_dates);


    % Determine plot limits
    xlimT = [min(Ameralik_mean.T(~isnan(Ameralik_mean.T)))-1, ...
             max(Ameralik_mean.T(~isnan(Ameralik_mean.T)))];
    xlimS = [min(Ameralik_mean.S(~isnan(Ameralik_mean.S))), ...
             max(Ameralik_mean.S(~isnan(Ameralik_mean.S)))+1];


    % Loop over observation dates
    for i = 1:length(obs_dates)
        if all(isnan(Ameralik_mean.T(:,i))) && all(isnan(Ameralik_mean.S(:,i)))
            continue
        end

        fig = figure('Name', datestr(obs_dates(i)), 'NumberTitle', 'off');
        tiledlayout(1,2);

        % Temperature panel
        axT = nexttile; hold(axT,'on');
        plot(axT, Ameralik_mean.T(:,i), Ameralik_mean.depths*-1, 'b', 'LineWidth', 1.5);
        plot(axT, s.T(:,closest_model_idx(i)), s.z, 'r--', 'LineWidth', 1.5);
        grid(axT,'on'); xlabel(axT,'Temperature (°C)'); ylabel(axT,'Depth (m)');
        xlim(axT, xlimT); legend(axT, 'Obs', 'Model','Location','best');

        % Salinity panel
        axS = nexttile; hold(axS,'on');
        plot(axS, Ameralik_mean.S(:,i), Ameralik_mean.depths*-1, 'b', 'LineWidth', 1.5);
        plot(axS, s.S(:,closest_model_idx(i)), s.z,'r--','LineWidth',1.5);
        grid(axS,'on'); xlabel(axS,'Salinity (PSU)'); ylabel(axS,'Depth (m)');
        xlim(axS, xlimS);

        % Optional: number of observations
        n_profiles = Ameralik_mean.nProfilesperdate(i);
        title(axS, sprintf('N obs = %d', n_profiles));

    end
end

%% ===== Helper functions =====

function idx = findClosestDate(dates, target)
    [~, idx] = min(abs(dates - target));
end


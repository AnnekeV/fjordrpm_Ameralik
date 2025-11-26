function fig = plotCompareObsModelProfiles(Ameralik_mean, s)
% PLOTCOMPAREOBSMODELPROFILES Compare obs and model profiles for all dates
% in a single figure. Each tile corresponds to one observation date (2 panels: T & S).
%
% INPUTS:
%   Ameralik_mean - struct with fields: T, S, depths, dates, nProfilesperdate
%   s             - model struct with fields: T, S, z, t
%
% OUTPUT:
%   fig           - figure handle

    % Convert model times to datetime
    model_dates = datetime(s.t,'ConvertFrom','datenum');
    obs_dates = Ameralik_mean.dates;

    % Find closest model date for each observation date
    closest_model_idx = arrayfun(@(d) findClosestDate(model_dates, d), obs_dates);

    % Determine plot limits for all dates
    xlimT = [min(Ameralik_mean.T(~isnan(Ameralik_mean.T)))-1, ...
             max(Ameralik_mean.T(~isnan(Ameralik_mean.T)))];
    xlimS = [min(Ameralik_mean.S(~isnan(Ameralik_mean.S))), ...
             max(Ameralik_mean.S(~isnan(Ameralik_mean.S)))+1];

    % Count valid dates
    validMask = ~all(isnan(Ameralik_mean.T) & all(isnan(Ameralik_mean.S)));
    nDates = sum(validMask);
    nRows = 3;

    % Create figure with tiled layout: rows = nDates, 2 columns (T & S)
    fig = figure('Name','Obs vs Model Comparison','NumberTitle','off');
    t = tiledlayout(nRows, ceil(nDates/nRows*2));%,'TileSpacing','compact','Padding','compact');
   

    dateIdx = find(validMask);

    for i = 1:nDates
        idx = dateIdx(i);

        % Temperature tile
        axT = nexttile((i-1)*2 + 1); hold(axT,'on');
        plot(axT, Ameralik_mean.T(:,idx), Ameralik_mean.depths*-1, 'b','LineWidth',1.5);
        plot(axT, s.T(:,closest_model_idx(idx)), s.z, 'r--','LineWidth',1.5);
        grid(axT,'on'); xlabel(axT,'Temperature (°C)'); ylabel(axT,'Depth (m)');
        xlim(axT, xlimT);
        if i == 1
            legend(axT, 'Obs','Model','Location','best');
        end
        title(axT, datestr(obs_dates(idx)));

        % Salinity tile
        axS = nexttile((i-1)*2 + 2); hold(axS,'on');
        plot(axS, Ameralik_mean.S(:,idx), Ameralik_mean.depths*-1, 'g','LineWidth',1.5);
        plot(axS, s.S(:,closest_model_idx(idx)), s.z, 'm--','LineWidth',1.5);
        grid(axS,'on'); xlabel(axS,'Salinity (PSU)'); yticklabels(axS, {});
        xlim(axS, xlimS);

        % Optional: number of observations
        n_profiles = Ameralik_mean.nProfilesperdate(idx);
        title(axS, sprintf('N obs = %d', n_profiles));
    end

end



%% ===== Helper function =====
function idx = findClosestDate(dates, target)
    [~, idx] = min(abs(dates - target));
end

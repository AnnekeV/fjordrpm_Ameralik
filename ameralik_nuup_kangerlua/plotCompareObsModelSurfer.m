function fig = plotCompareObsModelSurfer(Ameralik_mean,s,  target_var, ContourLevels)
% PLOT_OBSMODELTIMESERIES2D Plot 2D timeseries of observations and model.
%
% INPUTS:
%   Ameralik_mean - observational struct with fields: T, S, rho, depths, dates
%   s             - model struct with fields: T, S, rho, z, t
%   target_var    - 'T', 'S', or 'rho'
%   contourFlag   - true/false; overlay contours on top
%
% OUTPUT:
%   fig           - figure handle
  %% --- Extract observation data ---
    %% Get variable labels and choose cmocean colormap
    switch target_var
        case 'T'
            obs_data = Ameralik_mean.T;
            mod_data = s.T;
            yLabel = 'Temperature (°C)';
            cmap = cmocean('thermal');
        case 'S'
            obs_data = Ameralik_mean.S;
            mod_data = s.S;
            yLabel = 'Salinity (PSU)';
            cmap = cmocean('haline');
        case 'rho'
            obs_data = Ameralik_mean.rho;
            mod_data = s.rho;
            yLabel = 'Density (kg/m³)';
            cmap = cmocean('dense');
        otherwise
            error('target_var must be "T", "S", or "rho".');
    end
    
    %% Clean observations
    validMaskObs = ~all(isnan(obs_data),1);
    obs_data = obs_data(:, validMaskObs);
    obs_dates = datenum(Ameralik_mean.dates(validMaskObs));
    obs_depths = Ameralik_mean.depths;
    
    %% Model data
    mod_dates = s.t;
    mod_depths = s.z;
    
    %% Shared colorbar scaling
    allVals = [obs_data(:); mod_data(:)];
    p_low  = prctile(allVals, 1);
    p_high = prctile(allVals, 99);
    clims  = [p_low p_high];




    %% --- Create figure ---
    fig = figure('Color', 'w');

    %% --- Upper panel: observations ---
    ax1 = subplot(2,1,1); hold on;
    [Xobs, Yobs] = meshgrid(obs_dates, obs_depths);
    h1 = pcolor(Xobs, Yobs, obs_data);
    set(h1, 'EdgeColor', 'none');
    colormap(ax1, cmap);
    caxis(ax1, clims);
    colorbar;
    ylabel(yLabel);    
    xlim(datenum([datetime(2018,1,1) datetime(2019,12,31)]));
    ylim([0,700])
    set(gca, 'YDir', 'reverse'); % surface at top
    if length(ContourLevels)>0
        [C, hContour] = contour(Xobs, Yobs, obs_data-1000, ContourLevels, 'white', 'LineWidth', 1);
        clabel(C, hContour, 'FontSize', 10, 'Color', 'w');  % add values on the lines
    end

    %% --- Lower panel: model ---
    ax2 = subplot(2,1,2); hold on;
    [Xmod, Ymod] = meshgrid(mod_dates, mod_depths);
    h2 = pcolor(Xmod, Ymod, mod_data);
    set(h2, 'EdgeColor', 'none');
    colormap(ax2, cmap);
    caxis(ax2, clims);
    ylabel(yLabel);
    xlabel('Time');  %  xlim([datetime(2018,1,1) datetime(2019,12,31)]);
    ylim([-700,0])
    if length(ContourLevels)>0
        [C, hContour] = contour(Xmod, Ymod, mod_data-1000, ContourLevels, 'white', 'LineWidth', 1);
        clabel(C, hContour, 'FontSize', 10, 'Color', 'w');  % add values on the lines

    end

    %% --- Link x-axes for zooming/panning ---
    linkaxes([ax1, ax2], 'x');
    colorbar;

    grid(ax1,'on'); box(ax1,'on');
    grid(ax2,'on'); box(ax2,'on');
    title(ax1, 'Observations', 'Interpreter','none');
    title(ax2, 'Model', 'Interpreter','none');

    datetick(ax1, 'x', 'keeplimits'); % convert X axis back to dates
    datetick(ax2, 'x', 'keeplimits');



end



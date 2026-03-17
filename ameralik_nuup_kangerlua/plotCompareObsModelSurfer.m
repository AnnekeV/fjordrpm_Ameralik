function fig = plotCompareObsModelSurfer(Ameralik_obs,s,target_var,ContourLevels,ylim_max,cbar_range)
% PLOT_COMPAREOBSMODELSURFER Plot 2D timeseries of observations and model.
%
% INPUTS:
%   Ameralik_obs - observational struct with fields: T, S, rho, depths, dates
%   s             - model struct with fields: T, S, rho, z, t
%   target_var    - 'T', 'S', or 'rho'
%   ContourLevels - vector of contour levels to overlay
%
% OUTPUT:
%   fig           - figure handle

%% --- Extract variable data and colormap ---
switch target_var
    case 'T'
        obs_data = Ameralik_obs.T;
        mod_data = s.T;
        cbarLabel = 'Temperature (°C)';
        cmap = cmocean('thermal');
    case 'S'
        obs_data = Ameralik_obs.S;
        mod_data = s.S;
        cbarLabel = 'Salinity (PSU)';
        cmap = cmocean('haline');
    case 'rho'
        obs_data = Ameralik_obs.rho;
        mod_data = s.rho;
        cbarLabel = 'Density (kg/m³)';
        cmap = cmocean('dense');
    otherwise
        error('target_var must be "T", "S", or "rho".');
end

%% --- Clean observations ---
validMaskObs = ~all(isnan(obs_data),1);
obs_data = obs_data(:, validMaskObs);
obs_dates = datenum(Ameralik_obs.dates(validMaskObs));
obs_depths = Ameralik_obs.depths;

%% Model data
mod_dates = s.t;
mod_depths = s.z;


%% Shared colorbar scaling
if nargin < 6 || isempty(cbar_range)

    % automatic scaling
    allVals = [obs_data(:); mod_data(:)];
    p_low  = prctile(allVals,1);
    p_high = prctile(allVals,99);
    clims  = [p_low p_high];

else

    % user-defined color limits
    clims = cbar_range;

end

%% --- Create figure ---
fig = figure('Color', 'w', 'Position', [100 100 900 600]);

%% --- Use tiledlayout for tighter spacing ---
t = tiledlayout(2,1,'TileSpacing','compact','Padding','loose');

%% --- Upper panel: observations ---
ax1 = nexttile;
hold(ax1,'on');
[Xobs, Yobs] = meshgrid(obs_dates, obs_depths);
h1 = pcolor(Xobs, Yobs, obs_data);
set(h1, 'EdgeColor', 'none');
colormap(ax1, cmap);
caxis(ax1, clims);
ylabel('Depth (m)');
cb1 = colorbar;
cb1.Label.String = cbarLabel;

xlim(datenum([datetime(2018,1,1) datetime(2019,12,31)]));
ylim([0,ylim_max])
set(ax1, 'YDir', 'reverse'); % surface at top

shallowContours = ContourLevels <=25.5;

if ~isempty(ContourLevels)
    [C, hContour] = contour(Xobs, Yobs, obs_data-1000, ContourLevels, 'white', 'LineWidth', 1);
    clabel(C, hContour, 'FontSize', 10, 'Color', 'w');

    [C_shallow, hContour_shallow] = contour(Xobs, Yobs, obs_data-1000, ContourLevels(shallowContours), 'black', 'LineWidth', 1);
    clabel(C_shallow, hContour_shallow, 'FontSize', 10, 'Color', 'black');


end

% Add panel label
text(ax1.XLim(1)-50, ax1.YLim(1), '(a)', 'FontWeight','bold','FontSize',12, 'Color','black');

%% --- Lower panel: model ---
ax2 = nexttile;
hold(ax2,'on');
[Xmod, Ymod] = meshgrid(mod_dates, mod_depths*-1);
h2 = pcolor(Xmod, Ymod, mod_data);
set(h2, 'EdgeColor', 'none');
colormap(ax2, cmap);
caxis(ax2, clims);
ylabel('Depth (m)');
cb2 = colorbar;
cb2.Label.String = cbarLabel;

ylim([0,ylim_max])
set(ax2, 'YDir', 'reverse'); % surface at top
xlim(datenum([datetime(2018,1,1) datetime(2019,12,31)]));

if ~isempty(ContourLevels)
    [C, hContour] = contour(Xmod, Ymod, mod_data-1000, ContourLevels, 'white', 'LineWidth', 1);
    clabel(C, hContour, 'FontSize', 10, 'Color', 'w');

    [C_shallow, hContour_shallow] = contour(Xmod, Ymod, mod_data-1000, ContourLevels(shallowContours), 'black', 'LineWidth', 1);
    clabel(C_shallow, hContour_shallow, 'FontSize', 10, 'Color', 'black');
end

% Add panel label
text(ax2.XLim(1)-50, ax2.YLim(1), '(b)', 'FontWeight','bold','FontSize',12, 'Color','black');

%% --- Link x-axes and format ---
linkaxes([ax1, ax2], 'x');

start_date = datenum(datetime(2018,1,1));
end_date   = datenum(datetime(2020,1, 2));
tick_dates = datenum(datetime(2018,1,1) : calmonths(3) : datetime(2020,1,2));

set(ax1, 'XTick', tick_dates);
set(ax2, 'XTick', tick_dates);

datetick(ax1, 'x', 'mmm yyyy', 'keeplimits', 'keepticks');
datetick(ax2, 'x', 'mmm yyyy', 'keeplimits', 'keepticks');
% Remove grids
grid(ax1,'off'); box(ax1,'off');
grid(ax2,'off'); box(ax2,'off');

end

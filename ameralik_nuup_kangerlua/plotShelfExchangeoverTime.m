load ('ameralik_nuup_kangerlua/ameralik_combined_Kb1e-04_C01e+05_tidal.mat')
save_name = 'FW_export_surfer_high_wtidal.png';

load('ameralik_combined_Kb1e-03_C01e+05.mat'), 
save_name = 'FW_export_surfer_vhigh_notidal.png';


colors_ameralik;
folder_paths; % for saveFolderTS

%% VOLUME FLUXES ----------------------------------------------------------
a.A0v = s.H*p.W; %area vertical
a.A0v = a.A0v(find(abs(s.z)<110));

s.QVs = s.QVs(find(abs(s.z)<110), :);
s.UVs = s.QVs ./ a.A0v;         % mean velocity

s.z = s.z(find(abs(s.z)<110));



% time vectors
s.t_date = datetime(s.t, 'ConvertFrom','datenum');
s.t_start = datetime(s.t(1), 'ConvertFrom','datenum', 'Format','d MMM yyyy');
s.t_days_since_start = s.t - s.t(1);

% first cut t

close all;

%%
% plot filled contours (15 contour levels)
nlevels = 25;
nlevels=15;
contourf(s.t, s.z, s.UVs);%, nlevels, 'LineColor', 'none'); 
% % pcolor(s.UVs)

ylim([-115, 0])

%%
% Determine symmetric color limits
dataMax = max(abs(s.UVs(:)));  % max absolute value
cmax = 0.20;                   % maximum for colorbar
cmin = -cmax;                   % symmetric min

% Apply diverging colormap
colormap(divergingCMap(c_shelf_in, c_shelf_out, nlevels*2));
caxis([cmin cmax]);

% Colorbar
cb = colorbar;
cb.Label.String = 'Exchange velocity (m/s)';

% Set symmetric ticks on colorbar
nTicks = 5; % number of ticks
cb.Ticks = linspace(cmin, cmax, nTicks);

% Improve appearance
xlabel('Time (days since start)');
ylabel('Depth (m)');
title('Time–Depth Filled Contours of Exchange Velocity');

% Set x-axis back to datetime
% Define ticks automatically for every month
startDate = dateshift(s.t_date(1), 'start', 'month');
endDate   = dateshift(s.t_date(end), 'start', 'month');
xticksDates = startDate:calmonths(1):endDate;

% Convert datetime ticks to numeric
ax = gca;
ax.XTick = datenum(xticksDates);
ax.XTickLabel = datestr(xticksDates, 'mmm-yyyy'); % e.g., Jan-2025
xtickangle(45)  % rotate for readability


colorbar;
ylabel('Depth');
title('Shelf Exchange Over Time');

filename = fullfile(folder_fig, 'Shelf_exchange', save_name);
exportgraphics(gcf, filename, 'Resolution',300);



function custom_cmap = divergingCMap(c_neg, c_pos, nColors)
    % divergingCMap creates a colormap from c_neg -> white -> c_pos
    % Inputs:
    %   c_neg   - RGB color for negative values (1x3)
    %   c_pos   - RGB color for positive values (1x3)
    %   nColors - total number of colors (default 256)
    
    if nargin < 3
        nColors = 500;
    end
    
    nHalf = floor(nColors/2);
    midColor = [1 1 1]; % white in the middle

    cmap_neg = interp1([0 1], [c_neg; midColor], linspace(0,1,nHalf));
    cmap_pos = interp1([0 1], [midColor; c_pos], linspace(0,1,nColors-nHalf));
    
    custom_cmap = [cmap_neg; cmap_pos];
end
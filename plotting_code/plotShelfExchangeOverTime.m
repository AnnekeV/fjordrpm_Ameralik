load('../ameralik_nuup_kangerlua/ameralik_combined_Kb1e-03_C01e+04.mat')

s.t_date = datetime(s.t, 'ConvertFrom','datenum');

s.t_start = datetime(s.t(1), 'ConvertFrom','datenum', 'Format','d MMM yyyy');
s.t_days_since_start = s.t - s.t(1);

figure
x = s.t;  % convert datetime to numeric if needed
y = s.z;           % depth vector
Z = s.QSs;              % 2D matrix: depth x date

% Create contour plot
contourf(x, y, Z, 50, 'LineColor', 'none');  % 20 contour levels
colorbar


% Format x-axis as dates
datetick('x','yyyy-mm-dd')

xlabel('Date')
ylabel('Depth')
ylim([-150 0])
title('Shelf exchange Contour')
% --- Diverging colormap centered at zero ---
% Get min and max for symmetric limits
absmax = max(abs(Z(:)));
caxis([-absmax absmax]);  % center colormap at 0

% Use cmocean 'balance' if available (blue-red diverging)
if exist('cmocean','file')
    colormap(cmocean('balance', 256))
else
    % Fallback: simple red-blue colormap
    n = 256;
    red = [linspace(0,1,n/2)', zeros(n/2,1), zeros(n/2,1)];  % negative
    blue = [zeros(n/2,1), zeros(n/2,1), linspace(1,0,n/2)']; % positive
    cmap = [blue; red];  % combine
    colormap(cmap)
end

figure
plot(mean(s.QSs,2), s.z)
ylim([-150 0])
grid on;
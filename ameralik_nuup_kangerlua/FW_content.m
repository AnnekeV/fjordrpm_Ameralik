function FW = fw_content(S, z, H0, Sref, min_depth, max_depth)
% FW_CONTENT  Compute freshwater content from salinity profiles.
%
% Inputs:
%   S         - salinity matrix (nz × nt)
%   z         - depth array (nz × 1)
%   H0        - layer thicknesses (nz × 1)
%   Sref      - reference salinity
%   min_depth - minimum depth for integration
%   max_depth - maximum depth for integration
%
% Output:
%   FW        - freshwater content time series (1 × nt)

    % Identify layers within requested depth interval
    layers = find(abs(z) > min_depth & abs(z) < max_depth);

    % Compute FW content: sum over depth layers
    FW = sum(((Sref - S(layers,:)) ./ Sref) .* H0(layers), 1);

end



load('ameralik_combined_set_fjord_initial.mat'); 
load('/Users/annek/Library/CloudStorage/OneDrive-SharedLibraries-NIOZ/PhD Anneke Vries - General/fjord_modelling_ameralik/data/interim/Ameralik_mean_daily.mat'); 


% Option B: using 'all' and 'omitnan' (R2018b+)
mn = min(s.S, [], 'all', 'omitnan');
mx = max(s.S, [], 'all', 'omitnan');
fprintf('max(s.S) = %g\nmin(s.S) = %g\n', mx, mn);


% salinity threshold for model
Sref = 33.6;


close all;



% Colorblind-friendly palette
cbColors = [
    0, 0, 0;          % black
    230, 159, 0;      % orange
    86, 180, 233;     % sky blue
    0, 158, 115;      % bluish green
    240, 228, 66;     % yellow
    0, 114, 178;      % blue
    213, 94, 0;       % vermillion
    204, 121, 167    % reddish purple
] / 255;


s.date = datetime(s.t, "ConvertFrom", "datenum");

figure; hold on;
% fjord FW content
plot(s.date, fw_content(s.S, s.z, a.H0, Sref, 0, 50), 'DisplayName', 'Model Fjord: 0-50 m', 'Color', cbColors(1,:));
plot(s.date, fw_content(s.S, s.z, a.H0, Sref, 50, 200),  'DisplayName', 'Model Fjord: 50-200 m', 'Color',cbColors(2,:));
hold on;
plot(s.date, fw_content(s.S, s.z, a.H0, Sref, 200, 500),  'DisplayName', 'Model Fjord: 200-500 m', 'Color',cbColors(3,:));

% 
% % shelf FW content
% plot(s.date, fw_content(s.Ss, s.z, a.H0, Sref, 0, 50), 'DisplayName', 'Shelf: 0-50 m')
% hold on;
% plot(s.date, fw_content(s.Ss, s.z, a.H0, Sref, 50, 200),  'DisplayName', 'Shelf: 50-200 m');
% hold on;
% plot(s.date, fw_content(s.Ss, s.z, a.H0, Sref, 200, 500),  'DisplayName', 'Shelf: 200-500 m');



Ameralik_mean.dz = ones(size(Ameralik_mean.depths));

% Define depth ranges and labels for observational
depth_ranges = [0 50; 50 200; 200 500];
labels = {'Observations: 0-50 m', 'Obervations: 50-200 m', 'Observations: 200-500 m'};


% Loop through each depth range
for k = 1:size(depth_ranges,1)
    
    % Compute FW content
    FW = fw_content(Ameralik_mean.S, Ameralik_mean.depths * -1, Ameralik_mean.dz, ...
        33.3, depth_ranges(k,1), depth_ranges(k,2));
    
    % Remove NaNs and corresponding dates
    FW_valid = FW(~isnan(FW));
    dates_valid = Ameralik_mean.dates(~isnan(FW));
    
    
    % Plot line and scatter
    plot(dates_valid, FW_valid, 'Color', cbColors(k, :), 'DisplayName', labels{k}, 'LineStyle','--')
    scat = scatter(dates_valid, FW_valid, 25, cbColors(k, :), 'filled' , 'DisplayName','')
    scat.Annotation.LegendInformation.IconDisplayStyle = 'off';

end




ylabel('FW content (m)');
% title('Freshwater Content per Depth Range with S_{ref} =' + Sref(1))
legend('Location','best');
grid on;

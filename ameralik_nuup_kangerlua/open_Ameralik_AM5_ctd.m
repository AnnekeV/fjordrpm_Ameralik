%% =====================================================================
%  Process Ameralik CTD Data
% Input is pangea data Stuart Lee 2021
%
%  1. Load CTD temperature and salinity data for Ameralik fjord.
%  2. Organize into 3D matrices: Depth × Station × Time.
%  3. Filter out time steps with no valid data.
%  3a Calculates Potential temperature and density from in situ temp and
%  salinity
%  4. Optionally collapse consecutive time steps ≤1 day apart:
%       - Fill NaNs from day t+1 into day t
%       - Average where both have data (with warnings)
%  5. Output cleaned matrices T3D_Am, S3D_Am, rho_theta, and unique_times.
%
%  Notes:
%    - Depths assumed uniform across stations
%    - Works for multiple stations simultaneously
% 
%  Anneke Vries 26 November
% =====================================================================


plot_everything = true; 
plot_individual_dates = false; % watch out!!! many figures... don't do it


% Open CTDs from Ameralik as published on pangea
addpath('/Users/annek/Documents/gsw_matlab_v3_06_16')
addpath('/Users/annek/Documents/gsw_matlab_v3_06_16/library')
savepath()
gsw_ver()  % should return the toolbox versionavepath

% File path
filename = "/Users/annek/Library/CloudStorage/OneDrive-SharedLibraries-NIOZ/PhD Anneke Vries - General/fjord_modelling_ameralik/data/raw/AM5_no_duplicates.csv";
saveFolder = '/Users/annek/Library/CloudStorage/OneDrive-SharedLibraries-NIOZ/PhD Anneke Vries - General/fjord_modelling_ameralik/figures/CTD_profiles_Ameralik';

% Read the table
data = readtable(filename);

% Inspect variable names (MATLAB will replace spaces/special characters)
disp(data.Properties.VariableNames);

% Convert date/time to datetime array
time = datetime(data.time, 'InputFormat', 'yyyy-MM-dd');
t_start = datetime(2013,1,1);
days_since = datenum(time) - datenum(t_start);
data.days_since = days_since;


%%
% ---------------------------
% 1. Extract unique times, stations, and depths
% ---------------------------
unique_times  = unique(data.time);
unique_depths = unique(data.Depth);  % 1-m spacing assumed

nd = length(unique_depths);
nt = length(unique_times);

% ---------------------------
% 2. Initialize matrices for each fjord
% ---------------------------

T3D_Am = NaN(nd, 1, nt);  
S3D_Am = NaN(nd, 1, nt);  

% ---------------------------
% 4. Fill matrices
% ---------------------------
for ti = 1:nt
    this_time = unique_times(ti);
    idx_t = data.time == this_time;
    data_t = data(idx_t,:);

    % ------------------------
    % Ameralik stations
    % ------------------------
    stname = "AM5";
    depth = data_t.Depth;
    temp  = data_t.Temperature;
    sal   = data_t.Salinity;
    [~, row_idx] = ismember(depth, unique_depths);
    T3D_Am(row_idx, 1, ti) = temp;
    S3D_Am(row_idx, 1, ti) = sal;
   
end

%%

% Convert T3D to Potential Temperature and compute density
lon = -51; 
lat = 64; 
pref = 0;

% Convert SP -> Absolute Salinity
SA = gsw_SA_from_SP(S3D_Am, pref, lon, lat);

% Convert in situ temperature -> Conservative Temperature
CT = gsw_CT_from_t(SA, T3D_Am, pref);

% Calculate potential density referenced to 0 dbar
rho_theta = gsw_rho(SA, CT, pref);  

% Potential temperature from Conservative Temperature
theta = gsw_pt_from_CT(SA, CT);


% =====================================================================
%    Select AM5 and export
% ======================================================================


% Extract only AM5 station from 3D fields
AM5 = struct();

AM5.T     = squeeze(theta(:, 1, :));       % depth × time
AM5.S     = squeeze(S3D_Am(:, 1, :));      % depth × time
AM5.rho   = squeeze(rho_theta(:, 1, :));   % depth × time
AM5.depths = unique_depths;
AM5.dates  = unique_times;


% Initial winter conditions for AM5 only
inWinter = (month(unique_times) > 10) | (month(unique_times) < 3);
AM5.T_init   = mean(AM5.T(:, inWinter), 2, 'omitnan');
AM5.S_init   = mean(AM5.S(:, inWinter), 2, 'omitnan');
AM5.rho_init = mean(AM5.rho(:, inWinter), 2, 'omitnan');

AM5.stationName  = "AM5";   % optional label

saveFolder = '/Users/annek/Library/CloudStorage/OneDrive-SharedLibraries-NIOZ/PhD Anneke Vries - General/fjord_modelling_ameralik/data/interim';
save(fullfile(saveFolder,'Ameralik_AM5.mat'), 'AM5');


figure
x = datenum(AM5.dates);  % convert datetime to numeric if needed
y = AM5.depths;           % depth vector
Z = AM5.rho;              % 2D matrix: depth x date

% Create contour plot
contourf(x, y, Z, 20, 'LineColor', 'none');  % 20 contour levels
colorbar
% Reverse y-axis for oceanographic convention
set(gca,'YDir','reverse')

% Format x-axis as dates
datetick('x','yyyy-mm-dd','keepticks')

xlabel('Date')
ylabel('Depth')
title('Density Contour')

% ==============================
%       PLOTTING
% ==============================


if plot_everything
    fig_all = figure;
    tiledlayout(1,2);
    
    cmap_obs = parula(365);   % one colour per date
    
    % ==============================
    %       TEMPERATURE PROFILES
    % ==============================
    nexttile; hold on;
    
    for t = 1:length(unique_times)
        idx_date = data.time == unique_times(t);
        data_Date = data(idx_date,:);
        depth = data_Date.Depth;
        temp  = data_Date.Temperature;
        plot(temp, depth, 'LineWidth', 1.4, 'Color', cmap_obs(mod(data_Date.days_since(1),365),:));
        
    end
    
    set(gca,'YDir','reverse');
    xlabel('Temperature (°C)');
    ylabel('Depth (m)');
    % title('In situ temperature Profiles');
    h = colorbar; colormap(gca,cmap_obs); caxis([1, size(cmap_obs,1)]);    
    
    % ==============================
    %        SALINITY PROFILES
    % ==============================
    nexttile; hold on;
    
    
    for t = 1:length(unique_times)
        idx_date = data.time == unique_times(t);
        data_Date = data(idx_date,:);
        depth = data_Date.Depth;
        sal  = data_Date.Salinity;
        plot(sal, depth, 'LineWidth', 1.4, 'Color', cmap_obs(mod(data_Date.days_since(1),365),:));
    end
    
    set(gca,'YDir','reverse');
    xlabel('Temperature (°C)');
    ylabel('Depth (m)');
    % title('Salinity Profiles');
    h = colorbar; colormap(gca,cmap_obs); caxis([1, size(cmap_obs,1)]);
    figName = fullfile(saveFolder, 'CTD_Ameralik_all.png');
    % saveas(fig_all, figName)


end
if plot_individual_dates
    % # Plotting Ameralik per date
    % Number of stations and depths
    [nDepths, nStn, nTime] = size(T3D_Am);
    
    
    % Precompute limits for all plots
    allT = T3D_Am(:);
    allS = S3D_Am(:);
    xlimT = [min(allT(~isnan(allT))), max(allT(~isnan(allT)))];
    xlimS = [min(allS(~isnan(allS))), max(allS(~isnan(allS)))];
    ylimD = [min(unique_depths), max(unique_depths)];
    
    
    
    for ti = 1:nTime
        % Check if there is any data for this date
        if all(isnan(T3D_Am(:,:,ti)))
            continue  % skip if no stations have data
        end
    
        % Create new figure per date
        fig = figure('Name', datestr(unique_times(ti), 'yyyy-mm-dd'), 'NumberTitle', 'off');
        t = tiledlayout(1,2, 'TileSpacing','compact','Padding','compact');
    
        % -----------------------------
        % TEMPERATURE
        % -----------------------------
        ax1 = nexttile; hold on;
        plot(T3D_Am(:,1,ti), unique_depths, 'LineWidth', 1.5);
        set(ax1,'YDir','reverse', 'XLim', xlimT, 'YLim', ylimD);
        xlabel('In situ temperature (°C)');
        ylabel('Depth (m)');
        % title(['Temperature - ', datestr(unique_times(ti), 'yyyy-mm-dd')]);
    
        if ~isempty(plotted_stns)
            legend(plotted_stns,'Location','best');
        end
    
        % -----------------------------
        % SALINITY
        % -----------------------------
        ax2 = nexttile; hold on;
        plot(S3D_Am(:,1,ti), unique_depths, 'LineWidth', 1.5);
        set(ax2,'YDir','reverse', 'XLim', xlimS, 'YLim', ylimD);
        xlabel('Salinity (PSU)');
        ylabel('Depth (m)');
        % title(['Salinity - ', datestr(unique_times(ti), 'yyyy-mm-dd')]);
        if ~isempty(plotted_stns)
            legend(plotted_stns,'Location','best');
        end
        % -----------------------------
        % Save figure
        % -----------------------------
        figName = fullfile(saveFolder, ['CTD_Ameralik_', datestr(unique_times(ti), 'yyyy-mm-dd'), '.png']);
        % saveas(fig, figName);
        % close(fig);  % close figure to avoid too many open figures
    end
end


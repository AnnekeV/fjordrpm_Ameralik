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


plot_everything = false; 


% Open CTDs from Ameralik as published on pangea
addpath('/Users/annek/Documents/gsw_matlab_v3_06_16')
addpath('/Users/annek/Documents/gsw_matlab_v3_06_16/library')
savepath()
gsw_ver()  % should return the toolbox versionavepath

% File path
filename = '/Users/annek/Library/CloudStorage/OneDrive-SharedLibraries-NIOZ/PhD Anneke Vries - General/fjord_modelling_ameralik/data/raw/SW-Greenland-fjords_CTD.tab';
saveFolder = '/Users/annek/Library/CloudStorage/OneDrive-SharedLibraries-NIOZ/PhD Anneke Vries - General/fjord_modelling_ameralik/figures/CTD_profiles_Ameralik';

% Detect import options
opts = detectImportOptions(filename, 'FileType', 'text', 'Delimiter', '\t');

% Skip comment lines starting with /*
opts.CommentStyle = '/*';

% Read the table
data = readtable(filename, opts);

% Inspect variable names (MATLAB will replace spaces/special characters)
disp(data.Properties.VariableNames);

% Convert date/time to datetime array
time = datetime(data.Date_Time, 'InputFormat', 'yyyy-MM-dd');
t_start = datetime(2019,1,1);
days_since = datenum(time) - datenum(t_start);
data.days_since = days_since;



unique_times  = unique(data.Date_Time);
unique_stn    = unique(data.Event);
%%
% ---------------------------
% 1. Extract unique times, stations, and depths
% ---------------------------
unique_times  = unique(data.Date_Time);
unique_stn   = unique(data.Event);
unique_depths = unique(data.DepthWater_m_);  % 1-m spacing assumed

nd = length(unique_depths);
nt = length(unique_times);


% ---------------------------
% 3. Separate station lists
% ---------------------------
stn_Am = unique_stn(contains(unique_stn,'Ameralik'));
stn_NK = unique_stn(contains(unique_stn,'God'));
idx_AM5 = find(contains(stn_Am, 'AM5'));

% ---------------------------
% 2. Initialize matrices for each fjord
% ---------------------------

T3D_Am = NaN(nd, length(stn_Am), nt);  
S3D_Am = NaN(nd, length(stn_Am), nt);  

T3D_NK = NaN(nd, length(stn_NK), nt);  
S3D_NK = NaN(nd, length(stn_NK), nt);  


% ---------------------------
% 4. Fill matrices
% ---------------------------
for ti = 1:nt
    this_time = unique_times(ti);
    idx_t = data.Date_Time == this_time;
    data_t = data(idx_t,:);

    % ------------------------
    % Ameralik stations
    % ------------------------
    for si = 1:length(stn_Am)
        stname = stn_Am{si};
        idx_s = strcmp(data_t.Event, stname);
        if ~any(idx_s), continue; end
        depth = data_t.DepthWater_m_(idx_s);
        temp  = data_t.Temp__C_(idx_s);
        sal   = data_t.Sal(idx_s);
        [~, row_idx] = ismember(depth, unique_depths);
        T3D_Am(row_idx, si, ti) = temp;
        S3D_Am(row_idx, si, ti) = sal;
    end

    % ------------------------
    % Godthåbsfjord stations
    % ------------------------
    for si = 1:length(stn_NK)
        stname = stn_NK{si};
        idx_s = strcmp(data_t.Event, stname);
        if ~any(idx_s), continue; end
        depth = data_t.DepthWater_m_(idx_s);
        temp  = data_t.Temp__C_(idx_s);
        sal   = data_t.Sal(idx_s);
        [~, row_idx] = ismember(depth, unique_depths);
        T3D_NK(row_idx, si, ti) = temp;
        S3D_NK(row_idx, si, ti) = sal;
    end
end

% -------------------------------------------
% Make new list of times where Ameralik has data
% -------------------------------------------
hasProfile_Am = squeeze(any(any(~isnan(T3D_Am), 1), 2));  % logical index
unique_times_Am = unique_times(hasProfile_Am);

T3D_Am = T3D_Am(:,:,hasProfile_Am);
S3D_Am = S3D_Am(:,:,hasProfile_Am);



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




% ======================================================================
%    Select AM5 and export
% ======================================================================


% Extract only AM5 station from 3D fields
AM5 = struct();

AM5.T     = squeeze(theta(:, idx_AM5, :));       % depth × time
AM5.S     = squeeze(S3D_Am(:, idx_AM5, :));      % depth × time
AM5.rho   = squeeze(rho_theta(:, idx_AM5, :));   % depth × time
AM5.depths = unique_depths;
AM5.dates  = unique_times_Am;

% Condition: after October (month > 10) and before April (month < 4)
inWinter = (month(unique_times_Am) > 10) | (month(unique_times_Am) < 4);

% Initial winter conditions for AM5 only
inWinter = (month(unique_times_Am) > 10) | (month(unique_times_Am) < 4);
AM5.T_init   = mean(AM5.T(:, inWinter), 2, 'omitnan');
AM5.S_init   = mean(AM5.S(:, inWinter), 2, 'omitnan');
AM5.rho_init = mean(AM5.rho(:, inWinter), 2, 'omitnan');

% Logical index of times where there is at least one valid depth measurement 
% Aka remove any times on which no CTD profile is taken
valid_times = any(~isnan(AM5.T), 1);
AM5.T    = AM5.T(:, valid_times);
AM5.S    = AM5.S(:, valid_times);
AM5.rho  = AM5.rho(:, valid_times);
AM5.dates = AM5.dates(valid_times);

% 
AM5.stationIndex = idx_AM5;
AM5.stationName  = "AM5";   % optional label

saveFolder = '/Users/annek/Library/CloudStorage/OneDrive-SharedLibraries-NIOZ/PhD Anneke Vries - General/fjord_modelling_ameralik/data/interim';
save(fullfile(saveFolder,'Ameralik_AM5.mat'), 'AM5');




% ---------------------------------------------------------
% Backward loop: average consecutive days and store in new matrix
% ---------------------------------------------------------

% Temperature
[theta_new, unique_times_Am_new_T] = collapse_consecutive_days(theta, unique_times_Am, stn_Am);
[S3D_Am_new, unique_times_Am_new] = collapse_consecutive_days(S3D_Am, unique_times_Am, stn_Am);
[rho_theta_new, ~] = collapse_consecutive_days(rho_theta, unique_times_Am, stn_Am);

% Assert that resulting times match
assert(isequal(unique_times_Am_new_T, unique_times_Am_new), ...
    'Error: Time vectors for T3D and S3D do not match after collapsing consecutive days.');



% ======================================================================
%    Calculate mean profile of all stations in the fjord, i.e. mean per day
% ======================================================================


% Initialize matrices for daily averages
nDepths = length(unique_depths);
nTime   = length(unique_times_Am_new);

T_daily_mean = NaN(nDepths, nTime);
S_daily_mean = NaN(nDepths, nTime);
rho_daily_mean = NaN(nDepths, nTime);
nProfilesperdate  = zeros(nTime);


% Loop over time steps
for ti = 1:nTime
    temp_slice = theta_new(:,:,ti);  % all stations at this time
    sal_slice  = S3D_Am_new(:,:,ti);
    rho_slice  = rho_theta_new(:,:,ti);

    % Skip if no data
    if all(isnan(temp_slice(:))) && all(isnan(sal_slice(:)))
        continue
    end

    % Mean over stations, ignoring NaNs
    T_daily_mean(:,ti) = mean(temp_slice, 2, 'omitnan');
    S_daily_mean(:,ti) = mean(sal_slice, 2, 'omitnan');
    rho_daily_mean(:,ti) = mean(rho_slice, 2, 'omitnan');

    % Count number of valid profiles per date (stations with any data)
    nProfilesperdate(ti) = sum(any(~isnan(temp_slice), 1));
end






% Condition: after October (month > 10) and before April (month < 4)
inWinter = (month(unique_times_Am_new) > 10) | (month(unique_times_Am_new) < 4);

% Combine into a single structure that has the mean along fjord axis
Ameralik_mean = struct();
Ameralik_mean.T = T_daily_mean;
Ameralik_mean.S = S_daily_mean;
Ameralik_mean.rho = rho_daily_mean;
Ameralik_mean.depths = unique_depths;
Ameralik_mean.dates  = unique_times_Am_new;
Ameralik_mean.nProfilesperdate = nProfilesperdate;
% Initial conditions = winter mean over time & stations
Ameralik_mean.T_init = mean(theta(:,:,inWinter), [2 3], 'omitnan');
Ameralik_mean.S_init = mean(S3D_Am(:,:,inWinter), [2 3], 'omitnan');
Ameralik_mean.rho_init = mean(rho_theta(:,:,inWinter), [2 3], 'omitnan');


% Save the structure to a MAT-file
saveFolder = '/Users/annek/Library/CloudStorage/OneDrive-SharedLibraries-NIOZ/PhD Anneke Vries - General/fjord_modelling_ameralik/data/interim';
save(fullfile(saveFolder,'Ameralik_mean_daily.mat'), 'Ameralik_mean');



fig = figure(); hold on;

ntime = length(Ameralik_mean.dates);
colors = lines(ntime);
for t = 1:ntime
    plot(Ameralik_mean.rho(:,t), -Ameralik_mean.depths, 'Color', colors(t,:), 'DisplayName', string(Ameralik_mean.dates(t)));
end
legend();
grid on;

% ==============================
%       PLOTTING
% ==============================


if plot_everything
    fig_all = figure;
    tiledlayout(1,2);
    
    cmap_obs = parula(500);   % one colour per date
    
    % ==============================
    %       TEMPERATURE PROFILES
    % ==============================
    nexttile; hold on;
    
    for t = 1:length(unique_times)
        this_time = unique_times(t);
    
        % first subset by date
        idx_date = data.Date_Time == unique_times(t);
        data_Date = data(idx_date,:);
        unique_stn_date = unique(data_Date.Event);
    
    
        for s = 1:length(unique_stn_date)
    
            % now subset by station inside this date
            idx_stn = strcmp(data_Date.Event, unique_stn{s});
            if ~any(idx_stn), continue; end   % skip if no data
    
            depth = data_Date.DepthWater_m_(idx_stn);
            temp  = data_Date.Temp__C_(idx_stn);
    
            
            plot(temp, depth, 'LineWidth', 1.4, 'Color', cmap_obs(data_Date.days_since(1),:));
        end
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
        this_time = unique_times(t);
    
        % first subset by date
        idx_date = data.Date_Time == unique_times(t);
        data_Date = data(idx_date,:);
        unique_stn_date = unique(data_Date.Event);
    
    
        for s = 1:length(unique_stn_date)
    
            % now subset by station inside this date
            idx_stn = strcmp(data_Date.Event, unique_stn{s});
            if ~any(idx_stn), continue; end   % skip if no data
    
            depth = data_Date.DepthWater_m_(idx_stn);
            temp  = data_Date.Sal(idx_stn);
    
            
            plot(temp, depth, 'LineWidth', 1.4, 'Color', cmap_obs(data_Date.days_since(1),:));
        end
    end
    
    set(gca,'YDir','reverse');
    xlabel('Temperature (°C)');
    ylabel('Depth (m)');
    % title('Salinity Profiles');
    h = colorbar; colormap(gca,cmap_obs); caxis([1, size(cmap_obs,1)]);
    figName = fullfile(saveFolder, 'CTD_Ameralik_all.png');
    % saveas(fig_all, figName)


    
    
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
        plotted_stns = {}; % keep track of stations with data
        for si = 1:nStn
            if any(~isnan(T3D_Am(:,si,ti)))  % only plot if there is data
                plot(T3D_Am(:,si,ti), unique_depths, 'LineWidth', 1.5);
                plotted_stns{end+1} = stn_Am{si}; %#ok<SAGROW>
            end
        end
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
        plotted_stns = {};
        for si = 1:nStn
            if any(~isnan(S3D_Am(:,si,ti)))  % only plot if there is data
                plot(S3D_Am(:,si,ti), unique_depths, 'LineWidth', 1.5);
                plotted_stns{end+1} = stn_Am{si}; %#ok<SAGROW>
            end
        end
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







function [Data_new, times_new] = collapse_consecutive_days(Data, times, stnNames)
% COLLAPSE_CONSECUTIVE_DAYS Average consecutive days in a 3D matrix
%
% INPUTS:
%   Data        - 3D matrix (depth x stations x time)
%   times       - datetime array of length = size(Data,3)
%   stnNames    - cell array of station names (length = size(Data,2))
%   targetDepth - index of depth to check for warnings (can use depth index)
%
% OUTPUTS:
%   Data_new    - averaged 3D matrix
%   times_new   - updated datetime array

nDepth = size(Data,1);
nStn   = size(Data,2);
nTime  = length(times);

Data_new = Data;  % copy

for ti = nTime:-1:2
    % check consecutive
    if times(ti) - times(ti-1) == 1
        A = Data_new(:,:,ti-1);  % earlier day
        B = Data_new(:,:,ti);    % current day
        
        % check target depth for conflicts
        both_valid_depth = ~isnan(A(10,:)) & ~isnan(B(1,:));
        if any(both_valid_depth)
            conflictStations = stnNames(both_valid_depth);  % report station names
            warning('Both days (%s and %s) have valid data for the following station(s): %s', ...
                string(times(ti-1)), string(times(ti)), ...
                strjoin(conflictStations, ', '));
        end
        
        % average ignoring NaNs
        avgVals = mean(cat(3, A, B), 3, 'omitnan');
        
        % assign to earlier day
        Data_new(:,:,ti-1) = avgVals;
        
        % clear current day
        Data_new(:,:,ti) = NaN;
    end
end

% remove fully empty days
removeIdx = squeeze(all(all(isnan(Data_new),1),2));
Data_new(:,:,removeIdx) = [];
times_new = times;
times_new(removeIdx) = [];

end



% Assume these exist:
% depth: [Nz x 1]
% temp:  [Nz x Nprofiles]
% sal:   [Nz x Nprofiles]
% dates: [1 x Nprofiles] datetime or datenum

outdir = '/Users/annek/Library/CloudStorage/OneDrive-SharedLibraries-NIOZ/PhD Anneke Vries - General/fjord_modelling_ameralik/data/raw/AM5/';

for i = 1:length(AM5.dates)
    T = AM5.T(:,i);
    S = AM5.S(:,i);
    rho = AM5.rho(:,i);
    depth = AM5.depths(:);

    % Build table
    tbl = table(depth, T, S, rho);

    % Format filename using ISO date
    fname = sprintf('%s/profile_%s.csv', outdir, datestr(AM5.dates(i),'yyyymmdd_HHMM'));

    writetable(tbl, fname);
end

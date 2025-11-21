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

% Example: convert date/time to datetime array
time = datetime(data.Date_Time, 'InputFormat', 'yyyy-MM-dd');
t_start = datetime(2019,1,1);
days_since = datenum(time) - datenum(t_start);
data.days_since = days_since;



unique_times  = unique(data.Date_Time);
unique_stn    = unique(data.Event);

fig_all = figure;
tiledlayout(1,2);

cmap_obs = parula(365);   % one colour per date

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
title('In situ temperature Profiles');
h = colorbar; colormap(gca,cmap_obs); caxis([1,365]);


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
title('Salinity Profiles');
h = colorbar; colormap(gca,cmap_obs); caxis([1,365]);
figName = fullfile(saveFolder, 'CTD_Ameralik_all.png');
saveas(fig_all, figName)

% ---------------------------
% 1. Extract unique times, stations, and depths
% ---------------------------
unique_times  = unique(data.Date_Time);
unique_stn   = unique(data.Event);
unique_depths = unique(data.DepthWater_m_);  % 1-m spacing assumed

nd = length(unique_depths);
nt = length(unique_times);

% ---------------------------
% 2. Initialize matrices for each fjord
% ---------------------------
T3D_Am = NaN(nd, sum(contains(unique_stn,'Ameralik')), nt);  
S3D_Am = NaN(nd, sum(contains(unique_stn,'Ameralik')), nt);  

T3D_NK = NaN(nd, sum(contains(unique_stn,'God')), nt);  
S3D_NK = NaN(nd, sum(contains(unique_stn,'God')), nt);  

% ---------------------------
% 3. Separate station lists
% ---------------------------
stn_Am = unique_stn(contains(unique_stn,'Ameralik'));
stn_NK = unique_stn(contains(unique_stn,'God'));

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
    title(['Temperature - ', datestr(unique_times(ti), 'yyyy-mm-dd')]);
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
    title(['Salinity - ', datestr(unique_times(ti), 'yyyy-mm-dd')]);
    if ~isempty(plotted_stns)
        legend(plotted_stns,'Location','best');
    end
    % -----------------------------
    % Save figure
    % -----------------------------
    figName = fullfile(saveFolder, ['CTD_Ameralik_', datestr(unique_times(ti), 'yyyy-mm-dd'), '.png']);
    % saveas(fig, figName);
    close(fig);  % close figure to avoid too many open figures
end



% Initialize matrices for daily averages
nDepths = length(unique_depths);
nTime   = length(unique_times);

T_daily_mean = NaN(nDepths, nTime);
S_daily_mean = NaN(nDepths, nTime);
nProfilesperdate  = zeros(nTime);

% Loop over time steps
for ti = 1:nTime
    temp_slice = T3D_Am(:,:,ti);  % all stations at this time
    sal_slice  = S3D_Am(:,:,ti);

    % Skip if no data
    if all(isnan(temp_slice(:))) && all(isnan(sal_slice(:)))
        continue
    end

    % Mean over stations, ignoring NaNs
    T_daily_mean(:,ti) = mean(temp_slice, 2, 'omitnan');
    S_daily_mean(:,ti) = mean(sal_slice, 2, 'omitnan');

    % Count number of valid profiles per date (stations with any data)
    nProfilesperdate(ti) = sum(any(~isnan(temp_slice), 1));
end


% Condition: after October (month > 10) and before April (month < 4)
inWinter = (month(unique_times) > 10) | (month(unique_times) < 4);


% Combine into a single structure
Ameralik_mean = struct();
Ameralik_mean.T = T_daily_mean;
Ameralik_mean.S = S_daily_mean;
Ameralik_mean.depths = unique_depths;
Ameralik_mean.dates  = unique_times;
Ameralik_mean.nProfilesperdate = nProfilesperdate;
Ameralik_mean.T_init = mean(T3D_Am(:,:, inWinter),[2,3],'omitnan') ;  % average over time and stations
Ameralik_mean.S_init = mean(S3D_Am(:,:, inWinter),[2,3],'omitnan') ;  % average over time and stations



% Save the structure to a MAT-file
saveFolder = '/Users/annek/Library/CloudStorage/OneDrive-SharedLibraries-NIOZ/PhD Anneke Vries - General/fjord_modelling_ameralik/data/interim';
save(fullfile(saveFolder,'Ameralik_mean_daily.mat'), 'Ameralik_mean');


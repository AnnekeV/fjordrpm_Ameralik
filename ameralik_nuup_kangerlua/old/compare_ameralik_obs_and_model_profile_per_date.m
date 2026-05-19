% 
% load 
% % Save the structure to a MAT-file
% saveFolder = '/Users/annek/Library/CloudStorage/OneDrive-SharedLibraries-NIOZ/PhD Anneke Vries - General/fjord_modelling_ameralik/data/interim';
% save(fullfile(saveFolder,'Ameralik_mean_daily.mat'), 'Ameralik_mean');
% 
% 
% also load ameralik_combined.mat, containing s
% s.t has datenums
% 
% 
% and Ameralik mean has dates ,
% find ones closest together and compare in figure for temp and salinity 


%% Load data
load('/Users/annek/Library/CloudStorage/OneDrive-SharedLibraries-NIOZ/PhD Anneke Vries - General/fjord_modelling_ameralik/data/interim/Ameralik_AM5.mat'); 
load(    'ameralik_combined_Kb1e-04_C01e+05.mat')  % tidal

% Convert model times to datetime
model_dates = datetime(s.t,'ConvertFrom','datenum');

% Observation dates
obs_dates = Ameralik_mean.dates;

%% Find closest model date for each obs date
closest_model_idx = zeros(length(obs_dates),1);
for i = 1:length(obs_dates)
    [~, idx] = min(abs(model_dates - obs_dates(i)));
    closest_model_idx(i) = idx;
end


%%
bin_size = 10;  % in meters, change to 1, 5, 10 as needed
min_depth = min(Ameralik_mean.depths);
max_depth = max(Ameralik_mean.depths);
depth_bins = min_depth:bin_size:max_depth;
bin_centers = depth_bins(1:end-1) + bin_size/2;


% Preallocate binned matrices
T_binned = NaN(length(bin_centers), length(obs_dates));
S_binned = NaN(length(bin_centers), length(obs_dates));

for i = 1:length(obs_dates)
    % Skip if no data
    if all(isnan(Ameralik_mean.T(:,i)))
        continue
    end
    
    depths = Ameralik_mean.depths;
    T_profile = Ameralik_mean.T(:,i);
    S_profile = Ameralik_mean.S(:,i);

    for b = 1:length(bin_centers)
        idx_bin = depths >= depth_bins(b) & depths < depth_bins(b+1);
        if any(idx_bin)
            T_binned(b,i) = mean(T_profile(idx_bin), 'omitnan');
            S_binned(b,i) = mean(S_profile(idx_bin), 'omitnan');
        end
    end
end

%% Plot comparison

% Precompute limits for all plots

xlimT = [min(Ameralik_mean.T(~isnan(Ameralik_mean.T)))-1, max(Ameralik_mean.T(~isnan(Ameralik_mean.T)))];
xlimS = [min(Ameralik_mean.S(~isnan(Ameralik_mean.S))), max(Ameralik_mean.S(~isnan(Ameralik_mean.S)))+1];

for i = 1:length(obs_dates)
    % Skip if no data for this date
    if all(isnan(Ameralik_mean.T(:,i)))
        continue
    end

    fig = figure('Name',datestr(obs_dates(i)),'NumberTitle','off');
    tiledlayout(1,2);

    % Temperature
    axT = nexttile; hold(axT,'on');
    plot(axT, Ameralik_mean.T(:,i), Ameralik_mean.depths*-1, 'b','LineWidth',1.5);
    plot(axT, T_binned(:,i), bin_centers*-1, 'Color',[0.85 0.33 0.1],'LineStyle',':','LineWidth',1.5);
    plot(axT, s.T(:,closest_model_idx(i)), s.z,'r--','LineWidth',1.5);
    grid(axT,'on')
    axT.XLim = xlimT;    % ← reliable
    xlabel(axT,'Temperature (°C)');
    ylabel(axT,'Depth (m)');
    legend(axT, 'Obs','Obs binned', 'Model', Location='best')
    % title(axT, datestr(obs_dates(i)));

    % Salinity
    axS = nexttile; hold(axS,'on');
    plot(axS, Ameralik_mean.S(:,i), Ameralik_mean.depths*-1, 'b','LineWidth',1.5);
    plot(axS, S_binned(:,i), bin_centers*-1, 'Color',[0.85 0.33 0.1],'LineStyle',':','LineWidth',1.5);
    plot(axS, s.S(:,closest_model_idx(i)), s.z,'r--','LineWidth',1.5);
    grid(axS,'on')
    axS.XLim = xlimS;    % ← reliable
    xlabel(axS,'Salinity (PSU)');
    ylabel(axS,'Depth (m)');
    n_profiles = Ameralik_mean.nProfilesperdate(i); 
    % title(axS, ["N. obs = "+ n_profiles])



    % -------------------------
    % Save figure as PNG
    % -------------------------
    saveFolder = '/Users/annek/Library/CloudStorage/OneDrive-SharedLibraries-NIOZ/PhD Anneke Vries - General/fjord_modelling_ameralik/figures/comparison_obs_model';
    if ~exist(saveFolder,'dir')
        mkdir(saveFolder);
    end

    filename = fullfile(saveFolder, ['Comparison_' datestr(obs_dates(i), 'yyyymmdd') '.png']);
    % saveas(fig, filename); 

    % close(fig)

end

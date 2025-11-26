%% 
% Script to demonstrate a FjordRPM simulation of fjord response to
% synoptic shelf variability, for example shoaling and deepening of the
% pycnocline on the shelf in response to wind events. This sets up an 
% intermediary circulation in the fjord. There is no subglacial discharge 
% and there are no icebergs.

% clear workspace and close any figures to ensure clean environment
clear; close all;

% put FjordRPM code on path - need to update to the location of your code
path2sourcecode = '/Users/annek/Documents/fjordrpm/';
addpath(genpath(path2sourcecode));


% get basic constants and default controlling parameters
p = default_parameters;
p = parameters_ameralik;


p.Kb = 1e-3; % vertical mixing
p.C0 = 1e4; % shelf exchange

% set up model layers
% H_layer_deep  = 2;  % layer thickness deeper in fjord
% % a.H0 = [[1, 1, 2, 3, 5, 8 ].'; H_layer_deep*ones(((p.H-20)/10),1)];   % layer thicknesses
% p.N = 350;
% a.H0 = (p.H/p.N)*ones(p.N,1); % layer thicknesses, here taken to be equal
% Layer thicknesses
layers_1m   = ones(20,1);          % first 20 m, 1 m layers
layers_2m   = 2*ones((50-20)/2,1); % 20–50 m, 2 m layers
layers_5m   = 5*ones((110-50)/5,1); % 50–110 m, 5 m layers
layers_10m  = 10*ones((p.H-110)/10,1); % 110 m to bottom, 10 m layers
% 
% % Combine
a.H0 = [layers_1m; layers_2m; layers_5m; layers_10m];
p.N = length(a.H0); % number of layers


% set up time stepping
dt = 0.01; % time step (in days)
t_start = datenum(datetime(2018,1,1));
t_end = datenum(datetime(2019,12,31));
t = t_start:dt:t_end; % resulting time vector for simulation
p.t_save = t_start:1:t_end; % times on which to save output
nt = length(t);

% load initial profile Ameralik (first run open_previous_ctd.m)
% Save the structure to a MAT-file
saveFolder = '/Users/annek/Library/CloudStorage/OneDrive-SharedLibraries-NIOZ/PhD Anneke Vries - General/fjord_modelling_ameralik/data/interim';
load(fullfile(saveFolder,'Ameralik_mean_daily.mat'));




% read meteo data and select 2018 - 2019 
% DMI
T_temp = readtable("/Users/annek/Library/CloudStorage/OneDrive-SharedLibraries-NIOZ/PhD Anneke Vries - General/Data/Weather data/DMI/425000.csv", ...
    'Delimiter', ';', 'ReadVariableNames', true, 'VariableNamingRule', 'preserve');
T_temp.Properties.VariableNames{'Hour(utc)'} = 'Hour_utc';
T_temp.Properties.VariableNames{'101'} = 'temperature';

t_forc_date = datetime( T_temp.Year, ...
                        T_temp.Month, ...
                        T_temp.Day, ...
                        T_temp.Hour_utc, ...
                        0, 0 );
T_temp.time = t_forc_date  ;
% Define mask for 2018–2019 (anonymous function with datetime input)
mask1819 = @(time) (year(time)==2018 | year(time)==2019);
T_temp = T_temp(mask1819(T_temp.time), :);
Ta = T_temp.temperature;
f.Ta = Ta.'; % air temperature
f.tsurf = datenum(T_temp.time).'; % time vector for surface forcing


% Read CSV into table
% monthly data,
% then select appropriate times eries

T_GIC_15_19 = readtable('/Users/annek/Library/CloudStorage/OneDrive-SharedLibraries-NIOZ/PhD Anneke Vries - General/fjord_modelling_ameralik/data/processed/racmo_ameralik_gic_runoff_2015_2020.csv', 'VariableNamingRule', 'preserve');
T_GrIS_15_19 = readtable('/Users/annek/Library/CloudStorage/OneDrive-SharedLibraries-NIOZ/PhD Anneke Vries - General/fjord_modelling_ameralik/data/processed/racmo_ameralik_gris_runoff_2015_2020.csv', 'VariableNamingRule', 'preserve');
T_Tundra_15_19 = readtable('/Users/annek/Library/CloudStorage/OneDrive-SharedLibraries-NIOZ/PhD Anneke Vries - General/fjord_modelling_ameralik/data/processed/racmo_ameralik_tundra_runoff_2015_2020.csv', 'VariableNamingRule', 'preserve');

T_GIC =    T_GIC_15_19(mask1819(T_GIC_15_19.time), :); 
T_GrIS =   T_GrIS_15_19(mask1819(T_GrIS_15_19.time), :); 
T_Tundra = T_Tundra_15_19(mask1819(T_Tundra_15_19.time), :);  
runoff =  (T_GIC.runoff_m3_s + T_GrIS.runoff_m3_s + T_Tundra.runoff_m3_s);

% extend freshwater time series so can be run for a year
t_runoff = datenum(T_GIC.time(:)).'; % 1xN or Nx1 -> row later
runoff = runoff(:).';             % 1xN
t_runoff = t_runoff(:).';               % 1xN
runoff_ext = [runoff(1), runoff, runoff(end)];   % prepend first value and append last value
dt = median(diff(t_runoff)); % infer spacing for times: use median diff to be robust for nonuniform grids
t_runoff_ext = [t_runoff(1)-dt, t_runoff, t_runoff(end)+dt]; % prepend one time before first, append one after last
f.Qr = interp1(t_runoff_ext,runoff_ext,f.tsurf,'linear')  ;
f.Tr = 0*f.tsurf; % temperature of riverine input
f.Sr = 0*f.tsurf; % salinity of riverine input


% it is importatnt that t in forcing is the same length for both
% air-sea  exchange and rivers
% set up surface forcing - surface freshwater input


% set up shelf forcing
% here make it an exponential profile that shoals and deepens every 10 days
% f.ts must have dimensions 1 x nt
% f.zs must have dimensions nz x 1
% f.Ss and f.Ts must have dimensions nz x nt
% Load external profile data from a CSV file
% profiles from GF13 in 2019 (in front of sill)
folder_profiles = '/Users/annek/Library/CloudStorage/OneDrive-SharedLibraries-NIOZ/PhD Anneke Vries - General/fjord_modelling_ameralik/data/interim/CTDs/';
individual_profiles = { ...
  '20180110_HS180110',  '20180226_HS180226',  '20180312_HS180312',  '20180419_HS180419', ...
    '20180524_HS180524',  '20180619_HS180619',  '20180730_HS180730',  '20181119_HS181119', ...
    '20181128_HS181128',  '20181217_HS181217',  '20190123_HS190123',  '20190213_HS190213', ...
    '20190328_HS190328',  '20190423_HS190423',  '20190514_HS190514',  '20190521_HS190521', ...
    '20190619_HS190619',  '20190716_HS190716',  '20190819_HS190819',  '20190916_GF19131', ...
    '20190924_HS190924',  '20191022_HS191022',  '20191120_HS191120',  '20191209_HS191209' ...
};
individual_profiles = sort(individual_profiles);

% set up shelf forcing - here constant in time and depth
% for more complexity see other examples
% f.ts must have dimensions 1 x nt
% f.zs must have dimensions nz x 1
% f.Ss and f.Ts must have dimensions nz x nt

% Set up shelf forcing, and extend deepest value to below to prevent
% extrapolation of gradient, and uses same value as below
for k=1:length(individual_profiles),
    file_one_profile = fullfile(folder_profiles, [individual_profiles{k}, '.csv']);
    data = readtable(file_one_profile, 'VariableNamingRule', 'preserve'); % Adjust the filename as needed
    lastRow = data(end, :);
    
    % Copy the last row of data
    while lastRow.pressure < p.H
        lastRow.pressure = lastRow.pressure+1; % Assuming p.Hgl is the new value for pressure
        data = [data; lastRow]; % Interpolate to max fjord depth
    end
    
    depth = data.pressure'*-1; % Depth vector (negative values below surface)
    salinity = data.salinity; % Salinity profile
    temperature = data.potential_temperature; % Temperature profile
    time_CTD = datenum(datetime(data.datedatetime(1)));

    f.Ss(:,k) = salinity;
    f.Ts(:,k) = temperature;
    f.ts(k) = time_CTD;
end
% extend ts with t_end
f.ts = [t_start, f.ts, t_end+1]; % extend time vector for shelf forcing
f.Ts = [f.Ts(:,1), f.Ts, f.Ts(:,end)];
f.Ss = [f.Ss(:,1), f.Ss, f.Ss(:,end)];
f.zs = depth'; % depth vector for shelf forcing (negative below surface)


% set up subglacial discharge forcing
% in this example there is no subglacial discharge
f.tsg = t; % time vector for subglacial discharge
f.Qsg = 0*f.tsg; % subglacial discharge on tsg

% % fjord initial conditions
% % set up to be same as  average of winter profiles in Ameralik
% (nov-march)
% and extrapolate lowest value
[a.T0, a.S0] = bin_shelf_profiles(Ameralik_mean.T_init, Ameralik_mean.S_init, ...
    Ameralik_mean.depths*-1, a.H0, 'nearest');


% set up icebergs - in this example there are no icebergs
a.I0 = 0*a.H0;

% run the model
% p.plot_runtime = 1; % plot while simulation runs - fun but quite slow
s = run_model(p, t, f, a);



% save the output
% assume p.Kb and p.C0 exist
savename = sprintf('ameralik_combined_Kb%0.0e_C0%0.0e.mat', p.Kb, p.C0);
save(savename, 's', 'p', 't', 'f', 'a');



% % make an animation of the output (takes a few minutes)
savefoldervideo = '/Users/annek/Library/CloudStorage/OneDrive-SharedLibraries-NIOZ/PhD Anneke Vries - General/fjord_modelling_ameralik/figures/matlab_video_output';
% animate(p,s,200,fullfile(savefoldervideo, 'ameralik_combined_spinup_long'));




% PLOT AND SAVE FW CONTENT
titleStr = sprintf('Kb=%0.0e C0=%0.0e', p.Kb, p.C0);
load('/Users/annek/Library/CloudStorage/OneDrive-SharedLibraries-NIOZ/PhD Anneke Vries - General/fjord_modelling_ameralik/data/interim/Ameralik_mean_daily.mat'); 
depth_ranges = [0 50; 50  200];%; 200 500];
figFW = plotFWcontent(Ameralik_mean, s, 33.3, depth_ranges, titleStr);
folder_fig = '/Users/annek/Library/CloudStorage/OneDrive-SharedLibraries-NIOZ/PhD Anneke Vries - General/fjord_modelling_ameralik/figures/';
saveFolder_ts = fullfile(folder_fig, 'comparison_obs_model_timeseries');
base =  fullfile(saveFolder_ts, 'FW_content');
fname = sprintf('%s_Kb_%0.0e_C0_%0.0e_layers.png', base, p.Kb, p.C0);   % e.g. "..._Kb_1e-05.png"
print(figFW, fname, '-dpng', '-r300');
saveFigure(figFW, fname, 11, 6, 300);


% %%
% % PLOT TIMESERIES FOR T AND S AND COMPARE WITH OBS
% target_depths = [50 100 200 400];
% figT = plotCompareObsModelTimeseries(Ameralik_mean, s, target_depths, 'T', titleStr); % temeperature
% 
% 
% base = fullfile(saveFolder_ts, 'Temperature');
% savenameT = sprintf('%s_Kb_%0.0e_C0_%0.0e.png', base, p.Kb, p.C0);
% saveFigure(figT, savenameT, 9,6);
% 
% figS = plotCompareObsModelTimeseries(Ameralik_mean, s, target_depths, 'S', titleStr);  % salinity
% base =  fullfile(saveFolder_ts, 'Salinity');
% savenameS =  sprintf('%s_Kb_%0.0e_C0_%0.0e.png', base, p.Kb, p.C0);   
% saveFigure(figS, savenameS, 9,6);
% 

%%
% % make basic plots of the output
% plotrpm(p,s,25);
% 
title=  'Model Summary Ameralik Combi Initial fjord Smaller layers And Spinup';
plotrpm_no_glacier(p,s,a, 25,  title)
fname = fullfile('/Users/annek/Library/CloudStorage/OneDrive-SharedLibraries-NIOZ/PhD Anneke Vries - General/fjord_modelling_ameralik/figures/matlab_run_output', ...
   strrep(title, ' ', '_'));
% exportgraphics(gcf, [fname '.pdf'], 'ContentType', 'vector');

% 


% PLOT PROFILES FOR T AND S AND COMPARE WITH OBS
figPRO = plotCompareObsModelProfiles(Ameralik_mean, s);
base =  fullfile(folder_fig, 'comparison_obs_model_CTD_all', 'All_profiles_2019');
savenamePROFILES =  sprintf('%s_Kb_%0.0e_C0_%0.0e_layers_different.png', base, p.Kb, p.C0);   
saveFigure(figPRO, savenamePROFILES, 20, 12, 300);

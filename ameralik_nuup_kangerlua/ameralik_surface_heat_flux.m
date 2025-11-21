% Script to demonstrate a FjordRPM simulation of fjord response to
% seasonally-varying atmosphere-ocean heat flux. The shelf conditions are 
% constant in time and depth and there are no icebergs, no subglacial
% discharge and no riverine input.

% clear workspace and close any figures to ensure clean environment
clear; close all;

% put FjordRPM code on path - need to update to the location of your code
path2sourcecode = '~/OneDrive - University of Edinburgh/fjordMIX/code/fjordrpm/';
addpath(genpath(path2sourcecode));

% get basic constants and default controlling parameters
p = parameters_ameralik;
p.Kb = 1e-5; % vertical mixing

% can adjust any of the default parameters afterwards if needed
% p.C0 = 5e4; % for example adjust shelf exchange parameter
% p.run_plume_every = 10; % or update plume model only every 10 time steps



% in the case of multiple plumes, either at the same glacier or at
% different glaciers, specify vectors of grounding line depth and plume
% width. for example, 3 glaciers of grounding line depth 800, 700, 600 m
% and plume width 300, 200 and 300 m would require
% p.Hgl = [800,700,600];
% p.Wp = [300,200,300];

% set up model layers
p.N = 80; % number of layers
a.H0 = (p.H/p.N)*ones(p.N,1); % layer thicknesses, here taken to be equal



% read meteo data and select 2019 
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
T_temp =    T_temp(year(T_temp.time) == 2019, :);  % select 2019
Ta = T_temp.temperature;


% set up time stepping
t_forc = datenum(T_temp.time).';
t_start = t_forc(1);
t_end = t_forc(end);
dt = 0.2; % time step (in days)
t = t_start:dt:t_end; % resulting time vector for simulation
p.t_save = 0:1:t_end; % times on which to save output


% it is importatnt that t in forcing is the same length
% set up surface forcing - surface freshwater input
% here use idealised seasonal gaussian peaked at julian day 200
f.tsurf = t_forc; % time vector for surface forcing
f.Qr = 0*t_forc; % riverine input on ta
f.Tr = 0*t_forc; % temperature of riverine input
f.Sr = 0*t_forc; % salinity of riverine input
f.Ta = Ta.'; % air temperature

% set up shelf forcing - here constant in time and depth
% for more complexity see other examples
% f.ts must have dimensions 1 x nt
% f.zs must have dimensions nz x 1
% f.Ss and f.Ts must have dimensions nz x nt

f.ts = [0,t_end]; % time vector for shelf forcing
% import mean shelf profile from ameralik_mean_shelf_profile.mat
load('ameralik_mean_shelf_profile.mat'); % load mean shelf profile data
f.zs = meanzs; % assign shelf depth profile to f.zs
f.Ss = meanSs * ones(1,length(f.ts)); % shelf salinity on (zs,ts)
f.Ts = meanTs * ones(1,length(f.ts)); % shelf temperature on (zs,ts)


% no subglacial discharge because no marine-terminating glacier
% f.tsg must have dimensions 1 x nt
% f.Qsg must have dimensions num plumes x nt
f.tsg = t; % time vector for subglacial discharge
f.Qsg = 0*t; % subglacial discharge on tsg

% fjord initial conditions
% set up to be same as initial shelf profiles
[a.T0, a.S0] = bin_shelf_profiles(f.Ts(:,1), f.Ss(:,1), f.zs, a.H0);

% set up icebergs - in this example there are no icebergs
a.I0 = 0*a.H0;

% run the model
% p.plot_runtime = 1; % plot while simulation runs - fun but quite slow
s = run_model(p, t, f, a);

% save the output
save ameralik_surface_heat_flux.mat s p t f a

% make basic plots of the output
plotrpm(p,s,50);

% make an animation of the output (takes a few minutes)
% animate(p,s,50,'ameralik_surface_heat_flux');

plotrpm_no_glacier(p,s,a, 25)

% Save files
fname = fullfile('/Users/annek/Library/CloudStorage/OneDrive-SharedLibraries-NIOZ/PhD Anneke Vries - General/fjord_modelling_ameralik/figures/matlab_run_output', ...
    'model_summary_ameralik_surface_heat_flux');   
exportgraphics(gcf, [fname '.pdf'], 'ContentType', 'vector');




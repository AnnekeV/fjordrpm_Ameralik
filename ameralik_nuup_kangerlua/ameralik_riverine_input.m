% Script to demonstrate a FjordRPM simulation of fjord response to
% seasonally-varying riverine freshwater input (or this could also be
% precipitation). The shelf conditions are constant in time and depth and 
% there are no icebergs.

% clear workspace and close any figures to ensure clean environment
clear; close all;

% put FjordRPM code on path - need to update to the location of your code
path2sourcecode = '~/OneDrive - University of Edinburgh/fjordMIX/code/fjordrpm/';
addpath(genpath(path2sourcecode));

% get basic constants and default controlling parameters
p = parameters_ameralik;
p.Kb = 1e-4; % vertical mixing

% can adjust any of the default parameters afterwards if needed
% p.C0 = 5e4; % for example adjust shelf exchange parameter
% p.run_plume_every = 10; % or update plume model only every 10 time steps


% set up model layers
p.N = 80; % number of layers
a.H0 = (p.H/p.N)*ones(p.N,1); % layer thicknesses, here taken to be equal



% Read CSV into table
% monthly data, so 12 data points
T_GIC_15_19 = readtable('/Users/annek/Library/CloudStorage/OneDrive-SharedLibraries-NIOZ/PhD Anneke Vries - General/fjord_modelling_ameralik/data/processed/racmo_ameralik_gic_runoff_2015_2020.csv');
T_GrIS_15_19 = readtable('/Users/annek/Library/CloudStorage/OneDrive-SharedLibraries-NIOZ/PhD Anneke Vries - General/fjord_modelling_ameralik/data/processed/racmo_ameralik_gris_runoff_2015_2020.csv');
T_Tundra_15_19 = readtable('/Users/annek/Library/CloudStorage/OneDrive-SharedLibraries-NIOZ/PhD Anneke Vries - General/fjord_modelling_ameralik/data/processed/racmo_ameralik_tundra_runoff_2015_2020.csv');

T_GIC =    T_GIC_15_19(year(T_GIC_15_19.time) == 2019, :);  % select 2019
T_GrIS =   T_GrIS_15_19(year(T_GrIS_15_19.time) == 2019, :);  % select 2019
T_Tundra = T_Tundra_15_19(year(T_Tundra_15_19.time) == 2019, :);  % select 2019



% set up time stepping
dt = 0.2; % time step (in days)
% set up surface forcing - surface freshwater input
f.tsurf = datenum(T_GIC.time).';
nt = numel(f.tsurf);
assert(isequal(size(f.tsurf), [1 nt]), 'f.tsurf must be 1 x nt');
t_start = f.tsurf(1);
t_end = f.tsurf(end); % time to end the simulation (in days)
t = t_start:dt:t_end; % resulting time vector for simulation
p.t_save = 0:1:t_end; % times on which to save output

% Assign runoff column
f.Qr = (T_GIC.runoff_m3_s + T_GrIS.runoff_m3_s + T_Tundra.runoff_m3_s).'; % riverine input on ta
f.tsurf = f.tsurf;   % transpose time vector for surface forcing


f.Tr = 0*f.tsurf; % temperature of riverine input
f.Sr = 0*f.tsurf; % salinity of riverine input
f.Ta = 0*f.tsurf; % air temperature
p.kairsea = 0; % to turn off surface heat fluxes

% set up shelf forcing - here constant in time and depth
% for more complexity see other examples
% f.ts must have dimensions 1 x nt
% f.zs must have dimensions nz x 1
% f.Ss and f.Ts must have dimensions nz x nt
f.ts = f.tsurf;
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
save ameralik_riverine_input.mat s p t f a

% make basic plots of the output
plotrpm(p,s,50);

% make an animation of the output (takes a few minutes)
% animate(p,s,50,'ameralik_riverine_input');






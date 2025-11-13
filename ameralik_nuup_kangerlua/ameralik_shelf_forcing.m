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
p = parameters_ameralik;

% can adjust any of the default parameters afterwards if needed
% p.C0 = 5e4; % for example adjust shelf exchange parameter
% p.run_plume_every = 10; % or update plume model only every 10 time steps


% set up model layers
p.N = 80; % number of layers
a.H0 = (p.H/p.N)*ones(p.N,1); % layer thicknesses, here taken to be equal

% set up time stepping
dt = 0.2; % time step (in days)
t_start = 0;
t_end = 365; % time to end the simulation (in days)
t = 0:dt:t_end; % resulting time vector for simulation
p.t_save = 0:1:t_end; % times on which to save output

% set up surface forcing - surface freshwater input
% here use idealised seasonal gaussian peaked at julian day 200
f.tsurf = t; % time vector for surface forcing
f.Qr = 0*t; % riverine input on ta
f.Tr = 0*t; % temperature of riverine input
f.Sr = 0*t; % salinity of riverine input
f.Ta = -10+25*exp(-((mod(f.tsurf,365)-182)/75).^2); % air temperature
p.kairsea = 0; % to turn off surface heat fluxes


% set up shelf forcing
% here make it an exponential profile that shoals and deepens every 10 days
% f.ts must have dimensions 1 x nt
% f.zs must have dimensions nz x 1
% f.Ss and f.Ts must have dimensions nz x nt
% Load external profile data from a CSV file
% profiles from GF13 in 2019 (in front of sill)
folder_profiles = '/Users/annek/Library/CloudStorage/OneDrive-SharedLibraries-NIOZ/PhD Anneke Vries - General/fjord_modelling_ameralik/data/interim/CTDs/';
individual_profiles = {'20190123_HS190123', '20190213_HS190213', '20190328_HS190328', ...
    '20190423_HS190423', '20190514_HS190514', '20190521_HS190521', '20190619_HS190619', ...
    '20190716_HS190716', '20190819_HS190819', '20190916_GF19131', '20190924_HS190924', ...
    '20191022_HS191022', '20191120_HS191120', '20191209_HS191209'}; % make sure they are sorted
individual_profiles = sort(individual_profiles);

% set up shelf forcing - here constant in time and depth
% for more complexity see other examples
% f.ts must have dimensions 1 x nt
% f.zs must have dimensions nz x 1
% f.Ss and f.Ts must have dimensions nz x nt

% Set up shelf forcing, and extend deepest value to below to prevent
% extrapolation
for k=1:length(individual_profiles),
    file_one_profile = fullfile(folder_profiles, [individual_profiles{k}, '.csv']);
    data = readtable(file_one_profile); % Adjust the filename as needed
    lastRow = data(end, :);
    
    % Copy the last row of data
    while lastRow.pressure < p.H,
        lastRow.pressure = lastRow.pressure+1; % Assuming p.Hgl is the new value for pressure
        data = [data; lastRow]; % Interpolate to max fjord depth
    end
    
    depth = data.pressure'*-1; % Depth vector (negative values below surface)
    salinity = data.salinity; % Salinity profile
    temperature = data.potential_temperature; % Temperature profile
    time_CTD = data.timeJ(1);

    f.Ss(:,k) = salinity;
    f.Ts(:,k) = temperature;
    f.ts(k) = time_CTD;
end
% f.ts(1) =0; % see if this fixes anything (AV, 12Nov25 17:20 yes) % will need to change t

if length(individual_profiles) ==1;
    f.Ss(:,2) = salinity;
    f.Ts(:,2) = temperature;
    f.ts(2) = t_end;
end
% Set up time vector for shelf forcing


f.zs = depth'; % depth vector for shelf forcing (negative below surface)


% set up subglacial discharge forcing
% in this example there is no subglacial discharge
% f.tsg must have dimensions 1 x nt
% f.Qsg must have dimensions num plumes x nt
f.tsg = t; % time vector for subglacial discharge
f.Qsg = 0*f.tsg; % subglacial discharge on tsg

% fjord initial conditions
% set up to be same as initial shelf profiles
[a.T0, a.S0] = bin_shelf_profiles(f.Ts(:,1), f.Ss(:,1), f.zs, a.H0);

% set up icebergs - in this example there are no icebergs
a.I0 = 0*a.H0;

% run the model
% p.plot_runtime = 1; % plot while simulation runs - fun but quite slow
s = run_model(p, t, f, a);

% save the output
save example_amereralik.mat s p t f a

% make an animation of the output (takes a few minutes)
% animate(p,s,50,'example_ameralik');

% make basic plots of the output
plotrpm(p,s,30);






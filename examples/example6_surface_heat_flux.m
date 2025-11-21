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
p = default_parameters;
p.Kb = 1e-5; % vertical mixing

% set up fjord geometry
p.W = 6e3; % fjord width (m)
p.L = 60e3; % fjord length (m)
p.H = 800; % fjord depth (m)
p.sill = 1; % p.sill=1 for presence of sill, p.sill=0 for no sill
p.Hsill = 200; % sill depth below surface (m), only used if p.sill=1

% set up layer thickness - dHmin at surface and linearly increasing below
dHmin = 1;
p.N = 50;
% required increase from layer-to-layer so that sum(a.H0)=p.H when we have p.N layers
alpha = (p.H-p.N*dHmin)/(0.5*p.N*(p.N-1));
% resulting thicknesses
a.H0 = dHmin+alpha*[0:p.N-1]';

% set up time stepping
dt = 0.2; % time step (in days)
t_end = 3*365; % time to end the simulation (in days)
t = 0:dt:t_end; % resulting time vector for simulation
p.t_save = 0:1:t_end; % times on which to save output

% set up surface forcing - surface heat flux
% here use idealised seasonal gaussian air temp
f.tsurf = t; % time vector for surface forcing
f.Ta = -10+25*exp(-((mod(f.tsurf,365)-182)/75).^2); % air temperature

% set up shelf forcing - here constant in time and depth
% for more complexity see other examples
% f.ts must have dimensions 1 x nt
% f.zs must have dimensions nz x 1
% f.Ss and f.Ts must have dimensions nz x nt
f.ts = [0,t_end]; % time vector for shelf forcing
f.zs = [-p.H;0]; % depth vector for shelf forcing (negative below surface)
f.Ss = 34*ones(length(f.zs),length(f.ts)); % shelf salinity on (zs,ts)
f.Ts = 3*ones(length(f.zs),length(f.ts)); % shelf temperature on (zs,ts)

% fjord initial conditions
% set up to be same as initial shelf profiles
[a.T0, a.S0] = bin_shelf_profiles(f.Ts(:,1), f.Ss(:,1), f.zs, a.H0);

% run the model
% p.plot_runtime = 1; % plot while simulation runs - fun but quite slow
s = run_model(p, t, f, a);

% save the output
save example6_surface_heat_flux.mat s p t f a

% make an animation of the output (takes a few minutes)
animate(p,s,50,'example6_surface_heat_flux');

% make basic plots of the output
plotrpm(p,s,50);





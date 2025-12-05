% Script to demonstrate a FjordRPM simulation of fjord response to
% seasonally-varying riverine freshwater input (or this could also be
% precipitation). The shelf conditions are constant in time and depth and 
% otherwise there is no forcing (subglacial discharge, icebergs, air-sea
% heat flux).

% clear workspace and close any figures to ensure clean environment
clear; close all;

% put FjordRPM code on path - need to update to the location of your code
path2sourcecode = '~/OneDrive - University of Edinburgh/fjordMIX/code/fjordrpm/';
addpath(genpath(path2sourcecode));

% get basic constants and default controlling parameters
p = default_parameters;
p.Kb = 1e-4; % vertical mixing
p.C0 = 1e3;

% set up fjord geometry
p.W = 3e3; % fjord width (m)
p.L = 20e3; % fjord length (m)
p.H = 400; % fjord depth (m)
p.sill = 1; % p.sill=1 for presence of sill, p.sill=0 for no sill
p.Hsill = 200; % sill depth below surface (m), only used if p.sill=1


% set up glacier geometry
% (only used if there is non-zero subglacial discharge)
p.Hgl = 100; % grounding line depth (m)
p.Wp = 250; % subglacial discharge plume width (m)


% set up model layers
p.N = 80; % number of layers
a.H0 = (p.H/p.N)*ones(p.N,1); % layer thicknesses, here taken to be equal

% set up time stepping
dt = 0.1; % time step (in days)
t_end = 1*365; % time to end the simulation (in days)
t = 0:dt:t_end; % resulting time vector for simulation
p.t_save = 0:1:t_end; % times on which to save output

% set up surface forcing - surface freshwater input
% here use idealised seasonal gaussian peaked at julian day 200
f.tsurf = t; % time vector for surface forcing




f.Qr = 0*f.tsurf; % riverine input on tsurf
f.Tr = 0*f.tsurf; % temperature of riverine input
f.Sr = 0*f.tsurf; % salinity of riverine input

% set up shelf forcing - here constant in time and depth
% for more complexity see other examples
% f.ts must have dimensions 1 x nt
% f.zs must have dimensions nz x 1
% f.Ss and f.Ts must have dimensions nz x nt
f.ts = [0,t_end]; % time vector for shelf forcing
f.zs = [-p.H;0]; % depth vector for shelf forcing (negative below surface)
% f.Ss = 34*ones(length(f.zs),length(f.ts)); % shelf salinity on (zs,ts)
% f.Ts = 3*ones(length(f.zs),length(f.ts)); % shelf temperature on (zs,ts)
f.ts = t; % time vector for shelf forcing
f.zs = [-p.H:0]'; % depth vector for shelf forcing (negative below surface)
Sbottom = 33.7; % salinity at bottom
Stop = 32; % salinity at top
Tbottom = 3; % temperature at bottom
Ttop = -1; % temperature at top
zi = 25; % 'pycnocline' 
for k=1:length(f.ts),
    f.Ss(:,k) = Sbottom-(Sbottom-Stop)*exp(f.zs/zi); % shelf salinity
    f.Ts(:,k) = Tbottom-(Tbottom-Ttop)*exp(f.zs/zi); % shelf temperature
end


f.tsg = t; % time vector for subglacial discharge
f.Qsg = 600*exp(-((mod(f.tsg,365)-200)/8).^2); % subglacial discharge on tsg
total_input = mean(f.Qsg)*60*60*24*365/1e9

% fjord initial conditions
% set up to be same as initial shelf profiles
[a.T0, a.S0] = bin_shelf_profiles(f.Ts(:,1), f.Ss(:,1), f.zs, a.H0);

% run the model
% p.plot_runtime = 1; % plot while simulation runs - fun but quite slow
s = run_model(p, t, f, a);

% save the output
save example7_glof.mat s p t f a

% make an animation of the output (takes a few minutes)
% animate(p,s,50,'example5_riverine_input');

% make basic plots of the output
% plotrpm(p,s,50);

plotrpm_no_glacier(p,s,a,25,"GLOF")



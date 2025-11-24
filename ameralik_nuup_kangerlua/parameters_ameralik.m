function p = parameters_ameralik
p = default_parameters;

% DEFAULT_PARAMETERS Loads default parameters for FjordRPM.
%   p = DEFAULT_PARAMETERS sets the default box model parameters. The 
%   values can be modified afterwards for specific runs.

% set up fjord geometry
p.W = 5.5e3; % fjord width (m)
p.L = 75e3; % fjord length (m)
p.H = 700; % fjord depth (m)
p.sill = 1; % p.sill=1 for presence of sill, p.sill=0 for no sill
p.Hsill = 110; % sill depth below surface (m), only used if p.sill=1


% set up glacier geometry
% (not actually used since there is no glacier)
p.Hgl = 0; % grounding line depth (m)
p.Wp = 0; % subglacial discharge plume width (m)




% controlling parameters
p.Wp = 250;        % plume width (m)
p.C0 = 1e5;        % shelf exchange efficiency (s)
p.K0 = 5e-3;       % vertical mixing scale
p.Kb = 1e-6;       % background vertical mixing
p.Ri0 = 0.7;       % Richardson number dependency of mixing
p.M0 = 5e-7;       % iceberg melt efficiency (m s^-1 degC^-1)
p.U0 = 1;          % scale iceberg upwelling
p.kairsea = 30;    % air-sea heat flux coefficient (W m^-2 degC^-1)

% plume update frequency
p.run_plume_every = 1; % number of timesteps between plume dynamics update

% run-time plotting
p.plot_runtime = 0; % set to 1 to plot as model is solving

end
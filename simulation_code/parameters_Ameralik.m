function p = default_parameters

% DEFAULT_PARAMETERS Loads default parameters for FjordRPM.
%   p = DEFAULT_PARAMETERS sets the default box model parameters. The 
%   values can be modified afterwards for specific runs.

% physical constants - these should not be changed in general
p.g = 9.81;        % gravity (ms^-2)
p.betaS = 7.86e-4; % haline contraction (ppt^-1)
p.betaT = 3.87e-5; % thermal expansion (degC^-1)
p.l = 3.35e5;      % latent heat (J kg^-1)
p.cw = 3974;       % water heat capacity (J kg^-1 degC^-1)
p.ci = 2009;       % ice heat capacity (J kg^-1 degC^-1)
p.l1 = -5.73e-2;   % dependence of freezing point on salinity (degC ppt^-1)
p.l2 = 8.32e-2;    % freezing point offset (degC)
p.l3 = -7.61e-4;   % dependence of freezing point on depth (degC m^-1)
p.GT = 2.2e-2;     % thermal transfer coefficient (-)
p.GS = 6.2e-4;     % saline transfer coefficient (-)
p.Cd = 2.5e-3;     % drag coefficient (-)
p.Ti = -10;        % ice temperature (degC)
p.alphai = 0.1;    % iceberg plume entrainment coefficient (-)
p.alphap = 0.1;    % discharge plume entrainment coefficient (-)
p.sid = 86400;     % seconds in a day (useful to have)

% controlling parameters
p.Wp = 250;        % plume width (m)
p.C0 = 1e5;        % shelf exchange efficiency (s)
p.K0 = 5e-3;       % vertical mixing scale
p.Kb = 1e-6;       % background vertical mixing
p.Ri0 = 0.7;       % Richardson number dependency of mixing
p.M0 = 5e-7;       % iceberg melt efficiency (m s^-1 degC^-1)
p.U0 = 1;          % scale iceberg upwelling

% plume update frequency
p.run_plume_every = 1; % number of timesteps between plume dynamics update

% run-time plotting
p.plot_runtime = 0; % set to 1 to plot as model is solving

end
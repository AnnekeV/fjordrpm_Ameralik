function s = initialise_variables(p, t, f, a)

% INITIALISE_VARIABLES Initialise all model variables.
%   s = INITIALISE_VARIABLES(p, t, f, a) initialises the model variables
%   using parameters structure p, time vector t, forcing structure f and
%   initial conditions structure a, and returns solution structure s.

% set the timestep from the input time field
s.dt = t(2:end)-t(1:end-1);

%% initialise solution structure fields

% fields with dimensions p.N x 1
[s.H, s.V, s.I] = deal(zeros(p.N, 1));

% fields with dimensions p.N x length(t)
[s.T, s.S, ...
 s.QVs, s.QTs, s.QSs, s.Ts, s.Ss, s.phi, ...
 s.QVk, s.QTk, s.QSk, ...
 s.QVi, s.QTi, s.QSi, s.QMi, ...
 s.QVv, s.QTv, s.QSv, ...
 s.QVsurf, s.QTsurf, s.QSsurf] = deal(zeros(p.N, length(t)));

% fields with dimensions num plumes x p.N x length(t)
[s.QVp, s.QTp, s.QSp, s.QMp, s.QEp] = deal(zeros(length(p.Wp), p.N, length(t)));

% fields with dimensions num plumes x length(t)
s.knb = zeros(length(p.Wp), length(t));
s.Qsg = zeros(length(p.Wp), length(t));

% fields with dimensions 1 x length(t)
[s.Qr, s.Tr, s.Sr, s.Ta] = deal(zeros(1, length(t)));

%% initialise layer depths

% first deal with case where sill is so shallow or so deep that it would
% result in less than half a layer at top or bottom, by tweaking the
% sill depth itself
if p.Hsill<p.H/p.N % avoid very thin layers at top
    p.Hsill = p.H/p.N;
elseif p.Hsill>=p.H-0.5*p.H/p.N % if very deep, round to no sill
    p.Hsill = p.H; 
    p.sill = 0;
elseif p.Hsill>=p.H-p.H/p.N % avoid very thin layers at bottom
    p.Hsill = p.H-p.H/p.N;
end

% then make sill depth coincide with layer boundary
if p.sill==1
    % If there is a sill, redistribute the layers so that they are roughly
    % the same thickness above and below sill but a box boundary coincides
    % with the sill depth
    Nabove = round((p.Hsill/p.H)*p.N);
    Nbelow = p.N-Nabove;
    s.H = [(p.Hsill/Nabove)*ones(Nabove,1);...
           ((p.H-p.Hsill)/Nbelow)*ones(Nbelow,1)];
    % Store the location of the layer boundary coinciding with the sill
    s.ksill = Nabove;
else
    s.H = a.H0;
    s.ksill = p.N;
end

% resulting layer volumes
s.V = s.H*p.W*p.L;

% layer centres (useful to have at various points in the code)
layer_boundaries=[0;-cumsum(a.H0)] ;
s.z = (layer_boundaries(2:end)+layer_boundaries(1:end-1))/2;

%% model forcings

% get forcings on model layers and at model time steps
[s.Ts, s.Ss, s.Qsg, s.Qr, s.Tr, s.Sr, s.Ta] = bin_forcings(f, s.H, t);

% set any discharge values less than 1e-3 to 0, because the plume
% model struggles to deal with small values
s.Qsg(s.Qsg<1e-3) = 0;

% find layer with grounding line and store index
ints = cumsum(s.H);
for j=1:length(p.Hgl)
    s.kgl(j) = find(ints >= p.Hgl(j)-1e-6, 1);
end

% redistribute the other given initial conditions according to the new
% layer boundaries and initialise the solution variables
ints_old = [0; cumsum(a.H0)];
centres_old = 0.5*(ints_old(1:end-1)+ints_old(2:end));
ints_new = [0;cumsum(s.H)];
centres_new = 0.5*(ints_new(1:end-1)+ints_new(2:end));

s.T(:,1) = interp1(centres_old,a.T0,centres_new,'linear','extrap');
s.S(:,1) = interp1(centres_old,a.S0,centres_new,'linear','extrap');
s.I = interp1(centres_old,a.I0,centres_new,'linear','extrap');

end
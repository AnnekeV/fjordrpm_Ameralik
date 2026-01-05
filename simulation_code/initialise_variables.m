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
 s.QVc, s.QTc, s.QSc, ...
 s.QVsurf, s.QTsurf, s.QSsurf] = deal(zeros(p.N, length(t)));

% fields with dimensions num plumes x p.N x length(t)
[s.QVp, s.QTp, s.QSp, s.QMp, s.QEp] = deal(zeros(length(p.Wp), p.N, length(t)));

% fields with dimensions num plumes x length(t)
s.knb = zeros(length(p.Wp), length(t));
s.Qsg = zeros(length(p.Wp), length(t));

% fields with dimensions 1 x length(t)
[s.Qr, s.Tr, s.Sr, s.Ta] = deal(zeros(1, length(t)));

%% initialise layer depths

% in case with no sill the layer thicknesses are unmodified and
% s.ksill=p.N so that all layers exchange with shelf
if p.sill==0 
    s.H = a.H0;
    s.ksill = p.N;
% in case with sill, we want the sill depth to coincide with a layer
% boundary, so some adjustment may be required
elseif p.sill==1
    % layers above sill
    inds_above = find(cumsum(a.H0)<=p.Hsill);
    if length(inds_above)<2
        error('Must have at least two layers above sill depth');
    end
    if abs(sum(a.H0(inds_above))-p.Hsill) > 1e-10
        disp('N.B. Adjusting layer thicknesses to coincide with sill depth');
    end   
    s.H(inds_above) = a.H0(inds_above)*p.Hsill/sum(a.H0(inds_above));
    % layers below sill
    inds_below = find(cumsum(a.H0)>p.Hsill); 
    s.H(inds_below) = a.H0(inds_below)*(p.H-p.Hsill)/sum(a.H0(inds_below));
    s.ksill = inds_above(end);
end

% resulting layer volumes
s.V = s.H*p.W*p.L;

% layer centres (useful to have at various points in the code)

ints = -[0;cumsum(s.H)];
s.z = 0.5*(ints(1:end-1)+ints(2:end));

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
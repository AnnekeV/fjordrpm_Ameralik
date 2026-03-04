function s = step_solution_forwards(i, p, s)

% STEP_SOLUTION_FOWARDS Does an Euler forward timestep of T and S.
%   s = STEP_SOLUTION_FORWARDS(i, p, s) performs an Euler step for the
%   simulation for parameters structure p and solution s at time step i.

% compute the FjordRPM tracer variables at timestep i+1
% note the plume fluxes are summed over the number of plumes
s.T(:,i+1) = s.T(:,i)+s.dt(i)*p.sid*(sum(s.QTp(:,:,i),1)'+s.QTs(:,i)+s.QTk(:,i)+s.QTi(:,i)+s.QTv(:,i)+s.QTsurf(:,i))./s.V;
s.S(:,i+1) = s.S(:,i)+s.dt(i)*p.sid*(sum(s.QSp(:,:,i),1)'+s.QSs(:,i)+s.QSk(:,i)+s.QSi(:,i)+s.QSv(:,i)+s.QSsurf(:,i))./s.V;

% Create a copy of QSs that only keeps negative values (sink to shelf)
QSs_neg = s.QSs(:,i);
QSs_neg(QSs_neg >= 0) = 0;  % set all non-negative entries to 0

% Update tracer flux proportional to salinity flux
% with sink for shelf and source river VOLUME
% QSs (shelf) QSv (vertical flux) Qsk (vertical mixing)
s.Tracer(:,i+1) = s.Tracer(:,i) + s.dt(i)*p.sid*s.QVsurf(:,i)./s.V + s.dt(i)*p.sid*(QSs_neg+s.QSk(:,i)+s.QSv(:,i)).*s.Tracer(:,i)./s.S(:,i)./s.V; 


% check for temperatures going below in-situ freezing point and reset to
% in-situ freezing point. at the moment this is a quick fix - in reality 
% this should result in sea ice formation but this is not yet implemented
Tfreeze = p.l1*s.S(:,i+1) + p.l2 + p.l3*abs(s.z);
inds = find(s.T(:,i+1)<Tfreeze);
s.T(inds,i+1) = Tfreeze(inds);

end
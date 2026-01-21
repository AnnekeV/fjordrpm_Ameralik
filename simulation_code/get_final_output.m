function s = get_final_output(p, t, s, status)

% GET_FINAL_OUTPUT Get the output of the simulation.
%   s = GET_FINAL_OUTPUT(p, t, s, status) gets the model output for
%   input parameters p, time vector t and solution structure s, and 
%   returns solution structure s on timestepping specified by the user.

% compute fluxes one last time to get same number of values as for tracers
s = compute_fluxes(size(s.T,2), p, s);

% save values to output file as specified by the input parameter, unless
% (a) something went wrong, because we want all time steps to properly understand
% what happened, or (b) we did not specify particular time steps for saving
if status == 1 || ~isfield(p,'t_save')
    p.t_save = t;
end

% get the indices of the timesteps to save at
inx = find(ismember(t, p.t_save));

% time vector
s.t = t(inx);

% layer properties
s.T = s.T(:,inx);
s.S = s.S(:,inx);
s.Tracer = s.Tracer(:,inx);

% plume fluxes
s.QVp = s.QVp(:,:,inx);
s.QTp = s.QTp(:,:,inx);
s.QSp = s.QSp(:,:,inx);
s.QMp = s.QMp(:,:,inx);
s.QEp = s.QEp(:,:,inx);
s.knb = s.knb(inx);
% calculate plume melt rate in m/d
for j=1:length(p.Wp)
    s.mp(j,:,:) = p.sid*squeeze(s.QMp(j,:,:))./(p.Wp(j)*s.H);
end

% shelf fluxes
s.QVs = s.QVs(:,inx);
s.QTs = s.QTs(:,inx);
s.QSs = s.QSs(:,inx);
s.Ss = s.Ss(:,inx);
s.Ts = s.Ts(:,inx);
s.phi = s.phi(:,inx);

% vertical mixing
s.QVk = s.QVk(:,inx);
s.QTk = s.QTk(:,inx);
s.QSk = s.QSk(:,inx);

% vertical fluxes
s.QVv = s.QVv(:,inx);
s.QTv = s.QTv(:,inx);
s.QSv = s.QSv(:,inx);

% convection fluxes
s.QVc = s.QVc(:,inx);
s.QTc = s.QTc(:,inx);
s.QSc = s.QSc(:,inx);

% surface fluxes
s.QVsurf = s.QVsurf(:,inx);
s.QTsurf = s.QTsurf(:,inx);
s.QSsurf = s.QSsurf(:,inx);

% iceberg fluxes and melt rates
s.QVi = s.QVi(:,inx);
s.QTi = s.QTi(:,inx);
s.QSi = s.QSi(:,inx);
s.QMi = s.QMi(:,inx);
% calculate iceberg melt rates in m/d
s.mi = p.sid*s.QMi./s.I;
s.mi(s.I==0,:) = 0;

% subglacial discharge
s.Qsg = s.Qsg(:,inx);

% riverine input
s.Qr = s.Qr(inx);
s.Tr = s.Tr(inx);
s.Sr = s.Sr(inx);

% air temperature
s.Ta = s.Ta(inx);

% error status
s.status = status;

end

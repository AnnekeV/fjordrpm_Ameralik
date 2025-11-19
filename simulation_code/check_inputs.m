function status = check_inputs(p, t, f, a)

% CHECK_INPUTS Check for errors in model inputs.
%   status = CHECK_INPUTS(p, t, f, a) checks the model inputs.

status = 0;

% check provided depths are positive
if any([p.Hsill<0, p.Hgl<0, p.H<0])
    error('p.H, p.Hgl and p.Hsill must be positive');
end

% check dimensionality of initial conditions
if ~isequal([size(a.H0)],[size(a.S0)],[size(a.T0)],[size(a.I0)],[p.N,1])
    error('Initial conditions (a.H0, a.S0, a.T0, a.I0) must have dimensions p.N x 1');
end

% check sum of layer thicknesses is equal to fjord depth
if abs(sum(a.H0)-p.H) > 1e-10
    error('Layer thicknesses (a.H0) must sum to fjord depth (p.H)');
end

% check dimensionality of shelf forcing
nz = length(f.zs);
nt = length(f.ts);
disp(['nt =  ' num2str(nt)])

% f.ts
if ~isequal(size(f.ts),[1,nt])
    error('f.ts must have dimensions 1 x nt');
end
% f.zs
if ~isequal(size(f.zs),[nz,1])
    error('f.zs must have dimensions nz x 1');
end
% f.Ss and f.Ts
if ~isequal(size(f.Ss),size(f.Ts),[nz,nt])
    error('f.Ss and f.Ts must have dimensions length(f.zs) x length(f.ts)');
end

% check dimensionality of subglacial discharge forcing
nt = length(f.tsg);
% f.tsg
if ~isequal(size(f.tsg),[1,nt])
    error('f.tsg must have dimensions 1 x nt');
end
% f.Qsg
if ~isequal(size(f.Qsg,2),nt)
    error('Second dimension of f.Qsg must have length nt');
end
% number of plumes
if ~isequal(size(f.Qsg,1),length(p.Wp),length(p.Hgl))
    error('Check num plumes=size(f.Qsg,1)=length(p.Wp)=length(p.Hgl)');
end

% check dimensionality of surface forcing
nt = length(f.tsurf);
% f.tsurf
if ~isequal(size(f.tsurf),[1,nt])
    error('f.tsurf must have dimensions 1 x nt');
end
% f.Qr
if ~isequal(size(f.Qr,2),nt)
    error('Second dimension of f.Qr must have length nt');
end
% f.Tr
if ~isequal(size(f.Tr,2),nt)
    error('Second dimension of f.Tr must have length nt');
end
% f.Sr
if ~isequal(size(f.Sr,2),nt)
    error('Second dimension of f.Sr must have length nt');
end
% f.Ta
if ~isequal(size(f.Ta,2),nt)
    error('Second dimension of f.Ta must have length nt');
end

end


function [p, t, f, a] = check_inputs(p, t, f, a)

% CHECK_INPUTS Check for errors in model inputs.
%   f = CHECK_INPUTS(p, t, f, a) checks the model inputs, ensuring the
%   correct dimensionality and ensuring we have all the required fields,
%   setting to 0 any that are not provided (subglacial discharge, icebergs
%   surface forcing).

%%%%%%%%
% check geometry
% check provided depths are positive
if isfield(p,"Hgl")
    if p.Hgl<0
        error('p.Hgl must be positive');
    end
end
if p.sill && ~isfield(p,"Hsill")
    error('When p.sill=1, must specify sill depth p.Hsill')
end
if p.sill && isfield(p,"Hsill")
    if p.Hsill<0
        error('p.Hsill must be positive');
    end
    if p.Hsill==p.H
        error('When p.sill=1, p.Hsill must differ from p.H')
    end
end
if p.H<0
    error('p.H must be positive');
end
% check sum of layer thicknesses is equal to fjord depth
if abs(sum(a.H0)-p.H) > 1e-10
    error('Layer thicknesses (a.H0) must sum to fjord depth (p.H)');
end

%%%%%%%%
% check initial conditions
if ~isfield(a,"S0") || ~isfield(a,"T0") || ~isfield(a,"H0")
    error('Must specify initial conditions a.T0 and a.S0, and layer thicknesses a.H0');
end
% check dimensionality of initial conditions
if ~isequal([size(a.H0)],[size(a.S0)],[size(a.T0)],[p.N,1])
    error('Initial conditions (a.H0, a.S0, a.T0) must have dimensions p.N x 1');
end

%%%%%%%%
% check icebergs
% set icebergs to 0 if not specified
if ~isfield(a,"I0")
    a.I0 = 0*a.H0;
    disp('Iceberg concentration (a.I0) not specified: setting to 0.')
end
% check dimensionality
if ~isequal([size(a.I0)],[p.N,1])
    error('Iceberg concentration a.I0 must have dimensions p.N x 1');
end

%%%%%%%%
% check shelf forcing
if ~isfield(f,"zs") || ~isfield(f,"ts") || ~isfield(f,"Ts") || ~isfield(f,"Ss")
    error('Must specify shelf forcing variables f.ts, f.zs, f.Ts and f.Ss');
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

%%%%%%%%
% check subglacial discharge forcing
% set to 0 if it has not been specified
if ~isfield(f,"tsg") || ~isfield(f,"Qsg") || ~isfield(p,'Wp') || ~isfield(p,'Hgl')
    f.tsg = t;
    f.Qsg = 0*t;
    p.Wp = 0;
    p.Hgl = 0;
    disp('Subglacial discharge (f.tsg, f.Qsg, p.Hgl, p.Wp) not fully specified: setting to 0.')
end
% then check dimensionality
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

%%%%%%%%
% check surface freshwater forcing
% set inputs to 0 if they have not been specified
if ~isfield(f,"tsurf")
    f.tsurf = [t(1),t(end)];
end
% riverine inputs
if ~isfield(f,"Qr")
    f.Qr = 0*f.tsurf;
    disp('Riverine input flux (f.Qr) not specified: setting to 0.')
end
if ~isfield(f,"Tr")
    f.Tr = 0*f.tsurf;
    disp('Temperature of riverine input (f.Tr) not specified: setting to 0.')
end
if ~isfield(f,"Sr")
    f.Sr = 0*f.tsurf;
    disp('Salinity of riverine input (f.Sr) not specified: setting to 0.')
end
% air-sea heat flux
if ~isfield(f,"Ta")
    f.Ta = 0*f.tsurf;
    p.kairsea = 0;
    disp('Air temp (f.Ta) not specified: setting air-sea heat flux to 0.')
end
% then check dimensionality
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


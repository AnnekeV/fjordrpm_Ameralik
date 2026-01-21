function s = homogenise_unstable_layers(i, p, s)

% HOMOGENISE_UNSTABLE_LAYERS Homogenise two unstably stratified layers.
%   s = HOMOGENISE_UNSTABLE_LAYERS(i, p, s) takes input timestep i,
%   parameters structure p, and solution structure s and computes the
%   buoyancy jump between layers in the solution for that timestep,
%   homogenises any layers that are unstably stratified and returns an
%   updated solution structure s.

% required variables
V = s.V;
T = s.T(:,i);
S = s.S(:,i);
Tracer = s.Tracer(:,i);

% compute the buoyancy jump between boxes
B = p.g*(p.betaS*(S(2:end)-S(1:end-1))-p.betaT*(T(2:end)-T(1:end-1)));

if any(B < 0)
    % find the indices of negative buoyancy entries
    inx = find(B < 0);
    % homogenise any two such layers
    for k = 1:length(inx)
        inds = [inx(k), inx(k)+1];
        T(inds) = sum(T(inds).*V(inds))./sum(V(inds));
        S(inds) = sum(S(inds).*V(inds))./sum(V(inds));
        Tracer(inds) = sum(Tracer(inds).*V(inds))./sum(V(inds));
        % store associated fluxes
        s.QTc(inds,i) = V(inds).*(T(inds)-s.T(inds,i))/(s.dt(i)*p.sid);
        s.QSc(inds,i) = V(inds).*(S(inds)-s.S(inds,i))/(s.dt(i)*p.sid);
    end
end

% put homogenised solution into output stucture
s.T(:,i) = T;
s.S(:,i) = S;
s.Tracer(:,i) = Tracer;

end


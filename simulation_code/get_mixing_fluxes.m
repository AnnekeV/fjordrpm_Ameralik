function [QVk0,QTk0,QSk0,Ri] = get_mixing_fluxes(i, p, s)

% GET_MIXING_FLUXES Compute vertical tracer mixing fluxes.
%   [QVK0, QTK0, QSK0] = GET_MIXING_FLUXES(i, p, s) computes the
%   vertical mixing fluxes QVK0, QTK0, QSSK0 for the given parameters p
%   and solution s at timestep i.

% required variables at timestep i
H0 = s.H;
T0 = s.T(:,i);
S0 = s.S(:,i);

% the net volume mixing fluxes are always zero
QVk0 = 0*H0;

% reduced gravity between layers
gp = p.g*(p.betaS*(S0(2:end)-S0(1:end-1))-p.betaT*(T0(2:end)-T0(1:end-1)));

% horizontal velocity of layers
if size(s.QVp,1)==1
    u = (s.QVp(:,:,i)'-s.QVs(:,i))./(2*p.W*H0);
else
    u = (sum(s.QVp(:,:,i))'-s.QVs(:,i))./(2*p.W*H0);
end

% richardson number (old no tidal shear)
du = u(2:end)-u(1:end-1);
Ri = gp.*(H0(2:end)+H0(1:end-1))./(2*du.^2);  % no tidal mixing


% % add tidal mixing parameterization (Vries& Slater)
% % u_tide = p.u_tide_max/2 + p.u_tide_max/2 .* sin(omega .* s.t(i) + p.phi);  % at timestep i
% u_tide = p.u_tide_max;
% du_tide = u_tide * double(abs(s.z) < p.dz_distribution_scale); % only above sill depth or other relevant length scale
% du_tide = u_tide * ones(size(s.z));
% dudz_tide = du_tide./p.dz_tide;
% 

% % richardson number (when including tide)
% dh = H0(2:end)+H0(1:end-1);
% dudz2 = (2*du./dh + dudz_tide(1:end-1)).^2;
% Ri = 2.*gp./dh./(dudz2);

% KPP scheme
Ri(du==0) = p.Ri0;
Ri(Ri>p.Ri0) = p.Ri0;
Ri(Ri<0) = 0;

% get diffusivity as a function of the Richardson number
Kz = p.Kb + (Ri<p.Ri0 & Ri>=0)*p.K0.*(1-(Ri/p.Ri0).^2).^3;



% compute the mixing fluxes going in/out of each layer.
QS = 2*p.W*p.L*Kz.*(S0(2:end)-S0(1:end-1))./(H0(2:end)+H0(1:end-1));
QT = 2*p.W*p.L*Kz.*(T0(2:end)-T0(1:end-1))./(H0(2:end)+H0(1:end-1));

% the final layer fluxes are the net of the interface fluxes
QTk0 = [QT;0]-[0;QT];
QSk0 = [QS;0]-[0;QS];


Ri = [Ri; Ri(end)];  % now length n

end
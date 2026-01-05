T = (12 + 25/60)*60*60; % tidal period (s)
A = 2 ; % Amplitude of water level (m)
rho1 = 1026.5 ; % kg/m3
rho2 = 1026.6 ; % kg/m3
B = 3500 ; % m width of channel 
H0 =  110 ; % m thickness  of upper layer
h0 =  700-110 ; % m thickness  of lower layer
Y_i = 3500*80e3 ; % surface area inside the sill
c_i = 2; % wave phase speed TBD


epsilon_i = (2*pi^2*rho1*Y_i^2/(B*(H0 + h0)^2)) ...
            * (h0^2/H0 + h0) * c_i * (A/T)^2;


V_below_sill = h0*Y_i; % m3 volume below sill 
N2  =   1.6134e-05; % brunt vaisala feqency

Kz = 0.05*epsilon_i/ (V_below_sill*N2)

g = 9.81;
rho0 = 1025;

% z must be positive upward (e.g. z = -depth)
drho_dz = gradient(s.rho(:,1), s.z);

N2 = -(g/rho0) * drho_dz;
N  = sqrt(N2);
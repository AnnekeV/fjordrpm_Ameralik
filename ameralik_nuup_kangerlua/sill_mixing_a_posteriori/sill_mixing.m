close all; clear;

%% load
load ../ameralik_nuup_kangerlua/ameralik_combined_Kb1e-04_C01e+05.mat
s.t_date = datetime(s.t, "ConvertFrom","datenum");

T = (12 + 25/60)*60*60; % tidal period (s) 12 hour 25 minutes M2 tide
A = 1 ; % Amplitude of water level  due to tides (m)
% rho1 = 1026.5 ; % kg/m3
% rho2 = 1026.6 ; % kg/m3
B = p.W ; % m width of channel s.rho
H0 =  p.Hsill; % p.Hsill ; % m thickness  of upper layer water depth of sil
h0 =  p.H-H0 ; % m height of sill
Y_i = p.W*p.L  ; % surface area inside the sill
V_below_sill = h0*Y_i ; % m3 volume below sill 


%%


% Parameters
T = (12 + 25/60)*60*60;   % tidal period (s), M2 tide
A = 1;                   % tidal amplitude (m)

% Range of H0 (upper layer depth over sill)
H0 = linspace(1,700,500);   % m


% Derived quantities
h0 = p.H - H0;              % depth below sill (m) (sill height)

A_upstream = p.W* p.L;
Xarea_sill = H0 *p.W;


% Velocity over sill
u_sill = (2*pi .* A_upstream .* A) ./ (Xarea_sill .* T);


% Plot
figure
plot(H0, u_sill, 'LineWidth', 2)
grid on
xlabel('H_0 (m)')
ylabel('u_{sill} (m s^{-1})')
title('Sill Velocity as a Function of Upper-Layer Depth')

%%

g = 9.81;
rho0 = 1025;


below_layer = find(abs(s.z) >= H0);
above_layer = find(abs(s.z) < H0);
around_sill =  find(abs(s.z) > (p.Hsill - 50) & abs(s.z) < (p.Hsill +50)) ;

% Calcuate mean density of upper layer and lower layer
rho1 = (mean(s.rho(above_layer, :)));
rho2 = (mean(s.rho(below_layer, :)));
% 
% % Oslofjord from stigebrandt for comparison
% rho1 = 1e3;
% rho2 = rho1 + 5;
% h0 = 65;
% H0 = 15;
% Y_i = 2e8;
% B = 600;
% A = 0.15;



g_prime = g*(rho2 -rho1)/rho2;

c_bt = sqrt(g*p.H);  % barotropic  (surface)
c_i = sqrt((g_prime*h0*H0/(h0+H0)));  % baroclinic internal wave speed

epsilon_i = (2*pi^2*rho1*Y_i^2/(B*(H0 + h0)^2)) ...
            * (h0^2/H0 + h0) * c_i * (A/T)^2;





% z must be positive upward (e.g. z = -depth)
[nRows, nCols] = size(s.rho);
drho_dz = zeros(nRows, nCols);  

for k = 1:nCols
    drho_dz(:, k) = gradient(s.rho(:, k), s.z);
end

drho_dz = -(rho2 -rho1)./H0;
N2 = -(g/rho0) * drho_dz;

% Make sure N > 0
for k = 1:nCols
    if any(N2(:, k) < - 1e-4)   
        N2(:,k) = NaN;
    end
end

N  = sqrt(N2);

% N2_mean = mean(N2(below_sill, :)); % if you calculate a N2 profile
N2_mean = N2;

eff_mix = 0.05; % 5% for wave 1% for jet
Kz = eff_mix*epsilon_i ./ (V_below_sill*N2_mean)/7;

figure;
plot(s.t_date, Kz, 'LineWidth', 2)
xlabel('Time')
ylabel('K_z')
title('Turbulent Diffusivity vs Time')
% set(gca, 'YScale', 'log')   % LOG scale for y-axis
grid on
%save the figure
% Save the computed Kz and N2_mean to a .mat file for further analysis
saveas(gcf, 'mixing_Kz_over_time.png')


figure;
plot(s.t_date, N2_mean);
title("N2 mean")
saveas(gcf, 'mixing_N2_over_time.png')

figure;
plot(s.t_date, epsilon_i);
title("Energy transport from barotropic to baroclinic")
saveas(gcf, 'mixing_epsilon_over_time.png')

%% 2️⃣ Plot Density vs depth
figure;
plot(s.rho, s.z, 'LineWidth', 2)
xlabel('Rho')
ylabel('Depth (z)')
title('Density Profile')
grid on

saveas(gcf, 'mixing_rho_with_depth.png')



% %% 2️⃣ Plot N^2 vs depth
% figure;
% plot(N2, s.z, 'LineWidth', 2)
% xlabel('N^2')
% ylabel('Depth (z)')
% title('Stratification Profile')
% grid on
% 
% saveas(gcf, 'mixing_N2_with_depth.png')
% 

%%




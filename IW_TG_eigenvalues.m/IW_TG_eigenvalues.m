% compute as many vertical modes as there are points in the vertical 
% in the given Brunt Vaisala (N2) distribution
% by solving the eigenvalue problem of discretised 
% TG equation d^2 W/dz^2 + 1/(c2*N2)W = 0
% with boundary condition : W(z=0)=0 and W(z=-H) = 0
% the discrete equation is written : M W = ic2 W
% ic2 is a diagonal matrix of eigenvalues, i.e. 1/phase speed squared
% W is a matrix containing the eigenvectors, i.e. the modal structure
% of vertical velocity
% distribution discretisation along vertical must be regular ie dz=constant
% the surface must be a distance dz above n = 1, and the bottom must be a
% distance dz below n = N

% Mark Inall, jan 2026

%% house keeping
clc 
close all
clear
set(0,'defaultaxesfontsize',16);
set(0,'defaulttextfontsize',16);


%% load
load ../ameralik_nuup_kangerlua/ameralik_combined_Kb1e-04_C01e+05.mat
s.t_date = datetime(s.t, "ConvertFrom","datenum");

g = 9.81;
rho0 = 1025;

% z must be positive upward (e.g. z = -depth)
[nRows, nCols] = size(s.rho);
drho_dz = zeros(nRows, nCols);  

for k = 1:nCols
    drho_dz(:, k) = gradient(s.rho(:, k), s.z);
end

N2 = -(g/rho0) * drho_dz;

% % Make sure N > 0
% for k = 1:nCols
%     if any(N2(:, k) < - 1e-6)   
%         N2(:,k) = NaN;
%     end
% end
N2_Am = N2;


%% examples with constant N2(z) and a made up N2(z) profile
H=-100; % seabed, bottom
dz=-2; % vertical interval for modal solution
z = 0:dz:H; % z negative downwards, including surface and bottom. 
% Only need to solve for vertical velocity from z(2) to z(end-1), since W=0
% at z=0 and z=H.

% again, only specify N2 from z(2) to z(end-1), that's were we are solving for W
% N2 = 4e-5*ones(1,length(z)-2); % constant N2
N2_example = [1e-5 1e-5 8e-5 2e-5 1e-5];
z_example = [-2 -10 -20 -30 -98];
N2_ex = interp1(z_example,N2_example,z(2:end-1),"pchip"); % mid-depth peak


% if you (don't) want a real profile comment
N2_Am = N2_Am(:,1);
z = s.z;
% z=0:-2:-p.H;
% N2_Am = interp1(s.z,  N2_Am, z);
N2 = N2_Am(2:end-1);


% N2 = N2_ex; % comment out for const N2 profile


n=length(N2); % size of matrix for modal solution
% note n goes from one point below the surface to one point above the
% bottom, because we know boundary conditions of W=0 at z=0 and z=-H

%% fill matrix M 
M=zeros(n); % initialise with zeros
% interior term not effected by boundary conditions
for i=2:n-1
    M(i,i-1) = -1/(dz^2*N2(i));
    M(i,i) = 2/(dz^2*N2(i));
    M(i,i+1) = -1/(dz^2*N2(i));
end
% first line modified by W=0 at surface
M(1,1)=2/(dz^2*N2(1));
M(1,2)=-1/(dz^2*N2(1));
% last line modified by W=0 at seabed
M(n,n-1)=-1/(dz^2*N2(n));
M(n,n)=2/(dz^2*N2(n));
%% seek the eigenvalues and associated eigenvectors of M
[W,ic2]=eig(M);

c = diag(sqrt(1./ic2)); % inverse squared phase speeds of all modes are on the diagonal
% have to sort them by speed, not always largest first
% mode 1 is the fastest mode, etc
[c_sorted,idx] = sort(c,1,"descend");
% manual extract of modes 1,2 and 3
c1 = c_sorted(1); c2 = c_sorted(2); c3 = c_sorted(3);
W1 = [0; W(:,idx(1)); 0]./max(abs(W(:,idx(1)))); % top and tail and normalise
W2 = [0; W(:,idx(2)); 0]./max(abs(W(:,idx(2)))); % top and tail and normalise
W3 = [0; W(:,idx(3)); 0]./max(abs(W(:,idx(3)))); % top and tail and normalise

ind_mix = find(abs(W1) == max(abs(W1)));

depth_mode_1_zero_crossing = z(ind_mix); 


%% take a look
figure
tiledlayout(1,2)
ax1=nexttile;
plot(ax1,N2,z(2:end-1),'LineWidth',3)
%xlim(ax1,[0 1e-4])
ylabel(ax1,'depth (m)')
xlabel(ax1,'N^2 s^{-1}')
grid(ax1,"on")

ax2=nexttile;
plot(ax2,W1,z,W2,z,W3,z,'LineWidth',3)
legend(ax2,...
    ['C_1 = ', num2str(c1,2),' ms^{-1}'],...
    ['C_2 = ', num2str(c2,2),' ms^{-1}'],...
    ['C_3 = ', num2str(c3,2),' ms^{-1}'])
grid(ax2,"on")
xlabel(ax2,'vertical vel, normalised')

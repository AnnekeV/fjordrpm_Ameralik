function plotrpm(p, s, nplot)

% PLOTRPM makes summary plots after the model has run.
%   PLOTRPM(p, s, nplot) makes example plots of temperature, salinity,
%   fluxes and melt rates to show the sort of thing that can be done.
%   Inputs are the parameters structure p, solution structure s and nplot
%   is the number of time snapshots to plot.

% set interpreters to ensure labels show up as expected
set(groot,'DefaultTextInterpreter','tex');
set(groot,'DefaultAxesTickLabelInterpreter','tex');
set(groot,'DefaultLegendInterpreter','tex');
set(groot,'DefaultColorbarTickLabelInterpreter','tex');

% time indices to plot
ip = [1:max(1,round(length(s.t)/nplot)):length(s.t)];

% colourmaps
cmapt = parula(length(ip));
cmapz = parula(length(s.z));

% line width
lw = 2;

%% temperature
figure();

tcl = tiledlayout(2,2);
title(tcl,'TEMPERATURES');

% fjord profiles
nexttile; hold on;
for i=1:length(ip)
    plot(s.T(:,ip(i)),s.z,'color',cmapt(i,:),'linewidth',lw);
end
xlabel(['temperature (',char(176),'C)']); ylabel('depth (m)');
h = colorbar; colormap(gca,cmapt); caxis([min(s.t),max(s.t)]);
ylabel(h,'time (days)'); ylim([-p.H,0]);
set(gca,'box','on'); grid on; title('FJORD');

% fjord time series
nexttile; hold on;
for i=1:length(s.z)
    plot(s.t,s.T(i,:),'color',cmapz(length(s.z)-i+1,:),'linewidth',lw);
end
xlabel('time (days)'); ylabel(['temperature (',char(176),'C)']);
h = colorbar; colormap(gca,cmapz); caxis([-p.H,0]);
ylabel(h,'depth (m)');
set(gca,'box','on'); grid on; title('FJORD');

% shelf profiles
nexttile; hold on;
for i=1:length(ip)
    plot(s.Ts(:,ip(i)),s.z,'color',cmapt(i,:),'linewidth',lw);
end
xlabel(['temperature (',char(176),'C)']); ylabel('depth (m)');
h = colorbar; colormap(gca,cmapt); caxis([min(s.t),max(s.t)]);
ylabel(h,'time (days)'); ylim([-p.H,0]);
set(gca,'box','on'); grid on; title('SHELF');

% shelf time series
nexttile; hold on;
for i=1:length(s.z)
    plot(s.t,s.Ts(i,:),'color',cmapz(length(s.z)-i+1,:),'linewidth',lw);
end
xlabel('time (days)'); ylabel(['temperature (',char(176),'C)']);
h = colorbar; colormap(gca,cmapz); caxis([-p.H,0]);
ylabel(h,'depth (m)');
set(gca,'box','on'); grid on; title('SHELF');

%% salinity
figure();

tcl = tiledlayout(2,2);
title(tcl,'SALINITIES');

% fjord profiles
nexttile; hold on;
for i=1:length(ip)
    plot(s.S(:,ip(i)),s.z,'color',cmapt(i,:),'linewidth',lw);
end
xlabel('salinity'); ylabel('depth (m)');
h = colorbar; colormap(gca,cmapt); caxis([min(s.t),max(s.t)]);
ylabel(h,'time (days)'); ylim([-p.H,0]);
set(gca,'box','on'); grid on; title('FJORD');

% fjord time series
nexttile; hold on;
for i=1:length(s.z)
    plot(s.t,s.S(i,:),'color',cmapz(length(s.z)-i+1,:),'linewidth',lw);
end
xlabel('time (days)'); ylabel('salinity');
h = colorbar; colormap(gca,cmapz); caxis([-p.H,0]);
ylabel(h,'depth (m)');
set(gca,'box','on'); grid on; title('FJORD');

% shelf profiles
nexttile; hold on;
for i=1:length(ip)
    plot(s.Ss(:,ip(i)),s.z,'color',cmapt(i,:),'linewidth',lw);
end
xlabel('salinity'); ylabel('depth (m)');
h = colorbar; colormap(gca,cmapt); caxis([min(s.t),max(s.t)]);
ylabel(h,'time (days)'); ylim([-p.H,0]);
set(gca,'box','on'); grid on; title('SHELF');

% shelf time series
nexttile; hold on;
for i=1:length(s.z)
    plot(s.t,s.Ss(i,:),'color',cmapz(length(s.z)-i+1,:),'linewidth',lw);
end
xlabel('time (days)'); ylabel('salinity');
h = colorbar; colormap(gca,cmapz); caxis([-p.H,0]);
ylabel(h,'depth (m)');
set(gca,'box','on'); grid on; title('SHELF');

%% volume fluxes
figure();

tcl = tiledlayout(2,2);
title(tcl,'VOLUME FLUXES');

% deal with potential for multiple plumes by summing volume fluxes
s.QVp = squeeze(sum(s.QVp,1));

% plume
nexttile; hold on;
for i=1:length(ip)
    plot(s.QVp(:,ip(i)),s.z,'color',cmapt(i,:),'linewidth',lw);
end
xlabel('volume flux (m^3/s)'); ylabel('depth (m)');
h = colorbar; colormap(cmapt); caxis([min(s.t),max(s.t)]);
ylabel(h,'time (days)'); ylim([-p.H,0]);
set(gca,'box','on'); grid on; title('PLUME');

% shelf
nexttile; hold on;
for i=1:length(ip)
    plot(s.QVs(:,ip(i)),s.z,'color',cmapt(i,:),'linewidth',lw);
end
xlabel('volume flux (m^3/s)'); ylabel('depth (m)');
h = colorbar; colormap(cmapt); caxis([min(s.t),max(s.t)]);
ylabel(h,'time (days)'); ylim([-p.H,0]);
set(gca,'box','on'); grid on; title('SHELF');

% icebergs
% note for these vertical fluxes we plot the layer interface fluxes
% Q_{j+1,j} rather than the net fluxes Q_j
ints = -[0;cumsum(s.H(1:end-1))];
nexttile; hold on;
for i=1:length(ip)
    Qint = -cumsum(s.QVi(:,ip(i)),'reverse');
    plot(Qint,ints,'color',cmapt(i,:),'linewidth',lw);
end
xlabel('volume flux (m^3/s)'); ylabel('depth (m)');
h = colorbar; colormap(cmapt); caxis([min(s.t),max(s.t)]);
ylabel(h,'time (days)'); ylim([-p.H,0]);
set(gca,'box','on'); grid on; title('ICEBERGS');

% vertical advection
% note for these vertical fluxes we plot the layer interface fluxes
% Q_{j+1,j} rather than the net fluxes Q_j
ints = -[0;cumsum(s.H(1:end-1))];
nexttile; hold on;
for i=1:length(ip)
    Qint = -cumsum(s.QVv(:,ip(i)),'reverse');
    plot(Qint,ints,'color',cmapt(i,:),'linewidth',lw);
end
xlabel('volume flux (m^3/s)'); ylabel('depth (m)');
h = colorbar; colormap(cmapt); caxis([min(s.t),max(s.t)]);
ylabel(h,'time (days)'); ylim([-p.H,0]);
set(gca,'box','on'); grid on; title('VERTICAL ADVECTIVE');

%% freshwater
figure();

tcl = tiledlayout(2,3);
title(tcl,'FRESHWATER');

% iceberg melt rate
nexttile(1); hold on;
for i=1:length(ip)
    plot(s.mi(:,ip(i)),s.z,'color',cmapt(i,:),'linewidth',lw);
end
xlabel('iceberg melt rate (m/d)'); ylabel('depth (m)');
h = colorbar; colormap(cmapt); caxis([min(s.t),max(s.t)]);
ylabel(h,'time (days)');
set(gca,'box','on'); grid on;

% iceberg melt flux
nexttile(2); hold on;
for i=1:length(ip)
    plot(s.QMi(:,ip(i)),s.z,'color',cmapt(i,:),'linewidth',lw);
end
xlabel('iceberg melt flux (m^3/s)'); ylabel('depth (m)');
h = colorbar; colormap(cmapt); caxis([min(s.t),max(s.t)]);
ylabel(h,'time (days)');
set(gca,'box','on'); grid on;

% deal with potential for multiple plumes by taking mean over melt rate
% but sum over melt flux
s.mp = squeeze(mean(s.mp,1));
s.QMp = squeeze(sum(s.QMp,1));
s.Qsg = squeeze(sum(s.Qsg,1));

% plume melt rate
nexttile(4); hold on;
for i=1:length(ip)
    plot(s.mp(:,ip(i)),s.z,'color',cmapt(i,:),'linewidth',lw);
end
xlabel('plume melt rate (m/d)'); ylabel('depth (m)');
h = colorbar; colormap(cmapt); caxis([min(s.t),max(s.t)]);
ylabel(h,'time (days)');
set(gca,'box','on'); grid on;

% plume melt flux
nexttile(5); hold on;
for i=1:length(ip)
    plot(s.QMp(:,ip(i)),s.z,'color',cmapt(i,:),'linewidth',lw);
end
xlabel('plume melt flux (m^3/s)'); ylabel('depth (m)');
h = colorbar; colormap(cmapt); caxis([min(s.t),max(s.t)]);
ylabel(h,'time (days)');
set(gca,'box','on'); grid on;

% total fluxes
nexttile(6); hold on;
plot(s.t,sum(s.QMi),'linewidth',lw);
plot(s.t,sum(s.QMp),'linewidth',lw);
plot(s.t,s.Qsg,'linewidth',lw);
plot(s.t,s.Qr,'linewidth',lw);
xlabel('time (days)'); ylabel('total flux (m^3/s)');
legend('iceberg melt','plume sub. melt','sub. discharge','river','location','best');
title('freshwater inputs');
set(gca,'box','on'); grid on;

end
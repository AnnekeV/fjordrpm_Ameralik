clear title
close all   % closes all open figure windows
load('ameralik_combined_Kb1e-04_C01e+05_tidal.mat')
s_tidal = s;

load('ameralik_combined_Kb1e-03_C01e+05.mat')



s.t_date = datetime(s.t, "ConvertFrom","datenum");

% --- Tracer evolution ---
figure
imagesc(s.t, s.z, s.Tracer)
set(gca,'YDir','normal')   % depth increases downward
colorbar
xlabel('Time')
ylabel('Depth')
title('Tracer evolution')

% --- Normalized Tracer ---
Tracer_norm = s.Tracer ./ max(s.Tracer(:));
figure
imagesc(s.t, s.z, Tracer_norm)
set(gca,'YDir','normal')   % depth increases downward
colorbar
xlabel('Time')
ylabel('Depth')
title('Normalized Tracer evolution')

% --- Log10 Tracer ---
figure
imagesc(s.t, s.z, log10(s.Tracer + 1e-7))
set(gca,'YDir','normal')   % depth increases downward
colorbar
xlabel('Time')
ylabel('Depth')
title('Log10 Tracer evolution')

% --- Depth-integrated Tracer ---

dt = s.t(2) - s.t(1);
Tracer_sum_time = sum(s.Tracer, 1);
Tracer_sum_time_tidal = sum(s_tidal.Tracer, 1);

s.FW_depth = s.Tracer.*s.H;
s_tidal.FW_depth = s_tidal.Tracer.*s.H;

figure
t = tiledlayout(4,2,'TileSpacing','compact','Padding','compact');

ax1 = nexttile;
plot(s.t_date, s.Tracer(1,:))
hold on 
plot(s.t_date, s_tidal.Tracer(1,:))
ylabel('Total Tracer')
title('Tracer top layer')
legend(["V. high mix", "Tidal high mix"])


ax2 = nexttile;
plot(s.t_date, s.Tracer(2,:))
hold on 
plot(s.t_date, s_tidal.Tracer(2,:))
ylabel('Total Tracer')
title('Tracer second layer')
legend(["V. high mix", "Tidal high mix"])

ax3 = nexttile;
plot(s.t_date, Tracer_sum_time)
hold on
plot(s.t_date, Tracer_sum_time_tidal)
legend(["V. high mix", "Tidal high mix"])
ylabel('Total Tracer')
title('Depth-integrated Tracer')

ax4 = nexttile;
plot(s.t_date, cumsum(s.Qr * dt * p.sid))
hold on 
plot(s.t_date, sum(s.Tracer.*s.V, 1))
hold on 
plot(s.t_date, sum(s_tidal.Tracer.*s.V, 1))

xlabel('Time')
ylabel('Cumulative River Input')
title('Cumulative River Input')
legend(["River", "Tracer sum", "Tracer sum tidal"])


% for 0-50 m 

z_idx = abs(s.z) <50;

ax5 = nexttile;
plot(s.t_date, sum(s.FW_depth(z_idx,:), 1) );
hold on 
plot(s.t_date, sum(s_tidal.FW_depth(z_idx,:), 1) );
ylabel('Total FW depth tracer (m) ')
title('Tracer integrated 0-50 m')
legend(["V. high mix", "Tidal high mix"])

% and for 50-110 m 


% for 0-50 m 

z_idx = abs(s.z) >50 & abs(s.z) <110;

ax6 = nexttile;
plot(s.t_date, sum(s.FW_depth(z_idx,:), 1));
hold on
plot(s.t_date, sum(s_tidal.FW_depth(z_idx,:), 1));
ylabel('FW depth (m)')
title('FW depth 50-110 m')
legend(["V. high mix", "Tidal high mix"])



z_idx = abs(s.z) >110;

ax7 = nexttile;
plot(s.t_date, sum(s.FW_depth(z_idx,:), 1));
hold on
plot(s.t_date, sum(s_tidal.FW_depth(z_idx,:), 1));
ylabel('FW depth (m)')
title('FW depth 50-110 m')
legend(["V. high mix", "Tidal high mix"])


linkaxes([ax1, ax2, ax3,ax4, ax5, ax6, ax7], 'x')



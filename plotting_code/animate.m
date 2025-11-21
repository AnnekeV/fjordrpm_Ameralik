function animate(p,s,nframes,outputname)

% ANIMATE makes an animation of a FjordRPM run.
%   ANIMATE(p,s,nframes,outputname) makes a number nframes of snapshots of
%   the model output, equally spaced in time from the start to the end of
%   the run. Each plot contains circulation, temperature, salinity,
%   fjord-shelf exchange and freshwater fluxes. These plots are combined
%   into a mp4 animation and the individual plotting files are then
%   deleted. Input are the parameters structure p, solution structure s,
%   number of frames to include in the animation nframes and the output
%   file name outputname.

% delete existing video if exists
warning off; delete([outputname,'.mp4']); warning on;

% colour maps from https://uk.mathworks.com/matlabcentral/fileexchange/57773-cmocean-perceptually-uniform-colormaps
cmap_vel = cmocean('balance');
cmap_sal = cmocean('haline');
cmap_temp = cmocean('thermal');
cmap_anom = cmocean('delta');

% some nice plotting colours
load plotcols.mat

% plotting font size
fs = 10;

% deal with potential multiple plumes by summing the volume fluxes
% as if multiple plumes were one plume
s.QVp = squeeze(sum(s.QVp,1));
s.QMp = squeeze(sum(s.QMp,1));
s.Qsg = squeeze(sum(s.Qsg,1));

% axis limits
u0 = [s.QVs./(p.W*s.H)];
ulims = max(abs(u0(:)))*[-1,1];
w0 = cumsum(s.QVp+s.QVs)/(p.W*p.L);
wlims = max(abs(w0(:)))*[-1,1];
Slims = [min(s.S(:)),max(s.S(:))];
if diff(Slims)==0, Slims = [Slims(2)-0.1,Slims(2)]; end
Splims = [min([s.Ss(:);s.S(:)]),max([s.Ss(:);s.S(:)])];
if diff(Splims)==0, Splims = [Splims(2)-0.1,Splims(2)]; end
Tlims = [min(s.T(:)),max(s.T(:))];
Tplims = [min([s.Ts(:);s.T(:)]),max([s.Ts(:);s.T(:)])];
Sanomlims = max(abs(s.S(:)-s.Ss(:)))*[-1,1];
Tanomlims = max(abs(s.T(:)-s.Ts(:)))*[-1,1];
fluxlims = [min([s.Qsg,sum(s.QMi),s.Qr]),max([s.Qsg,sum(s.QMi),s.Qr])];
if length(unique(fluxlims))==1
    fluxlims(2)=fluxlims(2)+1;
end
tlims = [min(s.t),max(s.t)];

% grids
nx = 15;
x = linspace(0,p.L,nx)/1e3;
xg = linspace(0,p.L,nx+1)/1e3;
nz = length(s.z);
zc = s.z;
zg = -[0;cumsum(s.H)];

% sill patch
if p.sill==1
    xsill = [p.L,p.L,0.98*p.L,0.98*p.L]/1e3;
    zsill = -[p.H,p.Hsill,p.Hsill,p.H];
else
    xsill = NaN;
    zsill = NaN;
end
scolor = 0.5*[1,1,1];
swidth = 1;

% time steps to plot
inx = round(linspace(1,length(s.t),nframes));
n_timesteps = length(inx);

% loop over time steps to plot
for k=1:n_timesteps
    waitbar(k/n_timesteps);

    i = inx(k);
    figure(); set(gcf,'Visible','off');
    
    % plotting data for this timestep
    u = interp1([0,p.L]/1e3,[s.QVp(:,i),-s.QVs(:,i)]',x)'./(p.W*s.H);
    w = -[0;cumsum(s.QVp(:,i)+s.QVs(:,i))/(p.W*p.L)];
    w = 0.5*(w(1:end-1)+w(2:end));
    w = interp1([0,p.L]/1e3,[w,w]',x)';
    S = interp1([0,p.L]/1e3,[s.S(:,i),s.S(:,i)]',x)';
    Ss = interp1([0,p.L]/1e3,[s.Ss(:,i),s.Ss(:,i)]',x)';
    T = interp1([0,p.L]/1e3,[s.T(:,i),s.T(:,i)]',x)';
    Ts = interp1([0,p.L]/1e3,[s.Ts(:,i),s.Ts(:,i)]',x)';
    
    % pad data to deal with pcolor
    uplot = [[u,NaN(nz,1)];NaN(1,nx+1)];
    wplot = [[w,NaN(nz,1)];NaN(1,nx+1)];
    Splot = [[S,NaN(nz,1)];NaN(1,nx+1)];
    Sanomplot = [[S-Ss,NaN(nz,1)];NaN(1,nx+1)];
    Tplot = [[T,NaN(nz,1)];NaN(1,nx+1)];
    Tanomplot = [[T-Ts,NaN(nz,1)];NaN(1,nx+1)];
    
    % plot along-fjord velocity
    subplot(2,6,1:2); hold on;
    pcolor(xg,zg,uplot); shading flat;
    patch(xsill,zsill,scolor,'edgecolor','k','linewidth',swidth);
    colorbar('fontsize',fs); colormap(gca,cmap_vel); caxis(ulims);
    xlim([0,p.L]/1e3); ylim([-p.H,0]);
    title('along-fjord velocity (m/s)','fontsize',fs);
    xlabel('x (km)','fontsize',fs); ylabel('depth (m)','fontsize',fs);
    set(gca,'box','on','layer','top','fontsize',fs);
    text(0.03*p.L/1e3,-0.88*p.H,'glacier at left, shelf at right','fontsize',fs);
    text(0.03*p.L/1e3,-0.94*p.H,'positive velocities are left to right','fontsize',fs);
    
    % plot vertical velocity
    subplot(2,6,7:8); hold on;
    pcolor(xg,zg,wplot); shading flat;
    patch(xsill,zsill,scolor,'edgecolor','k','linewidth',swidth);
    colorbar('fontsize',fs); colormap(gca,cmap_vel); caxis(wlims);
    xlim([0,p.L]/1e3); ylim([-p.H,0]);
    title('vertical velocity (m/s)','fontsize',fs);
    xlabel('x (km)','fontsize',fs); ylabel('depth (m)','fontsize',fs);
    set(gca,'box','on','layer','top','fontsize',fs);

    % plot temperature
    subplot(2,6,3:4); hold on;
    pcolor(xg,zg,Tplot); shading flat;
    patch(xsill,zsill,scolor,'edgecolor','k','linewidth',swidth);
    colorbar('fontsize',fs); colormap(gca,cmap_temp); caxis(Tlims);
    xlim([0,p.L]/1e3); ylim([-p.H,0]);
    title('fjord temperature (C)','fontsize',fs);
    xlabel('x (km)','fontsize',fs);
    set(gca,'box','on','layer','top','fontsize',fs);

    % plot temperature profiles
    ints = -[0;cumsum(s.H)];
    subplot(2,6,5); hold on;
    stairs([s.Ts(1,i);s.Ts(:,i)],ints,'k','linewidth',2);
    stairs([s.T(1,i);s.T(:,i)],ints,'linewidth',2,'color',cols(2,:));
    xlim(Tplims); ylim([-p.H,0]);
    set(gca,'box','on','fontsize',fs); grid on;
    xlabel('temperature (C)','fontsize',fs);
    
    % plot salinity
    subplot(2,6,9:10); hold on;
    pcolor(xg,zg,Splot); shading flat;
    patch(xsill,zsill,scolor,'edgecolor','k','linewidth',swidth);
    colorbar('fontsize',fs); colormap(gca,cmap_sal); caxis(Slims);
    xlim([0,p.L]/1e3); ylim([-p.H,0]);
    title('fjord salinity','fontsize',fs);
    xlabel('x (km)','fontsize',fs);
    set(gca,'box','on','layer','top','fontsize',fs);

    % plot salinity profiles
    ints = -[0;cumsum(s.H)];
    subplot(2,6,6); hold on;
    stairs([s.Ss(1,i);s.Ss(:,i)],ints,'k','linewidth',2);
    stairs([s.S(1,i);s.S(:,i)],ints,'linewidth',2,'color',cols(2,:));
    xlim(Splims); ylim([-p.H,0]);
    set(gca,'box','on','fontsize',fs); grid on;
    xlabel('salinity','fontsize',fs);
    legend('shelf','fjord','location','southwest','fontsize',fs-2);
    
    % plot fjord-shelf exchange velocity
    subplot(2,6,11); hold on;
    stairs(-[u0(1,i);u0(:,i)],ints,'k','linewidth',2);
    set(gca,'box','on'); grid on;
    xlabel('fjord-shelf exchange velocity (m/s)','fontsize',fs);
    xlim(ulims); ylim([-p.H,0]);
    title('positive values out of fjord','fontsize',fs);

    % plot freshwater time series
    subplot(2,6,12); hold on;
    l1 = plot(s.t,s.Qsg,'linewidth',2,'color',cols(1,:));
    plot(s.t(i),s.Qsg(i),'o','color',cols(1,:));
    l2 = plot(s.t,sum(s.QMi),'linewidth',2,'color',cols(6,:));
    plot(s.t(i),sum(s.QMi(:,i)),'o','color',cols(6,:));
    l3 = plot(s.t,sum(s.QMp),'linewidth',2,'color',cols(3,:));
    plot(s.t(i),sum(s.QMp(:,i)),'o','color',cols(3,:));
    l4 = plot(s.t,s.Qr,'linewidth',2,'color',cols(4,:));
    plot(s.t(i),s.Qr(i),'o','color',cols(4,:));
    xlabel('time (days)','fontsize',fs);
    ylabel('flux (m$^3$/s)','fontsize',fs);
    set(gca,'box','on','fontsize',fs); grid on;
    legend([l1,l2,l3,l4],'discharge','iceberg melt',...
        'plume melt','river','location','best','fontsize',fs-2);
    xlim(tlims); ylim(fluxlims);
     
    % time step
    sgtitle(['t = ',num2str(0.01*round(100*s.t(i))),' days'],'fontsize',fs+2);
    
    % save plot
    if k<10
        savenum = ['00', num2str(k)];
    elseif k<100
        savenum = ['0', num2str(k)];
    else
        savenum = num2str(k);
    end
    saveplot(40,15,300,[outputname,'_',savenum,'.png']);
    close all;

end

% write video
video = VideoWriter([outputname,'.mp4'],'MPEG-4');
video.FrameRate = 5;
open(video);
pngs = dir(fullfile([outputname,'*.png']));
for k = 1:length(pngs)
    I = imread([pngs(k).folder,'/',pngs(k).name]);
    writeVideo(video, I);
end
close(video);
delete([outputname,'*.png']);

end

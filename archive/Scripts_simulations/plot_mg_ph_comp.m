% Author:   Gilmer A. Flores Barrera
% Date:   2025-05-21
% Description:
% 	Plot Mag, Phase and real(Complex) for Experiments Oestreicher
%clc; clear; close all;

format compact;
set(0,'defaultAxesFontSize',24);
set(0,'defaultAxesFontName','Cambria');
set(groot, 'defaultAxesTickLabelInterpreter','tex'); 
set(groot, 'defaultLegendInterpreter','tex');
set(0,'defaulttextInterpreter','tex');

addpath("C:\Users\gflor10\Box\US_codes_2024")

%for 
    freq=500;
   %filename=['C:\Users\gflor10\Box\REQ Estimator\Simulations\Results\' ...
      % 'req_sim_k004_128sources500Hz.mat'];
   % load(filename);

    % xvec=dinf.dx*(0:size(ux_s,2)-1)*1e2;
    % zvec=dinf.dz*(0:size(ux_s,1)-1)*1e2;

    f=freq;
    dinf.freq=freq;
    dinf.SAVE_FIGS=0;
    Fs = 1/dinf.dt;                        % Sampling frequency
    L = 2^nextpow2(size(ux_s,3));
    df = Fs/L;                              % frequency resolution
    f1 = (-round(L/2):1:round(L/2)-1)*df;   % frequency axis
    % find index for closest frequency to the vibration frequency
    [ ~, ix ] = min(abs(f1-f));  
    peak = ix;
    %[Frames0,~] = spatial_fil_phase_extrac(fu,peak,L);
    t_tag=floor(size(ux_s,3)/3);
    u_temp=(ux_s(:,:,t_tag:end));


SNR_dB = 6;   % signal-to-noise ratio

signal_power = mean(abs(u_temp(:)).^2);
noise_power = signal_power / (10^(SNR_dB/10));

noise = sqrt(noise_power) * randn(size(u_temp));

u_temp_noisy = u_temp + noise;



    [A,Phs,Comp]=amp_phs(u_temp_noisy,peak,L);
   % A=medfilt2(A, [3 3]);
    %(:,:,200:end)
    %xvec=dinf.dx*(0:size(A,2)-1)*1e2;
    %zvec=dinf.dy*(0:size(A,1)-1)*1e2;
    Vz_mg_ph= A.*(exp(1i*Phs));
%%
  xvec=dinf.dx*(0:size(Vz_mg_ph,2)-1)*1e2;
    zvec=dinf.dy*(0:size(Vz_mg_ph,1)-1)*1e2;
        figure('Position', get(0, 'Screensize'));
A=abs(Vz_mg_ph);
    % Magnitude
    ax1=subplot(1,3,1); imagesc(xvec,zvec,A/max(A(:)));
    title("V_0");
    %axis('xy'),
    xlabel('Lateral distance (cm)'); ylabel('Depth (cm)');
    colormap(ax1,"hot")
    colorbar; clim([0,1]),
    axis image;

    % Phase
    ax2=subplot(1,3,2); imagesc(xvec,zvec,(real(exp(1i*Phs)))),
    title("Exp(i\Phi(r))");
    %axis('xy');
    xlabel('Lateral distance (cm)'); ylabel('Depth (cm)');
    colormap(ax2,"redblue")
    colorbar, clim([-1,1])
    axis image;

    %Magnitude and Phase
    ax3=subplot(1,3,3); imagesc(xvec,zvec,(real(Vz_mg_ph)./max(max(real(Vz_mg_ph))))),
    title("V_0*Exp(i\Phi(r))");
    %axis('xy'),
    xlabel('Lateral distance (cm)'); ylabel('Depth (cm)');
    colorbar, clim([-1,1])
    colormap(ax3,slanCM("iceburn"))
    axis image;

  %  saveas(gcf,'Vz_mg_ph_TempFilt.svg')

%%
    addpath(fullfile('C:\Users\gflor10\Box\Elastography - To Share\clean_codes_RSWE'));

    [cs_map_est, ~, ~, xc, zc] = estimators.REQ_estimator(Vz_mg_ph, dinf.dx, dinf.dy, f, 3, ...
    'M',2,'StepX',1,'StepZ',1,'Gamma',1,'PadFactor',1, ...
    'Nbins',120,'SmoothSigma',1,'QuantE',0.62,'EdgeMode','valid', ...
    'WindowType','hann-circular');

    rswe.plot_req_map(cs_map_est, xc, zc, dinf, 'A_cs_map');
%%
    window=[51,51];
vz_pad=padarray(Vz_mg_ph,(window-[1,1])*0.5,'symmetric','both');

correc=xcorr2(ones(window(1),window(2)));

[TK_wfil]=sws_estimation_IUS2025(Vz_mg_ph,window,dinf.dx,dinf.dy,correc);
%%

promedioCs=zeros(4,1);
des_vestCs=zeros(4,1);
Cs_wfil=cell(1,4);
for i=4
    Cs_wfil{i}=2*pi*freq./(real(TK_wfil{i}));
    promedioCs(i)=mean(mean(Cs_wfil{i}));
    des_vestCs(i)=std(Cs_wfil{i},0,'all');
end

save('SWS_results.mat','Cs_wfil');


xx=(1:size(Cs_wfil{4},2))*dinf.dx*2*1e2;
zz=(1:size(Cs_wfil{4},1))*dinf.dy*2*1e2;
rswe.plot_req_map(Cs_wfil{4}, xc, zc, dinf, 'A_cs_map');
%%
    % A_norm = mat2gray(A);
    % % Compute percentiles on the normalized data
    % lims_norm = prctile(A_norm(:), [1 99]);
    % % Apply imadjust with those limits
    % A_eq2 = imadjust(A_norm, lims_norm, []);
    
    % figure('Position', get(0, 'Screensize'));
    % 
    % % Magnitude
    % ax1=subplot(1,3,1); imagesc(xvec,zvec,A_eq2);
    % % hold on 
    % % % Dibujar el rectángulo transparente con líneas blancas
    % % rectangle('Position', position_bg, ...
    % %           'EdgeColor', 'w', ...       % Color de borde blanco
    % %           'LineWidth', 5, ...         % Grosor de las líneas
    % %           'LineStyle', '-');          % Estilo de línea
    % % rectangle('Position', position_inc, ...
    % %           'EdgeColor', 'w', ...       % Color de borde blanco
    % %           'LineWidth', 5, ...         % Grosor de las líneas
    % %           'LineStyle', '-');          % Estilo de línea
    % % hold off
    % title("V_0");
    % %axis('xy'),
    % xlabel('Lateral distance (cm)'); ylabel('Depth (cm)');
    % colormap(ax1,"hot")
    % c=colorbar; clim([0,1]);
    % c.Label.String='a.u.';
    % c.Location="southoutside";
    % %ylim([zvec(1) zvec(end-1)])
    % axis image;
    % 
    % % Phase
    % ax2=subplot(1,3,2); imagesc(xvec,zvec,Phs),
    % % hold on 
    % % % Dibujar el rectángulo transparente con líneas blancas
    % % rectangle('Position', position_bg, ...
    % %           'EdgeColor', 'w', ...       % Color de borde blanco
    % %           'LineWidth', 5, ...         % Grosor de las líneas
    % %           'LineStyle', '-');          % Estilo de línea
    % % rectangle('Position', position_inc, ...
    % %           'EdgeColor', 'w', ...       % Color de borde blanco
    % %           'LineWidth', 5, ...         % Grosor de las líneas
    % %           'LineStyle', '-');          % Estilo de línea
    % % hold off
    % title("\Ree \{Exp(i\Phi(r))\}");
    % %axis('xy');
    % xlabel('Lateral distance (cm)'); ylabel('Depth (cm)');
    % colormap(ax2,"redblue")
    % c=colorbar; clim([-pi,pi]);
    % c.Label.String='rad';
    % c.Location="southoutside";
    % %ylim([zvec(1) zvec(end)])
    % axis image;
    
    A_norm = real(Vz_mg_ph)./max(max(real(Vz_mg_ph)));
    p = prctile(A_norm(:), [1 99]);
    lim_low  = p(1);
    lim_high = p(2);
    
    % 2) Clip M to those limits
    M_clipped       = A_norm;
    M_clipped(M_clipped < lim_low)  = lim_low;
    M_clipped(M_clipped > lim_high) = lim_high;
    
    % 3) Linearly scale into [0,1]
    M_eq = M_clipped / lim_high;
    
    %Magnitude and Phase
    % ax3=subplot(1,3,3); imagesc(xvec,zvec,(real(Vz_mg_ph)./max(max(real(Vz_mg_ph))))),
    ax3=subplot(1,3,3); imagesc(xvec,zvec,M_eq),
    % hold on 
    % % Dibujar el rectángulo transparente con líneas blancas
    % rectangle('Position', position_bg, ...
    %           'EdgeColor', 'w', ...       % Color de borde blanco
    %           'LineWidth', 5, ...         % Grosor de las líneas
    %           'LineStyle', '-');          % Estilo de línea
    % rectangle('Position', position_inc, ...
    %           'EdgeColor', 'w', ...       % Color de borde blanco
    %           'LineWidth', 5, ...         % Grosor de las líneas
    %           'LineStyle', '-');          % Estilo de línea
    % hold off
    title("\Re \{V_0*Exp(i\Phi(r))\}");
    %axis('xy'),
    xlabel('Lateral distance (cm)'); ylabel('Depth (cm)');
    c=colorbar; clim([-1,1]);
    c.Label.String='a.u.';
    c.Location="southoutside";
    colormap(ax3,slanCM("iceburn"))
    %ylim([zvec(1) zvec(end)])
    axis image;

   %saveas(gcf,'Vz_mg_ph_TempFilt_zones.png')





    %% generation of spatial filter and filtering process
    sigma = 300; % CHANGE 300;
    
    cs_min = 0.7; 
    cs_max = 100;
    
    % Fsx = 1/dinf.dx;                            
    % Fsz = 1/dinf.dz;
    Fsx=2^11;
    Fsz=2^11;
    
    % Spatial frequencies cutoffs estimation base on  the relationship  k=2pi/c 
    [kx,kz] = freqspace(size(Vz_mg_ph),'meshgrid');
    kx = kx*pi*Fsx;
    kz = kz*pi*Fsz;
    spatial_fft = abs(fftshift(fft2(Vz_mg_ph,Fsx,Fsz)));
    
    % Spatial FFT of Temp filtered Vz
    figure('Position', get(0, 'Screensize'));
    imagesc(kx(1,:),kz(:,1),db(spatial_fft));
    axis image;
    xlim([-750 750])
    ylim([-750 750])
    ttl='2D Spatial FFT Zmotion - Temporal Filtered';
    title(ttl);
    colormap("gray")
    hold on;
    xline(0, 'r--', 'LineWidth', 2);
    yline(0, 'r--', 'LineWidth', 2);
    hold off;
    clim([-40 0])

    % saveas(gcf,'2D Spatial FFT Zmotion-Temporal Filtered.svg')
    

    % 
    % Hd = ones(size(Vz_mg_ph)); 
    % r = sqrt(kx.^2 + kz.^2);
    % kl = (2*pi*f/cs_max);
    % kh = (2*pi*f/cs_min);
    % Hd((r<kl)|(r>kh)) = 0;
    % 
    % win = fspecial('gaussian',size(Vz_mg_ph),sigma); 
    % win = win / max(win(:));  % Make the maximum window value be 1.
    % h = fwind2(Hd,win);        % Using the 2-D window, design the filter that best produces the desired frequency response
    % mask2 = abs(fftshift(fft2(ifftshift(h))));
    % 
    % % Spatial FFT of Temp filtered Vz
    % figure('Position', get(0, 'Screensize'));
    % imagesc(kx(1,:),kz(:,1),mask2);
    % axis image;
    % ttl='2D Spatial Filter in Frequency Domain';
    % title(ttl);
    % colormap("gray")
    % saveas(gcf,'2D Spatial Filter in Frequency Domain.svg')
    % 
    % Wave_z = filter2(h,Vz_mg_ph);
    % spatial_fft1 = abs(fftshift(fft2(Wave_z,Fsx,Fsz)));
    % figure('Position', get(0, 'Screensize'));
    % imagesc(kx(1,:),kz(:,1),spatial_fft1);
    % axis image;
    % xlim([-750 750])
    % ylim([-750 750])
    % ttl='2D Spatial FFT Zmotion - Spatial Filtered';
    % title(ttl);
    % colormap("gray")
    % saveas(gcf,'2D Spatial FFT Zmotion-Spatial Filtered.svg')
%end
    % %%
    % A1=abs(Wave_z);
    % Phs1=angle(Wave_z);
    % Vz_mg_ph1=A1.*exp(1i*Phs1);
    % 
    % figure('Position', get(0, 'Screensize'));
    % 
    % % Magnitude
    % ax1=subplot(1,3,1); imagesc(xvec,zvec,A1/max(A1(:)));
    % title("V_0");
    % %axis('xy'),
    % xlabel('Lateral distance (cm)'); ylabel('Depth (cm)');
    % colormap(ax1,"hot")
    % c=colorbar; clim([0,1]),
    % axis image;
    % 
    % % Phase
    % ax2=subplot(1,3,2); imagesc(xvec,zvec,(real(exp(1i*Phs1)))),
    % title("Exp(i\Phi(r))");
    % %axis('xy');
    % xlabel('Lateral distance (cm)'); ylabel('Depth (cm)');
    % colormap(ax2,"redblue")
    % colorbar, clim([-1,1])
    % axis image;
    % 
    % %Magnitude and Phase
    % ax3=subplot(1,3,3); imagesc(xvec,zvec,(real(Vz_mg_ph1)./max(max(real(Vz_mg_ph1))))),
    % title("V_0*Exp(i\Phi(r))");
    % %axis('xy'),
    % xlabel('Lateral distance (cm)'); ylabel('Depth (cm)');
    % colorbar, clim([-1,1])
    % colormap(ax3,"jet")
    % axis image;
    % saveas(gcf,'Vz_mg_ph_SpatialFilt.png')
    % %%
    % % r = sqrt(kx.^2 + kz.^2);
    % % win = fspecial('gaussian',[Fsx Fsz],sigma);
    % % win = win ./ max(win(:));  % Make the maximum window value be 1.
    % % 
    % % Hd = ones([Fsx Fsz]);
    % % kl = (2*pi*filter_freq/cs_max); %502.6548
    % % kh = (2*pi*filter_freq/cs_min); %6.2832e+03
    % % Hd((r<kl)|(r>kh)) = 0;
    % % h = fwind2(Hd,win);  % Using the 2-D window, design the filter that best produces the desired frequency response
    % % 
    % % dir_angles = [0 180];
    % % Filter = cosine_sqrt_dependance(xvec,zvec,dir_angles);
    % % 
    % % M_filtered = filter2(h,Vz_mg_ph); % 2D FIR filter
    % % Vw = fftshift(fft2(ifftshift((squeeze(M_filtered)))));
    % %     for tt = 1: size(Filter,3)
    % %         Vw1 = Vw.*Filter(:,:,tt);
    % %         Vw1(isnan(Vw1))= 0;
    % %         M_filt_dir(:,:,tt) = (fftshift(ifftn(ifftshift(Vw1))));
    % % 
    % %     end
    % %  M_filtered1 = sum(M_filt_dir,3);
    % % 
    % % twoD_spatial_fft_Zmotion = fftshift(fft2(h,Fsx,Fsz));
    % % MagnZmotion = abs(twoD_spatial_fft_Zmotion);
    % % PhasZmotion   = angle(twoD_spatial_fft_Zmotion);
    % % figSFz = figure('Position', get(0, 'Screensize'));
    % % imagesc(kx(1,:)/pi,kz(:,1)/pi,Hd);
    % % axis image;
    % % xlim([-700 700])
    % % ylim([-700 700])
    % % %clim([0 1500]) 
    % % colorbar, colormap(jet)
    % % ttl=['2D Spatial FFT Zmotion _ Spatial Filtered']
    % % title(ttl);
    % 
    % % %%
    % % omega = 2*pi*f;
    % % resT = 1/dinf.PRFe; % 
    % % Tmax = 20*1e-3; % 
    % % t = 0:resT:Tmax;
    % % fu1 = zeros([size(Wave_z),length(t)]);
    % % for kk = 1:length(t)
    % %     fu1(:,:,kk) = abs(Wave_z).*cos(angle(Wave_z)+omega*t(kk));
    % % end
    % % 
    % % exp_phase = exp(1i*angle(Wave_z));
    % % 
    % % 
    % % aviobj = VideoWriter(['Spatially Filtered PV ' num2str(f) 'Hz'], 'MPEG-4'); 
    % % aviobj.FrameRate = 10; 
    % % open(aviobj);
    % % 
    % % for jj=1:length(t) % N_Alines
    % % 
    % %     gc = figure('Position', get(0, 'Screensize'));
    % %      % sample_frame = squeeze(Frames(:,slice,:,jj));
    % %     imagesc(xvec,zvec,fu1(:,:,jj)/max(fu1(:)));
    % %     axis image;
    % %     xlabel('Lateral distance (cm)'); ylabel('Depth (cm)');
    % %     colormap("jet")
    % %     clim([-1 1]); % grid on;
    % %     colorbar
    % %     drawnow
    % %     F=getframe(gc); 
    % %     writeVideo(aviobj,F);
    % % end
    % % 
    % % close(aviobj);
    % % close all; 
    % % 
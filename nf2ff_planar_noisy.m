% 
% NF2FF Conversion using Planar Scanner
%
% Normal Distributed Position Noise
%
clear 
close all
clc

disp('************************************************')
disp('          Near-To-Far-Field Conversion')
disp('          Planar Scanner with normal distributed position Noise')
disp('************************************************')

addpath('misc_functions')
addpath('plot_functions')
addpath('transformation_functions')
%% Load Data
disp('Load Data...')
f = 5e9;

setup = '../measurement/PlanarScan_HornAntenna_Noise/';


data_ff = readtable([setup 'Farfield/farfield (f=' num2str(f*1e-9) ') [1].txt']);

scans = dir(setup);
scan_names = {scans.name};
scan_names(ismember(scan_names,{'.','..','Farfield','Scan-Nwidth-Nheight-WSpacing-HSpacing-Distance-WVar-HVar-DVar.txt'})) = [];
data_nf_raw= cellfun(@(scan_names) readtable([setup,scan_names,'/NearFieldProbeResults' num2str(f*1e-9) 'GHz.txt']),scan_names,'UniformOutput',false);

% Load ideal probe positions
probe_pos_ideal = cellfun(@(scan_names) readtable([setup,scan_names,'/ProbePositions.txt']),scan_names,'UniformOutput',false);
% Exchange positions
for i=1:length(scan_names)
    data_nf{i} = data_nf_raw{i};
    data_nf{i}.X = probe_pos_ideal{i}.x;
    data_nf{i}.Y = probe_pos_ideal{i}.y;
    data_nf{i}.Z = probe_pos_ideal{i}.z;
end

% Rearrange farfield table
data_ff = table(data_ff.Var1*pi/180,data_ff.Var2*pi/180,data_ff.Var3,data_ff.Var4,data_ff.Var6);
data_ff.Properties.VariableNames = {'theta' 'phi' 'Eabs' 'Ethetaabs' 'Ephiabs'};

% Rearrange nearfield table
data_nf = cellfun(@rearrangeTables,data_nf,'UniformOutput',false);
 
% Select measurements to process
% data_nf = data_nf([16]);
% scan_names = scan_names([16]);

disp('Done!')
%% NF2FF transformation
disp('NF2FF Transformation...')
delta_theta=1;
delta_phi=1;
theta_range = (-90:delta_theta:90-delta_theta)*pi/180;
phi_range= (0:delta_phi:180-delta_phi)*pi/180;
[theta_grid,phi_grid]=meshgrid(theta_range,phi_range);

% NF2FF Algorithm Parameters
fft_padding = 4;

data_nf2ff_rect = cellfun(@(data_nf) nf2ff_planar_fft(data_nf,f,phi_range,theta_range,fft_padding,'none'),data_nf,'Uniformoutput',false);
data_nf2ff_hamming = cellfun(@(data_nf) nf2ff_planar_fft(data_nf,f,phi_range,theta_range,fft_padding,'hamming'),data_nf,'Uniformoutput',false);
data_nf2ff_tukey = cellfun(@(data_nf) nf2ff_planar_fft(data_nf,f,phi_range,theta_range,fft_padding,'tukey'),data_nf,'Uniformoutput',false);

% data_nf2ff_rect = cellfun(@(data_nf) nf2ff_planar_manual(data_nf,f,phi_range,theta_range,'none'),data_nf,'Uniformoutput',false);
% data_nf2ff_hamming = cellfun(@(data_nf) nf2ff_planar_manual(data_nf,f,phi_range,theta_range,'hamming'),data_nf,'Uniformoutput',false);
% data_nf2ff_tukey = cellfun(@(data_nf) nf2ff_planar_manual(data_nf,f,phi_range,theta_range,'tukey'),data_nf,'Uniformoutput',false);

data_nf2ff = data_nf2ff_rect;

disp('Done!')
%% Plots
disp('Plotting...')
close all

fontsize = 14;

normalized = true;
logarithmic = false;

% Phi=0 cut
figure('name','Far-Field Cuts,Phi=0�','numbertitle','off',...
        'units','normalized','outerposition',[0 0 1 1],...
        'DefaultAxesFontSize',fontsize);
plotFFPhiCut(data_ff,0,normalized,logarithmic)
cellfun(@(data_nf2ff) plotNFPhiCut(data_nf2ff,0,normalized,logarithmic),data_nf2ff)
grid on
xlabel('Theta [�]')
if logarithmic == true
    ylim([-50 0])
    ylabel('E-Field Pattern [dB]')
else 
    ylim([0 1])
    ylabel('E-Field Pattern [-]')
end
title('Far-Field Cut Phi=0�')
legend(['Far-Field',scan_names])  ;

figure('name','Far-Field Error,Phi=0�','numbertitle','off',...
        'units','normalized','outerposition',[0 0 1 1],...
        'DefaultAxesFontSize',fontsize);
cellfun(@(data_nf2ff) plotDiffPhiCut(data_nf2ff,data_ff,0,theta_range),data_nf2ff)
grid on
xlabel('Theta [�]')
ylabel('Difference to Reference Far-Field [dB]')
title('Difference to Reference Far-Field, Phi=0�')
legend(scan_names);


% Phi=90 cut
figure('name','Far-Field Cuts,Phi=90�','numbertitle','off',...
        'units','normalized','outerposition',[0 0 1 1],...
        'DefaultAxesFontSize',fontsize);
plotFFPhiCut(data_ff,pi/2,normalized,logarithmic)
cellfun(@(data_nf2ff) plotNFPhiCut(data_nf2ff,pi/2,normalized,logarithmic),data_nf2ff)
grid on
xlabel('Theta [�]')
if logarithmic == true
    ylim([-50 0])
    ylabel('E-Field Pattern [dB]')
else 
    ylim([0 1])
    ylabel('E-Field Pattern [-]')
end
title('Far-Field Cut Phi=90�')
legend(['Far-Field',scan_names])


figure('name','Far-Field Error,Phi=90�','numbertitle','off',...
        'units','normalized','outerposition',[0 0 1 1],...
        'DefaultAxesFontSize',fontsize);
cellfun(@(data_nf2ff) plotDiffPhiCut(data_nf2ff,data_ff,pi/2,theta_range),data_nf2ff)
grid on
xlabel('Theta [�]')
ylabel('Difference to Reference Far-Field [dB]')
title('Difference to Reference Far-Field, Phi=90�')
legend(scan_names)


disp('Done!')

%% Accumulated Pattern Error Analysis
close all
fontsize = 14;

sigma = [0,1,2,3];

% Calculate APE
ape_rect = cellfun(@(data_nf2ff) ErrorAnalysis(data_ff,data_nf2ff,'planar'),data_nf2ff_rect);
ape_rect_mean = [ape_rect(1),...
                 mean(ape_rect(2:11)),...
                 mean(ape_rect(12:21)),...
                 mean(ape_rect(22:end))];
err_rect = [0,...
            range(ape_rect(2:11))/2,...
            range(ape_rect(12:21))/2,...
            range(ape_rect(22:end))/2];

ape_hamming = cellfun(@(data_nf2ff) ErrorAnalysis(data_ff,data_nf2ff,'planar'),data_nf2ff_hamming);
ape_hamming_mean = [ape_hamming(1),...
                    mean(ape_hamming(2:11)),...
                    mean(ape_hamming(12:21)),...
                    mean(ape_hamming(22:end))];
err_hamming = [0,...
               range(ape_hamming(2:11))/2,...
               range(ape_hamming(12:21))/2,...
               range(ape_hamming(22:end))/2];

ape_tukey = cellfun(@(data_nf2ff) ErrorAnalysis(data_ff,data_nf2ff,'planar'),data_nf2ff_tukey);
ape_tukey_mean = [ape_tukey(1),...
                  mean(ape_tukey(2:11)),...
                  mean(ape_tukey(12:21)),...
                  mean(ape_tukey(22:end))];
err_tukey = [0,...
             range(ape_tukey(2:11))/2,...
             range(ape_tukey(12:21))/2,...
             range(ape_tukey(22:end))/2];


% Increasing Variance
figure('name','Accumulated Pattern Error, Varying Area','numbertitle','off',...
        'units','normalized','outerposition',[0 0 1 1],...
        'DefaultAxesFontSize',fontsize);
errorbar(sigma,100*ape_rect_mean,100*err_rect,'--*')
hold on
errorbar(sigma,100*ape_hamming_mean,100*err_rect,'--*')
errorbar(sigma,100*ape_tukey_mean,100*err_rect,'--*')
grid on
xlabel('Standard Deviation of Probe Position [mm]');
ylabel('Accumulated Pattern Error [%]')
title({'Accumulated Pattern Error','\lambda/2 spacing'})
legend('Rectangular','Hamming','Tukey')


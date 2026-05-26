function [SNDR,ENOB,SFDR,SNR]=SAR_ADC(enob_ADC,weight_ADC,parameter)

%% initial setup-------------------------------------------

Vref=parameter(1);
len=parameter(2);
fs=parameter(3);
fin=parameter(4);
waveplot=1;

% 参数设置
kT = 1.38e-23 * 300;  % 300K时的kT值
C_DAC = 30e-15;       % 示例DAC电容值
sigma_kt = sqrt(1.8 * kT / C_DAC);  % kT/C噪声标准差
sigma_cmp = 1e-4;     % 比较器噪声标准差（示例值，需根据设计确定）
noise_std = sqrt(sigma_kt^2 + sigma_cmp^2);  % 总标准差
V_noise=0;


%% key parameter calculate--------------------------------------------
num_ADC=length(weight_ADC);%表示可以出几位的数字码，分辨率

C_SAR_weight_ideal=[weight_ADC(1:end),1];%one side cap weight
% % --- 添加电容失配 ---
% std_unit = 0.005;                     % 单位电容的标准差
% rng(0);                               % 固定随机种子，使结果可重复（可选）
% 
% % 每个电容的绝对标准差 = std_unit * sqrt(理想权重)
% mismatch_std = std_unit * sqrt(C_SAR_weight_ideal);
% 
% % 生成失配后的实际电容权重
% C_SAR_weight = C_SAR_weight_ideal + mismatch_std .* randn(size(C_SAR_weight_ideal));
% C_SAR_weight = max(C_SAR_weight, 0);           % 确保电容值为正（极小概率下不会为负）
C_SAR_weight = C_SAR_weight_ideal;


Vcm=Vref/2;
t=(0:len-1)*(1/fs);
wave=Vref/4*sin(2*pi*fin*t);


%% SAR setup----------------------------------------------------------------
total_CDAC=sum(C_SAR_weight);


%% SAR digitalize---------------------------------------------------
Dout = zeros(len,num_ADC);
for i=1:1:len
   
    Vin=wave(i); % Our input is an sinusoidal wave
    Vinp=Vcm+Vin;
    Vinn=Vcm-Vin;
    
    %Sar transfer
    [Dout_sar]=SAR_ADC_vs(Vinp,Vinn,Vref,Vcm,C_SAR_weight,total_CDAC,num_ADC,V_noise);
 
    Dout(i,:) = Dout_sar;

end



%% ENOB calculate
Vout=DAC_SAR(Dout,weight_ADC,enob_ADC,Vref);
plot(t,Vout);
[SNDR,ENOB,SFDR,SNR] =SNR_ADC(Vout,fs,waveplot);

end
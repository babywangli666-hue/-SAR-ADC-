function [full_SNDR_noMES, full_ENOB_noMES, full_SFDR_noMES, full_SNR_noMES, ...
          band_SNDR_noMES, band_ENOB_noMES, band_SFDR_noMES, band_SNR_noMES,...
          full_SNDR_MES, full_ENOB_MES, full_SFDR_MES, full_SNR_MES, ...
          band_SNDR_MES, band_ENOB_MES, band_SFDR_MES, band_SNR_MES]=SAR_ADC(enob_ADC,weight_ADC,parameter)

%% initial setup-------------------------------------------

Vref=parameter(1);
len=parameter(2);
fs=parameter(3);
fin=parameter(4);
cutoff_freq=parameter(5);
waveplot=1;
VC1p=0;
VC2p=0;
VC1n=0;
VC2n=0;

% 参数设置
kT = 1.38e-23 * 300;  % 300K时的kT值
C_DAC = 30e-15;       % 示例DAC电容值
sigma_kt = sqrt(1.8 * kT / C_DAC);  % kT/C噪声标准差
sigma_cmp = 1e-4;     % 比较器噪声标准差（示例值，需根据设计确定）
noise_std = sqrt(sigma_kt^2 + sigma_cmp^2);  % 总标准差
V_noise=noise_std * randn;

%% key parameter calculate--------------------------------------------
num_ADC=length(weight_ADC);%表示可以出几位的数字码，分辨率

C_SAR_weight_ideal=[weight_ADC(1:end),1];%one side cap weight
% --- 添加电容失配  ---
std_unit = 0.005;                     % 单位电容的标准差
%rng(0);                               % 固定随机种子，使结果可重复（可选）

% 每个电容的绝对标准差 = std_unit * sqrt(理想权重)
mismatch_std = std_unit * sqrt(C_SAR_weight_ideal);

% 生成失配后的实际电容权重
C_SAR_weight = C_SAR_weight_ideal + mismatch_std .* randn(size(C_SAR_weight_ideal));
C_SAR_weight = max(C_SAR_weight, 0);           % 确保电容值为正（极小概率下不会为负）

Vcm=Vref/2;
t=(0:len-1)*(1/fs);
wave=Vref/4*sin(2*pi*fin*t);


%% SAR setup----------------------------------------------------------------
total_CDAC=sum(C_SAR_weight);


%% SAR digitalize---------------------------------------------------
Dout_noMES = zeros(len,num_ADC);

for i=1:1:len

    Vin=wave(i); % Our input is an sinusoidal wave
    Vinp=Vcm+Vin;
    Vinn=Vcm-Vin;

    %Sar transfer
    [Dout_sar_noMES,V1,V2,V3,V4]=SAR_ADC_vs(Vinp,Vinn,Vref,Vcm,C_SAR_weight,total_CDAC,num_ADC,VC1p,VC2p,VC1n,VC2n,V_noise);
    VC1p = V1;
    VC2p = V2;
    VC1n = V3;
    VC2n = V4;

    Dout_noMES(i,:) = Dout_sar_noMES;

end

% 重置状态变量
VC1p = 0; VC2p = 0; VC1n = 0; VC2n = 0;

D_LSB_prev=zeros(1,num_ADC-1);
V_LSB_prev=0;
Vout_MES = zeros(1,len);

for i=1:1:len

    Vin=wave(i); % Our input is an sinusoidal wave
    Vinp=Vcm+Vin+V_LSB_prev;
    Vinn=Vcm-Vin-V_LSB_prev;

    %Sar transfer
    [Dout_sar_MES,V1,V2,V3,V4]=SAR_ADC_vs(Vinp,Vinn,Vref,Vcm,C_SAR_weight,total_CDAC,num_ADC,VC1p,VC2p,VC1n,VC2n,V_noise);
    VC1p = V1;
    VC2p = V2;
    VC1n = V3;
    VC2n = V4;

    Vo=sum(Dout_sar_MES .* weight_ADC)/2^enob_ADC*Vref+0.5*Vref/(2^enob_ADC); 
    VD_LSB=sum(D_LSB_prev .*C_SAR_weight_ideal(2:end-1))/2^enob_ADC*Vcm;
    Vout_MES(i)=Vo-VD_LSB;
   
     % 更新下一周期使用的LSB数字码（当前周期的LSB位）
    D_LSB_prev = Dout_sar_MES(2:end);
    D_LSB_prev = 2*D_LSB_prev - 1;

    % 计算当前周期LSB部分在实际电容下的电压
    Dout_sar_MES_temp=Dout_sar_MES(2:end);
    Dout_sar_MES_temp=2* Dout_sar_MES_temp - 1;
    V_LSB_prev = Vcm * sum(Dout_sar_MES_temp .* C_SAR_weight(2:end-1)) / total_CDAC;
end

%% ENOB calculate
Vout_noMES=DAC_SAR(Dout_noMES,weight_ADC,enob_ADC,Vref);
plot(t,Vout_noMES);
plot(t,Vout_MES);
[full_SNDR_noMES, full_ENOB_noMES, full_SFDR_noMES, full_SNR_noMES, ...
          band_SNDR_noMES, band_ENOB_noMES, band_SFDR_noMES, band_SNR_noMES] =SNR_ADC(Vout_noMES,fs,cutoff_freq,waveplot);
[full_SNDR_MES, full_ENOB_MES, full_SFDR_MES, full_SNR_MES, ...
          band_SNDR_MES, band_ENOB_MES, band_SFDR_MES, band_SNR_MES] =SNR_ADC(Vout_MES,fs,cutoff_freq,waveplot);

end

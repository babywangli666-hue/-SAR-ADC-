clc
clear;
close all;


enob_ADC=10;%target enob is must
weight_ADC=[512,256,128,64,32,16,8,4,2,1];%ADC weight is must

Vref=1.2;
len = 2^16;          % FFT 点数
fs = 10e7;           % 采样频率
k = 251;             % 整数个周期 %k = 100;
fin = fs * k / len;  % 相干频率
% len=2^16;
% fs=10e7;
% fin=fs/256;
cutoff_freq=fs/10;
parameter=[Vref,len,fs,fin,cutoff_freq];
[SNDR_noMES,ENOB_noMES,SFDR_noMES,SNR_noMES,...
    SNDR_MES,ENOB_MES,SFDR_MES,SNR_MES]=SAR_ADC(enob_ADC,weight_ADC,parameter);


% len = 2^16;          % FFT 点数
% fs = 10e7;           % 采样频率
% k = 256;             % 整数个周期 %k = 100;
% fin = fs * k / len;  % 相干频率
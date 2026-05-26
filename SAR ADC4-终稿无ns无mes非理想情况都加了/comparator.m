function output=comparator(Vp,Vn,V_noise)
% this function is a comparison function 
%the output of this function is either "1" or "0".

% % 参数设置
% kT = 1.38e-23 * 300;  % 300K时的kT值
% C_DAC = 30e-15;       % 示例DAC电容值
% sigma_kt = sqrt(1.8 * kT / C_DAC);  % kT/C噪声标准差
% sigma_cmp = 1e-4;     % 比较器噪声标准差（示例值，需根据设计确定）
% noise_std = sqrt(sigma_kt^2 + sigma_cmp^2);  % 总标准差

if Vp>Vn-V_noise   %Vn-V_noise
    output=1;
else
    output=0;
end
end
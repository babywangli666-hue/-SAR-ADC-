% 内部函数：根据给定的频谱数据计算 SNDR, ENOB, SFDR, SNR
function [SNDR, ENOB, SFDR, SNR] = analyze_signal(freq, f2_dB, p_spect, fs, N, remove_idx, span)
    % 找到信号基波峰值
    [~, max_f] = max(p_spect);
    left = max(1, max_f - span/2);
    right = min(length(p_spect), max_f + span/2);
    Ps = sum(p_spect(left : right));          % 信号功率
    P = sum(p_spect);                          % 总功率

    % SNDR 和 ENOB
    SNDR = 10 * log10(Ps / (P - Ps));
    ENOB = (SNDR - 1.76) / 6.02;

    % SFDR
    f2_dB_spur = f2_dB;
    f2_dB_spur(left : right) = -Inf;
    max_spur_dB = max(f2_dB_spur);
    if isinf(max_spur_dB)
        max_spur_dB = -Inf;
    end
    SFDR = f2_dB(max_f) - max_spur_dB;

    % SNR（剔除信号及谐波）
    f_signal = freq(max_f);
    df = fs / N;                               % 频率分辨率
    P_harm = 0;
    harm_order = 2;
    while true
        f_harm = harm_order * f_signal;
        if f_harm > freq(end)                  % 只考虑当前频带内的谐波
            break;
        end
        % 在原始完整谱中的索引（含直流）
        idx_full = round(f_harm / df) + 1;
        % 在当前截断谱中的索引（已去除 remove_idx 个直流点）
        idx_curr = idx_full - remove_idx;
        if idx_curr >= 1 && idx_curr <= length(p_spect)
            left_h = max(1, idx_curr - span/2);
            right_h = min(length(p_spect), idx_curr + span/2);
            P_harm = P_harm + sum(p_spect(left_h : right_h));
        end
        harm_order = harm_order + 1;
    end
    P_noise = P - Ps - P_harm;
    if P_noise <= 0
        P_noise = eps;
    end
    SNR = 10 * log10(Ps / P_noise);
end
function [SNDR, ENOB, SFDR, SNR] = SNR_ADC(Vout, fs, waveplot)
    % 输入：
    %   Vout    - ADC 输出的量化离散信号（向量）
    %   fs      - 采样频率 (Hz)
    %   waveplot- 是否绘制频谱图 (1 绘制，0 不绘制)
    % 输出：
    %   SNDR    - 信噪失真比 (dB)
    %   ENOB    - 有效位数 (bit)
    %   SFDR    - 无杂散动态范围 (dB)
    %   SNR     - 信噪比 (dB)

    span = 50;  % 用于确定信号主峰附近的带宽（点数）

    % 选择 2 的幂次长度进行 FFT（取信号末尾部分）
    fft_ord = floor(log(length(Vout)) / log(2));
    N = 2^fft_ord;                          % FFT 点数
    wave_out = Vout(end - N + 1 : end);      % 取末尾 N 个点（稳态部分）
    wave_out = wave_out(:) .* hanning(N);    % 加汉宁窗，并确保为列向量

    % --- 修正的单边幅度谱计算 ---
    fft_out = fft(wave_out);                 % 做 FFT
    amp_bilateral = abs(fft_out) / N;        % 双边幅度谱

    if mod(N, 2) == 0                        % N 为偶数（通常情况）
        amp_single = amp_bilateral(1 : N/2 + 1);   % 包含 0 和 Nyquist 频率
        amp_single(2 : end-1) = 2 * amp_single(2 : end-1);  % 中间频率乘以 2
    else                                      % N 为奇数
        amp_single = amp_bilateral(1 : (N+1)/2);
        amp_single(2 : end) = 2 * amp_single(2 : end);      % 除直流外均乘 2
    end
    f2 = amp_single;                          % 正确的单边幅度谱

    % --- 频率轴 (0 ~ fs/2) ---
    freq = linspace(0, fs/2, length(f2));

    % --- 去除直流及附近低频分量 (前 span/2 个点) ---
    remove_idx = span/2;
    f2 = f2(remove_idx+1 : end);
    freq = freq(remove_idx+1 : end);

    % --- 转换为 dB 并可选绘图 ---
    f2_dB = 20 * log10(f2);
    % if waveplot == 1
    %     plot(freq, f2_dB);
    %     xlabel('Frequency (Hz)');
    %     ylabel('Magnitude (dB)');
    %     grid on;
    % end
    if waveplot == 1
    figure(2);
    set(gcf, 'Renderer', 'painters');    % 强制向量渲染
    set(gcf, 'Color', 'white');          % 背景设为白色
    plot(freq, f2_dB, 'b');              % 线性坐标
    xlabel('Frequency (Hz)');
    ylabel('Magnitude (dB)');
    title('全频带频谱 (0 - fs/2)', 'FontName', 'SimHei');
    grid on;
    % 输出向量图：保存 EMF + 复制到剪贴板
    exportgraphics(gcf, 'spectrum.emf', 'ContentType', 'vector');
    copygraphics(gcf, 'ContentType', 'vector');
end

    % --- 功率谱 (单边) ---
    p_spect = f2.^2;                          % 每个频点的功率

    % --- 找到信号基波峰值 (最大功率点) ---
    [~, max_f] = max(p_spect);                % max_f 是当前截断谱中的索引

    % 计算信号功率 Ps (基波附近 span 个点)
    left = max(1, max_f - span/2);
    right = min(length(p_spect), max_f + span/2);
    Ps = sum(p_spect(left : right));

    % 总功率 P
    P = sum(p_spect);

    % --- SNDR 和 ENOB ---
    SNDR = 10 * log10(Ps / (P - Ps));
    ENOB = (SNDR - 1.76) / 6.02;

    % --- SFDR 计算 ---
    % 将基波附近 span 个点置为 -Inf，然后找剩余部分的最大峰值
    f2_dB_spur = f2_dB;
    f2_dB_spur(left : right) = -Inf;          % 屏蔽基波区域
    max_spur_dB = max(f2_dB_spur);             % 最大杂散幅度 (dB)
    if isinf(max_spur_dB)
        max_spur_dB = -Inf;                    % 无杂散时设为 -Inf
    end
    SFDR = f2_dB(max_f) - max_spur_dB;         % 基波 dB - 最大杂散 dB

    % --- SNR 计算 (需剔除信号及谐波) ---
    % 获取信号频率 (当前谱中的频率值)
    f_signal = freq(max_f);

    % 原始完整谱的参数 (用于谐波索引计算)
    L_full = length(amp_single);                % 原始单边谱长度 (含直流)
    df = fs / N;                                 % 频率分辨率 (Hz)
    % 当前谱的第一个点对应原始完整谱的索引 remove_idx+1

    % 初始化谐波功率
    P_harm = 0;

    % 生成谐波频率 (2 次及以上，不超过 fs/2)
    harm_order = 2;
    while true
        f_harm = harm_order * f_signal;
        if f_harm > fs/2
            break;
        end

        % 在原始完整谱中的索引 (1-based)
        idx_full = round(f_harm / df) + 1;       % 因为 freq_full(1)=0 Hz

        % 在当前截断谱中的索引
        idx_curr = idx_full - remove_idx;

        % 检查索引是否有效
        if idx_curr >= 1 && idx_curr <= length(p_spect)
            % 取该谐波附近 span 个点的功率
            left_h = max(1, idx_curr - span/2);
            right_h = min(length(p_spect), idx_curr + span/2);
            P_harm = P_harm + sum(p_spect(left_h : right_h));
        end

        harm_order = harm_order + 1;
    end

    % 噪声功率 = 总功率 - 信号功率 - 谐波功率
    P_noise = P - Ps - P_harm;
    if P_noise <= 0
        P_noise = eps;   % 避免负值或零，取极小值
    end
    SNR = 10 * log10(Ps / P_noise);

end
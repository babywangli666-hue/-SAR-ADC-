function [full_SNDR, full_ENOB, full_SFDR, full_SNR, ...
          band_SNDR, band_ENOB, band_SFDR, band_SNR] = SNR_ADC(Vout, fs, cutoff_freq, waveplot)
    % 输入：
    %   Vout         - ADC 输出的量化离散信号（向量）
    %   fs           - 采样频率 (Hz)
    %   cutoff_freq  - 限带截止频率 (Hz)，用于截取 0~cutoff_freq 的频谱
    %   waveplot     - 是否绘制频谱图 (1 绘制，0 不绘制)
    % 输出：
    %   full_*       - 全频带（0 ~ fs/2）的指标
    %   band_*       - 限带（0 ~ cutoff_freq）的指标

    span = 50;  % 信号主峰附近带宽（点数）

    % 选择 2 的幂次长度进行 FFT（取信号末尾部分）
    fft_ord = floor(log(length(Vout)) / log(2));
    N = 2^fft_ord;
    wave_out = Vout(end - N + 1 : end);      % 取末尾 N 个点（稳态部分）
    wave_out = wave_out(:) .* hanning(N);    % 加汉宁窗

    % --- 修正的单边幅度谱计算 ---
    fft_out = fft(wave_out);
    amp_bilateral = abs(fft_out) / N;

    if mod(N, 2) == 0
        amp_single = amp_bilateral(1 : N/2 + 1);
        amp_single(2 : end-1) = 2 * amp_single(2 : end-1);
    else
        amp_single = amp_bilateral(1 : (N+1)/2);
        amp_single(2 : end) = 2 * amp_single(2 : end);
    end
    f2_full = amp_single;                    % 全频带单边幅度谱

    % --- 全频带频率轴 (0 ~ fs/2) ---
    freq_full = linspace(0, fs/2, length(f2_full));

    % --- 去除直流及附近低频分量 (前 span/2 个点) ---
    remove_idx = span/2;
    f2_full = f2_full(remove_idx+1 : end);
    freq_full = freq_full(remove_idx+1 : end);
    f2_dB_full = 20 * log10(f2_full);
    p_spect_full = f2_full.^2;                % 全频带功率谱

    % --- 限带截取 (0 ~ cutoff_freq) ---
    % 找到截止频率对应的最大索引
    idx_cut = find(freq_full <= cutoff_freq, 1, 'last');
    if isempty(idx_cut)
        error('截止频率过低，频带内无有效数据。');
    end
    f2_band = f2_full(1:idx_cut);
    freq_band = freq_full(1:idx_cut);
    f2_dB_band = f2_dB_full(1:idx_cut);
    p_spect_band = p_spect_full(1:idx_cut);

    % --- 分别计算两个版本的指标 ---
    [full_SNDR, full_ENOB, full_SFDR, full_SNR] = analyze_signal(...
        freq_full, f2_dB_full, p_spect_full, fs, N, remove_idx, span);
    [band_SNDR, band_ENOB, band_SFDR, band_SNR] = analyze_signal(...
        freq_band, f2_dB_band, p_spect_band, fs, N, remove_idx, span);

%  % --- 可选绘图：只绘制全频带频谱（对数横坐标） ---
%     if waveplot == 1
%         figure;
%         semilogx(freq_full, f2_dB_full, 'b');   % 对数横坐标
%         xlabel('Frequency (Hz)'); ylabel('Magnitude (dB)');
%         title('全频带频谱 (0 ~ fs/2)');
%         grid on;
%         % 标注信号峰值
%         [~, max_f_full] = max(p_spect_full);
%         hold on;
%         semilogx(freq_full(max_f_full), f2_dB_full(max_f_full), 'ro', 'MarkerSize', 8);
%         hold off;
%     end
% end
% --- 可选绘图：只绘制全频带频谱（对数横坐标） ---
if waveplot == 1
    figure;
    set(gcf, 'Renderer', 'painters');       % 可选，保险设置
    semilogx(freq_full, f2_dB_full, 'b');
    xlabel('Frequency (Hz)'); ylabel('Magnitude (dB)');
    title('全频带频谱 (0 ~ fs/2)');
    grid on;
    [~, max_f_full] = max(p_spect_full);
    hold on;
    semilogx(freq_full(max_f_full), f2_dB_full(max_f_full), 'ro', 'MarkerSize', 8);
    hold off;
    % 复制向量图到剪贴板
    copygraphics(gcf, 'ContentType', 'vector');
end
end

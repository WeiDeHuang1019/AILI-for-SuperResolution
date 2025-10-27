function [ssimVal, ssimMap] = SSIMcalc(Iref, Itst, peak, opts)
% SSIM_CALC  計算影像的 SSIM（支援灰階/RGB；可回傳 SSIM map）.
%
% 用法：
%   ssimVal                 = ssim_calc(Iref, Itst)
%   [ssimVal, ssimMap]      = ssim_calc(Iref, Itst)
%   ssimVal                 = ssim_calc(Iref, Itst, peak)
%   [ssimVal, ssimMap]      = ssim_calc(Iref, Itst, peak, opts)
%
% 參數：
%   - Iref, Itst：參考/待測影像（H×W 或 H×W×C），型別可為 uint8/uint16/single/double
%   - peak（選）：最大像素值；預設依型別推斷：uint8→255、uint16→65535、浮點→1
%   - opts（選）：結構設定
%       opts.winSize  (預設 11)    高斯視窗大小（奇數）
%       opts.sigma    (預設 1.5)   高斯標準差
%       opts.K1       (預設 0.01)  SSIM 參數
%       opts.K2       (預設 0.03)  SSIM 參數
%
% 回傳：
%   - ssimVal：整體 SSIM（平均）
%   - ssimMap：每像素 SSIM（若輸入是彩色，為各通道 SSIM map 的平均）

    arguments
        Iref
        Itst
        peak double {mustBePositive} = []
        opts.winSize (1,1) double {mustBeInteger,mustBePositive} = 11
        opts.sigma   (1,1) double {mustBePositive} = 1.5
        opts.K1      (1,1) double {mustBeNonnegative} = 0.01
        opts.K2      (1,1) double {mustBeNonnegative} = 0.03
    end

    % ----- 檢查與預設 -----
    if ~isequal(size(Iref), size(Itst))
        error('Iref 與 Itst 尺寸/通道數必須一致。');
    end
    if ndims(Iref) > 3
        error('僅支援灰階或 RGB（最多 3 維）。');
    end

    if isempty(peak)
        if isa(Iref,'uint8') || isa(Itst,'uint8')
            peak = 255;
        elseif isa(Iref,'uint16') || isa(Itst,'uint16')
            peak = 65535;
        else
            peak = 1.0;  % 浮點預設視為 0~1
        end
    end
    L  = peak;
    C1 = (opts.K1 * L)^2;
    C2 = (opts.K2 * L)^2;

    % 轉 double
    A = double(Iref);
    B = double(Itst);

    % 高斯視窗（2D）
    W = localGaussian2D(opts.winSize, opts.sigma);

    % ----- 計算 -----
    if size(A,3) == 1
        [ssimVal, ssimMap] = localSSIMsingle(A, B, W, C1, C2);
    else
        C = size(A,3);
        maps = zeros(size(A,1), size(A,2), C);
        vals = zeros(1, C);
        for c = 1:C
            [vals(c), maps(:,:,c)] = localSSIMsingle(A(:,:,c), B(:,:,c), W, C1, C2);
        end
        ssimVal = mean(vals);
        ssimMap = mean(maps, 3);
    end
end

% ====== 子函式們 ======

function [val, S] = localSSIMsingle(X, Y, W, C1, C2)
    muX = conv2(X, W, 'same');
    muY = conv2(Y, W, 'same');

    muX2 = muX.^2;      muY2 = muY.^2;      muXY = muX .* muY;
    sigmaX2 = conv2(X.^2, W, 'same') - muX2;
    sigmaY2 = conv2(Y.^2, W, 'same') - muY2;
    sigmaXY = conv2(X.*Y, W, 'same') - muXY;

    num = (2*muXY + C1) .* (2*sigmaXY + C2);
    den = (muX2 + muY2 + C1) .* (sigmaX2 + sigmaY2 + C2);
    S   = num ./ den;

    val = mean(S(~isnan(S)), 'omitnan');
end

function W = localGaussian2D(winSize, sigma)
    if mod(winSize,2) == 0
        error('opts.winSize 必須為奇數。');
    end
    r = (winSize-1)/2;
    x = -r:r;
    g = exp(-(x.^2)/(2*sigma^2));
    W = (g(:) * g(:)');      % 2D
    W = W / sum(W(:));       % 正規化
end


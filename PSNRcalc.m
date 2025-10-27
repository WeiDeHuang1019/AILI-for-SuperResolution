function [psnrVal, mseVal] = PSNRcalc(Iref, Itst, peak)
% PSNR_CALC  計算影像之間的 PSNR（支援灰階/RGB、uint8/uint16/single/double）.
%
% 用法：
%   psnrVal = psnr_calc(Iref, Itst)
%   [psnrVal, mseVal] = psnr_calc(Iref, Itst)
%   psnrVal = psnr_calc(Iref, Itst, peak)   % 自訂峰值（例如 255 或 1）
%
% 說明：
%   - Iref：參考影像（H×W 或 H×W×C）
%   - Itst：待測影像（尺寸/通道必須與 Iref 相同）
%   - peak：最大可能像素值（預設依型別推斷：uint8→255、uint16→65535、浮點→1）
%   - 回傳：
%       psnrVal：PSNR（dB）
%       mseVal ：MSE
%
% 注意：
%   - 若兩影像完全相同，MSE=0 → PSNR = Inf
%   - 若影像是浮點且不是 0~1 範圍，請自行指定 peak 以避免誤判

    arguments
        Iref
        Itst
        peak double {mustBePositive} = []
    end

    % 檢查尺寸
    if ~isequal(size(Iref), size(Itst))
        error('Iref 與 Itst 尺寸/通道數不一致。');
    end

    % 依型別決定預設峰值
    if isempty(peak)
        if isa(Iref,'uint8') || isa(Itst,'uint8')
            peak = 255;
        elseif isa(Iref,'uint16') || isa(Itst,'uint16')
            peak = 65535;
        elseif isfloat(Iref) || isfloat(Itst)
            % 預設視為已正規化影像
            peak = 1.0;
        else
            error('不支援的資料型別，請改為 uint8/uint16/float，或自行指定 peak。');
        end
    end

    % 轉 double 計算
    A = double(Iref);
    B = double(Itst);

    % MSE（對所有像素/通道平均）
    diff  = A - B;
    mseVal = mean(diff(:).^2, 'omitnan');

    if mseVal == 0
        psnrVal = Inf;
    else
        psnrVal = 10 * log10((peak^2) / mseVal);
    end
end





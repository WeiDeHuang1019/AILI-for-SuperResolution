function [Iref_c, Itst_c, shave] = Shave_calc(Iref, Itst, candidates)
% Shave_calc  在計算指標前裁掉邊界像素（避免 padding 影響）
% 用法：
%   [Iref_c, Itst_c, shave] = Shave_calc(Iref, Itst)
%   [Iref_c, Itst_c, shave] = Shave_calc(Iref, Itst, [2 3 4])  % 自訂候選倍率
%
% 規則：
% - 以常見放大倍率 {2,3,4} 嘗試；挑選同時整除 H 與 W 的第一個作為 shave 值
% - 若找不到合適倍率，或影像太小，則不裁（shave=0）
% - 回傳裁切後的 Iref_c / Itst_c（RGB）

    if nargin < 3
        candidates = [2 3 4];
    end

    % 轉 double，保證 3 通道
    %Iref = im2double(Iref);  if size(Iref,3)~=3,  Iref = repmat(Iref,1,1,3); end
    %Itst = im2double(Itst);  if size(Itst,3)~=3,  Itst = repmat(Itst,1,1,3); end

    % 尺寸對齊（保險）
    if any(size(Iref,1:2) ~= size(Itst,1:2))
        Itst = imresize(Itst, [size(Iref,1) size(Iref,2)], 'bicubic');
    end

    [H, W, ~] = size(Iref);

    % 自動推斷 shave（偏好 2/3/4）
    shave = 0;
    for s = candidates
        if mod(H, s)==0 && mod(W, s)==0
            shave = s;
            break;
        end
    end

    % 邊界裁切
    if shave > 0 && H > 2*shave && W > 2*shave
        Iref_c = Iref(1+shave : end-shave, 1+shave : end-shave, :);
        Itst_c = Itst(1+shave : end-shave, 1+shave : end-shave, :);
    else
        % 不裁
        shave  = 0;
        Iref_c = Iref;
        Itst_c = Itst;
    end
end

function out = AILI_pipeline(z, newH, newW)
% AILI 2D interpolation (RGB/Gray both supported)
% z: input image (H×W or H×W×3), any numeric
% out: newH × newW (gray) or newH × newW × 3 (RGB), double in [0,1]

    z = im2double(z);

    % --- RGB 支援：偵測 3 通道就逐通道處理 ---
    if ndims(z) == 3 && size(z,3) == 3
        out = zeros(newH, newW, 3);
        for c = 1:3
            out(:,:,c) = AILI_single(z(:,:,c), newH, newW);
        end
    else
        out = AILI_single(z, newH, newW);
    end
end

% ===== 單通道核心（你的原始演算法，僅修正 xi/yi 的 step 用法） =====
function out = AILI_single(z, newH, newW)
    [H, W] = size(z);
    out = zeros(newH, newW);

    % 複製邊界填充（上下左右各 +2）
    zp = padarray(z, [2 2], 'replicate', 'both');

    % 映射：輸出像素中心 -> 原圖連續座標
    stepx = W / newW;   % ← x 方向步長（寬度 / 新寬度）
    stepy = H / newH;   % ← y 方向步長（高度 / 新高度）

    for i = 1:newH
        yi = (i - 0.5) * stepy + 0.5;   % ← 用 stepy（行）
        for j = 1:newW
            xi = (j - 0.5) * stepx + 0.5; % ← 用 stepx（列）

            % ---- 以下保留你的內插流程 ----
            fxf = floor(xi);  fyf = floor(yi);
            xidx = (fxf-1) + (0:3);
            yidx = (fyf-1) + (0:3);
            f = zp(yidx+2, xidx+2);

            xc = ceil(xi);     yc = ceil(yi);
            xf = floor(xi);    yf = floor(yi);

            yi_Is_At_Left = (yc - yi) < (yi - yf);

            if yi_Is_At_Left
                yp = yi - yc;
                yM = -0.15; yN = 1.175; yH = yp + 1;
                Vc1 = f(3,1); Vc2 = f(3,2); Vc3 = f(3,3); Vc4 = f(3,4);
            else
                yp = yi - yf;
                yM = 1.175; yN = -0.15; yH = yp - 1;
                Vc1 = f(2,1); Vc2 = f(2,2); Vc3 = f(2,3); Vc4 = f(2,4);
            end

            DxVc12 = Vc2 - Vc1; DxVc23 = Vc3 - Vc2; DxVc34 = Vc4 - Vc3;

            A1 = f(2,1) - f(1,1);  B1 = f(3,1) - f(2,1);  C1 = f(4,1) - f(3,1);
            A2 = f(2,2) - f(1,2);  B2 = f(3,2) - f(2,2);  C2 = f(4,2) - f(3,2);
            A3 = f(2,3) - f(1,3);  B3 = f(3,3) - f(2,3);  C3 = f(4,3) - f(3,3);
            A4 = f(2,4) - f(1,4);  B4 = f(3,4) - f(2,4);  C4 = f(4,4) - f(3,4);

            Dx2VcL = DxVc23 - DxVc12;  Dx2VcR = DxVc34 - DxVc23;

            D1 = B1 - A1;  E1 = C1 - B1;
            D2 = B2 - A2;  E2 = C2 - B2;
            D3 = B3 - A3;  E3 = C3 - B3;
            D4 = B4 - A4;  E4 = C4 - B4;

            Bx1 = B2 - B1;  Bx2 = B3 - B2;  Bx3 = B4 - B3;
            Ex1 = E2 - E1;  Ex2 = E3 - E2;  Ex3 = E4 - E3;
            Dx1 = D2 - D1;  Dx2 = D3 - D2;  Dx3 = D4 - D3;

            V2tmp0  = yM * D2  + yN * E2;

            BxL = Bx2 - Bx1;   BxR = Bx3 - Bx2;
            ExL = Ex2 - Ex1;   ExR = Ex3 - Ex2;
            DxL = Dx2 - Dx1;   DxR = Dx3 - Dx2;

            Bxtmp0 = yM * Dx2 + yN * Ex2;
            Dxtmp0 = yM * DxL + yN * ExL;
            Extmp0 = yM * DxR + yN * ExR;

            V2tmp1 = B2   + V2tmp0  * (yH/2);
            Bxtmp1 = Bx2  + Bxtmp0  * (yH/2);
            Dxtmp1 = BxL  + Dxtmp0  * (yH/2);
            Extmp1 = BxR  + Extmp0  * (yH/2);

            V2 = Vc2      + V2tmp1 * yp;
            Bx = DxVc23   + Bxtmp1 * yp;
            Dx = Dx2VcL   + Dxtmp1 * yp;
            Ex = Dx2VcR   + Extmp1 * yp;

            xi_Is_At_Left = (xc - xi) < (xi - xf);
            if xi_Is_At_Left
                xp = xi - xc;  xM = -0.15; xN = 1.175; xH = xp + 1;
                hC = V2 + Bx;
            else
                xp = xi - xf;  xM = 1.175;  xN = -0.15; xH = xp - 1;
                hC = V2;
            end

            Qx = xM * Dx + xN * Ex;
            qx = Qx * (xH/2) + Bx;
            fh = hC + xp * qx;
            out(i,j) = fh;
        end
    end
end

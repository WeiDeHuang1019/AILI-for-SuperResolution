% 自動評估資料夾（GTmod12 / LRbicx2 / LRbicx3 / LRbicx4）
% 需要：AILI_pipeline.m、PSNRcalc.m、SSIMcalc.m、FSIMcalc.m 在 path 上
% 說明：
%   - PSNR/SSIM/FSIM：全部直接以 RGB 三通道計算（不轉灰階）

close all;home;clc;clear;

%% 路徑設定
baseDir = 'C:\Users\F114112124\Desktop\Image_Super_Resolution\Classical\Set5'; %加入dataset目錄路徑*(Set5或Set14)
gtDir   = fullfile(baseDir, 'GTmod12'); %此為compare_img所在目錄

doShave = true; % 是否(true or false)進行邊界裁切 (Shave/crop)
RGBtoY = true; % 是否做RGB to Y

%以下設定個別input_img目錄以及對應的縮放倍率
lrInfo = { ...
    'LRbicx2', 2; ...
    'LRbicx3', 3; ...
    'LRbicx4', 4; ...
};

% 支援的副檔名
exts = {'*.png','*.jpg','*.jpeg','*.bmp','*.tif','*.tiff'};

%% 取得 GT 檔案清單（以 GT 為基準對齊）
gtFiles = [];
for k = 1:numel(exts)
    gtFiles = [gtFiles; dir(fullfile(gtDir, exts{k}))]; %#ok<AGROW>
end
if isempty(gtFiles)
    error('在 %s 找不到任何影像檔。', gtDir);
end

%% 工具：讀彩色且轉 double[0,1]
to_color_double = @(im) im2double(im);

%% 主流程：逐張 GT，對應各 scale 評估（全部用 RGB）
Image  = {};
Scale  = [];
PSNR_v = [];
SSIM_v = [];
FSIM_v = [];

for i = 1:numel(gtFiles)
    [~, baseName, ~] = fileparts(gtFiles(i).name);

    % 讀 GT（RGB）
    gtPath = find_one_by_basename(gtDir, baseName);
    if isempty(gtPath)
        warning('找不到 GT：%s，略過。', baseName);
        continue;
    end
    gtColor = to_color_double(imread(gtPath));         % RGB
    if size(gtColor,3) ~= 3, gtColor = repmat(gtColor,1,1,3); end  % 保險：若是灰階，擴為 3 通道
    Hgt = size(gtColor,1);
    Wgt = size(gtColor,2);

    % 針對 x2/x3/x4
    for li = 1:size(lrInfo,1)
        lrSub  = lrInfo{li,1};
        scale  = lrInfo{li,2};
        lrDir  = fullfile(baseDir, lrSub);

        lrPath = find_one_by_basename(lrDir, baseName);
        if isempty(lrPath)
            warning('找不到 %s 於 %s，略過該項。', baseName, lrSub);
            continue;
        end

        % 讀 LR（RGB）
        lrColor = to_color_double(imread(lrPath));
        if size(lrColor,3) ~= 3, lrColor = repmat(lrColor,1,1,3); end

        % 以 GT 尺寸為目標，跑 AILI（支援 RGB/Gray）
        scaledColor = AILI_pipeline(lrColor, Hgt, Wgt);
        %scaledColor = imresize(lrColor, scale, 'bicubic');
        % 是否做RGB to Y
        if RGBtoY
            gtEval = RGB2YIQ(gtColor);
            srEval = RGB2YIQ(scaledColor);
        else
            gtEval = gtColor;
            srEval = scaledColor;
        end
        gtUnit8 = im2uint8(gtEval);    % 0–255, uint8
        srUnit8 = im2uint8(srEval);

        % 做邊界像素的shave
        if doShave 
            [gtUnit8, srUnit8, used_shave] = Shave_calc(gtUnit8, srUnit8, scale);
        end

        % 尺寸保險（若 AILI 回傳尺寸與 GT 略有差異）
        %if size(scaledColor,1) ~= Hgt || size(scaledColor,2) ~= Wgt
        %    scaledColor = imresize(scaledColor, [Hgt, Wgt], 'bicubic');
        %end

        % 通道保險
        %if size(srEval,3) ~= 3
        %    srEval = repmat(srEval,1,1,3);
        %end

        % ===== 指標（全部以 RGB 計算） =====
        psnr_val = PSNRcalc(gtUnit8,  srUnit8);   % RGB
        ssim_val = SSIMcalc(gtUnit8,  srUnit8);   % RGB
        fsim_val = FSIMcalc(gtUnit8,  srUnit8);   % RGB

        % 累積
        Image{end+1,1} = baseName; %#ok<SAGROW>
        Scale(end+1,1) = scale;    %#ok<SAGROW>
        PSNR_v(end+1,1)= psnr_val; %#ok<SAGROW>
        SSIM_v(end+1,1)= ssim_val; %#ok<SAGROW>
        FSIM_v(end+1,1)= fsim_val; %#ok<SAGROW>
    end
end

% 建立 per-image 表（含 fsim）
T = table(Image, Scale, PSNR_v, SSIM_v, FSIM_v, ...
    'VariableNames', {'image','scale','psnr','ssim','fsim'});

% 依 scale 輸出平均表（含 fsim_mean）
scales = unique(T.scale);
SumImage = {};
SumScale = [];
MeanPSNR = [];
MeanSSIM = [];
MeanFSIM = [];
for s = reshape(scales,1,[])
    idx = (T.scale == s);
    SumImage{end+1,1} = '[MEAN]'; %#ok<SAGROW>
    SumScale(end+1,1) = s;        %#ok<SAGROW>
    MeanPSNR(end+1,1) = mean(T.psnr(idx)); %#ok<SAGROW>
    MeanSSIM(end+1,1) = mean(T.ssim(idx)); %#ok<SAGROW>
    MeanFSIM(end+1,1) = mean(T.fsim(idx)); %#ok<SAGROW>
end
TSum = table(SumImage, SumScale, MeanPSNR, MeanSSIM, MeanFSIM, ...
    'VariableNames', {'image','scale','psnr_mean','ssim_mean','fsim_mean'});

% 輸出 CSV（依 scale→image 排序）
T_sorted = sortrows(T, {'scale','image'});
perImageCsv_byScale = fullfile(baseDir, 'AILI_metrics_per_image.csv');
writetable(T_sorted, perImageCsv_byScale);

summaryCsv  = fullfile(baseDir, 'AILI_metrics_summary.csv');
writetable(TSum, summaryCsv);

fprintf('完成！\n- 逐圖(依Scale分組)：%s\n- 各Scale平均：%s\n', ...
        perImageCsv_byScale, summaryCsv);

%% === 內部小工具：依 basename 找檔 ===
function fpath = find_one_by_basename(folder, basename)
    exts = {'*.png','*.jpg','*.jpeg','*.bmp','*.tif','*.tiff'};
    fpath = '';
    % 先嘗試「任何副檔名」
    list = dir(fullfile(folder, [basename '.*']));
    if ~isempty(list)
        fpath = fullfile(list(1).folder, list(1).name);
        return;
    end
    % 再逐一副檔名嘗試
    for k = 1:numel(exts)
        cand = dir(fullfile(folder, [basename exts{k}(2:end)])); % 例如 basename + '.png'
        if ~isempty(cand)
            fpath = fullfile(cand(1).folder, cand(1).name);
            return;
        end
    end
end

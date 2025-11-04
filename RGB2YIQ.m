function [Y, I, Q] = RGB2YIQ(imgRGB)
% RGB2YIQ - Convert an RGB image to YIQ color space
%
%   [Y, I, Q] = RGB2YIQ(imgRGB)
%
% Input:
%   imgRGB : RGB image, size H×W×3, can be uint8 or double
%             (if double, assumed range 0–1 or 0–255 都可)
%
% Output:
%   Y : luminance component
%   I : in-phase chrominance component
%   Q : quadrature chrominance component
%
% Reference:
%   YIQ transform used in NTSC television and FSIM color extension.
%   Y = 0.299R + 0.587G + 0.114B
%   I = 0.596R - 0.274G - 0.322B
%   Q = 0.211R - 0.523G + 0.312B
%
% Example:
%   rgb = imread('peppers.png');
%   [Y,I,Q] = RGB2YIQ(rgb);
%   figure; imshow(Y,[]); title('Y channel');
%
%
% -------------------------------------------------------------------------

% 確保輸入為 double
imgRGB = double(imgRGB);

% 拆出通道
R = imgRGB(:,:,1);
G = imgRGB(:,:,2);
B = imgRGB(:,:,3);

% RGB → YIQ 轉換公式
Y = 0.299 * R + 0.587 * G + 0.114 * B;
I = 0.596 * R - 0.274 * G - 0.322 * B;
Q = 0.211 * R - 0.523 * G + 0.312 * B;

end

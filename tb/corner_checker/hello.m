b=imread('image.bmp'); % 24-bit BMP image RGB888

k=1;

[rows, cols, _] = size(b)

for i=rows:-1:1
  for j=1:cols
    [c(i,j,1),c(i,j,2),c(i,j,3)] = deal(uint8(0.299 * b(i,j,1) + 0.587 * b(i,j,2) + 0.114 * b(i,j,3)));
    a(k)=c(i,j,1);
    k=k+1;
  endfor
endfor


imshow(c);

fid = fopen('image.bin', 'wt');
##fprintf(fid, '%x\n', a);
fwrite(fid, a, 'uint8')
disp('Text file write done');disp(' ');
fclose(fid);

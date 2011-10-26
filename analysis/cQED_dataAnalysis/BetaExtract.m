function b = BetaExtract(stomodat)

id = sum(stomodat(1:4))/4; %II
pi1 = sum(stomodat(5:8))/4; %ZI
pi2 = sum(stomodat(9:12))/4; %IZ
pipi = sum(stomodat(13:16))/4; %ZZ

m = [id; pi1; pi2; pipi];
%m = [0; pi1-id; pi2-id; pipi-id];
A = [1 1 1 1; 1 -1 1 -1; 1 1 -1 -1;1 -1 -1 1];

b = A\m;

%smallm = [pi1-id; pi2-id; pipi-id];

%smallA = [-1 1 -1; 1 -1 -1; -1 -1 1];
%b = smallA\smallm;
%maxb = max(abs(b));
%b = b/maxb;

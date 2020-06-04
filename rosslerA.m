function dx = rosslerA(t,x)
    dx = zeros(4,1);
    dx(1) = - x(2) - x(3);
    dx(2) = x(1) + 0.25*x(2) + x(4);
    dx(3) = x(1)*x(3)+3;
    dx(4) = -0.5*x(3) + 0.05*x(4);
 end
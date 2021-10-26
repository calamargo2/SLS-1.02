// Numerical evaluation of integrals (quadrature).
// Q = quad(f,a,b) approximates the integral of f(x) from a to b to
// within a relative error of 1e-3. `f' is the name of the function
// that evaluates f(x). Function f must return a vector of output
// values if given a vector of input values. 
// q = quad(F,a,b,tol) integrates to a relative error of tol. 
// An error occurrs if an excessive recursion level is reached,
// indicating a possibly singular integral.  
// q = quad(F,a,b,tol) integrates to a relative error of tol
// quad() uses an adaptive recursive Simpson's rule.

quad = function(func, a, b, tol) 
{
  local(c, cnt, fa, fb, fc, lev, q, x, y);

  if(tol == 0) { tol = 1.e-3; }

  c = (a + b)/2;

  // Top level initialization

  x = [ a, b, c, (a:b:(b-a)/10) ];
  y = func(x);  // Evaluate caller's function
  fa = y[1];    // func() evaluated at a, b, c
  fb = y[2];
  fc = y[3];
  lev = 1;

  // Adaptive, recursive Simpson's quadrature
  q = quadstp(func, a, b, tol, lev, fa, fc, fb, 0);
  cnt = q.cnt + 3;

  return << q=q.Q; cnt=cnt >>;
};

// quadstp() Recursive function used by quad(F,a,b,tol).

// q = quadstp(F,a,b,tol,lev,fa,fc,fb,Q0) tries to approximate
// the integral of f(x) from a to b to within a relative error of tol.
// F is the name of the function that evaluated f(x). The remaining
// arguments are generated by quad or by the recursion.  lev is the
// recursion level. 
// fa = f(a). fc = f((a+b)/2). fb = f(b).
// Q0 is an approximate value of the integral.

quadstp = function(func, a, b, tol, lev, fa, fc, fb, Q0) 
{
  local(c, cnt, f, h, L1, L2, x, LEVMAX, Q);

  LEVMAX = 10;
  if(lev > LEVMAX) {
    error("Recursion level limit reached in quad. Singularity likely");
  else
    h = b - a;
    c = (a + b)/2;
    x = [ (a+h/4), (b-h/4) ];
    f = func(x);
    
    cnt = 2;
    
    // Simpson's rule for half intervals.
    L1.Q = h*(fa + 4*f[1] + fc)/12;
    L2.Q = h*(fc + 4*f[2] + fb)/12;
    Q = L1.Q + L2.Q;
   
    // Recursively refine approximations.
    if(abs(Q - Q0) > tol*abs(Q)) {
      L1 = quadstp(func, a, c, tol/2, lev+1, fa, f[1], fc, L1.Q);
      L2 = quadstp(func, c, b, tol/2, lev+1, fc, f[2], fb, L2.Q);
      Q = L1.Q + L2.Q;
      cnt = cnt + L1.cnt + L2.cnt;
    }
  }
  return << Q=Q; cnt=cnt >>;
};

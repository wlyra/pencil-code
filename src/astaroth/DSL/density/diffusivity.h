//if (ldiff_hyper3lnrho){
//       rhs += diffrho_hyper3*del6(LNRHO)
//}
#if LSHOCK
//if (ldiff_shock){
//  if (ldensity_nolog){
            rhs += diffrho_shock * (value(SHOCK) * laplace(RHO) + dot(gradient(SHOCK),grho))
//  }
//  else
//  {
//            /*if (ldiffusion_nolog){ 
//              call dot_mn(p%gshock,p%grho,tmp)
//              rhs =  exp(-value(LNRHO)) * diffrho_shock * (value(SHOCK) * laplace(exp(LNRHO)) + dot(gradient(SHOCK),glnrho))
//  	}else
//  */        rhs += diffrho_shock * (value(SHOCK) * (laplace(LNRHO) + norm2(glnrho)) + dot(gradient(SHOCK),glnrho))
//  }
//}
#endif

//checked 18.6.
  rhs = 0.
  rho1 = 0.
  lnrho = value(LNRHO)       // rho or lnrho
  grho = real3(0.,0.,0.)
  glnrho = gradient(LNRHO)   // grad(rho) or grad(lnrho) 
  
  if (ldensity_nolog){
    lnrho = log(value(RHO))
    rho1 =  1./value(RHO)
    grho = glnrho
    glnrho = grho*rho1
  }
  else
  {
    rho1 =  exp(-lnrho)
    grho = glnrho/rho1
  }
  cv1 = 1./cv
  lnTT = lnTT0+cv1*value(SS)+gamma_m1*(lnrho-lnrho0)
  TT = exp(lnTT)

  rhs +=  2. * nu * contract(stress_tensor(UU))
        + zeta * rho1 * divergence(UU) * divergence(UU)   // precalculated?

#if LMAGNETIC
  j = (gradient_of_divergence(AA) - veclaplace(AA))/mu0
  rhs += eta * mu0 * dot(j,j)*rho1
#endif

#if LINTERSTELLAR
  #include "../entropy/heatcool.h"
#endif

  rhs /= TT
  #include "../entropy/heat_cond_hyper3.h"
  return -dot(vecvalue(UU), gradient(SS)) + rhs //+ heat_conduction(step_num)

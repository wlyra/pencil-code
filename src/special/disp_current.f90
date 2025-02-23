! $Id$
!
!  Electric field, dE/dt = curlB, currently only for the special case
!  of no fluid induction.
!
!  25-feb-07/axel: adapted from nospecial.f90
!
!** AUTOMATIC CPARAM.INC GENERATION ****************************
! Declare (for generation of special_dummies.inc) the number of f array
! variables and auxiliary variables added by this module
!
! CPARAM logical, parameter :: lspecial = .true.
!
! MVAR CONTRIBUTION 4
! MAUX CONTRIBUTION 0
!
! PENCILS PROVIDED e2; edot2; el(3); a0; ga0(3); del2ee(3); curlE(3); BcurlE
! PENCILS PROVIDED rhoe, divJ, divE, gGamma(3); sigE, sigB; eb
! PENCILS EXPECTED infl_phi, infl_dphi, gphi(3)
!***************************************************************
!
module Special
!
  use Cparam
  use Cdata
  use General, only: keep_compiler_quiet
  use Messages
!
  implicit none
!
  include '../special.h'
!
! input parameters
!
  real :: ampl=1e-3, alpf=0.
  real :: ampl_ex=0.0, ampl_ey=0.0, ampl_ez=0.0, ampl_a0=0.0
  real :: kx_ex=0.0, kx_ey=0.0, kx_ez=0.0
  real :: ky_ex=0.0, ky_ey=0.0, ky_ez=0.0
  real :: kz_ex=0.0, kz_ey=0.0, kz_ez=0.0
  real :: kx_a0=0.0, ky_a0=0.0, kz_a0=0.0
  real :: phase_ex=0.0, phase_ey=0.0, phase_ez=0.0, phase_a0=0.0
  real :: amplee=0.0, initpower_ee=0.0, initpower2_ee=0.0
  real :: cutoff_ee=0.0, ncutoff_ee=0.0, kpeak_ee=0.0
  real :: relhel_ee=0.0, kgaussian_ee=0.0
  real :: ampla0=0.0, initpower_a0=0.0, initpower2_a0=0.0
  real :: cutoff_a0=0.0, ncutoff_a0=0.0, kpeak_a0=0.0
  real :: relhel_a0=0.0, kgaussian_a0=0.0, eta_ee=0.0
  real :: weight_longitudinalE=2.0
  logical :: luse_scale_factor_in_sigma=.false.
  real, pointer :: eta, ascale, Hscript, echarge, sigEm_all, sigBm_all
  integer :: iGamma=0, ia0=0, idiva_name=0, ieedot=0, iedotx=0, iedoty=0, iedotz=0
  logical :: llongitudinalE=.true., llorenz_gauge_disp=.false., lskip_projection_ee=.false.
  logical :: lscale_tobox=.true., lskip_projection_a0=.false.
  logical :: lvectorpotential=.false., lphi_hom=.false.
  logical :: lno_noise_ee=.false., lnoncollinear_EB=.false., lnoncollinear_EB_aver=.false.
  logical :: leedot_as_aux=.false., lcurlyA=.true., lsolve_chargedensity=.false.
  logical :: lswitch_off_divJ=.false., lswitch_off_Gamma=.false.
  character(len=50) :: initee='zero', inita0='zero'
!
  namelist /special_init_pars/ &
    initee, inita0, alpf, &
    ampl_ex, ampl_ey, ampl_ez, ampl_a0, &
    kx_ex, kx_ey, kx_ez, &
    ky_ex, ky_ey, ky_ez, &
    kz_ex, kz_ey, kz_ez, &
    kx_a0, ky_a0, kz_a0, &
    phase_ex, phase_ey, phase_ez, phase_a0, &
    llongitudinalE, llorenz_gauge_disp, lphi_hom, &
    amplee, initpower_ee, initpower2_ee, lscale_tobox, &
    cutoff_ee, ncutoff_ee, kpeak_ee, relhel_ee, kgaussian_ee, &
    ampla0, initpower_a0, initpower2_a0, lno_noise_ee, &
    cutoff_a0, ncutoff_a0, kpeak_a0, relhel_a0, kgaussian_a0, &
    leedot_as_aux, lsolve_chargedensity, &
    weight_longitudinalE
!
  ! run parameters
  real :: beta_inflation=0.
  namelist /special_run_pars/ &
    alpf, llongitudinalE, llorenz_gauge_disp, lphi_hom, &
    leedot_as_aux, eta_ee, lcurlyA, beta_inflation, &
    weight_longitudinalE, lswitch_off_divJ, lswitch_off_Gamma, &
    lnoncollinear_EB, lnoncollinear_EB_aver, luse_scale_factor_in_sigma
!
! Declare any index variables necessary for main or
!
  real :: c_light2
!
! other variables (needs to be consistent with reset list below)
!
  integer :: idiag_EEEM=0       ! DIAG_DOC: $\left<\Ev^2+\Bv^2\right>/2$
  integer :: idiag_erms=0       ! DIAG_DOC: $\left<\Ev^2\right>^{1/2}$
  integer :: idiag_edotrms=0    ! DIAG_DOC: $\left<\dot{\Ev}^2\right>^{1/2}$
  integer :: idiag_emax=0       ! DIAG_DOC: $\max(|\Ev|)$
  integer :: idiag_a0rms=0      ! DIAG_DOC: $\left<A_0^2\right>^{1/2}$
  integer :: idiag_grms=0       ! DIAG_DOC: $\left<C-\nabla\cdot\Av\right>^{1/2}$
  integer :: idiag_da0rms=0     ! DIAG_DOC: $\left<C-\nabla\cdot\Av\right>^{1/2}$
  integer :: idiag_BcurlEm=0    ! DIAG_DOC: $\left<\Bv\cdot\nabla\times\Ev\right>$
  integer :: idiag_divJrms=0    ! DIAG_DOC: $\left<\nab\Jv^2\right>^{1/2}$
  integer :: idiag_divErms=0    ! DIAG_DOC: $\left<\nab\Ev^2\right>^{1/2}$
  integer :: idiag_rhoerms=0    ! DIAG_DOC: $\left<\rho_e^2\right>^{1/2}$
  integer :: idiag_divJm=0      ! DIAG_DOC: $\left<\nab\Jv\right>$
  integer :: idiag_divEm=0      ! DIAG_DOC: $\left<\nab\Ev\right>$
  integer :: idiag_rhoem=0      ! DIAG_DOC: $\left<\rho_e\right>$
  integer :: idiag_mfpf=0       ! DIAG_DOC: $-f'/f$
  integer :: idiag_fppf=0       ! DIAG_DOC: $f''/f$
  integer :: idiag_afact=0      ! DIAG_DOC: $a$ (scale factor)
  integer :: idiag_constrainteqn=0  ! DIAG_DOC: $<deldotE+>$
  integer :: idiag_exm=0        ! DIAG_DOC: $\left<E_x\right>$
  integer :: idiag_eym=0        ! DIAG_DOC: $\left<E_y\right>$
  integer :: idiag_ezm=0        ! DIAG_DOC: $\left<E_z\right>$
  integer :: idiag_sigEm=0      ! DIAG_DOC: $\left<\sigma_\mathrm{E}\right>$
  integer :: idiag_sigBm=0      ! DIAG_DOC: $\left<\sigma_\mathrm{B}\right>$
  integer :: idiag_sigErms=0    ! DIAG_DOC: $\left<\sigma_\mathrm{E}^2\right>^{1/2}$
  integer :: idiag_sigBrms=0    ! DIAG_DOC: $\left<\sigma_\mathrm{B}^2\right>^{1/2}$
  integer :: idiag_Johmrms=0    ! DIAG_DOC: $\left<\Jv^2\right>^{1/2}$
  integer :: idiag_echarge=0    ! DIAG_DOC: $\left<e_\mathrm{eff}\right>$
  integer :: idiag_ebm=0        ! DIAG_DOC: $\left<\Ev\cdot\Bv\right>$
!
! xy averaged diagnostics given in xyaver.in
!
  integer :: idiag_exmz=0       ! XYAVG_DOC: $\left<{\cal E}_x\right>_{xy}$
  integer :: idiag_eymz=0       ! XYAVG_DOC: $\left<{\cal E}_y\right>_{xy}$
  integer :: idiag_ezmz=0       ! XYAVG_DOC: $\left<{\cal E}_z\right>_{xy}$
!
  contains
!
!***********************************************************************
    subroutine register_special
!
!  Configure pre-initialised (i.e. before parameter read) variables
!  which should be know to be able to evaluate
!
!  18-mar-21/axel: coded Faraday displacement current
!
      use FArrayManager
      use Sub, only: register_report_aux
      use SharedVariables, only: put_shared_variable
!
!  It would have been more consistent to call the indices to the
!  three components iex, iey, and iez
!
      call farray_register_pde('ee',iee,vector=3)
      iex=iee; iey=iee+1; iez=iee+2
!
      if (leedot_as_aux) &
        call register_report_aux('eedot', ieedot, iedotx, iedoty, iedotz)
!
      if (lsolve_chargedensity) &
        call farray_register_pde('rhoe',irhoe)
!
      if (llorenz_gauge_disp) then
        call farray_register_pde('a0',ia0)
        call farray_register_pde('diva_name',idiva_name)
      endif
!
      if (llongitudinalE) &
        call farray_register_pde('Gamma',iGamma)
!
      call put_shared_variable('alpf',alpf,caller='register_disp_current')
      call put_shared_variable('lphi_hom',lphi_hom)
      call put_shared_variable('lnoncollinear_EB',lnoncollinear_EB)
      call put_shared_variable('lnoncollinear_EB_aver',lnoncollinear_EB_aver)
!
      if (lroot) call svn_id( &
           "$Id$")
!
    endsubroutine register_special
!***********************************************************************
    subroutine initialize_special(f)
!
!  called by run.f90 after reading parameters, but before the time loop
!
!  20-mar-21/axel: coded
!
      use FArrayManager
      use SharedVariables, only: get_shared_variable
!
      real, dimension (mx,my,mz,mfarray) :: f
!
!  Initialize module variables which are parameter dependent
!  If one really wants to work with c_light /= 1,
!  then one needs to override this.
!
      if (c_light/=1.) call fatal_error('disp_current', "use unit_system='set'")
      c_light2=c_light**2
!
      if (lmagnetic .and. .not.lswitch_off_divJ) &
        call get_shared_variable('eta',eta, caller='initialize_magnetic')
!
!  The following are only obtained when luse_scale_factor_in_sigma=T
!  (luse_scale_factor_in_sigma=F by default)
!
      if (luse_scale_factor_in_sigma) then
        call get_shared_variable('ascale', ascale, caller='initialize_magnetic')
        call get_shared_variable('Hscript', Hscript)
        call get_shared_variable('echarge', echarge)
        call get_shared_variable('sigEm_all', sigEm_all)
        call get_shared_variable('sigBm_all', sigBm_all)
      else
        if (.not.associated(ascale)) allocate(ascale,Hscript,echarge,sigEm_all,sigBm_all)
        ascale=1.
        Hscript=0.
        echarge=0.
        sigEm_all=0.
        sigBm_all=0.
      endif
!
      call keep_compiler_quiet(f)
!
    endsubroutine initialize_special
!***********************************************************************
    subroutine init_special(f)
!
!  initialise special condition; called from start.f90
!  06-oct-2003/tony: coded
!
      use Initcond
      use Mpicomm
      use Sub
!
      real, dimension (mx,my,mz,mfarray) :: f
      real, dimension (nx) :: diva
!
      intent(inout) :: f
!
!  SAMPLE IMPLEMENTATION
!
      select case (initee)
        case ('nothing'); if (lroot) print*,'initee: nothing'
        case ('zero'); f(:,:,:,iex:iez)=0.
        case ('coswave-phase')
          call coswave_phase(f,iex,ampl_ex,kx_ex,ky_ex,kz_ex,phase_ex)
          call coswave_phase(f,iey,ampl_ey,kx_ey,ky_ey,kz_ey,phase_ey)
          call coswave_phase(f,iez,ampl_ez,kx_ez,ky_ez,kz_ez,phase_ez)
        case ('sinwave-phase')
          call sinwave_phase(f,iex,ampl_ex,kx_ex,ky_ex,kz_ex,phase_ex)
          call sinwave_phase(f,iey,ampl_ey,kx_ey,ky_ey,kz_ey,phase_ey)
          call sinwave_phase(f,iez,ampl_ez,kx_ez,ky_ez,kz_ez,phase_ez)
        case ('power_randomphase_hel')
          call power_randomphase_hel(amplee,initpower_ee,initpower2_ee, &
            cutoff_ee,ncutoff_ee,kpeak_ee,f,iex,iez,relhel_ee,kgaussian_ee, &
            lskip_projection_ee, lvectorpotential, lscale_tobox=lscale_tobox, &
            lno_noise=lno_noise_ee)
!
        case default
          call fatal_error("init_special","no such initee: "//trim(initee))
      endselect
!
!  Initial condition for Gama
!
      if (llongitudinalE) then
!        f(:,:,:,iGamma)=0.
         do n=n1,n2; do m=m1,m2
           call div(f,iaa,diva)
           f(l1:l2,m,n,iGamma)=diva
         enddo; enddo
      endif
!
!  Initial condition for rhoe
!
      if (lsolve_chargedensity) f(:,:,:,irhoe)=0.
!
!  Initialize diva_name if llorenz_gauge_disp=T
!
      if (llorenz_gauge_disp) then
        do n=n1,n2; do m=m1,m2
          call div(f,iaa,diva)
          f(l1:l2,m,n,idiva_name)=diva
        enddo; enddo
!
!  initial conditions for A0 (provided llorenz_gauge_disp=T)
!
        select case (inita0)
          case ('coswave-phase')
            call coswave_phase(f,ia0,ampl_a0,kx_a0,ky_a0,kz_a0,phase_a0)
          case ('zero'); f(:,:,:,ia0)=0.
          case ('power_randomphase')
            call power_randomphase_hel(ampla0,initpower_a0,initpower2_a0, &
              cutoff_a0,ncutoff_a0,kpeak_a0,f,ia0,ia0, &
              relhel_a0,kgaussian_a0, lskip_projection_a0, lvectorpotential, &
              lscale_tobox, lpower_profile_file=.false.)
          case default
            call fatal_error("init_special","no such inita0: "//trim(inita0))
        endselect
      endif
!
      if (leedot_as_aux) f(:,:,:,iedotx:iedotz)=0.
!
    endsubroutine init_special
!***********************************************************************
    subroutine pencil_criteria_special()
!
!  All pencils that this special module depends on are specified here.
!
!  25-feb-07/axel: adapted
!
      lpenc_requested(i_aa)=.true.
      if (alpf/=0.) then
        lpenc_requested(i_bb)=.true.
        lpenc_requested(i_infl_phi)=.true.
        lpenc_requested(i_infl_dphi)=.true.
        lpenc_requested(i_gphi)=.true.
      endif
!
!  compulsory pencils
!
      lpenc_requested(i_el)=.true.
      lpenc_requested(i_ga0)=.true.
      lpenc_requested(i_curlb)=.true.
      lpenc_requested(i_jj_ohm)=.true.
!
! Pencils for lnoncollinear_EB
!
      if (lnoncollinear_EB .or. lnoncollinear_EB_aver) then
        lpenc_requested(i_bb)=.true.
        lpenc_requested(i_e2)=.true.
        lpenc_requested(i_b2)=.true.
      endif
!
      if (llorenz_gauge_disp) then
        lpenc_requested(i_diva)=.true.
      endif
!
!  Terms for Gamma evolution.
!
      if (llongitudinalE) then
        lpenc_requested(i_divE)=.true.
        lpenc_requested(i_gGamma)=.true.
      endif
!
!  charge density
!
      if (lsolve_chargedensity) then
        lpenc_requested(i_divJ)=.true.
        lpenc_requested(i_uij)=.true.
        lpenc_requested(i_bij)=.true.
        lpenc_requested(i_uu)=.true.
        lpenc_requested(i_bb)=.true.
      endif
!
!  diffusion term.
!
      if (eta_ee/=0.) lpenc_requested(i_del2ee)=.true.
!
!  Diagnostics pencils:
!
      if (eta_ee/=0.) lpenc_requested(i_del2ee)=.true.
      if (eta_ee/=0.) lpenc_requested(i_del2ee)=.true.

      if (idiag_BcurlEm/=0) then
        lpenc_diagnos(i_curlE)=.true.
        lpenc_diagnos(i_BcurlE)=.true.
      endif

      if (idiag_a0rms/=0) lpenc_diagnos(i_a0)=.true.
      if (idiag_grms/=0) lpenc_diagnos(i_diva)=.true.
      if (idiag_edotrms/=0) lpenc_diagnos(i_edot2)=.true.
      if (idiag_EEEM/=0 .or. idiag_erms/=0 .or. idiag_emax/=0) lpenc_diagnos(i_e2)=.true.
      if (idiag_exmz/=0 .or. idiag_eymz/=0 .or. idiag_ezmz/=0 ) lpenc_diagnos(i_el)=.true.
      if (idiag_exm/=0 .or. idiag_eym/=0 .or. idiag_ezm/=0 ) lpenc_diagnos(i_el)=.true.
!
    endsubroutine pencil_criteria_special
!***********************************************************************
    subroutine pencil_interdep_special(lpencil_in)
!
!  Interdependency among pencils provided by this module are specified here.
!
!  18-07-06/tony: coded
!
      logical, dimension(npencils) :: lpencil_in
!
      call keep_compiler_quiet(lpencil_in)
!
    endsubroutine pencil_interdep_special
!***********************************************************************
    subroutine calc_pencils_special(f,p)
!
!  Calculate Hydro pencils.
!  Most basic pencils should come first, as others may depend on them.
!
!   24-nov-04/tony: coded
!
      use Sub, only: grad, div, curl, del2v, dot2_mn, dot, levi_civita
!
      real, dimension (mx,my,mz,mfarray) :: f
      type (pencil_case) :: p
!
      real, dimension (nx) :: tmp
      real, dimension (nx) :: boost, gam_EB, eprime, bprime, jprime
      real, parameter :: Chypercharge=41./12.
      integer :: i,j,k
!
      intent(in) :: f
      intent(inout) :: p
!
!  Terms for Gamma evolution.
!
      if (llongitudinalE) then
        call div(f,iee,p%divE)
        call grad(f,iGamma,p%gGamma)
        p%curlb=-p%del2a+p%gGamma
        if (lsolve_chargedensity) p%rhoe=f(l1:l2,m,n,irhoe)
!      else
!        p%curlb=p%jj
!        p%curlb=p%graddiva-p%del2a
!        print*,'ram=p%graddiva',p%graddiva
!        print*,'ram=p%del2a',p%del2a
      endif
!
! el and e2 (note that this is called after magnetic, where sigma is computed)
!
      p%el=f(l1:l2,m,n,iex:iez)
      call dot2_mn(p%el,p%e2)
!
!  Compute fully non-collinear expression for the current density.
!  This is for the spatially dependent sigE and sigB. The averaged ones are
!  computed in backreact_infl.f90.
!
      if (lnoncollinear_EB .or. lnoncollinear_EB_aver) then
        if (lnoncollinear_EB) then
          call dot(p%el,p%bb,p%eb)
          boost=sqrt((p%e2-p%b2)**2+4.*p%eb**2)
          gam_EB=sqrt21*sqrt(1.+(p%e2+p%b2)/boost)
          eprime=sqrt21*sqrt(p%e2-p%b2+boost)
          bprime=sqrt21*sqrt(p%b2-p%e2+boost)*sign(1.,p%eb)
          jprime=Chypercharge*echarge**3/(6.*pi**2*Hscript)*eprime*abs(bprime)/tanh(pi*abs(Bprime)/Eprime)
          p%sigE=abs(jprime)*eprime/(gam_EB*boost)
          p%sigB=abs(jprime)*p%eb/(eprime*gam_EB*boost)
        elseif (lnoncollinear_EB_aver) then
          p%sigE=sigEm_all
          p%sigB=sigBm_all
        endif
        do j=1,3
          p%jj_ohm(:,j)=p%sigE*p%el(:,j)+p%sigB*p%bb(:,j)
        enddo
      endif
!             else
!               do j=1,3
!                 p%jj_ohm(:,j)=(p%el(:,j)+p%uxb(:,j))*mu01/eta_total
!               enddo
!
! edot2
!
      if (leedot_as_aux) then
        call dot2_mn(f(l1:l2,m,n,iedotx:iedotz),p%edot2)
      else
        p%edot2=0.
      endif
!
!  del2ee  !(AB: not needed)
!
      if (eta_ee/=0.) call del2v(f,iex,p%del2ee)
!
!  curle
!
      if (idiag_BcurlEm/=0) then
        call curl(f,iex,p%curle)
        call dot(p%bb,p%curle,p%BcurlE)
      endif
!
!  del2ee
!
      if (eta_ee/=0.) call del2v(f,iex,p%del2ee)
!
! a0 & ga0
!
      if (ia0>0) then
        p%a0=f(l1:l2,m,n,ia0)
        call grad(f,ia0,p%ga0)
      endif
!
!  divJ (using Ohm's law)
!  divJ=sigma*[divE+eps_ijk*(u_j,i * b_k + u_j * b_k,i)]
!  The use if eta may be suspect and should be checked.
!
      if (lpenc_requested(i_divJ)) then
        tmp=0.
        do i=1,3
        do j=1,3
        do k=1,3
          tmp=tmp+levi_civita(i,j,k)*(p%uij(:,j,i)*p%bb(:,k)+p%uu(:,j)*p%bij(:,k,i))
        enddo
        enddo
        enddo
        if (lswitch_off_divJ) then
          p%divJ=0.
        else
          p%divJ=(p%divE+tmp)/(mu0*eta)
        endif
      endif
!
    endsubroutine calc_pencils_special
!***********************************************************************
    subroutine dspecial_dt(f,df,p)
!
!  calculate right hand side of ONE OR MORE extra coupled PDEs
!  along the 'current' Pencil, i.e. f(l1:l2,m,n) where
!  m,n are global variables looped over in equ.f90
!
!  Due to the multi-step Runge Kutta timestepping used one MUST always
!  add to the present contents of the df array.  NEVER reset it to zero.
!
!  several precalculated Pencils of information are passed if for
!  efficiency.
!
!   18-mar-21/axel: coded Faraday displacement current
!
      use Diagnostics
      use Mpicomm
      use Sub
!
      real, dimension (mx,my,mz,mfarray) :: f
      real, dimension (mx,my,mz,mvar) :: df
      type (pencil_case) :: p
!
      real, dimension (nx,3) :: gtmp
      real, dimension (nx) :: tmp, del2a0, constrainteqn, constrainteqn1
      real :: inflation_factor=0., mfpf=0., fppf=0.
!
      intent(in) :: p
      intent(inout) :: f, df
!
!  identify module and boundary conditions
!
      if (headtt.or.ldebug) print*,'dspecial_dt: SOLVE dSPECIAL_dt'
      if (headtt) call identify_bcs('ee',iee)
!
!  Calculate rhs of Gamma equation and update curl
!
      if (lphi_hom) then
        tmp=0.
        weight_longitudinalE=0.
      else
        if (alpf/=0.) then
          call dot(p%bb,p%gphi,tmp)
          tmp=-alpf*tmp
        else
          tmp=0.
        endif
      endif
      constrainteqn1=sqrt(p%divE**2+tmp**2)
      if (any(constrainteqn1 == 0.)) then
        constrainteqn=0.
      else
        constrainteqn=(p%divE-tmp)/constrainteqn1
      endif
      if (llongitudinalE) then
        if (lsolve_chargedensity) tmp=tmp+f(l1:l2,m,n,irhoe)
        if (.not.lswitch_off_Gamma) &
          df(l1:l2,m,n,iGamma) = df(l1:l2,m,n,iGamma) - (1.-weight_longitudinalE)*p%divE &
                                -weight_longitudinalE*tmp
      endif
!
!  solve: dE/dt = curlB - ...
!  Calculate curlB as -del2a, because curlB leads to instability.
!  Solve dA/dt = -E.
!
      if (lmagnetic) then
        df(l1:l2,m,n,iax:iaz)=df(l1:l2,m,n,iax:iaz)-p%el
        df(l1:l2,m,n,iex:iez)=df(l1:l2,m,n,iex:iez)+c_light2*(p%curlb-mu0*p%jj_ohm)
!
!  Solve for charge density
!
        if (lsolve_chargedensity) df(l1:l2,m,n,irhoe)=df(l1:l2,m,n,irhoe)-p%divJ
!
!  Magneto-genesis from reheating. In the papers by Subramanian (2010) and Sharma+17,
!  as well as BS21, the calliographic variable curly-A=f*A was introduced to get
!  rid of the first derivative of A. But the disadvantage is that the generation
!  term, (f"/f)*<A.E> is then gauge-dependent. Because of this and other reasons,
!  it is better to work with the original 2(f'/f)*A' = -2(f'/f)*E term, which is
!  gauge-independent.
!
        if (beta_inflation/=0.) then
          if (ip<14.and.lroot) print*,'scl_factor_target, Hp_target, appa_target, wweos_target=', &
                                       scl_factor_target, Hp_target, appa_target, wweos_target
          mfpf=beta_inflation*Hp_target
          fppf=beta_inflation*((beta_inflation+1.)*Hp_target**2-appa_target)
          if (lcurlyA) then
            inflation_factor=fppf
            df(l1:l2,m,n,iex:iez)=df(l1:l2,m,n,iex:iez)-c_light2*inflation_factor*p%aa
          else
            inflation_factor=-2.*mfpf
            df(l1:l2,m,n,iex:iez)=df(l1:l2,m,n,iex:iez)-c_light2*inflation_factor*p%el
          endif
          if (ip<15.and.lroot.and.lfirst) print*,'t, inflation_factor=',t, inflation_factor
        endif
!
!  if particles, would add J=sum(qi*Vi*ni)
!
!  A0 equation: 3 terms
!  dA0/dt = divA
!  dAA/dt = ... + gradA0
!
!  helical term:
!  dEE/dt = ... -alp/f (dphi*BB + gradphi x E)
!  Use the combined routine multsv_add if both terms are included.
!
        if (alpf/=0.) then
          if (lphi_hom) then
            call multsv(p%infl_dphi,p%bb,gtmp)
          else
            call cross(p%gphi,p%el,gtmp)
            call multsv_add(gtmp,p%infl_dphi,p%bb,gtmp)
          endif
!          print*,"p%infl_phi",p%infl_phi
!          print*,"p%infl_dphi",p%infl_dphi
          df(l1:l2,m,n,iex:iez)=df(l1:l2,m,n,iex:iez)-alpf*gtmp
          if (llorenz_gauge_disp) then
            call del2(f,ia0,del2a0)
            if (lphi_hom) then
              df(l1:l2,m,n,idiva_name)=df(l1:l2,m,n,idiva_name)+del2a0
            else
              call dot_mn(p%gphi,p%bb,tmp)
              df(l1:l2,m,n,idiva_name)=df(l1:l2,m,n,idiva_name)+alpf*tmp+del2a0
            endif
!
!  Evolution of the equation for the scalar potential.
!
            !df(l1:l2,m,n,ia0)=df(l1:l2,m,n,ia0)+p%diva
            df(l1:l2,m,n,ia0)=df(l1:l2,m,n,ia0)+f(l1:l2,m,n,idiva_name)
            df(l1:l2,m,n,iax:iaz)=df(l1:l2,m,n,iax:iaz)+p%ga0
          endif
        endif
        if (eta_ee/=0.) df(l1:l2,m,n,iex:iez)=df(l1:l2,m,n,iex:iez)+c_light2*eta_ee*p%del2ee
      endif
!
!  Compute eedot_as_aux; currently ignore alpf/=0.
!
      if (leedot_as_aux) f(l1:l2,m,n,iedotx:iedotz)=c_light2*(p%curlb-mu0*p%jj_ohm)
!
!  timestep constraint
!
      if (lfirst.and.ldt) advec_cs2=max(advec_cs2,c_light2*dxyz_2)
!
!  diagnostics
!
      if (ldiagnos) then
        if (idiag_EEEM/=0) call sum_mn_name(.5*(p%e2+p%b2),idiag_EEEM)
        call sum_mn_name(p%el(:,1),idiag_exm)
        call sum_mn_name(p%el(:,2),idiag_eym)
        call sum_mn_name(p%el(:,3),idiag_ezm)
        call sum_mn_name(p%sigE,idiag_sigEm)
        call sum_mn_name(p%sigB,idiag_sigBm)
        call sum_mn_name(p%eb,idiag_ebm)
        if (idiag_sigErms/=0) call sum_mn_name(p%sigE**2,idiag_sigErms,lsqrt=.true.)
        if (idiag_sigBrms/=0) call sum_mn_name(p%sigB**2,idiag_sigBrms,lsqrt=.true.)
        if (idiag_Johmrms/=0) then
          call dot2_mn(p%jj_ohm,tmp)
          call sum_mn_name(tmp,idiag_Johmrms,lsqrt=.true.)
        endif
        call save_name(echarge,idiag_echarge)
        call sum_mn_name(p%e2,idiag_erms,lsqrt=.true.)
        call sum_mn_name(p%edot2,idiag_edotrms,lsqrt=.true.)
        call max_mn_name(p%e2,idiag_emax,lsqrt=.true.)
        if (idiag_a0rms/=0) call sum_mn_name(p%a0**2,idiag_a0rms,lsqrt=.true.)
        call sum_mn_name(p%BcurlE,idiag_BcurlEm)
        if (lsolve_chargedensity) then
          call sum_mn_name(p%rhoe,idiag_rhoem)
          if (idiag_rhoerms/=0) call sum_mn_name(p%rhoe**2,idiag_rhoerms,lsqrt=.true.)
        endif
        if (idiag_divErms/=0) call sum_mn_name(p%divE**2,idiag_divErms,lsqrt=.true.)
        if (idiag_divJrms/=0) call sum_mn_name(p%divJ**2,idiag_divJrms,lsqrt=.true.)
        call sum_mn_name(p%divE,idiag_divEm)
        call sum_mn_name(p%divJ,idiag_divJm)
        call save_name(mfpf,idiag_mfpf)
        call save_name(fppf,idiag_fppf)
        call save_name(scl_factor_target,idiag_afact)
        if (idiva_name>0) then
          if (idiag_grms/=0) call sum_mn_name((f(l1:l2,m,n,idiva_name)-p%diva)**2/ &
            (f(l1:l2,m,n,idiva_name)**2+p%diva**2),idiag_grms,lsqrt=.true.)
          if (idiag_da0rms/=0) call sum_mn_name(f(l1:l2,m,n,idiva_name)**2,idiag_da0rms,lsqrt=.true.)
        endif
        call sum_mn_name(constrainteqn,idiag_constrainteqn)
!
        call xysum_mn_name_z(p%el(:,1),idiag_exmz)
        call xysum_mn_name_z(p%el(:,2),idiag_eymz)
        call xysum_mn_name_z(p%el(:,3),idiag_ezmz)
!
      endif
!
    endsubroutine dspecial_dt
!***********************************************************************
    subroutine read_special_init_pars(iostat)
!
      use File_io, only: parallel_unit
!
      integer, intent(out) :: iostat
!
      read(parallel_unit, NML=special_init_pars, IOSTAT=iostat)
!
    endsubroutine read_special_init_pars
!***********************************************************************
    subroutine write_special_init_pars(unit)
!
      integer, intent(in) :: unit
!
      write(unit, NML=special_init_pars)
!
    endsubroutine write_special_init_pars
!***********************************************************************
    subroutine read_special_run_pars(iostat)
!
      use File_io, only: parallel_unit
!
      integer, intent(out) :: iostat
!
      read(parallel_unit, NML=special_run_pars, IOSTAT=iostat)
!
    endsubroutine read_special_run_pars
!***********************************************************************
    subroutine write_special_run_pars(unit)
!
      integer, intent(in) :: unit
!
      write(unit, NML=special_run_pars)
!
    endsubroutine write_special_run_pars
!***********************************************************************
    subroutine rprint_special(lreset,lwrite)
!
!  reads and registers print parameters relevant to special
!
!   06-oct-03/tony: coded
!
      use Diagnostics
      use FArrayManager, only: farray_index_append
      use Sub
!
!  define counters
!
      integer :: iname,inamez
      logical :: lreset,lwr
      logical, optional :: lwrite
!
      lwr = .false.
      if (present(lwrite)) lwr=lwrite
!
!  reset everything in case of reset
!  (this needs to be consistent with what is defined above!)
!
      if (lreset) then
        idiag_EEEM=0; idiag_erms=0; idiag_exm=0;idiag_eym=0;  idiag_ezm=0; idiag_emax=0
        idiag_edotrms=0; idiag_a0rms=0; idiag_grms=0; idiag_da0rms=0; idiag_BcurlEm=0
        idiag_mfpf=0; idiag_fppf=0; idiag_afact=0
        idiag_rhoerms=0; idiag_divErms=0; idiag_divJrms=0
        idiag_rhoem=0; idiag_divEm=0; idiag_divJm=0; idiag_constrainteqn=0
        idiag_ebm=0; idiag_sigEm=0; idiag_sigBm=0; idiag_sigErms=0; idiag_sigBrms=0; idiag_Johmrms=0
        idiag_echarge=0
        cformv=''
      endif
!
!  check for those quantities that we want to evaluate online
!
      do iname=1,nname
        call parse_name(iname,cname(iname),cform(iname),'EEEM',idiag_EEEM)
        call parse_name(iname,cname(iname),cform(iname),'erms',idiag_erms)
        call parse_name(iname,cname(iname),cform(iname),'exm',idiag_exm)
        call parse_name(iname,cname(iname),cform(iname),'eym',idiag_eym)
        call parse_name(iname,cname(iname),cform(iname),'ezm',idiag_ezm)
        call parse_name(iname,cname(iname),cform(iname),'edotrms',idiag_edotrms)
        call parse_name(iname,cname(iname),cform(iname),'emax',idiag_emax)
        call parse_name(iname,cname(iname),cform(iname),'a0rms',idiag_a0rms)
        call parse_name(iname,cname(iname),cform(iname),'grms',idiag_grms)
        call parse_name(iname,cname(iname),cform(iname),'da0rms',idiag_da0rms)
        call parse_name(iname,cname(iname),cform(iname),'BcurlEm',idiag_BcurlEm)
        call parse_name(iname,cname(iname),cform(iname),'divErms',idiag_divErms)
        call parse_name(iname,cname(iname),cform(iname),'divJrms',idiag_divJrms)
        call parse_name(iname,cname(iname),cform(iname),'rhoerms',idiag_rhoerms)
        call parse_name(iname,cname(iname),cform(iname),'divEm',idiag_divEm)
        call parse_name(iname,cname(iname),cform(iname),'divJm',idiag_divJm)
        call parse_name(iname,cname(iname),cform(iname),'rhoem',idiag_rhoem)
        call parse_name(iname,cname(iname),cform(iname),'sigEm',idiag_sigEm)
        call parse_name(iname,cname(iname),cform(iname),'sigBm',idiag_sigBm)
        call parse_name(iname,cname(iname),cform(iname),'ebm',idiag_ebm)
        call parse_name(iname,cname(iname),cform(iname),'sigErms',idiag_sigErms)
        call parse_name(iname,cname(iname),cform(iname),'sigBrms',idiag_sigBrms)
        call parse_name(iname,cname(iname),cform(iname),'Johmrms',idiag_Johmrms)
        call parse_name(iname,cname(iname),cform(iname),'echarge',idiag_echarge)
        call parse_name(iname,cname(iname),cform(iname),'mfpf',idiag_mfpf)
        call parse_name(iname,cname(iname),cform(iname),'fppf',idiag_fppf)
        call parse_name(iname,cname(iname),cform(iname),'afact',idiag_afact)
        call parse_name(iname,cname(iname),cform(iname),'constrainteqn',idiag_constrainteqn)
      enddo
!
      do inamez=1,nnamez
        call parse_name(inamez,cnamez(inamez),cformz(inamez),'exmz',idiag_exmz)
        call parse_name(inamez,cnamez(inamez),cformz(inamez),'eymz',idiag_eymz)
        call parse_name(inamez,cnamez(inamez),cformz(inamez),'ezmz',idiag_ezmz)
      enddo
!
!  check for those quantities for which we want video slices
!
      if (lwrite_slices) then
        where(cnamev=='ee') cformv='DEFINED'
      endif
!
!  write column where which magnetic variable is stored
!
      if (lwr) then
      endif
!
    endsubroutine rprint_special
!***********************************************************************
    subroutine special_after_boundary(f)
!
!  Possibility to modify the f array after the boundaries are
!  communicated.
!
!  06-jul-06/tony: coded
!
      real, dimension (mx,my,mz,mfarray), intent(in) :: f
!
      call keep_compiler_quiet(f)
!
    endsubroutine special_after_boundary
!***********************************************************************
    subroutine get_slices_special(f,slices)
!
!  Write slices for animation of electric potential
!
!  26-feb-07/axel: adapted from gross_pitaevskii
!
      use Slices_methods, only: assign_slices_vec
!
      real, dimension (mx,my,mz,mvar+maux) :: f
      type (slice_data) :: slices
!
      integer :: inamev
!
!  Loop over slices
!
      select case (trim(slices%name))
!
!  Electric field.
!
      case ('ee'); call assign_slices_vec(slices,f,iee)
!
      endselect
!
    endsubroutine get_slices_special
!***********************************************************************
!
!********************************************************************
!************        DO NOT DELETE THE FOLLOWING       **************
!********************************************************************
!**  This is an automatically generated include file that creates  **
!**  copies dummy routines from nospecial.f90 for any Special      **
!**  routines not implemented in this file                         **
!**                                                                **
    include '../special_dummies.inc'
!********************************************************************
!
endmodule Special

! $Id: nodensity.f90,v 1.48 2006-12-05 20:43:34 dobler Exp $

!** AUTOMATIC CPARAM.INC GENERATION ****************************
! Declare (for generation of cparam.inc) the number of f array
! variables and auxiliary variables added by this module
!
! CPARAM logical, parameter :: ldensity = .false.
! MVAR CONTRIBUTION 0
! MAUX CONTRIBUTION 0
!
! PENCILS PROVIDED rho,lnrho,rho1,glnrho,del2lnrho,hlnrho,grho
! PENCILS PROVIDED del6lnrho,uij5glnrho,uglnrho,ugrho,sglnrho
!
!***************************************************************

module Density

  use Cparam
  use Messages
  use EquationOfState, only: cs0,cs20,lnrho0,rho0, &
                             gamma,gamma1,cs2top,cs2bot

  implicit none

  include 'density.h'


  !namelist /density_init_pars/ dummy
  !namelist /density_run_pars/  dummy

  ! other variables (needs to be consistent with reset list below)
  integer :: idiag_rhom=0
  integer :: idiag_rhomin=0,idiag_rhomax=0
  logical :: ldensity_nolog=.false.

  contains

!***********************************************************************
    subroutine register_density()
!
!  Initialise variables which should know that we solve the
!  compressible hydro equations: ilnrho; increase nvar accordingly.
!
!   8-jun-02/axel: adapted from density
!
      use Cdata
      use Sub
!
      logical, save :: first=.true.
!
      if (.not. first) call fatal_error('register_density', &
                                        'module registration called twice')
      first = .false.
!
!
!  identify version number (generated automatically by CVS)
!
      if (lroot) call cvs_id( &
           "$Id: nodensity.f90,v 1.48 2006-12-05 20:43:34 dobler Exp $")
!
    endsubroutine register_density
!***********************************************************************
    subroutine initialize_density(f,lstarting)
!
!  Perform any post-parameter-read initialization i.e. calculate derived
!  parameters.
!
!  24-nov-02/tony: coded
!
      use Cdata, only: lentropy
      use EquationOfState, only: select_eos_variable
!
      real, dimension (mx,my,mz,mfarray) :: f
      logical :: lstarting
!
! Tell the equation of state that we're here and we don't have a
! variable => isochoric (constant density)
!
      call select_eos_variable('lnrho',-1)
!
      if (ip == 0) print*,f,lstarting ! keep compiler quiet
    endsubroutine initialize_density
!***********************************************************************
    subroutine init_lnrho(f,xx,yy,zz)
!
!  initialise lnrho; called from start.f90
!
!   7-jun-02/axel: adapted from density
!
      use Cdata
      use Sub
!
      real, dimension (mx,my,mz,mfarray) :: f
      real, dimension (mx,my,mz) :: xx,yy,zz
!
      if(NO_WARN) print*,f,xx,yy,zz !(prevent compiler warnings)
    endsubroutine init_lnrho
!***********************************************************************
    subroutine pencil_criteria_density()
!
!  All pencils that the Density module depends on are specified here.
!
!  20-11-04/anders: coded
!
    endsubroutine pencil_criteria_density
!***********************************************************************
    subroutine pencil_interdep_density(lpencil_in)
!
!  Interdependency among pencils from the Density module is specified here.
!
!  20-11-04/anders: coded
!
      logical, dimension(npencils) :: lpencil_in
!
      if(NO_WARN) print*,lpencil_in(1)
!
    endsubroutine pencil_interdep_density
!***********************************************************************
    subroutine calc_pencils_density(f,p)
!
!  Calculate Density pencils.
!  Most basic pencils should come first, as others may depend on them.
!
!  20-11-04/anders: coded
!
      real, dimension (mx,my,mz,mfarray) :: f
      type (pencil_case) :: p
!
      intent(in) :: f
      intent(inout) :: p
! rho
      if (lpencil(i_rho)) p%rho=rho0
! lnrho
      if (lpencil(i_lnrho)) p%lnrho=lnrho0
! rho1
      if (lpencil(i_rho1)) p%rho1=1./rho0
! glnrho
      if (lpencil(i_glnrho)) p%glnrho=0.
! grho
      if (lpencil(i_grho)) p%grho=0.
! del6lnrho
      if (lpencil(i_del6lnrho)) p%del6lnrho=0.
! hlnrho
      if (lpencil(i_hlnrho)) p%hlnrho=0.
! sglnrho
      if (lpencil(i_sglnrho)) p%sglnrho=0.
! uglnrho
      if (lpencil(i_uglnrho)) p%uglnrho=0.
! ugrho
      if (lpencil(i_ugrho)) p%ugrho=0.
! uij5glnrho
      if (lpencil(i_uij5glnrho)) p%uij5glnrho=0.
!
      if (NO_WARN) print*, f
!
    endsubroutine calc_pencils_density
!***********************************************************************
    subroutine dlnrho_dt(f,df,p)
!
!  continuity equation, dummy routine
!
!   7-jun-02/axel: adapted from density
!
      real, dimension (mx,my,mz,mfarray) :: f
      real, dimension (mx,my,mz,mvar) :: df
      type (pencil_case) :: p
!
      intent(in) :: f,df,p
!
      if(NO_WARN) print*,f,df,p
!
    endsubroutine dlnrho_dt
!***********************************************************************
    subroutine read_density_init_pars(unit,iostat)
      integer, intent(in) :: unit
      integer, intent(inout), optional :: iostat

      if (present(iostat) .and. (NO_WARN)) print*,iostat
      if (NO_WARN) print*,unit

    endsubroutine read_density_init_pars
!***********************************************************************
    subroutine write_density_init_pars(unit)
      integer, intent(in) :: unit

      if (NO_WARN) print*,unit

    endsubroutine write_density_init_pars
!***********************************************************************
    subroutine read_density_run_pars(unit,iostat)
      integer, intent(in) :: unit
      integer, intent(inout), optional :: iostat

      if (present(iostat) .and. (NO_WARN)) print*,iostat
      if (NO_WARN) print*,unit

    endsubroutine read_density_run_pars
!***********************************************************************
    subroutine write_density_run_pars(unit)
      integer, intent(in) :: unit

      if (NO_WARN) print*,unit
    endsubroutine write_density_run_pars
!***********************************************************************
    subroutine rprint_density(lreset,lwrite)
!
!  reads and registers print parameters relevant for compressible part
!
!   8-jun-02/axel: adapted from density
!
      use Cdata
      use Sub
!
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
        idiag_rhom=0
        idiag_rhomin=0; idiag_rhomax=0
      endif
!
!  write column where which magnetic variable is stored
!
      if (lwr) then
        write(3,*) 'i_rhom=',idiag_rhom
        write(3,*) 'i_rhomin=',idiag_rhomin
        write(3,*) 'i_rhomax=',idiag_rhomax
        write(3,*) 'nname=',nname
        write(3,*) 'ilnrho=',ilnrho
      endif
!
    endsubroutine rprint_density
!***********************************************************************
endmodule Density

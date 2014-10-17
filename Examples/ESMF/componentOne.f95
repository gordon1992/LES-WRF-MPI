module componentone
use ESMF
use esmfHelpers
implicit none

public :: componentOneSetServices, componentOneSetVM

private
    character (len=*), parameter :: componentName = "Component One"

contains

subroutine componentOneSetVM(component, rc)
    type(ESMF_GridComp) :: component
    integer, intent(out) :: rc
    type(ESMF_VM) :: vm
    logical :: pthreadsEnabled
    call ESMF_VMGetGlobal(vm, rc=rc)
    call checkRC(rc, "Error occurred while trying to get global VM for "//componentName)
    call ESMF_VMGet(vm, pthreadsEnabledFlag=pthreadsEnabled, rc=rc)
    call checkRC(rc, "Error occurred while trying to get pthreads enabled info for "//componentName)
    if (pthreadsEnabled) then
        call ESMF_GridCompSetVMMinThreads(component, rc=rc)
        call checkRC(rc, "Error occurred while trying to set minimum threads for "//componentName)
    endif
    rc=ESMF_SUCCESS
end subroutine componentOneSetVM

subroutine componentOneSetServices(component, rc)
    type(ESMF_GridComp) :: component
    integer, intent(out) :: rc
    call ESMF_GridCompSetEntryPoint(component, ESMF_METHOD_INITIALIZE, componentOneInit, rc=rc)
    call checkRC(rc, "Error occurred setting init method for "//componentName)
    call ESMF_GridCompSetEntryPoint(component, ESMF_METHOD_RUN, componentOneRun, rc=rc)
    call checkRC(rc, "Error occurred setting run method for "//componentName)
    call ESMF_GridCompSetEntryPoint(component, ESMF_METHOD_FINALIZE, componentOneFinal, rc=rc)
    call checkRC(rc, "Error occurred setting finalize method for "//componentName)
    rc = ESMF_SUCCESS
end subroutine componentOneSetServices

subroutine componentOneInit(gridcomp, importState, exportState, clock, rc)
    implicit none
    type(ESMF_GridComp) :: gridcomp
    type(ESMF_State) :: importState, exportState
    type(ESMF_Clock) :: clock
    integer, intent(out) :: rc
    integer :: petCount
    type(ESMF_VM) :: vm
    call ESMF_VMGetGlobal(vm, rc=rc)
    call checkRC(rc, "Error occurred while trying to get global VM for "//componentName)
    call ESMF_VMGet(vm, petCount=petCount, rc=rc)
    call checkRC(rc, "Error occurred while trying to get pet count info for "//componentName)
    rc = ESMF_SUCCESS
    call ESMF_LogWrite("Component One Init subroutine called", ESMF_LOGMSG_INFO)
end subroutine componentOneInit

subroutine componentOneRun(gridcomp, importState, exportState, clock, rc)
    implicit none
    type(ESMF_GridComp) :: gridcomp
    type(ESMF_State) :: importState, exportState
    type(ESMF_Clock) :: clock
    integer, intent(out) :: rc
    rc = ESMF_SUCCESS
    !call sleep(1)
    call ESMF_LogWrite("Component One Run subroutine called", ESMF_LOGMSG_INFO)
end subroutine componentOneRun

subroutine componentOneFinal(gridcomp, importState, exportState, clock, rc)
    implicit none
    type(ESMF_GridComp) :: gridcomp
    type(ESMF_State) :: importState, exportState
    type(ESMF_Clock) :: clock
    integer, intent(out) :: rc
    rc = ESMF_SUCCESS
    call ESMF_LogWrite("Component One Final subroutine called", ESMF_LOGMSG_INFO)
end subroutine componentOneFinal

end module componentone

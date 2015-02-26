subroutine program_global_sum(sys, tile, model_id) ! This replaces 'program main'
    use gmcfAPI
    implicit none
    integer(8) , intent(In) :: sys
    integer(8) , intent(In) :: tile
    integer , intent(In) :: model_id
    integer :: iterations, i
    integer :: clock_start, clock_end, clock_rate
    real(kind=4) :: total_time, messages_per_second
    real(kind=4) :: value
    iterations = 1
    call gmcfInitCoupler(sys, tile, model_id)
    call system_clock(clock_start, clock_rate)
    do i=1, iterations
        value = model_id
        call getGlobalSumOfGMCF(model_id, value)
    end do
    call system_clock(clock_end, clock_rate)
    call gmcfFinished(model_id)
    if (model_id .eq. 1) then
        total_time = (clock_end - clock_start)/real(clock_rate)
        messages_per_second = iterations / total_time
        print*, total_time, "s for ", iterations, " iterations, a rate of ", messages_per_second, " iterations per second."
    end if
end subroutine program_global_sum

subroutine getGlobalSumOfGMCF(model_id, value)
    implicit none
    integer, intent(in) :: model_id
    real(kind=4), intent(inout) :: value
    call getGlobalOp(model_id, value, 1)
end subroutine getGlobalSumOfGMCF

subroutine getGlobalOp(model_id, value, tag)
    implicit none
    integer, intent(in) :: model_id, tag
    real(kind=4), intent(inout) :: value
    if (model_id .eq. 1) then
        call getGlobalOpMaster(model_id, value, tag)
    else
        call getGlobalOpNotMaster(model_id, value, tag)
    end if
end subroutine getGlobalOp

subroutine getGlobalOpMaster(model_id, value, tag)
    use gmcfAPI
    integer, intent(in) :: model_id, tag
    real(kind=4), intent(inout) :: value
    real(kind=4) :: received
    integer :: i
    call gmcfLockReg(model_id)
    do i=2,INSTANCES
        call gmcfAddOneToSet(model_id, REGREADY, i)
    end do
    call gmcfWaitForRegs(model_id)
    do i=2,INSTANCES
        print*, 'gmcfReadReg(sba_sys,', i, ',', tag, ', received)'
        call gmcfReadReg(sba_sys, i, tag, received)
        print*, 'gmcfReadReg got value', received, ' from ', i
        if (tag .eq. 1) then
            value = value + received
        else
            print*, tag, ' is an invalid tag.'
        end if
    end do
    print*, 'Global op result calculated, value is ', value
    ! Write global op result to register
    call gmcfWriteReg(sba_sys, model_id, tag, value)
    call gmcfUnlockReg(model_id)
end subroutine getGlobalOpMaster

subroutine getGlobalOpNotMaster(model_id, value, tag)
    use gmcfAPI
    integer, intent(in) :: model_id, tag
    real(kind=4), intent(inout) :: value
    call gmcfLockReg(model_id)
    call gmcfWriteReg(sba_sys, model_id, tag, value)
    call gmcfUnlockReg(model_id)
    ! Get global op result
    call gmcfAddOneToSet(model_id, REGREADY, 1)
    call gmcfWaitForRegs(model_id)
    call gmcfReadReg(sba_sys, 1, tag, value)
    print*, 'Global op result received, value is ', value
end subroutine getGlobalOpNotMaster


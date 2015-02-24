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
    iterations = 30000
    call gmcfInitCoupler(sys, tile, model_id)
    call system_clock(clock_start, clock_rate)
    do i=1, iterations
        value = model_id
        call getGlobalSumOfGMCF(model_id, value)
    end do
    print*, value
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
    real(kind=4), dimension(1) :: receiveBuffer, sendBuffer
    integer :: i, has_packets, fifo_empty
    type(gmcfPacket) :: packet
    do i=2, INSTANCES
        call gmcfWaitFor(model_id, RESPDATA, i, 1)
    end do
    call gmcfSetSize(model_id, RESPDATA, has_packets)
    do while(has_packets .gt. 0)
        call gmcfShiftPendingFromInclusionSet(model_id, RESPDATA, packet, fifo_empty)
        if (packet%data_id .ne. tag) then
            print*, 'Received unexpected packet from', packet%source, ' with id ', packet%data_id
        else
            call gmcfRead1DFloatArray(receiveBuffer, shape(receiveBuffer), packet)
            if (tag .eq. 1) then
                value = value + receiveBuffer(1)
            else
                print*, 'Unexpected global op'
            end if
        end if
        call gmcfSetSize(model_id, RESPDATA, has_packets)
    end do
    sendBuffer(1) = value
    do i=2, INSTANCES
        call gmcfSend1DFloatArray(model_id, sendBuffer, shape(sendBuffer), tag, i, PRE, 1)
    end do
    do i=2,INSTANCES
        call gmcfWaitFor(model_id, ACKDATA, i, 1)
    end do
    call gmcfSetSize(model_id, ACKDATA, has_packets)
    do while(has_packets .gt. 0)
        call gmcfShiftPendingFromInclusionSet(model_id, ACKDATA, packet, fifo_empty)
        call gmcfSetSize(model_id, ACKDATA, has_packets)
    end do
end subroutine getGlobalOpMaster

subroutine getGlobalOpNotMaster(model_id, value, tag)
    use gmcfAPI
    integer, intent(in) :: model_id, tag
    real(kind=4), intent(inout) :: value
    real(kind=4), dimension(1) :: receiveBuffer, sendBuffer
    integer :: has_packets, fifo_empty
    type(gmcfPacket) :: packet
    sendBuffer(1) = value
    call gmcfSend1DFloatArray(model_id, sendBuffer, shape(sendBuffer), tag, 1, PRE, 1)
    call gmcfWaitFor(model_id, ACKDATA, 1, 1)
    call gmcfHasPackets(model_id, ACKDATA, has_packets)
    call gmcfSetSize(model_id, ACKDATA, has_packets)
    do while(has_packets .gt. 0)
        call gmcfShiftPendingFromInclusionSet(model_id, ACKDATA, packet, fifo_empty)
        call gmcfSetSize(model_id, ACKDATA, has_packets)
    end do
    call gmcfWaitFor(model_id, RESPDATA, 1, 1)
    call gmcfSetSize(model_id, RESPDATA, has_packets)
    do while(has_packets .gt. 0)
        call gmcfShiftPendingFromInclusionSet(model_id, RESPDATA, packet, fifo_empty)
        if (packet%data_id .ne. tag) then
            print*, 'Received unexpected packet'
        else
            call gmcfRead1DFloatArray(receiveBuffer, shape(receiveBuffer),packet)
        end if
        call gmcfSetSize(model_id, RESPDATA, has_packets)
    end do
    value = receiveBuffer(1)
end subroutine getGlobalOpNotMaster


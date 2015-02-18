subroutine program_message_rate(sys, tile, model_id) ! This replaces 'program main'
    use gmcfAPI
    implicit none
    integer(8) , intent(In) :: sys
    integer(8) , intent(In) :: tile
    integer , intent(In) :: model_id
    integer :: iterations, i, has_packets, fifo_empty
    integer :: clock_start, clock_end, clock_rate
    real(kind=4) :: total_time, messages_per_second
    type(gmcfPacket) :: packet
    real(kind=4), dimension(1) :: buffer
    iterations = 100000
    call gmcfInitCoupler(sys, tile, model_id)
    call system_clock(clock_start, clock_rate)
    if (mod(model_id, 2) .eq. 0) then
        buffer(1) = 1
        do i=1,iterations
            call gmcfWaitFor(model_id, REQDATA, model_id - 1, 1)
            call gmcfHasPackets(model_id, REQDATA, has_packets)
            do while(has_packets == 1)
                call gmcfShiftPending(model_id, REQDATA, packet, fifo_empty)
                select case(packet%data_id)
                case(1)
                    call gmcfSend1DFloatArray(model_id, buffer, shape(buffer), packet%data_id, packet%source, PRE, 1)
                case default
                    print*, 'Erroneous REQDATA'
                end select
                call gmcfHasPackets(model_id, REQDATA, has_packets)
            end do
            call gmcfWaitFor(model_id, ACKDATA, model_id - 1 , 1)
            call gmcfHasPackets(model_id, ACKDATA, has_packets)
            do while(has_packets == 1)
                call gmcfShiftPending(model_id, ACKDATA, packet, fifo_empty)
                if (packet%source .ne. model_id - 1) then
                    print*, 'Erroneous ACKDATA'
                end if
                call gmcfHasPackets(model_id, ACKDATA, has_packets)
            end do
        end do
    else
        do i=1,iterations
            call gmcfRequestData(model_id, 1, size(buffer), model_id + 1, PRE, 1)
            call gmcfWaitFor(model_id, RESPDATA, model_id + 1, 1)
            call gmcfHasPackets(model_id, RESPDATA, has_packets)
            do while(has_packets == 1)
                call gmcfShiftPending(model_id, RESPDATA, packet, fifo_empty)
                select case(packet%data_id)
                case(1)
                    call gmcfRead1DFloatArray(buffer, shape(buffer), packet)
                case default
                    print*, 'Erroneous RESPDATA'
                end select
                call gmcfHasPackets(model_id, RESPDATA, has_packets)
            end do
        end do
    end if
    call system_clock(clock_end, clock_rate)
    call gmcfFinished(model_id)
    if (mod(model_id, 2) .eq. 0) then
        total_time = (clock_end - clock_start)/real(clock_rate)
        messages_per_second = iterations / total_time
        print*, total_time, "s for ", iterations, " messages, a rate of ", messages_per_second, " messages per second."
    end if
end subroutine program_message_rate


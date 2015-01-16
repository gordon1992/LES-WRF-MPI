module gmcf_mpi_equivalent
use gmcfAPI
implicit none

! This is currently a skeleton with only communication between LES instances
! in mind.

contains

subroutine GMCF_MPI_AllReduceInPlaceRealSum()
    implicit none
    ! Equivalent to
    ! MPI_Gather(xs)
    ! if (master) then
    !     do for all received values - value
    !         x = x + value
    !     end do
    ! end if
    ! MPI_Broadcast(x)
end subroutine GMCF_API_AllReduceInPlaceRealSum

subroutine GMCF_MPI_AllReduceInPlaceRealMax()
    implicit none
    ! Equivalent to
    ! MPI_Gather(xs)
    ! if (master) then
    !     do for all recieved values - value
    !         if (value > x) then
    !             x = value
    !         end if
    !     end do
    ! end if
    ! MPI_Broadcast(x)          
end subroutine GMCF_API_AllReduceInPlaceRealMax

subroutine GMCF_MPI_AllReduceInPlaceRealMin()
    implicit none
    ! Equivalent to
    ! MPI_Gather(xs)
    ! if (master) then
    !     do for all recieved values - value
    !         if (value < x) then
    !             x = value
    !         end if
    !     end do
    ! end if
    ! MPI_Broadcast(x) 
end subroutine GMCF_API_AllReduceInPlaceRealMin

subroutine GMCF_MPI_Gather()
    implicit none
    ! Equivalent to
    ! if (master) then
    !     do for all other processes
    !         MPI_Recv()
    !     end do
    ! else
    !     MPI_Send()
    ! end if
end subroutine GMCF_MPI_Gather

subroutine GMCF_MPI_Broadcast()
    ! Equivalent to
    ! if (master) then
    !     do for all other processes
    !         MPI_Send()
    !     end do
    ! else
    !     MPI_Recv()
    ! end if
end subroutine GMCF_MPI_Broadcast

subroutine GMCF_MPI_ISend1DFloatArray()
    implicit none
    ! Equivalent to
    ! gmcfSend1DFloatArray()
end subroutine GMCF_MPI_ISend1DFloatArray

subroutine GMCF_MPI_Send1DFloatArray()
    implicit none
    ! Equivalent to
    ! GMCF_MPI_ISend1DFloatArray()
    ! GMCF_MPI_Wait()
end subroutine GMCF_MPI_Send1DFloatArray

subroutine GMCF_MPI_IRecv1DFloatArray()
    implicit none
    ! Equivalent to
    ! Nothing in this case? Within models doesn't need to request data from
    ! the sender unlike between models which does. Also MPI doesn't guarantee
    ! IRecv actually has any valid data until after MPI_Wait() returns. Since
    ! GMCF doesn't give unique labels to each request then there is nothing to
    ! do here...
end subroutine GMCF_MPI_IRecv1DFloatArray

subroutine GMCF_MPI_Recv1DFloatArray()
    implicit none
    ! Equivalent to
    ! GMCF_MPI_IRecv1DFloatArray()
    ! GMCF_MPI_Wait()
end subroutine GMCF_MPI_Recv1DFloatArray

subroutine GMCF_MPI_Wait()
    implicit none
    ! Equivalent to
    ! gmcfHasPackets()
    ! do while (hasPackets)
    !     gmcfShiftPending()
    !     select case (...)
    !         gmcfRead(1D/3D)FloatArray()
    !     etc ...
    ! end do
end subroutine GMCF_MPI_Wait

end module

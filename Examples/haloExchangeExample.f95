program haloExchangeExample
use mpi_helper
implicit none
integer, parameter :: rows = 10
integer, parameter :: columns = 8
integer :: colSize, rowSize ! Ignoring the halo boundaries, actual sizes will be + 2
integer, parameter :: topTag = 1
integer, parameter :: bottomTag = 2
integer, parameter :: leftTag = 3
integer, parameter :: rightTag = 4

! Mapping desired (excluding boundaries)
! 0 0 0 0 0 1 1 1 1 1
! 0 0 0 0 0 1 1 1 1 1
! 0 0 0 0 0 1 1 1 1 1
! 2 2 2 2 2 3 3 3 3 3
! 2 2 2 2 2 3 3 3 3 3
! 2 2 2 2 2 3 3 3 3 3

call main()

contains

subroutine main()
    implicit none
    call initialise_mpi()
    if (.NOT. (mpi_size .EQ. 4)) then
        call finalise_mpi()
        return
    endif
    colSize = columns/2
    rowSize = rows/2
    call haloExchange()
    call finalise_mpi()
end subroutine main

subroutine haloExchange()
    implicit none
    integer :: colDim, rowDim
    integer, dimension(colSize + 2, rowSize + 2) :: processArray    
    call getWorkingGridValues(colDim, rowDim)
    call initArray(processArray)
    call exchange2DHalos(processArray, colDim, rowDim)
end subroutine haloExchange

subroutine initArray(processArray)
    implicit none
    integer, dimension(:,:), intent(out) :: processArray
    integer :: col, row
    do col = 1, size(processArray, 1)
        do row = 1, size(processArray, 2)
            processArray(col, row) = -1
        end do
    end do
    do col = 2, size(processArray,1) - 1
        do row = 2, size(processArray,2) - 1
            processArray(col, row) = rank
        end do
    end do
end subroutine initArray

! Top left coordinates
subroutine getWorkingGridValues(colDim, rowDim)
    implicit none
    integer, intent(out) :: colDim, rowDim
    colDim = (colSize * modulo(rank, 2)) + 1
    rowDim = (rowSize * (rank / 2)) + 1
end subroutine getWorkingGridValues

subroutine exchange2DHalos(processArray, colDim, rowDim)
    implicit none
    integer, dimension(colSize + 2,rowSize + 2), intent(inout) :: processArray
    integer, intent(in) :: colDim, rowDim
    integer :: communicateWith, colType, rowType
    call MPI_TYPE_CONTIGUOUS(colSize, MPI_INT, colType, ierror)
    call checkMPIError()
    call MPI_TYPE_COMMIT(colType, ierror)
    call checkMPIError()
    call MPI_TYPE_VECTOR(rowSize, 1, colSize+2, MPI_INT, rowType, ierror)
    call checkMPIError()
    call MPI_TYPE_COMMIT(rowType, ierror)
    call checkMPIError()
    if (rowDim .ne. 1) then
        ! Top edge to send, bottom edge to receive
        communicateWith = rank - (rows / rowSize)
        print*, 'Process ', rank, ' needs to send top edge to ', communicateWith
        call MPI_SendRecv(processArray(2, 2), 1, rowType, communicateWith, topTag, & 
                          processArray(1, 2), 1, rowType, communicateWith, bottomTag, &
                          MPI_COMM_WORLD, ierror)
    end if
    if ((rowDim + rowSize - 1) .ne. rows) then
        ! Bottom edge to send, top edge to receive
        communicateWith = rank + (rows / rowSize)
        print*, 'Process ', rank, ' needs to send bottom edge to ', communicateWith
        call MPI_SendRecv(processArray(colSize+1, 2), 1, rowType, communicateWith, bottomTag, & 
                          processArray(colSize+2, 2), 1, rowType, communicateWith, topTag, & 
                          MPI_COMM_WORLD, ierror)
    end if
    if (colDim .ne. 1) then
        ! Left edge to send, right edge to receive
        communicateWith = rank - 1
        print*, 'Process ', rank, ' needs to send left edge to ', communicateWith
        call MPI_SendRecv(processArray(2, 2), 1, colType, communicateWith, leftTag, & 
                          processArray(2, 1), 1, colType, communicateWith, rightTag, &
                          MPI_COMM_WORLD, ierror)
    end if
    if ((colDim + colSize - 1) .ne. columns) then
        ! Right edge to send, left edge to receive
        communicateWith = rank + 1
        print*, 'Process ', rank, ' needs to send right edge to ', communicateWith
        call MPI_SendRecv(processArray(2, rowSize+1), 1, colType, communicateWith, rightTag, & 
                          processArray(2, rowSize+2), 1, colType, communicateWith, leftTag, & 
                          MPI_COMM_WORLD, ierror)
    end if
    call sleep(rank)
    call outputArray(processArray)
    call MPI_Type_Free(rowType, ierror)
    call checkMPIError()
    call MPI_Type_Free(colType, ierror)
    call checkMPIError()
end subroutine exchange2DHalos

subroutine outputArray(array)
    implicit none
    integer, dimension(:,:), intent(in) :: array
    integer :: col, row
    do col = 1, size(array,1)
        do row = 1, size(array, 2)
            if (array(col,row) .ne. -1) then
                write(*,"(I4)",advance="no") array(col,row)
            else
                write(*,"(A4)",advance="no") '-'
            end if
        end do
        write (*,*)
    end do
    write (*,*)
end subroutine outputArray

end program haloExchangeExample

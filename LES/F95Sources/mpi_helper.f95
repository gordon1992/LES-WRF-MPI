module mpi_helper
use mpi
implicit none

integer(kind=4) :: rank, mpi_size, ierror, status(MPI_STATUS_SIZE)
integer :: communicator
integer, parameter :: topTag = 1, bottomTag = 2, leftTag = 3, rightTag = 4

! Process Mapping
! 0 1 2 3
! 4 5 6 7
! 8 9 . .
! . . . .

contains

subroutine initialise_mpi()
    implicit none
    logical :: alreadyInitialised
    communicator = MPI_COMM_WORLD
    call MPI_Initialized(alreadyInitialised, ierror)
    call checkMPIError()
    if (.not. alreadyInitialised) then
        call MPI_Init(ierror)
        call checkMPIError()
    end if
    call MPI_COMM_Rank(communicator, rank, ierror)
    call checkMPIError()
    call MPI_COMM_Size(communicator, mpi_size, ierror)
    call checkMPIError()
end subroutine initialise_mpi

subroutine finalise_mpi()
    implicit none
    call MPI_Finalize(ierror)
    call checkMPIError()
end subroutine

subroutine checkMPIError()
    implicit none
    integer :: abortError
    if (ierror .ne. MPI_SUCCESS) then
        print*, ierror, " MPI error!"
        call MPI_Abort(communicator, ierror, abortError)
    end if
end subroutine checkMPIError

logical function isMaster()
    implicit none
    isMaster = rank .eq. 0
end function isMaster

logical function isTopRow(procPerRow)
    implicit none
    integer, intent(in) :: procPerRow
    isTopRow = rank .lt. procPerRow
end function isTopRow

logical function isBottomRow(procPerRow)
    implicit none
    integer, intent(in) :: procPerRow
    isBottomRow = rank .gt. (mpi_size - procPerRow - 1)
end function isBottomRow

logical function isLeftmostColumn(procPerRow)
    implicit none
    integer, intent(in) :: procPerRow
    isLeftmostColumn = modulo(rank, procPerRow) .eq. 0
end function isLeftmostColumn

logical function isRightmostColumn(procPerRow)
    implicit none
    integer, intent(in) :: procPerRow
    isRightmostColumn = modulo(rank, procPerRow) .eq. (procPerRow - 1)
end function isRightmostColumn

subroutine exchange2DHalos(array, rowSize, colSize, procPerRow)
    implicit none
    integer, intent(in) :: rowSize, colSize, procPerRow
    integer, dimension(rowSize + 2, colSize + 2), intent(inout) :: array
    integer :: commWith, colType, rowType
    call MPI_TYPE_CONTIGUOUS(rowSize, MPI_INT, colType, ierror)
    call checkMPIError()
    call MPI_TYPE_COMMIT(colType, ierror)
    call checkMPIError()
    call MPI_TYPE_VECTOR(colSize, 1, rowSize+2, MPI_INT, rowType, ierror)
    call checkMPIError()
    call MPI_TYPE_COMMIT(rowType, ierror)
    call checkMPIError()
    if (.not. isTopRow(procPerRow)) then
        ! Top edge to send, bottom edge to receive
        commWith = rank - procPerRow
        print*, 'Process ', rank, ' needs to send top edge to ', commWith
        call MPI_SendRecv(array(2, 2), 1, rowType, commWith, topTag, & 
                          array(1, 2), 1, rowType, commWith, bottomTag, &
                          communicator, status, ierror)
    end if
    if (.not. isBottomRow(procPerRow)) then
        ! Bottom edge to send, top edge to receive
        commWith = rank + procPerRow
        print*, 'Process ', rank, ' needs to send bottom edge to ', commWith
        call MPI_SendRecv(array(rowSize+1, 2), 1, rowType, commWith, bottomTag, & 
                          array(rowSize+2, 2), 1, rowType, commWith, topTag, & 
                          communicator, status, ierror)
    end if
    if (.not. isLeftmostColumn(procPerRow)) then
        ! Left edge to send, right edge to receive
        commWith = rank - 1
        print*, 'Process ', rank, ' needs to send left edge to ', commWith
        call MPI_SendRecv(array(2, 2), 1, colType, commWith, leftTag, & 
                          array(2, 1), 1, colType, commWith, rightTag, &
                          communicator, status, ierror)
    end if
    if (.not. isRightmostColumn(procPerRow)) then
        ! Right edge to send, left edge to receive
        commWith = rank + 1
        print*, 'Process ', rank, ' needs to send right edge to ', commWith
        call MPI_SendRecv(array(2, colSize+1), 1, colType, commWith, rightTag, & 
                          array(2, colSize+2), 1, colType, commWith, leftTag, & 
                          communicator, status, ierror)
    end if
    if (.not. isTopRow(procPerRow) .and. .not. isLeftmostColumn(procPerRow)) then
        ! There is a top left corner to specify
        array(1,1) = (array(2, 1) + array(1, 2)) / 2
    end if
    if (.not. isTopRow(procPerRow) .and. .not. isRightmostColumn(procPerRow)) then
        ! There is a top right corner to specify
        array(1, colSize + 2) = (array(2, colSize + 2) + &
                                 array(1, colSize + 1)) / 2
    end if
    if (.not. isBottomRow(procPerRow) .and. .not. isLeftmostColumn(procPerRow)) then
        ! There is a bottom left corner to specify
        array(rowSize + 2, 1) = (array(rowSize + 1, 1) + &
                                 array(rowSize + 2, 2)) / 2
    end if
    if (.not. isBottomRow(procPerRow) .and. .not. isRightmostColumn(procPerRow)) then
        ! There is a bottom right corner to specify
        array(rowSize + 2, colSize + 2) = (array(rowSize + 2, colSize + 1) + &
                                           array(rowSize + 1, colSize + 2)) / 2
    end if
    call sleep(rank + 1) ! to try and prevent process output being mangled by each other
    call outputArray(array)
    call MPI_Type_Free(rowType, ierror)
    call checkMPIError()
    call MPI_Type_Free(colType, ierror)
    call checkMPIError()
end subroutine exchange2DHalos

subroutine exchange2DHalos3DArray(array, rowSize, colSize, depthSize, procPerRow, k)
    implicit none
    integer, intent(in) :: rowSize, colSize, depthSize, procPerRow, k
    integer, dimension(rowSize + 2, colSize + 2, depthSize), intent(inout) :: array
    integer :: commWith, colType, rowType
    call MPI_TYPE_CONTIGUOUS(rowSize, MPI_INT, colType, ierror)
    call checkMPIError()
    call MPI_TYPE_COMMIT(colType, ierror)
    call checkMPIError()
    call MPI_TYPE_VECTOR(colSize, 1, rowSize+2, MPI_INT, rowType, ierror)
    call checkMPIError()
    call MPI_TYPE_COMMIT(rowType, ierror)
    call checkMPIError()
    if (.not. isTopRow(procPerRow)) then
        ! Top edge to send, bottom edge to receive
        commWith = rank - procPerRow
        print*, 'Process ', rank, ' needs to send top edge to ', commWith
        call MPI_SendRecv(array(2, 2, k), 1, rowType, commWith, topTag, & 
                          array(1, 2, k), 1, rowType, commWith, bottomTag, &
                          communicator, status, ierror)
    end if
    if (.not. isBottomRow(procPerRow)) then
        ! Bottom edge to send, top edge to receive
        commWith = rank + procPerRow
        print*, 'Process ', rank, ' needs to send bottom edge to ', commWith
        call MPI_SendRecv(array(rowSize+1, 2, k), 1, rowType, commWith, bottomTag, & 
                          array(rowSize+2, 2, k), 1, rowType, commWith, topTag, & 
                          communicator, status, ierror)
    end if
    if (.not. isLeftmostColumn(procPerRow)) then
        ! Left edge to send, right edge to receive
        commWith = rank - 1
        print*, 'Process ', rank, ' needs to send left edge to ', commWith
        call MPI_SendRecv(array(2, 2, k), 1, colType, commWith, leftTag, & 
                          array(2, 1, k), 1, colType, commWith, rightTag, &
                          communicator, status, ierror)
    end if
    if (.not. isRightmostColumn(procPerRow)) then
        ! Right edge to send, left edge to receive
        commWith = rank + 1
        print*, 'Process ', rank, ' needs to send right edge to ', commWith
        call MPI_SendRecv(array(2, colSize+1, k), 1, colType, commWith, rightTag, & 
                          array(2, colSize+2, k), 1, colType, commWith, leftTag, & 
                          communicator, status, ierror)
    end if
    if (.not. isTopRow(procPerRow) .and. .not. isLeftmostColumn(procPerRow)) then
        ! There is a top left corner to specify
        array(1,1, k) = (array(2, 1, k) + array(1, 2, k)) / 2
    end if
    if (.not. isTopRow(procPerRow) .and. .not. isRightmostColumn(procPerRow)) then
        ! There is a top right corner to specify
        array(1, colSize + 2, k) = (array(2, colSize + 2, k) + &
                                    array(1, colSize + 1, k)) / 2
    end if
    if (.not. isBottomRow(procPerRow) .and. .not. isLeftmostColumn(procPerRow)) then
        ! There is a bottom left corner to specify
        array(rowSize + 2, 1, k) = (array(rowSize + 1, 1, k) + &
                                    array(rowSize + 2, 2, k)) / 2
    end if
    if (.not. isBottomRow(procPerRow) .and. .not. isRightmostColumn(procPerRow)) then
        ! There is a bottom right corner to specify
        array(rowSize + 2, colSize + 2, k) = (array(rowSize + 2, colSize + 1, k) + &
                                              array(rowSize + 1, colSize + 2, k)) / 2
    end if
    call sleep(rank + 1) ! to try and prevent process output being mangled by each other
    call outputArray(array(:,:,k))
    call MPI_Type_Free(rowType, ierror)
    call checkMPIError()
    call MPI_Type_Free(colType, ierror)
    call checkMPIError()
end subroutine exchange2DHalos3DArray


subroutine outputArray(array)
    implicit none
    integer, dimension(:,:), intent(in) :: array
    integer :: col, row
    do row = 1, size(array, 1)
        do col = 1, size(array,2)
            if (array(row, col) .ne. -1) then
                write(*,"(I4)",advance="no") array(row,col)
            else
                write(*,"(A4)",advance="no") '-'
            end if
        end do
        write (*,*)
    end do
    write (*,*)
end subroutine outputArray

end module mpi_helper


program haloExchangeRealExample
use mpi_helper
implicit none
integer, parameter :: rows = 30, columns = 40, depthSize=2, dimensions = 2
integer, parameter :: procPerCol = 3, procPerRow = 4
integer :: dimensionSizes(dimensions)
logical :: periodicDimensions(dimensions)
integer :: coordinates(dimensions), neighbours(2*dimensions)
logical :: reorder
data dimensionSizes /procPerCol,procPerRow/, periodicDimensions /.false.,.false./, &
reorder /.false./
integer, parameter :: rowCount = rows / procPerCol
integer, parameter :: colCount = columns / procPerRow

integer :: leftThickness, rightThickness, topThickness, bottomThickness

call main()

contains

subroutine main()
    implicit none
    real(kind=4), dimension(:,:,:), allocatable :: processArray
    integer :: i
    leftThickness = 3
    rightThickness = 2
    topThickness = 2
    bottomThickness = 3
    call initialise_mpi()
    if (.NOT. (mpi_size .EQ. (procPerRow * procPerCol))) then
        call finalise_mpi()
        return
    endif
    call setupCartesianVirtualTopology(dimensions, dimensionSizes, periodicDimensions, coordinates, neighbours, reorder)
    allocate(processArray(rowCount + topThickness + bottomThickness, &
                          colCount + leftThickness + rightThickness, &
                          depthSize))
    call initArray(processArray)
    call exchangeRealHalos(processArray, procPerRow, neighbours, leftThickness, rightThickness, topThickness, bottomThickness)
    do i=1, depthSize
        call MPI_Barrier(communicator, ierror)
        call checkMPIError()
        call sleep(rank+1)
        call outputArrayReal(processArray(:,:,i))
    end do
    deallocate(processArray)
    call finalise_mpi()
end subroutine main

subroutine initArray(processArray)
    implicit none
    real(kind=4), dimension(:,:,:), intent(out) :: processArray
    integer :: col, row, depth
    do row = 1, size(processArray, 1)
        do col = 1, size(processArray, 2)
            do depth = 1, size(processArray, 3)
                processArray(row, col, depth) = -1.00
            end do
        end do
    end do
    do row = topThickness + 1, size(processArray, 1) - bottomThickness
        do col = leftThickness + 1, size(processArray, 2) - rightThickness
            do depth = 1, size(processArray, 3)
                processArray(row, col, depth) = rank
                if (col < rightThickness + leftThickness + 1 .or. &
                    col > size(processArray, 2) - rightThickness - leftThickness .or. &
                    row < topThickness + bottomThickness + 1 .or. &
                    row > size(processArray, 1) - bottomThickness - topThickness) then
                    processArray(row, col, depth) = processArray(row, col, depth) + 0.5
                end if
            end do
        end do
    end do
end subroutine initArray

end program haloExchangeRealExample

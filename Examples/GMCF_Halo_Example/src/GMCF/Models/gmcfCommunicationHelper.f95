module gmcfCommunicationHelper

use gmcfAPI
implicit none
integer, parameter :: topTag = 1, bottomTag = 2, leftTag = 3, rightTag = 4

contains

subroutine exchangeRealHalos(array, procPerRow, procPerCol, leftThickness, &
                                rightThickness, topThickness, &
                                bottomThickness, model_id)
    implicit none
    real(kind=4), dimension(:,:,:), intent(inout) :: array
    integer, intent(in) :: procPerRow, procPerCol, leftThickness, rightThickness, topThickness, bottomThickness
    integer :: commWith, r, c, d, rowCount, colCount, depthSize, model_id
    real(kind=4), dimension(:,:,:), allocatable :: leftRecv, leftSend, rightSend, rightRecv
    real(kind=4), dimension(:,:,:), allocatable :: topRecv, topSend, bottomSend, bottomRecv
    rowCount = size(array, 1) - topThickness - bottomThickness
    colCount = size(array, 2) - leftThickness - rightThickness
    depthSize = size(array, 3)
    allocate(leftRecv(rowCount, rightThickness, depthSize))
    allocate(rightSend(rowCount, leftThickness, depthSize))
    allocate(rightRecv(rowCount, leftThickness, depthSize))
    allocate(leftSend(rowCount, rightThickness, depthSize))
    allocate(topRecv(bottomThickness, colCount, depthSize))
    allocate(bottomSend(topThickness, colCount, depthSize))
    allocate(bottomRecv(topThickness, colCount, depthSize))
    allocate(topSend(bottomThickness, colCount, depthSize))
    ! Top edge to send, bottom edge to receive
    if (.not. isTopRow(model_id, procPerRow)) then
        commWith = model_id - procPerRow
        !print*, 'Model_id ', model_id, ' communicating with top neighbour ', commWith
        do r=1, bottomThickness
            do c=1, colCount
                do d=1, depthSize
                    topSend(r, c, d) = array(r + topThickness, c+leftThickness, d)
                end do
            end do
        end do
        call gmcfSend3DFloatArray(model_id, topSend, shape(topSend), topTag, commWith, PRE, 1)
    end if
    ! Bottom edge to send, top edge to receive
    if (.not. isBottomRow(model_id, procPerRow, procPerCol)) then
        commWith = model_id + procPerRow
        !print*, 'Model_id ', model_id, ' communicating with bottom neighbour ', commWith
        do r=1, topThickness
            do c=1, colCount
                do d=1, depthSize
                    bottomSend(r, c, d) = array(size(array, 1) - bottomThickness - topThickness + r, &
                                          c+leftThickness, &
                                          d)
                end do
            end do
        end do
        call gmcfSend3DFloatArray(model_id, bottomSend, shape(bottomSend), bottomTag, commWith, PRE, 1)
    end if
    ! Left edge to send, right edge to receive
    if (.not. isLeftmostColumn(model_id, procPerRow)) then
        commWith = model_id - 1
        !print*, 'Model_id ', model_id, ' communicating with left neighbour ', commWith
        do r=1, rowCount
            do c=1, rightThickness
                do d=1, depthSize
                    leftSend(r, c, d) = array(r+topThickness, c + leftThickness, d)
                end do
            end do
        end do
        call gmcfSend3DFloatArray(model_id, leftSend, shape(leftSend), leftTag, commWith, PRE, 1)
    end if
    ! Right edge to send, left edge to receive
    if (.not. isRightmostColumn(model_id, procPerRow)) then
        commWith = model_id + 1
        !print*, 'Model_id ', model_id, ' communicating with right neighbour ', commWith
        do r=1, rowCount
            do c=1, leftThickness
                do d=1, depthSize
                    rightSend(r, c, d) = array(r+topThickness, &
                                               size(array, 2) - rightThickness - leftThickness + c,&
                                               d)
                end do
            end do
        end do
        call gmcfSend3DFloatArray(model_id, rightSend, shape(rightSend), rightTag, commWith, PRE, 1)
    end if
    call recvHaloBoundaries(leftRecv, rightRecv, topRecv, bottomRecv, model_id, procPerRow, procPerCol)
    if (.not. isTopRow(model_id, procPerRow)) then
        ! Top edge to send, bottom edge to receive
        do r=1, topThickness
            do c=1, colCount
                do d=1, depthSize
                    array(r, c+leftThickness, d) = bottomRecv(r, c, d)
                end do
            end do
        end do
    end if
    if (.not. isBottomRow(model_id, procPerRow, procPerCol)) then
        ! Bottom edge to send, top edge to receive
        do r=1, bottomThickness
            do c=1, colCount
                do d=1, depthSize
                    array(size(array, 1) - bottomThickness + r, c+leftThickness, d) = topRecv(r, c, d)
                end do
            end do
        end do
    end if
    if (.not. isLeftmostColumn(model_id, procPerRow)) then
        ! Left edge to send, right edge to receive
        do r=1, rowCount
            do c=1, leftThickness
                do d=1, depthSize
                    array(r+topThickness, c, d) = rightRecv(r, c, d)
                end do
            end do
        end do
    end if
    if (.not. isRightmostColumn(model_id, procPerRow)) then
        ! Right edge to send, left edge to receive
        do r=1, rowCount
            do c=1, rightThickness
                do d=1, depthSize
                    array(r+topThickness, size(array, 2) - rightThickness + c, d) = leftRecv(r, c, d)
                end do
            end do
        end do
    end if
    call waitForHaloAcks(model_id, procPerRow, procPerCol)
    deallocate(leftRecv)
    deallocate(leftSend)
    deallocate(rightSend)
    deallocate(rightRecv)
    deallocate(topRecv)
    deallocate(topSend)
    deallocate(bottomSend)
    deallocate(bottomRecv)
end subroutine exchangeRealHalos

subroutine recvHaloBoundaries(leftRecv, rightRecv, topRecv, bottomRecv, model_id, procPerRow, procPerCol)
    implicit none
    real(kind=4), dimension(:,:,:), intent(out) :: leftRecv, rightRecv, topRecv, bottomRecv
    integer, intent(in) :: model_id, procPerRow, procPerCol
    integer :: fifo_empty, i, sender
    integer, dimension(4) :: neighbours
    type(gmcfPacket) :: packet
    neighbours = -1
    if (.not. isTopRow(model_id, procPerRow)) then
        neighbours(1) = model_id - procPerRow
    end if
    if (.not. isBottomRow(model_id, procPerRow, procPerCol)) then
        neighbours(2) = model_id + procPerRow
    end if
    if (.not. isLeftmostColumn(model_id, procPerRow)) then
        neighbours(3) = model_id - 1
    end if
    if (.not. isRightmostColumn(model_id, procPerRow)) then
        neighbours(4) = model_id + 1
    end if
    do while (sum(neighbours) .ne. -4)
        do i=1,4
            if (neighbours(i) .ne. -1) then
                sender = neighbours(i)
                neighbours(i) = -1
                exit
            end if
        end do
        call gmcfShiftPending(model_id, sender, RESPDATA, packet, fifo_empty)
        select case (packet%data_id)
            case (topTag)
                call gmcfRead3DFloatArray(topRecv, shape(topRecv), packet)
            case (bottomTag)
                call gmcfRead3DFloatArray(bottomRecv, shape(bottomRecv), packet)
            case (leftTag)
                call gmcfRead3DFloatArray(leftRecv, shape(leftRecv), packet)
            case (rightTag)
                call gmcfRead3DFloatArray(rightRecv, shape(rightRecv), packet)
            case default
                print*, 'Model_id  ', model_id, ' received an unexpected RESPDATA from ', &
                packet%source, ' with tag ', packet%data_id, ' asked for sender ', sender
        end select
    end do
end subroutine recvHaloBoundaries

subroutine waitForHaloAcks(model_id, procPerRow, procPerCol)
    implicit none
    integer, intent(in) :: model_id, procPerRow, procPerCol
    integer :: fifo_empty, i, sender
    type(gmcfPacket) :: packet
    integer, dimension(4) :: neighbours
    neighbours = -1
    if (.not. isTopRow(model_id, procPerRow)) then
        call gmcfWaitFor(model_id, ACKDATA, model_id - procPerRow, 1)
        neighbours(1) = model_id - procPerRow
    end if
    if (.not. isBottomRow(model_id, procPerRow, procPerCol)) then
        call gmcfWaitFor(model_id, ACKDATA, model_id + procPerRow, 1)
        neighbours(2) = model_id + procPerRow
    end if
    if (.not. isLeftmostColumn(model_id, procPerRow)) then
        call gmcfWaitFor(model_id, ACKDATA, model_id - 1, 1)
        neighbours(3) = model_id - 1
    end if
    if (.not. isRightmostColumn(model_id, procPerRow)) then
        call gmcfWaitFor(model_id, ACKDATA, model_id + 1, 1)
        neighbours(4) = model_id + 1
    end if
    do while (sum(neighbours) .ne. -4)
        do i=1,4
            if (neighbours(i) .ne. -1) then
                sender = neighbours(i)
                neighbours(i) = -1
                exit
            end if
        end do
        call gmcfShiftPending(model_id, sender, ACKDATA, packet, fifo_empty)
    end do
end subroutine waitForHaloAcks

logical function isMaster(model_id)
    implicit none
    integer, intent(in) :: model_id
    isMaster = model_id .eq. 1
end function isMaster

logical function isTopRow(model_id, procPerRow)
    implicit none
    integer, intent(in) :: model_id, procPerRow
    isTopRow = model_id .le. procPerRow
end function isTopRow

logical function isBottomRow(model_id, procPerRow, procPerCol)
    implicit none
    integer, intent(in) :: model_id, procPerRow, procPerCol
    integer :: instanceCount
    instanceCount = procPerRow * procPerCol
    isBottomRow = model_id .gt. (instanceCount - procPerRow)
end function isBottomRow

logical function isLeftmostColumn(model_id, procPerRow)
    implicit none
    integer, intent(in) :: model_id, procPerRow
    isLeftmostColumn = modulo(model_id - 1, procPerRow) .eq. 0
end function isLeftmostColumn

logical function isRightmostColumn(model_id, procPerRow)
    implicit none
    integer, intent(in) :: model_id, procPerRow
    isRightmostColumn = modulo(model_id - 1, procPerRow) .eq. (procPerRow - 1)
end function isRightmostColumn

subroutine initArray(array, model_id, topThickness, bottomThickness, leftThickness, rightThickness)
    implicit none
    real(kind=4), dimension(:,:,:), intent(out) :: array
    integer, intent(in) :: model_id, topThickness, bottomThickness, leftThickness, rightThickness
    integer :: r, c, d
    do r=1,size(array,1)
        do c=1,size(array,2)
            do d=1,size(array,3)
                array(r, c, d) = -1
            end do
        end do
    end do
    do r=1+topThickness,size(array,1)-bottomThickness
        do c=1+leftThickness,size(array,2)-rightThickness
            do d=1,size(array,3)
                array(r, c, d) = model_id
            end do
        end do
    end do
end subroutine initArray

subroutine outputArrayReal(array)
    implicit none
    real(kind=4), dimension(:,:), intent(in) :: array
    integer :: col, row
    do row = 1, size(array, 1)
        do col = 1, size(array,2)
            if (array(row, col) .ne. -1.0) then
                write(*,"(F6.2)",advance="no") array(row,col)
            else
                write(*,"(A6)", advance="no") '-'
            end if
        end do
        write (*,*)
    end do
    write (*,*)
end subroutine outputArrayReal

end module gmcfCommunicationHelper


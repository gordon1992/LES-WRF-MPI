module module_boundp

! GR: Ignore boundp for halo exchange. This would kill performance!
! GR: Actually, we need this for correctness (UrbanFlow = NaN... is due to
! non-convergence).

contains

subroutine boundp2(jm,im,p,km)
    use common_sn ! create_new_include_statements() line 102
    implicit none
    integer, intent(In) :: im
    integer, intent(In) :: jm
    integer, intent(In) :: km
    real(kind=4), dimension(0:ip+2,0:jp+2,0:kp+1) , intent(InOut) :: p
    integer :: i, j
! 
! --computational boundary(neumann condition)
    do j = 0,jm+1
        do i = 0,im+1
            p(i,j,   0) = p(i,j,1)
            p(i,j,km+1) = p(i,j,km)
        end do
    end do
#ifdef MPI && !defined(FAST_MPI)
! --halo exchanges
    call exchangeAll2DHalos3DRealArray(p, size(p, 1) - 2, size(p, 2) - 2, size(p, 3), procPerRow)
#endif
end subroutine boundp2

subroutine boundp1(km,jm,p,im)
    use common_sn ! create_new_include_statements() line 102
    implicit none
    integer, intent(In) :: im
    integer, intent(In) :: jm
    integer, intent(In) :: km
    real(kind=4), dimension(0:ip+2,0:jp+2,0:kp+1) , intent(InOut) :: p
#if !defined(MPI) || (PROC_PER_ROW==1) || defined(FAST_MPI)
    integer :: i, j, k
#else
    integer :: j, k
#endif
! 
! --computational boundary(neumann condition)
#ifdef MPI && !defined(FAST_MPI)
    if (isTopRow(procPerRow) .or. isBottomRow(procPerRow)) then
#endif
        do k = 0,km+1
            do j = 0,jm+1
#ifdef MPI && !defined(FAST_MPI)
                if (isTopRow(procPerRow)) then
#endif
                    p(   0,j,k) = p(1 ,j,k)
#ifdef MPI && !defined(FAST_MPI)
                else
#endif
                    p(im+1,j,k) = p(im,j,k)
#ifdef MPI && !defined(FAST_MPI)
                end if
#endif
            end do
        end do
#ifdef MPI && !defined(FAST_MPI)
    end if
#endif
! --side flow exchanges
#if !defined(MPI) || (PROC_PER_ROW==1) || defined(FAST_MPI)
    do k = 0,km+1
        do i = 0,im+1
            p(i,   0,k) = p(i,jm,k) ! right to left
            p(i,jm+1,k) = p(i, 1,k) ! left to right
        end do
    end do
#else
    if (isLeftMostColumn(procPerRow)) then
        call sideRightToLeftMPIAllExchange(p, size(p, 1) - 2, size(p, 2) - 2, size(p, 3), procPerRow, 1)
        call sideLeftToRightMPIAllExchange(p, size(p, 1) - 2, size(p, 2) - 2, size(p, 3), procPerRow, 2)
    else if (isRightMostColumn(procPerRow)) then
        call sideRightToLeftMPIAllExchange(p, size(p, 1) - 2, size(p, 2) - 2, size(p, 3), procPerRow, jp+1)
        call sideLeftToRightMPIAllExchange(p, size(p, 1) - 2, size(p, 2) - 2, size(p, 3), procPerRow, jp+2)
    end if
#endif
#ifdef MPI
! --halo exchanges
    call exchangeAll2DHalos3DRealArray(p, size(p, 1) - 2, size(p, 2) - 2, size(p, 3), procPerRow)
#endif
end subroutine boundp1

end module module_boundp


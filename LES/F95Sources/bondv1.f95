module module_bondv1

contains

subroutine bondv1(jm,u,z2,dzn,v,w,km,n,im,dt,dxs)
    use common_sn ! create_new_include_statements() line 102
    implicit none
    real(kind=4), intent(In) :: dt
    real(kind=4), dimension(0:ip) , intent(In) :: dxs
    real(kind=4), dimension(-1:kp+2) , intent(In) :: dzn
    integer, intent(In) :: im, jm, km, n
    real(kind=4), dimension(0:ip+1,-1:jp+1,0:kp+1) , intent(InOut) :: u
    real(kind=4), dimension(0:ip+1,-1:jp+1,0:kp+1) , intent(InOut) :: v
    real(kind=4), dimension(0:ip+1,-1:jp+1,-1:kp+1) , intent(InOut) :: w
    real(kind=4), dimension(kp+2) , intent(In) :: z2
    real(kind=4) :: u_val
    integer :: i, j, k, startI, endI
    real(kind=4) :: aaa, bbb, uout
! 
! 
! -------------------inflow-------------------
! 
!      Setup for initial wind profile
! 
#ifdef MPI
    if (isTopRow(procPerRow)) then
#endif
        do i = 0,1
            do k = 1,78 ! kp = 90 so OK
                do j = 1,jm
                    u_val = 5.*((z2(k)+0.5*dzn(k))/600.)**0.2
                    !print *, u_val
                    u(i,j,k) = u_val
                    v(i,j,k) = 0.0
                    w(i,j,k) = 0.0
                end do
            end do
        end do

        do i = 0,1
            do k = 79,km
                do j = 1,jm
                    u(i,j,k) = u(i,j,77)
                    v(i,j,k) = 0.0
                    w(i,j,k) = 0.0
                end do
            end do
        end do
#ifdef MPI
    end if
#endif

#if ICAL == 0
    !if(ical == 0.and.n == 1) then
#ifdef MPI
    if (isTopRow(procPerRow)) then
        startI = 2
    else
        startI = 0
    end if
    if (isBottomRow(procPerRow)) then
        endI = ip
    else
        endI = ip + 1
    end if
#else
    startI = 2
    endI = im
#endif
    if(n == 1) then
        do k = 1,km
            do j = 1,jm
                do i = startI, endI
                    u(i,j,k) = u(1,j,k)
                    v(i,j,k) = v(1,j,k)
                    w(i,j,k) = w(1,j,k)
                end do
            end do
        end do
    endif
#endif  
    
#ifdef WV_DEBUG
    print *, 'F95: BONDV1_INIT_UVW: UVWSUM: ',n,sum(u)+sum(v)+sum(w)
#endif

! ------------- outflow condition ------------
!      advective condition
! 
#ifdef MPI
    if (isBottomRow(procPerRow)) then
#endif
        aaa = 0.0
        bbb = 0.0
        do k = 1,km
            do j = 1,jm
                aaa = amax1(aaa,u(im,j,k))
                bbb = amin1(bbb,u(im,j,k))
            end do
        end do
        uout = (aaa+bbb)/2.
#ifdef WV_DEBUG
        print *, 'F95: UOUT: ',uout
#endif

        do k = 1,km
            do j = 1,jm
                u(im,j,k) = u(im,j,k)-dt*uout *(u(im,j,k)-u(im-1,j,k))/dxs(im)
            end do
        end do

        do k = 1,km
            do j = 1,jm
                v(im+1,j,k) = v(im+1,j,k)-dt*uout *(v(im+1,j,k)-v(im,j,k))/dxs(im)
            end do
        end do

        do k = 1,km
            do j = 1,jm
                w(im+1,j,k) = w(im+1,j,k)-dt*uout *(w(im+1,j,k)-w(im,j,k))/dxs(im)
            end do
        end do
#ifdef MPI
    end if
#endif
#if !defined(MPI) || (PROC_PER_ROW==1)
! --side flow condition; periodic
    do k = 0,km+1
        do i = 0,im+1
            u(i,   0,k) = u(i,jm  ,k)
            u(i,jm+1,k) = u(i,   1,k)
        end do
    end do 

    do k = 0,km+1
        do i = 0,im+1
            v(i,   0,k) = v(i,jm  ,k)
            v(i,jm+1,k) = v(i,   1,k)
        end do
    end do

    do k = 0,km
        do i = 0,im+1
            w(i,   0,k) = w(i,jm  ,k)
            w(i,jm+1,k) = w(i,   1,k)
        end do
    end do 
#else
    if (isLeftMostColumn(procPerRow)) then
        call sideflowRightLeft(u, size(u, 1) - 2, size(u, 2) - 2, size(u, 3), procPerRow, 1)
        call sideflowLeftRight(u, size(u, 1) - 2, size(u, 2) - 2, size(u, 3), procPerRow, 2)
    else if (isRightMostColumn(procPerRow)) then
        call sideflowRightLeft(u, size(u, 1) - 2, size(u, 2) - 2, size(u, 3), procPerRow, jp+1)
        call sideflowLeftRight(u, size(u, 1) - 2, size(u, 2) - 2, size(u, 3), procPerRow, jp+2)
    end if
    if (isLeftMostColumn(procPerRow)) then
        call sideflowRightLeft(v, size(v, 1) - 2, size(v, 2) - 2, size(v, 3), procPerRow, 1)
        call sideflowLeftRight(v, size(v, 1) - 2, size(v, 2) - 2, size(v, 3), procPerRow, 2)
    else if (isRightMostColumn(procPerRow)) then
        call sideflowRightLeft(v, size(v, 1) - 2, size(v, 2) - 2, size(v, 3), procPerRow, jp+1)
        call sideflowLeftRight(v, size(v, 1) - 2, size(v, 2) - 2, size(v, 3), procPerRow, jp+2)
    end if
    if (isLeftMostColumn(procPerRow)) then
        call sideflowRightLeft(w, size(w, 1) - 2, size(w, 2) - 2, size(w, 3), procPerRow, 1)
        call sideflowLeftRight(w, size(w, 1) - 2, size(w, 2) - 2, size(w, 3), procPerRow, 2)
    else if (isRightMostColumn(procPerRow)) then
        call sideflowRightLeft(w, size(w, 1) - 2, size(w, 2) - 2, size(w, 3), procPerRow, jp+1)
        call sideflowLeftRight(w, size(w, 1) - 2, size(w, 2) - 2, size(w, 3), procPerRow, jp+2)
    end if
#endif
! -------top and underground condition
    do j = 0,jm+1
        do i = 0,im+1
            u(i,j,   0) = -u(i,j, 1)
            u(i,j,km+1) = u(i,j,km)
        end do
    end do

    do j = 0,jm+1
        do i = 0,im+1
            v(i,j,   0) = -v(i,j, 1)
            v(i,j,km+1) = v(i,j,km)
        end do
    end do

    do j = -1,jm+1 ! 2 !WV: I think this is wrong: j = jm+2 is not allocated!
        do i = -1,im+1
            w(i,j, 0) = 0.0
            w(i,j,km) = 0.0
        end do
    end do

! =================================
#ifdef MPI
! --halo exchanges
    call exchangeRealHalos(u, size(u, 1) - 2, size(u, 2) - 2, size(u, 3), procPerRow)
    call exchangeRealHalos(v, size(v, 1) - 2, size(v, 2) - 2, size(v, 3), procPerRow)
    call exchangeRealHalos(w, size(w, 1) - 2, size(w, 2) - 2, size(w, 3), procPerRow)
#endif
#ifdef WV_DEBUG
    print *,'F95 UVWSUM after bondv1:',sum(u)+sum(v)+sum(w)
#endif
end subroutine bondv1

end module module_bondv1


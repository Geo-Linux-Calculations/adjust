C %P%
      SUBROUTINE AFVS (ACARD)
      IMPLICIT DOUBLE PRECISION (A-H, O-Z)
      IMPLICIT INTEGER (I-N)
      CHARACTER*99 SCCSID
      CHARACTER*88 ACARD
**     2/7/2003  ** override input covariance matrix  by scaling horizontal and vertical components
** v 4.32vf
       LOGICAL IVCGPS,VSlogic
      COMMON/VCREC/SIGH,SIGU, VFHOR,VFUP, IVCGPS
      CHARACTER*13 VSPROJ
      PARAMETER (MAXPRJ=2500)
      COMMON/VSREC/SIGHS(MAXPRJ), SIGUS(MAXPRJ), ISETHU, VSPROJ(MAXPRJ),
     &             VSlogic
      COMMON/UNITS/LUNIT

C      SCCSID='$Id: afvc.for 66104 2012-10-18 14:11:43Z jarir.saleh $	20$Date: 2007/11/20 15:21:33 $ NGS'
      ISETHU=ISETHU+1
      IF(ISETHU.GT.MAXPRJ) THEN
        WRITE(LUNIT,999) MAXPRJ
 999    FORMAT(//' PROGRAM MAXIMUM OF ',I5,' VS RECORDS HAS BEEN',
     &  ' EXCEEDED.')
        CALL ABORT2
      ENDIF

C
      READ (ACARD,1) SIGHS(ISETHU),SIGUS(ISETHU),VSPROJ(ISETHU)
    1 FORMAT (2X, 2f8.3, 1X, A13)
      VSlogic = .TRUE.
      RETURN
      END

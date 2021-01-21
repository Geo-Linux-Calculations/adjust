C %P%

      LOGICAL FUNCTION VFCGPS (IUO,IUO2,B,G,A,NX,GOOGE)
********************************************************************************
* REFORM OBS. EQS., COMPUTE INVERSE AND V.F.'S, AND TEST CONVERGE
********************************************************************************
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      IMPLICIT INTEGER (I-N)
      PARAMETER ( LENC = 10 )
      PARAMETER (NVECS=700)
      LOGICAL GETA
      LOGICAL LSS, LUP, LMSL, LABS, LADJ, LUPI
      LOGICAL FATAL,FATAL2,FIXVF,PROP,INVERT
      DIMENSION B(*),G(*),A(*),NX(*),GOOGE(*)
      DIMENSION IC(LENC),C(LENC)
      DIMENSION COVECF(3,3), C3(3,LENC)
      COMMON /OPT/    AX, E2, DMSL, DGH, VM, VP, CTOL, ITMAX, IMODE,
     &                LMSL, LSS, LUP, LABS, LADJ, LUPI
      COMMON /CONST/  PI, PI2, RAD
      COMMON /STRUCT/ NSTA, NAUX, NUNK, IDIM, NSTAS, NOBS, NCON, NZ,NGRT
      COMMON/UNITS/ LUNIT
      COMMON /GPSHUS/ GPSVS(NVECS*3,2), GPSRNS(NVECS*3)

** v 4.32vf
      LOGICAL IVCGPS,VSlogic
      COMMON/VCREC/SIGH,SIGU, VFHOR,VFUP, IVCGPS
      CHARACTER*13 VSPROJ
      PARAMETER (MAXPRJ=2500)
      COMMON/VSREC/SIGHS(MAXPRJ), SIGUS(MAXPRJ), ISETHU, VSPROJ(MAXPRJ),
     &             VSlogic
      CHARACTER*99 SCCSID

***10-31-03
*      common/vcrec2/vtvhor, vtvup, vtvcor, rnhor, rnup
C
C      SCCSID='$Id: vfcgps.for 115801 2020-05-14 06:21:11Z michael.dennis $	20$Date: 2008/08/25 16:04:22 $ NGS'
      VFCGPS = .TRUE.
      VFSTOL = 1.D-3
      VFCTOL = 1.D-3

***  COMPLETE THE COMPUTATION OF THE GOOGE NUMBERS

      DO 44 I = 1,NUNK
        IF ( .NOT. GETA(I,I,VAL,A,NX)) THEN
          CALL INVIUN (I,ISN,ITYP,ICODE)
          WRITE (LUNIT,55) I,ISN,ITYP,ICODE
   55     FORMAT ('0 FATAL ERROR IN GOOGE COMPUTATION IN VFCGPS',4I8)
          CALL ABORT2
        ENDIF

***  ALLOW FOR GOOGE OF ZERO IF SOLVING A SINGULAR SYSTEM

        VAL2 = VAL*VAL
        GOOGE(I) = DIVID( VAL2, GOOGE(I) )
   44 CONTINUE

*** INVERT WITHIN PROFILE

      IF (IMODE .NE. 1) THEN
        IF ( .NOT. INVERT(A,NX)) THEN
          WRITE (LUNIT,666)
  666     FORMAT ('0STATE ERROR IN INVERSION OF A IN VFCGPS')
          CALL ABORT2
        ENDIF
      ENDIF

*** INITIALIZE VARIANCE FACTORS

      VTVHOR=0.D0
      VTVUP=0.D0
      VTVCOR=0.D0
      RNHOR=0.D0
      RNUP=0.D0

*** LOOP OVER THE OBSERVATIONS

      FATAL2 = .FALSE.
      FATAL = .FALSE.
      REWIND IUO
      REWIND IUO2

  100 READ (IUO,END=777) KIND,ISN,JSN,IC,C,LENG,CMO,OBSB,SD,IOBS,
     &                   IVF,IAUX,IGRT
      IF (KIND .LE. 999) THEN
        IF (KIND .LT. 18  .OR.  KIND .GT. 20) THEN
          CALL FORMC (KIND,C,B,ISN,JSN,IAUX,IGRT)
          CALL COMPOB (KIND,OBS0,B,OBSB,ISN,JSN,IAUX,IGRT)
          IF (KIND .EQ. 1  .OR.  KIND .EQ. 2) THEN
            CMO = OBS0
          ELSE
            CMO = OBS0 - OBSB
            IF ( KIND .EQ.  8  .OR.  KIND .EQ. 10  .OR.
     &           KIND .EQ. 11  .OR.  KIND .EQ. 12) THEN
              IF (CMO .GT. PI) THEN
                CMO = CMO - PI - PI
              ELSEIF (CMO .LT. -PI) THEN
                CMO = CMO + PI + PI
              ENDIF
            ENDIF
          ENDIF
          CALL BIGL (KIND,ISN,JSN,IOBS,IVF,CMO,SD,FATAL)
          WRITE (IUO2) KIND,ISN,JSN,IC,C,LENG,CMO,OBSB,SD,IOBS,
     &                 IVF,IAUX,IGRT

        ELSEIF (KIND .EQ. 18) THEN
*** CORRELATED TYPE (DOPPLER)

          OBSBX = OBSB
          SDX = SD
          IOBSX = IOBS
          CALL FORMC (KIND,C,B,ISN,JSN,IAUX,IGRT)
          DO 101 I = 1, LENG
            C3(1,I) = C(I)
  101     CONTINUE
           CALL BIGL (KIND,ISN,JSN,IOBS,IVF,CMO,SD,FATAL)
          WRITE (IUO2) KIND,ISN,JSN,IC,C,LENG,CMO,OBSB,SD,IOBS,
     &                 IVF,IAUX,IGRT

        ELSEIF (KIND .EQ. 18) THEN

         CALL COMPOB (KIND,OBS0X,B,OBSBX,ISN,JSN,IAUX,IGRT)
          CMOX = OBS0X - OBSBX
          CALL BIGL (KIND,ISN,JSN,IOBSX,IVF,CMOX,SDX,FATAL)
          WRITE (IUO2) KIND,ISN,JSN,IC,C,LENG,CMOX,OBSBX,SDX,IOBSX,
     &                 IVF,IAUX,IGRT
          READ (IUO,END=777) KIND,ISN,JSN,IC,C,LENG,CMO,OBSBY,SDY,IOBSY,
     &                       IVF,IAUX,IGRT
          CALL FORMC (KIND,C,B,ISN,JSN,IAUX,IGRT)
          DO 102 I = 1, LENG
            C3(2,I) = C(I)
  102     CONTINUE
          CALL COMPOB (KIND,OBS0Y,B,OBSBY,ISN,JSN,IAUX,IGRT)
          CMOY = OBS0Y - OBSBY
          CALL BIGL (KIND,ISN,JSN,IOBSY,IVF,CMOY,SDY,FATAL)
          WRITE (IUO2) KIND,ISN,JSN,IC,C,LENG,CMOY,OBSBY,SDY,IOBSY,
     &                 IVF,IAUX,IGRT
          READ (IUO,END=777) KIND,ISN,JSN,IC,C,LENG,CMO,OBSBZ,SDZ,IOBSZ,
     &                       IVF,IAUX,IGRT
          CALL FORMC (KIND,C,B,ISN,JSN,IAUX,IGRT)
          DO 103 I = 1, LENG
            C3(3,I) = C(I)
  103     CONTINUE
          CALL COMPOB (KIND,OBS0Z,B,OBSBZ,ISN,JSN,IAUX,IGRT)
          CMOZ = OBS0Z - OBSBZ
          CALL BIGL (KIND,ISN,JSN,IOBS,IVF,CMOZ,SDZ,FATAL)
          WRITE (IUO2) KIND,ISN,JSN,IC,C,LENG,CMOZ,OBSBZ,SDZ,IOBSZ,
     &                 IVF,IAUX,IGRT
          READ (IUO,END=777) ISIGNL, ( (COVECF(I,J), J = 1,3), I = 1,3 )
          WRITE (IUO2) ISIGNL, ( (COVECF(I,J), J = 1,3), I = 1,3 )
        ENDIF

*** GPS OBSERVATIONS

      ELSE
        NVEC = ISN
        IAUX = JSN
        NR = 3*NVEC
        WRITE (IUO2) KIND,ISN,JSN,IC,C,LENG,CMO,OBSB,SD,IOBS,
     &               IVF,IAUX,IGRT
        CALL FORMG3 (IUO,IUO2,NVEC,NR,G,B,A,NX,FATAL,IVF,IAUX,IGRT,
     &     VTVHOR,VTVUP,VTVCOR,RNHOR,RNUP)
      ENDIF
      GO TO 100

*** ABORT DUE TO LARGE MISCLOSURES

  777 IF (FATAL) THEN
        CALL LINE (3)
        WRITE (LUNIT,3) VM
    3   FORMAT ('0TERMINATED DUE TO MISCLOSURES (C-O)/SD EXCEEDING ' ,
     &          F11.1/)
        CALL ABORT2
      ENDIF

      REWIND IUO
      REWIND IUO2

*** EXCHANGE PRIMARY/SECONDARY OBS EQ FILE INDICATOR

      ITEMP = IUO
      IUO = IUO2
      IUO2 = ITEMP

*** HEADING

      CALL LINE (3)
      WRITE (LUNIT,20)
****12-02-03***********
*   20 FORMAT (/' TYPE            WEIGHTED SUM OF SQUARES   REDUNDANCY ',
*     &    '        FACTOR  ESTIMATED S.D.'/)
   20 FORMAT (/' TYPE            WEIGHTED SUM OF SQUARES   CORRECTED ',
     & 'SUM OF SQUARES    REDUNDANCY       FACTOR  ESTIMATED S.D.'/)
*************************

*** COMPUTE VARIANCE FACTORS AND TEST CONVERGENCE

****12-02-03************
      CVTVH = VTVHOR + 2.D0*VTVCOR/3.D0
      CVTVU = VTVUP + VTVCOR/3.D0
**************************
      VFHOR=CVTVH/RNHOR
      VFUP=CVTVU/RNUP
      VFHOR=SQRT(VFHOR)
      VFUP= SQRT(VFUP)
      SIGH=SIGH*VFHOR
      SIGU=SIGU*VFUP
      IF (DABS(VFHOR-1.D0) .GT. VFCTOL) VFCGPS = .FALSE.
      IF (DABS(VFUP -1.D0) .GT. VFCTOL) VFCGPS = .FALSE.

      CALL LINE (1)
*****12-02-03**************
*      WRITE (LUNIT,12) 'HORIZONTAL OBSERVATIONS ',VTVHOR,RNHOR,VFHOR,
*     & SIGH
*      WRITE (LUNIT,12) 'UP         OBSERVATIONS ',VTVUP,RNUP,VFUP, SIGU
*      WRITE (LUNIT,12) 'CORRELATED OBSERVATIONS ',VTVCOR
*   12     FORMAT (1X,A24,3F14.3, F8.3)

           WRITE (LUNIT,12) 'HORIZONTAL OBSERVATIONS ',VTVHOR,CVTVH,
     & RNHOR,VFHOR,SIGH
      WRITE (LUNIT,12) 'UP         OBSERVATIONS ',VTVUP,CVTVU,
     & RNUP,VFUP,SIGU
      WRITE (LUNIT,12) 'CORRELATED OBSERVATIONS ',VTVCOR
   12     FORMAT (1X,A24,F14.3,13X,4F14.3)

***************************
      IF(RNHOR.LT.VFSTOL .OR. RNUP.LT.VFSTOL) THEN 
        CALL LINE (1)
        WRITE (LUNIT,11) RNHOR,RNUP
   11   FORMAT (1X,2F10.4,'  HORIZONTAL AND/OR VERTICAL GPS ',
     &         'REDUNDANCY NUMBER FAILS TOLERANCE TEST. ABORTING.' )
        FATAL2 = .TRUE.
      ENDIF


*** ABORT IF SINGULAR VARIANCE FACTORS

      IF (FATAL2) THEN
        CALL LINE (3)
        WRITE (LUNIT,4)
    4   FORMAT (' TERMINATED DUE TO VARIANCE FACTOR SINGULARITIES  ')
        CALL ABORT2
      ENDIF

      RETURN
      END


      SUBROUTINE FORMG3 (IUO, IUO2, NVEC, NR, G, B, A, NX, FATAL, IVF,
     &                   IAUX, IGRT,VTVHOR,VTVUP,VTVCOR,RNHOR,RNUP)
********************************************************************************
* ROUTINE TO RE-COMPUTE OBS.EQ. FOR A GPS SESSION
********************************************************************************
      IMPLICIT DOUBLE PRECISION (A-H, O-Z)
      IMPLICIT INTEGER (I-N)
      PARAMETER ( NVECS = 700, MXSSN = 9999 )
      DIMENSION ICM((NVECS+1)*3+1+3)
      DIMENSION KINDS(NVECS*3), ISNS(NVECS*3), JSNS(NVECS*3)
      DIMENSION LOBS(NVECS*3)
      LOGICAL FATAL
      LOGICAL L2HLF, LEHT
      DIMENSION B(*), G(NR,*), A (*), NX(*)
      COMMON /STRUCT/ NSTA, NAUX, NUNK, IDIM, NSTAS, NOBS, NCON, NZ,NGRT
      COMMON /DUAL/   N2HLF, I2HLF(MXSSN), L2HLF, LEHT

      IF ( .NOT. L2HLF) THEN
        LENG = (NVEC+1)*IDIM + 1
      ELSE
        LENG = (NVEC+1)*3 + 1
      ENDIF
      IF (NGRT .GT. 0) LENG = LENG + 3
*     NC = NR + 3 + LENG
      NC = NR + 5 + LENG

*** READ SUPPORTING INDICIES

      READ (IUO) ICM, NICM, KINDS, ISNS, JSNS, LOBS
      WRITE (IUO2) ICM, NICM, KINDS, ISNS, JSNS, LOBS

*** LOAD WORK SPACE (G)

      DO 1 I = 1, NR
        READ (IUO) (G(I,J), J = 1, NC)
    1 CONTINUE

*** COMPUTE AND DECORRELATE OBS. EQ. AND MISCLOSURE
      CALL VFGPS3 (G, NR, NC, NVEC, LENG, B, ICM, NICM, KINDS, ISNS,
     &       JSNS, LOBS, IAUX, IVF, FATAL, A, NX, N1, N2, N3,N4,N5,IGRT,
     &     VTVHOR,VTVUP,VTVCOR,RNHOR,RNUP)

*** REWRITE UPDATED WORK SPACE
      DO 500 I = 1, NR
        WRITE (IUO2) (G(I,J), J = 1, NC)
  500 CONTINUE

      RETURN
      END


      SUBROUTINE VFGPS3(G, NR, NC, NVEC, LENG, B, ICM, NICM, KINDS,ISNS,
     &       JSNS, LOBS, IAUX, IVF, FATAL, A, NX, N1, N2, N3,N4,N5,IGRT,
     &     VTVHOR,VTVUP,VTVCOR,RNHOR,RNUP)
********************************************************************************
* COMPUTE CONTRIBUTIONS TO SUM OF SQUARES AND REDUNDANCY FOR ONE GPS SESSION
********************************************************************************
      IMPLICIT DOUBLE PRECISION (A-H, O-Z)
      IMPLICIT INTEGER (I-N)
      PARAMETER ( NVECS = 700, LENC = 10, MXVF = 40, MXSSN = 9999 )
      DIMENSION ICM((NVECS+1)*3+1+3)
      DIMENSION KINDS(NVECS*3), ISNS(NVECS*3), JSNS(NVECS*3)
      DIMENSION LOBS(NVECS*3)
      LOGICAL FATAL, PROP, FIXVF
      LOGICAL LSS, LUP, LMSL, LABS, LADJ, LUPI
      LOGICAL L2HLF, LEHT
      DIMENSION IC(LENC), C(LENC)
      DIMENSION B(*), G(NR,NC), A(*), NX(*)
      COMMON/UNITS/ LUNIT
      COMMON /LASTSN/ ISNX, JSNX
      COMMON /DUAL/   N2HLF, I2HLF(MXSSN), L2HLF, LEHT
      COMMON /STRUCT/ NSTA, NAUX, NUNK, IDIM, NSTAS, NOBS, NCON, NZ,NGRT
      COMMON /GPSHUS/ GPSVS(NVECS*3,2), GPSRNS(NVECS*3)

*** LENGTH OF COEFF. ARRAYS

      IF ( .NOT. L2HLF) THEN
        LENGC = 2*IDIM
      ELSE
        LENGC = 2*3
      ENDIF
      IF (IAUX .GT. 0) LENGC = LENGC + 1
      IF (IGRT .GT. 0) LENGC = LENGC + 3

*** SET LAST STATION ENCOUNTERED TO NULL

      ISNX = 0
      JSNX = 0
*** DETERMINE WORK ARRAY COLUMN POINTERS

      CALL GLOCAT (N1, N2, N3, N4, N5, NVEC, LENG)

*** (STEP 1.)  COMPUTE COEFFICIENTS OF CORRELATED OBSERVATIONS

      DO 10 I = 1, NR
        KIND = KINDS(I)
        ISN = ISNS(I)
        JSN = JSNS(I)
        CALL FORMC (KIND, C, B, ISN, JSN, IAUX, IGRT)
        CALL GETGIC (ISN, JSN, IAUX, ICM, IC, N2, NICM, IGRT)

        DO 2 J = 1, LENG
          K = J + N2
          G(I,K) = 0.D0
    2   CONTINUE

        DO 20 J = 1, LENGC
          G(I,IC(J) ) = C(J)
   20   CONTINUE
   10 CONTINUE

****  STEP 2. COMPUTE REDUNDANCY NUMBERS FOR THIS SESSION
***     SAVE IN GPSRNS
      CALL RNNEU (G, NR, NC, NVEC, LENG, B, ICM, NICM, KINDS,
     &                   ISNS, JSNS, LOBS, IAUX, IVF, FATAL, NOBIGV,
     &                   A, NX, N2, N3, N4, GMDES, IGRT)

**
*   STEP 4.
******   COMPUTE RESIDUALS (MISCLOSURES) IN X,Y,Z
C
      DO 90 I = 1, NR
        KIND = KINDS(I)
        ISN = ISNS(I)
        JSN = JSNS(I)
        CALL COMPOB (KIND, OBS0, B, ADUMMY, ISN, JSN, IAUX, IGRT)
        CMO = OBS0 - G(I,NC)
        G(I,N4) = CMO
   90 CONTINUE
C
******* STEP 5. COMPUTE RESIDUALS IN E,N,U. 
*******    PUT V-TILDE H IN COLUMN 1 OF GPSVS
*******    PUT V-TILDE U IN COLUMN 2 OF GPSVS
***
      DO 100 IVEC=1,NVEC
        CALL RGPS2( IVEC, NVEC, NR, NC, N4, LENG, G, B, IAUX, IVF,
     &              SIGUWT, A, NX, IGRT, KINDS,ISNS,JSNS,LOBS)
  100 CONTINUE

***  STEP 6.  COMPUTE V-HAT-H AND V-HAT U
C     multiply the columns of GPSVS by R(inverse)(transpose), where R is the 
C     upper Cholesky factor of the covariance matrix of the 
C       observatios for this session.
C
      CALL CMRHS3(G,NR,GPSVS,3*NVECS,1)
C
C      DO THE SAME FOR COLUMN 2
C
      CALL CMRHS3(G,NR, GPSVS,3*NVECS,2)
**
**   STEP 7. COMPUTE CONTRIBUTIONS OF THIS SESSION TO VTPV HORIZONTAL,
****    UP, AND MIXED TERMS. ACCUMULATE REDUNDANCY NUMBERS
***
      SPVVHS=0.D0
      SPVVUS=0.D0
      SPVVHU=0.D0
      RNHS=0.D0
      RNUS=0.D0
C
C  accumulate the weighted sum of squares of residuals for this session
      DO 110 I=1,NR
        SD = 1.D0
        CALL BIGV (KINDS(I), ISNS(I), JSNS(I), LOBS(I), IVF, G(I,N4), 
     &             SD, FATAL)
C  SKIP REJECTED OBSERVATIONS
        IF(G(I,N5).GE.100.D0) GO TO 110
        SPVVHS=SPVVHS+GPSVS(I,1)**2
        SPVVUS=SPVVUS+GPSVS(I,2)**2
        SPVVHU=SPVVHU+GPSVS(I,1)*GPSVS(I,2)
        IF (MOD(I,3).EQ.0) THEN
          RNUS=RNUS+GPSRNS(I)
        ELSE
          RNHS=RNHS+GPSRNS(I)
        ENDIF
  110 CONTINUE
C
C  add the contribution of this session to the total
      VTVHOR=VTVHOR+SPVVHS
      VTVUP=VTVUP+SPVVUS
      VTVCOR=VTVCOR+2.D0*SPVVHU
      RNHOR=RNHOR+RNHS
      RNUP=RNUP+RNUS
****
      RETURN
      END


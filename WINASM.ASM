            .186                      ;��� ������ pusha, popa
            .MODEL  SMALL             ;����� ������ �����
            .STACK  2048h             ;2 �� �⥪�
AttrPl      EQU  01111010b            ;��ਡ���: ����� ����������
AttrPB      EQU  00101000b            ;����⨢��� "������" ����
AttrBG      EQU  00111111b            ;䮭�
AttrSh      EQU  00111000b            ;⥭��
AttrW       EQU  00011110b            ;����
LenTxtBuf   EQU  0A0h                 ;����� ���� �����
Down        EQU  80                   ;᪠�-����: ��. "����"
Up          EQU  72                   ;"�����"
Act         EQU  28                   ;"Enter"
LenBut      EQU  NameB2-NameB1        ;����� "������"
LenHead	    EQU  19                   ;����� ��������� ����

video       SEGMENT AT 0B800h         ;ᥣ���� ����� �����������
            DW     2000 dup (?)       ;ࠧ��஬ 2000 ����
video       ENDS

windata     SEGMENT PARA PRIVATE      ;ᥣ���� ������
HiLine      DB     '������ୠ� ࠡ�� "������ ����䥩�"$'
BotLine     DB     'Ross FreeWare 1999$' ;������ �� ������

Button      STRUC            ;���ᠭ�� �������� "������"
 Coords     DW     ?         ;���न���� �뢮��
 AttrB      DB     ?         ;��ਡ��
 Text       DW     ?         ;�������
Button      ENDS

NameB1      DB    10h,'   ���� ⥪��    ',11h ;������ ��
NameB2      DB    10h,' �뢮� १���� ',11h ;"�������" ����
NameB3      DB    10h,'��室��� ���ﭨ�',11h
NameB4      DB    10h,'��室 �� �ணࠬ��',11h
B1          Button <0401h,AttrPl,NameB1>       ;���ᠭ�� "������"
B2          Button <0901h,AttrPB,NameB2>       ;� �������
B3          Button <0E01h,AttrPB,NameB3>       ;��������
B4          Button <1301h,AttrPB,NameB4>

Window      STRUC                  ;���ᠭ�� �������� ����
 CrdBeg     DW     ?               ;���न���� ���孥�� ������ 㣫�
 CrdEnd     DW     ?               ;���न���� ������� �ࠢ��� 㣫�
 Head       DB     LenHead dup (?) ;���������
Window      ENDS

InpWin      Window <0719h,0E40h,'   ���� �����    '> ;���ᠭ��
OutWin      Window <1019h,164Ah,'   ���� �뢮��   '> ;����
TargetWin   Window <0216h,094Eh,' ���ᠭ�� ࠡ��� '> ;������ன
; ᮤ�ঠ��� ��砫쭮�� ���� � ��������
T1    DB   '                   �������:$'
T2    DB   ' � ��室��� ��ப� ����⠢��� ���⠬� ��� �$'
T3    DB   ' ����� ᨬ���� � �������� १����.$'
T4    DB   ' ��६�饭�� �� ����:                      <Up>,<Down>$'
T5    DB   ' �롮� �㭪樨 � ���� ��ப�:              <Enter>$'
T6    DB   ' �������� ��᫥����� ���������� ᨬ����:   <BackStep>$'

TxtBuf      DB     LenTxtBuf,LenTxtBuf dup (?) ;���� ��ப�
MenuState   DW     0                           ;㪠��⥫� ����
Temp        DW     ?                           ;�६����� ��६�����
RouteTable  DW     InpTxt                      ;⠡��� ���ᮢ
            DW     OutTxt                      ;��楤��
            DW     Reset
            DW     GoAway
windata     ENDS

DrawBut     MACRO    Bt           ;���ப������ �뢮�� "������" ����
            LOCAL    DBloop       ;�����쭠� ��⪠
            mov      dx,Bt.Coords ;���न���� "������"
            push     dx           ;��࠭��� ��� ��. ����権
            call     Cnt          ;������ � ᬥ饭�� ���������
                                  ;१���� � di
            mov      si,Bt.Text   ;���筨� - ���� ������
            cld                   ;�த������� "���।"
            mov      ah,Bt.AttrB  ;����㧪� ��ਡ�� "������"
            mov      cx,LenBut    ;ࠧ��� "������"
DBloop:     lodsb                 ;����㧪� ᨬ���� � al
            stosw                 ;����饭�� ax � ��࠭��� �������
            loop     DBloop       ;横� �� ��� ����� "������"
            mov      ax,(AttrSh shl 8)+0DCh ;⥭� � ��ਡ�⠬�
            stosw                 ;���ᮢ���
            pop      dx           ;���न���� ��砫� "������"
            inc      dh           ;� �� - ��� "�������"
            inc      dl
            call     Cnt          ;���᫨�� ᬥ饭��
            mov      cx,LenBut    ;����� "������"
            mov      ax,(AttrSh shl 8)+0DFh ;⥭� ��� "�������"
            rep      stosw        ;���ᮢ���
ENDM

PrintStr    MACRO    StrTxt       ;���ப������ ���� ��ப�
            push     dx           ;��࠭��� ���न����
            call     MoveAt       ;��⠭����� �����
            lea      dx,StrTxt    ;���� ��ப�
            call     OutStr       ;�뢮� ��ப�
            pop      dx           ;����⠭����� ���न����
            inc      dh           ;᫥����� ��ப�
ENDM

wincode     SEGMENT PARA PRIVATE  ;ᥣ���� ����
            ASSUME   cs:wincode,ds:windata
beg:        mov      ax,windata   ;����㧪� ᥣ���⭮�� ॣ����
            mov      ds,ax        ;������
            call     VMode        ;��⠭���� �����०���
            call     Reset        ;��砫�� ��� ��࠭�
cycle:      mov      ah,01h	  ;㤠����� ᨬ����� �� ����
            int      16h          ;����������
            jz       cycle
            mov      ah,0h        ;�⥭�� ᨬ���� � ���������
            int      16h
            shr      ax,8         ;ᬥ饭�� ᨬ���� �� ah � al
            cmp      al,Down      ;�� ��� "����" ?
            je       Downjob      ;�᫨ �� - ��ࠡ����
            cmp      al,Up        ;���� - �� "�����" ?
            je       Upjob        ;�᫨ �� - ��ࠡ����
            cmp      al,Act       ;���� - "Enter" ?
            jne      cycle        ;�᫨ ��� - ���� ���� ᨬ���
            mov      bx,[MenuState] ;�� - ����㧨�� 㪠��⥫� ����
            shl      bx,1         ;㬭����� �� 2
            call     [RouteTable+bx] ;����� ᮮ�. ��楤���
            jmp      cycle        ;��⥬ ���� ���� ᨬ���
Downjob:    mov      bx,[MenuState] ;����㧨�� 㪠��⥫� ����
            cmp      bx,3           ;��᫥���� "������" ?
            jne      Dj1          ;��� - ���室
            xor      bx,bx        ;��६����� 㪠��⥫�
            mov      [MenuState],bx ;�� ����� "������"
            mov      B1.AttrB,AttrPl ;"��४����" ������
            mov      B4.AttrB,AttrPB
            jmp      Dj4
Dj1:        inc      [MenuState]  ;㪠��⥫� �� ᫥����. "������"
            or       bx,bx        ;�᫨ ��ࢠ�,
            jz       Dj3          ;� ...
            xor      cx,cx
            xchg     bx,cx        ;� ���稪 ���-�� ����७��
Dj2:        add      bx,5         ;������ ᬥ饭�� �� ��ਡ��
            loop     Dj2
Dj3:        mov      [B1.AttrB+bx],AttrPB ;"�������" "������"
            add      bx,5                 ;� ᫥������
            mov      [B1.AttrB+bx],AttrPl ;"������"
Dj4:        call     DrawMenu          ;�ᮢ���
            jmp      cycle             ;᫥���騩 ᨬ���
Upjob:      mov      bx,[MenuState]    ;����㧨�� 㪠��⥫� ����
            or       bx,bx             ;��ࢠ� ?
            jnz      Uj1               ;�᫨ ���, � ���室
            mov      [MenuState],3     ;�� - 㪠��⥫� �� ��᫥����
            mov      B1.AttrB,AttrPB   ;����� - "�������"
            mov      B4.AttrB,AttrPl   ;��᫥���� - "������"
            jmp      Uj3
Uj1:        dec      [MenuState]       ;㪠��⥫� �� �।�����
            xor      cx,cx
            xchg     bx,cx             ;� ���稪 ���-�� ����७��
Uj2:        add      bx,5              ;������ ᬥ饭�� �� ��ਡ��
            loop     Uj2
            mov      [B1.AttrB+bx],AttrPB ;"�������" "������"
            sub      bx,5                 ;� �।�����
            mov      [B1.AttrB+bx],AttrPl ;"������"
Uj3:        call     DrawMenu             ;�ᮢ���
            jmp      cycle                ;᫥���騩 ᨬ���


GoAway:     call   VMode              ;������ ��࠭ ��। ��室��
            mov    ax,4C00h           ;����砭�� �ணࠬ��
            int    21h                ;� ��।�祩 ���� �����襭��

VMode       PROC                 ;��楤�� ��⠭���� �����०���
            push   ax bx         ;��࠭���� ࠡ��� ॣ���஢
            mov    ax,0003h      ;��⠭���� �����०���
            int    10h           ;16 �. 80�25
            mov    ax,1003h      ;���樠������ EGA-�������
            mov    bl,0          ;��⠭���� �મ�� => 16 梥⮢
            int    10h
            pop    bx ax         ;����⠭������� ॣ���஢
            ret                  ;������
VMode       ENDP

Image       PROC                       ;��楤�� ��ଫ���� ��࠭�
            pusha                      ;��࠭���� ॣ���஢
            mov      ax,video          ;����㧪� ����
            mov      es,ax             ;�����ᥣ����
            cld                        ;�த������� "���।"
            xor      di,di             ;ᬥ饭�� 0
            mov      cx,80             ;80 ᨬ����� � ��ப�
            mov      ax,(AttrPl shl 8) ;�ᮢ���� ������
            rep      stosw             ;������ ��࠭�
            mov      cx,80*23          ;23 ��ப� �� 80 ᨬ�����
            mov      ax,(AttrBG shl 8 )+' ' ;��������� 䮭��
            rep      stosw             ;����������
            mov      cx,80             ;��ப� 80 ᨬ�����
            mov      ax,(AttrPl shl 8) ;������ �����
            rep      stosw             ;��࠭� �ᮢ���
            mov      dx,0014h          ;�뢮� ������
            PrintStr HiLine            ;������
            mov      dx,181Eh          ;�뢮� ������
            PrintStr BotLine           ;�����
            popa                       ;����⠭����� ॣ�����
            ret                        ;������
Image       ENDP

HideCur     PROC                ;��楤�� �몫�祭�� �����
            push     ax cx      ;��࠭��� ॣ�����
            mov      ah,01h     ;��⠭���� ࠧ��� � ��� �����
            mov      cx,2000h   ;20 - �������� �����
            int      10h        ;�맮� �㭪権
            pop      cx ax      ;����⠭����� ॣ�����
            ret                 ;������
HideCur     ENDP

DrawMenu    PROC                ;��楤�� �뢮�� ����
            DrawBut  B1         ;�ᮢ���� "������"
            DrawBut  B2
            DrawBut  B3
            DrawBut  B4
            ret                 ;������
DrawMenu    ENDP

Cls         PROC   ;��楤�� ���⪨ �������� ������ ��࠭�
            mov    ax,0600h     ;�㭪�� ���⪨ ��࠭�
            int    10h          ;�맮� �㭪樨
            ret                 ;������
Cls         ENDP

WinDraw     PROC    ;��楤�� �ᮢ���� ����
            mov     bh,AttrW      ;��ਡ�� ����
            call    Cls           ;���⪠ ����
            xchg    dx,cx         ;��� Cnt ���न��� ��砫�
            call    Cnt           ;������ � ᬥ饭��
            push    cx dx         ;��࠭���� ���न���
            xchg    cx,dx         ;�������� ���⠬� ��砫� � �����
            sub     dl,cl         ;���᫥��� ࠧ��� ���� x
            mov     dh,dl         ;x � dh
            sub     dl,LenHead+1  ;x-�����-1
            shr     dl,1          ;(x-�����-1)/2
            sub     dh,dl         ;x-(x-�����-1)/2
            sub     dh,LenHead+1  ;x-(x-�����-1)/2-22
            mov     al,0C9h       ;㣮���
            mov     ah,AttrW      ;� ��ਡ�⮬
            cld                   ;���ࠢ����� "���।"
            stosw                 ;�ᮢ��� 㣮���
            mov     al,0CDh       ;�ᮢ����
            mov     cl,dl         ;ࠬ�� ��
            xor     ch,ch         ;���������
            rep     stosw
            mov     cl,LenHead    ;����� ���������
            mov     ah,AttrPl     ;��ਡ�� ��� ���������
WDLoop:     lodsb                 ;�뢮�
            stosw                 ;���������
            loop    WDLoop
            mov     ah,AttrW      ;�ᮢ����
            mov     al,0CDh       ;ࠬ�� ��᫥
            mov     cl,dh         ;���������
            rep     stosw
            mov     al,0BBh       ;㣮���
            stosw                 ;���ᮢ���
            pop     dx cx         ;����⠭����� ���न���� ����
            sub     cx,dx         ;ࠧ��� ����: cl=x, ch=y
            dec     ch            ;ॠ��� ࠧ���
            dec     cl
            mov     bx,cx         ;bx � ����⢥ �࠭�⥫� ࠧ���
            mov     dx,78         ;���祭�� ����. ����. -1
            sub     dl,cl         ;78-x
            shl     dx,1          ;(78-x)*2
            mov     bp,dx         ;1-� ᬥ饭�� ��� �ᮢ���� ࠬ��
            mov     dl,bl         ;x
            shl     dl,1          ;x*2 - 2-� ᬥ饭��
            mov     cl,bh         ;y
            xor     ch,ch
            mov     al,0BAh       ;���⨪���� ᨬ��� ࠬ��
repstr:     add     di,bp         ;�ਡ����� 1-� ᬥ饭��
            stosw                 ;�ᮢ��� ᨬ���
            add     di,dx         ;�ਡ����� 2-� ᬥ饭��
            stosw                 ;�ᮢ��� ᨬ���
            loop    repstr        ;横� �� ࠧ���� y
            add     di,bp         ;�ਡ����� 1-� ᬥ饭��
            mov     al,0C8h       ;㣮���
            stosw                 ;�ᮢ���
            mov     al,0CDh       ;��ਧ��⠫�� ᨬ��� ࠬ��
            mov     cl,bl         ;� ������⢥ x
            rep     stosw         ;�ᮢ���
            mov     al,0BCh       ;㣮���
            stosw                 ;�ᮢ���
            ret                   ;������
WinDraw     ENDP

Reset       PROC                  ;��楤�� ��砫쭮�� ���ﭨ�
            call     Image        ;��ଫ���� ���� ��࠭�
            call     HideCur      ;�몫�祭�� �����
            call     DrawMenu     ;�ᮢ���� ����
            mov      cx,TargetWin.CrdBeg  ;���न���� ��砫쭮��
            mov      dx,TargetWin.CrdEnd  ;����
            lea      si,TargetWin.Head    ;ᬥ饭�� �� ���������
            call     WinDraw              ;�ᮢ��� ����
            mov      dx,TargetWin.CrdBeg  ;���न����
            inc      dl                   ;㢥����� ���
            inc      dh                   ;�뢮�� ⥪��
            PrintStr T1                   ;������ ��ப�
            PrintStr T2                   ;⥪�� � ����
            PrintStr T3
            PrintStr T4
            PrintStr T5
            PrintStr T6
            ret           ;������
Reset       ENDP

ShowCur     PROC              ;��楤�� ����祭�� �����
            push   ax cx      ;��࠭���� ॣ���஢
            mov    ah,01h     ;��⠭���� ࠧ��� � ��� �����
            mov    cx,0E0Fh   ;��砫쭠� � ����筠� ��ப� �����
            int    10h        ;�맮� �㭪樨
            pop    cx ax      ;����⠭������� ॣ���஢
            ret               ;������
ShowCur     ENDP

OutStr      PROC              ;��楤�� �뢮�� ��ப�
            push   ax         ;���. ॣ����
            mov    ah,9       ;�뢮� ��ப� ᨬ����� ��
            int    21h        ;���᮫�
            pop    ax         ;�����. ॣ����
            ret               ;������
OutStr      ENDP

MoveAt      PROC              ;��楤�� ��⠭���� �����
            push   ax bx      ;���. ॣ�����
            xor    bx,bx      ;�������࠭�� 0
            mov    ah,02      ;�㭪�� ��⠭����
            int    10h        ;�맮� �㭪樨
            pop    bx ax      ;�����. ॣ�����
            ret               ;������
MoveAt      ENDP

Cnt         PROC   ;��楤�� ������ ���न��� � ᬥ饭��
            push   ax cx      ;���. ॣ�����
            mov    ax,video   ;����㧪� ����
            mov    es,ax      ;�����ᥣ����
            xor    di,di      ;������ ᬥ饭��
            xor    cx,cx      ;������ ���稪
            mov    cl,dh      ;� ���稪 - ���-�� ��ப
cntloop:    add    di,0A0h    ;�������� ���-�� ���� � ��ப�
            loop   cntloop
            xor    ax,ax      ;���᫥���
            mov    al,dl      ;������⢠
            shl    al,1       ;���� � �������� ��ப�
            add    di,ax      ;����������  � ᬥ饭��
            pop    cx ax      ;�����. ॣ�����
            ret               ;������
Cnt         ENDP

prnsym      PROC     ;��楤�� �뢮�� ᨬ���� �� ��࠭
            push     bx cx    ;���. ॣ�����
            xor      bx,bx    ;�������࠭�� 0
            xor      cx,cx    ;���-��
            inc      cx       ;ᨬ����� = 1
            mov      ah,0Ah   ;�㭪�� �뢮�� ᨬ���� �� ��࠭
            int      10h      ;�맮� �㭪樨
            pop      cx bx    ;�����. ॣ�����
            ret               ;������
prnsym      ENDP

InpTxt      PROC     ;��楤�� ����� ��ப� � ����
            mov      cx,InpWin.CrdBeg ;���न���� ���� �����
            mov      dx,InpWin.CrdEnd
            lea      si,InpWin.Head   ;���� ���������
            call     WinDraw          ;�ᮢ���� ����
            mov      dx,InpWin.CrdBeg ;���न����
            inc      dl               ;��砫쭮� ����樨
            inc      dh               ;����� ��ப�
            mov      Temp,dx          ;��������� �� � ��ଥ����
            call     MoveAt           ;��⠭���� �����
            call     ShowCur          ;� ��� ����祭��
            mov      bx,InpWin.CrdEnd ;������ ���न����
            dec      bl               ;��� �����
            dec      bh               ;��ப�
            push     ds               ;���� ᥣ����
            pop      es               ;���� �ਥ�����
            lea      di,TxtBuf        ;�ਥ���� - ����
            mov      si,di            ;��� ��।������ �����
            inc      di               ;��砫� - 2-� �������
            xor      cx,cx            ;���㫥��� ���稪�
            mov      cl,[si]          ;���-�� ᨬ����� ��� �����
            mov      Word Ptr [si],0  ;���� ������� 0
            cld                     ;���ࠢ����� "���।"
inp:        xor     ch,ch           ;���㫨�� ��. ���� ���稪�
            xor     ah,ah           ;�㭪�� ����� � ���������� BIOS
            int     16h             ;����砥� �������� ���
            or      al,al           ;�஢�ઠ �� ���७�� ���
            jz      inp             ;�᫨ ��, � ���� ᭮��
            cmp     al,32           ;�஢�ઠ �� �ࠢ���騩 ᨬ���
            jl      control         ;�᫨ ��, � �� ᯥ�. ��楤���
            or      cl,cl           ;�᫨ ���⨣��� ����� ���-��,
            jz      beep            ;� - ��㪮��� ᨣ���
            cmp     dl,bl           ;��᫥���� ������� ?
            jne     it1             ;��� - ���室
            cmp     dh,bh           ;���� - ��᫥���� ��ப� ?
            je      beep            ;�� - ��㪮��� ᨣ���
            call    prnsym          ;���� - ����� ᨬ����
            stosb                   ;��������� ᨬ��� �� ���. ES:DI
            inc     Word Ptr [si]   ;㢥����� ���-�� ����. ᨬ�.
            dec     cl              ;㬥����� ���稪
            mov     dx,Temp         ;����⠭����� ���न����
            inc     dh              ;᫥����� ��ப�
            mov     Temp,dx         ;��࠭��� ���न����
            call    MoveAt          ;��⠭����� �����
            jmp     inp             ;���� ������ ᨬ����
it1:        call    prnsym          ;����� ᨬ����
            stosb                   ;���������� ᨬ��� �� ���. ES:DI
            inc     Word Ptr [si]   ;㢥����� ���-�� ����. ᨬ�.
            dec     cl              ;㬥����� ���稪
            inc     dl              ;᫥����� �������
            call    MoveAt          ;��⠭����� �����
            jmp     inp             ;���� ������ ᨬ����
control:    cmp     al,13           ;��� ASCII 13?
            jne     bs              ;�᫨ ���, � ᫥�. �஢�ઠ
            cmp     ah,28           ;���� �஢��塞 ᪠�-��� <CR>
            jne     inp             ;�᫨ ���, � ���� ᨬ����
            jmp     quitinp         ;��ࠡ�⪠ ������ ���⪨
bs:         cmp     al,8            ;�஢�ઠ �� <BS>
            jne     inp             ;�᫨ ���, � ���� ᨬ����
            cmp     dl,Byte Ptr [Temp] ;��ࢠ� ������� ?
            je      prevline        ;�᫨ ���,
            dec     dl              ;� ������ �� 蠣
it2:        call    MoveAt          ;��⠭���� �����
            mov     al,' '          ;��࠭�� ᨬ����
            call    prnsym          ;�஡����
            dec     di              ;������ �ਥ����� 㬥�����
            dec     Word Ptr [si]   ;���-�� ��������� ᨬ����� ⮦�
            inc     cl              ;� ���稪 ����� 㢥�����
            jmp     inp             ;���� ������ ᨬ����
prevline:   mov     ch,Byte Ptr InpWin.CrdBeg+1 ;���न����
            inc     ch              ;��砫� ��ࢮ� ��ப�
            cmp     dh,ch           ;��ࢠ� ��ப� ?
            je      beep            ;�� - ��㪮��� ᨣ���
            dec     dh              ;���� �।�. ��ப�
            mov     Temp,dx         ;��࠭��� ���न����
            mov     dl,bl           ;��᫥���� �������
            jmp     it2
beep:       push    dx              ;���. ॣ����
            mov     ah,02           ;�뢮� ᨬ���� �� ���᮫�
            mov     dl,7            ;ᨬ��� - ��㪮��� ᨣ���
            int     21h             ;�맮� �㭪樨
            pop     dx              ;�����. ॣ����
            call    MoveAt          ;��⠭���� �����
            jmp     inp             ;���� ������ ᨬ����
quitinp:    call    HideCur         ;������� �����
            call    swap            ;��ࠡ���� ��ப�
            ret                     ;������
InpTxt      ENDP

OutTxt      PROC     ;��楤�� �뢮�� ��ப� � ����
            mov      cx,OutWin.CrdBeg ;���न���� ���� �뢮��
            mov      dx,OutWin.CrdEnd
            lea      si,OutWin.Head   ;���� ���������
            call     WinDraw          ;�ᮢ��� ����
            mov      dx,OutWin.CrdBeg ;���न����
            inc      dl               ;��砫쭮�
            inc      dh               ;����樨 �뢮��
            mov      Temp,dx          ;��࠭���� ��
            call     MoveAt           ;��⠭���� �����
            mov      bx,OutWin.CrdEnd ;������ ���न����
            dec      bl               ;��� �뢮��
            dec      bh               ;��ப�
            push     ds               ;����㧪� ᥣ����
            pop      es               ;����
            lea      si,TxtBuf        ;� ᬥ饭��
            xor      cx,cx            ;���稪 ���㫨��
            mov      cl,[si]          ;� ����㧨�� ���-�� ᨬ�����
            inc      si               ;�뢮� - � ��ண� �������
            cld                       ;���ࠢ����� "���।"
outp:       or      cl,cl             ;����� ��ப� = 0
            jz      quitoutp          ;�᫨ �� - �� ��室
            lodsb                     ;���� ᨬ��� �� ����
            call    prnsym            ;�뢮� ᨬ���� �� ��࠭
            dec     cl                ;㬥����� ���稪
            cmp     dl,bl             ;��᫥���� ������� ?
            je      ot1               ;�᫨ ���, � -
            inc     dl                ;᫥����� �������
            jmp     ot2
ot1:        cmp     dh,bh             ;��᫥���� ��ப� ?
            je      quitoutp          ;�� - ��室
            mov     dx,Temp           ;��� - ����. ��砫� ��ப�
            inc     dh                ;��३� �� ᫥������
            mov     Temp,dx           ;��࠭��� ���न����
ot2:        call    MoveAt            ;��⠭����� �����
            jmp     outp              ;�뢮� ᫥���饣� ᨬ����
quitoutp:   ret                       ;������
OutTxt      ENDP

swap        PROC    ;��楤�� ������� ���⠬� ᨬ�����
            pusha                ;���. ॣ�����
            lea     si,TxtBuf    ;ᬥ饭�� ���� ���� ��ப�
            mov     di,si        ;� ������� ॣ�����
            xor     cx,cx        ;���㫥��� ���稪� �
            mov     cl,[si]      ;����㧪� ����� ⥪�� ��
                                 ;��ࢮ�� ������� ��ப�
            shr     cl,1         ;������� �� 2
            inc     si           ;��砫쭠� ������ - 2-�
            inc     di           ;�������
            cld                  ;��ᬮ�� "���।"
swloop:     lodsw                ;����㧪� 2-� ᨬ����� � ax
            xchg    al,ah        ;����⠭���� �� ���⠬�
            stosw                ;� ��࠭���� ���⭮
            loop    swloop       ;����७�� �� ���� ⥪��
            popa                 ;�����. ॣ�����
            ret                  ;������
swap        ENDP

wincode     ENDS
            END     beg

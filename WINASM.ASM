            .186                      ;для команд pusha, popa
            .MODEL  SMALL             ;малая модель памяти
            .STACK  2048h             ;2 кб стека
AttrPl      EQU  01111010b            ;атрибуты: полос окаймления
AttrPB      EQU  00101000b            ;неактивной "кнопки" меню
AttrBG      EQU  00111111b            ;фона
AttrSh      EQU  00111000b            ;теней
AttrW       EQU  00011110b            ;окон
LenTxtBuf   EQU  0A0h                 ;длина буфера ввода
Down        EQU  80                   ;скан-коды: кл. "вниз"
Up          EQU  72                   ;"вверх"
Act         EQU  28                   ;"Enter"
LenBut      EQU  NameB2-NameB1        ;длина "кнопки"
LenHead	    EQU  19                   ;длина заголовка окон

video       SEGMENT AT 0B800h         ;сегмент памяти видеоадаптера
            DW     2000 dup (?)       ;размером 2000 байт
video       ENDS

windata     SEGMENT PARA PRIVATE      ;сегмент данных
HiLine      DB     'Лабораторная работа "Оконный интерфейс"$'
BotLine     DB     'Ross FreeWare 1999$' ;надписи на полосах

Button      STRUC            ;описание структуры "кнопки"
 Coords     DW     ?         ;координаты вывода
 AttrB      DB     ?         ;атрибут
 Text       DW     ?         ;надпись
Button      ENDS

NameB1      DB    10h,'   Ввод текста    ',11h ;надписи на
NameB2      DB    10h,' Вывод результата ',11h ;"кнопках" меню
NameB3      DB    10h,'Исходное состояние',11h
NameB4      DB    10h,'Выход из программы',11h
B1          Button <0401h,AttrPl,NameB1>       ;описание "кнопок"
B2          Button <0901h,AttrPB,NameB2>       ;с помощью
B3          Button <0E01h,AttrPB,NameB3>       ;структуры
B4          Button <1301h,AttrPB,NameB4>

Window      STRUC                  ;описание структуры окна
 CrdBeg     DW     ?               ;координаты верхнего левого угла
 CrdEnd     DW     ?               ;координаты нижнего правого угла
 Head       DB     LenHead dup (?) ;заголовок
Window      ENDS

InpWin      Window <0719h,0E40h,'   Окно ввода    '> ;описание
OutWin      Window <1019h,164Ah,'   Окно вывода   '> ;окон
TargetWin   Window <0216h,094Eh,' Описание работы '> ;структурой
; содержание начального окна с заданием
T1    DB   '                   Задание:$'
T2    DB   ' В исходной строке переставить местами четные и$'
T3    DB   ' нечетные символы и напечатать результат.$'
T4    DB   ' Перемещение по меню:                      <Up>,<Down>$'
T5    DB   ' Выбор функции и ввод строки:              <Enter>$'
T6    DB   ' Удаление последнего введенного символа:   <BackStep>$'

TxtBuf      DB     LenTxtBuf,LenTxtBuf dup (?) ;буфер строки
MenuState   DW     0                           ;указатель меню
Temp        DW     ?                           ;временная переменная
RouteTable  DW     InpTxt                      ;таблица адресов
            DW     OutTxt                      ;процедур
            DW     Reset
            DW     GoAway
windata     ENDS

DrawBut     MACRO    Bt           ;макрокоманда вывода "кнопки" меню
            LOCAL    DBloop       ;локальная метка
            mov      dx,Bt.Coords ;координаты "кнопки"
            push     dx           ;сохранить для др. операций
            call     Cnt          ;пересчет в смещение видеоадреса
                                  ;результат в di
            mov      si,Bt.Text   ;источник - адрес надписи
            cld                   ;продвижение "вперед"
            mov      ah,Bt.AttrB  ;загрузка атрибута "кнопки"
            mov      cx,LenBut    ;размер "кнопки"
DBloop:     lodsb                 ;загрузка символа в al
            stosw                 ;помещение ax в экранную область
            loop     DBloop       ;цикл на всю длину "кнопки"
            mov      ax,(AttrSh shl 8)+0DCh ;тень с атрибутами
            stosw                 ;нарисовать
            pop      dx           ;координаты начала "кнопки"
            inc      dh           ;а это - под "кнопкой"
            inc      dl
            call     Cnt          ;вычислить смещение
            mov      cx,LenBut    ;длина "кнопки"
            mov      ax,(AttrSh shl 8)+0DFh ;тень под "кнопкой"
            rep      stosw        ;нарисовать
ENDM

PrintStr    MACRO    StrTxt       ;макрокоманда печати строки
            push     dx           ;сохранить координату
            call     MoveAt       ;установить курсор
            lea      dx,StrTxt    ;адрес строки
            call     OutStr       ;вывод строки
            pop      dx           ;восстановить координату
            inc      dh           ;следующая строка
ENDM

wincode     SEGMENT PARA PRIVATE  ;сегмент кода
            ASSUME   cs:wincode,ds:windata
beg:        mov      ax,windata   ;загрузка сегментного регистра
            mov      ds,ax        ;данных
            call     VMode        ;установка видеорежима
            call     Reset        ;начальный вид экрана
cycle:      mov      ah,01h	  ;удаление символов из буфера
            int      16h          ;клавиатуры
            jz       cycle
            mov      ah,0h        ;чтение символа с ожиданием
            int      16h
            shr      ax,8         ;смещение символа из ah в al
            cmp      al,Down      ;это код "вниз" ?
            je       Downjob      ;если да - обработать
            cmp      al,Up        ;иначе - это "вверх" ?
            je       Upjob        ;если да - обработать
            cmp      al,Act       ;иначе - "Enter" ?
            jne      cycle        ;если нет - читать новый символ
            mov      bx,[MenuState] ;да - загрузить указатель меню
            shl      bx,1         ;умножить на 2
            call     [RouteTable+bx] ;запуск соотв. процедуры
            jmp      cycle        ;затем читать новый символ
Downjob:    mov      bx,[MenuState] ;загрузить указатель меню
            cmp      bx,3           ;последняя "кнопка" ?
            jne      Dj1          ;нет - переход
            xor      bx,bx        ;переместить указатель
            mov      [MenuState],bx ;на первую "кнопку"
            mov      B1.AttrB,AttrPl ;"перекрасить" кнопки
            mov      B4.AttrB,AttrPB
            jmp      Dj4
Dj1:        inc      [MenuState]  ;указатель на следующ. "кнопку"
            or       bx,bx        ;если первая,
            jz       Dj3          ;то ...
            xor      cx,cx
            xchg     bx,cx        ;в счетчик кол-во повторений
Dj2:        add      bx,5         ;подсчет смещения до атрибута
            loop     Dj2
Dj3:        mov      [B1.AttrB+bx],AttrPB ;"погасить" "кнопку"
            add      bx,5                 ;а следующую
            mov      [B1.AttrB+bx],AttrPl ;"зажечь"
Dj4:        call     DrawMenu          ;рисовать
            jmp      cycle             ;следующий символ
Upjob:      mov      bx,[MenuState]    ;загрузить указатель меню
            or       bx,bx             ;первая ?
            jnz      Uj1               ;если нет, то переход
            mov      [MenuState],3     ;да - указатель на последнюю
            mov      B1.AttrB,AttrPB   ;первую - "погасить"
            mov      B4.AttrB,AttrPl   ;последнюю - "зажечь"
            jmp      Uj3
Uj1:        dec      [MenuState]       ;указатель на предыдущую
            xor      cx,cx
            xchg     bx,cx             ;в счетчик кол-во повторений
Uj2:        add      bx,5              ;подсчет смещения до атрибута
            loop     Uj2
            mov      [B1.AttrB+bx],AttrPB ;"погасить" "кнопку"
            sub      bx,5                 ;а предыдущую
            mov      [B1.AttrB+bx],AttrPl ;"зажечь"
Uj3:        call     DrawMenu             ;рисовать
            jmp      cycle                ;следующий символ


GoAway:     call   VMode              ;очистить экран перед выходом
            mov    ax,4C00h           ;окончание программы
            int    21h                ;с передачей кода завершения

VMode       PROC                 ;процедура установки видеорежима
            push   ax bx         ;сохранение рабочих регистров
            mov    ax,0003h      ;Установка видеорежима
            int    10h           ;16 цв. 80х25
            mov    ax,1003h      ;инициализация EGA-палитры
            mov    bl,0          ;установка яркости => 16 цветов
            int    10h
            pop    bx ax         ;восстановление регистров
            ret                  ;возврат
VMode       ENDP

Image       PROC                       ;процедура оформления экрана
            pusha                      ;сохранение регистров
            mov      ax,video          ;загрузка адреса
            mov      es,ax             ;видеосегмента
            cld                        ;продвижение "вперед"
            xor      di,di             ;смещение 0
            mov      cx,80             ;80 символов в строке
            mov      ax,(AttrPl shl 8) ;рисование полосы
            rep      stosw             ;вверху экрана
            mov      cx,80*23          ;23 строки по 80 символов
            mov      ax,(AttrBG shl 8 )+' ' ;заполнить фоном
            rep      stosw             ;заполнение
            mov      cx,80             ;строка 80 символов
            mov      ax,(AttrPl shl 8) ;полоску внизу
            rep      stosw             ;экрана рисовать
            mov      dx,0014h          ;вывод надписи
            PrintStr HiLine            ;вверху
            mov      dx,181Eh          ;вывод надписи
            PrintStr BotLine           ;внизу
            popa                       ;восстановить регистры
            ret                        ;возврат
Image       ENDP

HideCur     PROC                ;процедура выключения курсора
            push     ax cx      ;сохранить регистры
            mov      ah,01h     ;установка размера и формы курсора
            mov      cx,2000h   ;20 - подавить курсор
            int      10h        ;вызов функций
            pop      cx ax      ;восстановить регистры
            ret                 ;возврат
HideCur     ENDP

DrawMenu    PROC                ;процедура вывода меню
            DrawBut  B1         ;рисование "кнопок"
            DrawBut  B2
            DrawBut  B3
            DrawBut  B4
            ret                 ;возврат
DrawMenu    ENDP

Cls         PROC   ;процедура очистки заданной области экрана
            mov    ax,0600h     ;функция очистки экрана
            int    10h          ;вызов функции
            ret                 ;возврат
Cls         ENDP

WinDraw     PROC    ;процедура рисования окна
            mov     bh,AttrW      ;атрибут окна
            call    Cls           ;очистка окна
            xchg    dx,cx         ;для Cnt координата начала
            call    Cnt           ;пересчет в смещение
            push    cx dx         ;сохранение координат
            xchg    cx,dx         ;поменять местами начало и конец
            sub     dl,cl         ;вычисление размера окна x
            mov     dh,dl         ;x в dh
            sub     dl,LenHead+1  ;x-длина-1
            shr     dl,1          ;(x-длина-1)/2
            sub     dh,dl         ;x-(x-длина-1)/2
            sub     dh,LenHead+1  ;x-(x-длина-1)/2-22
            mov     al,0C9h       ;уголок
            mov     ah,AttrW      ;с атрибутом
            cld                   ;направление "вперед"
            stosw                 ;рисовать уголок
            mov     al,0CDh       ;рисование
            mov     cl,dl         ;рамки до
            xor     ch,ch         ;заголовка
            rep     stosw
            mov     cl,LenHead    ;длина заголовка
            mov     ah,AttrPl     ;атрибут для заголовка
WDLoop:     lodsb                 ;вывод
            stosw                 ;заголовка
            loop    WDLoop
            mov     ah,AttrW      ;рисование
            mov     al,0CDh       ;рамки после
            mov     cl,dh         ;заголовка
            rep     stosw
            mov     al,0BBh       ;уголок
            stosw                 ;нарисовать
            pop     dx cx         ;восстановить координаты окна
            sub     cx,dx         ;размер окна: cl=x, ch=y
            dec     ch            ;реальный размер
            dec     cl
            mov     bx,cx         ;bx в качестве хранителя размера
            mov     dx,78         ;значение макс. коорд. -1
            sub     dl,cl         ;78-x
            shl     dx,1          ;(78-x)*2
            mov     bp,dx         ;1-е смещение для рисования рамки
            mov     dl,bl         ;x
            shl     dl,1          ;x*2 - 2-е смещение
            mov     cl,bh         ;y
            xor     ch,ch
            mov     al,0BAh       ;вертикальный символ рамки
repstr:     add     di,bp         ;прибавить 1-е смещение
            stosw                 ;рисовать символ
            add     di,dx         ;прибавить 2-е смещение
            stosw                 ;рисовать символ
            loop    repstr        ;цикл по размеру y
            add     di,bp         ;прибавить 1-е смещение
            mov     al,0C8h       ;уголок
            stosw                 ;рисовать
            mov     al,0CDh       ;горизонтальный символ рамки
            mov     cl,bl         ;в количестве x
            rep     stosw         ;рисовать
            mov     al,0BCh       ;уголок
            stosw                 ;рисовать
            ret                   ;возврат
WinDraw     ENDP

Reset       PROC                  ;процедура начального состояния
            call     Image        ;оформление вида экрана
            call     HideCur      ;выключение курсора
            call     DrawMenu     ;рисование меню
            mov      cx,TargetWin.CrdBeg  ;координаты начального
            mov      dx,TargetWin.CrdEnd  ;окна
            lea      si,TargetWin.Head    ;смещение до заголовка
            call     WinDraw              ;рисовать окно
            mov      dx,TargetWin.CrdBeg  ;координаты
            inc      dl                   ;увеличить для
            inc      dh                   ;вывода текста
            PrintStr T1                   ;печатать строки
            PrintStr T2                   ;текста в окне
            PrintStr T3
            PrintStr T4
            PrintStr T5
            PrintStr T6
            ret           ;возврат
Reset       ENDP

ShowCur     PROC              ;процедура включения курсора
            push   ax cx      ;сохранение регистров
            mov    ah,01h     ;установка размера и формы курсора
            mov    cx,0E0Fh   ;начальная и конечная строки курсора
            int    10h        ;вызов функции
            pop    cx ax      ;восстановление регистров
            ret               ;возврат
ShowCur     ENDP

OutStr      PROC              ;процедура вывода строки
            push   ax         ;сохр. регистр
            mov    ah,9       ;вывод строки символов на
            int    21h        ;консоль
            pop    ax         ;восст. регистр
            ret               ;возврат
OutStr      ENDP

MoveAt      PROC              ;процедура установки курсора
            push   ax bx      ;сохр. регистры
            xor    bx,bx      ;видеостраница 0
            mov    ah,02      ;функция установки
            int    10h        ;вызов функции
            pop    bx ax      ;восст. регистры
            ret               ;возврат
MoveAt      ENDP

Cnt         PROC   ;процедура пересчета координат в смещение
            push   ax cx      ;сохр. регистры
            mov    ax,video   ;загрузка адреса
            mov    es,ax      ;видеосегмента
            xor    di,di      ;очистить смещение
            xor    cx,cx      ;очистить счетчик
            mov    cl,dh      ;в счетчик - кол-во строк
cntloop:    add    di,0A0h    ;добавить кол-во байт в строке
            loop   cntloop
            xor    ax,ax      ;вычисление
            mov    al,dl      ;количества
            shl    al,1       ;байт в неполной строке
            add    di,ax      ;добавление  к смещению
            pop    cx ax      ;восст. регистры
            ret               ;возврат
Cnt         ENDP

prnsym      PROC     ;процедура вывода символа на экран
            push     bx cx    ;сохр. регистры
            xor      bx,bx    ;видеостраница 0
            xor      cx,cx    ;кол-во
            inc      cx       ;символов = 1
            mov      ah,0Ah   ;функция вывода символа на экран
            int      10h      ;вызов функции
            pop      cx bx    ;восст. регистры
            ret               ;возврат
prnsym      ENDP

InpTxt      PROC     ;процедура ввода строки в окне
            mov      cx,InpWin.CrdBeg ;координаты окна ввода
            mov      dx,InpWin.CrdEnd
            lea      si,InpWin.Head   ;адрес заголовка
            call     WinDraw          ;рисование окна
            mov      dx,InpWin.CrdBeg ;координаты
            inc      dl               ;начальной позиции
            inc      dh               ;ввода строки
            mov      Temp,dx          ;запомнить их в перменной
            call     MoveAt           ;установка курсора
            call     ShowCur          ;и его включение
            mov      bx,InpWin.CrdEnd ;конечные координаты
            dec      bl               ;для ввода
            dec      bh               ;строки
            push     ds               ;адрес сегмента
            pop      es               ;буфера приемника
            lea      di,TxtBuf        ;приемник - буфер
            mov      si,di            ;для определения длины
            inc      di               ;начало - 2-й элемент
            xor      cx,cx            ;обнуление счетчика
            mov      cl,[si]          ;кол-во символов для ввода
            mov      Word Ptr [si],0  ;пока введено 0
            cld                     ;направление "вперед"
inp:        xor     ch,ch           ;обнулить ст. часть счетчика
            xor     ah,ah           ;функция ввода с клавиатуры BIOS
            int     16h             ;получаем введенный код
            or      al,al           ;проверка на расширенный код
            jz      inp             ;если да, то читать снова
            cmp     al,32           ;проверка на управляющий символ
            jl      control         ;если да, то на спец. процедуру
            or      cl,cl           ;если достигнут лимит кол-ва,
            jz      beep            ;то - звуковой сигнал
            cmp     dl,bl           ;последняя колонка ?
            jne     it1             ;нет - переход
            cmp     dh,bh           ;иначе - последняя строка ?
            je      beep            ;да - звуковой сигнал
            call    prnsym          ;иначе - печать символа
            stosb                   ;запомнить символ по адр. ES:DI
            inc     Word Ptr [si]   ;увеличить кол-во введ. симв.
            dec     cl              ;уменьшить счетчик
            mov     dx,Temp         ;восстановить координаты
            inc     dh              ;следующая строка
            mov     Temp,dx         ;сохранить координаты
            call    MoveAt          ;установить курсор
            jmp     inp             ;ввод нового символа
it1:        call    prnsym          ;печать символа
            stosb                   ;запоминаем символ по адр. ES:DI
            inc     Word Ptr [si]   ;увеличить кол-во введ. симв.
            dec     cl              ;уменьшить счетчик
            inc     dl              ;следующая колонка
            call    MoveAt          ;установить курсор
            jmp     inp             ;ввод нового символа
control:    cmp     al,13           ;код ASCII 13?
            jne     bs              ;если нет, то след. проверка
            cmp     ah,28           ;иначе проверяем скан-код <CR>
            jne     inp             ;если нет, то ввод символа
            jmp     quitinp         ;обработка возврата каретки
bs:         cmp     al,8            ;проверка на <BS>
            jne     inp             ;если нет, то ввод символа
            cmp     dl,Byte Ptr [Temp] ;первая колонка ?
            je      prevline        ;если нет,
            dec     dl              ;то возврат на шаг
it2:        call    MoveAt          ;установка курсора
            mov     al,' '          ;стирание символа
            call    prnsym          ;пробелом
            dec     di              ;индекс приемника уменьшить
            dec     Word Ptr [si]   ;кол-во введенных символов тоже
            inc     cl              ;а счетчик лимита увеличить
            jmp     inp             ;ввод нового символа
prevline:   mov     ch,Byte Ptr InpWin.CrdBeg+1 ;координаты
            inc     ch              ;начала первой строки
            cmp     dh,ch           ;первая строка ?
            je      beep            ;да - звуковой сигнал
            dec     dh              ;иначе предыд. строка
            mov     Temp,dx         ;сохранить координаты
            mov     dl,bl           ;последняя колонка
            jmp     it2
beep:       push    dx              ;сохр. регистра
            mov     ah,02           ;вывод символа на консоль
            mov     dl,7            ;символ - звуковой сигнал
            int     21h             ;вызов функции
            pop     dx              ;восст. регистра
            call    MoveAt          ;установка курсора
            jmp     inp             ;ввод нового символа
quitinp:    call    HideCur         ;погасить курсор
            call    swap            ;обработать строку
            ret                     ;возврат
InpTxt      ENDP

OutTxt      PROC     ;процедура вывода строки в окно
            mov      cx,OutWin.CrdBeg ;координаты окна вывода
            mov      dx,OutWin.CrdEnd
            lea      si,OutWin.Head   ;адрес заголовка
            call     WinDraw          ;рисовать окно
            mov      dx,OutWin.CrdBeg ;координаты
            inc      dl               ;начальной
            inc      dh               ;позиции вывода
            mov      Temp,dx          ;сохранение их
            call     MoveAt           ;установка курсора
            mov      bx,OutWin.CrdEnd ;конечные координаты
            dec      bl               ;для вывода
            dec      bh               ;строки
            push     ds               ;загрузка сегмента
            pop      es               ;буфера
            lea      si,TxtBuf        ;и смещения
            xor      cx,cx            ;счетчик обнулить
            mov      cl,[si]          ;и загрузить кол-во символов
            inc      si               ;вывод - со второго элемента
            cld                       ;направление "вперед"
outp:       or      cl,cl             ;длина строки = 0
            jz      quitoutp          ;если да - на выход
            lodsb                     ;читать символ из буфера
            call    prnsym            ;вывод символа на экран
            dec     cl                ;уменьшить счетчик
            cmp     dl,bl             ;последняя колонка ?
            je      ot1               ;если нет, то -
            inc     dl                ;следующая колонка
            jmp     ot2
ot1:        cmp     dh,bh             ;последняя строка ?
            je      quitoutp          ;да - выход
            mov     dx,Temp           ;нет - коорд. начала строки
            inc     dh                ;перейти на следующую
            mov     Temp,dx           ;сохранить координаты
ot2:        call    MoveAt            ;установить курсор
            jmp     outp              ;вывод следующего символа
quitoutp:   ret                       ;возврат
OutTxt      ENDP

swap        PROC    ;процедура подмены местами символов
            pusha                ;сохр. регистры
            lea     si,TxtBuf    ;смещение адреса буфера строки
            mov     di,si        ;в индексные регистры
            xor     cx,cx        ;обнуление счетчика и
            mov     cl,[si]      ;загрузка длины текста из
                                 ;первого элемента строки
            shr     cl,1         ;деление на 2
            inc     si           ;начальная позиция - 2-й
            inc     di           ;элемент
            cld                  ;просмотр "вперед"
swloop:     lodsw                ;загрузка 2-х символов в ax
            xchg    al,ah        ;перестановка их местами
            stosw                ;и сохранение обратно
            loop    swloop       ;повторение до конца текста
            popa                 ;восст. регистры
            ret                  ;возврат
swap        ENDP

wincode     ENDS
            END     beg

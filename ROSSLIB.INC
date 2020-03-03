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

Cls         PROC   ;процедура очистки заданной области экрана
            mov    ax,0600h     ;функция очистки экрана
            int    10h          ;вызов функции
            ret                 ;возврат
Cls         ENDP

DrawMenu    PROC                ;процедура вывода меню
            DrawBut  B1         ;рисование "кнопок"
            DrawBut  B2
            DrawBut  B3
            DrawBut  B4
            ret                 ;возврат
DrawMenu    ENDP

HideCur     PROC                ;процедура выключения курсора
            push     ax cx      ;сохранить регистры
            mov      ah,01h     ;установка размера и формы курсора
            mov      cx,2000h   ;20 - подавить курсор
            int      10h        ;вызов функций
            pop      cx ax      ;восстановить регистры
            ret                 ;возврат
HideCur     ENDP

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

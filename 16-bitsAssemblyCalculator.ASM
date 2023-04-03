org 100h
start:
	call OutPol
    call enterdata
    call ent
    call OutONP
	call ConvToONP
	call outdata
	next:
	call ent
	call CountONP
    call theend
ent:
    pusha
    pushf
        mov ah,2
        mov dl,10
        int 21h
        mov dl,13
        int 21h
    popf
    popa
    ret
OutPol:
	pusha
	pushf
		mov ah,9
		mov dx,dane
		int 21h
	popa
	popf
	ret
enterdata:
	pusha
	pushf
		mov ah, 10
		mov dx, data
		int 21h
	popf
	popa
    ret
OutONP:
	pusha
	pushf
		mov ah,9
		mov dx,haslo
		int 21h
	popa
	popf
	ret
outdata:
	pusha
	pushf
		xor ax,ax
		mov ax,"$"
		mov [di],ax
		xor ax,ax
		mov ah,9
		mov dx, output + 2
		int 21h
		call next
	popa
	popf
	ret
theend:	
    pop cx
	mov	ax, 4C00h
	int	21h
;-------------------zmienne----------------------
data  db  26
        db 0
        times 27 db "$"
output	db	26
		db	0
		times 27 db "$"	
haslo db "odwrotna notacja polska: $"
dane db "podaj ciag znakow do zmiany: $"
wynik db "wynik wpisanego rownania: $"
przezzero db "blad poniewaz dzielenie przez 0 $"
bladodejmowania db "blad w odejmowaniu $"
zmienna dw 0
a dw 0
b dw 0
czyzero dw 0
;------------------------------------------------
;------------------ZmianaNaONP-------------------
ConvToONP:
		mov si,data+2
		mov di,output+2
		mov cx,[data+25]
		xor ax,ax
		petla:
		sub cx,1
		mov al,byte [si]
		cmp al,"$" ; sprawdzam czy koniec ciagu wejsiowego jesli tak to skacze na koniec
		je oproznijStos
		cmp cx,0
		je outdata
		cmp al,58 ; sprawdzam czy cos innego niz cyfra i znaki jesli tak do skacze do konca programu(pozniej zrobie znaki litery)
		ja outdata
		isNum:; sprawdzam czy cyfra jesli tak to wpisuje
			cmp al,"0"
			jae dodaj
		isOtw:;sprawdzam czy nawias otwierajacy jesli tak to daje go na Stos
			cmp al,"("
			je NaStos
		isZam:; sprawdzam czy nawiaz zamykajacy jesli tak to zrzucam rzeczy ze stosu i dodaje je do onp az trafie na nawias otwierajacy
			cmp al,")"
			je Zamykajacy
		isZnaki:;sprawdzam po kolei czy trafiam na znaki
			cmp al,"+"
			je sprawdz
			cmp al,"-"
			je sprawdz
			cmp al,"*"
			je NaStos
			cmp al,"/"
			je div
		mov al," "
dodaj:	
	mov [di],al
	inc di
	inc si
	xor ax,ax
	jmp petla
NaStos:
	push ax
	xor dx,dx 
	mov dx,[di - 1]
	cmp dl," "
	je skip3
	xor dx,dx
	mov ax," "
	jmp dodaj
	skip3:
	inc si
	jmp petla
sprawdz:
	pop bx
	cmp bl,"*"
	je mulordiv
	cmp bl,"/"
	je mulordiv
	push bx
	push ax
	mov al," "
	xor dx,dx
	mov dx,[di - 1]
	cmp dl," "
	je skip3
	xor bx,bx
	jmp dodaj
div:
	xor bx,bx
	pop bx
	cmp bl,'*'
	je mulordiv
	push bx
	push ax
	mov ax," "
	xor dx,dx
	mov dx,[di - 1]
	cmp dl," "
	je skip3
	jmp dodaj
mulordiv:
	xor cx,cx
	mov cl,al
	call Dodajspacje
	xor ax,ax
	mov al,cl
	mov [di],bx
	xor bx,bx
	inc di
	pop bx
	cmp bl,"*"
	je mulordiv
	cmp bl,"/"
	je mulordiv
	push bx
	push ax
	xor bx,bx
	xor ax,ax
	call Dodajspacje
	inc si
	jmp petla
Zamykajacy:
	xor cx,cx
	mov cl,al
	call Dodajspacje
	xor ax,ax
	mov al,cl
	pop bx
	cmp bl,"("
	je dalej
	mov al,bl
	mov [di],ax
	xor bx,bx
	xor ax,ax
	inc di
	jmp Zamykajacy
dalej:
	inc si
	jmp petla
oproznijStos:
	pop ax
	cmp al,"$"
	je outdata
	cmp al,0
	je outdata
	cmp al,41
	jl outdata
	cmp al,48
	ja outdata
	mov [di],ax
	xor ax,ax
	inc di
	call Dodajspacje
	jmp oproznijStos
Dodajspacje:
	xor dx,dx
	mov dx,[di - 1]
	cmp dx," "
	je skip2
	mov al, " "
	mov [di],ax
	inc di
	skip2:	
	ret
;-------------------------------------------------
;------------------LiczenieONP--------------------
CountONP:
	finit
		mov si,output + 1
		spacja:
		inc si
		mov al,[si]
		cmp al,32
		je spacja
		xor ax,ax
		sprawdzamydalej:
		mov al,[si]
		cmp al,36                         
		je wypisywaniewyniku
		cmp al,"0"                            
		jae Liczba
		cmp al,"+"
		je dodawanie
		cmp al,"-"
		je odejmowanie
		cmp al,"*"
		je mnozenie
		cmp al,"/"
		je dzielenie
		inc si
		xor ax,ax
		jmp sprawdzamydalej

Liczba:
	sub ax,"0"
	xor bx,bx
	mov bx,10
	jmp CzyDalejLiczba
CzyDalejLiczba:      
	inc si                      
	xor cx,cx
	mov cl,[si]
	cmp cl,"0"
	jae Tak																				
	jmp wrzucamyLiczbeNaStos
Tak:
	sub cx,"0"
	mul bx
	add ax,cx
	xor cx,cx
	jmp CzyDalejLiczba
wrzucamyLiczbeNaStos:
	mov [zmienna],ax
	fild word [zmienna]
	xor ax,ax
	xor cx,cx
	jmp sprawdzamydalej
dodawanie:
	faddp
	xor ax,ax
	xor bx,bx
	inc si
	jmp sprawdzamydalej
mnozenie:
	fmulp
	xor ax,ax
	xor bx,bx
	inc si
	jmp sprawdzamydalej
odejmowanie:
	fistp word [a]
	fist word [b]
	xor ax,ax
	xor bx,bx
	mov ax,[a]
	mov bx,[b]
	cmp ax,bx
	jb dodatnie
	jmp bladodejmowanie
	dodatnie:
	fild word [a]
	fsubp
	xor ax,ax
	xor bx,bx
	inc si
	jmp sprawdzamydalej
bladodejmowanie:
	mov ah,9
		mov dx,bladodejmowania
		int 21h
		mov	ax, 4C00h
		int	21h
dzielenie:
	fist word [zmienna]
	xor	ax,ax
	mov ax,[zmienna]
	cmp ax,0
	je dzielenieprzezZero
	fdivp
	xor ax,ax
	xor bx,bx
	inc si
	jmp sprawdzamydalej
dzielenieprzezZero:
		mov ah,9
		mov dx,przezzero
		int 21h
		mov	ax, 4C00h
		int	21h
wypisywaniewyniku:
	mov ah,9
	mov dx,wynik
	int 21h
	fist word [zmienna]
	xor	ax,ax
	mov ax,[zmienna]
	xor	bx,bx
	mov	bx,10
	xor	dx,dx
	mov	cx,0
	petla1:
		div	bx
		push	dx
		xor	dx,dx
		inc	cx
		cmp	ax,0
		jne	petla1
		mov	ah,2
	petla2:
		pop	dx
		add	dl,'0'
		int	21h
		loop petla2
mov	ax, 4C00h
	int	21h






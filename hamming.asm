.data 
buf1: 		.space 512 							# bufor na pierwszy obrazek 
buf2: 		.space 512 							# bufor na drugi obrazek 
temp:        	.space 62 							# bufor pomocniczy do wczytania naglowkow plikow
hamm:		.space 5
odstep:		.asciiz " "
odstep4:	.asciiz "    "
lin:		.asciiz "\r\n"
err1:        	.asciiz "Blad odczytu pliku \n" 
outfile1:    	.asciiz "hamming.txt" 						# plik do zapisania minimalnej odl. Hamminga       
outfile2:    	.asciiz "tablica.txt" 						# plik do zapisania wszystkich znalezionych odl. Hamminga
infile1:     	.asciiz "obraz1.bmp"        					# pierwszy plik do otwarcia 
infile2:    	.asciiz "obraz2.bmp"        					# drugi plik do otwarcia 
linef: 		.asciiz "y\\x | -7 | -6 | -5 | -4 | -3 | -2 | -1 |  0 |  1 |  2 |  3 |  4 |  5 |  6 |  7 |\r\n"
       		.text
		.globl main


main:
###############################
# $s0 - handler pierwszego pliku - obraz1
# $s1 - handler pierwszego pliku - obraz1
# $t4 - handler pliku wynikowego tablica.txt
#############################@
	#otwarcie pliku 1
	li $v0, 13 								# system call for file_open
	la $a0, infile1 							# address of filename string
	li $a1, 0 
	syscall 								# file descriptor of opened file in v0
	move $s0, $v0								# #$s0 -kopia handlera do pierwszego pliku
	beq $v0, -1, error1							# sprawdzenie czy plik zostal otwarty
	
	#otwarcie pliku 2
	li $v0, 13 								#system call for file_open
	la $a0, infile2 							#address of filename string
	li $a1, 0
	li $a2, 0
	syscall 								#file descriptor of opened file in v0
	move  $s1, $v0								# $s1 - kopia handlera do drugiego pliku
	beq $v0, -1, error1							# sprawdzenie czy plik zostal otwarty
	
	#otwarcie pliku tablica.txt
	li $v0, 13 								#system call for file_open
	la $a0, outfile2 							#address of filename string
	li $a1, 1
	li $a2, 0
	syscall 								#file descriptor of opened file in v0
	move  $t4, $v0								# $s1 - kopia handlera pliku tablica.txt
	beq $v0, -1, error1							# sprawdzenie czy plik zostal otwarty
		
	#zapisanie do pliku tablica.txt gornego wiersza tabeli
	la $a1, linef
	move $a0,$t4								#do $a0 kopiujemy handler pliku do zapisu
	li $v0,15								#przerwanie systemowe - zapis do pliku
	li $a2, 82								#ilosc danych w bajtach, ktore maja byc zapisane do pliku
	syscall		
	
	#wczytanie nag³ówka z pliku 1	
	move $a0, $s0
	la $a1, temp
	li $a2, 62
	li $v0,14
	syscall
	
	#wczytanie nag³ówka z pliku 2
	move $a0, $s1
	la $a1, temp
	li $a2, 62
	li $v0,14
	syscall
	
	#wczytanie danych z pliku 1 do buf1
	li $v0, 14 	 							#system call for file_read 
	la $a1, buf1	 							#address of data buffer 
	move $a0, $s0	 							#move file descr from ... to a0 
	li $a2, 512 	 							#amount to read (bytes) 
	syscall 
	
	#wczytanie danych z pliku 2 do buf2
	li $v0, 14 	 							#system call for file_read 
	la $a1, buf2	 							#address of data buffer 
	move $a0, $s1	 							#move file descr from ... to a0 
	li $a2, 512 	 							#amount to read (bytes) 
	syscall 
	
	#zamkniecie pliku 1
	li $v0, 16 								#systemp call for file_close
	move $a0, $s0 								#move file descr from $s0 to a0
	syscall
	
	#zamkniecie pliku 2
	li $v0, 16 								#systemp call for file_close
	move $a0, $s1 								#move file descr from $s1 to a0
	syscall
	
	
#############################################
# $t0 - rejestr przechowujacy 4 pierwsze bajty wiersza z pliku 1
# $t1 - rejestr przechowujacy 4 pierwsze bajty wiersza z pliku 2
# $t2 - rejestr przechowujacy 4 kolejne bajty wiersza z pliku 1
# $t3 - rejestr przechowujacy 4 kolejne bajty wiersza z pliku 2
# $t4 - handler pliku wynikowego tablica.txt
# $t5 - rejestr pomocniczy
# $t6 - rejestr pomocniczy	
# $t7 - rejestr pomocniczy(m.in. licznik petli)
# $t8 - indeks pierwszego obrazka
# $t9 - indeks drugiego obrazka
# $s0 - przesuniecie poziome
# $s1 - przesuniecie pionowe
# $s2 - wartoœæ bezwzglêdna z przesuniêcia poziomego
# $s3 - rejestr zawiera wynik xorowania rejestrów przechowuj¹cych bajty z pierwszego pliku z rejestrami przechowuj¹cymi bajty z 2 pliku
# $s4 - indeks staly w petli drugiego obrazka
# $s5 - indeks staly w petli pierwszego obrazka
# $s6 - licznik rozniacych sie miejsc
# $s7 - minimalna odleglosc Hamminga
##############################################

	li $s7, 4096 				#minimalna odleglosc Hamminga - zainicjowana maksymalna mozliwa odlegloscia Hamminga
	li $s1, -8 				#ustawienie przesuniecia pionowego
	j loop
	

loop:
	addi $s1, $s1, 1			#zwiekszenie przesuniecia pionowego o 1
	li $s0, -8				#ustawienie przesuniecia poziomego
	li $s5,0 				#indeks pierwszego obrazka
	li $s4,0 				#indeks drugiego obrazka
	li $s6, 0 				#wyzerowanie licznika rozniacych sie miejsc
	beq $s1, 8, zapisz_hamming		#jesli przesuniecie pionowe>7 - koniec sprawdzania

zapisz_przesuniecie:				#zapisz wartosc przesuniecia pionowego do tabeli w pliku tabela.txt
	la $a1, lin
	move $a0,$t4				#do $a0 kopiujemy handler pliku do zapisu
	li $v0,15				#przerwanie systemowe - zapis do pliku
	li $a2, 3				#ilosc danych w bajtach, ktore maja byc zapisane do pliku
	syscall	

	move $t7, $s1				#zamiana wartosci liczbowej na ASCII
	la $a0, ($t7)
	la $a1, hamm
	jal itoa

	move $a0,$t4				#do $a0 kopiujemy handler pliku do zapisu
	li $v0,15				#przerwanie systemowe - zapis do pliku
	li $a2, 2				#ilosc danych w bajtach, ktore maja byc zapisane do pliku
	syscall		

	la $a1, odstep4
	li $v0,15				#przerwanie systemowe - zapis do pliku
	li $a2, 2				#ilosc danych w bajtach, ktore maja byc zapisane do pliku
	syscall	
			
	la $a1, odstep4
	li $v0,15				#przerwanie systemowe - zapis do pliku
	li $a2, 2				#ilosc danych w bajtach, ktore maja byc zapisane do pliku
	syscall	
	
	move $t7, $s1 				#o ile linii mamy przesunac - skopiowanie z $s1 wartosci przesuniecia pionowego
	blez $t7, zmien_znak 			#jesli przesuniecie<0 przesuwamy drugi obrazek o wartosc bezwzgledna przesuniecia
	
przesun_1:					#przesuwanie pierwszego obrazka
	beqz $t7, loop2  			#jesli liczba przesuniec pozostalych do zrobienia==0 wczytaj bajty
	addiu $s4, $s4, 8			#zwiekszamy indeks o 8 (przeskakujemy do nastepnej linii) w pliku 1
	subi $t7, $t7, 1			#dekrementacja licznika (liczby pozostalych przesuniec)
	j przesun_1
	
zmien_znak:				
	abs $t7, $t7				#jesli liczba przesuniec<0 - bierzemy wartosc bezwzgledna

przesun_2:
	beqz $t7, loop2 			#jesli liczba pozostalych przesuniec===0 wczytaj bajt
	addiu $s5, $s5, 8			#zwiekszamy indeks o 8 (przeskakujemy do nastepnej linii) w pliku 2
	subi $t7, $t7, 1			#dekrementacja licznika(liczby pozostalych przesuniec)		
	j przesun_2

dodajtab:					#zapisanie aktualnej odleglosci Hamminga do pliku
	#zamiana wartosci na kod ASCII
	move $t7, $s6		
	la $a0, ($t7)
	la $a1, hamm
	jal itoa

	#zapisanie wartosci do tablicy w pliku tablica.txt
	move $a0,$t4				#do $a0 kopiujemy handler pliku do zapisu
	li $v0,15				#przerwanie systemowe - zapis do pliku
	li $a2, 5				#ilosc danych w bajtach, ktore maja byc zapisane do pliku
	syscall		
	
sprawdzmin:
	#znajdowanie minimalnej odl. Hamminga
	bgt $s6, $s7, loop2			#jesli aktualna odleglosc Hamminga jest wieksza od minialnej, skocz do loop2
	move $s7, $s6
		
loop2:
	move $t8, $s5				#indeks pierwszego obrazka
	move $t9, $s4 				#indeks drugiego obrazka
	addi $s0, $s0, 1			#zwiekszenie przesuniecia poziomego o 1
	li $s6, 0 				#wyzerowanie licznika rozniacych sie miejsc
	beq $s0, 8, loop			#jesli przesuniecie>7 - przesuwamy pionowo

porown_4B:

	lw $t0, buf1($t8) 			#ladujemy 4 bajty z pierwszego pliku (32piksele)
	lw $t1, buf2($t9) 			#ladujemy 4 bajty z druiego pliku (32piksele)
	
	#zmiana kolejnosci wczytanych bajtow w rejestrze $t0
	move $t6, $t0
	jal zmiana_kolejnosci_bajtow
	move $t0, $a0
	#zmiana kolejnosci wczytanych bajtow w rejestrze $t1	
	move $t6, $t1
	jal zmiana_kolejnosci_bajtow
	move $t1, $a0
	

	addiu $t8, $t8, 4			#zwiekszenie indeksu w pierwszym pliku
	addiu $t9, $t9, 4			#zwiekszenie indeksu w drugim pliku
	lw $t2, buf1($t8) 			#ladujemy 4 bajty z pierwszego pliku (32piksele) - druga polowka wiersza
	lw $t3, buf2($t9)			#ladujemy 4 bajty z druiego pliku (32piksele) - druga polowka wiersza

	#zmiana kolejnosci wczytanych bajtow w rejestrze $t2
	move $t6, $t2
	jal zmiana_kolejnosci_bajtow
	move $t2, $a0
	#zmiana kolejnosci wczytanych bajtow w rejestrze $t3
	move $t6, $t3
	jal zmiana_kolejnosci_bajtow
	move $t3, $a0

zmien_znak2:
	abs $s2, $s0				#jesli liczba przesuniec<0 - bierzemy wartosc bezwzgledna
	
	beqz $s0, porown1			#jesli liczba przesuniec==0, porownujemy bity
	bgtz $s0, przesuw2			#jesli liczba przesuniec>0, przesuwamy drugi obrazek
	

przesuw1:

shift:
	sllv $t0, $t0, $s2			#przesuniecie logiczne w lewo o $s0 pierwszej polowy wiersza
	rol $t2, $t2, $s2			#rotacja w lewo o $s0 drugiej polowy wiersza
	move $t6, $t2 				#skopiowanie $drugiej polowy wiersza do $t6
	
	#w rejestrze $t5 umieszczamy 2^$s0-1
	move $t7, $s2				#ustawienie licznika $t7 na $s0
	li $t5, 2
	subi $t7, $t7, 1			#zmniejszenie licznika $t7
potega2:					#obliczenie 2^$s0 - 1
	blez $t7, dalej				#jesli licznik wyzerowany - koniec petli
	sll $t5, $t5, 1				#przesuwamy logicznie $t5 w lewo == mnozymy*2
	subi $t7, $t7, 1
	j potega2
	
dalej:
	subiu $t5, $t5, 1			#odejmujemy 1
	and $t6, $t6, $t5			#$t6 and $t5 - reszta z dzielenia liczby z rejestru $t6 przez 2^$s0
	sub $t2, $t2, $t6 			#od liczby po rotacji odejmujemy reszte z dzielenia - otrzymujemy liczbe 
						#po przesunieciu logicznym w lewo
	addu $t0, $t0, $t6 			#do pierwszej polowy wiersza dodajemy bity 'przesuniete' w rotacji
	j porown1				#skocz do porownania bitow
	

przesuw2:					#przesuwanie drugiego obrazka

shift2:
	sllv $t1, $t1, $s0			#przesuniecie logiczne w lewo o $s0 pierwszej polowy wiersza
	rol $t3, $t3, $s0			#rotacja w lewo o $s0 drugiej polowy wiersza
	move $t6, $t3 				#skopiowanie $drugiej polowy wiersza do $t6
	
	#w rejestrze $t5 umieszczamy 2^$s0-1
	move $t7, $s0				#ustawienie licznika $t7 na $s0
	li $t5, 2
	subi $t7, $t7, 1			#zmniejszenie licznika $t7
potega22:					#obliczenie 2^$s0 - 1
	blez $t7, dalej2				#jesli licznik wyzerowany - koniec petli
	sll $t5, $t5, 1				#przesuwamy logicznie $t5 w lewo == mnozymy*2
	subi $t7, $t7, 1
	j potega22
	
dalej2:
	subiu $t5, $t5, 1			#odejmujemy 1
	and $t6, $t6, $t5			#$t6 and $t5 - reszta z dzielenia liczby z rejestru $t6 przez 2^$s0
	sub $t3, $t3, $t6 			#od liczby po rotacji odejmujemy reszte z dzielenia - otrzymujemy liczbe 
						#po przesunieciu logicznym w lewo
	addu $t1, $t1, $t6 			#do pierwszej polowy wiersza dodajemy bity 'przesuniete' w rotacji


porown1: #porownuje 1sze polowki wierszy
	xor $s3, $t0, $t1 			#xorujemy $t1 i %t0 - tam gdzie bêd¹ jedynki slowa sie roznia
	li $t7,0				#wyzerowanie licznika

licz:
	bgez $s3, rown0 			#jesli liczba jest dodatnia => najwazniejszy bit=0, czyli slowa nie roznia sie na tym bicie
	addiu $s6, $s6, 1			#najwazniejszy bit=0, inkrementujemy liczbe roznic
rown0:
	addiu $t7, $t7, 1			#inkrementujemy licznik $t7
	sll $s3, $s3, 1				#przesuniecie logiczne w lewo
	ble $t7, 32, licz			#wykonuj dopoki licznik<= 32


porown2: #porownuje drugie polowki wierszy

	xor $s3, $t2, $t3 			#xorujemy $t2 i %t3 - tam gdzie bêd¹ jedynki slowa sie roznia
	li $t7,	32				#ustawienie licznika petli na 32-przesuniecie w poziomie
	sub $t7, $t7, $s2
licz2:	
	bgez $s3, rown02 			#jesli liczba jest dodatnia => najwazniejszy bit=0, czyli slowa nie roznia sie na tym bicie

	addiu $s6, $s6, 1			#najwazniejszy bit=0, inkrementujemy liczbe roznic
rown02:
	subiu $t7, $t7, 1			#inkrementujemy licznik $t7
	sll $s3, $s3, 1				#przesuniecie logiczne w lewo
	bnez $t7, licz2				#wykonuj dopoki licznik>0

	#koniec sprawdzania tych bajtow, zwiekszamy indeksy
	addiu $t8, $t8, 4			#zwiekszamy indeks w pierwszym obrazku o 4
	addiu $t9, $t9, 4			#zwiekszamy indeks w drugim obrazku o 4
	bge $t8, 512, dodajtab			#jesli wyszlismy poza rozmiar buf1, skaczemy do dodajtab
	bge $t9, 512, dodajtab			#jesli wyszlismy poza rozmiar buf1, skaczemy do dodajtab
	j porown_4B
	
######################################################
# $s0 - kopia handlera do zamkniecia pliku hamming.txt
######################################################


zapisz_hamming:
	li $v0, 13 				#system call for file_open
	la $a0, outfile1 			#address of filename string
	li $a1, 1 
	li $a2, 0
	syscall 				#file descriptor of opened file in v0
	move $s0, $v0				# kopia handlera do zamkniecia pliku

	la $a0, ($s7)				#zamiana liczby na kod ASCII
	la $a1, hamm
	jal itoa


	move $a0,$s0				#do $a0 kopiujemy handler pliku do zapisu
	li $v0,15				#przerwanie systemowe - zapis do pliku
	li $a2, 2				#ilosc danych w bajtach, ktore maja byc zapisane do pliku
	syscall		
	
	li $v0, 16				#syscall for close_file
	la $a0, ($s0)
	syscall
	
	j exit
	
error1:						#jesli nastapil blad odczytu pliku
	la $a0, err1
	li $v0, 4
	syscall
	j exit
	
exit:
	li $v0, 16				#szamkniecie pliku tablica.txt
	la $a0, ($t4)
	syscall
	li $v0, 10				#zakonczenie programu
	syscall


###############################################################
# Ito A - zamiana liczby (integer) na kod ASCII 
# argumenty:
#    $a0 - integer do zamiany
#    $a1 - miejsce zapisania znakow przekonwertowanych
# zwraca:  liczba znakow w ciagu wyjsciowym
#
itoa:
li $t0, ' '
sb $t0, 0($a1)	
sb $t0, 1($a1)
sb $t0, 2($a1)
sb $t0, 3($a1)
  bnez $a0, itoa.non_zero  # jesli wartosc ==0
  nop
  li   $t0, '0'
  sb   $t0, 0($a1)
  sb   $zero, 1($a1)
  li   $v0, 1
  jr   $ra
itoa.non_zero:
  addi $t0, $zero, 10     # jesli wartosc < 0
  li $v0, 0
    
  bgtz $a0, itoa.recurse
  nop
  li   $t1, '-'
  sb   $t1, 0($a1)
  addi $v0, $v0, 1
  neg  $a0, $a0
itoa.recurse:
  addi $sp, $sp, -24
  sw   $fp, 8($sp)
  addi $fp, $sp, 8
  sw   $a0, 4($fp)
  sw   $a1, 8($fp)
  sw   $ra, -4($fp)
  sw   $s0, -8($fp)
  sw   $s1, -12($fp)
   
  div  $a0, $t0       
  mflo $s0            # $s0 = quotient
  mfhi $s1            # s1 = remainder  
  beqz $s0, itoa.write
itoa.continue:
  move $a0, $s0  
  jal itoa.recurse
  nop
itoa.write:
  add  $t1, $a1, $v0
  addi $v0, $v0, 1    
  addi $t2, $s1, 0x30 # zmien na ASCII
  sb   $t2, 0($t1)    # przechowaj w buforze
  sb   $zero, 1($t1)
  
itoa.exit:
  lw   $a1, 8($fp)
  lw   $a0, 4($fp)
  lw   $ra, -4($fp)
  lw   $s0, -8($fp)
  lw   $s1, -12($fp)
  lw   $fp, 8($sp)    
  addi $sp, $sp, 24
  jr $ra

########################################
# Zamiana kolejnosci bajtow w rejestrze
# rejestr z zamienionymi bajtami - $a0
########################################
zmiana_kolejnosci_bajtow:
	li $a0, 0
	move $a1, $t6
	srl $a1, $a1, 24
	add $a0, $a0, $a1
	move $a1, $t6
	sll $a1, $a1, 8
	srl $a1, $a1, 24
	sll $a1, $a1, 8
	add $a0, $a0, $a1
	move $a1, $t6
	srl $a1, $a1, 8
	sll $a1, $a1, 24
	srl $a1, $a1, 8
	add $a0, $a0, $a1
	move $a1, $t6
	sll $a1, $a1, 24
	add $a0, $a0, $a1
	jr $ra

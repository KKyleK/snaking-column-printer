; name:	Kyle Koivuneva
; Student ID: 201485395
; Course: Comp 2655
; Assignment: Final exam
; Due Date: December 22nd
; File name: snaking.s
; Instructor: Paul Pospisil
;
;
; Purpose: Given an input file containing lines of words,
;          Prints them to the screen in column snaking form
;
; Details: First traverses the input file, gathering data on
;          the number of lines and the longest word in that file.
;          Uses that information to determine other statistics about
;	   the file. Prints out a number line, and then using the 
;	   previously calculated statistics, writes out the words 
;          in column snaking format
;
;Program status: Correctly writes out files where there are no 
;                elements in the last row. If there are elements in
;	   	 the last row, missing elements are absent in the last
;		 column rather then the last row as specified.
;		 
;	         Also, if a word is longer then 80 digits long, the
;		 word is cut off, however the last letter that should
;		 be printed is not, and instead the last letter of the
;                word is printed instead.  
;
;	         Other then faulty printing, the stats portion works
;		 as intended, as does the number line, and error
;		 testing for empty or missing file.
;
; Values tested: File contents with a max word size between 0-79 (works)
;		 File contents with a max word size of 80 (works)
;		 File contents with a max word size of 81 (fails) 
;
;		 File contents with no partialy filled last row (works)
;		 File contents with partialy filled last row (fails)
; 		 File contents of one single filled row (works)
;		 File contents of one single unfilled row (works)
;		
;		 File contents of the example given (fails)
;
; 		 For all values tested, the program failed to print
;		 if there was a partially filled last row, where the 
;		 missing elements would cause a gap in the last column
;		 instead of the last row, as well as 81+ character words
;		 print the incorrect final character (as mentioned above)
;
;
; Register Table (for main):
;
; d0: holds return value from opening the file
; d1: holds number of characters read from file opening
; 
; Each register used (d0-d7) to hold one of the statistics 
; during the writing of the statisitcs to the screen portion
;
; a0: holds intermediate values
; a1: holds the stats array

	xref		openFile
	xref		closeFile
	xref		resetFile
	xref		readCharFile

start:

	lea		stats,a6	;stats data type declared

	move.l		#0,-(sp)	;make room for return value
	pea		chars_read	;pass first parameter
	jsr		openFile

	move.l		(sp)+,a0	;number of chars read
	move.l 		(a0),d1		;chars read (need in a register)
	move.l		d1,NUM_WORDS(a6)	;for later
	move.l		(sp)+,d0	;return value - if file opened

	cmpi.l		#0,d0			;error and exit if no file
	beq		skip_file_not_found

	pea		not_found
	jsr		write_message
	addq.l		#4,sp		;print not found and terminate
	bra		done

skip_file_not_found:

	cmpi.l		#0,d1
	bne		skip_empty	;check if file is empty

	pea		empty
	jsr		write_message
	addq.l		#4,sp		;print empty file and terminate
	bra		done
skip_empty:
	
	move.l		#0,-(sp)		;num words
	move.l		#0,-(sp)		;longest word	
	move.l		d1,-(sp)		;pass first parameter
	jsr		longest_word
	add.l		#4,sp		        ;pop off input parameter
	move.l		(sp)+,LONGEST(a6)	;store the longest word 
	move.l		(sp)+,NUM_WORDS(a6)	;store number of words

        ;push down space for return values
	move.w		#0,-(sp)		;# of collumns (80 max) 
	move.w		#0,-(sp)		;# of rows (24 max)
	move.w		#0,-(sp)		;# of words in last row				 
	move.w		#0,-(sp)		;# of total spaces
	move.w		#0,-(sp)		;# of spaces between
	move.w		#0,-(sp)		;# of extra spaces	

	;push down input parameters
	move.l		NUM_WORDS(a6),-(sp)	;# of total words	
	move.l		LONGEST(a6),-(sp)	;length of longest word

	jsr		calculate_stats

	add.l		#8,sp			;get rid of input

	move.w		(sp)+,EXTRA_SPACES(a6)
	move.w		(sp)+,SPACES_BETWEEN(a6)
	move.w		(sp)+,TOTAL_SPACES(a6)	;place return values 
	move.w		(sp)+,WORDS_LROW(a6)	;into stats structure
	move.w		(sp)+,NUM_ROW(a6)
	move.w		(sp)+,NUM_COL(a6)

	clr.l		d0
	clr.l		d1
	clr.l		d2
	clr.l		d3	;clear registers for message writing
	clr.l		d4	;must be longs, since the subroutine
	clr.l		d5	;writes the ascii value of long words
	clr.l		d6
	clr.l		d7

	move.w		EXTRA_SPACES(a6),d0
	move.w		SPACES_BETWEEN(a6),d1
	move.w		TOTAL_SPACES(a6),d2 ;transfer values for subroutines 
	move.w		WORDS_LROW(a6),d3	
	move.w		NUM_ROW(a6),d4
	move.w		NUM_COL(a6),d5
	move.l		NUM_WORDS(a6),d6
	move.l		LONGEST(a6),d7

	pea		num_words	;message to print
	jsr		write_message	;write the message
	addq.l		#4,sp
	move.l		d6,-(sp)		
	jsr		write_amount	;write the amount
	add.l		#4,sp
	move.w		#CR,-(sp)
	jsr		write_char
	add.l		#2,sp		;new line
	move.w		#LF,-(sp)
	jsr		write_char
	add.l		#2,sp

	pea		longest		;repeat for each message and
	jsr		write_message	;value	
	addq.l		#4,sp
	move.l		d7,-(sp)		
	jsr		write_amount	
	add.l		#4,sp
	move.w		#CR,-(sp)
	jsr		write_char
	add.l		#2,sp		
	move.w		#LF,-(sp)
	jsr		write_char
	add.l		#2,sp

	pea		num_col
	jsr		write_message	
	addq.l		#4,sp
	move.l		d5,-(sp)		
	jsr		write_amount	
	add.l		#4,sp
	move.w		#CR,-(sp)
	jsr		write_char
	add.l		#2,sp		
	move.w		#LF,-(sp)
	jsr		write_char
	add.l		#2,sp

	pea		num_row
	jsr		write_message	
	addq.l		#4,sp
	move.l		d4,-(sp)		
	jsr		write_amount	
	add.l		#4,sp
	move.w		#CR,-(sp)
	jsr		write_char
	add.l		#2,sp		
	move.w		#LF,-(sp)
	jsr		write_char
	add.l		#2,sp

	pea		words_lrow
	jsr		write_message	
	addq.l		#4,sp
	move.l		d3,-(sp)		
	jsr		write_amount	
	add.l		#4,sp
	move.w		#CR,-(sp)
	jsr		write_char
	add.l		#2,sp		
	move.w		#LF,-(sp)
	jsr		write_char
	add.l		#2,sp

	pea		total_spaces
	jsr		write_message	
	addq.l		#4,sp
	move.l		d2,-(sp)		
	jsr		write_amount	
	add.l		#4,sp
	move.w		#CR,-(sp)
	jsr		write_char
	add.l		#2,sp		
	move.w		#LF,-(sp)
	jsr		write_char
	add.l		#2,sp

	pea		spaces_between
	jsr		write_message	
	addq.l		#4,sp
	move.l		d1,-(sp)		
	jsr		write_amount	
	add.l		#4,sp
	move.w		#CR,-(sp)
	jsr		write_char
	add.l		#2,sp		
	move.w		#LF,-(sp)
	jsr		write_char
	add.l		#2,sp


	pea		extra_spaces
	jsr		write_message	
	addq.l		#4,sp
	move.l		d0,-(sp)		
	jsr		write_amount	
	add.l		#4,sp
	move.w		#CR,-(sp)
	jsr		write_char
	add.l		#2,sp		
	move.w		#LF,-(sp)
	jsr		write_char
	add.l		#2,sp
	
	jsr		number_line	;write the number line

	pea		stats		;pass the stats structure
	jsr		display_words	;write the words to the screen
	add.l		#4,sp		;correct stack

done:
	jsr		closeFile
	jsr		exit		;close file and exit



;----- SUBROUTINE: display_words -----
;
; Void display_words(stats);
;
; Purpose: Prints the content of a file in snaking column
;          order.
;
; Details: Writes the top line of the file first, and then
;          skips over words. The number of words skipped over is
;          = number of words/number of columns -1, +1 if 
;	   words%num col >0. By 'consuming' or skipping words,
;          each row is written out. Once a row is finished, the file
;	   reset, and the program restarts the process, starting at
;          the second line if there is still more words to print
; 
;
; Register Table:
;
; d1: counter for current word 
; d2: counter for if the program has written out all words
; d3: holds the number of words to be consumed
; d4: holds the number of initial words to be consumed, following
;     a file reset
; d6: works as the counter for printing spaces, writing words, and
;     consuming
; d7: holds intermediate values

display_words:

	link		a1,#0
	movem.l		d0-d7,-(sp)	;d0 stored to prevent corruption	

	move.l		8(a1),a2    	;move stats into an adress
					;register where values can be
	move.l		NUM_WORDS(a2),d2 ;extracted
	clr.l		d3	
	move.w		NUM_COL(a2),d3
	
	divu.w		d3,d2
	move.w		d2,d3		;d3: number to consume
	sub.w		#1,d3		;#'s to consume = elements/
	lsr.l		#8,d2		;collumns - 1 + 1 if remainder
	lsr.l		#8,d2

	cmpi.w		#0,d2		;check if there is a remainder	
	beq		skip_extra
	add.w		#1,d3

skip_extra:

	move.l		NUM_WORDS(a2),d2	;number of words
	move.l		#1,d1		;current word (start at word 1)
		
	move.l		#0,d4		;number of words to initially
					;consume
next_row:

	jsr		resetFile
	move.l		#1,d1		;currently at word 1

initial_consume:
	move.l		d4,d6		;initial consumes counter (d6)

change_start_point:
	
	cmpi.l		#0,d6
	beq		reset_chars	;check if enough words have 		
					;been skipped
	sub.l		#2,sp		;read character
	jsr		readCharFile
	move.w		(sp)+,d7	
	lsr.w		#8,d7		;since value is in high order word

	cmpi.w		#CR,d7		;check if at end of line
	bne		change_start_point

	add.l		#1,d1		;update current word (at next line)

	sub.l		#2,sp		
	jsr		readCharFile	;consume the LF
	add.l		#2,sp	

	dbra		d6,change_start_point	;consume next line

reset_chars:
	move.l		LONGEST(a2),d6	;counter for number of chars

write_to_screen:

	sub.l		#2,sp		;room for result
	jsr		readCharFile
	move.w		(sp)+,d7	
	lsr.w		#8,d7		;since value is in high order word

	cmpi.w		#CR,d7
	beq		next_word

	move.w		d7,-(sp)
	jsr		write_char	;print
	add.l		#2,sp
	sub.l		#1,d6		;character printed
	
	bra		write_to_screen	 ;repeat till CR encountered

next_word:

	add.l		#1,d1	;at the next word
	sub.w		#1,d2	;counter for number of words printed

	sub.l		#2,sp		
	jsr		readCharFile	;consume the LF
	add.l		#2,sp		

pad:
	cmpi.l		#0,d6		;add space padding if number	
	beq		done_padding    ;of characters printed is less
	move.w		#SPACE,-(sp)	;then the length of the longest word
	jsr		write_char	;print spaces
	add.l		#2,sp
	dbra		d6,pad
	
done_padding:
	
	move.w		SPACES_BETWEEN(a2),d6   ;counter for printing	

print_spaces_between:
	cmpi.l		#0,d6			
	beq		done_spaces_between
	move.w		#SPACE,-(sp)
	jsr		write_char		;print spaces
	add.l		#2,sp
	dbra		d6,print_spaces_between	

done_spaces_between:

	move.w		d3,d6		;d6 as our counter for consuming
	cmpi.w		#0,d6		
	beq		no_consume	;skip consuming if only 1 row	
	
	cmp.l		NUM_WORDS(a2),d1  ;at last element, nothing to 
	bhi		no_consume	  ;consume	  

	sub.l		#1,d6		;1- for dbra
consume:	
	
	cmp.l		NUM_WORDS(a2),d1  ;stop consuming if at eof 
	bhi		no_consume	  


	sub.l		#2,sp		;room for result
	jsr		readCharFile
	move.w		(sp)+,d7	
	lsr.w		#8,d7		;since value is in high order word

	cmpi.w		#CR,d7		;consume till at CR
	bne		consume

	add.l		#1,d1		;update current word location

	sub.l		#2,sp		
	jsr		readCharFile	;consume the LF
	add.l		#2,sp	

	dbra		d6,consume	;consume next word 
		
no_consume:

	cmpi.l		#0,d2		;completely done printing
	beq		done_printing

	cmp.l		NUM_WORDS(a2),d1  ;new line - reset the file
	bhi		new_line	

	bra		reset_chars	;print next word, continue down
					;same row

new_line:
	add.l		#1,d4		;to print next line need to traverse 
	move.w		#CR,-(sp)	;down words first. d4 incremented
	jsr		write_char	;so program starts by consuming
	add.l		#2,sp		;till it is at correct word
	move.w		#LF,-(sp)
	jsr		write_char
	add.l		#2,sp
	bra		next_row	;onto the next row

done_printing:


	movem.l		(sp)+,d0-d7 
	unlk		a1
	rts


;----- SUBROUTINE: number_line -----
;
; Void number_line();
;
; Purpose: Prints a number line across the screen.
;
; Details: First prints 1-8, by incrementing 10 spaces
;	   between each number. Then prints a continuous 
;	   1-90 eight times.
;
; Register Table:
;
; d1: counter for which digit should be printed
; d2: counter for how many more prints should be done

number_line:

	movem.l		d0-d2,-(sp)

	move.l		#8,d2		;counter for where the digits fall
	move.l		#0,d1		;counter for placing the digits
		
print_spaces:

	move.w		#SPACE,-(sp)
	jsr		write_char	;print 9 spaces (tenth is a number)
	add.l		#2,sp

	dbra		d2,print_spaces

	add.l		#1,d1		;increment number to be printed
	move.l		#8,d2

	add.b		#ASCII,d1	
	move.w		d1,-(sp)
	jsr		write_char	;print a number by converting 
	add.l		#2,sp		;to it's ascii value first
	sub.b		#ASCII,d1

	cmpi.b		#8,d1		;repeat for 1-8
	bne		print_spaces


	move.w		#CR,-(sp)
	jsr		write_char
	add.l		#2,sp		;new line, next portion of the
	move.w		#LF,-(sp)	;number line
	jsr		write_char
	add.l		#2,sp

	move.l		#1,d1
	move.l		#79,d2		;79 (80 because of dbra)
print_numbers:				;characters to print, starting
	add.b		#ASCII,d1	;at one	
	move.w		d1,-(sp)
	jsr		write_char	;print first character
	add.l		#2,sp
	sub.b		#ASCII,d1

	add.l		#1,d1		;increment character to print

	cmpi.b		#10,d1
	bne		skip_reduce	;only printing 1-9 and 0, so at
	move.l		#0,d1		;10, cycle back to 0

skip_reduce:
	dbra		d2,print_numbers	;repeat till all digits
						;printed
	move.w		#CR,-(sp)
	jsr		write_char
	add.l		#2,sp		
	move.w		#LF,-(sp)
	jsr		write_char
	add.l		#2,sp

	move.w		#CR,-(sp)
	jsr		write_char
	add.l		#2,sp		;write two new lines
	move.w		#LF,-(sp)
	jsr		write_char
	add.l		#2,sp

	movem.l		(sp)+,d0-d2


;----- SUBROUTINE: write_char -----
;
; Void write_char(word);
;
; Purpose: Writes a character to the screen
;
; Details: Uses a gemdos call to write a character  
;          to the screen. 		
;
; Register Table: No registers used

write_char:
	link		a1,#0
	movem.l		d0/a0,-(sp)	;save d0 and a0 from corruption
	move.w		8(a1),-(sp)

	move.w		#2,-(sp)	;gemdos call number for writing
	trap		#1
	addq.l		#4,sp

	movem.l		(sp)+,d0/a0
	unlk		a1
	rts



;----- SUBROUTINE: write_amount -----
;
; Void write_amount(long);
;
; Purpose: writes a word or long word to the screen in it's 
;	   ascii form
;
; Details: Decomposes the number by dividing by 10. The remainder
;	   is placed onto the stack to be printed, and the number is
;          divided again, with it's remainder again being placed onto
;          the stack. This process continues until the number is 0, where
;          the stack contents are written out using the write_char 
;          function.
;
;
; Register Table:
;
; d1: holds the long word to be printed
; d2: holds the remainder of divisions
; d3: holds the number of numbers to be printed


write_amount:	
	link		a1,#0
	movem.l		d0-d3/a0,-(sp)
	move.l		8(a1),d1	;the long word to be printed

	clr.l		d3	;counter for printing the stack

print:
	divu.w		#10,d1
	move.l		d1,d2
	clr.l		d1		;divide by 10, store remainder
	move.w		d2,d1		;in d2
	
	lsr.l		#8,d2
	lsr.l		#8,d2

	move.w		d2,-(sp)	;remainder (to be printed) placed
					;on stack to reverse order
	add.l		#1,d3		
	cmpi.w		#0,d1		;once the number is at 0, stop
	bne		print

	sub.l		#1,d3

print_loop:
	move.w		(sp)+,d1	;pop words off one by one

	add.b		#ASCII,d1	;turn digit into ascii before
					;printing
	move.w		d1,-(sp)
	jsr		write_char	;print word
	addq.l		#2,sp

	dbra		d3,print_loop	;next word

	movem.l		(sp)+,d0-d3/a0
	unlk		a1
	rts


;----- SUBROUTINE: calculate_stats -----
;
; words & longs calculate_stats(words and longs); (multiple return and input
;					       parameters)
;
; Purpose: Calculates all of the statistics required
;	   for filling the stats structure
;
;
; Details: Calculations are done as follows.
;          number of columns = 80/length of longest word 
;	   number of spaces per row = 80%length of longest word 
;	   number of spaces between = num spaces/num columns 
;	   number of extra spaces = num spaces%num columns
;	   number of rows = num words/num columns. +1 if 
;	                    number of elements on last row is >0
;	   num elements last row = num words % num columns        
; 
;	   The function returns each of the above calculated
;          measurements
;
; Register Table:
;
; d1: holds the longest word
; d2: holds the number of columns
; d3: used for holding results of calculations


calculate_stats:

	link		a1,#0
	movem.l		d1-d4/a0,-(sp)
	
	clr.l		d0		;clear the upper word of d0
	move.l		8(a1),d1	;longest word

	cmpi.l		#80,d1		;spaces = 0, collumns = 1
	bcs		proceed		;test if longest word is 80
					;or larger

	move.l		#0,d4		;no spaces
	move.l		#1,d3		;1 column

	move.w		d4,20(a1)	;number of total spaces saved
	move.w		d3,26(a1)	;number of collumns, saved
	
	move.l		#0,d3
	move.w		d3,18(a1)	;0 spaces inbetween 
	move.w		d4,16(a1)	;0 spaces after each element

	bra		rows		;skip to calculating rows
proceed:

	move.l		#80,d3
	divu.w		d1,d3		;get number of collumns
	
	move.l		d3,d4           
	and.l		#$0000FFFF,d3
	lsr.l		#8,d4		;number of spaces	
	lsr.l		#8,d4

more_spaces:

	cmp.w		d3,d4		;check if there is at least
	bcc		good		;1 space per column

	sub.w		#1,d3		;othwerise one less collumn for
	add.w		d1,d4		;more spaces between words
	bra		more_spaces	;check again (might need more)

good:	

	move.w		d4,20(a1)	;number of total spaces saved
	move.w		d3,26(a1)	;number of collumns, saved
	
	divu.w		d3,d4		;quotient: number of spaces
					;remainder:remaining spaces
	move.l		d4,d3
	and.l		#$0000FFFF,d3
	lsr.l		#8,d4			
	lsr.l		#8,d4

	move.w		d3,18(a1)	;spaces inbetween saved
	move.w		d4,16(a1)	;extra spaces at end saved

rows:
	move.l		12(a1),d1	;number of words
	move.w		26(a1),d2	;number of collumns (.long to clear)

	divu.w		d2,d1
	move.w		d1,d3		;number of rows calculated
	lsr.l		#8,d1
	lsr.l		#8,d1		;number of words on last row

	cmpi.w		#0,d1		;check if there is a partial row
	beq		skip_add

	add.w		#1,d3		;add extra row if 
	jsr		skip_change	;number of last row words
					;equal to number of collumns.
skip_add:

	move.w		26(a1),d1

skip_change:
	move.w		d1,22(a1)	;number of last row words saved
	move.w		d3,24(a1)	;number of total rows saved

	movem.l		(sp)+,d1-d4/a0
	unlk		a1
	rts


;----- SUBROUTINE: write_message -----
;
; Void write_message(char[]);
;
; Purpose: Prints an array of chars until a null is encounterd.
;
; Details: Prints words using the gemdos call. The array to be
;	   printed is placed onto the stack along with the 
;          gemdos function call number.
;
; Register Table: no registers used

write_message:
	link		a1,#0
	movem.l		d0/a0,-(sp)	;prevents d0 or a0 from 
	move.l		8(a1),-(sp)	;becoming undefined	
	move.w		#9,-(sp)
	trap		#1
	addq.l		#6,sp		;correct the stack		
	movem.l		(sp)+,d0/a0	;keeps d0 and a0 in tact
	unlk		a1
	rts


;----- SUBROUTINE: exit -----
;
; PURPOSE: Exits the program
;

exit:
	clr.w		-(sp)
	trap		#1

;----- SUBROUTINE: longest_word -----
;
; LONG longest_word(LONG) (returns two longs)
;
; PURPOSE: returns the size of the longest word in the file
;
; details: resets the file, and reads through every line, 
;	   keeping track of the longest line (discludes CR and LF's)
;	   returns the longest word, and the number of words
;
;	
;d0: Number of characters
;d1: current number of characters
;d2: largest number of characters
;d3: current character
;d4: holds the number of words read

longest_word:
	link		a1,#0
	movem.l		d0-d4,-(sp)
	move.l		8(a1),d0	;the number of chars in the file
	sub.l		#1,d0		;for dbra (d0 used as a counter)

	jsr		resetFile	;back to top of file
	
	clr.l		d2
	clr.l		d1
	clr.l		d4

read_file:

	sub.l		#2,sp		
	jsr		readCharFile	;read a character
	move.w		(sp)+,d3	
	lsr.w		#8,d3		;since value is in high order word

	cmpi.b		#CR,d3		;if it's a CR, end of the line
	beq		compare

	add.l		#1,d1
	bra		next

compare:

	add.l		#1,d4		;counter for number of words
	sub.l		#1,d0		;for the LF character

	sub.l		#2,sp		;read LF character
	jsr		readCharFile
	move.w		(sp)+,d3	;don't save it

	cmp.l		d1,d2
	bls		new_largest	;check if the new word is longer
	bra		reset

new_largest:
	move.l		d1,d2		

reset:
	clr.l		d1		;new line
next:
	
	dbra		d0,read_file	;read the next line

	move.l		d2,12(a1)	;return largest word 
	move.l		d4,16(a1)	;return number of words
	movem.l		(sp)+,d0-d4 	
	unlk		a1
	rts



NUM_WORDS		equ	0	;num of words (long)
LONGEST			equ	4	;longest word (long)
NUM_COL			equ	8	;number of collumns (word)
NUM_ROW			equ	10	;number of rows (word)
WORDS_LROW		equ	12	;number of words in last row (word)
TOTAL_SPACES		equ	14	;number of total spaces (probs word)
SPACES_BETWEEN		equ	16	;spaces between each word (word)
EXTRA_SPACES		equ	18

stats:			ds.b	20 	

not_found:		dc.b	"file not found",NULL
empty:			dc.b	"empty file",NULL
chars_read:		dc.l	0

num_words:		dc.b	"Number of words = ",NULL
longest:		dc.b	"Max word length = ",NULL
num_col:		dc.b	"Number of columns = ",NULL
num_row:		dc.b	"Number of rows = ",NULL
words_lrow:		dc.b	"Number of words in the last row = ",NULL
total_spaces:		dc.b	"Number of total spaces in a row = ",NULL	
spaces_between:		dc.b	"Number of spaces between columns = ",NULL
extra_spaces:		dc.b	"Number of extra spaces at the end of the row = ",NULL




NULL			equ	0
CR			equ	13
LF			equ	10 
ASCII			equ	48
SPACE			equ	' '

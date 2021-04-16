TITLE Low-Level I/O Procedures     (TomKimberlyProgram6A.asm)

; Author: Kimberly Tom
; Last Modified: 12/2/18
; OSU email address: tomki@oregonstate.edu
; Course number/section: 271-400
; Project Number: 6A                Due Date: 12/2/18
; Description: This program obtains 10 unsigned integers that fit in 32 bit register from the user as a string,
; then converts the string into numerical form.  It prints the integers to the console by then converting the numerical
; form numbers back to string form.  It also calculates the sum and average of the 10 integers, converts both back to
; string from, then prints the sum and average to the console. 

INCLUDE Irvine32.inc

NUM_ARRAY_LENGTH EQU 10							; max length of an integer that can fit in 32 bit register
MAX_STRING_LENGTH EQU 15						; max length of string used for storage from integer to string conversion

;*******************************************************
;macro to get user's number and add to array
;receives:  varName, max size of array, string (named buffer)
;returns: n/a
;preconditions: n/a
;registers changed: eax, ecx, edx
;*******************************************************
mGetString		MACRO		varName, size, buffer
	push			ecx
	push			edx

	mDisplayString	buffer	
	call			crlf
	mov				edx, varName				; where user's input will be stored as string
	mov				ecx, size-1					; max string length the user can enter	
	call			readString					; obtain number from user in the form of a string and store to varName, also sets eax to the string size
	pop				edx
	pop				ecx
ENDM

;*******************************************************
;macro to to display a string
;receives:  string (named buffer)
;returns: string
;preconditions: n/a
;registers changed: edx
;*******************************************************
mDisplayString	MACRO		buffer
	push			edx
	mov				edx, buffer
	call			writeString
	pop				edx
ENDM

.data

title_1				BYTE	"Low-Level I/O Procedures		by Kimberly Tom", 0
intro_1				BYTE	"Provide 10 unsigned integers (each must fit into a 32-bit register).", 0dh, 0ah 
					BYTE	 "After 10 valid integers have been provided, I will display the integers, their sum, and their average.", 0
enterNum_1			BYTE	"Enter an unsigned integer (do not add commas). ", 0
error				BYTE	"The number you entered is out of range or not a number. Try again. ", 0
yourNums			BYTE	"The numbers you have entered are: ", 0
sumMessage			BYTE	"The sum of your integers is: ", 0
avgMessage			BYTE	"The average of your integers is: ", 0
thankUMessage		BYTE	"Thank you for using this program.", 0
goodByeMessage		BYTE	"Good bye!", 0
array				DWORD	10 DUP(?)									; array of 10 integers
userNumber			DWORD	?											; the number the user adds to the array
stringStore			BYTE	15 DUP(?)									; for integer to string conversion
sum					DWORD	?											; to hold sum of integers
avg					DWORD	?											; to hold average of integers

.code
main PROC
   
	; introduction
    push			OFFSET title_1
	push			OFFSET intro_1
	call			introduction
	
	; obtain numbers from user
	push			OFFSET enterNum_1
	push			OFFSET error
	push			OFFSET array
	push			OFFSET stringStore
	call			getUserNum

	; print numbers the user entered
	push			OFFSET array
	push			OFFSET stringStore
	push			OFFSET yourNums
	call			printInteger

	; calculate sum of the integers
	push			OFFSET array
	push			OFFSET sum
	call			calculateSum
	
	; print the sum
	push			OFFSET sumMessage
	push			OFFSET sum
	push			OFFSET stringStore
	call			printCalc

	; calculate the average of the integeres
	push			sum
	push			OFFSET avg
	call			calculateAvg

	; print the average
	push			OFFSET avgMessage
	push			OFFSET avg
	push			OFFSET stringStore
	call			printCalc

	; say goodbye
	push			OFFSET thankUMessage
	push			OFFSET goodByeMessage
	call			finishProgram

	exit	; exit to operating system
main ENDP


;*******************************************************
;Procedure to show the title of the program and the instructions
;receives:  message strings by reference
;returns: title and intro messages printed to console
;preconditions: none
;registers changed: ebp
;*******************************************************
introduction PROC

	push			ebp
	mov				ebp, esp
	mDisplayString	[ebp + 12]
	call			crlf
	call			crlf
	mDisplayString	[ebp + 8]
	call			crlf
	call			crlf

	pop				ebp
	ret				8
introduction ENDP

;*******************************************************
;Procedure to get the numbers from the user
;receives:  prompt string, error message string, array that holds 10 numbers, array to store a string (by reference)
;returns: array of numbers
;preconditions: n/a
;registers changed: ebp, eax, esi, edi, ecx
;*******************************************************
getUserNum PROC
	push		ebp
	mov			ebp, esp

	pushad

	mov			ecx, 10						; for loop count for 10 numbers
		
	mov			edi, [ebp + 12]				; address of number array in edi 
	mov			esi, [ebp + 8]				; address of where string is stored
		
; prompt and call readVal for every spot in the array
getNumber:
	push		[ebp + 20]					; push the prompt to get numbers
	push		[ebp + 16]					; push error message
	push		edi							; push address of number array position
	push		esi							; push the address of where string is stored
	call		readVal
	add			edi, 4						; continue on to the next element of the array
	loop		getNumber					; loop 10 times for 10 numbers

	popad
	pop			ebp
	ret			16
getUserNum ENDP

;*******************************************************
;Procedure that invokes getString macro to get the user's string of digits
;then converts the digit character string to numeric number, while validating the user's input
;receives: prompt string, error string, number array position, string array position for storage, by reference
;returns: a number in the number array position
;preconditions: number user provides must fit in 32 bit register, number must be unsigned
;registers changed: esi, ecx, eax, ebx, edx, edi, ebp
;*******************************************************
readVal PROC
	push		ebp
	mov			ebp, esp
	
	pushad

	; ask user for number and provide string destination
	mGetString	[ebp + 8], MAX_STRING_LENGTH, [ebp + 20] 	

; validate if string user provided fits in 32 bit register
validateNum:
	cmp			eax, 10					
	jg			invalid						; if length of user input is greater than 10, jump to invalid
	mov			esi, [ebp + 8]				; move character string to esi
	mov			ecx, eax					; set loop count to length of user's string which we got from mGetString
	mov			edi, [ebp + 12]				; move array to edi
	mov			eax, 0						; now use eax for the numerical total, set to zero
	cld

; with help from masm32.com and stackoverflow
convertToNumerical:
	push		eax
	lodsb									; load the byte at current address of the character string
	mov			ebx, 0		
	mov			bl, al
	pop			eax			
	cmp			bl, 57
	jg			invalid						; if user input is greater than 57, user didn't input a number and it is invalid
	cmp			bl, 48
	jl			invalid						; if user input is less than 48, user didn't input a number and it is invalid
	mov			edx, 10
	mul			edx							; multiply accumulator by 10
	jc			invalid						; input is too big if carry bit is set, jump to invalid
	sub			bl, 48						; convert the character to a number
	add			eax, ebx					; add the number to the numerical total
	jc			invalid						; input is too big if carry bit is set, jump to invalid
	loop		convertToNumerical					
	jmp			endOfString

	
; if number is invalid, display invalid message and jump to have user input a new number
invalid:		
	mGetString		[ebp + 8], MAX_STRING_LENGTH, [ebp + 16]
	jmp			validateNum

endOfString:
	mov			[edi], eax			; save the numercial total (user's number) and put in current number array element position
	
	popad

	pop			ebp
	ret			16

readVal ENDP

;*******************************************************
;Procedure that converts a numeric value to a string of characters, and invokes the displayString macro to produce the output
;receives: array of 10 numbers passed by reference, array where digit characters can be stored passsed by reference
;returns: array of characters
;preconditions: n/a
;registers changed: eax, edi, ebx, al, ebx, edx, ebp
;*******************************************************
writeVal PROC
	
	push			ebp
	mov				ebp, esp

	pushad

	; with help from the demoString program from CS271 and stackOverflow
	mov				eax, [ebp + 12]				; move current number to eax
	mov				edi, [ebp + 8]				; set to position in array where string can be stored
	add				edi, MAX_STRING_LENGTH		; point to end of string
	dec				edi							; decrement by one to avoid the null byte
	std											; move through string from end to begining
	
	push			eax							
	mov				al, 0
	stosb										; store zero byte at the end of the string
	pop				eax
	
	mov				ebx, 10						; for division

convertString:									; convert number to ASCII char
	mov				edx, 0			
	div				ebx							; divide by 10
	add				edx, 48						; add 48 to convert it to ASCII char
	push			eax
	mov				eax, edx
	stosb										;store the ASCII character to the array where we are storing the string
	pop				eax
	cmp				eax, 0						
	jne				convertString				; if eax is is not zero, repeat conversion

	inc				edi
	mDisplayString	edi							; display the string to the console
	
	popad

	pop				ebp
	ret				8
writeVal ENDP

;*******************************************************
;Procedure to print integer
;receives: message, the array of 10 numbers, array to store string by reference
;returns: array of numbers printed to console
;preconditions: n/a
;registers changed: esi, edi, ecx, ebp
;*******************************************************
printInteger PROC
	push			ebp
	mov				ebp, esp
	
	pushad
	
	mov				ecx, 10					; size of array for looping
	mov				esi, [ebp + 16]			; put array address in esi
	mov				edi, [ebp + 12]			; put the array to store string in edi

	call			crlf
	mDisplayString	[ebp + 8]
	call			crlf

; with help from stack Overflow
printArray:
	push			[esi]					; push the actual element of the array we are on
	push			edi						; push the address of where we are storing the string
	call			writeVal				; writes the value to console
	cmp				ecx, 1					
	je				lastNumber				; don't add comma if we are at the last number
	mov				al, ','				
	call			WriteChar
	mov				al, ' '					
	call			WriteChar

lastNumber:
	add				esi, 4					; continue to next element in array
	loop			printArray				; loop 10 times as there are 10 integers
	call			crlf
	
	popad

	pop				ebp
	ret				12
printInteger ENDP

;*******************************************************
;Procedure to calculate the sum 
;receives:  sum passed by reference, array passed by reference
;returns: the sum in the sum parameter
;preconditions: none
;registers changed: ebp, ecx, eax, esi, edx
;*******************************************************
calculateSum PROC

	push			ebp
	mov				ebp, esp

	pushad

	mov				ecx, 10					; loop 10 times for 10 numbers
	mov				eax, 0					; start sum accumulation at zero
	
	mov				esi, [ebp + 12]			; move the address of the array of numberse to esi
	mov				edi, [ebp + 8]			; move the address of sum to edi
	
findSum:
	add				eax, [esi]				; add the number we are pointing to in the array to to sum total
	add				esi, 4					; increment to next position
	loop			findSum					; loop 10 times as there are 10 numberes in the array

	mov				[edi], eax				; save the sum
	popad
	pop				ebp
	ret				12
calculateSum ENDP

;*******************************************************
;Procedure to calculate the average
;receives:  sum passed by value, average passed by reference
;returns: the average in the average parameter
;preconditions: none
;registers changed: ebp, eax, edx, ebx
;*******************************************************
calculateAvg PROC
	push			ebp
	mov				ebp, esp

	pushad

	mov				eax, [ebp + 12]			; move sum to eax
	mov				edx, 0
	mov				ebx, 10
	div				ebx						; divide by 10 to get the average of the 10 integers

	mov				ebx, [ebp + 8]			; move address of average variable to ebx
	mov				[ebx], eax				; move the calculated average to the average parameter

	popad
	pop				ebp
	ret				8
calculateAvg ENDP

;*******************************************************
;Procedure to print the calculation of the sum and average
;receives:  a message string, a parameter passed by reference that holds the calculation, address for a place to store a string by reference
;returns: a string with a calcualted number
;preconditions: none
;registers changed: ebp, esi, edi
;*******************************************************
printCalc PROC

push				ebp
	mov				ebp, esp
	
	pushad

	call			crlf
	mDisplayString	[ebp + 16]
	call			crlf

	mov				esi, [ebp + 12]			; move address of the average variable to esi
	mov				edi, [ebp + 8]			; move address of the string stored in stringstore to edi

	push			[esi]
	push			edi
	call			writeVal				; call writeVal to convert the numbers to a string and print

	call			crlf

	popad
	pop				ebp
	ret				12

printCalc ENDP

;*******************************************************
;Procedure to say goodbye to the user
;receives: thankUMessage (passed by reference), goodByeMessage(passed by reference)
;returns: n/a
;preconditions: n/a 
;registers changed: ebp 
;*******************************************************
finishProgram PROC

	push			ebp
	mov				ebp, esp

	call			crlf
	call			crlf
	mDisplayString	[ebp+12]
	call			crlf
	mDisplayString	[ebp+8]

	pop				ebp
	ret				8
finishProgram ENDP

END main

	.title palette switch test
	.asect

	. = 100

	.word	int	; PC
	.word	200	; PSW

	. = 1000

palette	= 177662

start:
	mtps	#0	; enable interrupts
loop:
	wait
	mov	#palette, r0
	mov	#1000, sp
	mov	#7*400, r2
	mov	#10.*400, r1
	mov	#7*400, r2
	mov	#10.*400,r1
	mov 	#7*400, r2
	mov 	#443, delay+2
delay:
	dec	#443
	bne	delay

	.rept	256.

	mov	r1, (r0)
	mov	r2, (r0)
	mov	r2, (r0)
	mov	r2, (r0)
	mov	r2, (r0)
	mov	r1, (r0)
	mov	#10.*400, r1
	mov	#7*400, r2

	.endr

	jmp loop

int:
	rti

	.end start

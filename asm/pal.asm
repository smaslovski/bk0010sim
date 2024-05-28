	.title palette switch test
	.asect

	. = 100

	.word	int	; PC
	.word	200	; PSW

	. = 1000

palreg	= 177662

start:
	mtps	#0	; enable interrupts
loop:
	wait
	mov	#1000, sp
	mov	#palreg, r0
	mov	#7*400, r1
	mov	#10.*400, r2
	mov	#7*400, r3
	mov	#10.*400,r4
	mov 	#7*400, r5
	mov 	#443, delay+2
delay:
	dec	#443
	bne	delay

	.rept	256.

	mov	r1, (r0)
	mov	r2, (r0)
	mov	r3, (r0)
	mov	r4, (r0)
	mov	r5, (r0)
	mov	r1, (r0)
	mov	#7*400, r1
	mov	#10.*400, r2

	.endr

	jmp loop

int:
	rti

	.end start

<TITLE>Pintos Projects: Project 1--Threads</TITLE>

<META NAME="description" CONTENT="Pintos Projects: Project 1--Threads">
<META NAME="keywords" CONTENT="Pintos Projects: Project 1--Threads">
<META NAME="resource-type" CONTENT="document">
<META NAME="distribution" CONTENT="global">
<META NAME="Generator" CONTENT="texi2html 1.66">
<LINK REL="stylesheet" HREF="pintos.css">
</HEAD>

<BODY >

<HR SIZE=2>
<H1> 2. Project 1: Threads </H1>
<!--docid::SEC15::-->
<P>

In this assignment, we give you a minimally functional thread system.
Your job is to extend the functionality of this system to gain a
better understanding of synchronization problems.
</P>
<P>

You will be working primarily in the <Q><TT>threads</TT></Q> directory for
this assignment, with some work in the <Q><TT>devices</TT></Q> directory on the
side.  Compilation should be done in the <Q><TT>threads</TT></Q> directory.
</P>
<P>

Before you read the description of this project, you should read all of
the following sections: <A HREF="pintos_1.html#SEC1">1. Introduction</A>, <A HREF="pintos_8.html#SEC138">C. Coding Standards</A>,
<A HREF="pintos_10.html#SEC145">E. Debugging Tools</A>, and <A HREF="pintos_11.html#SEC158">F. Development Tools</A>.  You should at least
skim the material from <A HREF="pintos_6.html#SEC91">A.1 Loading</A> through <A HREF="pintos_6.html#SEC111">A.5 Memory Allocation</A>, especially <A HREF="pintos_6.html#SEC100">A.3 Synchronization</A>.  To complete this project
you will also need to read <A HREF="pintos_7.html#SEC131">B. 4.4<ACRONYM>BSD</ACRONYM> Scheduler</A>.
</P>
<P>

<A NAME="Project 1 Background"></A>
<HR SIZE="6">
<A NAME="SEC16"></A>
<H2> 2.1 Background </H2>
<!--docid::SEC16::-->
<P>

<A NAME="Understanding Threads"></A>
<HR SIZE="6">
<A NAME="SEC17"></A>
<H3> 2.1.1 Understanding Threads </H3>
<!--docid::SEC17::-->
<P>

The first step is to read and understand the code for the initial thread
system.
Pintos already implements thread creation and thread completion,
a simple scheduler to switch between threads, and synchronization
primitives (semaphores, locks, condition variables, and optimization
barriers).
</P>
<P>

Some of this code might seem slightly mysterious.  If
you haven't already compiled and run the base system, as described in
the introduction (see section <A HREF="pintos_1.html#SEC1">1. Introduction</A>), you should do so now.  You
can read through parts of the source code to see what's going
on.  If you like, you can add calls to <CODE>printf()</CODE> almost
anywhere, then recompile and run to see what happens and in what
order.  You can also run the kernel in a debugger and set breakpoints
at interesting spots, single-step through code and examine data, and
so on.
</P>
<P>

When a thread is created, you are creating a new context to be
scheduled.  You provide a function to be run in this context as an
argument to <CODE>thread_create()</CODE>.  The first time the thread is
scheduled and runs, it starts from the beginning of that function
and executes in that context.  When the function returns, the thread
terminates.  Each thread, therefore, acts like a mini-program running
inside Pintos, with the function passed to <CODE>thread_create()</CODE>
acting like <CODE>main()</CODE>.
</P>
<P>

At any given time, exactly one thread runs and the rest, if any,
become inactive.  The scheduler decides which thread to
run next.  (If no thread is ready to run
at any given time, then the special &quot;idle&quot; thread, implemented in
<CODE>idle()</CODE>, runs.)
Synchronization primitives can force context switches when one
thread needs to wait for another thread to do something.
</P>
<P>

The mechanics of a context switch are
in <Q><TT>threads/switch.S</TT></Q>, which is 80<VAR>x</VAR>86
assembly code.  (You don't have to understand it.)  It saves the
state of the currently running thread and restores the state of the
thread we're switching to.
</P>
<P>

Using the GDB debugger, slowly trace through a context
switch to see what happens (see section <A HREF="pintos_10.html#SEC151">E.5 GDB</A>).  You can set a
breakpoint on <CODE>schedule()</CODE> to start out, and then
single-step from there.<A NAME="DOCF2" HREF="pintos_fot.html#FOOT2">(2)</A>  Be sure
to keep track of each thread's address
and state, and what procedures are on the call stack for each thread.
You will notice that when one thread calls <CODE>switch_threads()</CODE>,
another thread starts running, and the first thing the new thread does
is to return from <CODE>switch_threads()</CODE>.  You will understand the thread
system once you understand why and how the <CODE>switch_threads()</CODE> that
gets called is different from the <CODE>switch_threads()</CODE> that returns.
See section <A HREF="pintos_6.html#SEC99">A.2.3 Thread Switching</A>, for more information.
</P>
<P>

<STRONG>Warning</STRONG>: In Pintos, each thread is assigned a small,
fixed-size execution stack just under 4 kB in size.  The kernel
tries to detect stack overflow, but it cannot do so perfectly.  You
may cause bizarre problems, such as mysterious kernel panics, if you
declare large data structures as non-static local variables,
e.g. <Q><SAMP>int buf[1000];</SAMP></Q>.  Alternatives to stack allocation include
the page allocator and the block allocator (see section <A HREF="pintos_6.html#SEC111">A.5 Memory Allocation</A>).
</P>
<P>

<A NAME="Project 1 Source Files"></A>
<HR SIZE="6">
<A NAME="SEC18"></A>
<H3> 2.1.2 Source Files </H3>
<!--docid::SEC18::-->
<P>

Here is a brief overview of the files in the <Q><TT>threads</TT></Q>
directory.  You will not need to modify most of this code, but the
hope is that presenting this overview will give you a start on what
code to look at.
</P>
<P>

</P>
<DL COMPACT>
<DT><Q><TT>loader.S</TT></Q>
<DD><DT><Q><TT>loader.h</TT></Q>
<DD>The kernel loader.  Assembles to 512 bytes of code and data that the
PC BIOS loads into memory and which in turn finds the kernel on disk,
loads it into memory, and jumps to <CODE>start()</CODE> in <Q><TT>start.S</TT></Q>.
See section <A HREF="pintos_6.html#SEC92">A.1.1 The Loader</A>, for details.  You should not need to look at
this code or modify it.
<P>

</P>
<DT><Q><TT>start.S</TT></Q>
<DD>Does basic setup needed for memory protection and 32-bit
operation on 80<VAR>x</VAR>86 CPUs.  Unlike the loader, this code is
actually part of the kernel.  See section <A HREF="pintos_6.html#SEC93">A.1.2 Low-Level Kernel Initialization</A>,
for details.
<P>

</P>
<DT><Q><TT>kernel.lds.S</TT></Q>
<DD>The linker script used to link the kernel.  Sets the load address of
the kernel and arranges for <Q><TT>start.S</TT></Q> to be near the beginning
of the kernel image.  See section <A HREF="pintos_6.html#SEC92">A.1.1 The Loader</A>, for details. Again, you
should not need to look at this code
or modify it, but it's here in case you're curious.
<P>

</P>
<DT><Q><TT>init.c</TT></Q>
<DD><DT><Q><TT>init.h</TT></Q>
<DD>Kernel initialization, including <CODE>main()</CODE>, the kernel's &quot;main
program.&quot;  You should look over <CODE>main()</CODE> at least to see what
gets initialized.  You might want to add your own initialization code
here.  See section <A HREF="pintos_6.html#SEC94">A.1.3 High-Level Kernel Initialization</A>, for details.
<P>

</P>
<DT><Q><TT>thread.c</TT></Q>
<DD><DT><Q><TT>thread.h</TT></Q>
<DD>Basic thread support.  Much of your work will take place in these files.
<Q><TT>thread.h</TT></Q> defines <CODE>struct thread</CODE>, which you are likely to modify
in all four projects.  See <A HREF="pintos_6.html#SEC97">A.2.1 <CODE>struct thread</CODE></A> and <A HREF="pintos_6.html#SEC96">A.2 Threads</A> for
more information.
<P>

</P>
<DT><Q><TT>switch.S</TT></Q>
<DD><DT><Q><TT>switch.h</TT></Q>
<DD>Assembly language routine for switching threads.  Already discussed
above.  See section <A HREF="pintos_6.html#SEC98">A.2.2 Thread Functions</A>, for more information.
<P>

</P>
<DT><Q><TT>palloc.c</TT></Q>
<DD><DT><Q><TT>palloc.h</TT></Q>
<DD>Page allocator, which hands out system memory in multiples of 4 kB
pages.  See section <A HREF="pintos_6.html#SEC112">A.5.1 Page Allocator</A>, for more information.
<P>

</P>
<DT><Q><TT>malloc.c</TT></Q>
<DD><DT><Q><TT>malloc.h</TT></Q>
<DD>A simple implementation of <CODE>malloc()</CODE> and <CODE>free()</CODE> for
the kernel.  See section <A HREF="pintos_6.html#SEC113">A.5.2 Block Allocator</A>, for more information.
<P>

</P>
<DT><Q><TT>interrupt.c</TT></Q>
<DD><DT><Q><TT>interrupt.h</TT></Q>
<DD>Basic interrupt handling and functions for turning interrupts on and
off.  See section <A HREF="pintos_6.html#SEC107">A.4 Interrupt Handling</A>, for more information.
<P>

</P>
<DT><Q><TT>intr-stubs.S</TT></Q>
<DD><DT><Q><TT>intr-stubs.h</TT></Q>
<DD>Assembly code for low-level interrupt handling.  See section <A HREF="pintos_6.html#SEC108">A.4.1 Interrupt Infrastructure</A>, for more information.
<P>

</P>
<DT><Q><TT>synch.c</TT></Q>
<DD><DT><Q><TT>synch.h</TT></Q>
<DD>Basic synchronization primitives: semaphores, locks, condition
variables, and optimization barriers.  You will need to use these for
synchronization in all
four projects.  See section <A HREF="pintos_6.html#SEC100">A.3 Synchronization</A>, for more information.
<P>

</P>
<DT><Q><TT>io.h</TT></Q>
<DD>Functions for I/O port access.  This is mostly used by source code in
the <Q><TT>devices</TT></Q> directory that you won't have to touch.
<P>

</P>
<DT><Q><TT>vaddr.h</TT></Q>
<DD><DT><Q><TT>pte.h</TT></Q>
<DD>Functions and macros for working with virtual addresses and page table
entries.  These will be more important to you in project 3.  For now,
you can ignore them.
<P>

</P>
<DT><Q><TT>flags.h</TT></Q>
<DD>Macros that define a few bits in the 80<VAR>x</VAR>86 &quot;flags&quot; register.
Probably of no interest.  See [ <A HREF="pintos_13.html#IA32-v1">IA32-v1</A>], section 3.4.3, &quot;EFLAGS
Register,&quot; for more information.
</DL>
<P>

<A NAME="devices code"></A>
<HR SIZE="6">
<A NAME="SEC19"></A>
<H4> 2.1.2.1 <Q><TT>devices</TT></Q> code </H4>
<!--docid::SEC19::-->
<P>

The basic threaded kernel also includes these files in the
<Q><TT>devices</TT></Q> directory:
</P>
<P>

</P>
<DL COMPACT>
<DT><Q><TT>timer.c</TT></Q>
<DD><DT><Q><TT>timer.h</TT></Q>
<DD>System timer that ticks, by default, 100 times per second.  You will
modify this code in this project.
<P>

</P>
<DT><Q><TT>vga.c</TT></Q>
<DD><DT><Q><TT>vga.h</TT></Q>
<DD>VGA display driver.  Responsible for writing text to the screen.
You should have no need to look at this code.  <CODE>printf()</CODE>
calls into the VGA display driver for you, so there's little reason to
call this code yourself.
<P>

</P>
<DT><Q><TT>serial.c</TT></Q>
<DD><DT><Q><TT>serial.h</TT></Q>
<DD>Serial port driver.  Again, <CODE>printf()</CODE> calls this code for you,
so you don't need to do so yourself.
It handles serial input by passing it to the input layer (see below).
<P>

</P>
<DT><Q><TT>block.c</TT></Q>
<DD><DT><Q><TT>block.h</TT></Q>
<DD>An abstraction layer for <EM>block devices</EM>, that is, random-access,
disk-like devices that are organized as arrays of fixed-size blocks.
Out of the box, Pintos supports two types of block devices: IDE disks
and partitions.  Block devices, regardless of type, won't actually be
used until project 2.
<P>

</P>
<DT><Q><TT>ide.c</TT></Q>
<DD><DT><Q><TT>ide.h</TT></Q>
<DD>Supports reading and writing sectors on up to 4 IDE disks.
<P>

</P>
<DT><Q><TT>partition.c</TT></Q>
<DD><DT><Q><TT>partition.h</TT></Q>
<DD>Understands the structure of partitions on disks, allowing a single
disk to be carved up into multiple regions (partitions) for
independent use.
<P>

</P>
<DT><Q><TT>kbd.c</TT></Q>
<DD><DT><Q><TT>kbd.h</TT></Q>
<DD>Keyboard driver.  Handles keystrokes passing them to the input layer
(see below).
<P>

</P>
<DT><Q><TT>input.c</TT></Q>
<DD><DT><Q><TT>input.h</TT></Q>
<DD>Input layer.  Queues input characters passed along by the keyboard or
serial drivers.
<P>

</P>
<DT><Q><TT>intq.c</TT></Q>
<DD><DT><Q><TT>intq.h</TT></Q>
<DD>Interrupt queue, for managing a circular queue that both kernel
threads and interrupt handlers want to access.  Used by the keyboard
and serial drivers.
<P>

</P>
<DT><Q><TT>rtc.c</TT></Q>
<DD><DT><Q><TT>rtc.h</TT></Q>
<DD>Real-time clock driver, to enable the kernel to determine the current
date and time.  By default, this is only used by <Q><TT>thread/init.c</TT></Q>
to choose an initial seed for the random number generator.
<P>

</P>
<DT><Q><TT>speaker.c</TT></Q>
<DD><DT><Q><TT>speaker.h</TT></Q>
<DD>Driver that can produce tones on the PC speaker.
<P>

</P>
<DT><Q><TT>pit.c</TT></Q>
<DD><DT><Q><TT>pit.h</TT></Q>
<DD>Code to configure the 8254 Programmable Interrupt Timer.  This code is
used by both <Q><TT>devices/timer.c</TT></Q> and <Q><TT>devices/speaker.c</TT></Q>
because each device uses one of the PIT's output channel.
</DL>
<P>

<A NAME="lib files"></A>
<HR SIZE="6">
<A NAME="SEC20"></A>
<H4> 2.1.2.2 <Q><TT>lib</TT></Q> files </H4>
<!--docid::SEC20::-->
<P>

Finally, <Q><TT>lib</TT></Q> and <Q><TT>lib/kernel</TT></Q> contain useful library
routines.  (<Q><TT>lib/user</TT></Q> will be used by user programs, starting in
project 2, but it is not part of the kernel.)  Here's a few more
details:
</P>
<P>

</P>
<DL COMPACT>
<DT><Q><TT>ctype.h</TT></Q>
<DD><DT><Q><TT>inttypes.h</TT></Q>
<DD><DT><Q><TT>limits.h</TT></Q>
<DD><DT><Q><TT>stdarg.h</TT></Q>
<DD><DT><Q><TT>stdbool.h</TT></Q>
<DD><DT><Q><TT>stddef.h</TT></Q>
<DD><DT><Q><TT>stdint.h</TT></Q>
<DD><DT><Q><TT>stdio.c</TT></Q>
<DD><DT><Q><TT>stdio.h</TT></Q>
<DD><DT><Q><TT>stdlib.c</TT></Q>
<DD><DT><Q><TT>stdlib.h</TT></Q>
<DD><DT><Q><TT>string.c</TT></Q>
<DD><DT><Q><TT>string.h</TT></Q>
<DD>A subset of the standard C library.  See section <A HREF="pintos_8.html#SEC140">C.2 C99</A>, for
information
on a few recently introduced pieces of the C library that you might
not have encountered before.  See section <A HREF="pintos_8.html#SEC141">C.3 Unsafe String Functions</A>, for
information on what's been intentionally left out for safety.
<P>

</P>
<DT><Q><TT>debug.c</TT></Q>
<DD><DT><Q><TT>debug.h</TT></Q>
<DD>Functions and macros to aid debugging.  See section <A HREF="pintos_10.html#SEC145">E. Debugging Tools</A>, for
more information.
<P>

</P>
<DT><Q><TT>random.c</TT></Q>
<DD><DT><Q><TT>random.h</TT></Q>
<DD>Pseudo-random number generator.  The actual sequence of random values
will not vary from one Pintos run to another, unless you do one of
three things: specify a new random seed value on the <Q><SAMP>-rs</SAMP></Q>
kernel command-line option on each run, or use a simulator other than
Bochs, or specify the <Q><SAMP>-r</SAMP></Q> option to <CODE>pintos</CODE>.
<P>

</P>
<DT><Q><TT>round.h</TT></Q>
<DD>Macros for rounding.
<P>

</P>
<DT><Q><TT>syscall-nr.h</TT></Q>
<DD>System call numbers.  Not used until project 2.
<P>

</P>
<DT><Q><TT>kernel/list.c</TT></Q>
<DD><DT><Q><TT>kernel/list.h</TT></Q>
<DD>Doubly linked list implementation.  Used all over the Pintos code, and
you'll probably want to use it a few places yourself in project 1.
<P>

</P>
<DT><Q><TT>kernel/bitmap.c</TT></Q>
<DD><DT><Q><TT>kernel/bitmap.h</TT></Q>
<DD>Bitmap implementation.  You can use this in your code if you like, but
you probably won't have any need for it in project 1.
<P>

</P>
<DT><Q><TT>kernel/hash.c</TT></Q>
<DD><DT><Q><TT>kernel/hash.h</TT></Q>
<DD>Hash table implementation.  Likely to come in handy for project 3.
<P>

</P>
<DT><Q><TT>kernel/console.c</TT></Q>
<DD><DT><Q><TT>kernel/console.h</TT></Q>
<DD><DT><Q><TT>kernel/stdio.h</TT></Q>
<DD>Implements <CODE>printf()</CODE> and a few other functions.
</DL>
<P>

<A NAME="Project 1 Synchronization"></A>
<HR SIZE="6">
<A NAME="SEC21"></A>
<H3> 2.1.3 Synchronization </H3>
<!--docid::SEC21::-->
<P>

Proper synchronization is an important part of the solutions to these
problems.  Any synchronization problem can be easily solved by turning
interrupts off: while interrupts are off, there is no concurrency, so
there's no possibility for race conditions.  Therefore, it's tempting to
solve all synchronization problems this way, but <STRONG>don't</STRONG>.
Instead, use semaphores, locks, and condition variables to solve the
bulk of your synchronization problems.  Read the tour section on
synchronization (see section <A HREF="pintos_6.html#SEC100">A.3 Synchronization</A>) or the comments in
<Q><TT>threads/synch.c</TT></Q> if you're unsure what synchronization primitives
may be used in what situations.
</P>
<P>

In the Pintos projects, the only class of problem best solved by
disabling interrupts is coordinating data shared between a kernel thread
and an interrupt handler.  Because interrupt handlers can't sleep, they
can't acquire locks.  This means that data shared between kernel threads
and an interrupt handler must be protected within a kernel thread by
turning off interrupts.
</P>
<P>

This project only requires accessing a little bit of thread state from
interrupt handlers.  For the alarm clock, the timer interrupt needs to
wake up sleeping threads.  In the advanced scheduler, the timer
interrupt needs to access a few global and per-thread variables.  When
you access these variables from kernel threads, you will need to disable
interrupts to prevent the timer interrupt from interfering.
</P>
<P>

When you do turn off interrupts, take care to do so for the least amount
of code possible, or you can end up losing important things such as
timer ticks or input events.  Turning off interrupts also increases the
interrupt handling latency, which can make a machine feel sluggish if
taken too far.
</P>
<P>

The synchronization primitives themselves in <Q><TT>synch.c</TT></Q> are
implemented by disabling interrupts.  You may need to increase the
amount of code that runs with interrupts disabled here, but you should
still try to keep it to a minimum.
</P>
<P>

Disabling interrupts can be useful for debugging, if you want to make
sure that a section of code is not interrupted.  You should remove
debugging code before turning in your project.  (Don't just comment it
out, because that can make the code difficult to read.)
</P>
<P>

There should be no busy waiting in your submission.  A tight loop that
calls <CODE>thread_yield()</CODE> is one form of busy waiting.
</P>
<P>

<A NAME="Development Suggestions"></A>
<HR SIZE="6">
<A NAME="SEC22"></A>
<H3> 2.1.4 Development Suggestions </H3>
<!--docid::SEC22::-->
<P>

In the past, many groups divided the assignment into pieces, then each
group member worked on his or her piece until just before the
deadline, at which time the group reconvened to combine their code and
submit.  <STRONG>This is a bad idea.  We do not recommend this
approach.</STRONG>  Groups that do this often find that two changes conflict
with each other, requiring lots of last-minute debugging.  Some groups
who have done this have turned in code that did not even compile or
boot, much less pass any tests.
</P>
<P>

Instead, we recommend integrating your team's changes early and often,
using a source code control system such as CVS (see section <A HREF="pintos_11.html#SEC161">F.3 CVS</A>).
This is less likely to produce surprises, because everyone can see
everyone else's code as it is written, instead of just when it is
finished.  These systems also make it possible to review changes and,
when a change introduces a bug, drop back to working versions of code.
</P>
<P>

You should expect to run into bugs that you simply don't understand
while working on this and subsequent projects.  When you do,
reread the appendix on debugging tools, which is filled with
useful debugging tips that should help you to get back up to speed
(see section <A HREF="pintos_10.html#SEC145">E. Debugging Tools</A>).  Be sure to read the section on backtraces
(see section <A HREF="pintos_10.html#SEC149">E.4 Backtraces</A>), which will help you to get the most out of every
kernel panic or assertion failure.
</P>
<P>

<A NAME="Project 1 Requirements"></A>
<HR SIZE="6">
<A NAME="SEC23"></A>
<H2> 2.2 Requirements </H2>
<!--docid::SEC23::-->
<P>

<A NAME="Project 1 Design Document"></A>
<HR SIZE="6">
<A NAME="SEC24"></A>
<H3> 2.2.1 Design Document </H3>
<!--docid::SEC24::-->
<P>

Before you turn in your project, you must copy <A HREF="threads.tmpl">the
project 1 design document template</A> into your source tree under the name
<Q><TT>pintos/src/threads/DESIGNDOC</TT></Q> and fill it in.  We recommend that
you read the design document template before you start working on the
project.  See section <A HREF="pintos_9.html#SEC142">D. Project Documentation</A>, for a sample design document
that goes along with a fictitious project.
</P>
<P>

<A NAME="Alarm Clock"></A>
<HR SIZE="6">
<A NAME="SEC25"></A>
<H3> 2.2.2 Alarm Clock </H3>
<!--docid::SEC25::-->
<P>

Reimplement <CODE>timer_sleep()</CODE>, defined in <Q><TT>devices/timer.c</TT></Q>.
Although a working implementation is provided, it &quot;busy waits,&quot; that
is, it spins in a loop checking the current time and calling
<CODE>thread_yield()</CODE> until enough time has gone by.  Reimplement it to
avoid busy waiting.
</P>
<P>

<A NAME="IDX1"></A>
</P>
<DL>
<DT><U>Function:</U> void <B>timer_sleep</B> (int64_t <VAR>ticks</VAR>)
<DD>Suspends execution of the calling thread until time has advanced by at
least <VAR>x</VAR> timer ticks.  Unless the system is otherwise idle, the
thread need not wake up after exactly <VAR>x</VAR> ticks.  Just put it on
the ready queue after they have waited for the right amount of time.
<P>

<CODE>timer_sleep()</CODE> is useful for threads that operate in real-time,
e.g. for blinking the cursor once per second.
</P>
<P>

The argument to <CODE>timer_sleep()</CODE> is expressed in timer ticks, not in
milliseconds or any another unit.  There are <CODE>TIMER_FREQ</CODE> timer
ticks per second, where <CODE>TIMER_FREQ</CODE> is a macro defined in
<CODE>devices/timer.h</CODE>.  The default value is 100.  We don't recommend
changing this value, because any change is likely to cause many of
the tests to fail.
</P>
</DL>
<P>

Separate functions <CODE>timer_msleep()</CODE>, <CODE>timer_usleep()</CODE>, and
<CODE>timer_nsleep()</CODE> do exist for sleeping a specific number of
milliseconds, microseconds, or nanoseconds, respectively, but these will
call <CODE>timer_sleep()</CODE> automatically when necessary.  You do not need
to modify them.
</P>
<P>

If your delays seem too short or too long, reread the explanation of the
<Q><SAMP>-r</SAMP></Q> option to <CODE>pintos</CODE> (see section <A HREF="pintos_1.html#SEC6">1.1.4 Debugging versus Testing</A>).
</P>
<P>

The alarm clock implementation is not needed for later projects,
although it could be useful for project 4.
</P>
<P>

<A NAME="Priority Scheduling"></A>
<HR SIZE="6">
<A NAME="SEC26"></A>
<H3> 2.2.3 Priority Scheduling </H3>
<!--docid::SEC26::-->
<P>

Implement priority scheduling in Pintos.
When a thread is added to the ready list that has a higher priority
than the currently running thread, the current thread should
immediately yield the processor to the new thread.  Similarly, when
threads are waiting for a lock, semaphore, or condition variable, the
highest priority waiting thread should be awakened first.  A thread
may raise or lower its own priority at any time, but lowering its
priority such that it no longer has the highest priority must cause it
to immediately yield the CPU.
</P>
<P>

Thread priorities range from <CODE>PRI_MIN</CODE> (0) to <CODE>PRI_MAX</CODE> (63).
Lower numbers correspond to lower priorities, so that priority 0
is the lowest priority and priority 63 is the highest.
The initial thread priority is passed as an argument to
<CODE>thread_create()</CODE>.  If there's no reason to choose another
priority, use <CODE>PRI_DEFAULT</CODE> (31).  The <CODE>PRI_</CODE> macros are
defined in <Q><TT>threads/thread.h</TT></Q>, and you should not change their
values.
</P>
<P>

One issue with priority scheduling is &quot;priority inversion&quot;.  Consider
high, medium, and low priority threads <VAR>H</VAR>, <VAR>M</VAR>, and <VAR>L</VAR>,
respectively.  If <VAR>H</VAR> needs to wait for <VAR>L</VAR> (for instance, for a
lock held by <VAR>L</VAR>), and <VAR>M</VAR> is on the ready list, then <VAR>H</VAR>
will never get the CPU because the low priority thread will not get any
CPU time.  A partial fix for this problem is for <VAR>H</VAR> to &quot;donate&quot;
its priority to <VAR>L</VAR> while <VAR>L</VAR> is holding the lock, then recall
the donation once <VAR>L</VAR> releases (and thus <VAR>H</VAR> acquires) the lock.
</P>
<P>

Implement priority donation.  You will need to account for all different
situations in which priority donation is required.  Be sure to handle
multiple donations, in which multiple priorities are donated to a single
thread.  You must also handle nested donation: if <VAR>H</VAR> is waiting on
a lock that <VAR>M</VAR> holds and <VAR>M</VAR> is waiting on a lock that <VAR>L</VAR>
holds, then both <VAR>M</VAR> and <VAR>L</VAR> should be boosted to <VAR>H</VAR>'s
priority.  If necessary, you may impose a reasonable limit on depth of
nested priority donation, such as 8 levels.
</P>
<P>

You must implement priority donation for locks.  You need not
implement priority donation for the other Pintos synchronization
constructs.  You do need to implement priority scheduling in all
cases.
</P>
<P>

Finally, implement the following functions that allow a thread to
examine and modify its own priority.  Skeletons for these functions are
provided in <Q><TT>threads/thread.c</TT></Q>.
</P>
<P>

<A NAME="IDX2"></A>
</P>
<DL>
<DT><U>Function:</U> void <B>thread_set_priority</B> (int <VAR>new_priority</VAR>)
<DD>Sets the current thread's priority to <VAR>new_priority</VAR>.  If the
current thread no longer has the highest priority, yields.
</DL>
<P>

<A NAME="IDX3"></A>
</P>
<DL>
<DT><U>Function:</U> int <B>thread_get_priority</B> (void)
<DD>Returns the current thread's priority.  In the presence of priority
donation, returns the higher (donated) priority.
</DL>
<P>

You need not provide any interface to allow a thread to directly modify
other threads' priorities.
</P>
<P>

The priority scheduler is not used in any later project.
</P>
<P>

<A NAME="Advanced Scheduler"></A>
<HR SIZE="6">
<A NAME="SEC27"></A>
<H3> 2.2.4 Advanced Scheduler </H3>
<!--docid::SEC27::-->
<P>
No Longer Required for Project 1<br>
<s>Implement a multilevel feedback queue scheduler similar to the
4.4<ACRONYM>BSD</ACRONYM> scheduler to
reduce the average response time for running jobs on your system.
See section <A HREF="pintos_7.html#SEC131">B. 4.4<ACRONYM>BSD</ACRONYM> Scheduler</A>, for detailed requirements.
</P>
<P>

Like the priority scheduler, the advanced scheduler chooses the thread
to run based on priorities.  However, the advanced scheduler does not do
priority donation.  Thus, we recommend that you have the priority
scheduler working, except possibly for priority donation, before you
start work on the advanced scheduler.
</P>
<P>

You must write your code to allow us to choose a scheduling algorithm
policy at Pintos startup time.  By default, the priority scheduler
must be active, but we must be able to choose the 4.4<ACRONYM>BSD</ACRONYM>
scheduler
with the <Q><SAMP>-mlfqs</SAMP></Q> kernel option.  Passing this
option sets <CODE>thread_mlfqs</CODE>, declared in <Q><TT>threads/thread.h</TT></Q>, to
true when the options are parsed by <CODE>parse_options()</CODE>, which happens
early in <CODE>main()</CODE>.
</P>
<P>

When the 4.4<ACRONYM>BSD</ACRONYM> scheduler is enabled, threads no longer
directly control their own priorities.  The <VAR>priority</VAR> argument to
<CODE>thread_create()</CODE> should be ignored, as well as any calls to
<CODE>thread_set_priority()</CODE>, and <CODE>thread_get_priority()</CODE> should return
the thread's current priority as set by the scheduler.
</P>
<P>

The advanced scheduler is not used in any later project.
</P></s>
<P>

<A NAME="Project 1 FAQ"></A>
<HR SIZE="6">
<A NAME="SEC28"></A>
<H2> 2.3 FAQ </H2>
<!--docid::SEC28::-->
<P>

</P>
<DL COMPACT>
<DT><B>How much code will I need to write?</B>
<DD><P>

Here's a summary of our reference solution, produced by the
<CODE>diffstat</CODE> program.  The final row gives total lines inserted
and deleted; a changed line counts as both an insertion and a deletion.
</P>
<P>

The reference solution represents just one possible solution.  Many
other solutions are also possible and many of those differ greatly from
the reference solution.  Some excellent solutions may not modify all the
files modified by the reference solution, and some may modify files not
modified by the reference solution.
</P>
<P>

<TABLE><tr><td>&nbsp;</td><td class=example><pre> devices/timer.c       |   42 +++++-
 threads/fixed-point.h |  120 ++++++++++++++++++
 threads/synch.c       |   88 ++++++++++++-
 threads/thread.c      |  196 ++++++++++++++++++++++++++----
 threads/thread.h      |   23 +++
 5 files changed, 440 insertions(+), 29 deletions(-)
</pre></td></tr></table><P>

<Q><TT>fixed-point.h</TT></Q> is a new file added by the reference solution.
</P>
<P>

</P>
<DT><B>How do I update the <Q><TT>Makefile</TT></Q>s when I add a new source file?</B>
<DD><P>

<A NAME="Adding Source Files"></A>
To add a <Q><TT>.c</TT></Q> file, edit the top-level <Q><TT>Makefile.build</TT></Q>.
Add the new file to variable <Q><SAMP><VAR>dir</VAR>_SRC</SAMP></Q>, where
<VAR>dir</VAR> is the directory where you added the file.  For this
project, that means you should add it to <CODE>threads_SRC</CODE> or
<CODE>devices_SRC</CODE>.  Then run <CODE>make</CODE>.  If your new file
doesn't get
compiled, run <CODE>make clean</CODE> and then try again.
</P>
<P>

When you modify the top-level <Q><TT>Makefile.build</TT></Q> and re-run
<CODE>make</CODE>, the modified
version should be automatically copied to
<Q><TT>threads/build/Makefile</TT></Q>.  The converse is
not true, so any changes will be lost the next time you run <CODE>make
clean</CODE> from the <Q><TT>threads</TT></Q> directory.  Unless your changes are
truly temporary, you should prefer to edit <Q><TT>Makefile.build</TT></Q>.
</P>
<P>

A new <Q><TT>.h</TT></Q> file does not require editing the <Q><TT>Makefile</TT></Q>s.
</P>
<P>

</P>
<DT><B>What does <CODE>warning: no previous prototype for `<VAR>func</VAR>'</CODE> mean?</B>
<DD><P>

It means that you defined a non-<CODE>static</CODE> function without
preceding it by a prototype.  Because non-<CODE>static</CODE> functions are
intended for use by other <Q><TT>.c</TT></Q> files, for safety they should be
prototyped in a header file included before their definition.  To fix
the problem, add a prototype in a header file that you include, or, if
the function isn't actually used by other <Q><TT>.c</TT></Q> files, make it
<CODE>static</CODE>.
</P>
<P>

</P>
<DT><B>What is the interval between timer interrupts?</B>
<DD><P>

Timer interrupts occur <CODE>TIMER_FREQ</CODE> times per second.  You can
adjust this value by editing <Q><TT>devices/timer.h</TT></Q>.  The default is
100 Hz.
</P>
<P>

We don't recommend changing this value, because any changes are likely
to cause many of the tests to fail.
</P>
<P>

</P>
<DT><B>How long is a time slice?</B>
<DD><P>

There are <CODE>TIME_SLICE</CODE> ticks per time slice.  This macro is
declared in <Q><TT>threads/thread.c</TT></Q>.  The default is 4 ticks.
</P>
<P>

We don't recommend changing this value, because any changes are likely
to cause many of the tests to fail.
</P>
<P>

</P>
<DT><B>How do I run the tests?</B>
<DD><P>

See section <A HREF="pintos_1.html#SEC8">1.2.1 Testing</A>.
</P>
<P>

</P>
<DT><B>Why do I get a test failure in <CODE>pass()</CODE>?</B>
<DD><P>

<A NAME="The pass function fails"></A>
You are probably looking at a backtrace that looks something like this:
</P>
<P>

<TABLE><tr><td>&nbsp;</td><td class=example><pre>0xc0108810: debug_panic (lib/kernel/debug.c:32)
0xc010a99f: pass (tests/threads/tests.c:93)
0xc010bdd3: test_mlfqs_load_1 (...threads/mlfqs-load-1.c:33)
0xc010a8cf: run_test (tests/threads/tests.c:51)
0xc0100452: run_task (threads/init.c:283)
0xc0100536: run_actions (threads/init.c:333)
0xc01000bb: main (threads/init.c:137)
</pre></td></tr></table><P>

This is just confusing output from the <CODE>backtrace</CODE> program.  It
does not actually mean that <CODE>pass()</CODE> called <CODE>debug_panic()</CODE>.  In
fact, <CODE>fail()</CODE> called <CODE>debug_panic()</CODE> (via the <CODE>PANIC()</CODE>
macro).  GCC knows that <CODE>debug_panic()</CODE> does not return, because it
is declared <CODE>NO_RETURN</CODE> (see section <A HREF="pintos_10.html#SEC148">E.3 Function and Parameter Attributes</A>), so it doesn't include any code in <CODE>fail()</CODE> to take
control when <CODE>debug_panic()</CODE> returns.  This means that the return
address on the stack looks like it is at the beginning of the function
that happens to follow <CODE>fail()</CODE> in memory, which in this case happens
to be <CODE>pass()</CODE>.
</P>
<P>

See section <A HREF="pintos_10.html#SEC149">E.4 Backtraces</A>, for more information.
</P>
<P>

</P>
<DT><B>How do interrupts get re-enabled in the new thread following <CODE>schedule()</CODE>?</B>
<DD><P>

Every path into <CODE>schedule()</CODE> disables interrupts.  They eventually
get re-enabled by the next thread to be scheduled.  Consider the
possibilities: the new thread is running in <CODE>switch_thread()</CODE> (but
see below), which is called by <CODE>schedule()</CODE>, which is called by one
of a few possible functions:
</P>
<P>

<UL>
<LI>
<CODE>thread_exit()</CODE>, but we'll never switch back into such a thread, so
it's uninteresting.
<P>

</P>
<LI>
<CODE>thread_yield()</CODE>, which immediately restores the interrupt level upon
return from <CODE>schedule()</CODE>.
<P>

</P>
<LI>
<CODE>thread_block()</CODE>, which is called from multiple places:
<P>

<UL>
<LI>
<CODE>sema_down()</CODE>, which restores the interrupt level before returning.
<P>

</P>
<LI>
<CODE>idle()</CODE>, which enables interrupts with an explicit assembly STI
instruction.
<P>

</P>
<LI>
<CODE>wait()</CODE> in <Q><TT>devices/intq.c</TT></Q>, whose callers are responsible for
re-enabling interrupts.
</UL>
</UL>
<P>

There is a special case when a newly created thread runs for the first
time.  Such a thread calls <CODE>intr_enable()</CODE> as the first action in
<CODE>kernel_thread()</CODE>, which is at the bottom of the call stack for every
kernel thread but the first.
</DL>
<P>

<A NAME="Alarm Clock FAQ"></A>
<HR SIZE="6">
<A NAME="SEC29"></A>
<H3> 2.3.1 Alarm Clock FAQ </H3>
<!--docid::SEC29::-->
<P>

</P>
<DL COMPACT>
<DT><B>Do I need to account for timer values overflowing?</B>
<DD><P>

Don't worry about the possibility of timer values overflowing.  Timer
values are expressed as signed 64-bit numbers, which at 100 ticks per
second should be good for almost 2,924,712,087 years.  By then, we
expect Pintos to have been phased out of the CS 140 curriculum.
</DL>
<P>

<A NAME="Priority Scheduling FAQ"></A>
<HR SIZE="6">
<A NAME="SEC30"></A>
<H3> 2.3.2 Priority Scheduling FAQ </H3>
<!--docid::SEC30::-->
<P>

</P>
<DL COMPACT>
<DT><B>Doesn't priority scheduling lead to starvation?</B>
<DD><P>

Yes, strict priority scheduling can lead to starvation
because a thread will not run if any higher-priority thread is runnable.
The advanced scheduler introduces a mechanism for dynamically
changing thread priorities.
</P>
<P>

Strict priority scheduling is valuable in real-time systems because it
offers the programmer more control over which jobs get processing
time.  High priorities are generally reserved for time-critical
tasks. It's not &quot;fair,&quot; but it addresses other concerns not
applicable to a general-purpose operating system.
</P>
<P>

</P>
<DT><B>What thread should run after a lock has been released?</B>
<DD><P>

When a lock is released, the highest priority thread waiting for that
lock should be unblocked and put on the list of ready threads.  The
scheduler should then run the highest priority thread on the ready
list.
</P>
<P>

</P>
<DT><B>If the highest-priority thread yields, does it continue running?</B>
<DD><P>

Yes.  If there is a single highest-priority thread, it continues
running until it blocks or finishes, even if it calls
<CODE>thread_yield()</CODE>.
If multiple threads have the same highest priority,
<CODE>thread_yield()</CODE> should switch among them in &quot;round robin&quot; order.
</P>
<P>

</P>
<DT><B>What happens to the priority of a donating thread?</B>
<DD><P>

Priority donation only changes the priority of the donee
thread.  The donor thread's priority is unchanged.  
Priority donation is not additive: if thread <VAR>A</VAR> (with priority 5) donates
to thread <VAR>B</VAR> (with priority 3), then <VAR>B</VAR>'s new priority is 5, not 8.
</P>
<P>

</P>
<DT><B>Can a thread's priority change while it is on the ready queue?</B>
<DD><P>

Yes.  Consider a ready, low-priority thread <VAR>L</VAR> that holds a lock.
High-priority thread <VAR>H</VAR> attempts to acquire the lock and blocks,
thereby donating its priority to ready thread <VAR>L</VAR>.
</P>
<P>

</P>
<DT><B>Can a thread's priority change while it is blocked?</B>
<DD><P>

Yes.  While a thread that has acquired lock <VAR>L</VAR> is blocked for any
reason, its priority can increase by priority donation if a
higher-priority thread attempts to acquire <VAR>L</VAR>.  This case is
checked by the <CODE>priority-donate-sema</CODE> test.
</P>
<P>

</P>
<DT><B>Can a thread added to the ready list preempt the processor?</B>
<DD><P>

Yes.  If a thread added to the ready list has higher priority than the
running thread, the correct behavior is to immediately yield the
processor.  It is not acceptable to wait for the next timer interrupt.
The highest priority thread should run as soon as it is runnable,
preempting whatever thread is currently running.
</P>
<P>

</P>
<DT><B>How does <CODE>thread_set_priority()</CODE> affect a thread receiving donations?</B>
<DD><P>

It sets the thread's base priority.  The thread's effective priority
becomes the higher of the newly set priority or the highest donated
priority.  When the donations are released, the thread's priority
becomes the one set through the function call.  This behavior is checked
by the <CODE>priority-donate-lower</CODE> test.
</P>
<P>

</P>
<DT><B>Doubled test names in output make them fail.</B>
<DD><P>

Suppose you are seeing output in which some test names are doubled,
like this:
</P>
<P>

<TABLE><tr><td>&nbsp;</td><td class=example><pre>(alarm-priority) begin
(alarm-priority) (alarm-priority) Thread priority 30 woke up.
Thread priority 29 woke up.
(alarm-priority) Thread priority 28 woke up.
</pre></td></tr></table><P>

What is happening is that output from two threads is being
interleaved.  That is, one thread is printing <CODE>&quot;(alarm-priority)
Thread priority 29 woke up.\n&quot;</CODE> and another thread is printing
<CODE>&quot;(alarm-priority) Thread priority 30 woke up.\n&quot;</CODE>, but the first
thread is being preempted by the second in the middle of its output.
</P>
<P>

This problem indicates a bug in your priority scheduler.  After all, a
thread with priority 29 should not be able to run while a thread with
priority 30 has work to do.
</P>
<P>

Normally, the implementation of the <CODE>printf()</CODE> function in the
Pintos kernel attempts to prevent such interleaved output by acquiring
a console lock during the duration of the <CODE>printf</CODE> call and
releasing it afterwards.  However, the output of the test name,
e.g., <CODE>(alarm-priority)</CODE>, and the message following it is output
using two calls to <CODE>printf</CODE>, resulting in the console lock being
acquired and released twice.
</DL>
<P>

<A NAME="Advanced Scheduler FAQ"></A>
<HR SIZE="6">
<A NAME="SEC31"></A>
<H3> 2.3.3 Advanced Scheduler FAQ </H3>
<!--docid::SEC31::-->
<P>

</P>
<DL COMPACT>
<DT><B>How does priority donation interact with the advanced scheduler?</B>
<DD><P>

It doesn't have to.  We won't test priority donation and the advanced
scheduler at the same time.
</P>
<P>

</P>
<DT><B>Can I use one queue instead of 64 queues?</B>
<DD><P>

Yes.  In general, your implementation may differ from the description,
as long as its behavior is the same.
</P>
<P>

</P>
<DT><B>Some scheduler tests fail and I don't understand why.  Help!</B>
<DD><P>

If your implementation mysteriously fails some of the advanced
scheduler tests, try the following:
</P>
<P>

<UL>
<LI>
Read the source files for the tests that you're failing, to make sure
that you understand what's going on.  Each one has a comment at the
top that explains its purpose and expected results.
<P>

</P>
<LI>
Double-check your fixed-point arithmetic routines and your use of them
in the scheduler routines.
<P>

</P>
<LI>
Consider how much work your implementation does in the timer
interrupt.  If the timer interrupt handler takes too long, then it
will take away most of a timer tick from the thread that the timer
interrupt preempted.  When it returns control to that thread, it
therefore won't get to do much work before the next timer interrupt
arrives.  That thread will therefore get blamed for a lot more CPU
time than it actually got a chance to use.  This raises the
interrupted thread's recent CPU count, thereby lowering its priority.
It can cause scheduling decisions to change.  It also raises the load
average.
</UL>
</DL>
<A NAME="Project 2--User Programs"></A>
<HR SIZE="6">
<TABLE CELLPADDING=1 CELLSPACING=1 BORDER=0>
<TR><TD VALIGN="MIDDLE" ALIGN="LEFT">[<A HREF="pintos_2.html#SEC15"> &lt;&lt; </A>]</TD>
<TD VALIGN="MIDDLE" ALIGN="LEFT">[<A HREF="pintos_3.html#SEC32"> &gt;&gt; </A>]</TD>
<TD VALIGN="MIDDLE" ALIGN="LEFT"> &nbsp; <TD VALIGN="MIDDLE" ALIGN="LEFT"> &nbsp; <TD VALIGN="MIDDLE" ALIGN="LEFT"> &nbsp; <TD VALIGN="MIDDLE" ALIGN="LEFT"> &nbsp; <TD VALIGN="MIDDLE" ALIGN="LEFT"> &nbsp; <TD VALIGN="MIDDLE" ALIGN="LEFT">[<A HREF="pintos.html#SEC_Top">Top</A>]</TD>
<TD VALIGN="MIDDLE" ALIGN="LEFT">[<A HREF="pintos.html#SEC_Contents">Contents</A>]</TD>
<TD VALIGN="MIDDLE" ALIGN="LEFT">[Index]</TD>
<TD VALIGN="MIDDLE" ALIGN="LEFT">[<A HREF="pintos_abt.html#SEC_About"> ? </A>]</TD>
</TR></TABLE>
<BR>
<FONT SIZE="-1">
This document was generated
by <I>root</I> on <I>January, 14 2015</I>
using <A HREF="http://texi2html.cvshome.org"><I>texi2html</I></A>
</FONT>

</BODY>
</HTML>

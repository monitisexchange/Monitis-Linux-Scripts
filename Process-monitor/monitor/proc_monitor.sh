#!/bin/bash

# sorces included
source monitor_constant.sh    || exit 2

#previous measurement data
declare -i prev_time=0
declare    return_value

#Validate Process parameters
#@return 0 - success
#@return 1 - PROC_ID is changed (m.b. restarted)
#@return 2 - process down
#@return 4 - No execution command for PROC_ID
#@return 8 - Nor PROC_CMD or PROC_ID is defined
function validate() {
	MSG=""
	local ret=0
	if [[ ( "x$PROC_CMD" != "x" ) ]] #PROC_CMD is defined
	then
		pid=`ps -efw | grep -i "$PROC_CMD" | grep -v grep | awk '{print $2} ' `
		if test "$pid" ;  then
			array=( $pid )
			if [[ ( "x$PROC_ID" != "x" ) ]] #PROC_ID is defined also
			then
				ret=1 #error Incorrect PROC_ID (m.b. restarted)
				for i in "${array[@]}"
				do
					if [[ ( $i -eq $PROC_ID ) ]]
					then
						ret=0
						break;
					fi
				done
				if [[ ($ret -gt 0) ]]
				then
					MSG="INCORRECT PID ( $PROC_ID ) for $PROC_CMD (found ${array[@]} ) - m.b. restarted"
					PROC_ID=${array[0]}
				fi
			fi
		else
			ret=2 #process down
			MSG="NO execution for command $PROC_CMD (m.b. DOWN)"
		fi
	elif [[ ( "x$PROC_ID" != "x" ) ]] #PROC_ID is defined
	then
		if [[ ( -f /proc/$PROC_ID/comm ) ]]
		then
			ret=0
			PROC_CMD=$( cat /proc/$PROC_ID/comm )
			MSG="PID is $PROC_ID for $PROC_CMD"
		else
			ret=4 #error No execution command for PROC_ID
			MSG="No execution command for PID "$PROC_ID
		fi
	else
		ret=8 #Nor PROC_CMD and PROC_ID is defined
		MSG="Nor PROC_CMD and PROC_ID is defined"
	fi
	return $ret
}

#  Format a timestamp into the form 'x day hh:mm:ss'
#  
#  @param TIMESTAMP {NUMBER} the timestamp in sec
# 
function formatTimestamp(){
	local time="$1"
	local sec=$(( $time%60 ))
	local min=$(( ($time/60)%60 ))
	local hr=$(( ($time/3600)%24 ))
	local da=$(( $time/86400 ))
	local str=$(echo `printf "%u.%02u.%02u" $hr $min $sec`)
	if [[ ($da -gt 0) ]]
	then
		str="$da day $str" 
	fi
	echo $str
}

#Function returns variable value from file
#
#@param FILENAME {STRING} - relative or absolute path to file 
#							where beforehand stored the variables set
#@param VAR {STRING} - searching variable name
#@param DELIMITER {CHAR} - separating delimiter
#sample:
#   $(extract_value mstatus auto_increment_offset)
function extract_value() {
    FILENAME=$1
    VAR=$2
    DELIMITER=$3
    if [ $DELIMITER ]
    then
	    grep -w $VAR $FILENAME | awk -F $DELIMITER '{print $2 $3}'    
    else
	    grep -w $VAR $FILENAME | awk '{print $2 $3}'
    fi
}

function get_slow_queries(){
	slow=$(mysqldumpslow -s c -t 5 )
	local pattern="Count:"
	local replaser=' + '${pattern}
	slow=${slow//$pattern/$replaser}
	echo $slow
}

#@return 0 - success
#@return 1 - PROC_ID is changed (m.b. restarted)
#@return 2 - process down
#@return 4 - No execution command for PROC_ID
#@return 8 - Nor PROC_CMD or PROC_ID is defined

function get_measure() {
	local details="details"

	#echo "********** Validate **********"
	validate
	local ret="$?"
	if [[ ($ret -gt 1) && ($ret -lt 4) ]]
	then
		MSG="Process is DOWN..."
		problem="FATAL "+"$MSG"
		details="$details+${problem}"
		return_value="$RESP_DOWN | $details"
		return 1
	elif [[ ($ret -ge 4) ]]
	then
		MSG="No execution command for PID $PROC_ID or invalide parameters"
		return 16
	fi
	
#	local ofd=$( ls /proc/$PROC_ID/fd | wc -l )	#requer ROOT permission
#	local ofd=$( lsof -p$PROC_ID | wc -l )	
	local lsof=$( lsof -p$PROC_ID )
	ofd=$( echo "$lsof" | wc -l )
	osd=$( echo "$lsof" | grep -iE "tcp | udp | ipv" | wc -l )
	local ofdm=$( ulimit -n )
	local ofd_pr=$(echo "scale=1; 100 * $ofd / $ofdm" | bc )
	
	local stats=$( cat /proc/$PROC_ID/stat )
	local array=( $stats )
			  #0	pid %d      The process ID.
              #1	comm %s     The filename of the executable, in parentheses.  This is visible whether or not the executable is swapped out.
              #2	state %c    One character from the string "RSDZTW" where R is running, S is sleeping in an interruptible wait, D is waiting in uninterruptible disk sleep, Z is zombie, T is traced or stopped (on a signal), and W is paging.
              #3	ppid %d     The PID of the parent.
              #4	pgrp %d     The process group ID of the process.
              #5	session %d  The session ID of the process.
              #6	tty_nr %d   The controlling terminal of the process.  (The minor device number is contained in the combination of bits 31 to 20 and 7 to 0; the major device number is in bits 15 to 8.)
              #7	tpgid %d    The ID of the foreground process group of the controlling terminal of the process.
              #8	flags %u (%lu before Linux 2.6.22) The kernel flags word of the process.  For bit meanings, see the PF_* defines in <linux/sched.h>.  Details depend on the kernel version.
              #9	minflt %lu  The number of minor faults the process has made which have not required loading a memory page from disk.
              #10	cminflt %lu The number of minor faults that the process's waited-for children have made.
              #11	majflt %lu  The number of major faults the process has made which have required loading a memory page from disk.
              #12	cmajflt %lu The number of major faults that the process's waited-for children have made.
              #13	utime %lu   Amount of time that this process has been scheduled in user mode, measured in clock ticks (divide by sysconf(_SC_CLK_TCK).  This includes guest time, guest_time
                          #(time spent running a virtual CPU, see below), so that applications that are not aware of the guest time field do not lose that time from their calculations.
              #14	stime %lu   Amount of time that this process has been scheduled in kernel mode, measured in clock ticks (divide by sysconf(_SC_CLK_TCK).
              #15	cutime %ld  Amount of time that this process's waited-for children have been scheduled in user mode, measured in clock ticks (divide by sysconf(_SC_CLK_TCK).  (See also times(2).)
                          #This includes guest time, cguest_time (time spent running a virtual CPU, see below).
              #16	cstime %ld  Amount of time that this process's waited-for children have been scheduled in kernel mode, measured in clock ticks (divide by sysconf(_SC_CLK_TCK).
              #17	priority %ld (Explanation for Linux 2.6) For processes running a real- time scheduling policy (policy below; see sched_setscheduler(2)), this is the negated scheduling
                          #priority, minus one; that is, a number in the range -2 to -100, corresponding to real-time priorities 1 to 99.  For processes running under a non-real-time scheduling policy,
                          #this is the raw nice value (setpriority(2)) as represented in the kernel.  The kernel stores nice values as numbers in the range 0 (high) to 39 (low), corresponding to the user- visible nice range of -20 to 19.
                          #Before Linux 2.6, this was a scaled value based on the scheduler weighting given to this process.
              #18	nice %ld    The nice value (see setpriority(2)), a value in the range 19 (low priority) to -20 (high priority).
              #19	num_threads %ld Number of threads in this process (since Linux 2.6). Before kernel 2.6, this field was hard coded to 0 as a placeholder for an earlier removed field.
              #20	itrealvalue %ld The time in jiffies before the next SIGALRM is sent to the process due to an interval timer.  Since kernel 2.6.17, this field is no longer maintained, and is hard coded as 0.
              #21	starttime %llu (was %lu before Linux 2.6) The time in jiffies the process started after system boot.
              #22	vsize %lu   Virtual memory size in bytes.
              #23	rss %ld     Resident Set Size: number of pages the process has in real memory.This is just the pages which count toward text, data, or stack space.  This does not include pages which have not been demand-loaded in, or which are swapped out.
              #24	rsslim %lu  Current soft limit in bytes on the rss of the process; see the description of RLIMIT_RSS in getpriority(2).
              #25	startcode %lu The address above which program text can run.
              #26	endcode %lu The address below which program text can run.
              #27	startstack %lu The address of the start (i.e., bottom) of the stack.
              #28	kstkesp %lu The current value of ESP (stack pointer), as found in the kernel stack page for the process.
              #29	kstkeip %lu The current EIP (instruction pointer).
              #30	signal %lu  The bitmap of pending signals, displayed as a decimal number.  Obsolete, because it does not provide information on real-time signals; use /proc/[pid]/status instead.
              #31	blocked %lu The bitmap of blocked signals, displayed as a decimal number.  Obsolete, because it does not provide information on real-time signals; use /proc/[pid]/status instead.
              #32	sigignore %lu The bitmap of ignored signals, displayed as a decimal number.  Obsolete, because it does not provide information on real-time signals; use /proc/[pid]/status instead.
              #33	sigcatch %lu The bitmap of caught signals, displayed as a decimal number.  Obsolete, because it does not provide information on real-time signals; use /proc/[pid]/status instead.
              #34	wchan %lu   This is the "channel" in which the process is waiting.  It is the address of a system call, and can be looked up in a namelist if you need a textual name.  (If you have an up-
                          #to-date /etc/psdatabase, then try ps -l to see the WCHAN field in action.)
              #35	nswap %lu   Number of pages swapped (not maintained).
              #36	cnswap %lu  Cumulative nswap for child processes (not maintained).
              #37	exit_signal %d (since Linux 2.1.22) Signal to be sent to parent when we die.
              #38	processor %d (since Linux 2.2.8) CPU number last executed on.
              #39	rt_priority %u (since Linux 2.5.19; was %lu before Linux 2.6.22) Real-time scheduling priority, a number in the range 1 to 99 for processes scheduled under a real-time policy, or 0, for non-real-time processes (see sched_setscheduler(2)).
              #40	policy %u (since Linux 2.5.19; was %lu before Linux 2.6.22) scheduling policy (see sched_setscheduler(2)).  Decode using the SCHED_* constants in linux/sched.h.
              #41	delayacct_blkio_ticks %llu (since Linux 2.6.18) Aggregated block I/O delays, measured in clock ticks (centiseconds).
              #42	guest_time %lu (since Linux 2.6.24) Guest time of the process (time spent running a virtual CPU for a guest operating system), measured in clock ticks (divide by sysconf(_SC_CLK_TCK).
              #43	cguest_time %ld (since Linux 2.6.24) Guest time of the process's children, measured in clock ticks (divide by sysconf(_SC_CLK_TCK).
	local utime=${array[13]}
	local stime=${array[14]}
	
#/proc/[pid]/status	
              #* Name: Command run by this process.
              #* State: Current state of the process.  One of "R (running)", "S (sleeping)", "D (disk sleep)", "T (stopped)", "T (tracing stop)", "Z (zombie)", or "X (dead)".
              #* Tgid: Thread group ID (i.e., Process ID).
              #* Pid: Thread ID (see gettid(2)).
              #* TracerPid: PID of process tracing this process (0 if not being traced).
              #* Uid, Gid: Real, effective, saved set, and file system UIDs (GIDs).
              #* FDSize: Number of file descriptor slots currently allocated.
              #* Groups: Supplementary group list.
              #* VmPeak: Peak virtual memory size.
              #* VmSize: Virtual memory size.
              #* VmLck: Locked memory size (see mlock(3)).
              #* VmHWM: Peak resident set size ("high water mark").
              #* VmRSS: Resident set size.
              #* VmData, VmStk, VmExe: Size of data, stack, and text segments.
              #* VmLib: Shared library code size.
              #* VmPTE: Page table entries size (since Linux 2.6.10).
              #* Threads: Number of threads in process containing this thread.
              #* SigPnd, ShdPnd: Number of signals pending for thread and for process as a whole (see pthreads(7) and signal(7)).
              #* SigBlk, SigIgn, SigCgt: Masks indicating signals being blocked, ignored, and caught (see signal(7)).
              #* CapInh, CapPrm, CapEff: Masks of capabilities enabled in inheritable, permitted, and effective sets (see capabilities(7)).
              #* CapBnd: Capability Bounding set (since kernel 2.6.26, see capabilities(7)).
              #* Cpus_allowed: Mask of CPUs on which this process may run (since Linux 2.6.24, see cpuset(7)).
              #* Cpus_allowed_list: Same as previous, but in "list format" (since Linux 2.6.26, see cpuset(7)).
              #* Mems_allowed: Mask of memory nodes allowed to this process (since Linux 2.6.24, see cpuset(7)).
              #* Mems_allowed_list: Same as previous, but in "list format" (since Linux 2.6.26, see cpuset(7)).
              #* voluntary_context_switches, nonvoluntary_context_switches: Number of voluntary and involuntary context switches (since Linux 2.6.23).
#
	local FDSize=$(extract_value /proc/$PROC_ID/status FDSize :)
	FDSize=` trim "$FDSize" `
	local VmPeak=$(extract_value /proc/$PROC_ID/status VmPeak :)
	local VmSize=$(extract_value /proc/$PROC_ID/status VmSize :)
	local virt=$( echo $VmSize | awk '{print $1}')
	local virtmb=$(echo "scale=3; $virt / 1024" | bc )
	local VmHWM=$(extract_value /proc/$PROC_ID/status VmHWM :)
	local VmRSS=$(extract_value /proc/$PROC_ID/status VmRSS :)
	local res=$( echo $VmRSS | awk '{print $1}')
	local resmb=$(echo "scale=3; $res / 1024" | bc )
	local VmData=$(extract_value /proc/$PROC_ID/status VmData :)
	local data=$( echo $VmData | awk '{print $1}')
	local VmStk=$(extract_value /proc/$PROC_ID/status VmStk :)
	local stack=$( echo $VmStk | awk '{print $1}')
	local VmExe=$(extract_value /proc/$PROC_ID/status VmExe :)
	local Threads=$(extract_value /proc/$PROC_ID/status Threads :)
	Threads=` trim "$Threads" `

	local cm=( $( ps -p$PROC_ID -o %cpu,%mem | grep -v % ) )
	local cpu_pr=${cm[0]}
	local mem_pr=${cm[1]}
	
	local uptime=$( ps -o etime $PROC_ID | grep -v ELAPSED )
	uptime=` trim "$uptime" `
	uptime=${uptime//:/.}

	#echo "*********** Analizing ****************"
	local status="OK"
	
	errors=0
	local tmp=$(( 100 * $ofd / $ofdm ))
	if [[ $tmp -gt 90 ]]
	then
	    MSG[$errors]="WARNING - too much open file descriptors"
	    errors=$(($errors+1))
	    status="NOK"
	fi

	
	if [[ ( ${cpu_pr/.*} -gt 95 ) || ( ${mem_pr/.*} -gt 95 ) ]]
	then
	    MSG[$errors]="WARNING - too much used resources"
	    errors=$(($errors+1))
	    status="NOK"
	fi

		
	if [ $errors -gt 0 ]
	then
	    problem="Problems detected"
	    CNT=0
	    while [[ ("$CNT" != "$errors") ]]
	    do
	        problem="$problem + ${MSG[$CNT]}"
	        CNT=$(($CNT+1))
	    done
	    details="$details+${problem}"
	else
	    details="$details + VmPeak:$VmPeak"
	    details="$details + VmHWM:$VmHWM"
	    details="$details + VmData:$VmData"
	    details="$details + VmStk:$VmStk"
	fi
	local param="status:$status;cpu:$cpu_pr;mem:$mem_pr;virt:$virtmb;res:$resmb;ofd:$ofd;osd:$osd;ofd_pr:$ofd_pr;threads:$Threads;uptime:$uptime"

	return_value="$param | $details"
	return 0
}

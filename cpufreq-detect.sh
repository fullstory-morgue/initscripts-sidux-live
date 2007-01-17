#!/bin/sh

CPUINFO=/proc/cpuinfo
IOPORTS=/proc/ioports

[ -f $CPUINFO ] || exit 0

MODEL_NAME=$(grep '^model name' "$CPUINFO" | head -1 | sed -e 's/^.*: //;')
CPU=$(grep -E '^cpud[^:]+:' "$CPUINFO" | head -1 | sed -e 's/^.*: //;')
VENDOR_ID=$(grep -E '^vendor_id[^:]+:' "$CPUINFO" | head -1 | sed -e 's/^.*: //;')
CPU_FAMILY=$(sed -e '/^cpu family/ {s/.*: //;p;Q};d' $CPUINFO)

CPUFREQ=
# We don't really need to fallback to acpi-cpufreq here, imho
#CPUFREQ_FALLBACK=acpi-cpufreq

# Two modules for PIII-M depending the chipset.
if [ -f $IOPORTS ] && grep -q 'Intel .*ICH' $IOPORTS ; then
	PIII_CPUFREQ=speedstep-ich
else
	PIII_CPUFREQ=speedstep-smi
fi

case "$VENDOR_ID" in
	
	GenuineIntel*)
		# If the CPU has the est flag, it supports enhanced speedstep and should
		# use the speedstep-centrino driver
		if [ "`grep est $CPUINFO`" ]; then
			CPUFREQ=speedstep-centrino;
		elif [ $CPU_FAMILY = 15 ]; then
			# Right. Check if it's a P4 without est.
			# Could be speedstep-ich.
			CPUFREQ=speedstep-ich;
		else
			# So it doesn't have Enhanced Speedstep, and it's not a P4. It could be 
			# a Speedstep PIII, or it may be unsupported. There's no terribly good
			# programmatic way of telling.
			case "$MODEL_NAME" in
				Intel\(R\)\ Pentium\(R\)\ III\ Mobile\ CPU*)
					CPUFREQ=$PIII_CPUFREQ
					;;
		    
				# JD: says this works with   cpufreq_userspace
				Mobile\ Intel\(R\)\ Pentium\(R\)\ III\ CPU\ -\ M*)
					CPUFREQ=$PIII_CPUFREQ
					;;
		    
				# https://bugzilla.ubuntu.com/show_bug.cgi?id=4262
				# UNCONFIRMED
				Pentium\ III\ \(Coppermine\)*)
					CPUFREQ=$PIII_CPUFREQ
					;;
			esac
		fi
		;;
	
	AuthenticAMD*)
		# Hurrah. This is nice and easy.
		case $CPU_FAMILY in
			5)
				# K6
				CPUFREQ=powernow-k6
				;;
			6)
				# K7
				CPUFREQ=powernow-k7
				;;
			15)
				# K8
				CPUFREQ=powernow-k8
				;;
		esac
		;;
	
	CentaurHauls*)
		# VIA
		if [ $CPU_FAMILY = 6 ]; then
			CPUFREQ=longhaul;
		fi
		;;    
	
	GenuineTMx86*)
		# Transmeta
		if [ "`grep longrun $CPUINFO`" ]; then
			CPUFREQ=longrun
		fi
		;;

esac